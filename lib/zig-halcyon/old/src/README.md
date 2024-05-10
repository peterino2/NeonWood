# FactsVM

- halcyon - top level package
    - plumbing
        - halcyon-C - standard C API
        - halcyon-mono - C# assemblies based on halcyon-C
    - storyNode - top level parser and assembler of storyNodes and facts.
        - tokenizer.zig
    - facts.zig - top level database
        - values.zig - implements operations for builtin types and custom values.
        - namespace.zig - accessors, namespaces etc..
    - evaluators.zig - publically facing objects which can be loaded with callbacks and a large number of conditions to check 
      (tens of thousands of conditions can be checked)
    - serialization - utilities to write to and read from bytestreams.
    - lib - optional extensions which impose a bit of a framework and standard structures
        - quest.zig
        - characters.zig


