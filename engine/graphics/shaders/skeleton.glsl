#version 450
// this is all pseudocode, not used.
#extension GL_EXT_shader_explicit_arithmetic_types_int8 : enable

layout (location = 0) in vec3 vPosition;
layout (location = 1) in vec3 vNormal;
layout (location = 2) in vec4 vColor;
layout (location = 3) in vec2 vTexCoord;
layout (location = 4) in int vSkeletal; // index into vertex bone ssbo, index of -1 means not animated.

struct ObjectData {
    mat4 model;
    uint textureId;
    uint animation; // offset into animation buffer where to take bones.
    uint pad0;
    uint pad1;
};

layout(std140, set = 1, binding = 0) readonly buffer ObjectBuffer{ 
    ObjectData objects[];
} objectBuffer;


struct VertexBoneData {
    u8vec4 bones;
    u8vec4 weights;
};

layout(std140, set = 2, binding = 0) readonly buffer VertexBoneData{
    VertexBoneData bones[],
} vbd; // one per vertex

layout(std140, set = 2, binding = 1) readonly buffer Binds{
    mat4 bones[],
} inverseRestPose;

layout(std140, set = 2, binding = 2) readonly buffer BoneBuffer{
    mat4 finals[],
} animationBuffer;

void vertex () 
{
    vec3 position = vec3(0.0);

    if(vSkeletal == -1)
    {
        position = vPosition;
    }
    else 
    {
        uint animation = objectBuffer.objects[gl_BaseInstance].animation;

        for(int i = 0; i < 4; i += 1)
        {
            uint boneIndex = vbd.bones[gl_BaseInstance].bone[i];
            float weight = vbd.bones[gl_BaseInstance].weights[i] / 255;

            // this will depend on ozz's finals format
            mat4 boneTransform = animationBuffer.finals[vSkeletal + animation] * inverseRestPose.bones[boneIndex];

            position += weight * (boneTransform * vec4(vPosition, 1.0));
        }
    }

    
    // final output
	mat4 modelMatrix = objectBuffer.objects[gl_BaseInstance].model;
    mat4 final = (cameraData.viewproj * modelMatrix);
    vec4 position = final * vec4(position, 1.0f);
	gl_Position = position;
}
