#version 460

layout (location = 0) in vec4 color;
layout (location = 1) in vec2 texCoords;

layout (location = 0) out vec4 outFragColor;

layout (set = 1, binding = 0) uniform sampler2D msdf;

float median(float r, float g, float b) 
{
    return max(min(r, g), min(max(r, g), b));
}


// SDF sample code
void main() 
{
    vec2 flipped_texCoords = vec2(texCoords.x, 1.0 - texCoords.y);
    vec2 pos = flipped_texCoords.xy;
    vec3 sampled = texture(msdf, flipped_texCoords).rgb;

    ivec2 sz = textureSize(msdf, 0).xy;
    float dx = dFdx(pos.x) * sz.x; 
    float dy = dFdy(pos.y) * sz.y;
    float toPixels = 8.0 * inversesqrt(dx * dx + dy * dy);
    float sigDist = median(sampled.r, sampled.g, sampled.b);
    float w = fwidth(sigDist);
    float opacity = smoothstep(0.5 - w, 0.5 + w, sigDist);    

    outFragColor = vec4(color.rgb, opacity);
}
