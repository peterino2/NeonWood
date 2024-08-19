print("hello world")
helloZig()

local x = addFunc(2, 3)

print(x)

function fact(n)
    if n == 0 then
        return 1
    else
        return n * fact(n - 1)
    end
end

print(fact(4))

-- print("vector new")
v = vector.new(1, 2, 3)
-- print("vector as string")
print(v)
print(v[1])
print(v[2])
print(v[3])

v[3] = 420
print("magnitude =", v:magnitude())

v2 = vector.new({x = 4, z = 6, y = 3})
v3 = vector.new()
-- print("vector as string")
print(v2)

v[3] = 420
print("magnitude =", v2:magnitude())

v4 = v2 + v;
print(v4)
v4.x = 12;
print(v4.x, v4)
-- vector.set(v, 3, 12.0)
-- print(vector.string(v))
-- print(vector.size(v))
-- 
-- v2 = vector.new()
-- vector.set(v2, 1, 4)
-- vector.set(v2, 2, 5)
-- vector.set(v2, 3, 6)
-- 
-- print(vector.string(v2))
-- 
-- ok how should this work 

