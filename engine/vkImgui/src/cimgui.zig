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

    pub fn setColor(self: *@This(), colorId: StyleColor, newColor: Vec4) void {
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

pub fn imVec2_ImVec2_Nil(x: [*c]const u8) [*c]Vec2 {
    return c.igImVec2_ImVec2_Nil(x);
}
pub fn createContext(shared_font_atlas: [*c]FontAtlas) [*c]Context {
    return c.igCreateContext(shared_font_atlas);
}
pub fn destroyContext(ctx: [*c]Context) void {
    c.igDestroyContext(ctx);
}
pub fn getCurrentContext() ?*Context {
    return @ptrCast(c.igGetCurrentContext());
}
pub fn setCurrentContext(ctx: [*c]Context) void {
    c.igSetCurrentContext(ctx);
}
pub fn getIo() ?*Io {
    return @ptrCast(c.igGetIO());
}
pub fn getStyle() ?*Style {
    return @ptrCast(c.igGetStyle());
}
pub fn newFrame() void {
    c.igNewFrame();
}
pub fn endFrame() void {
    c.igEndFrame();
}
pub fn render() void {
    c.igRender();
}
pub fn getDrawData() [*c]DrawData {
    return c.igGetDrawData();
}
pub fn showDemoWindow(p_open: [*c]bool) void {
    c.igShowDemoWindow(p_open);
}

// ====

pub fn setNextWindowPos(pos: Vec2, cond: Cond, pivot: Vec2) void {
    c.igSetNextWindowPos(@bitCast(pos), @bitCast(cond), @bitCast(pivot));
}

pub fn getMainViewport() ?*Viewport {
    return @ptrCast(c.igGetMainViewport());
}

pub fn setNextWindowViewport(viewport_id: ID) void {
    c.igSetNextWindowViewport(viewport_id);
}

pub fn setNextWindowSize(size: Vec2, cond: Cond) void {
    c.igSetNextWindowSize(@bitCast(size), @bitCast(cond));
}

pub fn pushStyleVar_Float(idx: StyleVar, val: f32) void {
    c.igPushStyleVar_Float(@intFromEnum(idx), val);
}
pub fn pushStyleVar_Vec2(idx: StyleVar, val: Vec2) void {
    c.igPushStyleVar_Vec2(@intFromEnum(idx), @bitCast(val));
}

pub fn popStyleVar(count: c_int) void {
    c.igPopStyleVar(count);
}

pub fn getID_Str(str_id: [*c]const u8) ID {
    return c.igGetID_Str(str_id);
}

pub fn dockSpace(id: ID, size: Vec2, flags: DockNodeFlags, window_class: [*c]const WindowClass) ID {
    return c.igDockSpace(id, @bitCast(size), @bitCast(flags), @ptrCast(window_class));
}

pub fn begin(name: [*c]const u8, p_open: [*c]bool, flags: WindowFlags) bool {
    return c.igBegin(name, p_open, @bitCast(flags));
}
pub fn end() void {
    c.igEnd();
}

// ===

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
