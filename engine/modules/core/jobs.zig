const std = @import("std");
const Atomic = std.atomic.Atomic;
const core = @import("../core.zig");
const ArrayListUnmanaged = std.ArrayListUnmanaged;

// simple test, no manager needed.
// var worker = JobWorker.init(std.mem.Allocator);
// try worker.assignContext(); // errors if the worker is not read
//
pub const JobManager = struct {
    allocator: std.mem.Allocator,
    jobs: ArrayListUnmanaged(*JobContext),
    workers: []JobWorker,
    workersBusy: []bool,
    numCpus: usize,

    pub fn init(allocator: std.mem.Allocator) void {
        var self = JobManager{
            .allocator = allocator,
            .numCpus = std.Thread.getCpuCount() catch 4,
            .jobs = .{},
            .workers = undefined,
        };

        self.workers = self.allocator.alloc(JobWorker, self.numCpus - 1);
        self.workersBusy = self.allocator.alloc(bool, self.numCpus - 1);

        var i: usize = 0;
        while (i < self.workers.len) : (i += 1) {
            self.workers[i] = .{JobWorker.init(self.allocator)};
            self.workersBusy = false;
        }

        return self;
    }
};

pub const JobWorker = struct {
    detached: bool = true, // most threads are detached, completions are handled via callbacks.
    currentJobContext: ?*JobContext = null,
    workerThread: std.Thread,
    futex: Atomic(u32) = Atomic(u32).init(0),
    current: u32 = 0,
    allocator: std.mem.Allocator,

    pub fn wake(self: *JobWorker) void {
        std.Thread.Futex.wake(&self.futex, 1);
    }

    pub fn init(allocator: std.mem.Allocator) !*@This() {
        var self = try allocator.create(JobWorker);

        self.* = .{
            .allocator = allocator,
            .workerThread = try std.Thread.spawn(.{}, @This().workerThreadFunc, .{self}),
        };

        return self;
    }

    pub fn workerThreadFunc(self: *@This()) void {
        core.engine_logs("worker ready");
        while (true) {
            std.Thread.Futex.wait(&self.futex, self.current);
            core.engine_logs("we woke up");
        }
    }
};

pub const JobContext = struct {
    const Self = @This();

    allocator: std.mem.Allocator, //todo, backed arena allocator would be sick for this.
    //func: *const fn (*anyopaque, *JobContext) void,
    func: *const fn (*anyopaque, *JobContext) void,
    capture: []u8 = undefined,
    hasCaptureAlloc: bool = false,

    pub fn new(allocator: std.mem.Allocator, comptime CaptureType: type, capture: CaptureType) !JobContext {
        _ = CaptureType;
        _ = capture;
        if (!@hasDecl(CaptureType, "func")) {
            return error.NoValidLambda;
        }

        const Wrap = struct {
            pub fn wrappedFunc(pointer: *anyopaque, context: *JobContext) void {
                var ptr = @ptrCast(*CaptureType, @alignCast(@alignOf(CaptureType), pointer));
                ptr.func(context);
            }
        };
        _ = Wrap;

        var self = Self{
            .allocator = allocator,
            .func = Wrap.wrappedFunc,
        };

        var ptr = try allocator.create(CaptureType);
        self.capture.len = @sizeOf(CaptureType);
        self.capture.ptr = @ptrCast([*]u8, ptr);
        ptr.* = capture;
        return self;
    }

    pub fn deinit(self: *Self) void {
        if (self.hasCaptureAlloc) {
            // need to use the size to do an anonymous destroy
            //self.allocator.destroy(self.capture.ptr);
            self.allocator.free(self.capture);
        }
    }
};

test "job context create" {}
