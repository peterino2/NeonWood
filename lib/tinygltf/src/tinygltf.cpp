#define TINYGLTF_IMPLEMENTATION
#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION

#include "tiny_gltf.h"

extern "C" Model LoadModel_c(const char* modelPath)
{
    tinygltf::Model model;
    tinygltf::TinyGTLF loader;
    bool ret = loader.
}
