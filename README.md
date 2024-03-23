
![](https://i.imgur.com/U3uyhEX.png)


# Neonwood

This is a gamedev toolkit targeting the vulkan renderer for now.
It's been written over the last two months as a learning project but has so far
already released a game jam game: Cognesia.

You can play it here on windows or linux.

![](https://img.itch.zone/aW1hZ2UvMTc2ODYxOS8xMDM5OTAwOC5wbmc=/original/nuQmeN.png)
[https://peterino2.itch.io/cognesia](https://peterino2.itch.io/cognesia)

The intent is to provide a general purpose low overhead gamedev toolkit that I can
use to produce small games with.

And eventually evolve it into a full on game engine for use with creating larger
personal project games for windows linux macos android and any other systems I
can get my hands on.

## Building

`Note: if you want to build, latest integration does not contain the game cognesia,
cognesia is only available on the archive v0.0.0 branch.`

A couple of sample programs ship with the integration branch.

All executables are built under zig-out/bin

```{bash}
git clone https://github.com/peterino2/NeonWood.git --recursive && cd NeonWood
cd engine
zig build install
```

## Engine Highlights

* Highly modular architecture, core renderer handles vulkan majority of systems are
implemented in a game or a project first before being considered for being added to
the core engine.
* Data oriented, major subsystems heavily leverage sparse multisets as a primary container
for object-like data, with object handles being interchangeable between them. (this is a precursor to a more formal ECS)
* Core engine features extensible with an interface idiom.
* No real distinction between game and engine code, The best games are the ones that have
a highly systemic approach to content production.
* Performant. integrates tracy for performance profiling, vulkan for low overhead graphics.
* A job queue dispatch system is available as well for multithreading
* Will be battle tested. I love making games. I intend to actually leverage this engine to
make real and playable games, and prefer to drive feature development by making products.
* Cross platform desktop support with vulkan, and planned webgpu support in the future.
* Will probably get documented all the way through.

## Cognesia Game Features

* Custom scripting language `zig-halcyon` designed for authoring branching dialogue content
* Mixed 2d 3d and sprite based artwork
* Screen effects such as vignette and fading.
* Custom sprite animation system with support for footsteps and animation montage events
* The most ghetto collision and boundary detection system you've ever seen.
* All story content was created in a single afternoon.

## Dependencies

### Windows

* python 3.6+
* lunarg vulkan development libraries ( binaries added to path )
* glslc on your path ( comes with the lunarg vulkan sdk)

### Linux

I will be perfectly honest I do not game on linux and the general ecosystem there seems quite difficult to understand.
for me right now. Its highly unlikely that my linux build works exceptionally well for cross compiling.

I would reccomend compiling and packaging on a linux system directly rather than attempting to cross compile from a windows machine or such.

* Get latest from: [](https://packages.lunarg.com/)

mesa-common-dev is also needed for creating cross platform packages on linux

Eg. for Ubuntu:

```{bash}
wget -qO- https://packages.lunarg.com/lunarg-signing-key-pub.asc | sudo tee /etc/apt/trusted.gpg.d/lunarg.asc
sudo wget -qO /etc/apt/sources.list.d/lunarg-vulkan-1.3.231-jammy.list https://packages.lunarg.com/vulkan/1.3.231/lunarg-vulkan-1.3.231-jammy.list
sudo apt update
sudo apt install vulkan-sdk
```

### Organization, Architecture

The codebase will heavily leverage build.zig as it's master build system.
`modules/` contains core engine code. available for use with all projects.

Because the goal is to bubble features from individual projects into engine.
Games and applications will implement features and systems they need under `projects/\<game name\>/`
first.

(eg Cogensia implements an animated sprite renderer, this is not part of the core engine. But it could be...)

Individual modules start up and are called by the main application via the engine's `start_module()` function.

### Guiding Design and long term vision

I'm honestly a firm believer of the idea that the only flipping thing that matters when it comes to games is **content**.

To produce content in a timely manner you can either throw tons of people at the problem or be ultra focused in the data that you produce for the engine.

If the data going into your engine is in the best format for describing your content, then production will go smoothly.

This runs counter to various larger mainstream game engines' philosophies of providing ultra-flexible tooling for designers and artists. Flexibility magnifies code complexity by orders of magnitude because non technical staff are now responsible for technical decisions while being expected to remain flexible to changing business and design requirements.

This works at AAA companies because of the manpower available, and it allows people with incredible talent to specialize and bring out the best possible in every facet of their craft.

But smaller shops must be far more judicious. To my knowledge there are very few game engines out there that make it easy during design time to specify data requirements and low level systems implementations.

These newer engines like bevy come close but still not quite to the degree that I'm thinking of.

The ideal engine should:

Provide baseline common features such as rendering, physics, graphics, low level networking.

and allow the game programmers to implement systems for their specific game that crunch data for their specific game.

That is, the engine should be just a framework for your core programmming team to specify their runtime and data requirements.


## Libraries and packages used

### Engine

* [zmath](https://github.com/michal-z/zig-gamedev/tree/main/libs/zmath)
* [vulkan-zig bindings by snektron](https://github.com/Snektron/vulkan-zig)
* [miniaudio](https://github.com/mackron/miniaudio)

### Cognesia Game

* [halcyon](https://github.com/peterino2/zig-halcyon)
