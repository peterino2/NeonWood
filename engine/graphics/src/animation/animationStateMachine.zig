states: std.ArrayListUnmanaged(State) = .{},

pub const Transition = struct {
    nextState: u32,
};

pub const State = struct {
    transitions: std.ArrayListUnmanaged(Transition) = .{},

    pub fn deinit(self: *@This()) void {
        self.transitions.deinit(gAllocator);
    }
};

pub fn init(self: *@This()) void {
    _ = self;
}

var gArena: std.heap.ArenaAllocator = undefined;
var gAllocator: std.mem.Allocator = undefined;

pub fn initializeStateMachineHeap(allocator: std.mem.Allocator) void {
    gArena = std.heap.ArenaAllocator.init(allocator);
    gAllocator = gArena.allocator();
}

pub fn deinitStateMachineHeap() void {
    gArena.deinit();
}

const std = @import("std");
const ozz = @import("ozz");
const core = @import("core");
const graphics = @import("../graphics.zig");
const vk_constants = @import("../vk_constants.zig");
const animation_system = @import("animationSystem.zig");
const AnimationSystem = animation_system.PlaybackTrack;
const PlaybackTrack = animation_system.PlaybackTrack;

const AnimationNode = struct {
    playbackRate: f32 = 1.0,
    rootBoneMask: ?core.Name = null, // walking down from root, refers to all inferior bones
    maskMode: enum { none, above, below } = .none,
    weight: f32 = 1.0,
};

test "sketching" {
    const entity = core.createEntity();

    //...
    const animator = entity.addComponent(graphics.Animator);
    animator.setSkeleton("sk_whatever");

    const smb = animator.stateMachineBuilder();
    {
        const state = smb.addState("idle", .{}); // by default it's looping
        {
            const anim = state.addAnim(.{
                .rate = 1.0,
                .mode = .loop,
            });
            anim.setBoneMaskByRoot("torso", 0.0);
        }

        {
            const blend = state.addBlend2d(.{});
            blend.setAnimation("a_walk_right", .{ .x = 1.0, .y = 0.0 });
            blend.setAnimation("a_walk_left", .{ .x = -1.0, .y = 0.0 });
            blend.setAnimation("a_walk_front", .{ .x = 0.0, .y = 1.0 });
            blend.setAnimation("a_walk_back", .{ .x = 0.0, .y = -1.0 });
            blend.setBoneMaskByRoot("pelvis", 0.0);
        }
    }

    _ = // shitty dsl
        \\  idle:[
        \\      anim:
        \\          rate: 1.0,
        \\          mode: looping
        \\      axis2d:
        \\          axis: [
        \\              (0, -1.0, a_look_down),
        \\              (0, 1.0, a_look_down),
        \\              (1.0, 0, a_look_right),
        \\              (-1.0, 0, a_look_left),
        \\          ]
        \\      axis1d:
        \\          axis
        \\      ]
        \\x 
    ;
}
// drives the multiple tracks in the animator
