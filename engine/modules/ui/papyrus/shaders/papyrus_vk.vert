//we will be using glsl version 4.5 syntax
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
    // float zLevel;
};

layout(std140, set = 0, binding = 0) readonly buffer ImageBufferObjects {
    ImageRenderData objects[];
} objectBuffer;

layout (push_constant) uniform constants 
{
	vec2 extent;
} PushConstants;

void main()
{
	vec2 imagePosition = objectBuffer.objects[gl_BaseInstance].imagePosition;
    vec2 imageSize = objectBuffer.objects[gl_BaseInstance].imageSize;
    vec2 anchor = objectBuffer.objects[gl_BaseInstance].anchorPoint;
    vec2 scale = objectBuffer.objects[gl_BaseInstance].scale;
    float alpha = objectBuffer.objects[gl_BaseInstance].alpha;
	vec4 baseColor = objectBuffer.objects[gl_BaseInstance].baseColor;

	vec2 finalSize = (imageSize / PushConstants.extent);
    //float zLevel = objectBuffer.objects[gl_BaseInstance].zLevel;

    vec2 finalPos = ((imagePosition / PushConstants.extent) * 2 - 1) - anchor * finalSize * scale;

	outColor = baseColor;
	//outColor = vec3(vColor.x, vColor.y, vColor.z);
    gl_Position = vec4(
        finalPos.x + ( vPosition.x * finalSize.x * scale.x), 
        finalPos.y + (-vPosition.y * finalSize.y * scale.y),
        vPosition.z, 1.0
        );
        //1.0); 

	//gl_Position = vec4( ((position.x) - 1.3) * 0.3 * 1.3, (-position.y + 0.05) * 1.3, position.z, 1.0); // + vec4(imagePosition, 0.0f, 1.0f);
    texCoord = vec2(1 - vTexCoord.x, vTexCoord.y);
}

