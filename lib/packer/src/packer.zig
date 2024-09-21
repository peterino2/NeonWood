const std = @import("std");
const p2 = @import("p2");

const PackedFileEntry = @import("PackedFileEntry.zig");

const packerfs = @import("packerfs.zig");
pub const PackerFS = packerfs.PackerFS;

const constants = @import("constants.zig");
pub const PackerMagic = constants.PackerMagic;
pub const littleEndian = constants.littleEndian;

// this is invalidated if a PackedArhive is modified
pub const PackerBytesRef = struct {
    typeTag: []const u8,
    raw_bytes: []const u8,
};

const PackedArchiveContents = std.ArrayListAlignedUnmanaged(u8, 8);

// only responsible for reading and writing archives from disk
// not intended to be the end API
pub const PackedArchive = struct {
    allocator: std.mem.Allocator,
    contents: *PackedArchiveContents,
    // file by convention is little-endian for u32s and u64s
    headerEntries: std.ArrayListUnmanaged(PackedFileEntry),
    entriesByString: std.StringHashMapUnmanaged(usize), // does not get serialized.
    contentBuffer: []const u8 = undefined,
    finished: bool = false,

    pub fn initEmpty(allocator: std.mem.Allocator) !@This() {
        const self: @This() = .{
            .contents = try allocator.create(PackedArchiveContents),
            .allocator = allocator,
            .headerEntries = .{},
            .entriesByString = .{},
        };
        self.contents.* = .{};

        return self;
    }

    pub fn appendFileByBytes(self: *@This(), fileType: []const u8, fileName: []const u8, bytes: []const u8) !void {
        try p2.assert(self.finished != true);
        const writer = self.contents.writer(self.allocator);
        const fileOffset = self.contents.items.len;

        try writer.writeAll(bytes);
        const bytesWritten = bytes.len;

        // if bytes written + fileOffset results in a non-64-bit aligned offset, then we shall pad with zeroes until we hit a 32 bit aligned offset
        const padding = 8 - ((bytesWritten + fileOffset) % 8);
        try writer.writeByteNTimes(0x0, padding);

        const newHeaderEntry = try PackedFileEntry.init(fileType, fileName, fileOffset, @intCast(bytes.len));
        try self.addHeader(newHeaderEntry);
    }

    // finish building, set externalContentData if this contents does NOT contain
    // the actual content data, such as in the case where the content is
    // sent over a network or if the content is embedded with @embedFile
    pub fn finishBuilding(self: *@This(), externalContentData: bool) !void {
        if (!externalContentData) {
            self.contentBuffer = self.contents.items;
        }

        for (self.headerEntries.items, 0..) |*entry, i| {
            try self.entriesByString.put(self.allocator, entry.getFileName(), i);
        }
        self.finished = true;
    }

    fn loadHeadersFromReader(self: *@This(), reader: anytype) !usize {
        var iterator = try PackedFileEntry.ReaderIterator.init(reader);
        while (try iterator.next(reader)) |entry| {
            try self.headerEntries.append(self.allocator, entry);
        }
        return iterator.bytesRead;
    }

    fn loadContentFromReader(self: *@This(), reader: anytype) !usize {
        const writer = self.contents.writer(self.allocator);
        var totalRead: usize = 0;

        var readBuffer: [1024]u8 = undefined;
        var bytesRead = try reader.read(&readBuffer);
        totalRead += bytesRead;
        _ = try writer.write((&readBuffer)[0..bytesRead]);

        while (bytesRead > 0) {
            bytesRead = try reader.read(&readBuffer);
            _ = try writer.write((&readBuffer)[0..bytesRead]);
            totalRead += bytesRead;
        }

        return totalRead;
    }

    fn setContentRefToOffset(self: *@This(), bytes: []const u8, offset: usize) void {
        self.contentBuffer = bytes[offset..];
    }

    pub fn loadFromBytes(self: *@This(), bytes: []const u8) !void {
        try p2.assert(self.finished != true);
        var reader = std.io.fixedBufferStream(bytes);
        const bytesRead = try self.loadHeadersFromReader(&reader);
        self.setContentRefToOffset(bytes, bytesRead);
        try self.finishBuilding(true);
    }

    pub fn loadFromFile(self: *@This(), filePath: []const u8) !void {
        try p2.assert(self.finished != true);
        // open file for reading
        const file = try std.fs.cwd().openFile(filePath, .{});
        defer file.close();

        const reader = file.reader();
        _ = try self.loadHeadersFromReader(reader);
        const contentBytes = try self.loadContentFromReader(reader);

        try self.finishBuilding(false);

        std.debug.print("total content bytes {d}\n", .{contentBytes});
    }

    pub fn writeToFile(self: @This(), filePath: []const u8) !void {

        // create file
        const file = try p2.createFileWithPath(filePath);
        defer file.close();

        const writer = file.writer();
        // write out pack magic and number of header elements to indicate start of file.
        try writer.writeAll(&@as([4]u8, @bitCast(PackerMagic)));
        try writer.writeAll(&@as([4]u8, @bitCast(
            @as(
                u32,
                @intCast(self.headerEntries.items.len),
            ),
        )));

        var headerSize: usize = 0;

        for (self.headerEntries.items) |entry| {
            headerSize += try entry.writeHeader(writer, @intCast(self.headerEntries.items.len));
        }

        std.debug.print("total header size = {d}\n", .{headerSize});

        // write out contents buffer,
        try writer.writeAll(self.contents.items);
    }

    pub fn addHeader(self: *@This(), fileEntry: PackedFileEntry) !void {
        try self.headerEntries.append(self.allocator, fileEntry);
    }

    pub fn updateHeaderOffset(self: @This(), offset: u64) void {
        const p = @as(*u64, @ptrCast(@alignCast(self.contents.items.ptr)));
        p.* = offset;
    }

    pub fn debugPrintAllFiles(self: @This()) void {
        for (self.headerEntries.items) |entry| {
            std.debug.print("> {s}({s}, size = {d} bytes)\n", .{
                entry.getFileName(),
                entry.getTypeName(),
                entry.fileLen,
            });
        }

        std.debug.print("totalContentSize = {d}\n", .{
            self.contents.items.len - 8,
        });
    }

    // only used for debugging or while generating a PackerFileSystem.
    //
    // using a PackerFileSystem is the better method of getting file contents
    pub fn getFileByName(self: *@This(), fileName: []const u8) ?PackerBytesRef {
        if (!self.finished) {
            return null;
        }

        if (self.entriesByString.get(fileName)) |entryOffset| {
            const header = &self.headerEntries.items[entryOffset];
            var bytes: []const u8 = undefined;

            bytes.ptr = @ptrCast(&self.contentBuffer[header.fileOffset]);
            bytes.len = header.fileLen;

            return .{
                .typeTag = header.getTypeName(),
                .raw_bytes = bytes,
            };
        }

        return null;
    }

    pub fn deinit(self: *@This()) void {
        self.contents.deinit(self.allocator);
        self.headerEntries.deinit(self.allocator);
        if (self.finished) {
            self.entriesByString.deinit(self.allocator);
        }
        self.allocator.destroy(self.contents);
    }
};

fn loadHeadersFromReader(self: *@This(), reader: anytype) !usize {
    var bytesRead: usize = 0;
    // read and verify magic
    var magic: [4]u8 align(4) = undefined;
    try p2.assert(try reader.read(&magic) == 4);
    try p2.assert(p2.arrayTo_u32(magic) == PackerMagic);
    std.debug.print("magic = {s}\n", .{magic});
    bytesRead += 4;

    // read header entries count
    var entriesCount_read: [4]u8 align(4) = undefined;
    try p2.assert(try reader.read(&entriesCount_read) == 4);
    const entriesCount = p2.arrayTo_u32(entriesCount_read);
    std.debug.print("entriesCount = {d}\n", .{entriesCount});
    bytesRead += 4;

    for (0..entriesCount) |_| {
        const newEntry = try self.headerEntries.addOne(self.allocator);
        try newEntry.loadFromReader(reader);
        bytesRead += PackedFileEntry.calculateHeaderLen();
    }

    return bytesRead;
}
