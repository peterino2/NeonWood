inp = """
struct ImDrawListSplitter
{
    int _Current;
    int _Count;
    ImVector_ImDrawChannel _Channels;
};
"""

'''
struct ImGuiInputEvent
{
    ImGuiInputEventType Type;
    ImGuiInputSource Source;
    union
    {
        ImGuiInputEventMousePos MousePos;
        ImGuiInputEventMouseWheel MouseWheel;
        ImGuiInputEventMouseButton MouseButton;
        ImGuiInputEventMouseViewport MouseViewport;
        ImGuiInputEventKey Key;
        ImGuiInputEventText Text;
        ImGuiInputEventAppFocused AppFocused;
    };
    bool AddedByTestEngine;
};
'''

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

    isVector = False
    if entry[:8] == 'ImVector':
        isVector = True

    typeName = entry
    const = False
    pointer = False
    if '*' in typeName:
        pointer = True;
        typeName = typeName.strip('*')

    if typeName[:5] == 'const':
        const = True
        typeName = typeName[5:]
        typeName = typeName.strip(' ')

    if '_' in typeName:
        x = typeName.split('_')
        typeName = x[-1]
    rv = convertInner(typeName)

    if const:
        rv = 'const ' + rv

    if pointer:
        rv = '[*c]' + rv

    if isVector:
        rv += 'Vector'

    return rv

def convertInner(typeName):
    if 'float' == typeName:
        return 'f32'
    if 'char' == typeName:
        return 'u8'
    if 'int' == typeName:
        return 'c_int'
    if 'short' == typeName:
        return 'c_short'
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

def splitTypeAndLabel(line):
    spaceIndex = line.rindex(' ')
    left = line[:spaceIndex]
    right = line[spaceIndex + 1:]
    return left, right

def generateStruct(inp):
    inp = inp.strip('\n ')
    defs = []
    name = ''
    nameLine = ''

    for l in inp.split('\n'):
        line = l.strip(' {')
        if len(line) < 1:
            continue
        if 'struct' in line:
            name = line.split(' ')[1]
            nameLine = line
            continue
        if '{' in line:
            continue
        if '}' in line:
            continue

        if '(*' not in line:
            typeName, varName = splitTypeAndLabel(line)
            varName = varName.strip(';')
            arraySpec = None
            if '[' in varName:
                varName, rhs = varName.split('[')
                arraySpec = rhs.strip(']')
            varName =  convertVarName(varName)
            if arraySpec is not None:
                arraySpec = arraySpec.replace('ImGui', '')
                arraySpec = arraySpec.replace('_', '.')
                # varName += '[' + arraySpec + ']'
            typeName = convertTypeName(typeName)
            defs.append([typeName, varName, arraySpec])
        else:
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
            defs.append([None, None, None, ostr])

    print(f'pub const {convertTypeName(name)} = extern struct ' + '{ // ' + nameLine)
    for d in defs:
        if d[0] is not None:
            typedef = d[0]
            if d[2] is not None:
                typedef = f"[{d[2]}]" + d[0]
            print(f"    {d[1]}: {typedef},")
        elif d[3] is not None:
            print('   ', d[3])

    print('};')

generateStruct(inp)


structs = """
ImDrawCmd {int Size;int Capacity;ImDrawCmd* Data;} ImVector_ImDrawCmd;
ImDrawIdx {int Size;int Capacity;ImDrawIdx* Data;} ImVector_ImDrawIdx;
"""

"""
unsigned_char {int Size;int Capacity;unsigned char* Data;} ImVector_unsigned_char;
typedef struct ImPool_ImGuiTable {ImVector_ImGuiTable Buf;ImGuiStorage Map;ImPoolIdx FreeIdx;ImPoolIdx AliveCount;} ImPool_ImGuiTable;
typedef struct ImPool_ImGuiTabBar {ImVector_ImGuiTabBar Buf;ImGuiStorage Map;ImPoolIdx FreeIdx;ImPoolIdx AliveCount;} ImPool_ImGuiTabBar;
typedef struct ImChunkStream_ImGuiWindowSettings {ImVector_char Buf;} ImChunkStream_ImGuiWindowSettings;
typedef struct ImChunkStream_ImGuiTableSettings {ImVector_char Buf;} ImChunkStream_ImGuiTableSettings;
"""

for i in structs.split('\n'):
    sname = i.split(' ')[0]
    tname = convertTypeName(sname)
    # print(sname, tname)
    o = f"""
pub const {tname}Vector = extern struct {{ // struct ImVector_{sname}
    size: c_int,
    capacity: c_int,
    data: [*c]{tname},
}};
    """
    print(o)

