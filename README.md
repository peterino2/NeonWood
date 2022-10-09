
# NeonWood Toy Game Development Toolkit

This is an attempt at creating a higher level game development
toolkit developed in zig specifically targeting the vulkan renderer
initially (then webgpu or webgl depending on availability for that stuff
would be available).

The goal is to create a highly flexible in-house toolkit of 
software that can churn out relatively good looking 
3D games in say... the timeframe required for a gamejam.

# Organization and Architecture

The codebase will heavily leverage build.zig as it's master build
system.

The one toplevel build.zig will be the entry point into the build.

It will gather all modules under modules/ 

there is only one module that is special among all the others, and that is 

`core`

this module implements what will be an effective `standard library` for 
the rest of the neonwood stack

build flags for shipping:

`zig build -fstage1 -Drelease-fast -Dtarget=x86_64-windows`
