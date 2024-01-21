ctx: *PapyrusContext,
node: NodeHandle,
n: *const papyrus.PapyrusNode,
drawList: *DrawList,
parentInfo: LayoutInfo,
resolvedSize: Vector2f = .{},
resolvedPos: Vector2f = .{},

const papyrus = @import("papyrus.zig");
const core = @import("root").neonwood.core;

const PapyrusContext = papyrus.PapyrusContext;
const LayoutInfo = papyrus.LayoutInfo;
const Vector2f = core.Vector2f;
const DrawList = PapyrusContext.DrawList;
const NodeHandle = papyrus.NodeHandle;
