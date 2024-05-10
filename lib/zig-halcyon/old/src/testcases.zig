const std = @import("std");
const dut = @import("storyNode.zig");

pub const simple = struct {
    pub const simple_1 =
        \\$: Hello! #second comment
        \\$: I'm going to ask you a question.
        \\: do you like cats or dogs?
        \\@end
    ;

    pub const simple_2 =
        \\[label1]
        \\$: Hello! #second comment
        \\[label2]
        \\$: I'm going to ask you a question.
        \\: do you like cats or dogs?
        \\@end
    ;

    pub const multiLabel =
        \\[label1]
        \\[label3]
        \\$: Hello! #second comment
        \\[label2]
        \\$: I'm going to ask you a question.
        \\: do you like cats or dogs?
        \\@end
    ;

    pub const duplicateLabel =
        \\[label1]
        \\[label1]
        \\$: Hello! #second comment
        \\[label2]
        \\$: I'm going to ask you a question.
        \\: do you like cats or dogs?
        \\@end
    ;

    pub const duplicateLabel_differentPlace =
        \\[label1]
        \\$: Hello! #second comment
        \\[label1]
        \\[label2]
        \\$: I'm going to ask you a question.
        \\: do you like cats or dogs?
        \\@end
    ;

    pub const set_1: []const []const u8 = &.{
        simple_1,
        simple_2,
        multiLabel,
        duplicateLabel,
        duplicateLabel_differentPlace,
    };
};

pub fn explainStory(story: dut.StoryNodes) !void {
    std.debug.print("\n", .{});
    for (story.textContent.items) |content, i| {
        if (i == 0) continue;
        const node = story.instances.items[i];
        std.debug.assert(node.id == i);
        if (story.conditionalBlock.contains(node)) {
            std.debug.print("{d}> {s}\n", .{ i, content.asUtf8Native() });
        } else {
            if (story.speakerName.get(node)) |speaker| {
                std.debug.print("{d}> STORY_TEXT> {s}: {s} ", .{ i, speaker.asUtf8Native(), content.asUtf8Native() });
            } else {
                std.debug.print("{d}> STORY_TEXT> $: {s} ", .{ i, content.asUtf8Native() });
            }

            if (story.passThrough.items[node.id]) {
                std.debug.print("-", .{});
            }

            if (story.nextNode.get(node)) |next| {
                std.debug.print("-> {d}", .{next.id});
            }
        }

        if (story.choices.get(node)) |choices| {
            std.debug.print("\n", .{});
            for (choices.items) |c| {
                std.debug.print("    -> {d}\n", .{c});
            }
        }
        std.debug.print("\n", .{});
    }

    var iter = story.tags.iterator();

    std.debug.print("\nLabels\n", .{});
    while (iter.next()) |instance| {
        std.debug.print("key: {s} -> {d}\n", .{ instance.key_ptr.*, instance.value_ptr.*.id });
    }

    std.debug.print("\n", .{});
}

test "simple_1" {
    const alloc = std.testing.allocator;
    var i: usize = 0;
    while (i < simple.set_1.len) : (i += 1) {
        var hasError: bool = false;
        var story = dut.NodeParser.DoParse(simple.set_1[i], alloc) catch |err| switch (err) {
            error.DuplicateLabelWarning => {
                if (i == 4) {
                    hasError = true;
                    return undefined;
                } else return error.DuplicateLabelError;
            },
            else => |narrow| return narrow,
        };

        if (!hasError) {
            try explainStory(story);
        }
        story.deinit();
    }
}
