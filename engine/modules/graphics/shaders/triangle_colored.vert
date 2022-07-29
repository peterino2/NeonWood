//we will be using glsl version 4.5 syntax
#version 450

layout (location = 0) out vec3 out_color;

void main()
{
	//const array of positions for the triangle
	const vec3 positions[3] = vec3[3](
		vec3(0.8f,0.8f, 0.0f),
		vec3(-0.8f,0.8f, 0.0f),
		vec3(0.f,-0.8f, 0.0f)
	);

	const vec3 colors[3] = vec3[3](
		vec3(1.f,0.f, 0.0f),
		vec3(0.f,1.f, 0.0f),
		vec3(0.f,-0.f, 1.0f)
	);

	//output the position of each vertex
	gl_Position = vec4(positions[gl_VertexIndex], 1.0f);
	out_color = colors[gl_VertexIndex];
}
