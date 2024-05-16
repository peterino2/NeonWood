const std = @import("std");
const logging = @import("logging.zig");
const input = @import("input.zig");
const p2 = @import("p2");
const engine_logs = logging.engine_logs;

const ObjectHandle = p2.ObjectHandle;
const Name = p2.Name;
const MakeName = p2.MakeName;

const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;

const ArrayListUnmanaged = std.ArrayListUnmanaged;
const AutoHashMapUnmanaged = std.AutoHashMapUnmanaged;

pub fn InterfaceRef(comptime Vtable: type) type {
    return struct {
        ptr: *anyopaque,
        vtable: *const Vtable,
    };
}

pub fn MakeTypeName(comptime TargetType: type) Name {
    const hashedName = comptime std.fmt.comptimePrint("{s}_{d}", .{ @typeName(TargetType), @sizeOf(TargetType) });

    return MakeName(hashedName);
}

// todo.. engineObject is not the right word for this

pub const EngineDataEventError = error{
    UnknownStatePanic,
    BadInit,
    UnknownError,
    OutOfMemory,
};

pub const RttiData = struct {
    typeName: Name,
    typeSize: usize,
    typeAlign: usize,

    init_func: *const fn (std.mem.Allocator) EngineDataEventError!*anyopaque,
    tick_func: ?*const fn (*anyopaque, f64) void = null,
    preTick_func: ?*const fn (*anyopaque, f64) EngineDataEventError!void = null,
    deinit_func: ?*const fn (*anyopaque) void = null,
    postInit_func: ?*const fn (*anyopaque) EngineDataEventError!void = null,
    processEvents: ?*const fn (*anyopaque, u64) EngineDataEventError!void = null,
    exitSignal_func: ?*const fn (*anyopaque) EngineDataEventError!void = null,

    pub fn from(comptime TargetType: type) RttiData {
        const wrappedInit = struct {
            const funcFind: @TypeOf(@field(TargetType, "init")) = @field(TargetType, "init");

            pub fn func(allocator: std.mem.Allocator) EngineDataEventError!*anyopaque {
                const newObject = funcFind(allocator) catch return error.BadInit;
                return @as(*anyopaque, @ptrCast(newObject));
            }
        };

        var self = RttiData{
            .typeName = MakeTypeName(TargetType),
            .typeSize = @sizeOf(TargetType),
            .typeAlign = @alignOf(TargetType),
            .init_func = wrappedInit.func,
        };

        if (@hasDecl(TargetType, "postInit")) {
            const wrappedPostInit = struct {
                pub fn func(pointer: *anyopaque) EngineDataEventError!void {
                    var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                    try ptr.postInit();
                }
            };

            self.postInit_func = wrappedPostInit.func;
        }

        if (@hasDecl(TargetType, "preTick")) {
            const wrappedTick = struct {
                pub fn func(pointer: *anyopaque, deltaTime: f64) EngineDataEventError!void {
                    var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                    try ptr.preTick(deltaTime);
                }
            };

            self.preTick_func = wrappedTick.func;
        }

        if (@hasDecl(TargetType, "tick")) {
            const wrappedTick = struct {
                pub fn func(pointer: *anyopaque, deltaTime: f64) void {
                    var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                    ptr.tick(deltaTime);
                }
            };

            self.tick_func = wrappedTick.func;
        }

        if (@hasDecl(TargetType, "processEvents")) {
            const wrappedProcessEvents = struct {
                pub fn func(pointer: *anyopaque, frameNumber: u64) EngineDataEventError!void {
                    var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                    try ptr.processEvents(frameNumber);
                }
            };

            self.processEvents = wrappedProcessEvents.func;
        }

        if (@hasDecl(TargetType, "onExitSignal")) {
            const wrappedProcessEvents = struct {
                pub fn func(pointer: *anyopaque) EngineDataEventError!void {
                    var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                    try ptr.onExitSignal();
                }
            };

            self.exitSignal_func = wrappedProcessEvents.func;
        }

        if (@hasDecl(TargetType, "deinit")) {
            const wrappedDeinit = struct {
                pub fn func(pointer: *anyopaque) void {
                    var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                    ptr.deinit();
                }
            };

            self.deinit_func = wrappedDeinit.func;
        }

        return self;
    }
};

pub const EngineObjectRef = InterfaceRef(RttiData);
