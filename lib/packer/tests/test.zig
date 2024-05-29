const packer = @import("packer");
const testFile = @embedFile("testFile.txt");
const lost_empire = @embedFile("lost_empire.obj");
const monkey = @embedFile("monkey.obj");
const embeddedArchive = @embedFile("archive.pak");
const std = @import("std");

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
    try archive.appendFileByBytes("text", "testFile.txt", testFile);
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
        archive.getFileByName("testFile.txt").?.raw_bytes,
        archive2.getFileByName("testFile.txt").?.raw_bytes,
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
        archive.getFileByName("testFile.txt").?.raw_bytes,
        archive3.getFileByName("testFile.txt").?.raw_bytes,
    ));

    try std.testing.expect(std.mem.eql(
        u8,
        archive.getFileByName("lost_empire.obj").?.raw_bytes,
        archive3.getFileByName("lost_empire.obj").?.raw_bytes,
    ));

    const file = std.fs.cwd().openFile("tests/archive.pak", .{});
    defer file.close();

    const mapped_mem = try std.c.mmap(
        null,
        embeddedArchive.len,
        std.posix.PROT.READ,
        std.posix.MAP.SHARED,
        file,
        null,
    );
    defer std.posix.munmap(mapped_mem);
    try std.testing.expect(u8, embeddedArchive, mapped_mem);
}

test "packerfs_test" {
    const fs = try PackerFS.init(std.testing.allocator);
    defer fs.destroy();

    try fs.discoverFromFile("tests/archive.pak");
    try std.testing.expect(fs.countFilesDiscovered() == 3);

    const lost_empire_mapping = try fs.loadFileByPath();
    defer fs.unmap(lost_empire_mapping);
}
