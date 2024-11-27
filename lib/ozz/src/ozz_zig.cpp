#include <iostream>
#include "stdio.h"

#include "ozz/animation/runtime/animation.h"
#include "ozz/animation/runtime/local_to_model_job.h"
#include "ozz/animation/runtime/sampling_job.h"
#include "ozz/animation/runtime/skeleton.h"
#include "ozz/base/log.h"
#include "ozz/base/maths/simd_math.h"
#include "ozz/base/maths/soa_transform.h"
#include "ozz/base/maths/vec_float.h"
#include "ozz/options/options.h"

#include "ozz/base/io/archive.h"
#include "ozz/base/io/archive_traits.h"
#include "ozz/base/io/stream.h"

extern "C" {

void testFunc()
{
    fprintf(stderr, "lmao2nova \n");
    auto filename = "ozz-animation/media/bin/robot_skeleton.ozz";
    ozz::io::File file(filename, "rb");

    if (!file.opened()) 
    {
        ozz::log::Err() << "Cannot open file " << filename << "." << std::endl;
        return;
    }

    ozz::io::IArchive archive(&file);
    ozz::animation::Skeleton skeleton;
    archive >> skeleton;
}

void startupOzz()
{
}

void shutdownOzz()
{
}

void* CreateSkeleton_c()
{
    ozz::animation::Skeleton* rv = new(ozz::animation::Skeleton);
    return rv;
}

void LoadSkeletonFromFile_c(void* skeleton, const char* filename)
{
    ozz::animation::Skeleton* sk = static_cast<ozz::animation::Skeleton*>(skeleton);

    ozz::io::File file(filename, "rb");
    if (!file.opened()) 
    {
        ozz::log::Err() << "Cannot open file " << filename << "." << std::endl;
        return;
    }

    std::cout << "loading animation from " << filename << std::endl;
    ozz::io::IArchive archive(&file);
    archive >> *sk;
}
void DestroySkeleton_c(void* skeleton)
{
    ozz::animation::Skeleton* sk = static_cast<ozz::animation::Skeleton*>(skeleton);
    
    delete sk;
}

void* CreateAnimation_c()
{
    ozz::animation::Animation* a = new(ozz::animation::Animation);
    return a;
}


void DestroyAnimation_c(void* anim)
{
    ozz::animation::Animation* self = static_cast<ozz::animation::Animation*>(anim);
    delete self;
}

void LoadAnimationFromFile_c(void* anim, const char* filename)
{
    ozz::animation::Animation* self = static_cast<ozz::animation::Animation*>(anim);

    ozz::io::File file(filename, "rb");
    if (!file.opened()) {
      ozz::log::Err() << "Failed to open animation file " << filename << "."
                      << std::endl;
      return;
    }
    ozz::io::IArchive archive(&file);

    if (!archive.TestTag<ozz::animation::Animation>()) {
      ozz::log::Err() << "Failed to load animation instance from file "
                      << filename << "." << std::endl;
      return;
    }

    // Once the tag is validated, reading cannot fail.
    archive >> *self;
}

}
