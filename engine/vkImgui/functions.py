inp = """
CIMGUI_API ImVec2* igImVec2_ImVec2_Nil(const char* x);
CIMGUI_API void ImVec2_destroy(ImVec2* self);
CIMGUI_API ImVec2* ImVec2_ImVec2_Float(float _x,float _y);
CIMGUI_API ImVec4* ImVec4_ImVec4_Nil(void);
CIMGUI_API void ImVec4_destroy(ImVec4* self);
CIMGUI_API ImVec4* ImVec4_ImVec4_Float(float _x,float _y,float _z,float _w);
CIMGUI_API ImGuiContext* igCreateContext(ImFontAtlas* shared_font_atlas);
CIMGUI_API void igDestroyContext(ImGuiContext* ctx);
CIMGUI_API ImGuiContext* igGetCurrentContext(void);
CIMGUI_API void igSetCurrentContext(ImGuiContext* ctx);
CIMGUI_API ImGuiIO* igGetIO(void);
CIMGUI_API ImGuiStyle* igGetStyle(void);
CIMGUI_API void igNewFrame(void);
CIMGUI_API void igEndFrame(void);
CIMGUI_API void igRender(void);
CIMGUI_API ImDrawData* igGetDrawData(void);
CIMGUI_API void igShowDemoWindow(bool* p_open);
"""


singletonList = [
    'getStyle',
    'getIO',
    'getCurrentContext',
    'getMainViewport',
]

bitcastList = [
    "Vec2",
    "Vec4",
    "Cond",
    "WindowFlags",
    "DockNodeFlags",
    "ConstCharPtrVector",
    "CharVector",
    "WcharVector",
    "InputTextFlags",
    "TreeNodeFlags",
    "PopupFlags",
    "SelectableFlags",
    "ComboFlags",
    "TabBarFlags",
    "TabItemFlags",
    "TableColumnFlags",
    "TableFlags",
    "TableRowFlags",
    "TableBgTarget",
    "FocusedFlags",
    "HoveredFlags",
    "DragDropFlags",
    "DockNodeFlags",
    "ModFlags",
    "ConfigFlags",
    "BackendFlags",
    "ColorEditFlags",
    "SliderFlags",
    "Cond",
    "Style",
    "KeyData",
    "FontAtlas",
    "FontAtlasCustomRect",
    "FontConfig",
    "Io",
    "Viewport",
    "PlatformMonitorVector",
    "ViewportPtrVector",
    "PlatformIO",
    "PlatformMonitor",
    "ViewportFlags",
    "DrawFlags",
    "DrawListFlags",
    "FontAtlasFlags",
    "PlatformImeData",
    "StbUndoRecord",
    "StbUndoState",
    "StbTexteditState",
    "StbTexteditRow",
    "Vec1",
    "Rect",
    "BitVector",
    "Vec2ih",
    "DrawListSharedData",
    "DrawListPtrVector",
    "DrawList",
    "DrawDataBuilder",
    "ItemFlags",
    "ItemStatusFlags",
    "SeparatorFlags",
    "TextFlags",
    "TooltipFlags",
    "NextWindowDataFlags",
    "NextItemDataFlags",
    "ActivateFlags",
    "ScrollFlags",
    "NavHighlightFlags",
    "NavDirSourceFlags",
    "NavMoveFlags",
    "OldColumnFlags",
    "DebugLogFlags",
    "DataTypeTempStorage",
    "DataTypeInfo",
    "ColorMod",
    "StyleMod",
    "ComboPreviewData",
    "GroupData",
    "MenuColumns",
    "InputTextState",
    "PopupData",
    "NextWindowData",
    "NextItemData",
    "LastItemData",
    "StackSizes",
    "WindowStackData",
    "PtrOrIndex",
    "BitArrayForNamedKeys",
    "InputEventMousePos",
    "InputEventMouseWheel",
    "InputEventMouseButton",
    "InputEventMouseViewport",
    "InputEventKey",
    "InputEventText",
    "InputEventAppFocused",
    "InputEvent",
    "ListClipperRange",
    "ListClipperData",
    "ListClipperRangeVector",
    "NavItemData",
    "OldColumnData",
    "OldColumnDataVector",
    "WindowPtrVector",
    "WindowDockStyle",
    "DockRequestVector",
    "DockNodeSettingsVector",
    "DockContext",
    "ViewportP",
    "WindowSettings",
    "SettingsHandler",
    "MetricsConfig",
    "StackLevelInfoVector",
    "StackTool",
    "ContextHook",
    "InputEventVector",
    "WindowStackDataVector",
    "ColorModVector",
    "StyleModVector",
    "IDVector",
    "ItemFlagsVector",
    "GroupDataVector",
    "PopupDataVector",
    "ViewportPPtrVector",
    "ListClipperDataVector",
    "TableTempDataVector",
    "TableVector",
    "TabBarVector",
    "PtrOrIndexVector",
    "ShrinkWidthItemVector",
    "ShrinkWidthItem",
    "SettingsHandlerVector",
    "ContextHookVector",
    "u8Vector",
    "TablePool",
    "TabBarPool",
    "TabItemVector",
    "WindowSettingsChunkStream",
    "TableSettingsChunkStream",
    "TabItem",
    "TabBar",
    "TableTempData",
    "TableSettings",
    "FontBuilderIO",
    "TableCellData",
    "TableInstanceData",
    "TableColumnSpan",
    "TableColumnIdxSpan",
    "TableCellDataSpan",
    "TableInstanceDataVector",
    "TableColumnSortSpecsVector",
    "TextBuffer",
    "Context",
    "DrawChannelVector",
    "DrawChannel",
    "DrawCmdVector",
    "DrawIdxVector",
    "f32Vector",
    "FontPtrVector",
    "Payload",
    "ListClipper",
    "Storage",
    "StoragePairVector",
    "WindowClass",
    "InputTextCallbackData",
    "SizeCallbackData",
    "DrawData",
    "FontGlyphVector",
    "Font",
    "DrawCmd",
    "DrawVert",
    "DrawCmdHeader",
    "DrawListSplitter",
]


ptrcastList = [
    "WindowClass"
]

enumcastList = [
    "StyleVar",
    "DataType",
    "DataTypePrivate",
    "NavLayer",
    "DataAuthority",
    "DockNodeState",
    "WindowDockStyleCol",
    "ContextHookType",
    "Dir",
    "NavInput",
    "LayoutType",
    "LogType",
    "Axis",
    "PlotType",
    "PopupPositionPolicy",
    "MouseButton",
    "MouseCursor",
    "SortDirection",
    "Key",
    "StyleColor",
    "KeyPrivate",
    "InputSource",
    "NavReadMode",
    "InputEventType",
]

with open('functions.txt') as f:
    inp = f.read()
    pass

def splitTypeAndLabel(line):
    if ' ' in line:
        spaceIndex = line.rindex(' ')
        left = line[:spaceIndex]
        right = line[spaceIndex + 1:]
        return left, right
    else:
        return line, ''

def convertInner(typeName):
    if 'size_t' == typeName:
        return 'usize'
    if 'double' == typeName:
        return 'f64'
    if 'float' == typeName:
        return 'f32'
    if 'char' == typeName:
        return 'u8'
    if 'int' == typeName:
        return 'c_int'
    if 'short' == typeName:
        return 'c_short'
    if 'unsigned char' == typeName:
        return 'u8'
    if 'unsigned int' == typeName:
        return 'c_uint'
    if 'unsigned short' == typeName:
        return 'c_ushort'
    if 'unsigned long' == typeName:
        return 'c_ulong'
    if 'long' == typeName:
        return 'c_long'
    if 'longlong' == typeName:
        return 'c_longlong'
    if 'ImGui' == typeName[0:5]:
        return typeName[5:]
    if 'Im' == typeName[0:2]:
        return typeName[2:]
    return typeName

def parseFuncName(line):
    line = line.strip(' \n;')
    line = line.replace(')', '')
    s = line.split('(')
    funcName = s[1].strip('* ')
    return funcName

def parseFunction(line):
    line = line.strip(' \n;')
    line = line.replace(')', '')
    s = line.split('(')
    returnType = convertTypeName(s[0].strip(' '))
    funcName = convertVarName(s[1].strip('* '))
    funcName = funcName.replace('__', '_')
    argsRaw = s[2].split(',')
    args = []
    for a in argsRaw:
        if len(a) >= 1:
            args.append(a)

    argList = []
    for a in args:
        a = a.strip(' ')
        tname, vname = splitTypeAndLabel(a)
        argList.append([convertTypeName(tname), convertVarName(vname)])

    return (returnType, funcName, argList)

def convertFuncName(funcName):
    returnType, funcName, argList = parseFunction(line)
    ostr = funcName + ': *const fn ('
    first = True
    for arg in argList:
        if first:
            first = False
        else:
            ostr += ', '
        ostr += arg[0]
    ostr += ') ' + returnType + ','
    return ostr

def convertVarName(name):
    ostr = ""
    first = True
    for c in name:
        if c.isupper():
            if first:
                first = False
            else:
                ostr += '_'
        ostr += c.lower()
    return ostr

def convertTypeName(entry):
    if 'void*' == entry:
        return '?*anyopaque'
    if 'void' == entry:
        return 'void'
    if 'size_t' == entry:
        return 'c_usize'

    # print('---')
    # print(entry)
    entry = entry.strip(' ')
    isVector = False
    if entry[:8] == 'ImVector':
        isVector = True

    typeName = entry
    const = False
    pointer = False
    if '*' in typeName:
        pointer = True;
        typeName = typeName.strip('*')

    # print('\'' + typeName[:5] + '\'')
    if typeName[:5] == 'const':
        const = True
        typeName = typeName[5:]
        typeName = typeName.strip(' ')
    # print(typeName)


    if '_' in typeName:
        x = typeName.split('_')
        typeName = x[-1]
    rv = convertInner(typeName)

    if const and pointer:
        rv = 'const ' + rv

    if pointer:
        rv = '[*c]' + rv

    if isVector:
        rv += 'Vector'

    # print(rv)
    return rv


def startswith(line, segment):
    if line[0:len(segment)] == segment:
        return True
    return False

def parseRawArgsList(line):
    argList = []
    windowStart = 0
    braceCount = 0
    for i in range(0, len(line)):
        if line[i] == '(':
            braceCount += 1
            continue
        if line[i] == ')':
            braceCount -= 1
            continue
        if braceCount == 0 and (line[i] == ',' or i == len(line) - 1):
            argList.append((line[windowStart: i + 1]).strip(','))
            windowStart = i
    return argList

def lowerFirst(s):
    if len(s) > 1:
        s = s[0].lower() + s[1:]
    elif len(s) == 1:
        s = s[0].lower()
    return s

funcList = []
for l in inp.split('\n'):
    line = l.strip(' \n;')
    line = line.replace(' *', '* ')

    if len(line) == 0:
        continue

    function = {}
    if startswith(line, 'CIMGUI_API'):
        line = line[len('CIMGUI_API'):].strip(' ')
        s = line[line.index('('):]
        argListRaw = parseRawArgsList(s.strip(' ()'))
        argList = []
        for arg in argListRaw:
            if '(*' in arg:
                paramName =  parseFuncName(arg)
                typeName = arg
                argList.append((typeName, paramName))
            elif ' ' in arg:
                argList.append(( arg[:arg.rindex(' ')].strip(' '), arg[arg.rindex(' '):].strip(' ')))
            else:
                argList.append((arg.strip(' '), None))
        #print(line, '> ', argList)
        function['rawName'] = line[:line.index('(')]
        function['args'] = argList
        rawName = function['rawName']
        function['label'] = rawName[rawName.rindex(' '):].strip(' ')
        function['returnType'] = rawName[:rawName.rindex(' ')].strip(' ')
        # reject any functions that have a variadic
        shouldAdd = True
        for arg in function['args']:
            if '...' in arg[0]:
                shouldAdd = False
        if shouldAdd:
            funcList.append(function)

def wrapCast(arg):
    convertedType = convertTypeName(arg[0])
    return convertedType

for f in funcList:
    if startswith(f['label'], 'ig'):
        ostr = "pub fn "
        label = f['label'][2:]
        ostr += lowerFirst(label)
        ostr += "("
        first = True
        for arg in f['args']:
            if arg[0] == 'void':
                continue
            if first:
                first = False
            else:
                ostr += ', '
            ostr += convertVarName(arg[1]) + ': '
            ostr += convertTypeName(arg[0])

        ostr += ") "
        returnType = convertTypeName(f['returnType'])
        isSingleton = False
        for s in singletonList:
            if s == lowerFirst(label):
                returnType = returnType.replace(r'[*c]', r'?*')
                isSingleton = True
                break
        ostr += returnType
        ostr += " { //" + f['label'] +"\n    "
        if returnType != 'void':
            ostr += 'return '
        if isSingleton:
            ostr += '@ptrCast('
        ostr += "c." + f['label'] + '('
        first = True
        for arg in f['args']:
            if first:
                first = False
            else:
                ostr += ', '

            if arg[0] == 'void':
                continue
            argStr = convertVarName(arg[1])
            def applyCasts(a, t):
                for cast in bitcastList:
                    if t == cast:
                        return '@bitCast(' + a + ')'
                for cast in ptrcastList:
                    if cast in t:
                        return '@ptrCast(' + a + ')'
                for cast in enumcastList:
                    if t == cast:
                        return '@intFromEnum(' + a + ')'
                return a
            argStr = applyCasts(argStr, convertTypeName(arg[0]))
            ostr += argStr
            # print(wrapCast(arg))
        if isSingleton:
            ostr += ')'
        ostr += ');\n'
        # ostr += convertTypeName(arg[0])
        ostr += "}"
        print(ostr)
    else:
        continue
