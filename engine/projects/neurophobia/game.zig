// this folder contains
const std = @import("std");
const root = @import("root");
const nw = root.neonwood;
const vk = @import("vulkan");

const core = nw.core;
const graphics = nw.graphics;
const vkinit = graphics.vkinit;
const vma = @import("vma");

const NeonVkContext = graphics.NeonVkContext;
const NeonVkBuffer = graphics.NeonVkBuffer;
const p2a = core.p_to_a;

const ArrayListUnmanaged = std.ArrayListUnmanaged;

// so.. given a single descriptor set:
// 1. create builder
// 2. add buffers for data templates
// 3. finalize and build.

// maybe a better way of doing this:

// NeonGpuObjectBuilder and NeonGpuObject are an abstraction + automation of

// vk.DescriptorSet + vk.Buffer

// var builder = graphics.NeonGpuObjectBuilder.init(allocator);
// builder.addBuffer(SpriteDataGpu, .objectStorageBuffer);
// builder.addBuffer(CameraDataGpu, .uniform);
// var gpuObject: NeonGpuObject = builder.build();

// ---- Proposed API for implemeting extensions into the game ---

// a GpuPipeData is an API that exists as an API that abstracts both
// vulkan buffer allocation and

pub fn GpuMappingData(comptime ObjectType: type) type {
    return struct {
        raw: GpuMappingRaw,
        objects: []ObjectType,

        pub fn unmap(self: *@This(), gc: *NeonVkContext) void {
            self.raw.unmap(gc);
        }
    };
}

pub const GpuMappingRaw = struct {
    data: []u8,
    allocation: vma.Allocation,

    pub fn unmap(self: *@This(), gc: *NeonVkContext) void {
        gc.vmaAllocator.unmapMemory(self.allocation);
    }
};

pub const GpuPipeDataBinding = struct {
    // one slot per frame
    descriptorSets: []vk.DescriptorSet,
    buffers: []NeonVkBuffer,
    objectCount: usize,
    objectSize: usize,
    frameCount: usize,
    isFrameBuffer: bool = true,

    pub fn getDescriptorSet(self: @This(), frameIndex: usize) [*]const vk.DescriptorSet
    {
        return @ptrCast([*]const vk.DescriptorSet, &self.descriptorSets[frameIndex]);
    }

    pub fn mapBuffers(self: *@This(), gc: *NeonVkContext, comptime MappingType: type) ![]GpuMappingData(MappingType) {
        var frameIndex: usize = 0;
        if(self.isFrameBuffer)
        {
            try core.assertf(self.frameCount == self.buffers.len, "mismatched frameBuffer", .{});
        }
        // maps buffers for these bindings, one for each frame
        var rv = try gc.allocator.alloc(GpuMappingData(MappingType), self.buffers.len);
        while (frameIndex < self.buffers.len) : (frameIndex += 1) {
            var data = try gc.vmaAllocator.mapMemory(self.buffers[frameIndex].allocation, MappingType);
            var mapping: []MappingType = undefined;
            mapping.ptr = @ptrCast([*]MappingType, data);
            mapping.len = self.objectCount;

            var gpuMappingData: GpuMappingData(MappingType) = .{
                .objects = mapping,
                .raw = .{ .data = @ptrCast([]u8, mapping), .allocation = self.buffers[frameIndex].allocation },
            };

            rv[frameIndex] = gpuMappingData;
        }

        return rv;
    }
};

pub const GpuPipeData = struct {
    allocator: std.mem.Allocator,
    descriptorSetLayout: vk.DescriptorSetLayout,
    bindings: []GpuPipeDataBinding,

    pub fn init(allocator: std.mem.Allocator, bindingCount: usize, frameCount: usize) !@This() {
        var self = GpuPipeData{
            .descriptorSetLayout = undefined,
            .bindings = try allocator.alloc(GpuPipeDataBinding, bindingCount),
            .allocator = allocator,
        };

        for (self.bindings) |*binding| {
            binding.buffers = try allocator.alloc(NeonVkBuffer, frameCount);
            binding.descriptorSets = try allocator.alloc(vk.DescriptorSet, frameCount);
        }

        return self;
    }

    // Maps each buffer per frame
    pub fn mapBuffers(self: *@This(), gc: *NeonVkContext, comptime ObjectType: type, binding: usize) ![]GpuMappingData(ObjectType) {
        _ = self;
        _ = ObjectType;
        _ = binding;
        var pipeDataBuffer = self.bindings[binding];

        return pipeDataBuffer.mapBuffers(gc, ObjectType);
    }

    // pub fn unmapAll(self: *@This(), mappings: anytype);
    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        allocator.free(self.buffers);
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

    pub fn addBufferBinding(
        self: *@This(),
        comptime BindingType: type,
        descriptorType: vk.DescriptorType,
        stageFlags: vk.ShaderStageFlags,
        bindingMode: BindingMode,
    ) !void {
        var gc = self.gc;
        var binding = vkinit.descriptorSetLayoutBinding(descriptorType, stageFlags, self.currentBinding);
        core.graphics_log("builder adding additional binding {any} {any}", .{ descriptorType, stageFlags });
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
        }

        try self.bindingObjectInfos.append(self.allocator, bindingObjectInfo);
        self.currentBinding += 1;
    }

    pub fn build(self: *@This()) !GpuPipeData {
        var rv = try GpuPipeData.init(self.allocator, self.bindings.items.len, self.frameCount);
        var gc: *NeonVkContext = self.gc;
        var setInfo = vk.DescriptorSetLayoutCreateInfo{ .binding_count = @intCast(u32, self.bindings.items.len), .flags = .{}, .p_bindings = self.bindings.items.ptr };
        rv.descriptorSetLayout = try gc.vkd.createDescriptorSetLayout(gc.dev, &setInfo, null);
        core.graphics_log("finalizing build", .{});

        var bindingId: usize = 0;
        while (bindingId < self.bindings.items.len) : (bindingId += 1) {
            var binding = &rv.bindings[bindingId];
            var bindingInfo: BindingObjectInfo = self.bindingObjectInfos.items[bindingId];
            var bindingLayout = self.bindings.items[bindingId];
            _ = bindingLayout;

            core.graphics_log("allocating {d} frame buffers for binding {d}", .{ binding.buffers.len, bindingId });
            for (binding.buffers) |*buffer, frameId| {
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
                );

                var descriptorAllocInfo = vk.DescriptorSetAllocateInfo{
                    .descriptor_pool = gc.descriptorPool,
                    .descriptor_set_count = 1,
                    .p_set_layouts = p2a(&rv.descriptorSetLayout),
                };

                try gc.vkd.allocateDescriptorSets(gc.dev, &descriptorAllocInfo, @ptrCast([*]vk.DescriptorSet, &binding.descriptorSets[frameId]));

                var bufferInfo = vk.DescriptorBufferInfo {
                    .buffer = buffer.buffer,
                    .offset = 0,
                    .range = bindingInfo.finalObjectSize * bindingInfo.objectCount,
                };

                var descriptorWrite = vkinit.writeDescriptorSet(
                    descriptorType,
                    binding.descriptorSets[frameId],
                    &bufferInfo,
                    @intCast(u32, bindingId),
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

    // 2. buffer allocation and write descriptions
};
