# NeonWood Game Engine

This is a vulkan based gamedev toolkit targeting the vulkan renderer for now.
It's been written over the last two months as a learning project but has so far
already released a game jam game: Cognesia.

You can play it here on windows or linux.

[itch.io page](https://peterino2.itch.io/cognesia)

The intent is to provide a general purpose low overhead gamedev toolkit that I can
use to produce small games with.

And eventually evolve it into a full on game engine for use with creating larger
personal project games for windows linux macos android and any other systems I
can get my hands on.

## Building

A couple of sample programs ship with the integration branch. They include a
multithreaded job dispatch test, an imgui test with support for docking.

And the gamejam game `cognesia`.

All executables are built under zig-out/bin

If you're on windows build_and_package.bat will create a package bundle for
cognesia under source

to play cognesia from source, run:

```{bash}
git clone https://github.com/peterino2/NeonWood.git --recursive && cd NeonWood
cd engine
zig build -fstage1 -Drelease-safe
./zig-out/bin/cognesia.exe
```

## Engine Highlights

* Highly modular architecture, core renderer handles vulkan majority of systems are
implemented in a game or a project first before being considered for being added to
the core engine.
* Data oriented, major subsystems heavily leverage sparse multisets as a primary container
for object-like data. (this is a precursor to a more formal ECS planned.)
* Core engine features extensible with an interface idiom.
* No real distinction between game and engine code, The best games are the ones that have
a highly systemic approach to content production.
* Performant. integrates tracy for performance profiling, vulkan for low over
* Cross platform desktop support with vulkan, and planned webgpu support in the future.
* Will be battle tested. I love making games I intend to actually leverage this engine to
make real and playable games, and prefer to drive feature development by making products.
* Will probably eventually get documented.

## Cognesia Game Features

* Custom scripting language `zig-halcyon` designed for authoring branching dialogue content
* Mixed 2d 3d and sprite based artwork
* Screen effects
* Custom sprite animation system with support for footsteps and animation montage events
* The most ghetto collision and boundary detection system you've ever seen.
* All content was created in an afternoon.

### Organization and Architecture

The codebase will heavily leverage build.zig as it's master build system.

modules/ contains core engine code. available for use with all projects.

Because the goal is to bubble features from individual projects into engine.
Games and applications will implement features and systems they need under projects/\<game name\>/
first.

(eg Cogensia implements an animated sprite renderer, this is not part of the core engine. But it could be...)

Individual modules start up and are called by the main application via the engine's `start_module()` function.

build flags for shipping:

`zig build -fstage1 -Drelease-safe -Dtarget=x86_64-windows`

## Dependencies

### Windows

* python 3.6+
* lunarg vulkan development libraries ( binaries added to path )
* glslc on your path ( comes with the lunarg vulkan sdk)

### Linux

I will be perfectly honest I do not game on linux and the general ecosystem there seems quite difficult to understand.
for me right now. Its highly unlikely that my linux build works exceptionally well for cross compiling.

* Get latest from: [](https://packages.lunarg.com/)

mesa-common-dev is also needed for creating cross platform packages on linux

Eg. for Ubuntu:

```{bash}
wget -qO- https://packages.lunarg.com/lunarg-signing-key-pub.asc | sudo tee /etc/apt/trusted.gpg.d/lunarg.asc
sudo wget -qO /etc/apt/sources.list.d/lunarg-vulkan-1.3.231-jammy.list https://packages.lunarg.com/vulkan/1.3.231/lunarg-vulkan-1.3.231-jammy.list
sudo apt update
sudo apt install vulkan-sdk
```

## Libraries and packages used

### Engine

* [zmath](https://github.com/michal-z/zig-gamedev/tree/main/libs/zmath)
* [vulkan-zig bindings by snektron](https://github.com/Snektron/vulkan-zig)
* [miniaudio](https://github.com/mackron/miniaudio)
* [dear imgui / cimgui](https://github.com/cimgui/cimgui)

### Cognesia Game

* [halcyon](https://github.com/peterino2/zig-halcyon)