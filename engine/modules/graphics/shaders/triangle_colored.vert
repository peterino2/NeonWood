#version 450

layout (location = 0) in vec3 vPosition;

void main()
{
	gl_Position = vec4(vPosition, 1.0f);
}

