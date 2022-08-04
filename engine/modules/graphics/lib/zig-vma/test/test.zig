const vk = @import("vk");
const vma = @import("vma");
const std = @import("std");

test "vma" {
    const instance = try vk.CreateInstance(.{}, null);
    defer vk.DestroyInstance(instance, null);

    var physDevice: vk.PhysicalDevice = .Null;
    _ = try vk.EnumeratePhysicalDevices(instance, @as(*[1]vk.PhysicalDevice, &physDevice));
    if (physDevice == .Null) return error.NoDevicesAvailable;

    const device = try vk.CreateDevice(physDevice, .{
        .queueCreateInfoCount = 1,
        .pQueueCreateInfos = &[_]vk.DeviceQueueCreateInfo{ .{
            .queueFamilyIndex = 0,
            .queueCount = 1,
            .pQueuePriorities = &[_]f32{ 1.0 },
        } },
    }, null);
    defer vk.DestroyDevice(device, null);

    const functions = vma.VulkanFunctions.init(instance, device, vk.vkGetInstanceProcAddr);

    const allocator = try vma.Allocator.create(.{
        .instance = instance,
        .physicalDevice = physDevice,
        .device = device,
        .frameInUseCount = 3,
        .pVulkanFunctions = &functions,
    });
    defer allocator.destroy();
}

test "Compile everything" {
    @setEvalBranchQuota(10000);
    compileEverything(vma);
}

fn compileEverything(comptime Outer: type) void {
    inline for (comptime std.meta.declarations(Outer)) |decl| {
        if (decl.is_pub) {
            const T = @TypeOf(@field(Outer, decl.name));
            if (T == type) {
                switch (@typeInfo(@field(Outer, decl.name))) {
                    .Struct,
                    .Enum,
                    .Union,
                    .Opaque,
                    => compileEverything(@field(Outer, decl.name)),
                    else => {},
                }
            }
        }
    }
}