const std = @import("std");

const Endian = enum {
    big,
    little,
};

pub const XxdOptions = struct {
    wordSize: u32 = 8, // in bits
    endian: Endian = .little,
    wordsPerGroup: u32 = 2, // in number of words
    groupsPerLine: u32 = 8, // number of bytes per word
    groupSplit: u32 = 4, // insert a double space every x number of
    showAddress: bool = true,
};

pub fn xxdWrite(
    writer: anytype,
    bytes: []const u8,
    options: XxdOptions,
) !void {
    var wordBuffer: [16]u8 = undefined;
    var wordOffset: usize = 0;

    const bytesPerWord = options.wordSize / 8;

    var wordInGroup: usize = 0;
    var groupInLine: usize = 0;

    for (bytes, 0..) |byte, index| {
        if (wordInGroup == options.wordsPerGroup) {
            if ((groupInLine + 1) % options.groupSplit == 0 and wordInGroup == options.wordsPerGroup) {
                try writer.writeByte(' ');
            }

            try writer.writeByte(' ');

            wordInGroup = 0;
            groupInLine += 1;

            if (groupInLine == options.groupsPerLine) {
                try writer.writeByte('\n');
                groupInLine = 0;
            }
        }

        if (options.showAddress) {
            if (wordInGroup == 0 and wordOffset == 0 and groupInLine == 0) {
                try writer.print("{x:6.0}: ", .{index});
            }
        }

        wordBuffer[wordOffset] = byte;
        wordOffset += 1;
        if (wordOffset == bytesPerWord) {
            // write out the word into the reader according to endian
            var wordOffsetIndex: usize = 0;
            while (wordOffsetIndex < bytesPerWord) : (wordOffsetIndex += 1) {
                const wordByte = if (options.endian == .little)
                    wordBuffer[wordOffsetIndex]
                else
                    wordBuffer[bytesPerWord - 1 - wordOffsetIndex];

                try writeByteAsHex(wordByte, writer);
            }
            wordOffset = 0;
        }

        wordInGroup += 1;
    }

    _ = try writer.write(".\n");
}

inline fn writeByteAsHex(byte: u8, writer: anytype) !void {
    const hex = byteAsHex(byte);
    try writer.writeByte(hex[1]);
    try writer.writeByte(hex[0]);
}

inline fn byteAsHex(byte: u8) [2]u8 {
    var rv: [2]u8 = undefined;
    rv[1] = nibbleAsHex(byte >> 4);
    rv[0] = nibbleAsHex(byte & 0xF);

    return rv;
}

fn nibbleAsHex(nib: u8) u8 {
    if (nib < 10)
        return '0' + nib;
    return 'A' - 10 + nib;
}

test "testing all" {
    std.debug.print("\n", .{});
    const writer = std.io.getStdOut().writer();
    try writeByteAsHex(0x2f, writer);
    std.debug.print("\n\n", .{});
    try xxdWrite(writer, &[_]u8{ 0xab, 0xf2, 0x21, 0x22, 0x43, 0x44, 0x12, 0x33, 0x12, 0x42, 0x22, 0xab, 0xf2, 0x21, 0x22, 0x43, 0x44, 0x12, 0x33, 0x12, 0x42, 0x22, 0xab, 0xf2, 0x21, 0x22, 0x43, 0x44, 0x12, 0x33, 0x12, 0x42, 0x22, 0xab, 0xf2, 0x21, 0x22, 0x43, 0x44, 0x12, 0x33, 0x12, 0x42, 0x22 }, .{});
    std.debug.print("\n", .{});
}
