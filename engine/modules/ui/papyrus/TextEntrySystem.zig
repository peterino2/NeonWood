// Main text entry engine rooted in papyrus

backingAllocator: std.mem.Allocator,
arena: std.heap.ArenaAllocator,
ctx: *papyrus.Context,
trg: ?*const TextRenderGeometry = null,
cursorResults: ?TextRenderGeometry.HitResults = null,
selected: ?*papyrus.NodeProperty_TextEntry = null,
firstFrame: bool = false,
cursorBlink: bool = true,
cursorBlinkTime: f64 = 0.4,
cursorBlinkResetTime: f64 = 0.4,
insertIndex: u32 = 0,

const std = @import("std");
const papyrus = @import("../papyrus.zig");
const NodeHandle = papyrus.NodeHandle;
const Context = papyrus.Context;
const core = @import("../../core.zig");
const platform = @import("../../platform.zig");
const TextRenderGeometry = @import("textRender/textRenderGeometry.zig");

// couple of things we'll need to do...
pub fn create(ctx: *papyrus.Context, backingAllocator: std.mem.Allocator) !*@This() {
    const self = try backingAllocator.create(@This());

    self.* = .{
        .ctx = ctx,
        .backingAllocator = backingAllocator,
        .arena = std.heap.ArenaAllocator.init(backingAllocator),
    };

    return self;
}

pub fn sendCodePoint(self: *@This(), codepoint: u32) !void {
    const codepoints = @as([4]u8, @bitCast(codepoint));
    if (self.selected) |te| {
        te.editText.insert(self.insertIndex, codepoints[0]) catch unreachable;
        self.insertIndex += 1;
    }
}

pub fn tick(self: *@This(), deltaTime: f64) !void {
    if (self.firstFrame) {
        if (self.trg) |trg| {
            self.firstFrame = false;
            self.cursorResults = trg.getCurrentEndGeo();
        }
    }

    self.cursorBlinkTime -= deltaTime;

    if (self.cursorBlinkTime < 0) {
        self.cursorBlinkTime = self.cursorBlinkResetTime + self.cursorBlinkTime;
        self.cursorBlink = !self.cursorBlink;
    }

    if (self.trg) |trg| {
        self.cursorResults = trg.getGeometryAtIndex(self.insertIndex);
    }
}

pub fn testHits(self: *@This()) !void {
    if (self.trg) |trg| {
        const cursorPos = platform.getInstance().cursorPos;
        self.cursorResults = trg.testHit(cursorPos);
        if (self.cursorResults) |hr| {
            try self.ctx.pushDebugText("text entry hittest found found: line={d} index={d}", .{ hr.line, hr.index });
            self.insertIndex = hr.index;
        }
    }
}

pub fn maybeResetSelection(self: *@This()) void {
    if (self.selected) |te| {
        te.entryState = .Normal;
    }
    self.selected = null;
    self.trg = null;
    self.cursorResults = null;
}

pub fn selectTextForEdit(self: *@This(), node: NodeHandle) void {
    self.maybeResetSelection();
    self.ctx.getTextEntry(node).entryState = .Pressed;
    self.selected = self.ctx.getTextEntry(node);
    self.insertIndex = if (self.insertIndex >= self.selected.?.editText.items.len) 0 else self.insertIndex;
    self.firstFrame = true;
    self.cursorBlink = true;
    self.cursorBlinkTime = self.cursorBlinkResetTime;
}

pub fn destroy(self: *@This()) void {
    self.arena.deinit();
    self.backingAllocator.destroy(self);
}

// ===== key events =====
pub fn sendEscape(self: *@This()) !void {
    core.ui_logs("escape recieved");
    self.maybeResetSelection();
}

pub fn sendEnter(self: *@This()) !void {
    // core.ui_logs("enter recieved");

    if (self.selected) |te| {
        if (te.enterSendsNewline) {
            te.editText.insert(self.insertIndex, '\n') catch unreachable;
            self.insertIndex += 1;
        }
    }
}

pub fn sendTab(self: *@This()) !void {
    _ = self;
    core.ui_logs("tab recieved");
}

pub fn sendBackspace(self: *@This()) !void {
    // core.ui_logs("backspace recieved");
    if (self.selected) |te| {
        if (self.insertIndex == 0) {
            return;
        } else {
            _ = te.editText.orderedRemove(@max(self.insertIndex - 1, 0));
            self.insertIndex -= 1;
        }
    }
}

pub fn sendDelete(self: *@This()) !void {
    core.ui_logs("delete recieved");
    if (self.selected) |te| {
        if (self.insertIndex >= te.editText.items.len) {
            return;
        } else {
            _ = te.editText.orderedRemove(self.insertIndex);
        }
    }
}

pub fn sendRight(self: *@This()) !void {
    core.ui_logs("right recieved");

    if (self.selected) |te| {
        if (self.insertIndex < te.editText.items.len) {
            self.insertIndex = @min(self.insertIndex + 1, te.editText.items.len);
        }
    }
    self.cursorBlinkTime = self.cursorBlinkResetTime;
    self.resetCursorBlink();
}

pub fn sendLeft(self: *@This()) !void {
    core.ui_logs("left recieved");
    if (self.selected) |te| {
        _ = te;
        if (self.insertIndex > 0) {
            self.insertIndex = self.insertIndex - 1;
        }
    }
    self.cursorBlinkTime = self.cursorBlinkResetTime;
    self.resetCursorBlink();
}

fn cursorJumpRelative(self: *@This(), offset: core.Vector2f) !void {
    if (self.selected) |te| {
        _ = te;
        if (self.trg) |trg| {
            if (self.cursorResults) |cr| {
                const jumpTo = cr.characterGeo.pos.add(offset).add(.{ .x = 1.0 });
                if (trg.testHit(jumpTo)) |newCr| {
                    self.cursorResults = newCr;
                    self.insertIndex = newCr.index;
                } else {}
            } else {}
        } else {}
    }
}

pub fn sendUp(self: *@This()) !void {
    core.ui_logs("up recieved");
    if (self.cursorResults) |cr| {
        _ = cr;
        self.cursorJumpRelative(.{ .x = 1.0, .y = self.cursorResults.?.characterGeo.size.y * 1.5 }) catch unreachable;
    }
    self.resetCursorBlink();
}

pub fn sendDown(self: *@This()) !void {
    core.ui_logs("down recieved");
    if (self.cursorResults) |cr| {
        _ = cr;
        self.cursorJumpRelative(.{ .x = 1.0, .y = -self.cursorResults.?.characterGeo.size.y * 0.5 }) catch unreachable;
    }
    self.resetCursorBlink();
}

inline fn resetCursorBlink(self: *@This()) void {
    self.cursorBlinkTime = self.cursorBlinkResetTime;
    self.cursorBlink = true;
}

pub fn sendPageup(self: *@This()) !void {
    _ = self;
    core.ui_logs("pageup recieved");
}

pub fn sendPagedown(self: *@This()) !void {
    _ = self;
    core.ui_logs("pagedown recieved");
}

pub fn sendHome(self: *@This()) !void {
    _ = self;
    core.ui_logs("home recieved");
}

pub fn sendEnd(self: *@This()) !void {
    _ = self;
    core.ui_logs("end recieved");
}
