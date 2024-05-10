// Copyright (c) peterino2@github.com

#version 460

layout (location = 0) in vec3 vPosition;
layout (location = 1) in vec3 vNormal;
layout (location = 2) in vec4 vColor;
layout (location = 3) in vec2 vTexCoord;

layout (location = 0) out vec4 outColor;
layout (location = 1) out vec2 texCoord;

struct ImageRenderData {
    vec2 imagePosition;
    vec2 imageSize;
    vec2 anchorPoint;
    vec2 scale;
    float alpha;
	vec4 baseColor;
    float zLevel;
};

struct ImageRenderData2{
    ImageRenderData ird;
    float someFloat;
    vec2 someVec2;
};

layout(std140, set = 0, binding = 0) readonly buffer ImageBufferObjects {
    ImageRenderData2 objects[];
} objectBuffer;

layout (push_constant) uniform constants 
{
	vec2 extent;
} PushConstants;

void main()
{
	vec2 imagePosition = objectBuffer.objects[gl_BaseInstance].ird.imagePosition;
    vec2 imageSize = objectBuffer.objects[gl_BaseInstance].ird.imageSize;
    vec2 anchor = objectBuffer.objects[gl_BaseInstance].ird.anchorPoint;
    vec2 scale = objectBuffer.objects[gl_BaseInstance].ird.scale;
    float alpha = objectBuffer.objects[gl_BaseInstance].ird.alpha;
	vec4 baseColor = objectBuffer.objects[gl_BaseInstance].ird.baseColor;

	vec2 finalSize = (imageSize / PushConstants.extent);

    vec2 finalPos = ((imagePosition / PushConstants.extent) * 2 - 1) - anchor * finalSize * scale;

	outColor = baseColor;
    gl_Position = vec4(
        finalPos.x + ( vPosition.x * finalSize.x ), 
        finalPos.y + (-vPosition.y * finalSize.y ),
        vPosition.z, 1.0
        );

    texCoord = vec2(1 - vTexCoord.x, vTexCoord.y);
}

