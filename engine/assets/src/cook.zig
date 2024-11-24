pub const CookResultEnum = enum {
    Success,
    Failure,
};

pub const CookResult = struct {
    bytes: ?[]u8 = null,
    result: CookResultEnum = .Success,

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        if (self.bytes) |bytes| {
            allocator.free(bytes);
        }
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

    pub fn destroy(self: *@This()) void {
        self.cooks.deinit(self.allocator);
        self.typesByExt.deinit(self.allocator);
        self.generates.deinit(self.allocator);

        self.allocator.destroy(self);
    }
};

var gCookRegistry: *CookRegistry = undefined;

pub const GenerateError = error{UnableToGenerate};
pub const LoadError = error{BadFile};

pub const CookGenerateFunction = *const fn (allocator: std.mem.Allocator, out: *std.ArrayList(u8)) GenerateError!void;
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

            try generateFunction(allocator, &cookFilePath);

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

    if (gCookRegistry.typesByExt.get(extension)) |assetType| {
        var cookFilePath = std.ArrayList(u8).init(allocator);
        defer cookFilePath.deinit();

        const cookFunction = gCookRegistry.cooks.get(assetType).?;

        try cookFilePath.appendSlice(path);
        try cookFilePath.appendSlice(".cook");

        dir.access(cookFilePath.items, .{}) catch return;

        var results = cookFunction(allocator, dir, path, .{
            .cookFileName = cookFilePath.items,
            .fileName = path,
        });
        defer results.deinit(allocator);

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

        if (results.bytes) |bytes| {
            const file = try dir.createFile(outPath.items, .{});
            defer file.close();
            try file.writeAll(bytes);
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
            info: CookInfo = .{ .assetType = "Texture" }, // there must always be a CookInfo field, its asset type must match the type this is registered as
            sourceType: []const u8 = "png",
        };

        pub fn generateFunction(allocator: std.mem.Allocator, out: *std.ArrayList(u8)) GenerateError!void {
            _ = allocator;

            out.clearRetainingCapacity();

            std.json.stringify(TestConfig{}, .{ .whitespace = .indent_4 }, out.writer()) catch return GenerateError.UnableToGenerate;
        }

        pub fn cookFunction(allocator: std.mem.Allocator, dir: std.fs.Dir, path: []const u8, params: CookParams) CookResult {
            _ = params;
            const rawFileBytes = loadFileAlloc(allocator, dir, path) catch unreachable;
            defer allocator.free(rawFileBytes);

            return .{
                .bytes = allocator.dupe(u8, "placeholder") catch null,
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
