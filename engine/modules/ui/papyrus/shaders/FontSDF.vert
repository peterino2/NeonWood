#version 460

layout(location = 0) in vec3 texPosition;
layout(location = 1) in vec3 texNormal;
layout(location = 2) in vec4 texColor;
layout(location = 3) in vec2 texCoord;

layout (location = 0) out vec4 fragColor;
layout (location = 1) out vec2 texCoords;
layout (location = 2) out int instanceId;

struct FontInfo {
  uint isSimple;
  vec4 pad;
};

layout(std140, set = 0, binding = 0) readonly buffer FontInfoBuffer{ 
    FontInfo fontInfo[];
} fontBuffer;

layout (push_constant) uniform constants {
	vec2 extent;
} PushConstants;

void main()
{
    //gl_Position = vec4((texPosition.xy / PushConstants.extent) * 2 + vec2(-1.0f, -1.0f), texPosition.z, 1.0);
    gl_Position = vec4((texPosition.xy / vec2(1600, 900)) * 2 + vec2(-1.0f, -1.0f), texPosition.z, 1.0);
    texCoords = texCoord;
    fragColor = texColor;
    instanceId = gl_BaseInstance;
}
