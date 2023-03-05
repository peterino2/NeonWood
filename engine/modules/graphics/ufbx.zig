// some quick bindings to ufbx
const std = @import("std");
const core = @import("../core.zig");

const c = @cImport({
    @cInclude("ufbx.h");
    @cInclude("ufbx_compat.h");
});

pub const FbxLoadOpts = c.ufbx_load_opts;

pub fn CreateDefaultLoadOpts() FbxLoadOpts {
    return std.mem.zeroes(FbxLoadOpts);
}

pub const FbxScene = struct {
    _scene: ?*c.ufbx_scene,

    pub fn printAllNodes(self: *@This()) void {
        if (self._scene == null) {
            core.engine_log("What the fuck", .{});
        }

        var nodes = c.ufbx_scene_GetNodeListFromScene(self._scene);
        for (0..nodes.*.count) |i| {
            const node = nodes.*.data[i];
            if (node.*.is_root)
                continue;

            core.engine_log("FBX NODE: {s}", .{@ptrCast([*c]const u8, c.ufbx_node_GetName(node))});

            if (node.*.mesh) |mesh| {
                core.engine_log(" >MESH faces count: {d}", .{mesh.*.faces.count});
            }
        }
    }

    pub fn LoadFromFile(fileName: []const u8) !@This() {
        var opts = CreateDefaultLoadOpts();
        std.debug.print("filename = {s}\n", .{@ptrCast([*c]const u8, fileName.ptr)});

        var self = @This(){
            ._scene = c.ufbx_load_file_len(fileName.ptr, fileName.len, &opts, null),
        };

        return self;
    }

    pub fn deinit(self: *@This()) void {
        c.ufbx_free_scene(self._scene);
    }
};

pub fn loadFbx(path: []const u8) !FbxScene {
    var scene = try FbxScene.LoadFromFile(path);

    return scene;
}
