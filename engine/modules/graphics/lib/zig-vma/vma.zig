// This API and many of the comments in this file come
// directly from the VulkanMemoryAllocator source, which is
// released under the following license:
//
// Copyright (c) 2017-2019 Advanced Micro Devices, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;
const vk = @import("vk");
const vma_config = @import("vma_config.zig");
pub const config = if (builtin.mode == .Debug) vma_config.debugConfig else vma_config.releaseConfig;

const vulkan_call_conv = vk.vulkan_call_conv;

// callbacks use vulkan_call_conv, but the vma functions may not.
pub const CallConv = .C;

/// \struct Allocator
/// \brief Represents main object of this library initialized.
///
/// Fill structure #AllocatorCreateInfo and call function create() to create it.
/// Call function destroy() to destroy it.
///
/// It is recommended to create just one object of this type per `Device` object,
/// right after Vulkan is initialized and keep it alive until before Vulkan device is destroyed.
pub const Allocator = enum(usize) {
    Null = 0,
    _,

    /// Creates Allocator object.
    pub fn create(createInfo: AllocatorCreateInfo) !Allocator {
        var result: Allocator = undefined;
        const rc = vmaCreateAllocator(&createInfo, &result);
        if (@enumToInt(rc) >= 0) return result;

        return error.VMACreateFailed;
    }

    /// Destroys allocator object.
    /// fn (Allocator) void
    pub const destroy = vmaDestroyAllocator;

    /// PhysicalDeviceProperties are fetched from physicalDevice by the allocator.
    /// You can access it here, without fetching it again on your own.
    pub fn getPhysicalDeviceProperties(allocator: Allocator) *const vk.PhysicalDeviceProperties {
        var properties: *const vk.PhysicalDeviceProperties = undefined;
        vmaGetPhysicalDeviceProperties(allocator, &properties);
        return properties;
    }

    /// PhysicalDeviceMemoryProperties are fetched from physicalDevice by the allocator.
    /// You can access it here, without fetching it again on your own.
    pub fn getMemoryProperties(allocator: Allocator) *const vk.PhysicalDeviceMemoryProperties {
        var properties: *const vk.PhysicalDeviceMemoryProperties = undefined;
        vmaGetMemoryProperties(allocator, &properties);
        return properties;
    }

    /// \brief Given Memory Type Index, returns Property Flags of this memory type.
    ///
    /// This is just a convenience function. Same information can be obtained using
    /// GetMemoryProperties().
    pub fn getMemoryTypeProperties(allocator: Allocator, memoryTypeIndex: u32) vk.MemoryPropertyFlags {
        var flags: vk.MemoryPropertyFlags align(4) = undefined;
        vmaGetMemoryTypeProperties(allocator, memoryTypeIndex, &flags);
        return flags;
    }

    /// \brief Sets index of the current frame.
    ///
    /// This function must be used if you make allocations with
    /// #VMA_ALLOCATION_CREATE_CAN_BECOME_LOST_BIT and
    /// #VMA_ALLOCATION_CREATE_CAN_MAKE_OTHER_LOST_BIT flags to inform the allocator
    /// when a new frame begins. Allocations queried using GetAllocationInfo() cannot
    /// become lost in the current frame.
    /// fn setCurrentFrameIndex(self: Allocator, frameIndex: u32) void
    pub const setCurrentFrameIndex = vmaSetCurrentFrameIndex;

    /// \brief Retrieves statistics from current state of the Allocator.
    ///
    /// This function is called "calculate" not "get" because it has to traverse all
    /// internal data structures, so it may be quite slow. For faster but more brief statistics
    /// suitable to be called every frame or every allocation, use GetBudget().
    ///
    /// Note that when using allocator from multiple threads, returned information may immediately
    /// become outdated.
    pub fn calculateStats(allocator: Allocator) Stats {
        var stats: Stats = undefined;
        vmaCalculateStats(allocator, &stats);
        return stats;
    }

    /// \brief Retrieves information about current memory budget for all memory heaps.
    ///
    /// \param[out] pBudget Must point to array with number of elements at least equal to number of memory heaps in physical device used.
    ///
    /// This function is called "get" not "calculate" because it is very fast, suitable to be called
    /// every frame or every allocation. For more detailed statistics use CalculateStats().
    ///
    /// Note that when using allocator from multiple threads, returned information may immediately
    /// become outdated.
    pub fn getBudget(allocator: Allocator) Budget {
        var budget: Budget = undefined;
        vmaGetBudget(allocator, &budget);
        return budget;
    }

    // pub usingnamespace if (config.statsStringEnabled)
    //     struct {
    //         /// Builds and returns statistics as string in JSON format.
    //         /// @param[out] ppStatsString Must be freed using FreeStatsString() function.
    //         pub fn buildStatsString(allocator: Allocator, detailedMap: bool) [*:0]u8 {
    //             var string: [*:0]u8 = undefined;
    //             vmaBuildStatsString(allocator, &string, @boolToInt(detailedMap));
    //             return string;
    //         }

    //         pub const freeStatsString = vmaFreeStatsString;
    //     }
    // else
    //     struct {};

    /// \brief Helps to find memoryTypeIndex, given memoryTypeBits and AllocationCreateInfo.
    ///
    /// This algorithm tries to find a memory type that:
    ///
    /// - Is allowed by memoryTypeBits.
    /// - Contains all the flags from pAllocationCreateInfo->requiredFlags.
    /// - Matches intended usage.
    /// - Has as many flags from pAllocationCreateInfo->preferredFlags as possible.
    ///
    /// \return Returns error.VK_FEATURE_NOT_PRESENT if not found. Receiving such result
    /// from this function or any other allocating function probably means that your
    /// device doesn't support any memory type with requested features for the specific
    /// type of resource you want to use it for. Please check parameters of your
    /// resource, like image layout (OPTIMAL versus LINEAR) or mip level count.
    pub fn findMemoryTypeIndex(allocator: Allocator, memoryTypeBits: u32, allocationCreateInfo: AllocationCreateInfo) !u32 {
        var index: u32 = undefined;
        const rc = vmaFindMemoryTypeIndex(allocator, memoryTypeBits, &allocationCreateInfo, &index);
        if (@enumToInt(rc) >= 0) return index;

        if (rc == .ERROR_FEATURE_NOT_PRESENT) return error.VK_FEATURE_NOT_PRESENT;
        return error.VK_UNDOCUMENTED_ERROR;
    }

    /// \brief Helps to find memoryTypeIndex, given vk.BufferCreateInfo and AllocationCreateInfo.
    ///
    /// It can be useful e.g. to determine value to be used as PoolCreateInfo::memoryTypeIndex.
    /// It internally creates a temporary, dummy buffer that never has memory bound.
    /// It is just a convenience function, equivalent to calling:
    ///
    /// - `vkCreateBuffer`
    /// - `vkGetBufferMemoryRequirements`
    /// - `FindMemoryTypeIndex`
    /// - `vkDestroyBuffer`
    pub fn findMemoryTypeIndexForBufferInfo(
        allocator: Allocator,
        bufferCreateInfo: vk.BufferCreateInfo,
        allocationCreateInfo: AllocationCreateInfo,
    ) !u32 {
        var index: u32 = undefined;
        const rc = vmaFindMemoryTypeIndexForBufferInfo(allocator, &bufferCreateInfo, &allocationCreateInfo, &index);
        if (@enumToInt(rc) >= 0) return index;

        return switch (rc) {
            .ERROR_OUT_OF_HOST_MEMORY => error.VK_OUT_OF_HOST_MEMORY,
            .ERROR_OUT_OF_DEVICE_MEMORY => error.VK_OUT_OF_DEVICE_MEMORY,
            .ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS => error.VK_INVALID_OPAQUE_CAPTURE_ADDRESS,
            .ERROR_FEATURE_NOT_PRESENT => error.VK_FEATURE_NOT_PRESENT,
            else => error.VK_UNDOCUMENTED_ERROR,
        };
    }

    /// \brief Helps to find memoryTypeIndex, given vk.ImageCreateInfo and AllocationCreateInfo.
    ///
    /// It can be useful e.g. to determine value to be used as PoolCreateInfo::memoryTypeIndex.
    /// It internally creates a temporary, dummy image that never has memory bound.
    /// It is just a convenience function, equivalent to calling:
    ///
    /// - `vkCreateImage`
    /// - `vkGetImageMemoryRequirements`
    /// - `FindMemoryTypeIndex`
    /// - `vkDestroyImage`
    pub fn findMemoryTypeIndexForImageInfo(
        allocator: Allocator,
        imageCreateInfo: vk.ImageCreateInfo,
        allocationCreateInfo: AllocationCreateInfo,
    ) !u32 {
        var index: u32 = undefined;
        const rc = vmaFindMemoryTypeIndexForImageInfo(allocator, &imageCreateInfo, &allocationCreateInfo, &index);
        if (@enumToInt(rc) >= 0) return index;

        return switch (rc) {
            .ERROR_OUT_OF_HOST_MEMORY => error.VK_OUT_OF_HOST_MEMORY,
            .ERROR_OUT_OF_DEVICE_MEMORY => error.VK_OUT_OF_DEVICE_MEMORY,
            .ERROR_FEATURE_NOT_PRESENT => error.VK_FEATURE_NOT_PRESENT,
            else => error.VK_UNDOCUMENTED_ERROR,
        };
    }

    /// \brief Allocates Vulkan device memory and creates #Pool object.
    ///
    /// @param allocator Allocator object.
    /// @param pCreateInfo Parameters of pool to create.
    /// @param[out] pPool Handle to created pool.
    pub fn createPool(allocator: Allocator, createInfo: PoolCreateInfo) !Pool {
        var pool: Pool = undefined;
        const rc = vmaCreatePool(allocator, &createInfo, &pool);
        if (@enumToInt(rc) >= 0) return pool;

        return switch (rc) {
            .ERROR_OUT_OF_HOST_MEMORY => error.VK_OUT_OF_HOST_MEMORY,
            .ERROR_OUT_OF_DEVICE_MEMORY => error.VK_OUT_OF_DEVICE_MEMORY,
            .ERROR_TOO_MANY_OBJECTS => error.VK_TOO_MANY_OBJECTS,
            .ERROR_INVALID_EXTERNAL_HANDLE => error.VK_INVALID_EXTERNAL_HANDLE,
            .ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS => error.VK_INVALID_OPAQUE_CAPTURE_ADDRESS,
            .ERROR_MEMORY_MAP_FAILED => error.VK_MEMORY_MAP_FAILED,
            else => error.VK_UNDOCUMENTED_ERROR,
        };
    }

    /// \brief Destroys #Pool object and frees Vulkan device memory.
    /// fn destroyPool(self: Allocator, pool: Pool) void
    pub const destroyPool = vmaDestroyPool;

    /// \brief Retrieves statistics of existing #Pool object.
    ///
    /// @param allocator Allocator object.
    /// @param pool Pool object.
    /// @param[out] pPoolStats Statistics of specified pool.
    pub fn getPoolStats(allocator: Allocator, pool: Pool) PoolStats {
        var stats: PoolStats = undefined;
        vmaGetPoolStats(allocator, pool, &stats);
        return stats;
    }

    /// \brief Marks all allocations in given pool as lost if they are not used in current frame or PoolCreateInfo::frameInUseCount back from now.
    ///
    /// @param allocator Allocator object.
    /// @param pool Pool.
    pub fn makePoolAllocationsLost(allocator: Allocator, pool: Pool) void {
        vmaMakePoolAllocationsLost(allocator, pool, null);
    }
    /// \brief Marks all allocations in given pool as lost if they are not used in current frame or PoolCreateInfo::frameInUseCount back from now.
    ///
    /// @param allocator Allocator object.
    /// @param pool Pool.
    /// @return the number of allocations that were marked as lost.
    pub fn makePoolAllocationsLostAndCount(allocator: Allocator, pool: Pool) usize {
        var count: usize = undefined;
        vmaMakePoolAllocationsLost(allocator, pool, &count);
        return count;
    }

    /// \brief Checks magic number in margins around all allocations in given memory pool in search for corruptions.
    ///
    /// Corruption detection is enabled only when `VMA_DEBUG_DETECT_CORRUPTION` macro is defined to nonzero,
    /// `VMA_DEBUG_MARGIN` is defined to nonzero and the pool is created in memory type that is
    /// `HOST_VISIBLE` and `HOST_COHERENT`. For more information, see [Corruption detection](@ref debugging_memory_usage_corruption_detection).
    ///
    /// Possible return values:
    ///
    /// - `error.VK_FEATURE_NOT_PRESENT` - corruption detection is not enabled for specified pool.
    /// - `vk.SUCCESS` - corruption detection has been performed and succeeded.
    /// - `error.VK_VALIDATION_FAILED_EXT` - corruption detection has been performed and found memory corruptions around one of the allocations.
    /// `VMA_ASSERT` is also fired in that case.
    /// - Other value: Error returned by Vulkan, e.g. memory mapping failure.
    pub fn checkPoolCorruption(allocator: Allocator, pool: Pool) !void {
        const rc = vmaCheckPoolCorruption(allocator, pool);
        if (@enumToInt(rc) >= 0) return;

        return switch (rc) {
            .ERROR_FEATURE_NOT_PRESENT => error.VMA_CORRUPTION_DETECTION_DISABLED,
            .ERROR_VALIDATION_FAILED_EXT => error.VMA_CORRUPTION_DETECTED,
            .ERROR_OUT_OF_HOST_MEMORY => error.VK_OUT_OF_HOST_MEMORY,
            .ERROR_OUT_OF_DEVICE_MEMORY => error.VK_OUT_OF_DEVICE_MEMORY,
            .ERROR_MEMORY_MAP_FAILED => error.VK_MEMORY_MAP_FAILED,
            else => error.VK_UNDOCUMENTED_ERROR,
        };
    }

    /// \brief Retrieves name of a custom pool.
    ///
    /// After the call `ppName` is either null or points to an internally-owned null-terminated string
    /// containing name of the pool that was previously set. The pointer becomes invalid when the pool is
    /// destroyed or its name is changed using SetPoolName().
    pub fn getPoolName(allocator: Allocator, pool: Pool) ?[*:0]const u8 {
        var name: ?[*:0]const u8 = undefined;
        vmaGetPoolName(allocator, pool, &name);
        return name;
    }

    /// \brief Sets name of a custom pool.
    ///
    /// `pName` can be either null or pointer to a null-terminated string with new name for the pool.
    /// Function makes internal copy of the string, so it can be changed or freed immediately after this call.
    /// fn setPoolName(self: Allocator, pool: Pool, name: ?[*:0]const u8)
    pub const setPoolName = vmaSetPoolName;

    /// \brief General purpose memory allocation.
    ///
    /// @param[out] pAllocation Handle to allocated memory.
    /// @param[out] pAllocationInfo Optional. Information about allocated memory. It can be later fetched using function GetAllocationInfo().
    ///
    /// You should free the memory using FreeMemory() or FreeMemoryPages().
    ///
    /// It is recommended to use AllocateMemoryForBuffer(), AllocateMemoryForImage(),
    /// CreateBuffer(), CreateImage() instead whenever possible.
    pub fn allocateMemory(allocator: Allocator, vkMemoryRequirements: vk.MemoryRequirements, createInfo: AllocationCreateInfo) !Allocation {
        return allocateMemoryAndGetInfo(allocator, vkMemoryRequirements, createInfo, null);
    }
    pub fn allocateMemoryAndGetInfo(allocator: Allocator, vkMemoryRequirements: vk.MemoryRequirements, createInfo: AllocationCreateInfo, outInfo: ?*AllocationInfo) !Allocation {
        var result: Allocation = undefined;
        const rc = vmaAllocateMemory(allocator, &vkMemoryRequirements, &createInfo, &result, outInfo);
        if (@enumToInt(rc) >= 0) return result;
        return switch (rc) {
            .ERROR_OUT_OF_HOST_MEMORY => error.VK_OUT_OF_HOST_MEMORY,
            .ERROR_OUT_OF_DEVICE_MEMORY => error.VK_OUT_OF_DEVICE_MEMORY,
            .ERROR_TOO_MANY_OBJECTS => error.VK_TOO_MANY_OBJECTS,
            .ERROR_INVALID_EXTERNAL_HANDLE => error.VK_INVALID_EXTERNAL_HANDLE,
            .ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS => error.VK_INVALID_OPAQUE_CAPTURE_ADDRESS,
            .ERROR_MEMORY_MAP_FAILED => error.VK_MEMORY_MAP_FAILED,
            .ERROR_FRAGMENTED_POOL => error.VK_FRAGMENTED_POOL,
            .ERROR_OUT_OF_POOL_MEMORY => error.VK_OUT_OF_POOL_MEMORY,
            else => error.VK_UNDOCUMENTED_ERROR,
        };
    }

    /// \brief General purpose memory allocation for multiple allocation objects at once.
    ///
    /// @param allocator Allocator object.
    /// @param pVkMemoryRequirements Memory requirements for each allocation.
    /// @param pCreateInfo Creation parameters for each alloction.
    /// @param allocationCount Number of allocations to make.
    /// @param[out] pAllocations Pointer to array that will be filled with handles to created allocations.
    /// @param[out] pAllocationInfo Optional. Pointer to array that will be filled with parameters of created allocations.
    ///
    /// You should free the memory using FreeMemory() or FreeMemoryPages().
    ///
    /// Word "pages" is just a suggestion to use this function to allocate pieces of memory needed for sparse binding.
    /// It is just a general purpose allocation function able to make multiple allocations at once.
    /// It may be internally optimized to be more efficient than calling AllocateMemory() `allocationCount` times.
    ///
    /// All allocations are made using same parameters. All of them are created out of the same memory pool and type.
    /// If any allocation fails, all allocations already made within this function call are also freed, so that when
    /// returned result is not `vk.SUCCESS`, `pAllocation` array is always entirely filled with `.Null`.
    pub fn allocateMemoryPages(allocator: Allocator, vkMemoryRequirements: vk.MemoryRequirements, createInfo: AllocationCreateInfo, outAllocations: []Allocation) !void {
        const rc = vmaAllocateMemoryPages(allocator, &vkMemoryRequirements, &createInfo, outAllocations.len, outAllocations.ptr, null);
        if (@enumToInt(rc) >= 0) return;
        return switch (rc) {
            .ERROR_OUT_OF_HOST_MEMORY => error.VK_OUT_OF_HOST_MEMORY,
            .ERROR_OUT_OF_DEVICE_MEMORY => error.VK_OUT_OF_DEVICE_MEMORY,
            .ERROR_TOO_MANY_OBJECTS => error.VK_TOO_MANY_OBJECTS,
            .ERROR_INVALID_EXTERNAL_HANDLE => error.VK_INVALID_EXTERNAL_HANDLE,
            .ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS => error.VK_INVALID_OPAQUE_CAPTURE_ADDRESS,
            .ERROR_MEMORY_MAP_FAILED => error.VK_MEMORY_MAP_FAILED,
            .ERROR_FRAGMENTED_POOL => error.VK_FRAGMENTED_POOL,
            .ERROR_OUT_OF_POOL_MEMORY => error.VK_OUT_OF_POOL_MEMORY,
            else => error.VK_UNDOCUMENTED_ERROR,
        };
    }
    pub fn allocateMemoryPagesAndGetInfo(allocator: Allocator, vkMemoryRequirements: vk.MemoryRequirements, createInfo: AllocationCreateInfo, outAllocations: []Allocation, outInfo: []AllocationInfo) !void {
        assert(outAllocations.len == outInfo.len);
        const rc = vmaAllocateMemoryPages(allocator, &vkMemoryRequirements, &createInfo, outAllocations.len, outAllocations.ptr, outInfo.ptr);
        if (@enumToInt(rc) >= 0) return;
        return switch (rc) {
            .ERROR_OUT_OF_HOST_MEMORY => error.VK_OUT_OF_HOST_MEMORY,
            .ERROR_OUT_OF_DEVICE_MEMORY => error.VK_OUT_OF_DEVICE_MEMORY,
            .ERROR_TOO_MANY_OBJECTS => error.VK_TOO_MANY_OBJECTS,
            .ERROR_INVALID_EXTERNAL_HANDLE => error.VK_INVALID_EXTERNAL_HANDLE,
            .ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS => error.VK_INVALID_OPAQUE_CAPTURE_ADDRESS,
            .ERROR_MEMORY_MAP_FAILED => error.VK_MEMORY_MAP_FAILED,
            .ERROR_FRAGMENTED_POOL => error.VK_FRAGMENTED_POOL,
            .ERROR_OUT_OF_POOL_MEMORY => error.VK_OUT_OF_POOL_MEMORY,
            else => error.VK_UNDOCUMENTED_ERROR,
        };
    }

    /// @param[out] pAllocation Handle to allocated memory.
    /// @param[out] pAllocationInfo Optional. Information about allocated memory. It can be later fetched using function GetAllocationInfo().
    ///
    /// You should free the memory using FreeMemory().
    pub fn allocateMemoryForBuffer(allocator: Allocator, buffer: vk.Buffer, createInfo: AllocationCreateInfo) !Allocation {
        return allocateMemoryForBufferAndGetInfo(allocator, buffer, createInfo, null);
    }
    pub fn allocateMemoryForBufferAndGetInfo(allocator: Allocator, buffer: vk.Buffer, createInfo: AllocationCreateInfo, outInfo: ?*AllocationInfo) !Allocation {
        var result: Allocation = undefined;
        const rc = vmaAllocateMemoryForBuffer(allocator, buffer, &createInfo, &result, outInfo);
        if (@enumToInt(rc) >= 0) return result;

        return switch (rc) {
            .ERROR_OUT_OF_HOST_MEMORY => error.VK_OUT_OF_HOST_MEMORY,
            .ERROR_OUT_OF_DEVICE_MEMORY => error.VK_OUT_OF_DEVICE_MEMORY,
            .ERROR_TOO_MANY_OBJECTS => error.VK_TOO_MANY_OBJECTS,
            .ERROR_INVALID_EXTERNAL_HANDLE => error.VK_INVALID_EXTERNAL_HANDLE,
            .ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS => error.VK_INVALID_OPAQUE_CAPTURE_ADDRESS,
            .ERROR_MEMORY_MAP_FAILED => error.VK_MEMORY_MAP_FAILED,
            .ERROR_FRAGMENTED_POOL => error.VK_FRAGMENTED_POOL,
            .ERROR_OUT_OF_POOL_MEMORY => error.VK_OUT_OF_POOL_MEMORY,
            else => error.VK_UNDOCUMENTED_ERROR,
        };
    }

    /// Function similar to AllocateMemoryForBuffer().
    pub fn allocateMemoryForImage(allocator: Allocator, image: vk.Image, createInfo: AllocationCreateInfo) !Allocation {
        return allocateMemoryForImageAndGetInfo(allocator, image, createInfo, null);
    }
    pub fn allocateMemoryForImageAndGetInfo(allocator: Allocator, image: vk.Image, createInfo: AllocationCreateInfo, outInfo: ?*AllocationInfo) !Allocation {
        var result: Allocation = undefined;
        const rc = vmaAllocateMemoryForImage(allocator, image, &createInfo, &result, outInfo);
        if (@enumToInt(rc) >= 0) return result;

        return switch (rc) {
            .ERROR_OUT_OF_HOST_MEMORY => error.VK_OUT_OF_HOST_MEMORY,
            .ERROR_OUT_OF_DEVICE_MEMORY => error.VK_OUT_OF_DEVICE_MEMORY,
            .ERROR_TOO_MANY_OBJECTS => error.VK_TOO_MANY_OBJECTS,
            .ERROR_INVALID_EXTERNAL_HANDLE => error.VK_INVALID_EXTERNAL_HANDLE,
            .ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS => error.VK_INVALID_OPAQUE_CAPTURE_ADDRESS,
            .ERROR_MEMORY_MAP_FAILED => error.VK_MEMORY_MAP_FAILED,
            .ERROR_FRAGMENTED_POOL => error.VK_FRAGMENTED_POOL,
            .ERROR_OUT_OF_POOL_MEMORY => error.VK_OUT_OF_POOL_MEMORY,
            else => error.VK_UNDOCUMENTED_ERROR,
        };
    }

    /// \brief Frees memory previously allocated using AllocateMemory(), AllocateMemoryForBuffer(), or AllocateMemoryForImage().
    ///
    /// Passing `.Null` as `allocation` is valid. Such function call is just skipped.
    /// fn freeMemory(allocator: Allocator, allocation: Allocation) void
    pub const freeMemory = vmaFreeMemory;

    /// \brief Frees memory and destroys multiple allocations.
    ///
    /// Word "pages" is just a suggestion to use this function to free pieces of memory used for sparse binding.
    /// It is just a general purpose function to free memory and destroy allocations made using e.g. AllocateMemory(),
    /// AllocateMemoryPages() and other functions.
    /// It may be internally optimized to be more efficient than calling FreeMemory() `allocationCount` times.
    ///
    /// Allocations in `pAllocations` array can come from any memory pools and types.
    /// Passing `.Null` as elements of `pAllocations` array is valid. Such entries are just skipped.
    pub fn freeMemoryPages(allocator: Allocator, allocations: []Allocation) void {
        vmaFreeMemoryPages(allocator, allocations.len, allocations.ptr);
    }

    /// \brief Returns current information about specified allocation and atomically marks it as used in current frame.
    ///
    /// Current paramters of given allocation are returned in `pAllocationInfo`.
    ///
    /// This function also atomically "touches" allocation - marks it as used in current frame,
    /// just like TouchAllocation().
    /// If the allocation is in lost state, `pAllocationInfo->deviceMemory == .Null`.
    ///
    /// Although this function uses atomics and doesn't lock any mutex, so it should be quite efficient,
    /// you can avoid calling it too often.
    ///
    /// - You can retrieve same AllocationInfo structure while creating your resource, from function
    /// CreateBuffer(), CreateImage(). You can remember it if you are sure parameters don't change
    /// (e.g. due to defragmentation or allocation becoming lost).
    /// - If you just want to check if allocation is not lost, TouchAllocation() will work faster.
    pub fn getAllocationInfo(allocator: Allocator, allocation: Allocation) AllocationInfo {
        var info: AllocationInfo = undefined;
        vmaGetAllocationInfo(allocator, allocation, &info);
        return info;
    }

    /// \brief Returns `true` if allocation is not lost and atomically marks it as used in current frame.
    ///
    /// If the allocation has been created with #.canBecomeLost flag,
    /// this function returns `true` if it's not in lost state, so it can still be used.
    /// It then also atomically "touches" the allocation - marks it as used in current frame,
    /// so that you can be sure it won't become lost in current frame or next `frameInUseCount` frames.
    ///
    /// If the allocation is in lost state, the function returns `false`.
    /// Memory of such allocation, as well as buffer or image bound to it, should not be used.
    /// Lost allocation and the buffer/image still need to be destroyed.
    ///
    /// If the allocation has been created without #.canBecomeLost flag,
    /// this function always returns `true`.
    pub fn touchAllocation(allocator: Allocator, allocation: Allocation) bool {
        return vmaTouchAllocation(allocator, allocation) != 0;
    }

    /// \brief Sets pUserData in given allocation to new value.
    ///
    /// If the allocation was created with VMA_ALLOCATION_CREATE_USER_DATA_COPY_STRING_BIT,
    /// pUserData must be either null, or pointer to a null-terminated string. The function
    /// makes local copy of the string and sets it as allocation's `pUserData`. String
    /// passed as pUserData doesn't need to be valid for whole lifetime of the allocation -
    /// you can free it after this call. String previously pointed by allocation's
    /// pUserData is freed from memory.
    ///
    /// If the flag was not used, the value of pointer `pUserData` is just copied to
    /// allocation's `pUserData`. It is opaque, so you can use it however you want - e.g.
    /// as a pointer, ordinal number or some handle to you own data.
    /// fn setAllocationUserData(allocator: Allocator, allocation: Allocation, pUserData: ?*anyopaque) void
    pub const setAllocationUserData = vmaSetAllocationUserData;

    /// \brief Creates new allocation that is in lost state from the beginning.
    ///
    /// It can be useful if you need a dummy, non-null allocation.
    ///
    /// You still need to destroy created object using FreeMemory().
    ///
    /// Returned allocation is not tied to any specific memory pool or memory type and
    /// not bound to any image or buffer. It has size = 0. It cannot be turned into
    /// a real, non-empty allocation.
    pub fn createLostAllocation(allocator: Allocator) Allocation {
        var allocation: Allocation = undefined;
        vmaCreateLostAllocation(allocator, &allocation);
        return allocation;
    }

    /// \brief Maps memory represented by given allocation and returns pointer to it.
    ///
    /// Maps memory represented by given allocation to make it accessible to CPU code.
    /// When succeeded, `*ppData` contains pointer to first byte of this memory.
    /// If the allocation is part of bigger `vk.DeviceMemory` block, the pointer is
    /// correctly offseted to the beginning of region assigned to this particular
    /// allocation.
    ///
    /// Mapping is internally reference-counted and synchronized, so despite raw Vulkan
    /// function `vkMapMemory()` cannot be used to map same block of `vk.DeviceMemory`
    /// multiple times simultaneously, it is safe to call this function on allocations
    /// assigned to the same memory block. Actual Vulkan memory will be mapped on first
    /// mapping and unmapped on last unmapping.
    ///
    /// If the function succeeded, you must call UnmapMemory() to unmap the
    /// allocation when mapping is no longer needed or before freeing the allocation, at
    /// the latest.
    ///
    /// It also safe to call this function multiple times on the same allocation. You
    /// must call UnmapMemory() same number of times as you called MapMemory().
    ///
    /// It is also safe to call this function on allocation created with
    /// #VMA_ALLOCATION_CREATE_MAPPED_BIT flag. Its memory stays mapped all the time.
    /// You must still call UnmapMemory() same number of times as you called
    /// MapMemory(). You must not call UnmapMemory() additional time to free the
    /// "0-th" mapping made automatically due to #VMA_ALLOCATION_CREATE_MAPPED_BIT flag.
    ///
    /// This function fails when used on allocation made in memory type that is not
    /// `HOST_VISIBLE`.
    ///
    /// This function always fails when called for allocation that was created with
    /// #VMA_ALLOCATION_CREATE_CAN_BECOME_LOST_BIT flag. Such allocations cannot be
    /// mapped.
    ///
    /// This function doesn't automatically flush or invalidate caches.
    /// If the allocation is made from a memory types that is not `HOST_COHERENT`,
    /// you also need to use InvalidateAllocation() / FlushAllocation(), as required by Vulkan specification.
    pub fn mapMemory(allocator: Allocator, allocation: Allocation, comptime T: type) ![*]T {
        var data: *anyopaque = undefined;
        const rc = vmaMapMemory(allocator, allocation, &data);
        if (@enumToInt(rc) >= 0) return @intToPtr([*]T, @ptrToInt(data));
        return error.VK_UNDOCUMENTED_ERROR;
        //return switch (rc) {
        //    .ERROR_OUT_OF_HOST_MEMORY => error.VK_OUT_OF_HOST_MEMORY,
        //    .ERROR_OUT_OF_DEVICE_MEMORY => error.VK_OUT_OF_DEVICE_MEMORY,
        //    .ERROR_MEMORY_MAP_FAILED => error.VK_MEMORY_MAP_FAILED,
        //    else => error.VK_UNDOCUMENTED_ERROR,
        //};
    }

    /// \brief Unmaps memory represented by given allocation, mapped previously using MapMemory().
    ///
    /// For details, see description of MapMemory().
    ///
    /// This function doesn't automatically flush or invalidate caches.
    /// If the allocation is made from a memory types that is not `HOST_COHERENT`,
    /// you also need to use InvalidateAllocation() / FlushAllocation(), as required by Vulkan specification.
    /// fn unmapMemory(self: Allocator, allocation: Allocation) void
    pub const unmapMemory = vmaUnmapMemory;

    /// \brief Flushes memory of given allocation.
    ///
    /// Calls `vkFlushMappedMemoryRanges()` for memory associated with given range of given allocation.
    /// It needs to be called after writing to a mapped memory for memory types that are not `HOST_COHERENT`.
    /// Unmap operation doesn't do that automatically.
    ///
    /// - `offset` must be relative to the beginning of allocation.
    /// - `size` can be `vk.WHOLE_SIZE`. It means all memory from `offset` the the end of given allocation.
    /// - `offset` and `size` don't have to be aligned.
    /// They are internally rounded down/up to multiply of `nonCoherentAtomSize`.
    /// - If `size` is 0, this call is ignored.
    /// - If memory type that the `allocation` belongs to is not `HOST_VISIBLE` or it is `HOST_COHERENT`,
    /// this call is ignored.
    ///
    /// Warning! `offset` and `size` are relative to the contents of given `allocation`.
    /// If you mean whole allocation, you can pass 0 and `vk.WHOLE_SIZE`, respectively.
    /// Do not pass allocation's offset as `offset`!!!
    /// fn flushAllocation(allocator: Allocator, allocation: Allocation, offset: vk.DeviceSize, size: vk.DeviceSize) void
    pub const flushAllocation = vmaFlushAllocation;

    /// \brief Invalidates memory of given allocation.
    ///
    /// Calls `vkInvalidateMappedMemoryRanges()` for memory associated with given range of given allocation.
    /// It needs to be called before reading from a mapped memory for memory types that are not `HOST_COHERENT`.
    /// Map operation doesn't do that automatically.
    ///
    /// - `offset` must be relative to the beginning of allocation.
    /// - `size` can be `vk.WHOLE_SIZE`. It means all memory from `offset` the the end of given allocation.
    /// - `offset` and `size` don't have to be aligned.
    /// They are internally rounded down/up to multiply of `nonCoherentAtomSize`.
    /// - If `size` is 0, this call is ignored.
    /// - If memory type that the `allocation` belongs to is not `HOST_VISIBLE` or it is `HOST_COHERENT`,
    /// this call is ignored.
    ///
    /// Warning! `offset` and `size` are relative to the contents of given `allocation`.
    /// If you mean whole allocation, you can pass 0 and `vk.WHOLE_SIZE`, respectively.
    /// Do not pass allocation's offset as `offset`!!!
    /// fn invalidateAllocation(allocator: Allocator, allocation: Allocation, offset: vk.DeviceSize, size: vk.DeviceSize) void
    pub const invalidateAllocation = vmaInvalidateAllocation;

    /// \brief Checks magic number in margins around all allocations in given memory types (in both default and custom pools) in search for corruptions.
    ///
    /// @param memoryTypeBits Bit mask, where each bit set means that a memory type with that index should be checked.
    ///
    /// Corruption detection is enabled only when `VMA_DEBUG_DETECT_CORRUPTION` macro is defined to nonzero,
    /// `VMA_DEBUG_MARGIN` is defined to nonzero and only for memory types that are
    /// `HOST_VISIBLE` and `HOST_COHERENT`. For more information, see [Corruption detection](@ref debugging_memory_usage_corruption_detection).
    ///
    /// Possible return values:
    ///
    /// - `error.VK_FEATURE_NOT_PRESENT` - corruption detection is not enabled for any of specified memory types.
    /// - `vk.SUCCESS` - corruption detection has been performed and succeeded.
    /// - `error.VK_VALIDATION_FAILED_EXT` - corruption detection has been performed and found memory corruptions around one of the allocations.
    /// `VMA_ASSERT` is also fired in that case.
    /// - Other value: Error returned by Vulkan, e.g. memory mapping failure.
    pub fn checkCorruption(allocator: Allocator, memoryTypeBits: u32) !void {
        const rc = vmaCheckCorruption(allocator, memoryTypeBits);
        if (@enumToInt(rc) >= 0) return;

        return switch (rc) {
            .ERROR_FEATURE_NOT_PRESENT => error.VMA_CORRUPTION_DETECTION_DISABLED,
            .ERROR_VALIDATION_FAILED_EXT => error.VMA_CORRUPTION_DETECTED,
            .ERROR_OUT_OF_HOST_MEMORY => error.VK_OUT_OF_HOST_MEMORY,
            .ERROR_OUT_OF_DEVICE_MEMORY => error.VK_OUT_OF_DEVICE_MEMORY,
            .ERROR_MEMORY_MAP_FAILED => error.VK_MEMORY_MAP_FAILED,
            else => error.VK_UNDOCUMENTED_ERROR,
        };
    }

    /// \brief Begins defragmentation process.
    ///
    /// @param allocator Allocator object.
    /// @param pInfo Structure filled with parameters of defragmentation.
    /// @param[out] pStats Optional. Statistics of defragmentation. You can pass null if you are not interested in this information.
    /// @param[out] pContext Context object that must be passed to DefragmentationEnd() to finish defragmentation.
    /// @return `vk.SUCCESS` and `*pContext == null` if defragmentation finished within this function call. `vk.NOT_READY` and `*pContext != null` if defragmentation has been started and you need to call DefragmentationEnd() to finish it. Negative value in case of error.
    ///
    /// Use this function instead of old, deprecated Defragment().
    ///
    /// Warning! Between the call to DefragmentationBegin() and DefragmentationEnd():
    ///
    /// - You should not use any of allocations passed as `pInfo->pAllocations` or
    ///   any allocations that belong to pools passed as `pInfo->pPools`,
    ///   including calling GetAllocationInfo(), TouchAllocation(), or access
    ///   their data.
    /// - Some mutexes protecting internal data structures may be locked, so trying to
    ///   make or free any allocations, bind buffers or images, map memory, or launch
    ///   another simultaneous defragmentation in between may cause stall (when done on
    ///   another thread) or deadlock (when done on the same thread), unless you are
    ///   100% sure that defragmented allocations are in different pools.
    /// - Information returned via `pStats` and `pInfo->pAllocationsChanged` are undefined.
    ///   They become valid after call to DefragmentationEnd().
    /// - If `pInfo->commandBuffer` is not null, you must submit that command buffer
    ///   and make sure it finished execution before calling DefragmentationEnd().
    ///
    /// For more information and important limitations regarding defragmentation, see documentation chapter:
    /// [Defragmentation](@ref defragmentation).
    pub fn defragmentationBegin(allocator: Allocator, info: DefragmentationInfo2) !DefragmentationContext {
        return defragmentationBeginWithStats(allocator, info, null);
    }
    pub fn defragmentationBeginWithStats(allocator: Allocator, info: DefragmentationInfo2, stats: ?*DefragmentationStats) !DefragmentationContext {
        var context: DefragmentationContext = undefined;
        const rc = vmaDefragmentationBegin(allocator, &info, stats, &context);
        if (@enumToInt(rc) >= 0) return context; // includes NOT_READY
        return switch (rc) {
            .ERROR_OUT_OF_HOST_MEMORY => error.VK_OUT_OF_HOST_MEMORY,
            .ERROR_OUT_OF_DEVICE_MEMORY => error.VK_OUT_OF_DEVICE_MEMORY,
            .ERROR_TOO_MANY_OBJECTS => error.VK_TOO_MANY_OBJECTS,
            .ERROR_INVALID_EXTERNAL_HANDLE => error.VK_INVALID_EXTERNAL_HANDLE,
            .ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS => error.VK_INVALID_OPAQUE_CAPTURE_ADDRESS,
            .ERROR_MEMORY_MAP_FAILED => error.VK_MEMORY_MAP_FAILED,
            .ERROR_FRAGMENTED_POOL => error.VK_FRAGMENTED_POOL,
            .ERROR_OUT_OF_POOL_MEMORY => error.VK_OUT_OF_POOL_MEMORY,
            else => error.VK_UNDOCUMENTED_ERROR,
        };
    }

    /// \brief Ends defragmentation process.
    ///
    /// Use this function to finish defragmentation started by DefragmentationBegin().
    /// It is safe to pass `context == null`. The function then does nothing.
    pub fn defragmentationEnd(allocator: Allocator, context: DefragmentationContext) !void {
        const rc = vmaDefragmentationEnd(allocator, context);
        if (@enumToInt(rc) >= 0) return;
        return switch (rc) {
            .ERROR_OUT_OF_HOST_MEMORY => error.VK_OUT_OF_HOST_MEMORY,
            .ERROR_OUT_OF_DEVICE_MEMORY => error.VK_OUT_OF_DEVICE_MEMORY,
            .ERROR_TOO_MANY_OBJECTS => error.VK_TOO_MANY_OBJECTS,
            .ERROR_INVALID_EXTERNAL_HANDLE => error.VK_INVALID_EXTERNAL_HANDLE,
            .ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS => error.VK_INVALID_OPAQUE_CAPTURE_ADDRESS,
            .ERROR_MEMORY_MAP_FAILED => error.VK_MEMORY_MAP_FAILED,
            .ERROR_FRAGMENTED_POOL => error.VK_FRAGMENTED_POOL,
            .ERROR_OUT_OF_POOL_MEMORY => error.VK_OUT_OF_POOL_MEMORY,
            else => error.VK_UNDOCUMENTED_ERROR,
        };
    }

    /// \brief Binds buffer to allocation.
    ///
    /// Binds specified buffer to region of memory represented by specified allocation.
    /// Gets `vk.DeviceMemory` handle and offset from the allocation.
    /// If you want to create a buffer, allocate memory for it and bind them together separately,
    /// you should use this function for binding instead of standard `vkBindBufferMemory()`,
    /// because it ensures proper synchronization so that when a `vk.DeviceMemory` object is used by multiple
    /// allocations, calls to `vkBind*Memory()` or `vkMapMemory()` won't happen from multiple threads simultaneously
    /// (which is illegal in Vulkan).
    ///
    /// It is recommended to use function createBuffer() instead of this one.
    pub fn bindBufferMemory(allocator: Allocator, allocation: Allocation, buffer: vk.Buffer) !void {
        const rc = vmaBindBufferMemory(allocator, allocation, buffer);
        if (@enumToInt(rc) >= 0) return;
        return switch (rc) {
            .ERROR_OUT_OF_HOST_MEMORY => error.VK_OUT_OF_HOST_MEMORY,
            .ERROR_OUT_OF_DEVICE_MEMORY => error.VK_OUT_OF_DEVICE_MEMORY,
            .ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS => error.VK_INVALID_OPAQUE_CAPTURE_ADDRESS,
            else => error.VK_UNDOCUMENTED_ERROR,
        };
    }

    /// \brief Binds buffer to allocation with additional parameters.
    ///
    /// @param allocationLocalOffset Additional offset to be added while binding, relative to the beginnig of the `allocation`. Normally it should be 0.
    /// @param pNext A chain of structures to be attached to `vk.BindBufferMemoryInfoKHR` structure used internally. Normally it should be null.
    ///
    /// This function is similar to BindBufferMemory(), but it provides additional parameters.
    ///
    /// If `pNext` is not null, #Allocator object must have been created with #VMA_ALLOCATOR_CREATE_KHR_BIND_MEMORY2_BIT flag
    /// or with AllocatorCreateInfo::vulkanApiVersion `== vk.API_VERSION_1_1`. Otherwise the call fails.
    pub fn bindBufferMemory2(allocator: Allocator, allocation: Allocation, allocationLocalOffset: vk.DeviceSize, buffer: vk.Buffer, pNext: ?*const anyopaque) !void {
        const rc = vmaBindBufferMemory2(allocator, allocation, allocationLocalOffset, buffer, pNext);
        if (@enumToInt(rc) >= 0) return;
        return switch (rc) {
            .ERROR_OUT_OF_HOST_MEMORY => error.VK_OUT_OF_HOST_MEMORY,
            .ERROR_OUT_OF_DEVICE_MEMORY => error.VK_OUT_OF_DEVICE_MEMORY,
            .ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS => error.VK_INVALID_OPAQUE_CAPTURE_ADDRESS,
            else => error.VK_UNDOCUMENTED_ERROR,
        };
    }

    /// \brief Binds image to allocation.
    ///
    /// Binds specified image to region of memory represented by specified allocation.
    /// Gets `vk.DeviceMemory` handle and offset from the allocation.
    /// If you want to create an image, allocate memory for it and bind them together separately,
    /// you should use this function for binding instead of standard `vkBindImageMemory()`,
    /// because it ensures proper synchronization so that when a `vk.DeviceMemory` object is used by multiple
    /// allocations, calls to `vkBind*Memory()` or `vkMapMemory()` won't happen from multiple threads simultaneously
    /// (which is illegal in Vulkan).
    ///
    /// It is recommended to use function CreateImage() instead of this one.
    pub fn bindImageMemory(allocator: Allocator, allocation: Allocation, image: vk.Image) !void {
        const rc = vmaBindImageMemory(allocator, allocation, image);
        if (@enumToInt(rc) >= 0) return;
        return switch (rc) {
            .ERROR_OUT_OF_HOST_MEMORY => error.VK_OUT_OF_HOST_MEMORY,
            .ERROR_OUT_OF_DEVICE_MEMORY => error.VK_OUT_OF_DEVICE_MEMORY,
            else => error.VK_UNDOCUMENTED_ERROR,
        };
    }

    /// \brief Binds image to allocation with additional parameters.
    ///
    /// @param allocationLocalOffset Additional offset to be added while binding, relative to the beginnig of the `allocation`. Normally it should be 0.
    /// @param pNext A chain of structures to be attached to `vk.BindImageMemoryInfoKHR` structure used internally. Normally it should be null.
    ///
    /// This function is similar to BindImageMemory(), but it provides additional parameters.
    ///
    /// If `pNext` is not null, #Allocator object must have been created with #VMA_ALLOCATOR_CREATE_KHR_BIND_MEMORY2_BIT flag
    /// or with AllocatorCreateInfo::vulkanApiVersion `== vk.API_VERSION_1_1`. Otherwise the call fails.
    pub fn bindImageMemory2(allocator: Allocator, allocation: Allocation, allocationLocalOffset: vk.DeviceSize, image: vk.Image, pNext: ?*const anyopaque) !void {
        const rc = vmaBindImageMemory2(allocator, allocation, allocationLocalOffset, image, pNext);
        if (@enumToInt(rc) >= 0) return;
        return switch (rc) {
            .ERROR_OUT_OF_HOST_MEMORY => error.VK_OUT_OF_HOST_MEMORY,
            .ERROR_OUT_OF_DEVICE_MEMORY => error.VK_OUT_OF_DEVICE_MEMORY,
            .ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS => error.VK_INVALID_OPAQUE_CAPTURE_ADDRESS,
            else => error.VK_UNDOCUMENTED_ERROR,
        };
    }

    /// @param[out] pBuffer Buffer that was created.
    /// @param[out] pAllocation Allocation that was created.
    /// @param[out] pAllocationInfo Optional. Information about allocated memory. It can be later fetched using function GetAllocationInfo().
    ///
    /// This function automatically:
    ///
    /// -# Creates buffer.
    /// -# Allocates appropriate memory for it.
    /// -# Binds the buffer with the memory.
    ///
    /// If any of these operations fail, buffer and allocation are not created,
    /// returned value is negative error code, *pBuffer and *pAllocation are null.
    ///
    /// If the function succeeded, you must destroy both buffer and allocation when you
    /// no longer need them using either convenience function DestroyBuffer() or
    /// separately, using `vkDestroyBuffer()` and FreeMemory().
    ///
    /// If VMA_ALLOCATOR_CREATE_KHR_DEDICATED_ALLOCATION_BIT flag was used,
    /// vk.KHR_dedicated_allocation extension is used internally to query driver whether
    /// it requires or prefers the new buffer to have dedicated allocation. If yes,
    /// and if dedicated allocation is possible (AllocationCreateInfo::pool is null
    /// and VMA_ALLOCATION_CREATE_NEVER_ALLOCATE_BIT is not used), it creates dedicated
    /// allocation for this buffer, just like when using
    /// VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT.
    pub fn createBuffer(
        allocator: Allocator,
        bufferCreateInfo: vk.BufferCreateInfo,
        allocationCreateInfo: AllocationCreateInfo,
    ) !CreateBufferResult {
        return createBufferAndGetInfo(allocator, bufferCreateInfo, allocationCreateInfo, null);
    }
    pub fn createBufferAndGetInfo(
        allocator: Allocator,
        bufferCreateInfo: vk.BufferCreateInfo,
        allocationCreateInfo: AllocationCreateInfo,
        outInfo: ?*AllocationInfo,
    ) !CreateBufferResult {
        var result: CreateBufferResult = undefined;
        const rc = vmaCreateBuffer(
            allocator,
            &bufferCreateInfo,
            &allocationCreateInfo,
            &result.buffer,
            &result.allocation,
            outInfo,
        );
        if (@enumToInt(rc) >= 0) return result;
        return error.VK_UNDOCUMENTED_ERROR;
        //switch (rc) {
        //.ERROR_OUT_OF_HOST_MEMORY => error.VK_OUT_OF_HOST_MEMORY,
        //.ERROR_OUT_OF_DEVICE_MEMORY => error.VK_OUT_OF_DEVICE_MEMORY,
        //.ERROR_TOO_MANY_OBJECTS => error.VK_TOO_MANY_OBJECTS,
        //.ERROR_INVALID_EXTERNAL_HANDLE => error.VK_INVALID_EXTERNAL_HANDLE,
        //.ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS => error.VK_INVALID_OPAQUE_CAPTURE_ADDRESS,
        //.ERROR_MEMORY_MAP_FAILED => error.VK_MEMORY_MAP_FAILED,
        //.ERROR_FRAGMENTED_POOL => error.VK_FRAGMENTED_POOL,
        //.ERROR_OUT_OF_POOL_MEMORY => error.VK_OUT_OF_POOL_MEMORY,
        //else => error.VK_UNDOCUMENTED_ERROR,
        //};
    }
    pub const CreateBufferResult = struct {
        buffer: vk.Buffer,
        allocation: Allocation,
    };

    /// \brief Destroys Vulkan buffer and frees allocated memory.
    ///
    /// This is just a convenience function equivalent to:
    ///
    /// \code
    /// vkDestroyBuffer(device, buffer, allocationCallbacks);
    /// FreeMemory(allocator, allocation);
    /// \endcode
    ///
    /// It it safe to pass null as buffer and/or allocation.
    /// fn destroyBuffer(allocator: Allocator, buffer: vk.Buffer, allocation: Allocation) void
    pub const destroyBuffer = vmaDestroyBuffer;

    /// Function similar to CreateBuffer().
    pub fn createImage(
        allocator: Allocator,
        imageCreateInfo: vk.ImageCreateInfo,
        allocationCreateInfo: AllocationCreateInfo,
    ) !CreateImageResult {
        return createImageAndGetInfo(allocator, imageCreateInfo, allocationCreateInfo, null);
    }
    pub fn createImageAndGetInfo(
        allocator: Allocator,
        imageCreateInfo: vk.ImageCreateInfo,
        allocationCreateInfo: AllocationCreateInfo,
        outInfo: ?*AllocationInfo,
    ) !CreateImageResult {
        var result: CreateImageResult = undefined;
        const rc = vmaCreateImage(
            allocator,
            &imageCreateInfo,
            &allocationCreateInfo,
            &result.image,
            &result.allocation,
            outInfo,
        );
        if (@enumToInt(rc) >= 0) return result;
        return error.VK_UNDOCUMENTED_ERROR;
        //return switch (rc) {
        //    .ERROR_OUT_OF_HOST_MEMORY => error.VK_OUT_OF_HOST_MEMORY,
        //    .ERROR_OUT_OF_DEVICE_MEMORY => error.VK_OUT_OF_DEVICE_MEMORY,
        //    .ERROR_TOO_MANY_OBJECTS => error.VK_TOO_MANY_OBJECTS,
        //    .ERROR_INVALID_EXTERNAL_HANDLE => error.VK_INVALID_EXTERNAL_HANDLE,
        //    .ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS => error.VK_INVALID_OPAQUE_CAPTURE_ADDRESS,
        //    .ERROR_MEMORY_MAP_FAILED => error.VK_MEMORY_MAP_FAILED,
        //    .ERROR_FRAGMENTED_POOL => error.VK_FRAGMENTED_POOL,
        //    .ERROR_OUT_OF_POOL_MEMORY => error.VK_OUT_OF_POOL_MEMORY,
        //    else => error.VK_UNDOCUMENTED_ERROR,
        //};
    }
    pub const CreateImageResult = struct {
        image: vk.Image,
        allocation: Allocation,
    };

    /// \brief Destroys Vulkan image and frees allocated memory.
    ///
    /// This is just a convenience function equivalent to:
    ///
    /// \code
    /// vkDestroyImage(device, image, allocationCallbacks);
    /// FreeMemory(allocator, allocation);
    /// \endcode
    ///
    /// It is safe to pass null as image and/or allocation.
    /// fn destroyImage(self: Allocator, image: vk.Image, allocation: Allocation) void
    pub const destroyImage = vmaDestroyImage;
};

/// Callback function called after successful vkAllocateMemory.
pub const PfnAllocateDeviceMemoryFunction = *const fn (
    allocator: Allocator,
    memoryType: u32,
    memory: vk.DeviceMemory,
    size: vk.DeviceSize,
) callconv(vulkan_call_conv) void;

/// Callback function called before vkFreeMemory.
pub const PfnFreeDeviceMemoryFunction = *const fn (
    allocator: Allocator,
    memoryType: u32,
    memory: vk.DeviceMemory,
    size: vk.DeviceSize,
) callconv(vulkan_call_conv) void;

/// \brief Set of callbacks that the library will call for `vkAllocateMemory` and `vkFreeMemory`.
///
/// Provided for informative purpose, e.g. to gather statistics about number of
/// allocations or total amount of memory allocated in Vulkan.
///
/// Used in AllocatorCreateInfo::pDeviceMemoryCallbacks.
pub const DeviceMemoryCallbacks = extern struct {
    pfnAllocate: ?PfnAllocateDeviceMemoryFunction,
    pfnFree: ?PfnFreeDeviceMemoryFunction,
};

/// Flags for created #Allocator.
pub const AllocatorCreateFlags = packed struct {
    /// \brief Allocator and all objects created from it will not be synchronized internally, so you must guarantee they are used from only one thread at a time or synchronized externally by you.
    ///
    /// Using this flag may increase performance because internal mutexes are not used.
    externallySynchronized: bool = false,

    /// \brief Enables usage of vk.KHR_dedicated_allocation extension.
    ///
    /// The flag works only if AllocatorCreateInfo::vulkanApiVersion `== vk.API_VERSION_1_0`.
    /// When it's `vk.API_VERSION_1_1`, the flag is ignored because the extension has been promoted to Vulkan 1.1.
    ///
    /// Using this extenion will automatically allocate dedicated blocks of memory for
    /// some buffers and images instead of suballocating place for them out of bigger
    /// memory blocks (as if you explicitly used #VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT
    /// flag) when it is recommended by the driver. It may improve performance on some
    /// GPUs.
    ///
    /// You may set this flag only if you found out that following device extensions are
    /// supported, you enabled them while creating Vulkan device passed as
    /// AllocatorCreateInfo::device, and you want them to be used internally by this
    /// library:
    ///
    /// - vk.KHR_get_memory_requirements2 (device extension)
    /// - vk.KHR_dedicated_allocation (device extension)
    ///
    /// When this flag is set, you can experience following warnings reported by Vulkan
    /// validation layer. You can ignore them.
    ///
    /// > vkBindBufferMemory(): Binding memory to buffer 0x2d but vkGetBufferMemoryRequirements() has not been called on that buffer.
    dedicatedAllocationKHR: bool = false,

    /// Enables usage of vk.KHR_bind_memory2 extension.
    ///
    /// The flag works only if AllocatorCreateInfo::vulkanApiVersion `== vk.API_VERSION_1_0`.
    /// When it's `vk.API_VERSION_1_1`, the flag is ignored because the extension has been promoted to Vulkan 1.1.
    ///
    /// You may set this flag only if you found out that this device extension is supported,
    /// you enabled it while creating Vulkan device passed as AllocatorCreateInfo::device,
    /// and you want it to be used internally by this library.
    ///
    /// The extension provides functions `vkBindBufferMemory2KHR` and `vkBindImageMemory2KHR`,
    /// which allow to pass a chain of `pNext` structures while binding.
    /// This flag is required if you use `pNext` parameter in BindBufferMemory2() or BindImageMemory2().
    bindMemory2KHR: bool = false,

    /// Enables usage of vk.EXT_memory_budget extension.
    ///
    /// You may set this flag only if you found out that this device extension is supported,
    /// you enabled it while creating Vulkan device passed as AllocatorCreateInfo::device,
    /// and you want it to be used internally by this library, along with another instance extension
    /// vk.KHR_get_physical_device_properties2, which is required by it (or Vulkan 1.1, where this extension is promoted).
    ///
    /// The extension provides query for current memory usage and budget, which will probably
    /// be more accurate than an estimation used by the library otherwise.
    memoryBudgetEXT: bool = false,

    __reserved_bits_04_31: u28 = 0,

    pub usingnamespace vk.FlagsMixin(@This(), vk.Flags);
};

/// \brief Pointers to some Vulkan functions - a subset used by the library.
///
/// Used in AllocatorCreateInfo::pVulkanFunctions.
pub const VulkanFunctions = extern struct {
    vkGetPhysicalDeviceProperties: vk.PfnGetPhysicalDeviceProperties,
    vkGetPhysicalDeviceMemoryProperties: vk.PfnGetPhysicalDeviceMemoryProperties,
    vkAllocateMemory: vk.PfnAllocateMemory,
    vkFreeMemory: vk.PfnFreeMemory,
    vkMapMemory: vk.PfnMapMemory,
    vkUnmapMemory: vk.PfnUnmapMemory,
    vkFlushMappedMemoryRanges: vk.PfnFlushMappedMemoryRanges,
    vkInvalidateMappedMemoryRanges: vk.PfnInvalidateMappedMemoryRanges,
    vkBindBufferMemory: vk.PfnBindBufferMemory,
    vkBindImageMemory: vk.PfnBindImageMemory,
    vkGetBufferMemoryRequirements: vk.PfnGetBufferMemoryRequirements,
    vkGetImageMemoryRequirements: vk.PfnGetImageMemoryRequirements,
    vkCreateBuffer: vk.PfnCreateBuffer,
    vkDestroyBuffer: vk.PfnDestroyBuffer,
    vkCreateImage: vk.PfnCreateImage,
    vkDestroyImage: vk.PfnDestroyImage,
    vkCmdCopyBuffer: vk.PfnCmdCopyBuffer,

    dedicatedAllocation: if (config.dedicatedAllocation or config.vulkanVersion >= 1001000) DedicatedAllocationFunctions else void,
    bindMemory2: if (config.bindMemory2 or config.vulkanVersion >= 1001000) BindMemory2Functions else void,
    memoryBudget: if (config.memoryBudget or config.vulkanVersion >= 1001000) MemoryBudgetFunctions else void,

    const DedicatedAllocationFunctions = extern struct {
        vkGetBufferMemoryRequirements2: vk.PfnGetBufferMemoryRequirements2,
        vkGetImageMemoryRequirements2: vk.PfnGetImageMemoryRequirements2,
    };
    const BindMemory2Functions = extern struct {
        vkBindBufferMemory2: vk.PfnBindBufferMemory2,
        vkBindImageMemory2: vk.PfnBindImageMemory2,
    };
    const MemoryBudgetFunctions = extern struct {
        vkGetPhysicalDeviceMemoryProperties2: vk.PfnGetPhysicalDeviceMemoryProperties2,
    };

    fn isDeviceFunc(comptime FuncType: type) bool {
        comptime {
            const info = @typeInfo(@typeInfo(FuncType).Pointer.child).Fn;
            if (info.args.len == 0) return false;
            const arg0 = info.args[0].arg_type;
            return arg0 == vk.Device or arg0 == vk.Queue or arg0 == vk.CommandBuffer;
        }
    }

    fn loadRecursive(
        comptime T: type,
        inst: vk.Instance,
        device: vk.Device,
        vkGetInstanceProcAddr: *const fn (vk.Instance, [*:0]const u8) callconv(vk.vulkan_call_conv) vk.PfnVoidFunction,
        vkGetDeviceProcAddr: *const fn (vk.Device, [*:0]const u8) callconv(vulkan_call_conv) vk.PfnVoidFunction,
    ) T {
        if (@typeInfo(T) != .Struct) return undefined;
        var value: T = undefined;
        inline for (@typeInfo(T).Struct.fields) |field| {
            if (comptime std.mem.startsWith(u8, field.name, "vk")) {
                if (comptime isDeviceFunc(field.field_type)) {
                    const func = vkGetDeviceProcAddr(device, @ptrCast([*:0]const u8, field.name.ptr));
                    const resolved = func orelse @panic("Couldn't fetch vk device function " ++ field.name);
                    @field(value, field.name) = @ptrCast(field.field_type, resolved);
                } else {
                    const func = vkGetInstanceProcAddr(inst, @ptrCast([*:0]const u8, field.name.ptr));
                    const resolved = func orelse @panic("Couldn't fetch vk instance function " ++ field.name);
                    @field(value, field.name) = @ptrCast(field.field_type, resolved);
                }
            } else {
                @field(value, field.name) = loadRecursive(field.field_type, inst, device, vkGetInstanceProcAddr, vkGetDeviceProcAddr);
            }
        }
        return value;
    }

    pub fn init(
        inst: vk.Instance,
        device: vk.Device,
        vkGetInstanceProcAddr: *const fn (vk.Instance, [*:0]const u8) callconv(vulkan_call_conv) vk.PfnVoidFunction,
    ) VulkanFunctions {
        const vkGetDeviceProcAddrPtr = vkGetInstanceProcAddr(inst, "vkGetDeviceProcAddr") orelse @panic("Couldn't fetch vkGetDeviceProcAddr: vkGetInstanceProcAddr returned null.");
        const vkGetDeviceProcAddr = @ptrCast(*const fn (vk.Device, [*:0]const u8) callconv(vulkan_call_conv) vk.PfnVoidFunction, vkGetDeviceProcAddrPtr);
        return loadRecursive(VulkanFunctions, inst, device, vkGetInstanceProcAddr, vkGetDeviceProcAddr);
    }
};

/// Flags to be used in RecordSettings::flags.
pub const RecordFlags = packed struct {
    /// \brief Enables flush after recording every function call.
    ///
    /// Enable it if you expect your application to crash, which may leave recording file truncated.
    /// It may degrade performance though.
    flushAfterCall: bool = false,

    __reserved_bits_01_31: u31 = 0,

    pub usingnamespace vk.FlagsMixin(@This(), vk.Flags);
};

/// Parameters for recording calls to VMA functions. To be used in AllocatorCreateInfo::pRecordSettings.
pub const RecordSettings = extern struct {
    /// Flags for recording. Use #RecordFlagBits enum.
    flags: RecordFlags = .{},
    /// \brief Path to the file that should be written by the recording.
    ///
    /// Suggested extension: "csv".
    /// If the file already exists, it will be overwritten.
    /// It will be opened for the whole time #Allocator object is alive.
    /// If opening this file fails, creation of the whole allocator object fails.
    pFilePath: [*:0]const u8,
};

/// Description of a Allocator to be created.
pub const AllocatorCreateInfo = extern struct {
    /// Flags for created allocator. Use #AllocatorCreateFlagBits enum.
    flags: AllocatorCreateFlags align(4) = .{},
    /// Vulkan physical device.
    /// It must be valid throughout whole lifetime of created allocator.
    physicalDevice: vk.PhysicalDevice,
    /// Vulkan device.
    /// It must be valid throughout whole lifetime of created allocator.
    device: vk.Device,
    /// Preferred size of a single `vk.DeviceMemory` block to be allocated from large heaps > 1 GiB. Optional.
    /// Set to 0 to use default, which is currently 256 MiB.
    preferredLargeHeapBlockSize: vk.DeviceSize = 0,
    /// Custom CPU memory allocation callbacks. Optional.
    /// Optional, can be null. When specified, will also be used for all CPU-side memory allocations.
    pAllocationCallbacks: ?*const vk.AllocationCallbacks = null,
    /// Informative callbacks for `vkAllocateMemory`, `vkFreeMemory`. Optional.
    /// Optional, can be null.
    pDeviceMemoryCallbacks: ?*const DeviceMemoryCallbacks = null,
    /// \brief Maximum number of additional frames that are in use at the same time as current frame.
    ///
    /// This value is used only when you make allocations with
    /// .canBeLost = true. Such allocation cannot become
    /// lost if allocation.lastUseFrameIndex >= allocator.currentFrameIndex - frameInUseCount.
    ///
    /// For example, if you double-buffer your command buffers, so resources used for
    /// rendering in previous frame may still be in use by the GPU at the moment you
    /// allocate resources needed for the current frame, set this value to 1.
    ///
    /// If you want to allow any allocations other than used in the current frame to
    /// become lost, set this value to 0.
    frameInUseCount: u32,
    /// \brief Either null or a pointer to an array of limits on maximum number of bytes that can be allocated out of particular Vulkan memory heap.
    ///
    /// If not NULL, it must be a pointer to an array of
    /// `vk.PhysicalDeviceMemoryProperties::memoryHeapCount` elements, defining limit on
    /// maximum number of bytes that can be allocated out of particular Vulkan memory
    /// heap.
    ///
    /// Any of the elements may be equal to `vk.WHOLE_SIZE`, which means no limit on that
    /// heap. This is also the default in case of `pHeapSizeLimit` = NULL.
    ///
    /// If there is a limit defined for a heap:
    ///
    /// - If user tries to allocate more memory from that heap using this allocator,
    /// the allocation fails with `error.VK_OUT_OF_DEVICE_MEMORY`.
    /// - If the limit is smaller than heap size reported in `vk.MemoryHeap::size`, the
    /// value of this limit will be reported instead when using GetMemoryProperties().
    ///
    /// Warning! Using this feature may not be equivalent to installing a GPU with
    /// smaller amount of memory, because graphics driver doesn't necessary fail new
    /// allocations with `error.VK_OUT_OF_DEVICE_MEMORY` result when memory capacity is
    /// exceeded. It may return success and just silently migrate some device memory
    /// blocks to system RAM. This driver behavior can also be controlled using
    /// vk.AMD_memory_overallocation_behavior extension.
    pHeapSizeLimit: ?[*]const vk.DeviceSize = null,
    /// \brief Pointers to Vulkan functions. Can be null if you leave define `VMA_STATIC_VULKAN_FUNCTIONS 1`.
    ///
    /// If you leave define `VMA_STATIC_VULKAN_FUNCTIONS 1` in configuration section,
    /// you can pass null as this member, because the library will fetch pointers to
    /// Vulkan functions internally in a static way, like:
    ///
    /// vulkanFunctions.vkAllocateMemory = &vkAllocateMemory;
    ///
    /// Fill this member if you want to provide your own pointers to Vulkan functions,
    /// e.g. fetched using `vkGetInstanceProcAddr()` and `vkGetDeviceProcAddr()`.
    pVulkanFunctions: ?*const VulkanFunctions = null,
    /// \brief Parameters for recording of VMA calls. Can be null.
    ///
    /// If not null, it enables recording of calls to VMA functions to a file.
    /// If support for recording is not enabled using `VMA_RECORDING_ENABLED` macro,
    /// creation of the allocator object fails with `error.VK_FEATURE_NOT_PRESENT`.
    pRecordSettings: ?*const RecordSettings = null,
    /// \brief Optional handle to Vulkan instance object.
    ///
    /// Optional, can be null. Must be set if #VMA_ALLOCATOR_CREATE_EXT_MEMORY_BUDGET_BIT flas is used
    /// or if `vulkanApiVersion >= vk.MAKE_VERSION(1, 1, 0)`.
    instance: vk.Instance,
    /// \brief Optional. The highest version of Vulkan that the application is designed to use.
    ///
    /// It must be a value in the format as created by macro `vk.MAKE_VERSION` or a constant like: `vk.API_VERSION_1_1`, `vk.API_VERSION_1_0`.
    /// The patch version number specified is ignored. Only the major and minor versions are considered.
    /// It must be less or euqal (preferably equal) to value as passed to `vkCreateInstance` as `vk.ApplicationInfo::apiVersion`.
    /// Only versions 1.0 and 1.1 are supported by the current implementation.
    /// Leaving it initialized to zero is equivalent to `vk.API_VERSION_1_0`.
    vulkanApiVersion: u32 = 0,
};

/// \brief Calculated statistics of memory usage in entire allocator.
pub const StatInfo = extern struct {
    /// Number of `vk.DeviceMemory` Vulkan memory blocks allocated.
    blockCount: u32,
    /// Number of #Allocation allocation objects allocated.
    allocationCount: u32,
    /// Number of free ranges of memory between allocations.
    unusedRangeCount: u32,
    /// Total number of bytes occupied by all allocations.
    usedBytes: vk.DeviceSize,
    /// Total number of bytes occupied by unused ranges.
    unusedBytes: vk.DeviceSize,

    allocationSizeMin: vk.DeviceSize,
    allocationSizeAvg: vk.DeviceSize,
    allocationSizeMax: vk.DeviceSize,
    unusedRangeSizeMin: vk.DeviceSize,
    unusedRangeSizeAvg: vk.DeviceSize,
    unusedRangeSizeMax: vk.DeviceSize,
};

/// General statistics from current state of Allocator.
pub const Stats = extern struct {
    memoryType: [vk.MAX_MEMORY_TYPES]StatInfo,
    memoryHeap: [vk.MAX_MEMORY_HEAPS]StatInfo,
    total: StatInfo,
};

/// \brief Statistics of current memory usage and available budget, in bytes, for specific memory heap.
pub const Budget = extern struct {
    /// \brief Sum size of all `vk.DeviceMemory` blocks allocated from particular heap, in bytes.
    blockBytes: vk.DeviceSize,

    /// \brief Sum size of all allocations created in particular heap, in bytes.
    ///
    /// Usually less or equal than `blockBytes`.
    /// Difference `blockBytes - allocationBytes` is the amount of memory allocated but unused -
    /// available for new allocations or wasted due to fragmentation.
    ///
    /// It might be greater than `blockBytes` if there are some allocations in lost state, as they account
    /// to this value as well.
    allocationBytes: vk.DeviceSize,

    /// \brief Estimated current memory usage of the program, in bytes.
    ///
    /// Fetched from system using `vk.EXT_memory_budget` extension if enabled.
    ///
    /// It might be different than `blockBytes` (usually higher) due to additional implicit objects
    /// also occupying the memory, like swapchain, pipelines, descriptor heaps, command buffers, or
    /// `vk.DeviceMemory` blocks allocated outside of this library, if any.
    usage: vk.DeviceSize,

    /// \brief Estimated amount of memory available to the program, in bytes.
    ///
    /// Fetched from system using `vk.EXT_memory_budget` extension if enabled.
    ///
    /// It might be different (most probably smaller) than `vk.MemoryHeap::size[heapIndex]` due to factors
    /// external to the program, like other programs also consuming system resources.
    /// Difference `budget - usage` is the amount of additional memory that can probably
    /// be allocated without problems. Exceeding the budget may result in various problems.
    budget: vk.DeviceSize,
};

/// \struct Pool
/// \brief Represents custom memory pool
///
/// Fill structure PoolCreateInfo and call function CreatePool() to create it.
/// Call function DestroyPool() to destroy it.
///
/// For more information see [Custom memory pools](@ref choosing_memory_type_custom_memory_pools).
pub const Pool = enum(usize) { Null = 0, _ };

pub const MemoryUsage = enum(u32) {
    /// No intended memory usage specified.
    /// Use other members of AllocationCreateInfo to specify your requirements.
    unknown = 0,
    /// Memory will be used on device only, so fast access from the device is preferred.
    /// It usually means device-local GPU (video) memory.
    /// No need to be mappable on host.
    /// It is roughly equivalent of `D3D12_HEAP_TYPE_DEFAULT`.
    ///
    /// Usage:
    ///
    /// - Resources written and read by device, e.g. images used as attachments.
    /// - Resources transferred from host once (immutable) or infrequently and read by
    /// device multiple times, e.g. textures to be sampled, vertex buffers, uniform
    /// (constant) buffers, and majority of other types of resources used on GPU.
    ///
    /// Allocation may still end up in `HOST_VISIBLE` memory on some implementations.
    /// In such case, you are free to map it.
    /// You can use #VMA_ALLOCATION_CREATE_MAPPED_BIT with this usage type.
    gpuOnly = 1,
    /// Memory will be mappable on host.
    /// It usually means CPU (system) memory.
    /// Guarantees to be `HOST_VISIBLE` and `HOST_COHERENT`.
    /// CPU access is typically uncached. Writes may be write-combined.
    /// Resources created in this pool may still be accessible to the device, but access to them can be slow.
    /// It is roughly equivalent of `D3D12_HEAP_TYPE_UPLOAD`.
    ///
    /// Usage: Staging copy of resources used as transfer source.
    cpuOnly = 2,
    /// Memory that is both mappable on host (guarantees to be `HOST_VISIBLE`) and preferably fast to access by GPU.
    /// CPU access is typically uncached. Writes may be write-combined.
    ///
    /// Usage: Resources written frequently by host (dynamic), read by device. E.g. textures, vertex buffers, uniform buffers updated every frame or every draw call.
    cpuToGpu = 3,
    /// Memory mappable on host (guarantees to be `HOST_VISIBLE`) and cached.
    /// It is roughly equivalent of `D3D12_HEAP_TYPE_READBACK`.
    ///
    /// Usage:
    ///
    /// - Resources written by device, read by host - results of some computations, e.g. screen capture, average scene luminance for HDR tone mapping.
    /// - Any resources read or accessed randomly on host, e.g. CPU-side copy of vertex buffer used as source of transfer, but also used for collision detection.
    gpuToCpu = 4,
    /// CPU memory - memory that is preferably not `DEVICE_LOCAL`, but also not guaranteed to be `HOST_VISIBLE`.
    ///
    /// Usage: Staging copy of resources moved from GPU memory to CPU memory as part
    /// of custom paging/residency mechanism, to be moved back to GPU memory when needed.
    cpuCopy = 5,
    /// Lazily allocated GPU memory having `vk.MEMORY_PROPERTY_LAZILY_ALLOCATED_BIT`.
    /// Exists mostly on mobile platforms. Using it on desktop PC or other GPUs with no such memory type present will fail the allocation.
    ///
    /// Usage: Memory for transient attachment images (color attachments, depth attachments etc.), created with `vk.IMAGE_USAGE_TRANSIENT_ATTACHMENT_BIT`.
    ///
    /// Allocations with this usage are always created as dedicated - it implies #VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT.
    gpuLazilyAllocated = 6,
};

/// Flags to be passed as AllocationCreateInfo::flags.
pub const AllocationCreateFlags = packed struct {
    /// \brief Set this flag if the allocation should have its own memory block.
    ///
    /// Use it for special, big resources, like fullscreen images used as attachments.
    ///
    /// You should not use this flag if AllocationCreateInfo::pool is not null.
    dedicatedMemory: bool = false,

    /// \brief Set this flag to only try to allocate from existing `vk.DeviceMemory` blocks and never create new such block.
    ///
    /// If new allocation cannot be placed in any of the existing blocks, allocation
    /// fails with `error.VK_OUT_OF_DEVICE_MEMORY` error.
    ///
    /// You should not use #VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT and
    /// #VMA_ALLOCATION_CREATE_NEVER_ALLOCATE_BIT at the same time. It makes no sense.
    ///
    /// If AllocationCreateInfo::pool is not null, this flag is implied and ignored. */
    neverAllocate: bool = false,
    /// \brief Set this flag to use a memory that will be persistently mapped and retrieve pointer to it.
    ///
    /// Pointer to mapped memory will be returned through AllocationInfo::pMappedData.
    ///
    /// Is it valid to use this flag for allocation made from memory type that is not
    /// `HOST_VISIBLE`. This flag is then ignored and memory is not mapped. This is
    /// useful if you need an allocation that is efficient to use on GPU
    /// (`DEVICE_LOCAL`) and still want to map it directly if possible on platforms that
    /// support it (e.g. Intel GPU).
    ///
    /// You should not use this flag together with #VMA_ALLOCATION_CREATE_CAN_BECOME_LOST_BIT.
    createMapped: bool = false,
    /// Allocation created with this flag can become lost as a result of another
    /// allocation with #VMA_ALLOCATION_CREATE_CAN_MAKE_OTHER_LOST_BIT flag, so you
    /// must check it before use.
    ///
    /// To check if allocation is not lost, call GetAllocationInfo() and check if
    /// AllocationInfo::deviceMemory is not `.Null`.
    ///
    /// For details about supporting lost allocations, see Lost Allocations
    /// chapter of User Guide on Main Page.
    ///
    /// You should not use this flag together with #VMA_ALLOCATION_CREATE_MAPPED_BIT.
    canBecomeLost: bool = false,
    /// While creating allocation using this flag, other allocations that were
    /// created with flag #VMA_ALLOCATION_CREATE_CAN_BECOME_LOST_BIT can become lost.
    ///
    /// For details about supporting lost allocations, see Lost Allocations
    /// chapter of User Guide on Main Page.
    canMakeOtherLost: bool = false,
    /// Set this flag to treat AllocationCreateInfo::pUserData as pointer to a
    /// null-terminated string. Instead of copying pointer value, a local copy of the
    /// string is made and stored in allocation's `pUserData`. The string is automatically
    /// freed together with the allocation. It is also used in BuildStatsString().
    userDataCopyString: bool = false,
    /// Allocation will be created from upper stack in a double stack pool.
    ///
    /// This flag is only allowed for custom pools created with #VMA_POOL_CREATE_LINEAR_ALGORITHM_BIT flag.
    upperAddress: bool = false,
    /// Create both buffer/image and allocation, but don't bind them together.
    /// It is useful when you want to bind yourself to do some more advanced binding, e.g. using some extensions.
    /// The flag is meaningful only with functions that bind by default: CreateBuffer(), CreateImage().
    /// Otherwise it is ignored.
    dontBind: bool = false,
    /// Create allocation only if additional device memory required for it, if any, won't exceed
    /// memory budget. Otherwise return `error.VK_OUT_OF_DEVICE_MEMORY`.
    withinBudget: bool = false,

    __reserved_bits_09_15: u7 = 0,

    /// Allocation strategy that chooses smallest possible free range for the
    /// allocation.
    strategyBestFit: bool = false,
    /// Allocation strategy that chooses biggest possible free range for the
    /// allocation.
    strategyWorstFit: bool = false,
    /// Allocation strategy that chooses first suitable free range for the
    /// allocation.
    ///
    /// "First" doesn't necessarily means the one with smallest offset in memory,
    /// but rather the one that is easiest and fastest to find.
    strategyFirstFit: bool = false,

    __reserved_bits_19_31: u13 = 0,

    /// Allocation strategy that tries to minimize memory usage.
    pub const STRATEGY_MIN_MEMORY = AllocationCreateFlags{ .strategyBestFit = true };
    /// Allocation strategy that tries to minimize allocation time.
    pub const STRATEGY_MIN_TIME = AllocationCreateFlags{ .strategyFirstFit = true };
    /// Allocation strategy that tries to minimize memory fragmentation.
    pub const STRATEGY_MIN_FRAGMENTATION = AllocationCreateFlags{ .strategyWorstFit = true };

    /// A bit mask to extract only `STRATEGY` bits from entire set of flags.
    pub const STRATEGY_MASK = AllocationCreateFlags{
        .strategyBestFit = true,
        .strategyWorstFit = true,
        .strategyFirstFit = true,
    };

    pub usingnamespace vk.FlagsMixin(@This(), vk.Flags);
};

pub const AllocationCreateInfo = extern struct {
    /// Use #AllocationCreateFlagBits enum.
    flags: AllocationCreateFlags = .{},
    /// \brief Intended usage of memory.
    ///
    /// You can leave #MemoryUsage.unknown if you specify memory requirements in other way. \n
    /// If `pool` is not null, this member is ignored.
    usage: MemoryUsage = .unknown,
    /// \brief Flags that must be set in a Memory Type chosen for an allocation.
    ///
    /// Leave 0 if you specify memory requirements in other way. \n
    /// If `pool` is not null, this member is ignored.*/
    requiredFlags: vk.MemoryPropertyFlags = .{},
    /// \brief Flags that preferably should be set in a memory type chosen for an allocation.
    ///
    /// Set to 0 if no additional flags are prefered. \n
    /// If `pool` is not null, this member is ignored. */
    preferredFlags: vk.MemoryPropertyFlags = .{},
    /// \brief Bitmask containing one bit set for every memory type acceptable for this allocation.
    ///
    /// Value 0 is equivalent to `UINT32_MAX` - it means any memory type is accepted if
    /// it meets other requirements specified by this structure, with no further
    /// restrictions on memory type index. \n
    /// If `pool` is not null, this member is ignored.
    memoryTypeBits: u32 = 0,
    /// \brief Pool that this allocation should be created in.
    ///
    /// Leave `.Null` to allocate from default pool. If not null, members:
    /// `usage`, `requiredFlags`, `preferredFlags`, `memoryTypeBits` are ignored.
    pool: Pool = .Null,
    /// \brief Custom general-purpose pointer that will be stored in #Allocation, can be read as AllocationInfo::pUserData and changed using SetAllocationUserData().
    ///
    /// If #AllocationCreateFlags.userDataCopyString is true, it must be either
    /// null or pointer to a null-terminated string. The string will be then copied to
    /// internal buffer, so it doesn't need to be valid after allocation call.
    pUserData: ?*anyopaque = null,
};

/// Flags to be passed as PoolCreateInfo::flags.
pub const PoolCreateFlags = packed struct {
    __reserved_bit_00: u1 = 0,
    /// \brief Use this flag if you always allocate only buffers and linear images or only optimal images out of this pool and so Buffer-Image Granularity can be ignored.
    ///
    /// This is an optional optimization flag.
    ///
    /// If you always allocate using CreateBuffer(), CreateImage(),
    /// AllocateMemoryForBuffer(), then you don't need to use it because allocator
    /// knows exact type of your allocations so it can handle Buffer-Image Granularity
    /// in the optimal way.
    ///
    /// If you also allocate using AllocateMemoryForImage() or AllocateMemory(),
    /// exact type of such allocations is not known, so allocator must be conservative
    /// in handling Buffer-Image Granularity, which can lead to suboptimal allocation
    /// (wasted memory). In that case, if you can make sure you always allocate only
    /// buffers and linear images or only optimal images out of this pool, use this flag
    /// to make allocator disregard Buffer-Image Granularity and so make allocations
    /// faster and more optimal.
    ignoreBufferImageGranularity: bool = false,

    /// \brief Enables alternative, linear allocation algorithm in this pool.
    ///
    /// Specify this flag to enable linear allocation algorithm, which always creates
    /// new allocations after last one and doesn't reuse space from allocations freed in
    /// between. It trades memory consumption for simplified algorithm and data
    /// structure, which has better performance and uses less memory for metadata.
    ///
    /// By using this flag, you can achieve behavior of free-at-once, stack,
    /// ring buffer, and double stack. For details, see documentation chapter
    /// \ref linear_algorithm.
    ///
    /// When using this flag, you must specify PoolCreateInfo::maxBlockCount == 1 (or 0 for default).
    ///
    /// For more details, see [Linear allocation algorithm](@ref linear_algorithm).
    linearAlgorithm: bool = false,

    /// \brief Enables alternative, buddy allocation algorithm in this pool.
    ///
    /// It operates on a tree of blocks, each having size that is a power of two and
    /// a half of its parent's size. Comparing to default algorithm, this one provides
    /// faster allocation and deallocation and decreased external fragmentation,
    /// at the expense of more memory wasted (internal fragmentation).
    ///
    /// For more details, see [Buddy allocation algorithm](@ref buddy_algorithm).
    buddyAlgorithm: bool = false,

    __reserved_bits_04_31: u28 = 0,

    /// Bit mask to extract only `ALGORITHM` bits from entire set of flags.
    pub const ALGORITHM_MASK = PoolCreateFlags{
        .linearAlgorithm = true,
        .buddyAlgorithm = true,
    };

    pub usingnamespace vk.FlagsMixin(@This());
};

/// \brief Describes parameter of created #Pool.
pub const PoolCreateInfo = extern struct {
    /// \brief Vulkan memory type index to allocate this pool from.
    memoryTypeIndex: u32,
    /// \brief Use combination of #PoolCreateFlagBits.
    flags: PoolCreateFlags = .{},
    /// \brief Size of a single `vk.DeviceMemory` block to be allocated as part of this pool, in bytes. Optional.
    ///
    /// Specify nonzero to set explicit, constant size of memory blocks used by this
    /// pool.
    ///
    /// Leave 0 to use default and let the library manage block sizes automatically.
    /// Sizes of particular blocks may vary.
    blockSize: vk.DeviceSize = 0,
    /// \brief Minimum number of blocks to be always allocated in this pool, even if they stay empty.
    ///
    /// Set to 0 to have no preallocated blocks and allow the pool be completely empty.
    minBlockCount: usize = 0,
    /// \brief Maximum number of blocks that can be allocated in this pool. Optional.
    ///
    /// Set to 0 to use default, which is `SIZE_MAX`, which means no limit.
    ///
    /// Set to same value as PoolCreateInfo::minBlockCount to have fixed amount of memory allocated
    /// throughout whole lifetime of this pool.
    maxBlockCount: usize = 0,
    /// \brief Maximum number of additional frames that are in use at the same time as current frame.
    ///
    /// This value is used only when you make allocations with
    /// #VMA_ALLOCATION_CREATE_CAN_BECOME_LOST_BIT flag. Such allocation cannot become
    /// lost if allocation.lastUseFrameIndex >= allocator.currentFrameIndex - frameInUseCount.
    ///
    /// For example, if you double-buffer your command buffers, so resources used for
    /// rendering in previous frame may still be in use by the GPU at the moment you
    /// allocate resources needed for the current frame, set this value to 1.
    ///
    /// If you want to allow any allocations other than used in the current frame to
    /// become lost, set this value to 0.
    frameInUseCount: u32,
};

/// \brief Describes parameter of existing #Pool.
pub const PoolStats = extern struct {
    /// \brief Total amount of `vk.DeviceMemory` allocated from Vulkan for this pool, in bytes.
    size: vk.DeviceSize,
    /// \brief Total number of bytes in the pool not used by any #Allocation.
    unusedSize: vk.DeviceSize,
    /// \brief Number of #Allocation objects created from this pool that were not destroyed or lost.
    allocationCount: usize,
    /// \brief Number of continuous memory ranges in the pool not used by any #Allocation.
    unusedRangeCount: usize,
    /// \brief Size of the largest continuous free memory region available for new allocation.
    ///
    /// Making a new allocation of that size is not guaranteed to succeed because of
    /// possible additional margin required to respect alignment and buffer/image
    /// granularity.
    unusedRangeSizeMax: vk.DeviceSize,
    /// \brief Number of `vk.DeviceMemory` blocks allocated for this pool.
    blockCount: usize,
};

/// \struct Allocation
/// \brief Represents single memory allocation.
///
/// It may be either dedicated block of `vk.DeviceMemory` or a specific region of a bigger block of this type
/// plus unique offset.
///
/// There are multiple ways to create such object.
/// You need to fill structure AllocationCreateInfo.
/// For more information see [Choosing memory type](@ref choosing_memory_type).
///
/// Although the library provides convenience functions that create Vulkan buffer or image,
/// allocate memory for it and bind them together,
/// binding of the allocation to a buffer or an image is out of scope of the allocation itself.
/// Allocation object can exist without buffer/image bound,
/// binding can be done manually by the user, and destruction of it can be done
/// independently of destruction of the allocation.
///
/// The object also remembers its size and some other information.
/// To retrieve this information, use function GetAllocationInfo() and inspect
/// returned structure AllocationInfo.
///
/// Some kinds allocations can be in lost state.
/// For more information, see [Lost allocations](@ref lost_allocations).
pub const Allocation = enum(usize) { Null = 0, _ };

/// \brief Parameters of #Allocation objects, that can be retrieved using function GetAllocationInfo().
pub const AllocationInfo = extern struct {
    /// \brief Memory type index that this allocation was allocated from.
    ///
    /// It never changes.
    memoryType: u32,
    /// \brief Handle to Vulkan memory object.
    ///
    /// Same memory object can be shared by multiple allocations.
    ///
    /// It can change after call to Defragment() if this allocation is passed to the function, or if allocation is lost.
    ///
    /// If the allocation is lost, it is equal to `.Null`.
    deviceMemory: vk.DeviceMemory,
    /// \brief Offset into deviceMemory object to the beginning of this allocation, in bytes. (deviceMemory, offset) pair is unique to this allocation.
    ///
    /// It can change after call to Defragment() if this allocation is passed to the function, or if allocation is lost.
    offset: vk.DeviceSize,
    /// \brief Size of this allocation, in bytes.
    ///
    /// It never changes, unless allocation is lost.
    size: vk.DeviceSize,
    /// \brief Pointer to the beginning of this allocation as mapped data.
    ///
    /// If the allocation hasn't been mapped using MapMemory() and hasn't been
    /// created with #VMA_ALLOCATION_CREATE_MAPPED_BIT flag, this value null.
    ///
    /// It can change after call to MapMemory(), UnmapMemory().
    /// It can also change after call to Defragment() if this allocation is passed to the function.
    pMappedData: ?*anyopaque,
    /// \brief Custom general-purpose pointer that was passed as AllocationCreateInfo::pUserData or set using SetAllocationUserData().
    ///
    /// It can change after call to SetAllocationUserData() for this allocation.
    pUserData: ?*anyopaque,
};

/// \struct DefragmentationContext
/// \brief Represents Opaque object that represents started defragmentation process.
///
/// Fill structure #DefragmentationInfo2 and call function DefragmentationBegin() to create it.
/// Call function DefragmentationEnd() to destroy it.
pub const DefragmentationContext = enum(usize) { Null = 0, _ };

/// Flags to be used in DefragmentationBegin(). None at the moment. Reserved for future use.
pub const DefragmentationFlags = packed struct {
    __reserved_bits_0_31: u32 = 0,

    pub usingnamespace vk.FlagsMixin(@This());
};

/// \brief Parameters for defragmentation.
///
/// To be used with function DefragmentationBegin().
pub const DefragmentationInfo2 = extern struct {
    /// \brief Reserved for future use. Should be 0.
    flags: DefragmentationFlags = .{},
    /// \brief Number of allocations in `pAllocations` array.
    allocationCount: u32,
    /// \brief Pointer to array of allocations that can be defragmented.
    ///
    /// The array should have `allocationCount` elements.
    /// The array should not contain nulls.
    /// Elements in the array should be unique - same allocation cannot occur twice.
    /// It is safe to pass allocations that are in the lost state - they are ignored.
    /// All allocations not present in this array are considered non-moveable during this defragmentation.
    pAllocations: [*]Allocation,
    /// \brief Optional, output. Pointer to array that will be filled with information whether the allocation at certain index has been changed during defragmentation.
    ///
    /// The array should have `allocationCount` elements.
    /// You can pass null if you are not interested in this information.
    pAllocationsChanged: ?[*]vk.Bool32,
    /// \brief Numer of pools in `pPools` array.
    poolCount: u32,
    /// \brief Either null or pointer to array of pools to be defragmented.
    ///
    /// All the allocations in the specified pools can be moved during defragmentation
    /// and there is no way to check if they were really moved as in `pAllocationsChanged`,
    /// so you must query all the allocations in all these pools for new `vk.DeviceMemory`
    /// and offset using GetAllocationInfo() if you might need to recreate buffers
    /// and images bound to them.
    ///
    /// The array should have `poolCount` elements.
    /// The array should not contain nulls.
    /// Elements in the array should be unique - same pool cannot occur twice.
    ///
    /// Using this array is equivalent to specifying all allocations from the pools in `pAllocations`.
    /// It might be more efficient.
    pPools: ?[*]Pool,
    /// \brief Maximum total numbers of bytes that can be copied while moving allocations to different places using transfers on CPU side, like `memcpy()`, `memmove()`.
    ///
    /// `vk.WHOLE_SIZE` means no limit.
    maxCpuBytesToMove: vk.DeviceSize,
    /// \brief Maximum number of allocations that can be moved to a different place using transfers on CPU side, like `memcpy()`, `memmove()`.
    ///
    /// `UINT32_MAX` means no limit.
    maxCpuAllocationsToMove: u32,
    /// \brief Maximum total numbers of bytes that can be copied while moving allocations to different places using transfers on GPU side, posted to `commandBuffer`.
    ///
    /// `vk.WHOLE_SIZE` means no limit.
    maxGpuBytesToMove: vk.DeviceSize,
    /// \brief Maximum number of allocations that can be moved to a different place using transfers on GPU side, posted to `commandBuffer`.
    ///
    /// `UINT32_MAX` means no limit.
    maxGpuAllocationsToMove: u32,
    /// \brief Optional. Command buffer where GPU copy commands will be posted.
    ///
    /// If not null, it must be a valid command buffer handle that supports Transfer queue type.
    /// It must be in the recording state and outside of a render pass instance.
    /// You need to submit it and make sure it finished execution before calling DefragmentationEnd().
    ///
    /// Passing null means that only CPU defragmentation will be performed.
    commandBuffer: vk.CommandBuffer,
};

/// \brief Deprecated. Optional configuration parameters to be passed to function Defragment().
///
/// \deprecated This is a part of the old interface. It is recommended to use structure #DefragmentationInfo2 and function DefragmentationBegin() instead.
pub const DefragmentationInfo = extern struct {
    /// \brief Maximum total numbers of bytes that can be copied while moving allocations to different places.
    ///
    /// Default is `vk.WHOLE_SIZE`, which means no limit.
    maxBytesToMove: vk.DeviceSize,
    /// \brief Maximum number of allocations that can be moved to different place.
    ///
    /// Default is `UINT32_MAX`, which means no limit.
    maxAllocationsToMove: u32,
};

/// \brief Statistics returned by function Defragment().
pub const DefragmentationStats = extern struct {
    /// Total number of bytes that have been copied while moving allocations to different places.
    bytesMoved: vk.DeviceSize,
    /// Total number of bytes that have been released to the system by freeing empty `vk.DeviceMemory` objects.
    bytesFreed: vk.DeviceSize,
    /// Number of allocations that have been moved to different places.
    allocationsMoved: u32,
    /// Number of empty `vk.DeviceMemory` objects that have been released to the system.
    deviceMemoryBlocksFreed: u32,
};

pub extern fn vmaCreateAllocator(pCreateInfo: *const AllocatorCreateInfo, pAllocator: *Allocator) callconv(CallConv) vk.Result;
pub extern fn vmaDestroyAllocator(allocator: Allocator) callconv(CallConv) void;

pub extern fn vmaGetPhysicalDeviceProperties(
    allocator: Allocator,
    ppPhysicalDeviceProperties: **const vk.PhysicalDeviceProperties,
) callconv(CallConv) void;
pub extern fn vmaGetMemoryProperties(
    allocator: Allocator,
    ppPhysicalDeviceMemoryProperties: **const vk.PhysicalDeviceMemoryProperties,
) callconv(CallConv) void;
pub extern fn vmaGetMemoryTypeProperties(
    allocator: Allocator,
    memoryTypeIndex: u32,
    pFlags: *align(4) vk.MemoryPropertyFlags,
) callconv(CallConv) void;

pub extern fn vmaSetCurrentFrameIndex(allocator: Allocator, frameIndex: u32) callconv(CallConv) void;
pub extern fn vmaCalculateStats(allocator: Allocator, pStats: *Stats) callconv(CallConv) void;

pub extern fn vmaGetBudget(
    allocator: Allocator,
    pBudget: *Budget,
) callconv(CallConv) void;

// pub usingnamespace if (config.statsStringEnabled)
//     struct {
//         pub extern fn vmaBuildStatsString(
//             allocator: Allocator,
//             ppStatsString: *[*:0]u8,
//             detailedMap: vk.Bool32,
//         ) callconv(CallConv) void;
//         pub extern fn vmaFreeStatsString(
//             allocator: Allocator,
//             pStatsString: [*:0]u8,
//         ) callconv(CallConv) void;
//     }
// else
//     struct {};

pub extern fn vmaFindMemoryTypeIndex(
    allocator: Allocator,
    memoryTypeBits: u32,
    pAllocationCreateInfo: *const AllocationCreateInfo,
    pMemoryTypeIndex: *u32,
) callconv(CallConv) vk.Result;

pub extern fn vmaFindMemoryTypeIndexForBufferInfo(
    allocator: Allocator,
    pBufferCreateInfo: *const vk.BufferCreateInfo,
    pAllocationCreateInfo: *const AllocationCreateInfo,
    pMemoryTypeIndex: *u32,
) callconv(CallConv) vk.Result;

pub extern fn vmaFindMemoryTypeIndexForImageInfo(
    allocator: Allocator,
    pImageCreateInfo: *const vk.ImageCreateInfo,
    pAllocationCreateInfo: *const AllocationCreateInfo,
    pMemoryTypeIndex: *u32,
) callconv(CallConv) vk.Result;

pub extern fn vmaCreatePool(
    allocator: Allocator,
    pCreateInfo: *const PoolCreateInfo,
    pPool: *Pool,
) callconv(CallConv) vk.Result;

pub extern fn vmaDestroyPool(
    allocator: Allocator,
    pool: Pool,
) callconv(CallConv) void;

pub extern fn vmaGetPoolStats(
    allocator: Allocator,
    pool: Pool,
    pPoolStats: *PoolStats,
) callconv(CallConv) void;

pub extern fn vmaMakePoolAllocationsLost(
    allocator: Allocator,
    pool: Pool,
    pLostAllocationCount: ?*usize,
) callconv(CallConv) void;

pub extern fn vmaCheckPoolCorruption(allocator: Allocator, pool: Pool) callconv(CallConv) vk.Result;

pub extern fn vmaGetPoolName(
    allocator: Allocator,
    pool: Pool,
    ppName: *?[*:0]const u8,
) callconv(CallConv) void;

pub extern fn vmaSetPoolName(
    allocator: Allocator,
    pool: Pool,
    pName: ?[*:0]const u8,
) callconv(CallConv) void;

pub extern fn vmaAllocateMemory(
    allocator: Allocator,
    pVkMemoryRequirements: *const vk.MemoryRequirements,
    pCreateInfo: *const AllocationCreateInfo,
    pAllocation: *Allocation,
    pAllocationInfo: ?*AllocationInfo,
) callconv(CallConv) vk.Result;

pub extern fn vmaAllocateMemoryPages(
    allocator: Allocator,
    pVkMemoryRequirements: *const vk.MemoryRequirements,
    pCreateInfo: *const AllocationCreateInfo,
    allocationCount: usize,
    pAllocations: [*]Allocation,
    pAllocationInfo: ?[*]AllocationInfo,
) callconv(CallConv) vk.Result;

pub extern fn vmaAllocateMemoryForBuffer(
    allocator: Allocator,
    buffer: vk.Buffer,
    pCreateInfo: *const AllocationCreateInfo,
    pAllocation: *Allocation,
    pAllocationInfo: ?*AllocationInfo,
) callconv(CallConv) vk.Result;

pub extern fn vmaAllocateMemoryForImage(
    allocator: Allocator,
    image: vk.Image,
    pCreateInfo: *const AllocationCreateInfo,
    pAllocation: *Allocation,
    pAllocationInfo: ?*AllocationInfo,
) callconv(CallConv) vk.Result;

pub extern fn vmaFreeMemory(
    allocator: Allocator,
    allocation: Allocation,
) callconv(CallConv) void;

pub extern fn vmaFreeMemoryPages(
    allocator: Allocator,
    allocationCount: usize,
    pAllocations: [*]Allocation,
) callconv(CallConv) void;

/// \brief Deprecated.
///
/// In version 2.2.0 it used to try to change allocation's size without moving or reallocating it.
/// In current version it returns `vk.SUCCESS` only if `newSize` equals current allocation's size.
/// Otherwise returns `error.VK_OUT_OF_POOL_MEMORY`, indicating that allocation's size could not be changed.
pub extern fn vmaResizeAllocation(
    allocator: Allocator,
    allocation: Allocation,
    newSize: vk.DeviceSize,
) callconv(CallConv) vk.Result;

pub extern fn vmaGetAllocationInfo(
    allocator: Allocator,
    allocation: Allocation,
    pAllocationInfo: *AllocationInfo,
) callconv(CallConv) void;

pub extern fn vmaTouchAllocation(
    allocator: Allocator,
    allocation: Allocation,
) callconv(CallConv) vk.Bool32;

pub extern fn vmaSetAllocationUserData(
    allocator: Allocator,
    allocation: Allocation,
    pUserData: ?*anyopaque,
) callconv(CallConv) void;

pub extern fn vmaCreateLostAllocation(
    allocator: Allocator,
    pAllocation: *Allocation,
) callconv(CallConv) void;

pub extern fn vmaMapMemory(
    allocator: Allocator,
    allocation: Allocation,
    ppData: **anyopaque,
) callconv(CallConv) vk.Result;

pub extern fn vmaUnmapMemory(
    allocator: Allocator,
    allocation: Allocation,
) callconv(CallConv) void;

pub extern fn vmaFlushAllocation(allocator: Allocator, allocation: Allocation, offset: vk.DeviceSize, size: vk.DeviceSize) callconv(CallConv) void;

pub extern fn vmaInvalidateAllocation(allocator: Allocator, allocation: Allocation, offset: vk.DeviceSize, size: vk.DeviceSize) callconv(CallConv) void;

pub extern fn vmaCheckCorruption(allocator: Allocator, memoryTypeBits: u32) callconv(CallConv) vk.Result;

pub extern fn vmaDefragmentationBegin(
    allocator: Allocator,
    pInfo: *const DefragmentationInfo2,
    pStats: ?*DefragmentationStats,
    pContext: *DefragmentationContext,
) callconv(CallConv) vk.Result;

pub extern fn vmaDefragmentationEnd(
    allocator: Allocator,
    context: DefragmentationContext,
) callconv(CallConv) vk.Result;

/// \brief Deprecated. Compacts memory by moving allocations.
///
/// @param pAllocations Array of allocations that can be moved during this compation.
/// @param allocationCount Number of elements in pAllocations and pAllocationsChanged arrays.
/// @param[out] pAllocationsChanged Array of boolean values that will indicate whether matching allocation in pAllocations array has been moved. This parameter is optional. Pass null if you don't need this information.
/// @param pDefragmentationInfo Configuration parameters. Optional - pass null to use default values.
/// @param[out] pDefragmentationStats Statistics returned by the function. Optional - pass null if you don't need this information.
/// @return `vk.SUCCESS` if completed, negative error code in case of error.
///
/// \deprecated This is a part of the old interface. It is recommended to use structure #DefragmentationInfo2 and function DefragmentationBegin() instead.
///
/// This function works by moving allocations to different places (different
/// `vk.DeviceMemory` objects and/or different offsets) in order to optimize memory
/// usage. Only allocations that are in `pAllocations` array can be moved. All other
/// allocations are considered nonmovable in this call. Basic rules:
///
/// - Only allocations made in memory types that have
/// `vk.MEMORY_PROPERTY_HOST_VISIBLE_BIT` and `vk.MEMORY_PROPERTY_HOST_COHERENT_BIT`
/// flags can be compacted. You may pass other allocations but it makes no sense -
/// these will never be moved.
/// - Custom pools created with #VMA_POOL_CREATE_LINEAR_ALGORITHM_BIT or
/// #VMA_POOL_CREATE_BUDDY_ALGORITHM_BIT flag are not defragmented. Allocations
/// passed to this function that come from such pools are ignored.
/// - Allocations created with #VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT or
/// created as dedicated allocations for any other reason are also ignored.
/// - Both allocations made with or without #VMA_ALLOCATION_CREATE_MAPPED_BIT
/// flag can be compacted. If not persistently mapped, memory will be mapped
/// temporarily inside this function if needed.
/// - You must not pass same #Allocation object multiple times in `pAllocations` array.
///
/// The function also frees empty `vk.DeviceMemory` blocks.
///
/// Warning: This function may be time-consuming, so you shouldn't call it too often
/// (like after every resource creation/destruction).
/// You can call it on special occasions (like when reloading a game level or
/// when you just destroyed a lot of objects). Calling it every frame may be OK, but
/// you should measure that on your platform.
///
/// For more information, see [Defragmentation](@ref defragmentation) chapter.
pub extern fn vmaDefragment(
    allocator: Allocator,
    pAllocations: *Allocation,
    allocationCount: usize,
    pAllocationsChanged: *vk.Bool32,
    pDefragmentationInfo: *const DefragmentationInfo,
    pDefragmentationStats: *DefragmentationStats,
) callconv(CallConv) vk.Result;

pub extern fn vmaBindBufferMemory(
    allocator: Allocator,
    allocation: Allocation,
    buffer: vk.Buffer,
) callconv(CallConv) vk.Result;

pub extern fn vmaBindBufferMemory2(
    allocator: Allocator,
    allocation: Allocation,
    allocationLocalOffset: vk.DeviceSize,
    buffer: vk.Buffer,
    pNext: ?*const anyopaque,
) callconv(CallConv) vk.Result;

pub extern fn vmaBindImageMemory(
    allocator: Allocator,
    allocation: Allocation,
    image: vk.Image,
) callconv(CallConv) vk.Result;

pub extern fn vmaBindImageMemory2(
    allocator: Allocator,
    allocation: Allocation,
    allocationLocalOffset: vk.DeviceSize,
    image: vk.Image,
    pNext: ?*const anyopaque,
) callconv(CallConv) vk.Result;

pub extern fn vmaCreateBuffer(
    allocator: Allocator,
    pBufferCreateInfo: *const vk.BufferCreateInfo,
    pAllocationCreateInfo: *const AllocationCreateInfo,
    pBuffer: *vk.Buffer,
    pAllocation: *Allocation,
    pAllocationInfo: ?*AllocationInfo,
) callconv(CallConv) vk.Result;

pub extern fn vmaDestroyBuffer(
    allocator: Allocator,
    buffer: vk.Buffer,
    allocation: Allocation,
) callconv(CallConv) void;

pub extern fn vmaCreateImage(
    allocator: Allocator,
    pImageCreateInfo: *const vk.ImageCreateInfo,
    pAllocationCreateInfo: *const AllocationCreateInfo,
    pImage: *vk.Image,
    pAllocation: *Allocation,
    pAllocationInfo: ?*AllocationInfo,
) callconv(CallConv) vk.Result;

pub extern fn vmaDestroyImage(
    allocator: Allocator,
    image: vk.Image,
    allocation: Allocation,
) callconv(CallConv) void;
