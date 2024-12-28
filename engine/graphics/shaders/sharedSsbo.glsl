struct ObjectData {
    mat4 model;
    uint textureId;
    uint animation;
    uint pad0;
    uint pad1;
};

layout(std140, set = 1, binding = 0) readonly buffer ObjectBuffer{ 
    ObjectData objects[];
} objectBuffer;

