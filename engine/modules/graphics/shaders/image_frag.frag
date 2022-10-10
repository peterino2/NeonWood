//glsl version 4.5
#version 460

layout (location = 0) in vec3 in_color;
layout (location = 1) in vec2 texCoord;

layout (location = 0) out vec4 outFragColor;

layout(set = 1, binding = 0) uniform sampler2D tex;


void main()
{
    vec4 color = texture(tex, texCoord).xyzw;

    if(color.w < 0.05)
    {
        discard;
    }

    outFragColor = vec4(color.xyz, 1.0f);
}

