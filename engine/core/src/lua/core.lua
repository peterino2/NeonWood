
tickables = {}
properties = {}

local function registerTick(object, f)
    table.insert(tickables, {obj = object, func = f})
end

function __TickScripts(deltaTime)
    for index, entry in ipairs(tickables) do
        entry.func(entry.obj, deltaTime)
    end
end

function __RegisterEntityProperty(userdata)
    properties[userdata] = {}
end

function SetProperty(entity, property)
    properties[entity] = property
end

function GetProperty(entity) 
    return properties[entity]
end

Core = {
    registerTick = registerTick;
}
