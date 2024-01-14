const std = @import("std");
const platform = @import("../platform.zig");
const c = @import("glad_c.zig");
const core = @import("../core.zig");

pub fn init(allocator: std.mem.Allocator) !*@This() {
    _ = allocator;
}

pub fn tick(self: *@This(), dt: f64) void {
    _ = dt;
    _ = self;
}

pub fn start(allocator: std.mem.Allocator) void {
    _ = allocator;
    core.graphics_logs("loading GLES 2.0 with GLAD");
    _ = c.gladLoadGLES2Loader(@ptrCast(&platform.c.glfwGetProcAddress));
}

pub fn shutdown(allocator: std.mem.Allocator) void {
    _ = allocator;
}
