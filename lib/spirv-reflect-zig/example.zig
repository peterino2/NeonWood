// Copyright (c) peterino2@github.com

const std = @import("std");
const test_vk = @import("test_vk");

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const zout = bw.writer();

    try zout.print("\n\nHello World!\n\nThis is a sample program using reflected type info from\n", .{});
    try zout.print("the shader in `test_shaders/test_vk.vert`\n\n", .{});
    try zout.print("sizeOf {s} == {d}\n", .{ @typeName(test_vk.ImageRenderData), @sizeOf(test_vk.ImageRenderData) });
    try zout.print("The following fields, types and offsets are in {s}:\n", .{@typeName(test_vk.ImageRenderData)});
    for (test_vk.ImageRenderData.FieldDetails) |field| {
        try zout.print("  name={s}, offset={d}, size={d}\n", .{ field.name, field.offset, field.size });
    }
    try bw.flush();
}
