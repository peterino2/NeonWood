const std = @import("std");
const papyrus = @import("papyrus.zig");
const localization = @import("localization.zig");
const utils = @import("utils.zig");

const c = @import("c.zig");

const PapyrusContext = papyrus.PapyrusContext;
const PapyrusNode = papyrus.PapyrusNode;
const MakeText = localization.MakeText;
const grapvizDotToPng = utils.grapvizDotToPng;

const BmpRenderer = @import("BmpRenderer.zig");
const BmpWriter = BmpRenderer.BmpWriter;

const colors = @import("colors.zig");
const Color = colors.Color;
const ColorRGBA8 = colors.ColorRGBA8;

const ModernStyle = colors.ModernStyle;
const BurnStyle = colors.BurnStyle;

const PapyrusFont = @import("PapyrusFont.zig");
const FontAtlas = PapyrusFont.FontAtlas;

const DynamicPool = @import("pool.zig").DynamicPool;

// ========================  unit tests for papyrus ==========================

test "hierarchy test" {
    var ctx = try PapyrusContext.create(std.testing.allocator);
    defer ctx.deinit();

    std.debug.print(
        "\nsizeof PapyrusNode={d} for a context with 10k widgets, memory usage = {d}M, {d}K\n",
        .{ @sizeOf(PapyrusNode), @sizeOf(PapyrusNode) * 10_000 / 1024 / 1024, (@sizeOf(PapyrusNode) * 10_000 % (1024 * 1024)) / 1024 },
    );

    // example implementation of something mid-sized in this ui.
    {
        // This adds a default slot to the ui library
        // Slots can have children and can set up a few policies such as docking, etc...
        // by default this slot will be free
        var slot = try ctx.addSlot(0);
        ctx.get(slot).text = MakeText("slot1");

        var slot2 = try ctx.addSlot(slot);
        ctx.get(slot2).text = MakeText("slot2");

        var slot3 = try ctx.addSlot(slot);
        ctx.get(slot3).text = MakeText("slot3");

        var slot5 = try ctx.addSlot(slot);
        ctx.get(slot5).text = MakeText("slot5");

        var slot4 = try ctx.addSlot(slot2);
        ctx.get(slot4).text = MakeText("slot4");

        try ctx.writeTree(0, "before.viz");
        try grapvizDotToPng(std.testing.allocator, "before.viz", "before.png");

        try ctx.removeFromParent(slot2);
        ctx.get(try ctx.addSlot(slot3)).text = MakeText("slot7");

        var x = try ctx.addSlot(slot3);

        ctx.get(x).text = MakeText("slot8");
        ctx.get(try ctx.addSlot(x)).text = MakeText("slot9");
        ctx.get(try ctx.addSlot(x)).text = MakeText("slot10");

        try ctx.writeTree(0, "after.viz");
        try grapvizDotToPng(std.testing.allocator, "after.viz", "after.png");
    }

    ctx.tick(0.0016);
}

test "Testing a fullscreen render" {
    var ctx = try PapyrusContext.create(std.testing.allocator);
    defer ctx.deinit();

    var rend = try BmpRenderer.init(std.testing.allocator, ctx, ctx.extent);
    rend.baseColor = ColorRGBA8.fromHex(0x888888ff);
    defer rend.deinit();
    rend.setRenderFile("Saved/frame_fs00.bmp");

    var panel = try ctx.addPanel(0);
    ctx.getPanel(panel).hasTitle = true;
    ctx.getPanel(panel).titleColor = ModernStyle.GreyDark;
    ctx.get(panel).style.backgroundColor = ModernStyle.Grey;
    ctx.get(panel).style.foregroundColor = ModernStyle.BrightGrey;
    ctx.get(panel).style.borderColor = ModernStyle.Yellow;
    ctx.get(panel).pos = .{ .x = 1920 / 4 - 300, .y = 1080 / 4 };
    ctx.get(panel).size = .{ .x = 1920 / 2, .y = 1080 / 2 };

    {
        var panel2 = try ctx.addPanel(panel);
        ctx.getPanel(panel2).hasTitle = false;
        ctx.get(panel2).style = ctx.getRead(panel).style;
        ctx.get(panel2).anchor = .TopLeft;
        ctx.get(panel2).fill = .FillXY;
        ctx.get(panel2).pos = .{ .x = 1, .y = 1 };
        ctx.get(panel2).size = .{ .x = 0.80, .y = 0.80 };
        ctx.getPanel(panel2).titleColor = ModernStyle.GreyDark;
    }

    var panel2 = try ctx.addPanel(panel);
    {
        ctx.getPanel(panel2).hasTitle = false;
        ctx.get(panel2).style = ctx.getRead(panel).style;
        ctx.get(panel2).anchor = .TopRight;
        ctx.get(panel2).fill = .FillY;
        ctx.get(panel2).pos = .{ .x = -105, .y = 1 };
        ctx.get(panel2).size = .{ .x = 100, .y = 0.9 };
        ctx.getPanel(panel2).titleColor = ModernStyle.GreyDark;

        // add some text to this panel
        const text = try ctx.addText(panel, "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.");
        ctx.get(text).style.foregroundColor = ModernStyle.Orange;
        ctx.get(text).pos = .{ .x = 32, .y = 32 };
        ctx.get(text).size = .{ .x = 300, .y = 400 };
    }

    {
        var panel3 = try ctx.addPanel(panel2);
        ctx.getPanel(panel3).hasTitle = true;
        ctx.getPanel(panel3).titleColor = ModernStyle.GreyDark;
        ctx.get(panel3).style = ctx.getRead(panel).style;
        ctx.get(panel3).anchor = .TopLeft;
        ctx.get(panel3).fill = .FillXY;
        ctx.get(panel3).pos = .{ .x = 0, .y = 25 };
        ctx.get(panel3).size = .{ .x = 0.9, .y = 0.9 };
    }

    try rend.render();

    rend.setRenderFile("Saved/frame_fs01.bmp");
    ctx.get(panel).pos = ctx.get(panel).pos.add(.{ .x = 300 });
    try rend.render();

    rend.setRenderFile("Saved/frame_fs02.bmp");
    ctx.get(panel).size = ctx.get(panel).size.add(.{ .x = 300, .y = 200 });
    try rend.render();
}

test "Testing a render" {
    var ctx = try PapyrusContext.create(std.testing.allocator);
    defer ctx.deinit();

    var rend = try BmpRenderer.init(std.testing.allocator, ctx, ctx.extent);
    rend.baseColor = ColorRGBA8.fromHex(0x888888ff);
    defer rend.deinit();
    rend.setRenderFile("Saved/frame.bmp");
    try ctx.fallbackFont.atlas.dumpBufferToFile("Saved/Fallback.bmp");

    var panel = try ctx.addPanel(0);
    ctx.get(panel).style.backgroundColor = ModernStyle.Grey;
    ctx.get(panel).style.foregroundColor = ModernStyle.GreyDark;
    ctx.get(panel).style.borderColor = ModernStyle.Yellow;
    ctx.get(panel).pos = .{ .x = 100, .y = 300 };
    ctx.get(panel).size = .{ .x = 400, .y = 400 };

    var panel2 = try ctx.addPanel(0);
    ctx.get(panel2).text = MakeText("wanker window");
    ctx.getPanel(panel2).hasTitle = true;
    ctx.get(panel2).style = ctx.get(panel).style;
    ctx.get(panel2).pos = .{ .x = 700, .y = 300 };
    ctx.get(panel2).size = .{ .x = 400, .y = 400 };

    var panel3 = try ctx.addPanel(0);
    ctx.get(panel3).text = MakeText("panel 3");
    ctx.getPanel(panel3).hasTitle = true;
    ctx.get(panel3).style = ctx.get(panel).style;
    ctx.get(panel3).pos = .{ .x = 1200, .y = 300 };
    ctx.get(panel3).size = .{ .x = 400, .y = 400 };

    try rend.render();
}

test "basic bmp renderer test" {
    var renderer = try BmpWriter.init(std.testing.allocator, .{ .x = 1980, .y = 1080 });

    renderer.drawRectangle(.Line, .{ .x = 500, .y = 200 }, .{ .x = 700, .y = 500 }, 255, 255, 0);
    renderer.drawRectangle(.Filled, .{}, .{ .x = 420, .y = 69 * 10 }, 69, 42, 69);

    defer renderer.deinit();

    var timer = try std.time.Timer.start();

    const startTime = timer.read();
    var atlas = try FontAtlas.initFromFile(std.testing.allocator, "fonts/ShareTechMono-Regular.ttf", 36);
    try atlas.dumpBufferToFile("Saved/atlas.bmp");
    defer atlas.deinit();

    var atlas2 = try FontAtlas.initFromFile(std.testing.allocator, "fonts/ProggyClean.ttf", 36);
    try atlas2.dumpBufferToFile("Saved/ProggyClean.bmp");
    defer atlas2.deinit();

    const endTime = timer.read();
    const duration = (@as(f64, @floatFromInt(endTime - startTime)) / 1000000000);
    std.debug.print(" duration: {d}\n", .{duration});

    try renderer.writeOut("Saved/test.bmp");
}

test "dynamic pool test" {
    const TestStruct = struct {
        value1: u32 = 0,
        value4: u32 = 0,
        value2: u32 = 0,
        value3: u32 = 0,
    };

    var dynPool = DynamicPool(TestStruct).init(std.testing.allocator);
    defer dynPool.deinit();

    {
        // insert some objects objects
        var count: u32 = 1000000;
        while (count > 0) : (count -= 1) {
            _ = try dynPool.new(.{});
        }

        // Insert 1 randomly add and delete objects another million objects in groups
        var prng = std.rand.DefaultPrng.init(0x1234);
        var rand = prng.random();

        var workBuffer: [5]u32 = .{ 0, 0, 0, 0, 0 };

        count = 1000000;
        while (count > 0) : (count -= 1) {
            const index = rand.int(u32) % 5;
            var i: u32 = 0;
            while (i < index) : (i += 1) {
                workBuffer[i] = try dynPool.new(.{});
            }

            i = 0;
            while (i < index) : (i += 1) {
                dynPool.get(workBuffer[i]).?.*.value1 = 2;
                dynPool.destroy(workBuffer[i]);
            }
        }
    }
}

test "sdf fontAtlas generation" {
    var allocator = std.testing.allocator;
    var atlas = try FontAtlas.initFromFileSDF(allocator, "fonts/ShareTechMono-Regular.ttf", 128);
    defer atlas.deinit();

    try atlas.dumpBufferToFile("Saved/ComicMonoSDF.bmp");
}

test "sdf texture generation" {
    var allocator = std.testing.allocator;
    var font: c.stbtt_fontinfo = undefined;

    var fileContent = try utils.loadFileAlloc("fonts/ComicMono.ttf", 8, allocator);
    defer allocator.free(fileContent);

    _ = c.stbtt_InitFont(&font, fileContent.ptr, c.stbtt_GetFontOffsetForIndex(fileContent.ptr, 0));

    var width: c_int = 0;
    var height: c_int = 0;
    var xoff: c_int = 0;
    var yoff: c_int = 0;

    var pixels = c.stbtt_GetCodepointSDF(
        &font,
        c.stbtt_ScaleForPixelHeight(&font, 50),
        @as(c_int, @intCast('a')),
        6,
        180,
        30,
        &width,
        &height,
        &xoff,
        &yoff,
    );

    var writer = try BmpWriter.init(std.testing.allocator, .{ .x = 1980, .y = 1080 });
    defer writer.deinit();

    var pixelSlice: []const u8 = undefined;
    pixelSlice.ptr = pixels;
    pixelSlice.len = @as(usize, @intCast(width * height));

    writer.blitBlackWhite(pixelSlice, @as(i32, @intCast(width)), @as(i32, @intCast(height)), 32, 32);
    std.debug.print("\n{d}x{d}\n", .{ width, height });

    try writer.writeOut("Saved/sdf_single_char.bmp");
}
