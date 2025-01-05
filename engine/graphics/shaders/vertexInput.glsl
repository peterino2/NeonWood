#extension GL_EXT_shader_explicit_arithmetic_types_int8 : enable
layout (location = 0) in vec3 vPosition;
layout (location = 1) in vec3 vNormal;
layout (location = 2) in vec4 vColor;
layout (location = 3) in vec2 vTexCoord;
layout (location = 4) in u8vec4 bones;
layout (location = 5) in u8vec4 weights;
