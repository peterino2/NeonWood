#define CIMGUI_DEFINE_ENUMS_AND_STRUCTS
#define IMGUI_DEFINE_MATH_OPERATORS
#define CIMGUI_USE_GLFW
#include "imgui.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_vulkan.h"
#include <stdio.h>

extern "C" bool cImGui_vk_Init(ImGui_ImplVulkan_InitInfo* info, VkRenderPass render_pass)
{
    ImGui_ImplVulkan_Init(info, render_pass);
    return false;
}

extern "C" void cImGui_vk_Shutdown()
{
    ImGui_ImplVulkan_Shutdown();
}

extern "C" void cImGui_vk_NewFrame()
{
    ImGui_ImplVulkan_NewFrame();
}

extern "C" void cImGui_vk_RenderDrawData(ImDrawData* draw_data, VkCommandBuffer command_buffer, VkPipeline pipeline = VK_NULL_HANDLE)
{
    ImGui_ImplVulkan_RenderDrawData(draw_data, command_buffer, pipeline);
}

extern "C" bool cImGui_vk_CreateFontsTexture(VkCommandBuffer command_buffer)
{
    ImGui_ImplVulkan_CreateFontsTexture(command_buffer);
    return true;
}

extern "C" void cImGui_vk_DestroyFontUploadObjects()
{
    ImGui_ImplVulkan_DestroyFontUploadObjects();
}

extern "C" void cImGui_vk_SetMinImageCount(uint32_t min_image_count)
{
    ImGui_ImplVulkan_SetMinImageCount(min_image_count);
}
