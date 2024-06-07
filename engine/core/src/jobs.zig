const std = @import("std");
const Atomic = std.atomic.Value;
const core = @import("core.zig");
const tracy = core.tracy;
const RingQueueU = core.RingQueueU;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

const build_opts = @import("root").options;

pub const JobManager = struct {
    allocator: std.mem.Allocator,

    // need a mutex for the jobQueue... todo later
    jobQueue: RingQueueU(JobContext),
    mutex: std.Thread.Mutex = .{},
    jobQueueConcurrent: core.ConcurrentQueueU(JobContext),
    workers: []*JobWorker,
    numCpus: usize,

    pub fn create(allocator: std.mem.Allocator) !*@This() {
        var self = try allocator.create(@This());

        self.* = JobManager{
            .allocator = allocator,
            .numCpus = std.Thread.getCpuCount() catch 4,
            .jobQueue = RingQueueU(JobContext).init(allocator, 4096) catch unreachable,
            .jobQueueConcurrent = core.ConcurrentQueueU(JobContext).initCapacity(allocator, 4096) catch unreachable,
            .workers = undefined,
        };

        self.workers = self.allocator.alloc(*JobWorker, @max(self.numCpus - 2, 4)) catch unreachable;
        core.engine_log("allocating worker count : {d}", .{self.workers.len});

        var i: usize = 0;
        while (i < self.workers.len) : (i += 1) {
            self.workers[i] = JobWorker.init(self.allocator, i) catch unreachable;
            self.workers[i].workerId = i;
            self.workers[i].manager = self;
        }

        return self;
    }

    pub fn newJob(self: *@This(), capture: anytype) !void {
        const Lambda = @TypeOf(capture);
        const ctx = try JobContext.new(self.allocator, Lambda, capture);

        if (build_opts.mutex_job_queue) {
            self.mutex.lock();
            try self.jobQueue.push(ctx);
            self.mutex.unlock();
        } else {
            try self.jobQueueConcurrent.push(ctx);
        }

        for (self.workers) |worker| {
            if (!worker.isBusy()) {
                worker.wake();
                break;
            }
        }
    }

    pub fn destroy(self: *@This()) void {
        for (self.workers) |worker| {
            worker.deinit();
        }
        self.allocator.free(self.workers);

        self.clearJobs();

        self.jobQueue.deinit(self.allocator);
        self.jobQueueConcurrent.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    pub fn clearJobs(self: *@This()) void {
        var jobCtx: ?JobContext = null;

        if (build_opts.mutex_job_queue) {
            self.mutex.lock();
            jobCtx = self.jobQueue.pop();
            self.mutex.unlock();
        } else {
            jobCtx = self.jobQueueConcurrent.pop();
        }

        while (jobCtx) |*c| {
            c.deinit();

            if (build_opts.mutex_job_queue) {
                self.mutex.lock();
                jobCtx = self.jobQueue.pop();
                self.mutex.unlock();
            } else {
                jobCtx = self.jobQueueConcurrent.pop();
            }
        }
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
        // this needs to be re-evaluated, it's nice for system performance but
        // a 1-2ms worst case wake time is kind of unacceptable.
        std.Thread.Futex.wake(&self.futex, 1);
    }

    pub fn init(allocator: std.mem.Allocator, workerNumber: usize) !*@This() {
        const self = try allocator.create(JobWorker);

        self.* = .{
            .allocator = allocator,
            .workerThread = try std.Thread.spawn(.{}, @This().workerThreadFunc, .{self}),
            .workerId = workerNumber,
        };

        return self;
    }

    pub fn isBusy(self: *@This()) bool {
        return self.busy.load(.acquire);
    }

    pub fn assignContext(self: *@This(), context: JobContext) !void {
        self.busy.store(true, .seq_cst);
        self.currentJobContext = context;
        self.wake();
    }

    pub fn workerThreadFunc(self: *@This()) void {
        const printed = std.fmt.allocPrintZ(self.allocator, "WorkerThread_{d}", .{self.workerId}) catch unreachable;
        tracy.InitThread();
        tracy.SetThreadName(@as([*:0]u8, @ptrCast(printed.ptr)));

        self.allocator.free(printed);

        while (!self.shouldDie.load(.acquire)) {
            if (self.currentJobContext != null) {
                self.busy.store(true, .seq_cst);
                var ctx = self.currentJobContext.?;
                ctx.func(ctx.capture, &ctx);
                ctx.deinit();
                self.currentJobContext = null;
                self.busy.store(false, .seq_cst);
            } else {
                std.Thread.Futex.wait(&self.futex, self.current);
            }

            if (self.manager) |manager| {
                if (build_opts.mutex_job_queue) {
                    self.manager.?.mutex.lock();
                    if (self.manager.?.jobQueue.count() > 0) {
                        self.currentJobContext = self.manager.?.jobQueue.pop().?;
                    }
                    self.manager.?.mutex.unlock();
                } else {
                    self.currentJobContext = manager.jobQueueConcurrent.pop();
                }
            }
        }

        if (self.currentJobContext) |*ctx| {
            ctx.deinit();
        }
    }

    pub fn deinit(self: *@This()) void {
        self.shouldDie.store(true, .seq_cst);
        self.wake();
        self.workerThread.join();
        self.allocator.destroy(self);
    }
};

pub const JobContext = struct {
    const Self = @This();

    allocator: std.mem.Allocator, //todo, backed arena allocator would be sick for this.
    func: *const fn (*anyopaque, *JobContext) void, // todo, add an error for job funcs
    capture: *anyopaque = undefined,
    destroyFunc: *const fn (*anyopaque, std.mem.Allocator) void,

    const align8_struct = struct { size: u64 };

    pub fn new(allocator: std.mem.Allocator, comptime CaptureType: type, capture: CaptureType) !JobContext {
        if (!@hasDecl(CaptureType, "func")) {
            return error.NoValidLambda;
        }

        const Wrap = struct {
            pub fn wrappedFunc(pointer: *anyopaque, context: *JobContext) void {
                var ptr = @as(*CaptureType, @ptrCast(@alignCast(pointer)));
                ptr.func(context);
            }

            pub fn wrappedDestroy(ptr: *anyopaque, alloc: std.mem.Allocator) void {
                const p = @as(*CaptureType, @ptrCast(@alignCast(ptr)));
                alloc.destroy(p);
            }
        };

        const self = Self{
            .allocator = allocator,
            .func = Wrap.wrappedFunc,
            .destroyFunc = Wrap.wrappedDestroy,
            .capture = try allocator.create(CaptureType),
        };
        const ptr = @as(*CaptureType, @ptrCast(@alignCast(self.capture)));
        ptr.* = capture;
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.destroyFunc(self.capture, self.allocator);
    }
};
