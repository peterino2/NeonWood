// top level api for interacting with C
// used as the baseline for mono or ue

const std = @import("std");
const ArrayList = std.ArrayList;
const s = @import("storyNode.zig");
const c = @cImport({
    @cInclude("Halcyon.h");
});

const StoryNodes = s.StoryNodes;
const halc_nodes_t = c.halc_nodes_t;
const halc_strings_array_t = c.halc_strings_array_t;
const HalcStory = c.HalcStory;
const HalcString = c.HalcString;
const HalcInteractor = c.HalcInteractor;
const HalcChoicesList = c.HalcChoicesList;

const Interactor = s.Interactor;
var allocStruct = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = allocStruct.allocator();

const Cstr = ?[*:0]const u8;
const Cstr_checked = [*:0]const u8;

export fn HalcInteractor_Destroy(handle: ?*HalcInteractor) void {
    var interactor = GetInteractorFromHandle(handle);
    interactor.?.*.deinit();

    allocator.destroy(interactor.?);
}

export fn HalcStory_Parse(str: HalcString, ret: ?*c.HalcStory) c_int {
    if (ret == null) return -1;

    return HalcStory_Parse_impl(str, ret.?) catch -1;
}

fn HalcStory_Parse_impl(str: HalcString, ret: *c.HalcStory) !c_int {
    var storyNodes = try allocator.create(StoryNodes);
    errdefer allocator.destroy(storyNodes);

    var strSlice: []const u8 = undefined;
    strSlice.ptr = str.utf8.?;
    strSlice.len = str.len;

    storyNodes.* = try s.NodeParser.DoParse(strSlice, allocator);
    ret.*.nodes = @ptrCast(*halc_nodes_t, storyNodes);
    ret.*.num_nodes = storyNodes.*.instances.items.len;

    return 0;
}

fn StoryNodesIntoHandle(story: ?*StoryNodes) *halc_nodes_t {
    return @ptrCast(*halc_nodes_t, story);
}

fn InteractorIntoHandle(story: ?*Interactor) *c.halc_interactor_t {
    return @ptrCast(*c.halc_interactor_t, story);
}

fn GetStoryNodesFromHandle(story: ?*HalcStory) ?*StoryNodes {
    return @ptrCast(*StoryNodes, @alignCast(8, story.?.nodes.?));
}

fn GetInteractorFromHandle(i: ?*HalcInteractor) ?*Interactor {
    return @ptrCast(*Interactor, @alignCast(@alignOf(Interactor), i.?.interactor.?));
}

export fn HalcStory_Destroy(story: ?*c.HalcStory) void {
    if (story != null) {
        story.?.num_nodes = 0;
        var nodes = GetStoryNodesFromHandle(story.?);
        nodes.?.deinit();
        if (nodes != null)
            allocator.destroy(nodes.?);
    }
}

export fn HalcStory_CreateInteractorFromStart(
    story: ?*HalcStory,
    interactor: ?*HalcInteractor,
) c_int {
    if (story == null) return -1;
    if (interactor == null) return -1;

    var nodes = GetStoryNodesFromHandle(story.?).?;
    var i = allocator.create(Interactor) catch {
        return -1;
    };

    i.* = Interactor.init(nodes, allocator);
    interactor.?.*.interactor = InteractorIntoHandle(i);
    interactor.?.*.id = i.node.id;

    return 0;
}

export fn HalcInteractor_GetStoryText(
    interactor: ?*HalcInteractor,
    ostr: ?*HalcString,
) c_int {
    if (interactor == null) return -1;
    var i = GetInteractorFromHandle(interactor);
    var str = i.?.getCurrentStoryText();
    ostr.?.*.len = str.len;
    ostr.?.*.utf8 = &str[0];
    return 0;
}

export fn HalcInteractor_GetSpeaker(
    interactor: ?*HalcInteractor,
    ostr: ?*HalcString,
) c_int {
    if (interactor == null) return -1;
    var i = GetInteractorFromHandle(interactor);
    var str = i.?.getCurrentSpeaker();
    ostr.?.*.len = str.len;
    ostr.?.*.utf8 = &str[0];
    return 0;
}

export fn HalcInteractor_Next(
    interactor: ?*HalcInteractor,
) c_int {
    if (interactor == null) {
        std.debug.print("Invalid Interactor passed in \n", .{});
        return -1;
    }
    var i = GetInteractorFromHandle(interactor);
    if (i == null) {
        std.debug.print("Unable to get valid interactor from handle \n", .{});
        return -1;
    }
    i.?.*.next() catch {
        std.debug.print("Unable to go next for some reason...\n", .{});
        return -1;
    };
    interactor.?.*.id = i.?.node.id;
    return @intCast(c_int, i.?.node.id);
}

fn GetArrayListFromChoices(array: ?*HalcChoicesList) ?*ArrayList(HalcString) {
    std.debug.print("addr of choicesList From ZIG {}\n", .{array.?.handle.?});
    return @ptrCast(*ArrayList(HalcString), @alignCast(@alignOf(ArrayList(HalcString)), array.?.handle.?));
}

export fn HalcInteractor_GetChoices(
    interactor: ?*HalcInteractor,
    choices: ?*HalcChoicesList,
) c_int {
    errdefer choices = null;
    if (interactor == null) return -1;
    if (choices == null) return -1;
    var maybe_i = GetInteractorFromHandle(interactor);
    if (maybe_i == null) return -1;

    var i = maybe_i.?;

    if (i.story.choices.contains(i.node)) {
        var choiceItems = i.story.choices.get(i.node).?.items;
        var halcStrings = ArrayList(HalcString).init(allocator);

        var index: usize = 0;
        while (index < choiceItems.len) : (index += 1) {
            const nextNode = choiceItems[index];

            var nextNodeString = i.story.getStoryText(nextNode.id) catch {
                std.debug.print("unable to get story text for node {}", .{nextNode});
                return -1;
            };

            halcStrings.append(.{
                .len = nextNodeString.len,
                .utf8 = &nextNodeString[0],
            }) catch {
                std.debug.print("unable to append strings", .{});
                halcStrings.deinit();
                return -1;
            };
        }

        var handle = allocator.create(ArrayList(HalcString)) catch {
            std.debug.print("unable to create list of strings... this is bad\n", .{});
            return -1;
        };
        handle.* = halcStrings;

        choices.?.* = .{
            .len = halcStrings.items.len,
            .strings = &halcStrings.items[0],
            .handle = @ptrCast(*c.halc_strings_array_t, @alignCast(@alignOf(ArrayList(HalcString)), handle)),
        };
        return @intCast(c_int, halcStrings.items.len);
    }
    return -1;
}

export fn HalcInteractor_SelectChoice(
    interactor: ?*HalcInteractor,
    choiceId: usize,
) c_int {
    var maybe_i = GetInteractorFromHandle(interactor);
    if (maybe_i == null) return -1;

    var i = maybe_i.?;

    if (i.story.choices.contains(i.node)) {
        var choiceItems = i.story.choices.get(i.node).?.items;
        var choiceNode = choiceItems[choiceId];
        if (i.node.id < i.story.instances.items.len) {
            i.node = choiceNode;
        } else {
            return -1;
        }
    } else {
        return -1;
    }

    return @intCast(c_int, i.node.id);
}

export fn HalcChoicesList_Destroy(list: ?*HalcChoicesList) void {
    _ = list;
    var x = GetArrayListFromChoices(list.?).?;
    x.deinit();
    allocator.destroy(x);
}
