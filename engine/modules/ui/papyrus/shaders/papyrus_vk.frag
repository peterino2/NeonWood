#version 450

//shader input
layout (location = 0) in vec4 fragColor;
layout (location = 1) in vec2 texCoord;

layout (location = 0) out vec4 outFragColor;

layout (set = 1, binding = 0) uniform sampler2D tex;

layout (push_constant) uniform constants 
{
	vec2 extent;
} PushConstants;

float median(float r, float g, float b) 
{
    return max(min(r, g), min(max(r, g), b));
}

void main() 
{
    //vec4 color = texture(tex, vec2(texCoord.x / 40 + 0.3, texCoord.y));
    outFragColor = vec4(fragColor.xyz, 1.0f);
    //outFragColor = vec4(1.0, 1.0, 1.0, 1.0f);
    // vec2 xform = vec2(texCoord.x / 100 + 0.3, texCoord.y);

    // vec2 flipped_texCoords = vec2(1.0 - xform.x, 1.0 - xform.y);
    // vec2 pos = flipped_texCoords.xy;
    // vec3 sampled = texture(tex, flipped_texCoords).rgb;

    // ivec2 sz = textureSize(tex, 0).xy;
    // float dx = dFdx(pos.x) * sz.x; 
    // float dy = dFdy(pos.y) * sz.y;
    // float toPixels = 8.0 * inversesqrt(dx * dx + dy * dy);
    // float sigDist = median(sampled.r, sampled.g, sampled.b);
    // float w = fwidth(sigDist);
    // float opacity = smoothstep(0.5 - w, 0.5 + w, sigDist);    

    // outFragColor = vec4(vec3(1,1,1), opacity);
}
