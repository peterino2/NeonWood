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

extern "C" void SetupImguiColors ()
{
    ImGuiStyle& style = ImGui::GetStyle();
    style.WindowBorderSize = 1;
    style.ChildBorderSize = 1;
    style.PopupBorderSize = 1;
    style.FrameBorderSize = 0;
    style.TabBorderSize = 0;
    style.WindowPadding = {20, 20};

    style.WindowRounding = 6;
    style.ChildRounding = 6;
    style.FrameRounding = 6;
    style.ScrollbarRounding = 6;
    style.GrabRounding = 6;
    style.LogSliderDeadzone = 6;
    style.TabRounding = 6;
    style.WindowMenuButtonPosition = ImGuiDir_None;

    ImVec4* colors = ImGui::GetStyle().Colors;

    colors[ImGuiCol_Text]                   = ImVec4(1.00f, 1.00f, 1.00f, 1.00f);
    colors[ImGuiCol_TextDisabled]           = ImVec4(0.50f, 0.50f, 0.50f, 1.00f);
    colors[ImGuiCol_WindowBg]               = ImVec4(0.00f, 0.00f, 0.00f, 1.00f);
    colors[ImGuiCol_ChildBg]                = ImVec4(0.00f, 0.00f, 0.00f, 0.00f);
    colors[ImGuiCol_PopupBg]                = ImVec4(0.08f, 0.08f, 0.08f, 0.94f);
    colors[ImGuiCol_Border]                 = ImVec4(0.43f, 0.43f, 0.50f, 0.50f);
    colors[ImGuiCol_BorderShadow]           = ImVec4(0.00f, 0.00f, 0.00f, 0.00f);
    colors[ImGuiCol_FrameBg]                = ImVec4(0.48f, 0.16f, 0.16f, 0.54f);
    colors[ImGuiCol_FrameBgHovered]         = ImVec4(1.00f, 0.83f, 0.00f, 0.40f);
    colors[ImGuiCol_FrameBgActive]          = ImVec4(0.78f, 0.01f, 0.01f, 0.67f);
    colors[ImGuiCol_TitleBg]                = ImVec4(0.04f, 0.04f, 0.04f, 1.00f);
    colors[ImGuiCol_TitleBgActive]          = ImVec4(0.57f, 0.14f, 0.14f, 0.71f);
    colors[ImGuiCol_TitleBgCollapsed]       = ImVec4(0.00f, 0.00f, 0.00f, 0.51f);
    colors[ImGuiCol_MenuBarBg]              = ImVec4(0.14f, 0.14f, 0.14f, 1.00f);
    colors[ImGuiCol_ScrollbarBg]            = ImVec4(0.02f, 0.02f, 0.02f, 0.53f);
    colors[ImGuiCol_ScrollbarGrab]          = ImVec4(0.31f, 0.31f, 0.31f, 1.00f);
    colors[ImGuiCol_ScrollbarGrabHovered]   = ImVec4(0.41f, 0.41f, 0.41f, 1.00f);
    colors[ImGuiCol_ScrollbarGrabActive]    = ImVec4(0.51f, 0.51f, 0.51f, 1.00f);
    colors[ImGuiCol_CheckMark]              = ImVec4(0.10f, 0.05f, 0.00f, 1.00f);
    colors[ImGuiCol_SliderGrab]             = ImVec4(1.00f, 0.68f, 0.00f, 1.00f);
    colors[ImGuiCol_SliderGrabActive]       = ImVec4(0.07f, 0.00f, 0.00f, 1.00f);
    colors[ImGuiCol_Button]                 = ImVec4(0.11f, 0.09f, 0.00f, 0.40f);
    colors[ImGuiCol_ButtonHovered]          = ImVec4(0.02f, 0.01f, 0.01f, 1.00f);
    colors[ImGuiCol_ButtonActive]           = ImVec4(0.10f, 0.03f, 0.00f, 1.00f);
    colors[ImGuiCol_Header]                 = ImVec4(0.09f, 0.03f, 0.00f, 0.31f);
    colors[ImGuiCol_HeaderHovered]          = ImVec4(0.69f, 0.42f, 0.00f, 0.80f);
    colors[ImGuiCol_HeaderActive]           = ImVec4(0.17f, 0.09f, 0.00f, 1.00f);
    colors[ImGuiCol_Separator]              = ImVec4(0.82f, 0.32f, 0.04f, 0.50f);
    colors[ImGuiCol_SeparatorHovered]       = ImVec4(0.96f, 0.49f, 0.04f, 0.78f);
    colors[ImGuiCol_SeparatorActive]        = ImVec4(0.91f, 0.60f, 0.06f, 0.89f);
    colors[ImGuiCol_ResizeGrip]             = ImVec4(0.83f, 0.32f, 0.13f, 0.20f);
    colors[ImGuiCol_ResizeGripHovered]      = ImVec4(0.73f, 0.00f, 0.00f, 0.67f);
    colors[ImGuiCol_ResizeGripActive]       = ImVec4(0.86f, 0.08f, 0.08f, 0.95f);
    colors[ImGuiCol_Tab]                    = ImVec4(0.88f, 0.16f, 0.16f, 0.86f);
    colors[ImGuiCol_TabHovered]             = ImVec4(0.55f, 0.12f, 0.12f, 0.80f);
    colors[ImGuiCol_TabActive]              = ImVec4(0.57f, 0.02f, 0.02f, 1.00f);
    colors[ImGuiCol_TabUnfocused]           = ImVec4(0.77f, 0.29f, 0.04f, 0.97f);
    colors[ImGuiCol_TabUnfocusedActive]     = ImVec4(0.70f, 0.57f, 0.21f, 1.00f);
    colors[ImGuiCol_DockingPreview]         = ImVec4(0.42f, 0.26f, 0.09f, 0.70f);
    colors[ImGuiCol_DockingEmptyBg]         = ImVec4(0.0f, 0.00f, 0.00f, 0.00f);
    colors[ImGuiCol_PlotLines]              = ImVec4(0.61f, 0.61f, 0.61f, 1.00f);
    colors[ImGuiCol_PlotLinesHovered]       = ImVec4(1.00f, 0.43f, 0.35f, 1.00f);
    colors[ImGuiCol_PlotHistogram]          = ImVec4(0.90f, 0.70f, 0.00f, 1.00f);
    colors[ImGuiCol_PlotHistogramHovered]   = ImVec4(1.00f, 0.60f, 0.00f, 1.00f);
    colors[ImGuiCol_TableHeaderBg]          = ImVec4(0.19f, 0.19f, 0.20f, 1.00f);
    colors[ImGuiCol_TableBorderStrong]      = ImVec4(0.31f, 0.31f, 0.35f, 1.00f);
    colors[ImGuiCol_TableBorderLight]       = ImVec4(0.23f, 0.23f, 0.25f, 1.00f);
    colors[ImGuiCol_TableRowBg]             = ImVec4(0.00f, 0.00f, 0.00f, 0.00f);
    colors[ImGuiCol_TableRowBgAlt]          = ImVec4(1.00f, 1.00f, 1.00f, 0.06f);
    colors[ImGuiCol_TextSelectedBg]         = ImVec4(0.79f, 0.70f, 0.34f, 0.35f);
    colors[ImGuiCol_DragDropTarget]         = ImVec4(1.00f, 1.00f, 0.00f, 0.90f);
    colors[ImGuiCol_NavHighlight]           = ImVec4(0.57f, 0.22f, 0.05f, 1.00f);
    colors[ImGuiCol_NavWindowingHighlight]  = ImVec4(1.00f, 1.00f, 1.00f, 0.70f);
    colors[ImGuiCol_NavWindowingDimBg]      = ImVec4(0.80f, 0.80f, 0.80f, 0.20f);
    colors[ImGuiCol_ModalWindowDimBg]       = ImVec4(0.80f, 0.80f, 0.80f, 0.35f);
}

extern "C" void setFontScale(int newWidth, int newHeight)
{
    const float orig_width = 1600;
    const float orig_height = 900;

    float ratio_width = float(newWidth) / orig_width;
    float ratio_height = float(newHeight) / orig_height;

    float ratio = ratio_width > ratio_height ? ratio_height : ratio_width;

    auto& io = ImGui::GetIO();
    io.FontGlobalScale = (ratio * 1.0);
    printf("global scale: %f (%d x %d)\n", ratio, newWidth, newWidth);

    ImGuiStyle& style = ImGui::GetStyle();
    style.WindowPadding = {20 * ratio, 20 * ratio};
}