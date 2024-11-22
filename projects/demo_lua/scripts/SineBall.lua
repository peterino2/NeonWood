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
--
local function tick(ball, deltaTime)
    local properties = GetProperty(ball)
    properties.ballTime = properties.ballTime + deltaTime
    properties.ballScene:setPosition(
        properties.rootPosition +
        Vectorf.new(math.sin(properties.ballTime), math.cos(properties.ballTime), 0)
    )
end

local function create(position, tickFunction, timeDilation)
    local ball = Entity.new()
    print("entity:")
    print(ball)
    local properties = GetProperty(ball)
    properties.dilation = timeDilation
    properties.ballTime = 0.0
    properties.rootPosition = position
    properties.ballScene = ball:addComponent(Scene) -- todo make a getComponent function
    properties.ballScene:printHandleIndex()

    -- todo implement a custom argument type
    properties.ballScene:setPosition(position)

    properties.sm = ball:addComponent(StaticMesh)
    properties.sm:scriptInit()
    properties.sm:setMesh("m_primitive_box")

    Core.registerTick(ball, tickFunction)
    return ball
end

SineBall = {
    create = create;
}

