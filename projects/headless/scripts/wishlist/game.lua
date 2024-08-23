
function initPlayer() 
    player = core.newEntity()
    player:addComponent(FirstPersonComponent)
    player:addComponent(Transform)
    player:addComponent(Rendering)
    player:addComponent(Mesh)
    player:addComponent(Physics)

    initHud()
end

function initHud()
    hud = core.newEntity()
    hud:addComponent(UI)

    local panel = hud.get(UI):addPanel()
    panel:setSize(200, 150)
    panel:back()
end
