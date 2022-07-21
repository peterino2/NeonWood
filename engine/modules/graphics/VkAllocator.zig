const std = @import("std");
const vk = @import("vulkan");
const c = @import("c.zig");
const core = @import("../core/core.zig");
const ArrayList = std.ArrayList;

const vulkan_constants = @import("vulkan_constants.zig");
const NUM_FRAMES = vulkan_constants.NUM_FRAMES;

const DeviceDispatch = vulkan_constants.DeviceDispatch;
const BaseDispatch = vulkan_constants.BaseDispatch;
const InstanceDispatch = vulkan_constants.InstanceDispatch;

const defaultLocalMemoryPerPoolMB = 128;
const defaultHostVisibleMemoryPerPoolMB = 64;

pub const NeonVkMemoryUsage = enum {
    VULKAN_MEMORY_USAGE_UNKNOWN,
    VULKAN_MEMORY_USAGE_GPU_ONLY,
    VULKAN_MEMORY_USAGE_CPU_ONLY,
    VULKAN_MEMORY_USAGE_CPU_TO_GPU,
    VULKAN_MEMORY_USAGE_GPU_TO_CPU,
};

pub const NeonVkAllocationType = enum {
    VULKAN_ALLOCATION_TYPE_FREE,
    VULKAN_ALLOCATION_TYPE_BUFFER,
    VULKAN_ALLOCATION_TYPE_IMAGE,
    VULKAN_ALLOCATION_TYPE_IMAGE_LINEAR,
    VULKAN_ALLOCATION_TYPE_IMAGE_OPTIMAL,
};

pub const NeonVkAllocation = struct {
    poolId: u32,
    blockId: u32,
    deviceMemory: u32,
    size: vk.DeviceSize,
    offset: vk.DeviceSize,
    data: ?*anyopaque,
};

pub const NeonVkMemoryBlock = struct {
    id: u32,
    size: vk.DeviceSize,
    offset: vk.DeviceSize,
    prev: ?*NeonVkMemoryBlock,
    next: ?*NeonVkMemoryBlock,
    free: bool,
};

pub const NeonVkMemoryPool = struct {
    head: ?*NeonVkMemoryBlock,
    id: u32,
    nextId: u32,
    memoryTypeIndex: u32,
    hostVisible: bool,
    deviceMemory: vk.DeviceMemory,
    size: vk.DeviceSize,
    allocated: vk.DeviceSize,
    data: ?*anyopaque,

    pub fn make_new_and_maybe_init(
        id: u32,
        memoryTypeBits: u32,
        size: vk.DeviceSize,
        hostVisible: bool,
    ) ?*NeonVkMemoryPool {
        var self = NeonVkMemoryPool{
            .id = id,
            .memoryTypeBits = 0,
            .size = size,
            .hostVisible = hostVisible,
        };

        _ = memoryTypeBits;
        _ = self;

        return null;
    }
};

pub const NeonVkAllocator = struct {
    vki: InstanceDispatch,
    vkb: BaseDispatch,
    vkd: DeviceDispatch,

    dev: vk.Device,
    memoryProperties: vk.PhysicalDeviceMemoryProperties,
    deviceProperties: vk.PhysicalDeviceProperties,

    allocator: std.mem.Allocator,

    nextPoolId: u32,
    garbageIndex: u32,

    deviceLocalMemoryMB: u32,
    hostVisibleMemoryMB: u32,

    pools: ArrayList(*NeonVkMemoryPool),
    garbage: [NUM_FRAMES]ArrayList(NeonVkAllocation),

    pub fn init(
        vki: InstanceDispatch,
        vkb: BaseDispatch,
        vkd: DeviceDispatch,
        dev: vk.Device,
        memoryProperties: vk.PhysicalDeviceMemoryProperties,
        deviceProperties: vk.PhysicalDeviceProperties,
        allocator: std.mem.Allocator,
    ) !NeonVkAllocator {
        var self = NeonVkAllocator{
            .vki = vki,
            .vkb = vkb,
            .vkd = vkd,
            .dev = dev,
            .memoryProperties = memoryProperties,
            .deviceProperties = deviceProperties,
            .allocator = allocator,
            .nextPoolId = 0,
            .garbageIndex = 0,
            .deviceLocalMemoryMB = defaultLocalMemoryPerPoolMB,
            .hostVisibleMemoryMB = defaultHostVisibleMemoryPerPoolMB,
            .pools = ArrayList(*NeonVkMemoryPool).init(allocator),
            .garbage = undefined,
        };

        for (self.garbage) |_, i| {
            self.garbage[i] = ArrayList(NeonVkAllocation).init(self.allocator);
        }

        return self;
    }

    fn find_memory_index_by_type(
        self: NeonVkAllocator,
        memoryTypeBits: u32,
        usage: NeonVkMemoryUsage,
    ) ?u32 {
        var required: vk.MemoryPropertyFlags = .{};
        var preferred: vk.MemoryPropertyFlags = .{};

        switch (usage) {
            .VULKAN_MEMORY_USAGE_GPU_ONLY => {
                preferred.device_local_bit = true;
            },
            .VULKAN_MEMORY_USAGE_CPU_ONLY => {
                required.host_visible_bit = true;
            },
            .VULKAN_MEMORY_USAGE_CPU_TO_GPU => {
                required.host_visible_bit = true;
                preferred.device_local_bit = true;
            },
            .VULKAN_MEMORY_USAGE_GPU_TO_CPU => {
                required.host_visible_bit = true;
                preferred.host_coherent_bit = true;
                preferred.host_cached_bit = true;
            },
            .VULKAN_MEMORY_USAGE_UNKNOWN => {
                // core.graphics_log("Trying to find supported memory usage, this was unsupported {s} ", @tagName(usage));
            },
        }

        // search twice, once for a memory property index that has both preferred and required flags.
        var i: usize = 0;
        while (i < self.memoryProperties.memory_type_count) : (i += 1) {
            if (((memoryTypeBits >> @intCast(u5, i)) & 1) == 0) {
                continue;
            }

            const properties: vk.MemoryPropertyFlags = self.memoryProperties.memory_types[i].property_flags;
            if ((@bitCast(u32, properties) & @bitCast(u32, required)) != @bitCast(u32, required)) {
                continue;
            }

            if ((@bitCast(u32, properties) & @bitCast(u32, preferred)) != @bitCast(u32, required)) {
                continue;
            }

            return @intCast(u32, i);
        }

        // then a second time for both
        i = 0;
        while (i < self.memoryProperties.memory_type_count) : (i += 1) {
            if (((memoryTypeBits >> @intCast(u5, i)) & 1) == 0) {
                continue;
            }

            const properties: vk.MemoryPropertyFlags = self.memoryProperties.memory_types[i].property_flags;
            if ((@bitCast(u32, properties) & @bitCast(u32, required)) != @bitCast(u32, required)) {
                continue;
            }

            return @intCast(u32, i);
        }

        return null;
    }

    pub fn AllocateFromPool(size: u32, alignment: u32, memoryTypeBits: u32, hostVisible: bool) ?NeonVkAllocation {
        var allocation: NeonVkAllocation = undefined;

        _ = size;
        _ = alignment;
        _ = memoryTypeBits;
        _ = hostVisible;

        return allocation;
    }

    pub fn Allocate(
        self: *NeonVkAllocator,
        size: u32,
        alignment: u32,
        memoryTypeBits: u32,
        hostVisible: bool,
    ) !NeonVkAllocation {
        var allocation: ?NeonVkAllocation = AllocateFromPool(
            size,
            alignment,
            memoryTypeBits,
            hostVisible,
        );

        if (allocation != null)
            return allocation.?;

        // failed to allocate from the pool, so we need to create a new pool.
        var poolSize = if (self.hostVisble)
            self.hostVisibleMemoryMB
        else
            self.deviceLocalMemoryMB;

        const newPool = NeonVkMemoryPool.make_new_and_maybe_init(self.nextPoolId, memoryTypeBits, poolSize, hostVisible);
        if (newPool != null) {
            self.pools.append(newPool);
        } else {
            core.graphics_logs("Unable to create new memory pool");
            return error.UnableToAllocateNewMemoryPool;
        }

        return allocation;
    }
};
