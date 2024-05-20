const std = @import("std");
const p2 = @import("p2");

// serialize format of the file:
//
// HeaderOffset(uint64)@0x00
//
//
// Header format
// "pack" @ 0x0 == 0x7061636B

inline fn arrayTo_u32(array: anytype) u32 {
    return @as(*const u32, @ptrCast(@alignCast(&array))).*;
}

inline fn arrayTo_u64(array: anytype) u64 {
    return @as(*const u64, @ptrCast(@alignCast(&array))).*;
}

const PackerMagicBE: u32 = 0x7061636B; // spells out pack in ascii
const PackerMagicLE: u32 = 0x6B636170; // spells out pack in ascii in little endian

// This is used so we can use a single 32 bit compare at the offset to check if we have the correct offset or not.
pub const PackerMagic = if (std.mem.eql(u8, "pack", &@as([4]u8, @bitCast(PackerMagicBE))))
    PackerMagicBE
else
    PackerMagicLE;

pub const littleEndian = if (std.mem.eql(u8, "pack", &@as([4]u8, @bitCast(PackerMagicBE))))
    false
else
    true;

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
    finished: bool = false,

    const PackedFileEntry = struct {
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

        // returns bytes written, not a true serialize function,
        // writes out it's contents as it's meant to be read back to the writer.
        pub fn writeHeader(self: @This(), writer: anytype, elementsCount: u32) !usize {
            var bytesWritten: usize = 0;

            bytesWritten += try writer.write(&@as([8]u8, @bitCast(self.fileOffset + (elementsCount * calculateHeaderLen()) + 8)));
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
    };

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

    // finish building
    pub fn finishBuilding(self: *@This()) !void {
        for (self.headerEntries.items, 0..) |*entry, i| {
            try self.entriesByString.put(self.allocator, entry.getFileName(), i);
        }
        self.finished = true;
    }

    pub fn loadFromReader(self: *@This(), reader: anytype) !void {
        _ = self;

        // read and verify magic
        var magic: [4]u8 align(4) = undefined;
        try p2.assert(try reader.read(&magic) == 4);
        try p2.assert(arrayTo_u32(magic) == PackerMagic);
        std.debug.print("magic = {s}\n", .{magic});
        // read header entries count
        var entriesCount: [4]u8 align(4) = undefined;
        try p2.assert(try reader.read(&entriesCount) == 4);
        std.debug.print("entriesCount = {d}\n", .{arrayTo_u32(entriesCount)});
        // debug print all headers read
    }

    pub fn loadFromFile(self: *@This(), filePath: []const u8) !void {
        // open file for reading
        const file = try std.fs.cwd().openFile(filePath, .{});
        defer file.close();

        try self.loadFromReader(file.reader());
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

            bytes.ptr = @ptrCast(&self.contents.items[header.fileOffset]);
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
