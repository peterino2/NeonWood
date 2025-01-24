struct ObjectData {
    mat4 model;
    uint textureId;
    int animation; // this is the index offset of the first matrix in the animation finals buffer.
    uint flags0;
    // packed flags0 flags;
    // [0,0]: alwaysInFront
    // [1,1]: useAltCamera
    uint pad1;
};

layout(std140, set = 1, binding = 0) readonly buffer ObjectBuffer{ 
    ObjectData objects[];
} objectBuffer;


uint flag0_AlwaysInFront(uint flags)
{
    return flags & 0x1;
}

uint flag0_useAltFov(uint flags)
{
    return (flags >> 1) & 0x1;
}
