#version 460

layout (location = 0) in vec3 vPosition;
layout (location = 1) in vec3 vNormal;
layout (location = 2) in vec4 vColor;
layout (location = 3) in vec2 vTexCoord;
layout (location = 4) in uint vSkeletal;

layout (location = 0) out vec3 outColor;
layout (location = 1) out vec2 texCoord;
layout (location = 2) out vec3 worldPosition;
layout (location = 3) flat out uint textureId;

layout (set = 0, binding = 0) uniform CameraBuffer{
    mat4 view;
    mat4 proj;
    mat4 viewproj;
    vec4 position;
} cameraData;

#include "sharedSsbo.glsl"
#include "skeletalBuffers.glsl"

void main()
{
    vec3 vertexPos = vec3(0.0);

    if(vSkeletal == -1)
    {
        vertexPos = vPosition;
    }
    else 
    {
        uint animation = objectBuffer.objects[gl_BaseInstance].animation;

        for(int i = 0; i < 4; i += 1)
        {
            uint boneIndex = vbd.buf[gl_BaseInstance].bones[i];
            float weight = vbd.buf[gl_BaseInstance].weights[i] / 255;

            // this will depend on ozz's finals format
            mat4 boneTransform = animationBuffer.finals[vSkeletal + animation] * inverseRestPose.bones[boneIndex];

            vertexPos += weight * (boneTransform * vec4(vPosition, 1.0)).xyz;
        }
    }

	mat4 modelMatrix = objectBuffer.objects[gl_BaseInstance].model;
    mat4 final = (cameraData.viewproj * modelMatrix);
    vec4 position = final * vec4(vertexPos, 1.0f);

	gl_Position = position;
    textureId = objectBuffer.objects[gl_BaseInstance].textureId;
	outColor = vec3(vColor.x, vColor.y, vColor.z);
    texCoord = vTexCoord;
    worldPosition = (modelMatrix * position).xyz;
}
