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


void main()
{
    vec3 color = in_color.rgb;
    float cameraDist = length(cameraData.position.xyz - worldPosition);
    float opacity = (1.0) - (cameraDist / 300);
    outFragColor = vec4(color, opacity * 1.0);
}
