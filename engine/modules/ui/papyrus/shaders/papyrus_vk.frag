#version 450

//shader input
layout (location = 0) in vec4 fragColor;
layout (location = 1) in vec2 texCoord;

layout (location = 0) out vec4 outFragColor;

layout (set = 1, binding = 0) uniform sampler2D tex;

layout (push_constant) uniform constants 
{
	vec2 extent;
} PushConstants;

float median(float r, float g, float b) 
{
    return max(min(r, g), min(max(r, g), b));
}

void main() 
{
    //vec4 color = texture(tex, vec2(texCoord.x / 40 + 0.3, texCoord.y));
    outFragColor = vec4(pow(fragColor.xyz, vec3(2.2)), 1.0f);
}
