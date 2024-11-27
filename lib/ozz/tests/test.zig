const ozz = @import("ozz");
const std = @import("std");

pub const PlaybackSample = struct {
    animation: *ozz.Animation,
    skeleton: *ozz.Skeleton,
    samplingJob: *ozz.SamplingJob,

    // controller: ozz.PlaybackController,
    //
    allocator: std.mem.Allocator,
    locals: std.ArrayListUnmanaged(ozz.SoaTransform),
    models: std.ArrayListUnmanaged(ozz.Float4x4),

    pub fn create(allocator: std.mem.Allocator) !*@This() {
        const self = try allocator.create(@This());

        return self;
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.destroy(self);
    }
};

test "helloWorld" {
    ozz.hello();
    ozz.startupOzz();
    defer ozz.shutdownOzz();

    // load an ozz file
}
