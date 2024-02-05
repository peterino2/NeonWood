backingAllocator: std.mem.Allocator,
arena: std.heap.ArenaAllocator,

position: core.Vector2f = .{},
geo: GeometryCache = .{},
charHeight: f32 = 0.0,
boundsX: struct {
    left: f32 = 0.0,
    right: f32 = 0.0,
} = .{},

// rather than creating/destroying these lines every single frame
// i'd rather keep the allocations alive.
geoPool: std.ArrayListUnmanaged(GeometryLine) = .{},

const std = @import("std");
const core = @import("../../../core.zig");
const GeometryLine = std.ArrayListUnmanaged(GeometryEntry);
const GeometryCache = std.ArrayListUnmanaged(GeometryLineEntry);

pub const GeometryLineEntry = struct {
    yOffset: f32 = 0,
    lineGeo: GeometryLine = .{},
};

pub const GeometryEntry = struct {
    x: f32,
    width: f32,
    index: u32,
};

// how the fuck do i use This
//
//
// var geo = create...
//
//
// 1... writing phase.
//
// geo.setCharHeight
// while (i < linesOfTextToRender)
//      geo.pushLine(yOffset)
//      for(char in textToRender):
//          geo.addCharGeo(xOffset, width, isValid)
//
// geo.setBoundsX(left, right);
//
// 2... testing phase
//
// var mousePos = getMousePos();
//
// results = geo.testHit(mousePos);
//
// results.line = int, which line the character came from  // we can source this easily from the line index
// results.charIndex = int, index of the actual character in the source //
// results.charGeo =
//      xPos, yPos,
//      xSize, ySize, of character

pub fn addCharGeo(self: *@This(), xOffset: f32, width: f32, charIndex: u32) !void {
    var newCharGeo: GeometryEntry = .{
        .x = xOffset,
        .index = charIndex,
        .width = width,
    };
    try self.geo.items[self.geo.items.len - 1].lineGeo.append(self.arena.allocator(), newCharGeo);
}

pub fn addGeoLine(self: *@This(), yOffset: f32) !void {
    var geoLine = self.recycleOrNewGeoLine();
    geoLine.yOffset = yOffset;
    try self.geo.append(self.arena.allocator(), geoLine);
}

pub const HitResults = struct {
    line: u32 = 0, // 0-indexed line that the character appears in
    index: u32 = 0,
    characterGeo: struct {
        pos: core.Vector2f = .{},
        size: core.Vector2f = .{},
    },
};

pub fn testHit(self: @This(), mouseHit: core.Vector2f) ?HitResults {
    var converted = mouseHit; //mouseHit.sub(self.position);
    if (self.geo.items.len < 1) {
        // core.engine_logs("didnt hit due no geometry");
        return null;
    }

    if (converted.y < self.geo.items[0].yOffset) {
        // core.engine_log("didnt hit due to out of bounds y too high converted.y = {d}  yoffset={d}", .{ converted.y, self.geo.items[0].yOffset });
        return null;
    }

    if (converted.y > self.geo.items[self.geo.items.len - 1].yOffset + self.charHeight) {
        // core.engine_log("didnt hit due to out of bounds y too low converted.y={d} maxy={d}", .{ converted.y, self.geo.items[self.geo.items.len - 1].yOffset + self.charHeight });
        return null;
    }

    if (converted.x < self.boundsX.left or converted.x > self.boundsX.right) {
        // core.engine_log("didnt hit due to out of bounds x converted.x={d} left={d} right={d}", .{ converted.x, self.boundsX.left, self.boundsX.right });
        return null;
    }

    if (self.boundsX.left == self.boundsX.right) {
        core.engine_err("odd boundsX for geometry left:{d} right:{d}", .{ self.boundsX.left, self.boundsX.right });
    }

    if (self.charHeight == 0.0) {
        core.engine_err("bad height value for charHeight {d}", .{self.charHeight});
    }

    // search along the y indexer
    var line: i32 = @as(i32, @intCast(self.geo.items.len)) - 1;
    while (line >= 0) : (line -= 1) {
        var lineEntry = self.geo.items[@intCast(line)];

        // todo this could be binary search
        // we have found our line, search through the line and find the character
        if (converted.y > lineEntry.yOffset) {
            for (lineEntry.lineGeo.items) |charGeo| {
                if (converted.x > charGeo.x and converted.x < charGeo.x + charGeo.width) {
                    // we found our character
                    return .{
                        .line = @intCast(line),
                        .index = charGeo.index,
                        .characterGeo = .{
                            .pos = .{
                                .x = charGeo.x,
                                .y = lineEntry.yOffset,
                            },
                            .size = .{
                                .x = charGeo.width,
                                .y = self.charHeight,
                            },
                        },
                    };
                }
            }
            break;
        }
    }

    return null;
}

pub fn setBoundsX(self: *@This(), left: f32, right: f32) void {
    self.boundsX = .{ .left = left, .right = right };
}

pub fn setCharHeight(self: *@This(), charHeight: f32) void {
    self.charHeight = charHeight;
}

pub fn setPosition(self: *@This(), position: core.Vector2f) void {
    self.position = position;
}

pub fn create(backingAllocator: std.mem.Allocator) !*@This() {
    var self = try backingAllocator.create(@This());
    self.* = .{
        .backingAllocator = backingAllocator,
        .arena = std.heap.ArenaAllocator.init(backingAllocator),
    };
    return self;
}

pub fn resetAllLines(self: *@This()) !void {
    // reverse iterate through the active lines in the geometry
    var i: isize = @as(isize, @intCast(self.geo.items.len)) - 1;
    while (i >= 0) : (i -= 1) {
        try self.returnLine(@intCast(i));
    }
    self.geo.clearRetainingCapacity();
    self.boundsX = .{};
    self.charHeight = 0.0;
}

// get yourself a new GeometryLineEntry
pub fn recycleOrNewGeoLine(self: *@This()) GeometryLineEntry {
    if (self.geoPool.items.len > 0) {
        var newLine = self.geoPool.pop();
        return .{
            .yOffset = 0,
            .lineGeo = newLine,
        };
    } else {
        return .{
            .yOffset = 0,
            .lineGeo = .{},
        };
    }
}

// returns an array back to the geoPool
pub fn returnLine(self: *@This(), lineIndex: usize) !void {
    self.geo.items[lineIndex].lineGeo.clearRetainingCapacity();
    self.geo.items[lineIndex].yOffset = 0;
    try self.geoPool.append(self.arena.allocator(), self.geo.items[lineIndex].lineGeo);
    _ = self.geo.orderedRemove(lineIndex);
}

pub fn destroy(self: *@This()) void {
    self.arena.deinit();
    self.backingAllocator.destroy(self);
}
