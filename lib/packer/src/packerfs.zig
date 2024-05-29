// packerfs
//
// think of it as a single large file system archive
//
// that allows you to mount and unmount multiple packer files into memory.
// as well as discover files from a pak which aren't yet fully mounted, and
// keep track of them in a registry.
//
// hmm... how does one handle memory mapping.
//
// packerfs is the main way that we should be accessing files,
//
// when a file is discovered into the registry. we gain the option to load the file
// when we load the file it is mmapped into memory at an address and the pointer to bytes in the file is returned
//
// version 1:
// - I discover files from paks
// - I want a file, I ask for that file.
// - I get back a mapping struct which contains a []const u8 bytes struct
//      - this bytes struct tracks which archive it came from
// - When I am done with the bytes, I unmap the mapping struct

const std = @import("std");
const p2 = @import("p2");
const Name = p2.Name;
const PackedFileEntry = @import("PackedFileEntry.zig");

// this contains information about where the file came from.
const PakSourceRef = usize;

pub fn getDisplayNameForFileSource(source: PakSourceRef, packerfs: PackerFS) []const u8 {
    return packerfs.fileMountings.items[source].filePath;
}

pub const PackerBytesMapping = struct {
    bytes: []const u8,
    mappingId: u32,
    inMemory: bool,
};

pub const PackerFS = struct {
    allocator: std.mem.Allocator,
    fileHeaders: std.ArrayListUnmanaged(PackedFileEntry) = .{},
    filePakSources: std.ArrayListUnmanaged(PakSourceRef) = .{},
    fileHandlesByName: std.AutoHashMapUnmanaged(u32, usize) = .{},

    pakMountings: std.ArrayListUnmanaged(PakMounting) = .{},

    settings: Settings = .{},

    pub const PakMounting = struct {
        filePath: []const u8, // path to the file
        bytes: ?[]u8 align(8) = null,
        mountRefs: std.ArrayListUnmanaged(usize) = .{},

        pub fn isFileMounted(self: @This()) bool {
            return self.bytes != null;
        }

        pub fn addFileMountRef(self: *@This(), fileRef: usize) !void {
            try self.mountRefs.append(fileRef);
        }

        pub fn removeFileMountRef(self: *@This(), fileRef: usize) !void {
            for (0..self.mountRefs.items.len) |i| {
                if (self.mountRefs.items[i] == fileRef) {
                    self.mountRefs.swapRemove(i);
                    return;
                }
            }
            return error.MappingNotValid;
        }
    };

    pub const Settings = struct {
        mountOnDemand: bool = true, // disable this if mounting a file needs to be done manually
    };

    // todo: implement load memory to file then-map setup.
    // for systems which do not support mmap

    pub fn init(allocator: std.mem.Allocator, settings: Settings) !*@This() {
        const self = try allocator.create(@This());
        self.* = .{
            .allocator = allocator,
            .settings = settings,
        };

        return self;
    }

    pub fn discoverFromFile(self: *@This(), filePath: []const u8) !void {
        // load the file and read out all headers from the file at the path
        const file = try std.fs.cwd().openFile(filePath, .{});
        defer file.close();

        const reader = file.reader();
        var iterator = try PackedFileEntry.ReaderIterator.init(reader);

        const pakMountingIndex = self.pakMountings.items.len;

        try self.pakMountings.append(.{ .filePath = filePath });

        while (try iterator.next(reader)) |headerEntry| {
            const headerIndex = self.fileHeaders.items.len;

            const HeaderName = Name.Make(headerEntry.getFileName());

            if (self.fileHandlesByName.get(HeaderName.handle())) |oldFileHeaderIndex| {
                const oldFileHeaderSource = self.filePakSources.items[oldFileHeaderIndex];
                std.debug.print(
                    // todo; how should I deal with eviction?
                    "file {s} is already discovered, previously from {s}, this previous reference will be overwritten.\n",
                    .{ headerEntry.getFileName(), getDisplayNameForFileSource(oldFileHeaderSource) },
                );

                self.fileHeaders.items[oldFileHeaderIndex] = headerEntry;
                self.filePakSources.items[oldFileHeaderIndex] = pakMountingIndex;

                if (self.fileBytesMounted.items[oldFileHeaderIndex] != null) {
                    self.allocator.free(self.fileBytesMounted.items[oldFileHeaderIndex]);
                }

                self.fileBytesMounted.items[oldFileHeaderIndex] = null;
            } else {
                try self.fileHeaders.append(self.allocator, headerEntry);
                try self.filePakSources.append(self.allocator, pakMountingIndex);
                try self.fileBytesMounted.append(self.allocator, null);

                try self.fileHandlesByName.put(self.allocator, HeaderName.handle(), headerIndex);

                try p2.assert(self.filePakSources.items.len == self.fileHeaders.items.len);
            }
        }
    }

    pub fn countFilesDiscovered(self: @This()) u64 {
        return @intCast(self.fileHeaders.items.len);
    }

    pub fn loadFileByPath(self: @This(), path: []const u8) !PackerBytesMapping {
        return try self.loadFileByIndex(self, self.fileHandlesByName.get(Name.Make(path)).?);
    }

    // if the file is not loaded, then mount the entire package then load out the bytes
    // TODO: implement file memory mapping on windows, or cook up a really good packaging setup.
    pub fn loadFileByIndex(self: @This(), index: usize) !PackerBytesMapping {

        // grab the file header,
        // grab the file source,
        const source = self.fileSourceInfos.items[index];
        const header = self.fileHeaders.items[index];
        _ = header;

        const pakMountingRef = &self.pakMountings.items[source];

        if (!pakMountingRef.isFileMounted()) {
            //pakMountingRef.*.bytes = try self.allocator.alignedAlloc(pakMountingRef.pakSize
            pakMountingRef.*.bytes = try p2.loadFileAlloc(pakMountingRef.filePath, 8, self.allocator);
        }
    }

    pub fn destroy(self: *@This()) void {
        self.fileHeaders.deinit(self.allocator);
        self.fileHandlesByName.deinit(self.allocator);
        self.fileSourceInfos.deinit(self.allocator);
        self.fileBytesMounted.deinit(self.allocator);

        self.allocator.destroy(self);
    }
};
