const std = @import("std");

const c = @cImport({
    @cDefine("CGLTF_IMPLEMENTATION", .{});
    @cInclude("cgltf.h");
});
