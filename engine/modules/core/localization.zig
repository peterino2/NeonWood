const std = @import("std");
const name = @import("name.zig");
const Name = name.Name;

pub fn MakeName(comptime utf8: []const u8) Name {
    @setEvalBranchQuota(100000);
    return comptime Name.fromUtf8(utf8);
}
pub var gLocDbRef: ?*anyopaque = null;
pub var gLocDbInterface: *LocDbInterface = undefined;

pub const LocDbErrors = error{
    OutOfMemory,
    UnableToSetLocalization,
    UnknownError,
};

pub const LocDbInterface = struct {

    // Fetches the localized version of the string if it exists
    setLocalization: *const fn (*anyopaque, Name) LocDbErrors!void,
    getLocalized: *const fn (*anyopaque, u32) ?[]const u8,
    createEntry: *const fn (*anyopaque, u32, []const u8) LocDbErrors!u32,

    pub fn from(comptime TargetType: type) void {
        const W = struct {
            pub fn getLocalized(pointer: *anyopaque, key: u32) ?[]const u8 {
                var ptr = @ptrCast(*TargetType, @alignCast(@alignOf(TargetType), pointer));
                return ptr.getLocalized(key);
            }

            pub fn createEntry(pointer: *anyopaque, key: u32, source: []const u8) LocDbErrors!u32 {
                var ptr = @ptrCast(*TargetType, @alignCast(@alignOf(TargetType), pointer));
                try ptr.createEntry(key, source);
            }
        };

        return @This(){
            .getLocalized = W.getLocalized,
            .createEntry = W.createEntry,
        };
    }
};

pub fn setupLocDb(ref: *anyopaque, interface: *LocDbInterface) void {
    gLocDbRef = ref;
    gLocDbInterface = interface;
}

// Anything display should probably be utilizing Text instead of just a normal []const u8,
pub const Text = struct {
    utf8: []const u8,
    localized: ?[]const u8 = null,
    locKey: u32,

    pub fn get(self: *@This()) []const u8 {
        if (gLocDbRef) |locdb| {
            self.localized = gLocDbInterface.getFunc(locdb, self.locKey);
            return self.localized;
        }
    }
};
