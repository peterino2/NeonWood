struct ObjectData {
    mat4 model;
    uint textureId;
    uint pad0;
    uint pad1;
    uint pad2;
};

layout(std140, set = 1, binding = 0) readonly buffer ObjectBuffer{ 
    ObjectData objects[];
} objectBuffer;
