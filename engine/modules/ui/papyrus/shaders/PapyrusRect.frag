#version 460

//shader input
layout (location = 0) in vec4 fragColor;
layout (location = 1) in vec2 texCoord;
layout (location = 2) in vec2 panelPixelPosition; // relative to the topleft
layout (location = 3) flat in int instanceId;

layout (location = 0) out vec4 outFragColor;

layout (set = 1, binding = 0) uniform sampler2D tex;


#include "PapyrusRectShared.glsl"
#include "FragmentHelpers.glsl"

void main() 
{
    vec2 imageSize = objectBuffer.objects[instanceId].imageSize;
    vec4 rounding =  objectBuffer.objects[instanceId].rounding;
    vec4 borderColor =  objectBuffer.objects[instanceId].borderColor;
    float borderWidth =  objectBuffer.objects[instanceId].borderWidth;
    float alpha = fragColor.w;
    uint usesImage = objectBuffer.objects[instanceId].flags & 1;

    // check to discard topleft
    vec3 color = fragColor.xyz;
    if(panelPixelPosition.x < rounding.x && panelPixelPosition.y < rounding.y)
    {
        float dist = distance(panelPixelPosition, vec2(rounding.x, rounding.x));
        if(dist > (rounding.x ))
        {
            discard;
        }
        else if(somewhatEqual(dist, rounding.x))
        {
            color = borderColor.xyz;
            alpha = borderColor.w;
        }
    }

    // top right
    if(panelPixelPosition.x > imageSize.x - rounding.y && panelPixelPosition.y < rounding.y )
    {
        float dist = distance(panelPixelPosition, vec2(imageSize.x - rounding.y, rounding.y));
        if(dist > rounding.y)
        {
           discard;
        }
        else if(somewhatEqual(dist, rounding.y))
        {
           color = borderColor.xyz;
           alpha = borderColor.w;
        }
    }

    // bottom Left
    if(panelPixelPosition.x < rounding.x && panelPixelPosition.y > imageSize.y - rounding.y)
    {
        float dist = distance(panelPixelPosition, vec2(rounding.x, imageSize.y - rounding.y));
        if(dist > rounding.y)
        {
           discard;
        }
        else if(somewhatEqual(dist, rounding.y))
        {
           color = borderColor.xyz;
           alpha = borderColor.w;
        }
    }

    // bottom right
    if(panelPixelPosition.x > imageSize.x - rounding.a && imageSize.y - panelPixelPosition.y < rounding.a )
    {
        float dist = distance(panelPixelPosition, vec2(imageSize.x - rounding.x, imageSize.y - rounding.y));
        if(dist > rounding.y)
        {
           discard;
        }
        else if(somewhatEqual(dist, rounding.y))
        {
           color = borderColor.xyz;
           alpha = borderColor.w;
        }
    }
    
    // check to discard topright
    
    // determine border colors

    if( panelPixelPosition.x < borderWidth 
        || panelPixelPosition.x > imageSize.x - borderWidth
        || panelPixelPosition.y < borderWidth
        || panelPixelPosition.y > imageSize.y - borderWidth
    )
    {
        color = borderColor.xyz;
        alpha = borderColor.w;
    }

    // scale the color
    if(usesImage > 0)
    {
        vec4 sampledColor = texture(tex, vec2(texCoord.x, 1 - texCoord.y));
        outFragColor = vec4(sampledColor.rgb, sampledColor.a * alpha);
    }
    else 
    {
        outFragColor = vec4(pow(color, vec3(2.2)), alpha);
    }
}
