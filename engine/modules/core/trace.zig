// trace module
//
// provides performance counters, trace capabilities and error
// logging to the rest of the engine.
//
// also provides a unified Trace context for error handling and recovery.
const std = @import("std");
const names = @import("names.zig");
const string = @import("string.zig");
const engineTime = @import("engineTime.zig");

const ArrayListUnmanaged = std.ArrayListUnmanaged;
const AutoHashMap = std.AutoHashMap;

const MakeName = names.MakeName;
const Name = names.Name;
const Mutex = std.Thread.mutex;

const TraceEntry = struct {
    payload: []const u8,
    timestamp: i128,
};

const Trace = struct {
    name: Name,
    data: ArrayListUnmanaged(TraceEntry) = .{},
    mutex: std.Thread.Mutex = .{},

    // add a trace entry to this trace.
    // this is considered a move operation, the data slice is considered owned by the trace.
    pub fn addEntry(self: *@This(), allocator: std.mem.Allocator, data: []const u8) !*TraceEntry {
        var entry = TraceEntry{
            .data = data,
            .timestamp = engineTime.getEngineTimeStamp(),
        };

        try self.data.append(allocator, entry);
        return &self.data.items[self.data.items.len - 1];
    }

    // adds an entry to this trace, copies the string slice
    pub fn addEntryCopy(self: *@This(), allocator: std.mem.Allocator, data: []const u8) !*TraceEntry {
        var d = try string.dupeString(allocator, data);
        return try self.addEntry(allocator, d);
    }

    // adds an entry by fmt.
    pub fn addEntryFmt(self: *@This(), allocator: std.mem.Allocator, fmt: []const u8, args: anytype) !*TraceEntry {
        var f = try std.fmt.allocPrint(allocator, fmt, args);
        return try self.addEntry(allocator, f);
    }

    pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
        self.data.deinit(allocator);
    }
};

pub const TracesContext = struct {
    allocator: std.mem.Allocator,
    defaultTrace: Trace,
    traces: std.AutoHashMapUnmanaged(u32, *Trace),

    pub fn deinit(self: *@This()) void {
        // todo: loop over traces and call deinit on each trace.
        self.traces.deinit(self.allocator);
    }
};
