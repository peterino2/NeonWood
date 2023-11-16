//
// I think it's about time Peterino's tackling rendering.
//
// My first REAL crack at making a gpu driven proper vulkan renderer.
//
// This is a replacement for vk_renderer.
//
// Spec List for rendering:
//
// gltf support
// hlsl
// shared texture binding
// forward clustered rendering
// mega mesh
// gpu skinning
//
//
// https://advances.realtimerendering.com/s2016/Siggraph2016_idTech6.pdf
//
// gltf support
// Gpu skinning
// Megamesh: take all loaded mesh data and upload it to a single mesh buffer
// Giga texture binding: (all textures are bound all at once)
//  - TextureList:
// Clustered Forward+ Rendering (fully dynamic lighting, extreme light counts)
// Streaming open world workflow
//
// Skeletal Animation
// PBR
//
// Papyrus 2d Rendering
// Papyrus 3d Rendering
//
// Fixed Materials System (Users install megashaders, default lit shaders are
// provided for standard rendering)
//
// Modular rendergraph workflow (not shadergraph)
//
// Run-To-Completion job based architecture with dependencies.
//
// Lock free RHI dispatch thread (triple command buffering)
//  - next to write (NTW)
//  - most recently written (MRW)
//  - currently rendering (CR)
//
//  when frame is done processing
//  renderer subsystems: in vulkan the order that command buffers appear determin the submission order.
//
// Game API side:
//
// Queue Based High Level Render Jobs
// Queue Based High Level Asset Jobs
//
//
// Lock free RHI dispatch thread (triple command buffering)
//  - next to write (NTW)
//  - most recently written (MRW)
//  - currently rendering (CR)
//
//  when frame is done processing
//      -> Swap NTW with MRW
//          -> queue RENDER job
//              - Render job swaps MRW with NTW
//              - Submit subjobs which build command buffers
//              - Signals Next Render Available
//          -> game simulations UPLOAD render info
//              -> writes into NTW
//
//  renderer subsystems: in vulkan the order that command buffers appear determin the submission order.
//
