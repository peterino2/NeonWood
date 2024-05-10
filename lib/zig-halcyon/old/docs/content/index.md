---
title: Overview
date: 2022-05-05
author: Peterino
category: Implementation
tags: 
    - Zig
    - Low level programming
state: posted
references: test.md
template: template.html
...

# Overview 

Halcyon is the ultimate script for producing rich and reactive interactive fiction.

Here's what we aim to provide. By v0.5.0.

#### 📜 A simple language

- Inspired by Renpy, author content in a syntax that is a joy to write in.
- Incredibly powerful yet simple. Mix scripting with manuscript on the fly.
- Text-based source file management.

```
George: Hello! how are you?
    > Emilia: I'm doing great!
        George: Wonderful!
    > Emilia: Uhh not so well.
        George: Huh, well why don't you tell me what's going on?
        @goto emilia_explains_her_problem
```

#### 📜 A beautiful runtime

- Games are demanding for performance. Thats why this runtime is natively written in zig ⚡, it features no garbage collection, minimal memory footprint, and puts you in charge of it's compute.
- Don't pay for what you don't use, the event system and debug features can be completely turned off.
- A lighting fast data oriented runtime with an ECS architecture, hot-reload scripts while you're playing.
- No dependencies. Other than a tiny static link to the zig standard library, no messy dependencies are brought into your system.

#### 📜 Debugging for everyone

- Full featured debugging. Debug game instances, step forward, and backwards, edit quest facts.
- Connect to remote instances via a debug server.
- Debug multiplayer sessions, save and load gamestates.
- Play and write at the same time, take seconds not hours to iterate.

#### 📜 Quality at every step of production
- Databases and spreadsheets for localization can be generated with a click of a button. All text is locally tagged with keys for localization.
- Manage auxilary content such as recordings directly within project files.
- Bake and cook entire games with hundreds of thousands of lines of text into compact, production ready shippable binaries.
- A goal of this project is to be in use by AA and AAA releases.

#### 📜 Seamless integration with your projects
- Plugins and prebuilt packages for Unreal Engine and Unity will be available.
- Sane defaults and rich examples lets you get started with writing right away.

#### 📜 An open ecosystem
- Written in zig, a next-generation systems programming language that provides actual super powers.
- The runtime cross compiles for all modern systems including android, IOS and Consoles (bring your own sdk if you got one).
- The runtime and parser are entirely open source.
- Bindings planned for more languages and frameworks.

### Development

The tool is currently in development by just me, Peterino. I am an engine and tools developer who works in the AAA gamedev space and wanted to have an elegant solution for my personal projects that is comparable or better to the tools I am familiar with at work.

The tool is undergoing heavy development and is not publically available (yet).
