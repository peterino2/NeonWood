//glsl version 4.5
#version 460

layout (location = 0) in vec3 in_color;
layout (location = 1) in vec2 texCoord;

layout (location = 0) out vec4 outFragColor;

layout(set = 2, binding = 0) uniform sampler2D tex1;


void main()
{
    vec4 color = texture(tex1, texCoord).xyzw;

    if(color.w < 0.05)
    {
        discard;
    }

    outFragColor = vec4(color.xyz, in_color.x);
}

