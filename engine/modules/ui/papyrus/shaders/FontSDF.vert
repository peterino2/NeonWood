#version 460

layout(location = 0) in vec3 texPosition;
layout(location = 1) in vec3 texNormal;
layout(location = 2) in vec4 texColor;
layout(location = 3) in vec2 texCoord;

layout (location = 0) out vec4 fragColor;
layout (location = 1) out vec2 texCoords;

struct FontInfo {
    vec2 FontLocation;
    vec2 FontSize;
    float alpha;
};

layout(std140, set = 0, binding = 0) readonly buffer FontInfoBuffer{ 
    FontInfo fontInfo[];
} fontBuffer;

void main()
{
    gl_Position = vec4(texPosition, 1.0);
    texCoords = texCoord;
    fragColor = texColor;
}
