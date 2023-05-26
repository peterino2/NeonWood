const std = @import("std");
const neonwood = @import("root").neonwood;
const core = neonwood.core;

pub fn LookupPerfTest(comptime TestSize: comptime_int, comptime AccessCount: comptime_int) !void {
    var allocator = std.heap.c_allocator;
    var prng = std.rand.DefaultPrng.init(12348);
    var rand = prng.random();

    const TestPayload = struct {
        touchCount: u32 = 0,
        name: []const u8 = "payload",
    };

    // Doing a test of 1 million accesses to random sparse set handles to one thousand hashmap lookups
    const TestMap = std.AutoHashMap(u32, TestPayload);
    const TestSet = core.SparseMultiSet(struct {
        obj: TestPayload = .{},
    });
    var timer = try std.time.Timer.start();

    core.engine_log(" === preparing test with {d} entries === ", .{TestSize});
    var testMap = TestMap.init(allocator);
    defer testMap.deinit();
    try core.traceFmtDefault("preparing hashmap with {d} entries", .{TestSize});
    var i: usize = 0;
    while (i < TestSize) : (i += 1) {
        try testMap.put(@intCast(u32, i), .{});
    }
    // core.engine_logs("hashmap prep finished");
    try core.traceFmtDefault("prep complete", .{});
    try core.traceFmtDefault("testing 20M accesses hashMap", .{});
    i = 0;
    _ = rand;
    var hashMapTime: f64 = 0;

    {
        const startTime = timer.read();
        // random access for 1M.
        while (i < AccessCount) : (i += 1) {
            var id = @intCast(u32, i % TestSize);
            testMap.getEntry(id).?.value_ptr.*.touchCount += 1;
        }
        const endTime = timer.read();
        core.engine_log("hashMap: {d} accesses executed in {d}s", .{ AccessCount, (@intToFloat(f64, endTime - startTime) / 1000000000) });
        hashMapTime = @intToFloat(f64, endTime - startTime) / 1000000000;

        // sequential access
        // repetition access
        // insertion/removal
        // existence check
        // memory usage
    }
    try core.traceFmtDefault("hasmap test complete", .{});

    // --- testing sparse sets
    // core.engine_logs("Testing sparse sets");
    try core.traceFmtDefault("preparing sparseSet with {d} entries", .{TestSize});
    var testSet = TestSet.init(allocator);
    defer testSet.deinit();
    var handlesList = std.ArrayList(core.ObjectHandle).init(allocator);

    i = 0;
    while (i < TestSize) : (i += 1) {
        var newHandle = try testSet.createObject(.{});
        try handlesList.append(newHandle);
    }
    // core.engine_logs("sparseSet prep finished");
    try core.traceFmtDefault("prep complete", .{});

    var sparseSetTime: f64 = 0;
    i = 0;
    {
        const startTime = timer.read();
        while (i < AccessCount) : (i += 1) {
            testSet.get(handlesList.items[i % TestSize], .obj).?.*.touchCount += 1;
        }
        const endTime = timer.read();
        core.engine_log("sparseSet: {d} accesses executed in {d}s", .{ AccessCount, (@intToFloat(f64, endTime - startTime) / 1000000000) });
        sparseSetTime = @intToFloat(f64, endTime - startTime) / 1000000000;
    }

    core.engine_log("sparseSet is {d} times faster than hashmap", .{hashMapTime / sparseSetTime});

    // dump trace results
    // try core.dumpDefaultTrace();
}

const K = 1000;
const M = 1000 * K;
const G = 1000 * M;

pub fn main() anyerror!void {
    core.engine_log("Starting up", .{});
    core.start_module();
    defer core.shutdown_module();
    try LookupPerfTest(10, 10 * M);
    try LookupPerfTest(100, 10 * M);
    try LookupPerfTest(1 * K, 10 * M);
    try LookupPerfTest(10 * K, 10 * M);
    try LookupPerfTest(100 * K, 10 * M);
    try LookupPerfTest(200 * K, 10 * M);
}
