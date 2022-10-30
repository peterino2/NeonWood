//glsl version 4.5
#version 460

layout (location = 0) in vec3 in_color;
layout (location = 1) in vec2 texCoord;

layout (location = 0) out vec4 outFragColor;

layout(set = 1, binding = 0) uniform sampler2D tex;


void main()
{
    vec4 color = texture(tex, texCoord).xyzw;

    if(color.w < 0.01)
    {
        discard;
        // outFragColor = vec4(0.0, 0.0, 0.0, 0.8f);
    }
    else 
    {
        vec3 mixed = mix(normalize(vec3(0.5, 0.3, 0.2)) * 3, vec3(0.2, 0.2, 0.4) * 3, texCoord.y);
        outFragColor = vec4(color.xyz * mixed, in_color.x * color.w);
        //outFragColor = vec4(color.xyz, in_color.x);h
    }

    // outFragColor = vec4(1.0f, 0.0f, 0.0f, 1.0f);
}

