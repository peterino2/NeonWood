const std = @import("std");
pub const neonwood = @import("../../modules/neonwood.zig");

const core = neonwood.core;

const ArrayListUnmanaged = std.ArrayListUnmanaged;

pub const CGAny = union(enum){
    line: CGLine, // only line is supported right now
    box: CGBox,
    circle: CGCircle,
};

pub const CGBox = struct {

    topLeft: core.Vectorf,
    botRight: core.Vectorf,

    // returns if we're overlapping from this box to the other one.
    pub fn intersectBox(self: @This(), other: CGBox) bool
    {
        // x overlap
        const xrange1 = [_]f32{self.topLeft.x, self.botRight.x};
        const xrange2 = [_]f32{other.topLeft.x, other.botRight.x};

        const yrange1 = [_]f32{self.topLeft.z, self.botRight.z};
        const yrange2 = [_]f32{other.topLeft.z, other.botRight.z};

        const xoverlap = xrange1[0] <= xrange2[1] and xrange1[1] >= xrange2[0];
        const yoverlap = yrange1[0] <= yrange2[1] and yrange1[1] >= yrange2[0];

        return xoverlap and yoverlap;
    }

    // returns intersection of this box and this line
    pub fn intersectLine(self: @This(), other: CGLine) bool
    {
        _ = self;
        _ = other;
        return false;
    }

    // returns true if we intersect this box and the circle
    pub fn intersectCircle(self: @This()) bool 
    {
        _ = self;
        return false;
    }
};

pub const CGCircle = struct {
    point: core.Vectorf,
    radius: f32,
};

pub const CGLine = struct {
    start: core.Vectorf,
    end: core.Vectorf,

    //  done in 2d only using x and z
    pub fn intersectLine(self: @This(), other: CGLine) bool
    {
        if(self.start.x == self.end.x and self.start.z == self.end.z) return false;
        if(other.start.x == other.end.x and other.start.z == other.end.z) return false;

        var x1: f32 = self.start.x;
        var y1: f32 = self.start.z;
        
        var x2: f32 = self.end.x;
        var y2: f32 = self.end.z;

        var x3: f32 = other.start.x;
        var y3: f32 = other.start.z;

        var x4: f32 = other.end.x;
        var y4: f32 = other.end.z;

        var denom: f32 = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1);

        if(denom == 0)
        {
            // this is a parallel line
            return false;
        }

        var ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denom;

        if( ua > 1 or ua < 0)
            return false;

        var ub = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denom;
        if(ub > 1 or ub < 0)
        {
            return false;
        }

        // core.Vector2f{
        //   .x = x1 + ua * (x2 - x1),
        //   .y = y1 + ua * (y2 - y1)
        // };

        return true;
    }
};

/// i have written so much code in domains i've never fucked with before
// in such a short period of time. I'm just going to be fully diving into business logic 
// with these next few subsystems.

// This collision checking algorithm is going to be next level bad.
// but to be perfectly honest.

// But there's barely a week left in this gamejam and there is a LOT 
// to do in terms of actual gameplay mechanics. For now All i need to 
// be able to do is detect walls, and triggers

pub const Collision2D = struct {
    allocator: std.mem.Allocator,
    boxes: ArrayListUnmanaged(CGBox),
    lines: ArrayListUnmanaged(CGLine),
    circles: ArrayListUnmanaged(CGCircle),

    pub fn init(allocator: std.mem.Allocator) @This() {
        var line1 = CGLine{
            .start = core.Vectorf{.x = 1.0, .z = 1.0, .y = 0},
            .end = core.Vectorf{.x = 3.0, .z = 3.0, .y = 0},
        };

        var line2 = CGLine{
            .start = core.Vectorf{.x = 1.0, .z = 3.0, .y = 0},
            .end = core.Vectorf{.x = 3.0, .z = 1.0, .y = 0},
        };

        var line3 = CGLine{
            .start = core.Vectorf{.x = -1.0, .z = -1.0, .y = 0},
            .end = core.Vectorf{.x = -3.0, .z = -3.0, .y = 0},
        };


        core.assert(line1.intersectLine(line2));
        core.assert(line2.intersectLine(line1));
        core.assert(!line1.intersectLine(line3));

        core.engine_logs("INTERSECTION WORKS");

        return .{
            .allocator = allocator,
            .boxes = .{},
            .circles = .{},
            .lines = .{},
        };
    }

    fn iterIntoVec(iter:anytype) !core.Vectorf
    {
        var vec: core.Vectorf = undefined;
        var next: u32 = 0;
        while ( next < 3)  {
            var tok = iter.next().?;
            switch (next) {
                0 => {
                    vec.x = try std.fmt.parseFloat(f32, tok);
                },
                1 => {
                    vec.y = try std.fmt.parseFloat(f32, tok);
                },
                2 => {
                    vec.z = try std.fmt.parseFloat(f32, tok);
                },
                else => {
                    unreachable;
                }
            }
            next += 1;
        }
        return vec;
    }

    fn parseLine(line: []const u8) ?CGAny
    {
        if(line.len < 2) 
            return null;

        var tokens = std.mem.tokenize(u8, line, " ");
        var maybeFirst = tokens.next();

        if(maybeFirst == null)
        {
            return null;
        }

        var first = maybeFirst.?;

        if(std.mem.eql(u8, first, "#"))
        {
            return null;
        }

        if(std.mem.eql(u8, first, "L"))
        {
            var p1 = iterIntoVec(&tokens) catch unreachable;
            var p2 = iterIntoVec(&tokens) catch unreachable;

            return CGAny{
                .line = .{.start = p1, .end = p2},
            };
        }

        return null;
    }

    // loads a collision asset from a file, adding it's collision to the current collision geometry
    pub fn loadCollisionFromFile(self: *@This(), path: []const u8) !void
    {
        var fileContents = try core.loadFileAlloc(path, 1, self.allocator);
        defer self.allocator.free(fileContents);

        var lines = core.splitIntoLines(fileContents);

        while(lines.next()) |line|
        {
            var res = parseLine(line);
            if(res)|r|
            {
                switch(r)
                {
                    .line => |newLine| {
                        try self.lines.append(self.allocator, newLine);
                    },
                    else =>{
                        unreachable;
                    }
                }
            }
        }
    }

    // returns true if it hits something
    pub fn lineTrace(self: @This(), startPoint: core.Vectorf, direction: core.Vectorf, length: f32) bool
    {  
        var traceLine = CGLine{
            .start = startPoint,
            .end = startPoint.add(direction.normalize().fmul(length)),
        };

        for(self.lines.items) |line|
        {
            if(traceLine.intersectLine(line)){
                return true;
            }
        }

        return false;
    }

    pub fn addLine(self: *@This(), start: core.Vectorf, end: core.Vectorf) !*CGLine
    {
        var newLine = CGLine{
            .start = start,
            .end = end,
        };

        try self.lines.append(self.allocator, newLine);
        return &self.lines.items[self.lines.items.len - 1];
    }

    // although we use Vectorfs the y parameter is ignored it's only 2d collisions.
    // only x y coordinates are done
    pub fn addBox(self: *@This(), topLeft: core.Vectorf, botRight: core.Vectorf) !*CGBox
    {
        try self.boxes.append(self.allocator, .{
            .topLeft = topLeft, 
            .botRight = botRight,
        });

        return &self.boxes.items[self.boxes.items.len - 1];
    }

    // although we use Vectorfs the y parameter is ignored it's only 2d collisions.
    pub fn addCircle(self: *@This(), point: core.Vectorf, radius: f32) !*CGCircle 
    {
        try self.circles.append(.{
            .point = point,
            .radius = radius,
        });

        return &self.boxes.items[self.boxes.items.len - 1];
    }

    pub fn clearCollisions(self: *@This()) void
    {
        self.lines.clearRetainingCapacity();
    }
};


// given a plane definition and a point and a direction
// finds the point of intersection if it exists
// returns -1 if the value is invalid
pub fn intersectPlaneAndLine(
    s: core.Vectorf,
    dir: core.Vectorf,
    px: f32,
    py: f32,
    pz: f32,
    d: f32,
) ?core.Vectorf {
    var sx = s.x;
    var sy = s.y;
    var sz = s.z;
    var dn = dir.normalize();
    var dx = dn.x;
    var dy = dn.y;
    var dz = dn.z;
    var denominator = (px*dx + py*dy + pz*dz);
    if(denominator == 0)
        return null;

    var numerator = -1 * (d + px*sx + py*sy + pz * sz);

    var t = numerator / denominator;
    return s.add(dir.fmul(t));
}
