-- an ball that moves back and forth


-- how do i like to do this ... 
--
-- on the zig side of things. 
--
-- i would create an entity and add it to a global variable
-- but this setup has no concept of objects or content management

-- ideally the best way to do this would be something like
-- 1. define the type and behaviours
--      object.lua -> create()
-- 2. instantiate the entity
-- 3. register a tick for the entity
-- 4. do things.
--
-- ok that works

function create()
    local ball = Entity.new()
    local transform = ball:addComponent(Transform)
    transform:setPosition(0,0,0)
    Systems.registerTick(ball, tick)
end

function tick(ball, deltaTime)
    print("tick")
end
