#version 450

#include "../globalSet.glsl"


layout(set = 1, binding = 0) uniform samplerCube cubemap;

layout (location = 0) in vec3 inUVW;

layout (location = 0) out vec4 outFragColor;

void main() 
{
	outFragColor = texture(cubemap, inUVW);
}
