print("hello from sample.lua")

entity = CreateEntity()
component = AddComponent(entity, SampleComponent)
component.setName(name);

-- i guess in this case, the SampleComponent would be a metatable?
