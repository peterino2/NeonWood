
// A stage defines a standard interface which encapsulates an entire level and an ECS state.

const std = @import("std");
const nw = @import("root").neonwood;

const core = nw.core;
const assets = nw.assets;

pub const Interactable = struct {
    position: core.Vectorf,
    radius: f32,
    tag: []const u8,
};

pub const Mesh = struct {
    position: core.Vectorf = core.Vectorf{.x=0,.y=0,.z=0},
    rotation: core.Quat = @Vector(4, f32){0,0,0,1},
    scale: core.Vectorf = core.Vectorf{.x=1,.y=1,.z=1},
    mesh: core.Name = core.MakeName("mesh_quad"),
    texture: core.Name = core.NoName,
    hasCollisions: bool = false,
    collisionFile: []const u8 = "",
    hasSprite: bool = false,
    spriteName: core.Name = core.MakeName(""),
    startingAnim: core.Name = core.MakeName(""),

};

// a stage is a list of asset datas required to load a scene in cognesia
pub const StageData = struct {

    allocator: std.mem.Allocator,

    data: struct {
        // this will be used to set the starting position of Denver by the top level game
        startingPosition: core.Vectorf = core.Vectorf.zero(),
        startingPositions: std.ArrayListUnmanaged(struct {
            position: core.Vectorf = core.Vectorf.zero(),
            anim: core.Name = core.MakeName("idleDown"),
            flipped: bool = false,
            startingDialogue: ?[]const u8 = null, 
        }) = .{},
        startingDialogue: ?[]const u8 = null, // this will be executed as soon as the load function is complete.
        interactables: std.ArrayListUnmanaged(Interactable) = .{},
        mainStageMesh: Mesh = .{},
        extraMeshes: std.ArrayListUnmanaged(Mesh) = .{},
        startingDir: core.Name = core.MakeName("idleDown"),
    },


    pub fn init(allocator: std.mem.Allocator) @This()
    {
        var new = @This(){
            .allocator = allocator,
            .data = .{}
        };
        return new;
    }
 
    // saves the stage to disk with a json representation
    pub fn saveToDisk(self: @This(), path: []const u8) !void 
    {

        var ostr = std.ArrayList(u8).init(self.allocator);
        try std.json.stringify(self.data, .{.whitespace = .{.indent_level = 2}}, ostr.writer());
        defer ostr.deinit();

        try core.writeToFile(ostr.items, path);
    }

    // loads the stage from a file
    pub fn loadFromFile(self: *@This(), path: []const u8) !void
    {
        var fileString = try core.loadFileAlloc(path, 1, self.allocator);
        defer self.allocator.free(fileString);

        var parser = std.json.Parser.init(self.allocator, false);
        defer parser.deinit();

        var tree = try parser.parse(fileString);
        // TODO: need to bind tree.deinit to the higher level stage manager. 
        // there are a lot of memory leaks in this section. but it's relatively small and 
        // only when working with the editor version of this stuff.
        // defer tree.deinit();

        // load main stage mesh
        // self.data.startingPosition = core.Vectorf.new(
        //     @floatCast(f32, tree.root.Object.get("startingPosition").?.Object.get("x").?.Float),
        //     @floatCast(f32, tree.root.Object.get("startingPosition").?.Object.get("y").?.Float),
        //     @floatCast(f32, tree.root.Object.get("startingPosition").?.Object.get("z").?.Float),
        // );

        var jsonRoot = tree.root.Object;
        if(jsonRoot.get("startingPosition")) |positions|
        {
            for(positions.Array.items) |s|
            {
                var flipped:bool = false;
                const startingInfo = s.Object;
                if(startingInfo.get("flipped")) |b|
                {
                    flipped = b.Bool;
                }
                var startingDialogue: ?[]const u8 = null;
                if(startingInfo.get("startingDialogue"))|d|
                {
                    startingDialogue = try std.fmt.allocPrintZ(self.allocator, "{s}", .{d.String});
                }

                try self.data.startingPositions.append(
                    self.allocator,
                    .{
                        .position = core.Vectorf.new(
                            @floatCast(f32, startingInfo.get("position").?.Object.get("x").?.Float),
                            @floatCast(f32, startingInfo.get("position").?.Object.get("y").?.Float),
                            @floatCast(f32, startingInfo.get("position").?.Object.get("z").?.Float),
                        ),
                        .anim = core.Name.fromUtf8(startingInfo.get("anim").?.String),
                        .flipped = flipped,
                        .startingDialogue = startingDialogue,
                    }
                );
            }
        }

        if(jsonRoot.get("startingDir")) |startingDir|
        {
            self.data.startingDir = core.Name.fromUtf8(try std.fmt.allocPrintZ(self.allocator, "{s}", .{startingDir.Object.get("utf8").?.String}));
        }

        const mesh = tree.root.Object.get("mainStageMesh").?.Object;
        self.data.mainStageMesh = .{
            .position = core.Vectorf.new(
                @floatCast(f32, mesh.get("position").?.Object.get("x").?.Float),
                @floatCast(f32, mesh.get("position").?.Object.get("y").?.Float),
                @floatCast(f32, mesh.get("position").?.Object.get("z").?.Float),
            ),
            .scale = core.Vectorf.new (
                @floatCast(f32, mesh.get("scale").?.Object.get("x").?.Float),
                @floatCast(f32, mesh.get("scale").?.Object.get("y").?.Float),
                @floatCast(f32, mesh.get("scale").?.Object.get("z").?.Float),
            ),
            .mesh = core.Name.fromUtf8(
                try std.fmt.allocPrintZ(self.allocator, "{s}", .{mesh.get("mesh").?.Object.get("utf8").?.String}),
            ),
            .texture = core.Name.fromUtf8(
                try std.fmt.allocPrintZ(self.allocator, "{s}", .{mesh.get("texture").?.Object.get("utf8").?.String}),
            ),
            .hasCollisions = mesh.get("hasCollisions").?.Bool,
            .collisionFile = try std.fmt.allocPrintZ(self.allocator, "{s}", .{mesh.get("collisionFile").?.String}),
        };

        if(jsonRoot.get("startingDialogue")) |startingDialogue|
        {
            switch(startingDialogue)
            {
                .String => {
                    self.data.startingDialogue = try std.fmt.allocPrintZ(self.allocator, "{s}", .{
                        startingDialogue.String
                    });
                },
                .Null => {
                },
                else => {
                    return error.InvalidField;
                }
            }
        }

        // load interactables
        if(tree.root.Object.get("interactables")) |interactables|
        {
            for(interactables.Object.get("items").?.Array.items) |o|
            {
                var obj = o.Object;
                var p = obj.get("position").?.Object;
                var i = Interactable{
                    .position = core.Vectorf.new(
                        @floatCast(f32, p.get("x").?.Float),
                        @floatCast(f32, p.get("y").?.Float),
                        @floatCast(f32, p.get("z").?.Float),
                    ),
                    .radius = @floatCast(f32, obj.get("radius").?.Float),
                    .tag = try std.fmt.allocPrintZ(self.allocator, "{s}", .{
                        obj.get("tag").?.String
                    }),
                };
                try self.data.interactables.append(self.allocator, i);
            }
        }

        if(tree.root.Object.get("extraMeshes")) |meshes|
        {
            var meshlist = meshes.Object.get("items").?.Array;
            for(meshlist.items) |meshJson|
            {
                var meshObj = meshJson.Object;
                var m: Mesh = .{
                    .position = core.Vectorf.new(
                        @floatCast(f32, meshObj.get("position").?.Object.get("x").?.Float),
                        @floatCast(f32, meshObj.get("position").?.Object.get("y").?.Float),
                        @floatCast(f32, meshObj.get("position").?.Object.get("z").?.Float),
                    ),
                    .mesh = core.Name.fromUtf8(meshObj.get("mesh").?.String),
                };

                if(meshObj.get("scale"))|scale|
                {
                    m.scale = core.Vectorf.new(
                        @floatCast(f32, scale.Object.get("x").?.Float),
                        @floatCast(f32, scale.Object.get("y").?.Float),
                        @floatCast(f32, scale.Object.get("z").?.Float),
                    );
                }

                if(meshObj.get("sprite_texture")) |sprite|
                {
                    m.hasSprite = true;
                    m.spriteName = core.Name.fromUtf8(try std.fmt.allocPrintZ(self.allocator, "{s}", .{sprite.String}));
                }

                var spriteAnim = meshObj.get("sprite_anim").?;
                m.hasSprite = true;
                m.startingAnim = core.Name.fromUtf8(try std.fmt.allocPrintZ(self.allocator, "{s}", .{spriteAnim.String}));

                try self.data.extraMeshes.append(self.allocator, m);
            }
        }
    }
};

pub const StageSys = struct
{
    allocator: std.mem.Allocator,
    currentStage: StageData,

    pub fn init(allocator: std.mem.Allocator) @This() {

        return .{
            .allocator = allocator,
            .currentStage = StageData.init(allocator),
        };
    }

    pub fn loadStageFromFile(self: *@This(), file: []const u8) !StageData
    {
        var stageData = StageData{
            .data = .{},
            .allocator = self.allocator,
        };
        try stageData.loadFromFile(file);

        return stageData;
    }
};