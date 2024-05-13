const std = @import("std");
const core = @import("core.zig");

pub fn openFileDialog(defaultPath: []const u8, filters: []const u8) ![*c]const u8 {
    return try core.getEngine().nfdRuntime.openFileDialog(defaultPath, filters);
}

pub fn openFolderDialog(defaultPath: []const u8) ![*c]const u8 {
    return try core.getEngine().nfdRuntime.openFolderDialog(defaultPath);
}
