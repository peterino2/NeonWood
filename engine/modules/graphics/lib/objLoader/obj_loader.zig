const std = @import("std");

const ArrayListUnmanaged = std.ArrayListUnmanaged;

// Higher level file functions.
pub fn loadFileAlloc(filename: []const u8, comptime alignment: usize, allocator: std.mem.Allocator) ![]const u8 {
    var file = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
    const filesize = (try file.stat()).size;
    var buffer: []u8 = try allocator.allocAdvanced(u8, @intCast(u29, alignment), filesize, .exact);
    try file.reader().readNoEof(buffer);
    return buffer;
}

const ObjVec = struct {
    x: f32,
    y: f32,
    z: f32,
};

const ObjVec2 = struct {
    x: f32,
    y: f32,
};

const ObjColor = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,
};

const ObjMesh = struct {
    object_name: []u8,
    v_positions: ArrayListUnmanaged(ObjVec) = .{},
    v_colors: ArrayListUnmanaged(ObjColor) = .{},
    v_normals: ArrayListUnmanaged(ObjVec) = .{},
    v_textures: ArrayListUnmanaged(ObjVec2) = .{},
    v_faces: ArrayListUnmanaged(ObjFace) = .{},
    allocator: std.mem.Allocator,

    pub fn print_stats(self: *ObjMesh) void {
        std.debug.print("obj: {s}, Vertices count = {d} Normals count = {d}, faces = {d}\n", .{
            self.object_name,
            self.v_positions.items.len,
            self.v_normals.items.len,
            self.v_faces.items.len,
        });
    }

    pub fn init(_object_name: []const u8, allocator: std.mem.Allocator) !ObjMesh {
        const object_name = try allocator.alloc(u8, _object_name.len);

        std.mem.copy(u8, object_name, _object_name);

        var self = ObjMesh{
            .object_name = object_name,
            .allocator = allocator,
        };

        return self;
    }

    pub fn setName(self: *ObjMesh, name: []const u8) !void {
        self.allocator.free(self.object_name);
        self.object_name = try self.allocator.alloc(u8, name.len);
        std.mem.copy(u8, self.object_name, name);
    }

    pub fn deinit(self: *ObjMesh) void {
        self.v_positions.deinit(self.allocator);
        self.v_colors.deinit(self.allocator);
        self.v_normals.deinit(self.allocator);
        self.v_textures.deinit(self.allocator);
        self.v_faces.deinit(self.allocator);
        self.allocator.free(self.object_name);
    }
};

const ObjFace = struct {
    vertex: [4]u32,
    texture: [4]u32,
    normal: [4]u32,
    count: u32,

    pub fn init() ObjFace {
        return .{
            .vertex = .{ 0, 0, 0, 0 },
            .texture = .{ 0, 0, 0, 0 },
            .normal = .{ 0, 0, 0, 0 },
            .count = 0,
        };
    }
};

const ResultType = enum {
    vertex,
    color,
    normal,
    face,
    object,
    group,
    comment,
    texture,
};

const LineParseResult = union(ResultType) {
    vertex: ObjVec,
    color: ObjColor,
    normal: ObjVec,
    face: ObjFace,
    object: []const u8,
    group: []const u8,
    comment: []const u8,
    texture: ObjVec2,
};

fn iterIntoVec2(iter: anytype) !ObjVec2 {
    var vec: ObjVec2 = undefined;
    var next: u32 = 0;
    while (iter.next()) |tok| {
        switch (next) {
            0 => {
                vec.x = try std.fmt.parseFloat(f32, tok);
            },
            1 => {
                vec.y = try std.fmt.parseFloat(f32, tok);
            },
            else => {
                return error.UnexpectedVectorPosition;
            },
        }
        next += 1;
    }

    return vec;
}

fn iterIntoVec3(iter: anytype) !ObjVec {
    var vec: ObjVec = undefined;
    var next: u32 = 0;
    while (iter.next()) |tok| {
        switch (next) {
            0 => {
                vec.x = try std.fmt.parseFloat(f32, tok);
            },
            1 => {
                vec.y = try std.fmt.parseFloat(f32, tok);
            },
            2 => {
                vec.z = try std.fmt.parseFloat(f32, tok);
            },
            else => {
                return error.UnexpectedVectorPosition;
            },
        }
        next += 1;
    }

    return vec;
}

pub fn toksIntoFace(toks: anytype) !ObjFace {
    var rv = ObjFace.init();
    var count: u32 = 0;
    while (toks.next()) |tok| {
        if (tok.len == 0)
            continue;
        var face_desc = std.mem.tokenize(u8, tok, "/");
        var ic: u32 = 0; // ic= inner_count
        while (face_desc.next()) |prop| {
            switch (ic) {
                0 => {
                    rv.vertex[count] = std.fmt.parseInt(u32, prop, 10) catch 0;
                },
                1 => {
                    rv.texture[count] = std.fmt.parseInt(u32, prop, 10) catch 0;
                },
                2 => {
                    rv.normal[count] = std.fmt.parseInt(u32, prop, 10) catch 0;
                },
                else => return error.TooManyfaceProperties,
            }

            ic += 1;
        }
        count += 1;
    }

    rv.count = count;
    return rv;
}

test "splitting" {
    const wank = "47//1";

    var iter = std.mem.tokenize(u8, wank, "/");

    while (iter.next()) |x| {
        std.debug.print("{s}, ", .{x});
    }
    std.debug.print("\n", .{});
}

fn parse_line(lineIn: []const u8, allocator: std.mem.Allocator) !LineParseResult {
    _ = allocator;
    var line: []const u8 = lineIn;

    if (line.len <= 0)
        return LineParseResult{ .comment = "<<empty line>>" };
    while (line[0] == ' ') {
        line = line[1..line.len];
    }

    var tokens = std.mem.tokenize(u8, line, " ");
    const first = tokens.next().?;

    if (line[0] == '#') {
        return LineParseResult{
            .comment = if (line.len > 1) line[1..line.len] else line[0..line.len],
        };
    }

    if (std.mem.eql(u8, "mtllib", first)) {
        return LineParseResult{
            .comment = "gonna ignore mtllibs for now.",
        };
    }

    if (std.mem.eql(u8, "vt", first)) {
        return LineParseResult{
            .texture = try iterIntoVec2(&tokens),
        };
    }

    if (std.mem.eql(u8, "vn", first)) {
        return LineParseResult{
            .normal = try iterIntoVec3(&tokens),
        };
    }

    if (std.mem.eql(u8, "v", first)) {
        return LineParseResult{
            .vertex = try iterIntoVec3(&tokens),
        };
    }
    if (std.mem.eql(u8, "f", first)) {
        return LineParseResult{
            .face = try toksIntoFace(&tokens),
        };
    } else if (std.mem.eql(u8, "g", first)) {
        // get a slice of the entire group
        const groupName = line[first.len + 1 .. line.len];
        return LineParseResult{
            .group = groupName,
        };
    } else if (std.mem.eql(u8, "o", first)) {
        // get a slice of the entire group
        const groupName = line[first.len + 1 .. line.len];
        std.debug.print("LOADING OBJECT: {s}\n", .{groupName});
        return LineParseResult{
            .object = groupName,
        };
    } else if (std.mem.eql(u8, "usemtl", first)) {
        return LineParseResult{
            .comment = "not yet implemented",
        };
    } else if (std.mem.eql(u8, "s", first)) {
        return LineParseResult{
            .comment = "not yet implemented",
        };
    }

    std.debug.print("error: unrecognized header: `{s}` in line: {s} ", .{ first, line });

    return error.NotImplemented;
}

test "parse_vector" {
    {
        var result = try parse_line("v 0.437500 0.765625 -0.164063", std.testing.allocator);
        std.debug.print("\n", .{});
        std.debug.print("{any}\n", .{result});
        try std.testing.expect(result == .vertex);
    }

    {
        var result = try parse_line("vn 0.437500 0.765625 -0.164063", std.testing.allocator);
        std.debug.print("\n", .{});
        std.debug.print("{any}\n", .{result});
        try std.testing.expect(result == .normal);
    }

    {
        var result = try parse_line("f 47//1 1//1 3//1 45//1", std.testing.allocator);
        std.debug.print("\n", .{});
        std.debug.print("{any}\n", .{result});
        try std.testing.expect(result == .face);
    }

    {
        var result = try parse_line("f 47//1 1//1 3//1 ", std.testing.allocator);
        std.debug.print("\n", .{});
        std.debug.print("{any}\n", .{result});
        try std.testing.expect(result == .face);
    }

    {
        var result = try parse_line("o Suzanne", std.testing.allocator);
        std.debug.print("\n", .{});
        std.debug.print("{any}\n", .{result});
        try std.testing.expect(result == .object);
    }

    {
        var result = try parse_line("g Suzanne", std.testing.allocator);
        std.debug.print("\n", .{});
        std.debug.print("{any}\n", .{result});
        try std.testing.expect(result == .group);
    }

    {
        var result = try parse_line("  # this is a comment ", std.testing.allocator);
        std.debug.print("\n", .{});
        try std.testing.expect(result == .comment);
        std.debug.print("{s}\n", .{result.comment});
    }
}

pub fn fileIntoLines(file_contents: []const u8) std.mem.SplitIterator(u8) {
    // find a \n and see if it has \r\n
    var index: u32 = 0;
    while (index < file_contents.len) : (index += 1) {
        if (file_contents[index] == '\n') {
            if (index > 0) {
                if (file_contents[index - 1] == '\r') {
                    return std.mem.split(u8, file_contents, "\r\n");
                } else {
                    return std.mem.split(u8, file_contents, "\n");
                }
            } else {
                return std.mem.split(u8, file_contents, "\n");
            }
        }
    }
    return std.mem.split(u8, file_contents, "\n");
}

const ObjContents = struct {
    meshes: std.ArrayList(ObjMesh),

    pub fn load(fileName: []const u8, allocator: std.mem.Allocator) !ObjContents {
        var self = ObjContents{
            .meshes = std.ArrayList(ObjMesh).init(allocator),
        };
        _ = self;

        var mesh = try ObjMesh.init("root", allocator);
        _ = mesh;

        var file_contents = try loadFileAlloc(fileName, 1, std.testing.allocator);
        defer std.testing.allocator.free(file_contents);
        var lines = fileIntoLines(file_contents);

        while (lines.next()) |line| {
            var result = parse_line(line, std.testing.allocator) catch {
                unreachable;
            };

            if (result == .object) {
                if (mesh.v_positions.items.len > 0) {
                    try self.meshes.append(mesh);
                    mesh = try ObjMesh.init(result.object, allocator);
                } else {
                    try mesh.setName(result.object);
                }
                std.debug.print("new obj name detected: {s}\n", .{result.object});
            }

            if (result == .vertex) {
                try mesh.v_positions.append(mesh.allocator, result.vertex);
            }

            if (result == .normal) {
                try mesh.v_normals.append(mesh.allocator, result.normal);
            }

            if (result == .face) {
                try mesh.v_faces.append(mesh.allocator, result.face);
            }

            if (result == .texture) {
                try mesh.v_textures.append(mesh.allocator, result.texture);
            }
        }
        try self.meshes.append(mesh);
        return self;
    }

    pub fn deinit(self: *ObjContents) void {
        for (self.meshes.items) |_, i| {
            self.meshes.items[i].deinit();
        }
        self.meshes.deinit();
    }
};

test "load_monkey_full" {
    const monkey_obj_path = "./test/monkey.obj";
    var obj_contents = try ObjContents.load(monkey_obj_path, std.testing.allocator);
    defer obj_contents.deinit();
    try std.testing.expect(obj_contents.meshes.items.len == 1);
    obj_contents.meshes.items[0].print_stats();
}

test "parse_monkey" {
    const monkey_obj_path = "./test/monkey.obj";
    const monkey_mtl_path = "./test/monkey.mtl";

    var file_contents = try loadFileAlloc(monkey_obj_path, 1, std.testing.allocator);
    defer std.testing.allocator.free(file_contents);
    var lines = fileIntoLines(file_contents);
    var count: u32 = 0;
    var vertex_count: u32 = 0;
    var normal_count: u32 = 0;
    var faces_count: u32 = 0;
    var texture_count: u32 = 0;

    while (lines.next()) |line| {
        var result = parse_line(line, std.testing.allocator) catch {
            unreachable;
        };
        if (result == .vertex)
            vertex_count += 1;

        if (result == .normal)
            normal_count += 1;

        if (result == .face)
            faces_count += 1;

        if (result == .texture)
            texture_count += 1;

        _ = result;
        count += 1;
    }

    std.debug.print("{s} loaded, Vertices count = {d} Normals count = {d}, faces = {d}\n", .{
        monkey_obj_path,
        vertex_count,
        normal_count,
        faces_count,
    });

    _ = monkey_mtl_path;
    _ = monkey_obj_path;
}
