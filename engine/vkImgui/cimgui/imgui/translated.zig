
pub const __builtin_bswap16 = @import("std").zig.c_builtins.__builtin_bswap16;
pub const __builtin_bswap32 = @import("std").zig.c_builtins.__builtin_bswap32;
pub const __builtin_bswap64 = @import("std").zig.c_builtins.__builtin_bswap64;
pub const __builtin_signbit = @import("std").zig.c_builtins.__builtin_signbit;
pub const __builtin_signbitf = @import("std").zig.c_builtins.__builtin_signbitf;
pub const __builtin_popcount = @import("std").zig.c_builtins.__builtin_popcount;
pub const __builtin_ctz = @import("std").zig.c_builtins.__builtin_ctz;
pub const __builtin_clz = @import("std").zig.c_builtins.__builtin_clz;
pub const __builtin_sqrt = @import("std").zig.c_builtins.__builtin_sqrt;
pub const __builtin_sqrtf = @import("std").zig.c_builtins.__builtin_sqrtf;
pub const __builtin_sin = @import("std").zig.c_builtins.__builtin_sin;
pub const __builtin_sinf = @import("std").zig.c_builtins.__builtin_sinf;
pub const __builtin_cos = @import("std").zig.c_builtins.__builtin_cos;
pub const __builtin_cosf = @import("std").zig.c_builtins.__builtin_cosf;
pub const __builtin_exp = @import("std").zig.c_builtins.__builtin_exp;
pub const __builtin_expf = @import("std").zig.c_builtins.__builtin_expf;
pub const __builtin_exp2 = @import("std").zig.c_builtins.__builtin_exp2;
pub const __builtin_exp2f = @import("std").zig.c_builtins.__builtin_exp2f;
pub const __builtin_log = @import("std").zig.c_builtins.__builtin_log;
pub const __builtin_logf = @import("std").zig.c_builtins.__builtin_logf;
pub const __builtin_log2 = @import("std").zig.c_builtins.__builtin_log2;
pub const __builtin_log2f = @import("std").zig.c_builtins.__builtin_log2f;
pub const __builtin_log10 = @import("std").zig.c_builtins.__builtin_log10;
pub const __builtin_log10f = @import("std").zig.c_builtins.__builtin_log10f;
pub const __builtin_abs = @import("std").zig.c_builtins.__builtin_abs;
pub const __builtin_labs = @import("std").zig.c_builtins.__builtin_labs;
pub const __builtin_llabs = @import("std").zig.c_builtins.__builtin_llabs;
pub const __builtin_fabs = @import("std").zig.c_builtins.__builtin_fabs;
pub const __builtin_fabsf = @import("std").zig.c_builtins.__builtin_fabsf;
pub const __builtin_floor = @import("std").zig.c_builtins.__builtin_floor;
pub const __builtin_floorf = @import("std").zig.c_builtins.__builtin_floorf;
pub const __builtin_ceil = @import("std").zig.c_builtins.__builtin_ceil;
pub const __builtin_ceilf = @import("std").zig.c_builtins.__builtin_ceilf;
pub const __builtin_trunc = @import("std").zig.c_builtins.__builtin_trunc;
pub const __builtin_truncf = @import("std").zig.c_builtins.__builtin_truncf;
pub const __builtin_round = @import("std").zig.c_builtins.__builtin_round;
pub const __builtin_roundf = @import("std").zig.c_builtins.__builtin_roundf;
pub const __builtin_strlen = @import("std").zig.c_builtins.__builtin_strlen;
pub const __builtin_strcmp = @import("std").zig.c_builtins.__builtin_strcmp;
pub const __builtin_object_size = @import("std").zig.c_builtins.__builtin_object_size;
pub const __builtin___memset_chk = @import("std").zig.c_builtins.__builtin___memset_chk;
pub const __builtin_memset = @import("std").zig.c_builtins.__builtin_memset;
pub const __builtin___memcpy_chk = @import("std").zig.c_builtins.__builtin___memcpy_chk;
pub const __builtin_memcpy = @import("std").zig.c_builtins.__builtin_memcpy;
pub const __builtin_expect = @import("std").zig.c_builtins.__builtin_expect;
pub const __builtin_nanf = @import("std").zig.c_builtins.__builtin_nanf;
pub const __builtin_huge_valf = @import("std").zig.c_builtins.__builtin_huge_valf;
pub const __builtin_inff = @import("std").zig.c_builtins.__builtin_inff;
pub const __builtin_isnan = @import("std").zig.c_builtins.__builtin_isnan;
pub const __builtin_isinf = @import("std").zig.c_builtins.__builtin_isinf;
pub const __builtin_isinf_sign = @import("std").zig.c_builtins.__builtin_isinf_sign;
pub const __has_builtin = @import("std").zig.c_builtins.__has_builtin;
pub const __builtin_assume = @import("std").zig.c_builtins.__builtin_assume;
pub const __builtin_unreachable = @import("std").zig.c_builtins.__builtin_unreachable;
pub const __builtin_constant_p = @import("std").zig.c_builtins.__builtin_constant_p;
pub const __builtin_mul_overflow = @import("std").zig.c_builtins.__builtin_mul_overflow;
pub const int_least64_t = i64;
pub const uint_least64_t = u64;
pub const int_fast64_t = i64;
pub const uint_fast64_t = u64;
pub const int_least32_t = i32;
pub const uint_least32_t = u32;
pub const int_fast32_t = i32;
pub const uint_fast32_t = u32;
pub const int_least16_t = i16;
pub const uint_least16_t = u16;
pub const int_fast16_t = i16;
pub const uint_fast16_t = u16;
pub const int_least8_t = i8;
pub const uint_least8_t = u8;
pub const int_fast8_t = i8;
pub const uint_fast8_t = u8;
pub const intmax_t = c_longlong;
pub const uintmax_t = c_ulonglong;
pub const ptrdiff_t = c_longlong;
pub const wchar_t = c_ushort;
pub const max_align_t = extern struct {
    __clang_max_align_nonce1: c_longlong align(8) = @import("std").mem.zeroes(c_longlong),
    __clang_max_align_nonce2: c_longdouble align(16) = @import("std").mem.zeroes(c_longdouble),
};
pub const __builtin_va_list = [*c]u8;
pub const __gnuc_va_list = __builtin_va_list;
pub const va_list = __builtin_va_list;
pub const ImVector_int = c_int;
pub const struct_ImVec4 = extern struct {
    x: f32 = @import("std").mem.zeroes(f32),
    y: f32 = @import("std").mem.zeroes(f32),
    z: f32 = @import("std").mem.zeroes(f32),
    w: f32 = @import("std").mem.zeroes(f32),
};
pub const ImVec4 = struct_ImVec4;
pub const ImTextureID = ?*anyopaque;
pub const ImDrawIdx = c_ushort;
pub const struct_ImVector_ImDrawIdx = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImDrawIdx = @import("std").mem.zeroes([*c]ImDrawIdx),
};
pub const ImVector_ImDrawIdx = struct_ImVector_ImDrawIdx;
pub const struct_ImVec2 = extern struct {
    x: f32 = @import("std").mem.zeroes(f32),
    y: f32 = @import("std").mem.zeroes(f32),
};
pub const ImVec2 = struct_ImVec2;
pub const ImU32 = c_uint;
pub const struct_ImDrawVert = extern struct {
    pos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    uv: ImVec2 = @import("std").mem.zeroes(ImVec2),
    col: ImU32 = @import("std").mem.zeroes(ImU32),
};
pub const ImDrawVert = struct_ImDrawVert;
pub const struct_ImVector_ImDrawVert = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImDrawVert = @import("std").mem.zeroes([*c]ImDrawVert),
};
pub const ImVector_ImDrawVert = struct_ImVector_ImDrawVert;
pub const ImDrawListFlags = c_int;
pub const struct_ImVector_float = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]f32 = @import("std").mem.zeroes([*c]f32),
};
pub const ImVector_float = struct_ImVector_float;
pub const ImWchar16 = c_ushort;
pub const ImWchar = ImWchar16;
pub const struct_ImVector_ImWchar = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImWchar = @import("std").mem.zeroes([*c]ImWchar),
};
pub const ImVector_ImWchar = struct_ImVector_ImWchar;
// cimgui2.h:1156:18: warning: struct demoted to opaque type - has bitfield
pub const struct_ImFontGlyph = opaque {};
pub const ImFontGlyph = struct_ImFontGlyph;
pub const struct_ImVector_ImFontGlyph = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: ?*ImFontGlyph = @import("std").mem.zeroes(?*ImFontGlyph),
};
pub const ImVector_ImFontGlyph = struct_ImVector_ImFontGlyph;
pub const ImFontAtlasFlags = c_int;
pub const struct_ImVector_ImFontPtr = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c][*c]ImFont = @import("std").mem.zeroes([*c][*c]ImFont),
};
pub const ImVector_ImFontPtr = struct_ImVector_ImFontPtr;
pub const struct_ImFontAtlasCustomRect = extern struct {
    Width: c_ushort = @import("std").mem.zeroes(c_ushort),
    Height: c_ushort = @import("std").mem.zeroes(c_ushort),
    X: c_ushort = @import("std").mem.zeroes(c_ushort),
    Y: c_ushort = @import("std").mem.zeroes(c_ushort),
    GlyphID: c_uint = @import("std").mem.zeroes(c_uint),
    GlyphAdvanceX: f32 = @import("std").mem.zeroes(f32),
    GlyphOffset: ImVec2 = @import("std").mem.zeroes(ImVec2),
    Font: [*c]ImFont = @import("std").mem.zeroes([*c]ImFont),
};
pub const ImFontAtlasCustomRect = struct_ImFontAtlasCustomRect;
pub const struct_ImVector_ImFontAtlasCustomRect = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImFontAtlasCustomRect = @import("std").mem.zeroes([*c]ImFontAtlasCustomRect),
};
pub const ImVector_ImFontAtlasCustomRect = struct_ImVector_ImFontAtlasCustomRect;
pub const struct_ImFontConfig = extern struct {
    FontData: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    FontDataSize: c_int = @import("std").mem.zeroes(c_int),
    FontDataOwnedByAtlas: bool = @import("std").mem.zeroes(bool),
    FontNo: c_int = @import("std").mem.zeroes(c_int),
    SizePixels: f32 = @import("std").mem.zeroes(f32),
    OversampleH: c_int = @import("std").mem.zeroes(c_int),
    OversampleV: c_int = @import("std").mem.zeroes(c_int),
    PixelSnapH: bool = @import("std").mem.zeroes(bool),
    GlyphExtraSpacing: ImVec2 = @import("std").mem.zeroes(ImVec2),
    GlyphOffset: ImVec2 = @import("std").mem.zeroes(ImVec2),
    GlyphRanges: [*c]const ImWchar = @import("std").mem.zeroes([*c]const ImWchar),
    GlyphMinAdvanceX: f32 = @import("std").mem.zeroes(f32),
    GlyphMaxAdvanceX: f32 = @import("std").mem.zeroes(f32),
    MergeMode: bool = @import("std").mem.zeroes(bool),
    FontBuilderFlags: c_uint = @import("std").mem.zeroes(c_uint),
    RasterizerMultiply: f32 = @import("std").mem.zeroes(f32),
    EllipsisChar: ImWchar = @import("std").mem.zeroes(ImWchar),
    Name: [40]u8 = @import("std").mem.zeroes([40]u8),
    DstFont: [*c]ImFont = @import("std").mem.zeroes([*c]ImFont),
};
pub const ImFontConfig = struct_ImFontConfig;
pub const struct_ImVector_ImFontConfig = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImFontConfig = @import("std").mem.zeroes([*c]ImFontConfig),
};
pub const ImVector_ImFontConfig = struct_ImVector_ImFontConfig;
pub const struct_ImFontBuilderIO = extern struct {
    FontBuilder_Build: ?*const fn ([*c]ImFontAtlas) callconv(.C) bool = @import("std").mem.zeroes(?*const fn ([*c]ImFontAtlas) callconv(.C) bool),
};
pub const ImFontBuilderIO = struct_ImFontBuilderIO;
pub const struct_ImFontAtlas = extern struct {
    Flags: ImFontAtlasFlags = @import("std").mem.zeroes(ImFontAtlasFlags),
    TexID: ImTextureID = @import("std").mem.zeroes(ImTextureID),
    TexDesiredWidth: c_int = @import("std").mem.zeroes(c_int),
    TexGlyphPadding: c_int = @import("std").mem.zeroes(c_int),
    Locked: bool = @import("std").mem.zeroes(bool),
    TexReady: bool = @import("std").mem.zeroes(bool),
    TexPixelsUseColors: bool = @import("std").mem.zeroes(bool),
    TexPixelsAlpha8: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    TexPixelsRGBA32: [*c]c_uint = @import("std").mem.zeroes([*c]c_uint),
    TexWidth: c_int = @import("std").mem.zeroes(c_int),
    TexHeight: c_int = @import("std").mem.zeroes(c_int),
    TexUvScale: ImVec2 = @import("std").mem.zeroes(ImVec2),
    TexUvWhitePixel: ImVec2 = @import("std").mem.zeroes(ImVec2),
    Fonts: ImVector_ImFontPtr = @import("std").mem.zeroes(ImVector_ImFontPtr),
    CustomRects: ImVector_ImFontAtlasCustomRect = @import("std").mem.zeroes(ImVector_ImFontAtlasCustomRect),
    ConfigData: ImVector_ImFontConfig = @import("std").mem.zeroes(ImVector_ImFontConfig),
    TexUvLines: [64]ImVec4 = @import("std").mem.zeroes([64]ImVec4),
    FontBuilderIO: [*c]const ImFontBuilderIO = @import("std").mem.zeroes([*c]const ImFontBuilderIO),
    FontBuilderFlags: c_uint = @import("std").mem.zeroes(c_uint),
    PackIdMouseCursors: c_int = @import("std").mem.zeroes(c_int),
    PackIdLines: c_int = @import("std").mem.zeroes(c_int),
};
pub const ImFontAtlas = struct_ImFontAtlas;
pub const ImU8 = u8;
pub const struct_ImFont = extern struct {
    IndexAdvanceX: ImVector_float = @import("std").mem.zeroes(ImVector_float),
    FallbackAdvanceX: f32 = @import("std").mem.zeroes(f32),
    FontSize: f32 = @import("std").mem.zeroes(f32),
    IndexLookup: ImVector_ImWchar = @import("std").mem.zeroes(ImVector_ImWchar),
    Glyphs: ImVector_ImFontGlyph = @import("std").mem.zeroes(ImVector_ImFontGlyph),
    FallbackGlyph: ?*const ImFontGlyph = @import("std").mem.zeroes(?*const ImFontGlyph),
    ContainerAtlas: [*c]ImFontAtlas = @import("std").mem.zeroes([*c]ImFontAtlas),
    ConfigData: [*c]const ImFontConfig = @import("std").mem.zeroes([*c]const ImFontConfig),
    ConfigDataCount: c_short = @import("std").mem.zeroes(c_short),
    FallbackChar: ImWchar = @import("std").mem.zeroes(ImWchar),
    EllipsisChar: ImWchar = @import("std").mem.zeroes(ImWchar),
    DotChar: ImWchar = @import("std").mem.zeroes(ImWchar),
    DirtyLookupTables: bool = @import("std").mem.zeroes(bool),
    Scale: f32 = @import("std").mem.zeroes(f32),
    Ascent: f32 = @import("std").mem.zeroes(f32),
    Descent: f32 = @import("std").mem.zeroes(f32),
    MetricsTotalSurface: c_int = @import("std").mem.zeroes(c_int),
    Used4kPagesMap: [2]ImU8 = @import("std").mem.zeroes([2]ImU8),
};
pub const ImFont = struct_ImFont;
pub const struct_ImDrawListSharedData = extern struct {
    TexUvWhitePixel: ImVec2 = @import("std").mem.zeroes(ImVec2),
    Font: [*c]ImFont = @import("std").mem.zeroes([*c]ImFont),
    FontSize: f32 = @import("std").mem.zeroes(f32),
    CurveTessellationTol: f32 = @import("std").mem.zeroes(f32),
    CircleSegmentMaxError: f32 = @import("std").mem.zeroes(f32),
    ClipRectFullscreen: ImVec4 = @import("std").mem.zeroes(ImVec4),
    InitialFlags: ImDrawListFlags = @import("std").mem.zeroes(ImDrawListFlags),
    ArcFastVtx: [48]ImVec2 = @import("std").mem.zeroes([48]ImVec2),
    ArcFastRadiusCutoff: f32 = @import("std").mem.zeroes(f32),
    CircleSegmentCounts: [64]ImU8 = @import("std").mem.zeroes([64]ImU8),
    TexUvLines: [*c]const ImVec4 = @import("std").mem.zeroes([*c]const ImVec4),
};
pub const ImDrawListSharedData = struct_ImDrawListSharedData;
pub const struct_ImVector_ImVec4 = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImVec4 = @import("std").mem.zeroes([*c]ImVec4),
};
pub const ImVector_ImVec4 = struct_ImVector_ImVec4;
pub const struct_ImVector_ImTextureID = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImTextureID = @import("std").mem.zeroes([*c]ImTextureID),
};
pub const ImVector_ImTextureID = struct_ImVector_ImTextureID;
pub const struct_ImVector_ImVec2 = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImVec2 = @import("std").mem.zeroes([*c]ImVec2),
};
pub const ImVector_ImVec2 = struct_ImVector_ImVec2;
pub const struct_ImDrawCmdHeader = extern struct {
    ClipRect: ImVec4 = @import("std").mem.zeroes(ImVec4),
    TextureId: ImTextureID = @import("std").mem.zeroes(ImTextureID),
    VtxOffset: c_uint = @import("std").mem.zeroes(c_uint),
};
pub const ImDrawCmdHeader = struct_ImDrawCmdHeader;
pub const ImDrawChannel = struct_ImDrawChannel;
pub const struct_ImVector_ImDrawChannel = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImDrawChannel = @import("std").mem.zeroes([*c]ImDrawChannel),
};
pub const ImVector_ImDrawChannel = struct_ImVector_ImDrawChannel;
pub const struct_ImDrawListSplitter = extern struct {
    _Current: c_int = @import("std").mem.zeroes(c_int),
    _Count: c_int = @import("std").mem.zeroes(c_int),
    _Channels: ImVector_ImDrawChannel = @import("std").mem.zeroes(ImVector_ImDrawChannel),
};
pub const ImDrawListSplitter = struct_ImDrawListSplitter;
pub const struct_ImDrawList = extern struct {
    CmdBuffer: ImVector_ImDrawCmd = @import("std").mem.zeroes(ImVector_ImDrawCmd),
    IdxBuffer: ImVector_ImDrawIdx = @import("std").mem.zeroes(ImVector_ImDrawIdx),
    VtxBuffer: ImVector_ImDrawVert = @import("std").mem.zeroes(ImVector_ImDrawVert),
    Flags: ImDrawListFlags = @import("std").mem.zeroes(ImDrawListFlags),
    _VtxCurrentIdx: c_uint = @import("std").mem.zeroes(c_uint),
    _Data: [*c]const ImDrawListSharedData = @import("std").mem.zeroes([*c]const ImDrawListSharedData),
    _OwnerName: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    _VtxWritePtr: [*c]ImDrawVert = @import("std").mem.zeroes([*c]ImDrawVert),
    _IdxWritePtr: [*c]ImDrawIdx = @import("std").mem.zeroes([*c]ImDrawIdx),
    _ClipRectStack: ImVector_ImVec4 = @import("std").mem.zeroes(ImVector_ImVec4),
    _TextureIdStack: ImVector_ImTextureID = @import("std").mem.zeroes(ImVector_ImTextureID),
    _Path: ImVector_ImVec2 = @import("std").mem.zeroes(ImVector_ImVec2),
    _CmdHeader: ImDrawCmdHeader = @import("std").mem.zeroes(ImDrawCmdHeader),
    _Splitter: ImDrawListSplitter = @import("std").mem.zeroes(ImDrawListSplitter),
    _FringeScale: f32 = @import("std").mem.zeroes(f32),
};
pub const ImDrawList = struct_ImDrawList;
pub const ImDrawCallback = ?*const fn ([*c]const ImDrawList, [*c]const ImDrawCmd) callconv(.C) void;
pub const struct_ImDrawCmd = extern struct {
    ClipRect: ImVec4 = @import("std").mem.zeroes(ImVec4),
    TextureId: ImTextureID = @import("std").mem.zeroes(ImTextureID),
    VtxOffset: c_uint = @import("std").mem.zeroes(c_uint),
    IdxOffset: c_uint = @import("std").mem.zeroes(c_uint),
    ElemCount: c_uint = @import("std").mem.zeroes(c_uint),
    UserCallback: ImDrawCallback = @import("std").mem.zeroes(ImDrawCallback),
    UserCallbackData: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
};
pub const ImDrawCmd = struct_ImDrawCmd;
pub const struct_ImVector_ImDrawCmd = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImDrawCmd = @import("std").mem.zeroes([*c]ImDrawCmd),
};
pub const ImVector_ImDrawCmd = struct_ImVector_ImDrawCmd;
pub const struct_ImDrawChannel = extern struct {
    _CmdBuffer: ImVector_ImDrawCmd = @import("std").mem.zeroes(ImVector_ImDrawCmd),
    _IdxBuffer: ImVector_ImDrawIdx = @import("std").mem.zeroes(ImVector_ImDrawIdx),
};
pub const ImGuiID = c_uint;
pub const ImGuiViewportFlags = c_int;
pub const ImDrawData = struct_ImDrawData;
pub const struct_ImGuiViewport = extern struct {
    ID: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    Flags: ImGuiViewportFlags = @import("std").mem.zeroes(ImGuiViewportFlags),
    Pos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    Size: ImVec2 = @import("std").mem.zeroes(ImVec2),
    WorkPos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    WorkSize: ImVec2 = @import("std").mem.zeroes(ImVec2),
    DpiScale: f32 = @import("std").mem.zeroes(f32),
    ParentViewportId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    DrawData: [*c]ImDrawData = @import("std").mem.zeroes([*c]ImDrawData),
    RendererUserData: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    PlatformUserData: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    PlatformHandle: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    PlatformHandleRaw: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    PlatformRequestMove: bool = @import("std").mem.zeroes(bool),
    PlatformRequestResize: bool = @import("std").mem.zeroes(bool),
    PlatformRequestClose: bool = @import("std").mem.zeroes(bool),
};
pub const ImGuiViewport = struct_ImGuiViewport;
pub const struct_ImDrawData = extern struct {
    Valid: bool = @import("std").mem.zeroes(bool),
    CmdListsCount: c_int = @import("std").mem.zeroes(c_int),
    TotalIdxCount: c_int = @import("std").mem.zeroes(c_int),
    TotalVtxCount: c_int = @import("std").mem.zeroes(c_int),
    CmdLists: [*c][*c]ImDrawList = @import("std").mem.zeroes([*c][*c]ImDrawList),
    DisplayPos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    DisplaySize: ImVec2 = @import("std").mem.zeroes(ImVec2),
    FramebufferScale: ImVec2 = @import("std").mem.zeroes(ImVec2),
    OwnerViewport: [*c]ImGuiViewport = @import("std").mem.zeroes([*c]ImGuiViewport),
};
pub const struct_ImVector_ImU32 = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImU32 = @import("std").mem.zeroes([*c]ImU32),
};
pub const ImVector_ImU32 = struct_ImVector_ImU32;
pub const struct_ImFontGlyphRangesBuilder = extern struct {
    UsedChars: ImVector_ImU32 = @import("std").mem.zeroes(ImVector_ImU32),
};
pub const ImFontGlyphRangesBuilder = struct_ImFontGlyphRangesBuilder;
pub const struct_ImColor = extern struct {
    Value: ImVec4 = @import("std").mem.zeroes(ImVec4),
};
pub const ImColor = struct_ImColor;
pub const ImGuiConfigFlags = c_int;
pub const ImGuiBackendFlags = c_int;
pub const struct_ImGuiPlatformImeData = extern struct {
    WantVisible: bool = @import("std").mem.zeroes(bool),
    InputPos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    InputLineHeight: f32 = @import("std").mem.zeroes(f32),
};
pub const ImGuiPlatformImeData = struct_ImGuiPlatformImeData;
pub const ImGuiModFlags = c_int;
pub const struct_ImGuiKeyData = extern struct {
    Down: bool = @import("std").mem.zeroes(bool),
    DownDuration: f32 = @import("std").mem.zeroes(f32),
    DownDurationPrev: f32 = @import("std").mem.zeroes(f32),
    AnalogValue: f32 = @import("std").mem.zeroes(f32),
};
pub const ImGuiKeyData = struct_ImGuiKeyData;
pub const ImU16 = c_ushort;
pub const ImS8 = i8;
pub const struct_ImGuiIO = extern struct {
    ConfigFlags: ImGuiConfigFlags = @import("std").mem.zeroes(ImGuiConfigFlags),
    BackendFlags: ImGuiBackendFlags = @import("std").mem.zeroes(ImGuiBackendFlags),
    DisplaySize: ImVec2 = @import("std").mem.zeroes(ImVec2),
    DeltaTime: f32 = @import("std").mem.zeroes(f32),
    IniSavingRate: f32 = @import("std").mem.zeroes(f32),
    IniFilename: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    LogFilename: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    MouseDoubleClickTime: f32 = @import("std").mem.zeroes(f32),
    MouseDoubleClickMaxDist: f32 = @import("std").mem.zeroes(f32),
    MouseDragThreshold: f32 = @import("std").mem.zeroes(f32),
    KeyRepeatDelay: f32 = @import("std").mem.zeroes(f32),
    KeyRepeatRate: f32 = @import("std").mem.zeroes(f32),
    UserData: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    Fonts: [*c]ImFontAtlas = @import("std").mem.zeroes([*c]ImFontAtlas),
    FontGlobalScale: f32 = @import("std").mem.zeroes(f32),
    FontAllowUserScaling: bool = @import("std").mem.zeroes(bool),
    FontDefault: [*c]ImFont = @import("std").mem.zeroes([*c]ImFont),
    DisplayFramebufferScale: ImVec2 = @import("std").mem.zeroes(ImVec2),
    ConfigDockingNoSplit: bool = @import("std").mem.zeroes(bool),
    ConfigDockingWithShift: bool = @import("std").mem.zeroes(bool),
    ConfigDockingAlwaysTabBar: bool = @import("std").mem.zeroes(bool),
    ConfigDockingTransparentPayload: bool = @import("std").mem.zeroes(bool),
    ConfigViewportsNoAutoMerge: bool = @import("std").mem.zeroes(bool),
    ConfigViewportsNoTaskBarIcon: bool = @import("std").mem.zeroes(bool),
    ConfigViewportsNoDecoration: bool = @import("std").mem.zeroes(bool),
    ConfigViewportsNoDefaultParent: bool = @import("std").mem.zeroes(bool),
    MouseDrawCursor: bool = @import("std").mem.zeroes(bool),
    ConfigMacOSXBehaviors: bool = @import("std").mem.zeroes(bool),
    ConfigInputTrickleEventQueue: bool = @import("std").mem.zeroes(bool),
    ConfigInputTextCursorBlink: bool = @import("std").mem.zeroes(bool),
    ConfigDragClickToInputText: bool = @import("std").mem.zeroes(bool),
    ConfigWindowsResizeFromEdges: bool = @import("std").mem.zeroes(bool),
    ConfigWindowsMoveFromTitleBarOnly: bool = @import("std").mem.zeroes(bool),
    ConfigMemoryCompactTimer: f32 = @import("std").mem.zeroes(f32),
    BackendPlatformName: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    BackendRendererName: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    BackendPlatformUserData: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    BackendRendererUserData: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    BackendLanguageUserData: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    GetClipboardTextFn: ?*const fn (?*anyopaque) callconv(.C) [*c]const u8 = @import("std").mem.zeroes(?*const fn (?*anyopaque) callconv(.C) [*c]const u8),
    SetClipboardTextFn: ?*const fn (?*anyopaque, [*c]const u8) callconv(.C) void = @import("std").mem.zeroes(?*const fn (?*anyopaque, [*c]const u8) callconv(.C) void),
    ClipboardUserData: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    SetPlatformImeDataFn: ?*const fn ([*c]ImGuiViewport, [*c]ImGuiPlatformImeData) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport, [*c]ImGuiPlatformImeData) callconv(.C) void),
    _UnusedPadding: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    WantCaptureMouse: bool = @import("std").mem.zeroes(bool),
    WantCaptureKeyboard: bool = @import("std").mem.zeroes(bool),
    WantTextInput: bool = @import("std").mem.zeroes(bool),
    WantSetMousePos: bool = @import("std").mem.zeroes(bool),
    WantSaveIniSettings: bool = @import("std").mem.zeroes(bool),
    NavActive: bool = @import("std").mem.zeroes(bool),
    NavVisible: bool = @import("std").mem.zeroes(bool),
    Framerate: f32 = @import("std").mem.zeroes(f32),
    MetricsRenderVertices: c_int = @import("std").mem.zeroes(c_int),
    MetricsRenderIndices: c_int = @import("std").mem.zeroes(c_int),
    MetricsRenderWindows: c_int = @import("std").mem.zeroes(c_int),
    MetricsActiveWindows: c_int = @import("std").mem.zeroes(c_int),
    MetricsActiveAllocations: c_int = @import("std").mem.zeroes(c_int),
    MouseDelta: ImVec2 = @import("std").mem.zeroes(ImVec2),
    KeyMap: [645]c_int = @import("std").mem.zeroes([645]c_int),
    KeysDown: [645]bool = @import("std").mem.zeroes([645]bool),
    MousePos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    MouseDown: [5]bool = @import("std").mem.zeroes([5]bool),
    MouseWheel: f32 = @import("std").mem.zeroes(f32),
    MouseWheelH: f32 = @import("std").mem.zeroes(f32),
    MouseHoveredViewport: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    KeyCtrl: bool = @import("std").mem.zeroes(bool),
    KeyShift: bool = @import("std").mem.zeroes(bool),
    KeyAlt: bool = @import("std").mem.zeroes(bool),
    KeySuper: bool = @import("std").mem.zeroes(bool),
    NavInputs: [20]f32 = @import("std").mem.zeroes([20]f32),
    KeyMods: ImGuiModFlags = @import("std").mem.zeroes(ImGuiModFlags),
    KeysData: [645]ImGuiKeyData = @import("std").mem.zeroes([645]ImGuiKeyData),
    WantCaptureMouseUnlessPopupClose: bool = @import("std").mem.zeroes(bool),
    MousePosPrev: ImVec2 = @import("std").mem.zeroes(ImVec2),
    MouseClickedPos: [5]ImVec2 = @import("std").mem.zeroes([5]ImVec2),
    MouseClickedTime: [5]f64 = @import("std").mem.zeroes([5]f64),
    MouseClicked: [5]bool = @import("std").mem.zeroes([5]bool),
    MouseDoubleClicked: [5]bool = @import("std").mem.zeroes([5]bool),
    MouseClickedCount: [5]ImU16 = @import("std").mem.zeroes([5]ImU16),
    MouseClickedLastCount: [5]ImU16 = @import("std").mem.zeroes([5]ImU16),
    MouseReleased: [5]bool = @import("std").mem.zeroes([5]bool),
    MouseDownOwned: [5]bool = @import("std").mem.zeroes([5]bool),
    MouseDownOwnedUnlessPopupClose: [5]bool = @import("std").mem.zeroes([5]bool),
    MouseDownDuration: [5]f32 = @import("std").mem.zeroes([5]f32),
    MouseDownDurationPrev: [5]f32 = @import("std").mem.zeroes([5]f32),
    MouseDragMaxDistanceAbs: [5]ImVec2 = @import("std").mem.zeroes([5]ImVec2),
    MouseDragMaxDistanceSqr: [5]f32 = @import("std").mem.zeroes([5]f32),
    NavInputsDownDuration: [20]f32 = @import("std").mem.zeroes([20]f32),
    NavInputsDownDurationPrev: [20]f32 = @import("std").mem.zeroes([20]f32),
    PenPressure: f32 = @import("std").mem.zeroes(f32),
    AppFocusLost: bool = @import("std").mem.zeroes(bool),
    AppAcceptingEvents: bool = @import("std").mem.zeroes(bool),
    BackendUsingLegacyKeyArrays: ImS8 = @import("std").mem.zeroes(ImS8),
    BackendUsingLegacyNavInputArray: bool = @import("std").mem.zeroes(bool),
    InputQueueSurrogate: ImWchar16 = @import("std").mem.zeroes(ImWchar16),
    InputQueueCharacters: ImVector_ImWchar = @import("std").mem.zeroes(ImVector_ImWchar),
};
pub const ImGuiIO = struct_ImGuiIO;
pub const ImU64 = c_ulonglong;
pub const struct_ImGuiPlatformMonitor = extern struct {
    MainPos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    MainSize: ImVec2 = @import("std").mem.zeroes(ImVec2),
    WorkPos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    WorkSize: ImVec2 = @import("std").mem.zeroes(ImVec2),
    DpiScale: f32 = @import("std").mem.zeroes(f32),
};
pub const ImGuiPlatformMonitor = struct_ImGuiPlatformMonitor;
pub const struct_ImVector_ImGuiPlatformMonitor = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiPlatformMonitor = @import("std").mem.zeroes([*c]ImGuiPlatformMonitor),
};
pub const ImVector_ImGuiPlatformMonitor = struct_ImVector_ImGuiPlatformMonitor;
pub const struct_ImVector_ImGuiViewportPtr = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c][*c]ImGuiViewport = @import("std").mem.zeroes([*c][*c]ImGuiViewport),
};
pub const ImVector_ImGuiViewportPtr = struct_ImVector_ImGuiViewportPtr;
pub const struct_ImGuiPlatformIO = extern struct {
    Platform_CreateWindow: ?*const fn ([*c]ImGuiViewport) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport) callconv(.C) void),
    Platform_DestroyWindow: ?*const fn ([*c]ImGuiViewport) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport) callconv(.C) void),
    Platform_ShowWindow: ?*const fn ([*c]ImGuiViewport) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport) callconv(.C) void),
    Platform_SetWindowPos: ?*const fn ([*c]ImGuiViewport, ImVec2) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport, ImVec2) callconv(.C) void),
    Platform_GetWindowPos: ?*const fn ([*c]ImGuiViewport) callconv(.C) ImVec2 = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport) callconv(.C) ImVec2),
    Platform_SetWindowSize: ?*const fn ([*c]ImGuiViewport, ImVec2) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport, ImVec2) callconv(.C) void),
    Platform_GetWindowSize: ?*const fn ([*c]ImGuiViewport) callconv(.C) ImVec2 = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport) callconv(.C) ImVec2),
    Platform_SetWindowFocus: ?*const fn ([*c]ImGuiViewport) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport) callconv(.C) void),
    Platform_GetWindowFocus: ?*const fn ([*c]ImGuiViewport) callconv(.C) bool = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport) callconv(.C) bool),
    Platform_GetWindowMinimized: ?*const fn ([*c]ImGuiViewport) callconv(.C) bool = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport) callconv(.C) bool),
    Platform_SetWindowTitle: ?*const fn ([*c]ImGuiViewport, [*c]const u8) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport, [*c]const u8) callconv(.C) void),
    Platform_SetWindowAlpha: ?*const fn ([*c]ImGuiViewport, f32) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport, f32) callconv(.C) void),
    Platform_UpdateWindow: ?*const fn ([*c]ImGuiViewport) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport) callconv(.C) void),
    Platform_RenderWindow: ?*const fn ([*c]ImGuiViewport, ?*anyopaque) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport, ?*anyopaque) callconv(.C) void),
    Platform_SwapBuffers: ?*const fn ([*c]ImGuiViewport, ?*anyopaque) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport, ?*anyopaque) callconv(.C) void),
    Platform_GetWindowDpiScale: ?*const fn ([*c]ImGuiViewport) callconv(.C) f32 = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport) callconv(.C) f32),
    Platform_OnChangedViewport: ?*const fn ([*c]ImGuiViewport) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport) callconv(.C) void),
    Platform_CreateVkSurface: ?*const fn ([*c]ImGuiViewport, ImU64, ?*const anyopaque, [*c]ImU64) callconv(.C) c_int = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport, ImU64, ?*const anyopaque, [*c]ImU64) callconv(.C) c_int),
    Renderer_CreateWindow: ?*const fn ([*c]ImGuiViewport) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport) callconv(.C) void),
    Renderer_DestroyWindow: ?*const fn ([*c]ImGuiViewport) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport) callconv(.C) void),
    Renderer_SetWindowSize: ?*const fn ([*c]ImGuiViewport, ImVec2) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport, ImVec2) callconv(.C) void),
    Renderer_RenderWindow: ?*const fn ([*c]ImGuiViewport, ?*anyopaque) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport, ?*anyopaque) callconv(.C) void),
    Renderer_SwapBuffers: ?*const fn ([*c]ImGuiViewport, ?*anyopaque) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiViewport, ?*anyopaque) callconv(.C) void),
    Monitors: ImVector_ImGuiPlatformMonitor = @import("std").mem.zeroes(ImVector_ImGuiPlatformMonitor),
    Viewports: ImVector_ImGuiViewportPtr = @import("std").mem.zeroes(ImVector_ImGuiViewportPtr),
};
pub const ImGuiPlatformIO = struct_ImGuiPlatformIO;
pub const struct_ImGuiInputEventMousePos = extern struct {
    PosX: f32 = @import("std").mem.zeroes(f32),
    PosY: f32 = @import("std").mem.zeroes(f32),
};
pub const ImGuiInputEventMousePos = struct_ImGuiInputEventMousePos;
pub const struct_ImGuiInputEventMouseWheel = extern struct {
    WheelX: f32 = @import("std").mem.zeroes(f32),
    WheelY: f32 = @import("std").mem.zeroes(f32),
};
pub const ImGuiInputEventMouseWheel = struct_ImGuiInputEventMouseWheel;
pub const struct_ImGuiInputEventMouseButton = extern struct {
    Button: c_int = @import("std").mem.zeroes(c_int),
    Down: bool = @import("std").mem.zeroes(bool),
};
pub const ImGuiInputEventMouseButton = struct_ImGuiInputEventMouseButton;
pub const struct_ImGuiInputEventMouseViewport = extern struct {
    HoveredViewportID: ImGuiID = @import("std").mem.zeroes(ImGuiID),
};
pub const ImGuiInputEventMouseViewport = struct_ImGuiInputEventMouseViewport;
pub const ImGuiKey = c_int;
pub const struct_ImGuiInputEventKey = extern struct {
    Key: ImGuiKey = @import("std").mem.zeroes(ImGuiKey),
    Down: bool = @import("std").mem.zeroes(bool),
    AnalogValue: f32 = @import("std").mem.zeroes(f32),
};
pub const ImGuiInputEventKey = struct_ImGuiInputEventKey;
pub const struct_ImGuiInputEventText = extern struct {
    Char: c_uint = @import("std").mem.zeroes(c_uint),
};
pub const ImGuiInputEventText = struct_ImGuiInputEventText;
pub const struct_ImGuiInputEventAppFocused = extern struct {
    Focused: bool = @import("std").mem.zeroes(bool),
};
pub const ImGuiInputEventAppFocused = struct_ImGuiInputEventAppFocused;
const union_unnamed_1 = extern union {
    MousePos: ImGuiInputEventMousePos,
    MouseWheel: ImGuiInputEventMouseWheel,
    MouseButton: ImGuiInputEventMouseButton,
    MouseViewport: ImGuiInputEventMouseViewport,
    Key: ImGuiInputEventKey,
    Text: ImGuiInputEventText,
    AppFocused: ImGuiInputEventAppFocused,
};
pub const struct_ImGuiInputEvent = extern struct {
    Type: ImGuiInputEventType = @import("std").mem.zeroes(ImGuiInputEventType),
    Source: ImGuiInputSource = @import("std").mem.zeroes(ImGuiInputSource),
    unnamed_0: union_unnamed_1 = @import("std").mem.zeroes(union_unnamed_1),
    AddedByTestEngine: bool = @import("std").mem.zeroes(bool),
};
pub const ImGuiInputEvent = struct_ImGuiInputEvent;
pub const struct_ImVector_ImGuiInputEvent = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiInputEvent = @import("std").mem.zeroes([*c]ImGuiInputEvent),
};
pub const ImVector_ImGuiInputEvent = struct_ImVector_ImGuiInputEvent;
pub const ImGuiDir = c_int;
pub const struct_ImGuiStyle = extern struct {
    Alpha: f32 = @import("std").mem.zeroes(f32),
    DisabledAlpha: f32 = @import("std").mem.zeroes(f32),
    WindowPadding: ImVec2 = @import("std").mem.zeroes(ImVec2),
    WindowRounding: f32 = @import("std").mem.zeroes(f32),
    WindowBorderSize: f32 = @import("std").mem.zeroes(f32),
    WindowMinSize: ImVec2 = @import("std").mem.zeroes(ImVec2),
    WindowTitleAlign: ImVec2 = @import("std").mem.zeroes(ImVec2),
    WindowMenuButtonPosition: ImGuiDir = @import("std").mem.zeroes(ImGuiDir),
    ChildRounding: f32 = @import("std").mem.zeroes(f32),
    ChildBorderSize: f32 = @import("std").mem.zeroes(f32),
    PopupRounding: f32 = @import("std").mem.zeroes(f32),
    PopupBorderSize: f32 = @import("std").mem.zeroes(f32),
    FramePadding: ImVec2 = @import("std").mem.zeroes(ImVec2),
    FrameRounding: f32 = @import("std").mem.zeroes(f32),
    FrameBorderSize: f32 = @import("std").mem.zeroes(f32),
    ItemSpacing: ImVec2 = @import("std").mem.zeroes(ImVec2),
    ItemInnerSpacing: ImVec2 = @import("std").mem.zeroes(ImVec2),
    CellPadding: ImVec2 = @import("std").mem.zeroes(ImVec2),
    TouchExtraPadding: ImVec2 = @import("std").mem.zeroes(ImVec2),
    IndentSpacing: f32 = @import("std").mem.zeroes(f32),
    ColumnsMinSpacing: f32 = @import("std").mem.zeroes(f32),
    ScrollbarSize: f32 = @import("std").mem.zeroes(f32),
    ScrollbarRounding: f32 = @import("std").mem.zeroes(f32),
    GrabMinSize: f32 = @import("std").mem.zeroes(f32),
    GrabRounding: f32 = @import("std").mem.zeroes(f32),
    LogSliderDeadzone: f32 = @import("std").mem.zeroes(f32),
    TabRounding: f32 = @import("std").mem.zeroes(f32),
    TabBorderSize: f32 = @import("std").mem.zeroes(f32),
    TabMinWidthForCloseButton: f32 = @import("std").mem.zeroes(f32),
    ColorButtonPosition: ImGuiDir = @import("std").mem.zeroes(ImGuiDir),
    ButtonTextAlign: ImVec2 = @import("std").mem.zeroes(ImVec2),
    SelectableTextAlign: ImVec2 = @import("std").mem.zeroes(ImVec2),
    DisplayWindowPadding: ImVec2 = @import("std").mem.zeroes(ImVec2),
    DisplaySafeAreaPadding: ImVec2 = @import("std").mem.zeroes(ImVec2),
    MouseCursorScale: f32 = @import("std").mem.zeroes(f32),
    AntiAliasedLines: bool = @import("std").mem.zeroes(bool),
    AntiAliasedLinesUseTex: bool = @import("std").mem.zeroes(bool),
    AntiAliasedFill: bool = @import("std").mem.zeroes(bool),
    CurveTessellationTol: f32 = @import("std").mem.zeroes(f32),
    CircleTessellationMaxError: f32 = @import("std").mem.zeroes(f32),
    Colors: [55]ImVec4 = @import("std").mem.zeroes([55]ImVec4),
};
pub const ImGuiStyle = struct_ImGuiStyle;
pub const ImGuiWindowFlags = c_int;
pub const ImGuiTabItemFlags = c_int;
pub const ImGuiDockNodeFlags = c_int;
pub const struct_ImGuiWindowClass = extern struct {
    ClassId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    ParentViewportId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    ViewportFlagsOverrideSet: ImGuiViewportFlags = @import("std").mem.zeroes(ImGuiViewportFlags),
    ViewportFlagsOverrideClear: ImGuiViewportFlags = @import("std").mem.zeroes(ImGuiViewportFlags),
    TabItemFlagsOverrideSet: ImGuiTabItemFlags = @import("std").mem.zeroes(ImGuiTabItemFlags),
    DockNodeFlagsOverrideSet: ImGuiDockNodeFlags = @import("std").mem.zeroes(ImGuiDockNodeFlags),
    DockingAlwaysTabBar: bool = @import("std").mem.zeroes(bool),
    DockingAllowUnclassed: bool = @import("std").mem.zeroes(bool),
};
pub const ImGuiWindowClass = struct_ImGuiWindowClass;
pub const struct_ImVector_ImDrawListPtr = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c][*c]ImDrawList = @import("std").mem.zeroes([*c][*c]ImDrawList),
};
pub const ImVector_ImDrawListPtr = struct_ImVector_ImDrawListPtr;
pub const struct_ImDrawDataBuilder = extern struct {
    Layers: [2]ImVector_ImDrawListPtr = @import("std").mem.zeroes([2]ImVector_ImDrawListPtr),
};
pub const ImDrawDataBuilder = struct_ImDrawDataBuilder;
pub const struct_ImGuiViewportP = extern struct {
    _ImGuiViewport: ImGuiViewport = @import("std").mem.zeroes(ImGuiViewport),
    Idx: c_int = @import("std").mem.zeroes(c_int),
    LastFrameActive: c_int = @import("std").mem.zeroes(c_int),
    LastFrontMostStampCount: c_int = @import("std").mem.zeroes(c_int),
    LastNameHash: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    LastPos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    Alpha: f32 = @import("std").mem.zeroes(f32),
    LastAlpha: f32 = @import("std").mem.zeroes(f32),
    PlatformMonitor: c_short = @import("std").mem.zeroes(c_short),
    PlatformWindowCreated: bool = @import("std").mem.zeroes(bool),
    Window: ?*ImGuiWindow = @import("std").mem.zeroes(?*ImGuiWindow),
    DrawListsLastFrame: [2]c_int = @import("std").mem.zeroes([2]c_int),
    DrawLists: [2][*c]ImDrawList = @import("std").mem.zeroes([2][*c]ImDrawList),
    DrawDataP: ImDrawData = @import("std").mem.zeroes(ImDrawData),
    DrawDataBuilder: ImDrawDataBuilder = @import("std").mem.zeroes(ImDrawDataBuilder),
    LastPlatformPos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    LastPlatformSize: ImVec2 = @import("std").mem.zeroes(ImVec2),
    LastRendererSize: ImVec2 = @import("std").mem.zeroes(ImVec2),
    WorkOffsetMin: ImVec2 = @import("std").mem.zeroes(ImVec2),
    WorkOffsetMax: ImVec2 = @import("std").mem.zeroes(ImVec2),
    BuildWorkOffsetMin: ImVec2 = @import("std").mem.zeroes(ImVec2),
    BuildWorkOffsetMax: ImVec2 = @import("std").mem.zeroes(ImVec2),
};
pub const ImGuiViewportP = struct_ImGuiViewportP;
// cimgui2.h:2527:15: warning: struct demoted to opaque type - has bitfield
pub const struct_ImGuiWindow = opaque {};
pub const ImGuiWindow = struct_ImGuiWindow;
pub const struct_ImVector_ImGuiWindowPtr = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]?*ImGuiWindow = @import("std").mem.zeroes([*c]?*ImGuiWindow),
};
pub const ImVector_ImGuiWindowPtr = struct_ImVector_ImGuiWindowPtr;
pub const ImGuiItemFlags = c_int;
pub const ImGuiItemStatusFlags = c_int;
pub const struct_ImRect = extern struct {
    Min: ImVec2 = @import("std").mem.zeroes(ImVec2),
    Max: ImVec2 = @import("std").mem.zeroes(ImVec2),
};
pub const ImRect = struct_ImRect;
pub const struct_ImGuiLastItemData = extern struct {
    ID: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    InFlags: ImGuiItemFlags = @import("std").mem.zeroes(ImGuiItemFlags),
    StatusFlags: ImGuiItemStatusFlags = @import("std").mem.zeroes(ImGuiItemStatusFlags),
    Rect: ImRect = @import("std").mem.zeroes(ImRect),
    NavRect: ImRect = @import("std").mem.zeroes(ImRect),
    DisplayRect: ImRect = @import("std").mem.zeroes(ImRect),
};
pub const ImGuiLastItemData = struct_ImGuiLastItemData;
pub const struct_ImGuiStackSizes = extern struct {
    SizeOfIDStack: c_short = @import("std").mem.zeroes(c_short),
    SizeOfColorStack: c_short = @import("std").mem.zeroes(c_short),
    SizeOfStyleVarStack: c_short = @import("std").mem.zeroes(c_short),
    SizeOfFontStack: c_short = @import("std").mem.zeroes(c_short),
    SizeOfFocusScopeStack: c_short = @import("std").mem.zeroes(c_short),
    SizeOfGroupStack: c_short = @import("std").mem.zeroes(c_short),
    SizeOfItemFlagsStack: c_short = @import("std").mem.zeroes(c_short),
    SizeOfBeginPopupStack: c_short = @import("std").mem.zeroes(c_short),
    SizeOfDisabledStack: c_short = @import("std").mem.zeroes(c_short),
};
pub const ImGuiStackSizes = struct_ImGuiStackSizes;
pub const struct_ImGuiWindowStackData = extern struct {
    Window: ?*ImGuiWindow = @import("std").mem.zeroes(?*ImGuiWindow),
    ParentLastItemDataBackup: ImGuiLastItemData = @import("std").mem.zeroes(ImGuiLastItemData),
    StackSizesOnBegin: ImGuiStackSizes = @import("std").mem.zeroes(ImGuiStackSizes),
};
pub const ImGuiWindowStackData = struct_ImGuiWindowStackData;
pub const struct_ImVector_ImGuiWindowStackData = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiWindowStackData = @import("std").mem.zeroes([*c]ImGuiWindowStackData),
};
pub const ImVector_ImGuiWindowStackData = struct_ImVector_ImGuiWindowStackData;
const union_unnamed_2 = extern union {
    val_i: c_int,
    val_f: f32,
    val_p: ?*anyopaque,
};
pub const struct_ImGuiStoragePair = extern struct {
    key: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    unnamed_0: union_unnamed_2 = @import("std").mem.zeroes(union_unnamed_2),
};
pub const ImGuiStoragePair = struct_ImGuiStoragePair;
pub const struct_ImVector_ImGuiStoragePair = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiStoragePair = @import("std").mem.zeroes([*c]ImGuiStoragePair),
};
pub const ImVector_ImGuiStoragePair = struct_ImVector_ImGuiStoragePair;
pub const struct_ImGuiStorage = extern struct {
    Data: ImVector_ImGuiStoragePair = @import("std").mem.zeroes(ImVector_ImGuiStoragePair),
};
pub const ImGuiStorage = struct_ImGuiStorage;
pub const ImS32 = c_int;
pub const ImS16 = c_short;
pub const struct_ImGuiTabItem = extern struct {
    ID: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    Flags: ImGuiTabItemFlags = @import("std").mem.zeroes(ImGuiTabItemFlags),
    Window: ?*ImGuiWindow = @import("std").mem.zeroes(?*ImGuiWindow),
    LastFrameVisible: c_int = @import("std").mem.zeroes(c_int),
    LastFrameSelected: c_int = @import("std").mem.zeroes(c_int),
    Offset: f32 = @import("std").mem.zeroes(f32),
    Width: f32 = @import("std").mem.zeroes(f32),
    ContentWidth: f32 = @import("std").mem.zeroes(f32),
    RequestedWidth: f32 = @import("std").mem.zeroes(f32),
    NameOffset: ImS32 = @import("std").mem.zeroes(ImS32),
    BeginOrder: ImS16 = @import("std").mem.zeroes(ImS16),
    IndexDuringLayout: ImS16 = @import("std").mem.zeroes(ImS16),
    WantClose: bool = @import("std").mem.zeroes(bool),
};
pub const ImGuiTabItem = struct_ImGuiTabItem;
pub const struct_ImVector_ImGuiTabItem = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiTabItem = @import("std").mem.zeroes([*c]ImGuiTabItem),
};
pub const ImVector_ImGuiTabItem = struct_ImVector_ImGuiTabItem;
pub const ImGuiTabBarFlags = c_int;
pub const struct_ImVector_char = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]u8 = @import("std").mem.zeroes([*c]u8),
};
pub const ImVector_char = struct_ImVector_char;
pub const struct_ImGuiTextBuffer = extern struct {
    Buf: ImVector_char = @import("std").mem.zeroes(ImVector_char),
};
pub const ImGuiTextBuffer = struct_ImGuiTextBuffer;
pub const struct_ImGuiTabBar = extern struct {
    Tabs: ImVector_ImGuiTabItem = @import("std").mem.zeroes(ImVector_ImGuiTabItem),
    Flags: ImGuiTabBarFlags = @import("std").mem.zeroes(ImGuiTabBarFlags),
    ID: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    SelectedTabId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    NextSelectedTabId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    VisibleTabId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    CurrFrameVisible: c_int = @import("std").mem.zeroes(c_int),
    PrevFrameVisible: c_int = @import("std").mem.zeroes(c_int),
    BarRect: ImRect = @import("std").mem.zeroes(ImRect),
    CurrTabsContentsHeight: f32 = @import("std").mem.zeroes(f32),
    PrevTabsContentsHeight: f32 = @import("std").mem.zeroes(f32),
    WidthAllTabs: f32 = @import("std").mem.zeroes(f32),
    WidthAllTabsIdeal: f32 = @import("std").mem.zeroes(f32),
    ScrollingAnim: f32 = @import("std").mem.zeroes(f32),
    ScrollingTarget: f32 = @import("std").mem.zeroes(f32),
    ScrollingTargetDistToVisibility: f32 = @import("std").mem.zeroes(f32),
    ScrollingSpeed: f32 = @import("std").mem.zeroes(f32),
    ScrollingRectMinX: f32 = @import("std").mem.zeroes(f32),
    ScrollingRectMaxX: f32 = @import("std").mem.zeroes(f32),
    ReorderRequestTabId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    ReorderRequestOffset: ImS16 = @import("std").mem.zeroes(ImS16),
    BeginCount: ImS8 = @import("std").mem.zeroes(ImS8),
    WantLayout: bool = @import("std").mem.zeroes(bool),
    VisibleTabWasSubmitted: bool = @import("std").mem.zeroes(bool),
    TabsAddedNew: bool = @import("std").mem.zeroes(bool),
    TabsActiveCount: ImS16 = @import("std").mem.zeroes(ImS16),
    LastTabItemIdx: ImS16 = @import("std").mem.zeroes(ImS16),
    ItemSpacingY: f32 = @import("std").mem.zeroes(f32),
    FramePadding: ImVec2 = @import("std").mem.zeroes(ImVec2),
    BackupCursorPos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    TabsNames: ImGuiTextBuffer = @import("std").mem.zeroes(ImGuiTextBuffer),
};
pub const ImGuiTabBar = struct_ImGuiTabBar;
// cimgui2.h:2005:24: warning: struct demoted to opaque type - has bitfield
pub const struct_ImGuiDockNode = opaque {};
pub const ImGuiDockNode = struct_ImGuiDockNode;
pub const struct_ImBitArray_ImGuiKey_NamedKey_COUNT__lessImGuiKey_NamedKey_BEGIN = extern struct {
    Storage: [5]ImU32 = @import("std").mem.zeroes([5]ImU32),
};
pub const ImBitArray_ImGuiKey_NamedKey_COUNT__lessImGuiKey_NamedKey_BEGIN = struct_ImBitArray_ImGuiKey_NamedKey_COUNT__lessImGuiKey_NamedKey_BEGIN;
pub const ImBitArrayForNamedKeys = ImBitArray_ImGuiKey_NamedKey_COUNT__lessImGuiKey_NamedKey_BEGIN;
pub const ImGuiNextItemDataFlags = c_int;
pub const ImGuiCond = c_int;
pub const struct_ImGuiNextItemData = extern struct {
    Flags: ImGuiNextItemDataFlags = @import("std").mem.zeroes(ImGuiNextItemDataFlags),
    Width: f32 = @import("std").mem.zeroes(f32),
    FocusScopeId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    OpenCond: ImGuiCond = @import("std").mem.zeroes(ImGuiCond),
    OpenVal: bool = @import("std").mem.zeroes(bool),
};
pub const ImGuiNextItemData = struct_ImGuiNextItemData;
pub const ImGuiNextWindowDataFlags = c_int;
pub const struct_ImGuiSizeCallbackData = extern struct {
    UserData: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    Pos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    CurrentSize: ImVec2 = @import("std").mem.zeroes(ImVec2),
    DesiredSize: ImVec2 = @import("std").mem.zeroes(ImVec2),
};
pub const ImGuiSizeCallbackData = struct_ImGuiSizeCallbackData;
pub const ImGuiSizeCallback = ?*const fn ([*c]ImGuiSizeCallbackData) callconv(.C) void;
pub const struct_ImGuiNextWindowData = extern struct {
    Flags: ImGuiNextWindowDataFlags = @import("std").mem.zeroes(ImGuiNextWindowDataFlags),
    PosCond: ImGuiCond = @import("std").mem.zeroes(ImGuiCond),
    SizeCond: ImGuiCond = @import("std").mem.zeroes(ImGuiCond),
    CollapsedCond: ImGuiCond = @import("std").mem.zeroes(ImGuiCond),
    DockCond: ImGuiCond = @import("std").mem.zeroes(ImGuiCond),
    PosVal: ImVec2 = @import("std").mem.zeroes(ImVec2),
    PosPivotVal: ImVec2 = @import("std").mem.zeroes(ImVec2),
    SizeVal: ImVec2 = @import("std").mem.zeroes(ImVec2),
    ContentSizeVal: ImVec2 = @import("std").mem.zeroes(ImVec2),
    ScrollVal: ImVec2 = @import("std").mem.zeroes(ImVec2),
    PosUndock: bool = @import("std").mem.zeroes(bool),
    CollapsedVal: bool = @import("std").mem.zeroes(bool),
    SizeConstraintRect: ImRect = @import("std").mem.zeroes(ImRect),
    SizeCallback: ImGuiSizeCallback = @import("std").mem.zeroes(ImGuiSizeCallback),
    SizeCallbackUserData: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    BgAlphaVal: f32 = @import("std").mem.zeroes(f32),
    ViewportId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    DockId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    WindowClass: ImGuiWindowClass = @import("std").mem.zeroes(ImGuiWindowClass),
    MenuBarOffsetMinVal: ImVec2 = @import("std").mem.zeroes(ImVec2),
};
pub const ImGuiNextWindowData = struct_ImGuiNextWindowData;
pub const ImGuiCol = c_int;
pub const struct_ImGuiColorMod = extern struct {
    Col: ImGuiCol = @import("std").mem.zeroes(ImGuiCol),
    BackupValue: ImVec4 = @import("std").mem.zeroes(ImVec4),
};
pub const ImGuiColorMod = struct_ImGuiColorMod;
pub const struct_ImVector_ImGuiColorMod = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiColorMod = @import("std").mem.zeroes([*c]ImGuiColorMod),
};
pub const ImVector_ImGuiColorMod = struct_ImVector_ImGuiColorMod;
pub const ImGuiStyleVar = c_int;
const union_unnamed_3 = extern union {
    BackupInt: [2]c_int,
    BackupFloat: [2]f32,
};
pub const struct_ImGuiStyleMod = extern struct {
    VarIdx: ImGuiStyleVar = @import("std").mem.zeroes(ImGuiStyleVar),
    unnamed_0: union_unnamed_3 = @import("std").mem.zeroes(union_unnamed_3),
};
pub const ImGuiStyleMod = struct_ImGuiStyleMod;
pub const struct_ImVector_ImGuiStyleMod = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiStyleMod = @import("std").mem.zeroes([*c]ImGuiStyleMod),
};
pub const ImVector_ImGuiStyleMod = struct_ImVector_ImGuiStyleMod;
pub const struct_ImVector_ImGuiID = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiID = @import("std").mem.zeroes([*c]ImGuiID),
};
pub const ImVector_ImGuiID = struct_ImVector_ImGuiID;
pub const struct_ImVector_ImGuiItemFlags = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiItemFlags = @import("std").mem.zeroes([*c]ImGuiItemFlags),
};
pub const ImVector_ImGuiItemFlags = struct_ImVector_ImGuiItemFlags;
pub const struct_ImVec1 = extern struct {
    x: f32 = @import("std").mem.zeroes(f32),
};
pub const ImVec1 = struct_ImVec1;
pub const struct_ImGuiGroupData = extern struct {
    WindowID: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    BackupCursorPos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    BackupCursorMaxPos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    BackupIndent: ImVec1 = @import("std").mem.zeroes(ImVec1),
    BackupGroupOffset: ImVec1 = @import("std").mem.zeroes(ImVec1),
    BackupCurrLineSize: ImVec2 = @import("std").mem.zeroes(ImVec2),
    BackupCurrLineTextBaseOffset: f32 = @import("std").mem.zeroes(f32),
    BackupActiveIdIsAlive: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    BackupActiveIdPreviousFrameIsAlive: bool = @import("std").mem.zeroes(bool),
    BackupHoveredIdIsAlive: bool = @import("std").mem.zeroes(bool),
    EmitItem: bool = @import("std").mem.zeroes(bool),
};
pub const ImGuiGroupData = struct_ImGuiGroupData;
pub const struct_ImVector_ImGuiGroupData = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiGroupData = @import("std").mem.zeroes([*c]ImGuiGroupData),
};
pub const ImVector_ImGuiGroupData = struct_ImVector_ImGuiGroupData;
pub const struct_ImGuiPopupData = extern struct {
    PopupId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    Window: ?*ImGuiWindow = @import("std").mem.zeroes(?*ImGuiWindow),
    SourceWindow: ?*ImGuiWindow = @import("std").mem.zeroes(?*ImGuiWindow),
    ParentNavLayer: c_int = @import("std").mem.zeroes(c_int),
    OpenFrameCount: c_int = @import("std").mem.zeroes(c_int),
    OpenParentId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    OpenPopupPos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    OpenMousePos: ImVec2 = @import("std").mem.zeroes(ImVec2),
};
pub const ImGuiPopupData = struct_ImGuiPopupData;
pub const struct_ImVector_ImGuiPopupData = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiPopupData = @import("std").mem.zeroes([*c]ImGuiPopupData),
};
pub const ImVector_ImGuiPopupData = struct_ImVector_ImGuiPopupData;
pub const struct_ImVector_ImGuiViewportPPtr = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c][*c]ImGuiViewportP = @import("std").mem.zeroes([*c][*c]ImGuiViewportP),
};
pub const ImVector_ImGuiViewportPPtr = struct_ImVector_ImGuiViewportPPtr;
pub const ImGuiActivateFlags = c_int;
pub const ImGuiNavMoveFlags = c_int;
pub const ImGuiScrollFlags = c_int;
pub const struct_ImGuiNavItemData = extern struct {
    Window: ?*ImGuiWindow = @import("std").mem.zeroes(?*ImGuiWindow),
    ID: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    FocusScopeId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    RectRel: ImRect = @import("std").mem.zeroes(ImRect),
    InFlags: ImGuiItemFlags = @import("std").mem.zeroes(ImGuiItemFlags),
    DistBox: f32 = @import("std").mem.zeroes(f32),
    DistCenter: f32 = @import("std").mem.zeroes(f32),
    DistAxial: f32 = @import("std").mem.zeroes(f32),
};
pub const ImGuiNavItemData = struct_ImGuiNavItemData;
pub const ImGuiMouseCursor = c_int;
pub const ImGuiDragDropFlags = c_int;
pub const struct_ImGuiPayload = extern struct {
    Data: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    DataSize: c_int = @import("std").mem.zeroes(c_int),
    SourceId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    SourceParentId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    DataFrameCount: c_int = @import("std").mem.zeroes(c_int),
    DataType: [33]u8 = @import("std").mem.zeroes([33]u8),
    Preview: bool = @import("std").mem.zeroes(bool),
    Delivery: bool = @import("std").mem.zeroes(bool),
};
pub const ImGuiPayload = struct_ImGuiPayload;
pub const struct_ImVector_unsigned_char = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]u8 = @import("std").mem.zeroes([*c]u8),
};
pub const ImVector_unsigned_char = struct_ImVector_unsigned_char;
pub const struct_ImGuiListClipper = extern struct {
    DisplayStart: c_int = @import("std").mem.zeroes(c_int),
    DisplayEnd: c_int = @import("std").mem.zeroes(c_int),
    ItemsCount: c_int = @import("std").mem.zeroes(c_int),
    ItemsHeight: f32 = @import("std").mem.zeroes(f32),
    StartPosY: f32 = @import("std").mem.zeroes(f32),
    TempData: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
};
pub const ImGuiListClipper = struct_ImGuiListClipper;
pub const struct_ImGuiListClipperRange = extern struct {
    Min: c_int = @import("std").mem.zeroes(c_int),
    Max: c_int = @import("std").mem.zeroes(c_int),
    PosToIndexConvert: bool = @import("std").mem.zeroes(bool),
    PosToIndexOffsetMin: ImS8 = @import("std").mem.zeroes(ImS8),
    PosToIndexOffsetMax: ImS8 = @import("std").mem.zeroes(ImS8),
};
pub const ImGuiListClipperRange = struct_ImGuiListClipperRange;
pub const struct_ImVector_ImGuiListClipperRange = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiListClipperRange = @import("std").mem.zeroes([*c]ImGuiListClipperRange),
};
pub const ImVector_ImGuiListClipperRange = struct_ImVector_ImGuiListClipperRange;
pub const struct_ImGuiListClipperData = extern struct {
    ListClipper: [*c]ImGuiListClipper = @import("std").mem.zeroes([*c]ImGuiListClipper),
    LossynessOffset: f32 = @import("std").mem.zeroes(f32),
    StepNo: c_int = @import("std").mem.zeroes(c_int),
    ItemsFrozen: c_int = @import("std").mem.zeroes(c_int),
    Ranges: ImVector_ImGuiListClipperRange = @import("std").mem.zeroes(ImVector_ImGuiListClipperRange),
};
pub const ImGuiListClipperData = struct_ImGuiListClipperData;
pub const struct_ImVector_ImGuiListClipperData = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiListClipperData = @import("std").mem.zeroes([*c]ImGuiListClipperData),
};
pub const ImVector_ImGuiListClipperData = struct_ImVector_ImGuiListClipperData;
pub const ImGuiTableFlags = c_int;
pub const struct_ImGuiTableTempData = extern struct {
    TableIndex: c_int = @import("std").mem.zeroes(c_int),
    LastTimeActive: f32 = @import("std").mem.zeroes(f32),
    UserOuterSize: ImVec2 = @import("std").mem.zeroes(ImVec2),
    DrawSplitter: ImDrawListSplitter = @import("std").mem.zeroes(ImDrawListSplitter),
    HostBackupWorkRect: ImRect = @import("std").mem.zeroes(ImRect),
    HostBackupParentWorkRect: ImRect = @import("std").mem.zeroes(ImRect),
    HostBackupPrevLineSize: ImVec2 = @import("std").mem.zeroes(ImVec2),
    HostBackupCurrLineSize: ImVec2 = @import("std").mem.zeroes(ImVec2),
    HostBackupCursorMaxPos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    HostBackupColumnsOffset: ImVec1 = @import("std").mem.zeroes(ImVec1),
    HostBackupItemWidth: f32 = @import("std").mem.zeroes(f32),
    HostBackupItemWidthStackSize: c_int = @import("std").mem.zeroes(c_int),
};
pub const ImGuiTableTempData = struct_ImGuiTableTempData;
pub const ImGuiTableColumnFlags = c_int;
pub const ImGuiTableColumnIdx = ImS8;
pub const ImGuiTableDrawChannelIdx = ImU8;
// cimgui2.h:2685:10: warning: struct demoted to opaque type - has bitfield
pub const struct_ImGuiTableColumn = opaque {};
pub const ImGuiTableColumn = struct_ImGuiTableColumn;
pub const struct_ImSpan_ImGuiTableColumn = extern struct {
    Data: ?*ImGuiTableColumn = @import("std").mem.zeroes(?*ImGuiTableColumn),
    DataEnd: ?*ImGuiTableColumn = @import("std").mem.zeroes(?*ImGuiTableColumn),
};
pub const ImSpan_ImGuiTableColumn = struct_ImSpan_ImGuiTableColumn;
pub const struct_ImSpan_ImGuiTableColumnIdx = extern struct {
    Data: [*c]ImGuiTableColumnIdx = @import("std").mem.zeroes([*c]ImGuiTableColumnIdx),
    DataEnd: [*c]ImGuiTableColumnIdx = @import("std").mem.zeroes([*c]ImGuiTableColumnIdx),
};
pub const ImSpan_ImGuiTableColumnIdx = struct_ImSpan_ImGuiTableColumnIdx;
pub const struct_ImGuiTableCellData = extern struct {
    BgColor: ImU32 = @import("std").mem.zeroes(ImU32),
    Column: ImGuiTableColumnIdx = @import("std").mem.zeroes(ImGuiTableColumnIdx),
};
pub const ImGuiTableCellData = struct_ImGuiTableCellData;
pub const struct_ImSpan_ImGuiTableCellData = extern struct {
    Data: [*c]ImGuiTableCellData = @import("std").mem.zeroes([*c]ImGuiTableCellData),
    DataEnd: [*c]ImGuiTableCellData = @import("std").mem.zeroes([*c]ImGuiTableCellData),
};
pub const ImSpan_ImGuiTableCellData = struct_ImSpan_ImGuiTableCellData;
// cimgui2.h:2737:24: warning: struct demoted to opaque type - has bitfield
pub const struct_ImGuiTable = opaque {};
pub const ImGuiTable = struct_ImGuiTable;
pub const struct_ImVector_ImGuiTableTempData = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiTableTempData = @import("std").mem.zeroes([*c]ImGuiTableTempData),
};
pub const ImVector_ImGuiTableTempData = struct_ImVector_ImGuiTableTempData;
pub const struct_ImVector_ImGuiTable = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: ?*ImGuiTable = @import("std").mem.zeroes(?*ImGuiTable),
};
pub const ImVector_ImGuiTable = struct_ImVector_ImGuiTable;
pub const ImPoolIdx = c_int;
pub const struct_ImPool_ImGuiTable = extern struct {
    Buf: ImVector_ImGuiTable = @import("std").mem.zeroes(ImVector_ImGuiTable),
    Map: ImGuiStorage = @import("std").mem.zeroes(ImGuiStorage),
    FreeIdx: ImPoolIdx = @import("std").mem.zeroes(ImPoolIdx),
    AliveCount: ImPoolIdx = @import("std").mem.zeroes(ImPoolIdx),
};
pub const ImPool_ImGuiTable = struct_ImPool_ImGuiTable;
pub const struct_ImVector_ImGuiTabBar = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiTabBar = @import("std").mem.zeroes([*c]ImGuiTabBar),
};
pub const ImVector_ImGuiTabBar = struct_ImVector_ImGuiTabBar;
pub const struct_ImPool_ImGuiTabBar = extern struct {
    Buf: ImVector_ImGuiTabBar = @import("std").mem.zeroes(ImVector_ImGuiTabBar),
    Map: ImGuiStorage = @import("std").mem.zeroes(ImGuiStorage),
    FreeIdx: ImPoolIdx = @import("std").mem.zeroes(ImPoolIdx),
    AliveCount: ImPoolIdx = @import("std").mem.zeroes(ImPoolIdx),
};
pub const ImPool_ImGuiTabBar = struct_ImPool_ImGuiTabBar;
pub const struct_ImGuiPtrOrIndex = extern struct {
    Ptr: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    Index: c_int = @import("std").mem.zeroes(c_int),
};
pub const ImGuiPtrOrIndex = struct_ImGuiPtrOrIndex;
pub const struct_ImVector_ImGuiPtrOrIndex = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiPtrOrIndex = @import("std").mem.zeroes([*c]ImGuiPtrOrIndex),
};
pub const ImVector_ImGuiPtrOrIndex = struct_ImVector_ImGuiPtrOrIndex;
pub const struct_ImGuiShrinkWidthItem = extern struct {
    Index: c_int = @import("std").mem.zeroes(c_int),
    Width: f32 = @import("std").mem.zeroes(f32),
    InitialWidth: f32 = @import("std").mem.zeroes(f32),
};
pub const ImGuiShrinkWidthItem = struct_ImGuiShrinkWidthItem;
pub const struct_ImVector_ImGuiShrinkWidthItem = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiShrinkWidthItem = @import("std").mem.zeroes([*c]ImGuiShrinkWidthItem),
};
pub const ImVector_ImGuiShrinkWidthItem = struct_ImVector_ImGuiShrinkWidthItem;
pub const struct_StbUndoRecord = extern struct {
    where: c_int = @import("std").mem.zeroes(c_int),
    insert_length: c_int = @import("std").mem.zeroes(c_int),
    delete_length: c_int = @import("std").mem.zeroes(c_int),
    char_storage: c_int = @import("std").mem.zeroes(c_int),
};
pub const StbUndoRecord = struct_StbUndoRecord;
pub const struct_StbUndoState = extern struct {
    undo_rec: [99]StbUndoRecord = @import("std").mem.zeroes([99]StbUndoRecord),
    undo_char: [999]ImWchar = @import("std").mem.zeroes([999]ImWchar),
    undo_point: c_short = @import("std").mem.zeroes(c_short),
    redo_point: c_short = @import("std").mem.zeroes(c_short),
    undo_char_point: c_int = @import("std").mem.zeroes(c_int),
    redo_char_point: c_int = @import("std").mem.zeroes(c_int),
};
pub const StbUndoState = struct_StbUndoState;
pub const struct_STB_TexteditState = extern struct {
    cursor: c_int = @import("std").mem.zeroes(c_int),
    select_start: c_int = @import("std").mem.zeroes(c_int),
    select_end: c_int = @import("std").mem.zeroes(c_int),
    insert_mode: u8 = @import("std").mem.zeroes(u8),
    row_count_per_page: c_int = @import("std").mem.zeroes(c_int),
    cursor_at_end_of_line: u8 = @import("std").mem.zeroes(u8),
    initialized: u8 = @import("std").mem.zeroes(u8),
    has_preferred_x: u8 = @import("std").mem.zeroes(u8),
    single_line: u8 = @import("std").mem.zeroes(u8),
    padding1: u8 = @import("std").mem.zeroes(u8),
    padding2: u8 = @import("std").mem.zeroes(u8),
    padding3: u8 = @import("std").mem.zeroes(u8),
    preferred_x: f32 = @import("std").mem.zeroes(f32),
    undostate: StbUndoState = @import("std").mem.zeroes(StbUndoState),
};
pub const STB_TexteditState = struct_STB_TexteditState;
pub const ImGuiInputTextFlags = c_int;
pub const struct_ImGuiInputTextState = extern struct {
    ID: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    CurLenW: c_int = @import("std").mem.zeroes(c_int),
    CurLenA: c_int = @import("std").mem.zeroes(c_int),
    TextW: ImVector_ImWchar = @import("std").mem.zeroes(ImVector_ImWchar),
    TextA: ImVector_char = @import("std").mem.zeroes(ImVector_char),
    InitialTextA: ImVector_char = @import("std").mem.zeroes(ImVector_char),
    TextAIsValid: bool = @import("std").mem.zeroes(bool),
    BufCapacityA: c_int = @import("std").mem.zeroes(c_int),
    ScrollX: f32 = @import("std").mem.zeroes(f32),
    Stb: STB_TexteditState = @import("std").mem.zeroes(STB_TexteditState),
    CursorAnim: f32 = @import("std").mem.zeroes(f32),
    CursorFollow: bool = @import("std").mem.zeroes(bool),
    SelectedAllMouseLock: bool = @import("std").mem.zeroes(bool),
    Edited: bool = @import("std").mem.zeroes(bool),
    Flags: ImGuiInputTextFlags = @import("std").mem.zeroes(ImGuiInputTextFlags),
};
pub const ImGuiInputTextState = struct_ImGuiInputTextState;
pub const ImGuiColorEditFlags = c_int;
pub const ImGuiLayoutType = c_int;
pub const struct_ImGuiComboPreviewData = extern struct {
    PreviewRect: ImRect = @import("std").mem.zeroes(ImRect),
    BackupCursorPos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    BackupCursorMaxPos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    BackupCursorPosPrevLine: ImVec2 = @import("std").mem.zeroes(ImVec2),
    BackupPrevLineTextBaseOffset: f32 = @import("std").mem.zeroes(f32),
    BackupLayout: ImGuiLayoutType = @import("std").mem.zeroes(ImGuiLayoutType),
};
pub const ImGuiComboPreviewData = struct_ImGuiComboPreviewData;
pub const struct_ImGuiDockRequest = opaque {};
pub const ImGuiDockRequest = struct_ImGuiDockRequest;
pub const struct_ImVector_ImGuiDockRequest = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: ?*ImGuiDockRequest = @import("std").mem.zeroes(?*ImGuiDockRequest),
};
pub const ImVector_ImGuiDockRequest = struct_ImVector_ImGuiDockRequest;
pub const struct_ImGuiDockNodeSettings = opaque {};
pub const ImGuiDockNodeSettings = struct_ImGuiDockNodeSettings;
pub const struct_ImVector_ImGuiDockNodeSettings = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: ?*ImGuiDockNodeSettings = @import("std").mem.zeroes(?*ImGuiDockNodeSettings),
};
pub const ImVector_ImGuiDockNodeSettings = struct_ImVector_ImGuiDockNodeSettings;
pub const struct_ImGuiDockContext = extern struct {
    Nodes: ImGuiStorage = @import("std").mem.zeroes(ImGuiStorage),
    Requests: ImVector_ImGuiDockRequest = @import("std").mem.zeroes(ImVector_ImGuiDockRequest),
    NodesSettings: ImVector_ImGuiDockNodeSettings = @import("std").mem.zeroes(ImVector_ImGuiDockNodeSettings),
    WantFullRebuild: bool = @import("std").mem.zeroes(bool),
};
pub const ImGuiDockContext = struct_ImGuiDockContext;
pub const ImGuiContext = struct_ImGuiContext;
pub const struct_ImGuiSettingsHandler = extern struct {
    TypeName: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    TypeHash: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    ClearAllFn: ?*const fn ([*c]ImGuiContext, [*c]ImGuiSettingsHandler) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiContext, [*c]ImGuiSettingsHandler) callconv(.C) void),
    ReadInitFn: ?*const fn ([*c]ImGuiContext, [*c]ImGuiSettingsHandler) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiContext, [*c]ImGuiSettingsHandler) callconv(.C) void),
    ReadOpenFn: ?*const fn ([*c]ImGuiContext, [*c]ImGuiSettingsHandler, [*c]const u8) callconv(.C) ?*anyopaque = @import("std").mem.zeroes(?*const fn ([*c]ImGuiContext, [*c]ImGuiSettingsHandler, [*c]const u8) callconv(.C) ?*anyopaque),
    ReadLineFn: ?*const fn ([*c]ImGuiContext, [*c]ImGuiSettingsHandler, ?*anyopaque, [*c]const u8) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiContext, [*c]ImGuiSettingsHandler, ?*anyopaque, [*c]const u8) callconv(.C) void),
    ApplyAllFn: ?*const fn ([*c]ImGuiContext, [*c]ImGuiSettingsHandler) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiContext, [*c]ImGuiSettingsHandler) callconv(.C) void),
    WriteAllFn: ?*const fn ([*c]ImGuiContext, [*c]ImGuiSettingsHandler, [*c]ImGuiTextBuffer) callconv(.C) void = @import("std").mem.zeroes(?*const fn ([*c]ImGuiContext, [*c]ImGuiSettingsHandler, [*c]ImGuiTextBuffer) callconv(.C) void),
    UserData: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
};
pub const ImGuiSettingsHandler = struct_ImGuiSettingsHandler;
pub const struct_ImVector_ImGuiSettingsHandler = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiSettingsHandler = @import("std").mem.zeroes([*c]ImGuiSettingsHandler),
};
pub const ImVector_ImGuiSettingsHandler = struct_ImVector_ImGuiSettingsHandler;
pub const struct_ImChunkStream_ImGuiWindowSettings = extern struct {
    Buf: ImVector_char = @import("std").mem.zeroes(ImVector_char),
};
pub const ImChunkStream_ImGuiWindowSettings = struct_ImChunkStream_ImGuiWindowSettings;
pub const struct_ImChunkStream_ImGuiTableSettings = extern struct {
    Buf: ImVector_char = @import("std").mem.zeroes(ImVector_char),
};
pub const ImChunkStream_ImGuiTableSettings = struct_ImChunkStream_ImGuiTableSettings;
pub const ImGuiContextHookCallback = ?*const fn ([*c]ImGuiContext, [*c]ImGuiContextHook) callconv(.C) void;
pub const struct_ImGuiContextHook = extern struct {
    HookId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    Type: ImGuiContextHookType = @import("std").mem.zeroes(ImGuiContextHookType),
    Owner: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    Callback: ImGuiContextHookCallback = @import("std").mem.zeroes(ImGuiContextHookCallback),
    UserData: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
};
pub const ImGuiContextHook = struct_ImGuiContextHook;
pub const struct_ImVector_ImGuiContextHook = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiContextHook = @import("std").mem.zeroes([*c]ImGuiContextHook),
};
pub const ImVector_ImGuiContextHook = struct_ImVector_ImGuiContextHook;
pub const ImGuiDebugLogFlags = c_int;
pub const struct_ImGuiMetricsConfig = extern struct {
    ShowDebugLog: bool = @import("std").mem.zeroes(bool),
    ShowStackTool: bool = @import("std").mem.zeroes(bool),
    ShowWindowsRects: bool = @import("std").mem.zeroes(bool),
    ShowWindowsBeginOrder: bool = @import("std").mem.zeroes(bool),
    ShowTablesRects: bool = @import("std").mem.zeroes(bool),
    ShowDrawCmdMesh: bool = @import("std").mem.zeroes(bool),
    ShowDrawCmdBoundingBoxes: bool = @import("std").mem.zeroes(bool),
    ShowDockingNodes: bool = @import("std").mem.zeroes(bool),
    ShowWindowsRectsType: c_int = @import("std").mem.zeroes(c_int),
    ShowTablesRectsType: c_int = @import("std").mem.zeroes(c_int),
};
pub const ImGuiMetricsConfig = struct_ImGuiMetricsConfig;
// cimgui2.h:2127:19: warning: struct demoted to opaque type - has bitfield
pub const struct_ImGuiStackLevelInfo = opaque {};
pub const ImGuiStackLevelInfo = struct_ImGuiStackLevelInfo;
pub const struct_ImVector_ImGuiStackLevelInfo = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: ?*ImGuiStackLevelInfo = @import("std").mem.zeroes(?*ImGuiStackLevelInfo),
};
pub const ImVector_ImGuiStackLevelInfo = struct_ImVector_ImGuiStackLevelInfo;
pub const struct_ImGuiStackTool = extern struct {
    LastActiveFrame: c_int = @import("std").mem.zeroes(c_int),
    StackLevel: c_int = @import("std").mem.zeroes(c_int),
    QueryId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    Results: ImVector_ImGuiStackLevelInfo = @import("std").mem.zeroes(ImVector_ImGuiStackLevelInfo),
    CopyToClipboardOnCtrlC: bool = @import("std").mem.zeroes(bool),
    CopyToClipboardLastTime: f32 = @import("std").mem.zeroes(f32),
};
pub const ImGuiStackTool = struct_ImGuiStackTool;
pub const struct_ImGuiContext = extern struct {
    Initialized: bool = @import("std").mem.zeroes(bool),
    FontAtlasOwnedByContext: bool = @import("std").mem.zeroes(bool),
    IO: ImGuiIO = @import("std").mem.zeroes(ImGuiIO),
    PlatformIO: ImGuiPlatformIO = @import("std").mem.zeroes(ImGuiPlatformIO),
    InputEventsQueue: ImVector_ImGuiInputEvent = @import("std").mem.zeroes(ImVector_ImGuiInputEvent),
    InputEventsTrail: ImVector_ImGuiInputEvent = @import("std").mem.zeroes(ImVector_ImGuiInputEvent),
    Style: ImGuiStyle = @import("std").mem.zeroes(ImGuiStyle),
    ConfigFlagsCurrFrame: ImGuiConfigFlags = @import("std").mem.zeroes(ImGuiConfigFlags),
    ConfigFlagsLastFrame: ImGuiConfigFlags = @import("std").mem.zeroes(ImGuiConfigFlags),
    Font: [*c]ImFont = @import("std").mem.zeroes([*c]ImFont),
    FontSize: f32 = @import("std").mem.zeroes(f32),
    FontBaseSize: f32 = @import("std").mem.zeroes(f32),
    DrawListSharedData: ImDrawListSharedData = @import("std").mem.zeroes(ImDrawListSharedData),
    Time: f64 = @import("std").mem.zeroes(f64),
    FrameCount: c_int = @import("std").mem.zeroes(c_int),
    FrameCountEnded: c_int = @import("std").mem.zeroes(c_int),
    FrameCountPlatformEnded: c_int = @import("std").mem.zeroes(c_int),
    FrameCountRendered: c_int = @import("std").mem.zeroes(c_int),
    WithinFrameScope: bool = @import("std").mem.zeroes(bool),
    WithinFrameScopeWithImplicitWindow: bool = @import("std").mem.zeroes(bool),
    WithinEndChild: bool = @import("std").mem.zeroes(bool),
    GcCompactAll: bool = @import("std").mem.zeroes(bool),
    TestEngineHookItems: bool = @import("std").mem.zeroes(bool),
    TestEngine: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    Windows: ImVector_ImGuiWindowPtr = @import("std").mem.zeroes(ImVector_ImGuiWindowPtr),
    WindowsFocusOrder: ImVector_ImGuiWindowPtr = @import("std").mem.zeroes(ImVector_ImGuiWindowPtr),
    WindowsTempSortBuffer: ImVector_ImGuiWindowPtr = @import("std").mem.zeroes(ImVector_ImGuiWindowPtr),
    CurrentWindowStack: ImVector_ImGuiWindowStackData = @import("std").mem.zeroes(ImVector_ImGuiWindowStackData),
    WindowsById: ImGuiStorage = @import("std").mem.zeroes(ImGuiStorage),
    WindowsActiveCount: c_int = @import("std").mem.zeroes(c_int),
    WindowsHoverPadding: ImVec2 = @import("std").mem.zeroes(ImVec2),
    CurrentWindow: ?*ImGuiWindow = @import("std").mem.zeroes(?*ImGuiWindow),
    HoveredWindow: ?*ImGuiWindow = @import("std").mem.zeroes(?*ImGuiWindow),
    HoveredWindowUnderMovingWindow: ?*ImGuiWindow = @import("std").mem.zeroes(?*ImGuiWindow),
    HoveredDockNode: ?*ImGuiDockNode = @import("std").mem.zeroes(?*ImGuiDockNode),
    MovingWindow: ?*ImGuiWindow = @import("std").mem.zeroes(?*ImGuiWindow),
    WheelingWindow: ?*ImGuiWindow = @import("std").mem.zeroes(?*ImGuiWindow),
    WheelingWindowRefMousePos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    WheelingWindowTimer: f32 = @import("std").mem.zeroes(f32),
    DebugHookIdInfo: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    HoveredId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    HoveredIdPreviousFrame: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    HoveredIdAllowOverlap: bool = @import("std").mem.zeroes(bool),
    HoveredIdUsingMouseWheel: bool = @import("std").mem.zeroes(bool),
    HoveredIdPreviousFrameUsingMouseWheel: bool = @import("std").mem.zeroes(bool),
    HoveredIdDisabled: bool = @import("std").mem.zeroes(bool),
    HoveredIdTimer: f32 = @import("std").mem.zeroes(f32),
    HoveredIdNotActiveTimer: f32 = @import("std").mem.zeroes(f32),
    ActiveId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    ActiveIdIsAlive: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    ActiveIdTimer: f32 = @import("std").mem.zeroes(f32),
    ActiveIdIsJustActivated: bool = @import("std").mem.zeroes(bool),
    ActiveIdAllowOverlap: bool = @import("std").mem.zeroes(bool),
    ActiveIdNoClearOnFocusLoss: bool = @import("std").mem.zeroes(bool),
    ActiveIdHasBeenPressedBefore: bool = @import("std").mem.zeroes(bool),
    ActiveIdHasBeenEditedBefore: bool = @import("std").mem.zeroes(bool),
    ActiveIdHasBeenEditedThisFrame: bool = @import("std").mem.zeroes(bool),
    ActiveIdClickOffset: ImVec2 = @import("std").mem.zeroes(ImVec2),
    ActiveIdWindow: ?*ImGuiWindow = @import("std").mem.zeroes(?*ImGuiWindow),
    ActiveIdSource: ImGuiInputSource = @import("std").mem.zeroes(ImGuiInputSource),
    ActiveIdMouseButton: c_int = @import("std").mem.zeroes(c_int),
    ActiveIdPreviousFrame: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    ActiveIdPreviousFrameIsAlive: bool = @import("std").mem.zeroes(bool),
    ActiveIdPreviousFrameHasBeenEditedBefore: bool = @import("std").mem.zeroes(bool),
    ActiveIdPreviousFrameWindow: ?*ImGuiWindow = @import("std").mem.zeroes(?*ImGuiWindow),
    LastActiveId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    LastActiveIdTimer: f32 = @import("std").mem.zeroes(f32),
    ActiveIdUsingMouseWheel: bool = @import("std").mem.zeroes(bool),
    ActiveIdUsingNavDirMask: ImU32 = @import("std").mem.zeroes(ImU32),
    ActiveIdUsingNavInputMask: ImU32 = @import("std").mem.zeroes(ImU32),
    ActiveIdUsingKeyInputMask: ImBitArrayForNamedKeys = @import("std").mem.zeroes(ImBitArrayForNamedKeys),
    CurrentItemFlags: ImGuiItemFlags = @import("std").mem.zeroes(ImGuiItemFlags),
    NextItemData: ImGuiNextItemData = @import("std").mem.zeroes(ImGuiNextItemData),
    LastItemData: ImGuiLastItemData = @import("std").mem.zeroes(ImGuiLastItemData),
    NextWindowData: ImGuiNextWindowData = @import("std").mem.zeroes(ImGuiNextWindowData),
    ColorStack: ImVector_ImGuiColorMod = @import("std").mem.zeroes(ImVector_ImGuiColorMod),
    StyleVarStack: ImVector_ImGuiStyleMod = @import("std").mem.zeroes(ImVector_ImGuiStyleMod),
    FontStack: ImVector_ImFontPtr = @import("std").mem.zeroes(ImVector_ImFontPtr),
    FocusScopeStack: ImVector_ImGuiID = @import("std").mem.zeroes(ImVector_ImGuiID),
    ItemFlagsStack: ImVector_ImGuiItemFlags = @import("std").mem.zeroes(ImVector_ImGuiItemFlags),
    GroupStack: ImVector_ImGuiGroupData = @import("std").mem.zeroes(ImVector_ImGuiGroupData),
    OpenPopupStack: ImVector_ImGuiPopupData = @import("std").mem.zeroes(ImVector_ImGuiPopupData),
    BeginPopupStack: ImVector_ImGuiPopupData = @import("std").mem.zeroes(ImVector_ImGuiPopupData),
    BeginMenuCount: c_int = @import("std").mem.zeroes(c_int),
    Viewports: ImVector_ImGuiViewportPPtr = @import("std").mem.zeroes(ImVector_ImGuiViewportPPtr),
    CurrentDpiScale: f32 = @import("std").mem.zeroes(f32),
    CurrentViewport: [*c]ImGuiViewportP = @import("std").mem.zeroes([*c]ImGuiViewportP),
    MouseViewport: [*c]ImGuiViewportP = @import("std").mem.zeroes([*c]ImGuiViewportP),
    MouseLastHoveredViewport: [*c]ImGuiViewportP = @import("std").mem.zeroes([*c]ImGuiViewportP),
    PlatformLastFocusedViewportId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    FallbackMonitor: ImGuiPlatformMonitor = @import("std").mem.zeroes(ImGuiPlatformMonitor),
    ViewportFrontMostStampCount: c_int = @import("std").mem.zeroes(c_int),
    NavWindow: ?*ImGuiWindow = @import("std").mem.zeroes(?*ImGuiWindow),
    NavId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    NavFocusScopeId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    NavActivateId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    NavActivateDownId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    NavActivatePressedId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    NavActivateInputId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    NavActivateFlags: ImGuiActivateFlags = @import("std").mem.zeroes(ImGuiActivateFlags),
    NavJustMovedToId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    NavJustMovedToFocusScopeId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    NavJustMovedToKeyMods: ImGuiModFlags = @import("std").mem.zeroes(ImGuiModFlags),
    NavNextActivateId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    NavNextActivateFlags: ImGuiActivateFlags = @import("std").mem.zeroes(ImGuiActivateFlags),
    NavInputSource: ImGuiInputSource = @import("std").mem.zeroes(ImGuiInputSource),
    NavLayer: ImGuiNavLayer = @import("std").mem.zeroes(ImGuiNavLayer),
    NavIdIsAlive: bool = @import("std").mem.zeroes(bool),
    NavMousePosDirty: bool = @import("std").mem.zeroes(bool),
    NavDisableHighlight: bool = @import("std").mem.zeroes(bool),
    NavDisableMouseHover: bool = @import("std").mem.zeroes(bool),
    NavAnyRequest: bool = @import("std").mem.zeroes(bool),
    NavInitRequest: bool = @import("std").mem.zeroes(bool),
    NavInitRequestFromMove: bool = @import("std").mem.zeroes(bool),
    NavInitResultId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    NavInitResultRectRel: ImRect = @import("std").mem.zeroes(ImRect),
    NavMoveSubmitted: bool = @import("std").mem.zeroes(bool),
    NavMoveScoringItems: bool = @import("std").mem.zeroes(bool),
    NavMoveForwardToNextFrame: bool = @import("std").mem.zeroes(bool),
    NavMoveFlags: ImGuiNavMoveFlags = @import("std").mem.zeroes(ImGuiNavMoveFlags),
    NavMoveScrollFlags: ImGuiScrollFlags = @import("std").mem.zeroes(ImGuiScrollFlags),
    NavMoveKeyMods: ImGuiModFlags = @import("std").mem.zeroes(ImGuiModFlags),
    NavMoveDir: ImGuiDir = @import("std").mem.zeroes(ImGuiDir),
    NavMoveDirForDebug: ImGuiDir = @import("std").mem.zeroes(ImGuiDir),
    NavMoveClipDir: ImGuiDir = @import("std").mem.zeroes(ImGuiDir),
    NavScoringRect: ImRect = @import("std").mem.zeroes(ImRect),
    NavScoringNoClipRect: ImRect = @import("std").mem.zeroes(ImRect),
    NavScoringDebugCount: c_int = @import("std").mem.zeroes(c_int),
    NavTabbingDir: c_int = @import("std").mem.zeroes(c_int),
    NavTabbingCounter: c_int = @import("std").mem.zeroes(c_int),
    NavMoveResultLocal: ImGuiNavItemData = @import("std").mem.zeroes(ImGuiNavItemData),
    NavMoveResultLocalVisible: ImGuiNavItemData = @import("std").mem.zeroes(ImGuiNavItemData),
    NavMoveResultOther: ImGuiNavItemData = @import("std").mem.zeroes(ImGuiNavItemData),
    NavTabbingResultFirst: ImGuiNavItemData = @import("std").mem.zeroes(ImGuiNavItemData),
    NavWindowingTarget: ?*ImGuiWindow = @import("std").mem.zeroes(?*ImGuiWindow),
    NavWindowingTargetAnim: ?*ImGuiWindow = @import("std").mem.zeroes(?*ImGuiWindow),
    NavWindowingListWindow: ?*ImGuiWindow = @import("std").mem.zeroes(?*ImGuiWindow),
    NavWindowingTimer: f32 = @import("std").mem.zeroes(f32),
    NavWindowingHighlightAlpha: f32 = @import("std").mem.zeroes(f32),
    NavWindowingToggleLayer: bool = @import("std").mem.zeroes(bool),
    DimBgRatio: f32 = @import("std").mem.zeroes(f32),
    MouseCursor: ImGuiMouseCursor = @import("std").mem.zeroes(ImGuiMouseCursor),
    DragDropActive: bool = @import("std").mem.zeroes(bool),
    DragDropWithinSource: bool = @import("std").mem.zeroes(bool),
    DragDropWithinTarget: bool = @import("std").mem.zeroes(bool),
    DragDropSourceFlags: ImGuiDragDropFlags = @import("std").mem.zeroes(ImGuiDragDropFlags),
    DragDropSourceFrameCount: c_int = @import("std").mem.zeroes(c_int),
    DragDropMouseButton: c_int = @import("std").mem.zeroes(c_int),
    DragDropPayload: ImGuiPayload = @import("std").mem.zeroes(ImGuiPayload),
    DragDropTargetRect: ImRect = @import("std").mem.zeroes(ImRect),
    DragDropTargetId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    DragDropAcceptFlags: ImGuiDragDropFlags = @import("std").mem.zeroes(ImGuiDragDropFlags),
    DragDropAcceptIdCurrRectSurface: f32 = @import("std").mem.zeroes(f32),
    DragDropAcceptIdCurr: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    DragDropAcceptIdPrev: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    DragDropAcceptFrameCount: c_int = @import("std").mem.zeroes(c_int),
    DragDropHoldJustPressedId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    DragDropPayloadBufHeap: ImVector_unsigned_char = @import("std").mem.zeroes(ImVector_unsigned_char),
    DragDropPayloadBufLocal: [16]u8 = @import("std").mem.zeroes([16]u8),
    ClipperTempDataStacked: c_int = @import("std").mem.zeroes(c_int),
    ClipperTempData: ImVector_ImGuiListClipperData = @import("std").mem.zeroes(ImVector_ImGuiListClipperData),
    CurrentTable: ?*ImGuiTable = @import("std").mem.zeroes(?*ImGuiTable),
    TablesTempDataStacked: c_int = @import("std").mem.zeroes(c_int),
    TablesTempData: ImVector_ImGuiTableTempData = @import("std").mem.zeroes(ImVector_ImGuiTableTempData),
    Tables: ImPool_ImGuiTable = @import("std").mem.zeroes(ImPool_ImGuiTable),
    TablesLastTimeActive: ImVector_float = @import("std").mem.zeroes(ImVector_float),
    DrawChannelsTempMergeBuffer: ImVector_ImDrawChannel = @import("std").mem.zeroes(ImVector_ImDrawChannel),
    CurrentTabBar: [*c]ImGuiTabBar = @import("std").mem.zeroes([*c]ImGuiTabBar),
    TabBars: ImPool_ImGuiTabBar = @import("std").mem.zeroes(ImPool_ImGuiTabBar),
    CurrentTabBarStack: ImVector_ImGuiPtrOrIndex = @import("std").mem.zeroes(ImVector_ImGuiPtrOrIndex),
    ShrinkWidthBuffer: ImVector_ImGuiShrinkWidthItem = @import("std").mem.zeroes(ImVector_ImGuiShrinkWidthItem),
    MouseLastValidPos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    InputTextState: ImGuiInputTextState = @import("std").mem.zeroes(ImGuiInputTextState),
    InputTextPasswordFont: ImFont = @import("std").mem.zeroes(ImFont),
    TempInputId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    ColorEditOptions: ImGuiColorEditFlags = @import("std").mem.zeroes(ImGuiColorEditFlags),
    ColorEditLastHue: f32 = @import("std").mem.zeroes(f32),
    ColorEditLastSat: f32 = @import("std").mem.zeroes(f32),
    ColorEditLastColor: ImU32 = @import("std").mem.zeroes(ImU32),
    ColorPickerRef: ImVec4 = @import("std").mem.zeroes(ImVec4),
    ComboPreviewData: ImGuiComboPreviewData = @import("std").mem.zeroes(ImGuiComboPreviewData),
    SliderGrabClickOffset: f32 = @import("std").mem.zeroes(f32),
    SliderCurrentAccum: f32 = @import("std").mem.zeroes(f32),
    SliderCurrentAccumDirty: bool = @import("std").mem.zeroes(bool),
    DragCurrentAccumDirty: bool = @import("std").mem.zeroes(bool),
    DragCurrentAccum: f32 = @import("std").mem.zeroes(f32),
    DragSpeedDefaultRatio: f32 = @import("std").mem.zeroes(f32),
    ScrollbarClickDeltaToGrabCenter: f32 = @import("std").mem.zeroes(f32),
    DisabledAlphaBackup: f32 = @import("std").mem.zeroes(f32),
    DisabledStackSize: c_short = @import("std").mem.zeroes(c_short),
    TooltipOverrideCount: c_short = @import("std").mem.zeroes(c_short),
    TooltipSlowDelay: f32 = @import("std").mem.zeroes(f32),
    ClipboardHandlerData: ImVector_char = @import("std").mem.zeroes(ImVector_char),
    MenusIdSubmittedThisFrame: ImVector_ImGuiID = @import("std").mem.zeroes(ImVector_ImGuiID),
    PlatformImeData: ImGuiPlatformImeData = @import("std").mem.zeroes(ImGuiPlatformImeData),
    PlatformImeDataPrev: ImGuiPlatformImeData = @import("std").mem.zeroes(ImGuiPlatformImeData),
    PlatformImeViewport: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    PlatformLocaleDecimalPoint: u8 = @import("std").mem.zeroes(u8),
    DockContext: ImGuiDockContext = @import("std").mem.zeroes(ImGuiDockContext),
    SettingsLoaded: bool = @import("std").mem.zeroes(bool),
    SettingsDirtyTimer: f32 = @import("std").mem.zeroes(f32),
    SettingsIniData: ImGuiTextBuffer = @import("std").mem.zeroes(ImGuiTextBuffer),
    SettingsHandlers: ImVector_ImGuiSettingsHandler = @import("std").mem.zeroes(ImVector_ImGuiSettingsHandler),
    SettingsWindows: ImChunkStream_ImGuiWindowSettings = @import("std").mem.zeroes(ImChunkStream_ImGuiWindowSettings),
    SettingsTables: ImChunkStream_ImGuiTableSettings = @import("std").mem.zeroes(ImChunkStream_ImGuiTableSettings),
    Hooks: ImVector_ImGuiContextHook = @import("std").mem.zeroes(ImVector_ImGuiContextHook),
    HookIdNext: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    LogEnabled: bool = @import("std").mem.zeroes(bool),
    LogType: ImGuiLogType = @import("std").mem.zeroes(ImGuiLogType),
    LogFile: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    LogBuffer: ImGuiTextBuffer = @import("std").mem.zeroes(ImGuiTextBuffer),
    LogNextPrefix: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    LogNextSuffix: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    LogLinePosY: f32 = @import("std").mem.zeroes(f32),
    LogLineFirstItem: bool = @import("std").mem.zeroes(bool),
    LogDepthRef: c_int = @import("std").mem.zeroes(c_int),
    LogDepthToExpand: c_int = @import("std").mem.zeroes(c_int),
    LogDepthToExpandDefault: c_int = @import("std").mem.zeroes(c_int),
    DebugLogFlags: ImGuiDebugLogFlags = @import("std").mem.zeroes(ImGuiDebugLogFlags),
    DebugLogBuf: ImGuiTextBuffer = @import("std").mem.zeroes(ImGuiTextBuffer),
    DebugItemPickerActive: bool = @import("std").mem.zeroes(bool),
    DebugItemPickerBreakId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    DebugMetricsConfig: ImGuiMetricsConfig = @import("std").mem.zeroes(ImGuiMetricsConfig),
    DebugStackTool: ImGuiStackTool = @import("std").mem.zeroes(ImGuiStackTool),
    FramerateSecPerFrame: [120]f32 = @import("std").mem.zeroes([120]f32),
    FramerateSecPerFrameIdx: c_int = @import("std").mem.zeroes(c_int),
    FramerateSecPerFrameCount: c_int = @import("std").mem.zeroes(c_int),
    FramerateSecPerFrameAccum: f32 = @import("std").mem.zeroes(f32),
    WantCaptureMouseNextFrame: c_int = @import("std").mem.zeroes(c_int),
    WantCaptureKeyboardNextFrame: c_int = @import("std").mem.zeroes(c_int),
    WantTextInputNextFrame: c_int = @import("std").mem.zeroes(c_int),
    TempBuffer: ImVector_char = @import("std").mem.zeroes(ImVector_char),
};
pub const struct_ImGuiInputTextCallbackData = extern struct {
    EventFlag: ImGuiInputTextFlags = @import("std").mem.zeroes(ImGuiInputTextFlags),
    Flags: ImGuiInputTextFlags = @import("std").mem.zeroes(ImGuiInputTextFlags),
    UserData: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    EventChar: ImWchar = @import("std").mem.zeroes(ImWchar),
    EventKey: ImGuiKey = @import("std").mem.zeroes(ImGuiKey),
    Buf: [*c]u8 = @import("std").mem.zeroes([*c]u8),
    BufTextLen: c_int = @import("std").mem.zeroes(c_int),
    BufSize: c_int = @import("std").mem.zeroes(c_int),
    BufDirty: bool = @import("std").mem.zeroes(bool),
    CursorPos: c_int = @import("std").mem.zeroes(c_int),
    SelectionStart: c_int = @import("std").mem.zeroes(c_int),
    SelectionEnd: c_int = @import("std").mem.zeroes(c_int),
};
pub const ImGuiInputTextCallbackData = struct_ImGuiInputTextCallbackData;
pub const struct_ImGuiOnceUponAFrame = extern struct {
    RefFrame: c_int = @import("std").mem.zeroes(c_int),
};
pub const ImGuiOnceUponAFrame = struct_ImGuiOnceUponAFrame;
// cimgui2.h:969:24: warning: struct demoted to opaque type - has bitfield
pub const struct_ImGuiTableColumnSortSpecs = opaque {};
pub const ImGuiTableColumnSortSpecs = struct_ImGuiTableColumnSortSpecs;
pub const struct_ImGuiTableSortSpecs = extern struct {
    Specs: ?*const ImGuiTableColumnSortSpecs = @import("std").mem.zeroes(?*const ImGuiTableColumnSortSpecs),
    SpecsCount: c_int = @import("std").mem.zeroes(c_int),
    SpecsDirty: bool = @import("std").mem.zeroes(bool),
};
pub const ImGuiTableSortSpecs = struct_ImGuiTableSortSpecs;
pub const struct_ImGuiTextRange = extern struct {
    b: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    e: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
};
pub const ImGuiTextRange = struct_ImGuiTextRange;
pub const struct_ImVector_ImGuiTextRange = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiTextRange = @import("std").mem.zeroes([*c]ImGuiTextRange),
};
pub const ImVector_ImGuiTextRange = struct_ImVector_ImGuiTextRange;
pub const struct_ImGuiTextFilter = extern struct {
    InputBuf: [256]u8 = @import("std").mem.zeroes([256]u8),
    Filters: ImVector_ImGuiTextRange = @import("std").mem.zeroes(ImVector_ImGuiTextRange),
    CountGrep: c_int = @import("std").mem.zeroes(c_int),
};
pub const ImGuiTextFilter = struct_ImGuiTextFilter;
pub const struct_ImBitVector = extern struct {
    Storage: ImVector_ImU32 = @import("std").mem.zeroes(ImVector_ImU32),
};
pub const ImBitVector = struct_ImBitVector;
pub const struct_ImGuiDataTypeInfo = extern struct {
    Size: usize = @import("std").mem.zeroes(usize),
    Name: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    PrintFmt: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
    ScanFmt: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
};
pub const ImGuiDataTypeInfo = struct_ImGuiDataTypeInfo;
pub const struct_ImGuiMenuColumns = extern struct {
    TotalWidth: ImU32 = @import("std").mem.zeroes(ImU32),
    NextTotalWidth: ImU32 = @import("std").mem.zeroes(ImU32),
    Spacing: ImU16 = @import("std").mem.zeroes(ImU16),
    OffsetIcon: ImU16 = @import("std").mem.zeroes(ImU16),
    OffsetLabel: ImU16 = @import("std").mem.zeroes(ImU16),
    OffsetShortcut: ImU16 = @import("std").mem.zeroes(ImU16),
    OffsetMark: ImU16 = @import("std").mem.zeroes(ImU16),
    Widths: [4]ImU16 = @import("std").mem.zeroes([4]ImU16),
};
pub const ImGuiMenuColumns = struct_ImGuiMenuColumns;
pub const ImGuiOldColumnFlags = c_int;
pub const struct_ImGuiOldColumnData = extern struct {
    OffsetNorm: f32 = @import("std").mem.zeroes(f32),
    OffsetNormBeforeResize: f32 = @import("std").mem.zeroes(f32),
    Flags: ImGuiOldColumnFlags = @import("std").mem.zeroes(ImGuiOldColumnFlags),
    ClipRect: ImRect = @import("std").mem.zeroes(ImRect),
};
pub const ImGuiOldColumnData = struct_ImGuiOldColumnData;
pub const struct_ImVector_ImGuiOldColumnData = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiOldColumnData = @import("std").mem.zeroes([*c]ImGuiOldColumnData),
};
pub const ImVector_ImGuiOldColumnData = struct_ImVector_ImGuiOldColumnData;
pub const struct_ImGuiOldColumns = extern struct {
    ID: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    Flags: ImGuiOldColumnFlags = @import("std").mem.zeroes(ImGuiOldColumnFlags),
    IsFirstFrame: bool = @import("std").mem.zeroes(bool),
    IsBeingResized: bool = @import("std").mem.zeroes(bool),
    Current: c_int = @import("std").mem.zeroes(c_int),
    Count: c_int = @import("std").mem.zeroes(c_int),
    OffMinX: f32 = @import("std").mem.zeroes(f32),
    OffMaxX: f32 = @import("std").mem.zeroes(f32),
    LineMinY: f32 = @import("std").mem.zeroes(f32),
    LineMaxY: f32 = @import("std").mem.zeroes(f32),
    HostCursorPosY: f32 = @import("std").mem.zeroes(f32),
    HostCursorMaxPosX: f32 = @import("std").mem.zeroes(f32),
    HostInitialClipRect: ImRect = @import("std").mem.zeroes(ImRect),
    HostBackupClipRect: ImRect = @import("std").mem.zeroes(ImRect),
    HostBackupParentWorkRect: ImRect = @import("std").mem.zeroes(ImRect),
    Columns: ImVector_ImGuiOldColumnData = @import("std").mem.zeroes(ImVector_ImGuiOldColumnData),
    Splitter: ImDrawListSplitter = @import("std").mem.zeroes(ImDrawListSplitter),
};
pub const ImGuiOldColumns = struct_ImGuiOldColumns;
pub const struct_ImGuiTableInstanceData = extern struct {
    LastOuterHeight: f32 = @import("std").mem.zeroes(f32),
    LastFirstRowHeight: f32 = @import("std").mem.zeroes(f32),
};
pub const ImGuiTableInstanceData = struct_ImGuiTableInstanceData;
pub const struct_ImGuiTableSettings = extern struct {
    ID: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    SaveFlags: ImGuiTableFlags = @import("std").mem.zeroes(ImGuiTableFlags),
    RefScale: f32 = @import("std").mem.zeroes(f32),
    ColumnsCount: ImGuiTableColumnIdx = @import("std").mem.zeroes(ImGuiTableColumnIdx),
    ColumnsCountMax: ImGuiTableColumnIdx = @import("std").mem.zeroes(ImGuiTableColumnIdx),
    WantApply: bool = @import("std").mem.zeroes(bool),
};
pub const ImGuiTableSettings = struct_ImGuiTableSettings;
pub const struct_ImGuiTableColumnsSettings = opaque {};
pub const ImGuiTableColumnsSettings = struct_ImGuiTableColumnsSettings;
pub const struct_ImGuiWindowTempData = extern struct {
    CursorPos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    CursorPosPrevLine: ImVec2 = @import("std").mem.zeroes(ImVec2),
    CursorStartPos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    CursorMaxPos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    IdealMaxPos: ImVec2 = @import("std").mem.zeroes(ImVec2),
    CurrLineSize: ImVec2 = @import("std").mem.zeroes(ImVec2),
    PrevLineSize: ImVec2 = @import("std").mem.zeroes(ImVec2),
    CurrLineTextBaseOffset: f32 = @import("std").mem.zeroes(f32),
    PrevLineTextBaseOffset: f32 = @import("std").mem.zeroes(f32),
    IsSameLine: bool = @import("std").mem.zeroes(bool),
    Indent: ImVec1 = @import("std").mem.zeroes(ImVec1),
    ColumnsOffset: ImVec1 = @import("std").mem.zeroes(ImVec1),
    GroupOffset: ImVec1 = @import("std").mem.zeroes(ImVec1),
    CursorStartPosLossyness: ImVec2 = @import("std").mem.zeroes(ImVec2),
    NavLayerCurrent: ImGuiNavLayer = @import("std").mem.zeroes(ImGuiNavLayer),
    NavLayersActiveMask: c_short = @import("std").mem.zeroes(c_short),
    NavLayersActiveMaskNext: c_short = @import("std").mem.zeroes(c_short),
    NavFocusScopeIdCurrent: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    NavHideHighlightOneFrame: bool = @import("std").mem.zeroes(bool),
    NavHasScroll: bool = @import("std").mem.zeroes(bool),
    MenuBarAppending: bool = @import("std").mem.zeroes(bool),
    MenuBarOffset: ImVec2 = @import("std").mem.zeroes(ImVec2),
    MenuColumns: ImGuiMenuColumns = @import("std").mem.zeroes(ImGuiMenuColumns),
    TreeDepth: c_int = @import("std").mem.zeroes(c_int),
    TreeJumpToParentOnPopMask: ImU32 = @import("std").mem.zeroes(ImU32),
    ChildWindows: ImVector_ImGuiWindowPtr = @import("std").mem.zeroes(ImVector_ImGuiWindowPtr),
    StateStorage: [*c]ImGuiStorage = @import("std").mem.zeroes([*c]ImGuiStorage),
    CurrentColumns: [*c]ImGuiOldColumns = @import("std").mem.zeroes([*c]ImGuiOldColumns),
    CurrentTableIdx: c_int = @import("std").mem.zeroes(c_int),
    LayoutType: ImGuiLayoutType = @import("std").mem.zeroes(ImGuiLayoutType),
    ParentLayoutType: ImGuiLayoutType = @import("std").mem.zeroes(ImGuiLayoutType),
    ItemWidth: f32 = @import("std").mem.zeroes(f32),
    TextWrapPos: f32 = @import("std").mem.zeroes(f32),
    ItemWidthStack: ImVector_float = @import("std").mem.zeroes(ImVector_float),
    TextWrapPosStack: ImVector_float = @import("std").mem.zeroes(ImVector_float),
};
pub const ImGuiWindowTempData = struct_ImGuiWindowTempData;
pub const struct_ImVec2ih = extern struct {
    x: c_short = @import("std").mem.zeroes(c_short),
    y: c_short = @import("std").mem.zeroes(c_short),
};
pub const ImVec2ih = struct_ImVec2ih;
pub const struct_ImGuiWindowSettings = extern struct {
    ID: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    Pos: ImVec2ih = @import("std").mem.zeroes(ImVec2ih),
    Size: ImVec2ih = @import("std").mem.zeroes(ImVec2ih),
    ViewportPos: ImVec2ih = @import("std").mem.zeroes(ImVec2ih),
    ViewportId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    DockId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    ClassId: ImGuiID = @import("std").mem.zeroes(ImGuiID),
    DockOrder: c_short = @import("std").mem.zeroes(c_short),
    Collapsed: bool = @import("std").mem.zeroes(bool),
    WantApply: bool = @import("std").mem.zeroes(bool),
};
pub const ImGuiWindowSettings = struct_ImGuiWindowSettings;
pub const struct_ImVector_const_charPtr = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c][*c]const u8 = @import("std").mem.zeroes([*c][*c]const u8),
};
pub const ImVector_const_charPtr = struct_ImVector_const_charPtr;
pub const ImGuiDataType = c_int;
pub const ImGuiNavInput = c_int;
pub const ImGuiMouseButton = c_int;
pub const ImGuiSortDirection = c_int;
pub const ImGuiTableBgTarget = c_int;
pub const ImDrawFlags = c_int;
pub const ImGuiButtonFlags = c_int;
pub const ImGuiComboFlags = c_int;
pub const ImGuiFocusedFlags = c_int;
pub const ImGuiHoveredFlags = c_int;
pub const ImGuiPopupFlags = c_int;
pub const ImGuiSelectableFlags = c_int;
pub const ImGuiSliderFlags = c_int;
pub const ImGuiTableRowFlags = c_int;
pub const ImGuiTreeNodeFlags = c_int;
pub const ImS64 = c_longlong;
pub const ImWchar32 = c_uint;
pub const ImGuiInputTextCallback = ?*const fn ([*c]ImGuiInputTextCallbackData) callconv(.C) c_int;
pub const ImGuiMemAllocFunc = ?*const fn (usize, ?*anyopaque) callconv(.C) ?*anyopaque;
pub const ImGuiMemFreeFunc = ?*const fn (?*anyopaque, ?*anyopaque) callconv(.C) void;
pub const ImGuiWindowFlags_None: c_int = 0;
pub const ImGuiWindowFlags_NoTitleBar: c_int = 1;
pub const ImGuiWindowFlags_NoResize: c_int = 2;
pub const ImGuiWindowFlags_NoMove: c_int = 4;
pub const ImGuiWindowFlags_NoScrollbar: c_int = 8;
pub const ImGuiWindowFlags_NoScrollWithMouse: c_int = 16;
pub const ImGuiWindowFlags_NoCollapse: c_int = 32;
pub const ImGuiWindowFlags_AlwaysAutoResize: c_int = 64;
pub const ImGuiWindowFlags_NoBackground: c_int = 128;
pub const ImGuiWindowFlags_NoSavedSettings: c_int = 256;
pub const ImGuiWindowFlags_NoMouseInputs: c_int = 512;
pub const ImGuiWindowFlags_MenuBar: c_int = 1024;
pub const ImGuiWindowFlags_HorizontalScrollbar: c_int = 2048;
pub const ImGuiWindowFlags_NoFocusOnAppearing: c_int = 4096;
pub const ImGuiWindowFlags_NoBringToFrontOnFocus: c_int = 8192;
pub const ImGuiWindowFlags_AlwaysVerticalScrollbar: c_int = 16384;
pub const ImGuiWindowFlags_AlwaysHorizontalScrollbar: c_int = 32768;
pub const ImGuiWindowFlags_AlwaysUseWindowPadding: c_int = 65536;
pub const ImGuiWindowFlags_NoNavInputs: c_int = 262144;
pub const ImGuiWindowFlags_NoNavFocus: c_int = 524288;
pub const ImGuiWindowFlags_UnsavedDocument: c_int = 1048576;
pub const ImGuiWindowFlags_NoDocking: c_int = 2097152;
pub const ImGuiWindowFlags_NoNav: c_int = 786432;
pub const ImGuiWindowFlags_NoDecoration: c_int = 43;
pub const ImGuiWindowFlags_NoInputs: c_int = 786944;
pub const ImGuiWindowFlags_NavFlattened: c_int = 8388608;
pub const ImGuiWindowFlags_ChildWindow: c_int = 16777216;
pub const ImGuiWindowFlags_Tooltip: c_int = 33554432;
pub const ImGuiWindowFlags_Popup: c_int = 67108864;
pub const ImGuiWindowFlags_Modal: c_int = 134217728;
pub const ImGuiWindowFlags_ChildMenu: c_int = 268435456;
pub const ImGuiWindowFlags_DockNodeHost: c_int = 536870912;
pub const ImGuiWindowFlags_ = c_uint;
pub const ImGuiInputTextFlags_None: c_int = 0;
pub const ImGuiInputTextFlags_CharsDecimal: c_int = 1;
pub const ImGuiInputTextFlags_CharsHexadecimal: c_int = 2;
pub const ImGuiInputTextFlags_CharsUppercase: c_int = 4;
pub const ImGuiInputTextFlags_CharsNoBlank: c_int = 8;
pub const ImGuiInputTextFlags_AutoSelectAll: c_int = 16;
pub const ImGuiInputTextFlags_EnterReturnsTrue: c_int = 32;
pub const ImGuiInputTextFlags_CallbackCompletion: c_int = 64;
pub const ImGuiInputTextFlags_CallbackHistory: c_int = 128;
pub const ImGuiInputTextFlags_CallbackAlways: c_int = 256;
pub const ImGuiInputTextFlags_CallbackCharFilter: c_int = 512;
pub const ImGuiInputTextFlags_AllowTabInput: c_int = 1024;
pub const ImGuiInputTextFlags_CtrlEnterForNewLine: c_int = 2048;
pub const ImGuiInputTextFlags_NoHorizontalScroll: c_int = 4096;
pub const ImGuiInputTextFlags_AlwaysOverwrite: c_int = 8192;
pub const ImGuiInputTextFlags_ReadOnly: c_int = 16384;
pub const ImGuiInputTextFlags_Password: c_int = 32768;
pub const ImGuiInputTextFlags_NoUndoRedo: c_int = 65536;
pub const ImGuiInputTextFlags_CharsScientific: c_int = 131072;
pub const ImGuiInputTextFlags_CallbackResize: c_int = 262144;
pub const ImGuiInputTextFlags_CallbackEdit: c_int = 524288;
pub const ImGuiInputTextFlags_ = c_uint;
pub const ImGuiTreeNodeFlags_None: c_int = 0;
pub const ImGuiTreeNodeFlags_Selected: c_int = 1;
pub const ImGuiTreeNodeFlags_Framed: c_int = 2;
pub const ImGuiTreeNodeFlags_AllowItemOverlap: c_int = 4;
pub const ImGuiTreeNodeFlags_NoTreePushOnOpen: c_int = 8;
pub const ImGuiTreeNodeFlags_NoAutoOpenOnLog: c_int = 16;
pub const ImGuiTreeNodeFlags_DefaultOpen: c_int = 32;
pub const ImGuiTreeNodeFlags_OpenOnDoubleClick: c_int = 64;
pub const ImGuiTreeNodeFlags_OpenOnArrow: c_int = 128;
pub const ImGuiTreeNodeFlags_Leaf: c_int = 256;
pub const ImGuiTreeNodeFlags_Bullet: c_int = 512;
pub const ImGuiTreeNodeFlags_FramePadding: c_int = 1024;
pub const ImGuiTreeNodeFlags_SpanAvailWidth: c_int = 2048;
pub const ImGuiTreeNodeFlags_SpanFullWidth: c_int = 4096;
pub const ImGuiTreeNodeFlags_NavLeftJumpsBackHere: c_int = 8192;
pub const ImGuiTreeNodeFlags_CollapsingHeader: c_int = 26;
pub const ImGuiTreeNodeFlags_ = c_uint;
pub const ImGuiPopupFlags_None: c_int = 0;
pub const ImGuiPopupFlags_MouseButtonLeft: c_int = 0;
pub const ImGuiPopupFlags_MouseButtonRight: c_int = 1;
pub const ImGuiPopupFlags_MouseButtonMiddle: c_int = 2;
pub const ImGuiPopupFlags_MouseButtonMask_: c_int = 31;
pub const ImGuiPopupFlags_MouseButtonDefault_: c_int = 1;
pub const ImGuiPopupFlags_NoOpenOverExistingPopup: c_int = 32;
pub const ImGuiPopupFlags_NoOpenOverItems: c_int = 64;
pub const ImGuiPopupFlags_AnyPopupId: c_int = 128;
pub const ImGuiPopupFlags_AnyPopupLevel: c_int = 256;
pub const ImGuiPopupFlags_AnyPopup: c_int = 384;
pub const ImGuiPopupFlags_ = c_uint;
pub const ImGuiSelectableFlags_None: c_int = 0;
pub const ImGuiSelectableFlags_DontClosePopups: c_int = 1;
pub const ImGuiSelectableFlags_SpanAllColumns: c_int = 2;
pub const ImGuiSelectableFlags_AllowDoubleClick: c_int = 4;
pub const ImGuiSelectableFlags_Disabled: c_int = 8;
pub const ImGuiSelectableFlags_AllowItemOverlap: c_int = 16;
pub const ImGuiSelectableFlags_ = c_uint;
pub const ImGuiComboFlags_None: c_int = 0;
pub const ImGuiComboFlags_PopupAlignLeft: c_int = 1;
pub const ImGuiComboFlags_HeightSmall: c_int = 2;
pub const ImGuiComboFlags_HeightRegular: c_int = 4;
pub const ImGuiComboFlags_HeightLarge: c_int = 8;
pub const ImGuiComboFlags_HeightLargest: c_int = 16;
pub const ImGuiComboFlags_NoArrowButton: c_int = 32;
pub const ImGuiComboFlags_NoPreview: c_int = 64;
pub const ImGuiComboFlags_HeightMask_: c_int = 30;
pub const ImGuiComboFlags_ = c_uint;
pub const ImGuiTabBarFlags_None: c_int = 0;
pub const ImGuiTabBarFlags_Reorderable: c_int = 1;
pub const ImGuiTabBarFlags_AutoSelectNewTabs: c_int = 2;
pub const ImGuiTabBarFlags_TabListPopupButton: c_int = 4;
pub const ImGuiTabBarFlags_NoCloseWithMiddleMouseButton: c_int = 8;
pub const ImGuiTabBarFlags_NoTabListScrollingButtons: c_int = 16;
pub const ImGuiTabBarFlags_NoTooltip: c_int = 32;
pub const ImGuiTabBarFlags_FittingPolicyResizeDown: c_int = 64;
pub const ImGuiTabBarFlags_FittingPolicyScroll: c_int = 128;
pub const ImGuiTabBarFlags_FittingPolicyMask_: c_int = 192;
pub const ImGuiTabBarFlags_FittingPolicyDefault_: c_int = 64;
pub const ImGuiTabBarFlags_ = c_uint;
pub const ImGuiTabItemFlags_None: c_int = 0;
pub const ImGuiTabItemFlags_UnsavedDocument: c_int = 1;
pub const ImGuiTabItemFlags_SetSelected: c_int = 2;
pub const ImGuiTabItemFlags_NoCloseWithMiddleMouseButton: c_int = 4;
pub const ImGuiTabItemFlags_NoPushId: c_int = 8;
pub const ImGuiTabItemFlags_NoTooltip: c_int = 16;
pub const ImGuiTabItemFlags_NoReorder: c_int = 32;
pub const ImGuiTabItemFlags_Leading: c_int = 64;
pub const ImGuiTabItemFlags_Trailing: c_int = 128;
pub const ImGuiTabItemFlags_ = c_uint;
pub const ImGuiTableFlags_None: c_int = 0;
pub const ImGuiTableFlags_Resizable: c_int = 1;
pub const ImGuiTableFlags_Reorderable: c_int = 2;
pub const ImGuiTableFlags_Hideable: c_int = 4;
pub const ImGuiTableFlags_Sortable: c_int = 8;
pub const ImGuiTableFlags_NoSavedSettings: c_int = 16;
pub const ImGuiTableFlags_ContextMenuInBody: c_int = 32;
pub const ImGuiTableFlags_RowBg: c_int = 64;
pub const ImGuiTableFlags_BordersInnerH: c_int = 128;
pub const ImGuiTableFlags_BordersOuterH: c_int = 256;
pub const ImGuiTableFlags_BordersInnerV: c_int = 512;
pub const ImGuiTableFlags_BordersOuterV: c_int = 1024;
pub const ImGuiTableFlags_BordersH: c_int = 384;
pub const ImGuiTableFlags_BordersV: c_int = 1536;
pub const ImGuiTableFlags_BordersInner: c_int = 640;
pub const ImGuiTableFlags_BordersOuter: c_int = 1280;
pub const ImGuiTableFlags_Borders: c_int = 1920;
pub const ImGuiTableFlags_NoBordersInBody: c_int = 2048;
pub const ImGuiTableFlags_NoBordersInBodyUntilResize: c_int = 4096;
pub const ImGuiTableFlags_SizingFixedFit: c_int = 8192;
pub const ImGuiTableFlags_SizingFixedSame: c_int = 16384;
pub const ImGuiTableFlags_SizingStretchProp: c_int = 24576;
pub const ImGuiTableFlags_SizingStretchSame: c_int = 32768;
pub const ImGuiTableFlags_NoHostExtendX: c_int = 65536;
pub const ImGuiTableFlags_NoHostExtendY: c_int = 131072;
pub const ImGuiTableFlags_NoKeepColumnsVisible: c_int = 262144;
pub const ImGuiTableFlags_PreciseWidths: c_int = 524288;
pub const ImGuiTableFlags_NoClip: c_int = 1048576;
pub const ImGuiTableFlags_PadOuterX: c_int = 2097152;
pub const ImGuiTableFlags_NoPadOuterX: c_int = 4194304;
pub const ImGuiTableFlags_NoPadInnerX: c_int = 8388608;
pub const ImGuiTableFlags_ScrollX: c_int = 16777216;
pub const ImGuiTableFlags_ScrollY: c_int = 33554432;
pub const ImGuiTableFlags_SortMulti: c_int = 67108864;
pub const ImGuiTableFlags_SortTristate: c_int = 134217728;
pub const ImGuiTableFlags_SizingMask_: c_int = 57344;
pub const ImGuiTableFlags_ = c_uint;
pub const ImGuiTableColumnFlags_None: c_int = 0;
pub const ImGuiTableColumnFlags_Disabled: c_int = 1;
pub const ImGuiTableColumnFlags_DefaultHide: c_int = 2;
pub const ImGuiTableColumnFlags_DefaultSort: c_int = 4;
pub const ImGuiTableColumnFlags_WidthStretch: c_int = 8;
pub const ImGuiTableColumnFlags_WidthFixed: c_int = 16;
pub const ImGuiTableColumnFlags_NoResize: c_int = 32;
pub const ImGuiTableColumnFlags_NoReorder: c_int = 64;
pub const ImGuiTableColumnFlags_NoHide: c_int = 128;
pub const ImGuiTableColumnFlags_NoClip: c_int = 256;
pub const ImGuiTableColumnFlags_NoSort: c_int = 512;
pub const ImGuiTableColumnFlags_NoSortAscending: c_int = 1024;
pub const ImGuiTableColumnFlags_NoSortDescending: c_int = 2048;
pub const ImGuiTableColumnFlags_NoHeaderLabel: c_int = 4096;
pub const ImGuiTableColumnFlags_NoHeaderWidth: c_int = 8192;
pub const ImGuiTableColumnFlags_PreferSortAscending: c_int = 16384;
pub const ImGuiTableColumnFlags_PreferSortDescending: c_int = 32768;
pub const ImGuiTableColumnFlags_IndentEnable: c_int = 65536;
pub const ImGuiTableColumnFlags_IndentDisable: c_int = 131072;
pub const ImGuiTableColumnFlags_IsEnabled: c_int = 16777216;
pub const ImGuiTableColumnFlags_IsVisible: c_int = 33554432;
pub const ImGuiTableColumnFlags_IsSorted: c_int = 67108864;
pub const ImGuiTableColumnFlags_IsHovered: c_int = 134217728;
pub const ImGuiTableColumnFlags_WidthMask_: c_int = 24;
pub const ImGuiTableColumnFlags_IndentMask_: c_int = 196608;
pub const ImGuiTableColumnFlags_StatusMask_: c_int = 251658240;
pub const ImGuiTableColumnFlags_NoDirectResize_: c_int = 1073741824;
pub const ImGuiTableColumnFlags_ = c_uint;
pub const ImGuiTableRowFlags_None: c_int = 0;
pub const ImGuiTableRowFlags_Headers: c_int = 1;
pub const ImGuiTableRowFlags_ = c_uint;
pub const ImGuiTableBgTarget_None: c_int = 0;
pub const ImGuiTableBgTarget_RowBg0: c_int = 1;
pub const ImGuiTableBgTarget_RowBg1: c_int = 2;
pub const ImGuiTableBgTarget_CellBg: c_int = 3;
pub const ImGuiTableBgTarget_ = c_uint;
pub const ImGuiFocusedFlags_None: c_int = 0;
pub const ImGuiFocusedFlags_ChildWindows: c_int = 1;
pub const ImGuiFocusedFlags_RootWindow: c_int = 2;
pub const ImGuiFocusedFlags_AnyWindow: c_int = 4;
pub const ImGuiFocusedFlags_NoPopupHierarchy: c_int = 8;
pub const ImGuiFocusedFlags_DockHierarchy: c_int = 16;
pub const ImGuiFocusedFlags_RootAndChildWindows: c_int = 3;
pub const ImGuiFocusedFlags_ = c_uint;
pub const ImGuiHoveredFlags_None: c_int = 0;
pub const ImGuiHoveredFlags_ChildWindows: c_int = 1;
pub const ImGuiHoveredFlags_RootWindow: c_int = 2;
pub const ImGuiHoveredFlags_AnyWindow: c_int = 4;
pub const ImGuiHoveredFlags_NoPopupHierarchy: c_int = 8;
pub const ImGuiHoveredFlags_DockHierarchy: c_int = 16;
pub const ImGuiHoveredFlags_AllowWhenBlockedByPopup: c_int = 32;
pub const ImGuiHoveredFlags_AllowWhenBlockedByActiveItem: c_int = 128;
pub const ImGuiHoveredFlags_AllowWhenOverlapped: c_int = 256;
pub const ImGuiHoveredFlags_AllowWhenDisabled: c_int = 512;
pub const ImGuiHoveredFlags_NoNavOverride: c_int = 1024;
pub const ImGuiHoveredFlags_RectOnly: c_int = 416;
pub const ImGuiHoveredFlags_RootAndChildWindows: c_int = 3;
pub const ImGuiHoveredFlags_ = c_uint;
pub const ImGuiDockNodeFlags_None: c_int = 0;
pub const ImGuiDockNodeFlags_KeepAliveOnly: c_int = 1;
pub const ImGuiDockNodeFlags_NoDockingInCentralNode: c_int = 4;
pub const ImGuiDockNodeFlags_PassthruCentralNode: c_int = 8;
pub const ImGuiDockNodeFlags_NoSplit: c_int = 16;
pub const ImGuiDockNodeFlags_NoResize: c_int = 32;
pub const ImGuiDockNodeFlags_AutoHideTabBar: c_int = 64;
pub const ImGuiDockNodeFlags_ = c_uint;
pub const ImGuiDragDropFlags_None: c_int = 0;
pub const ImGuiDragDropFlags_SourceNoPreviewTooltip: c_int = 1;
pub const ImGuiDragDropFlags_SourceNoDisableHover: c_int = 2;
pub const ImGuiDragDropFlags_SourceNoHoldToOpenOthers: c_int = 4;
pub const ImGuiDragDropFlags_SourceAllowNullID: c_int = 8;
pub const ImGuiDragDropFlags_SourceExtern: c_int = 16;
pub const ImGuiDragDropFlags_SourceAutoExpirePayload: c_int = 32;
pub const ImGuiDragDropFlags_AcceptBeforeDelivery: c_int = 1024;
pub const ImGuiDragDropFlags_AcceptNoDrawDefaultRect: c_int = 2048;
pub const ImGuiDragDropFlags_AcceptNoPreviewTooltip: c_int = 4096;
pub const ImGuiDragDropFlags_AcceptPeekOnly: c_int = 3072;
pub const ImGuiDragDropFlags_ = c_uint;
pub const ImGuiDataType_S8: c_int = 0;
pub const ImGuiDataType_U8: c_int = 1;
pub const ImGuiDataType_S16: c_int = 2;
pub const ImGuiDataType_U16: c_int = 3;
pub const ImGuiDataType_S32: c_int = 4;
pub const ImGuiDataType_U32: c_int = 5;
pub const ImGuiDataType_S64: c_int = 6;
pub const ImGuiDataType_U64: c_int = 7;
pub const ImGuiDataType_Float: c_int = 8;
pub const ImGuiDataType_Double: c_int = 9;
pub const ImGuiDataType_COUNT: c_int = 10;
pub const ImGuiDataType_ = c_uint;
pub const ImGuiDir_None: c_int = -1;
pub const ImGuiDir_Left: c_int = 0;
pub const ImGuiDir_Right: c_int = 1;
pub const ImGuiDir_Up: c_int = 2;
pub const ImGuiDir_Down: c_int = 3;
pub const ImGuiDir_COUNT: c_int = 4;
pub const ImGuiDir_ = c_int;
pub const ImGuiSortDirection_None: c_int = 0;
pub const ImGuiSortDirection_Ascending: c_int = 1;
pub const ImGuiSortDirection_Descending: c_int = 2;
pub const ImGuiSortDirection_ = c_uint;
pub const ImGuiKey_None: c_int = 0;
pub const ImGuiKey_Tab: c_int = 512;
pub const ImGuiKey_LeftArrow: c_int = 513;
pub const ImGuiKey_RightArrow: c_int = 514;
pub const ImGuiKey_UpArrow: c_int = 515;
pub const ImGuiKey_DownArrow: c_int = 516;
pub const ImGuiKey_PageUp: c_int = 517;
pub const ImGuiKey_PageDown: c_int = 518;
pub const ImGuiKey_Home: c_int = 519;
pub const ImGuiKey_End: c_int = 520;
pub const ImGuiKey_Insert: c_int = 521;
pub const ImGuiKey_Delete: c_int = 522;
pub const ImGuiKey_Backspace: c_int = 523;
pub const ImGuiKey_Space: c_int = 524;
pub const ImGuiKey_Enter: c_int = 525;
pub const ImGuiKey_Escape: c_int = 526;
pub const ImGuiKey_LeftCtrl: c_int = 527;
pub const ImGuiKey_LeftShift: c_int = 528;
pub const ImGuiKey_LeftAlt: c_int = 529;
pub const ImGuiKey_LeftSuper: c_int = 530;
pub const ImGuiKey_RightCtrl: c_int = 531;
pub const ImGuiKey_RightShift: c_int = 532;
pub const ImGuiKey_RightAlt: c_int = 533;
pub const ImGuiKey_RightSuper: c_int = 534;
pub const ImGuiKey_Menu: c_int = 535;
pub const ImGuiKey_0: c_int = 536;
pub const ImGuiKey_1: c_int = 537;
pub const ImGuiKey_2: c_int = 538;
pub const ImGuiKey_3: c_int = 539;
pub const ImGuiKey_4: c_int = 540;
pub const ImGuiKey_5: c_int = 541;
pub const ImGuiKey_6: c_int = 542;
pub const ImGuiKey_7: c_int = 543;
pub const ImGuiKey_8: c_int = 544;
pub const ImGuiKey_9: c_int = 545;
pub const ImGuiKey_A: c_int = 546;
pub const ImGuiKey_B: c_int = 547;
pub const ImGuiKey_C: c_int = 548;
pub const ImGuiKey_D: c_int = 549;
pub const ImGuiKey_E: c_int = 550;
pub const ImGuiKey_F: c_int = 551;
pub const ImGuiKey_G: c_int = 552;
pub const ImGuiKey_H: c_int = 553;
pub const ImGuiKey_I: c_int = 554;
pub const ImGuiKey_J: c_int = 555;
pub const ImGuiKey_K: c_int = 556;
pub const ImGuiKey_L: c_int = 557;
pub const ImGuiKey_M: c_int = 558;
pub const ImGuiKey_N: c_int = 559;
pub const ImGuiKey_O: c_int = 560;
pub const ImGuiKey_P: c_int = 561;
pub const ImGuiKey_Q: c_int = 562;
pub const ImGuiKey_R: c_int = 563;
pub const ImGuiKey_S: c_int = 564;
pub const ImGuiKey_T: c_int = 565;
pub const ImGuiKey_U: c_int = 566;
pub const ImGuiKey_V: c_int = 567;
pub const ImGuiKey_W: c_int = 568;
pub const ImGuiKey_X: c_int = 569;
pub const ImGuiKey_Y: c_int = 570;
pub const ImGuiKey_Z: c_int = 571;
pub const ImGuiKey_F1: c_int = 572;
pub const ImGuiKey_F2: c_int = 573;
pub const ImGuiKey_F3: c_int = 574;
pub const ImGuiKey_F4: c_int = 575;
pub const ImGuiKey_F5: c_int = 576;
pub const ImGuiKey_F6: c_int = 577;
pub const ImGuiKey_F7: c_int = 578;
pub const ImGuiKey_F8: c_int = 579;
pub const ImGuiKey_F9: c_int = 580;
pub const ImGuiKey_F10: c_int = 581;
pub const ImGuiKey_F11: c_int = 582;
pub const ImGuiKey_F12: c_int = 583;
pub const ImGuiKey_Apostrophe: c_int = 584;
pub const ImGuiKey_Comma: c_int = 585;
pub const ImGuiKey_Minus: c_int = 586;
pub const ImGuiKey_Period: c_int = 587;
pub const ImGuiKey_Slash: c_int = 588;
pub const ImGuiKey_Semicolon: c_int = 589;
pub const ImGuiKey_Equal: c_int = 590;
pub const ImGuiKey_LeftBracket: c_int = 591;
pub const ImGuiKey_Backslash: c_int = 592;
pub const ImGuiKey_RightBracket: c_int = 593;
pub const ImGuiKey_GraveAccent: c_int = 594;
pub const ImGuiKey_CapsLock: c_int = 595;
pub const ImGuiKey_ScrollLock: c_int = 596;
pub const ImGuiKey_NumLock: c_int = 597;
pub const ImGuiKey_PrintScreen: c_int = 598;
pub const ImGuiKey_Pause: c_int = 599;
pub const ImGuiKey_Keypad0: c_int = 600;
pub const ImGuiKey_Keypad1: c_int = 601;
pub const ImGuiKey_Keypad2: c_int = 602;
pub const ImGuiKey_Keypad3: c_int = 603;
pub const ImGuiKey_Keypad4: c_int = 604;
pub const ImGuiKey_Keypad5: c_int = 605;
pub const ImGuiKey_Keypad6: c_int = 606;
pub const ImGuiKey_Keypad7: c_int = 607;
pub const ImGuiKey_Keypad8: c_int = 608;
pub const ImGuiKey_Keypad9: c_int = 609;
pub const ImGuiKey_KeypadDecimal: c_int = 610;
pub const ImGuiKey_KeypadDivide: c_int = 611;
pub const ImGuiKey_KeypadMultiply: c_int = 612;
pub const ImGuiKey_KeypadSubtract: c_int = 613;
pub const ImGuiKey_KeypadAdd: c_int = 614;
pub const ImGuiKey_KeypadEnter: c_int = 615;
pub const ImGuiKey_KeypadEqual: c_int = 616;
pub const ImGuiKey_GamepadStart: c_int = 617;
pub const ImGuiKey_GamepadBack: c_int = 618;
pub const ImGuiKey_GamepadFaceUp: c_int = 619;
pub const ImGuiKey_GamepadFaceDown: c_int = 620;
pub const ImGuiKey_GamepadFaceLeft: c_int = 621;
pub const ImGuiKey_GamepadFaceRight: c_int = 622;
pub const ImGuiKey_GamepadDpadUp: c_int = 623;
pub const ImGuiKey_GamepadDpadDown: c_int = 624;
pub const ImGuiKey_GamepadDpadLeft: c_int = 625;
pub const ImGuiKey_GamepadDpadRight: c_int = 626;
pub const ImGuiKey_GamepadL1: c_int = 627;
pub const ImGuiKey_GamepadR1: c_int = 628;
pub const ImGuiKey_GamepadL2: c_int = 629;
pub const ImGuiKey_GamepadR2: c_int = 630;
pub const ImGuiKey_GamepadL3: c_int = 631;
pub const ImGuiKey_GamepadR3: c_int = 632;
pub const ImGuiKey_GamepadLStickUp: c_int = 633;
pub const ImGuiKey_GamepadLStickDown: c_int = 634;
pub const ImGuiKey_GamepadLStickLeft: c_int = 635;
pub const ImGuiKey_GamepadLStickRight: c_int = 636;
pub const ImGuiKey_GamepadRStickUp: c_int = 637;
pub const ImGuiKey_GamepadRStickDown: c_int = 638;
pub const ImGuiKey_GamepadRStickLeft: c_int = 639;
pub const ImGuiKey_GamepadRStickRight: c_int = 640;
pub const ImGuiKey_ModCtrl: c_int = 641;
pub const ImGuiKey_ModShift: c_int = 642;
pub const ImGuiKey_ModAlt: c_int = 643;
pub const ImGuiKey_ModSuper: c_int = 644;
pub const ImGuiKey_COUNT: c_int = 645;
pub const ImGuiKey_NamedKey_BEGIN: c_int = 512;
pub const ImGuiKey_NamedKey_END: c_int = 645;
pub const ImGuiKey_NamedKey_COUNT: c_int = 133;
pub const ImGuiKey_KeysData_SIZE: c_int = 645;
pub const ImGuiKey_KeysData_OFFSET: c_int = 0;
pub const ImGuiKey_ = c_uint;
pub const ImGuiModFlags_None: c_int = 0;
pub const ImGuiModFlags_Ctrl: c_int = 1;
pub const ImGuiModFlags_Shift: c_int = 2;
pub const ImGuiModFlags_Alt: c_int = 4;
pub const ImGuiModFlags_Super: c_int = 8;
pub const ImGuiModFlags_ = c_uint;
pub const ImGuiNavInput_Activate: c_int = 0;
pub const ImGuiNavInput_Cancel: c_int = 1;
pub const ImGuiNavInput_Input: c_int = 2;
pub const ImGuiNavInput_Menu: c_int = 3;
pub const ImGuiNavInput_DpadLeft: c_int = 4;
pub const ImGuiNavInput_DpadRight: c_int = 5;
pub const ImGuiNavInput_DpadUp: c_int = 6;
pub const ImGuiNavInput_DpadDown: c_int = 7;
pub const ImGuiNavInput_LStickLeft: c_int = 8;
pub const ImGuiNavInput_LStickRight: c_int = 9;
pub const ImGuiNavInput_LStickUp: c_int = 10;
pub const ImGuiNavInput_LStickDown: c_int = 11;
pub const ImGuiNavInput_FocusPrev: c_int = 12;
pub const ImGuiNavInput_FocusNext: c_int = 13;
pub const ImGuiNavInput_TweakSlow: c_int = 14;
pub const ImGuiNavInput_TweakFast: c_int = 15;
pub const ImGuiNavInput_KeyLeft_: c_int = 16;
pub const ImGuiNavInput_KeyRight_: c_int = 17;
pub const ImGuiNavInput_KeyUp_: c_int = 18;
pub const ImGuiNavInput_KeyDown_: c_int = 19;
pub const ImGuiNavInput_COUNT: c_int = 20;
pub const ImGuiNavInput_ = c_uint;
pub const ImGuiConfigFlags_None: c_int = 0;
pub const ImGuiConfigFlags_NavEnableKeyboard: c_int = 1;
pub const ImGuiConfigFlags_NavEnableGamepad: c_int = 2;
pub const ImGuiConfigFlags_NavEnableSetMousePos: c_int = 4;
pub const ImGuiConfigFlags_NavNoCaptureKeyboard: c_int = 8;
pub const ImGuiConfigFlags_NoMouse: c_int = 16;
pub const ImGuiConfigFlags_NoMouseCursorChange: c_int = 32;
pub const ImGuiConfigFlags_DockingEnable: c_int = 64;
pub const ImGuiConfigFlags_ViewportsEnable: c_int = 1024;
pub const ImGuiConfigFlags_DpiEnableScaleViewports: c_int = 16384;
pub const ImGuiConfigFlags_DpiEnableScaleFonts: c_int = 32768;
pub const ImGuiConfigFlags_IsSRGB: c_int = 1048576;
pub const ImGuiConfigFlags_IsTouchScreen: c_int = 2097152;
pub const ImGuiConfigFlags_ = c_uint;
pub const ImGuiBackendFlags_None: c_int = 0;
pub const ImGuiBackendFlags_HasGamepad: c_int = 1;
pub const ImGuiBackendFlags_HasMouseCursors: c_int = 2;
pub const ImGuiBackendFlags_HasSetMousePos: c_int = 4;
pub const ImGuiBackendFlags_RendererHasVtxOffset: c_int = 8;
pub const ImGuiBackendFlags_PlatformHasViewports: c_int = 1024;
pub const ImGuiBackendFlags_HasMouseHoveredViewport: c_int = 2048;
pub const ImGuiBackendFlags_RendererHasViewports: c_int = 4096;
pub const ImGuiBackendFlags_ = c_uint;
pub const ImGuiCol_Text: c_int = 0;
pub const ImGuiCol_TextDisabled: c_int = 1;
pub const ImGuiCol_WindowBg: c_int = 2;
pub const ImGuiCol_ChildBg: c_int = 3;
pub const ImGuiCol_PopupBg: c_int = 4;
pub const ImGuiCol_Border: c_int = 5;
pub const ImGuiCol_BorderShadow: c_int = 6;
pub const ImGuiCol_FrameBg: c_int = 7;
pub const ImGuiCol_FrameBgHovered: c_int = 8;
pub const ImGuiCol_FrameBgActive: c_int = 9;
pub const ImGuiCol_TitleBg: c_int = 10;
pub const ImGuiCol_TitleBgActive: c_int = 11;
pub const ImGuiCol_TitleBgCollapsed: c_int = 12;
pub const ImGuiCol_MenuBarBg: c_int = 13;
pub const ImGuiCol_ScrollbarBg: c_int = 14;
pub const ImGuiCol_ScrollbarGrab: c_int = 15;
pub const ImGuiCol_ScrollbarGrabHovered: c_int = 16;
pub const ImGuiCol_ScrollbarGrabActive: c_int = 17;
pub const ImGuiCol_CheckMark: c_int = 18;
pub const ImGuiCol_SliderGrab: c_int = 19;
pub const ImGuiCol_SliderGrabActive: c_int = 20;
pub const ImGuiCol_Button: c_int = 21;
pub const ImGuiCol_ButtonHovered: c_int = 22;
pub const ImGuiCol_ButtonActive: c_int = 23;
pub const ImGuiCol_Header: c_int = 24;
pub const ImGuiCol_HeaderHovered: c_int = 25;
pub const ImGuiCol_HeaderActive: c_int = 26;
pub const ImGuiCol_Separator: c_int = 27;
pub const ImGuiCol_SeparatorHovered: c_int = 28;
pub const ImGuiCol_SeparatorActive: c_int = 29;
pub const ImGuiCol_ResizeGrip: c_int = 30;
pub const ImGuiCol_ResizeGripHovered: c_int = 31;
pub const ImGuiCol_ResizeGripActive: c_int = 32;
pub const ImGuiCol_Tab: c_int = 33;
pub const ImGuiCol_TabHovered: c_int = 34;
pub const ImGuiCol_TabActive: c_int = 35;
pub const ImGuiCol_TabUnfocused: c_int = 36;
pub const ImGuiCol_TabUnfocusedActive: c_int = 37;
pub const ImGuiCol_DockingPreview: c_int = 38;
pub const ImGuiCol_DockingEmptyBg: c_int = 39;
pub const ImGuiCol_PlotLines: c_int = 40;
pub const ImGuiCol_PlotLinesHovered: c_int = 41;
pub const ImGuiCol_PlotHistogram: c_int = 42;
pub const ImGuiCol_PlotHistogramHovered: c_int = 43;
pub const ImGuiCol_TableHeaderBg: c_int = 44;
pub const ImGuiCol_TableBorderStrong: c_int = 45;
pub const ImGuiCol_TableBorderLight: c_int = 46;
pub const ImGuiCol_TableRowBg: c_int = 47;
pub const ImGuiCol_TableRowBgAlt: c_int = 48;
pub const ImGuiCol_TextSelectedBg: c_int = 49;
pub const ImGuiCol_DragDropTarget: c_int = 50;
pub const ImGuiCol_NavHighlight: c_int = 51;
pub const ImGuiCol_NavWindowingHighlight: c_int = 52;
pub const ImGuiCol_NavWindowingDimBg: c_int = 53;
pub const ImGuiCol_ModalWindowDimBg: c_int = 54;
pub const ImGuiCol_COUNT: c_int = 55;
pub const ImGuiCol_ = c_uint;
pub const ImGuiStyleVar_Alpha: c_int = 0;
pub const ImGuiStyleVar_DisabledAlpha: c_int = 1;
pub const ImGuiStyleVar_WindowPadding: c_int = 2;
pub const ImGuiStyleVar_WindowRounding: c_int = 3;
pub const ImGuiStyleVar_WindowBorderSize: c_int = 4;
pub const ImGuiStyleVar_WindowMinSize: c_int = 5;
pub const ImGuiStyleVar_WindowTitleAlign: c_int = 6;
pub const ImGuiStyleVar_ChildRounding: c_int = 7;
pub const ImGuiStyleVar_ChildBorderSize: c_int = 8;
pub const ImGuiStyleVar_PopupRounding: c_int = 9;
pub const ImGuiStyleVar_PopupBorderSize: c_int = 10;
pub const ImGuiStyleVar_FramePadding: c_int = 11;
pub const ImGuiStyleVar_FrameRounding: c_int = 12;
pub const ImGuiStyleVar_FrameBorderSize: c_int = 13;
pub const ImGuiStyleVar_ItemSpacing: c_int = 14;
pub const ImGuiStyleVar_ItemInnerSpacing: c_int = 15;
pub const ImGuiStyleVar_IndentSpacing: c_int = 16;
pub const ImGuiStyleVar_CellPadding: c_int = 17;
pub const ImGuiStyleVar_ScrollbarSize: c_int = 18;
pub const ImGuiStyleVar_ScrollbarRounding: c_int = 19;
pub const ImGuiStyleVar_GrabMinSize: c_int = 20;
pub const ImGuiStyleVar_GrabRounding: c_int = 21;
pub const ImGuiStyleVar_TabRounding: c_int = 22;
pub const ImGuiStyleVar_ButtonTextAlign: c_int = 23;
pub const ImGuiStyleVar_SelectableTextAlign: c_int = 24;
pub const ImGuiStyleVar_COUNT: c_int = 25;
pub const ImGuiStyleVar_ = c_uint;
pub const ImGuiButtonFlags_None: c_int = 0;
pub const ImGuiButtonFlags_MouseButtonLeft: c_int = 1;
pub const ImGuiButtonFlags_MouseButtonRight: c_int = 2;
pub const ImGuiButtonFlags_MouseButtonMiddle: c_int = 4;
pub const ImGuiButtonFlags_MouseButtonMask_: c_int = 7;
pub const ImGuiButtonFlags_MouseButtonDefault_: c_int = 1;
pub const ImGuiButtonFlags_ = c_uint;
pub const ImGuiColorEditFlags_None: c_int = 0;
pub const ImGuiColorEditFlags_NoAlpha: c_int = 2;
pub const ImGuiColorEditFlags_NoPicker: c_int = 4;
pub const ImGuiColorEditFlags_NoOptions: c_int = 8;
pub const ImGuiColorEditFlags_NoSmallPreview: c_int = 16;
pub const ImGuiColorEditFlags_NoInputs: c_int = 32;
pub const ImGuiColorEditFlags_NoTooltip: c_int = 64;
pub const ImGuiColorEditFlags_NoLabel: c_int = 128;
pub const ImGuiColorEditFlags_NoSidePreview: c_int = 256;
pub const ImGuiColorEditFlags_NoDragDrop: c_int = 512;
pub const ImGuiColorEditFlags_NoBorder: c_int = 1024;
pub const ImGuiColorEditFlags_AlphaBar: c_int = 65536;
pub const ImGuiColorEditFlags_AlphaPreview: c_int = 131072;
pub const ImGuiColorEditFlags_AlphaPreviewHalf: c_int = 262144;
pub const ImGuiColorEditFlags_HDR: c_int = 524288;
pub const ImGuiColorEditFlags_DisplayRGB: c_int = 1048576;
pub const ImGuiColorEditFlags_DisplayHSV: c_int = 2097152;
pub const ImGuiColorEditFlags_DisplayHex: c_int = 4194304;
pub const ImGuiColorEditFlags_Uint8: c_int = 8388608;
pub const ImGuiColorEditFlags_Float: c_int = 16777216;
pub const ImGuiColorEditFlags_PickerHueBar: c_int = 33554432;
pub const ImGuiColorEditFlags_PickerHueWheel: c_int = 67108864;
pub const ImGuiColorEditFlags_InputRGB: c_int = 134217728;
pub const ImGuiColorEditFlags_InputHSV: c_int = 268435456;
pub const ImGuiColorEditFlags_DefaultOptions_: c_int = 177209344;
pub const ImGuiColorEditFlags_DisplayMask_: c_int = 7340032;
pub const ImGuiColorEditFlags_DataTypeMask_: c_int = 25165824;
pub const ImGuiColorEditFlags_PickerMask_: c_int = 100663296;
pub const ImGuiColorEditFlags_InputMask_: c_int = 402653184;
pub const ImGuiColorEditFlags_ = c_uint;
pub const ImGuiSliderFlags_None: c_int = 0;
pub const ImGuiSliderFlags_AlwaysClamp: c_int = 16;
pub const ImGuiSliderFlags_Logarithmic: c_int = 32;
pub const ImGuiSliderFlags_NoRoundToFormat: c_int = 64;
pub const ImGuiSliderFlags_NoInput: c_int = 128;
pub const ImGuiSliderFlags_InvalidMask_: c_int = 1879048207;
pub const ImGuiSliderFlags_ = c_uint;
pub const ImGuiMouseButton_Left: c_int = 0;
pub const ImGuiMouseButton_Right: c_int = 1;
pub const ImGuiMouseButton_Middle: c_int = 2;
pub const ImGuiMouseButton_COUNT: c_int = 5;
pub const ImGuiMouseButton_ = c_uint;
pub const ImGuiMouseCursor_None: c_int = -1;
pub const ImGuiMouseCursor_Arrow: c_int = 0;
pub const ImGuiMouseCursor_TextInput: c_int = 1;
pub const ImGuiMouseCursor_ResizeAll: c_int = 2;
pub const ImGuiMouseCursor_ResizeNS: c_int = 3;
pub const ImGuiMouseCursor_ResizeEW: c_int = 4;
pub const ImGuiMouseCursor_ResizeNESW: c_int = 5;
pub const ImGuiMouseCursor_ResizeNWSE: c_int = 6;
pub const ImGuiMouseCursor_Hand: c_int = 7;
pub const ImGuiMouseCursor_NotAllowed: c_int = 8;
pub const ImGuiMouseCursor_COUNT: c_int = 9;
pub const ImGuiMouseCursor_ = c_int;
pub const ImGuiCond_None: c_int = 0;
pub const ImGuiCond_Always: c_int = 1;
pub const ImGuiCond_Once: c_int = 2;
pub const ImGuiCond_FirstUseEver: c_int = 4;
pub const ImGuiCond_Appearing: c_int = 8;
pub const ImGuiCond_ = c_uint;
pub const ImDrawFlags_None: c_int = 0;
pub const ImDrawFlags_Closed: c_int = 1;
pub const ImDrawFlags_RoundCornersTopLeft: c_int = 16;
pub const ImDrawFlags_RoundCornersTopRight: c_int = 32;
pub const ImDrawFlags_RoundCornersBottomLeft: c_int = 64;
pub const ImDrawFlags_RoundCornersBottomRight: c_int = 128;
pub const ImDrawFlags_RoundCornersNone: c_int = 256;
pub const ImDrawFlags_RoundCornersTop: c_int = 48;
pub const ImDrawFlags_RoundCornersBottom: c_int = 192;
pub const ImDrawFlags_RoundCornersLeft: c_int = 80;
pub const ImDrawFlags_RoundCornersRight: c_int = 160;
pub const ImDrawFlags_RoundCornersAll: c_int = 240;
pub const ImDrawFlags_RoundCornersDefault_: c_int = 240;
pub const ImDrawFlags_RoundCornersMask_: c_int = 496;
pub const ImDrawFlags_ = c_uint;
pub const ImDrawListFlags_None: c_int = 0;
pub const ImDrawListFlags_AntiAliasedLines: c_int = 1;
pub const ImDrawListFlags_AntiAliasedLinesUseTex: c_int = 2;
pub const ImDrawListFlags_AntiAliasedFill: c_int = 4;
pub const ImDrawListFlags_AllowVtxOffset: c_int = 8;
pub const ImDrawListFlags_ = c_uint;
pub const ImFontAtlasFlags_None: c_int = 0;
pub const ImFontAtlasFlags_NoPowerOfTwoHeight: c_int = 1;
pub const ImFontAtlasFlags_NoMouseCursors: c_int = 2;
pub const ImFontAtlasFlags_NoBakedLines: c_int = 4;
pub const ImFontAtlasFlags_ = c_uint;
pub const ImGuiViewportFlags_None: c_int = 0;
pub const ImGuiViewportFlags_IsPlatformWindow: c_int = 1;
pub const ImGuiViewportFlags_IsPlatformMonitor: c_int = 2;
pub const ImGuiViewportFlags_OwnedByApp: c_int = 4;
pub const ImGuiViewportFlags_NoDecoration: c_int = 8;
pub const ImGuiViewportFlags_NoTaskBarIcon: c_int = 16;
pub const ImGuiViewportFlags_NoFocusOnAppearing: c_int = 32;
pub const ImGuiViewportFlags_NoFocusOnClick: c_int = 64;
pub const ImGuiViewportFlags_NoInputs: c_int = 128;
pub const ImGuiViewportFlags_NoRendererClear: c_int = 256;
pub const ImGuiViewportFlags_TopMost: c_int = 512;
pub const ImGuiViewportFlags_Minimized: c_int = 1024;
pub const ImGuiViewportFlags_NoAutoMerge: c_int = 2048;
pub const ImGuiViewportFlags_CanHostOtherWindows: c_int = 4096;
pub const ImGuiViewportFlags_ = c_uint;
pub const ImGuiDataAuthority = c_int;
pub const ImGuiNavHighlightFlags = c_int;
pub const ImGuiNavDirSourceFlags = c_int;
pub const ImGuiSeparatorFlags = c_int;
pub const ImGuiTextFlags = c_int;
pub const ImGuiTooltipFlags = c_int;
pub const ImGuiErrorLogCallback = ?*const fn (?*anyopaque, [*c]const u8, ...) callconv(.C) void;
pub extern var GImGui: [*c]ImGuiContext;
pub const struct_StbTexteditRow = extern struct {
    x0: f32 = @import("std").mem.zeroes(f32),
    x1: f32 = @import("std").mem.zeroes(f32),
    baseline_y_delta: f32 = @import("std").mem.zeroes(f32),
    ymin: f32 = @import("std").mem.zeroes(f32),
    ymax: f32 = @import("std").mem.zeroes(f32),
    num_chars: c_int = @import("std").mem.zeroes(c_int),
};
pub const StbTexteditRow = struct_StbTexteditRow;
pub const ImGuiItemFlags_None: c_int = 0;
pub const ImGuiItemFlags_NoTabStop: c_int = 1;
pub const ImGuiItemFlags_ButtonRepeat: c_int = 2;
pub const ImGuiItemFlags_Disabled: c_int = 4;
pub const ImGuiItemFlags_NoNav: c_int = 8;
pub const ImGuiItemFlags_NoNavDefaultFocus: c_int = 16;
pub const ImGuiItemFlags_SelectableDontClosePopup: c_int = 32;
pub const ImGuiItemFlags_MixedValue: c_int = 64;
pub const ImGuiItemFlags_ReadOnly: c_int = 128;
pub const ImGuiItemFlags_Inputable: c_int = 256;
pub const ImGuiItemFlags_ = c_uint;
pub const ImGuiItemStatusFlags_None: c_int = 0;
pub const ImGuiItemStatusFlags_HoveredRect: c_int = 1;
pub const ImGuiItemStatusFlags_HasDisplayRect: c_int = 2;
pub const ImGuiItemStatusFlags_Edited: c_int = 4;
pub const ImGuiItemStatusFlags_ToggledSelection: c_int = 8;
pub const ImGuiItemStatusFlags_ToggledOpen: c_int = 16;
pub const ImGuiItemStatusFlags_HasDeactivated: c_int = 32;
pub const ImGuiItemStatusFlags_Deactivated: c_int = 64;
pub const ImGuiItemStatusFlags_HoveredWindow: c_int = 128;
pub const ImGuiItemStatusFlags_FocusedByTabbing: c_int = 256;
pub const ImGuiItemStatusFlags_ = c_uint;
pub const ImGuiInputTextFlags_Multiline: c_int = 67108864;
pub const ImGuiInputTextFlags_NoMarkEdited: c_int = 134217728;
pub const ImGuiInputTextFlags_MergedItem: c_int = 268435456;
pub const ImGuiInputTextFlagsPrivate_ = c_uint;
pub const ImGuiButtonFlags_PressedOnClick: c_int = 16;
pub const ImGuiButtonFlags_PressedOnClickRelease: c_int = 32;
pub const ImGuiButtonFlags_PressedOnClickReleaseAnywhere: c_int = 64;
pub const ImGuiButtonFlags_PressedOnRelease: c_int = 128;
pub const ImGuiButtonFlags_PressedOnDoubleClick: c_int = 256;
pub const ImGuiButtonFlags_PressedOnDragDropHold: c_int = 512;
pub const ImGuiButtonFlags_Repeat: c_int = 1024;
pub const ImGuiButtonFlags_FlattenChildren: c_int = 2048;
pub const ImGuiButtonFlags_AllowItemOverlap: c_int = 4096;
pub const ImGuiButtonFlags_DontClosePopups: c_int = 8192;
pub const ImGuiButtonFlags_AlignTextBaseLine: c_int = 32768;
pub const ImGuiButtonFlags_NoKeyModifiers: c_int = 65536;
pub const ImGuiButtonFlags_NoHoldingActiveId: c_int = 131072;
pub const ImGuiButtonFlags_NoNavFocus: c_int = 262144;
pub const ImGuiButtonFlags_NoHoveredOnFocus: c_int = 524288;
pub const ImGuiButtonFlags_PressedOnMask_: c_int = 1008;
pub const ImGuiButtonFlags_PressedOnDefault_: c_int = 32;
pub const ImGuiButtonFlagsPrivate_ = c_uint;
pub const ImGuiComboFlags_CustomPreview: c_int = 1048576;
pub const ImGuiComboFlagsPrivate_ = c_uint;
pub const ImGuiSliderFlags_Vertical: c_int = 1048576;
pub const ImGuiSliderFlags_ReadOnly: c_int = 2097152;
pub const ImGuiSliderFlagsPrivate_ = c_uint;
pub const ImGuiSelectableFlags_NoHoldingActiveID: c_int = 1048576;
pub const ImGuiSelectableFlags_SelectOnNav: c_int = 2097152;
pub const ImGuiSelectableFlags_SelectOnClick: c_int = 4194304;
pub const ImGuiSelectableFlags_SelectOnRelease: c_int = 8388608;
pub const ImGuiSelectableFlags_SpanAvailWidth: c_int = 16777216;
pub const ImGuiSelectableFlags_DrawHoveredWhenHeld: c_int = 33554432;
pub const ImGuiSelectableFlags_SetNavIdOnHover: c_int = 67108864;
pub const ImGuiSelectableFlags_NoPadWithHalfSpacing: c_int = 134217728;
pub const ImGuiSelectableFlagsPrivate_ = c_uint;
pub const ImGuiTreeNodeFlags_ClipLabelForTrailingButton: c_int = 1048576;
pub const ImGuiTreeNodeFlagsPrivate_ = c_uint;
pub const ImGuiSeparatorFlags_None: c_int = 0;
pub const ImGuiSeparatorFlags_Horizontal: c_int = 1;
pub const ImGuiSeparatorFlags_Vertical: c_int = 2;
pub const ImGuiSeparatorFlags_SpanAllColumns: c_int = 4;
pub const ImGuiSeparatorFlags_ = c_uint;
pub const ImGuiTextFlags_None: c_int = 0;
pub const ImGuiTextFlags_NoWidthForLargeClippedText: c_int = 1;
pub const ImGuiTextFlags_ = c_uint;
pub const ImGuiTooltipFlags_None: c_int = 0;
pub const ImGuiTooltipFlags_OverridePreviousTooltip: c_int = 1;
pub const ImGuiTooltipFlags_ = c_uint;
pub const ImGuiLayoutType_Horizontal: c_int = 0;
pub const ImGuiLayoutType_Vertical: c_int = 1;
pub const ImGuiLayoutType_ = c_uint;
pub const ImGuiLogType_None: c_int = 0;
pub const ImGuiLogType_TTY: c_int = 1;
pub const ImGuiLogType_File: c_int = 2;
pub const ImGuiLogType_Buffer: c_int = 3;
pub const ImGuiLogType_Clipboard: c_int = 4;
pub const ImGuiLogType = c_uint;
pub const ImGuiAxis_None: c_int = -1;
pub const ImGuiAxis_X: c_int = 0;
pub const ImGuiAxis_Y: c_int = 1;
pub const ImGuiAxis = c_int;
pub const ImGuiPlotType_Lines: c_int = 0;
pub const ImGuiPlotType_Histogram: c_int = 1;
pub const ImGuiPlotType = c_uint;
pub const ImGuiPopupPositionPolicy_Default: c_int = 0;
pub const ImGuiPopupPositionPolicy_ComboBox: c_int = 1;
pub const ImGuiPopupPositionPolicy_Tooltip: c_int = 2;
pub const ImGuiPopupPositionPolicy = c_uint;
pub const struct_ImGuiDataTypeTempStorage = extern struct {
    Data: [8]ImU8 = @import("std").mem.zeroes([8]ImU8),
};
pub const ImGuiDataTypeTempStorage = struct_ImGuiDataTypeTempStorage;
pub const ImGuiDataType_String: c_int = 11;
pub const ImGuiDataType_Pointer: c_int = 12;
pub const ImGuiDataType_ID: c_int = 13;
pub const ImGuiDataTypePrivate_ = c_uint;
pub const ImGuiNextWindowDataFlags_None: c_int = 0;
pub const ImGuiNextWindowDataFlags_HasPos: c_int = 1;
pub const ImGuiNextWindowDataFlags_HasSize: c_int = 2;
pub const ImGuiNextWindowDataFlags_HasContentSize: c_int = 4;
pub const ImGuiNextWindowDataFlags_HasCollapsed: c_int = 8;
pub const ImGuiNextWindowDataFlags_HasSizeConstraint: c_int = 16;
pub const ImGuiNextWindowDataFlags_HasFocus: c_int = 32;
pub const ImGuiNextWindowDataFlags_HasBgAlpha: c_int = 64;
pub const ImGuiNextWindowDataFlags_HasScroll: c_int = 128;
pub const ImGuiNextWindowDataFlags_HasViewport: c_int = 256;
pub const ImGuiNextWindowDataFlags_HasDock: c_int = 512;
pub const ImGuiNextWindowDataFlags_HasWindowClass: c_int = 1024;
pub const ImGuiNextWindowDataFlags_ = c_uint;
pub const ImGuiNextItemDataFlags_None: c_int = 0;
pub const ImGuiNextItemDataFlags_HasWidth: c_int = 1;
pub const ImGuiNextItemDataFlags_HasOpen: c_int = 2;
pub const ImGuiNextItemDataFlags_ = c_uint;
pub const ImGuiKey_LegacyNativeKey_BEGIN: c_int = 0;
pub const ImGuiKey_LegacyNativeKey_END: c_int = 512;
pub const ImGuiKey_Gamepad_BEGIN: c_int = 617;
pub const ImGuiKey_Gamepad_END: c_int = 641;
pub const ImGuiKeyPrivate_ = c_uint;
pub const ImGuiInputEventType_None: c_int = 0;
pub const ImGuiInputEventType_MousePos: c_int = 1;
pub const ImGuiInputEventType_MouseWheel: c_int = 2;
pub const ImGuiInputEventType_MouseButton: c_int = 3;
pub const ImGuiInputEventType_MouseViewport: c_int = 4;
pub const ImGuiInputEventType_Key: c_int = 5;
pub const ImGuiInputEventType_Text: c_int = 6;
pub const ImGuiInputEventType_Focus: c_int = 7;
pub const ImGuiInputEventType_COUNT: c_int = 8;
pub const ImGuiInputEventType = c_uint;
pub const ImGuiInputSource_None: c_int = 0;
pub const ImGuiInputSource_Mouse: c_int = 1;
pub const ImGuiInputSource_Keyboard: c_int = 2;
pub const ImGuiInputSource_Gamepad: c_int = 3;
pub const ImGuiInputSource_Clipboard: c_int = 4;
pub const ImGuiInputSource_Nav: c_int = 5;
pub const ImGuiInputSource_COUNT: c_int = 6;
pub const ImGuiInputSource = c_uint;
pub const ImGuiNavReadMode_Down: c_int = 0;
pub const ImGuiNavReadMode_Pressed: c_int = 1;
pub const ImGuiNavReadMode_Released: c_int = 2;
pub const ImGuiNavReadMode_Repeat: c_int = 3;
pub const ImGuiNavReadMode_RepeatSlow: c_int = 4;
pub const ImGuiNavReadMode_RepeatFast: c_int = 5;
pub const ImGuiNavReadMode = c_uint;
pub const ImGuiActivateFlags_None: c_int = 0;
pub const ImGuiActivateFlags_PreferInput: c_int = 1;
pub const ImGuiActivateFlags_PreferTweak: c_int = 2;
pub const ImGuiActivateFlags_TryToPreserveState: c_int = 4;
pub const ImGuiActivateFlags_ = c_uint;
pub const ImGuiScrollFlags_None: c_int = 0;
pub const ImGuiScrollFlags_KeepVisibleEdgeX: c_int = 1;
pub const ImGuiScrollFlags_KeepVisibleEdgeY: c_int = 2;
pub const ImGuiScrollFlags_KeepVisibleCenterX: c_int = 4;
pub const ImGuiScrollFlags_KeepVisibleCenterY: c_int = 8;
pub const ImGuiScrollFlags_AlwaysCenterX: c_int = 16;
pub const ImGuiScrollFlags_AlwaysCenterY: c_int = 32;
pub const ImGuiScrollFlags_NoScrollParent: c_int = 64;
pub const ImGuiScrollFlags_MaskX_: c_int = 21;
pub const ImGuiScrollFlags_MaskY_: c_int = 42;
pub const ImGuiScrollFlags_ = c_uint;
pub const ImGuiNavHighlightFlags_None: c_int = 0;
pub const ImGuiNavHighlightFlags_TypeDefault: c_int = 1;
pub const ImGuiNavHighlightFlags_TypeThin: c_int = 2;
pub const ImGuiNavHighlightFlags_AlwaysDraw: c_int = 4;
pub const ImGuiNavHighlightFlags_NoRounding: c_int = 8;
pub const ImGuiNavHighlightFlags_ = c_uint;
pub const ImGuiNavDirSourceFlags_None: c_int = 0;
pub const ImGuiNavDirSourceFlags_RawKeyboard: c_int = 1;
pub const ImGuiNavDirSourceFlags_Keyboard: c_int = 2;
pub const ImGuiNavDirSourceFlags_PadDPad: c_int = 4;
pub const ImGuiNavDirSourceFlags_PadLStick: c_int = 8;
pub const ImGuiNavDirSourceFlags_ = c_uint;
pub const ImGuiNavMoveFlags_None: c_int = 0;
pub const ImGuiNavMoveFlags_LoopX: c_int = 1;
pub const ImGuiNavMoveFlags_LoopY: c_int = 2;
pub const ImGuiNavMoveFlags_WrapX: c_int = 4;
pub const ImGuiNavMoveFlags_WrapY: c_int = 8;
pub const ImGuiNavMoveFlags_AllowCurrentNavId: c_int = 16;
pub const ImGuiNavMoveFlags_AlsoScoreVisibleSet: c_int = 32;
pub const ImGuiNavMoveFlags_ScrollToEdgeY: c_int = 64;
pub const ImGuiNavMoveFlags_Forwarded: c_int = 128;
pub const ImGuiNavMoveFlags_DebugNoResult: c_int = 256;
pub const ImGuiNavMoveFlags_FocusApi: c_int = 512;
pub const ImGuiNavMoveFlags_Tabbing: c_int = 1024;
pub const ImGuiNavMoveFlags_Activate: c_int = 2048;
pub const ImGuiNavMoveFlags_DontSetNavHighlight: c_int = 4096;
pub const ImGuiNavMoveFlags_ = c_uint;
pub const ImGuiNavLayer_Main: c_int = 0;
pub const ImGuiNavLayer_Menu: c_int = 1;
pub const ImGuiNavLayer_COUNT: c_int = 2;
pub const ImGuiNavLayer = c_uint;
pub const ImGuiOldColumnFlags_None: c_int = 0;
pub const ImGuiOldColumnFlags_NoBorder: c_int = 1;
pub const ImGuiOldColumnFlags_NoResize: c_int = 2;
pub const ImGuiOldColumnFlags_NoPreserveWidths: c_int = 4;
pub const ImGuiOldColumnFlags_NoForceWithinWindow: c_int = 8;
pub const ImGuiOldColumnFlags_GrowParentContentsSize: c_int = 16;
pub const ImGuiOldColumnFlags_ = c_uint;
pub const ImGuiDockNodeFlags_DockSpace: c_int = 1024;
pub const ImGuiDockNodeFlags_CentralNode: c_int = 2048;
pub const ImGuiDockNodeFlags_NoTabBar: c_int = 4096;
pub const ImGuiDockNodeFlags_HiddenTabBar: c_int = 8192;
pub const ImGuiDockNodeFlags_NoWindowMenuButton: c_int = 16384;
pub const ImGuiDockNodeFlags_NoCloseButton: c_int = 32768;
pub const ImGuiDockNodeFlags_NoDocking: c_int = 65536;
pub const ImGuiDockNodeFlags_NoDockingSplitMe: c_int = 131072;
pub const ImGuiDockNodeFlags_NoDockingSplitOther: c_int = 262144;
pub const ImGuiDockNodeFlags_NoDockingOverMe: c_int = 524288;
pub const ImGuiDockNodeFlags_NoDockingOverOther: c_int = 1048576;
pub const ImGuiDockNodeFlags_NoDockingOverEmpty: c_int = 2097152;
pub const ImGuiDockNodeFlags_NoResizeX: c_int = 4194304;
pub const ImGuiDockNodeFlags_NoResizeY: c_int = 8388608;
pub const ImGuiDockNodeFlags_SharedFlagsInheritMask_: c_int = -1;
pub const ImGuiDockNodeFlags_NoResizeFlagsMask_: c_int = 12582944;
pub const ImGuiDockNodeFlags_LocalFlagsMask_: c_int = 12713072;
pub const ImGuiDockNodeFlags_LocalFlagsTransferMask_: c_int = 12712048;
pub const ImGuiDockNodeFlags_SavedFlagsMask_: c_int = 12712992;
pub const ImGuiDockNodeFlagsPrivate_ = c_int;
pub const ImGuiDataAuthority_Auto: c_int = 0;
pub const ImGuiDataAuthority_DockNode: c_int = 1;
pub const ImGuiDataAuthority_Window: c_int = 2;
pub const ImGuiDataAuthority_ = c_uint;
pub const ImGuiDockNodeState_Unknown: c_int = 0;
pub const ImGuiDockNodeState_HostWindowHiddenBecauseSingleWindow: c_int = 1;
pub const ImGuiDockNodeState_HostWindowHiddenBecauseWindowsAreResizing: c_int = 2;
pub const ImGuiDockNodeState_HostWindowVisible: c_int = 3;
pub const ImGuiDockNodeState = c_uint;
pub const ImGuiWindowDockStyleCol_Text: c_int = 0;
pub const ImGuiWindowDockStyleCol_Tab: c_int = 1;
pub const ImGuiWindowDockStyleCol_TabHovered: c_int = 2;
pub const ImGuiWindowDockStyleCol_TabActive: c_int = 3;
pub const ImGuiWindowDockStyleCol_TabUnfocused: c_int = 4;
pub const ImGuiWindowDockStyleCol_TabUnfocusedActive: c_int = 5;
pub const ImGuiWindowDockStyleCol_COUNT: c_int = 6;
pub const ImGuiWindowDockStyleCol = c_uint;
pub const struct_ImGuiWindowDockStyle = extern struct {
    Colors: [6]ImU32 = @import("std").mem.zeroes([6]ImU32),
};
pub const ImGuiWindowDockStyle = struct_ImGuiWindowDockStyle;
pub const ImGuiDebugLogFlags_None: c_int = 0;
pub const ImGuiDebugLogFlags_EventActiveId: c_int = 1;
pub const ImGuiDebugLogFlags_EventFocus: c_int = 2;
pub const ImGuiDebugLogFlags_EventPopup: c_int = 4;
pub const ImGuiDebugLogFlags_EventNav: c_int = 8;
pub const ImGuiDebugLogFlags_EventIO: c_int = 16;
pub const ImGuiDebugLogFlags_EventDocking: c_int = 32;
pub const ImGuiDebugLogFlags_EventViewport: c_int = 64;
pub const ImGuiDebugLogFlags_EventMask_: c_int = 127;
pub const ImGuiDebugLogFlags_OutputToTTY: c_int = 1024;
pub const ImGuiDebugLogFlags_ = c_uint;
pub const ImGuiContextHookType_NewFramePre: c_int = 0;
pub const ImGuiContextHookType_NewFramePost: c_int = 1;
pub const ImGuiContextHookType_EndFramePre: c_int = 2;
pub const ImGuiContextHookType_EndFramePost: c_int = 3;
pub const ImGuiContextHookType_RenderPre: c_int = 4;
pub const ImGuiContextHookType_RenderPost: c_int = 5;
pub const ImGuiContextHookType_Shutdown: c_int = 6;
pub const ImGuiContextHookType_PendingRemoval_: c_int = 7;
pub const ImGuiContextHookType = c_uint;
pub const struct_ImVector_ImGuiOldColumns = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiOldColumns = @import("std").mem.zeroes([*c]ImGuiOldColumns),
};
pub const ImVector_ImGuiOldColumns = struct_ImVector_ImGuiOldColumns;
pub const ImGuiTabBarFlags_DockNode: c_int = 1048576;
pub const ImGuiTabBarFlags_IsFocused: c_int = 2097152;
pub const ImGuiTabBarFlags_SaveSettings: c_int = 4194304;
pub const ImGuiTabBarFlagsPrivate_ = c_uint;
pub const ImGuiTabItemFlags_SectionMask_: c_int = 192;
pub const ImGuiTabItemFlags_NoCloseButton: c_int = 1048576;
pub const ImGuiTabItemFlags_Button: c_int = 2097152;
pub const ImGuiTabItemFlags_Unsorted: c_int = 4194304;
pub const ImGuiTabItemFlags_Preview: c_int = 8388608;
pub const ImGuiTabItemFlagsPrivate_ = c_uint;
pub const struct_ImVector_ImGuiTableInstanceData = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: [*c]ImGuiTableInstanceData = @import("std").mem.zeroes([*c]ImGuiTableInstanceData),
};
pub const ImVector_ImGuiTableInstanceData = struct_ImVector_ImGuiTableInstanceData;
pub const struct_ImVector_ImGuiTableColumnSortSpecs = extern struct {
    Size: c_int = @import("std").mem.zeroes(c_int),
    Capacity: c_int = @import("std").mem.zeroes(c_int),
    Data: ?*ImGuiTableColumnSortSpecs = @import("std").mem.zeroes(?*ImGuiTableColumnSortSpecs),
};
pub const ImVector_ImGuiTableColumnSortSpecs = struct_ImVector_ImGuiTableColumnSortSpecs;
// cimgui2.h:2841:10: warning: struct demoted to opaque type - has bitfield
pub const struct_ImGuiTableColumnSettings = opaque {};
pub const ImGuiTableColumnSettings = struct_ImGuiTableColumnSettings;
pub extern fn ImVec2_ImVec2_Nil() [*c]ImVec2;
pub extern fn ImVec2_destroy(self: [*c]ImVec2) void;
pub extern fn ImVec2_ImVec2_Float(_x: f32, _y: f32) [*c]ImVec2;
pub extern fn ImVec4_ImVec4_Nil() [*c]ImVec4;
pub extern fn ImVec4_destroy(self: [*c]ImVec4) void;
pub extern fn ImVec4_ImVec4_Float(_x: f32, _y: f32, _z: f32, _w: f32) [*c]ImVec4;
pub extern fn igCreateContext(shared_font_atlas: [*c]ImFontAtlas) [*c]ImGuiContext;
pub extern fn igDestroyContext(ctx: [*c]ImGuiContext) void;
pub extern fn igGetCurrentContext() [*c]ImGuiContext;
pub extern fn igSetCurrentContext(ctx: [*c]ImGuiContext) void;
pub extern fn igGetIO() [*c]ImGuiIO;
pub extern fn igGetStyle() [*c]ImGuiStyle;
pub extern fn igNewFrame() void;
pub extern fn igEndFrame() void;
pub extern fn igRender() void;
pub extern fn igGetDrawData() [*c]ImDrawData;
pub extern fn igShowDemoWindow(p_open: [*c]bool) void;
pub extern fn igShowMetricsWindow(p_open: [*c]bool) void;
pub extern fn igShowDebugLogWindow(p_open: [*c]bool) void;
pub extern fn igShowStackToolWindow(p_open: [*c]bool) void;
pub extern fn igShowAboutWindow(p_open: [*c]bool) void;
pub extern fn igShowStyleEditor(ref: [*c]ImGuiStyle) void;
pub extern fn igShowStyleSelector(label: [*c]const u8) bool;
pub extern fn igShowFontSelector(label: [*c]const u8) void;
pub extern fn igShowUserGuide() void;
pub extern fn igGetVersion() [*c]const u8;
pub extern fn igStyleColorsDark(dst: [*c]ImGuiStyle) void;
pub extern fn igStyleColorsLight(dst: [*c]ImGuiStyle) void;
pub extern fn igStyleColorsClassic(dst: [*c]ImGuiStyle) void;
pub extern fn igBegin(name: [*c]const u8, p_open: [*c]bool, flags: ImGuiWindowFlags) bool;
pub extern fn igEnd() void;
pub extern fn igBeginChild_Str(str_id: [*c]const u8, size: ImVec2, border: bool, flags: ImGuiWindowFlags) bool;
pub extern fn igBeginChild_ID(id: ImGuiID, size: ImVec2, border: bool, flags: ImGuiWindowFlags) bool;
pub extern fn igEndChild() void;
pub extern fn igIsWindowAppearing() bool;
pub extern fn igIsWindowCollapsed() bool;
pub extern fn igIsWindowFocused(flags: ImGuiFocusedFlags) bool;
pub extern fn igIsWindowHovered(flags: ImGuiHoveredFlags) bool;
pub extern fn igGetWindowDrawList() [*c]ImDrawList;
pub extern fn igGetWindowDpiScale() f32;
pub extern fn igGetWindowPos(pOut: [*c]ImVec2) void;
pub extern fn igGetWindowSize(pOut: [*c]ImVec2) void;
pub extern fn igGetWindowWidth() f32;
pub extern fn igGetWindowHeight() f32;
pub extern fn igGetWindowViewport() [*c]ImGuiViewport;
pub extern fn igSetNextWindowPos(pos: ImVec2, cond: ImGuiCond, pivot: ImVec2) void;
pub extern fn igSetNextWindowSize(size: ImVec2, cond: ImGuiCond) void;
pub extern fn igSetNextWindowSizeConstraints(size_min: ImVec2, size_max: ImVec2, custom_callback: ImGuiSizeCallback, custom_callback_data: ?*anyopaque) void;
pub extern fn igSetNextWindowContentSize(size: ImVec2) void;
pub extern fn igSetNextWindowCollapsed(collapsed: bool, cond: ImGuiCond) void;
pub extern fn igSetNextWindowFocus() void;
pub extern fn igSetNextWindowBgAlpha(alpha: f32) void;
pub extern fn igSetNextWindowViewport(viewport_id: ImGuiID) void;
pub extern fn igSetWindowPos_Vec2(pos: ImVec2, cond: ImGuiCond) void;
pub extern fn igSetWindowSize_Vec2(size: ImVec2, cond: ImGuiCond) void;
pub extern fn igSetWindowCollapsed_Bool(collapsed: bool, cond: ImGuiCond) void;
pub extern fn igSetWindowFocus_Nil() void;
pub extern fn igSetWindowFontScale(scale: f32) void;
pub extern fn igSetWindowPos_Str(name: [*c]const u8, pos: ImVec2, cond: ImGuiCond) void;
pub extern fn igSetWindowSize_Str(name: [*c]const u8, size: ImVec2, cond: ImGuiCond) void;
pub extern fn igSetWindowCollapsed_Str(name: [*c]const u8, collapsed: bool, cond: ImGuiCond) void;
pub extern fn igSetWindowFocus_Str(name: [*c]const u8) void;
pub extern fn igGetContentRegionAvail(pOut: [*c]ImVec2) void;
pub extern fn igGetContentRegionMax(pOut: [*c]ImVec2) void;
pub extern fn igGetWindowContentRegionMin(pOut: [*c]ImVec2) void;
pub extern fn igGetWindowContentRegionMax(pOut: [*c]ImVec2) void;
pub extern fn igGetScrollX() f32;
pub extern fn igGetScrollY() f32;
pub extern fn igSetScrollX_Float(scroll_x: f32) void;
pub extern fn igSetScrollY_Float(scroll_y: f32) void;
pub extern fn igGetScrollMaxX() f32;
pub extern fn igGetScrollMaxY() f32;
pub extern fn igSetScrollHereX(center_x_ratio: f32) void;
pub extern fn igSetScrollHereY(center_y_ratio: f32) void;
pub extern fn igSetScrollFromPosX_Float(local_x: f32, center_x_ratio: f32) void;
pub extern fn igSetScrollFromPosY_Float(local_y: f32, center_y_ratio: f32) void;
pub extern fn igPushFont(font: [*c]ImFont) void;
pub extern fn igPopFont() void;
pub extern fn igPushStyleColor_U32(idx: ImGuiCol, col: ImU32) void;
pub extern fn igPushStyleColor_Vec4(idx: ImGuiCol, col: ImVec4) void;
pub extern fn igPopStyleColor(count: c_int) void;
pub extern fn igPushStyleVar_Float(idx: ImGuiStyleVar, val: f32) void;
pub extern fn igPushStyleVar_Vec2(idx: ImGuiStyleVar, val: ImVec2) void;
pub extern fn igPopStyleVar(count: c_int) void;
pub extern fn igPushAllowKeyboardFocus(allow_keyboard_focus: bool) void;
pub extern fn igPopAllowKeyboardFocus() void;
pub extern fn igPushButtonRepeat(repeat: bool) void;
pub extern fn igPopButtonRepeat() void;
pub extern fn igPushItemWidth(item_width: f32) void;
pub extern fn igPopItemWidth() void;
pub extern fn igSetNextItemWidth(item_width: f32) void;
pub extern fn igCalcItemWidth() f32;
pub extern fn igPushTextWrapPos(wrap_local_pos_x: f32) void;
pub extern fn igPopTextWrapPos() void;
pub extern fn igGetFont() [*c]ImFont;
pub extern fn igGetFontSize() f32;
pub extern fn igGetFontTexUvWhitePixel(pOut: [*c]ImVec2) void;
pub extern fn igGetColorU32_Col(idx: ImGuiCol, alpha_mul: f32) ImU32;
pub extern fn igGetColorU32_Vec4(col: ImVec4) ImU32;
pub extern fn igGetColorU32_U32(col: ImU32) ImU32;
pub extern fn igGetStyleColorVec4(idx: ImGuiCol) [*c]const ImVec4;
pub extern fn igSeparator() void;
pub extern fn igSameLine(offset_from_start_x: f32, spacing: f32) void;
pub extern fn igNewLine() void;
pub extern fn igSpacing() void;
pub extern fn igDummy(size: ImVec2) void;
pub extern fn igIndent(indent_w: f32) void;
pub extern fn igUnindent(indent_w: f32) void;
pub extern fn igBeginGroup() void;
pub extern fn igEndGroup() void;
pub extern fn igGetCursorPos(pOut: [*c]ImVec2) void;
pub extern fn igGetCursorPosX() f32;
pub extern fn igGetCursorPosY() f32;
pub extern fn igSetCursorPos(local_pos: ImVec2) void;
pub extern fn igSetCursorPosX(local_x: f32) void;
pub extern fn igSetCursorPosY(local_y: f32) void;
pub extern fn igGetCursorStartPos(pOut: [*c]ImVec2) void;
pub extern fn igGetCursorScreenPos(pOut: [*c]ImVec2) void;
pub extern fn igSetCursorScreenPos(pos: ImVec2) void;
pub extern fn igAlignTextToFramePadding() void;
pub extern fn igGetTextLineHeight() f32;
pub extern fn igGetTextLineHeightWithSpacing() f32;
pub extern fn igGetFrameHeight() f32;
pub extern fn igGetFrameHeightWithSpacing() f32;
pub extern fn igPushID_Str(str_id: [*c]const u8) void;
pub extern fn igPushID_StrStr(str_id_begin: [*c]const u8, str_id_end: [*c]const u8) void;
pub extern fn igPushID_Ptr(ptr_id: ?*const anyopaque) void;
pub extern fn igPushID_Int(int_id: c_int) void;
pub extern fn igPopID() void;
pub extern fn igGetID_Str(str_id: [*c]const u8) ImGuiID;
pub extern fn igGetID_StrStr(str_id_begin: [*c]const u8, str_id_end: [*c]const u8) ImGuiID;
pub extern fn igGetID_Ptr(ptr_id: ?*const anyopaque) ImGuiID;
pub extern fn igTextUnformatted(text: [*c]const u8, text_end: [*c]const u8) void;
pub extern fn igText(fmt: [*c]const u8, ...) void;
pub extern fn igTextV(fmt: [*c]const u8, args: va_list) void;
pub extern fn igTextColored(col: ImVec4, fmt: [*c]const u8, ...) void;
pub extern fn igTextColoredV(col: ImVec4, fmt: [*c]const u8, args: va_list) void;
pub extern fn igTextDisabled(fmt: [*c]const u8, ...) void;
pub extern fn igTextDisabledV(fmt: [*c]const u8, args: va_list) void;
pub extern fn igTextWrapped(fmt: [*c]const u8, ...) void;
pub extern fn igTextWrappedV(fmt: [*c]const u8, args: va_list) void;
pub extern fn igLabelText(label: [*c]const u8, fmt: [*c]const u8, ...) void;
pub extern fn igLabelTextV(label: [*c]const u8, fmt: [*c]const u8, args: va_list) void;
pub extern fn igBulletText(fmt: [*c]const u8, ...) void;
pub extern fn igBulletTextV(fmt: [*c]const u8, args: va_list) void;
pub extern fn igButton(label: [*c]const u8, size: ImVec2) bool;
pub extern fn igSmallButton(label: [*c]const u8) bool;
pub extern fn igInvisibleButton(str_id: [*c]const u8, size: ImVec2, flags: ImGuiButtonFlags) bool;
pub extern fn igArrowButton(str_id: [*c]const u8, dir: ImGuiDir) bool;
pub extern fn igImage(user_texture_id: ImTextureID, size: ImVec2, uv0: ImVec2, uv1: ImVec2, tint_col: ImVec4, border_col: ImVec4) void;
pub extern fn igImageButton(user_texture_id: ImTextureID, size: ImVec2, uv0: ImVec2, uv1: ImVec2, frame_padding: c_int, bg_col: ImVec4, tint_col: ImVec4) bool;
pub extern fn igCheckbox(label: [*c]const u8, v: [*c]bool) bool;
pub extern fn igCheckboxFlags_IntPtr(label: [*c]const u8, flags: [*c]c_int, flags_value: c_int) bool;
pub extern fn igCheckboxFlags_UintPtr(label: [*c]const u8, flags: [*c]c_uint, flags_value: c_uint) bool;
pub extern fn igRadioButton_Bool(label: [*c]const u8, active: bool) bool;
pub extern fn igRadioButton_IntPtr(label: [*c]const u8, v: [*c]c_int, v_button: c_int) bool;
pub extern fn igProgressBar(fraction: f32, size_arg: ImVec2, overlay: [*c]const u8) void;
pub extern fn igBullet() void;
pub extern fn igBeginCombo(label: [*c]const u8, preview_value: [*c]const u8, flags: ImGuiComboFlags) bool;
pub extern fn igEndCombo() void;
pub extern fn igCombo_Str_arr(label: [*c]const u8, current_item: [*c]c_int, items: [*c]const [*c]const u8, items_count: c_int, popup_max_height_in_items: c_int) bool;
pub extern fn igCombo_Str(label: [*c]const u8, current_item: [*c]c_int, items_separated_by_zeros: [*c]const u8, popup_max_height_in_items: c_int) bool;
pub extern fn igCombo_FnBoolPtr(label: [*c]const u8, current_item: [*c]c_int, items_getter: ?*const fn (?*anyopaque, c_int, [*c][*c]const u8) callconv(.C) bool, data: ?*anyopaque, items_count: c_int, popup_max_height_in_items: c_int) bool;
pub extern fn igDragFloat(label: [*c]const u8, v: [*c]f32, v_speed: f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragFloat2(label: [*c]const u8, v: [*c]f32, v_speed: f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragFloat3(label: [*c]const u8, v: [*c]f32, v_speed: f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragFloat4(label: [*c]const u8, v: [*c]f32, v_speed: f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragFloatRange2(label: [*c]const u8, v_current_min: [*c]f32, v_current_max: [*c]f32, v_speed: f32, v_min: f32, v_max: f32, format: [*c]const u8, format_max: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragInt(label: [*c]const u8, v: [*c]c_int, v_speed: f32, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragInt2(label: [*c]const u8, v: [*c]c_int, v_speed: f32, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragInt3(label: [*c]const u8, v: [*c]c_int, v_speed: f32, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragInt4(label: [*c]const u8, v: [*c]c_int, v_speed: f32, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragIntRange2(label: [*c]const u8, v_current_min: [*c]c_int, v_current_max: [*c]c_int, v_speed: f32, v_min: c_int, v_max: c_int, format: [*c]const u8, format_max: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragScalar(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, v_speed: f32, p_min: ?*const anyopaque, p_max: ?*const anyopaque, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igDragScalarN(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, components: c_int, v_speed: f32, p_min: ?*const anyopaque, p_max: ?*const anyopaque, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderFloat(label: [*c]const u8, v: [*c]f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderFloat2(label: [*c]const u8, v: [*c]f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderFloat3(label: [*c]const u8, v: [*c]f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderFloat4(label: [*c]const u8, v: [*c]f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderAngle(label: [*c]const u8, v_rad: [*c]f32, v_degrees_min: f32, v_degrees_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderInt(label: [*c]const u8, v: [*c]c_int, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderInt2(label: [*c]const u8, v: [*c]c_int, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderInt3(label: [*c]const u8, v: [*c]c_int, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderInt4(label: [*c]const u8, v: [*c]c_int, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderScalar(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, p_min: ?*const anyopaque, p_max: ?*const anyopaque, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderScalarN(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, components: c_int, p_min: ?*const anyopaque, p_max: ?*const anyopaque, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igVSliderFloat(label: [*c]const u8, size: ImVec2, v: [*c]f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igVSliderInt(label: [*c]const u8, size: ImVec2, v: [*c]c_int, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igVSliderScalar(label: [*c]const u8, size: ImVec2, data_type: ImGuiDataType, p_data: ?*anyopaque, p_min: ?*const anyopaque, p_max: ?*const anyopaque, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igInputText(label: [*c]const u8, buf: [*c]u8, buf_size: usize, flags: ImGuiInputTextFlags, callback: ImGuiInputTextCallback, user_data: ?*anyopaque) bool;
pub extern fn igInputTextMultiline(label: [*c]const u8, buf: [*c]u8, buf_size: usize, size: ImVec2, flags: ImGuiInputTextFlags, callback: ImGuiInputTextCallback, user_data: ?*anyopaque) bool;
pub extern fn igInputTextWithHint(label: [*c]const u8, hint: [*c]const u8, buf: [*c]u8, buf_size: usize, flags: ImGuiInputTextFlags, callback: ImGuiInputTextCallback, user_data: ?*anyopaque) bool;
pub extern fn igInputFloat(label: [*c]const u8, v: [*c]f32, step: f32, step_fast: f32, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputFloat2(label: [*c]const u8, v: [*c]f32, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputFloat3(label: [*c]const u8, v: [*c]f32, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputFloat4(label: [*c]const u8, v: [*c]f32, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputInt(label: [*c]const u8, v: [*c]c_int, step: c_int, step_fast: c_int, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputInt2(label: [*c]const u8, v: [*c]c_int, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputInt3(label: [*c]const u8, v: [*c]c_int, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputInt4(label: [*c]const u8, v: [*c]c_int, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputDouble(label: [*c]const u8, v: [*c]f64, step: f64, step_fast: f64, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputScalar(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, p_step: ?*const anyopaque, p_step_fast: ?*const anyopaque, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igInputScalarN(label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, components: c_int, p_step: ?*const anyopaque, p_step_fast: ?*const anyopaque, format: [*c]const u8, flags: ImGuiInputTextFlags) bool;
pub extern fn igColorEdit3(label: [*c]const u8, col: [*c]f32, flags: ImGuiColorEditFlags) bool;
pub extern fn igColorEdit4(label: [*c]const u8, col: [*c]f32, flags: ImGuiColorEditFlags) bool;
pub extern fn igColorPicker3(label: [*c]const u8, col: [*c]f32, flags: ImGuiColorEditFlags) bool;
pub extern fn igColorPicker4(label: [*c]const u8, col: [*c]f32, flags: ImGuiColorEditFlags, ref_col: [*c]const f32) bool;
pub extern fn igColorButton(desc_id: [*c]const u8, col: ImVec4, flags: ImGuiColorEditFlags, size: ImVec2) bool;
pub extern fn igSetColorEditOptions(flags: ImGuiColorEditFlags) void;
pub extern fn igTreeNode_Str(label: [*c]const u8) bool;
pub extern fn igTreeNode_StrStr(str_id: [*c]const u8, fmt: [*c]const u8, ...) bool;
pub extern fn igTreeNode_Ptr(ptr_id: ?*const anyopaque, fmt: [*c]const u8, ...) bool;
pub extern fn igTreeNodeV_Str(str_id: [*c]const u8, fmt: [*c]const u8, args: va_list) bool;
pub extern fn igTreeNodeV_Ptr(ptr_id: ?*const anyopaque, fmt: [*c]const u8, args: va_list) bool;
pub extern fn igTreeNodeEx_Str(label: [*c]const u8, flags: ImGuiTreeNodeFlags) bool;
pub extern fn igTreeNodeEx_StrStr(str_id: [*c]const u8, flags: ImGuiTreeNodeFlags, fmt: [*c]const u8, ...) bool;
pub extern fn igTreeNodeEx_Ptr(ptr_id: ?*const anyopaque, flags: ImGuiTreeNodeFlags, fmt: [*c]const u8, ...) bool;
pub extern fn igTreeNodeExV_Str(str_id: [*c]const u8, flags: ImGuiTreeNodeFlags, fmt: [*c]const u8, args: va_list) bool;
pub extern fn igTreeNodeExV_Ptr(ptr_id: ?*const anyopaque, flags: ImGuiTreeNodeFlags, fmt: [*c]const u8, args: va_list) bool;
pub extern fn igTreePush_Str(str_id: [*c]const u8) void;
pub extern fn igTreePush_Ptr(ptr_id: ?*const anyopaque) void;
pub extern fn igTreePop() void;
pub extern fn igGetTreeNodeToLabelSpacing() f32;
pub extern fn igCollapsingHeader_TreeNodeFlags(label: [*c]const u8, flags: ImGuiTreeNodeFlags) bool;
pub extern fn igCollapsingHeader_BoolPtr(label: [*c]const u8, p_visible: [*c]bool, flags: ImGuiTreeNodeFlags) bool;
pub extern fn igSetNextItemOpen(is_open: bool, cond: ImGuiCond) void;
pub extern fn igSelectable_Bool(label: [*c]const u8, selected: bool, flags: ImGuiSelectableFlags, size: ImVec2) bool;
pub extern fn igSelectable_BoolPtr(label: [*c]const u8, p_selected: [*c]bool, flags: ImGuiSelectableFlags, size: ImVec2) bool;
pub extern fn igBeginListBox(label: [*c]const u8, size: ImVec2) bool;
pub extern fn igEndListBox() void;
pub extern fn igListBox_Str_arr(label: [*c]const u8, current_item: [*c]c_int, items: [*c]const [*c]const u8, items_count: c_int, height_in_items: c_int) bool;
pub extern fn igListBox_FnBoolPtr(label: [*c]const u8, current_item: [*c]c_int, items_getter: ?*const fn (?*anyopaque, c_int, [*c][*c]const u8) callconv(.C) bool, data: ?*anyopaque, items_count: c_int, height_in_items: c_int) bool;
pub extern fn igPlotLines_FloatPtr(label: [*c]const u8, values: [*c]const f32, values_count: c_int, values_offset: c_int, overlay_text: [*c]const u8, scale_min: f32, scale_max: f32, graph_size: ImVec2, stride: c_int) void;
pub extern fn igPlotLines_FnFloatPtr(label: [*c]const u8, values_getter: ?*const fn (?*anyopaque, c_int) callconv(.C) f32, data: ?*anyopaque, values_count: c_int, values_offset: c_int, overlay_text: [*c]const u8, scale_min: f32, scale_max: f32, graph_size: ImVec2) void;     
pub extern fn igPlotHistogram_FloatPtr(label: [*c]const u8, values: [*c]const f32, values_count: c_int, values_offset: c_int, overlay_text: [*c]const u8, scale_min: f32, scale_max: f32, graph_size: ImVec2, stride: c_int) void;
pub extern fn igPlotHistogram_FnFloatPtr(label: [*c]const u8, values_getter: ?*const fn (?*anyopaque, c_int) callconv(.C) f32, data: ?*anyopaque, values_count: c_int, values_offset: c_int, overlay_text: [*c]const u8, scale_min: f32, scale_max: f32, graph_size: ImVec2) void; 
pub extern fn igValue_Bool(prefix: [*c]const u8, b: bool) void;
pub extern fn igValue_Int(prefix: [*c]const u8, v: c_int) void;
pub extern fn igValue_Uint(prefix: [*c]const u8, v: c_uint) void;
pub extern fn igValue_Float(prefix: [*c]const u8, v: f32, float_format: [*c]const u8) void;
pub extern fn igBeginMenuBar() bool;
pub extern fn igEndMenuBar() void;
pub extern fn igBeginMainMenuBar() bool;
pub extern fn igEndMainMenuBar() void;
pub extern fn igBeginMenu(label: [*c]const u8, enabled: bool) bool;
pub extern fn igEndMenu() void;
pub extern fn igMenuItem_Bool(label: [*c]const u8, shortcut: [*c]const u8, selected: bool, enabled: bool) bool;
pub extern fn igMenuItem_BoolPtr(label: [*c]const u8, shortcut: [*c]const u8, p_selected: [*c]bool, enabled: bool) bool;
pub extern fn igBeginTooltip() void;
pub extern fn igEndTooltip() void;
pub extern fn igSetTooltip(fmt: [*c]const u8, ...) void;
pub extern fn igSetTooltipV(fmt: [*c]const u8, args: va_list) void;
pub extern fn igBeginPopup(str_id: [*c]const u8, flags: ImGuiWindowFlags) bool;
pub extern fn igBeginPopupModal(name: [*c]const u8, p_open: [*c]bool, flags: ImGuiWindowFlags) bool;
pub extern fn igEndPopup() void;
pub extern fn igOpenPopup_Str(str_id: [*c]const u8, popup_flags: ImGuiPopupFlags) void;
pub extern fn igOpenPopup_ID(id: ImGuiID, popup_flags: ImGuiPopupFlags) void;
pub extern fn igOpenPopupOnItemClick(str_id: [*c]const u8, popup_flags: ImGuiPopupFlags) void;
pub extern fn igCloseCurrentPopup() void;
pub extern fn igBeginPopupContextItem(str_id: [*c]const u8, popup_flags: ImGuiPopupFlags) bool;
pub extern fn igBeginPopupContextWindow(str_id: [*c]const u8, popup_flags: ImGuiPopupFlags) bool;
pub extern fn igBeginPopupContextVoid(str_id: [*c]const u8, popup_flags: ImGuiPopupFlags) bool;
pub extern fn igIsPopupOpen_Str(str_id: [*c]const u8, flags: ImGuiPopupFlags) bool;
pub extern fn igBeginTable(str_id: [*c]const u8, column: c_int, flags: ImGuiTableFlags, outer_size: ImVec2, inner_width: f32) bool;
pub extern fn igEndTable() void;
pub extern fn igTableNextRow(row_flags: ImGuiTableRowFlags, min_row_height: f32) void;
pub extern fn igTableNextColumn() bool;
pub extern fn igTableSetColumnIndex(column_n: c_int) bool;
pub extern fn igTableSetupColumn(label: [*c]const u8, flags: ImGuiTableColumnFlags, init_width_or_weight: f32, user_id: ImGuiID) void;
pub extern fn igTableSetupScrollFreeze(cols: c_int, rows: c_int) void;
pub extern fn igTableHeadersRow() void;
pub extern fn igTableHeader(label: [*c]const u8) void;
pub extern fn igTableGetSortSpecs() [*c]ImGuiTableSortSpecs;
pub extern fn igTableGetColumnCount() c_int;
pub extern fn igTableGetColumnIndex() c_int;
pub extern fn igTableGetRowIndex() c_int;
pub extern fn igTableGetColumnName_Int(column_n: c_int) [*c]const u8;
pub extern fn igTableGetColumnFlags(column_n: c_int) ImGuiTableColumnFlags;
pub extern fn igTableSetColumnEnabled(column_n: c_int, v: bool) void;
pub extern fn igTableSetBgColor(target: ImGuiTableBgTarget, color: ImU32, column_n: c_int) void;
pub extern fn igColumns(count: c_int, id: [*c]const u8, border: bool) void;
pub extern fn igNextColumn() void;
pub extern fn igGetColumnIndex() c_int;
pub extern fn igGetColumnWidth(column_index: c_int) f32;
pub extern fn igSetColumnWidth(column_index: c_int, width: f32) void;
pub extern fn igGetColumnOffset(column_index: c_int) f32;
pub extern fn igSetColumnOffset(column_index: c_int, offset_x: f32) void;
pub extern fn igGetColumnsCount() c_int;
pub extern fn igBeginTabBar(str_id: [*c]const u8, flags: ImGuiTabBarFlags) bool;
pub extern fn igEndTabBar() void;
pub extern fn igBeginTabItem(label: [*c]const u8, p_open: [*c]bool, flags: ImGuiTabItemFlags) bool;
pub extern fn igEndTabItem() void;
pub extern fn igTabItemButton(label: [*c]const u8, flags: ImGuiTabItemFlags) bool;
pub extern fn igSetTabItemClosed(tab_or_docked_window_label: [*c]const u8) void;
pub extern fn igDockSpace(id: ImGuiID, size: ImVec2, flags: ImGuiDockNodeFlags, window_class: [*c]const ImGuiWindowClass) ImGuiID;
pub extern fn igDockSpaceOverViewport(viewport: [*c]const ImGuiViewport, flags: ImGuiDockNodeFlags, window_class: [*c]const ImGuiWindowClass) ImGuiID;
pub extern fn igSetNextWindowDockID(dock_id: ImGuiID, cond: ImGuiCond) void;
pub extern fn igSetNextWindowClass(window_class: [*c]const ImGuiWindowClass) void;
pub extern fn igGetWindowDockID() ImGuiID;
pub extern fn igIsWindowDocked() bool;
pub extern fn igLogToTTY(auto_open_depth: c_int) void;
pub extern fn igLogToFile(auto_open_depth: c_int, filename: [*c]const u8) void;
pub extern fn igLogToClipboard(auto_open_depth: c_int) void;
pub extern fn igLogFinish() void;
pub extern fn igLogButtons() void;
pub extern fn igLogTextV(fmt: [*c]const u8, args: va_list) void;
pub extern fn igBeginDragDropSource(flags: ImGuiDragDropFlags) bool;
pub extern fn igSetDragDropPayload(@"type": [*c]const u8, data: ?*const anyopaque, sz: usize, cond: ImGuiCond) bool;
pub extern fn igEndDragDropSource() void;
pub extern fn igBeginDragDropTarget() bool;
pub extern fn igAcceptDragDropPayload(@"type": [*c]const u8, flags: ImGuiDragDropFlags) [*c]const ImGuiPayload;
pub extern fn igEndDragDropTarget() void;
pub extern fn igGetDragDropPayload() [*c]const ImGuiPayload;
pub extern fn igBeginDisabled(disabled: bool) void;
pub extern fn igEndDisabled() void;
pub extern fn igPushClipRect(clip_rect_min: ImVec2, clip_rect_max: ImVec2, intersect_with_current_clip_rect: bool) void;
pub extern fn igPopClipRect() void;
pub extern fn igSetItemDefaultFocus() void;
pub extern fn igSetKeyboardFocusHere(offset: c_int) void;
pub extern fn igIsItemHovered(flags: ImGuiHoveredFlags) bool;
pub extern fn igIsItemActive() bool;
pub extern fn igIsItemFocused() bool;
pub extern fn igIsItemClicked(mouse_button: ImGuiMouseButton) bool;
pub extern fn igIsItemVisible() bool;
pub extern fn igIsItemEdited() bool;
pub extern fn igIsItemActivated() bool;
pub extern fn igIsItemDeactivated() bool;
pub extern fn igIsItemDeactivatedAfterEdit() bool;
pub extern fn igIsItemToggledOpen() bool;
pub extern fn igIsAnyItemHovered() bool;
pub extern fn igIsAnyItemActive() bool;
pub extern fn igIsAnyItemFocused() bool;
pub extern fn igGetItemRectMin(pOut: [*c]ImVec2) void;
pub extern fn igGetItemRectMax(pOut: [*c]ImVec2) void;
pub extern fn igGetItemRectSize(pOut: [*c]ImVec2) void;
pub extern fn igSetItemAllowOverlap() void;
pub extern fn igGetMainViewport() [*c]ImGuiViewport;
pub extern fn igGetBackgroundDrawList_Nil() [*c]ImDrawList;
pub extern fn igGetForegroundDrawList_Nil() [*c]ImDrawList;
pub extern fn igGetBackgroundDrawList_ViewportPtr(viewport: [*c]ImGuiViewport) [*c]ImDrawList;
pub extern fn igGetForegroundDrawList_ViewportPtr(viewport: [*c]ImGuiViewport) [*c]ImDrawList;
pub extern fn igIsRectVisible_Nil(size: ImVec2) bool;
pub extern fn igIsRectVisible_Vec2(rect_min: ImVec2, rect_max: ImVec2) bool;
pub extern fn igGetTime() f64;
pub extern fn igGetFrameCount() c_int;
pub extern fn igGetDrawListSharedData() [*c]ImDrawListSharedData;
pub extern fn igGetStyleColorName(idx: ImGuiCol) [*c]const u8;
pub extern fn igSetStateStorage(storage: [*c]ImGuiStorage) void;
pub extern fn igGetStateStorage() [*c]ImGuiStorage;
pub extern fn igBeginChildFrame(id: ImGuiID, size: ImVec2, flags: ImGuiWindowFlags) bool;
pub extern fn igEndChildFrame() void;
pub extern fn igCalcTextSize(pOut: [*c]ImVec2, text: [*c]const u8, text_end: [*c]const u8, hide_text_after_double_hash: bool, wrap_width: f32) void;
pub extern fn igColorConvertU32ToFloat4(pOut: [*c]ImVec4, in: ImU32) void;
pub extern fn igColorConvertFloat4ToU32(in: ImVec4) ImU32;
pub extern fn igColorConvertRGBtoHSV(r: f32, g: f32, b: f32, out_h: [*c]f32, out_s: [*c]f32, out_v: [*c]f32) void;
pub extern fn igColorConvertHSVtoRGB(h: f32, s: f32, v: f32, out_r: [*c]f32, out_g: [*c]f32, out_b: [*c]f32) void;
pub extern fn igIsKeyDown(key: ImGuiKey) bool;
pub extern fn igIsKeyPressed(key: ImGuiKey, repeat: bool) bool;
pub extern fn igIsKeyReleased(key: ImGuiKey) bool;
pub extern fn igGetKeyPressedAmount(key: ImGuiKey, repeat_delay: f32, rate: f32) c_int;
pub extern fn igGetKeyName(key: ImGuiKey) [*c]const u8;
pub extern fn igSetNextFrameWantCaptureKeyboard(want_capture_keyboard: bool) void;
pub extern fn igIsMouseDown(button: ImGuiMouseButton) bool;
pub extern fn igIsMouseClicked(button: ImGuiMouseButton, repeat: bool) bool;
pub extern fn igIsMouseReleased(button: ImGuiMouseButton) bool;
pub extern fn igIsMouseDoubleClicked(button: ImGuiMouseButton) bool;
pub extern fn igGetMouseClickedCount(button: ImGuiMouseButton) c_int;
pub extern fn igIsMouseHoveringRect(r_min: ImVec2, r_max: ImVec2, clip: bool) bool;
pub extern fn igIsMousePosValid(mouse_pos: [*c]const ImVec2) bool;
pub extern fn igIsAnyMouseDown() bool;
pub extern fn igGetMousePos(pOut: [*c]ImVec2) void;
pub extern fn igGetMousePosOnOpeningCurrentPopup(pOut: [*c]ImVec2) void;
pub extern fn igIsMouseDragging(button: ImGuiMouseButton, lock_threshold: f32) bool;
pub extern fn igGetMouseDragDelta(pOut: [*c]ImVec2, button: ImGuiMouseButton, lock_threshold: f32) void;
pub extern fn igResetMouseDragDelta(button: ImGuiMouseButton) void;
pub extern fn igGetMouseCursor() ImGuiMouseCursor;
pub extern fn igSetMouseCursor(cursor_type: ImGuiMouseCursor) void;
pub extern fn igSetNextFrameWantCaptureMouse(want_capture_mouse: bool) void;
pub extern fn igGetClipboardText() [*c]const u8;
pub extern fn igSetClipboardText(text: [*c]const u8) void;
pub extern fn igLoadIniSettingsFromDisk(ini_filename: [*c]const u8) void;
pub extern fn igLoadIniSettingsFromMemory(ini_data: [*c]const u8, ini_size: usize) void;
pub extern fn igSaveIniSettingsToDisk(ini_filename: [*c]const u8) void;
pub extern fn igSaveIniSettingsToMemory(out_ini_size: [*c]usize) [*c]const u8;
pub extern fn igDebugTextEncoding(text: [*c]const u8) void;
pub extern fn igDebugCheckVersionAndDataLayout(version_str: [*c]const u8, sz_io: usize, sz_style: usize, sz_vec2: usize, sz_vec4: usize, sz_drawvert: usize, sz_drawidx: usize) bool;
pub extern fn igSetAllocatorFunctions(alloc_func: ImGuiMemAllocFunc, free_func: ImGuiMemFreeFunc, user_data: ?*anyopaque) void;
pub extern fn igGetAllocatorFunctions(p_alloc_func: [*c]ImGuiMemAllocFunc, p_free_func: [*c]ImGuiMemFreeFunc, p_user_data: [*c]?*anyopaque) void;
pub extern fn igMemAlloc(size: usize) ?*anyopaque;
pub extern fn igMemFree(ptr: ?*anyopaque) void;
pub extern fn igGetPlatformIO() [*c]ImGuiPlatformIO;
pub extern fn igUpdatePlatformWindows() void;
pub extern fn igRenderPlatformWindowsDefault(platform_render_arg: ?*anyopaque, renderer_render_arg: ?*anyopaque) void;
pub extern fn igDestroyPlatformWindows() void;
pub extern fn igFindViewportByID(id: ImGuiID) [*c]ImGuiViewport;
pub extern fn igFindViewportByPlatformHandle(platform_handle: ?*anyopaque) [*c]ImGuiViewport;
pub extern fn ImGuiStyle_ImGuiStyle() [*c]ImGuiStyle;
pub extern fn ImGuiStyle_destroy(self: [*c]ImGuiStyle) void;
pub extern fn ImGuiStyle_ScaleAllSizes(self: [*c]ImGuiStyle, scale_factor: f32) void;
pub extern fn ImGuiIO_AddKeyEvent(self: [*c]ImGuiIO, key: ImGuiKey, down: bool) void;
pub extern fn ImGuiIO_AddKeyAnalogEvent(self: [*c]ImGuiIO, key: ImGuiKey, down: bool, v: f32) void;
pub extern fn ImGuiIO_AddMousePosEvent(self: [*c]ImGuiIO, x: f32, y: f32) void;
pub extern fn ImGuiIO_AddMouseButtonEvent(self: [*c]ImGuiIO, button: c_int, down: bool) void;
pub extern fn ImGuiIO_AddMouseWheelEvent(self: [*c]ImGuiIO, wh_x: f32, wh_y: f32) void;
pub extern fn ImGuiIO_AddMouseViewportEvent(self: [*c]ImGuiIO, id: ImGuiID) void;
pub extern fn ImGuiIO_AddFocusEvent(self: [*c]ImGuiIO, focused: bool) void;
pub extern fn ImGuiIO_AddInputCharacter(self: [*c]ImGuiIO, c: c_uint) void;
pub extern fn ImGuiIO_AddInputCharacterUTF16(self: [*c]ImGuiIO, c: ImWchar16) void;
pub extern fn ImGuiIO_AddInputCharactersUTF8(self: [*c]ImGuiIO, str: [*c]const u8) void;
pub extern fn ImGuiIO_SetKeyEventNativeData(self: [*c]ImGuiIO, key: ImGuiKey, native_keycode: c_int, native_scancode: c_int, native_legacy_index: c_int) void;
pub extern fn ImGuiIO_SetAppAcceptingEvents(self: [*c]ImGuiIO, accepting_events: bool) void;
pub extern fn ImGuiIO_ClearInputCharacters(self: [*c]ImGuiIO) void;
pub extern fn ImGuiIO_ClearInputKeys(self: [*c]ImGuiIO) void;
pub extern fn ImGuiIO_ImGuiIO() [*c]ImGuiIO;
pub extern fn ImGuiIO_destroy(self: [*c]ImGuiIO) void;
pub extern fn ImGuiInputTextCallbackData_ImGuiInputTextCallbackData() [*c]ImGuiInputTextCallbackData;
pub extern fn ImGuiInputTextCallbackData_destroy(self: [*c]ImGuiInputTextCallbackData) void;
pub extern fn ImGuiInputTextCallbackData_DeleteChars(self: [*c]ImGuiInputTextCallbackData, pos: c_int, bytes_count: c_int) void;
pub extern fn ImGuiInputTextCallbackData_InsertChars(self: [*c]ImGuiInputTextCallbackData, pos: c_int, text: [*c]const u8, text_end: [*c]const u8) void;
pub extern fn ImGuiInputTextCallbackData_SelectAll(self: [*c]ImGuiInputTextCallbackData) void;
pub extern fn ImGuiInputTextCallbackData_ClearSelection(self: [*c]ImGuiInputTextCallbackData) void;
pub extern fn ImGuiInputTextCallbackData_HasSelection(self: [*c]ImGuiInputTextCallbackData) bool;
pub extern fn ImGuiWindowClass_ImGuiWindowClass() [*c]ImGuiWindowClass;
pub extern fn ImGuiWindowClass_destroy(self: [*c]ImGuiWindowClass) void;
pub extern fn ImGuiPayload_ImGuiPayload() [*c]ImGuiPayload;
pub extern fn ImGuiPayload_destroy(self: [*c]ImGuiPayload) void;
pub extern fn ImGuiPayload_Clear(self: [*c]ImGuiPayload) void;
pub extern fn ImGuiPayload_IsDataType(self: [*c]ImGuiPayload, @"type": [*c]const u8) bool;
pub extern fn ImGuiPayload_IsPreview(self: [*c]ImGuiPayload) bool;
pub extern fn ImGuiPayload_IsDelivery(self: [*c]ImGuiPayload) bool;
pub extern fn ImGuiTableColumnSortSpecs_ImGuiTableColumnSortSpecs() ?*ImGuiTableColumnSortSpecs;
pub extern fn ImGuiTableColumnSortSpecs_destroy(self: ?*ImGuiTableColumnSortSpecs) void;
pub extern fn ImGuiTableSortSpecs_ImGuiTableSortSpecs() [*c]ImGuiTableSortSpecs;
pub extern fn ImGuiTableSortSpecs_destroy(self: [*c]ImGuiTableSortSpecs) void;
pub extern fn ImGuiOnceUponAFrame_ImGuiOnceUponAFrame() [*c]ImGuiOnceUponAFrame;
pub extern fn ImGuiOnceUponAFrame_destroy(self: [*c]ImGuiOnceUponAFrame) void;
pub extern fn ImGuiTextFilter_ImGuiTextFilter(default_filter: [*c]const u8) [*c]ImGuiTextFilter;
pub extern fn ImGuiTextFilter_destroy(self: [*c]ImGuiTextFilter) void;
pub extern fn ImGuiTextFilter_Draw(self: [*c]ImGuiTextFilter, label: [*c]const u8, width: f32) bool;
pub extern fn ImGuiTextFilter_PassFilter(self: [*c]ImGuiTextFilter, text: [*c]const u8, text_end: [*c]const u8) bool;
pub extern fn ImGuiTextFilter_Build(self: [*c]ImGuiTextFilter) void;
pub extern fn ImGuiTextFilter_Clear(self: [*c]ImGuiTextFilter) void;
pub extern fn ImGuiTextFilter_IsActive(self: [*c]ImGuiTextFilter) bool;
pub extern fn ImGuiTextRange_ImGuiTextRange_Nil() [*c]ImGuiTextRange;
pub extern fn ImGuiTextRange_destroy(self: [*c]ImGuiTextRange) void;
pub extern fn ImGuiTextRange_ImGuiTextRange_Str(_b: [*c]const u8, _e: [*c]const u8) [*c]ImGuiTextRange;
pub extern fn ImGuiTextRange_empty(self: [*c]ImGuiTextRange) bool;
pub extern fn ImGuiTextRange_split(self: [*c]ImGuiTextRange, separator: u8, out: [*c]ImVector_ImGuiTextRange) void;
pub extern fn ImGuiTextBuffer_ImGuiTextBuffer() [*c]ImGuiTextBuffer;
pub extern fn ImGuiTextBuffer_destroy(self: [*c]ImGuiTextBuffer) void;
pub extern fn ImGuiTextBuffer_begin(self: [*c]ImGuiTextBuffer) [*c]const u8;
pub extern fn ImGuiTextBuffer_end(self: [*c]ImGuiTextBuffer) [*c]const u8;
pub extern fn ImGuiTextBuffer_size(self: [*c]ImGuiTextBuffer) c_int;
pub extern fn ImGuiTextBuffer_empty(self: [*c]ImGuiTextBuffer) bool;
pub extern fn ImGuiTextBuffer_clear(self: [*c]ImGuiTextBuffer) void;
pub extern fn ImGuiTextBuffer_reserve(self: [*c]ImGuiTextBuffer, capacity: c_int) void;
pub extern fn ImGuiTextBuffer_c_str(self: [*c]ImGuiTextBuffer) [*c]const u8;
pub extern fn ImGuiTextBuffer_append(self: [*c]ImGuiTextBuffer, str: [*c]const u8, str_end: [*c]const u8) void;
pub extern fn ImGuiTextBuffer_appendfv(self: [*c]ImGuiTextBuffer, fmt: [*c]const u8, args: va_list) void;
pub extern fn ImGuiStoragePair_ImGuiStoragePair_Int(_key: ImGuiID, _val_i: c_int) [*c]ImGuiStoragePair;
pub extern fn ImGuiStoragePair_destroy(self: [*c]ImGuiStoragePair) void;
pub extern fn ImGuiStoragePair_ImGuiStoragePair_Float(_key: ImGuiID, _val_f: f32) [*c]ImGuiStoragePair;
pub extern fn ImGuiStoragePair_ImGuiStoragePair_Ptr(_key: ImGuiID, _val_p: ?*anyopaque) [*c]ImGuiStoragePair;
pub extern fn ImGuiStorage_Clear(self: [*c]ImGuiStorage) void;
pub extern fn ImGuiStorage_GetInt(self: [*c]ImGuiStorage, key: ImGuiID, default_val: c_int) c_int;
pub extern fn ImGuiStorage_SetInt(self: [*c]ImGuiStorage, key: ImGuiID, val: c_int) void;
pub extern fn ImGuiStorage_GetBool(self: [*c]ImGuiStorage, key: ImGuiID, default_val: bool) bool;
pub extern fn ImGuiStorage_SetBool(self: [*c]ImGuiStorage, key: ImGuiID, val: bool) void;
pub extern fn ImGuiStorage_GetFloat(self: [*c]ImGuiStorage, key: ImGuiID, default_val: f32) f32;
pub extern fn ImGuiStorage_SetFloat(self: [*c]ImGuiStorage, key: ImGuiID, val: f32) void;
pub extern fn ImGuiStorage_GetVoidPtr(self: [*c]ImGuiStorage, key: ImGuiID) ?*anyopaque;
pub extern fn ImGuiStorage_SetVoidPtr(self: [*c]ImGuiStorage, key: ImGuiID, val: ?*anyopaque) void;
pub extern fn ImGuiStorage_GetIntRef(self: [*c]ImGuiStorage, key: ImGuiID, default_val: c_int) [*c]c_int;
pub extern fn ImGuiStorage_GetBoolRef(self: [*c]ImGuiStorage, key: ImGuiID, default_val: bool) [*c]bool;
pub extern fn ImGuiStorage_GetFloatRef(self: [*c]ImGuiStorage, key: ImGuiID, default_val: f32) [*c]f32;
pub extern fn ImGuiStorage_GetVoidPtrRef(self: [*c]ImGuiStorage, key: ImGuiID, default_val: ?*anyopaque) [*c]?*anyopaque;
pub extern fn ImGuiStorage_SetAllInt(self: [*c]ImGuiStorage, val: c_int) void;
pub extern fn ImGuiStorage_BuildSortByKey(self: [*c]ImGuiStorage) void;
pub extern fn ImGuiListClipper_ImGuiListClipper() [*c]ImGuiListClipper;
pub extern fn ImGuiListClipper_destroy(self: [*c]ImGuiListClipper) void;
pub extern fn ImGuiListClipper_Begin(self: [*c]ImGuiListClipper, items_count: c_int, items_height: f32) void;
pub extern fn ImGuiListClipper_End(self: [*c]ImGuiListClipper) void;
pub extern fn ImGuiListClipper_Step(self: [*c]ImGuiListClipper) bool;
pub extern fn ImGuiListClipper_ForceDisplayRangeByIndices(self: [*c]ImGuiListClipper, item_min: c_int, item_max: c_int) void;
pub extern fn ImColor_ImColor_Nil() [*c]ImColor;
pub extern fn ImColor_destroy(self: [*c]ImColor) void;
pub extern fn ImColor_ImColor_Float(r: f32, g: f32, b: f32, a: f32) [*c]ImColor;
pub extern fn ImColor_ImColor_Vec4(col: ImVec4) [*c]ImColor;
pub extern fn ImColor_ImColor_Int(r: c_int, g: c_int, b: c_int, a: c_int) [*c]ImColor;
pub extern fn ImColor_ImColor_U32(rgba: ImU32) [*c]ImColor;
pub extern fn ImColor_SetHSV(self: [*c]ImColor, h: f32, s: f32, v: f32, a: f32) void;
pub extern fn ImColor_HSV(pOut: [*c]ImColor, h: f32, s: f32, v: f32, a: f32) void;
pub extern fn ImDrawCmd_ImDrawCmd() [*c]ImDrawCmd;
pub extern fn ImDrawCmd_destroy(self: [*c]ImDrawCmd) void;
pub extern fn ImDrawCmd_GetTexID(self: [*c]ImDrawCmd) ImTextureID;
pub extern fn ImDrawListSplitter_ImDrawListSplitter() [*c]ImDrawListSplitter;
pub extern fn ImDrawListSplitter_destroy(self: [*c]ImDrawListSplitter) void;
pub extern fn ImDrawListSplitter_Clear(self: [*c]ImDrawListSplitter) void;
pub extern fn ImDrawListSplitter_ClearFreeMemory(self: [*c]ImDrawListSplitter) void;
pub extern fn ImDrawListSplitter_Split(self: [*c]ImDrawListSplitter, draw_list: [*c]ImDrawList, count: c_int) void;
pub extern fn ImDrawListSplitter_Merge(self: [*c]ImDrawListSplitter, draw_list: [*c]ImDrawList) void;
pub extern fn ImDrawListSplitter_SetCurrentChannel(self: [*c]ImDrawListSplitter, draw_list: [*c]ImDrawList, channel_idx: c_int) void;
pub extern fn ImDrawList_ImDrawList(shared_data: [*c]const ImDrawListSharedData) [*c]ImDrawList;
pub extern fn ImDrawList_destroy(self: [*c]ImDrawList) void;
pub extern fn ImDrawList_PushClipRect(self: [*c]ImDrawList, clip_rect_min: ImVec2, clip_rect_max: ImVec2, intersect_with_current_clip_rect: bool) void;
pub extern fn ImDrawList_PushClipRectFullScreen(self: [*c]ImDrawList) void;
pub extern fn ImDrawList_PopClipRect(self: [*c]ImDrawList) void;
pub extern fn ImDrawList_PushTextureID(self: [*c]ImDrawList, texture_id: ImTextureID) void;
pub extern fn ImDrawList_PopTextureID(self: [*c]ImDrawList) void;
pub extern fn ImDrawList_GetClipRectMin(pOut: [*c]ImVec2, self: [*c]ImDrawList) void;
pub extern fn ImDrawList_GetClipRectMax(pOut: [*c]ImVec2, self: [*c]ImDrawList) void;
pub extern fn ImDrawList_AddLine(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, col: ImU32, thickness: f32) void;
pub extern fn ImDrawList_AddRect(self: [*c]ImDrawList, p_min: ImVec2, p_max: ImVec2, col: ImU32, rounding: f32, flags: ImDrawFlags, thickness: f32) void;
pub extern fn ImDrawList_AddRectFilled(self: [*c]ImDrawList, p_min: ImVec2, p_max: ImVec2, col: ImU32, rounding: f32, flags: ImDrawFlags) void;
pub extern fn ImDrawList_AddRectFilledMultiColor(self: [*c]ImDrawList, p_min: ImVec2, p_max: ImVec2, col_upr_left: ImU32, col_upr_right: ImU32, col_bot_right: ImU32, col_bot_left: ImU32) void;
pub extern fn ImDrawList_AddQuad(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, col: ImU32, thickness: f32) void;
pub extern fn ImDrawList_AddQuadFilled(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_AddTriangle(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, p3: ImVec2, col: ImU32, thickness: f32) void;
pub extern fn ImDrawList_AddTriangleFilled(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, p3: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_AddCircle(self: [*c]ImDrawList, center: ImVec2, radius: f32, col: ImU32, num_segments: c_int, thickness: f32) void;
pub extern fn ImDrawList_AddCircleFilled(self: [*c]ImDrawList, center: ImVec2, radius: f32, col: ImU32, num_segments: c_int) void;
pub extern fn ImDrawList_AddNgon(self: [*c]ImDrawList, center: ImVec2, radius: f32, col: ImU32, num_segments: c_int, thickness: f32) void;
pub extern fn ImDrawList_AddNgonFilled(self: [*c]ImDrawList, center: ImVec2, radius: f32, col: ImU32, num_segments: c_int) void;
pub extern fn ImDrawList_AddText_Vec2(self: [*c]ImDrawList, pos: ImVec2, col: ImU32, text_begin: [*c]const u8, text_end: [*c]const u8) void;
pub extern fn ImDrawList_AddText_FontPtr(self: [*c]ImDrawList, font: [*c]const ImFont, font_size: f32, pos: ImVec2, col: ImU32, text_begin: [*c]const u8, text_end: [*c]const u8, wrap_width: f32, cpu_fine_clip_rect: [*c]const ImVec4) void;
pub extern fn ImDrawList_AddPolyline(self: [*c]ImDrawList, points: [*c]const ImVec2, num_points: c_int, col: ImU32, flags: ImDrawFlags, thickness: f32) void;
pub extern fn ImDrawList_AddConvexPolyFilled(self: [*c]ImDrawList, points: [*c]const ImVec2, num_points: c_int, col: ImU32) void;
pub extern fn ImDrawList_AddBezierCubic(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, col: ImU32, thickness: f32, num_segments: c_int) void;
pub extern fn ImDrawList_AddBezierQuadratic(self: [*c]ImDrawList, p1: ImVec2, p2: ImVec2, p3: ImVec2, col: ImU32, thickness: f32, num_segments: c_int) void;
pub extern fn ImDrawList_AddImage(self: [*c]ImDrawList, user_texture_id: ImTextureID, p_min: ImVec2, p_max: ImVec2, uv_min: ImVec2, uv_max: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_AddImageQuad(self: [*c]ImDrawList, user_texture_id: ImTextureID, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, uv1: ImVec2, uv2: ImVec2, uv3: ImVec2, uv4: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_AddImageRounded(self: [*c]ImDrawList, user_texture_id: ImTextureID, p_min: ImVec2, p_max: ImVec2, uv_min: ImVec2, uv_max: ImVec2, col: ImU32, rounding: f32, flags: ImDrawFlags) void;
pub extern fn ImDrawList_PathClear(self: [*c]ImDrawList) void;
pub extern fn ImDrawList_PathLineTo(self: [*c]ImDrawList, pos: ImVec2) void;
pub extern fn ImDrawList_PathLineToMergeDuplicate(self: [*c]ImDrawList, pos: ImVec2) void;
pub extern fn ImDrawList_PathFillConvex(self: [*c]ImDrawList, col: ImU32) void;
pub extern fn ImDrawList_PathStroke(self: [*c]ImDrawList, col: ImU32, flags: ImDrawFlags, thickness: f32) void;
pub extern fn ImDrawList_PathArcTo(self: [*c]ImDrawList, center: ImVec2, radius: f32, a_min: f32, a_max: f32, num_segments: c_int) void;
pub extern fn ImDrawList_PathArcToFast(self: [*c]ImDrawList, center: ImVec2, radius: f32, a_min_of_12: c_int, a_max_of_12: c_int) void;
pub extern fn ImDrawList_PathBezierCubicCurveTo(self: [*c]ImDrawList, p2: ImVec2, p3: ImVec2, p4: ImVec2, num_segments: c_int) void;
pub extern fn ImDrawList_PathBezierQuadraticCurveTo(self: [*c]ImDrawList, p2: ImVec2, p3: ImVec2, num_segments: c_int) void;
pub extern fn ImDrawList_PathRect(self: [*c]ImDrawList, rect_min: ImVec2, rect_max: ImVec2, rounding: f32, flags: ImDrawFlags) void;
pub extern fn ImDrawList_AddCallback(self: [*c]ImDrawList, callback: ImDrawCallback, callback_data: ?*anyopaque) void;
pub extern fn ImDrawList_AddDrawCmd(self: [*c]ImDrawList) void;
pub extern fn ImDrawList_CloneOutput(self: [*c]ImDrawList) [*c]ImDrawList;
pub extern fn ImDrawList_ChannelsSplit(self: [*c]ImDrawList, count: c_int) void;
pub extern fn ImDrawList_ChannelsMerge(self: [*c]ImDrawList) void;
pub extern fn ImDrawList_ChannelsSetCurrent(self: [*c]ImDrawList, n: c_int) void;
pub extern fn ImDrawList_PrimReserve(self: [*c]ImDrawList, idx_count: c_int, vtx_count: c_int) void;
pub extern fn ImDrawList_PrimUnreserve(self: [*c]ImDrawList, idx_count: c_int, vtx_count: c_int) void;
pub extern fn ImDrawList_PrimRect(self: [*c]ImDrawList, a: ImVec2, b: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_PrimRectUV(self: [*c]ImDrawList, a: ImVec2, b: ImVec2, uv_a: ImVec2, uv_b: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_PrimQuadUV(self: [*c]ImDrawList, a: ImVec2, b: ImVec2, c: ImVec2, d: ImVec2, uv_a: ImVec2, uv_b: ImVec2, uv_c: ImVec2, uv_d: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_PrimWriteVtx(self: [*c]ImDrawList, pos: ImVec2, uv: ImVec2, col: ImU32) void;
pub extern fn ImDrawList_PrimWriteIdx(self: [*c]ImDrawList, idx: ImDrawIdx) void;
pub extern fn ImDrawList_PrimVtx(self: [*c]ImDrawList, pos: ImVec2, uv: ImVec2, col: ImU32) void;
pub extern fn ImDrawList__ResetForNewFrame(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__ClearFreeMemory(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__PopUnusedDrawCmd(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__TryMergeDrawCmds(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__OnChangedClipRect(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__OnChangedTextureID(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__OnChangedVtxOffset(self: [*c]ImDrawList) void;
pub extern fn ImDrawList__CalcCircleAutoSegmentCount(self: [*c]ImDrawList, radius: f32) c_int;
pub extern fn ImDrawList__PathArcToFastEx(self: [*c]ImDrawList, center: ImVec2, radius: f32, a_min_sample: c_int, a_max_sample: c_int, a_step: c_int) void;
pub extern fn ImDrawList__PathArcToN(self: [*c]ImDrawList, center: ImVec2, radius: f32, a_min: f32, a_max: f32, num_segments: c_int) void;
pub extern fn ImDrawData_ImDrawData() [*c]ImDrawData;
pub extern fn ImDrawData_destroy(self: [*c]ImDrawData) void;
pub extern fn ImDrawData_Clear(self: [*c]ImDrawData) void;
pub extern fn ImDrawData_DeIndexAllBuffers(self: [*c]ImDrawData) void;
pub extern fn ImDrawData_ScaleClipRects(self: [*c]ImDrawData, fb_scale: ImVec2) void;
pub extern fn ImFontConfig_ImFontConfig() [*c]ImFontConfig;
pub extern fn ImFontConfig_destroy(self: [*c]ImFontConfig) void;
pub extern fn ImFontGlyphRangesBuilder_ImFontGlyphRangesBuilder() [*c]ImFontGlyphRangesBuilder;
pub extern fn ImFontGlyphRangesBuilder_destroy(self: [*c]ImFontGlyphRangesBuilder) void;
pub extern fn ImFontGlyphRangesBuilder_Clear(self: [*c]ImFontGlyphRangesBuilder) void;
pub extern fn ImFontGlyphRangesBuilder_GetBit(self: [*c]ImFontGlyphRangesBuilder, n: usize) bool;
pub extern fn ImFontGlyphRangesBuilder_SetBit(self: [*c]ImFontGlyphRangesBuilder, n: usize) void;
pub extern fn ImFontGlyphRangesBuilder_AddChar(self: [*c]ImFontGlyphRangesBuilder, c: ImWchar) void;
pub extern fn ImFontGlyphRangesBuilder_AddText(self: [*c]ImFontGlyphRangesBuilder, text: [*c]const u8, text_end: [*c]const u8) void;
pub extern fn ImFontGlyphRangesBuilder_AddRanges(self: [*c]ImFontGlyphRangesBuilder, ranges: [*c]const ImWchar) void;
pub extern fn ImFontGlyphRangesBuilder_BuildRanges(self: [*c]ImFontGlyphRangesBuilder, out_ranges: [*c]ImVector_ImWchar) void;
pub extern fn ImFontAtlasCustomRect_ImFontAtlasCustomRect() [*c]ImFontAtlasCustomRect;
pub extern fn ImFontAtlasCustomRect_destroy(self: [*c]ImFontAtlasCustomRect) void;
pub extern fn ImFontAtlasCustomRect_IsPacked(self: [*c]ImFontAtlasCustomRect) bool;
pub extern fn ImFontAtlas_ImFontAtlas() [*c]ImFontAtlas;
pub extern fn ImFontAtlas_destroy(self: [*c]ImFontAtlas) void;
pub extern fn ImFontAtlas_AddFont(self: [*c]ImFontAtlas, font_cfg: [*c]const ImFontConfig) [*c]ImFont;
pub extern fn ImFontAtlas_AddFontDefault(self: [*c]ImFontAtlas, font_cfg: [*c]const ImFontConfig) [*c]ImFont;
pub extern fn ImFontAtlas_AddFontFromFileTTF(self: [*c]ImFontAtlas, filename: [*c]const u8, size_pixels: f32, font_cfg: [*c]const ImFontConfig, glyph_ranges: [*c]const ImWchar) [*c]ImFont;
pub extern fn ImFontAtlas_AddFontFromMemoryTTF(self: [*c]ImFontAtlas, font_data: ?*anyopaque, font_size: c_int, size_pixels: f32, font_cfg: [*c]const ImFontConfig, glyph_ranges: [*c]const ImWchar) [*c]ImFont;
pub extern fn ImFontAtlas_AddFontFromMemoryCompressedTTF(self: [*c]ImFontAtlas, compressed_font_data: ?*const anyopaque, compressed_font_size: c_int, size_pixels: f32, font_cfg: [*c]const ImFontConfig, glyph_ranges: [*c]const ImWchar) [*c]ImFont;
pub extern fn ImFontAtlas_AddFontFromMemoryCompressedBase85TTF(self: [*c]ImFontAtlas, compressed_font_data_base85: [*c]const u8, size_pixels: f32, font_cfg: [*c]const ImFontConfig, glyph_ranges: [*c]const ImWchar) [*c]ImFont;
pub extern fn ImFontAtlas_ClearInputData(self: [*c]ImFontAtlas) void;
pub extern fn ImFontAtlas_ClearTexData(self: [*c]ImFontAtlas) void;
pub extern fn ImFontAtlas_ClearFonts(self: [*c]ImFontAtlas) void;
pub extern fn ImFontAtlas_Clear(self: [*c]ImFontAtlas) void;
pub extern fn ImFontAtlas_Build(self: [*c]ImFontAtlas) bool;
pub extern fn ImFontAtlas_GetTexDataAsAlpha8(self: [*c]ImFontAtlas, out_pixels: [*c][*c]u8, out_width: [*c]c_int, out_height: [*c]c_int, out_bytes_per_pixel: [*c]c_int) void;
pub extern fn ImFontAtlas_GetTexDataAsRGBA32(self: [*c]ImFontAtlas, out_pixels: [*c][*c]u8, out_width: [*c]c_int, out_height: [*c]c_int, out_bytes_per_pixel: [*c]c_int) void;
pub extern fn ImFontAtlas_IsBuilt(self: [*c]ImFontAtlas) bool;
pub extern fn ImFontAtlas_SetTexID(self: [*c]ImFontAtlas, id: ImTextureID) void;
pub extern fn ImFontAtlas_GetGlyphRangesDefault(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesKorean(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesJapanese(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesChineseFull(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesChineseSimplifiedCommon(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesCyrillic(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesThai(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_GetGlyphRangesVietnamese(self: [*c]ImFontAtlas) [*c]const ImWchar;
pub extern fn ImFontAtlas_AddCustomRectRegular(self: [*c]ImFontAtlas, width: c_int, height: c_int) c_int;
pub extern fn ImFontAtlas_AddCustomRectFontGlyph(self: [*c]ImFontAtlas, font: [*c]ImFont, id: ImWchar, width: c_int, height: c_int, advance_x: f32, offset: ImVec2) c_int;
pub extern fn ImFontAtlas_GetCustomRectByIndex(self: [*c]ImFontAtlas, index: c_int) [*c]ImFontAtlasCustomRect;
pub extern fn ImFontAtlas_CalcCustomRectUV(self: [*c]ImFontAtlas, rect: [*c]const ImFontAtlasCustomRect, out_uv_min: [*c]ImVec2, out_uv_max: [*c]ImVec2) void;
pub extern fn ImFontAtlas_GetMouseCursorTexData(self: [*c]ImFontAtlas, cursor: ImGuiMouseCursor, out_offset: [*c]ImVec2, out_size: [*c]ImVec2, out_uv_border: [*c]ImVec2, out_uv_fill: [*c]ImVec2) bool;
pub extern fn ImFont_ImFont() [*c]ImFont;
pub extern fn ImFont_destroy(self: [*c]ImFont) void;
pub extern fn ImFont_FindGlyph(self: [*c]ImFont, c: ImWchar) ?*const ImFontGlyph;
pub extern fn ImFont_FindGlyphNoFallback(self: [*c]ImFont, c: ImWchar) ?*const ImFontGlyph;
pub extern fn ImFont_GetCharAdvance(self: [*c]ImFont, c: ImWchar) f32;
pub extern fn ImFont_IsLoaded(self: [*c]ImFont) bool;
pub extern fn ImFont_GetDebugName(self: [*c]ImFont) [*c]const u8;
pub extern fn ImFont_CalcTextSizeA(pOut: [*c]ImVec2, self: [*c]ImFont, size: f32, max_width: f32, wrap_width: f32, text_begin: [*c]const u8, text_end: [*c]const u8, remaining: [*c][*c]const u8) void;
pub extern fn ImFont_CalcWordWrapPositionA(self: [*c]ImFont, scale: f32, text: [*c]const u8, text_end: [*c]const u8, wrap_width: f32) [*c]const u8;
pub extern fn ImFont_RenderChar(self: [*c]ImFont, draw_list: [*c]ImDrawList, size: f32, pos: ImVec2, col: ImU32, c: ImWchar) void;
pub extern fn ImFont_RenderText(self: [*c]ImFont, draw_list: [*c]ImDrawList, size: f32, pos: ImVec2, col: ImU32, clip_rect: ImVec4, text_begin: [*c]const u8, text_end: [*c]const u8, wrap_width: f32, cpu_fine_clip: bool) void;
pub extern fn ImFont_BuildLookupTable(self: [*c]ImFont) void;
pub extern fn ImFont_ClearOutputData(self: [*c]ImFont) void;
pub extern fn ImFont_GrowIndex(self: [*c]ImFont, new_size: c_int) void;
pub extern fn ImFont_AddGlyph(self: [*c]ImFont, src_cfg: [*c]const ImFontConfig, c: ImWchar, x0: f32, y0: f32, x1: f32, y1: f32, @"u0": f32, v0: f32, @"u1": f32, v1: f32, advance_x: f32) void;
pub extern fn ImFont_AddRemapChar(self: [*c]ImFont, dst: ImWchar, src: ImWchar, overwrite_dst: bool) void;
pub extern fn ImFont_SetGlyphVisible(self: [*c]ImFont, c: ImWchar, visible: bool) void;
pub extern fn ImFont_IsGlyphRangeUnused(self: [*c]ImFont, c_begin: c_uint, c_last: c_uint) bool;
pub extern fn ImGuiViewport_ImGuiViewport() [*c]ImGuiViewport;
pub extern fn ImGuiViewport_destroy(self: [*c]ImGuiViewport) void;
pub extern fn ImGuiViewport_GetCenter(pOut: [*c]ImVec2, self: [*c]ImGuiViewport) void;
pub extern fn ImGuiViewport_GetWorkCenter(pOut: [*c]ImVec2, self: [*c]ImGuiViewport) void;
pub extern fn ImGuiPlatformIO_ImGuiPlatformIO() [*c]ImGuiPlatformIO;
pub extern fn ImGuiPlatformIO_destroy(self: [*c]ImGuiPlatformIO) void;
pub extern fn ImGuiPlatformMonitor_ImGuiPlatformMonitor() [*c]ImGuiPlatformMonitor;
pub extern fn ImGuiPlatformMonitor_destroy(self: [*c]ImGuiPlatformMonitor) void;
pub extern fn ImGuiPlatformImeData_ImGuiPlatformImeData() [*c]ImGuiPlatformImeData;
pub extern fn ImGuiPlatformImeData_destroy(self: [*c]ImGuiPlatformImeData) void;
pub extern fn igGetKeyIndex(key: ImGuiKey) c_int;
pub extern fn igImHashData(data: ?*const anyopaque, data_size: usize, seed: ImU32) ImGuiID;
pub extern fn igImHashStr(data: [*c]const u8, data_size: usize, seed: ImU32) ImGuiID;
pub extern fn igImQsort(base: ?*anyopaque, count: usize, size_of_element: usize, compare_func: ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.C) c_int) void;
pub extern fn igImAlphaBlendColors(col_a: ImU32, col_b: ImU32) ImU32;
pub extern fn igImIsPowerOfTwo_Int(v: c_int) bool;
pub extern fn igImIsPowerOfTwo_U64(v: ImU64) bool;
pub extern fn igImUpperPowerOfTwo(v: c_int) c_int;
pub extern fn igImStricmp(str1: [*c]const u8, str2: [*c]const u8) c_int;
pub extern fn igImStrnicmp(str1: [*c]const u8, str2: [*c]const u8, count: usize) c_int;
pub extern fn igImStrncpy(dst: [*c]u8, src: [*c]const u8, count: usize) void;
pub extern fn igImStrdup(str: [*c]const u8) [*c]u8;
pub extern fn igImStrdupcpy(dst: [*c]u8, p_dst_size: [*c]usize, str: [*c]const u8) [*c]u8;
pub extern fn igImStrchrRange(str_begin: [*c]const u8, str_end: [*c]const u8, c: u8) [*c]const u8;
pub extern fn igImStrlenW(str: [*c]const ImWchar) c_int;
pub extern fn igImStreolRange(str: [*c]const u8, str_end: [*c]const u8) [*c]const u8;
pub extern fn igImStrbolW(buf_mid_line: [*c]const ImWchar, buf_begin: [*c]const ImWchar) [*c]const ImWchar;
pub extern fn igImStristr(haystack: [*c]const u8, haystack_end: [*c]const u8, needle: [*c]const u8, needle_end: [*c]const u8) [*c]const u8;
pub extern fn igImStrTrimBlanks(str: [*c]u8) void;
pub extern fn igImStrSkipBlank(str: [*c]const u8) [*c]const u8;
pub extern fn igImCharIsBlankA(c: u8) bool;
pub extern fn igImCharIsBlankW(c: c_uint) bool;
pub extern fn igImFormatString(buf: [*c]u8, buf_size: usize, fmt: [*c]const u8, ...) c_int;
pub extern fn igImFormatStringV(buf: [*c]u8, buf_size: usize, fmt: [*c]const u8, args: va_list) c_int;
pub extern fn igImFormatStringToTempBuffer(out_buf: [*c][*c]const u8, out_buf_end: [*c][*c]const u8, fmt: [*c]const u8, ...) void;
pub extern fn igImFormatStringToTempBufferV(out_buf: [*c][*c]const u8, out_buf_end: [*c][*c]const u8, fmt: [*c]const u8, args: va_list) void;
pub extern fn igImParseFormatFindStart(format: [*c]const u8) [*c]const u8;
pub extern fn igImParseFormatFindEnd(format: [*c]const u8) [*c]const u8;
pub extern fn igImParseFormatTrimDecorations(format: [*c]const u8, buf: [*c]u8, buf_size: usize) [*c]const u8;
pub extern fn igImParseFormatSanitizeForPrinting(fmt_in: [*c]const u8, fmt_out: [*c]u8, fmt_out_size: usize) void;
pub extern fn igImParseFormatSanitizeForScanning(fmt_in: [*c]const u8, fmt_out: [*c]u8, fmt_out_size: usize) [*c]const u8;
pub extern fn igImParseFormatPrecision(format: [*c]const u8, default_value: c_int) c_int;
pub extern fn igImTextCharToUtf8(out_buf: [*c]u8, c: c_uint) [*c]const u8;
pub extern fn igImTextStrToUtf8(out_buf: [*c]u8, out_buf_size: c_int, in_text: [*c]const ImWchar, in_text_end: [*c]const ImWchar) c_int;
pub extern fn igImTextCharFromUtf8(out_char: [*c]c_uint, in_text: [*c]const u8, in_text_end: [*c]const u8) c_int;
pub extern fn igImTextStrFromUtf8(out_buf: [*c]ImWchar, out_buf_size: c_int, in_text: [*c]const u8, in_text_end: [*c]const u8, in_remaining: [*c][*c]const u8) c_int;
pub extern fn igImTextCountCharsFromUtf8(in_text: [*c]const u8, in_text_end: [*c]const u8) c_int;
pub extern fn igImTextCountUtf8BytesFromChar(in_text: [*c]const u8, in_text_end: [*c]const u8) c_int;
pub extern fn igImTextCountUtf8BytesFromStr(in_text: [*c]const ImWchar, in_text_end: [*c]const ImWchar) c_int;
pub extern fn igImFileLoadToMemory(filename: [*c]const u8, mode: [*c]const u8, out_file_size: [*c]usize, padding_bytes: c_int) ?*anyopaque;
pub extern fn igImPow_Float(x: f32, y: f32) f32;
pub extern fn igImPow_double(x: f64, y: f64) f64;
pub extern fn igImLog_Float(x: f32) f32;
pub extern fn igImLog_double(x: f64) f64;
pub extern fn igImAbs_Int(x: c_int) c_int;
pub extern fn igImAbs_Float(x: f32) f32;
pub extern fn igImAbs_double(x: f64) f64;
pub extern fn igImSign_Float(x: f32) f32;
pub extern fn igImSign_double(x: f64) f64;
pub extern fn igImRsqrt_Float(x: f32) f32;
pub extern fn igImRsqrt_double(x: f64) f64;
pub extern fn igImMin(pOut: [*c]ImVec2, lhs: ImVec2, rhs: ImVec2) void;
pub extern fn igImMax(pOut: [*c]ImVec2, lhs: ImVec2, rhs: ImVec2) void;
pub extern fn igImClamp(pOut: [*c]ImVec2, v: ImVec2, mn: ImVec2, mx: ImVec2) void;
pub extern fn igImLerp_Vec2Float(pOut: [*c]ImVec2, a: ImVec2, b: ImVec2, t: f32) void;
pub extern fn igImLerp_Vec2Vec2(pOut: [*c]ImVec2, a: ImVec2, b: ImVec2, t: ImVec2) void;
pub extern fn igImLerp_Vec4(pOut: [*c]ImVec4, a: ImVec4, b: ImVec4, t: f32) void;
pub extern fn igImSaturate(f: f32) f32;
pub extern fn igImLengthSqr_Vec2(lhs: ImVec2) f32;
pub extern fn igImLengthSqr_Vec4(lhs: ImVec4) f32;
pub extern fn igImInvLength(lhs: ImVec2, fail_value: f32) f32;
pub extern fn igImFloor_Float(f: f32) f32;
pub extern fn igImFloorSigned_Float(f: f32) f32;
pub extern fn igImFloor_Vec2(pOut: [*c]ImVec2, v: ImVec2) void;
pub extern fn igImFloorSigned_Vec2(pOut: [*c]ImVec2, v: ImVec2) void;
pub extern fn igImModPositive(a: c_int, b: c_int) c_int;
pub extern fn igImDot(a: ImVec2, b: ImVec2) f32;
pub extern fn igImRotate(pOut: [*c]ImVec2, v: ImVec2, cos_a: f32, sin_a: f32) void;
pub extern fn igImLinearSweep(current: f32, target: f32, speed: f32) f32;
pub extern fn igImMul(pOut: [*c]ImVec2, lhs: ImVec2, rhs: ImVec2) void;
pub extern fn igImIsFloatAboveGuaranteedIntegerPrecision(f: f32) bool;
pub extern fn igImBezierCubicCalc(pOut: [*c]ImVec2, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, t: f32) void;
pub extern fn igImBezierCubicClosestPoint(pOut: [*c]ImVec2, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, p: ImVec2, num_segments: c_int) void;
pub extern fn igImBezierCubicClosestPointCasteljau(pOut: [*c]ImVec2, p1: ImVec2, p2: ImVec2, p3: ImVec2, p4: ImVec2, p: ImVec2, tess_tol: f32) void;
pub extern fn igImBezierQuadraticCalc(pOut: [*c]ImVec2, p1: ImVec2, p2: ImVec2, p3: ImVec2, t: f32) void;
pub extern fn igImLineClosestPoint(pOut: [*c]ImVec2, a: ImVec2, b: ImVec2, p: ImVec2) void;
pub extern fn igImTriangleContainsPoint(a: ImVec2, b: ImVec2, c: ImVec2, p: ImVec2) bool;
pub extern fn igImTriangleClosestPoint(pOut: [*c]ImVec2, a: ImVec2, b: ImVec2, c: ImVec2, p: ImVec2) void;
pub extern fn igImTriangleBarycentricCoords(a: ImVec2, b: ImVec2, c: ImVec2, p: ImVec2, out_u: [*c]f32, out_v: [*c]f32, out_w: [*c]f32) void;
pub extern fn igImTriangleArea(a: ImVec2, b: ImVec2, c: ImVec2) f32;
pub extern fn igImGetDirQuadrantFromDelta(dx: f32, dy: f32) ImGuiDir;
pub extern fn ImVec1_ImVec1_Nil() [*c]ImVec1;
pub extern fn ImVec1_destroy(self: [*c]ImVec1) void;
pub extern fn ImVec1_ImVec1_Float(_x: f32) [*c]ImVec1;
pub extern fn ImVec2ih_ImVec2ih_Nil() [*c]ImVec2ih;
pub extern fn ImVec2ih_destroy(self: [*c]ImVec2ih) void;
pub extern fn ImVec2ih_ImVec2ih_short(_x: c_short, _y: c_short) [*c]ImVec2ih;
pub extern fn ImVec2ih_ImVec2ih_Vec2(rhs: ImVec2) [*c]ImVec2ih;
pub extern fn ImRect_ImRect_Nil() [*c]ImRect;
pub extern fn ImRect_destroy(self: [*c]ImRect) void;
pub extern fn ImRect_ImRect_Vec2(min: ImVec2, max: ImVec2) [*c]ImRect;
pub extern fn ImRect_ImRect_Vec4(v: ImVec4) [*c]ImRect;
pub extern fn ImRect_ImRect_Float(x1: f32, y1: f32, x2: f32, y2: f32) [*c]ImRect;
pub extern fn ImRect_GetCenter(pOut: [*c]ImVec2, self: [*c]ImRect) void;
pub extern fn ImRect_GetSize(pOut: [*c]ImVec2, self: [*c]ImRect) void;
pub extern fn ImRect_GetWidth(self: [*c]ImRect) f32;
pub extern fn ImRect_GetHeight(self: [*c]ImRect) f32;
pub extern fn ImRect_GetArea(self: [*c]ImRect) f32;
pub extern fn ImRect_GetTL(pOut: [*c]ImVec2, self: [*c]ImRect) void;
pub extern fn ImRect_GetTR(pOut: [*c]ImVec2, self: [*c]ImRect) void;
pub extern fn ImRect_GetBL(pOut: [*c]ImVec2, self: [*c]ImRect) void;
pub extern fn ImRect_GetBR(pOut: [*c]ImVec2, self: [*c]ImRect) void;
pub extern fn ImRect_Contains_Vec2(self: [*c]ImRect, p: ImVec2) bool;
pub extern fn ImRect_Contains_Rect(self: [*c]ImRect, r: ImRect) bool;
pub extern fn ImRect_Overlaps(self: [*c]ImRect, r: ImRect) bool;
pub extern fn ImRect_Add_Vec2(self: [*c]ImRect, p: ImVec2) void;
pub extern fn ImRect_Add_Rect(self: [*c]ImRect, r: ImRect) void;
pub extern fn ImRect_Expand_Float(self: [*c]ImRect, amount: f32) void;
pub extern fn ImRect_Expand_Vec2(self: [*c]ImRect, amount: ImVec2) void;
pub extern fn ImRect_Translate(self: [*c]ImRect, d: ImVec2) void;
pub extern fn ImRect_TranslateX(self: [*c]ImRect, dx: f32) void;
pub extern fn ImRect_TranslateY(self: [*c]ImRect, dy: f32) void;
pub extern fn ImRect_ClipWith(self: [*c]ImRect, r: ImRect) void;
pub extern fn ImRect_ClipWithFull(self: [*c]ImRect, r: ImRect) void;
pub extern fn ImRect_Floor(self: [*c]ImRect) void;
pub extern fn ImRect_IsInverted(self: [*c]ImRect) bool;
pub extern fn ImRect_ToVec4(pOut: [*c]ImVec4, self: [*c]ImRect) void;
pub extern fn igImBitArrayTestBit(arr: [*c]const ImU32, n: c_int) bool;
pub extern fn igImBitArrayClearBit(arr: [*c]ImU32, n: c_int) void;
pub extern fn igImBitArraySetBit(arr: [*c]ImU32, n: c_int) void;
pub extern fn igImBitArraySetBitRange(arr: [*c]ImU32, n: c_int, n2: c_int) void;
pub extern fn ImBitVector_Create(self: [*c]ImBitVector, sz: c_int) void;
pub extern fn ImBitVector_Clear(self: [*c]ImBitVector) void;
pub extern fn ImBitVector_TestBit(self: [*c]ImBitVector, n: c_int) bool;
pub extern fn ImBitVector_SetBit(self: [*c]ImBitVector, n: c_int) void;
pub extern fn ImBitVector_ClearBit(self: [*c]ImBitVector, n: c_int) void;
pub extern fn ImDrawListSharedData_ImDrawListSharedData() [*c]ImDrawListSharedData;
pub extern fn ImDrawListSharedData_destroy(self: [*c]ImDrawListSharedData) void;
pub extern fn ImDrawListSharedData_SetCircleTessellationMaxError(self: [*c]ImDrawListSharedData, max_error: f32) void;
pub extern fn ImDrawDataBuilder_Clear(self: [*c]ImDrawDataBuilder) void;
pub extern fn ImDrawDataBuilder_ClearFreeMemory(self: [*c]ImDrawDataBuilder) void;
pub extern fn ImDrawDataBuilder_GetDrawListCount(self: [*c]ImDrawDataBuilder) c_int;
pub extern fn ImDrawDataBuilder_FlattenIntoSingleLayer(self: [*c]ImDrawDataBuilder) void;
pub extern fn ImGuiStyleMod_ImGuiStyleMod_Int(idx: ImGuiStyleVar, v: c_int) [*c]ImGuiStyleMod;
pub extern fn ImGuiStyleMod_destroy(self: [*c]ImGuiStyleMod) void;
pub extern fn ImGuiStyleMod_ImGuiStyleMod_Float(idx: ImGuiStyleVar, v: f32) [*c]ImGuiStyleMod;
pub extern fn ImGuiStyleMod_ImGuiStyleMod_Vec2(idx: ImGuiStyleVar, v: ImVec2) [*c]ImGuiStyleMod;
pub extern fn ImGuiComboPreviewData_ImGuiComboPreviewData() [*c]ImGuiComboPreviewData;
pub extern fn ImGuiComboPreviewData_destroy(self: [*c]ImGuiComboPreviewData) void;
pub extern fn ImGuiMenuColumns_ImGuiMenuColumns() [*c]ImGuiMenuColumns;
pub extern fn ImGuiMenuColumns_destroy(self: [*c]ImGuiMenuColumns) void;
pub extern fn ImGuiMenuColumns_Update(self: [*c]ImGuiMenuColumns, spacing: f32, window_reappearing: bool) void;
pub extern fn ImGuiMenuColumns_DeclColumns(self: [*c]ImGuiMenuColumns, w_icon: f32, w_label: f32, w_shortcut: f32, w_mark: f32) f32;
pub extern fn ImGuiMenuColumns_CalcNextTotalWidth(self: [*c]ImGuiMenuColumns, update_offsets: bool) void;
pub extern fn ImGuiInputTextState_ImGuiInputTextState() [*c]ImGuiInputTextState;
pub extern fn ImGuiInputTextState_destroy(self: [*c]ImGuiInputTextState) void;
pub extern fn ImGuiInputTextState_ClearText(self: [*c]ImGuiInputTextState) void;
pub extern fn ImGuiInputTextState_ClearFreeMemory(self: [*c]ImGuiInputTextState) void;
pub extern fn ImGuiInputTextState_GetUndoAvailCount(self: [*c]ImGuiInputTextState) c_int;
pub extern fn ImGuiInputTextState_GetRedoAvailCount(self: [*c]ImGuiInputTextState) c_int;
pub extern fn ImGuiInputTextState_OnKeyPressed(self: [*c]ImGuiInputTextState, key: c_int) void;
pub extern fn ImGuiInputTextState_CursorAnimReset(self: [*c]ImGuiInputTextState) void;
pub extern fn ImGuiInputTextState_CursorClamp(self: [*c]ImGuiInputTextState) void;
pub extern fn ImGuiInputTextState_HasSelection(self: [*c]ImGuiInputTextState) bool;
pub extern fn ImGuiInputTextState_ClearSelection(self: [*c]ImGuiInputTextState) void;
pub extern fn ImGuiInputTextState_GetCursorPos(self: [*c]ImGuiInputTextState) c_int;
pub extern fn ImGuiInputTextState_GetSelectionStart(self: [*c]ImGuiInputTextState) c_int;
pub extern fn ImGuiInputTextState_GetSelectionEnd(self: [*c]ImGuiInputTextState) c_int;
pub extern fn ImGuiInputTextState_SelectAll(self: [*c]ImGuiInputTextState) void;
pub extern fn ImGuiPopupData_ImGuiPopupData() [*c]ImGuiPopupData;
pub extern fn ImGuiPopupData_destroy(self: [*c]ImGuiPopupData) void;
pub extern fn ImGuiNextWindowData_ImGuiNextWindowData() [*c]ImGuiNextWindowData;
pub extern fn ImGuiNextWindowData_destroy(self: [*c]ImGuiNextWindowData) void;
pub extern fn ImGuiNextWindowData_ClearFlags(self: [*c]ImGuiNextWindowData) void;
pub extern fn ImGuiNextItemData_ImGuiNextItemData() [*c]ImGuiNextItemData;
pub extern fn ImGuiNextItemData_destroy(self: [*c]ImGuiNextItemData) void;
pub extern fn ImGuiNextItemData_ClearFlags(self: [*c]ImGuiNextItemData) void;
pub extern fn ImGuiLastItemData_ImGuiLastItemData() [*c]ImGuiLastItemData;
pub extern fn ImGuiLastItemData_destroy(self: [*c]ImGuiLastItemData) void;
pub extern fn ImGuiStackSizes_ImGuiStackSizes() [*c]ImGuiStackSizes;
pub extern fn ImGuiStackSizes_destroy(self: [*c]ImGuiStackSizes) void;
pub extern fn ImGuiStackSizes_SetToCurrentState(self: [*c]ImGuiStackSizes) void;
pub extern fn ImGuiStackSizes_CompareWithCurrentState(self: [*c]ImGuiStackSizes) void;
pub extern fn ImGuiPtrOrIndex_ImGuiPtrOrIndex_Ptr(ptr: ?*anyopaque) [*c]ImGuiPtrOrIndex;
pub extern fn ImGuiPtrOrIndex_destroy(self: [*c]ImGuiPtrOrIndex) void;
pub extern fn ImGuiPtrOrIndex_ImGuiPtrOrIndex_Int(index: c_int) [*c]ImGuiPtrOrIndex;
pub extern fn ImGuiInputEvent_ImGuiInputEvent() [*c]ImGuiInputEvent;
pub extern fn ImGuiInputEvent_destroy(self: [*c]ImGuiInputEvent) void;
pub extern fn ImGuiListClipperRange_FromIndices(min: c_int, max: c_int) ImGuiListClipperRange;
pub extern fn ImGuiListClipperRange_FromPositions(y1: f32, y2: f32, off_min: c_int, off_max: c_int) ImGuiListClipperRange;
pub extern fn ImGuiListClipperData_ImGuiListClipperData() [*c]ImGuiListClipperData;
pub extern fn ImGuiListClipperData_destroy(self: [*c]ImGuiListClipperData) void;
pub extern fn ImGuiListClipperData_Reset(self: [*c]ImGuiListClipperData, clipper: [*c]ImGuiListClipper) void;
pub extern fn ImGuiNavItemData_ImGuiNavItemData() [*c]ImGuiNavItemData;
pub extern fn ImGuiNavItemData_destroy(self: [*c]ImGuiNavItemData) void;
pub extern fn ImGuiNavItemData_Clear(self: [*c]ImGuiNavItemData) void;
pub extern fn ImGuiOldColumnData_ImGuiOldColumnData() [*c]ImGuiOldColumnData;
pub extern fn ImGuiOldColumnData_destroy(self: [*c]ImGuiOldColumnData) void;
pub extern fn ImGuiOldColumns_ImGuiOldColumns() [*c]ImGuiOldColumns;
pub extern fn ImGuiOldColumns_destroy(self: [*c]ImGuiOldColumns) void;
pub extern fn ImGuiDockNode_ImGuiDockNode(id: ImGuiID) ?*ImGuiDockNode;
pub extern fn ImGuiDockNode_destroy(self: ?*ImGuiDockNode) void;
pub extern fn ImGuiDockNode_IsRootNode(self: ?*ImGuiDockNode) bool;
pub extern fn ImGuiDockNode_IsDockSpace(self: ?*ImGuiDockNode) bool;
pub extern fn ImGuiDockNode_IsFloatingNode(self: ?*ImGuiDockNode) bool;
pub extern fn ImGuiDockNode_IsCentralNode(self: ?*ImGuiDockNode) bool;
pub extern fn ImGuiDockNode_IsHiddenTabBar(self: ?*ImGuiDockNode) bool;
pub extern fn ImGuiDockNode_IsNoTabBar(self: ?*ImGuiDockNode) bool;
pub extern fn ImGuiDockNode_IsSplitNode(self: ?*ImGuiDockNode) bool;
pub extern fn ImGuiDockNode_IsLeafNode(self: ?*ImGuiDockNode) bool;
pub extern fn ImGuiDockNode_IsEmpty(self: ?*ImGuiDockNode) bool;
pub extern fn ImGuiDockNode_Rect(pOut: [*c]ImRect, self: ?*ImGuiDockNode) void;
pub extern fn ImGuiDockNode_SetLocalFlags(self: ?*ImGuiDockNode, flags: ImGuiDockNodeFlags) void;
pub extern fn ImGuiDockNode_UpdateMergedFlags(self: ?*ImGuiDockNode) void;
pub extern fn ImGuiDockContext_ImGuiDockContext() [*c]ImGuiDockContext;
pub extern fn ImGuiDockContext_destroy(self: [*c]ImGuiDockContext) void;
pub extern fn ImGuiViewportP_ImGuiViewportP() [*c]ImGuiViewportP;
pub extern fn ImGuiViewportP_destroy(self: [*c]ImGuiViewportP) void;
pub extern fn ImGuiViewportP_ClearRequestFlags(self: [*c]ImGuiViewportP) void;
pub extern fn ImGuiViewportP_CalcWorkRectPos(pOut: [*c]ImVec2, self: [*c]ImGuiViewportP, off_min: ImVec2) void;
pub extern fn ImGuiViewportP_CalcWorkRectSize(pOut: [*c]ImVec2, self: [*c]ImGuiViewportP, off_min: ImVec2, off_max: ImVec2) void;
pub extern fn ImGuiViewportP_UpdateWorkRect(self: [*c]ImGuiViewportP) void;
pub extern fn ImGuiViewportP_GetMainRect(pOut: [*c]ImRect, self: [*c]ImGuiViewportP) void;
pub extern fn ImGuiViewportP_GetWorkRect(pOut: [*c]ImRect, self: [*c]ImGuiViewportP) void;
pub extern fn ImGuiViewportP_GetBuildWorkRect(pOut: [*c]ImRect, self: [*c]ImGuiViewportP) void;
pub extern fn ImGuiWindowSettings_ImGuiWindowSettings() [*c]ImGuiWindowSettings;
pub extern fn ImGuiWindowSettings_destroy(self: [*c]ImGuiWindowSettings) void;
pub extern fn ImGuiWindowSettings_GetName(self: [*c]ImGuiWindowSettings) [*c]u8;
pub extern fn ImGuiSettingsHandler_ImGuiSettingsHandler() [*c]ImGuiSettingsHandler;
pub extern fn ImGuiSettingsHandler_destroy(self: [*c]ImGuiSettingsHandler) void;
pub extern fn ImGuiMetricsConfig_ImGuiMetricsConfig() [*c]ImGuiMetricsConfig;
pub extern fn ImGuiMetricsConfig_destroy(self: [*c]ImGuiMetricsConfig) void;
pub extern fn ImGuiStackLevelInfo_ImGuiStackLevelInfo() ?*ImGuiStackLevelInfo;
pub extern fn ImGuiStackLevelInfo_destroy(self: ?*ImGuiStackLevelInfo) void;
pub extern fn ImGuiStackTool_ImGuiStackTool() [*c]ImGuiStackTool;
pub extern fn ImGuiStackTool_destroy(self: [*c]ImGuiStackTool) void;
pub extern fn ImGuiContextHook_ImGuiContextHook() [*c]ImGuiContextHook;
pub extern fn ImGuiContextHook_destroy(self: [*c]ImGuiContextHook) void;
pub extern fn ImGuiContext_ImGuiContext(shared_font_atlas: [*c]ImFontAtlas) [*c]ImGuiContext;
pub extern fn ImGuiContext_destroy(self: [*c]ImGuiContext) void;
pub extern fn ImGuiWindow_ImGuiWindow(context: [*c]ImGuiContext, name: [*c]const u8) ?*ImGuiWindow;
pub extern fn ImGuiWindow_destroy(self: ?*ImGuiWindow) void;
pub extern fn ImGuiWindow_GetID_Str(self: ?*ImGuiWindow, str: [*c]const u8, str_end: [*c]const u8) ImGuiID;
pub extern fn ImGuiWindow_GetID_Ptr(self: ?*ImGuiWindow, ptr: ?*const anyopaque) ImGuiID;
pub extern fn ImGuiWindow_GetID_Int(self: ?*ImGuiWindow, n: c_int) ImGuiID;
pub extern fn ImGuiWindow_GetIDFromRectangle(self: ?*ImGuiWindow, r_abs: ImRect) ImGuiID;
pub extern fn ImGuiWindow_Rect(pOut: [*c]ImRect, self: ?*ImGuiWindow) void;
pub extern fn ImGuiWindow_CalcFontSize(self: ?*ImGuiWindow) f32;
pub extern fn ImGuiWindow_TitleBarHeight(self: ?*ImGuiWindow) f32;
pub extern fn ImGuiWindow_TitleBarRect(pOut: [*c]ImRect, self: ?*ImGuiWindow) void;
pub extern fn ImGuiWindow_MenuBarHeight(self: ?*ImGuiWindow) f32;
pub extern fn ImGuiWindow_MenuBarRect(pOut: [*c]ImRect, self: ?*ImGuiWindow) void;
pub extern fn ImGuiTabItem_ImGuiTabItem() [*c]ImGuiTabItem;
pub extern fn ImGuiTabItem_destroy(self: [*c]ImGuiTabItem) void;
pub extern fn ImGuiTabBar_ImGuiTabBar() [*c]ImGuiTabBar;
pub extern fn ImGuiTabBar_destroy(self: [*c]ImGuiTabBar) void;
pub extern fn ImGuiTabBar_GetTabOrder(self: [*c]ImGuiTabBar, tab: [*c]const ImGuiTabItem) c_int;
pub extern fn ImGuiTabBar_GetTabName(self: [*c]ImGuiTabBar, tab: [*c]const ImGuiTabItem) [*c]const u8;
pub extern fn ImGuiTableColumn_ImGuiTableColumn() ?*ImGuiTableColumn;
pub extern fn ImGuiTableColumn_destroy(self: ?*ImGuiTableColumn) void;
pub extern fn ImGuiTableInstanceData_ImGuiTableInstanceData() [*c]ImGuiTableInstanceData;
pub extern fn ImGuiTableInstanceData_destroy(self: [*c]ImGuiTableInstanceData) void;
pub extern fn ImGuiTable_ImGuiTable() ?*ImGuiTable;
pub extern fn ImGuiTable_destroy(self: ?*ImGuiTable) void;
pub extern fn ImGuiTableTempData_ImGuiTableTempData() [*c]ImGuiTableTempData;
pub extern fn ImGuiTableTempData_destroy(self: [*c]ImGuiTableTempData) void;
pub extern fn ImGuiTableColumnSettings_ImGuiTableColumnSettings() ?*ImGuiTableColumnSettings;
pub extern fn ImGuiTableColumnSettings_destroy(self: ?*ImGuiTableColumnSettings) void;
pub extern fn ImGuiTableSettings_ImGuiTableSettings() [*c]ImGuiTableSettings;
pub extern fn ImGuiTableSettings_destroy(self: [*c]ImGuiTableSettings) void;
pub extern fn ImGuiTableSettings_GetColumnSettings(self: [*c]ImGuiTableSettings) ?*ImGuiTableColumnSettings;
pub extern fn igGetCurrentWindowRead() ?*ImGuiWindow;
pub extern fn igGetCurrentWindow() ?*ImGuiWindow;
pub extern fn igFindWindowByID(id: ImGuiID) ?*ImGuiWindow;
pub extern fn igFindWindowByName(name: [*c]const u8) ?*ImGuiWindow;
pub extern fn igUpdateWindowParentAndRootLinks(window: ?*ImGuiWindow, flags: ImGuiWindowFlags, parent_window: ?*ImGuiWindow) void;
pub extern fn igCalcWindowNextAutoFitSize(pOut: [*c]ImVec2, window: ?*ImGuiWindow) void;
pub extern fn igIsWindowChildOf(window: ?*ImGuiWindow, potential_parent: ?*ImGuiWindow, popup_hierarchy: bool, dock_hierarchy: bool) bool;
pub extern fn igIsWindowWithinBeginStackOf(window: ?*ImGuiWindow, potential_parent: ?*ImGuiWindow) bool;
pub extern fn igIsWindowAbove(potential_above: ?*ImGuiWindow, potential_below: ?*ImGuiWindow) bool;
pub extern fn igIsWindowNavFocusable(window: ?*ImGuiWindow) bool;
pub extern fn igSetWindowPos_WindowPtr(window: ?*ImGuiWindow, pos: ImVec2, cond: ImGuiCond) void;
pub extern fn igSetWindowSize_WindowPtr(window: ?*ImGuiWindow, size: ImVec2, cond: ImGuiCond) void;
pub extern fn igSetWindowCollapsed_WindowPtr(window: ?*ImGuiWindow, collapsed: bool, cond: ImGuiCond) void;
pub extern fn igSetWindowHitTestHole(window: ?*ImGuiWindow, pos: ImVec2, size: ImVec2) void;
pub extern fn igWindowRectAbsToRel(pOut: [*c]ImRect, window: ?*ImGuiWindow, r: ImRect) void;
pub extern fn igWindowRectRelToAbs(pOut: [*c]ImRect, window: ?*ImGuiWindow, r: ImRect) void;
pub extern fn igFocusWindow(window: ?*ImGuiWindow) void;
pub extern fn igFocusTopMostWindowUnderOne(under_this_window: ?*ImGuiWindow, ignore_window: ?*ImGuiWindow) void;
pub extern fn igBringWindowToFocusFront(window: ?*ImGuiWindow) void;
pub extern fn igBringWindowToDisplayFront(window: ?*ImGuiWindow) void;
pub extern fn igBringWindowToDisplayBack(window: ?*ImGuiWindow) void;
pub extern fn igBringWindowToDisplayBehind(window: ?*ImGuiWindow, above_window: ?*ImGuiWindow) void;
pub extern fn igFindWindowDisplayIndex(window: ?*ImGuiWindow) c_int;
pub extern fn igFindBottomMostVisibleWindowWithinBeginStack(window: ?*ImGuiWindow) ?*ImGuiWindow;
pub extern fn igSetCurrentFont(font: [*c]ImFont) void;
pub extern fn igGetDefaultFont() [*c]ImFont;
pub extern fn igGetForegroundDrawList_WindowPtr(window: ?*ImGuiWindow) [*c]ImDrawList;
pub extern fn igInitialize() void;
pub extern fn igShutdown() void;
pub extern fn igUpdateInputEvents(trickle_fast_inputs: bool) void;
pub extern fn igUpdateHoveredWindowAndCaptureFlags() void;
pub extern fn igStartMouseMovingWindow(window: ?*ImGuiWindow) void;
pub extern fn igStartMouseMovingWindowOrNode(window: ?*ImGuiWindow, node: ?*ImGuiDockNode, undock_floating_node: bool) void;
pub extern fn igUpdateMouseMovingWindowNewFrame() void;
pub extern fn igUpdateMouseMovingWindowEndFrame() void;
pub extern fn igAddContextHook(context: [*c]ImGuiContext, hook: [*c]const ImGuiContextHook) ImGuiID;
pub extern fn igRemoveContextHook(context: [*c]ImGuiContext, hook_to_remove: ImGuiID) void;
pub extern fn igCallContextHooks(context: [*c]ImGuiContext, @"type": ImGuiContextHookType) void;
pub extern fn igTranslateWindowsInViewport(viewport: [*c]ImGuiViewportP, old_pos: ImVec2, new_pos: ImVec2) void;
pub extern fn igScaleWindowsInViewport(viewport: [*c]ImGuiViewportP, scale: f32) void;
pub extern fn igDestroyPlatformWindow(viewport: [*c]ImGuiViewportP) void;
pub extern fn igSetWindowViewport(window: ?*ImGuiWindow, viewport: [*c]ImGuiViewportP) void;
pub extern fn igSetCurrentViewport(window: ?*ImGuiWindow, viewport: [*c]ImGuiViewportP) void;
pub extern fn igGetViewportPlatformMonitor(viewport: [*c]ImGuiViewport) [*c]const ImGuiPlatformMonitor;
pub extern fn igFindHoveredViewportFromPlatformWindowStack(mouse_platform_pos: ImVec2) [*c]ImGuiViewportP;
pub extern fn igMarkIniSettingsDirty_Nil() void;
pub extern fn igMarkIniSettingsDirty_WindowPtr(window: ?*ImGuiWindow) void;
pub extern fn igClearIniSettings() void;
pub extern fn igCreateNewWindowSettings(name: [*c]const u8) [*c]ImGuiWindowSettings;
pub extern fn igFindWindowSettings(id: ImGuiID) [*c]ImGuiWindowSettings;
pub extern fn igFindOrCreateWindowSettings(name: [*c]const u8) [*c]ImGuiWindowSettings;
pub extern fn igAddSettingsHandler(handler: [*c]const ImGuiSettingsHandler) void;
pub extern fn igRemoveSettingsHandler(type_name: [*c]const u8) void;
pub extern fn igFindSettingsHandler(type_name: [*c]const u8) [*c]ImGuiSettingsHandler;
pub extern fn igSetNextWindowScroll(scroll: ImVec2) void;
pub extern fn igSetScrollX_WindowPtr(window: ?*ImGuiWindow, scroll_x: f32) void;
pub extern fn igSetScrollY_WindowPtr(window: ?*ImGuiWindow, scroll_y: f32) void;
pub extern fn igSetScrollFromPosX_WindowPtr(window: ?*ImGuiWindow, local_x: f32, center_x_ratio: f32) void;
pub extern fn igSetScrollFromPosY_WindowPtr(window: ?*ImGuiWindow, local_y: f32, center_y_ratio: f32) void;
pub extern fn igScrollToItem(flags: ImGuiScrollFlags) void;
pub extern fn igScrollToRect(window: ?*ImGuiWindow, rect: ImRect, flags: ImGuiScrollFlags) void;
pub extern fn igScrollToRectEx(pOut: [*c]ImVec2, window: ?*ImGuiWindow, rect: ImRect, flags: ImGuiScrollFlags) void;
pub extern fn igScrollToBringRectIntoView(window: ?*ImGuiWindow, rect: ImRect) void;
pub extern fn igGetItemID() ImGuiID;
pub extern fn igGetItemStatusFlags() ImGuiItemStatusFlags;
pub extern fn igGetItemFlags() ImGuiItemFlags;
pub extern fn igGetActiveID() ImGuiID;
pub extern fn igGetFocusID() ImGuiID;
pub extern fn igSetActiveID(id: ImGuiID, window: ?*ImGuiWindow) void;
pub extern fn igSetFocusID(id: ImGuiID, window: ?*ImGuiWindow) void;
pub extern fn igClearActiveID() void;
pub extern fn igGetHoveredID() ImGuiID;
pub extern fn igSetHoveredID(id: ImGuiID) void;
pub extern fn igKeepAliveID(id: ImGuiID) void;
pub extern fn igMarkItemEdited(id: ImGuiID) void;
pub extern fn igPushOverrideID(id: ImGuiID) void;
pub extern fn igGetIDWithSeed(str_id_begin: [*c]const u8, str_id_end: [*c]const u8, seed: ImGuiID) ImGuiID;
pub extern fn igItemSize_Vec2(size: ImVec2, text_baseline_y: f32) void;
pub extern fn igItemSize_Rect(bb: ImRect, text_baseline_y: f32) void;
pub extern fn igItemAdd(bb: ImRect, id: ImGuiID, nav_bb: [*c]const ImRect, extra_flags: ImGuiItemFlags) bool;
pub extern fn igItemHoverable(bb: ImRect, id: ImGuiID) bool;
pub extern fn igIsClippedEx(bb: ImRect, id: ImGuiID) bool;
pub extern fn igSetLastItemData(item_id: ImGuiID, in_flags: ImGuiItemFlags, status_flags: ImGuiItemStatusFlags, item_rect: ImRect) void;
pub extern fn igCalcItemSize(pOut: [*c]ImVec2, size: ImVec2, default_w: f32, default_h: f32) void;
pub extern fn igCalcWrapWidthForPos(pos: ImVec2, wrap_pos_x: f32) f32;
pub extern fn igPushMultiItemsWidths(components: c_int, width_full: f32) void;
pub extern fn igIsItemToggledSelection() bool;
pub extern fn igGetContentRegionMaxAbs(pOut: [*c]ImVec2) void;
pub extern fn igShrinkWidths(items: [*c]ImGuiShrinkWidthItem, count: c_int, width_excess: f32) void;
pub extern fn igPushItemFlag(option: ImGuiItemFlags, enabled: bool) void;
pub extern fn igPopItemFlag() void;
pub extern fn igLogBegin(@"type": ImGuiLogType, auto_open_depth: c_int) void;
pub extern fn igLogToBuffer(auto_open_depth: c_int) void;
pub extern fn igLogRenderedText(ref_pos: [*c]const ImVec2, text: [*c]const u8, text_end: [*c]const u8) void;
pub extern fn igLogSetNextTextDecoration(prefix: [*c]const u8, suffix: [*c]const u8) void;
pub extern fn igBeginChildEx(name: [*c]const u8, id: ImGuiID, size_arg: ImVec2, border: bool, flags: ImGuiWindowFlags) bool;
pub extern fn igOpenPopupEx(id: ImGuiID, popup_flags: ImGuiPopupFlags) void;
pub extern fn igClosePopupToLevel(remaining: c_int, restore_focus_to_window_under_popup: bool) void;
pub extern fn igClosePopupsOverWindow(ref_window: ?*ImGuiWindow, restore_focus_to_window_under_popup: bool) void;
pub extern fn igClosePopupsExceptModals() void;
pub extern fn igIsPopupOpen_ID(id: ImGuiID, popup_flags: ImGuiPopupFlags) bool;
pub extern fn igBeginPopupEx(id: ImGuiID, extra_flags: ImGuiWindowFlags) bool;
pub extern fn igBeginTooltipEx(tooltip_flags: ImGuiTooltipFlags, extra_window_flags: ImGuiWindowFlags) void;
pub extern fn igGetPopupAllowedExtentRect(pOut: [*c]ImRect, window: ?*ImGuiWindow) void;
pub extern fn igGetTopMostPopupModal() ?*ImGuiWindow;
pub extern fn igGetTopMostAndVisiblePopupModal() ?*ImGuiWindow;
pub extern fn igFindBestWindowPosForPopup(pOut: [*c]ImVec2, window: ?*ImGuiWindow) void;
pub extern fn igFindBestWindowPosForPopupEx(pOut: [*c]ImVec2, ref_pos: ImVec2, size: ImVec2, last_dir: [*c]ImGuiDir, r_outer: ImRect, r_avoid: ImRect, policy: ImGuiPopupPositionPolicy) void;
pub extern fn igBeginViewportSideBar(name: [*c]const u8, viewport: [*c]ImGuiViewport, dir: ImGuiDir, size: f32, window_flags: ImGuiWindowFlags) bool;
pub extern fn igBeginMenuEx(label: [*c]const u8, icon: [*c]const u8, enabled: bool) bool;
pub extern fn igMenuItemEx(label: [*c]const u8, icon: [*c]const u8, shortcut: [*c]const u8, selected: bool, enabled: bool) bool;
pub extern fn igBeginComboPopup(popup_id: ImGuiID, bb: ImRect, flags: ImGuiComboFlags) bool;
pub extern fn igBeginComboPreview() bool;
pub extern fn igEndComboPreview() void;
pub extern fn igNavInitWindow(window: ?*ImGuiWindow, force_reinit: bool) void;
pub extern fn igNavInitRequestApplyResult() void;
pub extern fn igNavMoveRequestButNoResultYet() bool;
pub extern fn igNavMoveRequestSubmit(move_dir: ImGuiDir, clip_dir: ImGuiDir, move_flags: ImGuiNavMoveFlags, scroll_flags: ImGuiScrollFlags) void;
pub extern fn igNavMoveRequestForward(move_dir: ImGuiDir, clip_dir: ImGuiDir, move_flags: ImGuiNavMoveFlags, scroll_flags: ImGuiScrollFlags) void;
pub extern fn igNavMoveRequestResolveWithLastItem(result: [*c]ImGuiNavItemData) void;
pub extern fn igNavMoveRequestCancel() void;
pub extern fn igNavMoveRequestApplyResult() void;
pub extern fn igNavMoveRequestTryWrapping(window: ?*ImGuiWindow, move_flags: ImGuiNavMoveFlags) void;
pub extern fn igGetNavInputName(n: ImGuiNavInput) [*c]const u8;
pub extern fn igGetNavInputAmount(n: ImGuiNavInput, mode: ImGuiNavReadMode) f32;
pub extern fn igGetNavInputAmount2d(pOut: [*c]ImVec2, dir_sources: ImGuiNavDirSourceFlags, mode: ImGuiNavReadMode, slow_factor: f32, fast_factor: f32) void;
pub extern fn igCalcTypematicRepeatAmount(t0: f32, t1: f32, repeat_delay: f32, repeat_rate: f32) c_int;
pub extern fn igActivateItem(id: ImGuiID) void;
pub extern fn igSetNavWindow(window: ?*ImGuiWindow) void;
pub extern fn igSetNavID(id: ImGuiID, nav_layer: ImGuiNavLayer, focus_scope_id: ImGuiID, rect_rel: ImRect) void;
pub extern fn igPushFocusScope(id: ImGuiID) void;
pub extern fn igPopFocusScope() void;
pub extern fn igGetFocusedFocusScope() ImGuiID;
pub extern fn igGetFocusScope() ImGuiID;
pub extern fn igIsNamedKey(key: ImGuiKey) bool;
pub extern fn igIsLegacyKey(key: ImGuiKey) bool;
pub extern fn igIsGamepadKey(key: ImGuiKey) bool;
pub extern fn igGetKeyData(key: ImGuiKey) [*c]ImGuiKeyData;
pub extern fn igSetItemUsingMouseWheel() void;
pub extern fn igSetActiveIdUsingNavAndKeys() void;
pub extern fn igIsActiveIdUsingNavDir(dir: ImGuiDir) bool;
pub extern fn igIsActiveIdUsingNavInput(input: ImGuiNavInput) bool;
pub extern fn igIsActiveIdUsingKey(key: ImGuiKey) bool;
pub extern fn igSetActiveIdUsingKey(key: ImGuiKey) void;
pub extern fn igIsMouseDragPastThreshold(button: ImGuiMouseButton, lock_threshold: f32) bool;
pub extern fn igIsNavInputDown(n: ImGuiNavInput) bool;
pub extern fn igIsNavInputTest(n: ImGuiNavInput, rm: ImGuiNavReadMode) bool;
pub extern fn igGetMergedModFlags() ImGuiModFlags;
pub extern fn igIsKeyPressedMap(key: ImGuiKey, repeat: bool) bool;
pub extern fn igDockContextInitialize(ctx: [*c]ImGuiContext) void;
pub extern fn igDockContextShutdown(ctx: [*c]ImGuiContext) void;
pub extern fn igDockContextClearNodes(ctx: [*c]ImGuiContext, root_id: ImGuiID, clear_settings_refs: bool) void;
pub extern fn igDockContextRebuildNodes(ctx: [*c]ImGuiContext) void;
pub extern fn igDockContextNewFrameUpdateUndocking(ctx: [*c]ImGuiContext) void;
pub extern fn igDockContextNewFrameUpdateDocking(ctx: [*c]ImGuiContext) void;
pub extern fn igDockContextEndFrame(ctx: [*c]ImGuiContext) void;
pub extern fn igDockContextGenNodeID(ctx: [*c]ImGuiContext) ImGuiID;
pub extern fn igDockContextQueueDock(ctx: [*c]ImGuiContext, target: ?*ImGuiWindow, target_node: ?*ImGuiDockNode, payload: ?*ImGuiWindow, split_dir: ImGuiDir, split_ratio: f32, split_outer: bool) void;
pub extern fn igDockContextQueueUndockWindow(ctx: [*c]ImGuiContext, window: ?*ImGuiWindow) void;
pub extern fn igDockContextQueueUndockNode(ctx: [*c]ImGuiContext, node: ?*ImGuiDockNode) void;
pub extern fn igDockContextCalcDropPosForDocking(target: ?*ImGuiWindow, target_node: ?*ImGuiDockNode, payload: ?*ImGuiWindow, split_dir: ImGuiDir, split_outer: bool, out_pos: [*c]ImVec2) bool;
pub extern fn igDockNodeBeginAmendTabBar(node: ?*ImGuiDockNode) bool;
pub extern fn igDockNodeEndAmendTabBar() void;
pub extern fn igDockNodeGetRootNode(node: ?*ImGuiDockNode) ?*ImGuiDockNode;
pub extern fn igDockNodeIsInHierarchyOf(node: ?*ImGuiDockNode, parent: ?*ImGuiDockNode) bool;
pub extern fn igDockNodeGetDepth(node: ?*const ImGuiDockNode) c_int;
pub extern fn igDockNodeGetWindowMenuButtonId(node: ?*const ImGuiDockNode) ImGuiID;
pub extern fn igGetWindowDockNode() ?*ImGuiDockNode;
pub extern fn igGetWindowAlwaysWantOwnTabBar(window: ?*ImGuiWindow) bool;
pub extern fn igBeginDocked(window: ?*ImGuiWindow, p_open: [*c]bool) void;
pub extern fn igBeginDockableDragDropSource(window: ?*ImGuiWindow) void;
pub extern fn igBeginDockableDragDropTarget(window: ?*ImGuiWindow) void;
pub extern fn igSetWindowDock(window: ?*ImGuiWindow, dock_id: ImGuiID, cond: ImGuiCond) void;
pub extern fn igDockBuilderDockWindow(window_name: [*c]const u8, node_id: ImGuiID) void;
pub extern fn igDockBuilderGetNode(node_id: ImGuiID) ?*ImGuiDockNode;
pub extern fn igDockBuilderGetCentralNode(node_id: ImGuiID) ?*ImGuiDockNode;
pub extern fn igDockBuilderAddNode(node_id: ImGuiID, flags: ImGuiDockNodeFlags) ImGuiID;
pub extern fn igDockBuilderRemoveNode(node_id: ImGuiID) void;
pub extern fn igDockBuilderRemoveNodeDockedWindows(node_id: ImGuiID, clear_settings_refs: bool) void;
pub extern fn igDockBuilderRemoveNodeChildNodes(node_id: ImGuiID) void;
pub extern fn igDockBuilderSetNodePos(node_id: ImGuiID, pos: ImVec2) void;
pub extern fn igDockBuilderSetNodeSize(node_id: ImGuiID, size: ImVec2) void;
pub extern fn igDockBuilderSplitNode(node_id: ImGuiID, split_dir: ImGuiDir, size_ratio_for_node_at_dir: f32, out_id_at_dir: [*c]ImGuiID, out_id_at_opposite_dir: [*c]ImGuiID) ImGuiID;
pub extern fn igDockBuilderCopyDockSpace(src_dockspace_id: ImGuiID, dst_dockspace_id: ImGuiID, in_window_remap_pairs: [*c]ImVector_const_charPtr) void;
pub extern fn igDockBuilderCopyNode(src_node_id: ImGuiID, dst_node_id: ImGuiID, out_node_remap_pairs: [*c]ImVector_ImGuiID) void;
pub extern fn igDockBuilderCopyWindowSettings(src_name: [*c]const u8, dst_name: [*c]const u8) void;
pub extern fn igDockBuilderFinish(node_id: ImGuiID) void;
pub extern fn igIsDragDropActive() bool;
pub extern fn igBeginDragDropTargetCustom(bb: ImRect, id: ImGuiID) bool;
pub extern fn igClearDragDrop() void;
pub extern fn igIsDragDropPayloadBeingAccepted() bool;
pub extern fn igSetWindowClipRectBeforeSetChannel(window: ?*ImGuiWindow, clip_rect: ImRect) void;
pub extern fn igBeginColumns(str_id: [*c]const u8, count: c_int, flags: ImGuiOldColumnFlags) void;
pub extern fn igEndColumns() void;
pub extern fn igPushColumnClipRect(column_index: c_int) void;
pub extern fn igPushColumnsBackground() void;
pub extern fn igPopColumnsBackground() void;
pub extern fn igGetColumnsID(str_id: [*c]const u8, count: c_int) ImGuiID;
pub extern fn igFindOrCreateColumns(window: ?*ImGuiWindow, id: ImGuiID) [*c]ImGuiOldColumns;
pub extern fn igGetColumnOffsetFromNorm(columns: [*c]const ImGuiOldColumns, offset_norm: f32) f32;
pub extern fn igGetColumnNormFromOffset(columns: [*c]const ImGuiOldColumns, offset: f32) f32;
pub extern fn igTableOpenContextMenu(column_n: c_int) void;
pub extern fn igTableSetColumnWidth(column_n: c_int, width: f32) void;
pub extern fn igTableSetColumnSortDirection(column_n: c_int, sort_direction: ImGuiSortDirection, append_to_sort_specs: bool) void;
pub extern fn igTableGetHoveredColumn() c_int;
pub extern fn igTableGetHeaderRowHeight() f32;
pub extern fn igTablePushBackgroundChannel() void;
pub extern fn igTablePopBackgroundChannel() void;
pub extern fn igGetCurrentTable() ?*ImGuiTable;
pub extern fn igTableFindByID(id: ImGuiID) ?*ImGuiTable;
pub extern fn igBeginTableEx(name: [*c]const u8, id: ImGuiID, columns_count: c_int, flags: ImGuiTableFlags, outer_size: ImVec2, inner_width: f32) bool;
pub extern fn igTableBeginInitMemory(table: ?*ImGuiTable, columns_count: c_int) void;
pub extern fn igTableBeginApplyRequests(table: ?*ImGuiTable) void;
pub extern fn igTableSetupDrawChannels(table: ?*ImGuiTable) void;
pub extern fn igTableUpdateLayout(table: ?*ImGuiTable) void;
pub extern fn igTableUpdateBorders(table: ?*ImGuiTable) void;
pub extern fn igTableUpdateColumnsWeightFromWidth(table: ?*ImGuiTable) void;
pub extern fn igTableDrawBorders(table: ?*ImGuiTable) void;
pub extern fn igTableDrawContextMenu(table: ?*ImGuiTable) void;
pub extern fn igTableMergeDrawChannels(table: ?*ImGuiTable) void;
pub extern fn igTableGetInstanceData(table: ?*ImGuiTable, instance_no: c_int) [*c]ImGuiTableInstanceData;
pub extern fn igTableSortSpecsSanitize(table: ?*ImGuiTable) void;
pub extern fn igTableSortSpecsBuild(table: ?*ImGuiTable) void;
pub extern fn igTableGetColumnNextSortDirection(column: ?*ImGuiTableColumn) ImGuiSortDirection;
pub extern fn igTableFixColumnSortDirection(table: ?*ImGuiTable, column: ?*ImGuiTableColumn) void;
pub extern fn igTableGetColumnWidthAuto(table: ?*ImGuiTable, column: ?*ImGuiTableColumn) f32;
pub extern fn igTableBeginRow(table: ?*ImGuiTable) void;
pub extern fn igTableEndRow(table: ?*ImGuiTable) void;
pub extern fn igTableBeginCell(table: ?*ImGuiTable, column_n: c_int) void;
pub extern fn igTableEndCell(table: ?*ImGuiTable) void;
pub extern fn igTableGetCellBgRect(pOut: [*c]ImRect, table: ?*const ImGuiTable, column_n: c_int) void;
pub extern fn igTableGetColumnName_TablePtr(table: ?*const ImGuiTable, column_n: c_int) [*c]const u8;
pub extern fn igTableGetColumnResizeID(table: ?*const ImGuiTable, column_n: c_int, instance_no: c_int) ImGuiID;
pub extern fn igTableGetMaxColumnWidth(table: ?*const ImGuiTable, column_n: c_int) f32;
pub extern fn igTableSetColumnWidthAutoSingle(table: ?*ImGuiTable, column_n: c_int) void;
pub extern fn igTableSetColumnWidthAutoAll(table: ?*ImGuiTable) void;
pub extern fn igTableRemove(table: ?*ImGuiTable) void;
pub extern fn igTableGcCompactTransientBuffers_TablePtr(table: ?*ImGuiTable) void;
pub extern fn igTableGcCompactTransientBuffers_TableTempDataPtr(table: [*c]ImGuiTableTempData) void;
pub extern fn igTableGcCompactSettings() void;
pub extern fn igTableLoadSettings(table: ?*ImGuiTable) void;
pub extern fn igTableSaveSettings(table: ?*ImGuiTable) void;
pub extern fn igTableResetSettings(table: ?*ImGuiTable) void;
pub extern fn igTableGetBoundSettings(table: ?*ImGuiTable) [*c]ImGuiTableSettings;
pub extern fn igTableSettingsAddSettingsHandler() void;
pub extern fn igTableSettingsCreate(id: ImGuiID, columns_count: c_int) [*c]ImGuiTableSettings;
pub extern fn igTableSettingsFindByID(id: ImGuiID) [*c]ImGuiTableSettings;
pub extern fn igBeginTabBarEx(tab_bar: [*c]ImGuiTabBar, bb: ImRect, flags: ImGuiTabBarFlags, dock_node: ?*ImGuiDockNode) bool;
pub extern fn igTabBarFindTabByID(tab_bar: [*c]ImGuiTabBar, tab_id: ImGuiID) [*c]ImGuiTabItem;
pub extern fn igTabBarFindMostRecentlySelectedTabForActiveWindow(tab_bar: [*c]ImGuiTabBar) [*c]ImGuiTabItem;
pub extern fn igTabBarAddTab(tab_bar: [*c]ImGuiTabBar, tab_flags: ImGuiTabItemFlags, window: ?*ImGuiWindow) void;
pub extern fn igTabBarRemoveTab(tab_bar: [*c]ImGuiTabBar, tab_id: ImGuiID) void;
pub extern fn igTabBarCloseTab(tab_bar: [*c]ImGuiTabBar, tab: [*c]ImGuiTabItem) void;
pub extern fn igTabBarQueueReorder(tab_bar: [*c]ImGuiTabBar, tab: [*c]const ImGuiTabItem, offset: c_int) void;
pub extern fn igTabBarQueueReorderFromMousePos(tab_bar: [*c]ImGuiTabBar, tab: [*c]const ImGuiTabItem, mouse_pos: ImVec2) void;
pub extern fn igTabBarProcessReorder(tab_bar: [*c]ImGuiTabBar) bool;
pub extern fn igTabItemEx(tab_bar: [*c]ImGuiTabBar, label: [*c]const u8, p_open: [*c]bool, flags: ImGuiTabItemFlags, docked_window: ?*ImGuiWindow) bool;
pub extern fn igTabItemCalcSize(pOut: [*c]ImVec2, label: [*c]const u8, has_close_button: bool) void;
pub extern fn igTabItemBackground(draw_list: [*c]ImDrawList, bb: ImRect, flags: ImGuiTabItemFlags, col: ImU32) void;
pub extern fn igTabItemLabelAndCloseButton(draw_list: [*c]ImDrawList, bb: ImRect, flags: ImGuiTabItemFlags, frame_padding: ImVec2, label: [*c]const u8, tab_id: ImGuiID, close_button_id: ImGuiID, is_contents_visible: bool, out_just_closed: [*c]bool, out_text_clipped: [*c]bool
) void;
pub extern fn igRenderText(pos: ImVec2, text: [*c]const u8, text_end: [*c]const u8, hide_text_after_hash: bool) void;
pub extern fn igRenderTextWrapped(pos: ImVec2, text: [*c]const u8, text_end: [*c]const u8, wrap_width: f32) void;
pub extern fn igRenderTextClipped(pos_min: ImVec2, pos_max: ImVec2, text: [*c]const u8, text_end: [*c]const u8, text_size_if_known: [*c]const ImVec2, @"align": ImVec2, clip_rect: [*c]const ImRect) void;
pub extern fn igRenderTextClippedEx(draw_list: [*c]ImDrawList, pos_min: ImVec2, pos_max: ImVec2, text: [*c]const u8, text_end: [*c]const u8, text_size_if_known: [*c]const ImVec2, @"align": ImVec2, clip_rect: [*c]const ImRect) void;
pub extern fn igRenderTextEllipsis(draw_list: [*c]ImDrawList, pos_min: ImVec2, pos_max: ImVec2, clip_max_x: f32, ellipsis_max_x: f32, text: [*c]const u8, text_end: [*c]const u8, text_size_if_known: [*c]const ImVec2) void;
pub extern fn igRenderFrame(p_min: ImVec2, p_max: ImVec2, fill_col: ImU32, border: bool, rounding: f32) void;
pub extern fn igRenderFrameBorder(p_min: ImVec2, p_max: ImVec2, rounding: f32) void;
pub extern fn igRenderColorRectWithAlphaCheckerboard(draw_list: [*c]ImDrawList, p_min: ImVec2, p_max: ImVec2, fill_col: ImU32, grid_step: f32, grid_off: ImVec2, rounding: f32, flags: ImDrawFlags) void;
pub extern fn igRenderNavHighlight(bb: ImRect, id: ImGuiID, flags: ImGuiNavHighlightFlags) void;
pub extern fn igFindRenderedTextEnd(text: [*c]const u8, text_end: [*c]const u8) [*c]const u8;
pub extern fn igRenderMouseCursor(pos: ImVec2, scale: f32, mouse_cursor: ImGuiMouseCursor, col_fill: ImU32, col_border: ImU32, col_shadow: ImU32) void;
pub extern fn igRenderArrow(draw_list: [*c]ImDrawList, pos: ImVec2, col: ImU32, dir: ImGuiDir, scale: f32) void;
pub extern fn igRenderBullet(draw_list: [*c]ImDrawList, pos: ImVec2, col: ImU32) void;
pub extern fn igRenderCheckMark(draw_list: [*c]ImDrawList, pos: ImVec2, col: ImU32, sz: f32) void;
pub extern fn igRenderArrowPointingAt(draw_list: [*c]ImDrawList, pos: ImVec2, half_sz: ImVec2, direction: ImGuiDir, col: ImU32) void;
pub extern fn igRenderArrowDockMenu(draw_list: [*c]ImDrawList, p_min: ImVec2, sz: f32, col: ImU32) void;
pub extern fn igRenderRectFilledRangeH(draw_list: [*c]ImDrawList, rect: ImRect, col: ImU32, x_start_norm: f32, x_end_norm: f32, rounding: f32) void;
pub extern fn igRenderRectFilledWithHole(draw_list: [*c]ImDrawList, outer: ImRect, inner: ImRect, col: ImU32, rounding: f32) void;
pub extern fn igCalcRoundingFlagsForRectInRect(r_in: ImRect, r_outer: ImRect, threshold: f32) ImDrawFlags;
pub extern fn igTextEx(text: [*c]const u8, text_end: [*c]const u8, flags: ImGuiTextFlags) void;
pub extern fn igButtonEx(label: [*c]const u8, size_arg: ImVec2, flags: ImGuiButtonFlags) bool;
pub extern fn igCloseButton(id: ImGuiID, pos: ImVec2) bool;
pub extern fn igCollapseButton(id: ImGuiID, pos: ImVec2, dock_node: ?*ImGuiDockNode) bool;
pub extern fn igArrowButtonEx(str_id: [*c]const u8, dir: ImGuiDir, size_arg: ImVec2, flags: ImGuiButtonFlags) bool;
pub extern fn igScrollbar(axis: ImGuiAxis) void;
pub extern fn igScrollbarEx(bb: ImRect, id: ImGuiID, axis: ImGuiAxis, p_scroll_v: [*c]ImS64, avail_v: ImS64, contents_v: ImS64, flags: ImDrawFlags) bool;
pub extern fn igImageButtonEx(id: ImGuiID, texture_id: ImTextureID, size: ImVec2, uv0: ImVec2, uv1: ImVec2, padding: ImVec2, bg_col: ImVec4, tint_col: ImVec4) bool;
pub extern fn igGetWindowScrollbarRect(pOut: [*c]ImRect, window: ?*ImGuiWindow, axis: ImGuiAxis) void;
pub extern fn igGetWindowScrollbarID(window: ?*ImGuiWindow, axis: ImGuiAxis) ImGuiID;
pub extern fn igGetWindowResizeCornerID(window: ?*ImGuiWindow, n: c_int) ImGuiID;
pub extern fn igGetWindowResizeBorderID(window: ?*ImGuiWindow, dir: ImGuiDir) ImGuiID;
pub extern fn igSeparatorEx(flags: ImGuiSeparatorFlags) void;
pub extern fn igCheckboxFlags_S64Ptr(label: [*c]const u8, flags: [*c]ImS64, flags_value: ImS64) bool;
pub extern fn igCheckboxFlags_U64Ptr(label: [*c]const u8, flags: [*c]ImU64, flags_value: ImU64) bool;
pub extern fn igButtonBehavior(bb: ImRect, id: ImGuiID, out_hovered: [*c]bool, out_held: [*c]bool, flags: ImGuiButtonFlags) bool;
pub extern fn igDragBehavior(id: ImGuiID, data_type: ImGuiDataType, p_v: ?*anyopaque, v_speed: f32, p_min: ?*const anyopaque, p_max: ?*const anyopaque, format: [*c]const u8, flags: ImGuiSliderFlags) bool;
pub extern fn igSliderBehavior(bb: ImRect, id: ImGuiID, data_type: ImGuiDataType, p_v: ?*anyopaque, p_min: ?*const anyopaque, p_max: ?*const anyopaque, format: [*c]const u8, flags: ImGuiSliderFlags, out_grab_bb: [*c]ImRect) bool;
pub extern fn igSplitterBehavior(bb: ImRect, id: ImGuiID, axis: ImGuiAxis, size1: [*c]f32, size2: [*c]f32, min_size1: f32, min_size2: f32, hover_extend: f32, hover_visibility_delay: f32, bg_col: ImU32) bool;
pub extern fn igTreeNodeBehavior(id: ImGuiID, flags: ImGuiTreeNodeFlags, label: [*c]const u8, label_end: [*c]const u8) bool;
pub extern fn igTreeNodeBehaviorIsOpen(id: ImGuiID, flags: ImGuiTreeNodeFlags) bool;
pub extern fn igTreePushOverrideID(id: ImGuiID) void;
pub extern fn igDataTypeGetInfo(data_type: ImGuiDataType) [*c]const ImGuiDataTypeInfo;
pub extern fn igDataTypeFormatString(buf: [*c]u8, buf_size: c_int, data_type: ImGuiDataType, p_data: ?*const anyopaque, format: [*c]const u8) c_int;
pub extern fn igDataTypeApplyOp(data_type: ImGuiDataType, op: c_int, output: ?*anyopaque, arg_1: ?*const anyopaque, arg_2: ?*const anyopaque) void;
pub extern fn igDataTypeApplyFromText(buf: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, format: [*c]const u8) bool;
pub extern fn igDataTypeCompare(data_type: ImGuiDataType, arg_1: ?*const anyopaque, arg_2: ?*const anyopaque) c_int;
pub extern fn igDataTypeClamp(data_type: ImGuiDataType, p_data: ?*anyopaque, p_min: ?*const anyopaque, p_max: ?*const anyopaque) bool;
pub extern fn igInputTextEx(label: [*c]const u8, hint: [*c]const u8, buf: [*c]u8, buf_size: c_int, size_arg: ImVec2, flags: ImGuiInputTextFlags, callback: ImGuiInputTextCallback, user_data: ?*anyopaque) bool;
pub extern fn igTempInputText(bb: ImRect, id: ImGuiID, label: [*c]const u8, buf: [*c]u8, buf_size: c_int, flags: ImGuiInputTextFlags) bool;
pub extern fn igTempInputScalar(bb: ImRect, id: ImGuiID, label: [*c]const u8, data_type: ImGuiDataType, p_data: ?*anyopaque, format: [*c]const u8, p_clamp_min: ?*const anyopaque, p_clamp_max: ?*const anyopaque) bool;
pub extern fn igTempInputIsActive(id: ImGuiID) bool;
pub extern fn igGetInputTextState(id: ImGuiID) [*c]ImGuiInputTextState;
pub extern fn igColorTooltip(text: [*c]const u8, col: [*c]const f32, flags: ImGuiColorEditFlags) void;
pub extern fn igColorEditOptionsPopup(col: [*c]const f32, flags: ImGuiColorEditFlags) void;
pub extern fn igColorPickerOptionsPopup(ref_col: [*c]const f32, flags: ImGuiColorEditFlags) void;
pub extern fn igPlotEx(plot_type: ImGuiPlotType, label: [*c]const u8, values_getter: ?*const fn (?*anyopaque, c_int) callconv(.C) f32, data: ?*anyopaque, values_count: c_int, values_offset: c_int, overlay_text: [*c]const u8, scale_min: f32, scale_max: f32, frame_size: ImVec2
) c_int;
pub extern fn igShadeVertsLinearColorGradientKeepAlpha(draw_list: [*c]ImDrawList, vert_start_idx: c_int, vert_end_idx: c_int, gradient_p0: ImVec2, gradient_p1: ImVec2, col0: ImU32, col1: ImU32) void;
pub extern fn igShadeVertsLinearUV(draw_list: [*c]ImDrawList, vert_start_idx: c_int, vert_end_idx: c_int, a: ImVec2, b: ImVec2, uv_a: ImVec2, uv_b: ImVec2, clamp: bool) void;
pub extern fn igGcCompactTransientMiscBuffers() void;
pub extern fn igGcCompactTransientWindowBuffers(window: ?*ImGuiWindow) void;
pub extern fn igGcAwakeTransientWindowBuffers(window: ?*ImGuiWindow) void;
pub extern fn igDebugLog(fmt: [*c]const u8, ...) void;
pub extern fn igDebugLogV(fmt: [*c]const u8, args: va_list) void;
pub extern fn igErrorCheckEndFrameRecover(log_callback: ImGuiErrorLogCallback, user_data: ?*anyopaque) void;
pub extern fn igErrorCheckEndWindowRecover(log_callback: ImGuiErrorLogCallback, user_data: ?*anyopaque) void;
pub extern fn igDebugDrawItemRect(col: ImU32) void;
pub extern fn igDebugStartItemPicker() void;
pub extern fn igShowFontAtlas(atlas: [*c]ImFontAtlas) void;
pub extern fn igDebugHookIdInfo(id: ImGuiID, data_type: ImGuiDataType, data_id: ?*const anyopaque, data_id_end: ?*const anyopaque) void;
pub extern fn igDebugNodeColumns(columns: [*c]ImGuiOldColumns) void;
pub extern fn igDebugNodeDockNode(node: ?*ImGuiDockNode, label: [*c]const u8) void;
pub extern fn igDebugNodeDrawList(window: ?*ImGuiWindow, viewport: [*c]ImGuiViewportP, draw_list: [*c]const ImDrawList, label: [*c]const u8) void;
pub extern fn igDebugNodeDrawCmdShowMeshAndBoundingBox(out_draw_list: [*c]ImDrawList, draw_list: [*c]const ImDrawList, draw_cmd: [*c]const ImDrawCmd, show_mesh: bool, show_aabb: bool) void;
pub extern fn igDebugNodeFont(font: [*c]ImFont) void;
pub extern fn igDebugNodeFontGlyph(font: [*c]ImFont, glyph: ?*const ImFontGlyph) void;
pub extern fn igDebugNodeStorage(storage: [*c]ImGuiStorage, label: [*c]const u8) void;
pub extern fn igDebugNodeTabBar(tab_bar: [*c]ImGuiTabBar, label: [*c]const u8) void;
pub extern fn igDebugNodeTable(table: ?*ImGuiTable) void;
pub extern fn igDebugNodeTableSettings(settings: [*c]ImGuiTableSettings) void;
pub extern fn igDebugNodeInputTextState(state: [*c]ImGuiInputTextState) void;
pub extern fn igDebugNodeWindow(window: ?*ImGuiWindow, label: [*c]const u8) void;
pub extern fn igDebugNodeWindowSettings(settings: [*c]ImGuiWindowSettings) void;
pub extern fn igDebugNodeWindowsList(windows: [*c]ImVector_ImGuiWindowPtr, label: [*c]const u8) void;
pub extern fn igDebugNodeWindowsListByBeginStackParent(windows: [*c]?*ImGuiWindow, windows_size: c_int, parent_in_begin_stack: ?*ImGuiWindow) void;
pub extern fn igDebugNodeViewport(viewport: [*c]ImGuiViewportP) void;
pub extern fn igDebugRenderViewportThumbnail(draw_list: [*c]ImDrawList, viewport: [*c]ImGuiViewportP, bb: ImRect) void;
pub extern fn igImFontAtlasGetBuilderForStbTruetype() [*c]const ImFontBuilderIO;
pub extern fn igImFontAtlasBuildInit(atlas: [*c]ImFontAtlas) void;
pub extern fn igImFontAtlasBuildSetupFont(atlas: [*c]ImFontAtlas, font: [*c]ImFont, font_config: [*c]ImFontConfig, ascent: f32, descent: f32) void;
pub extern fn igImFontAtlasBuildPackCustomRects(atlas: [*c]ImFontAtlas, stbrp_context_opaque: ?*anyopaque) void;
pub extern fn igImFontAtlasBuildFinish(atlas: [*c]ImFontAtlas) void;
pub extern fn igImFontAtlasBuildRender8bppRectFromString(atlas: [*c]ImFontAtlas, x: c_int, y: c_int, w: c_int, h: c_int, in_str: [*c]const u8, in_marker_char: u8, in_marker_pixel_value: u8) void;
pub extern fn igImFontAtlasBuildRender32bppRectFromString(atlas: [*c]ImFontAtlas, x: c_int, y: c_int, w: c_int, h: c_int, in_str: [*c]const u8, in_marker_char: u8, in_marker_pixel_value: c_uint) void;
pub extern fn igImFontAtlasBuildMultiplyCalcLookupTable(out_table: [*c]u8, in_multiply_factor: f32) void;
pub extern fn igImFontAtlasBuildMultiplyRectAlpha8(table: [*c]const u8, pixels: [*c]u8, x: c_int, y: c_int, w: c_int, h: c_int, stride: c_int) void;
pub extern fn igLogText(fmt: [*c]const u8, ...) void;
pub extern fn ImGuiTextBuffer_appendf(buffer: [*c]struct_ImGuiTextBuffer, fmt: [*c]const u8, ...) void;
pub extern fn igGET_FLT_MAX() f32;
pub extern fn igGET_FLT_MIN() f32;
pub extern fn ImVector_ImWchar_create() [*c]ImVector_ImWchar;
pub extern fn ImVector_ImWchar_destroy(self: [*c]ImVector_ImWchar) void;
pub extern fn ImVector_ImWchar_Init(p: [*c]ImVector_ImWchar) void;
pub extern fn ImVector_ImWchar_UnInit(p: [*c]ImVector_ImWchar) void;
pub const __llvm__ = @as(c_int, 1);
pub const __clang__ = @as(c_int, 1);
pub const __clang_major__ = @as(c_int, 18);
pub const __clang_minor__ = @as(c_int, 1);
pub const __clang_patchlevel__ = @as(c_int, 6);
pub const __clang_version__ = "18.1.6 (https://github.com/ziglang/zig-bootstrap 98bc6bf4fc4009888d33941daf6b600d20a42a56)";
pub const __GNUC__ = @as(c_int, 4);
pub const __GNUC_MINOR__ = @as(c_int, 2);
pub const __GNUC_PATCHLEVEL__ = @as(c_int, 1);
pub const __GXX_ABI_VERSION = @as(c_int, 1002);
pub const __ATOMIC_RELAXED = @as(c_int, 0);
pub const __ATOMIC_CONSUME = @as(c_int, 1);
pub const __ATOMIC_ACQUIRE = @as(c_int, 2);
pub const __ATOMIC_RELEASE = @as(c_int, 3);
pub const __ATOMIC_ACQ_REL = @as(c_int, 4);
pub const __ATOMIC_SEQ_CST = @as(c_int, 5);
pub const __MEMORY_SCOPE_SYSTEM = @as(c_int, 0);
pub const __MEMORY_SCOPE_DEVICE = @as(c_int, 1);
pub const __MEMORY_SCOPE_WRKGRP = @as(c_int, 2);
pub const __MEMORY_SCOPE_WVFRNT = @as(c_int, 3);
pub const __MEMORY_SCOPE_SINGLE = @as(c_int, 4);
pub const __OPENCL_MEMORY_SCOPE_WORK_ITEM = @as(c_int, 0);
pub const __OPENCL_MEMORY_SCOPE_WORK_GROUP = @as(c_int, 1);
pub const __OPENCL_MEMORY_SCOPE_DEVICE = @as(c_int, 2);
pub const __OPENCL_MEMORY_SCOPE_ALL_SVM_DEVICES = @as(c_int, 3);
pub const __OPENCL_MEMORY_SCOPE_SUB_GROUP = @as(c_int, 4);
pub const __FPCLASS_SNAN = @as(c_int, 0x0001);
pub const __FPCLASS_QNAN = @as(c_int, 0x0002);
pub const __FPCLASS_NEGINF = @as(c_int, 0x0004);
pub const __FPCLASS_NEGNORMAL = @as(c_int, 0x0008);
pub const __FPCLASS_NEGSUBNORMAL = @as(c_int, 0x0010);
pub const __FPCLASS_NEGZERO = @as(c_int, 0x0020);
pub const __FPCLASS_POSZERO = @as(c_int, 0x0040);
pub const __FPCLASS_POSSUBNORMAL = @as(c_int, 0x0080);
pub const __FPCLASS_POSNORMAL = @as(c_int, 0x0100);
pub const __FPCLASS_POSINF = @as(c_int, 0x0200);
pub const __PRAGMA_REDEFINE_EXTNAME = @as(c_int, 1);
pub const __VERSION__ = "Clang 18.1.6 (https://github.com/ziglang/zig-bootstrap 98bc6bf4fc4009888d33941daf6b600d20a42a56)";
pub const __OBJC_BOOL_IS_BOOL = @as(c_int, 0);
pub const __CONSTANT_CFSTRINGS__ = @as(c_int, 1);
pub const __SEH__ = @as(c_int, 1);
pub const __clang_literal_encoding__ = "UTF-8";
pub const __clang_wide_literal_encoding__ = "UTF-16";
pub const __ORDER_LITTLE_ENDIAN__ = @as(c_int, 1234);
pub const __ORDER_BIG_ENDIAN__ = @as(c_int, 4321);
pub const __ORDER_PDP_ENDIAN__ = @as(c_int, 3412);
pub const __BYTE_ORDER__ = __ORDER_LITTLE_ENDIAN__;
pub const __LITTLE_ENDIAN__ = @as(c_int, 1);
pub const __CHAR_BIT__ = @as(c_int, 8);
pub const __BOOL_WIDTH__ = @as(c_int, 8);
pub const __SHRT_WIDTH__ = @as(c_int, 16);
pub const __INT_WIDTH__ = @as(c_int, 32);
pub const __LONG_WIDTH__ = @as(c_int, 32);
pub const __LLONG_WIDTH__ = @as(c_int, 64);
pub const __BITINT_MAXWIDTH__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 8388608, .decimal);
pub const __SCHAR_MAX__ = @as(c_int, 127);
pub const __SHRT_MAX__ = @as(c_int, 32767);
pub const __INT_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __LONG_MAX__ = @as(c_long, 2147483647);
pub const __LONG_LONG_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __WCHAR_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __WCHAR_WIDTH__ = @as(c_int, 16);
pub const __WINT_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __WINT_WIDTH__ = @as(c_int, 16);
pub const __INTMAX_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INTMAX_WIDTH__ = @as(c_int, 64);
pub const __SIZE_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __SIZE_WIDTH__ = @as(c_int, 64);
pub const __UINTMAX_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINTMAX_WIDTH__ = @as(c_int, 64);
pub const __PTRDIFF_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __PTRDIFF_WIDTH__ = @as(c_int, 64);
pub const __INTPTR_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INTPTR_WIDTH__ = @as(c_int, 64);
pub const __UINTPTR_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINTPTR_WIDTH__ = @as(c_int, 64);
pub const __SIZEOF_DOUBLE__ = @as(c_int, 8);
pub const __SIZEOF_FLOAT__ = @as(c_int, 4);
pub const __SIZEOF_INT__ = @as(c_int, 4);
pub const __SIZEOF_LONG__ = @as(c_int, 4);
pub const __SIZEOF_LONG_DOUBLE__ = @as(c_int, 16);
pub const __SIZEOF_LONG_LONG__ = @as(c_int, 8);
pub const __SIZEOF_POINTER__ = @as(c_int, 8);
pub const __SIZEOF_SHORT__ = @as(c_int, 2);
pub const __SIZEOF_PTRDIFF_T__ = @as(c_int, 8);
pub const __SIZEOF_SIZE_T__ = @as(c_int, 8);
pub const __SIZEOF_WCHAR_T__ = @as(c_int, 2);
pub const __SIZEOF_WINT_T__ = @as(c_int, 2);
pub const __SIZEOF_INT128__ = @as(c_int, 16);
pub const __INTMAX_TYPE__ = c_longlong;
pub const __INTMAX_FMTd__ = "lld";
pub const __INTMAX_FMTi__ = "lli";
pub const __INTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `LL`");
// (no file):94:9
pub const __UINTMAX_TYPE__ = c_ulonglong;
pub const __UINTMAX_FMTo__ = "llo";
pub const __UINTMAX_FMTu__ = "llu";
pub const __UINTMAX_FMTx__ = "llx";
pub const __UINTMAX_FMTX__ = "llX";
pub const __UINTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `ULL`");
// (no file):100:9
pub const __PTRDIFF_TYPE__ = c_longlong;
pub const __PTRDIFF_FMTd__ = "lld";
pub const __PTRDIFF_FMTi__ = "lli";
pub const __INTPTR_TYPE__ = c_longlong;
pub const __INTPTR_FMTd__ = "lld";
pub const __INTPTR_FMTi__ = "lli";
pub const __SIZE_TYPE__ = c_ulonglong;
pub const __SIZE_FMTo__ = "llo";
pub const __SIZE_FMTu__ = "llu";
pub const __SIZE_FMTx__ = "llx";
pub const __SIZE_FMTX__ = "llX";
pub const __WCHAR_TYPE__ = c_ushort;
pub const __WINT_TYPE__ = c_ushort;
pub const __SIG_ATOMIC_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __SIG_ATOMIC_WIDTH__ = @as(c_int, 32);
pub const __CHAR16_TYPE__ = c_ushort;
pub const __CHAR32_TYPE__ = c_uint;
pub const __UINTPTR_TYPE__ = c_ulonglong;
pub const __UINTPTR_FMTo__ = "llo";
pub const __UINTPTR_FMTu__ = "llu";
pub const __UINTPTR_FMTx__ = "llx";
pub const __UINTPTR_FMTX__ = "llX";
pub const __FLT16_DENORM_MIN__ = @as(f16, 5.9604644775390625e-8);
pub const __FLT16_HAS_DENORM__ = @as(c_int, 1);
pub const __FLT16_DIG__ = @as(c_int, 3);
pub const __FLT16_DECIMAL_DIG__ = @as(c_int, 5);
pub const __FLT16_EPSILON__ = @as(f16, 9.765625e-4);
pub const __FLT16_HAS_INFINITY__ = @as(c_int, 1);
pub const __FLT16_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __FLT16_MANT_DIG__ = @as(c_int, 11);
pub const __FLT16_MAX_10_EXP__ = @as(c_int, 4);
pub const __FLT16_MAX_EXP__ = @as(c_int, 16);
pub const __FLT16_MAX__ = @as(f16, 6.5504e+4);
pub const __FLT16_MIN_10_EXP__ = -@as(c_int, 4);
pub const __FLT16_MIN_EXP__ = -@as(c_int, 13);
pub const __FLT16_MIN__ = @as(f16, 6.103515625e-5);
pub const __FLT_DENORM_MIN__ = @as(f32, 1.40129846e-45);
pub const __FLT_HAS_DENORM__ = @as(c_int, 1);
pub const __FLT_DIG__ = @as(c_int, 6);
pub const __FLT_DECIMAL_DIG__ = @as(c_int, 9);
pub const __FLT_EPSILON__ = @as(f32, 1.19209290e-7);
pub const __FLT_HAS_INFINITY__ = @as(c_int, 1);
pub const __FLT_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __FLT_MANT_DIG__ = @as(c_int, 24);
pub const __FLT_MAX_10_EXP__ = @as(c_int, 38);
pub const __FLT_MAX_EXP__ = @as(c_int, 128);
pub const __FLT_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_MIN_10_EXP__ = -@as(c_int, 37);
pub const __FLT_MIN_EXP__ = -@as(c_int, 125);
pub const __FLT_MIN__ = @as(f32, 1.17549435e-38);
pub const __DBL_DENORM_MIN__ = @as(f64, 4.9406564584124654e-324);
pub const __DBL_HAS_DENORM__ = @as(c_int, 1);
pub const __DBL_DIG__ = @as(c_int, 15);
pub const __DBL_DECIMAL_DIG__ = @as(c_int, 17);
pub const __DBL_EPSILON__ = @as(f64, 2.2204460492503131e-16);
pub const __DBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __DBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __DBL_MANT_DIG__ = @as(c_int, 53);
pub const __DBL_MAX_10_EXP__ = @as(c_int, 308);
pub const __DBL_MAX_EXP__ = @as(c_int, 1024);
pub const __DBL_MAX__ = @as(f64, 1.7976931348623157e+308);
pub const __DBL_MIN_10_EXP__ = -@as(c_int, 307);
pub const __DBL_MIN_EXP__ = -@as(c_int, 1021);
pub const __DBL_MIN__ = @as(f64, 2.2250738585072014e-308);
pub const __LDBL_DENORM_MIN__ = @as(c_longdouble, 3.64519953188247460253e-4951);
pub const __LDBL_HAS_DENORM__ = @as(c_int, 1);
pub const __LDBL_DIG__ = @as(c_int, 18);
pub const __LDBL_DECIMAL_DIG__ = @as(c_int, 21);
pub const __LDBL_EPSILON__ = @as(c_longdouble, 1.08420217248550443401e-19);
pub const __LDBL_HAS_INFINITY__ = @as(c_int, 1);
pub const __LDBL_HAS_QUIET_NAN__ = @as(c_int, 1);
pub const __LDBL_MANT_DIG__ = @as(c_int, 64);
pub const __LDBL_MAX_10_EXP__ = @as(c_int, 4932);
pub const __LDBL_MAX_EXP__ = @as(c_int, 16384);
pub const __LDBL_MAX__ = @as(c_longdouble, 1.18973149535723176502e+4932);
pub const __LDBL_MIN_10_EXP__ = -@as(c_int, 4931);
pub const __LDBL_MIN_EXP__ = -@as(c_int, 16381);
pub const __LDBL_MIN__ = @as(c_longdouble, 3.36210314311209350626e-4932);
pub const __POINTER_WIDTH__ = @as(c_int, 64);
pub const __BIGGEST_ALIGNMENT__ = @as(c_int, 16);
pub const __WCHAR_UNSIGNED__ = @as(c_int, 1);
pub const __WINT_UNSIGNED__ = @as(c_int, 1);
pub const __INT8_TYPE__ = i8;
pub const __INT8_FMTd__ = "hhd";
pub const __INT8_FMTi__ = "hhi";
pub const __INT8_C_SUFFIX__ = "";
pub const __INT16_TYPE__ = c_short;
pub const __INT16_FMTd__ = "hd";
pub const __INT16_FMTi__ = "hi";
pub const __INT16_C_SUFFIX__ = "";
pub const __INT32_TYPE__ = c_int;
pub const __INT32_FMTd__ = "d";
pub const __INT32_FMTi__ = "i";
pub const __INT32_C_SUFFIX__ = "";
pub const __INT64_TYPE__ = c_longlong;
pub const __INT64_FMTd__ = "lld";
pub const __INT64_FMTi__ = "lli";
pub const __INT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `LL`");
// (no file):198:9
pub const __UINT8_TYPE__ = u8;
pub const __UINT8_FMTo__ = "hho";
pub const __UINT8_FMTu__ = "hhu";
pub const __UINT8_FMTx__ = "hhx";
pub const __UINT8_FMTX__ = "hhX";
pub const __UINT8_C_SUFFIX__ = "";
pub const __UINT8_MAX__ = @as(c_int, 255);
pub const __INT8_MAX__ = @as(c_int, 127);
pub const __UINT16_TYPE__ = c_ushort;
pub const __UINT16_FMTo__ = "ho";
pub const __UINT16_FMTu__ = "hu";
pub const __UINT16_FMTx__ = "hx";
pub const __UINT16_FMTX__ = "hX";
pub const __UINT16_C_SUFFIX__ = "";
pub const __UINT16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __INT16_MAX__ = @as(c_int, 32767);
pub const __UINT32_TYPE__ = c_uint;
pub const __UINT32_FMTo__ = "o";
pub const __UINT32_FMTu__ = "u";
pub const __UINT32_FMTx__ = "x";
pub const __UINT32_FMTX__ = "X";
pub const __UINT32_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `U`");
// (no file):220:9
pub const __UINT32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __INT32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __UINT64_TYPE__ = c_ulonglong;
pub const __UINT64_FMTo__ = "llo";
pub const __UINT64_FMTu__ = "llu";
pub const __UINT64_FMTx__ = "llx";
pub const __UINT64_FMTX__ = "llX";
pub const __UINT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `ULL`");
// (no file):228:9
pub const __UINT64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __INT64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_LEAST8_TYPE__ = i8;
pub const __INT_LEAST8_MAX__ = @as(c_int, 127);
pub const __INT_LEAST8_WIDTH__ = @as(c_int, 8);
pub const __INT_LEAST8_FMTd__ = "hhd";
pub const __INT_LEAST8_FMTi__ = "hhi";
pub const __UINT_LEAST8_TYPE__ = u8;
pub const __UINT_LEAST8_MAX__ = @as(c_int, 255);
pub const __UINT_LEAST8_FMTo__ = "hho";
pub const __UINT_LEAST8_FMTu__ = "hhu";
pub const __UINT_LEAST8_FMTx__ = "hhx";
pub const __UINT_LEAST8_FMTX__ = "hhX";
pub const __INT_LEAST16_TYPE__ = c_short;
pub const __INT_LEAST16_MAX__ = @as(c_int, 32767);
pub const __INT_LEAST16_WIDTH__ = @as(c_int, 16);
pub const __INT_LEAST16_FMTd__ = "hd";
pub const __INT_LEAST16_FMTi__ = "hi";
pub const __UINT_LEAST16_TYPE__ = c_ushort;
pub const __UINT_LEAST16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_LEAST16_FMTo__ = "ho";
pub const __UINT_LEAST16_FMTu__ = "hu";
pub const __UINT_LEAST16_FMTx__ = "hx";
pub const __UINT_LEAST16_FMTX__ = "hX";
pub const __INT_LEAST32_TYPE__ = c_int;
pub const __INT_LEAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_LEAST32_WIDTH__ = @as(c_int, 32);
pub const __INT_LEAST32_FMTd__ = "d";
pub const __INT_LEAST32_FMTi__ = "i";
pub const __UINT_LEAST32_TYPE__ = c_uint;
pub const __UINT_LEAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_LEAST32_FMTo__ = "o";
pub const __UINT_LEAST32_FMTu__ = "u";
pub const __UINT_LEAST32_FMTx__ = "x";
pub const __UINT_LEAST32_FMTX__ = "X";
pub const __INT_LEAST64_TYPE__ = c_longlong;
pub const __INT_LEAST64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_LEAST64_WIDTH__ = @as(c_int, 64);
pub const __INT_LEAST64_FMTd__ = "lld";
pub const __INT_LEAST64_FMTi__ = "lli";
pub const __UINT_LEAST64_TYPE__ = c_ulonglong;
pub const __UINT_LEAST64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINT_LEAST64_FMTo__ = "llo";
pub const __UINT_LEAST64_FMTu__ = "llu";
pub const __UINT_LEAST64_FMTx__ = "llx";
pub const __UINT_LEAST64_FMTX__ = "llX";
pub const __INT_FAST8_TYPE__ = i8;
pub const __INT_FAST8_MAX__ = @as(c_int, 127);
pub const __INT_FAST8_WIDTH__ = @as(c_int, 8);
pub const __INT_FAST8_FMTd__ = "hhd";
pub const __INT_FAST8_FMTi__ = "hhi";
pub const __UINT_FAST8_TYPE__ = u8;
pub const __UINT_FAST8_MAX__ = @as(c_int, 255);
pub const __UINT_FAST8_FMTo__ = "hho";
pub const __UINT_FAST8_FMTu__ = "hhu";
pub const __UINT_FAST8_FMTx__ = "hhx";
pub const __UINT_FAST8_FMTX__ = "hhX";
pub const __INT_FAST16_TYPE__ = c_short;
pub const __INT_FAST16_MAX__ = @as(c_int, 32767);
pub const __INT_FAST16_WIDTH__ = @as(c_int, 16);
pub const __INT_FAST16_FMTd__ = "hd";
pub const __INT_FAST16_FMTi__ = "hi";
pub const __UINT_FAST16_TYPE__ = c_ushort;
pub const __UINT_FAST16_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal);
pub const __UINT_FAST16_FMTo__ = "ho";
pub const __UINT_FAST16_FMTu__ = "hu";
pub const __UINT_FAST16_FMTx__ = "hx";
pub const __UINT_FAST16_FMTX__ = "hX";
pub const __INT_FAST32_TYPE__ = c_int;
pub const __INT_FAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_FAST32_WIDTH__ = @as(c_int, 32);
pub const __INT_FAST32_FMTd__ = "d";
pub const __INT_FAST32_FMTi__ = "i";
pub const __UINT_FAST32_TYPE__ = c_uint;
pub const __UINT_FAST32_MAX__ = @import("std").zig.c_translation.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __UINT_FAST32_FMTo__ = "o";
pub const __UINT_FAST32_FMTu__ = "u";
pub const __UINT_FAST32_FMTx__ = "x";
pub const __UINT_FAST32_FMTX__ = "X";
pub const __INT_FAST64_TYPE__ = c_longlong;
pub const __INT_FAST64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_FAST64_WIDTH__ = @as(c_int, 64);
pub const __INT_FAST64_FMTd__ = "lld";
pub const __INT_FAST64_FMTi__ = "lli";
pub const __UINT_FAST64_TYPE__ = c_ulonglong;
pub const __UINT_FAST64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINT_FAST64_FMTo__ = "llo";
pub const __UINT_FAST64_FMTu__ = "llu";
pub const __UINT_FAST64_FMTx__ = "llx";
pub const __UINT_FAST64_FMTX__ = "llX";
pub const __USER_LABEL_PREFIX__ = "";
pub const __FINITE_MATH_ONLY__ = @as(c_int, 0);
pub const __GNUC_STDC_INLINE__ = @as(c_int, 1);
pub const __GCC_ATOMIC_TEST_AND_SET_TRUEVAL = @as(c_int, 1);
pub const __CLANG_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __CLANG_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_BOOL_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_SHORT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_INT_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_LLONG_LOCK_FREE = @as(c_int, 2);
pub const __GCC_ATOMIC_POINTER_LOCK_FREE = @as(c_int, 2);
pub const __NO_INLINE__ = @as(c_int, 1);
pub const __PIC__ = @as(c_int, 2);
pub const __pic__ = @as(c_int, 2);
pub const __FLT_RADIX__ = @as(c_int, 2);
pub const __DECIMAL_DIG__ = __LDBL_DECIMAL_DIG__;
pub const __GCC_ASM_FLAG_OUTPUTS__ = @as(c_int, 1);
pub const __code_model_small__ = @as(c_int, 1);
pub const __amd64__ = @as(c_int, 1);
pub const __amd64 = @as(c_int, 1);
pub const __x86_64 = @as(c_int, 1);
pub const __x86_64__ = @as(c_int, 1);
pub const __SEG_GS = @as(c_int, 1);
pub const __SEG_FS = @as(c_int, 1);
pub const __seg_gs = @compileError("unable to translate macro: undefined identifier `address_space`");
// (no file):356:9
pub const __seg_fs = @compileError("unable to translate macro: undefined identifier `address_space`");
// (no file):357:9
pub const __corei7 = @as(c_int, 1);
pub const __corei7__ = @as(c_int, 1);
pub const __tune_corei7__ = @as(c_int, 1);
pub const __REGISTER_PREFIX__ = "";
pub const __NO_MATH_INLINES = @as(c_int, 1);
pub const __AES__ = @as(c_int, 1);
pub const __PCLMUL__ = @as(c_int, 1);
pub const __LAHF_SAHF__ = @as(c_int, 1);
pub const __LZCNT__ = @as(c_int, 1);
pub const __RDRND__ = @as(c_int, 1);
pub const __FSGSBASE__ = @as(c_int, 1);
pub const __BMI__ = @as(c_int, 1);
pub const __BMI2__ = @as(c_int, 1);
pub const __POPCNT__ = @as(c_int, 1);
pub const __PRFCHW__ = @as(c_int, 1);
pub const __RDSEED__ = @as(c_int, 1);
pub const __ADX__ = @as(c_int, 1);
pub const __MOVBE__ = @as(c_int, 1);
pub const __FMA__ = @as(c_int, 1);
pub const __F16C__ = @as(c_int, 1);
pub const __EVEX512__ = @as(c_int, 1);
pub const __AVX512CD__ = @as(c_int, 1);
pub const __AVX512VNNI__ = @as(c_int, 1);
pub const __AVX512DQ__ = @as(c_int, 1);
pub const __AVX512BW__ = @as(c_int, 1);
pub const __AVX512VL__ = @as(c_int, 1);
pub const __EVEX256__ = @as(c_int, 1);
pub const __FXSR__ = @as(c_int, 1);
pub const __XSAVE__ = @as(c_int, 1);
pub const __XSAVEOPT__ = @as(c_int, 1);
pub const __XSAVEC__ = @as(c_int, 1);
pub const __XSAVES__ = @as(c_int, 1);
pub const __CLFLUSHOPT__ = @as(c_int, 1);
pub const __CLWB__ = @as(c_int, 1);
pub const __INVPCID__ = @as(c_int, 1);
pub const __CRC32__ = @as(c_int, 1);
pub const __AVX512F__ = @as(c_int, 1);
pub const __AVX2__ = @as(c_int, 1);
pub const __AVX__ = @as(c_int, 1);
pub const __SSE4_2__ = @as(c_int, 1);
pub const __SSE4_1__ = @as(c_int, 1);
pub const __SSSE3__ = @as(c_int, 1);
pub const __SSE3__ = @as(c_int, 1);
pub const __SSE2__ = @as(c_int, 1);
pub const __SSE2_MATH__ = @as(c_int, 1);
pub const __SSE__ = @as(c_int, 1);
pub const __SSE_MATH__ = @as(c_int, 1);
pub const __MMX__ = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_1 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_2 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_4 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8 = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_16 = @as(c_int, 1);
pub const __SIZEOF_FLOAT128__ = @as(c_int, 16);
pub const _WIN32 = @as(c_int, 1);
pub const _WIN64 = @as(c_int, 1);
pub const WIN32 = @as(c_int, 1);
pub const __WIN32 = @as(c_int, 1);
pub const __WIN32__ = @as(c_int, 1);
pub const WINNT = @as(c_int, 1);
pub const __WINNT = @as(c_int, 1);
pub const __WINNT__ = @as(c_int, 1);
pub const WIN64 = @as(c_int, 1);
pub const __WIN64 = @as(c_int, 1);
pub const __WIN64__ = @as(c_int, 1);
pub const __MINGW64__ = @as(c_int, 1);
pub const __MSVCRT__ = @as(c_int, 1);
pub const __MINGW32__ = @as(c_int, 1);
pub const __declspec = @compileError("unable to translate C expr: unexpected token '__attribute__'");
// (no file):426:9
pub const _cdecl = @compileError("unable to translate macro: undefined identifier `__cdecl__`");
// (no file):427:9
pub const __cdecl = @compileError("unable to translate macro: undefined identifier `__cdecl__`");
// (no file):428:9
pub const _stdcall = @compileError("unable to translate macro: undefined identifier `__stdcall__`");
// (no file):429:9
pub const __stdcall = @compileError("unable to translate macro: undefined identifier `__stdcall__`");
// (no file):430:9
pub const _fastcall = @compileError("unable to translate macro: undefined identifier `__fastcall__`");
// (no file):431:9
pub const __fastcall = @compileError("unable to translate macro: undefined identifier `__fastcall__`");
// (no file):432:9
pub const _thiscall = @compileError("unable to translate macro: undefined identifier `__thiscall__`");
// (no file):433:9
pub const __thiscall = @compileError("unable to translate macro: undefined identifier `__thiscall__`");
// (no file):434:9
pub const _pascal = @compileError("unable to translate macro: undefined identifier `__pascal__`");
// (no file):435:9
pub const __pascal = @compileError("unable to translate macro: undefined identifier `__pascal__`");
// (no file):436:9
pub const __STDC__ = @as(c_int, 1);
pub const __STDC_HOSTED__ = @as(c_int, 1);
pub const __STDC_VERSION__ = @as(c_long, 201710);
pub const __STDC_UTF_16__ = @as(c_int, 1);
pub const __STDC_UTF_32__ = @as(c_int, 1);
pub const _DEBUG = @as(c_int, 1);
pub const EXTERN = @compileError("unable to translate C expr: unexpected token 'extern'");
// cimgui2.h:1:9
pub const CIMGUI_API = EXTERN;
pub const CONST = @compileError("unable to translate C expr: unexpected token 'const'");
// cimgui2.h:3:9
pub const __STDBOOL_H = "";
pub const __bool_true_false_are_defined = @as(c_int, 1);
pub const @"bool" = bool;
pub const @"true" = @as(c_int, 1);
pub const @"false" = @as(c_int, 0);
pub const __CLANG_STDINT_H = "";
pub const __int_least64_t = i64;
pub const __uint_least64_t = u64;
pub const __int_least32_t = i64;
pub const __uint_least32_t = u64;
pub const __int_least16_t = i64;
pub const __uint_least16_t = u64;
pub const __int_least8_t = i64;
pub const __uint_least8_t = u64;
pub const __uint32_t_defined = "";
pub const __int8_t_defined = "";
pub const __stdint_join3 = @compileError("unable to translate C expr: unexpected token '##'");
// C:\app\zig-windows-x86_64-0.13.0\lib\include/stdint.h:287:9
pub const __intptr_t_defined = "";
pub const _INTPTR_T = "";
pub const _UINTPTR_T = "";
pub const __int_c_join = @compileError("unable to translate C expr: unexpected token '##'");
// C:\app\zig-windows-x86_64-0.13.0\lib\include/stdint.h:324:9
pub inline fn __int_c(v: anytype, suffix: anytype) @TypeOf(__int_c_join(v, suffix)) {
    _ = &v;
    _ = &suffix;
    return __int_c_join(v, suffix);
}
pub const __uint_c = @compileError("unable to translate macro: undefined identifier `U`");
// C:\app\zig-windows-x86_64-0.13.0\lib\include/stdint.h:326:9
pub const __int64_c_suffix = __INT64_C_SUFFIX__;
pub const __int32_c_suffix = __INT64_C_SUFFIX__;
pub const __int16_c_suffix = __INT64_C_SUFFIX__;
pub const __int8_c_suffix = __INT64_C_SUFFIX__;
pub inline fn INT64_C(v: anytype) @TypeOf(__int_c(v, __int64_c_suffix)) {
    _ = &v;
    return __int_c(v, __int64_c_suffix);
}
pub inline fn UINT64_C(v: anytype) @TypeOf(__uint_c(v, __int64_c_suffix)) {
    _ = &v;
    return __uint_c(v, __int64_c_suffix);
}
pub inline fn INT32_C(v: anytype) @TypeOf(__int_c(v, __int32_c_suffix)) {
    _ = &v;
    return __int_c(v, __int32_c_suffix);
}
pub inline fn UINT32_C(v: anytype) @TypeOf(__uint_c(v, __int32_c_suffix)) {
    _ = &v;
    return __uint_c(v, __int32_c_suffix);
}
pub inline fn INT16_C(v: anytype) @TypeOf(__int_c(v, __int16_c_suffix)) {
    _ = &v;
    return __int_c(v, __int16_c_suffix);
}
pub inline fn UINT16_C(v: anytype) @TypeOf(__uint_c(v, __int16_c_suffix)) {
    _ = &v;
    return __uint_c(v, __int16_c_suffix);
}
pub inline fn INT8_C(v: anytype) @TypeOf(__int_c(v, __int8_c_suffix)) {
    _ = &v;
    return __int_c(v, __int8_c_suffix);
}
pub inline fn UINT8_C(v: anytype) @TypeOf(__uint_c(v, __int8_c_suffix)) {
    _ = &v;
    return __uint_c(v, __int8_c_suffix);
}
pub const INT64_MAX = INT64_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const INT64_MIN = -INT64_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const UINT64_MAX = UINT64_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const __INT_LEAST64_MIN = INT64_MIN;
pub const __INT_LEAST64_MAX = INT64_MAX;
pub const __UINT_LEAST64_MAX = UINT64_MAX;
pub const __INT_LEAST32_MIN = INT64_MIN;
pub const __INT_LEAST32_MAX = INT64_MAX;
pub const __UINT_LEAST32_MAX = UINT64_MAX;
pub const __INT_LEAST16_MIN = INT64_MIN;
pub const __INT_LEAST16_MAX = INT64_MAX;
pub const __UINT_LEAST16_MAX = UINT64_MAX;
pub const __INT_LEAST8_MIN = INT64_MIN;
pub const __INT_LEAST8_MAX = INT64_MAX;
pub const __UINT_LEAST8_MAX = UINT64_MAX;
pub const INT_LEAST64_MIN = __INT_LEAST64_MIN;
pub const INT_LEAST64_MAX = __INT_LEAST64_MAX;
pub const UINT_LEAST64_MAX = __UINT_LEAST64_MAX;
pub const INT_FAST64_MIN = __INT_LEAST64_MIN;
pub const INT_FAST64_MAX = __INT_LEAST64_MAX;
pub const UINT_FAST64_MAX = __UINT_LEAST64_MAX;
pub const INT32_MAX = INT32_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal));
pub const INT32_MIN = -INT32_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 2147483647, .decimal)) - @as(c_int, 1);
pub const UINT32_MAX = UINT32_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 4294967295, .decimal));
pub const INT_LEAST32_MIN = __INT_LEAST32_MIN;
pub const INT_LEAST32_MAX = __INT_LEAST32_MAX;
pub const UINT_LEAST32_MAX = __UINT_LEAST32_MAX;
pub const INT_FAST32_MIN = __INT_LEAST32_MIN;
pub const INT_FAST32_MAX = __INT_LEAST32_MAX;
pub const UINT_FAST32_MAX = __UINT_LEAST32_MAX;
pub const INT16_MAX = INT16_C(@as(c_int, 32767));
pub const INT16_MIN = -INT16_C(@as(c_int, 32767)) - @as(c_int, 1);
pub const UINT16_MAX = UINT16_C(@import("std").zig.c_translation.promoteIntLiteral(c_int, 65535, .decimal));
pub const INT_LEAST16_MIN = __INT_LEAST16_MIN;
pub const INT_LEAST16_MAX = __INT_LEAST16_MAX;
pub const UINT_LEAST16_MAX = __UINT_LEAST16_MAX;
pub const INT_FAST16_MIN = __INT_LEAST16_MIN;
pub const INT_FAST16_MAX = __INT_LEAST16_MAX;
pub const UINT_FAST16_MAX = __UINT_LEAST16_MAX;
pub const INT8_MAX = INT8_C(@as(c_int, 127));
pub const INT8_MIN = -INT8_C(@as(c_int, 127)) - @as(c_int, 1);
pub const UINT8_MAX = UINT8_C(@as(c_int, 255));
pub const INT_LEAST8_MIN = __INT_LEAST8_MIN;
pub const INT_LEAST8_MAX = __INT_LEAST8_MAX;
pub const UINT_LEAST8_MAX = __UINT_LEAST8_MAX;
pub const INT_FAST8_MIN = __INT_LEAST8_MIN;
pub const INT_FAST8_MAX = __INT_LEAST8_MAX;
pub const UINT_FAST8_MAX = __UINT_LEAST8_MAX;
pub const __INTN_MIN = @compileError("unable to translate macro: undefined identifier `INT`");
// C:\app\zig-windows-x86_64-0.13.0\lib\include/stdint.h:871:10
pub const __INTN_MAX = @compileError("unable to translate macro: undefined identifier `INT`");
// C:\app\zig-windows-x86_64-0.13.0\lib\include/stdint.h:872:10
pub const __UINTN_MAX = @compileError("unable to translate macro: undefined identifier `UINT`");
// C:\app\zig-windows-x86_64-0.13.0\lib\include/stdint.h:873:9
pub const __INTN_C = @compileError("unable to translate macro: undefined identifier `INT`");
// C:\app\zig-windows-x86_64-0.13.0\lib\include/stdint.h:874:10
pub const __UINTN_C = @compileError("unable to translate macro: undefined identifier `UINT`");
// C:\app\zig-windows-x86_64-0.13.0\lib\include/stdint.h:875:9
pub const INTPTR_MIN = -__INTPTR_MAX__ - @as(c_int, 1);
pub const INTPTR_MAX = __INTPTR_MAX__;
pub const UINTPTR_MAX = __UINTPTR_MAX__;
pub const PTRDIFF_MIN = -__PTRDIFF_MAX__ - @as(c_int, 1);
pub const PTRDIFF_MAX = __PTRDIFF_MAX__;
pub const SIZE_MAX = __SIZE_MAX__;
pub const INTMAX_MIN = -__INTMAX_MAX__ - @as(c_int, 1);
pub const INTMAX_MAX = __INTMAX_MAX__;
pub const UINTMAX_MAX = __UINTMAX_MAX__;
pub const SIG_ATOMIC_MIN = __INTN_MIN(__SIG_ATOMIC_WIDTH__);
pub const SIG_ATOMIC_MAX = __INTN_MAX(__SIG_ATOMIC_WIDTH__);
pub const WINT_MIN = __UINTN_C(__WINT_WIDTH__, @as(c_int, 0));
pub const WINT_MAX = __UINTN_MAX(__WINT_WIDTH__);
pub const WCHAR_MAX = __WCHAR_MAX__;
pub const WCHAR_MIN = __UINTN_C(__WCHAR_WIDTH__, @as(c_int, 0));
pub inline fn INTMAX_C(v: anytype) @TypeOf(__int_c(v, __INTMAX_C_SUFFIX__)) {
    _ = &v;
    return __int_c(v, __INTMAX_C_SUFFIX__);
}
pub inline fn UINTMAX_C(v: anytype) @TypeOf(__int_c(v, __UINTMAX_C_SUFFIX__)) {
    _ = &v;
    return __int_c(v, __UINTMAX_C_SUFFIX__);
}
pub const __STDDEF_H = "";
pub const __need_ptrdiff_t = "";
pub const __need_size_t = "";
pub const __need_wchar_t = "";
pub const __need_NULL = "";
pub const __need_max_align_t = "";
pub const __need_offsetof = "";
pub const _PTRDIFF_T = "";
pub const _SIZE_T = "";
pub const _WCHAR_T = "";
pub const NULL = @import("std").zig.c_translation.cast(?*anyopaque, @as(c_int, 0));
pub const __CLANG_MAX_ALIGN_T_DEFINED = "";
pub const offsetof = @compileError("unable to translate C expr: unexpected token 'an identifier'");
// C:\app\zig-windows-x86_64-0.13.0\lib\include/__stddef_offsetof.h:16:9
pub const __STDARG_H = "";
pub const __need___va_list = "";
pub const __need_va_list = "";
pub const __need_va_arg = "";
pub const __need___va_copy = "";
pub const __need_va_copy = "";
pub const __GNUC_VA_LIST = "";
pub const _VA_LIST = "";
pub const va_start = @compileError("unable to translate macro: undefined identifier `__builtin_va_start`");
// C:\app\zig-windows-x86_64-0.13.0\lib\include/__stdarg_va_arg.h:17:9
pub const va_end = @compileError("unable to translate macro: undefined identifier `__builtin_va_end`");
// C:\app\zig-windows-x86_64-0.13.0\lib\include/__stdarg_va_arg.h:19:9
pub const va_arg = @compileError("unable to translate C expr: unexpected token 'an identifier'");
// C:\app\zig-windows-x86_64-0.13.0\lib\include/__stdarg_va_arg.h:20:9
pub const __va_copy = @compileError("unable to translate macro: undefined identifier `__builtin_va_copy`");
// C:\app\zig-windows-x86_64-0.13.0\lib\include/__stdarg___va_copy.h:11:9
pub const va_copy = @compileError("unable to translate macro: undefined identifier `__builtin_va_copy`");
// C:\app\zig-windows-x86_64-0.13.0\lib\include/__stdarg_va_copy.h:11:9
pub const CIMGUI_DEFINE_ENUMS_AND_STRUCTS = @as(c_int, 1);
pub const IMGUI_HAS_DOCK = @as(c_int, 1);

[Process exited 0]
