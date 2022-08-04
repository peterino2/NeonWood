// This file stores comptime-known configuration variables.
// These would be defines specified before including vk_mem_alloc.h.
// This file is read by both the `zig build` in this repo and the
// zig header.

pub const debugConfig = Config{
    // Override values here for your build
    .vulkanVersion = 1001000, // Vulkan 1.1
    //.recordingEnabled = true,
    //.statsStringEnabled = false,
    //.debugMargin = 64,
    //.debugDetectCorruption = true,
    //.debugInitializeAllocations = true,
    //.debugGlobalMutex = true,
    //.debugMinBufferImageGranularity = 256,
};

pub const releaseConfig = Config{
    // Override values here for your build
    .vulkanVersion = 1001000, // Vulkan 1.1
    //.statsStringEnabled = false,
};

// Default values here, please do not change
// Null in any of these values means that no
// define will be passed to the build and the
// default value will be used.
pub const Config = struct {
    /// The current version of vulkan
    vulkanVersion: u32 = 1000000, // Vulkan 1.0

    /// Whether to use the KHR Dedicated Allocation extension
    dedicatedAllocation: bool = false, // NOTE: Please modify values in the instance at the top of this file, not here.

    /// Whether to use the KHR Bind Memory 2 extension
    bindMemory2: bool = false, // NOTE: Please modify values in the instance at the top of this file, not here.

    /// Whether to use the KHR Memory Budget extension
    memoryBudget: bool = false, // NOTE: Please modify values in the instance at the top of this file, not here.

    /// If you experience a bug with incorrect and nondeterministic data in your program and you suspect uninitialized memory to be used,
    /// you can enable automatic memory initialization to verify this.
    /// To do it, set debugInitializeAllocations to true.
    ///
    /// It makes memory of all new allocations initialized to bit pattern `0xDCDCDCDC`.
    /// Before an allocation is destroyed, its memory is filled with bit pattern `0xEFEFEFEF`.
    /// Memory is automatically mapped and unmapped if necessary.
    ///
    /// If you find these values while debugging your program, good chances are that you incorrectly
    /// read Vulkan memory that is allocated but not initialized, or already freed, respectively.
    ///
    /// Memory initialization works only with memory types that are `HOST_VISIBLE`.
    /// It works also with dedicated allocations.
    /// It doesn't work with allocations created with #VMA_ALLOCATION_CREATE_CAN_BECOME_LOST_BIT flag,
    /// as they cannot be mapped.
    debugInitializeAllocations: ?bool = null, // NOTE: Please modify values in the instance at the top of this file, not here.

    /// By default, allocations are laid out in memory blocks next to each other if possible
    /// (considering required alignment, `bufferImageGranularity`, and `nonCoherentAtomSize`).
    ///
    /// ![Allocations without margin](../gfx/Margins_1.png)
    ///
    /// Define debugMargin to some non-zero value (e.g. 16) to enforce specified
    /// number of bytes as a margin before and after every allocation.
    /// If your bug goes away after enabling margins, it means it may be caused by memory
    /// being overwritten outside of allocation boundaries. It is not 100% certain though.
    /// Change in application behavior may also be caused by different order and distribution
    /// of allocations across memory blocks after margins are applied.
    ///
    /// The margin is applied also before first and after last allocation in a block.
    /// It may occur only once between two adjacent allocations.
    ///
    /// Margins work with all types of memory.
    ///
    /// Margin is applied only to allocations made out of memory blocks and not to dedicated
    /// allocations, which have their own memory block of specific size.
    /// It is thus not applied to allocations made using #VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT flag
    /// or those automatically decided to put into dedicated allocations, e.g. due to its
    /// large size or recommended by VK_KHR_dedicated_allocation extension.
    /// Margins are also not active in custom pools created with #VMA_POOL_CREATE_BUDDY_ALGORITHM_BIT flag.
    ///
    /// Margins appear in [JSON dump](@ref statistics_json_dump) as part of free space.
    ///
    /// Note that enabling margins increases memory usage and fragmentation.
    debugMargin: ?usize = null, // NOTE: Please modify values in the instance at the top of this file, not here.

    /// You can additionally set debugDetectCorruption to enable validation
    /// of contents of the margins.
    ///
    /// When this feature is enabled, number of bytes specified as `VMA_DEBUG_MARGIN`
    /// (it must be multiply of 4) before and after every allocation is filled with a magic number.
    /// This idea is also know as "canary".
    /// Memory is automatically mapped and unmapped if necessary.
    ///
    /// This number is validated automatically when the allocation is destroyed.
    /// If it's not equal to the expected value, `VMA_ASSERT()` is executed.
    /// It clearly means that either CPU or GPU overwritten the memory outside of boundaries of the allocation,
    /// which indicates a serious bug.
    ///
    /// You can also explicitly request checking margins of all allocations in all memory blocks
    /// that belong to specified memory types by using function vmaCheckCorruption(),
    /// or in memory blocks that belong to specified custom pool, by using function
    /// vmaCheckPoolCorruption().
    ///
    /// Margin validation (corruption detection) works only for memory types that are
    /// `HOST_VISIBLE` and `HOST_COHERENT`.
    debugDetectCorruption: ?bool = null, // NOTE: Please modify values in the instance at the top of this file, not here.

    /// Recording functionality is disabled by default.
    /// To enable it, set recordingEnabled to true.
    ///
    /// <b>To record sequence of calls to a file:</b> Fill in
    /// VmaAllocatorCreateInfo::pRecordSettings member while creating #VmaAllocator
    /// object. File is opened and written during whole lifetime of the allocator.
    ///
    /// <b>To replay file:</b> Use VmaReplay - standalone command-line program.
    /// Precompiled binary can be found in "bin" directory.
    /// Its source can be found in "src/VmaReplay" directory.
    /// Its project is generated by Premake.
    /// Command line syntax is printed when the program is launched without parameters.
    /// Basic usage:
    ///
    ///     VmaReplay.exe MyRecording.csv
    ///
    /// <b>Documentation of file format</b> can be found in file: "docs/Recording file format.md".
    /// It's a human-readable, text file in CSV format (Comma Separated Values).
    ///
    /// \section record_and_replay_additional_considerations Additional considerations
    ///
    /// - Replaying file that was recorded on a different GPU (with different parameters
    ///   like `bufferImageGranularity`, `nonCoherentAtomSize`, and especially different
    ///   set of memory heaps and types) may give different performance and memory usage
    ///   results, as well as issue some warnings and errors.
    /// - Current implementation of recording in VMA, as well as VmaReplay application, is
    ///   coded and tested only on Windows. Inclusion of recording code is driven by
    ///   `VMA_RECORDING_ENABLED` macro. Support for other platforms should be easy to
    ///   add. Contributions are welcomed.
    recordingEnabled: ?bool = null, // NOTE: Please modify values in the instance at the top of this file, not here.

    /// Minimum value for VkPhysicalDeviceLimits::bufferImageGranularity.
    /// Set to more than 1 for debugging purposes only. Must be power of two.
    debugMinBufferImageGranularity: ?usize = null, // NOTE: Please modify values in the instance at the top of this file, not here.

    /// Set this to 1 for debugging purposes only, to enable single mutex protecting all
    /// entry calls to the library. Can be useful for debugging multithreading issues.
    debugGlobalMutex: ?bool = null, // NOTE: Please modify values in the instance at the top of this file, not here.

    /// Whether to use C++ STL containers for VMA internal data
    useStlContainers: ?bool = null, // NOTE: Please modify values in the instance at the top of this file, not here.

    /// Set to true to always use STL mutex, false otherwise.
    /// If null, the library will choose based on whether
    /// the compiler supports C++17.
    useStlSharedMutex: ?bool = null, // NOTE: Please modify values in the instance at the top of this file, not here.

    // Set this to true to enable functions: vmaBuildStatsString, vmaFreeStatsString.
    statsStringEnabled: bool = true, // NOTE: Please modify values in the instance at the top of this file, not here.

    /// Set this value to true to make the library fetch pointers to Vulkan functions
    /// internally, like:
    ///
    ///     vulkanFunctions.vkAllocateMemory = &vkAllocateMemory;
    ///
    /// Set to false if you are going to provide you own pointers to Vulkan functions via
    /// AllocatorCreateInfo::pVulkanFunctions.
    staticVulkanFunctions: bool = true, // NOTE: Please modify values in the instance at the top of this file, not here.
};
