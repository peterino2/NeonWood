//glsl version 4.5
#version 450

#extension GL_EXT_nonuniform_qualifier : require

layout (location = 0) in vec3 in_color;
layout (location = 1) in vec2 texCoord;
layout (location = 2) in vec3 worldPosition;
layout (location = 3) flat in uint textureId;

layout (location = 0) out vec4 outFragColor;


#include "globalSet.glsl"

#include "sharedSsbo.glsl"

void main()
{
	// outFragColor = vec4(in_color + 0.25 * sceneData.ambientColor.xyz,1.0f);
	// outFragColor = vec4(texCoord.x, texCoord.y, 0.5f, 1.0f);

    // vec4 color = texture(tex1, texCoord).xyzw;
    vec4 color = texture(gTex[textureId], texCoord).xyzw;

    if(color.w < 0.05f)
    {
        discard;
    }

    float cameraDist = length(cameraData.position.xyz - worldPosition);
    float opacity = clamp((1.f) - (clamp(cameraDist - 300, 0, 300) / 300.f), 0.f, 1.f);

    //float opacity = 1.0;
    if(opacity < 0.05f)
    {
        discard;
    }

    // outFragColor = vec4(mix(sceneData.fogColor.xyz, color.xyz, opacity), color.w);
    outFragColor = vec4(color.xyz, opacity);

    //vec3 mixed = mix(normalize(vec3(0.5, 0.3, 0.2)) * 3, vec3(0.2, 0.2, 1) * 3, texCoord.y * 2);
    //outFragColor = vec4(color.xyz, 1.0f);
    //outFragColor = vec4(0.0, 1.0, 0.0, 1.0f);
}
