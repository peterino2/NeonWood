# OpenAssetImporter Library Binding for Zig

This repo is a build sdk for [Assimp](https://github.com/assimp/assimp) to be used with the Zig build system:

```zig
const std = @import("std");

// Import the SDK
const Assimp = @import("Sdk.zig");

pub fn build(b: *std.Build) void {
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("static-example", null);
    exe.setBuildMode(mode);
    exe.addCSourceFile("src/example.cpp", &[_][]const u8{"-std=c++17"});
    exe.linkLibC();
    exe.linkLibCpp();
    exe.install();
    
    // Create a new instance
    var sdk = Assimp.init(b);

    // And link Assimp statically to our exe and enable a default set of
    // formats.
    sdk.addTo(exe, .static, Assimp.FormatSet.default);
}
```