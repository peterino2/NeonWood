#version 450

#include "../vertexInput.glsl"
#include "../globalSet.glsl"


layout (location = 0) out vec3 outUVW;

void main() 
{
	outUVW = vPosition;
	// Convert cubemap coordinates into Vulkan coordinate space

	// Remove translation from view matrix
	mat4 viewMat = mat4(mat3(cameraData.view));
	gl_Position = cameraData.proj * viewMat * vec4(vPosition.xyz, 1.0);
    // gl_Position = cameraData.viewproj * vec4(vPosition, 1.0f);
}
