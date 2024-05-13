// Copyright (c) peterino2@github.com

const std = @import("std");

arena: std.heap.ArenaAllocator,
allocator: std.mem.Allocator,
fileName: []const u8,

typeIdNames: std.StringArrayHashMap([]const u8),
reflectedTypes: std.StringArrayHashMap(ReflectedTypeInfo),

// some runtime options
opts: Options,

const Options = struct {
    verbose: bool = false,
    embedFile: ?[]const u8 = null,
};

pub const ReflectedField = struct {
    name: []u8,
    typeName: []u8,
    size: usize,
    offset: usize,
};

pub const ReflectedTypeInfo = struct {
    name: []u8,
    fields: std.ArrayList(ReflectedField),
    size: usize,
};

pub fn err(_: @This(), comptime fmt: []const u8, args: anytype) void {
    std.debug.print("[ERROR  ]:" ++ fmt ++ "\n", args);
}

pub fn warn(_: @This(), comptime fmt: []const u8, args: anytype) void {
    std.debug.print("[WARNING]:" ++ fmt ++ "\n", args);
}

pub fn logv(self: @This(), comptime fmt: []const u8, args: anytype) void {
    if (self.opts.verbose) {
        std.debug.print("[VERBOSE]:" ++ fmt ++ "\n", args);
    }
}

pub fn reflect(allocator: std.mem.Allocator, fileName: []const u8, opts: Options) !@This() {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const arenaAlloc = arena.allocator();
    var self = @This(){
        .arena = arena,
        .allocator = arenaAlloc,
        .fileName = fileName,
        .typeIdNames = std.StringArrayHashMap([]const u8).init(arenaAlloc),
        .reflectedTypes = std.StringArrayHashMap(ReflectedTypeInfo).init(arenaAlloc),
        .opts = opts,
    };

    var file = try std.fs.cwd().openFile(fileName, .{});
    const fileContents = try file.readToEndAlloc(allocator, 10000000);
    defer allocator.free(fileContents);

    var tree = try std.json.parseFromSlice(std.json.Value, allocator, fileContents, .{});
    defer tree.deinit();
    //var tree = try parser.parseFromSlice(fileContents);
    var root = tree.value.object;
    //defer tree.deinit();

    if (root.get("types")) |maybe| {
        const typesRef = maybe.object;
        for (typesRef.keys(), typesRef.values()) |k, v| {
            const reflectedType = self.generateReflectedTypeInfo(v.object) catch |e| {
                if (e == error.DummyObject) {
                    continue;
                } else {
                    return e;
                }
            };

            try self.reflectedTypes.put(try dupeString(self.allocator, k), reflectedType);
        }

        try self.updateReflectedSizes();
    }

    if (root.get("ssbos")) |maybe| {
        const ssbos = maybe.array;
        for (ssbos.items) |ssboObject| {
            self.logv("ssbo {s}", .{ssboObject.object.get("name").?.string});
        }
    }

    return self;
}

fn dupeString(allocator: std.mem.Allocator, str: []const u8) ![]u8 {
    return try std.fmt.allocPrint(allocator, "{s}", .{str});
}

fn updateReflectedSize(self: *@This(), typeToUpdate: []const u8) void {
    var reflected = self.reflectedTypes.getPtr(typeToUpdate).?;

    if (reflected.size != 0)
        return;

    // get the last element
    if (reflected.fields.items.len > 0) {
        const lastField = reflected.fields.items[reflected.fields.items.len - 1];
        if (lastField.typeName[0] == '_') {
            self.updateReflectedSize(lastField.typeName);
            reflected.size = lastField.offset + self.reflectedTypes.get(lastField.typeName).?.size;
        } else {
            // TODO: apply some padding rules
            reflected.size = lastField.offset + lastField.size;
        }
    }
}

fn updateReflectedSizes(self: *@This()) !void {
    for (self.reflectedTypes.keys()) |key| {
        self.updateReflectedSize(key);
    }

    for (self.reflectedTypes.values()) |*v| {
        for (v.fields.items) |*field| {
            if (field.typeName[0] == '_') {
                field.size = self.reflectedTypes.get(field.typeName).?.size;
            }
        }
    }
}
fn generateReflectedTypeInfo(self: @This(), typeObject: std.json.ObjectMap) !ReflectedTypeInfo {
    var info = ReflectedTypeInfo{
        .fields = std.ArrayList(ReflectedField).init(self.allocator),
        .name = try dupeString(self.allocator, typeObject.get("name").?.string),
        .size = 0,
    };

    for (typeObject.get("members").?.array.items) |member| {
        var reflectedField = ReflectedField{
            .name = try dupeString(self.allocator, member.object.get("name").?.string),
            .typeName = try dupeString(self.allocator, member.object.get("type").?.string),
            .size = 0,
            .offset = 0,
        };

        if (member.object.get("offset")) |offset| {
            reflectedField.offset = @as(usize, @intCast(offset.integer));
        } else {
            return error.DummyObject;
        }

        // determine size
        //
        if (std.mem.eql(u8, reflectedField.typeName, "int"))
            reflectedField.size = 4;

        if (std.mem.eql(u8, reflectedField.typeName, "uint"))
            reflectedField.size = 4;

        if (std.mem.eql(u8, reflectedField.typeName, "vec2"))
            reflectedField.size = 8;

        if (std.mem.eql(u8, reflectedField.typeName, "vec4"))
            reflectedField.size = 16;

        if (std.mem.eql(u8, reflectedField.typeName, "float"))
            reflectedField.size = 4;

        if (std.mem.eql(u8, reflectedField.typeName, "mat4"))
            reflectedField.size = 64;

        if (std.mem.eql(u8, reflectedField.typeName, "vec3")) {
            self.warn("vec3 usage detected, this is poorly supported by many vendors", .{});
            reflectedField.size = 16;
        }
        try info.fields.append(reflectedField);
    }

    return info;
}

pub fn deinit(self: *@This()) void {
    self.arena.deinit();
}

pub fn render(self: *@This(), allocator: std.mem.Allocator) ![]u8 {
    var ostring = std.ArrayList(u8).init(allocator);
    defer ostring.deinit();
    var writer = ostring.writer();

    var validateChunk = std.ArrayList(u8).init(allocator);
    defer validateChunk.deinit();
    var validate = validateChunk.writer();
    try validate.writeAll("comptime {");

    // write the preamble
    try writer.writeAll("// This file is automatically generated\n");
    try writer.writeAll("const gl = @import(\"glslTypes\");\n\n");
    if (self.opts.embedFile) |embedFile| {
        std.debug.print("embedFile = {s}\n", .{embedFile});
        try writer.print("pub const spirv = @embedFile(\"{s}\");\n\n", .{embedFile});
    }
    try writer.writeAll("const vec2 = gl.vec2;\n");
    try writer.writeAll("const vec3 = gl.vec3;\n");
    try writer.writeAll("const vec4 = gl.vec4;\n");
    try writer.writeAll("const mat4 = gl.mat4;\n");
    try writer.writeAll("const float = gl.float;\n");
    try writer.writeAll("const uint = gl.uint;\n");

    for (self.reflectedTypes.values()) |reflected| {
        if (std.mem.eql(u8, reflected.name, "gl_PerVertex")) {
            continue;
        }

        var testChunk = std.ArrayList(u8).init(allocator);
        defer testChunk.deinit();
        var testChunkWriter = testChunk.writer();

        try validate.print("gl.ValidateGeneratedStruct({s});", .{reflected.name});

        try testChunkWriter.writeAll("\npub const FieldDetails: []const gl.FieldDetail = &.{\n");

        try writer.print("\npub const {s} =  extern struct {{ \n", .{reflected.name});
        var currentOffset: usize = 0;
        var padCount: usize = 0;
        for (reflected.fields.items) |field| {
            const expected: usize = field.offset;

            try testChunkWriter.print(".{{ .name = \"{s}\", .offset = {d}, .size = {d} }},\n", .{ field.name, expected, field.size });

            if (currentOffset != expected) {
                if (currentOffset > expected) {
                    self.err(
                        "`{s}` has field `{s}` with invalid offsets. Expected to be at `{d}` but current offset is already `{d}`",
                        .{
                            reflected.name,
                            field.name,
                            expected,
                            currentOffset,
                        },
                    );
                }

                try writer.print("pad{d}:[{d}]u8,\n", .{ padCount, expected - currentOffset });
                currentOffset += expected - currentOffset;
                padCount += 1;
            }

            if (field.typeName[0] != '_') {
                try writer.print("{s}: {s}, \n", .{ field.name, field.typeName });
            } else {
                const refTypeName = self.reflectedTypes.get(field.typeName).?.name;
                try writer.print("{s}: {s}, \n", .{ field.name, refTypeName });
            }
            currentOffset += field.size;
        }

        try testChunkWriter.writeAll("};\n");

        try writer.writeAll(testChunk.items);
        try writer.writeAll("};\n\n");
    }

    try validate.writeAll("}");
    try writer.writeAll(validateChunk.items);

    try ostring.append(0);
    var ast = try std.zig.Ast.parse(allocator, @as([:0]const u8, @ptrCast(ostring.items[0 .. ostring.items.len - 1])), .zig);
    defer ast.deinit(allocator);
    const out = try ast.render(allocator);

    return out;
}
