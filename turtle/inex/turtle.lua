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

-- Corner points (relative to home) of the rectangle to build
CORNER_NEAR = {0,0,5}
CORNER_FAR = {-20, 5, 10}

-- "enumerators" for possible turtle faces
X_POS = 1
X_NEG = -1
Z_POS = 2
Z_NEG = -2

-- Turtle settings -------------------------------
MAX_FUEL = 160 --turtle.getFuelLimit()
FUEL_ITEM_VALUE = 80
-- Block types used, others picked up in inventory are discarded
BUILD_NAME = "minecraft:stone"
FUEL_NAME = "minecraft:coal"
-- Inventory slot for fuel
FUEL_SLOT = 1
-- Inventory slots for building blocks
BUILD_SLOTS = {2, 3}

--------------------------------------------------

-- object to store turtle state
Robot = {
    coord = {HOME_COORDS[1], HOME_COORDS[2], HOME_COORDS[3]},
    face = Z_POS,
    build_index = 1,
}

---- HELPERS ----------------------------------------------------------------
function add_coords(a, b)
    return {a[1]+b[1], a[2]+b[2], a[3]+b[3]}
end

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
    local d = 0
    if direction > 0 then d = 1
    elseif direction < 0 then d = -1 end
    return d
end

function get_directions(a, b)
    return {
        normalize_direction(b[1] - a[1]),
        normalize_direction(b[2] - a[2]),
        normalize_direction(b[3] - a[3])
    }
end

---- ROBOT METHODS ----------------------------------------------------------

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

    -- TODO: rewrite refueling
    self:refuel_if_need()

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
    local directions = get_directions(self.coord, target_coord)
    -- Y
    while self.coord[2] ~= target_coord[2] do
        self:move_horizontal(directions[2])
        print_coords(self.coord)
    end
    -- X
    while self.coord[1] ~= target_coord[1] do
        self:face_axis(1, directions[1])
        self:move_forward(1, directions[1])
        print_coords(self.coord)
    end
    -- Z
    while self.coord[3] ~= target_coord[3] do
        self:face_axis(3, directions[3])
        self:move_forward(3, directions[3])
        print_coords(self.coord)
    end

end

function Robot.refuel_if_need(self)
    local level = turtle.getFuelLevel()
    local needed = MAX_FUEL - level
    if needed > 0 then
        print("current fuel level=",level)
        print("more fuel needed=",needed)
        local n = math.floor(needed/FUEL_ITEM_VALUE)
        local current_slot = turtle.getSelectedSlot()
        turtle.select(FUEL_SLOT)
        while not turtle.refuel(n) do print("Refueling failed, tried n=",n) end
        -- back to original selected slot
        turtle.select(current_slot)
    end
end

function Robot.restock_if_need(self)
    if self.build_index > table.getn(BUILD_SLOTS) then
        local current_coord = self.coord
        self:go_home_and_restock()
        self:exit_home()
        self:move_to_coord(current_coord)
    end
end

function Robot.select_valid_build_slot(self)
    while true do
        turtle.select(BUILD_SLOTS[self.build_index])
        self:validate_slot(BUILD_NAME)
        local blocks_left = turtle.getItemCount()

        if blocks_left < 1 then
            print("out of blocks from", self.build_index)
            self.build_index = self.build_index + 1
            self:restock_if_need()
        else
            break
        end
    end
end

function Robot.build(self, dig)

    self:select_valid_build_slot()
    if turtle.detectDown() then
        if dig then
            turtle.digDown()
        else
            return
        end
    end

    while not turtle.placeDown() do print("Something blocks placement!") end

end

function Robot.validate_slot(self, item_name)
    -- Discard items in selected slot if name doesn't match
    local data = turtle.getItemDetail()
    if not data then return 0 end
    if data.name ~= item_name then
        turtle.drop()
    end
end

function Robot.restock_fuel(self)
    turtle.select(FUEL_SLOT)
    self:validate_slot(FUEL_NAME)

    local amount = turtle.getItemSpace()
    success = false
    while not success do
        success = turtle.suckDown(amount)
        --print("Sucking fuel from below...")
    end

end

function Robot.restock_blocks(self)
    for i = 1, table.getn(BUILD_SLOTS), 1 do
        turtle.select(BUILD_SLOTS[i])
        self:validate_slot(BUILD_NAME)

        local amount = turtle.getItemSpace()
        success = false
        while not success do
            success = turtle.suckUp(amount)
            --print("Sucking blocks from above...")
        end
    end
    self.build_index = 1
end

function Robot.go_home_and_restock(self)
    self:move_to_coord({HOME_COORDS[1], self.coords[2], HOME_COORDS[3]+2}, false)
    self:move_to_coord(HOME_COORDS, false)
    self:face_axis(3, 1)
    self:restock_fuel()
    self:restock_blocks()
    self:refuel_if_need()
    self:restock_fuel()
end

function Robot.exit_home(self)
    self:face_axis(3, 1)
    self:move_to_coord({HOME_COORDS[1], HOME_COORDS[2], HOME_COORDS[3]+2}, false)
end

function Robot.build_line(self, end_coord, axis)
    local direction = get_directions(self.coord, end_coord)
    self:build(false)
    while self.coord[axis] ~= end_coord[axis] do
        self:move_to_coord(add_coords(self.coord, direction))
        self:build(true)
    end
end

function Robot.build_walls(self)
    self:restock_fuel()
    self:restock_blocks()
    self:refuel_if_need()
    self:restock_fuel()

    self:exit_home()
    --- START ---
    local build_offset = {0, 0, 1} -- vector offset of turtle placing blocks
    local corner_near = add_coords(CORNER_NEAR,build_offset)
    local corner_far = add_coords(CORNER_FAR,build_offset)

    self:move_to_coord(corner_near, false)
    -- while each y-layer
    while self.coord[2] <= corner_far[2] do
        self:build_line({corner_far[1],self.coord[2], corner_near[3]}, 1)
        self:build_line({corner_far[1],self.coord[2], corner_far[3]}, 3)
        self:build_line({corner_near[1],self.coord[2], corner_far[3]}, 1)
        self:build_line({corner_near[1],self.coord[2], corner_near[3]}, 3)
        self:move_horizontal(1)
    end

    --- END ---
    self:go_home_and_restock()
end

function main()

    if PHASE_BUILD_WALLS then
        Robot:build_walls()
    end

end

main()
