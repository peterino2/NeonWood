// this folder contains
const std = @import("std");
const root = @import("root");
const nw = root.neonwood;
const vk = @import("vulkan");

const core = @import("../core.zig");
const graphics = @import("../graphics.zig");
const vkinit = graphics.vkinit;
const vma = @import("vma");

const NeonVkContext = graphics.NeonVkContext;
const NeonVkBuffer = graphics.NeonVkBuffer;
const p2a = core.p_to_a;

const NeonVkAllocator = graphics.NeonVkAllocator;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

// so.. given a single descriptor set:
// 1. create builder
// 2. add buffers for data templates
// 3. finalize and build.

// maybe a better way of doing this:

// NeonGpuObjectBuilder and NeonGpuObject are an abstraction + automation of

// vk.DescriptorSet + vk.Buffer and a way to map them.

// var builder = graphics.NeonGpuObjectBuilder.init(allocator);
// builder.addBuffer(SpriteDataGpu, .objectStorageBuffer);
// builder.addBuffer(CameraDataGpu, .uniform);
// var gpuObject: NeonGpuObject = builder.build();

// TODO: add a way to unmap multiple buffers.. it has been months now. I have no idea what i meant by this.

// ---- Proposed API for implemeting extensions into the game ---

// a GpuPipeData is an API that exists as an API that abstracts both
// vulkan buffer allocation and mapping

pub fn GpuMappingData(comptime ObjectType: type) type {
    return struct {
        raw: GpuMappingRaw,
        objects: []ObjectType, //WARNING! theres a bug do not use this with square operator unless it's a type that's a power of 2
        trueObjectSize: usize,

        pub fn unmap(self: *@This(), gc: *NeonVkContext) void {
            self.raw.unmap(gc);
        }
    };
}

pub const GpuMappingRaw = struct {
    data: []u8,
    allocation: vma.Allocation,

    pub fn unmap(self: *@This(), gc: *NeonVkContext) void {
        gc.vkAllocator.vmaAllocator.unmapMemory(self.allocation);
    }
};

pub const GpuPipeDataBinding = struct {
    // one slot per frame
    buffers: []NeonVkBuffer,
    objectCount: usize,
    objectSize: usize,
    frameCount: usize,
    isFrameBuffer: bool = true,

    pub fn mapBuffers(self: *@This(), gc: *NeonVkContext, comptime MappingType: type) ![]GpuMappingData(MappingType) {
        var frameIndex: usize = 0;
        if (self.isFrameBuffer) {
            try core.assertf(self.frameCount == self.buffers.len, "mismatched frameBuffer {d} != {d}", .{ self.frameCount, self.buffers.len });
        }

        // maps buffers for these bindings, one for each frame
        var rv = try gc.allocator.alloc(GpuMappingData(MappingType), self.buffers.len);
        while (frameIndex < self.buffers.len) : (frameIndex += 1) {
            var data = try gc.vkAllocator.vmaAllocator.mapMemory(self.buffers[frameIndex].allocation, MappingType);
            var mapping: []MappingType = undefined;
            mapping.ptr = @as([*]MappingType, @ptrCast(data));
            mapping.len = self.objectCount;

            var dataMapping: []u8 = undefined;
            dataMapping.ptr = @as([*]u8, @ptrCast(data));
            dataMapping.len = self.objectCount;
            var gpuMappingData: GpuMappingData(MappingType) = .{
                .objects = mapping,
                .trueObjectSize = self.objectSize,
                // .raw = .{ .data = @ptrCast[]u8, mapping), .allocation = self.buffers[frameIndex].allocation },
                .raw = .{ .data = dataMapping, .allocation = self.buffers[frameIndex].allocation },
            };

            rv[frameIndex] = gpuMappingData;
        }

        return rv;
    }

    pub fn deinit(self: *@This(), vkAllocator: *NeonVkAllocator) void {
        for (self.buffers) |*buffers| {
            buffers.deinit(vkAllocator);
        }
    }
};

// High level pipe controls for a gpu data pipe
pub const GpuPipeData = struct {
    allocator: std.mem.Allocator,
    descriptorSetLayout: vk.DescriptorSetLayout,
    bindings: []GpuPipeDataBinding,
    descriptorSets: []vk.DescriptorSet, // one per frame
    descriptorSetLayoutIsAllocated: bool = false,

    pub fn getDescriptorSet(self: @This(), frameIndex: usize) [*]const vk.DescriptorSet {
        return @as([*]const vk.DescriptorSet, @ptrCast(&self.descriptorSets[frameIndex]));
    }

    pub fn init(allocator: std.mem.Allocator, bindingCount: usize, frameCount: usize) !@This() {
        var self = GpuPipeData{
            .descriptorSetLayout = undefined,
            .bindings = try allocator.alloc(GpuPipeDataBinding, bindingCount),
            .descriptorSets = try allocator.alloc(vk.DescriptorSet, frameCount),
            .allocator = allocator,
        };

        for (self.bindings) |*binding| {
            binding.buffers = try allocator.alloc(NeonVkBuffer, frameCount);
            binding.frameCount = frameCount;
        }

        return self;
    }

    // Maps each buffer per frame
    pub fn mapBuffers(self: *@This(), gc: *NeonVkContext, comptime ObjectType: type, binding: usize) ![]GpuMappingData(ObjectType) {
        var pipeDataBuffer = self.bindings[binding];

        return pipeDataBuffer.mapBuffers(gc, ObjectType);
    }

    // pub fn unmapAll(self: *@This(), mappings: anytype);
    pub fn deinit(self: *@This(), allocator: std.mem.Allocator, gc: *NeonVkContext) void {
        if (self.descriptorSetLayoutIsAllocated) {
            gc.vkd.destroyDescriptorSetLayout(gc.dev, self.descriptorSetLayout, null);
        }
        for (self.bindings) |*binding| {
            binding.deinit(gc.vkAllocator);
            allocator.free(binding.buffers);
        }
        allocator.free(self.descriptorSets);
        allocator.free(self.bindings);
    }
};

pub const BindingMode = enum { uniform, storageBuffer };

pub const GpuPipeDataBuilder = struct {
    const BindingObjectInfo = struct {
        objectCount: usize,
        finalObjectSize: usize,
        trueObjectSize: usize,
        bindingMode: BindingMode,
    };

    gc: *NeonVkContext,
    allocator: std.mem.Allocator,

    currentBinding: u32 = 0,
    frameCount: usize = graphics.constants.NUM_FRAMES,
    objectCount: usize = graphics.constants.MAX_OBJECTS,
    bindings: ArrayListUnmanaged(vk.DescriptorSetLayoutBinding) = .{},
    bindingObjectInfos: ArrayListUnmanaged(BindingObjectInfo) = .{},

    pub fn init(allocator: std.mem.Allocator, gc: *NeonVkContext) @This() {
        var self = GpuPipeDataBuilder{
            .allocator = allocator,
            .gc = gc,
        };

        return self;
    }

    pub fn setObjectCount(
        self: *@This(),
        count: usize,
    ) void {
        self.objectCount = count;
    }

    pub fn addBufferBinding(
        self: *@This(),
        comptime BindingType: type,
        descriptorType: vk.DescriptorType,
        stageFlags: vk.ShaderStageFlags,
        bindingMode: BindingMode,
    ) !void {
        var gc = self.gc;
        var binding = vkinit.descriptorSetLayoutBinding(descriptorType, stageFlags, self.currentBinding);

        // core.graphics_log("builder adding additional binding {any} {any} objectSize = {d}", .{ descriptorType, stageFlags, @sizeOf(BindingType) });
        try self.bindings.append(self.allocator, binding);

        var objCount: usize = 1;

        // todo: there is a bug here because this code is incomplete this only accounts for storage buffers and uniforms
        if (descriptorType == .storage_buffer) {
            objCount = self.objectCount;
        }

        var bindingObjectInfo: BindingObjectInfo = .{
            .objectCount = objCount,
            .finalObjectSize = @sizeOf(BindingType),
            .trueObjectSize = @sizeOf(BindingType),
            .bindingMode = bindingMode,
        };

        // uniforms require that the buffer object gets padded to the correct size.
        if (descriptorType != .storage_buffer) {
            bindingObjectInfo.finalObjectSize = gc.pad_uniform_buffer_size(bindingObjectInfo.finalObjectSize);
            core.engine_log("final object size has been padded: {d}", .{bindingObjectInfo.finalObjectSize});
        } else {
            var trueSize: usize = 1;
            while (trueSize < bindingObjectInfo.finalObjectSize) {
                trueSize *= 2;
            }
            bindingObjectInfo.finalObjectSize = trueSize;
            core.engine_log("final object size has been padded as storage: {d}", .{bindingObjectInfo.finalObjectSize});
        }

        try self.bindingObjectInfos.append(self.allocator, bindingObjectInfo);
        self.currentBinding += 1;
    }

    pub fn build(self: *@This(), comptime buildName: []const u8) !GpuPipeData {
        var rv = try GpuPipeData.init(self.allocator, self.bindings.items.len, self.frameCount);
        var gc: *NeonVkContext = self.gc;
        var setInfo = vk.DescriptorSetLayoutCreateInfo{ .binding_count = @as(u32, @intCast(self.bindings.items.len)), .flags = .{}, .p_bindings = self.bindings.items.ptr };
        rv.descriptorSetLayout = try gc.vkd.createDescriptorSetLayout(gc.dev, &setInfo, null);
        rv.descriptorSetLayoutIsAllocated = true;
        core.graphics_log("finalizing build creating descriptor set layout at 0x{x} buildName: {s}", .{ @intFromEnum(rv.descriptorSetLayout), buildName });

        for (rv.descriptorSets, 0..) |_, frameId| {
            var descriptorAllocInfo = vk.DescriptorSetAllocateInfo{
                .descriptor_pool = gc.descriptorPool,
                .descriptor_set_count = 1,
                .p_set_layouts = p2a(&rv.descriptorSetLayout),
            };

            try gc.vkd.allocateDescriptorSets(gc.dev, &descriptorAllocInfo, @as([*]vk.DescriptorSet, @ptrCast(&rv.descriptorSets[frameId])));
        }

        var bindingId: usize = 0;
        while (bindingId < self.bindings.items.len) : (bindingId += 1) {
            var binding = &rv.bindings[bindingId];
            var bindingInfo: BindingObjectInfo = self.bindingObjectInfos.items[bindingId];
            var bindingLayout = self.bindings.items[bindingId];
            _ = bindingLayout;

            core.graphics_log("allocating {d} frame buffers for binding {d} buffer size = {d} object size = {d}", .{ binding.buffers.len, bindingId, bindingInfo.finalObjectSize * bindingInfo.objectCount, bindingInfo.finalObjectSize });

            for (binding.buffers, 0..) |*buffer, frameId| {
                var usageFlags: vk.BufferUsageFlags = .{};
                var memoryFlags: vma.MemoryUsage = .unknown;
                var descriptorType: vk.DescriptorType = .sampler;

                switch (bindingInfo.bindingMode) {
                    .uniform => {
                        usageFlags.uniform_buffer_bit = true;
                        memoryFlags = .cpuToGpu;
                        descriptorType = .uniform_buffer;
                    },
                    .storageBuffer => {
                        usageFlags.storage_buffer_bit = true;
                        memoryFlags = .cpuToGpu;
                        descriptorType = .storage_buffer;
                    },
                }

                buffer.* = try gc.create_buffer(
                    bindingInfo.finalObjectSize * bindingInfo.objectCount,
                    usageFlags,
                    memoryFlags,
                    "GPU binding buffer creation " ++ @src().fn_name ++ ": " ++ buildName,
                );

                var bufferInfo = vk.DescriptorBufferInfo{
                    .buffer = buffer.buffer,
                    .offset = 0,
                    .range = bindingInfo.finalObjectSize * bindingInfo.objectCount,
                };

                var descriptorWrite = vkinit.writeDescriptorSet(
                    descriptorType,
                    rv.descriptorSets[frameId],
                    &bufferInfo,
                    @as(u32, @intCast(bindingId)),
                );
                gc.vkd.updateDescriptorSets(gc.dev, 1, p2a(&descriptorWrite), 0, undefined);
            }
        }

        return rv;
    }

    pub fn deinit(self: *@This()) void {
        self.bindings.deinit(self.allocator);
        self.bindingObjectInfos.deinit(self.allocator);
    }
};
