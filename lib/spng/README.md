# zig-spng: fast multithreaded png decoding/encoding

zig bindings to the spng library, a more threadsafe solution for pngs than stb
I didn't find one published anywhere so here it is.


## Usage:

Link to your exe with build.zig by calling linkSpng.

```zig
const spngBuild = @import("zig-spng/build.zig");

...

spngBuild.linkSpng(b, myExe);
```

## Decoding a file


```zig

    var decodeBuffer = try allocator.alloc(u8, 500 * 1000 * 1000); // something arbitrarily large
    defer allocator.free(decodeBuffer);

    var decoder2 = try spng.SpngContext.newDecoder();
    defer decoder2.deinit();
    try decoder2.setFile("testpng.png");

    var len = try decoder2.decode(decodeBuffer, spng.SPNG_FMT_RGBA8, spng.SPNG_DECODE_TRNS);
    var header = try decoder2.getHeader();

    std.debug.print("decoded size = {d}\nheader={any}", .{ len, header });
```

output:


```
decoded size = 528540
header=.home.sear.git.zig-cache.o.6c6df69e4cfcdfdde0e33efd51510c3c.cimport.struct_spng_ihdr{ .width = 383, .height = 345, .bit_depth = 8, .color_type = 2, .compression_method = 0, .filter_method = 0, .interlace_method = 0 }
```
