inp = """
struct ImGuiViewport
{
    ImGuiID ID;
    ImGuiViewportFlags Flags;
    ImVec2 Pos;
    ImVec2 Size;
    ImVec2 WorkPos;
    ImVec2 WorkSize;
    float DpiScale;
    ImGuiID ParentViewportId;
    ImDrawData* DrawData;
    void* RendererUserData;
    void* PlatformUserData;
    void* PlatformHandle;
    void* PlatformHandleRaw;
    bool PlatformRequestMove;
    bool PlatformRequestResize;
    bool PlatformRequestClose;
};
"""

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

def convertTypeName(typeName):
    if 'float' == typeName:
        return 'f32'
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
        line = l.strip(' ')
        if 'struct' in line:
            name = line.split(' ')[1]
            nameLine = line
            continue
        if '{' in line:
            continue
        if '}' in line:
            continue

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

    print(f'pub const {convertTypeName(name)} = extern struct ' + '{ // ' + nameLine)
    for d in defs:
        #print(d)
        typedef = d[0]
        if d[2] is not None:
            typedef = f"[{d[2]}]" + d[0]
        print(f"    {d[1]}: {typedef},")

    print('};')

generateStruct(inp)
