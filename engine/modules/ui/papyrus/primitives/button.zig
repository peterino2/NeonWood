//pub const NodeProperty_Button = struct{
displayText: ?LocText = MakeText("Test Button"),
//};

const std = @import("std");
const papyrus = @import("../../papyrus.zig");
const LocText = papyrus.LocText;
const MakeText = papyrus.MakeText;

const PapyrusNode = papyrus.PapyrusNode;

// add button
