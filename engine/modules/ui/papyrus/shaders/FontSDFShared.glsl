struct FontInfo {
  vec2 position; // 8 bytes alignment 0
  vec2 size;     // 8 bytes alignment 8
  uint isSdf; // 4 bytes 16
  uint pad0;     // 4 bytes
  vec2 pad2;     // 8 bytes
};

layout(std140, set = 0, binding = 0) readonly buffer FontInfoBuffer{ 
    FontInfo fontInfo[];
} fontBuffer;

layout (push_constant) uniform constants {
	vec2 extent;
} PushConstants;
