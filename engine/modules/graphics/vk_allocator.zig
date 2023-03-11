// simple wrapper around vma

const std = @import("std");
const vma = @import("vma");
const core = @import("../core.zig");
const vk_constants = @import("vk_constants.zig");

const DeviceDispatch = vk_constants.DeviceDispatch;
const BaseDispatch = vk_constants.BaseDispatch;
const InstanceDispatch = vk_constants.InstanceDispatch;

pub const AllocationEvent = union {
    allocate: struct {
        name: core.Name = core.MakeName("root"),
        alloc: vma.Allocation,
    },
    destroy: struct {
        alloc: vma.Allocation,
        reason: ?[]u8,
    },
};

pub const VkAllocator = struct {
    vmaAllocator: vma.Allocator,
    allocator: std.mem.Allocator,
    eventsList: std.ArrayList(AllocationEvent),

    pub fn create(vmaAllocatorCreateInfo: vma.AllocatorCreateInfo, allocator: std.mem.Allocator) !@This() {
        return .{
            .vmaAllocator = try vma.Allocator.create(vmaAllocatorCreateInfo),
            .allocator = allocator,
            .eventsList = std.ArrayList(AllocationEvent.init(allocator)),
        };
    }

    pub fn createBuffer() void {}
    pub fn createImage() void {}
    pub fn mapMemory() void {}
    pub fn unmapMemory() void {}

    pub fn dumpEventsAsDot(self: @This()) ![]u8 {
        return try self.allocator.alloc(u8, 8);
    }

    pub fn destroy(self: *@This()) void {
        _ = self;
    }
};
