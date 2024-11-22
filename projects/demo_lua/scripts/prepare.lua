
local function tick1(ball, deltaTime)
    local properties = GetProperty(ball)
    properties.ballTime = properties.ballTime + deltaTime * properties.dilation
    properties.ballScene:setPosition(
        properties.rootPosition +
        Vectorf.new(math.sin(properties.ballTime), math.cos(properties.ballTime), 0)
    )
end

local function tick2(ball, deltaTime)
    local properties = GetProperty(ball)
    properties.ballTime = properties.ballTime + deltaTime * properties.dilation
    properties.ballScene:setPosition(
        properties.rootPosition +
        Vectorf.new(math.cos(properties.ballTime), math.sin(properties.ballTime), 0)
    )
end

local ball  = SineBall.create(Vectorf.new(-2, 0, -5),  tick1, 1.0)
local ball2 = SineBall.create(Vectorf.new( 2, 0, -5),  tick2, 1.0)
GetProperty(ball).ballScene:printHandleIndex()
local ball3 = SineBall.create(Vectorf.new( 0, 1, -5), tick1, 40.0)


-- local ballScene = ball:get(Scene)
-- ballScene:setPosition(0, 0, 5)

-- local camera = Flycam.create()
-- lostEmpire = Entity.new()
-- local lostEmpire_scene = lostEmpire:addComponent(Scene)
-- local lostEmpire_mesh = lostEmpire:addComponent(Mesh)
-- mesh:setMesh("m_empire")
-- mesh:setMesh("m_empire")
-- mesh:setTexture("t_texture")

