//glsl version 4.5
#version 450

layout (location = 0) in vec3 in_color;
layout (location = 1) in vec2 texCoord;
layout (location = 2) in vec3 worldPosition;

layout (location = 0) out vec4 outFragColor;

layout (set = 0, binding = 0) uniform CameraBuffer{
    mat4 view;
    mat4 proj;
    mat4 viewproj;
    vec4 position;
} cameraData;

layout(set = 0, binding = 1) uniform  SceneData{
    vec4 fogColor; // w is for exponent
	vec4 fogDistances; //x for min, y for max, zw unused.
	vec4 ambientColor;
	vec4 sunlightDirection; //w for sun power
	vec4 sunlightColor;
} sceneData;

layout(set = 2, binding = 0) uniform sampler2D tex1;


void main()
{
	//outFragColor = vec4(in_color + 0.25 * sceneData.ambientColor.xyz,1.0f);
	// outFragColor = vec4(texCoord.x, texCoord.y, 0.5f, 1.0f);

    vec4 color = texture(tex1, texCoord).xyzw;

    if(color.w < 0.05f)
    {
        discard;
    }

    float cameraDist = length(cameraData.position.xyz - worldPosition);
    float opacity = clamp((1.f) - (cameraDist / 100.f), 0.f, 1.f);

    if(opacity > 0.8)
    {
        opacity = 1.f;
    }

    //vec3 mixed = mix(normalize(vec3(0.5, 0.3, 0.2)) * 3, vec3(0.2, 0.2, 1) * 3, texCoord.y * 2);
    outFragColor = vec4(mix(sceneData.fogColor.xyz, color.xyz, opacity), color.w);
    //outFragColor = vec4(color.xyz, 1.0f);
    //outFragColor = vec4(0.0, 1.0, 0.0, 1.0f);
}
