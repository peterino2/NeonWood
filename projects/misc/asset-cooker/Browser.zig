allocator: std.mem.Allocator,
root: ui.NodeHandle = .{},
choosePathBtn: ui.NodeHandle = .{},
path: ui.NodeHandle = .{},
goButton: ui.NodeHandle = .{},
logText: ui.NodeHandle = .{},
logTextData: std.ArrayListUnmanaged(u8) = .{},

pub fn createBottomBar(self: *@This()) !void {
    var ctx = ui.getContext();
    {
        self.goButton = try ctx.addButton(self.root, ">> Go");

        ctx.get(self.goButton).size = .{ .x = 115, .y = 20 };
        ctx.get(self.goButton).pos = .{ .x = -144, .y = -40 };
        ctx.get(self.goButton).anchor = .BotRight;
        try ctx.events.installOnPressedEvent(self.goButton, .onPressed, .Mouse1, self, &onGoButton);
    }

    {
        const subroot = try ctx.addPanel(self.root);
        ctx.get(subroot).anchor = .BotRight;
        ctx.get(subroot).pos = .{ .x = -750, .y = -65 };
        ctx.getPanel(subroot).layoutMode = .Horizontal;
        ctx.get(subroot).justify = .Left;
        ctx.get(subroot).style = ui.papyrus.StyleInvisible;

        self.path = try ctx.addTextEntry_experimental(subroot, "content/");
        ctx.getTextEntry(self.path).textSize = 16;
        ctx.get(self.path).size = .{ .x = 600, .y = 20 };
        ctx.get(self.path).justify = .Left;

        // get cwd and set the text value
        var buffer: [4096]u8 = undefined;
        const path = try std.fs.cwd().realpath("content/", &buffer);
        ctx.getTextEntry(self.path).editText.clearRetainingCapacity();
        try ctx.getTextEntry(self.path).editText.appendSlice(path);

        self.choosePathBtn = try ctx.addButton(subroot, "choose path ...");
        ctx.get(self.choosePathBtn).justify = .Left;
        ctx.get(self.choosePathBtn).size = .{ .x = 115, .y = 20 };
        ctx.getButton(self.choosePathBtn).textSize = 16;
        try ctx.events.installOnPressedEvent(self.choosePathBtn, .onPressed, .Mouse1, self, &selectPath);
    }
}

pub fn createLog(self: *@This()) !void {
    var ctx = ui.getContext();
    const width = 750;
    const height = 600;

    const panelHandle = try ctx.addPanel(self.root);
    ctx.getPanel(panelHandle).hasTitle = false;
    ctx.get(panelHandle).style.borderWidth = 1.1;
    ctx.get(panelHandle).style.borderColor = .{ .r = 0.5, .g = 0.5, .b = 0.5, .a = 1.0 };
    ctx.get(panelHandle).pos = .{ .x = 5, .y = 5 };
    ctx.get(panelHandle).size = .{ .x = width, .y = height };
    // ctx.get(panelHandle).state = .Collapsed;
    self.logText = try ctx.addText(panelHandle, "hello world");
    ctx.get(self.logText).size = .{ .x = width - 10, .y = height - 10 };
    ctx.get(self.logText).pos = .{ .x = 5, .y = 5 };
    ctx.setFont(self.logText, "bitmap");
    ctx.getText(self.logText).textSize = 16;
}

pub fn create(allocator: std.mem.Allocator) !*@This() {
    const self = try allocator.create(@This());
    self.* = .{
        .allocator = allocator,
    };

    var ctx = ui.getContext();

    self.root = try ctx.addPanel(.{});
    ctx.get(self.root).pos = .{ .x = 10, .y = 10 };
    ctx.get(self.root).size = .{ .x = 800, .y = 720 };
    ctx.get(self.root).text = ui.papyrus.MakeText("Asset Cooker");
    ctx.get(self.root).justify = .Left;
    ctx.get(self.root).style.borderColor = ui.papyrus.Color.fromRGB(0x333333);

    const panel = ctx.getPanel(self.root);
    panel.hasTitle = true;
    panel.layoutMode = .Free;
    panel.titleColor = ui.papyrus.Color.fromRGB(0xcccccc);

    try self.createLog();
    try self.createBottomBar();

    return self;
}

pub fn onGoButton(node: ui.NodeHandle, eventType: ui.PressedType, this: ?*anyopaque) ui.HandlerError!void {
    _ = node;
    const self: *@This() = @ptrCast(@alignCast(this));
    const ctx = ui.getContext();

    if (eventType == .onPressed) {
        const path = ctx.getTextEntry(self.path).editText.items;

        self.logTextData.clearRetainingCapacity();
        var writer = self.logTextData.writer(self.allocator);
        writer.print("scanning directory: {s} ...\n", .{path}) catch unreachable;

        var cookFilePath = std.ArrayList(u8).init(self.allocator);
        defer cookFilePath.deinit();

        {
            // walk through all files and list out every single .cook file
            var dir = std.fs.openDirAbsolute(path, .{ .iterate = true }) catch unreachable;
            defer dir.close();

            var walker = dir.walk(ctx.allocator) catch unreachable;
            defer walker.deinit();

            while (walker.next() catch unreachable) |next| {
                switch (next.kind) {
                    .file => {
                        if (std.mem.startsWith(u8, "_cooked", next.path)) {
                            continue;
                        }

                        if (std.mem.endsWith(u8, ".cook", next.path)) {
                            continue;
                        }

                        cookFilePath.clearRetainingCapacity();
                        cookFilePath.appendSlice(next.path) catch unreachable;
                        cookFilePath.appendSlice(".cook") catch unreachable;

                        dir.access(cookFilePath.items, .{}) catch {
                            // writer.print(
                            //     "asset file {s} has no .cook file associated with it. will not cook.\n",
                            //     .{next.path},
                            // ) catch unreachable;

                            assets.cook.generateCookFile(self.allocator, dir, next.path) catch unreachable;

                            continue;
                        };

                        writer.print("  file {s} associated cook file detected \n", .{next.path}) catch unreachable;
                    },
                    else => {},
                }
            }
        }
        ctx.get(self.logText).text = ui.papyrus.LocText.fromUtf8(self.logTextData.items);
    }
}

pub fn selectPath(node: ui.NodeHandle, eventType: ui.PressedType, this: ?*anyopaque) ui.HandlerError!void {
    _ = node;
    if (eventType == .onPressed) {
        core.asyncOpenFolder(.{
            .callbackContext = this,
            .callback = openFileCallback,
        }) catch return {};
    }
}

fn openFileCallback(this: ?*anyopaque, file: ?[]const u8) void {
    const self: *@This() = @ptrCast(@alignCast(this));
    if (file) |f| {
        const ctx = ui.getContext();
        ctx.getTextEntry(self.path).editText.clearRetainingCapacity();
        ctx.getTextEntry(self.path).editText.appendSlice(f) catch unreachable;

        core.engine_log("selected file: {s}", .{f});
    } else {
        core.engine_log("no file selection", .{});
    }
}

pub fn destroy(self: *@This()) void {
    self.logTextData.deinit(self.allocator);
    self.allocator.destroy(self);
}

const neonwood = @import("NeonWood");
const core = neonwood.core;
const ui = neonwood.ui;
const assets = neonwood.assets;
const std = @import("std");
