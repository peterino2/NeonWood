// simple wrapper around vma with a very slow debug mode that
// shows every single vma event
//
// BECAUSE I CAN'T FIND WHERE I FAILED TO DESTROY SOME MEMORY.

const std = @import("std");
const vk = @import("vulkan");
const vma = @import("vma");
const core = @import("core");
const memory = core.MemoryTracker;
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
    size: usize,

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
    mutex: std.Thread.Mutex = .{},
    vmaAllocator: vma.Allocator,
    allocator: std.mem.Allocator,
    eventsList: std.ArrayList(AllocationEvent),
    liveAllocations: std.ArrayList(LiveAlloc),
    livePipelines: std.AutoHashMap(u64, []u8),
    vkb: vk_constants.BaseDispatch,
    vki: vk_constants.InstanceDispatch,
    vkd: vk_constants.DeviceDispatch,

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
        const bci = vk.BufferCreateInfo{
            .flags = .{},
            .size = bufferSize,
            .usage = .{ .transfer_src_bit = true },
            .sharing_mode = .exclusive,
            .queue_family_index_count = 0,
            .p_queue_family_indices = undefined,
        };

        const vmaCreateInfo = vma.AllocationCreateInfo{
            .flags = .{},
            .usage = .cpuOnly,
        };

        return self.createBuffer(bci, vmaCreateInfo, tag);
    }

    pub fn createPipelineLayout(self: *@This(), dev: vk.Device, plci: vk.PipelineLayoutCreateInfo, tag: []const u8) !vk.PipelineLayout {
        const pipelineLayout = try self.vkd.createPipelineLayout(dev, &plci, null);

        try self.livePipelines.put(@intFromEnum(pipelineLayout), try core.dupeString(self.allocator, tag));
        // core.graphics_log("constructing pipeline at @0x{x} tag: {s}", .{ @intFromEnum(pipelineLayout), tag });

        return pipelineLayout;
    }

    pub fn destroyPipelineLayout(self: *@This(), dev: vk.Device, layout: vk.PipelineLayout) void {
        self.allocator.free(self.livePipelines.get(@intFromEnum(layout)).?);
        _ = self.livePipelines.remove(@intFromEnum(layout));
        self.vkd.destroyPipelineLayout(dev, layout, null);
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
        const bci = vk.BufferCreateInfo{
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

        const vmaCreateInfo = vma.AllocationCreateInfo{
            .flags = .{},
            .usage = .gpuOnly,
        };

        return self.createBuffer(bci, vmaCreateInfo, tag);
    }

    pub fn create(
        vmaAllocatorCreateInfo: vma.AllocatorCreateInfo,
        allocator: std.mem.Allocator,
        vkb: vk_constants.BaseDispatch,
        vki: vk_constants.InstanceDispatch,
        vkd: vk_constants.DeviceDispatch,
    ) !*@This() {
        const newAllocator = try allocator.create(@This());

        newAllocator.* = @This(){
            .vmaAllocator = try vma.Allocator.create(vmaAllocatorCreateInfo),
            .allocator = allocator,
            .eventsList = std.ArrayList(AllocationEvent).init(allocator),
            .liveAllocations = std.ArrayList(LiveAlloc).init(allocator),
            .livePipelines = std.AutoHashMap(u64, []u8).init(allocator),
            .vkb = vkb,
            .vki = vki,
            .vkd = vkd,
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
            core.engine_log("We have a big issue here, a destroy was issued for allocation {any}\n But it is not alive", .{allocation});
            self.printOutStandingAllocations();
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
        self.mutex.lock();
        defer self.mutex.unlock();
        const results = try self.vmaAllocator.createBuffer(bci, aci);

        const object: AllocatedObject = .{
            .buffer = NeonVkBuffer{
                .buffer = results.buffer,
                .allocation = results.allocation,
                .size = bci.size,
            },
        };

        memory.MTAddUntrackedAllocation(bci.size);
        try self.pushAllocation(results.allocation, tag, object);

        return object.buffer;
    }

    pub fn destroyBuffer(self: *@This(), buffer: *NeonVkBuffer) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        memory.MTRemoveAllocation(buffer.size);

        self.pushDestroy(buffer.allocation);
        self.vmaAllocator.destroyBuffer(buffer.buffer, buffer.allocation);
    }

    pub fn destroyImage(self: *@This(), image: *NeonVkImage) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.pushDestroy(image.allocation);
        self.vmaAllocator.destroyImage(image.image, image.allocation);
    }

    pub fn createImage(
        self: *@This(),
        ici: vk.ImageCreateInfo,
        aci: AllocationCreateInfo,
        comptime tag: []const u8,
    ) !NeonVkImage {
        self.mutex.lock();
        defer self.mutex.unlock();
        const result = try self.vmaAllocator.createImage(ici, aci);

        const object: AllocatedObject = .{ .image = .{
            .image = result.image,
            .allocation = result.allocation,
            .pixelWidth = ici.extent.width,
            .pixelHeight = ici.extent.height,
        } };

        try self.pushAllocation(result.allocation, tag, object);

        return object.image;
    }

    pub fn mapBuffer(self: *@This(), comptime T: type, buffer: NeonVkBuffer) ![]T {
        var slice: []T = undefined;
        slice.ptr = try self.mapMemory(buffer, T);
        slice.len = buffer.size / @sizeOf(T);
        return slice;
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

    pub fn areAllocationsOutstanding(self: *@This()) bool {
        return self.liveAllocations.items.len > 0;
    }

    pub fn printOutStandingAllocations(self: *@This()) void {
        core.graphics_log(" == There are {d} allocations outstanding", .{self.liveAllocations.items.len});

        for (self.liveAllocations.items) |alloc| {
            core.graphics_log("live allocation@{d} tag:\'{s}\' {any}", .{ alloc.allocation, alloc.tag, alloc.object });
        }

        core.graphics_logs("--- Event log below --- ");

        self.printEventsLog();
        core.graphics_logs("end of report.");
        core.forceFlush();
    }

    pub fn destroy(self: *@This()) void {
        self.eventsList.deinit();
        self.liveAllocations.deinit();
        {
            var iter = self.livePipelines.iterator();
            while (iter.next()) |i| {
                self.allocator.free(i.value_ptr.*);
            }
        }

        self.livePipelines.deinit();
        self.vmaAllocator.destroy();
        self.allocator.destroy(self);
    }
};
