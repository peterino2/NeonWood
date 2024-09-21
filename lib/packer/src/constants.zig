const std = @import("std");

const PackerMagicBE: u32 = 0x7061636B; // spells out 'pack' in ascii
const PackerMagicLE: u32 = 0x6B636170; // spells out 'pack' in ascii in little endian

// This is used so we can use a single 32 bit compare at the offset to check if we have the correct offset or not.
// "pack" @ 0x0 == 0x7061636B
pub const PackerMagic = if (std.mem.eql(u8, "pack", &@as([4]u8, @bitCast(PackerMagicBE))))
    PackerMagicBE
else
    PackerMagicLE;

pub const littleEndian = if (std.mem.eql(u8, "pack", &@as([4]u8, @bitCast(PackerMagicBE))))
    false
else
    true;
