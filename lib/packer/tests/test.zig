const packer = @import("packer");
const testfile = @embedFile("testfile.txt");
const lost_empire = @embedFile("lost_empire.obj");
const monkey = @embedFile("monkey.obj");
const embeddedArchive = @embedFile("archive.pak");
const std = @import("std");

const p2 = @import("p2");

const PackerFS = packer.PackerFS;

test "packer magic test" {
    const magic_as_u8: [4]u8 = @bitCast(packer.PackerMagic);
    std.debug.print("magic = {s}\n", .{magic_as_u8});
    try std.testing.expect(std.mem.eql(u8, &magic_as_u8, "pack"));
}

test "packer forward path" {
    var archive = try packer.PackedArchive.initEmpty(std.testing.allocator);
    defer archive.deinit();

    try archive.appendFileByBytes("raw_bytes", "monkey.obj", monkey);
    try archive.appendFileByBytes("text", "testfile.txt", testfile);
    try archive.appendFileByBytes("mesh", "lost_empire.obj", lost_empire);

    try archive.finishBuilding(false);

    try std.testing.expect(std.mem.eql(u8, monkey, archive.getFileByName("monkey.obj").?.raw_bytes));
    // hmmm

    archive.debugPrintAllFiles();

    try archive.writeToFile("test_output/archive.pak");

    var archive2 = try packer.PackedArchive.initEmpty(std.testing.allocator);
    defer archive2.deinit();

    try archive2.loadFromFile("test_output/archive.pak");

    try std.testing.expect(std.mem.eql(
        u8,
        archive.getFileByName("testfile.txt").?.raw_bytes,
        archive2.getFileByName("testfile.txt").?.raw_bytes,
    ));

    try std.testing.expect(std.mem.eql(
        u8,
        archive.getFileByName("lost_empire.obj").?.raw_bytes,
        archive2.getFileByName("lost_empire.obj").?.raw_bytes,
    ));

    var archive3 = try packer.PackedArchive.initEmpty(std.testing.allocator);
    defer archive3.deinit();

    try archive3.loadFromBytes(embeddedArchive);

    try std.testing.expect(std.mem.eql(
        u8,
        archive.getFileByName("testfile.txt").?.raw_bytes,
        archive3.getFileByName("testfile.txt").?.raw_bytes,
    ));

    const writer = std.io.getStdErr().writer();

    try p2.xxdWrite(writer, archive.getFileByName("lost_empire.obj").?.raw_bytes[0..0x40], .{});

    try std.testing.expect(std.mem.eql(
        u8,
        archive.getFileByName("lost_empire.obj").?.raw_bytes,
        archive3.getFileByName("lost_empire.obj").?.raw_bytes,
    ));

    try std.testing.expect(std.mem.eql(
        u8,
        archive.getFileByName("lost_empire.obj").?.raw_bytes,
        lost_empire,
    ));
}

test "packerfs_test" {
    var fs = try PackerFS.init(std.testing.allocator, .{});
    defer fs.destroy();

    try fs.discoverFromFile("tests/archive.pak");
    try std.testing.expect(fs.countFilesDiscovered() == 3);

    const lost_empire_mapping = try fs.loadFile("lost_empire.obj");
    defer fs.unmap(lost_empire_mapping);

    std.debug.print("mapping len {d} lost_empire len {d}\n", .{ lost_empire_mapping.bytes.len, lost_empire.len });

    const writer = std.io.getStdErr().writer();
    try p2.xxdWrite(writer, lost_empire_mapping.bytes[0..0x40], .{});
    std.debug.print("\n", .{});
    try p2.xxdWrite(writer, lost_empire[0..0x40], .{});

    try std.testing.expect(std.mem.eql(u8, lost_empire_mapping.bytes, lost_empire));

    const lost_empire2 = try fs.loadFile("lost_empire2.obj");
    defer fs.unmap(lost_empire2);

    const lost_empire3 = try fs.loadFile("lost_empire2.obj");
    defer fs.unmap(lost_empire3);

    const lost_empire4 = try fs.loadFile("lost_empire3.obj");
    defer fs.unmap(lost_empire4);

    try p2.xxdWrite(writer, lost_empire2.bytes[0..0x40], .{});

    var subpaths = try fs.listAllSubpaths(std.testing.allocator, "lost_");
    defer subpaths.deinit();

    for (subpaths.data.items) |x| {
        std.debug.print(".[x ] = {s}\n", .{x});
    }

    std.debug.print("littleEndian {any}", .{packer.littleEndian});
}
