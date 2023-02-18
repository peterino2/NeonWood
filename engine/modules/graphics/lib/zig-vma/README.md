# Zig-VMA

This project provides Zig bindings for the Vulkan Memory Allocator library.

## Using this project

To use this library, first vendor this repository into your project (or use a git submodule).

In your build.zig, use this to link vma to your executable:
```zig
const vma_build = @import("path/to/vma/vma_build.zig");
vma_build.link(exe, "path/to/vk.zig", mode, target);
```

If you are linking vma to a package, use `pkg` to obtain a package for use in dependencies:
```zig
vma_build.pkg(exe.builder, "path/to/vk.zig")
```
If you aren't using `link` to enable the vma package on your root, you will still need to link the C sources with the executable, using this:
```zig
vma_build.linkWithoutModule(exe, mode, target);
```

`vma_config.zig` contains build flags which will be used to configure the project.  It has separate configurations for debug and release builds.  These flags can be modified to tune the library.

Check out [this repository](https://github.com/SpexGuy/sdltest) for an example of the library in use.
