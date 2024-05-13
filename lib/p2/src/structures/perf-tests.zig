const std = @import("std");
const sparse_set = @import("sparse-set.zig");

fn println(comptime fmt: []const u8, args: anytype) void {
    std.debug.print(fmt ++ "\n", args);
}

const LookupPerfContext = struct {
    testName: []const u8 = "lookup perf 1 Billion Accesses",
    dsName: std.ArrayList([]const u8), // name of data structures
    testSizes: std.ArrayList(usize),
    testTimes: std.ArrayList(std.ArrayList(f64)), //

    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{
            .dsName = std.ArrayList([]const u8).init(allocator),
            .testSizes = std.ArrayList(usize).init(allocator),
            .testTimes = std.ArrayList(std.ArrayList(f64)).init(allocator),
        };
    }

    pub fn printResults(self: @This()) void {
        // prints out results in a csv format
        println("Test Results: {s}", .{self.testName});
        std.debug.print("number of elements,", .{});

        for (self.dsName.items) |name| {
            std.debug.print("{s},", .{name});
        }

        std.debug.print("\n", .{});
        std.debug.assert(self.testSizes.items.len == self.testTimes.items.len);

        var i: usize = 0;
        while (i < self.testSizes.items.len) : (i += 1) {
            std.debug.print("{d},", .{self.testSizes.items[i]});
            const times = self.testTimes.items[i];

            for (times.items) |entry| {
                std.debug.print("{d},", .{entry});
            }

            std.debug.print("\n", .{});
        }
    }
};

pub fn LookupPerfTest(allocator: std.mem.Allocator, perfContext: *LookupPerfContext, comptime TestSize: comptime_int, comptime AccessCount: comptime_int) !void {
    var testTimes = std.ArrayList(f64).init(allocator);
    try testTimes.appendSlice(&.{
        0.0,
        0.0,
        0.0,
        0.0,
    });

    const TestPayload = struct {
        touchCount: u32 = 0,
        name: []const u8 = "payload",
    };

    // Doing a test of 1 million accesses to random sparse set handles to one thousand hashmap lookups
    const TestMap = std.AutoHashMap(u32, TestPayload);
    const TestSet = sparse_set.SparseMultiSet(struct {
        obj: TestPayload = .{},
    });
    var timer = try std.time.Timer.start();

    println(" === preparing test with {d} entries === ", .{TestSize});
    var testMap = TestMap.init(allocator);
    defer testMap.deinit();
    var i: usize = 0;
    while (i < TestSize) : (i += 1) {
        try testMap.put(@as(u32, @intCast(i)), .{});
    }
    i = 0;

    var hashMapTime: f64 = 0;

    {
        const startTime = timer.read();
        // random access for 1M.
        while (i < AccessCount) : (i += 1) {
            const id = @as(u32, @intCast(i % TestSize));
            testMap.getEntry(id).?.value_ptr.*.touchCount += 1;
        }
        const endTime = timer.read();
        println("hashMap: {d} accesses executed in {d}s", .{ AccessCount, (@as(f64, @floatFromInt(endTime - startTime)) / 1000000000) });
        hashMapTime = @as(f64, @floatFromInt(endTime - startTime)) / 1000000000; // index 0
        testTimes.items[0] = hashMapTime;
    }

    var hashmap_linear_time: f64 = 0;
    {
        i = 0;
        const startTime = timer.read();
        // random access for 1M.
        while (i < AccessCount) : (i += 1) {
            var iter = testMap.iterator();
            while (iter.next()) |entry| {
                entry.value_ptr.*.touchCount += 1;
                i += 1;
            }
        }
        const endTime = timer.read();
        println("hashMap_linear: {d} accesses executed in {d}s", .{ AccessCount, (@as(f64, @floatFromInt(endTime - startTime)) / 1000000000) });
        hashmap_linear_time = @as(f64, @floatFromInt(endTime - startTime)) / 1000000000;
        testTimes.items[2] = hashmap_linear_time;
    }

    // --- testing sparse sets
    var testSet = TestSet.init(allocator);
    defer testSet.deinit();
    var handlesList = std.ArrayList(sparse_set.SetHandle).init(allocator);

    i = 0;
    while (i < TestSize) : (i += 1) {
        const newHandle = try testSet.createObject(.{});
        try handlesList.append(newHandle);
    }

    var sparseSetTime: f64 = 0;
    i = 0;
    {
        const startTime = timer.read();
        while (i < AccessCount) : (i += 1) {
            testSet.get(handlesList.items[i % TestSize], .obj).?.*.touchCount += 1;
        }
        const endTime = timer.read();
        println("sparseSet: {d} accesses executed in {d}s", .{ AccessCount, (@as(f64, @floatFromInt(endTime - startTime)) / 1000000000) });
        sparseSetTime = @as(f64, @floatFromInt(endTime - startTime)) / 1000000000;
        testTimes.items[1] = sparseSetTime;
    }

    // linear access
    var sparseset_linear_time: f64 = 0;
    i = 0;
    {
        const startTime = timer.read();
        var denseArray = testSet.denseItems(.obj);
        while (i < AccessCount) : (i += 1) {
            denseArray[i % TestSize].touchCount += 1;
        }
        const endTime = timer.read();
        sparseset_linear_time = @as(f64, @floatFromInt(endTime - startTime)) / 1000000000;
        println("sparseSet_linear: {d} accesses executed in {d}s", .{ AccessCount, (@as(f64, @floatFromInt(endTime - startTime)) / 1000000000) });
        testTimes.items[3] = sparseset_linear_time;
    }

    println("random read: sparseSet is {d} times faster than hashmap", .{hashMapTime / sparseSetTime});
    println("sequential read: sparseSet is {d} times faster than hashmap", .{hashmap_linear_time / sparseset_linear_time});

    try perfContext.testTimes.append(testTimes);
    try perfContext.testSizes.append(TestSize);
}

const K = 1000;
const M = 1000 * K;
const G = 1000 * M;

pub fn count(comptime n: anytype) [n]u0 {
    return comptime [1]u0{0} ** n;
}

test "Perf test sparse vs hashmap" {
    // this test does NOT care about freeing memory, just gonna let the arena hit it.
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const arenaAlloc = arena.allocator();

    var context = LookupPerfContext.init(arenaAlloc);
    try context.dsName.append("hashmap random");
    try context.dsName.append("sparseSet random");
    try context.dsName.append("hashmap linear");
    try context.dsName.append("sparseset linear");

    inline for (comptime count(100 - 1), 0..) |_, i| {
        try LookupPerfTest(arenaAlloc, &context, (i + 1) * (100 * K) / 100, 100 * M);
    }

    context.printResults();
}
