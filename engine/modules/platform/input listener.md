

Lets architect an input listener yeah?

What kind of API do I specifically want?

I think I definitely want an object oriented API.
Probably primarily working with handles.

I want the main event loop to be like

User makes input
Input goes to input queue
input queue parses all input contexts and... 
forwards all inputs to the respective listeners.

A listener is just a simple struct which contains a listener interface.
hmm.. 

I think just a simple listener interface is going to be far too simple.

Ideally for a given program.

I'd like to do a very data driven way of setting up the actual inputs.

For games this is pretty straight forward as we know what kind of things can be done in 
the game without much issue, games don't have advanced OS-like behavior

While desktop UI systems do.

User makes input
Input goes to input queue
Input queue parses all input contexts and
forwards all inputs to the respective listeners.
    - Application input context
    - Game input system

the input function


```zig

const InputAction = struct {
    name: LocText,
    
    activations: ArrayListUnmanaged(PhysicalInput),
};


const MyGameSystem  = struct {
    
    handleJumpBinding: InputBinding,
    
    pub fn setupInputBunding(self: *@This()) !void
    {
        self.handleJumpBinding = input.bindAction(self, , @This().handleJumpInput);
        input.getBinding(self.handleJumpBinding).setPriority(64); // higher priority gets first consumption
    }

    pub fn handleJumpInput(input: InputAction) !bool
    {
        switch(input)
        {
            .button => {
                return true;
            },
            else => {}
        }

        return false;
    }
};

```
