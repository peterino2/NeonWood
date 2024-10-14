//
// given a file format which contains a list of allocs, frees, and reallocs
//
// display them in chronological order.
//
// and highlight which allocations are not free'd at each step
const nw = @import("NeonWood");

backingAllocator: std.mem.Allocator,
arena: std.heap.ArenaAllocator,
fullscreen: bool = false,
padding: bool = false,
dockspaceFlags: imgui.DockNodeFlags = .{},

open: bool = false,
// eventsList: p2.PagedVector(),

pub var NeonObjectTable: core.EngineObjectVTable = core.EngineObjectVTable.from(@This());

pub fn tick(self: *@This(), _: f64) void {
    dockspace(&self.open);
}

pub fn dockspace(open: *bool) void {
    const flags: imgui.WindowFlags = .{
        .menu_bar = true,
        .no_docking = true,
        .no_title_bar = true,
        .no_collapse = true,
        .no_resize = true,
        .no_move = true,
        .no_bring_to_front_on_focus = true,
        .no_nav_focus = true,
        .no_background = true,
    };

    const viewport = imgui.getMainViewport().?;
    imgui.setNextWindowPos(viewport.work_pos, .{}, .{});
    imgui.setNextWindowSize(viewport.work_size, .{});
    imgui.setNextWindowViewport(viewport.id);
    imgui.pushStyleVar_Float(.WindowRounding, 0.0);
    imgui.pushStyleVar_Float(.WindowBorderSize, 0.0);
    imgui.pushStyleVar_Vec2(.WindowPadding, .{ .x = 0, .y = 0 });

    _ = imgui.begin("Dockspace Demo", open, flags);
    imgui.popStyleVar(3);

    const id = imgui.getID_Str("MainDockspace");
    _ = imgui.dockSpace(id, .{ .x = 0, .y = 0 }, .{}, null);
    imgui.end();
}

pub inline fn allocator(self: @This()) std.mem.Allocator {
    return self.arena.allocator();
}

pub fn init(alloc: std.mem.Allocator) !*@This() {
    const self = try alloc.create(@This());
    self.* = .{ .backingAllocator = alloc, .arena = std.heap.ArenaAllocator.init(alloc) };
    return self;
}

pub fn deinit(self: *@This()) void {
    self.arena.deinit();
    self.backingAllocator.destroy(self);
}

pub fn main() !void {
    try nw.initializeAndRunStandardProgram(@This(), .{ .name = "Allocation viewer", .ui = false, .papyrus = false });
}

const std = @import("std");
const core = nw.core;
const imgui = nw.vkImgui.api;
const igWidgets = nw.vkImgui.widgets;
