const std = @import("std");
const Atomic = std.atomic.Atomic;
const core = @import("../core.zig");
const RingQueueU = core.RingQueueU;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

// simple test, no manager needed.
// var worker = JobWorker.init(std.mem.Allocator);
// try worker.assignContext(); // errors if the worker is not read

pub const JobManager = struct {
    allocator: std.mem.Allocator,

    // need a mutex for the jobQueue... todo later
    jobQueue: RingQueueU(*JobContext),
    workers: []*JobWorker,
    numCpus: usize,

    pub fn init(allocator: std.mem.Allocator) @This() {
        var self = JobManager{
            .allocator = allocator,
            .numCpus = std.Thread.getCpuCount() catch 4,
            .jobQueue = RingQueueU(*JobContext).init(allocator, 4096) catch unreachable,
            .workers = undefined,
        };

        self.workers = self.allocator.alloc(*JobWorker, self.numCpus - 1) catch unreachable;

        var i: usize = 0;
        while (i < self.workers.len) : (i += 1) {
            self.workers[i] = JobWorker.init(self.allocator) catch unreachable;
            self.workers[i].workerId = i;
        }

        return self;
    }

    pub fn newJob(self: *@This(), capture: anytype) !void {
        const Lambda = @TypeOf(capture);
        // 1. create a job context;
        var ctx = try JobContext.new(std.heap.c_allocator, Lambda, capture);
        // 2. find a worker and pass it the job context if available
        var found: ?*JobWorker = null;
        for (self.workers) |*worker| {
            if (!worker.isBusy()) {
                found = worker;
                try worker.assignContext(ctx);
                return;
            }
        }
        // 3. otherwise it goes on the RingQueue
    }
};

pub const JobWorker = struct {
    detached: bool = true, // most threads are detached, completions are handled via callbacks.
    currentJobContext: ?*JobContext = null,
    workerThread: std.Thread,
    futex: Atomic(u32) = Atomic(u32).init(0),
    current: u32 = 0,
    shouldDie: Atomic(bool) = Atomic(bool).init(false),
    busy: Atomic(bool) = Atomic(bool).init(false),
    allocator: std.mem.Allocator,
    workerId: usize = 0,
    manager: ?*JobManager = null,

    pub fn wake(self: *JobWorker) void {
        core.engine_log("waking worker {d}", .{self.workerId});
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

    pub fn isBusy(self: *@This()) void {
        return self.busy.load(.Acquire);
    }

    pub fn assignContext(self: *@This(), context: *JobContext) !void {
        self.busy.store(true, .SeqCst);
        self.currentJobContext = context;
        try self.wake();
    }

    pub fn workerThreadFunc(self: *@This()) void {
        core.engine_log("worker ready {d}", .{self.workerId});

        while (!self.shouldDie.load(.Acquire)) {
            std.Thread.Futex.wait(&self.futex, self.current);
            core.engine_logs("we woke up");

            if (self.currentJobContext != null) {
                self.busy.store(true, .SeqCst);
                var ctx = self.currentJobContext.?;
                ctx.func(ctx.capture.ptr, ctx);
                ctx.deinit();
                self.currentJobContext = null;
                self.busy.store(false, .SeqCst);
            } else {
                core.engine_log("no job available, sleeping again", .{});
            }
        }

        core.engine_logs("We dying now boys");
    }

    pub fn deinit(self: *@This()) void {
        core.engine_logs("deiniting worker");
        self.shouldDie.store(true, .SeqCst);
        self.wake();
        self.workerThread.join();
    }
};

pub const JobContext = struct {
    const Self = @This();

    allocator: std.mem.Allocator, //todo, backed arena allocator would be sick for this.
    //func: *const fn (*anyopaque, *JobContext) void,
    func: fn (*anyopaque, *JobContext) void,
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
