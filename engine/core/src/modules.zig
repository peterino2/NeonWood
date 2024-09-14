// the module startup system.

const std = @import("std");

// a series of comptime functions for letting you select which features are compiled and brought
// into the engine.

pub const ModuleDescription = struct {
    name: []const u8,
    enabledByDefault: bool,
};

pub fn isModuleEnabled(comptime module: ModuleDescription, comptime buildDescription: anytype) bool {
    if (!@hasField(@TypeOf(buildDescription), "enabledModules")) {
        return module.enabledByDefault;
    } else if (@hasField(@TypeOf(buildDescription.enabledModules), module.name)) {
        return @field(buildDescription.enabledModules, module.name);
    } else {
        return module.enabledByDefault;
    }
}

test "isModule in build test" {
    const ModA = ModuleDescription{
        .name = "featureA",
        .enabledByDefault = false,
    };

    const buildDesc: struct {
        enabledModules: struct {
            featureA: bool = true,
        } = .{},
    } = .{};

    std.debug.print("modA enabled = {any}\n", .{isModuleEnabled(ModA, buildDesc)});
}
