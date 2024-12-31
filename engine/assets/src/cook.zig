pub const CookResultEnum = enum {
    Success,
    Failure,
};

pub const FileBytes = struct {
    path: []const u8,
    bytes: []u8,
};

pub const ExtraFiles = std.ArrayList(FileBytes);

pub const CookResult = struct {
    bytes: std.ArrayList(u8),
    result: CookResultEnum = .Success,
    extraFiles: ?ExtraFiles = null,

    pub fn deinit(self: *@This()) void {
        self.bytes.deinit();
    }
};

pub const CookParams = struct {
    noSave: bool = false,
    fileName: []const u8,
    cookFileName: []const u8,
};
pub const CookInfo = struct {
    assetType: []const u8 = "none",
};

pub const CookRegistry = struct {
    allocator: std.mem.Allocator,
    cooks: std.StringHashMapUnmanaged(CookFunction) = .{},
    generates: std.StringHashMapUnmanaged(CookGenerateFunction) = .{},

    typesByExt: std.StringHashMapUnmanaged([]const u8) = .{},

    pub fn create(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());
        self.* = .{
            .allocator = allocator,
        };

        gCookRegistry = self;
        return self;
    }

    pub fn install(self: *@This(), typeName: []const u8, generate: CookGenerateFunction, cook: CookFunction, extensions: []const []const u8) !void {
        try self.generates.put(self.allocator, typeName, generate);
        try self.cooks.put(self.allocator, typeName, cook);

        for (extensions) |ext| {
            try self.typesByExt.put(self.allocator, ext, typeName);
        }
    }

    pub fn destroy(self: *@This()) void {
        self.cooks.deinit(self.allocator);
        self.typesByExt.deinit(self.allocator);
        self.generates.deinit(self.allocator);

        self.allocator.destroy(self);
    }
};

var gCookRegistry: *CookRegistry = undefined;
var gCooking: bool = false;

pub fn getRegistry() *CookRegistry {
    return gCookRegistry;
}

pub fn startup(allocator: std.mem.Allocator) !void {
    gCooking = true;
    _ = try CookRegistry.create(allocator);
}

pub fn shutdown() void {
    if (gCooking) {
        gCookRegistry.destroy();
        gCooking = false;
    }
}

pub const GenerateError = error{UnableToGenerate};
pub const LoadError = error{BadFile};

pub const CookGenerateFunction = *const fn (allocator: std.mem.Allocator, filePath: []const u8, out: *std.ArrayList(u8)) GenerateError!void;
pub const CookFunction = *const fn (allocator: std.mem.Allocator, dir: std.fs.Dir, path: []const u8, params: CookParams) CookResult;

pub fn loadFileAlloc(allocator: std.mem.Allocator, dir: std.fs.Dir, path: []const u8) ![]align(8) u8 {
    var file = try dir.openFile(path, .{});
    defer file.close();
    const filesize = (try file.stat()).size + 1; // add null byte
    const buffer: []align(8) u8 = try allocator.alignedAlloc(u8, 8, filesize);
    errdefer allocator.free(buffer);
    try file.reader().readNoEof(buffer[0 .. buffer.len - 1]);
    buffer[buffer.len - 1] = 0;

    return buffer;
}

pub fn getExtension(path: []const u8) ?[]const u8 {
    var extension: []const u8 = path;
    var i: i32 = @intCast(path.len - 1);
    while (i > 0) : (i -= 1) {
        if (path[@intCast(i)] == '.') {
            extension = path[@intCast(i)..];
            return extension;
        }
    }

    return null;
}

pub fn generateCookFile(allocator: std.mem.Allocator, dir: std.fs.Dir, path: []const u8) !void {
    if (getExtension(path)) |extension| {
        if (gCookRegistry.typesByExt.get(extension)) |assetType| {
            var cookFilePath = std.ArrayList(u8).init(allocator);
            defer cookFilePath.deinit();
            const generateFunction = gCookRegistry.generates.get(assetType).?;

            var outPath: std.ArrayListUnmanaged(u8) = .{};
            defer outPath.deinit(allocator);

            try outPath.appendSlice(allocator, path);
            try outPath.appendSlice(allocator, ".cook");

            try generateFunction(allocator, path, &cookFilePath);

            const file = try dir.createFile(outPath.items, .{});
            defer file.close();

            try file.writeAll(cookFilePath.items);
        }
    }
}

pub fn cookFile(allocator: std.mem.Allocator, dir: std.fs.Dir, path: []const u8) !void {
    std.debug.print("{s}\n", .{path});
    const extension = getExtension(path).?;

    if (std.mem.eql(u8, extension, ".cook")) {
        return;
    }

    var cookFilePath = std.ArrayList(u8).init(allocator);
    defer cookFilePath.deinit();

    try cookFilePath.appendSlice(path);
    try cookFilePath.appendSlice(".cook");

    if (gCookRegistry.typesByExt.get(extension)) |assetType| {
        const cookFunction = gCookRegistry.cooks.get(assetType).?;

        dir.access(cookFilePath.items, .{}) catch return;

        var results = cookFunction(allocator, dir, path, .{
            .cookFileName = cookFilePath.items,
            .fileName = path,
        });
        defer results.deinit();

        var outPath = std.ArrayList(u8).init(allocator);
        defer outPath.deinit();

        try outPath.appendSlice("_cooked/");
        try outPath.appendSlice(path);
        try outPath.appendSlice(".");
        try outPath.appendSlice(assetType);

        {
            var basePath: []const u8 = outPath.items;
            var index: usize = basePath.len - 1;
            while (basePath[index] != '/' and basePath[index] != '\\') : (index -= 1) {}
            basePath = basePath[0..index];
            try dir.makePath(basePath);
        }

        if (results.result == .Success) {
            const file = try dir.createFile(outPath.items, .{});
            defer file.close();
            try file.writeAll(results.bytes.items);
        }
        return;
    } else {
        unreachable;
    }
}

pub fn generateAllCookFiles(allocator: std.mem.Allocator, dir: std.fs.Dir) !void {
    var iter = dir.iterate();
    while (try iter.next()) |next| {
        switch (next.kind) {
            .file => {
                try generateCookFile(allocator, dir, next.name);
            },
            .directory => {
                if (!std.mem.eql(u8, "_cooked", next.name)) {
                    var subDir = try dir.openDir(next.name, .{ .iterate = true });
                    defer subDir.close();

                    try generateAllCookFiles(allocator, subDir);
                }
            },
            else => {},
        }
    }
}

pub fn cookAllFiles(allocator: std.mem.Allocator, dir: std.fs.Dir) !void {
    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |next| {
        switch (next.kind) {
            .file => {
                if (std.mem.startsWith(u8, next.path, "_cooked")) {
                    continue;
                }

                if (std.mem.startsWith(u8, next.path, ".gitignore")) {
                    continue;
                }

                try cookFile(allocator, dir, next.path);
            },
            else => {},
        }
    }
}

test "testing cooking" {
    const alloc = std.testing.allocator;

    const Test = struct {
        const TestConfig = struct {
            info: CookInfo = .{ .assetType = "Texture" }, // there must always be a CookInfo field
            sourceType: []const u8 = "png",
        };

        pub fn generateFunction(allocator: std.mem.Allocator, path: []const u8, out: *std.ArrayList(u8)) GenerateError!void {
            _ = allocator;
            _ = path;
            out.clearRetainingCapacity();

            std.json.stringify(TestConfig{}, .{ .whitespace = .indent_4 }, out.writer()) catch return GenerateError.UnableToGenerate;
        }

        pub fn cookFunction(allocator: std.mem.Allocator, dir: std.fs.Dir, path: []const u8, params: CookParams) CookResult {
            _ = params;
            const rawFileBytes = loadFileAlloc(allocator, dir, path) catch unreachable;
            defer allocator.free(rawFileBytes);
            const rv = std.ArrayList(u8).init(allocator);

            return .{
                .bytes = rv,
                .result = .Success,
            };
        }
    };

    const dir = try std.fs.cwd().openDir("test", .{ .iterate = true });

    const registry = try CookRegistry.create(alloc);
    defer registry.destroy();
    try registry.generates.put(registry.allocator, "Texture", Test.generateFunction);
    try registry.cooks.put(registry.allocator, "Texture", Test.cookFunction);
    try registry.typesByExt.put(registry.allocator, ".png", "Texture");

    // scan and generate all texture files
    try generateAllCookFiles(alloc, dir);
    try cookAllFiles(alloc, dir);
    // try generateCookFile(alloc, dir, "icon.png");
    // try cookFile(alloc, dir, "icon.png");
}

const std = @import("std");
