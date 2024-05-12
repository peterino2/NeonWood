ctx: *Context,
node: NodeHandle,
n: *const papyrus.Node,
drawList: *DrawList,
parentInfo: LayoutInfo,
resolvedSize: Vector2f = .{},
resolvedPos: Vector2f = .{},

const papyrus = @import("papyrus.zig");
const core = @import("core");

const Context = papyrus.Context;
const LayoutInfo = papyrus.LayoutInfo;
const Vector2f = core.Vector2f;
const DrawList = papyrus.DrawList;
const NodeHandle = papyrus.NodeHandle;
