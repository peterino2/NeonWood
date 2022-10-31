# NeonWood Game Engine

This is a vulkan based gamedev toolkit targeting the vulkan renderer for now.
It's been written over the last two months as a learning project but has so far 
already released a game jam game: Cognesia. 

You can play it here: 

The intent is to provide a general purpose low overhead gamedev toolkit that I can 
use to produce small games with.

And eventually evolve it into a full on game engine for use with creating larger
personal project games for windows linux macos android and any other systems I
can get my hands on.


# Building

A couple of sample programs ship with the integration branch. They include a 
multithreaded job dispatch test, an imgui test with support for docking.

And the gamejam game `cognesia`

# Features

* Highly modular

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


# Dependencies

## Windows:

- python 3.6+
- lunarg vulkan development libraries ( binaries added to path )
- glslc on your path

## Linux: 

# Building

## Linux

- get latest from:
https://packages.lunarg.com/

mesa-common-dev is also needed for creating cross platform packages on linux

or rip :

```
wget -qO- https://packages.lunarg.com/lunarg-signing-key-pub.asc | sudo tee /etc/apt/trusted.gpg.d/lunarg.asc
sudo wget -qO /etc/apt/sources.list.d/lunarg-vulkan-1.3.231-jammy.list https://packages.lunarg.com/vulkan/1.3.231/lunarg-vulkan-1.3.231-jammy.list
sudo apt update
sudo apt install vulkan-sdk
```