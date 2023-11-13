// CLI argument parsing library

const std = @import("std");

pub fn ArgParse(comptime T: type) type {
    return struct {
        args: T,
        allocator: std.mem.Allocator,

        pub fn Parse(allocator: std.mem.Allocator, argList: []const []const u8) !*@This() {
            var self: *@This() = try allocator.create(@This());
            self.args = .{};
            self.allocator = allocator;
            var shortBuf: [32]u8 = undefined;
            _ = shortBuf;
            var longBuf: [256]u8 = undefined;

            var i: u32 = 0;
            while (i < argList.len) {
                var a = argList[i];

                inline for (@typeInfo(T).Struct.fields) |field| {
                    var longRef = try std.fmt.bufPrint(&longBuf, "--{s}", .{field.name});

                    if (std.mem.startsWith(u8, a, longRef)) {
                        // check if it has more arguments.
                        if (a.len > longRef.len) {
                            if (a[longRef.len] == '=' and a.len > longRef.len + 1) {
                                var right = a[longRef.len + 1 ..];
                                switch (@typeInfo(field.type)) {
                                    .Bool => {
                                        if (std.mem.eql(u8, right, "true") or
                                            std.mem.eql(u8, right, "t") or
                                            std.mem.eql(u8, right, "True") or
                                            std.mem.eql(u8, right, "T") or
                                            std.mem.eql(u8, right, "1"))
                                        {
                                            @field(self.args, field.name) = true;
                                        } else {
                                            @field(self.args, field.name) = false;
                                        }
                                    },
                                    .Int => {
                                        @field(self.args, field.name) = try std.fmt.parseInt(field.type, right, 10);
                                    },
                                    .Float => {
                                        @field(self.args, field.name) = try std.fmt.parseFloat(field.type, right);
                                    },
                                    .Pointer => |pointer| {
                                        switch (pointer.Size) {
                                            .Slice => {
                                                // i'm just going to assume that it's a u8 slice, i don't support other types here.
                                            },
                                            else => {},
                                        }
                                    },
                                    else => {
                                        @compileError("unable to generate argparse, unsupported struct type in field: " ++ field.name);
                                    },
                                }
                            } else {
                                std.debug.print("Error parsing arguments: Expected value after argument assignment '{s}'\n", .{a});
                                return error.MalformedArgument;
                            }
                        } else {
                            switch (@typeInfo(field.type)) {
                                .Bool => {
                                    @field(self.args, field.name) = true;
                                },
                                .Int, .Float => {
                                    std.debug.print("Error parsing arguments: Expected value '{s}'\n", .{a});
                                    return error.MalformedArgument;
                                },
                                .Pointer => |pointer| {
                                    switch (pointer.Size) {
                                        .Slice => {
                                            // i'm just going to assume that it's a u8 slice, i don't support other types here.
                                            std.debug.print("Error parsing arguments: Expected value '{s}'\n", .{a});
                                            return error.MalformedArgument;
                                        },
                                        else => {},
                                    }
                                },
                                else => {
                                    @compileError("unable to generate argparse, unsupported struct type in field: " ++ field.name);
                                },
                            }
                        }
                        break;
                    }
                }

                i += 1;
            }

            return self;
        }

        pub fn deinit(self: *@This()) void {
            self.allocator.destroy(self);
        }
    };
}

test "test args" {
    const A = struct {
        foo: f32 = 0,
        bar: i32 = 0,
        baz: bool = false,
    };

    var x = try ArgParse(A).Parse(std.testing.allocator, &.{ "--foo=32", "--bar=22", "--baz" });
    std.debug.assert(x.args.foo == 32);
    std.debug.assert(x.args.bar == 22);
    std.debug.assert(x.args.baz == true);

    defer x.deinit();
}
