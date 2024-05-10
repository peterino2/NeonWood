#version 460

layout (location = 0) in vec3 vPosition;
layout (location = 1) in vec3 vNormal;
layout (location = 2) in vec4 vColor;
layout (location = 3) in vec2 vTexCoord;

layout (location = 0) out vec3 outColor;
layout (location = 1) out vec2 texCoord;
layout (location = 2) out vec3 worldPosition;

layout (set = 0, binding = 0) uniform CameraBuffer{
    mat4 view;
    mat4 proj;
    mat4 viewproj;
    vec4 position;
} cameraData;

// size: 16 x 4 + 3 x 4 = 76 => 128 bytes per object per alignment
struct ObjectData {
    mat4 model;
    vec4 color;
};

layout(std140, set = 1, binding = 0) readonly buffer ObjectBuffer{ 
    ObjectData objects[];
} objectBuffer;

void main()
{
    ObjectData object = objectBuffer.objects[gl_BaseInstance];
	mat4 modelMatrix = object.model;
    mat4 final = (cameraData.viewproj * modelMatrix);
    vec4 position = final * vec4(vPosition, 1.0f);
	gl_Position = position;
	outColor = object.color.xyz;
    texCoord = vTexCoord;
    vec4 modelPos = modelMatrix * vec4(vPosition, 1.0f);
    worldPosition = modelPos.xyz;
}
