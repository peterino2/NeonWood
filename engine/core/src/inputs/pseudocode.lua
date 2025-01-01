
moveAxis = CreateInput2DAxis()
moveAxis:addKey(Keys.W, 1.0, Axis.Y)
moveAxis:addKey(Keys.S, -1.0, Axis.Y)

moveAxis:addKey(Keys.A, -1.0, Axis.X)
moveAxis:addKey(Keys.D, 1.0, Axis.X)

Input.addBinding("move", moveAxis, true)

Input.removeBinding("move")


