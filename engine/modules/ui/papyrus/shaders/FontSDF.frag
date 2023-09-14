#version 460

layout (location = 0) in vec4 color;
layout (location = 1) in vec2 texCoord;
layout (location = 2) flat in int instanceId;

layout (location = 0) out vec4 outFragColor;

layout (set = 1, binding = 0) uniform sampler2D tex;

layout (push_constant) uniform constants {
	vec2 extent;
} PushConstants;

struct FontInfo {
    vec2 position;
    vec2 size;
    uint isSimple;
};

layout(std140, set = 0, binding = 0) readonly buffer FontInfoBuffer{ 
    FontInfo fontInfo[];
} fontBuffer;

// float median(float r, float g, float b) 
// {
//     return max(min(r, g), min(max(r, g), b));
// }

// SDF sample code
// void main() 
// {
//     float gamma = 2.2;
//     //outFragColor = vec4(pow(fragColor.xyz, vec3(2.2)), 1.0f);
//     //outFragColor = vec4(1.0, 1.0, 1.0, 1.0f);
//     vec2 xform = vec2(texCoord.x, texCoord.y);
//     vec2 pos = xform.xy;
//     vec3 sampled = texture(tex, xform).rgb;
// 
//     ivec2 sz = textureSize(tex, 0).xy;
//     float dx = dFdx(pos.x) * sz.x; 
//     float dy = dFdy(pos.y) * sz.y;
//     float toPixels = 8.0 * inversesqrt(dx * dx + dy * dy);
// 
//     float sigDist = median(sampled.r, sampled.g, sampled.b);
//     float w = fwidth(sigDist);
//     float compare = 180.f / 255.f;
//     //float opacity = smoothstep(compare - w, compare + w, sigDist);    
//     float opacity = step(compare, sigDist);
// 
//     outFragColor = vec4(pow(color.rgb, vec3(gamma)), opacity);
// }

float contour(float dist, float edge, float width) {
  return clamp(smoothstep(edge - width, edge + width, dist), 0.0, 1.0);
}

float getSample(vec2 texCoord, float edge, float width) {
  return contour(texture(tex, texCoord).r, edge, width);
}

void main() {
    vec4 tex = texture(tex, texCoord);

    uint isSimple = fontBuffer.fontInfo[instanceId].isSimple;

    if(isSimple != 0)
    {
        float dist  = tex.r;
        float width = fwidth(dist);
        vec4 textColor = clamp(color, 0.0, 1.0);
        float outerEdge = 1.0f - (120.0f / 255.0f);

        float alpha = contour(dist, outerEdge, width);

        float dscale = 0.354; // half of 1/sqrt2; you can play with this
        vec2 uv = texCoord.xy;
        vec2 duv = dscale * (dFdx(uv) + dFdy(uv));
        vec4 box = vec4(uv - duv, uv + duv);

        float asum = getSample(box.xy, outerEdge, width)
                 + getSample(box.zw, outerEdge, width)
                 + getSample(box.xw, outerEdge, width)
                 + getSample(box.zy, outerEdge, width);

        // weighted average, with 4 extra points having 0.5 weight each,
        // so 1 + 0.5*4 = 3 is the divisor
        alpha = (alpha + 0.5 * asum) / 3.0;

        textColor = vec4(color.xyz, alpha);//textColor.* alpha);
        textColor.xyz = pow(textColor.xyz, vec3(2.2)); // gamma correction

        // Premultiplied alpha output.
        outFragColor = textColor;
    }
    else {
        float alpha = 1.0;
        vec4 textColor = clamp(color, 0.0, 1.0);
        textColor = vec4(color.xyz, alpha);//textColor.* alpha);
        outFragColor = vec4(textColor.xyz, tex.x);
    }
}
