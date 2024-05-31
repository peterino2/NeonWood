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
// - discover files from paks
// - want a file, I ask for that file.
// - get back a mapping struct which contains a []const u8 bytes struct
//      - this bytes struct tracks which archive it came from
// - when finished using the file, unmap the mapping struct,
//      - if it was the last file to be unmapped,
//      - then the file shapp be evicted from

const std = @import("std");
const p2 = @import("p2");
const Name = p2.Name;
const PackedFileEntry = @import("PackedFileEntry.zig");

// this contains information about where the file came from.
const PakSourceRef = usize;

pub fn getDisplayNameForFileSource(source: PakSourceRef, packerfs: *const PackerFS) []const u8 {
    return packerfs.pakMountings.items[source].filePath;
}

pub const PackerBytesMapping = struct {
    bytes: []const u8,
    mappingId: usize,
    inMemory: bool,
};

pub const Settings = struct {
    mountOnDemand: bool = true, // Disable this if we want to restrict file mounting to be manually mounted only.
    // If set to false, PackerFS
    allowContentFolderAccess: bool = true,
    contentFolderExtraPaths: []const []const u8 = &[_][]const u8{}, // By default, this will mount the content/ folder on disk.
};

pub const PackerFS = struct {
    allocator: std.mem.Allocator,
    fileHeaders: std.ArrayListUnmanaged(PackedFileEntry) = .{},
    filePakSources: std.ArrayListUnmanaged(PakSourceRef) = .{},
    fileHandlesByName: std.AutoHashMapUnmanaged(u32, usize) = .{},

    pakMountings: std.ArrayListUnmanaged(PakMounting) = .{},
    contentPaths: std.ArrayListUnmanaged([]u8) = .{},

    settings: Settings = .{},

    pub const PakMounting = struct {
        filePath: []const u8, // path to the file
        bytes: ?[]u8 align(8) = null,
        mountRefs: std.ArrayListUnmanaged(usize) = .{},
        contentOffset: usize = 0,
        inMemory: bool = false,

        pub fn isFileMounted(self: @This()) bool {
            return self.bytes != null;
        }

        pub fn unmount(self: *@This(), allocator: std.mem.Allocator) void {
            if (self.bytes) |bytes| {
                allocator.free(bytes);
            }
            self.mountRefs.deinit(allocator);

            self.bytes = null;
            self.mountRefs = .{};
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

    // todo: implement load memory to file then-map setup.
    // for systems which do not support mmap

    pub fn init(allocator: std.mem.Allocator, settings: Settings) !*@This() {
        const self = try allocator.create(@This());
        self.* = .{
            .allocator = allocator,
            .settings = settings,
        };

        try self.contentPaths.append(self.allocator, try p2.dupeString(allocator, "content"));

        return self;
    }

    pub fn discoverFromFile(self: *@This(), filePath: []const u8) !void {
        std.debug.print("discovered from file: {s}\n", .{filePath});

        // load the file and read out all headers from the file at the path
        const file = try std.fs.cwd().openFile(filePath, .{});
        defer file.close();

        const reader = file.reader();
        var iterator = try PackedFileEntry.ReaderIterator.init(reader);

        const pakMountingIndex = self.pakMountings.items.len;

        try self.pakMountings.append(self.allocator, .{ .filePath = filePath });

        while (try iterator.next(reader)) |headerEntry| {
            const HeaderName = Name.Make(headerEntry.getFileName());

            if (self.fileHandlesByName.get(HeaderName.handle())) |oldFileHeaderIndex| {
                const oldFileHeaderSource = self.filePakSources.items[oldFileHeaderIndex];

                std.debug.print(
                    // todo; how should I deal with eviction?
                    "file {s} is already discovered, previously from {s}, this previous reference will be overwritten.\n",
                    .{ headerEntry.getFileName(), getDisplayNameForFileSource(oldFileHeaderSource, self) },
                );

                self.fileHeaders.items[oldFileHeaderIndex] = headerEntry;
                self.filePakSources.items[oldFileHeaderIndex] = pakMountingIndex;
            } else {
                _ = try self.addFileEntry(headerEntry, pakMountingIndex);
            }
        }
        self.pakMountings.items[pakMountingIndex].contentOffset = iterator.bytesRead;
    }

    pub fn countFilesDiscovered(self: @This()) u64 {
        return @intCast(self.fileHeaders.items.len);
    }

    pub fn loadFileByPath(self: *@This(), path: []const u8) !PackerBytesMapping {
        if (self.fileHandlesByName.get(Name.Make(path).handle())) |fileNameHandle| {
            const maybeBytes = try self.loadFileByIndexFromPak(fileNameHandle);
            if (maybeBytes != null) {
                return maybeBytes.?;
            }
        }

        if (!self.settings.allowContentFolderAccess) {
            return error.FileNotPackaged;
        }

        for (self.contentPaths.items) |contentPath| {
            if (try self.loadFileDirect(contentPath, path)) |bytes| {
                return bytes;
            }
        }

        return error.FileNotFound;
    }

    fn addFileEntry(self: *@This(), headerEntry: PackedFileEntry, pakMountingIndex: usize) !usize {
        const headerName = Name.Make(headerEntry.getFileName());
        const headerIndex = self.fileHeaders.items.len;
        try self.fileHeaders.append(self.allocator, headerEntry);
        try self.filePakSources.append(self.allocator, pakMountingIndex);

        try self.fileHandlesByName.put(self.allocator, headerName.handle(), headerIndex);

        try p2.assert(self.filePakSources.items.len == self.fileHeaders.items.len);

        return headerIndex;
    }

    fn loadFileDirect(self: *@This(), basePath: []const u8, path: []const u8) !?PackerBytesMapping {
        // if we made it to this function we can assume that the file does not exist in existing pak mounting references.
        // nor does it exist in self.fileHandlesByName
        // we can add a new file reference, AND a new pakMounting entry here.
        const fullPath = try std.fmt.allocPrint(self.allocator, "{s}/{s}", .{ basePath, path });
        defer self.allocator.free(fullPath);

        const fileBytes = p2.loadFileAlloc(fullPath, 8, self.allocator) catch return null;

        const pakMountIndex = self.pakMountings.items.len;
        try self.pakMountings.append(self.allocator, .{
            .filePath = path,
            .inMemory = true,
        });

        try p2.assert(self.filePakSources.items.len == self.fileHeaders.items.len);

        // generate a header for the thing
        const headerEntry = try PackedFileEntry.init("unknown", path, 0, fileBytes.len);
        const headerIndex = try self.addFileEntry(headerEntry, pakMountIndex);

        self.pakMountings.items[pakMountIndex].bytes = fileBytes;
        const mountId = self.pakMountings.items[pakMountIndex].mountRefs.items.len;
        try self.pakMountings.items[pakMountIndex].mountRefs.append(self.allocator, headerIndex);

        return .{
            .bytes = fileBytes,
            .mappingId = mountId,
            .inMemory = true,
        };
    }

    // if the file is not loaded, then mount the entire package then load out the bytes
    // TODO: implement file memory mapping on windows, or cook up a really good packaging setup.
    fn loadFileByIndexFromPak(self: *@This(), index: usize) !?PackerBytesMapping {

        // grab the file header,
        const source = self.filePakSources.items[index];
        const header = self.fileHeaders.items[index];

        // grab the file source,
        const pakMountingRef = &self.pakMountings.items[source];

        if (!pakMountingRef.isFileMounted()) {
            std.debug.print("mounting file: {s}\n", .{pakMountingRef.filePath});
            pakMountingRef.*.bytes = p2.loadFileAlloc(pakMountingRef.filePath, 8, self.allocator) catch return null;
            try p2.xxdWrite(std.io.getStdErr().writer(), pakMountingRef.*.bytes.?[0..0x40], .{});
        }

        const offset = header.fileOffset + pakMountingRef.contentOffset;

        return PackerBytesMapping{
            .bytes = pakMountingRef.bytes.?[offset .. offset + header.fileLen],
            .mappingId = 0,
            .inMemory = false, // TODO, support in-memory mappings
        };
    }

    pub fn unmap(self: @This(), mapping: PackerBytesMapping) void {
        _ = self;
        _ = mapping;
        return;
    }

    pub fn destroy(self: *@This()) void {
        self.fileHeaders.deinit(self.allocator);
        self.fileHandlesByName.deinit(self.allocator);
        self.filePakSources.deinit(self.allocator);

        for (self.pakMountings.items) |*mounting| {
            mounting.unmount(self.allocator);
        }

        self.pakMountings.deinit(self.allocator);

        for (self.contentPaths.items) |path| {
            self.allocator.free(path);
        }
        self.contentPaths.deinit(self.allocator);

        self.allocator.destroy(self);
    }
};
