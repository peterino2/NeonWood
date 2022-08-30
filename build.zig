// Overview of project management and operation.
//
// Largely inspired by unreal engine's module concept.
//
//  1. entry point to any project is a top-level
//      build.zig file that exists on a project.
//
//  2. this build.zig file shall use relative path to point to
//      the build.zig file of a neonwood engine source folder.
//
//  3. create a top level executable by defining a module/struct as the
//      game startup definition.
//
//  4. the game startup definition can then get modules added onto it
//      via nwbuild.
//
//      eg.
//
//      const nwbuild = @import("../engine/build.zig");
//
//      // creates a nwgame object which contains a ..addExecutable in it's .exe field
//      // pass the name of modules/<your game's main module here>
//      const game = nwbuild.newGame(b, "sample_game"):
//      // all module folders must contain a .zig file that matches the module folder's name.
//      // this file is used to define entry points into the game.
//
//      // the core module is always available
//      game.addModule("core");
//
//      // graphics is a dependency for... pretty much everything. not linking to it will
//      // mean pretty much everything fails compiling.
//      game.addEngineModule("graphics");
//      game.addModule();

const std = @import("std");
const neonwood = @import("engine/build.zig");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = neonwood.createGameExecutable(b) catch unreachable;
    _ = exe;

    _ = target;
    _ = mode;
}
