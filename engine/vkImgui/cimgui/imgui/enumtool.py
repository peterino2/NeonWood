import re
inp3 = """
"""

enumLists = []
for s in inp3.split("typedef enum {"):
    raw = s.strip('\n ')
    linesSplit = []
    for l in raw.split('\n'):
        if '}' in l:
            continue
        linesSplit.append(l.strip(' \n'))

    x = '\n'.join(linesSplit)
    enumLists.append(x)

inp4 = """
    ImGuiPlotType_Lines,
    ImGuiPlotType_Histogram
"""

# these are normal-ass enums
inp5 = """
    ImGuiContextHookType_NewFramePre,
    ImGuiContextHookType_NewFramePost,
    ImGuiContextHookType_EndFramePre,
    ImGuiContextHookType_EndFramePost,
    ImGuiContextHookType_RenderPre,
    ImGuiContextHookType_RenderPost,
    ImGuiContextHookType_Shutdown,
    ImGuiContextHookType_PendingRemoval_
"""

x = inp5.split('line')
preamble = ''
for l in x:
    line = l.strip(' ')
    if len(line) > 0:
        s = line.split('_')
        preamble = s[0] + '_'
        preamble = preamble.lstrip('\n ')
        break
print('   ', inp5.replace(preamble, '').replace('_', '').strip('\n ') + ',')
print('    _,')


def convertName(name):
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

def convertFlagName(x):
    if "COUNT" in x:
        return "count"
    flagName = x.split('_')[1].split('=')[0]
    flagNameZig = convertName(flagName)
    return flagNameZig

def convertSingle(line):
    s = line.split(' ')
    flagNameZig = convertFlagName(s[0])
    if flagNameZig != 'none':
        return flagNameZig + f': bool = false, // {line}'


def convertCompositeFlag(convert):
    left, right = convert.split('=')
    right = right.strip(' ')
    left = left.strip(' ')
    constName = convertFlagName(left)
    rhsFlagsRaw = right.split('|')
    rhsFlags = []

    for r in rhsFlagsRaw:
        rhsFlags.append(convertFlagName(r.strip(' ,')))

    ostr = f"pub const {constName} = ." + '{ '
    for r in rhsFlags:
        ostr += f'.{r} = true, '
    ostr = ostr[0:-2]
    ostr += '};'
    return ostr

def convertFlags(inputString):
    #print("input: ", inputString)
    if len(inputString.strip(' ')) <= 0:
        return
    singles = []
    composites = []
    firstLine = None
    for l in inputString.split('\n'):
        line = l.strip(' ')
        if len(line) <= 0:
            continue
        firstLine = line
        if '=' in line:
            left, right = line.split('=')
            if "_" in right:
                composites.append(convertCompositeFlag(line))
            else:
                singles.append(convertSingle(line))
        else:
            singles.append(convertFlagName(line.strip(' ,')) + ': bool = false, // ' + line)# this is a single flag

    structName = firstLine.split('_')[0][5:]
    print(f'pub const {structName} = packed struct(c_int)' + '{')

    count = 0
    for s in singles:
        if s is not None:
            count += 1
            print('    ' + s)

    if count != 32:
        print(f"    reserved: u{32 - count} = 0, // reserved, don't use")

    if len(composites):
        print('')

    for x in composites:
        print('    ' + x)

    print('};')

for e in enumLists:
    convertFlags(e)

def convertEnum(enumStr):
    name = None
    for l in enumStr.split('\n'):
        line = l.strip(' ,')
        if 'typedef enum {' in line:
            continue
        if len(line) == 0:
            continue
        name = convertFlagName(line)
        print(name)
