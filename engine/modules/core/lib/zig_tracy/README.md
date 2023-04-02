## How to use this binding

1. Copy build_tracy.zig and tracy.zig into your project.
2. In build.zig, import build_tracy.zig and call `link`.
3. If tracy should be enabled, pass the path to the folder containing TracyClient.cpp.
4. Otherwise, pass null as the path to tracy.
5. In your source, use the bindings in tracy.zig to mark zones.  All of the api points continue to exist when tracy is disabled, but they are empty.

For your convenience, the minimal source needed to build tracy client v0.7.8 is vendored in this repo.
The tracy server and further documentation are available in the official tracy repo:

https://github.com/wolfpld/tracy
