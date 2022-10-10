#version 460

layout (location = 0) in vec3 vPosition;
layout (location = 1) in vec3 vNormal;
layout (location = 2) in vec4 vColor;
layout (location = 3) in vec2 vTexCoord;

layout (location = 0) out vec3 outColor;
layout (location = 1) out vec2 texCoord;

struct ImageRenderData {
    vec2 imagePosition;
};

layout(std140, set = 0, binding = 0) readonly buffer ImageBufferObjects {
    ImageRenderData objects[];
} objectBuffer;

void main()
{
	vec2 imagePosition = objectBuffer.objects[gl_BaseInstance].imagePosition;
    vec4 position = vec4(vPosition, 1.0f);
	gl_Position = position + vec4(imagePosition, 0.0f, 1.0f);
	outColor = vec3(vColor.x, vColor.y, vColor.z);
    texCoord = vTexCoord;
}
