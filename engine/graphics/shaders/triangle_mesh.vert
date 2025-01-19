#version 460


#include "vertexInput.glsl"

layout (location = 0) out vec3 outColor;
layout (location = 1) out vec2 texCoord;
layout (location = 2) out vec3 worldPosition;
layout (location = 3) flat out uint textureId;

#include "globalSet.glsl"
#include "sharedSsbo.glsl"
#include "skeletalBuffers.glsl"

void main()
{
    vec3 vertexPos = vec3(0.0);
    int animation = objectBuffer.objects[gl_BaseInstance].animation;

    if(animation == -1)
    {
        vertexPos = vPosition;
    }
    else 
    {
        uint animation = objectBuffer.objects[gl_BaseInstance].animation;

        for(int i = 0; i < 4; i += 1)
        {
            uint boneIndex = bones[i];
            float weight = float(weights[i]) / 255;

            // this will depend on ozz's finals format
            mat4 boneTransform = animationBuffer.finals[animation + boneIndex];
            vertexPos += weight * (  boneTransform * vec4(vPosition, 1.0) ).xyz;
        }
    }

	mat4 modelMatrix = objectBuffer.objects[gl_BaseInstance].model;
    mat4 final = (cameraData.viewproj * modelMatrix);
    vec4 position = final * vec4(vertexPos, 1.0f);

	gl_Position = position;
    textureId = objectBuffer.objects[gl_BaseInstance].textureId;
	outColor = vec3(vColor.x, vColor.y, vColor.z);
    texCoord = vTexCoord;
    worldPosition = (modelMatrix * vec4(0,0,0,1)).xyz;
}
