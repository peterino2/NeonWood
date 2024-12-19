allocator: std.mem.Allocator,

modules: ModuleDirList,

testResultsQueue: core.RingQueue(ModuleResults),

const ModuleDirList = std.ArrayList(ModuleDir);
const ModuleDir = struct {
    name: []u8,
    modulePath: []u8,

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        allocator.free(self.modulePath);
    }
};

const ModuleResults = struct {
    success: bool = true,
    log: std.ArrayListUnmanaged(u8) = .{},
    logError: std.ArrayListUnmanaged(u8) = .{},

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.log.deinit(allocator);
        self.logError.deinit(allocator);
    }
};

pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());

pub fn init(allocator: std.mem.Allocator) !*@This() {
    const self = try allocator.create(@This());
    self.* = .{
        .allocator = allocator,
        .testResultsQueue = try core.RingQueue(ModuleResults).init(allocator, 4096),
        .modules = ModuleDirList.init(allocator),
    };

    return self;
}

pub fn prepare(self: *@This()) !void {
    const baseDirs: []const []const u8 = &.{ "../lib", "../engine" };

    for (baseDirs) |basePath| {
        const baseDir = try std.fs.cwd().openDir(basePath, .{ .iterate = true });

        var iter = baseDir.iterate();
        while (try iter.next()) |entry| {
            if (entry.kind == .directory) {
                {
                    const modDir = try baseDir.openDir(entry.name, .{});
                    modDir.access("build.zig.zon", .{}) catch {
                        core.engine_log("skipping module [{s}] because missing build.zig.zon ", .{entry.name});
                        continue;
                    };
                }

                const module: ModuleDir = .{
                    .name = try self.allocator.dupe(u8, entry.name),
                    .modulePath = try std.fmt.allocPrint(self.allocator, "{s}/{s}", .{ basePath, entry.name }),
                };

                try self.modules.append(module);
            }
        }
    }

    // create a task list and kick off tasks for each module
    {
        const L = struct {
            module: *const ModuleDir,
            program: *Program,
            allocator: std.mem.Allocator,

            pub fn func(ctx: @This(), job: *core.JobContext) void {
                _ = job;

                // core.engine_log("starting test job: {s} {s}", ctx.module.*);

                const argv: []const []const u8 = &.{ "zig", "build", "test" };

                const cwdPath = std.fs.cwd().realpathAlloc(ctx.allocator, ctx.module.modulePath) catch unreachable;
                defer ctx.allocator.free(cwdPath);

                const result = std.process.Child.run(.{
                    .argv = argv,
                    .allocator = ctx.allocator,
                    .cwd = cwdPath,
                }) catch unreachable;

                defer ctx.allocator.free(result.stdout);
                defer ctx.allocator.free(result.stderr);
                var success: bool = true;
                switch (result.term) {
                    .Exited => |value| {
                        if (value != 0) {
                            success = false;
                        }
                    },
                    .Signal => {
                        success = false;
                    },
                    .Stopped => {
                        success = false;
                        // no-op should be ok?
                    },
                    .Unknown => {
                        unreachable;
                    },
                }

                if (success) {
                    core.engine_log("test module [{s}] passed!", .{ctx.module.name});
                } else {
                    core.engine_err("test module [{s}] failed!", .{ctx.module.name});
                    core.engine_err("failure {s}: ", .{result.stderr});
                }

                var moduleResults: ModuleResults = .{
                    .success = success,
                };

                moduleResults.log.appendSlice(ctx.allocator, result.stdout) catch unreachable;
                moduleResults.logError.appendSlice(ctx.allocator, result.stderr) catch unreachable;

                ctx.program.testResultsQueue.pushLocked(moduleResults) catch unreachable;
            }
        };

        for (self.modules.items) |*mod| {
            try core.dispatchJob(L{ .module = mod, .program = self, .allocator = self.allocator });
        }
    }
}

pub fn tick(self: *@This(), _: f64) void {
    std.time.sleep(10_000_000);
    if (self.testResultsQueue.count() == self.modules.items.len) {
        // all tests complete, tear it down boys.
        while (self.testResultsQueue.popFromUnlocked()) |t| {
            var copy = t;
            copy.deinit(self.allocator);
        }
        core.exitNow();
    }
}

pub fn deinit(self: *@This()) void {
    self.testResultsQueue.deinit();
    for (self.modules.items) |*mod| {
        mod.deinit(self.allocator);
    }
    self.modules.deinit();
    self.allocator.destroy(self);
}

pub fn main() anyerror!void {
    try neonwood.initializeAndRunStandardProgram(@This(), .{
        .name = "Hello World",
        .enabledModules = .{
            .platform = false,
            .graphics = false,
            .ui = false,
            .papyrus = false,
            .vkImgui = false,
        },
    });
}

const Program = @This();
const std = @import("std");
const neonwood = @import("NeonWood");
const core = neonwood.core;
const script = core.script;
