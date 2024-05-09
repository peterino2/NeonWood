// CLI argument parsing library

const std = @import("std");

pub fn ParseArgs(comptime T: type) !T {
    var iter = try std.process.argsWithAllocator(std.heap.c_allocator);
    var args: T = .{};

    const shortBuf: [32]u8 = undefined;
    _ = shortBuf;

    var longBuf: [256]u8 = undefined;

    while (iter.next()) |a| {
        inline for (@typeInfo(T).Struct.fields) |field| {
            const longRef = try std.fmt.bufPrint(&longBuf, "--{s}", .{field.name});

            if (std.mem.startsWith(u8, a, longRef)) {
                // check if it has a value argument
                if (a.len > longRef.len) {
                    if (a[longRef.len] == '=' and a.len > longRef.len + 1) {
                        const right = a[longRef.len + 1 ..];
                        switch (@typeInfo(field.type)) {
                            .Bool => {
                                if (std.mem.eql(u8, right, "true") or
                                    std.mem.eql(u8, right, "t") or
                                    std.mem.eql(u8, right, "True") or
                                    std.mem.eql(u8, right, "TRUE") or
                                    std.mem.eql(u8, right, "T") or
                                    std.mem.eql(u8, right, "1"))
                                {
                                    @field(args, field.name) = true;
                                } else if (std.mem.eql(u8, right, "false") or
                                    std.mem.eql(u8, right, "f") or
                                    std.mem.eql(u8, right, "False") or
                                    std.mem.eql(u8, right, "FALSE") or
                                    std.mem.eql(u8, right, "F") or
                                    std.mem.eql(u8, right, "0"))
                                {
                                    @field(args, field.name) = false;
                                } else {
                                    std.debug.print("Error parsing: non-boolean argument", .{});
                                    @field(args, field.name) = false;
                                }
                            },
                            .Int => {
                                @field(args, field.name) = try std.fmt.parseInt(field.type, right, 10);
                            },
                            .Float => {
                                @field(args, field.name) = try std.fmt.parseFloat(field.type, right);
                            },
                            .Pointer => |pointer| {
                                switch (pointer.size) {
                                    .Slice => {
                                        @field(args, field.name) = right;
                                    },
                                    else => {
                                        @compileError("only u8 slices are supported");
                                    },
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
                            @field(args, field.name) = true;
                        },
                        .Int, .Float => {
                            std.debug.print("Error parsing arguments: Expected value '{s}'\n", .{a});
                            return error.MalformedArgument;
                        },
                        .Pointer => |pointer| {
                            switch (pointer.size) {
                                .Slice => {
                                    std.debug.print("Error parsing arguments: Expected value '{s}'\n", .{a});
                                    return error.MalformedArgument;
                                },
                                else => {
                                    @compileError("only u8 slices are supported");
                                },
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
    }

    return args;
}

pub fn main() !void {
    const A = struct {
        foo: f32 = 0,
        bar: i32 = 0,
        baz: bool = false,
        test_file: []const u8 = "",
    };

    var iter = std.process.args();
    const args = try ParseArgs(A, &iter);

    std.debug.print("A: {any}", .{args});
}

test "test args" {
    const A = struct {
        foo: f32 = 0,
        bar: i32 = 0,
        baz: bool = false,
        test_file: []const u8 = "",
    };

    const args = try ParseArgs(A, &.{ "--foo=32", "--bar=22", "--baz", "--test_file=lmao2nova" });

    std.debug.assert(args.foo == 32);
    std.debug.assert(args.bar == 22);
    std.debug.assert(args.baz == true);
    std.debug.assert(std.mem.eql(u8, args.test_file, "lmao2nova"));
}
