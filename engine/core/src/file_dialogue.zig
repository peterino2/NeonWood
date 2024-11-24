const std = @import("std");
const core = @import("core.zig");
const nfd = @import("nfd");

pub const AsyncOpenFileDialogArgs = nfd.AsyncOpenFileDialogArgs;

pub fn openFileDialog(defaultPath: []const u8, filters: []const u8) ![*c]const u8 {
    return try core.getEngine().nfdRuntime.openFileDialog(defaultPath, filters);
}

pub fn openFolderDialog(defaultPath: []const u8, context: ?*anyopaque) ![*c]const u8 {
    return try core.getEngine().nfdRuntime.openFolderDialog(defaultPath, context);
}

pub fn asyncOpenFile(args: AsyncOpenFileDialogArgs) !void {
    return try core.getEngine().nfdRuntime.asyncOpenFileDialog(args);
}

pub fn asyncOpenFolder(args: AsyncOpenFileDialogArgs) !void {
    return try core.getEngine().nfdRuntime.asyncOpenFolderDialog(args);
}
