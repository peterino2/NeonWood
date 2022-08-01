//glsl version 4.5
#version 450

layout (location = 0) in vec3 in_color;

//output write
layout (location = 0) out vec4 outFragColor;

void main()
{
	//return red
	outFragColor = vec4(in_color,1.0f);
}

