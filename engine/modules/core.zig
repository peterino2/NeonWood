const root = @import("root");
pub usingnamespace @import("core/misc.zig");
pub usingnamespace @import("core/logging.zig");
pub usingnamespace @import("core/engineTime.zig");
pub usingnamespace @import("core/rtti.zig");
pub usingnamespace @import("core/jobs.zig");
pub const engine = @import("core/engine.zig");
pub const tracy = @import("core/lib/Zig-Tracy/tracy.zig");
pub const zm = @import("core/lib/zmath/zmath.zig");
pub usingnamespace @import("core/lib/p2/algorithm.zig");
const algorithm = @import("core/lib/p2/algorithm.zig");
pub usingnamespace @import("core/math.zig");
pub usingnamespace @import("core/string.zig");

pub const scene = @import("core/scene.zig");
pub const SceneSystem = scene.SceneSystem;

pub const names = @import("core/names.zig");
pub const Name = names.Name;
pub const MakeName = names.MakeName;
pub const Engine = engine.Engine;

pub const spng = @import("core/lib/zig-spng/spng.zig");

pub const assert = std.debug.assert;
pub const DefaultName = MakeName("default");

const trace = @import("core/trace.zig");
pub const TracesContext = trace.TracesContext;

const std = @import("std");
const tests = @import("core/tests.zig");
const logging = @import("core/logging.zig");
const vk = @import("vulkan");
const c = @This();

pub fn assertf(eval: anytype, comptime fmt: []const u8, args: anytype) !void {
    if (!eval) {
        logging.engine_err(fmt, args);
        return error.AssertFailure;
    }
}

const logs = logging.engine_logs;
const log = logging.engine_log;

pub var gScene: *SceneSystem = undefined;

pub fn start_module() void {
    gEngine = gEngineAllocator.create(Engine) catch unreachable;
    gEngine.* = Engine.init(gEngineAllocator) catch unreachable;

    gScene = gEngine.createObject(scene.SceneSystem, .{ .can_tick = true }) catch unreachable;

    logging.setupLogging(gEngine) catch unreachable;

    logs("core module starting up... ");
    return;
}

pub fn run() void {}

pub fn shutdown_module() void {
    gEngineAllocator.destroy(gEngine);
    logs("core module shutting down...");
    return;
}

pub fn dispatchJob(capture: anytype) !void {
    try gEngine.jobManager.newJob(capture);
}

pub var gEngineAllocator: std.mem.Allocator = std.heap.c_allocator;
pub var gEngine: *Engine = undefined;

pub fn createObject(comptime T: type, params: engine.NeonObjectParams) !*T {
    return gEngine.createObject(T, params);
}

pub fn traceFmt(name: Name, comptime fmt: []const u8, args: anytype) !void {
    try gEngine.tracesContext.traces.getEntry(name.hash).?.value_ptr.*.traceFmt(
        gEngine.tracesContext.allocator,
        fmt,
        args,
    );
}

pub fn traceFmtDefault(comptime fmt: []const u8, args: anytype) !void {
    try traceFmt(DefaultName, fmt, args);
}

pub fn dumpDefaultTrace() !void {
    for (gEngine.tracesContext.traces.getEntry(DefaultName.hash).?.value_ptr.*.data.items) |*t| {
        t.debugPrint(std.heap.c_allocator);
    }
}

pub fn splitIntoLines(file_contents: []const u8) std.mem.SplitIterator(u8) {
    // find a \n and see if it has \r\n
    var index: u32 = 0;
    while (index < file_contents.len) : (index += 1) {
        if (file_contents[index] == '\n') {
            if (index > 0) {
                if (file_contents[index - 1] == '\r') {
                    return std.mem.split(u8, file_contents, "\r\n");
                } else {
                    return std.mem.split(u8, file_contents, "\n");
                }
            } else {
                return std.mem.split(u8, file_contents, "\n");
            }
        }
    }
    return std.mem.split(u8, file_contents, "\n");
}

// alignment of 1 should be used for text files
pub fn loadFileAlloc(filename: []const u8, comptime alignment: usize, allocator: std.mem.Allocator) ![]u8 {
    var file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    const filesize = (try file.stat()).size;
    var buffer: []u8 = try allocator.alignedAlloc(u8, alignment, filesize);
    try file.reader().readNoEof(buffer);
    return buffer;
}

const showDebug = false;

pub fn implement_func_for_tagged_union_nonull(
    self: anytype,
    comptime funcName: []const u8,
    comptime returnType: type,
    args: anytype,
) returnType {
    const Self = @TypeOf(self);
    inline for (@typeInfo(std.meta.Tag(Self)).Enum.fields) |field| {
        if (@intToEnum(std.meta.Tag(Self), field.value) == self) {
            if (@hasDecl(@TypeOf(@field(self, field.name)), funcName)) {
                return @field(@field(self, field.name), funcName)(args);
            }
        }
    }

    unreachable;
}

pub const NoName = MakeName("none");

pub fn writeToFile(data: []const u8, path: []const u8) !void {
    const file = try std.fs.cwd().createFile(
        path,
        .{
            .read = true,
        },
    );

    const bytes_written = try file.writeAll(data);
    _ = bytes_written;
    log("written: bytes to {s}", .{path});
}

pub fn dupe(comptime T: type, allocator: std.mem.Allocator, source: []const T) ![]T {
    var buff: []T = try allocator.alloc(T, source.len);
    for (source) |s, i| {
        buff[i] = s;
    }
    return buff;
}

pub const NeonObjectTableName: []const u8 = "NeonObjectTable";

pub fn SearchDeclsRecursive(comptime T: type) ?[]const RttiTypeInfo {
    @setEvalBranchQuota(10000000);
    return SearchDeclsRecursiveInner(T);
}

pub fn SearchDeclsRecursiveInner(comptime T: type) ?[]const RttiTypeInfo {
    inline for (comptime std.meta.declarations(T)) |decl| {
        if (decl.is_pub and !std.mem.eql(u8, decl.name, "RttiTypeInfoList")) {
            if (@TypeOf(@field(T, decl.name)) == type) {
                switch (@typeInfo(@field(T, decl.name))) {
                    .Struct, .Enum, .Union, .Opaque => {
                        inline for (comptime std.meta.declarations(T)) |decl2| {
                            if (std.mem.eql(u8, decl2.name, NeonObjectTableName)) {
                                @compileLog(decl.name, decl2.name, @typeInfo(@field(T, decl.name)));
                            }
                            // if (decl.is_pub and !std.mem.eql(u8, decl.name, "std") and !std.mem.eql(u8, decl.name, "c") and !std.mem.eql(u8, decl.name, "ctracy") and !std.mem.eql(u8, decl.name, "cimport") and !std.mem.eql(u8, decl.name, "vk") and !std.mem.eql(u8, decl.name, "vk_constants")) {
                            //     _ = SearchDeclsRecursiveInner(@field(T, decl.name));
                            // }
                            // and std.mem.eql(u8, decl2.name, NeonObjectTableName)) {} else {}
                        }
                    },
                    else => {},
                }
            }
        }
    }

    return null;
}

pub const RttiTypeInfoList: ?[]const RttiTypeInfo = SearchDeclsRecursive(root);

pub const RttiTypeInfo = struct {
    name: []const u8,
};
