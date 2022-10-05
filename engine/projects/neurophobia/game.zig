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
        allocation: vma.Allocation,
        objects: []ObjectType,
    };
}

pub const GpuPipeDataBuffer = struct {
    // one slot per frame
    descriptorSets: []vk.DescriptorSet,
    buffers: []NeonVkBuffer,
};

pub const GpuPipeData = struct {
    allocator: std.mem.Allocator,
    descriptorSetLayout: vk.DescriptorSetLayout,
    bindings: []GpuPipeDataBuffer,

    pub fn init(allocator: std.mem.Allocator, bindingCount: usize, frameCount: usize) !@This() {
        var self = GpuPipeData{
            .descriptorSetLayout = undefined,
            .bindings = try allocator.alloc(GpuPipeDataBuffer, bindingCount),
            .allocator = allocator,
        };

        for (self.bindings) |*binding| {
            binding.buffers = try allocator.alloc(NeonVkBuffer, frameCount);
            binding.descriptorSets = try allocator.alloc(vk.DescriptorSet, frameCount);
        }

        return self;
    }

    // pub fn bindDescriptorToSlot()

    // Maps each buffer per frame
    // pub fn mapBuffers(self: *@This(), comptime ObjectType: type) ![]GpuMappingData
    // pub fn unmapAll(self: *@This(), mappings: []GpuMappingData);

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

        var i: usize = 0;
        while (i < self.bindings.items.len) : (i += 1) {
            var binding = &rv.bindings[i];
            var bindingInfo: BindingObjectInfo = self.bindingObjectInfos.items[i];
            var bindingLayout = self.bindings.items[i];
            _ = bindingLayout;

            core.graphics_log("allocating {d} frame buffers for binding {d}", .{ binding.buffers.len, i });
            for (binding.buffers) |*buffer| {
                var usageFlags: vk.BufferUsageFlags = .{};
                var memoryFlags: vma.MemoryUsage = .unknown;

                switch (bindingInfo.bindingMode) {
                    .uniform => {
                        usageFlags.uniform_buffer_bit = true;
                        memoryFlags = .cpuToGpu;
                    },
                    .storageBuffer => {
                        usageFlags.storage_buffer_bit = true;
                        memoryFlags = .cpuToGpu;
                    },
                }

                buffer.* = try gc.create_buffer(
                    bindingInfo.finalObjectSize * bindingInfo.objectCount,
                    usageFlags,
                    memoryFlags,
                );
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
