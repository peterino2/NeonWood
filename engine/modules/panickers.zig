const std = @import("std");
const builtin = @import("builtin");
const os = std.os;
const windows = std.os.windows;
const core = @import("core.zig");

fn handleSegfaultWindows(info: *windows.EXCEPTION_POINTERS) callconv(windows.WINAPI) c_long {
    core.engine_logs("PANIC!!");
    core.forceFlush();
    switch (info.ExceptionRecord.ExceptionCode) {
        windows.EXCEPTION_DATATYPE_MISALIGNMENT => handleSegfaultWindowsExtra(info, 0, "Unaligned Memory Access"),
        windows.EXCEPTION_ACCESS_VIOLATION => handleSegfaultWindowsExtra(info, 1, null),
        windows.EXCEPTION_ILLEGAL_INSTRUCTION => handleSegfaultWindowsExtra(info, 2, null),
        windows.EXCEPTION_STACK_OVERFLOW => handleSegfaultWindowsExtra(info, 0, "Stack Overflow"),
        else => return windows.EXCEPTION_CONTINUE_SEARCH,
    }
}

var panic_mutex = std.Thread.Mutex{};
var panicking = std.atomic.Atomic(u8).init(0);
threadlocal var panic_stage: usize = 0;

fn waitForOtherThreadToFinishPanicking() void {
    if (panicking.fetchSub(1, .SeqCst) != 1) {
        // Another thread is panicking, wait for the last one to finish
        // and call abort()
        if (builtin.single_threaded) unreachable;

        // Sleep forever without hammering the CPU
        var futex = std.atomic.Atomic(u32).init(0);
        while (true) std.Thread.Futex.wait(&futex, 0);
        unreachable;
    }
}

fn handleSegfaultWindowsExtra(
    info: *windows.EXCEPTION_POINTERS,
    msg: u8,
    label: ?[]const u8,
) noreturn {
    const exception_address = @intFromPtr(info.ExceptionRecord.ExceptionAddress);
    if (@hasDecl(windows, "CONTEXT")) {
        switch (msg) {
            0 => std.debug.panicImpl(null, exception_address, "{s}", label.?),
            1 => {
                const format_item = "Segmentation fault at address 0x{x}";
                var buf: [format_item.len + 64]u8 = undefined; // 64 is arbitrary, but sufficiently large
                const to_print = std.fmt.bufPrint(buf[0..buf.len], format_item, .{info.ExceptionRecord.ExceptionInformation[1]}) catch unreachable;
                std.debug.panicImpl(null, exception_address, to_print);
            },
            2 => std.debug.panicImpl(null, exception_address, "Illegal Instruction"),
            else => unreachable,
        }
    }
}

fn dumpSegfaultInfoWindows(info: *windows.EXCEPTION_POINTERS, msg: u8, label: ?[]const u8) void {
    const stderr = std.io.getStdErr().writer();
    _ = switch (msg) {
        0 => stderr.print("{s}\n", .{label.?}),
        1 => stderr.print("Segmentation fault at address 0x{x}\n", .{info.ExceptionRecord.ExceptionInformation[1]}),
        2 => stderr.print("Illegal instruction at address 0x{x}\n", .{info.ContextRecord.getRegs().ip}),
        else => unreachable,
    } catch os.abort();

    std.debug.dumpStackTraceFromBase(info.ContextRecord);
}

pub fn dumpStackPointerAddr(prefix: []const u8) void {
    const sp = asm (""
        : [argc] "={rsp}" (-> usize),
    );
    std.debug.print("{} sp = 0x{x}\n", .{ prefix, sp });
}

fn dumpSegfaultInfoPosix(sig: i32, addr: usize, ctx_ptr: ?*const anyopaque) void {
    const stderr = std.io.getStdErr().writer();
    _ = switch (sig) {
        os.SIG.SEGV => stderr.print("Segmentation fault at address 0x{x}\n", .{addr}),
        os.SIG.ILL => stderr.print("Illegal instruction at address 0x{x}\n", .{addr}),
        os.SIG.BUS => stderr.print("Bus error at address 0x{x}\n", .{addr}),
        os.SIG.FPE => stderr.print("Arithmetic exception at address 0x{x}\n", .{addr}),
        else => unreachable,
    } catch os.abort();

    switch (builtin.cpu.arch) {
        .x86,
        .x86_64,
        .arm,
        .aarch64,
        => {
            const ctx: *const os.ucontext_t = @ptrCast(@alignCast(ctx_ptr));
            std.debug.dumpStackTraceFromBase(ctx);
        },
        else => {},
    }
}

fn handleSegfaultPosix(sig: i32, info: *const os.siginfo_t, ctx_ptr: ?*const anyopaque) callconv(.C) noreturn {
    core.engine_logs("PANIC!!");
    core.forceFlush();
    resetSegfaultHandler();

    const addr = switch (builtin.os.tag) {
        .linux => @intFromPtr(info.fields.sigfault.addr),
        .freebsd, .macos => @intFromPtr(info.addr),
        .netbsd => @intFromPtr(info.info.reason.fault.addr),
        .openbsd => @intFromPtr(info.data.fault.addr),
        .solaris => @intFromPtr(info.reason.fault.addr),
        else => unreachable,
    };

    nosuspend switch (panic_stage) {
        0 => {
            panic_stage = 1;
            _ = panicking.fetchAdd(1, .SeqCst);

            {
                panic_mutex.lock();
                defer panic_mutex.unlock();

                dumpSegfaultInfoPosix(sig, addr, ctx_ptr);
            }

            waitForOtherThreadToFinishPanicking();
        },
        else => {
            // panic mutex already locked
            dumpSegfaultInfoPosix(sig, addr, ctx_ptr);
        },
    };

    // We cannot allow the signal handler to return because when it runs the original instruction
    // again, the memory may be mapped and undefined behavior would occur rather than repeating
    // the segfault. So we simply abort here.
    os.abort();
}
//
//
fn resetSegfaultHandler() void {
    if (builtin.os.tag == .windows) {
        if (windows_segfault_handle) |handle| {
            _ = windows.kernel32.RemoveVectoredExceptionHandler(handle);
            windows_segfault_handle = null;
        }
        return;
    }

    var act = os.Sigaction{
        .handler = .{ .handler = os.SIG.DFL },
        .mask = os.empty_sigset,
        .flags = 0,
    };
    // To avoid a double-panic, do nothing if an error happens here.
    std.debug.updateSegfaultHandler(&act) catch {};
}

// my custom version of segfault handler.
var windows_segfault_handle: ?windows.HANDLE = null;

pub fn attachSegfaultHandler() void {
    if (builtin.os.tag == .windows) {
        windows_segfault_handle = windows.kernel32.AddVectoredExceptionHandler(0, handleSegfaultWindows);
        return;
    }
    var act = os.Sigaction{
        .handler = .{ .sigaction = handleSegfaultPosix },
        .mask = os.empty_sigset,
        .flags = (os.SA.SIGINFO | os.SA.RESTART | os.SA.RESETHAND),
    };

    std.debug.updateSegfaultHandler(&act) catch {
        @panic("unable to install segfault handler, maybe adjust have_segfault_handling_support in std/debug.zig");
    };
}
