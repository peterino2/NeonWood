print("hello from sample.lua")

entity = Entity.new()
scene = entity:addComponent(Scene)
print("original entity position: ", scene:getPosition())
scene:setPosition(Vectorf.new(1, 2, 3))
print("new entity position: ", scene:getPosition())

print(SampleComponent)
component = entity:addComponent(SampleComponent)
component:setName("lmao 3 nova")

print(component)
