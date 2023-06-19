#version 460

layout (location = 0) in vec4 color;
layout (location = 1) in vec2 texCoord;

layout (location = 0) out vec4 outFragColor;

layout (set = 1, binding = 0) uniform sampler2D tex;

layout (push_constant) uniform constants {
	vec2 extent;
} PushConstants;

float median(float r, float g, float b) 
{
    return max(min(r, g), min(max(r, g), b));
}


// SDF sample code
void main() 
{
    float gamma = 2.2;
    //outFragColor = vec4(pow(fragColor.xyz, vec3(2.2)), 1.0f);
    //outFragColor = vec4(1.0, 1.0, 1.0, 1.0f);
    vec2 xform = vec2(texCoord.x, texCoord.y);
    vec2 pos = xform.xy;
    vec3 sampled = texture(tex, xform).rgb;

    ivec2 sz = textureSize(tex, 0).xy;
    float dx = dFdx(pos.x) * sz.x; 
    float dy = dFdy(pos.y) * sz.y;
    float toPixels = 8.0 * inversesqrt(dx * dx + dy * dy);
    float sigDist = median(sampled.r, sampled.g, sampled.b);
    float w = fwidth(sigDist);
    float opacity = smoothstep(0.5 - w, 0.5 + w, sigDist);    

    outFragColor = vec4(pow(color.rgb, vec3(gamma)), opacity);
}
