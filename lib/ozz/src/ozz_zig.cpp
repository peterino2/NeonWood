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
    
}
