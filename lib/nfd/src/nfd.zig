pub const c = @cImport({
    @cInclude("nfd.h");
});

const std = @import("std");

pub const NFDCallbackError = error{
    InvalidPath,
    Unknown,
};

const NFDCallbackFn = *const fn (
    ?*anyopaque,
    ?[]const u8,
) void;

pub const NFDRuntimeOptions = struct {
    singleThreaded: bool = false,
};

pub const AsyncOpenFileDialogArgs = struct {
    filterList: []const u8 = "",
    defaultPath: []const u8 = "",
    callback: NFDCallbackFn,
    callbackContext: ?*anyopaque = null,
};

// There are a couple of incredibly annoying things about NFD.
// this is only for running things in multiple threads.
pub const NFDRuntime = struct {
    allocator: std.mem.Allocator,

    lock: std.Thread.Mutex = .{},

    outPath: [*c]u8 = null,
    nfdPathSet: c.nfdpathset_t = undefined,
    opts: NFDRuntimeOptions = .{},

    runtimeState: union(enum(u8)) {
        none: bool,
        openDialog: struct {
            filterList: []const u8,
            defaultPath: []const u8,
            callback: ?NFDCallbackFn = null,
            callbackContext: ?*anyopaque = null,
        },
        openDialogMultiple: struct {
            filterList: []const u8,
            defaultPath: []const u8,
        },
        saveDialog: struct {
            filterList: []const u8,
            defaultPath: []const u8,
        },
        openFolder: struct {
            defaultPath: []const u8,
        },
    } = .{ .none = false },

    pub fn create(allocator: std.mem.Allocator, options: NFDRuntimeOptions) !*@This() {
        const self = try allocator.create(@This());

        self.* = .{ .allocator = allocator, .opts = options };

        return self;
    }

    pub fn openFolderDialog(self: *@This(), defaultPath: []const u8) ![*c]const u8 {
        self.lock.lock();
        std.debug.assert(self.runtimeState == .none);
        self.runtimeState = .{ .openFolder = .{
            .defaultPath = defaultPath,
        } };
        self.lock.unlock();

        self.blockUntilComplete();

        return self.outPath;
    }

    pub fn openFileDialog(self: *@This(), defaultPath: []const u8, filters: []const u8) ![*c]const u8 {
        self.lock.lock();
        std.debug.assert(self.runtimeState == .none);
        self.runtimeState = .{ .openDialog = .{
            .filterList = filters,
            .defaultPath = defaultPath,
        } };
        self.lock.unlock();

        // a few sleeps here massively decreases cpu block time.
        self.blockUntilComplete();

        return self.outPath;
    }

    pub fn asyncOpenFileDialog(self: *@This(), args: AsyncOpenFileDialogArgs) !void {
        self.lock.lock();
        defer self.lock.unlock();

        switch (self.runtimeState) {
            .none => {
                self.runtimeState = .{ .openDialog = .{
                    .filterList = args.filterList,
                    .defaultPath = args.defaultPath,
                    .callback = args.callback,
                    .callbackContext = args.callbackContext,
                } };
            },
            .openDialog, .openDialogMultiple, .saveDialog, .openFolder => {
                // return dialog already opened error. nfd would returl NFD_ERROR here
                return error.DialogAlreadyOpen;
            },
        }
    }

    fn blockUntilComplete(self: *@This()) void {
        std.time.sleep(1000 * 1000);

        var spinning: bool = true;
        while (spinning) {
            self.lock.lock();
            if (self.runtimeState == .none) {
                spinning = false;
            }
            std.time.sleep(1000 * 1000);
            self.lock.unlock();
        }
    }

    pub fn processMessages(self: *@This()) !void {
        self.lock.lock();
        defer self.lock.unlock();
        switch (self.runtimeState) {
            .none => {},
            .openDialog => |args| {
                const res = c.NFD_OpenDialog(args.filterList.ptr, args.defaultPath.ptr, &self.outPath);
                if (res == c.NFD_CANCEL) {
                    self.outPath = null;
                } else if (res == c.NFD_ERROR) {
                    return error.InvalidFileDialog;
                }
                if (args.callback) |callback| {
                    if (self.outPath != null) {
                        callback(args.callbackContext, std.mem.span(self.outPath));
                    } else {
                        callback(args.callbackContext, null);
                    }
                }
                self.runtimeState = .{ .none = false };
            },
            .openDialogMultiple => {
                return error.NotImplemented;
            },
            .saveDialog => {
                return error.NotImplemented;
            },
            .openFolder => |args| {
                const res = c.NFD_PickFolder(args.defaultPath.ptr, &self.outPath);
                if (res == c.NFD_CANCEL) {
                    self.outPath = null;
                } else if (res == c.NFD_ERROR) {
                    return error.InvalidFileDialog;
                }
                self.runtimeState = .{ .none = false };
            },
        }
    }

    pub fn destroy(self: *@This()) void {
        self.allocator.destroy(self);
    }
};

test "nfd simple test" {
    var runtime = try NFDRuntime.create(std.testing.allocator, .{ .singleThreaded = true });
    defer runtime.destroy();
}
