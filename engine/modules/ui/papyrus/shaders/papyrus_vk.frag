#version 450

//shader input
layout (location = 0) in vec4 fragColor;
layout (location = 1) in vec2 texCoord;

layout (location = 0) out vec4 outFragColor;

layout (push_constant) uniform constants 
{
	vec2 extent;
} PushConstants;

void main() 
{
    outFragColor = fragColor;
}
