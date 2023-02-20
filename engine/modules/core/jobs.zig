const std = @import("std");
const Atomic = std.atomic.Atomic;
const core = @import("../core.zig");
const RingQueueU = core.RingQueueU;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

pub const JobManager = struct {
    allocator: std.mem.Allocator,

    // need a mutex for the jobQueue... todo later
    jobQueue: RingQueueU(JobContext),
    mutex: std.Thread.Mutex = .{},
    workers: []*JobWorker,
    numCpus: usize,

    pub fn init(allocator: std.mem.Allocator) @This() {
        var self = JobManager{
            .allocator = allocator,
            .numCpus = std.Thread.getCpuCount() catch 4,
            .jobQueue = RingQueueU(JobContext).init(allocator, 4096) catch unreachable,
            .workers = undefined,
        };

        self.workers = self.allocator.alloc(*JobWorker, self.numCpus - 2) catch unreachable;

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
        // this context is destroyed by the worker thread after it completes.
        // todo: Job contexts should be part of a fast bump allocation.
        // or some custom allocator that
        var ctx = try JobContext.new(self.allocator, Lambda, capture);
        // core.engine_logs("trying to create job");
        // 2. find a worker and pass it the job context if available
        for (self.workers) |worker| {
            if (!worker.isBusy()) {
                worker.manager = self;
                try worker.assignContext(ctx);
                return;
            }
        }

        // 3. otherwise it goes on the RingQueue
        self.mutex.lock();
        try self.jobQueue.push(ctx);
        self.mutex.unlock();
    }

    pub fn deinit(self: *@This()) void {
        for (self.workers) |worker| {
            worker.deinit();
        }
        self.allocator.free(self.workers);
    }
};

pub const JobWorker = struct {
    detached: bool = true, // most threads are detached, completions are handled via callbacks.
    currentJobContext: ?JobContext = null,
    workerThread: std.Thread,
    futex: Atomic(u32) = Atomic(u32).init(0),
    current: u32 = 0,
    shouldDie: Atomic(bool) = Atomic(bool).init(false),
    busy: Atomic(bool) = Atomic(bool).init(false),
    allocator: std.mem.Allocator,
    workerId: usize = 0,
    manager: ?*JobManager = null,

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

    pub fn isBusy(self: *@This()) bool {
        return self.busy.load(.Acquire);
    }

    pub fn assignContext(self: *@This(), context: JobContext) !void {
        self.busy.store(true, .SeqCst);
        self.currentJobContext = context;
        self.wake();
    }

    pub fn workerThreadFunc(self: *@This()) void {
        while (!self.shouldDie.load(.Acquire)) {
            if (self.currentJobContext != null) {
                self.busy.store(true, .SeqCst);
                var ctx = self.currentJobContext.?;
                ctx.func(ctx.capture.ptr, &ctx);
                ctx.deinit();
                self.currentJobContext = null;
                self.busy.store(false, .SeqCst);
            } else {
                std.Thread.Futex.wait(&self.futex, self.current);
            }

            if (self.manager != null) {
                self.manager.?.mutex.lock();
                if (self.manager.?.jobQueue.count() > 0) {
                    self.currentJobContext = self.manager.?.jobQueue.pop().?;
                }
                self.manager.?.mutex.unlock();
            }
        }

        core.engine_log("worker {d}: dying now", .{self.workerId});
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
    func: *const fn (*anyopaque, *JobContext) void, // todo, add an error for job funcs
    capture: []u8 = undefined,
    hasCaptureAlloc: bool = false,

    pub fn newJob(allocator: std.mem.Allocator, capture: anytype) !JobContext {
        const CaptureType = @TypeOf(capture);
        if (!@hasDecl(CaptureType, "func")) {
            return error.NoValidLambda;
        }

        const Wrap = struct {
            pub fn wrappedFunc(pointer: *anyopaque, context: *JobContext) void {
                var ptr = @ptrCast(*CaptureType, @alignCast(@alignOf(CaptureType), pointer));
                ptr.func(context);
            }
        };

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

    pub fn new(allocator: std.mem.Allocator, comptime CaptureType: type, capture: CaptureType) !JobContext {
        if (!@hasDecl(CaptureType, "func")) {
            return error.NoValidLambda;
        }

        const Wrap = struct {
            pub fn wrappedFunc(pointer: *anyopaque, context: *JobContext) void {
                var ptr = @ptrCast(*CaptureType, @alignCast(@alignOf(CaptureType), pointer));
                ptr.func(context);
            }
        };

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
