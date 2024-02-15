const std = @import("std");

pub fn implement_func_for_tagged_union_nonull(
    self: anytype,
    comptime funcName: []const u8,
    comptime returnType: type,
    args: anytype,
) returnType {
    const Self = @TypeOf(self);
    inline for (@typeInfo(std.meta.Tag(Self)).Enum.fields) |field| {
        if (@as(std.meta.Tag(Self), @enumFromInt(field.value)) == self) {
            if (@hasDecl(@TypeOf(@field(self, field.name)), funcName)) {
                return @field(@field(self, field.name), funcName)(args);
            }
        }
    }

    unreachable;
}
