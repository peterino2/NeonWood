const projectsPath = "projects/";

pub const ProgramInfo = struct {
    ProgramPath: []const u8,
    ProgramName: []const u8,

    pub fn make(comptime projectName: []const u8) @This() {
        return .{
            .ProgramPath = projectsPath ++ projectName ++ "/" ++ projectName ++ ".zig",
            .ProgramName = projectName,
        };
    }
};

pub const programList: []const ProgramInfo = &.{
    ProgramInfo.make("demo"),
};
