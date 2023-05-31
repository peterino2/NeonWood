//glsl version 4.5
#version 450

layout (location = 0) in vec3 in_color;
layout (location = 1) in vec2 texCoord;

layout (location = 0) out vec4 outFragColor;

layout(set = 0, binding = 1) uniform  SceneData{
    vec4 fogColor; // w is for exponent
	vec4 fogDistances; //x for min, y for max, zw unused.
	vec4 ambientColor;
	vec4 sunlightDirection; //w for sun power
	vec4 sunlightColor;
} sceneData;


void main()
{
    outFragColor = vec4(vec3(in_color.rgb),  5.0*(1.0 - pow(gl_FragCoord.z,3.0)));
}
