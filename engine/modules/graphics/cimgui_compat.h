#pragma once

#include <vulkan/vulkan.h>

struct ImGui_ImplVulkan_InitInfo
{
    VkInstance                      Instance;
    VkPhysicalDevice                PhysicalDevice;
    VkDevice                        Device;
    uint32_t                        QueueFamily;
    VkQueue                         Queue;
    VkPipelineCache                 PipelineCache;
    VkDescriptorPool                DescriptorPool;
    uint32_t                        Subpass;
    uint32_t                        MinImageCount;          // >= 2
    uint32_t                        ImageCount;             // >= MinImageCount
    VkSampleCountFlagBits           MSAASamples;            // >= VK_SAMPLE_COUNT_1_BIT (0 -> default to VK_SAMPLE_COUNT_1_BIT)
    const VkAllocationCallbacks*    Allocator;
    void                            (*CheckVkResultFn)(VkResult err);
};

typedef struct ImGui_ImplVulkan_InitInfo ImGui_ImplVulkan_InitInfo;


// Called by user code
//bool cImGui_ImplVulkan_Init(ImGui_ImplVulkan_InitInfo* info, VkRenderPass render_pass);
bool cImGui_vk_Init(ImGui_ImplVulkan_InitInfo* info, VkRenderPass render_pass);
void cImGui_vk_Shutdown();
void cImGui_vk_NewFrame();
void cImGui_vk_RenderDrawData(ImDrawData* draw_data, VkCommandBuffer command_buffer, VkPipeline pipeline);
bool cImGui_vk_CreateFontsTexture(VkCommandBuffer command_buffer);
void cImGui_vk_DestroyFontUploadObjects();
void cImGui_vk_SetMinImageCount(uint32_t min_image_count); // To override MinImageCount after initialization (e.g. if swap chain is recreated)

