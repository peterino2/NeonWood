const std = @import("std");
const graphics = @import("../graphics.zig");
const c = graphics.c;

pub fn setupDockspace(dockspaceName: anytype) void {
    var idStr: []const u8 = "DockWindow";
    var dockspaceID = c.igGetIDWithSeed(idStr.ptr, &idStr[idStr.len - 1], 0);

    var viewport = c.igGetMainViewport();

    c.igSetNextWindowPos(viewport.?.*.WorkPos, 0, .{ .x = 0, .y = 0 });
    c.igSetNextWindowSize(viewport.?.*.WorkSize, 0);
    c.igPushStyleVar_Float(c.ImGuiStyleVar_WindowRounding, 0.0);
    c.igPushStyleVar_Float(c.ImGuiStyleVar_WindowBorderSize, 0.0);

    c.igPushStyleVar_Vec2(c.ImGuiStyleVar_WindowPadding, .{ .x = 0, .y = 0 });

    var dockspace_flags: c_int = c.ImGuiDockNodeFlags_None;
    var window_flags: c_int = c.ImGuiWindowFlags_MenuBar | c.ImGuiWindowFlags_NoDocking;
    window_flags |= c.ImGuiWindowFlags_NoTitleBar | c.ImGuiWindowFlags_NoCollapse | c.ImGuiWindowFlags_NoResize;
    window_flags |= c.ImGuiWindowFlags_NoMove;
    window_flags |= c.ImGuiWindowFlags_NoBackground;
    window_flags |= c.ImGuiWindowFlags_NoBringToFrontOnFocus | c.ImGuiWindowFlags_NoNavFocus;

    if (c.igBegin(dockspaceName, null, window_flags)) {
        if (c.igBeginMenuBar()) {
            if (c.igBeginMenu("Options", true)) {
                _ = c.igMenuItem_Bool("Fullscreen", null, true, true);
                c.igEndMenu();
            }
            c.igEndMenuBar();
        }
        _ = c.igDockSpace(dockspaceID, .{ .x = 0, .y = 0 }, dockspace_flags, null);
        c.igEnd();
    }

    c.igPopStyleVar(3);
}
