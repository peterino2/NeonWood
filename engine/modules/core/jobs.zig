const std = @import("std");
const Atomic = std.atomic.Atomic;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

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

    pub fn init(allocator: std.mem.Allocator) @This() {
        var self = .{
            .allocator = allocator,
            .workerThread = undefined,
        };

        self.workerThread = std.Thread.spawn(.{}, @This().workerThreadFunc, .{self});

        return self;
    }

    pub fn workerThreadFunc(self: *@This()) void {
        while (true) {
            std.Thread.Futex.wait(&self.futex, self.current);
        }
    }
};

pub const JobContext = struct {
    allocator: std.mem.Allocator, //todo, backed arena allocator would be sick for this.
    thread: ?std.Thread, // a thread that is spawned and assigned when
    func: ?*const fn (*anyopaque, *JobWorker) void = null,
};
