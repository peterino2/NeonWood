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

bool SamplingJob_Run_c(void* context)
{
    ozz::animation::SamplingJob* self = static_cast<ozz::animation::SamplingJob*>(context);
    return self->Run();
}

bool SamplingJob_Validate_c(void* context)
{
    ozz::animation::SamplingJob* self = static_cast<ozz::animation::SamplingJob*>(context);
    return self->Validate();
}

int SkeletonNumJoints_c(void* context)
{
    ozz::animation::Skeleton* self = static_cast<ozz::animation::Skeleton*>(context);
    return self->num_joints();
}

int SkeletonNumSoaJoints_c(void* context)
{
    ozz::animation::Skeleton* self = static_cast<ozz::animation::Skeleton*>(context);
    return self->num_soa_joints();
}

void* CreateSkeleton_c()
{
    ozz::animation::Skeleton* rv = new ozz::animation::Skeleton();
    return rv;
}

void LoadSkeletonFromFile_c(void* skeleton, const char* filename)
{
    ozz::animation::Skeleton* sk = static_cast<ozz::animation::Skeleton*>(skeleton);

    ozz::io::File file(filename, "rb");
    if (!file.opened()) 
    {
        std::cout << "Cannot open file " << filename << "." << std::endl;
        return;
    }


    std::cout << "loading skeleton from " << filename << std::endl;
    ozz::io::IArchive archive(&file);

    if (!archive.TestTag<ozz::animation::Skeleton>()) {
        std::cout << "Archive doesn't contain the expected object type." <<
        std::endl;
      return;
    }

    archive >> *sk;
}

struct OpaqueSpan 
{
    void* start;
    void* end;
};

OpaqueSpan SkeletonJointRestPoses_c (void* skeleton)
{
    ozz::animation::Skeleton* sk = static_cast<ozz::animation::Skeleton*>(skeleton);
    auto x = sk->joint_rest_poses();
    OpaqueSpan* p = reinterpret_cast<OpaqueSpan*>(&x);

    return *p;
}

void DestroySkeleton_c(void* skeleton)
{
    ozz::animation::Skeleton* sk = static_cast<ozz::animation::Skeleton*>(skeleton);
    
    delete sk;
}

void* CreateAnimation_c()
{
    ozz::animation::Animation* a = new ozz::animation::Animation();
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

    std::cout << "loading skeleton from " << filename << std::endl;
    ozz::io::IArchive archive(&file);

    if (!archive.TestTag<ozz::animation::Animation>()) {
        std::cout << "Failed to load animation instance from file "
                      << filename << "." << std::endl;
      return;
    }

    // Once the tag is validated, reading cannot fail.
    archive >> *self;
}

// === SmplingJobContext ===

    //pub extern fn CreateSamplingJobContextCount_c(c_int) callconv(.C) ?*anyopaque;
void* CreateSamplingJobContext_c() 
{
    ozz::animation::SamplingJob::Context* rv = new ozz::animation::SamplingJob::Context();
    
    return rv;
}

void* CreateSamplingJobContextCount_c(int count) 
{
    ozz::animation::SamplingJob::Context* rv = new ozz::animation::SamplingJob::Context(count);
    
    return rv;
}

void DestroySamplingJobContext_c(void* context) 
{
    ozz::animation::SamplingJob::Context* self = static_cast<ozz::animation::SamplingJob::Context*>(context);

    delete self;
}

void SamplingJobContext_Resize_c(void* context, int maxSize) 
{
    ozz::animation::SamplingJob::Context* self = static_cast<ozz::animation::SamplingJob::Context*>(context);

    self->Resize(maxSize);
}

void SamplingJobContext_Invalidate_c(void* context) 
{
    ozz::animation::SamplingJob::Context* self = static_cast<ozz::animation::SamplingJob::Context*>(context);

    self->Invalidate();
}

int SamplingJobContext_MaxSoaTracks_c(void* context)
{
    ozz::animation::SamplingJob::Context* self = static_cast<ozz::animation::SamplingJob::Context*>(context);

    return self->max_soa_tracks();
}

int SamplingJobContext_MaxTracks_c(void* context)
{
    ozz::animation::SamplingJob::Context* self = static_cast<ozz::animation::SamplingJob::Context*>(context);

    return self->max_tracks();
}

bool LocalToModelJob_Run_c(void* context)
{
    ozz::animation::LocalToModelJob* self = static_cast<ozz::animation::LocalToModelJob*>(context);

    return self->Run();
}

}
