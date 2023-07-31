// simple wrapper around vma with a very slow debug mode that
// shows every single vma event
//
// BECAUSE I CAN'T FIND WHERE I FAILED TO DESTROY SOME MEMORY.

const std = @import("std");
const vk = @import("vulkan");
const vma = @import("vma");
const core = @import("../core.zig");
const vk_constants = @import("vk_constants.zig");

const DeviceDispatch = vk_constants.DeviceDispatch;
const BaseDispatch = vk_constants.BaseDispatch;
const InstanceDispatch = vk_constants.InstanceDispatch;

pub const Allocation = vma.Allocation;
pub const Allocator = vma.Allocator;
pub const AllocationCreateInfo = vma.AllocationCreateInfo;

pub const NeonVkBuffer = struct {
    buffer: vk.Buffer,
    allocation: vma.Allocation,

    pub fn deinit(self: *@This(), vkAllocator: *NeonVkAllocator) void {
        vkAllocator.destroyBuffer(self);
    }
};

pub const NeonVkImage = struct {
    image: vk.Image,
    allocation: vma.Allocation,
    pixelWidth: u32,
    pixelHeight: u32,

    pub fn deinit(self: *NeonVkImage, allocator: *NeonVkAllocator) void {
        allocator.destroyImage(self);
    }

    /// returns the image ratio of the height over width
    pub inline fn getImageRatioFloat(self: @This()) f32 {
        return @as(f32, @floatFromInt(self.pixelHeight)) / @as(f32, @floatFromInt(self.pixelWidth));
    }
};

pub const AllocationEvent = union(enum) {
    allocate: struct {
        alloc: usize,
        tag: []const u8,
    },
    destroy: struct {
        alloc: usize,
        tag: []const u8,
    },

    pub fn print(self: @This()) void {
        switch (self) {
            .allocate => |allocate| {
                core.graphics_log("allocate @{d} - {s}", .{ allocate.alloc, allocate.tag });
            },
            .destroy => |destroy| {
                core.graphics_log("destroy @{d} - {s}", .{ destroy.alloc, destroy.tag });
            },
        }
    }
};

pub const NeonVkAllocator = struct {
    vmaAllocator: vma.Allocator,
    allocator: std.mem.Allocator,
    eventsList: std.ArrayList(AllocationEvent),
    liveAllocations: std.ArrayList(LiveAlloc),

    const AllocatedObject = union {
        image: NeonVkImage,
        buffer: NeonVkBuffer,
    };

    const LiveAlloc = struct {
        allocation: usize,
        tag: []const u8,
        object: AllocatedObject,
    };

    pub fn createStagingBuffer(
        self: *@This(),
        bufferSize: u32,
        comptime tag: []const u8,
    ) !NeonVkBuffer {
        var bci = vk.BufferCreateInfo{
            .flags = .{},
            .size = bufferSize,
            .usage = .{ .transfer_src_bit = true },
            .sharing_mode = .exclusive,
            .queue_family_index_count = 0,
            .p_queue_family_indices = undefined,
        };

        var vmaCreateInfo = vma.AllocationCreateInfo{
            .flags = .{},
            .usage = .cpuOnly,
        };

        return self.createBuffer(bci, vmaCreateInfo, tag);
    }

    pub fn createGpuBuffer(
        self: *@This(),
        bufferSize: u32,
        options: struct {
            index_buffer_bit: bool = false,
            vertex_buffer_bit: bool = false,
            uniform_texel_buffer_bit: bool = false,
            storage_texel_buffer_bit: bool = false,
            uniform_buffer_bit: bool = false,
            storage_buffer_bit: bool = false,
            indirect_buffer_bit: bool = false,
        },
        comptime tag: []const u8,
    ) !NeonVkBuffer {
        var bci = vk.BufferCreateInfo{
            .flags = .{},
            .size = bufferSize,
            .usage = .{
                .transfer_dst_bit = true,
                .index_buffer_bit = options.index_buffer_bit,
                .vertex_buffer_bit = options.vertex_buffer_bit,
                .uniform_buffer_bit = options.uniform_buffer_bit,
                .storage_buffer_bit = options.storage_buffer_bit,
            },
            .sharing_mode = .exclusive,
            .queue_family_index_count = 0,
            .p_queue_family_indices = undefined,
        };

        var vmaCreateInfo = vma.AllocationCreateInfo{
            .flags = .{},
            .usage = .gpuOnly,
        };

        return self.createBuffer(bci, vmaCreateInfo, tag);
    }

    pub fn create(
        vmaAllocatorCreateInfo: vma.AllocatorCreateInfo,
        allocator: std.mem.Allocator,
    ) !*@This() {
        var newAllocator = try allocator.create(@This());

        newAllocator.* = @This(){
            .vmaAllocator = try vma.Allocator.create(vmaAllocatorCreateInfo),
            .allocator = allocator,
            .eventsList = std.ArrayList(AllocationEvent).init(allocator),
            .liveAllocations = std.ArrayList(LiveAlloc).init(allocator),
        };

        return newAllocator;
    }

    fn pushAllocation(
        self: *@This(),
        allocation: vma.Allocation,
        tag: []const u8,
        object: AllocatedObject,
    ) !void {
        try self.liveAllocations.append(.{
            .allocation = @intFromEnum(allocation),
            .tag = tag,
            .object = object,
        });

        try self.eventsList.append(.{ .allocate = .{
            .alloc = @intFromEnum(allocation),
            .tag = tag,
        } });
    }

    fn pushDestroy(self: *@This(), allocation: vma.Allocation) void {
        // find the corresponding live allocation
        var live: LiveAlloc = undefined;
        var i: u32 = 0;
        var found: bool = false;

        while (i < self.liveAllocations.items.len) : (i += 1) {
            if (self.liveAllocations.items[i].allocation == @intFromEnum(allocation)) {
                found = true;
                live = self.liveAllocations.items[i];
                break;
            }
        }

        if (found) {
            _ = self.liveAllocations.swapRemove(i);
        } else {
            unreachable;
        }

        self.eventsList.append(.{ .destroy = .{
            .alloc = @intFromEnum(allocation),
            .tag = live.tag,
        } }) catch unreachable;
    }

    pub fn createBuffer(
        self: *@This(),
        bci: vk.BufferCreateInfo,
        aci: AllocationCreateInfo,
        comptime tag: []const u8,
    ) !NeonVkBuffer {
        const results = try self.vmaAllocator.createBuffer(bci, aci);

        var object: AllocatedObject = .{
            .buffer = NeonVkBuffer{
                .buffer = results.buffer,
                .allocation = results.allocation,
            },
        };

        try self.pushAllocation(results.allocation, tag, object);

        return object.buffer;
    }

    pub fn destroyBuffer(self: *@This(), buffer: *NeonVkBuffer) void {
        self.pushDestroy(buffer.allocation);
        self.vmaAllocator.destroyBuffer(buffer.buffer, buffer.allocation);
    }

    pub fn destroyImage(self: *@This(), image: *NeonVkImage) void {
        self.pushDestroy(image.allocation);
        self.vmaAllocator.destroyImage(image.image, image.allocation);
    }

    pub fn createImage(
        self: *@This(),
        ici: vk.ImageCreateInfo,
        aci: AllocationCreateInfo,
        comptime tag: []const u8,
    ) !NeonVkImage {
        var result = try self.vmaAllocator.createImage(ici, aci);

        var object: AllocatedObject = .{ .image = .{
            .image = result.image,
            .allocation = result.allocation,
            .pixelWidth = ici.extent.width,
            .pixelHeight = ici.extent.height,
        } };

        try self.pushAllocation(result.allocation, tag, object);

        return object.image;
    }

    pub fn mapMemorySlice(self: *@This(), comptime T: type, buffer: NeonVkBuffer, size: usize) ![]T {
        var slice: []T = undefined;
        slice.ptr = try self.mapMemory(buffer, T);
        slice.len = size;

        return slice;
    }

    pub fn mapMemory(self: *@This(), buffer: NeonVkBuffer, comptime T: type) ![*]T {
        return try self.vmaAllocator.mapMemory(buffer.allocation, T);
    }

    pub fn unmapMemory(self: *@This(), buffer: NeonVkBuffer) void {
        self.vmaAllocator.unmapMemory(buffer.allocation);
    }

    pub fn printEventsLog(self: @This()) void {
        for (self.eventsList.items) |item| {
            item.print();
        }
    }

    pub fn destroy(self: *@This()) void {
        if (self.liveAllocations.items.len > 0) {
            core.graphics_log("There are still allocations outstanding: {d}", .{self.liveAllocations.items.len});

            self.printEventsLog();
            for (self.liveAllocations.items) |alloc| {
                core.graphics_log("allocation@{d} tag:\'{s}\' {any}", .{ alloc.allocation, alloc.tag, alloc.object });
            }
            core.forceFlush();

            return;
        }

        // if there are any live allocations left, print them all out.
        self.vmaAllocator.destroy();
    }
};
