// manually crafted translation for cimgui to zig

// ImVector_int == i32 in zig,
pub const Const_CharPtr = extern struct {
    size: c_int,
    capacity: c_int,
    data: [*c][*c]const u8,
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
pub const ViewportFlags = c_int; // ImGuiViewportFlags

// Im typedefs
pub const DrawFlags = c_int; // ImDrawFlags
pub const DrawListFlags = c_int; // ImDrawListFlags
pub const FontAtlasFlags = c_int; // ImFontAtlasFlags

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
    x: f32,
    y: f32,
};

pub const Vec4 = extern struct { // ImVec4
    x: f32,
    y: f32,
    z: f32,
    w: f32,
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

pub const Col = enum(c_int) {
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
    colors: [@as(usize, @intFromEnum(Col.COUNT))]Vec4,
};

pub const KeyData = extern struct { // struct ImGuiKeyData
    down: bool,
    down_duration: f32,
    down_duration_prev: f32,
    analog_value: f32,
};

pub const Vector_Wchar = extern struct { // typedef struct ImVector_ImWchar {
    size: c_int,
    capacity: c_int,
    data: [*c]Wchar,
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
    fonts: FontPtr,
    custom_rects: FontAtlasCustomRect,
    font_config: FontConfig,
    tex_uv_lines: [64]Vec4,
    font_builder_io: [*c]const FontBuilderIO,
    font_builder_flags: c_uint,
    pack_id_mouse_cursors: c_int,
    pack_id_lines: c_int,
};

pub const FontAtlasCustomRect = struct {};
pub const FontPtr = struct {};
pub const FontConfig = struct {};
pub const FontBuilderIO = struct {};

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
    input_queue_characters: Wchar, // ImVector_ImWchar InputQueueCharacters;
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

// placeholders
pub const PlatformImeData = struct {};
pub const InputTextCallbackData = struct {};
pub const SizeCallbackData = struct {};
pub const DrawData = struct {};

test "Imgui Header test" {
    const std = @import("std");
    const flags = WindowFlags{};
    const flags2 = WindowFlags.no_nav;
    std.debug.print("flags = {any}\n{any}\n\n ", .{ flags, flags2 });
    std.debug.print("size of Style = {d}", .{@sizeOf(Style)});
    std.debug.print("size of Io = {d}", .{@sizeOf(Io)});
}
