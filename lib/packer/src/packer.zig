const std = @import("std");

// serialize format of the file:
//
// HeaderOffset(uint64)@0x00
//
//
// Header format
// "pack" @ 0x0 == 0x7061636B

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
    //
    // layout of packedArchiveContents
    // 0x0 - 0x8                                                    : headerOffset
    // 0x8 - headerOffset                                           : fileContents
    // headerOffset - headerOffset + (headerOffset + 0x4 as u32)    : archiveHeader, header tracks it's length
    //
    // layout of archiveHeader
    // 0x0 - 0x4                                                : headerMagic
    // 0x4 - 0x8                                                : headerLength
    // 0x8 - 0x12                                               : checksum/status (filled with 0xCCCCCCCC during writing)
    // 0x12 - 0x16                                              : entriesCount
    // 0x16 - 0x16 + entriesCount * sizeOf(archiveHeaderEntry)  : [entriesCount] archiveHeaderEntry
    //
    // layout of archiveHeaderEntry
    // 16,8                        : archiveOffset + len
    // 4, 4                        : nameHash (cityHash of string)
    // 4, 4                        : nameLength
    // 4, 4                        : typeHash (cityHash of header)
    // 4, 4                        : typelength
    // 128, 1                      : name
    // 32, 1                       : type
    //
    // 184 bytes per entry...
    //
    // some sample asset paths
    //
    // basegame/weapons/guns/shotgun/skeleton/base_skeleton - 52 bytes
    // developers/peter/sample/testing/story/main_region/main_region - 61 bytes
    //
    // knowing specifically what I know about a really large AAA game, something like that one world map is like 130,000 files in the archive
    //
    // 130,000 assets * 136 = 16 MiB in header info... not too bad...
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
        const writer = self.contents.writer(self.allocator);
        // write in some initial stuff
        const initialOffset: u64 = 0x8;
        _ = try writer.write(&@as([8]u8, @bitCast(initialOffset)));

        return self;
    }

    pub fn appendFileByBytes(self: *@This(), fileType: []const u8, fileName: []const u8, bytes: []const u8) !void {
        const writer = self.contents.writer(self.allocator);
        const fileOffset = self.readHeaderOffset(); // offset in contents, that the file will be written into

        try writer.writeAll(bytes);
        const bytesWritten = bytes.len;

        // if bytes written + fileOffset results in a non-64-bit aligned offset, then we shall pad with zeroes until we hit a 32 bit aligned offset
        const padding = 8 - ((bytesWritten + fileOffset) % 8);
        try writer.writeByteNTimes(0x0, padding);

        const newHeaderOffset = fileOffset + bytesWritten + padding;

        const newHeaderEntry = try PackedFileEntry.init(fileType, fileName, fileOffset, @intCast(bytes.len));
        try self.addHeader(newHeaderEntry);

        self.updateHeaderOffset(newHeaderOffset);
    }

    // finish building
    pub fn finishBuilding(self: *@This()) !void {
        for (self.headerEntries.items, 0..) |*entry, i| {
            try self.entriesByString.put(self.allocator, entry.getFileName(), i);
        }
        self.finished = true;
    }

    pub fn addHeader(self: *@This(), fileEntry: PackedFileEntry) !void {
        try self.headerEntries.append(self.allocator, fileEntry);
    }

    pub fn updateHeaderOffset(self: @This(), offset: u64) void {
        const p = @as(*u64, @ptrCast(@alignCast(self.contents.items.ptr)));
        p.* = offset;
    }

    pub fn readHeaderOffset(self: @This()) u64 {
        return @as(*u64, @ptrCast(@alignCast(self.contents.items.ptr))).*;
    }

    pub fn debugPrintAllFiles(self: @This()) void {
        for (self.headerEntries.items) |entry| {
            std.debug.print("> {s}({s}, size = {d} bytes)\n", .{
                entry.getFileName(),
                entry.getTypeName(),
                entry.fileLen,
            });
        }

        std.debug.print("headerOffset = {d} totalContentSize = {d}\n", .{
            self.readHeaderOffset(),
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
