--[[
Small ComputerCraft Lua-script to build simple cubes in an area
author: papumaja
DTFYW
Comes 'as is' with no warranty of any kind yadda yadda
--]]

--[[
Turtle will expect to start at HOME_COORDS (x,y,z),
FACING towards positive z
It will expect to find a fuel chest BELOW
and a material chest ABOVE of HOME_COORDS
]]
HOME_COORDS = {0,0,0}

-- optional phases
PHASE_BUILD_WALLS = true
PHASE_EXCAVATE_INTERIOR = false
PHASE_BUILD_ROOF = false

-- Threshold of inventory stock before refill
REFUEL_THRESHOLD = 5

-- Inventory slot for fuel
FUEL_SLOT = 0

-- Block types used, others picked up in inventory are discarded
BUILD_ID = 0
FUEL_ID = 0

-- Corner points (relative to home) of the rectangle to build
CORNER_NEAR = {0,0,5}
CORNER_FAR = {-20, 5, 10}

-- "enumerators" for possible turtle faces
X_POS = 1
X_NEG = -1
Z_POS = 2
Z_NEG = -2

-- object to store turtle state
Robot = {
    coord = HOME_COORDS,
    face = Z_POS
}

function axis_direction_to_face(axis, direction)
    if axis == 0 and direction = 1 then return X_POS
    elseif axis == 0 and direction = -1 then return X_NEG
    elseif axis == 2 and direction = 1 then return Z_POS
    elseif axis == 2 and direction = -1 then return Z_NEG
    else return false
end

function Robot.move_horizontal(self, direction)
    if direction = 1 then
        if turtle.up() then
            self.coord[1] = self.coord[1] + 1
        else
            return false
        end
    else
        if turtle.down() then
            self.coord[1] = self.coord[1] - 1
        else
            return false
        end
    end
    return true
end

function Robot.move_forward(self, axis, direction)
    -- direction +1 or -1
    -- pre: turtle must face correct direction
    if turtle.forward() then
        self.coord[axis] = self.coord[axis] + direction
    else
        return false
    end
    return true
end

function Robot.update_face_left(self)
    if self.face == Z_POS then self.face = X_NEG
    elseif self.face == X_NEG then self.face = Z_NEG
    elseif self.face == Z_NEG then self.face = X_POS
    elseif self.face == X_POS then self.face = Z_POS
    else return false
end

function Robot.face_axis(self, axis, direction)
    -- 0 = x, 1 = y
    local desired_face = axis_direction_to_face(axis, direction)
    while self.face ~= desired_face
        if turtle.turnLeft() then
            self:update_face_left()
        end
    end
end

function Robot.build_walls(self)
    while true do
        turtle.dig()
    end
end

function main()

    if PHASE_BUILD_WALLS then
        Robot:build_walls(coord)
    end

end

main()
