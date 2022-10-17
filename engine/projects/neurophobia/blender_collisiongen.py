import bpy


# 1. select the object you want
# 2. open up scripting and add this script in
# 3. run the script

obdata = bpy.context.object.data

print('Vertices:')
for v in obdata.vertices:
    print('{}. {} {} {}'.format(v.index, v.co.x, v.co.y, v.co.z))

print('Edges:')
for e in obdata.edges:
    print('{}. {} {}'.format(e.index, e.vertices[0], e.vertices[1]))

print('Faces:')
for f in obdata.polygons:
    print('{}. '.format(f.index), end='')
    for v in f.vertices:
        print('{} '.format(v), end='')
    print() # for newline

def toVectorf(v):
    vertex = obdata.vertices[v].co;
    ostr = ".{"
    ostr += f".x = {vertex.x:.2f},"
    ostr += f".y = {vertex.z:.2f},"
    ostr += f".z = {-vertex.y:.2f}"
    ostr += "}"
    return ostr

print("// ====== CODEGEN  =====")

for e in obdata.edges:
    print('_ = try self.collision.addLine({}, {});'.format(toVectorf(e.vertices[0]), toVectorf(e.vertices[1])))