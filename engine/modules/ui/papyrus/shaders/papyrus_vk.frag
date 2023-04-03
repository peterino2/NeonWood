//glsl version 4.5
#version 460

layout (location = 0) in vec3 in_color;
layout (location = 1) in vec2 texCoord;

layout (location = 0) out vec4 outFragColor;

layout(set = 1, binding = 0) uniform sampler2D tex;

struct UiElementData {
    vec2 position;
    vec2 size;
    vec2 anchorPoint;
    vec2 scale;
    float alpha;
};

layout(std140, set = 0, binding = 0) readonly buffer UiElementDataBuffer
{
    UiElementData objects[];
} objectBuffer;

void main()
{
    vec4 color = texture(tex, texCoord).xyzw;

    if(color.w < 0.01)
    {
        discard;
    }
    else 
    {
        vec3 mixed = mix(normalize(vec3(0.5, 0.3, 0.2)) * 3, vec3(0.2, 0.2, 0.4) * 3, texCoord.y);
        outFragColor = vec4(color.xyz * mixed, in_color.x * color.w);
    }
}


