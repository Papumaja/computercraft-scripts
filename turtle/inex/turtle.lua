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

function print_coords(coord)
    print(coord[1], coord[2], coord[3])
end

function axis_direction_to_face(axis, d)
    if (axis == 1 and d == 1) then return X_POS
    elseif (axis == 1 and d == -1)  then return X_NEG
    elseif (axis == 3 and d == 1) then return Z_POS
    elseif (axis == 3 and d == -1)  then return Z_NEG
    else return false end
end

function normalize_direction(direction)
    local d = 1
    if direction < 0 then d = -1 end
    return d
end

function Robot.move_horizontal(self, direction)
    if direction > 0 then
        if turtle.up() then
            self.coord[2] = self.coord[2] + 1
        else
            return false
        end
    else
        if turtle.down() then
            self.coord[2] = self.coord[2] - 1
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
    else return false end
end

function Robot.face_axis(self, axis, direction)
    -- 0 = x, 1 = y
    local desired_face = axis_direction_to_face(axis, direction)
    while self.face ~= desired_face do
        if turtle.turnLeft() then
            self:update_face_left()
        end
    end
end

function Robot.move_to_coord(self, target_coord, dig_path)
    -- first Y, then X, then Z
    local directions = {
        normalize_direction(target_coord[1] - self.coord[1]),
        normalize_direction(target_coord[2] - self.coord[2]),
        normalize_direction(target_coord[3] - self.coord[3])
    }
    -- Y
    while self.coord[2] ~= target_coord[2] do
        self:move_horizontal(directions[2])
        print_coords(self.coord)
    end
    -- X
    self:face_axis(1, directions[1])
    while self.coord[1] ~= target_coord[1] do
        self:move_forward(1, directions[1])
        print_coords(self.coord)
    end
    -- Z
    self:face_axis(3, directions[3])
    while self.coord[3] ~= target_coord[3] do
        self:move_forward(3, directions[3])
        print_coords(self.coord)
    end

end

function Robot.build_walls(self)
    turtle.refuel(1)
    self:move_to_coord({0, 0, 5}, false)
    self:move_to_coord({-5, 0, 5}, false)
end

function main()

    if PHASE_BUILD_WALLS then
        Robot:build_walls(coord)
    end

end

main()
