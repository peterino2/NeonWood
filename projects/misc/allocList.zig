// given a file format which contains a list of allocs, frees, and reallocs
// display them in chronological order.
// and highlight which allocations are not free'd at each step
const nw = @import("NeonWood");

backingAllocator: std.mem.Allocator,
arena: std.heap.ArenaAllocator,
fullscreen: bool = false,
padding: bool = false,
dockspaceFlags: imgui.DockNodeFlags = .{},

stackToView: u32 = 0,

open: bool = true,

pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());

pub fn tick(self: *@This(), _: f64) void {
    dockspace(&self.open);
    self.mainWindow();
}

var strline: [256]u8 = undefined;

pub fn mainWindow(self: *@This()) void {
    if (imgui.begin("Main", &self.open, .{
        .no_collapse = true,
    })) {
        if (imgui.button("Dump the callstack!!!!", .{})) {
            core.MemoryTracker.dumpTimeline("timeline.txt") catch unreachable;
        }

        if (core.MemoryTracker.MTGet()) |tracker| {
            if (tracker.stackCompactor) |compactor| {
                var buf: [32]u8 = undefined;

                if (compactor.stackMap.get(self.stackToView)) |stack| {
                    const strList = stack.debugStr;
                    for (strList) |str| {
                        if (str) |s| {
                            imgui.textSlice(s);
                        }
                    }
                }

                if (false) {
                    var iter = compactor.stackMap.iterator();
                    while (iter.next()) |v| {
                        const stackDbgList = v.value_ptr.*.debugStr;
                        const buttonValue = std.fmt.bufPrintZ(&buf, "callstack: {x}", .{v.key_ptr.*}) catch unreachable;

                        if (imgui.button(buttonValue, .{})) {
                            self.stackToView = v.key_ptr.*;
                        }

                        if (self.stackToView == v.key_ptr.*) {
                            for (stackDbgList) |dbg| {
                                if (dbg) |dbgStr| {
                                    imgui.textSlice(dbgStr);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    imgui.end();

    if (imgui.begin("Timeline", &self.open, .{ .no_collapse = true })) {
        if (core.MemoryTracker.MTGet()) |tracker| {
            if (tracker.timeline) |*timeline| {
                var i: usize = 0;
                var s: [:0]u8 = undefined;
                while (i < timeline.events.len() and i < 1024) : (i += 1) {
                    const event = timeline.events.get(i);
                    switch (event.event) {
                        .alloc => |x| {
                            s = std.fmt.bufPrintZ(
                                &strline,
                                "{d} {x} alloc {d} bytes\n",
                                .{ i, event.callstackId, x.size },
                            ) catch unreachable;
                        },
                        .free => |x| {
                            s = std.fmt.bufPrintZ(
                                &strline,
                                "{d} {x} free {d} bytes\n",
                                .{ i, event.callstackId, x.size },
                            ) catch unreachable;
                        },
                        .resize => |x| {
                            s = std.fmt.bufPrintZ(
                                &strline,
                                "{d} {x} resize {d} -> {d} bytes\n",
                                .{ i, event.callstackId, x.oldSize, x.newSize },
                            ) catch unreachable;
                        },
                    }

                    if (imgui.button(s, .{})) {
                        core.engine_log("callstack clicked on {x}", .{event.callstackId});
                        self.stackToView = event.callstackId;
                    }
                }
            }
        }
    }
    imgui.end();
}

pub fn dockspace(open: *bool) void {
    const flags: imgui.WindowFlags = .{
        .menu_bar = false,
        .no_docking = true,
        .no_title_bar = true,
        .no_collapse = true,
        .no_resize = true,
        .no_move = true,
        .no_bring_to_front_on_focus = true,
        .no_nav_focus = true,
        .no_background = true,
    };

    const viewport = imgui.getMainViewport().?;
    imgui.setNextWindowPos(viewport.work_pos, .{}, .{});
    imgui.setNextWindowSize(viewport.work_size, .{});
    imgui.setNextWindowViewport(viewport.id);
    imgui.pushStyleVar_Float(.WindowRounding, 0.0);
    imgui.pushStyleVar_Float(.WindowBorderSize, 0.0);
    imgui.pushStyleVar_Vec2(.WindowPadding, .{ .x = 0, .y = 0 });

    _ = imgui.begin("Dockspace Demo", open, flags);
    imgui.popStyleVar(3);

    const id = imgui.getID_Str("MainDockspace");
    _ = imgui.dockSpace(id, .{ .x = 0, .y = 0 }, .{}, null);
    imgui.end();
}

pub inline fn allocator(self: @This()) std.mem.Allocator {
    return self.arena.allocator();
}

pub fn init(alloc: std.mem.Allocator) !*@This() {
    const self = try alloc.create(@This());
    self.* = .{
        .backingAllocator = alloc,
        .arena = std.heap.ArenaAllocator.init(alloc),
    };
    return self;
}

pub fn deinit(self: *@This()) void {
    self.arena.deinit();
    self.backingAllocator.destroy(self);
}

pub fn main() !void {
    core.stacks.initStackCompactor();
    nw.graphics.setStartupSettings("maxObjectCount", 10);
    try nw.initializeAndRunStandardProgram(@This(), .{ .name = "Allocation viewer", .ui = false, .papyrus = false });
}

const std = @import("std");
const core = nw.core;
const imgui = nw.vkImgui.api;
