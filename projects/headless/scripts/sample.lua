print("hello from sample.lua")

entity = Entity.new()
print(SampleComponent)
component = entity:addComponent(SampleComponent)
component:setName("lmao 3 nova")

print(component)
