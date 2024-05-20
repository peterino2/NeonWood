const packer = @import("packer");
const testFile = @embedFile("testFile.txt");
const lost_empire = @embedFile("lost_empire.obj");
const test_zig = @embedFile("test.zig");
const std = @import("std");

test "packer magic test" {
    const magic_as_u8: [4]u8 = @bitCast(packer.PackerMagic);
    std.debug.print("magic = {s}\n", .{magic_as_u8});
    try std.testing.expect(std.mem.eql(u8, &magic_as_u8, "pack"));
}

test "packer forward path" {
    var archive = try packer.PackedArchive.initEmpty(std.testing.allocator);
    defer archive.deinit();

    try archive.appendFileByBytes("raw_bytes", "testfiles/test/test.zig", test_zig);
    try archive.appendFileByBytes("text", "testFile.txt", testFile);
    try archive.appendFileByBytes("mesh", "lost_empire.obj", lost_empire);

    try archive.finishBuilding();

    try std.testing.expect(std.mem.eql(u8, test_zig, archive.getFileByName("testfiles/test/test.zig").?.raw_bytes));

    archive.debugPrintAllFiles();

    try archive.writeToFile("test_output/archive.pak");
}
