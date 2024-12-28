#extension GL_EXT_shader_explicit_arithmetic_types_int8 : enable

struct VertexBoneData {
    u8vec4 bones;
    u8vec4 weights;
};

layout(std140, set = 2, binding = 0) readonly buffer VertexBoneDataBuffer{ 
    VertexBoneData buf[];
} vbd;

layout(std140, set = 2, binding = 1) readonly buffer Binds{
    mat4 bones[];
} inverseRestPose;

layout(std140, set = 2, binding = 2) readonly buffer BoneBuffer{
    mat4 finals[];
} animationBuffer;
