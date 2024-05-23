pub fn MakeInterface(comptime vtable_declname: []const u8, comptime VTableType: type) type {
    return struct {
        pub const VTableDeclName = vtable_declname;
        pub const VTable = VTableType;

        pub fn Implement(comptime T: type) VTableType {
            return VTableType.Implement(T);
        }
    };
}

pub fn Reference(comptime Interface: type) type {
    return struct {
        ptr: *anyopaque,
        vtable: Interface.VTable,
    };
}

pub fn refFromPtr(comptime Interface: type, ptr: anytype) Reference(Interface) {
    return .{
        .ptr = @ptrCast(ptr),
        .vtable = @field(@TypeOf(ptr.*), Interface.VTableDeclName),
    };
}

test "simple" {
    const std = @import("std");

    const TestInterface = MakeInterface("TestInterfaceVTable", struct {
        testfn1: *const fn (*anyopaque, f64, f64) f64,
        testfn2: *const fn (*anyopaque, []const u8) void,

        pub fn Implement(comptime T: type) @This() {
            const Wrap = struct {
                pub fn testfn1(p: *anyopaque, a: f64, b: f64) f64 {
                    const ptr: *T = @ptrCast(@alignCast(p));
                    return ptr.testfn1(a, b);
                }
                pub fn testfn2(p: *anyopaque, msg: []const u8) void {
                    const ptr: *T = @ptrCast(@alignCast(p));
                    ptr.testfn2(msg);
                }
            };

            inline for (@typeInfo(Wrap).Struct.decls) |d| {
                if (!@hasDecl(T, d.name)) {
                    @compileError(@typeName(T) ++ " is missing implementation of func " ++ d.name);
                }
            }

            return .{
                .testfn1 = Wrap.testfn1,
                .testfn2 = Wrap.testfn2,
            };
        }
    });

    const Test1 = struct {
        name: []const u8,

        pub const TestInterfaceVTable = TestInterface.Implement(@This());

        pub fn testfn1(self: *@This(), a: f64, b: f64) f64 {
            std.debug.print("{s}: a + b == {d}\n", .{ self.name, a + b });
            return a + b;
        }

        pub fn testfn2(self: *@This(), msg: []const u8) void {
            std.debug.print("{s}: msg: {s}\n", .{ self.name, msg });
        }
    };

    const Test2 = struct {
        name: []const u8,

        pub const TestInterfaceVTable = TestInterface.VTable.Implement(@This());

        pub fn testfn1(self: *@This(), a: f64, b: f64) f64 {
            std.debug.print("2>{s}: a * b == {d}\n", .{ self.name, a * b });
            return a * b;
        }

        pub fn testfn2(self: *@This(), msg: []const u8) void {
            std.debug.print("2>{s}: msg: {s}\n", .{ self.name, msg });
        }
    };

    var t1 = Test1{ .name = "test1" };
    var t2 = Test2{ .name = "test2" };

    const refs = [_]Reference(TestInterface){
        refFromPtr(TestInterface, &t1),
        refFromPtr(TestInterface, &t2),
    };
    std.debug.print("\n", .{});

    for (refs) |r| {
        _ = r.vtable.testfn1(r.ptr, 12.0, 24.0);
    }
}
