---
title: Language Overview
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

# The language
The scripting language is loosely inspired by renpy. To declare a stream of dialogue, simply write it like thus.

```
PersonA: Hello! Great day isn't it?
PersonB: Man.. I really hate the way you talk so nicely.
PersonA: Haha you sure got me there! I really am a nice person.
PersonB: Get the hell away from me.
```


Dialogues can be written with with just the format \[Speaker\] : \[content\]
and each dialogue ends with a newline.

```
PersonA: This is a really long piece of dialogue 
: So I can extend it like this
```

### Conditionals

Single dialogue can be decorated with an if statement.

```
@if(PersonA_is_pissed)
PersonA: I am pissed off
PersonA: I will say this line regardless of if I'm pissed off or not.
```

Groups of dialogues can be gated by a tab-indent statements.

```
@if(PersonA_is_pissed)
    PersonA: I am really pissed off
    PersonB: If you're pissed off so am I!
PersonA: I will say this line regardless of if I'm pissed off or not.
```


### Variables

Variables are defined or imported at the top of each .halc file. with the `@vars` directive.

```
@vars(
    import PersonA; # This imports the PersonA namespace 
    # This defines a variable in the PersonA namespace
    def PersonAIsPissed = false; 
    # This defines a variable in the PersonA namespace
    def PersonA.isPissed = false; 
    # generally I'd recommend having the character definition 
    # wherever it is also defining all of it's variables

    # if def for the same variable from a global namespace name
    # is called more than once
)
```

#### namespaces

```
@vars{
    namespace PersonA{ 
        # this defines a namespace and can be accessed via a dot specifier.
        
    };
}
```

#### characters

To define a character, you declare it in a `@vars` like this.

The `name` variable will be used for the speaker name.

```
@vars {
    character PersonA { 
        def name = "I have a really long name"; 
    };
}
```


## The Runtime

`Warning, nerd stuff ahead!`

#### language runtime in detail

```
@if(PersonA_is_pissed)
PersonA: I am pissed off
PersonA: I will say this line regardless of if I'm pissed off or not.
```

<center><img  src="$ASSETPATH()/Lang_0.png" class="centerImage" width ="300"></center>

```
@if(PersonA_is_pissed)
    PersonA: I am really pissed off.
    PersonB: If you're pissed off so am I!
PersonA: I will say this line regardless of if I'm pissed off or not.
```


<center><img  src="$ASSETPATH()/Lang_1.png" class="centerImage" width ="300"></center>
