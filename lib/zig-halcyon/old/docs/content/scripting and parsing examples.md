---
title: Timeline
date: 2022-05-05
author: Peterino
category: Implementation
tags: 
    - Zig
    - Low level programming
state: preview
references: test.md
template: template.html
...

## Timeline

- v0.0.1 Parser and basic story nodes generation
    - generate nodes off of the parser simple example
        - nodes
        - basic links
        - choices
- v0.0.2 variables and scripting
    - vars
    - @set and @vars
    - conditionals
- v0.0.3 Unreal engine API and plugin
    - basic compilation
    - interactor and request API
    - event pump
        - engine tick
- v0.0.4 Imgui/Vulkan C++ node inspector
    - runtime embed into C++ vulkan imgui project
    - automatically display nodes and allow creation of
    - bound .graphproject files
- v0.0.5 debugger interface
    - sockets

## Quest Example

Quest states description. describing the data via json format, lots of changes 
```
QuestDefinition: {
    QuestName: "The tale of the missing shoelace"
    QuestStateListeners: [
        functions
    ]
}

# Quest states

{
    StateName,
    dataStore:{
        Journal: "Journal information"
    }
}
# QuestHandles can move from QuestStateToQuestState.
```

## dialogue script example

```
# all comments can be done this way.

# scripted variables can be imported into a script or they can be defined locally in a script.
# comments can be defined using single line comments like this.

# a vars block can be defined this way to define variables in specific scopes.
# it is reccomended that each script has their own subscope for things that they themselves define
# or to have a master vars.halc file that defines top level variables

@vars( # the vars codeblock is only used for importing and defining variables
    def g.GameLevelVariable :bool = true;           # these are persistent across multiple interactors and are shared between all players
    def p.PlayerLevelVariable :bool = true;         # the p. namespace is persistent for a specific player
    def i.InteractionLevelVariable :bool = true;    # the i. namespace is for variables that exist for the lifetime of one Interactor Only

    import g.SomeImportedVariable: bool;            # this is a variable that this script is expecting to be defined somewhere else.
    import g.SomeImportedVariableWithDefault;
)

`use_vars(my_dialogue.vars) # you could also have something like this to directly use a vars file.

[start] # labels can be assigned to a node
$: Hello! I am the narrator.
$: You can use the dollar sign to signify a line of dialogue.
    You can tab-in with 4 spaces to signify a longer piece of dialogue.

[decision]
$: Do you like cats or dogs?
    // decisions and sublines can be added by tabbing once over.
    > Cats: 
        $ Guess we can't be friends
        @goto leave_disgusted
    > Dogs: 
        @goto dogs // inline comments can be done this way 
    > Both: 
        $: That's incredibly silly. You can't pick both!
        @goto decision

[dogs] 
    $: They taste delicious! // segments of the script can be decorated with tags
    $chong: You take that back! // $$ is the narrator or default voice, $<name> will specify a specific character

[leave_disgusted]
    {
        // code blocks can be executed here.
        disgusted_narrator_callback.execute();
        g.NarratorIsDisgusted = true;
    }
    $$: You leave in disgust @{
        property1 = something,
        property2 = somethingElse,
    }

```

## hmm but what if we wanted to do more scripting? 

Other features that could be added in the content authoring format:
- 
- lore text link pillars of eternity
- targeted introspection like danganronpa
- intertwining with ingame sequences, eg scripted dialogues, character movement, emotes.
- wait for a specific amount of time
- wait for a specific set of conditions
- wait for a specific event

engine specific generics:
- play unreal engine sequencer asset
- execute unreal engine blueprint class/function
- execute unity component function


