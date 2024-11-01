// manually crafted translation for cimgui to zig
const std = @import("std");

// ImVector_int == i32 in zig,
pub const ConstCharPtrVector = extern struct {
    size: c_int,
    capacity: c_int,
    data: [*c][*c]const u8,
};

pub const CharVector = extern struct {
    size: c_int,
    capacity: c_int,
    data: [*c][*c]u8,
};

pub const WcharVector = extern struct { // typedef struct ImVector_ImWchar {
    size: c_int,
    capacity: c_int,
    data: [*c]Wchar,
};

const OldColumns = c_int;

// ImVector typedefs
pub const VectorInt = c_int; // ImVector_Int

// ImGui typedefs
// pub const Col = c_int; // ImGuiCol
// pub const Cond = c_int; // ImGuiCond
// pub const DataType = c_int; // ImGuiDataType
// pub const Dir = c_int; // ImGuiDir
// pub const Key = c_int; // ImGuiKey
// pub const NavInput = c_int; // ImGuiNavInput
// pub const MouseButton = c_int; // ImGuiMouseButton
// pub const MouseCursor = c_int; // ImGuiMouseCursor
// pub const SortDirection = c_int; // ImGuiSortDirection
// pub const StyleVar = c_int; // ImGuiStyleVar
// pub const TableBgTarget = c_int; // ImGuiTableBgTarget
// pub const BackendFlags = c_int; // ImGuiBackendFlags
// pub const ButtonFlags = c_int; // ImGuiButtonFlags
// pub const ColorEditFlags = c_int; // ImGuiColorEditFlags
// pub const ConfigFlags = c_int; // ImGuiConfigFlags
// pub const ComboFlags = c_int; // ImGuiComboFlags
// pub const DockNodeFlags = c_int; // ImGuiDockNodeFlags
// pub const DragDropFlags = c_int; // ImGuiDragDropFlags
// pub const FocusedFlags = c_int; // ImGuiFocusedFlags
// pub const HoveredFlags = c_int; // ImGuiHoveredFlags
// pub const InputTextFlags = c_int; // ImGuiInputTextFlags
// pub const ModFlags = c_int; // ImGuiModFlags
// pub const PopupFlags = c_int; // ImGuiPopupFlags
// pub const SelectableFlags = c_int; // ImGuiSelectableFlags
// pub const SliderFlags = c_int; // ImGuiSliderFlags
// pub const TabBarFlags = c_int; // ImGuiTabBarFlags
// pub const TabItemFlags = c_int; // ImGuiTabItemFlags
// pub const TableFlags = c_int; // ImGuiTableFlags
// pub const TableColumnFlags = c_int; // ImGuiTableColumnFlags
// pub const TableRowFlags = c_int; // ImGuiTableRowFlags
// pub const TreeNodeFlags = c_int; // ImGuiTreeNodeFlags
// pub const ViewportFlags = c_int; // ImGuiViewportFlags

// Im typedefs
//pub const DrawFlags = c_int; // ImDrawFlags
// pub const DrawListFlags = c_int; // ImDrawListFlags
// pub const FontAtlasFlags = c_int; // ImFontAtlasFlags
//

// Base Type Typedefs
pub const TextureID = ?*anyopaque; //ImTextureID;
pub const DrawIdx = c_ushort; //ImDrawIdx;
pub const ID = c_uint; // ImGuiID;
pub const S8 = i8; // ImS8;
pub const U8 = u8; // ImU8;
pub const S16 = c_short; // ImS16;
pub const U16 = c_ushort; // ImU16;
pub const S32 = c_int; // ImS32;
pub const U32 = c_uint; // ImU32;
pub const S64 = c_longlong; // ImS64;
pub const U64 = c_ulonglong; // ImU64;
pub const Wchar = c_ushort; // ImWchar;
pub const Wchar16 = c_ushort; // ImWchar16;
pub const Wchar32 = c_int; // ImWchar32;

pub const InputTextCallback = *fn (data: *InputTextCallbackData) c_int; // ImGuiInputTextCallback
pub const SizeCallback = *fn (data: *SizeCallbackData) void; // ImGuiInputTextCallback
pub const MemAllocFunc = *fn (sz: usize, user_data: ?*anyopaque) ?*anyopaque; // ImGuiMemAllocFunc
pub const MemFreeFunc = *fn (ptr: ?*anyopaque, user_data: ?*anyopaque) void; // ImMemAllocFunction

pub const Vec2 = extern struct { // ImVec2
    x: f32 = 0,
    y: f32 = 0,
};

pub const Vec4 = extern struct { // ImVec4
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
    w: f32 = 0,
};

pub const WindowFlags = packed struct(c_int) { // ImGuiWindowFlags
    no_title_bar: bool = false,
    no_resize: bool = false,
    no_move: bool = false,
    no_scrollbar: bool = false,
    no_scroll_with_mouse: bool = false,
    no_collapse: bool = false,
    always_auto_resize: bool = false,
    no_background: bool = false,
    no_saved_settings: bool = false,
    no_mouse_inputs: bool = false,
    menu_bar: bool = false,
    horizontal_scrollbar: bool = false,
    no_focus_on_appearing: bool = false,
    no_bring_to_front_on_focus: bool = false,
    always_vertical_scrollbar: bool = false,
    always_horizontal_scrollbar: bool = false,
    always_use_window_padding: bool = false,
    no_nav_inputs: bool = false,
    no_nav_focus: bool = false,
    unsaved_document: bool = false,
    no_docking: bool = false,
    reserved: u11 = 0, // reserved, don't use

    pub const no_nav: @This() = .{ .no_nav_inputs = true, .no_nav_focus = true };
    pub const no_decoration: @This() = .{ .no_title_bar = true, .no_resize = true, .no_scrollbar = true, .no_collapse = true };
    pub const no_inputs: @This() = .{ .no_mouse_inputs = true, .no_nav_inputs = true, .no_nav_focus = true };
};

pub const InputTextFlags = packed struct(c_int) { // ImGuiInputTextFlags
    chars_decimal: bool = false, // ImGuiInputTextFlags_CharsDecimal = 1 << 0
    chars_hexadecimal: bool = false, // ImGuiInputTextFlags_CharsHexadecimal = 1 << 1
    chars_uppercase: bool = false, // ImGuiInputTextFlags_CharsUppercase = 1 << 2
    no_blank: bool = false, // ImGuiInputTextFlags_CharsNoBlank = 1 << 3
    auto_select_all: bool = false, // ImGuiInputTextFlags_AutoSelectAll = 1 << 4
    enter_returns_true: bool = false, // ImGuiInputTextFlags_EnterReturnsTrue = 1 << 5
    callback_completion: bool = false, // ImGuiInputTextFlags_CallbackCompletion = 1 << 6,
    callback_history: bool = false, // ImGuiInputTextFlags_CallbackHistory = 1 << 7,
    callback_always: bool = false, // ImGuiInputTextFlags_CallbackAlways = 1 << 8,
    callback_char_filter: bool = false, // ImGuiInputTextFlags_CallbackCharFilter = 1 << 9,
    allow_tab_input: bool = false, // ImGuiInputTextFlags_AllowTabInput = 1 << 10,
    ctrl_enter_for_newline: bool = false, // ImGuiInputTextFlags_CtrlEnterForNewLine = 1 << 11,
    no_horizontal_scroll: bool = false, // ImGuiInputTextFlags_NoHorizontalScroll = 1 << 12,
    always_overwrite: bool = false, // ImGuiInputTextFlags_AlwaysOverwrite = 1 << 13,
    read_only: bool = false, // ImGuiInputTextFlags_ReadOnly = 1 << 14,
    password: bool = false, // ImGuiInputTextFlags_Password = 1 << 15,
    no_undo_redo: bool = false, // ImGuiInputTextFlags_NoUndoRedo = 1 << 16,
    chars_scientific: bool = false, // ImGuiInputTextFlags_CharsScientific = 1 << 17,
    callback_resize: bool = false, // ImGuiInputTextFlags_CallbackResize = 1 << 18,
    callback_edit: bool = false, // ImGuiInputTextFlags_CallbackEdit = 1 << 19
    reserved: u12 = 0, // reserved, don't use
};

pub const TreeNodeFlags = packed struct(c_int) {
    selected: bool = false, // ImGuiTreeNodeFlags_Selected = 1 << 0,
    framed: bool = false, // ImGuiTreeNodeFlags_Framed = 1 << 1,
    allow_item_overlap: bool = false, // ImGuiTreeNodeFlags_AllowItemOverlap = 1 << 2,
    no_tree_push_on_open: bool = false, // ImGuiTreeNodeFlags_NoTreePushOnOpen = 1 << 3,
    no_auto_open_on_log: bool = false, // ImGuiTreeNodeFlags_NoAutoOpenOnLog = 1 << 4,
    default_open: bool = false, // ImGuiTreeNodeFlags_DefaultOpen = 1 << 5,
    open_on_double_click: bool = false, // ImGuiTreeNodeFlags_OpenOnDoubleClick = 1 << 6,
    open_on_arrow: bool = false, // ImGuiTreeNodeFlags_OpenOnArrow = 1 << 7,
    leaf: bool = false, // ImGuiTreeNodeFlags_Leaf = 1 << 8,
    bullet: bool = false, // ImGuiTreeNodeFlags_Bullet = 1 << 9,
    frame_padding: bool = false, // ImGuiTreeNodeFlags_FramePadding = 1 << 10,
    span_avail_width: bool = false, // ImGuiTreeNodeFlags_SpanAvailWidth = 1 << 11,
    span_full_width: bool = false, // ImGuiTreeNodeFlags_SpanFullWidth = 1 << 12,
    nav_left_jumps_back_here: bool = false, // ImGuiTreeNodeFlags_NavLeftJumpsBackHere = 1 << 13,
    reserved: u18 = 0, // reserved, don't use

    pub const collapsing_header = .{ .framed = true, .no_tree_push_on_open = true, .no_auto_open_on_log = true };
};

pub const PopupFlags = packed struct(c_int) {
    mouse_button_left: bool = false, // ImGuiPopupFlags_MouseButtonLeft = 0,
    mouse_button_right: bool = false, // ImGuiPopupFlags_MouseButtonRight = 1,
    mouse_button_middle: bool = false, // ImGuiPopupFlags_MouseButtonMiddle = 2,
    mouse_button_mask: bool = false, // ImGuiPopupFlags_MouseButtonMask_ = 0x1F,
    mouse_button_default: bool = false, // ImGuiPopupFlags_MouseButtonDefault_ = 1,
    no_open_over_existing_popup: bool = false, // ImGuiPopupFlags_NoOpenOverExistingPopup = 1 << 5,
    no_open_over_items: bool = false, // ImGuiPopupFlags_NoOpenOverItems = 1 << 6,
    any_popup_id: bool = false, // ImGuiPopupFlags_AnyPopupId = 1 << 7,
    any_popup_level: bool = false, // ImGuiPopupFlags_AnyPopupLevel = 1 << 8,
    reserved: u23 = 0, // reserved, don't use

    pub const any_popup = .{ .any_popup_id = true, .any_popup_level = true };
};

pub const SelectableFlags = packed struct(c_int) {
    dont_close_popups: bool = false, // ImGuiSelectableFlags_DontClosePopups = 1 << 0,
    span_all_columns: bool = false, // ImGuiSelectableFlags_SpanAllColumns = 1 << 1,
    allow_double_click: bool = false, // ImGuiSelectableFlags_AllowDoubleClick = 1 << 2,
    disabled: bool = false, // ImGuiSelectableFlags_Disabled = 1 << 3,
    allow_item_overlap: bool = false, // ImGuiSelectableFlags_AllowItemOverlap = 1 << 4
    reserved: u27 = 0, // reserved, don't use
};

pub const ComboFlags = packed struct(c_int) {
    popup_align_left: bool = false, // ImGuiComboFlags_PopupAlignLeft = 1 << 0,
    height_small: bool = false, // ImGuiComboFlags_HeightSmall = 1 << 1,
    height_regular: bool = false, // ImGuiComboFlags_HeightRegular = 1 << 2,
    height_large: bool = false, // ImGuiComboFlags_HeightLarge = 1 << 3,
    height_largest: bool = false, // ImGuiComboFlags_HeightLargest = 1 << 4,
    no_arrow_button: bool = false, // ImGuiComboFlags_NoArrowButton = 1 << 5,
    no_preview: bool = false, // ImGuiComboFlags_NoPreview = 1 << 6,
    reserved: u25 = 0, // reserved, don't use

    pub const height_mask = .{ .height_small = true, .height_regular = true, .height_large = true, .height_largest = true };
};

pub const TabBarFlags = packed struct(c_int) {
    reorderable: bool = false, // ImGuiTabBarFlags_Reorderable = 1 << 0,
    auto_select_new_tabs: bool = false, // ImGuiTabBarFlags_AutoSelectNewTabs = 1 << 1,
    tab_list_popup_button: bool = false, // ImGuiTabBarFlags_TabListPopupButton = 1 << 2,
    no_close_with_middle_mouse_button: bool = false, // ImGuiTabBarFlags_NoCloseWithMiddleMouseButton = 1 << 3,
    no_tab_list_scrolling_buttons: bool = false, // ImGuiTabBarFlags_NoTabListScrollingButtons = 1 << 4,
    no_tooltip: bool = false, // ImGuiTabBarFlags_NoTooltip = 1 << 5,
    fitting_policy_resize_down: bool = false, // ImGuiTabBarFlags_FittingPolicyResizeDown = 1 << 6,
    fitting_policy_scroll: bool = false, // ImGuiTabBarFlags_FittingPolicyScroll = 1 << 7,
    reserved: u24 = 0, // reserved, don't use

    pub const fitting_policy_mask = .{ .fitting_policy_resize_down = true, .fitting_policy_scroll = true };
    pub const fitting_policy_default = .{ .fitting_policy_resize_down = true };
};

pub const TabItemFlags = packed struct(c_int) {
    unsaved_document: bool = false, // ImGuiTabItemFlags_UnsavedDocument = 1 << 0,
    set_selected: bool = false, // ImGuiTabItemFlags_SetSelected = 1 << 1,
    no_close_with_middle_mouse_button: bool = false, // ImGuiTabItemFlags_NoCloseWithMiddleMouseButton = 1 << 2,
    no_push_id: bool = false, // ImGuiTabItemFlags_NoPushId = 1 << 3,
    no_tooltip: bool = false, // ImGuiTabItemFlags_NoTooltip = 1 << 4,
    no_reorder: bool = false, // ImGuiTabItemFlags_NoReorder = 1 << 5,
    leading: bool = false, // ImGuiTabItemFlags_Leading = 1 << 6,
    trailing: bool = false, // ImGuiTabItemFlags_Trailing = 1 << 7
    reserved: u24 = 0, // reserved, don't use
};

pub const TableFlags = packed struct(c_int) {
    resizable: bool = false, // ImGuiTableFlags_Resizable = 1 << 0,
    reorderable: bool = false, // ImGuiTableFlags_Reorderable = 1 << 1,
    hideable: bool = false, // ImGuiTableFlags_Hideable = 1 << 2,
    sortable: bool = false, // ImGuiTableFlags_Sortable = 1 << 3,
    no_saved_settings: bool = false, // ImGuiTableFlags_NoSavedSettings = 1 << 4,
    context_menu_in_body: bool = false, // ImGuiTableFlags_ContextMenuInBody = 1 << 5,
    row_bg: bool = false, // ImGuiTableFlags_RowBg = 1 << 6,
    borders_inner_h: bool = false, // ImGuiTableFlags_BordersInnerH = 1 << 7,
    borders_outer_h: bool = false, // ImGuiTableFlags_BordersOuterH = 1 << 8,
    borders_inner_v: bool = false, // ImGuiTableFlags_BordersInnerV = 1 << 9,
    borders_outer_v: bool = false, // ImGuiTableFlags_BordersOuterV = 1 << 10,
    no_borders_in_body: bool = false, // ImGuiTableFlags_NoBordersInBody = 1 << 11,
    no_borders_in_body_until_resize: bool = false, // ImGuiTableFlags_NoBordersInBodyUntilResize = 1 << 12,
    sizing_fixed_fit: bool = false, // ImGuiTableFlags_SizingFixedFit = 1 << 13,
    sizing_fixed_same: bool = false, // ImGuiTableFlags_SizingFixedSame = 2 << 13,
    sizing_stretch_prop: bool = false, // ImGuiTableFlags_SizingStretchProp = 3 << 13,
    sizing_stretch_same: bool = false, // ImGuiTableFlags_SizingStretchSame = 4 << 13,
    no_host_extend_x: bool = false, // ImGuiTableFlags_NoHostExtendX = 1 << 16,
    no_host_extend_y: bool = false, // ImGuiTableFlags_NoHostExtendY = 1 << 17,
    no_keep_columns_visible: bool = false, // ImGuiTableFlags_NoKeepColumnsVisible = 1 << 18,
    precise_widths: bool = false, // ImGuiTableFlags_PreciseWidths = 1 << 19,
    no_clip: bool = false, // ImGuiTableFlags_NoClip = 1 << 20,
    pad_outer_x: bool = false, // ImGuiTableFlags_PadOuterX = 1 << 21,
    no_pad_outer_x: bool = false, // ImGuiTableFlags_NoPadOuterX = 1 << 22,
    no_pad_inner_x: bool = false, // ImGuiTableFlags_NoPadInnerX = 1 << 23,
    scroll_x: bool = false, // ImGuiTableFlags_ScrollX = 1 << 24,
    scroll_y: bool = false, // ImGuiTableFlags_ScrollY = 1 << 25,
    sort_multi: bool = false, // ImGuiTableFlags_SortMulti = 1 << 26,
    sort_tristate: bool = false, // ImGuiTableFlags_SortTristate = 1 << 27,
    reserved: u4 = 0,

    pub const borders_h = .{ .borders_inner_h = true, .borders_outer_h = true };
    pub const borders_v = .{ .borders_inner_v = true, .borders_outer_v = true };
    pub const borders_inner = .{ .borders_inner_v = true, .borders_inner_h = true };
    pub const borders_outer = .{ .borders_outer_v = true, .borders_outer_h = true };
    pub const borders = .{ .borders_inner = true, .borders_outer = true };
    pub const sizing_mask = .{ .sizing_fixed_fit = true, .sizing_fixed_same = true, .sizing_stretch_prop = true, .sizing_stretch_same = true };
};

pub const TableColumnFlags = packed struct(c_int) {
    disabled: bool = false, // ImGuiTableColumnFlags_Disabled = 1 << 0,
    default_hide: bool = false, // ImGuiTableColumnFlags_DefaultHide = 1 << 1,
    default_sort: bool = false, // ImGuiTableColumnFlags_DefaultSort = 1 << 2,
    width_stretch: bool = false, // ImGuiTableColumnFlags_WidthStretch = 1 << 3,
    width_fixed: bool = false, // ImGuiTableColumnFlags_WidthFixed = 1 << 4,
    no_resize: bool = false, // ImGuiTableColumnFlags_NoResize = 1 << 5,
    no_reorder: bool = false, // ImGuiTableColumnFlags_NoReorder = 1 << 6,
    no_hide: bool = false, // ImGuiTableColumnFlags_NoHide = 1 << 7,
    no_clip: bool = false, // ImGuiTableColumnFlags_NoClip = 1 << 8,
    no_sort: bool = false, // ImGuiTableColumnFlags_NoSort = 1 << 9,
    no_sort_ascending: bool = false, // ImGuiTableColumnFlags_NoSortAscending = 1 << 10,
    no_sort_descending: bool = false, // ImGuiTableColumnFlags_NoSortDescending = 1 << 11,
    no_header_label: bool = false, // ImGuiTableColumnFlags_NoHeaderLabel = 1 << 12,
    no_header_width: bool = false, // ImGuiTableColumnFlags_NoHeaderWidth = 1 << 13,
    prefer_sort_ascending: bool = false, // ImGuiTableColumnFlags_PreferSortAscending = 1 << 14,
    prefer_sort_descending: bool = false, // ImGuiTableColumnFlags_PreferSortDescending = 1 << 15,
    indent_enable: bool = false, // ImGuiTableColumnFlags_IndentEnable = 1 << 16,
    indent_disable: bool = false, // ImGuiTableColumnFlags_IndentDisable = 1 << 17,
    is_enabled: bool = false, // ImGuiTableColumnFlags_IsEnabled = 1 << 24,
    is_visible: bool = false, // ImGuiTableColumnFlags_IsVisible = 1 << 25,
    is_sorted: bool = false, // ImGuiTableColumnFlags_IsSorted = 1 << 26,
    is_hovered: bool = false, // ImGuiTableColumnFlags_IsHovered = 1 << 27,
    no_direct_resize: bool = false, // ImGuiTableColumnFlags_NoDirectResize_ = 1 << 30
    reserved: u2 = 0,

    pub const width_mask = .{ .width_stretch = true, .width_fixed = true };
    pub const indent_mask = .{ .indent_enable = true, .indent_disable = true };
    pub const status_mask = .{ .is_enabled = true, .is_visible = true, .is_sorted = true, .is_hovered = true };
};

pub const TableRowFlags = packed struct(c_int) {
    headers: bool = false, // ImGuiTableRowFlags_Headers = 1 << 0
    reserved: u31 = 0,
};

pub const TableBgTarget = packed struct(c_int) {
    row_bg0: bool = false, // ImGuiTableBgTarget_RowBg0 = 1,
    row_bg1: bool = false, // ImGuiTableBgTarget_RowBg1 = 2,
    cell_bg: bool = false, // ImGuiTableBgTarget_CellBg = 3
    reserved: u29 = 0, // reserved, don't use
};
pub const FocusedFlags = packed struct(c_int) {
    child_windows: bool = false, // ImGuiFocusedFlags_ChildWindows = 1 << 0,
    root_window: bool = false, // ImGuiFocusedFlags_RootWindow = 1 << 1,
    any_window: bool = false, // ImGuiFocusedFlags_AnyWindow = 1 << 2,
    no_popup_hierarchy: bool = false, // ImGuiFocusedFlags_NoPopupHierarchy = 1 << 3,
    dock_hierarchy: bool = false, // ImGuiFocusedFlags_DockHierarchy = 1 << 4,
    reserved: u27 = 0, // reserved, don't use

    pub const root_and_child_windows = .{ .root_window = true, .child_windows = true };
};
pub const HoveredFlags = packed struct(c_int) {
    child_windows: bool = false, // ImGuiHoveredFlags_ChildWindows = 1 << 0,
    root_window: bool = false, // ImGuiHoveredFlags_RootWindow = 1 << 1,
    any_window: bool = false, // ImGuiHoveredFlags_AnyWindow = 1 << 2,
    no_popup_hierarchy: bool = false, // ImGuiHoveredFlags_NoPopupHierarchy = 1 << 3,
    dock_hierarchy: bool = false, // ImGuiHoveredFlags_DockHierarchy = 1 << 4,
    allow_when_blocked_by_popup: bool = false, // ImGuiHoveredFlags_AllowWhenBlockedByPopup = 1 << 5,
    allow_when_blocked_by_active_item: bool = false, // ImGuiHoveredFlags_AllowWhenBlockedByActiveItem = 1 << 7,
    allow_when_overlapped: bool = false, // ImGuiHoveredFlags_AllowWhenOverlapped = 1 << 8,
    allow_when_disabled: bool = false, // ImGuiHoveredFlags_AllowWhenDisabled = 1 << 9,
    no_nav_override: bool = false, // ImGuiHoveredFlags_NoNavOverride = 1 << 10,
    reserved: u22 = 0, // reserved, don't use

    pub const rect_only = .{ .allow_when_blocked_by_popup = true, .allow_when_blocked_by_active_item = true, .allow_when_overlapped = true };
    pub const root_and_child_windows = .{ .root_window = true, .child_windows = true };
};
pub const DockNodeFlags = packed struct(c_int) {
    keep_alive_only: bool = false, // ImGuiDockNodeFlags_KeepAliveOnly = 1 << 0,
    no_docking_in_central_node: bool = false, // ImGuiDockNodeFlags_NoDockingInCentralNode = 1 << 2,
    passthru_central_node: bool = false, // ImGuiDockNodeFlags_PassthruCentralNode = 1 << 3,
    no_split: bool = false, // ImGuiDockNodeFlags_NoSplit = 1 << 4,
    no_resize: bool = false, // ImGuiDockNodeFlags_NoResize = 1 << 5,
    auto_hide_tab_bar: bool = false, // ImGuiDockNodeFlags_AutoHideTabBar = 1 << 6
    reserved: u26 = 0, // reserved, don't use
};
pub const DragDropFlags = packed struct(c_int) {
    source_no_preview_tooltip: bool = false, // ImGuiDragDropFlags_SourceNoPreviewTooltip = 1 << 0,
    source_no_disable_hover: bool = false, // ImGuiDragDropFlags_SourceNoDisableHover = 1 << 1,
    source_no_hold_to_open_others: bool = false, // ImGuiDragDropFlags_SourceNoHoldToOpenOthers = 1 << 2,
    source_allow_null_i_d: bool = false, // ImGuiDragDropFlags_SourceAllowNullID = 1 << 3,
    source_extern: bool = false, // ImGuiDragDropFlags_SourceExtern = 1 << 4,
    source_auto_expire_payload: bool = false, // ImGuiDragDropFlags_SourceAutoExpirePayload = 1 << 5,
    accept_before_delivery: bool = false, // ImGuiDragDropFlags_AcceptBeforeDelivery = 1 << 10,
    accept_no_draw_default_rect: bool = false, // ImGuiDragDropFlags_AcceptNoDrawDefaultRect = 1 << 11,
    accept_no_preview_tooltip: bool = false, // ImGuiDragDropFlags_AcceptNoPreviewTooltip = 1 << 12,
    reserved: u23 = 0, // reserved, don't use

    pub const accept_peek_only = .{ .accept_before_delivery = true, .accept_no_draw_default_rect = true };
};

// this is the only one that breaks naming schemes to keep it consistent
pub const DataType = enum(c_int) {
    S8,
    U8,
    S16,
    U16,
    S32,
    U32,
    S64,
    U64,
    Float,
    Double,
    COUNT,
    _,
};

pub const DataTypePrivate = enum(c_int) {
    String = DataType.COUNT,
    Pointer,
    ID,
    _,
};

pub const Dir = enum(c_int) {
    none = -1,
    left = 0,
    right = 1,
    up = 2,
    down = 3,
    _,
};
pub const SortDirection = enum(c_int) {
    none = 0,
    ascending = 1,
    descending = 2,
    _,
};

pub const Key = enum(c_int) {
    None = 0,
    Tab = 512,
    LeftArrow,
    RightArrow,
    UpArrow,
    DownArrow,
    PageUp,
    PageDown,
    Home,
    End,
    Insert,
    Delete,
    Backspace,
    Space,
    Enter,
    Escape,
    LeftCtrl,
    LeftShift,
    LeftAlt,
    LeftSuper,
    RightCtrl,
    RightShift,
    RightAlt,
    RightSuper,
    Menu,
    @"0",
    @"1",
    @"2",
    @"3",
    @"4",
    @"5",
    @"6",
    @"7",
    @"8",
    @"9",
    A,
    B,
    C,
    D,
    E,
    F,
    G,
    H,
    I,
    J,
    K,
    L,
    M,
    N,
    O,
    P,
    Q,
    R,
    S,
    T,
    U,
    V,
    W,
    X,
    Y,
    Z,
    F1,
    F2,
    F3,
    F4,
    F5,
    F6,
    F7,
    F8,
    F9,
    F10,
    F11,
    F12,
    Apostrophe,
    Comma,
    Minus,
    Period,
    Slash,
    Semicolon,
    Equal,
    LeftBracket,
    Backslash,
    RightBracket,
    GraveAccent,
    CapsLock,
    ScrollLock,
    NumLock,
    PrintScreen,
    Pause,
    Keypad0,
    Keypad1,
    Keypad2,
    Keypad3,
    Keypad4,
    Keypad5,
    Keypad6,
    Keypad7,
    Keypad8,
    Keypad9,
    KeypadDecimal,
    KeypadDivide,
    KeypadMultiply,
    KeypadSubtract,
    KeypadAdd,
    KeypadEnter,
    KeypadEqual,
    GamepadStart,
    GamepadBack,
    GamepadFaceUp,
    GamepadFaceDown,
    GamepadFaceLeft,
    GamepadFaceRight,
    GamepadDpadUp,
    GamepadDpadDown,
    GamepadDpadLeft,
    GamepadDpadRight,
    GamepadL1,
    GamepadR1,
    GamepadL2,
    GamepadR2,
    GamepadL3,
    GamepadR3,
    GamepadLStickUp,
    GamepadLStickDown,
    GamepadLStickLeft,
    GamepadLStickRight,
    GamepadRStickUp,
    GamepadRStickDown,
    GamepadRStickLeft,
    GamepadRStickRight,
    ModCtrl,
    ModShift,
    ModAlt,
    ModSuper,
    COUNT,
    _,
    // todo: figure this out.
    // NamedKey_BEGIN = 512,
    // NamedKey_END = Key.COUNT,
    // NamedKey_COUNT = Key.NamedKey_END - Key.NamedKey_BEGIN,
    // KeysData_SIZE = Key.COUNT,
    // KeysData_OFFSET = 0,
};

pub const NamedKeyCOUNT = Key.COUNT - 512;

pub const KeyPrivate = enum(c_int) {
    LegacyNative_BEGIN = 0,
    LegacyNative_END = 512,
    ImGuiKey_Gamepad_BEGIN = Key.GamepadStart,
    ImGuiKey_Gamepad_END = Key.GamepadRStickRight + 1,
};

pub const InputEventType = enum(c_int) {
    None = 0,
    MousePos,
    MouseWheel,
    MouseButton,
    MouseViewport,
    Key,
    Text,
    Focus,
    COUNT,
    _,
};

pub const InputSource = enum(c_int) {
    None = 0,
    Mouse,
    Keyboard,
    Gamepad,
    Clipboard,
    Nav,
    COUNT,
    _,
};

pub const NavReadMode = enum(c_int) {
    Down,
    Pressed,
    Released,
    Repeat,
    RepeatSlow,
    RepeatFast,
    _,
};

pub const ModFlags = packed struct(c_int) {
    ctrl: bool = false, // ImGuiModFlags_Ctrl = 1 << 0,
    shift: bool = false, // ImGuiModFlags_Shift = 1 << 1,
    alt: bool = false, // ImGuiModFlags_Alt = 1 << 2,
    super: bool = false, // ImGuiModFlags_Super = 1 << 3
    reserved: u28 = 0, // reserved, don't use
};

pub const NavInput = enum(c_int) {
    Activate,
    Cancel,
    Input,
    Menu,
    DpadLeft,
    DpadRight,
    DpadUp,
    DpadDown,
    LStickLeft,
    LStickRight,
    LStickUp,
    LStickDown,
    FocusPrev,
    FocusNext,
    TweakSlow,
    TweakFast,
    KeyLeft,
    KeyRight,
    KeyUp,
    KeyDown,
    COUNT,
    _,
};

pub const ConfigFlags = packed struct(c_int) {
    nav_enable_keyboard: bool = false, // ImGuiConfigFlags_NavEnableKeyboard = 1 << 0,
    nav_enable_gamepad: bool = false, // ImGuiConfigFlags_NavEnableGamepad = 1 << 1,
    nav_enable_set_mouse_pos: bool = false, // ImGuiConfigFlags_NavEnableSetMousePos = 1 << 2,
    nav_no_capture_keyboard: bool = false, // ImGuiConfigFlags_NavNoCaptureKeyboard = 1 << 3,
    no_mouse: bool = false, // ImGuiConfigFlags_NoMouse = 1 << 4,
    no_mouse_cursor_change: bool = false, // ImGuiConfigFlags_NoMouseCursorChange = 1 << 5,
    docking_enable: bool = false, // ImGuiConfigFlags_DockingEnable = 1 << 6,
    viewports_enable: bool = false, // ImGuiConfigFlags_ViewportsEnable = 1 << 10,
    dpi_enable_scale_viewports: bool = false, // ImGuiConfigFlags_DpiEnableScaleViewports = 1 << 14,
    dpi_enable_scale_fonts: bool = false, // ImGuiConfigFlags_DpiEnableScaleFonts = 1 << 15,
    is_s_r_g_b: bool = false, // ImGuiConfigFlags_IsSRGB = 1 << 20,
    is_touch_screen: bool = false, // ImGuiConfigFlags_IsTouchScreen = 1 << 21
    reserved: u20 = 0, // reserved, don't use
};

pub const BackendFlags = packed struct(c_int) {
    has_gamepad: bool = false, // ImGuiBackendFlags_HasGamepad = 1 << 0,
    has_mouse_cursors: bool = false, // ImGuiBackendFlags_HasMouseCursors = 1 << 1,
    has_set_mouse_pos: bool = false, // ImGuiBackendFlags_HasSetMousePos = 1 << 2,
    renderer_has_vtx_offset: bool = false, // ImGuiBackendFlags_RendererHasVtxOffset = 1 << 3,
    platform_has_viewports: bool = false, // ImGuiBackendFlags_PlatformHasViewports = 1 << 10,
    has_mouse_hovered_viewport: bool = false, // ImGuiBackendFlags_HasMouseHoveredViewport=1 << 11,
    renderer_has_viewports: bool = false, // ImGuiBackendFlags_RendererHasViewports = 1 << 12
    reserved: u25 = 0, // reserved, don't use
};

pub const StyleColor = enum(c_int) { // ImGuiCol
    Text,
    TextDisabled,
    WindowBg,
    ChildBg,
    PopupBg,
    Border,
    BorderShadow,
    FrameBg,
    FrameBgHovered,
    FrameBgActive,
    TitleBg,
    TitleBgActive,
    TitleBgCollapsed,
    MenuBarBg,
    ScrollbarBg,
    ScrollbarGrab,
    ScrollbarGrabHovered,
    ScrollbarGrabActive,
    CheckMark,
    SliderGrab,
    SliderGrabActive,
    Button,
    ButtonHovered,
    ButtonActive,
    Header,
    HeaderHovered,
    HeaderActive,
    Separator,
    SeparatorHovered,
    SeparatorActive,
    ResizeGrip,
    ResizeGripHovered,
    ResizeGripActive,
    Tab,
    TabHovered,
    TabActive,
    TabUnfocused,
    TabUnfocusedActive,
    DockingPreview,
    DockingEmptyBg,
    PlotLines,
    PlotLinesHovered,
    PlotHistogram,
    PlotHistogramHovered,
    TableHeaderBg,
    TableBorderStrong,
    TableBorderLight,
    TableRowBg,
    TableRowBgAlt,
    TextSelectedBg,
    DragDropTarget,
    NavHighlight,
    NavWindowingHighlight,
    NavWindowingDimBg,
    ModalWindowDimBg,
    COUNT,
    _,
};

pub const StyleVar = enum(c_int) {
    Alpha,
    DisabledAlpha,
    WindowPadding,
    WindowRounding,
    WindowBorderSize,
    WindowMinSize,
    WindowTitleAlign,
    ChildRounding,
    ChildBorderSize,
    PopupRounding,
    PopupBorderSize,
    FramePadding,
    FrameRounding,
    FrameBorderSize,
    ItemSpacing,
    ItemInnerSpacing,
    IndentSpacing,
    CellPadding,
    ScrollbarSize,
    ScrollbarRounding,
    GrabMinSize,
    GrabRounding,
    TabRounding,
    ButtonTextAlign,
    SelectableTextAlign,
    COUNT,
    _,
};

pub const ColorEditFlags = packed struct(c_int) {
    no_alpha: bool = false, // ImGuiColorEditFlags_NoAlpha = 1 << 1,
    no_picker: bool = false, // ImGuiColorEditFlags_NoPicker = 1 << 2,
    no_options: bool = false, // ImGuiColorEditFlags_NoOptions = 1 << 3,
    no_small_preview: bool = false, // ImGuiColorEditFlags_NoSmallPreview = 1 << 4,
    no_inputs: bool = false, // ImGuiColorEditFlags_NoInputs = 1 << 5,
    no_tooltip: bool = false, // ImGuiColorEditFlags_NoTooltip = 1 << 6,
    no_label: bool = false, // ImGuiColorEditFlags_NoLabel = 1 << 7,
    no_side_preview: bool = false, // ImGuiColorEditFlags_NoSidePreview = 1 << 8,
    no_drag_drop: bool = false, // ImGuiColorEditFlags_NoDragDrop = 1 << 9,
    no_border: bool = false, // ImGuiColorEditFlags_NoBorder = 1 << 10,
    alpha_bar: bool = false, // ImGuiColorEditFlags_AlphaBar = 1 << 16,
    alpha_preview: bool = false, // ImGuiColorEditFlags_AlphaPreview = 1 << 17,
    alpha_preview_half: bool = false, // ImGuiColorEditFlags_AlphaPreviewHalf= 1 << 18,
    h_d_r: bool = false, // ImGuiColorEditFlags_HDR = 1 << 19,
    display_r_g_b: bool = false, // ImGuiColorEditFlags_DisplayRGB = 1 << 20,
    display_h_s_v: bool = false, // ImGuiColorEditFlags_DisplayHSV = 1 << 21,
    display_hex: bool = false, // ImGuiColorEditFlags_DisplayHex = 1 << 22,
    uint8: bool = false, // ImGuiColorEditFlags_Uint8 = 1 << 23,
    float: bool = false, // ImGuiColorEditFlags_Float = 1 << 24,
    picker_hue_bar: bool = false, // ImGuiColorEditFlags_PickerHueBar = 1 << 25,
    picker_hue_wheel: bool = false, // ImGuiColorEditFlags_PickerHueWheel = 1 << 26,
    input_r_g_b: bool = false, // ImGuiColorEditFlags_InputRGB = 1 << 27,
    input_h_s_v: bool = false, // ImGuiColorEditFlags_InputHSV = 1 << 28,
    reserved: u9 = 0, // reserved, don't use

    pub const default_options = .{ .uint8 = true, .display_r_g_b = true, .input_r_g_b = true, .picker_hue_bar = true };
    pub const display_mask = .{ .display_r_g_b = true, .display_h_s_v = true, .display_hex = true };
    pub const data_type_mask = .{ .uint8 = true, .float = true };
    pub const picker_mask = .{ .picker_hue_wheel = true, .picker_hue_bar = true };
    pub const input_mask = .{ .input_r_g_b = true, .input_h_s_v = true };
};

pub const ButtonFlags = packed struct(c_int) {
    mouse_button_left: bool = false, // ImGuiButtonFlags_MouseButtonLeft = 1 << 0,
    mouse_button_right: bool = false, // ImGuiButtonFlags_MouseButtonRight = 1 << 1,
    mouse_button_middle: bool = false, // ImGuiButtonFlags_MouseButtonMiddle = 1 << 2,
    reserved: u29 = 0, // reserved, don't use

    pub const mouse_button_mask = .{ .mouse_button_left = true, .mouse_button_right = true, .mouse_button_middle = true };
    pub const mouse_button_default = .{ .mouse_button_left = true };
};

pub const SliderFlags = packed struct(c_int) {
    always_clamp: bool = false, // ImGuiSliderFlags_AlwaysClamp = 1 << 4,
    logarithmic: bool = false, // ImGuiSliderFlags_Logarithmic = 1 << 5,
    no_round_to_format: bool = false, // ImGuiSliderFlags_NoRoundToFormat = 1 << 6,
    no_input: bool = false, // ImGuiSliderFlags_NoInput = 1 << 7,
    reserved: u28 = 0, // reserved, don't use

    pub const InvalidMask: @This() = @bitCast(@as(c_int, 0x7000000F));
};

pub const MouseButton = enum(c_int) {
    Left = 0,
    Right = 1,
    Middle = 2,
    COUNT = 5,
    _,
};

pub const MouseCursor = enum(c_int) {
    None = -1,
    Arrow = 0,
    TextInput,
    ResizeAll,
    ResizeNS,
    ResizeEW,
    ResizeNESW,
    ResizeNWSE,
    Hand,
    NotAllowed,
    COUNT,
    _,
};

pub const Cond = packed struct(c_int) {
    always: bool = false, // ImGuiCond_Always = 1 << 0,
    once: bool = false, // ImGuiCond_Once = 1 << 1,
    first_use_ever: bool = false, // ImGuiCond_FirstUseEver = 1 << 2,
    appearing: bool = false, // ImGuiCond_Appearing = 1 << 3
    reserved: u28 = 0, // reserved, don't use
};

pub const Style = extern struct {
    alpha: f32,
    disabled_alpha: f32,
    window_padding: Vec2,
    window_rounding: f32,
    window_border_size: f32,
    window_min_size: Vec2,
    window_title_align: Vec2,
    window_menu_button_position: Dir,
    child_rounding: f32,
    child_border_size: f32,
    popup_rounding: f32,
    popup_border_size: f32,
    frame_padding: Vec2,
    frame_rounding: f32,
    frame_border_size: f32,
    item_spacing: Vec2,
    item_inner_spacing: Vec2,
    cell_padding: Vec2,
    touch_extra_padding: Vec2,
    indent_spacing: f32,
    columns_min_spacing: f32,
    scrollbar_size: f32,
    scrollbar_rounding: f32,
    grab_min_size: f32,
    grab_rounding: f32,
    log_slider_deadzone: f32,
    tab_rounding: f32,
    tab_border_size: f32,
    tab_min_width_for_close_button: f32,
    color_button_position: Dir,
    button_text_align: Vec2,
    selectable_text_align: Vec2,
    display_window_padding: Vec2,
    display_safe_area_padding: Vec2,
    mouse_cursor_scale: f32,
    anti_aliased_lines: bool,
    anti_aliased_lines_use_tex: bool,
    anti_aliased_fill: bool,
    curve_tessellation_tol: f32,
    circle_tessellation_max_error: f32,
    colors: [@as(usize, @intFromEnum(StyleColor.COUNT))]Vec4,

    pub inline fn setColor(self: *@This(), colorId: StyleColor, newColor: Vec4) void {
        self.colors[@as(usize, @intCast(@intFromEnum(colorId)))] = newColor;
    }
};

pub const KeyData = extern struct { // struct ImGuiKeyData
    down: bool,
    down_duration: f32,
    down_duration_prev: f32,
    analog_value: f32,
};

pub const FontAtlas = extern struct { // struct ImFontAtlas
    flags: FontAtlasFlags,
    tex_i_d: TextureID,
    tex_desired_width: c_int,
    tex_glyph_padding: c_int,
    locked: bool,
    tex_ready: bool,
    tex_pixels_use_colors: bool,
    tex_pixels_alpha8: [*c]u8,
    tex_pixels_rgba32: [*c]c_int,
    tex_width: c_int,
    tex_height: c_int,
    tex_uv_scale: Vec2,
    tex_uv_white_pixel: Vec2,
    fonts: FontPtrVector,
    custom_rects: FontAtlasCustomRect,
    font_config: FontConfig,
    tex_uv_lines: [64]Vec4,
    font_builder_io: [*c]const FontBuilderIO,
    font_builder_flags: c_uint,
    pack_id_mouse_cursors: c_int,
    pack_id_lines: c_int,
};

pub const FontAtlasCustomRect = extern struct { // struct ImFontAtlasCustomRect
    width: c_short,
    height: c_short,
    x: c_short,
    y: c_short,
    glyph_id: c_uint,
    glyph_advance_x: f32,
    glyph_offset: i32,
    font: [*c]Font,
};

pub const FontConfig = extern struct { // struct ImFontConfig
    font_data: ?*anyopaque,
    font_data_size: c_int,
    font_data_owned_by_atlas: bool,
    font_no: c_int,
    size_pixels: f32,
    oversample_h: c_int,
    oversample_v: c_int,
    pixel_snap_h: bool,
    glyph_extra_spacing: Vec2,
    glyph_offset: Vec2,
    glyph_ranges: [*c]const Wchar,
    glyph_min_advance_x: f32,
    glyph_max_advance_y: f32,
    merge_mode: bool,
    font_builder_flags: c_uint,
    rasterizer_multiply: f32,
    ellipsis_char: Wchar,
    name: [40]u8,
    dst_font: [*c]Font,
};

pub const Io = extern struct {
    config_flags: ConfigFlags, // ImGuiConfigFlags ConfigFlags;
    backend_flags: BackendFlags, // ImGuiBackendFlags BackendFlags;
    display_size: Vec2, // ImVec2 DisplaySize;
    delta_time: f32, // float DeltaTime;
    ini_saving_rate: f32, // float IniSavingRate;
    ini_file_name: [*c]const u8, // const char* IniFilename;
    log_filename: [*c]const u8, // const char* LogFilename;
    mouse_double_click_time: f32, // float MouseDoubleClickTime;
    mouse_double_click_max_dist: f32, // float MouseDoubleClickMaxDist;
    mouse_drag_threshold: f32, // float MouseDragThreshold;
    key_repeat_delay: f32, // float KeyRepeatDelay;
    key_repeat_rate: f32, // float KeyRepeatRate;
    user_data: ?*anyopaque, // void* UserData;
    fonts: [*c]FontAtlas, // ImFontAtlas*Fonts;
    font_global_scale: f32, // float FontGlobalScale;
    font_allow_user_scaling: bool, // bool FontAllowUserScaling;
    font_default: ?*anyopaque, // ImFont* FontDefault;
    display_framebuffer_scale: Vec2, // ImVec2 DisplayFramebufferScale;
    config_docking_no_split: bool, // bool ConfigDockingNoSplit;
    config_docking_with_shift: bool, // bool ConfigDockingWithShift;
    cofig_docking_always_tab_bar: bool, // bool ConfigDockingAlwaysTabBar;
    config_docking_transparent_payload: bool, // bool ConfigDockingTransparentPayload;
    config_viewports_no_auto_merge: bool, // bool ConfigViewportsNoAutoMerge;
    config_viewports_no_task_bar_icon: bool, // bool ConfigViewportsNoTaskBarIcon;
    config_viewports_no_decoration: bool, // bool ConfigViewportsNoDecoration;
    config_viewports_no_default_parent: bool, // bool ConfigViewportsNoDefaultParent;
    mouse_draw_cursor: bool, // bool MouseDrawCursor;
    config_macosx_behaviours: bool, // bool ConfigMacOSXBehaviors;
    config_input_trickle_event_queue: bool, // bool ConfigInputTrickleEventQueue;
    config_input_text_cursor_blink: bool, // bool ConfigInputTextCursorBlink;
    config_drag_click_to_input_text: bool, // bool ConfigDragClickToInputText;
    config_windows_resize_from_edges: bool, // bool ConfigWindowsResizeFromEdges;
    config_windows_move_from_title_bar_only: bool, // bool ConfigWindowsMoveFromTitleBarOnly;
    config_memory_compact_timer: f32, // float ConfigMemoryCompactTimer;
    backend_platform_name: [*c]const u8, // const char* BackendPlatformName;
    backend_renderer_name: [*c]const u8, // const char* BackendRendererName;
    backend_platform_user_data: ?*anyopaque, // void* BackendPlatformUserData;
    backend_renderer_user_data: ?*anyopaque, // void* BackendRendererUserData;
    backend_language_user_data: ?*anyopaque, // void* BackendLanguageUserData;
    //
    // const char* (*GetClipboardTextFn)(void* user_data);
    get_clipboard_text_fn: *const fn (?*anyopaque) callconv(.C) [*c]const u8,

    // void (*SetClipboardTextFn)(void* user_data, const char* text);
    set_clipboard_text_fn: *const fn (?*anyopaque, [*c]const u8) callconv(.C) void,
    clipboard_user_data: ?*anyopaque, // void* ClipboardUserData;

    // void (*SetPlatformImeDataFn)(ImGuiViewport* viewport, ImGuiPlatformImeData* data);
    set_platform_ime_data_fn: *const fn ([*c]Viewport, [*c]PlatformImeData) callconv(.C) void,

    _unused_padding: ?*anyopaque, // void* _UnusedPadding;
    want_capture_mouse: bool, // bool WantCaptureMouse;
    want_capture_keyboard: bool, // bool WantCaptureKeyboard;
    want_text_input: bool, // bool WantTextInput;
    want_set_mouse_pos: bool, // bool WantSetMousePos;
    want_save_ini_settings: bool, // bool WantSaveIniSettings;
    nav_active: bool, // bool NavActive;
    nav_visible: bool, // bool NavVisible;
    framerate: f32, // float Framerate;
    metrics_render_vertices: c_int, // int MetricsRenderVertices;
    metrics_render_indices: c_int, // int MetricsRenderIndices;
    metrics_render_windows: c_int, // int MetricsRenderWindows;
    metrics_active_windows: c_int, // int MetricsActiveWindows;
    metrics_active_allocations: c_int, // int MetricsActiveAllocations;
    mouse_delta: Vec2, // ImVec2 MouseDelta;
    key_map: [@as(usize, @intFromEnum(Key.COUNT))]c_int, // int KeyMap[ImGuiKey_COUNT];
    keys_down: [@as(usize, @intFromEnum(Key.COUNT))]bool, // bool KeysDown[ImGuiKey_COUNT];
    mouse_pos: Vec2, // ImVec2 MousePos;
    mouse_down: [5]bool, // bool MouseDown[5];
    mouse_wheel: f32, // float MouseWheel;
    mouse_wheel_h: f32, // float MouseWheelH;
    mouse_hovered_viewport: ID, // ImGuiID MouseHoveredViewport;
    key_ctrl: bool, // bool KeyCtrl;
    key_shift: bool, // bool KeyShift;
    key_alt: bool, // bool KeyAlt;
    key_super: bool, // bool KeySuper;
    nav_inputs: [@intFromEnum(NavInput.COUNT)]f32, // float NavInputs[ImGuiNavInput_COUNT];
    key_mods: ModFlags, // ImGuiModFlags KeyMods;
    keys_data: [@intFromEnum(Key.COUNT)]KeyData, // ImGuiKeyData KeysData[ImGuiKey_KeysData_SIZE]; -> KeysData_SIZE == COUNT
    want_capture_mouse_unless_popup_close: bool, // bool WantCaptureMouseUnlessPopupClose;
    mouse_pos_rev: Vec2, // ImVec2 MousePosPrev;
    mouse_clicked_pos: [5]Vec2, // ImVec2 MouseClickedPos[5];
    mouse_cliked_time: [5]f64, // double MouseClickedTime[5];
    mouse_clicked: [5]bool, // bool MouseClicked[5];
    mouse_double_clicked: [5]bool, // bool MouseDoubleClicked[5];
    mouse_clicked_count: [5]U16, // ImU16 MouseClickedCount[5];
    mouse_clicked_last_count: [5]U16, // ImU16 MouseClickedLastCount[5];
    mouse_released: [5]bool, // bool MouseReleased[5];
    mouse_down_owned: [5]bool, // bool MouseDownOwned[5];
    mouse_down_owned_unless_popup_close: [5]bool, // bool MouseDownOwnedUnlessPopupClose[5];
    mouse_down_duration: [5]f32, // float MouseDownDuration[5];
    mouse_down_duration_prev: [5]f32, // float MouseDownDurationPrev[5];
    mouse_drag_max_distance_abs: [5]f32, // ImVec2 MouseDragMaxDistanceAbs[5];
    mouse_drag_max_distance_sqr: [5]f32, // float MouseDragMaxDistanceSqr[5];
    nav_inputs_down_duration: [@intFromEnum(NavInput.COUNT)]f32, // float NavInputsDownDuration[ImGuiNavInput_COUNT];
    nav_inputs_down_duration_prev: [@intFromEnum(NavInput.COUNT)]f32, // float NavInputsDownDurationPrev[ImGuiNavInput_COUNT];
    pen_pressure: f32, // float PenPressure;
    app_focus_lost: bool, // bool AppFocusLost;
    app_accepting_events: bool, // bool AppAcceptingEvents;
    backend_using_legacy_key_arrays: S8, // ImS8 BackendUsingLegacyKeyArrays;
    backend_using_legacy_nav_input_array: bool, // bool BackendUsingLegacyNavInputArray;
    input_queue_surrogate: Wchar16, // ImWchar16 InputQueueSurrogate;
    input_queue_characters: WcharVector, // ImVector_ImWchar InputQueueCharacters;
};

pub const Viewport = extern struct { // struct ImGuiViewport
    id: ID,
    flags: ViewportFlags,
    pos: Vec2,
    size: Vec2,
    work_pos: Vec2,
    work_size: Vec2,
    dpi_scale: f32,
    parent_viewport_id: ID,
    draw_data: [*c]DrawData,
    renderer_user_data: ?*anyopaque,
    platform_user_data: ?*anyopaque,
    platform_handle: ?*anyopaque,
    platform_handle_raw: ?*anyopaque,
    platform_request_move: bool,
    platform_request_resize: bool,
    platform_request_close: bool,
};

pub const PlatformMonitorVector = extern struct { // struct ImVector_ImGuiPlatformMonitor
    size: c_int,
    capacity: c_int,
    data: [*c]PlatformMonitor,
};

pub const ViewportPtrVector = extern struct { // struct ImVector_ImGuiViewportPtr
    size: c_int,
    capacity: c_int,
    data: [*c][*c]Viewport,
};

pub const PlatformIO = extern struct { // struct ImGuiPlatformIO
    platform_create_window: *const fn ([*c]Viewport) callconv(.C) void,
    platform_destroy_window: *const fn ([*c]Viewport) callconv(.C) void,
    platform_show_window: *const fn ([*c]Viewport) callconv(.C) void,
    platform_set_window_pos: *const fn ([*c]Viewport, Vec2) callconv(.C) void,
    platform_get_window_pos: *const fn ([*c]Viewport) callconv(.C) Vec2,
    platform_set_window_size: *const fn ([*c]Viewport, Vec2) callconv(.C) void,
    platform_get_window_size: *const fn ([*c]Viewport) callconv(.C) Vec2,
    platform_set_window_focus: *const fn ([*c]Viewport) callconv(.C) void,
    platform_get_window_focus: *const fn ([*c]Viewport) callconv(.C) bool,
    platform_get_window_minimized: *const fn ([*c]Viewport) callconv(.C) bool,
    platform_set_window_title: *const fn ([*c]Viewport, [*c]const u8) callconv(.C) void,
    platform_set_window_alpha: *const fn ([*c]Viewport, f32) callconv(.C) void,
    platform_update_window: *const fn ([*c]Viewport) callconv(.C) void,
    platform_render_window: *const fn ([*c]Viewport, ?*anyopaque) callconv(.C) void,
    platform_swap_buffers: *const fn ([*c]Viewport, ?*anyopaque) callconv(.C) void,
    platform_get_window_dpi_scale: *const fn ([*c]Viewport) callconv(.C) f32,
    platform_on_changed_viewport: *const fn ([*c]Viewport) callconv(.C) void,
    platform_create_vk_surface: *const fn ([*c]Viewport, U64, [*c]const void, [*c]U64) callconv(.C) c_int,
    renderer_create_window: *const fn ([*c]Viewport) callconv(.C) void,
    renderer_destroy_window: *const fn ([*c]Viewport) callconv(.C) void,
    renderer_set_window_size: *const fn ([*c]Viewport, Vec2) callconv(.C) void,
    renderer_render_window: *const fn ([*c]Viewport, ?*anyopaque) callconv(.C) void,
    renderer_swap_buffers: *const fn ([*c]Viewport, ?*anyopaque) callconv(.C) void,
    monitors: PlatformMonitor,
    viewports: ViewportPtrVector,
};

pub const PlatformMonitor = extern struct { // struct ImGuiPlatformMonitor
    main_pos: Vec2,
    main_size: Vec2,
    work_pos: Vec2,
    work_size: Vec2,
    dpi_scale: f32,
};

pub const ViewportFlags = packed struct(c_int) {
    is_platform_window: bool = false, // cmGuiViewportFlags_IsPlatformWindow = 1 << 0,
    is_platform_monitor: bool = false, // ImGuiViewportFlags_IsPlatformMonitor = 1 << 1,
    owned_by_app: bool = false, // ImGuiViewportFlags_OwnedByApp = 1 << 2,
    no_decoration: bool = false, // ImGuiViewportFlags_NoDecoration = 1 << 3,
    no_task_bar_icon: bool = false, // ImGuiViewportFlags_NoTaskBarIcon = 1 << 4,
    no_focus_on_appearing: bool = false, // ImGuiViewportFlags_NoFocusOnAppearing = 1 << 5,
    no_focus_on_click: bool = false, // ImGuiViewportFlags_NoFocusOnClick = 1 << 6,
    no_inputs: bool = false, // ImGuiViewportFlags_NoInputs = 1 << 7,
    no_renderer_clear: bool = false, // ImGuiViewportFlags_NoRendererClear = 1 << 8,
    top_most: bool = false, // ImGuiViewportFlags_TopMost = 1 << 9,
    minimized: bool = false, // ImGuiViewportFlags_Minimized = 1 << 10,
    no_auto_merge: bool = false, // ImGuiViewportFlags_NoAutoMerge = 1 << 11,
    can_host_other_windows: bool = false, // ImGuiViewportFlags_CanHostOtherWindows = 1 << 12
    reserved: u19 = 0, // reserved, don't use
};

pub const DrawFlags = packed struct(c_int) {
    closed: bool = false, // ImDrawFlags_Closed = 1 << 0,
    round_corners_top_left: bool = false, // ImDrawFlags_RoundCornersTopLeft = 1 << 4,
    round_corners_top_right: bool = false, // ImDrawFlags_RoundCornersTopRight = 1 << 5,
    round_corners_bottom_left: bool = false, // ImDrawFlags_RoundCornersBottomLeft = 1 << 6,
    round_corners_bottom_right: bool = false, // ImDrawFlags_RoundCornersBottomRight = 1 << 7,
    round_corners_none: bool = false, // ImDrawFlags_RoundCornersNone = 1 << 8,
    reserved: u26 = 0, // reserved, don't use

    pub const round_corners_top = .{ .round_corners_top_left = true, .round_corners_top_right = true };
    pub const round_corners_bottom = .{ .round_corners_bottom_left = true, .round_corners_bottom_right = true };
    pub const round_corners_left = .{ .round_corners_bottom_left = true, .round_corners_top_left = true };
    pub const round_corners_right = .{ .round_corners_bottom_right = true, .round_corners_top_right = true };
    pub const round_corners_all = .{ .round_corners_top_left = true, .round_corners_top_right = true, .round_corners_bottom_left = true, .round_corners_bottom_right = true };
    pub const round_corners_default = .{ .round_corners_all = true };
    pub const round_corners_mask = .{ .round_corners_all = true, .round_corners_none = true };
};

pub const DrawListFlags = packed struct(c_int) {
    anti_aliased_lines: bool = false, // ImDrawListFlags_AntiAliasedLines = 1 << 0,
    anti_aliased_lines_use_tex: bool = false, // ImDrawListFlags_AntiAliasedLinesUseTex = 1 << 1,
    anti_aliased_fill: bool = false, // ImDrawListFlags_AntiAliasedFill = 1 << 2,
    allow_vtx_offset: bool = false, // ImDrawListFlags_AllowVtxOffset = 1 << 3
    reserved: u28 = 0, // reserved, don't use
};

pub const FontAtlasFlags = packed struct(c_int) {
    no_power_of_two_height: bool = false, // ImFontAtlasFlags_NoPowerOfTwoHeight = 1 << 0,
    no_mouse_cursors: bool = false, // ImFontAtlasFlags_NoMouseCursors = 1 << 1,
    no_baked_lines: bool = false, // ImFontAtlasFlags_NoBakedLines = 1 << 2
    reserved: u29 = 0, // reserved, don't use
};

pub const PlatformImeData = extern struct { // struct ImGuiPlatformImeData
    want_visible: bool,
    input_pos: Vec2,
    input_line_height: f32,
};

pub const StbUndoRecord = extern struct { // struct StbUndoRecord
    where: c_int,
    insert_length: c_int,
    delete_length: c_int,
    char_storage: c_int,
};

pub const StbUndoState = extern struct { // struct StbUndoState
    undo_rec: [99]StbUndoRecord,
    undo_char: [999]Wchar,
    undo_point: c_short,
    redo_point: c_short,
    undo_char_point: c_int,
    redo_char_point: c_int,
};

pub const StbTexteditState = extern struct { // struct STB_TexteditState
    cursor: c_int,
    select_start: c_int,
    select_end: c_int,
    insert_mode: u8,
    row_count_per_page: c_int,
    cursor_at_end_of_line: u8,
    initialized: u8,
    has_preferred_x: u8,
    single_line: u8,
    padding3: [3]u8,
    preferred_x: f32,
    undostate: StbUndoState,
};

pub const StbTexteditRow = extern struct { // struct StbTexteditRow
    x0: f32,
    x1: f32,
    baseline_y_delta: f32,
    ymin: f32,
    ymax: f32,
    num_chars: c_int,
};

pub const Vec1 = extern struct { // struct ImVec1
    x: f32,
};

pub const Rect = extern struct { // struct ImRect
    min: Vec2,
    max: Vec2,
};

pub const BitVector = extern struct { // struct ImBitVector
    storage: U32,
};

pub const Vec2ih = extern struct { // struct ImVec2ih
    x: c_short,
    y: c_short,
};

pub const PoolIdx = c_int;

pub const DrawListSharedData = extern struct { // struct ImDrawListSharedData
    tex_uv_white_pixel: Vec2,
    font: [*c]Font,
    font_size: f32,
    curve_tessellation_tol: f32,
    circle_segment_max_error: f32,
    clip_rect_fullscreen: Vec4,
    initial_flags: DrawListFlags,
    arc_fast_vtx: [48]Vec2,
    arc_fast_radius_cutoff: f32,
    circle_segment_counts: [64]U8,
    tex_uv_lines: [*c]const Vec4,
};

pub const DrawListPtrVector = extern struct { // struct ImVector_ImDrawListPtr
    size: c_int,
    capacity: c_int,
    data: [*c][*c]DrawList,
};

pub const DrawList = extern struct { // struct ImDrawList
    cmd_buffer: DrawCmd,
    idx_buffer: DrawIdx,
    vtx_buffer: DrawVert,
    flags: DrawListFlags,
    _vtx_current_idx: c_uint,
    _data: [*c]const DrawListSharedData,
    _owner_name: [*c]const u8,
    _vtx_write_ptr: [*c]DrawVert,
    _idx_write_ptr: [*c]DrawIdx,
    _clip_rect_stack: Vec4,
    _texture_id_stack: TextureID,
    _path: Vec2,
    _cmd_header: DrawCmdHeader,
    _splitter: DrawListSplitter,
    _fringe_scale: f32,
};

pub const DrawDataBuilder = extern struct { // struct ImDrawDataBuilder
    layers: [2]DrawListPtrVector,
};

pub const ItemFlags = packed struct(c_int) {
    no_tab_stop: bool = false, // ImGuiItemFlags_NoTabStop = 1 << 0,
    button_repeat: bool = false, // ImGuiItemFlags_ButtonRepeat = 1 << 1,
    disabled: bool = false, // ImGuiItemFlags_Disabled = 1 << 2,
    no_nav: bool = false, // ImGuiItemFlags_NoNav = 1 << 3,
    no_nav_default_focus: bool = false, // ImGuiItemFlags_NoNavDefaultFocus = 1 << 4,
    selectable_dont_close_popup: bool = false, // ImGuiItemFlags_SelectableDontClosePopup = 1 << 5,
    mixed_value: bool = false, // ImGuiItemFlags_MixedValue = 1 << 6,
    read_only: bool = false, // ImGuiItemFlags_ReadOnly = 1 << 7,
    inputable: bool = false, // ImGuiItemFlags_Inputable = 1 << 8
    reserved: u23 = 0, // reserved, don't use
};
pub const ItemStatusFlags = packed struct(c_int) {
    hovered_rect: bool = false, // ImGuiItemStatusFlags_HoveredRect = 1 << 0,
    has_display_rect: bool = false, // ImGuiItemStatusFlags_HasDisplayRect = 1 << 1,
    edited: bool = false, // ImGuiItemStatusFlags_Edited = 1 << 2,
    toggled_selection: bool = false, // ImGuiItemStatusFlags_ToggledSelection = 1 << 3,
    toggled_open: bool = false, // ImGuiItemStatusFlags_ToggledOpen = 1 << 4,
    has_deactivated: bool = false, // ImGuiItemStatusFlags_HasDeactivated = 1 << 5,
    deactivated: bool = false, // ImGuiItemStatusFlags_Deactivated = 1 << 6,
    hovered_window: bool = false, // ImGuiItemStatusFlags_HoveredWindow = 1 << 7,
    focused_by_tabbing: bool = false, // ImGuiItemStatusFlags_FocusedByTabbing = 1 << 8
    reserved: u23 = 0, // reserved, don't use
};

pub const SeparatorFlags = packed struct(c_int) {
    horizontal: bool = false, // ImGuiSeparatorFlags_Horizontal = 1 << 0,
    vertical: bool = false, // ImGuiSeparatorFlags_Vertical = 1 << 1,
    span_all_columns: bool = false, // ImGuiSeparatorFlags_SpanAllColumns = 1 << 2
    reserved: u29 = 0, // reserved, don't use
};

pub const TextFlags = packed struct(c_int) {
    no_width_for_large_clipped_text: bool = false, // ImGuiTextFlags_NoWidthForLargeClippedText = 1 << 0
    reserved: u31 = 0, // reserved, don't use
};

pub const TooltipFlags = packed struct(c_int) {
    override_previous_tooltip: bool = false, // ImGuiTooltipFlags_OverridePreviousTooltip = 1 << 0
    reserved: u31 = 0, // reserved, don't use
};

pub const LayoutType = enum(c_int) {
    Horizontal = 0,
    Vertical = 1,
    _,
};

pub const LogType = enum(c_int) {
    None = 0,
    TTY,
    File,
    Buffer,
    Clipboard,
    _,
};

pub const Axis = enum(c_int) {
    None = -1,
    X = 0,
    Y = 1,
    _,
};

pub const PlotType = enum(c_int) {
    Lines,
    Histogram,
    _,
};

pub const PopupPositionPolicy = enum(c_int) {
    Default,
    ComboBox,
    Tooltip,
    _,
};

pub const NextWindowDataFlags = packed struct(c_int) {
    has_pos: bool = false, // ImGuiNextWindowDataFlags_HasPos = 1 << 0,
    has_size: bool = false, // ImGuiNextWindowDataFlags_HasSize = 1 << 1,
    has_content_size: bool = false, // ImGuiNextWindowDataFlags_HasContentSize = 1 << 2,
    has_collapsed: bool = false, // ImGuiNextWindowDataFlags_HasCollapsed = 1 << 3,
    has_size_constraint: bool = false, // ImGuiNextWindowDataFlags_HasSizeConstraint = 1 << 4,
    has_focus: bool = false, // ImGuiNextWindowDataFlags_HasFocus = 1 << 5,
    has_bg_alpha: bool = false, // ImGuiNextWindowDataFlags_HasBgAlpha = 1 << 6,
    has_scroll: bool = false, // ImGuiNextWindowDataFlags_HasScroll = 1 << 7,
    has_viewport: bool = false, // ImGuiNextWindowDataFlags_HasViewport = 1 << 8,
    has_dock: bool = false, // ImGuiNextWindowDataFlags_HasDock = 1 << 9,
    has_window_class: bool = false, // ImGuiNextWindowDataFlags_HasWindowClass = 1 << 10
    reserved: u21 = 0, // reserved, don't use
};

pub const NextItemDataFlags = packed struct(c_int) {
    has_width: bool = false, // ImGuiNextItemDataFlags_HasWidth = 1 << 0,
    has_open: bool = false, // ImGuiNextItemDataFlags_HasOpen = 1 << 1
    reserved: u30 = 0, // reserved, don't use
};

pub const ActivateFlags = packed struct(c_int) {
    prefer_input: bool = false, // ImGuiActivateFlags_PreferInput = 1 << 0,
    prefer_tweak: bool = false, // ImGuiActivateFlags_PreferTweak = 1 << 1,
    try_to_preserve_state: bool = false, // ImGuiActivateFlags_TryToPreserveState = 1 << 2
    reserved: u29 = 0, // reserved, don't use
};
pub const ScrollFlags = packed struct(c_int) {
    keep_visible_edge_x: bool = false, // ImGuiScrollFlags_KeepVisibleEdgeX = 1 << 0,
    keep_visible_edge_y: bool = false, // ImGuiScrollFlags_KeepVisibleEdgeY = 1 << 1,
    keep_visible_center_x: bool = false, // ImGuiScrollFlags_KeepVisibleCenterX = 1 << 2,
    keep_visible_center_y: bool = false, // ImGuiScrollFlags_KeepVisibleCenterY = 1 << 3,
    always_center_x: bool = false, // ImGuiScrollFlags_AlwaysCenterX = 1 << 4,
    always_center_y: bool = false, // ImGuiScrollFlags_AlwaysCenterY = 1 << 5,
    no_scroll_parent: bool = false, // ImGuiScrollFlags_NoScrollParent = 1 << 6,
    reserved: u25 = 0, // reserved, don't use

    pub const mask_x = .{ .keep_visible_edge_x = true, .keep_visible_center_x = true, .always_center_x = true };
    pub const mask_y = .{ .keep_visible_edge_y = true, .keep_visible_center_y = true, .always_center_y = true };
};
pub const NavHighlightFlags = packed struct(c_int) {
    type_default: bool = false, // ImGuiNavHighlightFlags_TypeDefault = 1 << 0,
    type_thin: bool = false, // ImGuiNavHighlightFlags_TypeThin = 1 << 1,
    always_draw: bool = false, // ImGuiNavHighlightFlags_AlwaysDraw = 1 << 2,
    no_rounding: bool = false, // ImGuiNavHighlightFlags_NoRounding = 1 << 3
    reserved: u28 = 0, // reserved, don't use
};
pub const NavDirSourceFlags = packed struct(c_int) {
    raw_keyboard: bool = false, // ImGuiNavDirSourceFlags_RawKeyboard = 1 << 0,
    keyboard: bool = false, // ImGuiNavDirSourceFlags_Keyboard = 1 << 1,
    pad_d_pad: bool = false, // ImGuiNavDirSourceFlags_PadDPad = 1 << 2,
    pad_l_stick: bool = false, // ImGuiNavDirSourceFlags_PadLStick = 1 << 3
    reserved: u28 = 0, // reserved, don't use
};
pub const NavMoveFlags = packed struct(c_int) {
    loop_x: bool = false, // ImGuiNavMoveFlags_LoopX = 1 << 0,
    loop_y: bool = false, // ImGuiNavMoveFlags_LoopY = 1 << 1,
    wrap_x: bool = false, // ImGuiNavMoveFlags_WrapX = 1 << 2,
    wrap_y: bool = false, // ImGuiNavMoveFlags_WrapY = 1 << 3,
    allow_current_nav_id: bool = false, // ImGuiNavMoveFlags_AllowCurrentNavId = 1 << 4,
    also_score_visible_set: bool = false, // ImGuiNavMoveFlags_AlsoScoreVisibleSet = 1 << 5,
    scroll_to_edge_y: bool = false, // ImGuiNavMoveFlags_ScrollToEdgeY = 1 << 6,
    forwarded: bool = false, // ImGuiNavMoveFlags_Forwarded = 1 << 7,
    debug_no_result: bool = false, // ImGuiNavMoveFlags_DebugNoResult = 1 << 8,
    focus_api: bool = false, // ImGuiNavMoveFlags_FocusApi = 1 << 9,
    tabbing: bool = false, // ImGuiNavMoveFlags_Tabbing = 1 << 10,
    activate: bool = false, // ImGuiNavMoveFlags_Activate = 1 << 11,
    dont_set_nav_highlight: bool = false, // ImGuiNavMoveFlags_DontSetNavHighlight = 1 << 12
    reserved: u19 = 0, // reserved, don't use
};

pub const OldColumnFlags = packed struct(c_int) {
    no_border: bool = false, // ImGuiOldColumnFlags_NoBorder = 1 << 0,
    no_resize: bool = false, // ImGuiOldColumnFlags_NoResize = 1 << 1,
    no_preserve_widths: bool = false, // ImGuiOldColumnFlags_NoPreserveWidths = 1 << 2,
    no_force_within_window: bool = false, // ImGuiOldColumnFlags_NoForceWithinWindow = 1 << 3,
    grow_parent_contents_size: bool = false, // ImGuiOldColumnFlags_GrowParentContentsSize = 1 << 4
    reserved: u27 = 0, // reserved, don't use
};
pub const DebugLogFlags = packed struct(c_int) {
    event_active_id: bool = false, // ImGuiDebugLogFlags_EventActiveId = 1 << 0,
    event_focus: bool = false, // ImGuiDebugLogFlags_EventFocus = 1 << 1,
    event_popup: bool = false, // ImGuiDebugLogFlags_EventPopup = 1 << 2,
    event_nav: bool = false, // ImGuiDebugLogFlags_EventNav = 1 << 3,
    event_i_o: bool = false, // ImGuiDebugLogFlags_EventIO = 1 << 4,
    event_docking: bool = false, // ImGuiDebugLogFlags_EventDocking = 1 << 5,
    event_viewport: bool = false, // ImGuiDebugLogFlags_EventViewport = 1 << 6,
    output_to_t_t_y: bool = false, // ImGuiDebugLogFlags_OutputToTTY = 1 << 10
    reserved: u24 = 0, // reserved, don't use

    pub const event_mask = .{ .event_active_id = true, .event_focus = true, .event_popup = true, .event_nav = true, .event_i_o = true, .event_docking = true, .event_viewport = true };
};

pub const NavLayer = enum(c_int) {
    Main = 0,
    Menu = 1,
    COUNT,
    _,
};

pub const DataAuthority = enum(c_int) {
    Auto,
    DockNode,
    Window,
    _,
};

pub const DockNodeState = enum(c_int) {
    Unknown,
    HostWindowHiddenBecauseSingleWindow,
    HostWindowHiddenBecauseWindowsAreResizing,
    HostWindowVisible,
    _,
};

pub const WindowDockStyleCol = enum(c_int) {
    Text,
    Tab,
    TabHovered,
    TabActive,
    TabUnfocused,
    TabUnfocusedActive,
    COUNT,
    _,
};

pub const ContextHookType = enum(c_int) {
    NewFramePre,
    NewFramePost,
    EndFramePre,
    EndFramePost,
    RenderPre,
    RenderPost,
    Shutdown,
    PendingRemoval,
    _,
};

pub const DataTypeTempStorage = extern struct { // struct ImGuiDataTypeTempStorage
    data: [8]U8,
};

pub const DataTypeInfo = extern struct { // struct ImGuiDataTypeInfo
    size: usize,
    name: [*c]const u8,
    print_fmt: [*c]const u8,
    scan_fmt: [*c]const u8,
};

pub const ColorMod = extern struct { // struct ImGuiColorMod
    col: StyleColor,
    backup_value: Vec4,
};

// struct ImGuiStyleMod
// {
//     ImGuiStyleVar VarIdx;
//     union { int BackupInt[2]; float BackupFloat[2]; };
// };

pub const StyleMod = struct {
    VarIdx: StyleVar,
    Backup: union {
        int: [2]c_int,
        float: [2]f32,
    },
};

pub const ComboPreviewData = extern struct { // struct ImGuiComboPreviewData
    preview_rect: Rect,
    backup_cursor_pos: Vec2,
    backup_cursor_max_pos: Vec2,
    backup_cursor_pos_prev_line: Vec2,
    backup_prev_line_text_base_offset: f32,
    backup_layout: LayoutType,
};

pub const GroupData = extern struct { // struct ImGuiGroupData
    window_i_d: ID,
    backup_cursor_pos: Vec2,
    backup_cursor_max_pos: Vec2,
    backup_indent: Vec1,
    backup_group_offset: Vec1,
    backup_curr_line_size: Vec2,
    backup_curr_line_text_base_offset: f32,
    backup_active_id_is_alive: ID,
    backup_active_id_previous_frame_is_alive: bool,
    backup_hovered_id_is_alive: bool,
    emit_item: bool,
};

pub const MenuColumns = extern struct { // struct ImGuiMenuColumns
    total_width: U32,
    next_total_width: U32,
    spacing: U16,
    offset_icon: U16,
    offset_label: U16,
    offset_shortcut: U16,
    offset_mark: U16,
    widths: [4]U16,
};

pub const InputTextState = extern struct { // struct ImGuiInputTextState
    id: ID,
    cur_len_w: c_int,
    cur_len_a: c_int,
    text_w: WcharVector,
    text_a: CharVector,
    initial_text_a: CharVector,
    text_a_is_valid: bool,
    buf_capacity_a: c_int,
    scroll_x: f32,
    stb: StbTexteditState,
    cursor_anim: f32,
    cursor_follow: bool,
    selected_all_mouse_lock: bool,
    edited: bool,
    flags: InputTextFlags,
};

pub const PopupData = extern struct { // struct ImGuiPopupData
    popup_id: ID,
    window: [*c]Window,
    source_window: [*c]Window,
    parent_nav_layer: c_int,
    open_frame_count: c_int,
    open_parent_id: ID,
    open_popup_pos: Vec2,
    open_mouse_pos: Vec2,
};

pub const NextWindowData = extern struct { // struct ImGuiNextWindowData
    flags: NextWindowDataFlags,
    pos_cond: Cond,
    size_cond: Cond,
    collapsed_cond: Cond,
    dock_cond: Cond,
    pos_val: Vec2,
    pos_pivot_val: Vec2,
    size_val: Vec2,
    content_size_val: Vec2,
    scroll_val: Vec2,
    pos_undock: bool,
    collapsed_val: bool,
    size_constraint_rect: Rect,
    size_callback: SizeCallback,
    size_callback_user_data: ?*anyopaque,
    bg_alpha_val: f32,
    viewport_id: ID,
    dock_id: ID,
    window_class: WindowClass,
    menu_bar_offset_min_val: Vec2,
};

pub const NextItemData = extern struct { // struct ImGuiNextItemData
    flags: NextItemDataFlags,
    width: f32,
    focus_scope_id: ID,
    open_cond: Cond,
    open_val: bool,
};

pub const LastItemData = extern struct { // struct ImGuiLastItemData
    id: ID,
    in_flags: ItemFlags,
    status_flags: ItemStatusFlags,
    rect: Rect,
    nav_rect: Rect,
    display_rect: Rect,
};

pub const StackSizes = extern struct { // struct ImGuiStackSizes
    size_of_id_stack: c_short,
    size_of_color_stack: c_short,
    size_of_style_var_stack: c_short,
    size_of_font_stack: c_short,
    size_of_focus_scope_stack: c_short,
    size_of_group_stack: c_short,
    size_of_item_flags_stack: c_short,
    size_of_begin_popup_stack: c_short,
    size_of_disabled_stack: c_short,
};

pub const WindowStackData = extern struct { // struct ImGuiWindowStackData
    window: [*c]Window,
    parent_last_item_data_backup: LastItemData,
    stack_sizes_on_begin: StackSizes,
};

pub const PtrOrIndex = extern struct { // struct ImGuiPtrOrIndex
    ptr: ?*anyopaque,
    index: c_int,
};

pub const BitArrayForNamedKeys = extern struct { // struct ImBitArrayForNamedKeys
    storage: [(NamedKeyCOUNT + 31) >> 5]U32,
};

pub const InputEventMousePos = extern struct { // struct ImGuiInputEventMousePos
    pos_x: f32,
    pos_y: f32,
};

pub const InputEventMouseWheel = extern struct { // struct ImGuiInputEventMouseWheel
    wheel_x: f32,
    wheel_y: f32,
};

pub const InputEventMouseButton = extern struct { // struct ImGuiInputEventMouseButton
    button: c_int,
    down: bool,
};

pub const InputEventMouseViewport = extern struct { // struct ImGuiInputEventMouseViewport
    hovered_viewport_i_d: ID,
};

pub const InputEventKey = extern struct { // struct ImGuiInputEventKey
    key: Key,
    down: bool,
    analog_value: f32,
};

pub const InputEventText = extern struct { // struct ImGuiInputEventText
    char: c_uint,
};

pub const InputEventAppFocused = extern struct { // struct ImGuiInputEventAppFocused
    focused: bool,
};

pub const InputEvent = extern struct { // struct ImGuiInputEvent
    type: InputEventType,
    source: InputSource,
    events: extern union {
        mouse_pos: InputEventMousePos,
        mouse_wheel: InputEventMouseWheel,
        mouse_button: InputEventMouseButton,
        mouse_viewport: InputEventMouseViewport,
        key: InputEventKey,
        text: InputEventText,
        app_focused: InputEventAppFocused,
    },
    added_by_test_engine: bool,
};

pub const ListClipperRange = extern struct { // struct ImGuiListClipperRange
    min: c_int,
    max: c_int,
    pos_to_index_convert: bool,
    pos_to_index_offset_min: S8,
    pos_to_index_offset_max: S8,
};

pub const ListClipperData = extern struct { // struct ImGuiListClipperData
    list_clipper: [*c]ListClipper,
    lossyness_offset: f32,
    step_no: c_int,
    items_frozen: c_int,
    ranges: ListClipperRangeVector,
};

pub const ListClipperRangeVector = extern struct { // struct ImVector_ImGuiListClipperRange
    size: c_int,
    capacity: c_int,
    data: [*c]ListClipperRange,
};

pub const NavItemData = extern struct { // struct ImGuiNavItemData
    window: [*c]Window,
    id: ID,
    focus_scope_id: ID,
    rect_rel: Rect,
    in_flags: ItemFlags,
    dist_box: f32,
    dist_center: f32,
    dist_axial: f32,
};

pub const OldColumnData = extern struct { // struct ImGuiOldColumnData
    offset_norm: f32,
    offset_norm_before_resize: f32,
    flags: OldColumnFlags,
    clip_rect: Rect,
};

pub const OldColumnDataVector = extern struct { // struct ImVector_ImGuiOldColumnData
    size: c_int,
    capacity: c_int,
    data: [*c]OldColumnData,
};

pub const WindowPtrVector = extern struct { // struct ImVector_ImGuiWindowPtr
    size: c_int,
    capacity: c_int,
    data: [*c]Window,
};

pub const WindowDockStyle = extern struct { // struct ImGuiWindowDockStyle
    colors: [WindowDockStyleCol.COUNT]U32,
};

pub const DockRequestVector = extern struct { // struct ImVector_ImGuiDockRequest
    size: c_int,
    capacity: c_int,
    data: [*c]DockRequest,
};

pub const DockNodeSettingsVector = extern struct { // struct ImVector_ImGuiDockNodeSettings
    size: c_int,
    capacity: c_int,
    data: [*c]DockNodeSettings,
};

pub const DockContext = extern struct { // struct ImGuiDockContext
    nodes: Storage,
    requests: DockRequestVector,
    nodes_settings: DockNodeSettingsVector,
    want_full_rebuild: bool,
};

pub const ViewportP = extern struct { // struct ImGuiViewportP
    _imgui_viewport: Viewport,
    idx: c_int,
    last_frame_active: c_int,
    last_front_most_stamp_count: c_int,
    last_name_hash: ID,
    last_pos: Vec2,
    alpha: f32,
    last_alpha: f32,
    platform_monitor: c_short,
    platform_window_created: bool,
    window: [*c]Window,
    draw_lists_last_frame: [2]c_int,
    draw_lists: [2][*c]DrawList,
    draw_data_p: DrawData,
    draw_data_builder: DrawDataBuilder,
    last_platform_pos: Vec2,
    last_platform_size: Vec2,
    last_renderer_size: Vec2,
    work_offset_min: Vec2,
    work_offset_max: Vec2,
    build_work_offset_min: Vec2,
    build_work_offset_max: Vec2,
};

pub const WindowSettings = extern struct { // struct ImGuiWindowSettings
    i_d: ID,
    pos: Vec2ih,
    size: Vec2ih,
    viewport_pos: Vec2ih,
    viewport_id: ID,
    dock_id: ID,
    class_id: ID,
    dock_order: c_short,
    collapsed: bool,
    want_apply: bool,
};

pub const SettingsHandler = extern struct { // struct ImGuiSettingsHandler
    type_name: [*c]const u8,
    type_hash: ID,
    clear_all_fn: *const fn ([*c]Context, [*c]SettingsHandler) void,
    read_init_fn: *const fn ([*c]Context, [*c]SettingsHandler) void,
    read_open_fn: *const fn ([*c]Context, [*c]SettingsHandler, [*c]const u8) ?*anyopaque,
    read_line_fn: *const fn ([*c]Context, [*c]SettingsHandler, ?*anyopaque, [*c]const u8) void,
    apply_all_fn: *const fn ([*c]Context, [*c]SettingsHandler) void,
    write_all_fn: *const fn ([*c]Context, [*c]SettingsHandler, [*c]TextBuffer) void,
    user_data: ?*anyopaque,
};

pub const MetricsConfig = extern struct { // struct ImGuiMetricsConfig
    show_debug_log: bool,
    show_stack_tool: bool,
    show_windows_rects: bool,
    show_windows_begin_order: bool,
    show_tables_rects: bool,
    show_draw_cmd_mesh: bool,
    show_draw_cmd_bounding_boxes: bool,
    show_docking_nodes: bool,
    show_windows_rects_type: c_int,
    show_tables_rects_type: c_int,
};

pub const StackLevelInfoVector = extern struct { // struct ImVector_ImGuiStackLevelInfo
    size: c_int,
    capacity: c_int,
    data: [*c]StackLevelInfo,
};

pub const StackTool = extern struct { // struct ImGuiStackTool
    last_active_frame: c_int,
    stack_level: c_int,
    query_id: ID,
    results: StackLevelInfoVector,
    copy_to_clipboard_on_ctrl_c: bool,
    copy_to_clipboard_last_time: f32,
};

pub const ContextHook = extern struct { // struct ImGuiContextHook
    hook_id: ID,
    type: ContextHookType,
    owner: ID,
    callback: ContextHookCallback,
    user_data: ?*anyopaque,
};

pub const InputEventVector = extern struct { // struct ImVector_ImGuiInputEvent
    size: c_int,
    capacity: c_int,
    data: [*c]InputEvent,
};

pub const WindowStackDataVector = extern struct { // struct ImVector_ImGuiWindowStackData
    size: c_int,
    capacity: c_int,
    data: [*c]WindowStackData,
};

pub const ColorModVector = extern struct { // struct ImVector_ImGuiColorMod
    size: c_int,
    capacity: c_int,
    data: [*c]ColorMod,
};

pub const StyleModVector = extern struct { // struct ImGuiStyleMod
    size: c_int,
    capacity: c_int,
    data: [*c]StyleMod,
};

pub const IDVector = extern struct { // struct ImGuiID
    size: c_int,
    capacity: c_int,
    data: [*c]ID,
};

pub const ItemFlagsVector = extern struct { // struct ImGuiItemFlags
    size: c_int,
    capacity: c_int,
    data: [*c]ItemFlags,
};

pub const GroupDataVector = extern struct { // struct ImGuiGroupData
    size: c_int,
    capacity: c_int,
    data: [*c]GroupData,
};

pub const PopupDataVector = extern struct { // struct ImGuiPopupData
    size: c_int,
    capacity: c_int,
    data: [*c]PopupData,
};

pub const ViewportPPtrVector = extern struct { // struct ImGuiViewportPPtr
    size: c_int,
    capacity: c_int,
    data: [*c][*c]ViewportP,
};

pub const ListClipperDataVector = extern struct { // struct ImGuiListClipperData
    size: c_int,
    capacity: c_int,
    data: [*c]ListClipperData,
};

pub const TableTempDataVector = extern struct { // struct ImVector_ImGuiTableTempData
    size: c_int,
    capacity: c_int,
    data: [*c]TableTempData,
};

pub const TableVector = extern struct { // struct ImVector_ImGuiTable
    size: c_int,
    capacity: c_int,
    data: [*c]Table,
};

pub const TabBarVector = extern struct { // struct ImVector_ImGuiTabBar
    size: c_int,
    capacity: c_int,
    data: [*c]TabBar,
};

pub const PtrOrIndexVector = extern struct { // struct ImVector_ImGuiPtrOrIndex
    size: c_int,
    capacity: c_int,
    data: [*c]PtrOrIndex,
};

pub const ShrinkWidthItemVector = extern struct { // struct ImVector_ImGuiShrinkWidthItem
    size: c_int,
    capacity: c_int,
    data: [*c]ShrinkWidthItem,
};

pub const ShrinkWidthItem = extern struct { // struct ImVector_ImGuiShrinkWidthItem
    index: c_int,
    width: f32,
    initial_width: f32,
};

pub const SettingsHandlerVector = extern struct { // struct ImVector_ImGuiSettingsHandler
    size: c_int,
    capacity: c_int,
    data: [*c]SettingsHandler,
};

pub const ContextHookVector = extern struct { // struct ImVector_ImGuiContextHook
    size: c_int,
    capacity: c_int,
    data: [*c]ContextHook,
};

pub const u8Vector = extern struct { // struct ImVector_unsigned_char
    size: c_int,
    capacity: c_int,
    data: [*c]u8,
};

pub const TablePool = extern struct { // struct ImPool_ImGuiTable
    buf: TableVector,
    map: Storage,
    free_idx: PoolIdx,
    alive_count: PoolIdx,
};

pub const TabBarPool = extern struct { // struct ImPool_ImGuiTabBar
    buf: TabBarVector,
    map: Storage,
    free_idx: PoolIdx,
    alive_count: PoolIdx,
};

pub const TabItemVector = extern struct { // struct ImVector_ImGuiTabItem
    size: c_int,
    capacity: c_int,
    data: [*c]TabItem,
};

pub const WindowSettingsChunkStream = extern struct { // struct ImChunkStream_ImGuiWindowSettings
    buf: u8Vector,
};

pub const TableSettingsChunkStream = extern struct { // struct ImChunkStream_ImGuiTableSettings
    buf: u8Vector,
};

pub const TabItem = extern struct { // struct ImGuiTabItem
    i_d: ID,
    flags: TabItemFlags,
    window: [*c]Window,
    last_frame_visible: c_int,
    last_frame_selected: c_int,
    offset: f32,
    width: f32,
    content_width: f32,
    requested_width: f32,
    name_offset: S32,
    begin_order: S16,
    index_during_layout: S16,
    want_close: bool,
};

pub const TabBar = extern struct { // struct ImGuiTabBar
    tabs: TabItemVector,
    flags: TabBarFlags,
    i_d: ID,
    selected_tab_id: ID,
    next_selected_tab_id: ID,
    visible_tab_id: ID,
    curr_frame_visible: c_int,
    prev_frame_visible: c_int,
    bar_rect: Rect,
    curr_tabs_contents_height: f32,
    prev_tabs_contents_height: f32,
    width_all_tabs: f32,
    width_all_tabs_ideal: f32,
    scrolling_anim: f32,
    scrolling_target: f32,
    scrolling_target_dist_to_visibility: f32,
    scrolling_speed: f32,
    scrolling_rect_min_x: f32,
    scrolling_rect_max_x: f32,
    reorder_request_tab_id: ID,
    reorder_request_offset: S16,
    begin_count: S8,
    want_layout: bool,
    visible_tab_was_submitted: bool,
    tabs_added_new: bool,
    tabs_active_count: S16,
    last_tab_item_idx: S16,
    item_spacing_y: f32,
    frame_padding: Vec2,
    backup_cursor_pos: Vec2,
    tabs_names: TextBuffer,
};

pub const TableTempData = extern struct { // struct ImGuiTableTempData
    table_index: c_int,
    last_time_active: f32,
    user_outer_size: Vec2,
    draw_splitter: DrawListSplitter,
    host_backup_work_rect: Rect,
    host_backup_parent_work_rect: Rect,
    host_backup_prev_line_size: Vec2,
    host_backup_curr_line_size: Vec2,
    host_backup_cursor_max_pos: Vec2,
    host_backup_columns_offset: Vec1,
    host_backup_item_width: f32,
    host_backup_item_width_stack_size: c_int,
};
pub const ContextHookCallback = *const fn ([*c]Context, [*c]ContextHook) void;

pub const TableSettings = extern struct { // struct ImGuiTableSettings
    id: ID,
    save_flags: TableFlags,
    ref_scale: f32,
    columns_count: TableColumnIdx,
    columns_count_max: TableColumnIdx,
    want_apply: bool,
};

pub const FontBuilderIO = extern struct { // struct ImFontBuilderIO
    font_builder_build: *const fn ([*c]FontAtlas) callconv(.C) bool,
};

pub const TableCellData = extern struct { // struct ImGuiTableCellData
    bg_color: U32,
    column: TableColumnIdx,
};

pub const TableInstanceData = extern struct { // struct ImGuiTableInstanceData
    last_outer_height: f32,
    last_first_row_height: f32,
};

pub const TableColumnSpan = extern struct { // struct ImSpan_ImGuiTableColumn
    data: [*c]TableColumn,
    data_end: [*c]TableColumn,
};

pub const TableColumnIdxSpan = extern struct { // struct ImSpan_ImGuiTableColumnIdx
    data: [*c]TableColumnIdx,
    data_end: [*c]TableColumnIdx,
};

pub const TableCellDataSpan = extern struct { // struct ImSpan_ImGuiTableCellData
    data: [*c]TableCellData,
    data_end: [*c]TableCellData,
};

pub const TableInstanceDataVector = extern struct { // struct ImVector_ImGuiTableInstanceData
    size: c_int,
    capacity: c_int,
    data: [*c]TableInstanceData,
};

pub const TableColumnSortSpecsVector = extern struct { // struct ImVector_ImGuiTableColumnSortSpecs
    size: c_int,
    capacity: c_int,
    data: [*c]TableColumnSortSpecs,
};

pub const TextBuffer = extern struct { // struct ImGuiTextBuffer
    buf: u8Vector,
};

pub const TableColumnIdx = S8; // ImGuiTableColumnIdx
pub const TableDrawChannelIdx = U8; // ImGuiTableDrawChannelIdx

pub const Context = extern struct { // struct ImGuiContext
    initialized: bool,
    font_atlas_owned_by_context: bool,
    io: Io,
    platform_i_o: PlatformIO,
    input_events_queue: InputEventVector,
    input_events_trail: InputEventVector,
    style: Style,
    config_flags_curr_frame: ConfigFlags,
    config_flags_last_frame: ConfigFlags,
    font: [*c]Font,
    font_size: f32,
    font_base_size: f32,
    draw_list_shared_data: DrawListSharedData,
    time: f64,
    frame_count: c_int,
    frame_count_ended: c_int,
    frame_count_platform_ended: c_int,
    frame_count_rendered: c_int,
    within_frame_scope: bool,
    within_frame_scope_with_implicit_window: bool,
    within_end_child: bool,
    gc_compact_all: bool,
    test_engine_hook_items: bool,
    test_engine: ?*anyopaque,
    windows: WindowPtrVector,
    windows_focus_order: WindowPtrVector,
    windows_temp_sort_buffer: WindowPtrVector,
    current_window_stack: WindowStackDataVector,
    windows_by_id: Storage,
    windows_active_count: c_int,
    windows_hover_padding: Vec2,
    current_window: [*c]Window,
    hovered_window: [*c]Window,
    hovered_window_under_moving_window: [*c]Window,
    hovered_dock_node: [*c]DockNode,
    moving_window: [*c]Window,
    wheeling_window: [*c]Window,
    wheeling_window_ref_mouse_pos: Vec2,
    wheeling_window_timer: f32,
    debug_hook_id_info: ID,
    hovered_id: ID,
    hovered_id_previous_frame: ID,
    hovered_id_allow_overlap: bool,
    hovered_id_using_mouse_wheel: bool,
    hovered_id_previous_frame_using_mouse_wheel: bool,
    hovered_id_disabled: bool,
    hovered_id_timer: f32,
    hovered_id_not_active_timer: f32,
    active_id: ID,
    active_id_is_alive: ID,
    active_id_timer: f32,
    active_id_is_just_activated: bool,
    active_id_allow_overlap: bool,
    active_id_no_clear_on_focus_loss: bool,
    active_id_has_been_pressed_before: bool,
    active_id_has_been_edited_before: bool,
    active_id_has_been_edited_this_frame: bool,
    active_id_click_offset: Vec2,
    active_id_window: [*c]Window,
    active_id_source: InputSource,
    active_id_mouse_button: c_int,
    active_id_previous_frame: ID,
    active_id_previous_frame_is_alive: bool,
    active_id_previous_frame_has_been_edited_before: bool,
    active_id_previous_frame_window: [*c]Window,
    last_active_id: ID,
    last_active_id_timer: f32,
    active_id_using_mouse_wheel: bool,
    active_id_using_nav_dir_mask: U32,
    active_id_using_nav_input_mask: U32,
    active_id_using_key_input_mask: BitArrayForNamedKeys,
    current_item_flags: ItemFlags,
    next_item_data: NextItemData,
    last_item_data: LastItemData,
    next_window_data: NextWindowData,
    color_stack: ColorModVector,
    style_var_stack: StyleModVector,
    font_stack: FontPtrVector,
    focus_scope_stack: IDVector,
    item_flags_stack: ItemFlagsVector,
    group_stack: GroupDataVector,
    open_popup_stack: PopupDataVector,
    begin_popup_stack: PopupDataVector,
    begin_menu_count: c_int,
    viewports: ViewportPPtrVector,
    current_dpi_scale: f32,
    current_viewport: [*c]ViewportP,
    mouse_viewport: [*c]ViewportP,
    mouse_last_hovered_viewport: [*c]ViewportP,
    platform_last_focused_viewport_id: ID,
    fallback_monitor: PlatformMonitor,
    viewport_front_most_stamp_count: c_int,
    nav_window: [*c]Window,
    nav_id: ID,
    nav_focus_scope_id: ID,
    nav_activate_id: ID,
    nav_activate_down_id: ID,
    nav_activate_pressed_id: ID,
    nav_activate_input_id: ID,
    nav_activate_flags: ActivateFlags,
    nav_just_moved_to_id: ID,
    nav_just_moved_to_focus_scope_id: ID,
    nav_just_moved_to_key_mods: ModFlags,
    nav_next_activate_id: ID,
    nav_next_activate_flags: ActivateFlags,
    nav_input_source: InputSource,
    nav_layer: NavLayer,
    nav_id_is_alive: bool,
    nav_mouse_pos_dirty: bool,
    nav_disable_highlight: bool,
    nav_disable_mouse_hover: bool,
    nav_any_request: bool,
    nav_init_request: bool,
    nav_init_request_from_move: bool,
    nav_init_result_id: ID,
    nav_init_result_rect_rel: Rect,
    nav_move_submitted: bool,
    nav_move_scoring_items: bool,
    nav_move_forward_to_next_frame: bool,
    nav_move_flags: NavMoveFlags,
    nav_move_scroll_flags: ScrollFlags,
    nav_move_key_mods: ModFlags,
    nav_move_dir: Dir,
    nav_move_dir_for_debug: Dir,
    nav_move_clip_dir: Dir,
    nav_scoring_rect: Rect,
    nav_scoring_no_clip_rect: Rect,
    nav_scoring_debug_count: c_int,
    nav_tabbing_dir: c_int,
    nav_tabbing_counter: c_int,
    nav_move_result_local: NavItemData,
    nav_move_result_local_visible: NavItemData,
    nav_move_result_other: NavItemData,
    nav_tabbing_result_first: NavItemData,
    nav_windowing_target: [*c]Window,
    nav_windowing_target_anim: [*c]Window,
    nav_windowing_list_window: [*c]Window,
    nav_windowing_timer: f32,
    nav_windowing_highlight_alpha: f32,
    nav_windowing_toggle_layer: bool,
    dim_bg_ratio: f32,
    mouse_cursor: MouseCursor,
    drag_drop_active: bool,
    drag_drop_within_source: bool,
    drag_drop_within_target: bool,
    drag_drop_source_flags: DragDropFlags,
    drag_drop_source_frame_count: c_int,
    drag_drop_mouse_button: c_int,
    drag_drop_payload: Payload,
    drag_drop_target_rect: Rect,
    drag_drop_target_id: ID,
    drag_drop_accept_flags: DragDropFlags,
    drag_drop_accept_id_curr_rect_surface: f32,
    drag_drop_accept_id_curr: ID,
    drag_drop_accept_id_prev: ID,
    drag_drop_accept_frame_count: c_int,
    drag_drop_hold_just_pressed_id: ID,
    drag_drop_payload_buf_heap: u8Vector,
    drag_drop_payload_buf_local: [16]u8,
    clipper_temp_data_stacked: c_int,
    clipper_temp_data: ListClipperDataVector,
    current_table: [*c]Table,
    tables_temp_data_stacked: c_int,
    tables_temp_data: TableTempDataVector,
    tables: Table,
    tables_last_time_active: f32Vector,
    draw_channels_temp_merge_buffer: DrawChannelVector,
    current_tab_bar: [*c]TabBar,
    tab_bars: TabBar,
    current_tab_bar_stack: PtrOrIndexVector,
    shrink_width_buffer: ShrinkWidthItemVector,
    mouse_last_valid_pos: Vec2,
    input_text_state: InputTextState,
    input_text_password_font: Font,
    temp_input_id: ID,
    color_edit_options: ColorEditFlags,
    color_edit_last_hue: f32,
    color_edit_last_sat: f32,
    color_edit_last_color: U32,
    color_picker_ref: Vec4,
    combo_preview_data: ComboPreviewData,
    slider_grab_click_offset: f32,
    slider_current_accum: f32,
    slider_current_accum_dirty: bool,
    drag_current_accum_dirty: bool,
    drag_current_accum: f32,
    drag_speed_default_ratio: f32,
    scrollbar_click_delta_to_grab_center: f32,
    disabled_alpha_backup: f32,
    disabled_stack_size: c_short,
    tooltip_override_count: c_short,
    tooltip_slow_delay: f32,
    clipboard_handler_data: u8Vector,
    menus_id_submitted_this_frame: IDVector,
    platform_ime_data: PlatformImeData,
    platform_ime_data_prev: PlatformImeData,
    platform_ime_viewport: ID,
    platform_locale_decimal_point: u8,
    dock_context: DockContext,
    settings_loaded: bool,
    settings_dirty_timer: f32,
    settings_ini_data: TextBuffer,
    settings_handlers: SettingsHandlerVector,
    settings_windows: WindowSettings,
    settings_tables: TableSettings,
    hooks: ContextHookVector,
    hook_id_next: ID,
    log_enabled: bool,
    log_type: LogType,
    log_file: FileHandle,
    log_buffer: TextBuffer,
    log_next_prefix: [*c]const u8,
    log_next_suffix: [*c]const u8,
    log_line_pos_y: f32,
    log_line_first_item: bool,
    log_depth_ref: c_int,
    log_depth_to_expand: c_int,
    log_depth_to_expand_default: c_int,
    debug_log_flags: DebugLogFlags,
    debug_log_buf: TextBuffer,
    debug_item_picker_active: bool,
    debug_item_picker_break_id: ID,
    debug_metrics_config: MetricsConfig,
    debug_stack_tool: StackTool,
    framerate_sec_per_frame: [120]f32,
    framerate_sec_per_frame_idx: c_int,
    framerate_sec_per_frame_count: c_int,
    framerate_sec_per_frame_accum: f32,
    want_capture_mouse_next_frame: c_int,
    want_capture_keyboard_next_frame: c_int,
    want_text_input_next_frame: c_int,
    temp_buffer: u8Vector,
};

pub const DrawChannelVector = extern struct { // struct ImVector_ImDrawChannel
    size: c_int,
    capacity: c_int,
    data: [*c]DrawChannel,
};

pub const DrawChannel = extern struct { // struct ImDrawChannel
    _cmd_buffer: DrawCmdVector,
    _idx_buffer: DrawIdxVector,
};

pub const DrawCmdVector = extern struct { // struct ImVector_ImDrawCmd
    size: c_int,
    capacity: c_int,
    data: [*c]DrawCmd,
};

pub const DrawIdxVector = extern struct { // struct ImVector_ImDrawIdx
    size: c_int,
    capacity: c_int,
    data: [*c]DrawIdx,
};

pub const f32Vector = extern struct { // struct ImVector_float
    size: c_int,
    capacity: c_int,
    data: [*c]f32,
};

pub const FontPtrVector = extern struct { // struct ImVector_ImFontPtr
    size: c_int,
    capacity: c_int,
    data: [*c]Font,
};

pub const Payload = extern struct { // struct ImGuiPayload
    data: ?*anyopaque,
    data_size: c_int,
    source_id: ID,
    source_parent_id: ID,
    data_frame_count: c_int,
    data_type: [32 + 1]u8,
    preview: bool,
    delivery: bool,
};

pub const ListClipper = extern struct { // struct ImGuiListClipper
    display_start: c_int,
    display_end: c_int,
    items_count: c_int,
    items_height: f32,
    start_pos_y: f32,
    temp_data: ?*anyopaque,
};

pub const Storage = struct { // struct ImGuiStorage
    data: StoragePairVector,
};

pub const StoragePairVector = struct {
    size: c_int,
    capacity: c_int,
    data: ?*StoragePair,
};

pub const WindowClass = extern struct { // struct ImGuiWindowClass
    class_id: ID,
    parent_viewport_id: ID,
    viewport_flags_override_set: ViewportFlags,
    viewport_flags_override_clear: ViewportFlags,
    tab_item_flags_override_set: TabItemFlags,
    dock_node_flags_override_set: DockNodeFlags,
    docking_always_tab_bar: bool,
    docking_allow_unclassed: bool,
};

pub const InputTextCallbackData = extern struct { // struct ImGuiInputTextCallbackData
    event_flag: InputTextFlags,
    flags: InputTextFlags,
    user_data: ?*anyopaque,
    event_char: Wchar,
    event_key: Key,
    buf: [*c]u8,
    buf_text_len: c_int,
    buf_size: c_int,
    buf_dirty: bool,
    cursor_pos: c_int,
    selection_start: c_int,
    selection_end: c_int,
};

pub const SizeCallbackData = extern struct { // struct ImGuiSizeCallbackData
    user_data: ?*anyopaque,
    pos: Vec2,
    current_size: Vec2,
    desired_size: Vec2,
};

pub const DrawData = extern struct { // struct ImDrawData
    valid: bool,
    cmd_lists_count: c_int,
    total_idx_count: c_int,
    total_vtx_count: c_int,
    cmd_lists: [*c]DrawList,
    display_pos: Vec2,
    display_size: Vec2,
    framebuffer_scale: Vec2,
    owner_viewport: [*c]Viewport,
};

pub const FontGlyphVector = extern struct { // struct ImVector_ImFontGlyph
    size: c_int,
    capacity: c_int,
    data: ?*FontGlyph,
};

pub const Font = extern struct { // struct ImFont
    index_advance_x: f32Vector,
    fallback_advance_x: f32,
    font_size: f32,
    index_lookup: WcharVector,
    glyphs: FontGlyphVector,
    fallback_glyph: ?*FontGlyph,
    container_atlas: [*c]FontAtlas,
    config_data: [*c]const FontConfig,
    config_data_count: c_short,
    fallback_char: Wchar,
    ellipsis_char: Wchar,
    dot_char: Wchar,
    dirty_lookup_tables: bool,
    scale: f32,
    ascent: f32,
    descent: f32,
    metrics_total_surface: c_int,
    used4k_pages_map: [(0xFFFF + 1) / 4096 / 8]U8,
};

pub const DrawCmd = extern struct { // struct ImDrawCmd
    clip_rect: Vec4,
    texture_id: TextureID,
    vtx_offset: c_uint,
    idx_offset: c_uint,
    elem_count: c_uint,
    user_callback: DrawCallback,
    user_callback_data: ?*anyopaque,
};

pub const DrawVert = extern struct { // struct ImDrawVert
    pos: Vec2,
    uv: Vec2,
    col: U32,
};

pub const DrawCmdHeader = extern struct { // struct ImDrawCmdHeader
    clip_rect: Vec4,
    texture_id: TextureID,
    vtx_offset: c_uint,
};

pub const DrawListSplitter = extern struct { // struct ImDrawListSplitter
    _current: c_int,
    _count: c_int,
    _channels: DrawChannelVector,
};

pub inline fn createContext(shared_font_atlas: [*c]FontAtlas) [*c]Context { //igCreateContext
    return c.igCreateContext(shared_font_atlas);
}
pub inline fn destroyContext(ctx: [*c]Context) void { //igDestroyContext
    c.igDestroyContext(ctx);
}
pub inline fn getCurrentContext() ?*Context { //igGetCurrentContext
    return @ptrCast(c.igGetCurrentContext());
}
pub inline fn setCurrentContext(ctx: [*c]Context) void { //igSetCurrentContext
    c.igSetCurrentContext(ctx);
}
pub inline fn getIO() ?*Io { //igGetIO
    return @ptrCast(c.igGetIO());
}
pub inline fn getStyle() ?*Style { //igGetStyle
    return @ptrCast(c.igGetStyle());
}
pub inline fn newFrame() void { //igNewFrame
    c.igNewFrame();
}
pub inline fn endFrame() void { //igEndFrame
    c.igEndFrame();
}
pub inline fn render() void { //igRender
    c.igRender();
}
pub inline fn getDrawData() [*c]DrawData { //igGetDrawData
    return c.igGetDrawData();
}
pub inline fn showDemoWindow(p_open: [*c]bool) void { //igShowDemoWindow
    c.igShowDemoWindow(p_open);
}
pub inline fn showMetricsWindow(p_open: [*c]bool) void { //igShowMetricsWindow
    c.igShowMetricsWindow(p_open);
}
pub inline fn showDebugLogWindow(p_open: [*c]bool) void { //igShowDebugLogWindow
    c.igShowDebugLogWindow(p_open);
}
pub inline fn showStackToolWindow(p_open: [*c]bool) void { //igShowStackToolWindow
    c.igShowStackToolWindow(p_open);
}
pub inline fn showAboutWindow(p_open: [*c]bool) void { //igShowAboutWindow
    c.igShowAboutWindow(p_open);
}
pub inline fn showStyleEditor(ref: [*c]Style) void { //igShowStyleEditor
    c.igShowStyleEditor(ref);
}
pub inline fn showStyleSelector(label: [*c]const u8) bool { //igShowStyleSelector
    return c.igShowStyleSelector(label);
}
pub inline fn showFontSelector(label: [*c]const u8) void { //igShowFontSelector
    c.igShowFontSelector(label);
}
pub inline fn showUserGuide() void { //igShowUserGuide
    c.igShowUserGuide();
}
pub inline fn getVersion() [*c]const u8 { //igGetVersion
    return c.igGetVersion();
}
pub inline fn styleColorsDark(dst: [*c]Style) void { //igStyleColorsDark
    c.igStyleColorsDark(dst);
}
pub inline fn styleColorsLight(dst: [*c]Style) void { //igStyleColorsLight
    c.igStyleColorsLight(dst);
}
pub inline fn styleColorsClassic(dst: [*c]Style) void { //igStyleColorsClassic
    c.igStyleColorsClassic(dst);
}
pub inline fn begin(name: [*c]const u8, p_open: [*c]bool, flags: WindowFlags) bool { //igBegin
    return c.igBegin(name, p_open, @bitCast(flags));
}
pub inline fn end() void { //igEnd
    c.igEnd();
}
pub inline fn beginChild_Str(str_id: [*c]const u8, size: Vec2, border: bool, flags: WindowFlags) bool { //igBeginChild_Str
    return c.igBeginChild_Str(str_id, @bitCast(size), border, @bitCast(flags));
}
pub inline fn beginChild_ID(id: ID, size: Vec2, border: bool, flags: WindowFlags) bool { //igBeginChild_ID
    return c.igBeginChild_ID(id, @bitCast(size), border, @bitCast(flags));
}
pub inline fn endChild() void { //igEndChild
    c.igEndChild();
}
pub inline fn isWindowAppearing() bool { //igIsWindowAppearing
    return c.igIsWindowAppearing();
}
pub inline fn isWindowCollapsed() bool { //igIsWindowCollapsed
    return c.igIsWindowCollapsed();
}
pub inline fn isWindowFocused(flags: FocusedFlags) bool { //igIsWindowFocused
    return c.igIsWindowFocused(@bitCast(flags));
}
pub inline fn isWindowHovered(flags: HoveredFlags) bool { //igIsWindowHovered
    return c.igIsWindowHovered(@bitCast(flags));
}
pub inline fn getWindowDrawList() [*c]DrawList { //igGetWindowDrawList
    return c.igGetWindowDrawList();
}
pub inline fn getWindowDpiScale() f32 { //igGetWindowDpiScale
    return c.igGetWindowDpiScale();
}
pub inline fn getWindowPos(pout: [*c]Vec2) void { //igGetWindowPos
    c.igGetWindowPos(pout);
}
pub inline fn getWindowSize(pout: [*c]Vec2) void { //igGetWindowSize
    c.igGetWindowSize(pout);
}
pub inline fn getWindowWidth() f32 { //igGetWindowWidth
    return c.igGetWindowWidth();
}
pub inline fn getWindowHeight() f32 { //igGetWindowHeight
    return c.igGetWindowHeight();
}
pub inline fn getWindowViewport() [*c]Viewport { //igGetWindowViewport
    return c.igGetWindowViewport();
}
pub inline fn setNextWindowPos(pos: Vec2, cond: Cond, pivot: Vec2) void { //igSetNextWindowPos
    c.igSetNextWindowPos(@bitCast(pos), @bitCast(cond), @bitCast(pivot));
}
pub inline fn setNextWindowSize(size: Vec2, cond: Cond) void { //igSetNextWindowSize
    c.igSetNextWindowSize(@bitCast(size), @bitCast(cond));
}
pub inline fn setNextWindowSizeConstraints(size_min: Vec2, size_max: Vec2, custom_callback: SizeCallback, custom_callback_data: ?*anyopaque) void { //igSetNextWindowSizeConstraints
    c.igSetNextWindowSizeConstraints(@bitCast(size_min), @bitCast(size_max), custom_callback, custom_callback_data);
}
pub inline fn setNextWindowContentSize(size: Vec2) void { //igSetNextWindowContentSize
    c.igSetNextWindowContentSize(@bitCast(size));
}
pub inline fn setNextWindowCollapsed(collapsed: bool, cond: Cond) void { //igSetNextWindowCollapsed
    c.igSetNextWindowCollapsed(collapsed, @bitCast(cond));
}
pub inline fn setNextWindowFocus() void { //igSetNextWindowFocus
    c.igSetNextWindowFocus();
}
pub inline fn setNextWindowBgAlpha(alpha: f32) void { //igSetNextWindowBgAlpha
    c.igSetNextWindowBgAlpha(alpha);
}
pub inline fn setNextWindowViewport(viewport_id: ID) void { //igSetNextWindowViewport
    c.igSetNextWindowViewport(viewport_id);
}
pub inline fn setWindowPos_Vec2(pos: Vec2, cond: Cond) void { //igSetWindowPos_Vec2
    c.igSetWindowPos_Vec2(@bitCast(pos), @bitCast(cond));
}
pub inline fn setWindowSize_Vec2(size: Vec2, cond: Cond) void { //igSetWindowSize_Vec2
    c.igSetWindowSize_Vec2(@bitCast(size), @bitCast(cond));
}
pub inline fn setWindowCollapsed_Bool(collapsed: bool, cond: Cond) void { //igSetWindowCollapsed_Bool
    c.igSetWindowCollapsed_Bool(collapsed, @bitCast(cond));
}
pub inline fn setWindowFocus_Nil() void { //igSetWindowFocus_Nil
    c.igSetWindowFocus_Nil();
}
pub inline fn setWindowFontScale(scale: f32) void { //igSetWindowFontScale
    c.igSetWindowFontScale(scale);
}
pub inline fn setWindowPos_Str(name: [*c]const u8, pos: Vec2, cond: Cond) void { //igSetWindowPos_Str
    c.igSetWindowPos_Str(name, @bitCast(pos), @bitCast(cond));
}
pub inline fn setWindowSize_Str(name: [*c]const u8, size: Vec2, cond: Cond) void { //igSetWindowSize_Str
    c.igSetWindowSize_Str(name, @bitCast(size), @bitCast(cond));
}
pub inline fn setWindowCollapsed_Str(name: [*c]const u8, collapsed: bool, cond: Cond) void { //igSetWindowCollapsed_Str
    c.igSetWindowCollapsed_Str(name, collapsed, @bitCast(cond));
}
pub inline fn setWindowFocus_Str(name: [*c]const u8) void { //igSetWindowFocus_Str
    c.igSetWindowFocus_Str(name);
}
pub inline fn getContentRegionAvail(pout: [*c]Vec2) void { //igGetContentRegionAvail
    c.igGetContentRegionAvail(pout);
}
pub inline fn getContentRegionMax(pout: [*c]Vec2) void { //igGetContentRegionMax
    c.igGetContentRegionMax(pout);
}
pub inline fn getWindowContentRegionMin(pout: [*c]Vec2) void { //igGetWindowContentRegionMin
    c.igGetWindowContentRegionMin(pout);
}
pub inline fn getWindowContentRegionMax(pout: [*c]Vec2) void { //igGetWindowContentRegionMax
    c.igGetWindowContentRegionMax(pout);
}
pub inline fn getScrollX() f32 { //igGetScrollX
    return c.igGetScrollX();
}
pub inline fn getScrollY() f32 { //igGetScrollY
    return c.igGetScrollY();
}
pub inline fn setScrollX_Float(scroll_x: f32) void { //igSetScrollX_Float
    c.igSetScrollX_Float(scroll_x);
}
pub inline fn setScrollY_Float(scroll_y: f32) void { //igSetScrollY_Float
    c.igSetScrollY_Float(scroll_y);
}
pub inline fn getScrollMaxX() f32 { //igGetScrollMaxX
    return c.igGetScrollMaxX();
}
pub inline fn getScrollMaxY() f32 { //igGetScrollMaxY
    return c.igGetScrollMaxY();
}
pub inline fn setScrollHereX(center_x_ratio: f32) void { //igSetScrollHereX
    c.igSetScrollHereX(center_x_ratio);
}
pub inline fn setScrollHereY(center_y_ratio: f32) void { //igSetScrollHereY
    c.igSetScrollHereY(center_y_ratio);
}
pub inline fn setScrollFromPosX_Float(local_x: f32, center_x_ratio: f32) void { //igSetScrollFromPosX_Float
    c.igSetScrollFromPosX_Float(local_x, center_x_ratio);
}
pub inline fn setScrollFromPosY_Float(local_y: f32, center_y_ratio: f32) void { //igSetScrollFromPosY_Float
    c.igSetScrollFromPosY_Float(local_y, center_y_ratio);
}
pub inline fn pushFont(font: [*c]Font) void { //igPushFont
    c.igPushFont(font);
}
pub inline fn popFont() void { //igPopFont
    c.igPopFont();
}
pub inline fn pushStyleColor_U32(idx: StyleColor, col: U32) void { //igPushStyleColor_U32
    c.igPushStyleColor_U32(idx, col);
}
pub inline fn pushStyleColor_Vec4(idx: StyleColor, col: Vec4) void { //igPushStyleColor_Vec4
    c.igPushStyleColor_Vec4(idx, @bitCast(col));
}
pub inline fn popStyleColor(count: c_int) void { //igPopStyleColor
    c.igPopStyleColor(count);
}
pub inline fn pushStyleVar_Float(idx: StyleVar, val: f32) void { //igPushStyleVar_Float
    c.igPushStyleVar_Float(@intFromEnum(idx), val);
}
pub inline fn pushStyleVar_Vec2(idx: StyleVar, val: Vec2) void { //igPushStyleVar_Vec2
    c.igPushStyleVar_Vec2(@intFromEnum(idx), @bitCast(val));
}
pub inline fn popStyleVar(count: c_int) void { //igPopStyleVar
    c.igPopStyleVar(count);
}
pub inline fn pushAllowKeyboardFocus(allow_keyboard_focus: bool) void { //igPushAllowKeyboardFocus
    c.igPushAllowKeyboardFocus(allow_keyboard_focus);
}
pub inline fn popAllowKeyboardFocus() void { //igPopAllowKeyboardFocus
    c.igPopAllowKeyboardFocus();
}
pub inline fn pushButtonRepeat(repeat: bool) void { //igPushButtonRepeat
    c.igPushButtonRepeat(repeat);
}
pub inline fn popButtonRepeat() void { //igPopButtonRepeat
    c.igPopButtonRepeat();
}
pub inline fn pushItemWidth(item_width: f32) void { //igPushItemWidth
    c.igPushItemWidth(item_width);
}
pub inline fn popItemWidth() void { //igPopItemWidth
    c.igPopItemWidth();
}
pub inline fn setNextItemWidth(item_width: f32) void { //igSetNextItemWidth
    c.igSetNextItemWidth(item_width);
}
pub inline fn calcItemWidth() f32 { //igCalcItemWidth
    return c.igCalcItemWidth();
}
pub inline fn pushTextWrapPos(wrap_local_pos_x: f32) void { //igPushTextWrapPos
    c.igPushTextWrapPos(wrap_local_pos_x);
}
pub inline fn popTextWrapPos() void { //igPopTextWrapPos
    c.igPopTextWrapPos();
}
pub inline fn getFont() [*c]Font { //igGetFont
    return c.igGetFont();
}
pub inline fn getFontSize() f32 { //igGetFontSize
    return c.igGetFontSize();
}
pub inline fn getFontTexUvWhitePixel(pout: [*c]Vec2) void { //igGetFontTexUvWhitePixel
    c.igGetFontTexUvWhitePixel(pout);
}
pub inline fn getColorU32_Col(idx: StyleColor, alpha_mul: f32) U32 { //igGetColorU32_Col
    return c.igGetColorU32_Col(idx, alpha_mul);
}
pub inline fn getColorU32_Vec4(col: Vec4) U32 { //igGetColorU32_Vec4
    return c.igGetColorU32_Vec4(@bitCast(col));
}
pub inline fn getColorU32_U32(col: U32) U32 { //igGetColorU32_U32
    return c.igGetColorU32_U32(col);
}
pub inline fn getStyleColorVec4(idx: StyleColor) [*c]const Vec4 { //igGetStyleColorVec4
    return c.igGetStyleColorVec4(idx);
}
pub inline fn separator() void { //igSeparator
    c.igSeparator();
}
pub inline fn sameLine(offset_from_start_x: f32, space: f32) void { //igSameLine
    c.igSameLine(offset_from_start_x, space);
}
pub inline fn newLine() void { //igNewLine
    c.igNewLine();
}
pub inline fn spacing() void { //igSpacing
    c.igSpacing();
}
pub inline fn dummy(size: Vec2) void { //igDummy
    c.igDummy(@bitCast(size));
}
pub inline fn indent(indent_w: f32) void { //igIndent
    c.igIndent(indent_w);
}
pub inline fn unindent(indent_w: f32) void { //igUnindent
    c.igUnindent(indent_w);
}
pub inline fn beginGroup() void { //igBeginGroup
    c.igBeginGroup();
}
pub inline fn endGroup() void { //igEndGroup
    c.igEndGroup();
}
pub inline fn getCursorPos(pout: [*c]Vec2) void { //igGetCursorPos
    c.igGetCursorPos(pout);
}
pub inline fn getCursorPosX() f32 { //igGetCursorPosX
    return c.igGetCursorPosX();
}
pub inline fn getCursorPosY() f32 { //igGetCursorPosY
    return c.igGetCursorPosY();
}
pub inline fn setCursorPos(local_pos: Vec2) void { //igSetCursorPos
    c.igSetCursorPos(@bitCast(local_pos));
}
pub inline fn setCursorPosX(local_x: f32) void { //igSetCursorPosX
    c.igSetCursorPosX(local_x);
}
pub inline fn setCursorPosY(local_y: f32) void { //igSetCursorPosY
    c.igSetCursorPosY(local_y);
}
pub inline fn getCursorStartPos(pout: [*c]Vec2) void { //igGetCursorStartPos
    c.igGetCursorStartPos(pout);
}
pub inline fn getCursorScreenPos(pout: [*c]Vec2) void { //igGetCursorScreenPos
    c.igGetCursorScreenPos(pout);
}
pub inline fn setCursorScreenPos(pos: Vec2) void { //igSetCursorScreenPos
    c.igSetCursorScreenPos(@bitCast(pos));
}
pub inline fn alignTextToFramePadding() void { //igAlignTextToFramePadding
    c.igAlignTextToFramePadding();
}
pub inline fn getTextLineHeight() f32 { //igGetTextLineHeight
    return c.igGetTextLineHeight();
}
pub inline fn getTextLineHeightWithSpacing() f32 { //igGetTextLineHeightWithSpacing
    return c.igGetTextLineHeightWithSpacing();
}
pub inline fn getFrameHeight() f32 { //igGetFrameHeight
    return c.igGetFrameHeight();
}
pub inline fn getFrameHeightWithSpacing() f32 { //igGetFrameHeightWithSpacing
    return c.igGetFrameHeightWithSpacing();
}
pub inline fn pushID_Str(str_id: [*c]const u8) void { //igPushID_Str
    c.igPushID_Str(str_id);
}
pub inline fn pushID_StrStr(str_id_begin: [*c]const u8, str_id_end: [*c]const u8) void { //igPushID_StrStr
    c.igPushID_StrStr(str_id_begin, str_id_end);
}
pub inline fn pushID_Ptr(ptr_id: [*c]const void) void { //igPushID_Ptr
    c.igPushID_Ptr(ptr_id);
}
pub inline fn pushID_Int(int_id: c_int) void { //igPushID_Int
    c.igPushID_Int(int_id);
}
pub inline fn popID() void { //igPopID
    c.igPopID();
}
pub inline fn getID_Str(str_id: [*c]const u8) ID { //igGetID_Str
    return c.igGetID_Str(str_id);
}
pub inline fn getID_StrStr(str_id_begin: [*c]const u8, str_id_end: [*c]const u8) ID { //igGetID_StrStr
    return c.igGetID_StrStr(str_id_begin, str_id_end);
}
pub inline fn getID_Ptr(ptr_id: [*c]const void) ID { //igGetID_Ptr
    return c.igGetID_Ptr(ptr_id);
}
pub inline fn textUnformatted(text: [*c]const u8, text_end: [*c]const u8) void { //igTextUnformatted
    c.igTextUnformatted(text, text_end);
}
pub inline fn button(label: [*c]const u8, size: Vec2) bool { //igButton
    return c.igButton(label, @bitCast(size));
}
pub inline fn smallButton(label: [*c]const u8) bool { //igSmallButton
    return c.igSmallButton(label);
}
pub inline fn invisibleButton(str_id: [*c]const u8, size: Vec2, flags: ButtonFlags) bool { //igInvisibleButton
    return c.igInvisibleButton(str_id, @bitCast(size), flags);
}
pub inline fn arrowButton(str_id: [*c]const u8, dir: Dir) bool { //igArrowButton
    return c.igArrowButton(str_id, @intFromEnum(dir));
}
pub inline fn image(user_texture_id: TextureID, size: Vec2, uv0: Vec2, uv1: Vec2, tint_col: Vec4, border_col: Vec4) void { //igImage
    c.igImage(user_texture_id, @bitCast(size), @bitCast(uv0), @bitCast(uv1), @bitCast(tint_col), @bitCast(border_col));
}
pub inline fn imageButton(user_texture_id: TextureID, size: Vec2, uv0: Vec2, uv1: Vec2, frame_padding: c_int, bg_col: Vec4, tint_col: Vec4) bool { //igImageButton
    return c.igImageButton(user_texture_id, @bitCast(size), @bitCast(uv0), @bitCast(uv1), frame_padding, @bitCast(bg_col), @bitCast(tint_col));
}
pub inline fn checkbox(label: [*c]const u8, v: [*c]bool) bool { //igCheckbox
    return c.igCheckbox(label, v);
}
pub inline fn checkboxFlags_IntPtr(label: [*c]const u8, flags: [*c]c_int, flags_value: c_int) bool { //igCheckboxFlags_IntPtr
    return c.igCheckboxFlags_IntPtr(label, flags, flags_value);
}
pub inline fn checkboxFlags_UintPtr(label: [*c]const u8, flags: [*c]c_uint, flags_value: c_uint) bool { //igCheckboxFlags_UintPtr
    return c.igCheckboxFlags_UintPtr(label, flags, flags_value);
}
pub inline fn radioButton_Bool(label: [*c]const u8, active: bool) bool { //igRadioButton_Bool
    return c.igRadioButton_Bool(label, active);
}
pub inline fn radioButton_IntPtr(label: [*c]const u8, v: [*c]c_int, v_button: c_int) bool { //igRadioButton_IntPtr
    return c.igRadioButton_IntPtr(label, v, v_button);
}
pub inline fn progressBar(fraction: f32, size_arg: Vec2, overlay: [*c]const u8) void { //igProgressBar
    c.igProgressBar(fraction, @bitCast(size_arg), overlay);
}
pub inline fn bullet() void { //igBullet
    c.igBullet();
}
pub inline fn beginCombo(label: [*c]const u8, preview_value: [*c]const u8, flags: ComboFlags) bool { //igBeginCombo
    return c.igBeginCombo(label, preview_value, @bitCast(flags));
}
pub inline fn endCombo() void { //igEndCombo
    c.igEndCombo();
}
pub inline fn combo_Str(label: [*c]const u8, current_item: [*c]c_int, items_separated_by_zeros: [*c]const u8, popup_max_height_in_items: c_int) bool { //igCombo_Str
    return c.igCombo_Str(label, current_item, items_separated_by_zeros, popup_max_height_in_items);
}
pub inline fn dragFloat(label: [*c]const u8, v: [*c]f32, v_speed: f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: SliderFlags) bool { //igDragFloat
    return c.igDragFloat(label, v, v_speed, v_min, v_max, format, @bitCast(flags));
}
pub inline fn dragFloatRange2(label: [*c]const u8, v_current_min: [*c]f32, v_current_max: [*c]f32, v_speed: f32, v_min: f32, v_max: f32, format: [*c]const u8, format_max: [*c]const u8, flags: SliderFlags) bool { //igDragFloatRange2
    return c.igDragFloatRange2(label, v_current_min, v_current_max, v_speed, v_min, v_max, format, format_max, @bitCast(flags));
}
pub inline fn dragInt(label: [*c]const u8, v: [*c]c_int, v_speed: f32, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: SliderFlags) bool { //igDragInt
    return c.igDragInt(label, v, v_speed, v_min, v_max, format, @bitCast(flags));
}
pub inline fn dragIntRange2(label: [*c]const u8, v_current_min: [*c]c_int, v_current_max: [*c]c_int, v_speed: f32, v_min: c_int, v_max: c_int, format: [*c]const u8, format_max: [*c]const u8, flags: SliderFlags) bool { //igDragIntRange2
    return c.igDragIntRange2(label, v_current_min, v_current_max, v_speed, v_min, v_max, format, format_max, @bitCast(flags));
}
pub inline fn dragScalar(label: [*c]const u8, data_type: DataType, p_data: ?*anyopaque, v_speed: f32, p_min: [*c]const void, p_max: [*c]const void, format: [*c]const u8, flags: SliderFlags) bool { //igDragScalar
    return c.igDragScalar(label, @intFromEnum(data_type), p_data, v_speed, p_min, p_max, format, @bitCast(flags));
}
pub inline fn dragScalarN(label: [*c]const u8, data_type: DataType, p_data: ?*anyopaque, components: c_int, v_speed: f32, p_min: [*c]const void, p_max: [*c]const void, format: [*c]const u8, flags: SliderFlags) bool { //igDragScalarN
    return c.igDragScalarN(label, @intFromEnum(data_type), p_data, components, v_speed, p_min, p_max, format, @bitCast(flags));
}
pub inline fn sliderFloat(label: [*c]const u8, v: [*c]f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: SliderFlags) bool { //igSliderFloat
    return c.igSliderFloat(label, v, v_min, v_max, format, @bitCast(flags));
}
pub inline fn sliderAngle(label: [*c]const u8, v_rad: [*c]f32, v_degrees_min: f32, v_degrees_max: f32, format: [*c]const u8, flags: SliderFlags) bool { //igSliderAngle
    return c.igSliderAngle(label, v_rad, v_degrees_min, v_degrees_max, format, @bitCast(flags));
}
pub inline fn sliderInt(label: [*c]const u8, v: [*c]c_int, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: SliderFlags) bool { //igSliderInt
    return c.igSliderInt(label, v, v_min, v_max, format, @bitCast(flags));
}
pub inline fn sliderScalar(label: [*c]const u8, data_type: DataType, p_data: ?*anyopaque, p_min: [*c]const void, p_max: [*c]const void, format: [*c]const u8, flags: SliderFlags) bool { //igSliderScalar
    return c.igSliderScalar(label, @intFromEnum(data_type), p_data, p_min, p_max, format, @bitCast(flags));
}
pub inline fn sliderScalarN(label: [*c]const u8, data_type: DataType, p_data: ?*anyopaque, components: c_int, p_min: [*c]const void, p_max: [*c]const void, format: [*c]const u8, flags: SliderFlags) bool { //igSliderScalarN
    return c.igSliderScalarN(label, @intFromEnum(data_type), p_data, components, p_min, p_max, format, @bitCast(flags));
}
pub inline fn vSliderFloat(label: [*c]const u8, size: Vec2, v: [*c]f32, v_min: f32, v_max: f32, format: [*c]const u8, flags: SliderFlags) bool { //igVSliderFloat
    return c.igVSliderFloat(label, @bitCast(size), v, v_min, v_max, format, @bitCast(flags));
}
pub inline fn vSliderInt(label: [*c]const u8, size: Vec2, v: [*c]c_int, v_min: c_int, v_max: c_int, format: [*c]const u8, flags: SliderFlags) bool { //igVSliderInt
    return c.igVSliderInt(label, @bitCast(size), v, v_min, v_max, format, @bitCast(flags));
}
pub inline fn vSliderScalar(label: [*c]const u8, size: Vec2, data_type: DataType, p_data: ?*anyopaque, p_min: [*c]const void, p_max: [*c]const void, format: [*c]const u8, flags: SliderFlags) bool { //igVSliderScalar
    return c.igVSliderScalar(label, @bitCast(size), @intFromEnum(data_type), p_data, p_min, p_max, format, @bitCast(flags));
}
pub inline fn inputText(label: [*c]const u8, buf: [*c]u8, buf_size: usize, flags: InputTextFlags, callback: InputTextCallback, user_data: ?*anyopaque) bool { //igInputText
    return c.igInputText(label, buf, buf_size, @bitCast(flags), callback, user_data);
}
pub inline fn inputTextMultiline(label: [*c]const u8, buf: [*c]u8, buf_size: usize, size: Vec2, flags: InputTextFlags, callback: InputTextCallback, user_data: ?*anyopaque) bool { //igInputTextMultiline
    return c.igInputTextMultiline(label, buf, buf_size, @bitCast(size), @bitCast(flags), callback, user_data);
}
pub inline fn inputTextWithHint(label: [*c]const u8, hint: [*c]const u8, buf: [*c]u8, buf_size: usize, flags: InputTextFlags, callback: InputTextCallback, user_data: ?*anyopaque) bool { //igInputTextWithHint
    return c.igInputTextWithHint(label, hint, buf, buf_size, @bitCast(flags), callback, user_data);
}
pub inline fn inputFloat(label: [*c]const u8, v: [*c]f32, step: f32, step_fast: f32, format: [*c]const u8, flags: InputTextFlags) bool { //igInputFloat
    return c.igInputFloat(label, v, step, step_fast, format, @bitCast(flags));
}
pub inline fn inputInt(label: [*c]const u8, v: [*c]c_int, step: c_int, step_fast: c_int, flags: InputTextFlags) bool { //igInputInt
    return c.igInputInt(label, v, step, step_fast, @bitCast(flags));
}

pub inline fn inputDouble(label: [*c]const u8, v: [*c]f64, step: f64, step_fast: f64, format: [*c]const u8, flags: InputTextFlags) bool { //igInputDouble
    return c.igInputDouble(label, v, step, step_fast, format, @bitCast(flags));
}
pub inline fn inputScalar(label: [*c]const u8, data_type: DataType, p_data: ?*anyopaque, p_step: [*c]const void, p_step_fast: [*c]const void, format: [*c]const u8, flags: InputTextFlags) bool { //igInputScalar
    return c.igInputScalar(label, @intFromEnum(data_type), p_data, p_step, p_step_fast, format, @bitCast(flags));
}
pub inline fn inputScalarN(label: [*c]const u8, data_type: DataType, p_data: ?*anyopaque, components: c_int, p_step: [*c]const void, p_step_fast: [*c]const void, format: [*c]const u8, flags: InputTextFlags) bool { //igInputScalarN
    return c.igInputScalarN(label, @intFromEnum(data_type), p_data, components, p_step, p_step_fast, format, @bitCast(flags));
}
pub inline fn colorButton(desc_id: [*c]const u8, col: Vec4, flags: ColorEditFlags, size: Vec2) bool { //igColorButton
    return c.igColorButton(desc_id, @bitCast(col), @bitCast(flags), @bitCast(size));
}
pub inline fn setColorEditOptions(flags: ColorEditFlags) void { //igSetColorEditOptions
    c.igSetColorEditOptions(@bitCast(flags));
}
pub inline fn treeNode_Str(label: [*c]const u8) bool { //igTreeNode_Str
    return c.igTreeNode_Str(label);
}
pub inline fn treeNodeEx_Str(label: [*c]const u8, flags: TreeNodeFlags) bool { //igTreeNodeEx_Str
    return c.igTreeNodeEx_Str(label, @bitCast(flags));
}
pub inline fn treePush_Str(str_id: [*c]const u8) void { //igTreePush_Str
    c.igTreePush_Str(str_id);
}
pub inline fn treePush_Ptr(ptr_id: [*c]const void) void { //igTreePush_Ptr
    c.igTreePush_Ptr(ptr_id);
}
pub inline fn treePop() void { //igTreePop
    c.igTreePop();
}
pub inline fn getTreeNodeToLabelSpacing() f32 { //igGetTreeNodeToLabelSpacing
    return c.igGetTreeNodeToLabelSpacing();
}
pub inline fn collapsingHeader_TreeNodeFlags(label: [*c]const u8, flags: TreeNodeFlags) bool { //igCollapsingHeader_TreeNodeFlags
    return c.igCollapsingHeader_TreeNodeFlags(label, @bitCast(flags));
}
pub inline fn collapsingHeader_BoolPtr(label: [*c]const u8, p_visible: [*c]bool, flags: TreeNodeFlags) bool { //igCollapsingHeader_BoolPtr
    return c.igCollapsingHeader_BoolPtr(label, p_visible, @bitCast(flags));
}
pub inline fn setNextItemOpen(is_open: bool, cond: Cond) void { //igSetNextItemOpen
    c.igSetNextItemOpen(is_open, @bitCast(cond));
}
pub inline fn selectable_Bool(label: [*c]const u8, selected: bool, flags: SelectableFlags, size: Vec2) bool { //igSelectable_Bool
    return c.igSelectable_Bool(label, selected, @bitCast(flags), @bitCast(size));
}
pub inline fn selectable_BoolPtr(label: [*c]const u8, p_selected: [*c]bool, flags: SelectableFlags, size: Vec2) bool { //igSelectable_BoolPtr
    return c.igSelectable_BoolPtr(label, p_selected, @bitCast(flags), @bitCast(size));
}
pub inline fn beginListBox(label: [*c]const u8, size: Vec2) bool { //igBeginListBox
    return c.igBeginListBox(label, @bitCast(size));
}
pub inline fn endListBox() void { //igEndListBox
    c.igEndListBox();
}
pub inline fn plotLines_FloatPtr(label: [*c]const u8, values: [*c]const f32, values_count: c_int, values_offset: c_int, overlay_text: [*c]const u8, scale_min: f32, scale_max: f32, graph_size: Vec2, stride: c_int) void { //igPlotLines_FloatPtr
    c.igPlotLines_FloatPtr(label, values, values_count, values_offset, overlay_text, scale_min, scale_max, @bitCast(graph_size), stride);
}
pub inline fn plotHistogram_FloatPtr(label: [*c]const u8, values: [*c]const f32, values_count: c_int, values_offset: c_int, overlay_text: [*c]const u8, scale_min: f32, scale_max: f32, graph_size: Vec2, stride: c_int) void { //igPlotHistogram_FloatPtr
    c.igPlotHistogram_FloatPtr(label, values, values_count, values_offset, overlay_text, scale_min, scale_max, @bitCast(graph_size), stride);
}
pub inline fn value_Bool(prefix: [*c]const u8, b: bool) void { //igValue_Bool
    c.igValue_Bool(prefix, b);
}
pub inline fn value_Int(prefix: [*c]const u8, v: c_int) void { //igValue_Int
    c.igValue_Int(prefix, v);
}
pub inline fn value_Uint(prefix: [*c]const u8, v: c_uint) void { //igValue_Uint
    c.igValue_Uint(prefix, v);
}
pub inline fn value_Float(prefix: [*c]const u8, v: f32, float_format: [*c]const u8) void { //igValue_Float
    c.igValue_Float(prefix, v, float_format);
}
pub inline fn beginMenuBar() bool { //igBeginMenuBar
    return c.igBeginMenuBar();
}
pub inline fn endMenuBar() void { //igEndMenuBar
    c.igEndMenuBar();
}
pub inline fn beginMainMenuBar() bool { //igBeginMainMenuBar
    return c.igBeginMainMenuBar();
}
pub inline fn endMainMenuBar() void { //igEndMainMenuBar
    c.igEndMainMenuBar();
}
pub inline fn beginMenu(label: [*c]const u8, enabled: bool) bool { //igBeginMenu
    return c.igBeginMenu(label, enabled);
}
pub inline fn endMenu() void { //igEndMenu
    c.igEndMenu();
}
pub inline fn menuItem_Bool(label: [*c]const u8, shortcut: [*c]const u8, selected: bool, enabled: bool) bool { //igMenuItem_Bool
    return c.igMenuItem_Bool(label, shortcut, selected, enabled);
}
pub inline fn menuItem_BoolPtr(label: [*c]const u8, shortcut: [*c]const u8, p_selected: [*c]bool, enabled: bool) bool { //igMenuItem_BoolPtr
    return c.igMenuItem_BoolPtr(label, shortcut, p_selected, enabled);
}
pub inline fn beginTooltip() void { //igBeginTooltip
    c.igBeginTooltip();
}
pub inline fn endTooltip() void { //igEndTooltip
    c.igEndTooltip();
}
pub inline fn beginPopup(str_id: [*c]const u8, flags: WindowFlags) bool { //igBeginPopup
    return c.igBeginPopup(str_id, @bitCast(flags));
}
pub inline fn beginPopupModal(name: [*c]const u8, p_open: [*c]bool, flags: WindowFlags) bool { //igBeginPopupModal
    return c.igBeginPopupModal(name, p_open, @bitCast(flags));
}
pub inline fn endPopup() void { //igEndPopup
    c.igEndPopup();
}
pub inline fn openPopup_Str(str_id: [*c]const u8, popup_flags: PopupFlags) void { //igOpenPopup_Str
    c.igOpenPopup_Str(str_id, @bitCast(popup_flags));
}
pub inline fn openPopup_ID(id: ID, popup_flags: PopupFlags) void { //igOpenPopup_ID
    c.igOpenPopup_ID(id, @bitCast(popup_flags));
}
pub inline fn openPopupOnItemClick(str_id: [*c]const u8, popup_flags: PopupFlags) void { //igOpenPopupOnItemClick
    c.igOpenPopupOnItemClick(str_id, @bitCast(popup_flags));
}
pub inline fn closeCurrentPopup() void { //igCloseCurrentPopup
    c.igCloseCurrentPopup();
}
pub inline fn beginPopupContextItem(str_id: [*c]const u8, popup_flags: PopupFlags) bool { //igBeginPopupContextItem
    return c.igBeginPopupContextItem(str_id, @bitCast(popup_flags));
}
pub inline fn beginPopupContextWindow(str_id: [*c]const u8, popup_flags: PopupFlags) bool { //igBeginPopupContextWindow
    return c.igBeginPopupContextWindow(str_id, @bitCast(popup_flags));
}
pub inline fn beginPopupContextVoid(str_id: [*c]const u8, popup_flags: PopupFlags) bool { //igBeginPopupContextVoid
    return c.igBeginPopupContextVoid(str_id, @bitCast(popup_flags));
}
pub inline fn isPopupOpen_Str(str_id: [*c]const u8, flags: PopupFlags) bool { //igIsPopupOpen_Str
    return c.igIsPopupOpen_Str(str_id, @bitCast(flags));
}
pub inline fn beginTable(str_id: [*c]const u8, column: c_int, flags: TableFlags, outer_size: Vec2, inner_width: f32) bool { //igBeginTable
    return c.igBeginTable(str_id, column, @bitCast(flags), @bitCast(outer_size), inner_width);
}
pub inline fn endTable() void { //igEndTable
    c.igEndTable();
}
pub inline fn tableNextRow(row_flags: TableRowFlags, min_row_height: f32) void { //igTableNextRow
    c.igTableNextRow(@bitCast(row_flags), min_row_height);
}
pub inline fn tableNextColumn() bool { //igTableNextColumn
    return c.igTableNextColumn();
}
pub inline fn tableSetColumnIndex(column_n: c_int) bool { //igTableSetColumnIndex
    return c.igTableSetColumnIndex(column_n);
}
pub inline fn tableSetupColumn(label: [*c]const u8, flags: TableColumnFlags, init_width_or_weight: f32, user_id: ID) void { //igTableSetupColumn
    c.igTableSetupColumn(label, @bitCast(flags), init_width_or_weight, user_id);
}
pub inline fn tableSetupScrollFreeze(cols: c_int, rows: c_int) void { //igTableSetupScrollFreeze
    c.igTableSetupScrollFreeze(cols, rows);
}
pub inline fn tableHeadersRow() void { //igTableHeadersRow
    c.igTableHeadersRow();
}
pub inline fn tableHeader(label: [*c]const u8) void { //igTableHeader
    c.igTableHeader(label);
}
pub inline fn tableGetColumnCount() c_int { //igTableGetColumnCount
    return c.igTableGetColumnCount();
}
pub inline fn tableGetColumnIndex() c_int { //igTableGetColumnIndex
    return c.igTableGetColumnIndex();
}
pub inline fn tableGetRowIndex() c_int { //igTableGetRowIndex
    return c.igTableGetRowIndex();
}
pub inline fn tableGetColumnName_Int(column_n: c_int) [*c]const u8 { //igTableGetColumnName_Int
    return c.igTableGetColumnName_Int(column_n);
}
pub inline fn tableGetColumnFlags(column_n: c_int) TableColumnFlags { //igTableGetColumnFlags
    return c.igTableGetColumnFlags(column_n);
}
pub inline fn tableSetColumnEnabled(column_n: c_int, v: bool) void { //igTableSetColumnEnabled
    c.igTableSetColumnEnabled(column_n, v);
}
pub inline fn tableSetBgColor(target: TableBgTarget, color: U32, column_n: c_int) void { //igTableSetBgColor
    c.igTableSetBgColor(@bitCast(target), color, column_n);
}
pub inline fn columns(count: c_int, id: [*c]const u8, border: bool) void { //igColumns
    c.igColumns(count, id, border);
}
pub inline fn nextColumn() void { //igNextColumn
    c.igNextColumn();
}
pub inline fn getColumnIndex() c_int { //igGetColumnIndex
    return c.igGetColumnIndex();
}
pub inline fn getColumnWidth(column_index: c_int) f32 { //igGetColumnWidth
    return c.igGetColumnWidth(column_index);
}
pub inline fn setColumnWidth(column_index: c_int, width: f32) void { //igSetColumnWidth
    c.igSetColumnWidth(column_index, width);
}
pub inline fn getColumnOffset(column_index: c_int) f32 { //igGetColumnOffset
    return c.igGetColumnOffset(column_index);
}
pub inline fn setColumnOffset(column_index: c_int, offset_x: f32) void { //igSetColumnOffset
    c.igSetColumnOffset(column_index, offset_x);
}
pub inline fn getColumnsCount() c_int { //igGetColumnsCount
    return c.igGetColumnsCount();
}
pub inline fn beginTabBar(str_id: [*c]const u8, flags: TabBarFlags) bool { //igBeginTabBar
    return c.igBeginTabBar(str_id, @bitCast(flags));
}
pub inline fn endTabBar() void { //igEndTabBar
    c.igEndTabBar();
}
pub inline fn beginTabItem(label: [*c]const u8, p_open: [*c]bool, flags: TabItemFlags) bool { //igBeginTabItem
    return c.igBeginTabItem(label, p_open, @bitCast(flags));
}
pub inline fn endTabItem() void { //igEndTabItem
    c.igEndTabItem();
}
pub inline fn tabItemButton(label: [*c]const u8, flags: TabItemFlags) bool { //igTabItemButton
    return c.igTabItemButton(label, @bitCast(flags));
}
pub inline fn setTabItemClosed(tab_or_docked_window_label: [*c]const u8) void { //igSetTabItemClosed
    c.igSetTabItemClosed(tab_or_docked_window_label);
}
pub inline fn dockSpace(id: ID, size: Vec2, flags: DockNodeFlags, window_class: [*c]const WindowClass) ID { //igDockSpace
    return c.igDockSpace(id, @bitCast(size), @bitCast(flags), @ptrCast(window_class));
}
pub inline fn dockSpaceOverViewport(viewport: [*c]const Viewport, flags: DockNodeFlags, window_class: [*c]const WindowClass) ID { //igDockSpaceOverViewport
    return c.igDockSpaceOverViewport(viewport, @bitCast(flags), @ptrCast(window_class));
}
pub inline fn setNextWindowDockID(dock_id: ID, cond: Cond) void { //igSetNextWindowDockID
    c.igSetNextWindowDockID(dock_id, @bitCast(cond));
}
pub inline fn setNextWindowClass(window_class: [*c]const WindowClass) void { //igSetNextWindowClass
    c.igSetNextWindowClass(@ptrCast(window_class));
}
pub inline fn getWindowDockID() ID { //igGetWindowDockID
    return c.igGetWindowDockID();
}
pub inline fn isWindowDocked() bool { //igIsWindowDocked
    return c.igIsWindowDocked();
}
pub inline fn logToTTY(auto_open_depth: c_int) void { //igLogToTTY
    c.igLogToTTY(auto_open_depth);
}
pub inline fn logToFile(auto_open_depth: c_int, filename: [*c]const u8) void { //igLogToFile
    c.igLogToFile(auto_open_depth, filename);
}
pub inline fn logToClipboard(auto_open_depth: c_int) void { //igLogToClipboard
    c.igLogToClipboard(auto_open_depth);
}
pub inline fn logFinish() void { //igLogFinish
    c.igLogFinish();
}
pub inline fn logButtons() void { //igLogButtons
    c.igLogButtons();
}
pub inline fn beginDragDropSource(flags: DragDropFlags) bool { //igBeginDragDropSource
    return c.igBeginDragDropSource(@bitCast(flags));
}
pub inline fn setDragDropPayload(t: [*c]const u8, data: [*c]const void, sz: usize, cond: Cond) bool { //igSetDragDropPayload
    return c.igSetDragDropPayload(t, data, sz, @bitCast(cond));
}
pub inline fn endDragDropSource() void { //igEndDragDropSource
    c.igEndDragDropSource();
}
pub inline fn beginDragDropTarget() bool { //igBeginDragDropTarget
    return c.igBeginDragDropTarget();
}
pub inline fn acceptDragDropPayload(t: [*c]const u8, flags: DragDropFlags) [*c]const Payload { //igAcceptDragDropPayload
    return c.igAcceptDragDropPayload(t, @bitCast(flags));
}
pub inline fn endDragDropTarget() void { //igEndDragDropTarget
    c.igEndDragDropTarget();
}
pub inline fn getDragDropPayload() [*c]const Payload { //igGetDragDropPayload
    return c.igGetDragDropPayload();
}
pub inline fn beginDisabled(disabled: bool) void { //igBeginDisabled
    c.igBeginDisabled(disabled);
}
pub inline fn endDisabled() void { //igEndDisabled
    c.igEndDisabled();
}
pub inline fn pushClipRect(clip_rect_min: Vec2, clip_rect_max: Vec2, intersect_with_current_clip_rect: bool) void { //igPushClipRect
    c.igPushClipRect(@bitCast(clip_rect_min), @bitCast(clip_rect_max), intersect_with_current_clip_rect);
}
pub inline fn popClipRect() void { //igPopClipRect
    c.igPopClipRect();
}
pub inline fn setItemDefaultFocus() void { //igSetItemDefaultFocus
    c.igSetItemDefaultFocus();
}
pub inline fn setKeyboardFocusHere(offset: c_int) void { //igSetKeyboardFocusHere
    c.igSetKeyboardFocusHere(offset);
}
pub inline fn isItemHovered(flags: HoveredFlags) bool { //igIsItemHovered
    return c.igIsItemHovered(@bitCast(flags));
}
pub inline fn isItemActive() bool { //igIsItemActive
    return c.igIsItemActive();
}
pub inline fn isItemFocused() bool { //igIsItemFocused
    return c.igIsItemFocused();
}
pub inline fn isItemClicked(mouse_button: MouseButton) bool { //igIsItemClicked
    return c.igIsItemClicked(@intFromEnum(mouse_button));
}
pub inline fn isItemVisible() bool { //igIsItemVisible
    return c.igIsItemVisible();
}
pub inline fn isItemEdited() bool { //igIsItemEdited
    return c.igIsItemEdited();
}
pub inline fn isItemActivated() bool { //igIsItemActivated
    return c.igIsItemActivated();
}
pub inline fn isItemDeactivated() bool { //igIsItemDeactivated
    return c.igIsItemDeactivated();
}
pub inline fn isItemDeactivatedAfterEdit() bool { //igIsItemDeactivatedAfterEdit
    return c.igIsItemDeactivatedAfterEdit();
}
pub inline fn isItemToggledOpen() bool { //igIsItemToggledOpen
    return c.igIsItemToggledOpen();
}
pub inline fn isAnyItemHovered() bool { //igIsAnyItemHovered
    return c.igIsAnyItemHovered();
}
pub inline fn isAnyItemActive() bool { //igIsAnyItemActive
    return c.igIsAnyItemActive();
}
pub inline fn isAnyItemFocused() bool { //igIsAnyItemFocused
    return c.igIsAnyItemFocused();
}
pub inline fn getItemRectMin(pout: [*c]Vec2) void { //igGetItemRectMin
    c.igGetItemRectMin(pout);
}
pub inline fn getItemRectMax(pout: [*c]Vec2) void { //igGetItemRectMax
    c.igGetItemRectMax(pout);
}
pub inline fn getItemRectSize(pout: [*c]Vec2) void { //igGetItemRectSize
    c.igGetItemRectSize(pout);
}
pub inline fn setItemAllowOverlap() void { //igSetItemAllowOverlap
    c.igSetItemAllowOverlap();
}
pub inline fn getMainViewport() ?*Viewport { //igGetMainViewport
    return @ptrCast(c.igGetMainViewport());
}
pub inline fn getBackgroundDrawList_Nil() [*c]DrawList { //igGetBackgroundDrawList_Nil
    return c.igGetBackgroundDrawList_Nil();
}
pub inline fn getForegroundDrawList_Nil() [*c]DrawList { //igGetForegroundDrawList_Nil
    return c.igGetForegroundDrawList_Nil();
}
pub inline fn getBackgroundDrawList_ViewportPtr(viewport: [*c]Viewport) [*c]DrawList { //igGetBackgroundDrawList_ViewportPtr
    return c.igGetBackgroundDrawList_ViewportPtr(viewport);
}
pub inline fn getForegroundDrawList_ViewportPtr(viewport: [*c]Viewport) [*c]DrawList { //igGetForegroundDrawList_ViewportPtr
    return c.igGetForegroundDrawList_ViewportPtr(viewport);
}
pub inline fn isRectVisible_Nil(size: Vec2) bool { //igIsRectVisible_Nil
    return c.igIsRectVisible_Nil(@bitCast(size));
}
pub inline fn isRectVisible_Vec2(rect_min: Vec2, rect_max: Vec2) bool { //igIsRectVisible_Vec2
    return c.igIsRectVisible_Vec2(@bitCast(rect_min), @bitCast(rect_max));
}
pub inline fn getTime() f64 { //igGetTime
    return c.igGetTime();
}
pub inline fn getFrameCount() c_int { //igGetFrameCount
    return c.igGetFrameCount();
}
pub inline fn getDrawListSharedData() [*c]DrawListSharedData { //igGetDrawListSharedData
    return c.igGetDrawListSharedData();
}
pub inline fn getStyleColorName(idx: StyleColor) [*c]const u8 { //igGetStyleColorName
    return c.igGetStyleColorName(idx);
}
pub inline fn setStateStorage(storage: [*c]Storage) void { //igSetStateStorage
    c.igSetStateStorage(storage);
}
pub inline fn getStateStorage() [*c]Storage { //igGetStateStorage
    return c.igGetStateStorage();
}
pub inline fn beginChildFrame(id: ID, size: Vec2, flags: WindowFlags) bool { //igBeginChildFrame
    return c.igBeginChildFrame(id, @bitCast(size), @bitCast(flags));
}
pub inline fn endChildFrame() void { //igEndChildFrame
    c.igEndChildFrame();
}
pub inline fn calcTextSize(pout: [*c]Vec2, text: [*c]const u8, text_end: [*c]const u8, hide_text_after_double_hash: bool, wrap_width: f32) void { //igCalcTextSize
    c.igCalcTextSize(pout, text, text_end, hide_text_after_double_hash, wrap_width);
}
pub inline fn colorConvertU32ToFloat4(pout: [*c]Vec4, in: U32) void { //igColorConvertU32ToFloat4
    c.igColorConvertU32ToFloat4(pout, in);
}
pub inline fn colorConvertFloat4ToU32(in: Vec4) U32 { //igColorConvertFloat4ToU32
    return c.igColorConvertFloat4ToU32(@bitCast(in));
}
pub inline fn colorConvertRGBtoHSV(r: f32, g: f32, b: f32, out_h: [*c]f32, out_s: [*c]f32, out_v: [*c]f32) void { //igColorConvertRGBtoHSV
    c.igColorConvertRGBtoHSV(r, g, b, out_h, out_s, out_v);
}
pub inline fn colorConvertHSVtoRGB(h: f32, s: f32, v: f32, out_r: [*c]f32, out_g: [*c]f32, out_b: [*c]f32) void { //igColorConvertHSVtoRGB
    c.igColorConvertHSVtoRGB(h, s, v, out_r, out_g, out_b);
}
pub inline fn isKeyDown(key: Key) bool { //igIsKeyDown
    return c.igIsKeyDown(@intFromEnum(key));
}
pub inline fn isKeyPressed(key: Key, repeat: bool) bool { //igIsKeyPressed
    return c.igIsKeyPressed(@intFromEnum(key), repeat);
}
pub inline fn isKeyReleased(key: Key) bool { //igIsKeyReleased
    return c.igIsKeyReleased(@intFromEnum(key));
}
pub inline fn getKeyPressedAmount(key: Key, repeat_delay: f32, rate: f32) c_int { //igGetKeyPressedAmount
    return c.igGetKeyPressedAmount(@intFromEnum(key), repeat_delay, rate);
}
pub inline fn getKeyName(key: Key) [*c]const u8 { //igGetKeyName
    return c.igGetKeyName(@intFromEnum(key));
}
pub inline fn setNextFrameWantCaptureKeyboard(want_capture_keyboard: bool) void { //igSetNextFrameWantCaptureKeyboard
    c.igSetNextFrameWantCaptureKeyboard(want_capture_keyboard);
}
pub inline fn isMouseDown(btn: MouseButton) bool { //igIsMouseDown
    return c.igIsMouseDown(@intFromEnum(btn));
}
pub inline fn isMouseClicked(btn: MouseButton, repeat: bool) bool { //igIsMouseClicked
    return c.igIsMouseClicked(@intFromEnum(btn), repeat);
}
pub inline fn isMouseReleased(btn: MouseButton) bool { //igIsMouseReleased
    return c.igIsMouseReleased(@intFromEnum(btn));
}
pub inline fn isMouseDoubleClicked(btn: MouseButton) bool { //igIsMouseDoubleClicked
    return c.igIsMouseDoubleClicked(@intFromEnum(btn));
}
pub inline fn getMouseClickedCount(btn: MouseButton) c_int { //igGetMouseClickedCount
    return c.igGetMouseClickedCount(@intFromEnum(btn));
}
pub inline fn isMouseHoveringRect(r_min: Vec2, r_max: Vec2, clip: bool) bool { //igIsMouseHoveringRect
    return c.igIsMouseHoveringRect(@bitCast(r_min), @bitCast(r_max), clip);
}
pub inline fn isMousePosValid(mouse_pos: [*c]const Vec2) bool { //igIsMousePosValid
    return c.igIsMousePosValid(mouse_pos);
}
pub inline fn isAnyMouseDown() bool { //igIsAnyMouseDown
    return c.igIsAnyMouseDown();
}
pub inline fn getMousePos(pout: [*c]Vec2) void { //igGetMousePos
    c.igGetMousePos(pout);
}
pub inline fn getMousePosOnOpeningCurrentPopup(pout: [*c]Vec2) void { //igGetMousePosOnOpeningCurrentPopup
    c.igGetMousePosOnOpeningCurrentPopup(pout);
}
pub inline fn isMouseDragging(btn: MouseButton, lock_threshold: f32) bool { //igIsMouseDragging
    return c.igIsMouseDragging(@intFromEnum(btn), lock_threshold);
}
pub inline fn getMouseDragDelta(pout: [*c]Vec2, btn: MouseButton, lock_threshold: f32) void { //igGetMouseDragDelta
    c.igGetMouseDragDelta(pout, @intFromEnum(btn), lock_threshold);
}
pub inline fn resetMouseDragDelta(btn: MouseButton) void { //igResetMouseDragDelta
    c.igResetMouseDragDelta(@intFromEnum(btn));
}
pub inline fn getMouseCursor() MouseCursor { //igGetMouseCursor
    return c.igGetMouseCursor();
}
pub inline fn setMouseCursor(cursor_type: MouseCursor) void { //igSetMouseCursor
    c.igSetMouseCursor(@intFromEnum(cursor_type));
}
pub inline fn setNextFrameWantCaptureMouse(want_capture_mouse: bool) void { //igSetNextFrameWantCaptureMouse
    c.igSetNextFrameWantCaptureMouse(want_capture_mouse);
}
pub inline fn getClipboardText() [*c]const u8 { //igGetClipboardText
    return c.igGetClipboardText();
}
pub inline fn setClipboardText(text: [*c]const u8) void { //igSetClipboardText
    c.igSetClipboardText(text);
}
pub inline fn loadIniSettingsFromDisk(ini_filename: [*c]const u8) void { //igLoadIniSettingsFromDisk
    c.igLoadIniSettingsFromDisk(ini_filename);
}
pub inline fn loadIniSettingsFromMemory(ini_data: [*c]const u8, ini_size: usize) void { //igLoadIniSettingsFromMemory
    c.igLoadIniSettingsFromMemory(ini_data, ini_size);
}
pub inline fn saveIniSettingsToDisk(ini_filename: [*c]const u8) void { //igSaveIniSettingsToDisk
    c.igSaveIniSettingsToDisk(ini_filename);
}
pub inline fn saveIniSettingsToMemory(out_ini_size: [*c]usize) [*c]const u8 { //igSaveIniSettingsToMemory
    return c.igSaveIniSettingsToMemory(out_ini_size);
}
pub inline fn debugTextEncoding(text: [*c]const u8) void { //igDebugTextEncoding
    c.igDebugTextEncoding(text);
}
pub inline fn debugCheckVersionAndDataLayout(version_str: [*c]const u8, sz_io: usize, sz_style: usize, sz_vec2: usize, sz_vec4: usize, sz_drawvert: usize, sz_drawidx: usize) bool { //igDebugCheckVersionAndDataLayout
    return c.igDebugCheckVersionAndDataLayout(version_str, sz_io, sz_style, sz_vec2, sz_vec4, sz_drawvert, sz_drawidx);
}
pub inline fn setAllocatorFunctions(alloc_func: MemAllocFunc, free_func: MemFreeFunc, user_data: ?*anyopaque) void { //igSetAllocatorFunctions
    c.igSetAllocatorFunctions(alloc_func, free_func, user_data);
}
pub inline fn getAllocatorFunctions(p_alloc_func: [*c]MemAllocFunc, p_free_func: [*c]MemFreeFunc, p_user_data: [*c]void) void { //igGetAllocatorFunctions
    c.igGetAllocatorFunctions(p_alloc_func, p_free_func, p_user_data);
}
pub inline fn memAlloc(size: usize) ?*anyopaque { //igMemAlloc
    return c.igMemAlloc(size);
}
pub inline fn memFree(ptr: ?*anyopaque) void { //igMemFree
    c.igMemFree(ptr);
}
pub inline fn getPlatformIO() [*c]PlatformIO { //igGetPlatformIO
    return c.igGetPlatformIO();
}
pub inline fn updatePlatformWindows() void { //igUpdatePlatformWindows
    c.igUpdatePlatformWindows();
}
pub inline fn renderPlatformWindowsDefault(platform_render_arg: ?*anyopaque, renderer_render_arg: ?*anyopaque) void { //igRenderPlatformWindowsDefault
    c.igRenderPlatformWindowsDefault(platform_render_arg, renderer_render_arg);
}
pub inline fn destroyPlatformWindows() void { //igDestroyPlatformWindows
    c.igDestroyPlatformWindows();
}
pub inline fn findViewportByID(id: ID) [*c]Viewport { //igFindViewportByID
    return c.igFindViewportByID(id);
}
pub inline fn findViewportByPlatformHandle(platform_handle: ?*anyopaque) [*c]Viewport { //igFindViewportByPlatformHandle
    return c.igFindViewportByPlatformHandle(platform_handle);
}
pub inline fn getKeyIndex(key: Key) c_int { //igGetKeyIndex
    return c.igGetKeyIndex(@intFromEnum(key));
}
pub inline fn imHashData(data: [*c]const void, data_size: usize, seed: U32) ID { //igImHashData
    return c.igImHashData(data, data_size, seed);
}
pub inline fn imHashStr(data: [*c]const u8, data_size: usize, seed: U32) ID { //igImHashStr
    return c.igImHashStr(data, data_size, seed);
}
pub inline fn imQsort(base: ?*anyopaque, count: usize, size_of_element: usize) void { //igImQsort
    c.igImQsort(base, count, size_of_element);
}
pub inline fn imAlphaBlendColors(col_a: U32, col_b: U32) U32 { //igImAlphaBlendColors
    return c.igImAlphaBlendColors(col_a, col_b);
}
pub inline fn imIsPowerOfTwo_Int(v: c_int) bool { //igImIsPowerOfTwo_Int
    return c.igImIsPowerOfTwo_Int(v);
}
pub inline fn imIsPowerOfTwo_U64(v: U64) bool { //igImIsPowerOfTwo_U64
    return c.igImIsPowerOfTwo_U64(v);
}
pub inline fn imUpperPowerOfTwo(v: c_int) c_int { //igImUpperPowerOfTwo
    return c.igImUpperPowerOfTwo(v);
}
pub inline fn imStricmp(str1: [*c]const u8, str2: [*c]const u8) c_int { //igImStricmp
    return c.igImStricmp(str1, str2);
}
pub inline fn imStrnicmp(str1: [*c]const u8, str2: [*c]const u8, count: usize) c_int { //igImStrnicmp
    return c.igImStrnicmp(str1, str2, count);
}
pub inline fn imStrncpy(dst: [*c]u8, src: [*c]const u8, count: usize) void { //igImStrncpy
    c.igImStrncpy(dst, src, count);
}
pub inline fn imStrdup(str: [*c]const u8) [*c]u8 { //igImStrdup
    return c.igImStrdup(str);
}
pub inline fn imStrdupcpy(dst: [*c]u8, p_dst_size: [*c]usize, str: [*c]const u8) [*c]u8 { //igImStrdupcpy
    return c.igImStrdupcpy(dst, p_dst_size, str);
}
pub inline fn imStrchrRange(str_begin: [*c]const u8, str_end: [*c]const u8, ch: u8) [*c]const u8 { //igImStrchrRange
    return c.igImStrchrRange(str_begin, str_end, ch);
}
pub inline fn imStrlenW(str: [*c]const Wchar) c_int { //igImStrlenW
    return c.igImStrlenW(str);
}
pub inline fn imStreolRange(str: [*c]const u8, str_end: [*c]const u8) [*c]const u8 { //igImStreolRange
    return c.igImStreolRange(str, str_end);
}
pub inline fn imStrbolW(buf_mid_line: [*c]const Wchar, buf_begin: [*c]const Wchar) [*c]const Wchar { //igImStrbolW
    return c.igImStrbolW(buf_mid_line, buf_begin);
}
pub inline fn imStristr(haystack: [*c]const u8, haystack_end: [*c]const u8, needle: [*c]const u8, needle_end: [*c]const u8) [*c]const u8 { //igImStristr
    return c.igImStristr(haystack, haystack_end, needle, needle_end);
}
pub inline fn imStrTrimBlanks(str: [*c]u8) void { //igImStrTrimBlanks
    c.igImStrTrimBlanks(str);
}
pub inline fn imStrSkipBlank(str: [*c]const u8) [*c]const u8 { //igImStrSkipBlank
    return c.igImStrSkipBlank(str);
}
pub inline fn imCharIsBlankA(ch: u8) bool { //igImCharIsBlankA
    return c.igImCharIsBlankA(ch);
}
pub inline fn imCharIsBlankW(ch: c_uint) bool { //igImCharIsBlankW
    return c.igImCharIsBlankW(ch);
}
pub inline fn imParseFormatFindStart(format: [*c]const u8) [*c]const u8 { //igImParseFormatFindStart
    return c.igImParseFormatFindStart(format);
}
pub inline fn imParseFormatFindEnd(format: [*c]const u8) [*c]const u8 { //igImParseFormatFindEnd
    return c.igImParseFormatFindEnd(format);
}
pub inline fn imParseFormatTrimDecorations(format: [*c]const u8, buf: [*c]u8, buf_size: usize) [*c]const u8 { //igImParseFormatTrimDecorations
    return c.igImParseFormatTrimDecorations(format, buf, buf_size);
}
pub inline fn imParseFormatSanitizeForPrinting(fmt_in: [*c]const u8, fmt_out: [*c]u8, fmt_out_size: usize) void { //igImParseFormatSanitizeForPrinting
    c.igImParseFormatSanitizeForPrinting(fmt_in, fmt_out, fmt_out_size);
}
pub inline fn imParseFormatSanitizeForScanning(fmt_in: [*c]const u8, fmt_out: [*c]u8, fmt_out_size: usize) [*c]const u8 { //igImParseFormatSanitizeForScanning
    return c.igImParseFormatSanitizeForScanning(fmt_in, fmt_out, fmt_out_size);
}
pub inline fn imParseFormatPrecision(format: [*c]const u8, default_value: c_int) c_int { //igImParseFormatPrecision
    return c.igImParseFormatPrecision(format, default_value);
}
pub inline fn imTextStrToUtf8(out_buf: [*c]u8, out_buf_size: c_int, in_text: [*c]const Wchar, in_text_end: [*c]const Wchar) c_int { //igImTextStrToUtf8
    return c.igImTextStrToUtf8(out_buf, out_buf_size, in_text, in_text_end);
}
pub inline fn imTextCharFromUtf8(out_char: [*c]c_uint, in_text: [*c]const u8, in_text_end: [*c]const u8) c_int { //igImTextCharFromUtf8
    return c.igImTextCharFromUtf8(out_char, in_text, in_text_end);
}
pub inline fn imTextStrFromUtf8(out_buf: [*c]Wchar, out_buf_size: c_int, in_text: [*c]const u8, in_text_end: [*c]const u8, in_remaining: [*c]const u8) c_int { //igImTextStrFromUtf8
    return c.igImTextStrFromUtf8(out_buf, out_buf_size, in_text, in_text_end, in_remaining);
}
pub inline fn imTextCountCharsFromUtf8(in_text: [*c]const u8, in_text_end: [*c]const u8) c_int { //igImTextCountCharsFromUtf8
    return c.igImTextCountCharsFromUtf8(in_text, in_text_end);
}
pub inline fn imTextCountUtf8BytesFromChar(in_text: [*c]const u8, in_text_end: [*c]const u8) c_int { //igImTextCountUtf8BytesFromChar
    return c.igImTextCountUtf8BytesFromChar(in_text, in_text_end);
}
pub inline fn imTextCountUtf8BytesFromStr(in_text: [*c]const Wchar, in_text_end: [*c]const Wchar) c_int { //igImTextCountUtf8BytesFromStr
    return c.igImTextCountUtf8BytesFromStr(in_text, in_text_end);
}
pub inline fn imFileOpen(filename: [*c]const u8, mode: [*c]const u8) FileHandle { //igImFileOpen
    return c.igImFileOpen(filename, mode);
}
pub inline fn imFileClose(file: FileHandle) bool { //igImFileClose
    return c.igImFileClose(file);
}
pub inline fn imFileGetSize(file: FileHandle) U64 { //igImFileGetSize
    return c.igImFileGetSize(file);
}
pub inline fn imFileRead(data: ?*anyopaque, size: U64, count: U64, file: FileHandle) U64 { //igImFileRead
    return c.igImFileRead(data, size, count, file);
}
pub inline fn imFileWrite(data: [*c]const void, size: U64, count: U64, file: FileHandle) U64 { //igImFileWrite
    return c.igImFileWrite(data, size, count, file);
}
pub inline fn imFileLoadToMemory(filename: [*c]const u8, mode: [*c]const u8, out_file_size: [*c]usize, padding_bytes: c_int) ?*anyopaque { //igImFileLoadToMemory
    return c.igImFileLoadToMemory(filename, mode, out_file_size, padding_bytes);
}
pub inline fn imPow_Float(x: f32, y: f32) f32 { //igImPow_Float
    return c.igImPow_Float(x, y);
}
pub inline fn imPow_double(x: f64, y: f64) f64 { //igImPow_double
    return c.igImPow_double(x, y);
}
pub inline fn imLog_Float(x: f32) f32 { //igImLog_Float
    return c.igImLog_Float(x);
}
pub inline fn imLog_double(x: f64) f64 { //igImLog_double
    return c.igImLog_double(x);
}
pub inline fn imAbs_Int(x: c_int) c_int { //igImAbs_Int
    return c.igImAbs_Int(x);
}
pub inline fn imAbs_Float(x: f32) f32 { //igImAbs_Float
    return c.igImAbs_Float(x);
}
pub inline fn imAbs_double(x: f64) f64 { //igImAbs_double
    return c.igImAbs_double(x);
}
pub inline fn imSign_Float(x: f32) f32 { //igImSign_Float
    return c.igImSign_Float(x);
}
pub inline fn imSign_double(x: f64) f64 { //igImSign_double
    return c.igImSign_double(x);
}
pub inline fn imRsqrt_Float(x: f32) f32 { //igImRsqrt_Float
    return c.igImRsqrt_Float(x);
}
pub inline fn imRsqrt_double(x: f64) f64 { //igImRsqrt_double
    return c.igImRsqrt_double(x);
}
pub inline fn imMin(pout: [*c]Vec2, lhs: Vec2, rhs: Vec2) void { //igImMin
    c.igImMin(pout, @bitCast(lhs), @bitCast(rhs));
}
pub inline fn imMax(pout: [*c]Vec2, lhs: Vec2, rhs: Vec2) void { //igImMax
    c.igImMax(pout, @bitCast(lhs), @bitCast(rhs));
}
pub inline fn imClamp(pout: [*c]Vec2, v: Vec2, mn: Vec2, mx: Vec2) void { //igImClamp
    c.igImClamp(pout, @bitCast(v), @bitCast(mn), @bitCast(mx));
}
pub inline fn imLerp_Vec2Float(pout: [*c]Vec2, a: Vec2, b: Vec2, t: f32) void { //igImLerp_Vec2Float
    c.igImLerp_Vec2Float(pout, @bitCast(a), @bitCast(b), t);
}
pub inline fn imLerp_Vec2Vec2(pout: [*c]Vec2, a: Vec2, b: Vec2, t: Vec2) void { //igImLerp_Vec2Vec2
    c.igImLerp_Vec2Vec2(pout, @bitCast(a), @bitCast(b), @bitCast(t));
}
pub inline fn imLerp_Vec4(pout: [*c]Vec4, a: Vec4, b: Vec4, t: f32) void { //igImLerp_Vec4
    c.igImLerp_Vec4(pout, @bitCast(a), @bitCast(b), t);
}
pub inline fn imSaturate(f: f32) f32 { //igImSaturate
    return c.igImSaturate(f);
}
pub inline fn imLengthSqr_Vec2(lhs: Vec2) f32 { //igImLengthSqr_Vec2
    return c.igImLengthSqr_Vec2(@bitCast(lhs));
}
pub inline fn imLengthSqr_Vec4(lhs: Vec4) f32 { //igImLengthSqr_Vec4
    return c.igImLengthSqr_Vec4(@bitCast(lhs));
}
pub inline fn imInvLength(lhs: Vec2, fail_value: f32) f32 { //igImInvLength
    return c.igImInvLength(@bitCast(lhs), fail_value);
}
pub inline fn imFloor_Float(f: f32) f32 { //igImFloor_Float
    return c.igImFloor_Float(f);
}
pub inline fn imFloorSigned_Float(f: f32) f32 { //igImFloorSigned_Float
    return c.igImFloorSigned_Float(f);
}
pub inline fn imFloor_Vec2(pout: [*c]Vec2, v: Vec2) void { //igImFloor_Vec2
    c.igImFloor_Vec2(pout, @bitCast(v));
}
pub inline fn imFloorSigned_Vec2(pout: [*c]Vec2, v: Vec2) void { //igImFloorSigned_Vec2
    c.igImFloorSigned_Vec2(pout, @bitCast(v));
}
pub inline fn imModPositive(a: c_int, b: c_int) c_int { //igImModPositive
    return c.igImModPositive(a, b);
}
pub inline fn imDot(a: Vec2, b: Vec2) f32 { //igImDot
    return c.igImDot(@bitCast(a), @bitCast(b));
}
pub inline fn imRotate(pout: [*c]Vec2, v: Vec2, cos_a: f32, sin_a: f32) void { //igImRotate
    c.igImRotate(pout, @bitCast(v), cos_a, sin_a);
}
pub inline fn imLinearSweep(current: f32, target: f32, speed: f32) f32 { //igImLinearSweep
    return c.igImLinearSweep(current, target, speed);
}
pub inline fn imMul(pout: [*c]Vec2, lhs: Vec2, rhs: Vec2) void { //igImMul
    c.igImMul(pout, @bitCast(lhs), @bitCast(rhs));
}
pub inline fn imIsFloatAboveGuaranteedIntegerPrecision(f: f32) bool { //igImIsFloatAboveGuaranteedIntegerPrecision
    return c.igImIsFloatAboveGuaranteedIntegerPrecision(f);
}
pub inline fn imBezierCubicCalc(pout: [*c]Vec2, p1: Vec2, p2: Vec2, p3: Vec2, p4: Vec2, t: f32) void { //igImBezierCubicCalc
    c.igImBezierCubicCalc(pout, @bitCast(p1), @bitCast(p2), @bitCast(p3), @bitCast(p4), t);
}
pub inline fn imBezierCubicClosestPoint(pout: [*c]Vec2, p1: Vec2, p2: Vec2, p3: Vec2, p4: Vec2, p: Vec2, num_segments: c_int) void { //igImBezierCubicClosestPoint
    c.igImBezierCubicClosestPoint(pout, @bitCast(p1), @bitCast(p2), @bitCast(p3), @bitCast(p4), @bitCast(p), num_segments);
}
pub inline fn imBezierCubicClosestPointCasteljau(pout: [*c]Vec2, p1: Vec2, p2: Vec2, p3: Vec2, p4: Vec2, p: Vec2, tess_tol: f32) void { //igImBezierCubicClosestPointCasteljau
    c.igImBezierCubicClosestPointCasteljau(pout, @bitCast(p1), @bitCast(p2), @bitCast(p3), @bitCast(p4), @bitCast(p), tess_tol);
}
pub inline fn imBezierQuadraticCalc(pout: [*c]Vec2, p1: Vec2, p2: Vec2, p3: Vec2, t: f32) void { //igImBezierQuadraticCalc
    c.igImBezierQuadraticCalc(pout, @bitCast(p1), @bitCast(p2), @bitCast(p3), t);
}
pub inline fn imLineClosestPoint(pout: [*c]Vec2, a: Vec2, b: Vec2, p: Vec2) void { //igImLineClosestPoint
    c.igImLineClosestPoint(pout, @bitCast(a), @bitCast(b), @bitCast(p));
}
pub inline fn imTriangleContainsPoint(a: Vec2, b: Vec2, _c: Vec2, p: Vec2) bool { //igImTriangleContainsPoint
    return c.igImTriangleContainsPoint(@bitCast(a), @bitCast(b), @bitCast(_c), @bitCast(p));
}
pub inline fn imTriangleClosestPoint(pout: [*c]Vec2, a: Vec2, b: Vec2, _c: Vec2, p: Vec2) void { //igImTriangleClosestPoint
    c.igImTriangleClosestPoint(pout, @bitCast(a), @bitCast(b), @bitCast(_c), @bitCast(p));
}
pub inline fn imTriangleBarycentricCoords(a: Vec2, b: Vec2, _c: Vec2, p: Vec2, out_u: [*c]f32, out_v: [*c]f32, out_w: [*c]f32) void { //igImTriangleBarycentricCoords
    c.igImTriangleBarycentricCoords(@bitCast(a), @bitCast(b), @bitCast(_c), @bitCast(p), out_u, out_v, out_w);
}
pub inline fn imTriangleArea(a: Vec2, b: Vec2, _c: Vec2) f32 { //igImTriangleArea
    return c.igImTriangleArea(@bitCast(a), @bitCast(b), @bitCast(_c));
}
pub inline fn imGetDirQuadrantFromDelta(dx: f32, dy: f32) Dir { //igImGetDirQuadrantFromDelta
    return c.igImGetDirQuadrantFromDelta(dx, dy);
}
pub inline fn imBitArrayTestBit(arr: [*c]const U32, n: c_int) bool { //igImBitArrayTestBit
    return c.igImBitArrayTestBit(arr, n);
}
pub inline fn imBitArrayClearBit(arr: [*c]U32, n: c_int) void { //igImBitArrayClearBit
    c.igImBitArrayClearBit(arr, n);
}
pub inline fn imBitArraySetBit(arr: [*c]U32, n: c_int) void { //igImBitArraySetBit
    c.igImBitArraySetBit(arr, n);
}
pub inline fn imBitArraySetBitRange(arr: [*c]U32, n: c_int, n2: c_int) void { //igImBitArraySetBitRange
    c.igImBitArraySetBitRange(arr, n, n2);
}
pub inline fn getCurrentWindowRead() [*c]Window { //igGetCurrentWindowRead
    return c.igGetCurrentWindowRead();
}
pub inline fn getCurrentWindow() [*c]Window { //igGetCurrentWindow
    return c.igGetCurrentWindow();
}
pub inline fn findWindowByID(id: ID) [*c]Window { //igFindWindowByID
    return c.igFindWindowByID(id);
}
pub inline fn findWindowByName(name: [*c]const u8) [*c]Window { //igFindWindowByName
    return c.igFindWindowByName(name);
}
pub inline fn updateWindowParentAndRootLinks(window: [*c]Window, flags: WindowFlags, parent_window: [*c]Window) void { //igUpdateWindowParentAndRootLinks
    c.igUpdateWindowParentAndRootLinks(window, @bitCast(flags), parent_window);
}
pub inline fn calcWindowNextAutoFitSize(pout: [*c]Vec2, window: [*c]Window) void { //igCalcWindowNextAutoFitSize
    c.igCalcWindowNextAutoFitSize(pout, window);
}
pub inline fn isWindowChildOf(window: [*c]Window, potential_parent: [*c]Window, popup_hierarchy: bool, dock_hierarchy: bool) bool { //igIsWindowChildOf
    return c.igIsWindowChildOf(window, potential_parent, popup_hierarchy, dock_hierarchy);
}
pub inline fn isWindowWithinBeginStackOf(window: [*c]Window, potential_parent: [*c]Window) bool { //igIsWindowWithinBeginStackOf
    return c.igIsWindowWithinBeginStackOf(window, potential_parent);
}
pub inline fn isWindowAbove(potential_above: [*c]Window, potential_below: [*c]Window) bool { //igIsWindowAbove
    return c.igIsWindowAbove(potential_above, potential_below);
}
pub inline fn isWindowNavFocusable(window: [*c]Window) bool { //igIsWindowNavFocusable
    return c.igIsWindowNavFocusable(window);
}
pub inline fn setWindowPos_WindowPtr(window: [*c]Window, pos: Vec2, cond: Cond) void { //igSetWindowPos_WindowPtr
    c.igSetWindowPos_WindowPtr(window, @bitCast(pos), @bitCast(cond));
}
pub inline fn setWindowSize_WindowPtr(window: [*c]Window, size: Vec2, cond: Cond) void { //igSetWindowSize_WindowPtr
    c.igSetWindowSize_WindowPtr(window, @bitCast(size), @bitCast(cond));
}
pub inline fn setWindowCollapsed_WindowPtr(window: [*c]Window, collapsed: bool, cond: Cond) void { //igSetWindowCollapsed_WindowPtr
    c.igSetWindowCollapsed_WindowPtr(window, collapsed, @bitCast(cond));
}
pub inline fn setWindowHitTestHole(window: [*c]Window, pos: Vec2, size: Vec2) void { //igSetWindowHitTestHole
    c.igSetWindowHitTestHole(window, @bitCast(pos), @bitCast(size));
}
pub inline fn windowRectAbsToRel(pout: [*c]Rect, window: [*c]Window, r: Rect) void { //igWindowRectAbsToRel
    c.igWindowRectAbsToRel(pout, window, @bitCast(r));
}
pub inline fn windowRectRelToAbs(pout: [*c]Rect, window: [*c]Window, r: Rect) void { //igWindowRectRelToAbs
    c.igWindowRectRelToAbs(pout, window, @bitCast(r));
}
pub inline fn focusWindow(window: [*c]Window) void { //igFocusWindow
    c.igFocusWindow(window);
}
pub inline fn focusTopMostWindowUnderOne(under_this_window: [*c]Window, ignore_window: [*c]Window) void { //igFocusTopMostWindowUnderOne
    c.igFocusTopMostWindowUnderOne(under_this_window, ignore_window);
}
pub inline fn bringWindowToFocusFront(window: [*c]Window) void { //igBringWindowToFocusFront
    c.igBringWindowToFocusFront(window);
}
pub inline fn bringWindowToDisplayFront(window: [*c]Window) void { //igBringWindowToDisplayFront
    c.igBringWindowToDisplayFront(window);
}
pub inline fn bringWindowToDisplayBack(window: [*c]Window) void { //igBringWindowToDisplayBack
    c.igBringWindowToDisplayBack(window);
}
pub inline fn bringWindowToDisplayBehind(window: [*c]Window, above_window: [*c]Window) void { //igBringWindowToDisplayBehind
    c.igBringWindowToDisplayBehind(window, above_window);
}
pub inline fn findWindowDisplayIndex(window: [*c]Window) c_int { //igFindWindowDisplayIndex
    return c.igFindWindowDisplayIndex(window);
}
pub inline fn findBottomMostVisibleWindowWithinBeginStack(window: [*c]Window) [*c]Window { //igFindBottomMostVisibleWindowWithinBeginStack
    return c.igFindBottomMostVisibleWindowWithinBeginStack(window);
}
pub inline fn setCurrentFont(font: [*c]Font) void { //igSetCurrentFont
    c.igSetCurrentFont(font);
}
pub inline fn getDefaultFont() [*c]Font { //igGetDefaultFont
    return c.igGetDefaultFont();
}
pub inline fn getForegroundDrawList_WindowPtr(window: [*c]Window) [*c]DrawList { //igGetForegroundDrawList_WindowPtr
    return c.igGetForegroundDrawList_WindowPtr(window);
}
pub inline fn initialize() void { //igInitialize
    c.igInitialize();
}
pub inline fn shutdown() void { //igShutdown
    c.igShutdown();
}
pub inline fn updateInputEvents(trickle_fast_inputs: bool) void { //igUpdateInputEvents
    c.igUpdateInputEvents(trickle_fast_inputs);
}
pub inline fn updateHoveredWindowAndCaptureFlags() void { //igUpdateHoveredWindowAndCaptureFlags
    c.igUpdateHoveredWindowAndCaptureFlags();
}
pub inline fn startMouseMovingWindow(window: [*c]Window) void { //igStartMouseMovingWindow
    c.igStartMouseMovingWindow(window);
}
pub inline fn startMouseMovingWindowOrNode(window: [*c]Window, node: [*c]DockNode, undock_floating_node: bool) void { //igStartMouseMovingWindowOrNode
    c.igStartMouseMovingWindowOrNode(window, node, undock_floating_node);
}
pub inline fn updateMouseMovingWindowNewFrame() void { //igUpdateMouseMovingWindowNewFrame
    c.igUpdateMouseMovingWindowNewFrame();
}
pub inline fn updateMouseMovingWindowEndFrame() void { //igUpdateMouseMovingWindowEndFrame
    c.igUpdateMouseMovingWindowEndFrame();
}
pub inline fn addContextHook(context: [*c]Context, hook: [*c]const ContextHook) ID { //igAddContextHook
    return c.igAddContextHook(context, hook);
}
pub inline fn removeContextHook(context: [*c]Context, hook_to_remove: ID) void { //igRemoveContextHook
    c.igRemoveContextHook(context, hook_to_remove);
}
pub inline fn callContextHooks(context: [*c]Context, t: ContextHookType) void { //igCallContextHooks
    c.igCallContextHooks(context, @intFromEnum(t));
}
pub inline fn translateWindowsInViewport(viewport: [*c]ViewportP, old_pos: Vec2, new_pos: Vec2) void { //igTranslateWindowsInViewport
    c.igTranslateWindowsInViewport(viewport, @bitCast(old_pos), @bitCast(new_pos));
}
pub inline fn scaleWindowsInViewport(viewport: [*c]ViewportP, scale: f32) void { //igScaleWindowsInViewport
    c.igScaleWindowsInViewport(viewport, scale);
}
pub inline fn destroyPlatformWindow(viewport: [*c]ViewportP) void { //igDestroyPlatformWindow
    c.igDestroyPlatformWindow(viewport);
}
pub inline fn setWindowViewport(window: [*c]Window, viewport: [*c]ViewportP) void { //igSetWindowViewport
    c.igSetWindowViewport(window, viewport);
}
pub inline fn setCurrentViewport(window: [*c]Window, viewport: [*c]ViewportP) void { //igSetCurrentViewport
    c.igSetCurrentViewport(window, viewport);
}
pub inline fn getViewportPlatformMonitor(viewport: [*c]Viewport) [*c]const PlatformMonitor { //igGetViewportPlatformMonitor
    return c.igGetViewportPlatformMonitor(viewport);
}
pub inline fn findHoveredViewportFromPlatformWindowStack(mouse_platform_pos: Vec2) [*c]ViewportP { //igFindHoveredViewportFromPlatformWindowStack
    return c.igFindHoveredViewportFromPlatformWindowStack(@bitCast(mouse_platform_pos));
}
pub inline fn markIniSettingsDirty_Nil() void { //igMarkIniSettingsDirty_Nil
    c.igMarkIniSettingsDirty_Nil();
}
pub inline fn markIniSettingsDirty_WindowPtr(window: [*c]Window) void { //igMarkIniSettingsDirty_WindowPtr
    c.igMarkIniSettingsDirty_WindowPtr(window);
}
pub inline fn clearIniSettings() void { //igClearIniSettings
    c.igClearIniSettings();
}
pub inline fn createNewWindowSettings(name: [*c]const u8) [*c]WindowSettings { //igCreateNewWindowSettings
    return c.igCreateNewWindowSettings(name);
}
pub inline fn findWindowSettings(id: ID) [*c]WindowSettings { //igFindWindowSettings
    return c.igFindWindowSettings(id);
}
pub inline fn findOrCreateWindowSettings(name: [*c]const u8) [*c]WindowSettings { //igFindOrCreateWindowSettings
    return c.igFindOrCreateWindowSettings(name);
}
pub inline fn addSettingsHandler(handler: [*c]const SettingsHandler) void { //igAddSettingsHandler
    c.igAddSettingsHandler(handler);
}
pub inline fn removeSettingsHandler(type_name: [*c]const u8) void { //igRemoveSettingsHandler
    c.igRemoveSettingsHandler(type_name);
}
pub inline fn findSettingsHandler(type_name: [*c]const u8) [*c]SettingsHandler { //igFindSettingsHandler
    return c.igFindSettingsHandler(type_name);
}
pub inline fn setNextWindowScroll(scroll: Vec2) void { //igSetNextWindowScroll
    c.igSetNextWindowScroll(@bitCast(scroll));
}
pub inline fn setScrollX_WindowPtr(window: [*c]Window, scroll_x: f32) void { //igSetScrollX_WindowPtr
    c.igSetScrollX_WindowPtr(window, scroll_x);
}
pub inline fn setScrollY_WindowPtr(window: [*c]Window, scroll_y: f32) void { //igSetScrollY_WindowPtr
    c.igSetScrollY_WindowPtr(window, scroll_y);
}
pub inline fn setScrollFromPosX_WindowPtr(window: [*c]Window, local_x: f32, center_x_ratio: f32) void { //igSetScrollFromPosX_WindowPtr
    c.igSetScrollFromPosX_WindowPtr(window, local_x, center_x_ratio);
}
pub inline fn setScrollFromPosY_WindowPtr(window: [*c]Window, local_y: f32, center_y_ratio: f32) void { //igSetScrollFromPosY_WindowPtr
    c.igSetScrollFromPosY_WindowPtr(window, local_y, center_y_ratio);
}
pub inline fn scrollToItem(flags: ScrollFlags) void { //igScrollToItem
    c.igScrollToItem(@bitCast(flags));
}
pub inline fn scrollToRect(window: [*c]Window, rect: Rect, flags: ScrollFlags) void { //igScrollToRect
    c.igScrollToRect(window, @bitCast(rect), @bitCast(flags));
}
pub inline fn scrollToRectEx(pout: [*c]Vec2, window: [*c]Window, rect: Rect, flags: ScrollFlags) void { //igScrollToRectEx
    c.igScrollToRectEx(pout, window, @bitCast(rect), @bitCast(flags));
}
pub inline fn scrollToBringRectIntoView(window: [*c]Window, rect: Rect) void { //igScrollToBringRectIntoView
    c.igScrollToBringRectIntoView(window, @bitCast(rect));
}
pub inline fn getItemID() ID { //igGetItemID
    return c.igGetItemID();
}
pub inline fn getItemStatusFlags() ItemStatusFlags { //igGetItemStatusFlags
    return c.igGetItemStatusFlags();
}
pub inline fn getItemFlags() ItemFlags { //igGetItemFlags
    return c.igGetItemFlags();
}
pub inline fn getActiveID() ID { //igGetActiveID
    return c.igGetActiveID();
}
pub inline fn getFocusID() ID { //igGetFocusID
    return c.igGetFocusID();
}
pub inline fn setActiveID(id: ID, window: [*c]Window) void { //igSetActiveID
    c.igSetActiveID(id, window);
}
pub inline fn setFocusID(id: ID, window: [*c]Window) void { //igSetFocusID
    c.igSetFocusID(id, window);
}
pub inline fn clearActiveID() void { //igClearActiveID
    c.igClearActiveID();
}
pub inline fn getHoveredID() ID { //igGetHoveredID
    return c.igGetHoveredID();
}
pub inline fn setHoveredID(id: ID) void { //igSetHoveredID
    c.igSetHoveredID(id);
}
pub inline fn keepAliveID(id: ID) void { //igKeepAliveID
    c.igKeepAliveID(id);
}
pub inline fn markItemEdited(id: ID) void { //igMarkItemEdited
    c.igMarkItemEdited(id);
}
pub inline fn pushOverrideID(id: ID) void { //igPushOverrideID
    c.igPushOverrideID(id);
}
pub inline fn getIDWithSeed(str_id_begin: [*c]const u8, str_id_end: [*c]const u8, seed: ID) ID { //igGetIDWithSeed
    return c.igGetIDWithSeed(str_id_begin, str_id_end, seed);
}
pub inline fn itemSize_Vec2(size: Vec2, text_baseline_y: f32) void { //igItemSize_Vec2
    c.igItemSize_Vec2(@bitCast(size), text_baseline_y);
}
pub inline fn itemSize_Rect(bb: Rect, text_baseline_y: f32) void { //igItemSize_Rect
    c.igItemSize_Rect(@bitCast(bb), text_baseline_y);
}
pub inline fn itemAdd(bb: Rect, id: ID, nav_bb: [*c]const Rect, extra_flags: ItemFlags) bool { //igItemAdd
    return c.igItemAdd(@bitCast(bb), id, nav_bb, @bitCast(extra_flags));
}
pub inline fn itemHoverable(bb: Rect, id: ID) bool { //igItemHoverable
    return c.igItemHoverable(@bitCast(bb), id);
}
pub inline fn isClippedEx(bb: Rect, id: ID) bool { //igIsClippedEx
    return c.igIsClippedEx(@bitCast(bb), id);
}
pub inline fn setLastItemData(item_id: ID, in_flags: ItemFlags, status_flags: ItemStatusFlags, item_rect: Rect) void { //igSetLastItemData
    c.igSetLastItemData(item_id, @bitCast(in_flags), @bitCast(status_flags), @bitCast(item_rect));
}
pub inline fn calcItemSize(pout: [*c]Vec2, size: Vec2, default_w: f32, default_h: f32) void { //igCalcItemSize
    c.igCalcItemSize(pout, @bitCast(size), default_w, default_h);
}
pub inline fn calcWrapWidthForPos(pos: Vec2, wrap_pos_x: f32) f32 { //igCalcWrapWidthForPos
    return c.igCalcWrapWidthForPos(@bitCast(pos), wrap_pos_x);
}
pub inline fn pushMultiItemsWidths(components: c_int, width_full: f32) void { //igPushMultiItemsWidths
    c.igPushMultiItemsWidths(components, width_full);
}
pub inline fn isItemToggledSelection() bool { //igIsItemToggledSelection
    return c.igIsItemToggledSelection();
}
pub inline fn getContentRegionMaxAbs(pout: [*c]Vec2) void { //igGetContentRegionMaxAbs
    c.igGetContentRegionMaxAbs(pout);
}
pub inline fn shrinkWidths(items: [*c]ShrinkWidthItem, count: c_int, width_excess: f32) void { //igShrinkWidths
    c.igShrinkWidths(items, count, width_excess);
}
pub inline fn pushItemFlag(option: ItemFlags, enabled: bool) void { //igPushItemFlag
    c.igPushItemFlag(@bitCast(option), enabled);
}
pub inline fn popItemFlag() void { //igPopItemFlag
    c.igPopItemFlag();
}
pub inline fn logBegin(t: LogType, auto_open_depth: c_int) void { //igLogBegin
    c.igLogBegin(@intFromEnum(t), auto_open_depth);
}
pub inline fn logToBuffer(auto_open_depth: c_int) void { //igLogToBuffer
    c.igLogToBuffer(auto_open_depth);
}
pub inline fn logRenderedText(ref_pos: [*c]const Vec2, text: [*c]const u8, text_end: [*c]const u8) void { //igLogRenderedText
    c.igLogRenderedText(ref_pos, text, text_end);
}
pub inline fn logSetNextTextDecoration(prefix: [*c]const u8, suffix: [*c]const u8) void { //igLogSetNextTextDecoration
    c.igLogSetNextTextDecoration(prefix, suffix);
}
pub inline fn beginChildEx(name: [*c]const u8, id: ID, size_arg: Vec2, border: bool, flags: WindowFlags) bool { //igBeginChildEx
    return c.igBeginChildEx(name, id, @bitCast(size_arg), border, @bitCast(flags));
}
pub inline fn openPopupEx(id: ID, popup_flags: PopupFlags) void { //igOpenPopupEx
    c.igOpenPopupEx(id, @bitCast(popup_flags));
}
pub inline fn closePopupToLevel(remaining: c_int, restore_focus_to_window_under_popup: bool) void { //igClosePopupToLevel
    c.igClosePopupToLevel(remaining, restore_focus_to_window_under_popup);
}
pub inline fn closePopupsOverWindow(ref_window: [*c]Window, restore_focus_to_window_under_popup: bool) void { //igClosePopupsOverWindow
    c.igClosePopupsOverWindow(ref_window, restore_focus_to_window_under_popup);
}
pub inline fn closePopupsExceptModals() void { //igClosePopupsExceptModals
    c.igClosePopupsExceptModals();
}
pub inline fn isPopupOpen_ID(id: ID, popup_flags: PopupFlags) bool { //igIsPopupOpen_ID
    return c.igIsPopupOpen_ID(id, @bitCast(popup_flags));
}
pub inline fn beginPopupEx(id: ID, extra_flags: WindowFlags) bool { //igBeginPopupEx
    return c.igBeginPopupEx(id, @bitCast(extra_flags));
}
pub inline fn beginTooltipEx(tooltip_flags: TooltipFlags, extra_window_flags: WindowFlags) void { //igBeginTooltipEx
    c.igBeginTooltipEx(@bitCast(tooltip_flags), @bitCast(extra_window_flags));
}
pub inline fn getPopupAllowedExtentRect(pout: [*c]Rect, window: [*c]Window) void { //igGetPopupAllowedExtentRect
    c.igGetPopupAllowedExtentRect(pout, window);
}
pub inline fn getTopMostPopupModal() [*c]Window { //igGetTopMostPopupModal
    return c.igGetTopMostPopupModal();
}
pub inline fn getTopMostAndVisiblePopupModal() [*c]Window { //igGetTopMostAndVisiblePopupModal
    return c.igGetTopMostAndVisiblePopupModal();
}
pub inline fn findBestWindowPosForPopup(pout: [*c]Vec2, window: [*c]Window) void { //igFindBestWindowPosForPopup
    c.igFindBestWindowPosForPopup(pout, window);
}
pub inline fn findBestWindowPosForPopupEx(pout: [*c]Vec2, ref_pos: Vec2, size: Vec2, last_dir: [*c]Dir, r_outer: Rect, r_avoid: Rect, policy: PopupPositionPolicy) void { //igFindBestWindowPosForPopupEx
    c.igFindBestWindowPosForPopupEx(pout, @bitCast(ref_pos), @bitCast(size), last_dir, @bitCast(r_outer), @bitCast(r_avoid), @intFromEnum(policy));
}
pub inline fn beginViewportSideBar(name: [*c]const u8, viewport: [*c]Viewport, dir: Dir, size: f32, window_flags: WindowFlags) bool { //igBeginViewportSideBar
    return c.igBeginViewportSideBar(name, viewport, @intFromEnum(dir), size, @bitCast(window_flags));
}
pub inline fn beginMenuEx(label: [*c]const u8, icon: [*c]const u8, enabled: bool) bool { //igBeginMenuEx
    return c.igBeginMenuEx(label, icon, enabled);
}
pub inline fn menuItemEx(label: [*c]const u8, icon: [*c]const u8, shortcut: [*c]const u8, selected: bool, enabled: bool) bool { //igMenuItemEx
    return c.igMenuItemEx(label, icon, shortcut, selected, enabled);
}
pub inline fn beginComboPopup(popup_id: ID, bb: Rect, flags: ComboFlags) bool { //igBeginComboPopup
    return c.igBeginComboPopup(popup_id, @bitCast(bb), @bitCast(flags));
}
pub inline fn beginComboPreview() bool { //igBeginComboPreview
    return c.igBeginComboPreview();
}
pub inline fn endComboPreview() void { //igEndComboPreview
    c.igEndComboPreview();
}
pub inline fn navInitWindow(window: [*c]Window, force_reinit: bool) void { //igNavInitWindow
    c.igNavInitWindow(window, force_reinit);
}
pub inline fn navInitRequestApplyResult() void { //igNavInitRequestApplyResult
    c.igNavInitRequestApplyResult();
}
pub inline fn navMoveRequestButNoResultYet() bool { //igNavMoveRequestButNoResultYet
    return c.igNavMoveRequestButNoResultYet();
}
pub inline fn navMoveRequestSubmit(move_dir: Dir, clip_dir: Dir, move_flags: NavMoveFlags, scroll_flags: ScrollFlags) void { //igNavMoveRequestSubmit
    c.igNavMoveRequestSubmit(@intFromEnum(move_dir), @intFromEnum(clip_dir), @bitCast(move_flags), @bitCast(scroll_flags));
}
pub inline fn navMoveRequestForward(move_dir: Dir, clip_dir: Dir, move_flags: NavMoveFlags, scroll_flags: ScrollFlags) void { //igNavMoveRequestForward
    c.igNavMoveRequestForward(@intFromEnum(move_dir), @intFromEnum(clip_dir), @bitCast(move_flags), @bitCast(scroll_flags));
}
pub inline fn navMoveRequestResolveWithLastItem(result: [*c]NavItemData) void { //igNavMoveRequestResolveWithLastItem
    c.igNavMoveRequestResolveWithLastItem(result);
}
pub inline fn navMoveRequestCancel() void { //igNavMoveRequestCancel
    c.igNavMoveRequestCancel();
}
pub inline fn navMoveRequestApplyResult() void { //igNavMoveRequestApplyResult
    c.igNavMoveRequestApplyResult();
}
pub inline fn navMoveRequestTryWrapping(window: [*c]Window, move_flags: NavMoveFlags) void { //igNavMoveRequestTryWrapping
    c.igNavMoveRequestTryWrapping(window, @bitCast(move_flags));
}
pub inline fn getNavInputName(n: NavInput) [*c]const u8 { //igGetNavInputName
    return c.igGetNavInputName(@intFromEnum(n));
}
pub inline fn getNavInputAmount(n: NavInput, mode: NavReadMode) f32 { //igGetNavInputAmount
    return c.igGetNavInputAmount(@intFromEnum(n), @intFromEnum(mode));
}
pub inline fn getNavInputAmount2d(pout: [*c]Vec2, dir_sources: NavDirSourceFlags, mode: NavReadMode, slow_factor: f32, fast_factor: f32) void { //igGetNavInputAmount2d
    c.igGetNavInputAmount2d(pout, @bitCast(dir_sources), @intFromEnum(mode), slow_factor, fast_factor);
}
pub inline fn calcTypematicRepeatAmount(t0: f32, t1: f32, repeat_delay: f32, repeat_rate: f32) c_int { //igCalcTypematicRepeatAmount
    return c.igCalcTypematicRepeatAmount(t0, t1, repeat_delay, repeat_rate);
}
pub inline fn activateItem(id: ID) void { //igActivateItem
    c.igActivateItem(id);
}
pub inline fn setNavWindow(window: [*c]Window) void { //igSetNavWindow
    c.igSetNavWindow(window);
}
pub inline fn setNavID(id: ID, nav_layer: NavLayer, focus_scope_id: ID, rect_rel: Rect) void { //igSetNavID
    c.igSetNavID(id, @intFromEnum(nav_layer), focus_scope_id, @bitCast(rect_rel));
}
pub inline fn pushFocusScope(id: ID) void { //igPushFocusScope
    c.igPushFocusScope(id);
}
pub inline fn popFocusScope() void { //igPopFocusScope
    c.igPopFocusScope();
}
pub inline fn getFocusedFocusScope() ID { //igGetFocusedFocusScope
    return c.igGetFocusedFocusScope();
}
pub inline fn getFocusScope() ID { //igGetFocusScope
    return c.igGetFocusScope();
}
pub inline fn isNamedKey(key: Key) bool { //igIsNamedKey
    return c.igIsNamedKey(@intFromEnum(key));
}
pub inline fn isLegacyKey(key: Key) bool { //igIsLegacyKey
    return c.igIsLegacyKey(@intFromEnum(key));
}
pub inline fn isGamepadKey(key: Key) bool { //igIsGamepadKey
    return c.igIsGamepadKey(@intFromEnum(key));
}
pub inline fn getKeyData(key: Key) [*c]KeyData { //igGetKeyData
    return c.igGetKeyData(@intFromEnum(key));
}
pub inline fn setItemUsingMouseWheel() void { //igSetItemUsingMouseWheel
    c.igSetItemUsingMouseWheel();
}
pub inline fn setActiveIdUsingNavAndKeys() void { //igSetActiveIdUsingNavAndKeys
    c.igSetActiveIdUsingNavAndKeys();
}
pub inline fn isActiveIdUsingNavDir(dir: Dir) bool { //igIsActiveIdUsingNavDir
    return c.igIsActiveIdUsingNavDir(@intFromEnum(dir));
}
pub inline fn isActiveIdUsingNavInput(input: NavInput) bool { //igIsActiveIdUsingNavInput
    return c.igIsActiveIdUsingNavInput(@intFromEnum(input));
}
pub inline fn isActiveIdUsingKey(key: Key) bool { //igIsActiveIdUsingKey
    return c.igIsActiveIdUsingKey(@intFromEnum(key));
}
pub inline fn setActiveIdUsingKey(key: Key) void { //igSetActiveIdUsingKey
    c.igSetActiveIdUsingKey(@intFromEnum(key));
}
pub inline fn isMouseDragPastThreshold(btn: MouseButton, lock_threshold: f32) bool { //igIsMouseDragPastThreshold
    return c.igIsMouseDragPastThreshold(@intFromEnum(btn), lock_threshold);
}
pub inline fn isNavInputDown(n: NavInput) bool { //igIsNavInputDown
    return c.igIsNavInputDown(@intFromEnum(n));
}
pub inline fn isNavInputTest(n: NavInput, rm: NavReadMode) bool { //igIsNavInputTest
    return c.igIsNavInputTest(@intFromEnum(n), @intFromEnum(rm));
}
pub inline fn getMergedModFlags() ModFlags { //igGetMergedModFlags
    return c.igGetMergedModFlags();
}
pub inline fn isKeyPressedMap(key: Key, repeat: bool) bool { //igIsKeyPressedMap
    return c.igIsKeyPressedMap(@intFromEnum(key), repeat);
}
pub inline fn dockContextInitialize(ctx: [*c]Context) void { //igDockContextInitialize
    c.igDockContextInitialize(ctx);
}
pub inline fn dockContextShutdown(ctx: [*c]Context) void { //igDockContextShutdown
    c.igDockContextShutdown(ctx);
}
pub inline fn dockContextClearNodes(ctx: [*c]Context, root_id: ID, clear_settings_refs: bool) void { //igDockContextClearNodes
    c.igDockContextClearNodes(ctx, root_id, clear_settings_refs);
}
pub inline fn dockContextRebuildNodes(ctx: [*c]Context) void { //igDockContextRebuildNodes
    c.igDockContextRebuildNodes(ctx);
}
pub inline fn dockContextNewFrameUpdateUndocking(ctx: [*c]Context) void { //igDockContextNewFrameUpdateUndocking
    c.igDockContextNewFrameUpdateUndocking(ctx);
}
pub inline fn dockContextNewFrameUpdateDocking(ctx: [*c]Context) void { //igDockContextNewFrameUpdateDocking
    c.igDockContextNewFrameUpdateDocking(ctx);
}
pub inline fn dockContextEndFrame(ctx: [*c]Context) void { //igDockContextEndFrame
    c.igDockContextEndFrame(ctx);
}
pub inline fn dockContextGenNodeID(ctx: [*c]Context) ID { //igDockContextGenNodeID
    return c.igDockContextGenNodeID(ctx);
}
pub inline fn dockContextQueueDock(ctx: [*c]Context, target: [*c]Window, target_node: [*c]DockNode, payload: [*c]Window, split_dir: Dir, split_ratio: f32, split_outer: bool) void { //igDockContextQueueDock
    c.igDockContextQueueDock(ctx, target, target_node, payload, @intFromEnum(split_dir), split_ratio, split_outer);
}
pub inline fn dockContextQueueUndockWindow(ctx: [*c]Context, window: [*c]Window) void { //igDockContextQueueUndockWindow
    c.igDockContextQueueUndockWindow(ctx, window);
}
pub inline fn dockContextQueueUndockNode(ctx: [*c]Context, node: [*c]DockNode) void { //igDockContextQueueUndockNode
    c.igDockContextQueueUndockNode(ctx, node);
}
pub inline fn dockContextCalcDropPosForDocking(target: [*c]Window, target_node: [*c]DockNode, payload: [*c]Window, split_dir: Dir, split_outer: bool, out_pos: [*c]Vec2) bool { //igDockContextCalcDropPosForDocking
    return c.igDockContextCalcDropPosForDocking(target, target_node, payload, @intFromEnum(split_dir), split_outer, out_pos);
}
pub inline fn dockNodeBeginAmendTabBar(node: [*c]DockNode) bool { //igDockNodeBeginAmendTabBar
    return c.igDockNodeBeginAmendTabBar(node);
}
pub inline fn dockNodeEndAmendTabBar() void { //igDockNodeEndAmendTabBar
    c.igDockNodeEndAmendTabBar();
}
pub inline fn dockNodeGetRootNode(node: [*c]DockNode) [*c]DockNode { //igDockNodeGetRootNode
    return c.igDockNodeGetRootNode(node);
}
pub inline fn dockNodeIsInHierarchyOf(node: [*c]DockNode, parent: [*c]DockNode) bool { //igDockNodeIsInHierarchyOf
    return c.igDockNodeIsInHierarchyOf(node, parent);
}
pub inline fn dockNodeGetDepth(node: [*c]const DockNode) c_int { //igDockNodeGetDepth
    return c.igDockNodeGetDepth(node);
}
pub inline fn dockNodeGetWindowMenuButtonId(node: [*c]const DockNode) ID { //igDockNodeGetWindowMenuButtonId
    return c.igDockNodeGetWindowMenuButtonId(node);
}
pub inline fn getWindowDockNode() [*c]DockNode { //igGetWindowDockNode
    return c.igGetWindowDockNode();
}
pub inline fn getWindowAlwaysWantOwnTabBar(window: [*c]Window) bool { //igGetWindowAlwaysWantOwnTabBar
    return c.igGetWindowAlwaysWantOwnTabBar(window);
}
pub inline fn beginDocked(window: [*c]Window, p_open: [*c]bool) void { //igBeginDocked
    c.igBeginDocked(window, p_open);
}
pub inline fn beginDockableDragDropSource(window: [*c]Window) void { //igBeginDockableDragDropSource
    c.igBeginDockableDragDropSource(window);
}
pub inline fn beginDockableDragDropTarget(window: [*c]Window) void { //igBeginDockableDragDropTarget
    c.igBeginDockableDragDropTarget(window);
}
pub inline fn setWindowDock(window: [*c]Window, dock_id: ID, cond: Cond) void { //igSetWindowDock
    c.igSetWindowDock(window, dock_id, @bitCast(cond));
}
pub inline fn dockBuilderDockWindow(window_name: [*c]const u8, node_id: ID) void { //igDockBuilderDockWindow
    c.igDockBuilderDockWindow(window_name, node_id);
}
pub inline fn dockBuilderGetNode(node_id: ID) [*c]DockNode { //igDockBuilderGetNode
    return c.igDockBuilderGetNode(node_id);
}
pub inline fn dockBuilderGetCentralNode(node_id: ID) [*c]DockNode { //igDockBuilderGetCentralNode
    return c.igDockBuilderGetCentralNode(node_id);
}
pub inline fn dockBuilderAddNode(node_id: ID, flags: DockNodeFlags) ID { //igDockBuilderAddNode
    return c.igDockBuilderAddNode(node_id, @bitCast(flags));
}
pub inline fn dockBuilderRemoveNode(node_id: ID) void { //igDockBuilderRemoveNode
    c.igDockBuilderRemoveNode(node_id);
}
pub inline fn dockBuilderRemoveNodeDockedWindows(node_id: ID, clear_settings_refs: bool) void { //igDockBuilderRemoveNodeDockedWindows
    c.igDockBuilderRemoveNodeDockedWindows(node_id, clear_settings_refs);
}
pub inline fn dockBuilderRemoveNodeChildNodes(node_id: ID) void { //igDockBuilderRemoveNodeChildNodes
    c.igDockBuilderRemoveNodeChildNodes(node_id);
}
pub inline fn dockBuilderSetNodePos(node_id: ID, pos: Vec2) void { //igDockBuilderSetNodePos
    c.igDockBuilderSetNodePos(node_id, @bitCast(pos));
}
pub inline fn dockBuilderSetNodeSize(node_id: ID, size: Vec2) void { //igDockBuilderSetNodeSize
    c.igDockBuilderSetNodeSize(node_id, @bitCast(size));
}
pub inline fn dockBuilderSplitNode(node_id: ID, split_dir: Dir, size_ratio_for_node_at_dir: f32, out_id_at_dir: [*c]ID, out_id_at_opposite_dir: [*c]ID) ID { //igDockBuilderSplitNode
    return c.igDockBuilderSplitNode(node_id, @intFromEnum(split_dir), size_ratio_for_node_at_dir, out_id_at_dir, out_id_at_opposite_dir);
}
pub inline fn dockBuilderCopyDockSpace(src_dockspace_id: ID, dst_dockspace_id: ID, in_window_remap_pairs: [*c]CharVector) void { //igDockBuilderCopyDockSpace
    c.igDockBuilderCopyDockSpace(src_dockspace_id, dst_dockspace_id, in_window_remap_pairs);
}
pub inline fn dockBuilderCopyNode(src_node_id: ID, dst_node_id: ID, out_node_remap_pairs: [*c]IDVector) void { //igDockBuilderCopyNode
    c.igDockBuilderCopyNode(src_node_id, dst_node_id, out_node_remap_pairs);
}
pub inline fn dockBuilderCopyWindowSettings(src_name: [*c]const u8, dst_name: [*c]const u8) void { //igDockBuilderCopyWindowSettings
    c.igDockBuilderCopyWindowSettings(src_name, dst_name);
}
pub inline fn dockBuilderFinish(node_id: ID) void { //igDockBuilderFinish
    c.igDockBuilderFinish(node_id);
}
pub inline fn isDragDropActive() bool { //igIsDragDropActive
    return c.igIsDragDropActive();
}
pub inline fn beginDragDropTargetCustom(bb: Rect, id: ID) bool { //igBeginDragDropTargetCustom
    return c.igBeginDragDropTargetCustom(@bitCast(bb), id);
}
pub inline fn clearDragDrop() void { //igClearDragDrop
    c.igClearDragDrop();
}
pub inline fn isDragDropPayloadBeingAccepted() bool { //igIsDragDropPayloadBeingAccepted
    return c.igIsDragDropPayloadBeingAccepted();
}
pub inline fn setWindowClipRectBeforeSetChannel(window: [*c]Window, clip_rect: Rect) void { //igSetWindowClipRectBeforeSetChannel
    c.igSetWindowClipRectBeforeSetChannel(window, @bitCast(clip_rect));
}
pub inline fn beginColumns(str_id: [*c]const u8, count: c_int, flags: OldColumnFlags) void { //igBeginColumns
    c.igBeginColumns(str_id, count, @bitCast(flags));
}
pub inline fn endColumns() void { //igEndColumns
    c.igEndColumns();
}
pub inline fn pushColumnClipRect(column_index: c_int) void { //igPushColumnClipRect
    c.igPushColumnClipRect(column_index);
}
pub inline fn pushColumnsBackground() void { //igPushColumnsBackground
    c.igPushColumnsBackground();
}
pub inline fn popColumnsBackground() void { //igPopColumnsBackground
    c.igPopColumnsBackground();
}
pub inline fn getColumnsID(str_id: [*c]const u8, count: c_int) ID { //igGetColumnsID
    return c.igGetColumnsID(str_id, count);
}
pub inline fn getColumnOffsetFromNorm(col: [*c]const OldColumns, offset_norm: f32) f32 { //igGetColumnOffsetFromNorm
    return c.igGetColumnOffsetFromNorm(col, offset_norm);
}
pub inline fn getColumnNormFromOffset(col: [*c]const OldColumns, offset: f32) f32 { //igGetColumnNormFromOffset
    return c.igGetColumnNormFromOffset(col, offset);
}
pub inline fn tableOpenContextMenu(column_n: c_int) void { //igTableOpenContextMenu
    c.igTableOpenContextMenu(column_n);
}
pub inline fn tableSetColumnWidth(column_n: c_int, width: f32) void { //igTableSetColumnWidth
    c.igTableSetColumnWidth(column_n, width);
}
pub inline fn tableSetColumnSortDirection(column_n: c_int, sort_direction: SortDirection, append_to_sort_specs: bool) void { //igTableSetColumnSortDirection
    c.igTableSetColumnSortDirection(column_n, @intFromEnum(sort_direction), append_to_sort_specs);
}
pub inline fn tableGetHoveredColumn() c_int { //igTableGetHoveredColumn
    return c.igTableGetHoveredColumn();
}
pub inline fn tableGetHeaderRowHeight() f32 { //igTableGetHeaderRowHeight
    return c.igTableGetHeaderRowHeight();
}
pub inline fn tablePushBackgroundChannel() void { //igTablePushBackgroundChannel
    c.igTablePushBackgroundChannel();
}
pub inline fn tablePopBackgroundChannel() void { //igTablePopBackgroundChannel
    c.igTablePopBackgroundChannel();
}
pub inline fn getCurrentTable() [*c]Table { //igGetCurrentTable
    return c.igGetCurrentTable();
}
pub inline fn tableFindByID(id: ID) [*c]Table { //igTableFindByID
    return c.igTableFindByID(id);
}
pub inline fn beginTableEx(name: [*c]const u8, id: ID, columns_count: c_int, flags: TableFlags, outer_size: Vec2, inner_width: f32) bool { //igBeginTableEx
    return c.igBeginTableEx(name, id, columns_count, @bitCast(flags), @bitCast(outer_size), inner_width);
}
pub inline fn tableBeginInitMemory(table: [*c]Table, columns_count: c_int) void { //igTableBeginInitMemory
    c.igTableBeginInitMemory(table, columns_count);
}
pub inline fn tableBeginApplyRequests(table: [*c]Table) void { //igTableBeginApplyRequests
    c.igTableBeginApplyRequests(table);
}
pub inline fn tableSetupDrawChannels(table: [*c]Table) void { //igTableSetupDrawChannels
    c.igTableSetupDrawChannels(table);
}
pub inline fn tableUpdateLayout(table: [*c]Table) void { //igTableUpdateLayout
    c.igTableUpdateLayout(table);
}
pub inline fn tableUpdateBorders(table: [*c]Table) void { //igTableUpdateBorders
    c.igTableUpdateBorders(table);
}
pub inline fn tableUpdateColumnsWeightFromWidth(table: [*c]Table) void { //igTableUpdateColumnsWeightFromWidth
    c.igTableUpdateColumnsWeightFromWidth(table);
}
pub inline fn tableDrawBorders(table: [*c]Table) void { //igTableDrawBorders
    c.igTableDrawBorders(table);
}
pub inline fn tableDrawContextMenu(table: [*c]Table) void { //igTableDrawContextMenu
    c.igTableDrawContextMenu(table);
}
pub inline fn tableMergeDrawChannels(table: [*c]Table) void { //igTableMergeDrawChannels
    c.igTableMergeDrawChannels(table);
}
pub inline fn tableGetInstanceData(table: [*c]Table, instance_no: c_int) [*c]TableInstanceData { //igTableGetInstanceData
    return c.igTableGetInstanceData(table, instance_no);
}
pub inline fn tableSortSpecsSanitize(table: [*c]Table) void { //igTableSortSpecsSanitize
    c.igTableSortSpecsSanitize(table);
}
pub inline fn tableSortSpecsBuild(table: [*c]Table) void { //igTableSortSpecsBuild
    c.igTableSortSpecsBuild(table);
}
pub inline fn tableGetColumnNextSortDirection(column: [*c]TableColumn) SortDirection { //igTableGetColumnNextSortDirection
    return c.igTableGetColumnNextSortDirection(column);
}
pub inline fn tableFixColumnSortDirection(table: [*c]Table, column: [*c]TableColumn) void { //igTableFixColumnSortDirection
    c.igTableFixColumnSortDirection(table, column);
}
pub inline fn tableGetColumnWidthAuto(table: [*c]Table, column: [*c]TableColumn) f32 { //igTableGetColumnWidthAuto
    return c.igTableGetColumnWidthAuto(table, column);
}
pub inline fn tableBeginRow(table: [*c]Table) void { //igTableBeginRow
    c.igTableBeginRow(table);
}
pub inline fn tableEndRow(table: [*c]Table) void { //igTableEndRow
    c.igTableEndRow(table);
}
pub inline fn tableBeginCell(table: [*c]Table, column_n: c_int) void { //igTableBeginCell
    c.igTableBeginCell(table, column_n);
}
pub inline fn tableEndCell(table: [*c]Table) void { //igTableEndCell
    c.igTableEndCell(table);
}
pub inline fn tableGetCellBgRect(pout: [*c]Rect, table: [*c]const Table, column_n: c_int) void { //igTableGetCellBgRect
    c.igTableGetCellBgRect(pout, table, column_n);
}
pub inline fn tableGetColumnName_TablePtr(table: [*c]const Table, column_n: c_int) [*c]const u8 { //igTableGetColumnName_TablePtr
    return c.igTableGetColumnName_TablePtr(table, column_n);
}
pub inline fn tableGetColumnResizeID(table: [*c]const Table, column_n: c_int, instance_no: c_int) ID { //igTableGetColumnResizeID
    return c.igTableGetColumnResizeID(table, column_n, instance_no);
}
pub inline fn tableGetMaxColumnWidth(table: [*c]const Table, column_n: c_int) f32 { //igTableGetMaxColumnWidth
    return c.igTableGetMaxColumnWidth(table, column_n);
}
pub inline fn tableSetColumnWidthAutoSingle(table: [*c]Table, column_n: c_int) void { //igTableSetColumnWidthAutoSingle
    c.igTableSetColumnWidthAutoSingle(table, column_n);
}
pub inline fn tableSetColumnWidthAutoAll(table: [*c]Table) void { //igTableSetColumnWidthAutoAll
    c.igTableSetColumnWidthAutoAll(table);
}
pub inline fn tableRemove(table: [*c]Table) void { //igTableRemove
    c.igTableRemove(table);
}
pub inline fn tableGcCompactTransientBuffers_TablePtr(table: [*c]Table) void { //igTableGcCompactTransientBuffers_TablePtr
    c.igTableGcCompactTransientBuffers_TablePtr(table);
}
pub inline fn tableGcCompactTransientBuffers_TableTempDataPtr(table: [*c]TableTempData) void { //igTableGcCompactTransientBuffers_TableTempDataPtr
    c.igTableGcCompactTransientBuffers_TableTempDataPtr(table);
}
pub inline fn tableGcCompactSettings() void { //igTableGcCompactSettings
    c.igTableGcCompactSettings();
}
pub inline fn tableLoadSettings(table: [*c]Table) void { //igTableLoadSettings
    c.igTableLoadSettings(table);
}
pub inline fn tableSaveSettings(table: [*c]Table) void { //igTableSaveSettings
    c.igTableSaveSettings(table);
}
pub inline fn tableResetSettings(table: [*c]Table) void { //igTableResetSettings
    c.igTableResetSettings(table);
}
pub inline fn tableGetBoundSettings(table: [*c]Table) [*c]TableSettings { //igTableGetBoundSettings
    return c.igTableGetBoundSettings(table);
}
pub inline fn tableSettingsAddSettingsHandler() void { //igTableSettingsAddSettingsHandler
    c.igTableSettingsAddSettingsHandler();
}
pub inline fn tableSettingsCreate(id: ID, columns_count: c_int) [*c]TableSettings { //igTableSettingsCreate
    return c.igTableSettingsCreate(id, columns_count);
}
pub inline fn tableSettingsFindByID(id: ID) [*c]TableSettings { //igTableSettingsFindByID
    return c.igTableSettingsFindByID(id);
}
pub inline fn beginTabBarEx(tab_bar: [*c]TabBar, bb: Rect, flags: TabBarFlags, dock_node: [*c]DockNode) bool { //igBeginTabBarEx
    return c.igBeginTabBarEx(tab_bar, @bitCast(bb), @bitCast(flags), dock_node);
}
pub inline fn tabBarFindTabByID(tab_bar: [*c]TabBar, tab_id: ID) [*c]TabItem { //igTabBarFindTabByID
    return c.igTabBarFindTabByID(tab_bar, tab_id);
}
pub inline fn tabBarFindMostRecentlySelectedTabForActiveWindow(tab_bar: [*c]TabBar) [*c]TabItem { //igTabBarFindMostRecentlySelectedTabForActiveWindow
    return c.igTabBarFindMostRecentlySelectedTabForActiveWindow(tab_bar);
}
pub inline fn tabBarAddTab(tab_bar: [*c]TabBar, tab_flags: TabItemFlags, window: [*c]Window) void { //igTabBarAddTab
    c.igTabBarAddTab(tab_bar, @bitCast(tab_flags), window);
}
pub inline fn tabBarRemoveTab(tab_bar: [*c]TabBar, tab_id: ID) void { //igTabBarRemoveTab
    c.igTabBarRemoveTab(tab_bar, tab_id);
}
pub inline fn tabBarCloseTab(tab_bar: [*c]TabBar, tab: [*c]TabItem) void { //igTabBarCloseTab
    c.igTabBarCloseTab(tab_bar, tab);
}
pub inline fn tabBarQueueReorder(tab_bar: [*c]TabBar, tab: [*c]const TabItem, offset: c_int) void { //igTabBarQueueReorder
    c.igTabBarQueueReorder(tab_bar, tab, offset);
}
pub inline fn tabBarQueueReorderFromMousePos(tab_bar: [*c]TabBar, tab: [*c]const TabItem, mouse_pos: Vec2) void { //igTabBarQueueReorderFromMousePos
    c.igTabBarQueueReorderFromMousePos(tab_bar, tab, @bitCast(mouse_pos));
}
pub inline fn tabBarProcessReorder(tab_bar: [*c]TabBar) bool { //igTabBarProcessReorder
    return c.igTabBarProcessReorder(tab_bar);
}
pub inline fn tabItemEx(tab_bar: [*c]TabBar, label: [*c]const u8, p_open: [*c]bool, flags: TabItemFlags, docked_window: [*c]Window) bool { //igTabItemEx
    return c.igTabItemEx(tab_bar, label, p_open, @bitCast(flags), docked_window);
}
pub inline fn tabItemCalcSize(pout: [*c]Vec2, label: [*c]const u8, has_close_button: bool) void { //igTabItemCalcSize
    c.igTabItemCalcSize(pout, label, has_close_button);
}
pub inline fn tabItemBackground(draw_list: [*c]DrawList, bb: Rect, flags: TabItemFlags, col: U32) void { //igTabItemBackground
    c.igTabItemBackground(draw_list, @bitCast(bb), @bitCast(flags), col);
}
pub inline fn renderText(pos: Vec2, text: [*c]const u8, text_end: [*c]const u8, hide_text_after_hash: bool) void { //igRenderText
    c.igRenderText(@bitCast(pos), text, text_end, hide_text_after_hash);
}
pub inline fn renderTextWrapped(pos: Vec2, text: [*c]const u8, text_end: [*c]const u8, wrap_width: f32) void { //igRenderTextWrapped
    c.igRenderTextWrapped(@bitCast(pos), text, text_end, wrap_width);
}
pub inline fn renderTextEllipsis(draw_list: [*c]DrawList, pos_min: Vec2, pos_max: Vec2, clip_max_x: f32, ellipsis_max_x: f32, text: [*c]const u8, text_end: [*c]const u8, text_size_if_known: [*c]const Vec2) void { //igRenderTextEllipsis
    c.igRenderTextEllipsis(draw_list, @bitCast(pos_min), @bitCast(pos_max), clip_max_x, ellipsis_max_x, text, text_end, text_size_if_known);
}
pub inline fn renderFrame(p_min: Vec2, p_max: Vec2, fill_col: U32, border: bool, rounding: f32) void { //igRenderFrame
    c.igRenderFrame(@bitCast(p_min), @bitCast(p_max), fill_col, border, rounding);
}
pub inline fn renderFrameBorder(p_min: Vec2, p_max: Vec2, rounding: f32) void { //igRenderFrameBorder
    c.igRenderFrameBorder(@bitCast(p_min), @bitCast(p_max), rounding);
}
pub inline fn renderColorRectWithAlphaCheckerboard(draw_list: [*c]DrawList, p_min: Vec2, p_max: Vec2, fill_col: U32, grid_step: f32, grid_off: Vec2, rounding: f32, flags: DrawFlags) void { //igRenderColorRectWithAlphaCheckerboard
    c.igRenderColorRectWithAlphaCheckerboard(draw_list, @bitCast(p_min), @bitCast(p_max), fill_col, grid_step, @bitCast(grid_off), rounding, @bitCast(flags));
}
pub inline fn renderNavHighlight(bb: Rect, id: ID, flags: NavHighlightFlags) void { //igRenderNavHighlight
    c.igRenderNavHighlight(@bitCast(bb), id, @bitCast(flags));
}
pub inline fn findRenderedTextEnd(text: [*c]const u8, text_end: [*c]const u8) [*c]const u8 { //igFindRenderedTextEnd
    return c.igFindRenderedTextEnd(text, text_end);
}
pub inline fn renderMouseCursor(pos: Vec2, scale: f32, mouse_cursor: MouseCursor, col_fill: U32, col_border: U32, col_shadow: U32) void { //igRenderMouseCursor
    c.igRenderMouseCursor(@bitCast(pos), scale, @intFromEnum(mouse_cursor), col_fill, col_border, col_shadow);
}
pub inline fn renderArrow(draw_list: [*c]DrawList, pos: Vec2, col: U32, dir: Dir, scale: f32) void { //igRenderArrow
    c.igRenderArrow(draw_list, @bitCast(pos), col, @intFromEnum(dir), scale);
}
pub inline fn renderBullet(draw_list: [*c]DrawList, pos: Vec2, col: U32) void { //igRenderBullet
    c.igRenderBullet(draw_list, @bitCast(pos), col);
}
pub inline fn renderCheckMark(draw_list: [*c]DrawList, pos: Vec2, col: U32, sz: f32) void { //igRenderCheckMark
    c.igRenderCheckMark(draw_list, @bitCast(pos), col, sz);
}
pub inline fn renderArrowPointingAt(draw_list: [*c]DrawList, pos: Vec2, half_sz: Vec2, direction: Dir, col: U32) void { //igRenderArrowPointingAt
    c.igRenderArrowPointingAt(draw_list, @bitCast(pos), @bitCast(half_sz), @intFromEnum(direction), col);
}
pub inline fn renderArrowDockMenu(draw_list: [*c]DrawList, p_min: Vec2, sz: f32, col: U32) void { //igRenderArrowDockMenu
    c.igRenderArrowDockMenu(draw_list, @bitCast(p_min), sz, col);
}
pub inline fn renderRectFilledRangeH(draw_list: [*c]DrawList, rect: Rect, col: U32, x_start_norm: f32, x_end_norm: f32, rounding: f32) void { //igRenderRectFilledRangeH
    c.igRenderRectFilledRangeH(draw_list, @bitCast(rect), col, x_start_norm, x_end_norm, rounding);
}
pub inline fn renderRectFilledWithHole(draw_list: [*c]DrawList, outer: Rect, inner: Rect, col: U32, rounding: f32) void { //igRenderRectFilledWithHole
    c.igRenderRectFilledWithHole(draw_list, @bitCast(outer), @bitCast(inner), col, rounding);
}
pub inline fn calcRoundingFlagsForRectInRect(r_in: Rect, r_outer: Rect, threshold: f32) DrawFlags { //igCalcRoundingFlagsForRectInRect
    return c.igCalcRoundingFlagsForRectInRect(@bitCast(r_in), @bitCast(r_outer), threshold);
}
pub inline fn textEx(text: [*c]const u8, text_end: [*c]const u8, flags: TextFlags) void { //igTextEx
    c.igTextEx(text, text_end, @bitCast(flags));
}
pub inline fn buttonEx(label: [*c]const u8, size_arg: Vec2, flags: ButtonFlags) bool { //igButtonEx
    return c.igButtonEx(label, @bitCast(size_arg), flags);
}
pub inline fn closeButton(id: ID, pos: Vec2) bool { //igCloseButton
    return c.igCloseButton(id, @bitCast(pos));
}
pub inline fn collapseButton(id: ID, pos: Vec2, dock_node: [*c]DockNode) bool { //igCollapseButton
    return c.igCollapseButton(id, @bitCast(pos), dock_node);
}
pub inline fn arrowButtonEx(str_id: [*c]const u8, dir: Dir, size_arg: Vec2, flags: ButtonFlags) bool { //igArrowButtonEx
    return c.igArrowButtonEx(str_id, @intFromEnum(dir), @bitCast(size_arg), flags);
}
pub inline fn scrollbar(axis: Axis) void { //igScrollbar
    c.igScrollbar(@intFromEnum(axis));
}
pub inline fn scrollbarEx(bb: Rect, id: ID, axis: Axis, p_scroll_v: [*c]S64, avail_v: S64, contents_v: S64, flags: DrawFlags) bool { //igScrollbarEx
    return c.igScrollbarEx(@bitCast(bb), id, @intFromEnum(axis), p_scroll_v, avail_v, contents_v, @bitCast(flags));
}
pub inline fn imageButtonEx(id: ID, texture_id: TextureID, size: Vec2, uv0: Vec2, uv1: Vec2, padding: Vec2, bg_col: Vec4, tint_col: Vec4) bool { //igImageButtonEx
    return c.igImageButtonEx(id, texture_id, @bitCast(size), @bitCast(uv0), @bitCast(uv1), @bitCast(padding), @bitCast(bg_col), @bitCast(tint_col));
}
pub inline fn getWindowScrollbarRect(pout: [*c]Rect, window: [*c]Window, axis: Axis) void { //igGetWindowScrollbarRect
    c.igGetWindowScrollbarRect(pout, window, @intFromEnum(axis));
}
pub inline fn getWindowScrollbarID(window: [*c]Window, axis: Axis) ID { //igGetWindowScrollbarID
    return c.igGetWindowScrollbarID(window, @intFromEnum(axis));
}
pub inline fn getWindowResizeCornerID(window: [*c]Window, n: c_int) ID { //igGetWindowResizeCornerID
    return c.igGetWindowResizeCornerID(window, n);
}
pub inline fn getWindowResizeBorderID(window: [*c]Window, dir: Dir) ID { //igGetWindowResizeBorderID
    return c.igGetWindowResizeBorderID(window, @intFromEnum(dir));
}
pub inline fn separatorEx(flags: SeparatorFlags) void { //igSeparatorEx
    c.igSeparatorEx(@bitCast(flags));
}
pub inline fn checkboxFlags_S64Ptr(label: [*c]const u8, flags: [*c]S64, flags_value: S64) bool { //igCheckboxFlags_S64Ptr
    return c.igCheckboxFlags_S64Ptr(label, flags, flags_value);
}
pub inline fn checkboxFlags_U64Ptr(label: [*c]const u8, flags: [*c]U64, flags_value: U64) bool { //igCheckboxFlags_U64Ptr
    return c.igCheckboxFlags_U64Ptr(label, flags, flags_value);
}
pub inline fn buttonBehavior(bb: Rect, id: ID, out_hovered: [*c]bool, out_held: [*c]bool, flags: ButtonFlags) bool { //igButtonBehavior
    return c.igButtonBehavior(@bitCast(bb), id, out_hovered, out_held, flags);
}
pub inline fn dragBehavior(id: ID, data_type: DataType, p_v: ?*anyopaque, v_speed: f32, p_min: [*c]const void, p_max: [*c]const void, format: [*c]const u8, flags: SliderFlags) bool { //igDragBehavior
    return c.igDragBehavior(id, @intFromEnum(data_type), p_v, v_speed, p_min, p_max, format, @bitCast(flags));
}
pub inline fn sliderBehavior(bb: Rect, id: ID, data_type: DataType, p_v: ?*anyopaque, p_min: [*c]const void, p_max: [*c]const void, format: [*c]const u8, flags: SliderFlags, out_grab_bb: [*c]Rect) bool { //igSliderBehavior
    return c.igSliderBehavior(@bitCast(bb), id, @intFromEnum(data_type), p_v, p_min, p_max, format, @bitCast(flags), out_grab_bb);
}
pub inline fn splitterBehavior(bb: Rect, id: ID, axis: Axis, size1: [*c]f32, size2: [*c]f32, min_size1: f32, min_size2: f32, hover_extend: f32, hover_visibility_delay: f32, bg_col: U32) bool { //igSplitterBehavior
    return c.igSplitterBehavior(@bitCast(bb), id, @intFromEnum(axis), size1, size2, min_size1, min_size2, hover_extend, hover_visibility_delay, bg_col);
}
pub inline fn treeNodeBehavior(id: ID, flags: TreeNodeFlags, label: [*c]const u8, label_end: [*c]const u8) bool { //igTreeNodeBehavior
    return c.igTreeNodeBehavior(id, @bitCast(flags), label, label_end);
}
pub inline fn treeNodeBehaviorIsOpen(id: ID, flags: TreeNodeFlags) bool { //igTreeNodeBehaviorIsOpen
    return c.igTreeNodeBehaviorIsOpen(id, @bitCast(flags));
}
pub inline fn treePushOverrideID(id: ID) void { //igTreePushOverrideID
    c.igTreePushOverrideID(id);
}
pub inline fn dataTypeGetInfo(data_type: DataType) [*c]const DataTypeInfo { //igDataTypeGetInfo
    return c.igDataTypeGetInfo(@intFromEnum(data_type));
}
pub inline fn dataTypeFormatString(buf: [*c]u8, buf_size: c_int, data_type: DataType, p_data: [*c]const void, format: [*c]const u8) c_int { //igDataTypeFormatString
    return c.igDataTypeFormatString(buf, buf_size, @intFromEnum(data_type), p_data, format);
}
pub inline fn dataTypeApplyOp(data_type: DataType, op: c_int, output: ?*anyopaque, arg_1: [*c]const void, arg_2: [*c]const void) void { //igDataTypeApplyOp
    c.igDataTypeApplyOp(@intFromEnum(data_type), op, output, arg_1, arg_2);
}
pub inline fn dataTypeApplyFromText(buf: [*c]const u8, data_type: DataType, p_data: ?*anyopaque, format: [*c]const u8) bool { //igDataTypeApplyFromText
    return c.igDataTypeApplyFromText(buf, @intFromEnum(data_type), p_data, format);
}
pub inline fn dataTypeCompare(data_type: DataType, arg_1: [*c]const void, arg_2: [*c]const void) c_int { //igDataTypeCompare
    return c.igDataTypeCompare(@intFromEnum(data_type), arg_1, arg_2);
}
pub inline fn dataTypeClamp(data_type: DataType, p_data: ?*anyopaque, p_min: [*c]const void, p_max: [*c]const void) bool { //igDataTypeClamp
    return c.igDataTypeClamp(@intFromEnum(data_type), p_data, p_min, p_max);
}
pub inline fn inputTextEx(label: [*c]const u8, hint: [*c]const u8, buf: [*c]u8, buf_size: c_int, size_arg: Vec2, flags: InputTextFlags, callback: InputTextCallback, user_data: ?*anyopaque) bool { //igInputTextEx
    return c.igInputTextEx(label, hint, buf, buf_size, @bitCast(size_arg), @bitCast(flags), callback, user_data);
}
pub inline fn tempInputText(bb: Rect, id: ID, label: [*c]const u8, buf: [*c]u8, buf_size: c_int, flags: InputTextFlags) bool { //igTempInputText
    return c.igTempInputText(@bitCast(bb), id, label, buf, buf_size, @bitCast(flags));
}
pub inline fn tempInputScalar(bb: Rect, id: ID, label: [*c]const u8, data_type: DataType, p_data: ?*anyopaque, format: [*c]const u8, p_clamp_min: [*c]const void, p_clamp_max: [*c]const void) bool { //igTempInputScalar
    return c.igTempInputScalar(@bitCast(bb), id, label, @intFromEnum(data_type), p_data, format, p_clamp_min, p_clamp_max);
}
pub inline fn tempInputIsActive(id: ID) bool { //igTempInputIsActive
    return c.igTempInputIsActive(id);
}
pub inline fn getInputTextState(id: ID) [*c]InputTextState { //igGetInputTextState
    return c.igGetInputTextState(id);
}
pub inline fn colorTooltip(text: [*c]const u8, col: [*c]const f32, flags: ColorEditFlags) void { //igColorTooltip
    c.igColorTooltip(text, col, @bitCast(flags));
}
pub inline fn colorEditOptionsPopup(col: [*c]const f32, flags: ColorEditFlags) void { //igColorEditOptionsPopup
    c.igColorEditOptionsPopup(col, @bitCast(flags));
}
pub inline fn colorPickerOptionsPopup(ref_col: [*c]const f32, flags: ColorEditFlags) void { //igColorPickerOptionsPopup
    c.igColorPickerOptionsPopup(ref_col, @bitCast(flags));
}
pub inline fn shadeVertsLinearColorGradientKeepAlpha(draw_list: [*c]DrawList, vert_start_idx: c_int, vert_end_idx: c_int, gradient_p0: Vec2, gradient_p1: Vec2, col0: U32, col1: U32) void { //igShadeVertsLinearColorGradientKeepAlpha
    c.igShadeVertsLinearColorGradientKeepAlpha(draw_list, vert_start_idx, vert_end_idx, @bitCast(gradient_p0), @bitCast(gradient_p1), col0, col1);
}
pub inline fn shadeVertsLinearUV(draw_list: [*c]DrawList, vert_start_idx: c_int, vert_end_idx: c_int, a: Vec2, b: Vec2, uv_a: Vec2, uv_b: Vec2, clamp: bool) void { //igShadeVertsLinearUV
    c.igShadeVertsLinearUV(draw_list, vert_start_idx, vert_end_idx, @bitCast(a), @bitCast(b), @bitCast(uv_a), @bitCast(uv_b), clamp);
}
pub inline fn gcCompactTransientMiscBuffers() void { //igGcCompactTransientMiscBuffers
    c.igGcCompactTransientMiscBuffers();
}
pub inline fn gcCompactTransientWindowBuffers(window: [*c]Window) void { //igGcCompactTransientWindowBuffers
    c.igGcCompactTransientWindowBuffers(window);
}
pub inline fn gcAwakeTransientWindowBuffers(window: [*c]Window) void { //igGcAwakeTransientWindowBuffers
    c.igGcAwakeTransientWindowBuffers(window);
}
pub inline fn errorCheckEndFrameRecover(log_callback: ErrorLogCallback, user_data: ?*anyopaque) void { //igErrorCheckEndFrameRecover
    c.igErrorCheckEndFrameRecover(log_callback, user_data);
}
pub inline fn errorCheckEndWindowRecover(log_callback: ErrorLogCallback, user_data: ?*anyopaque) void { //igErrorCheckEndWindowRecover
    c.igErrorCheckEndWindowRecover(log_callback, user_data);
}
pub inline fn debugDrawItemRect(col: U32) void { //igDebugDrawItemRect
    c.igDebugDrawItemRect(col);
}
pub inline fn debugStartItemPicker() void { //igDebugStartItemPicker
    c.igDebugStartItemPicker();
}
pub inline fn showFontAtlas(atlas: [*c]FontAtlas) void { //igShowFontAtlas
    c.igShowFontAtlas(atlas);
}
pub inline fn debugHookIdInfo(id: ID, data_type: DataType, data_id: [*c]const void, data_id_end: [*c]const void) void { //igDebugHookIdInfo
    c.igDebugHookIdInfo(id, @intFromEnum(data_type), data_id, data_id_end);
}
pub inline fn debugNodeColumns(cols: [*c]OldColumns) void { //igDebugNodeColumns
    c.igDebugNodeColumns(cols);
}
pub inline fn debugNodeDockNode(node: [*c]DockNode, label: [*c]const u8) void { //igDebugNodeDockNode
    c.igDebugNodeDockNode(node, label);
}
pub inline fn debugNodeDrawList(window: [*c]Window, viewport: [*c]ViewportP, draw_list: [*c]const DrawList, label: [*c]const u8) void { //igDebugNodeDrawList
    c.igDebugNodeDrawList(window, viewport, draw_list, label);
}
pub inline fn debugNodeDrawCmdShowMeshAndBoundingBox(out_draw_list: [*c]DrawList, draw_list: [*c]const DrawList, draw_cmd: [*c]const DrawCmd, show_mesh: bool, show_aabb: bool) void { //igDebugNodeDrawCmdShowMeshAndBoundingBox
    c.igDebugNodeDrawCmdShowMeshAndBoundingBox(out_draw_list, draw_list, draw_cmd, show_mesh, show_aabb);
}
pub inline fn debugNodeFont(font: [*c]Font) void { //igDebugNodeFont
    c.igDebugNodeFont(font);
}
pub inline fn debugNodeFontGlyph(font: [*c]Font, glyph: [*c]const FontGlyph) void { //igDebugNodeFontGlyph
    c.igDebugNodeFontGlyph(font, glyph);
}
pub inline fn debugNodeStorage(storage: [*c]Storage, label: [*c]const u8) void { //igDebugNodeStorage
    c.igDebugNodeStorage(storage, label);
}
pub inline fn debugNodeTabBar(tab_bar: [*c]TabBar, label: [*c]const u8) void { //igDebugNodeTabBar
    c.igDebugNodeTabBar(tab_bar, label);
}
pub inline fn debugNodeTable(table: [*c]Table) void { //igDebugNodeTable
    c.igDebugNodeTable(table);
}
pub inline fn debugNodeTableSettings(settings: [*c]TableSettings) void { //igDebugNodeTableSettings
    c.igDebugNodeTableSettings(settings);
}
pub inline fn debugNodeInputTextState(state: [*c]InputTextState) void { //igDebugNodeInputTextState
    c.igDebugNodeInputTextState(state);
}
pub inline fn debugNodeWindow(window: [*c]Window, label: [*c]const u8) void { //igDebugNodeWindow
    c.igDebugNodeWindow(window, label);
}
pub inline fn debugNodeWindowSettings(settings: [*c]WindowSettings) void { //igDebugNodeWindowSettings
    c.igDebugNodeWindowSettings(settings);
}
pub inline fn debugNodeWindowsList(windows: [*c]WindowPtrVector, label: [*c]const u8) void { //igDebugNodeWindowsList
    c.igDebugNodeWindowsList(windows, label);
}
pub inline fn debugNodeWindowsListByBeginStackParent(windows: [*c]Window, windows_size: c_int, parent_in_begin_stack: [*c]Window) void { //igDebugNodeWindowsListByBeginStackParent
    c.igDebugNodeWindowsListByBeginStackParent(windows, windows_size, parent_in_begin_stack);
}
pub inline fn debugNodeViewport(viewport: [*c]ViewportP) void { //igDebugNodeViewport
    c.igDebugNodeViewport(viewport);
}
pub inline fn debugRenderViewportThumbnail(draw_list: [*c]DrawList, viewport: [*c]ViewportP, bb: Rect) void { //igDebugRenderViewportThumbnail
    c.igDebugRenderViewportThumbnail(draw_list, viewport, @bitCast(bb));
}
pub inline fn imFontAtlasGetBuilderForStbTruetype() [*c]const FontBuilderIO { //igImFontAtlasGetBuilderForStbTruetype
    return c.igImFontAtlasGetBuilderForStbTruetype();
}
pub inline fn imFontAtlasBuildInit(atlas: [*c]FontAtlas) void { //igImFontAtlasBuildInit
    c.igImFontAtlasBuildInit(atlas);
}
pub inline fn imFontAtlasBuildSetupFont(atlas: [*c]FontAtlas, font: [*c]Font, font_config: [*c]FontConfig, ascent: f32, descent: f32) void { //igImFontAtlasBuildSetupFont
    c.igImFontAtlasBuildSetupFont(atlas, font, font_config, ascent, descent);
}
pub inline fn imFontAtlasBuildPackCustomRects(atlas: [*c]FontAtlas, stbrp_context_opaque: ?*anyopaque) void { //igImFontAtlasBuildPackCustomRects
    c.igImFontAtlasBuildPackCustomRects(atlas, stbrp_context_opaque);
}
pub inline fn imFontAtlasBuildFinish(atlas: [*c]FontAtlas) void { //igImFontAtlasBuildFinish
    c.igImFontAtlasBuildFinish(atlas);
}
pub inline fn imFontAtlasBuildRender8bppRectFromString(atlas: [*c]FontAtlas, x: c_int, y: c_int, w: c_int, h: c_int, in_str: [*c]const u8, in_marker_char: u8, in_marker_pixel_value: u8) void { //igImFontAtlasBuildRender8bppRectFromString
    c.igImFontAtlasBuildRender8bppRectFromString(atlas, x, y, w, h, in_str, in_marker_char, in_marker_pixel_value);
}
pub inline fn imFontAtlasBuildRender32bppRectFromString(atlas: [*c]FontAtlas, x: c_int, y: c_int, w: c_int, h: c_int, in_str: [*c]const u8, in_marker_char: u8, in_marker_pixel_value: c_uint) void { //igImFontAtlasBuildRender32bppRectFromString
    c.igImFontAtlasBuildRender32bppRectFromString(atlas, x, y, w, h, in_str, in_marker_char, in_marker_pixel_value);
}

// TODO structs with bitfields...
// for the time being this shall be just an opaque pointer
pub const DockRequest = opaque {};
pub const Table = opaque {};
pub const StackLevelInfo = opaque {};
pub const TableColumnSortSpecs = opaque {};
pub const DockNode = opaque {};
pub const TableColumnSettings = opaque {};
pub const TableColumn = opaque {};
pub const Window = opaque {};
pub const FontGlyph = opaque {};
pub const DockNodeSettings = opaque {};
pub const StoragePair = opaque {};

pub const ErrorLogCallback = *const fn (?*anyopaque, [*c]const u8) callconv(.C) void;
pub const DrawCallback = *const fn ([*c]const DrawList, [*c]const DrawCmd) callconv(.C) void;

// TODO file handles? typedef FILE* ImFileHandle;
pub const FileHandle = std.fs.File;

var textFmtBuffer: [1024]u8 = undefined;

pub inline fn textSlice(buf: []const u8) void {
    textUnformatted(@ptrCast(buf.ptr), buf.ptr + buf.len);
}

pub inline fn textFmt(comptime fmt: []const u8, args: anytype) !void {
    const buffer = try std.fmt.bufPrint(&textFmtBuffer, fmt, args);
    textUnformatted(@ptrCast(buffer.ptr), buffer.ptr + buffer.len);
}

// pub inline fn textV(fmt: [*c]const u8, args: list) void { //igTextV
//     c.igTextV(fmt, args);
// }
// pub inline fn textColoredV(col: Vec4, fmt: [*c]const u8, args: list) void { //igTextColoredV
//     c.igTextColoredV(@bitCast(col), fmt, args);
// }
// pub inline fn textDisabledV(fmt: [*c]const u8, args: list) void { //igTextDisabledV
//     c.igTextDisabledV(fmt, args);
// }
// pub inline fn textWrappedV(fmt: [*c]const u8, args: list) void { //igTextWrappedV
//     c.igTextWrappedV(fmt, args);
// }
// pub inline fn labelTextV(label: [*c]const u8, fmt: [*c]const u8, args: list) void { //igLabelTextV
//     c.igLabelTextV(label, fmt, args);
// }
// pub inline fn bulletTextV(fmt: [*c]const u8, args: list) void { //igBulletTextV
//     c.igBulletTextV(fmt, args);
// }
//
// pub inline fn treeNodeV_Str(str_id: [*c]const u8, fmt: [*c]const u8, args: list) bool { //igTreeNodeV_Str
//     return c.igTreeNodeV_Str(str_id, fmt, args);
// }
// pub inline fn treeNodeV_Ptr(ptr_id: [*c]const void, fmt: [*c]const u8, args: list) bool { //igTreeNodeV_Ptr
//     return c.igTreeNodeV_Ptr(ptr_id, fmt, args);
// }
//
// pub inline fn treeNodeExV_Str(str_id: [*c]const u8, flags: TreeNodeFlags, fmt: [*c]const u8, args: list) bool { //igTreeNodeExV_Str
//     return c.igTreeNodeExV_Str(str_id, @bitCast(flags), fmt, args);
// }
// pub inline fn treeNodeExV_Ptr(ptr_id: [*c]const void, flags: TreeNodeFlags, fmt: [*c]const u8, args: list) bool { //igTreeNodeExV_Ptr
//     return c.igTreeNodeExV_Ptr(ptr_id, @bitCast(flags), fmt, args);
// }
//
// pub inline fn setTooltipV(fmt: [*c]const u8, args: list) void { //igSetTooltipV
//     c.igSetTooltipV(fmt, args);
// }
//
// pub inline fn logTextV(fmt: [*c]const u8, args: list) void { //igLogTextV
//     c.igLogTextV(fmt, args);
// }
//
// pub inline fn imFormatStringV(buf: [*c]u8, buf_size: usize, fmt: [*c]const u8, args: list) c_int { //igImFormatStringV
//     return c.igImFormatStringV(buf, buf_size, fmt, args);
// }
// pub inline fn imFormatStringToTempBufferV(out_buf: [*c]const u8, out_buf_end: [*c]const u8, fmt: [*c]const u8, args: list) void { //igImFormatStringToTempBufferV
//     c.igImFormatStringToTempBufferV(out_buf, out_buf_end, fmt, args);
// }
//
//
// pub inline fn debugLogV(fmt: [*c]const u8, args: list) void { //igDebugLogV
//     c.igDebugLogV(fmt, args);
// }

pub const c = @cImport({
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", {});
    @cDefine("CIMGUI_USE_GLFW", "1"); // if this needs a reference to glfw3, cleanest thing to do is to copy the glfw3 header here. I suspect it won't need it though.
    @cInclude("cimgui.h");
    @cInclude("cimgui_compat.h");
    @cInclude("cimgui_impl.h");
    @cInclude("cimplot.h");
});

test "Imgui Header test" {
    const flags = WindowFlags{};
    const flags2 = WindowFlags.no_nav;
    std.debug.print("flags = {any}\n{any}\n\n ", .{ flags, flags2 });
    std.debug.print("size of Style = {d}", .{@sizeOf(Style)});
    std.debug.print("size of Io = {d}\n", .{@sizeOf(Io)});
    std.debug.print("size of InputEvent = {d}\n", .{@sizeOf(InputEvent)});
}
