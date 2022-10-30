//glsl version 4.5
#version 450

layout (location = 0) in vec3 in_color;
layout (location = 1) in vec2 texCoord;

layout (location = 0) out vec4 outFragColor;

layout(set = 0, binding = 1) uniform  SceneData{
    vec4 fogColor; // w is for exponent
	vec4 fogDistances; //x for min, y for max, zw unused.
	vec4 ambientColor;
	vec4 sunlightDirection; //w for sun power
	vec4 sunlightColor;
} sceneData;

layout(set = 2, binding = 0) uniform sampler2D tex1;


void main()
{
	//outFragColor = vec4(in_color + 0.25 * sceneData.ambientColor.xyz,1.0f);
	// outFragColor = vec4(texCoord.x, texCoord.y, 0.5f, 1.0f);

    vec4 color = texture(tex1, texCoord).xyzw;

    if(color.w < 0.05)
    {
        discard;
    }

    //vec3 mixed = mix(normalize(vec3(0.5, 0.3, 0.2)) * 3, vec3(0.2, 0.2, 1) * 3, texCoord.y * 2);
    outFragColor = vec4(color.xyz, color.w);
    //outFragColor = vec4(color.xyz, 1.0f);
    //outFragColor = vec4(0.0, 1.0, 0.0, 1.0f);
}
