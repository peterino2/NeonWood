const std = @import("std");
const p2 = @import("../p2.zig");

const ChildProcess = std.process.Child;

pub const ShellProcess = struct {
    backingAllocator: std.mem.Allocator,

    argv: []const []const u8 = undefined,
    ownedArgs: ?[][]u8 = null,
    stringArena: p2.BumpArena = undefined,
    outputQueue: std.DoublyLinkedList([]const u8) = undefined,

    // initialize the shellprocess from a windows cmd string
    pub fn initCmd(alloc: std.mem.Allocator, cmd: []const u8) !*@This() {
        const self = try alloc.create(@This());
        self.* = .{
            .backingAllocator = alloc,
            .stringArena = try p2.BumpArena.init(alloc),
        };

        try self.splitArgsFromCmd(cmd);

        return self;
    }

    pub fn init(alloc: std.mem.Allocator, argv: []const []const u8) !*@This() {
        const self = try alloc.create(@This());
        self.* = .{
            .backingAllocator = alloc,
            .stringArena = try p2.BumpArena.init(alloc),
        };

        try self.setArgsOwned(argv);

        return self;
    }

    pub fn allocator(self: *@This()) std.mem.Allocator {
        return self.stringArena.allocator();
    }

    pub fn splitArgsFromCmd(self: *@This(), cmd: []const u8) !void {
        var currentCmd = std.ArrayList(u8).init(self.allocator());
        var ownedArgs = std.ArrayList([]u8).init(self.allocator());
        var terminalStack = std.ArrayList(u8).init(self.backingAllocator);
        defer terminalStack.deinit();

        for (cmd) |c| {
            if (terminalStack.items.len == 0) {
                if (c == ' ') {
                    try ownedArgs.append(try currentCmd.toOwnedSlice());
                } else if (c == '\'' or c == '\"') {
                    try terminalStack.append(c);
                    try currentCmd.append(c);
                } else {
                    try currentCmd.append(c);
                }
            } else {
                if (terminalStack.items[terminalStack.items.len - 1] == c) {
                    try currentCmd.append(terminalStack.pop());
                } else {
                    try currentCmd.append(c);
                }
            }
        }

        try ownedArgs.append(try currentCmd.toOwnedSlice());

        self.ownedArgs = try ownedArgs.toOwnedSlice();
        self.argv = @ptrCast(self.ownedArgs.?);
    }

    pub fn setArgsOwned(self: *@This(), args: []const []const u8) !void {
        self.ownedArgs = try self.allocator().alloc([]u8, args.len);

        for (args, 0..) |s, i| {
            self.ownedArgs.?[i] = try self.allocator().dupe(u8, s);
        }

        self.argv = @ptrCast(self.ownedArgs.?);
    }

    pub fn deinit(self: *@This()) void {
        self.stringArena.deinit();
        self.backingAllocator.destroy(self);
    }
};

pub fn runCmd(allocator: std.mem.allocator, cmd: []const []const u8, cwd: []const u8) ![]const u8 {
    var proc: ChildProcess = ChildProcess.init(cmd, allocator);
    proc.cwd = cwd;

    // const result = try std.process.Child.run(.{
    //     .argv = cmd,
    //     .allocator = allocator,
    //     .cwd = p2.getFolder(cwd),
    //     .max_output_bytes = 150 * 1024 * 1024,
    // });

    // return result.;
}
