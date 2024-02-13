
// has to match what's in the vertex shader
struct ImageRenderData {
    vec2 imagePosition;
    vec2 imageSize;
    vec2 anchorPoint;
    vec2 scale;
    float alpha;
    float borderWidth;
    uint flags;
	vec4 baseColor;
	vec4 rounding;
    vec4 borderColor;
};

layout(std140, set = 0, binding = 0) readonly buffer ImageBufferObjects {
    ImageRenderData objects[];
} objectBuffer;

layout (push_constant) uniform constants 
{
	vec2 extent;
} PushConstants;
