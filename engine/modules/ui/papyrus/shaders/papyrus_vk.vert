#version 460

layout (location = 0) in vec3 vPosition;
layout (location = 1) in vec3 vNormal;
layout (location = 2) in vec4 vColor;
layout (location = 3) in vec2 vTexCoord;

layout (location = 0) out vec3 outColor;
layout (location = 1) out vec2 texCoord;

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
	vec2 position = objectBuffer.objects[gl_BaseInstance].position;
    vec2 size = objectBuffer.objects[gl_BaseInstance].size;
    vec2 anchor = objectBuffer.objects[gl_BaseInstance].anchorPoint;
    vec2 scale = objectBuffer.objects[gl_BaseInstance].scale;
    float alpha = objectBuffer.objects[gl_BaseInstance].alpha;

    vec2 finalPos = position + anchor;

	outColor = vec3(alpha, vColor.y, vColor.z);
    gl_Position = vec4(
        finalPos.x + ( vPosition.x * size.x * scale.x), 
        finalPos.y + (-vPosition.y * size.y * scale.y),
        vPosition.z, 1.0
        );

    texCoord = vec2(1 - vTexCoord.x, vTexCoord.y);
}

