const std = @import("std");

const core = @import("core");
const Name = core.Name;

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
                var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                return ptr.getLocalized(key);
            }

            pub fn createEntry(pointer: *anyopaque, key: u32, source: []const u8) LocDbErrors!u32 {
                var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                try ptr.createEntry(key, source);
            }

            pub fn setLocalization(pointer: *anyopaque, name: Name) LocDbErrors!void {
                var ptr = @as(*TargetType, @ptrCast(@alignCast(pointer)));
                try ptr.setLocalization(name);
            }
        };

        return @This(){
            .getLocalized = W.getLocalized,
            .createEntry = W.createEntry,
            .setLocalization = W.setLocalization,
        };
    }
};

pub fn setupLocDb(ref: *anyopaque, interface: *LocDbInterface) void {
    gLocDbRef = ref;
    gLocDbInterface = interface;
}

// Anything display should probably be utilizing Text instead of just a normal []const u8,
pub const LocText = struct {
    utf8: []const u8,
    localized: ?[]const u8 = null,
    locKey: u32 = 0,

    pub fn getRead(self: @This()) []const u8 {
        if (self.localized) |localized| {
            return localized;
        }

        if (gLocDbRef) |locdb| {
            return gLocDbInterface.getLocalized(locdb, self.locKey).?;
        }

        return self.utf8;
    }

    pub fn get(self: *@This()) []const u8 {
        if (self.localized) |localized| {
            return localized;
        }

        if (gLocDbRef) |locdb| {
            self.localized = gLocDbInterface.getLocalized(locdb, self.locKey);
            return self.localized.?;
        }

        return self.utf8;
    }

    pub fn fromUtf8(text: []const u8) @This() {
        return .{
            .utf8 = text,
        };
    }

    pub fn fromUtf8Z(text: []const u8) @This() {
        for (text, 0..) |ch, i| {
            if (ch == 0) {
                var slice: []const u8 = undefined;
                slice.ptr = text.ptr;
                slice.len = i;
                return .{
                    .utf8 = slice,
                };
            }
        }

        return .{
            .utf8 = text,
        };
    }
};

// text construction macro
pub fn MakeText(comptime utf8: []const u8) LocText {
    return LocText.fromUtf8(utf8);
}
