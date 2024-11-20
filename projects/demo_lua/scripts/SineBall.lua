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

local function create(position)
    local ball = Entity.new()

    ballScene = ball:addComponent(Scene) -- todo make a getComponent function
    -- todo implement a custom argument type
    ballScene:setPosition(position)

    local sm = ball:addComponent(StaticMesh)
    sm:scriptInit()
    sm:setMesh("m_primitive_sphere")

    Systems.registerTick(ball, tick)
    return ball
end

ballTime = 0

local function tick(ball, deltaTime)
    ballTime = ballTime + deltaTime
    print("tick")
    ballScene:setPosition(math.sin(time), 0, -5)
end

SineBall = {
    create = create;
}

