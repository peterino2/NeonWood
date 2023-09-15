#version 460

layout (location = 0) in vec4 color;
layout (location = 1) in vec2 texCoord;
layout (location = 2) flat in int instanceId;
layout (location = 3) in vec2 pixelPosition;

layout (location = 0) out vec4 outFragColor;

layout (set = 1, binding = 0) uniform sampler2D tex;

layout (push_constant) uniform constants {
	vec2 extent;
} PushConstants;

struct FontInfo {
    vec2 position;
    vec2 size;
    uint isSdf;
    uint pad0;
    vec2 pad2;
};

layout(std140, set = 0, binding = 0) readonly buffer FontInfoBuffer{ 
    FontInfo fontInfo[];
} fontBuffer;


float contour(float dist, float edge, float width) {
  return clamp(smoothstep(edge - width, edge + width, dist), 0.0, 1.0);
}

float getSample(vec2 texCoord, float edge, float width) {
  return contour(texture(tex, texCoord).r, edge, width);
}

bool scissor(vec2 position, vec2 topleft, vec2 size)
{
    if(position.x >= topleft.x && position.x <= topleft.x + size.x &&
       position.y >= topleft.y && position.y <= topleft.y + size.y )
    {
        return true;
    }

    return false;
}

bool rect(vec2 position, vec2 topleft, vec2 size)
{
    if(position.x >= topleft.x && position.x <= topleft.x + size.x &&
       position.y >= topleft.y && position.y <= topleft.y + size.y )
    {
        return true;
    }

    return false;
}

void main() {
    vec4 tex = texture(tex, texCoord);

    uint isSdf = fontBuffer.fontInfo[instanceId].isSdf;
    vec2 position = fontBuffer.fontInfo[instanceId].position;
    vec2 size = fontBuffer.fontInfo[instanceId].size;

    if(!scissor(pixelPosition, position, size))
    {
        discard;
    }

    if(isSdf == 1)
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
        outFragColor = vec4(color.xyz , pow(tex.x, 1/1.5));//textColor.* alpha);
    }

    /* debug test.
    if(!rect(pixelPosition, position, size))
    {
        outFragColor = vec4(1.0, 0.0, 0.0, 1.0);
    }
    */
}
