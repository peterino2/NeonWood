#version 460

//shader input
layout (location = 0) in vec4 fragColor;
layout (location = 1) in vec2 texCoord;
layout (location = 2) in vec2 panelPixelPosition; // relative to the topleft
layout (location = 3) flat in int instanceId;

layout (location = 0) out vec4 outFragColor;

layout (set = 1, binding = 0) uniform sampler2D tex;

layout (push_constant) uniform constants 
{
	vec2 extent;
} PushConstants;

// has to match what's in the vertex shader
struct ImageRenderData {
    vec2 imagePosition;
    vec2 imageSize;
    vec2 anchorPoint;
    vec2 scale;
    float alpha;
    float borderWidth;
	vec4 baseColor;
	vec4 rounding;
    vec4 borderColor;
};

layout(std140, set = 0, binding = 0) readonly buffer ImageBufferObjects {
    ImageRenderData objects[];
} objectBuffer;

float median(float r, float g, float b) 
{
    return max(min(r, g), min(max(r, g), b));
}

void main() 
{
    vec2 imageSize = objectBuffer.objects[instanceId].imageSize;
    vec4 rounding =  objectBuffer.objects[instanceId].rounding;
    vec4 borderColor =  objectBuffer.objects[instanceId].borderColor;
    float borderWidth =  objectBuffer.objects[instanceId].borderWidth;

    // check to discard topleft
    vec3 color = fragColor.xyz;
    if(panelPixelPosition.x < rounding.x && panelPixelPosition.y < rounding.y)
    {
        if(distance(panelPixelPosition, vec2(rounding.x, rounding.x)) > rounding.x)
        {
            discard;
        }
    }

    // top right
    if(panelPixelPosition.x > imageSize.x - rounding.y && panelPixelPosition.y < rounding.y )
    {
         if(distance(panelPixelPosition, vec2(imageSize.x - rounding.y, rounding.y)) > rounding.y)
         {
            discard;
         }
    }
    
    // check to discard topright
    

    // determine border colors

    if(panelPixelPosition.x < borderWidth 
        || panelPixelPosition.x > imageSize.x - borderWidth
        || panelPixelPosition.y < borderWidth
        || panelPixelPosition.y > imageSize.y - borderWidth
    )
    {
        color = borderColor.xyz;
        //color = vec3(1.0, 0,0);
    }


    // scale the color
    outFragColor = vec4(pow(color, vec3(2.2)), fragColor.w);
}
