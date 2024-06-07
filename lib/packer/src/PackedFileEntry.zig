const std = @import("std");
const p2 = @import("p2");

const constants = @import("constants.zig");
const PackedFileEntry = @This();

fileOffset: u64,
fileLen: u64,

fileNameLen: u32,

typeLen: u32,

fileName: [128]u8 = std.mem.zeroes([128]u8), // 128 bytes, zero-init because zeros are written to file for padding
typeName: [32]u8 = std.mem.zeroes([32]u8), // 32 bytes, zero-init because zeros are written to file for padding
//
pub fn init(typeName: []const u8, fileName: []const u8, fileOffset: u64, fileLen: u64) !@This() {
    var self = @This(){
        .fileLen = fileLen,
        .fileOffset = fileOffset,

        .fileNameLen = @intCast(fileName.len),

        .typeLen = @intCast(typeName.len),
    };

    _ = try std.fmt.bufPrint(&self.fileName, "{s}", .{fileName});
    _ = try std.fmt.bufPrint(&self.typeName, "{s}", .{typeName});

    return self;
}

// todo make this a comptime, when i land and I am able to
// find out how comptime allocator interface looks.
pub fn calculateHeaderLen() usize {
    // TODO
    return 184;
}

pub fn loadFromReader(self: *@This(), reader: anytype) !void {
    var bytesRead: usize = 0;
    bytesRead += try reader.read(p2.u64_to_slice(&self.fileOffset));
    bytesRead += try reader.read(p2.u64_to_slice(&self.fileLen));
    bytesRead += try reader.read(p2.u32_to_slice(&self.fileNameLen));
    bytesRead += try reader.read(p2.u32_to_slice(&self.typeLen));

    bytesRead += try reader.read(&self.fileName);
    bytesRead += try reader.read(&self.typeName);

    std.debug.assert(bytesRead == calculateHeaderLen());

    std.debug.print("header deserialized {s} type: {s} fileOffset:{d} \n", .{ self.getFileName(), self.getTypeName(), self.fileOffset });
}

// returns bytes written, not a true serialize function,
// writes out it's contents as it's meant to be read back to the writer.
pub fn writeHeader(self: @This(), writer: anytype, elementsCount: u32) !usize {
    _ = elementsCount;
    var bytesWritten: usize = 0;

    bytesWritten += try writer.write(&@as([8]u8, @bitCast(self.fileOffset)));
    bytesWritten += try writer.write(&@as([8]u8, @bitCast(self.fileLen)));

    bytesWritten += try writer.write(&@as([4]u8, @bitCast(self.fileNameLen)));
    bytesWritten += try writer.write(&@as([4]u8, @bitCast(self.typeLen)));

    bytesWritten += try writer.write(&self.fileName);
    bytesWritten += try writer.write(&self.typeName);

    std.debug.assert(bytesWritten % 8 == 0);

    std.debug.print("{s} serialized {d} bytes\n", .{ self.getFileName(), bytesWritten });

    return bytesWritten;
}

pub fn getTypeName(self: *const @This()) []const u8 {
    var slice: []const u8 = undefined;

    slice.ptr = @ptrCast(&self.typeName);
    slice.len = self.typeLen;

    return slice;
}

pub fn getFileName(self: *const @This()) []const u8 {
    var slice: []const u8 = undefined;

    slice.ptr = @ptrCast(&self.fileName);
    slice.len = self.fileNameLen;

    return slice;
}

pub const ReaderIterator = struct {
    totalCount: u32,
    readCount: u32 = 0,
    bytesRead: u64,
    finished: bool = false,

    // this iterator becomes invalidated if anythign else modifies
    // the iterator is finished
    pub fn init(reader: anytype) !@This() {
        var bytesRead: usize = 0;

        // read and verify magic
        var magic: [4]u8 align(4) = undefined;
        try p2.assert(try reader.read(&magic) == 4);
        try p2.assert(p2.arrayTo_u32(magic) == constants.PackerMagic);
        bytesRead += 4;

        // read the number of header entries
        var entriesCount_read: [4]u8 align(4) = undefined;
        try p2.assert(try reader.read(&entriesCount_read) == 4);
        const entriesCount = p2.arrayTo_u32(entriesCount_read);
        std.debug.print("entriesCount = {d}\n", .{entriesCount});
        bytesRead += 4;

        return .{
            .bytesRead = bytesRead,
            .totalCount = entriesCount,
        };
    }

    pub fn next(self: *@This(), reader: anytype) !?PackedFileEntry {
        std.debug.print("readCount = {d}\n", .{self.readCount});
        if (self.readCount == self.totalCount)
            return null;

        var newEntry: PackedFileEntry = undefined;
        try newEntry.loadFromReader(reader);
        self.bytesRead += PackedFileEntry.calculateHeaderLen();
        self.readCount += 1;

        return newEntry;
    }
};
