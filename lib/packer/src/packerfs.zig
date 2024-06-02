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
    fileEntryId: usize,
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

    lock: std.Thread.Mutex = .{},

    pub const PakMounting = struct {
        filePath: []const u8, // path to the file
        bytes: []align(8) u8 = undefined,
        mounted: bool = false,
        mountRefs: std.ArrayListUnmanaged(usize) = .{},
        contentOffset: usize = 0,
        inMemory: bool = false,

        pub fn isFileMounted(self: @This()) bool {
            return self.mounted;
        }

        pub fn unmount(self: *@This(), allocator: std.mem.Allocator) void {
            if (self.mounted) {
                std.debug.print("unmounting file:{s} bytes: 0x{x}\n", .{ self.filePath, @intFromPtr(self.bytes.ptr) });
                allocator.free(self.bytes);
                self.mountRefs.deinit(allocator);
                self.mounted = false;
                self.mountRefs = .{};
            }
        }

        pub fn removeMapping(self: *@This(), allocator: std.mem.Allocator, fileRef: usize) void {
            for (0..self.mountRefs.items.len) |i| {
                if (self.mountRefs.items[i] == fileRef) {
                    _ = self.mountRefs.swapRemove(i);

                    // TODO: move this into a sweep and clean operation
                    if (self.mountRefs.items.len == 0) {
                        self.unmount(allocator);
                    }
                    return;
                }
            }
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
        self.lock.lock();
        defer self.lock.unlock();

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

    pub fn loadFile(self: *@This(), path: []const u8) !PackerBytesMapping {
        self.lock.lock();
        defer self.lock.unlock();

        if (self.fileHandlesByName.get(Name.Make(path).handle())) |fileNameHandle| {
            if (try self.loadFileByIndexFromPak(fileNameHandle)) |mapping| {
                return mapping;
            }
        }

        if (!self.settings.allowContentFolderAccess) {
            return error.FileNotPackaged;
        }

        for (self.contentPaths.items) |contentPath| {
            if (try self.loadFileDirect(contentPath, path)) |mapping| {
                std.debug.print("direct load - 0x{x}\n", .{@intFromPtr(mapping.bytes.ptr)});
                return mapping;
            }
        }

        std.debug.print("PackerFS - Error: FileNotFound {s}", .{path});
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

        const fileBytes: []align(8) u8 = @alignCast(p2.loadFileAlloc(fullPath, 8, self.allocator) catch return null);

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
        try self.pakMountings.items[pakMountIndex].mountRefs.append(self.allocator, headerIndex);
        self.pakMountings.items[pakMountIndex].mounted = true;

        std.debug.print("loadFileDirect {s} {d} 0x{x}\n", .{ path, headerIndex, @intFromPtr(fileBytes.ptr) });
        return .{
            .bytes = fileBytes,
            .mappingId = pakMountIndex,
            .fileEntryId = headerIndex,
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
            pakMountingRef.*.bytes = @alignCast(p2.loadFileAlloc(pakMountingRef.filePath, 8, self.allocator) catch return null);
        }

        const offset = header.fileOffset + pakMountingRef.contentOffset;
        try self.pakMountings.items[source].mountRefs.append(self.allocator, index);
        self.pakMountings.items[source].mounted = true;

        return PackerBytesMapping{
            .bytes = pakMountingRef.bytes[offset .. offset + header.fileLen],
            .mappingId = source,
            .fileEntryId = index,
            .inMemory = false,
        };
    }

    pub fn unmap(self: *@This(), mapping: PackerBytesMapping) void {
        self.lock.lock();
        defer self.lock.unlock();

        std.debug.print("unmapping file: {d},{d} 0x{x}\n", .{ mapping.mappingId, mapping.fileEntryId, @intFromPtr(mapping.bytes.ptr) });
        self.pakMountings.items[mapping.mappingId].removeMapping(self.allocator, mapping.fileEntryId);
        return;
    }

    pub fn destroy(self: *@This()) void {
        self.lock.lock();

        for (self.pakMountings.items) |*mounting| {
            mounting.unmount(self.allocator);
        }

        self.fileHeaders.deinit(self.allocator);
        self.fileHandlesByName.deinit(self.allocator);
        self.filePakSources.deinit(self.allocator);
        self.pakMountings.deinit(self.allocator);

        for (self.contentPaths.items) |path| {
            self.allocator.free(path);
        }
        self.contentPaths.deinit(self.allocator);
        self.lock.unlock();
        self.allocator.destroy(self);
    }
};
