struct ObjectData {
    mat4 model;
    uint textureId;
    int animation; // this is the index offset of the first matrix in the animation finals buffer.
    uint pad0;
    uint pad1;
};

layout(std140, set = 1, binding = 0) readonly buffer ObjectBuffer{ 
    ObjectData objects[];
} objectBuffer;

