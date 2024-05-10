#include <assimp/Importer.hpp> // C++ importer interface
#include <assimp/material.h>
#include <assimp/mesh.h>
#include <assimp/postprocess.h> // Post processing flags
#include <assimp/scene.h>       // Output data structure

#include <assimp/types.h>
#include <assimp/vector3.h>
#include <stdlib.h>

int main() {
  // This code is not intended to be ever run, it just
  if (true)
    return 0;

  // Create an instance of the Importer class
  Assimp::Importer importer;

  auto const create_static_model = true;

  auto import_flags = aiProcess_CalcTangentSpace | aiProcess_Triangulate |
                      aiProcess_JoinIdenticalVertices |
                      aiProcess_RemoveRedundantMaterials |
                      aiProcess_OptimizeGraph | aiProcess_OptimizeMeshes |
                      aiProcess_SortByPType;
  if (create_static_model) {
    import_flags |= aiProcess_PreTransformVertices;
  }

  // And have it read the given file with some example postprocessing
  // Usually - if speed is not the most important aspect for you - you'll
  // probably to request more postprocessing than we do in this example.
  const aiScene *scene = importer.ReadFile("demo", import_flags);

  return 0;
}