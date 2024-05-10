const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const storyNode = @import("storyNode.zig");

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    var allocator = std.heap.page_allocator;

    var dialogueTexts = ArrayList([]const u8).init(allocator);
    var speakerNames = AutoHashMap(u32, []const u8).init(allocator);
    var choices = AutoHashMap(u32, []const u32).init(allocator);
    var next = AutoHashMap(u32, u32).init(allocator);

    try dialogueTexts.appendSlice(&.{
        "Hello I am the narrator.", // 0
        "Do you like cats or dogs.", // 1
        "Guess we can't be friends.", // 2
        "You leave in disgust.", //3
        "They taste delicious.", //4
        "You can't choose both, that's stupid", // 5
        "YOU TAKE THAT BACK.", // 6
        "cats", // 7
        "dogs", // 8
        "both", // 9
    });

    try speakerNames.put(6, "chong");
    try choices.put(1, &.{ 7, 8, 9 });

    try next.put(0, 1);
    try next.put(2, 3);
    try next.put(4, 6);
    try next.put(6, 3);
    try next.put(5, 1);

    try next.put(7, 2);
    try next.put(8, 4);
    try next.put(9, 5);

    // -- interactor --

    var currentNode: u32 = 0;
    var shouldBreak: bool = false;
    var buffer: [4096]u8 = undefined;

    while (!shouldBreak) {
        // print out speaker: content
        const name = speakerNames.get(currentNode) orelse "narrator";
        try stdout.print("{s}: {s}\n", .{ name, dialogueTexts.items[currentNode] });

        // if there's choices print out choices
        if (choices.get(currentNode)) |currentChoices| {
            for (currentChoices) |printChoice, i| {
                const choiceContent = if (printChoice < dialogueTexts.items.len)
                    dialogueTexts.items[printChoice]
                else
                    "Unknown choice.";
                try stdout.print("{}: {s}\n", .{ i + 1, choiceContent });
            }
            const chosenValue = while (true) {
                const selection = (try stdin.readUntilDelimiterOrEof(&buffer, '\r')) orelse unreachable;
                try stdin.skipBytes(1, .{});
                const value = std.fmt.parseInt(u32, selection, 10) catch {
                    try stdout.print("Couldn't parse that\r\n", .{});
                    continue;
                };
                if (value < 1 or value > currentChoices.len) {
                    try stdout.print("Invalid selection\r\n", .{});
                    continue;
                }
                break value;
            } else unreachable;
            currentNode = next.get(currentChoices[chosenValue - 1]) orelse unreachable;
        } else {
            _ = try stdin.readUntilDelimiterOrEof(&buffer, '\n');
            currentNode = next.get(currentNode) orelse endLoop: {
                shouldBreak = true;
                break :endLoop 0;
            };
        }
    }

    try stdout.print("bye.\n", .{});
    _ = stdout;
    _ = stdin;
}
