--[[
Small ComputerCraft Lua-script to build simple shapes in an area
author: papumaja
DTFYW
Comes 'as is' with no warranty of any kind yadda yadda
--]]

--[[
Turtle will expect to start at HOME_COORDS (x,y,z),
FACING towards positive z
It will expect to find a fuel chest BELOW
and a material chest ABOVE of HOME_COORDS
Building schematics should leave turtle ALWAYS having free space above it
]]
HOME_COORDS = {30,74,-301}

-- optional phases
PHASE_BUILD_WALLS = true

-- Corner points (relative to home) of the rectangle to build
CORNER_NEAR = {25,66,-247}
CORNER_FAR = {-95, 66, -367}
--CORNER_FAR = {22, 70, -241}

-- "enumerators" for possible turtle faces
X_POS = 1
X_NEG = -1
Z_POS = 2
Z_NEG = -2
INITIAL_FACE = X_NEG

-- Turtle settings -------------------------------
MAX_FUEL = 1000 --turtle.getFuelLimit()
FUEL_ITEM_VALUE = 80
-- Will break obstructions
BREAK_THINGS = true
BREAK_THINGS_GOING_HOME = true
-- Block types used, others picked up in inventory are discarded
BUILD_NAME = "minecraft:stone"
FUEL_NAME = "minecraft:coal"
-- Inventory slot for fuel
FUEL_SLOT = 1
-- Threshold of inventory stock before refill
REFUEL_THRESHOLD = 5
-- Inventory slots for building blocks
BUILD_SLOTS = {2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}

--------------------------------------------------

-- object to store turtle state
Robot = {
    coord = {HOME_COORDS[1], HOME_COORDS[2], HOME_COORDS[3]},
    face = INITIAL_FACE,
    build_index = 1,
    refueling = false
}

---- HELPERS ----------------------------------------------------------------
function add_coords(a, b)
    return {a[1]+b[1], a[2]+b[2], a[3]+b[3]}
end

function substract_coords(a, b)
    return {a[1]-b[1], a[2]-b[2], a[3]-b[3]}
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

function face_to_axis_direction(face)
    if face == X_POS then return 1, 1
    elseif face == X_NEG then return 1, -1
    elseif face == Z_POS then return 3, 1
    elseif face == Z_NEG then return 3, -1
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

function Robot.move_horizontal(self, direction, dig_path)
    if direction > 0 then
        if turtle.up() then
            self.coord[2] = self.coord[2] + 1
        else
            if dig_path then turtle.digUp() end
            return false
        end
    else
        if turtle.down() then
            self.coord[2] = self.coord[2] - 1
        else
            if dig_path then turtle.digDown() end
            return false
        end
    end
    return true
end

function Robot.move_forward(self, axis, direction, dig_path)
    -- direction +1 or -1
    -- pre: turtle must face correct direction
    if turtle.forward() then
        self.coord[axis] = self.coord[axis] + direction
    else
        if dig_path then turtle.dig() end
        return false
    end

    -- TODO: rewrite refueling
    self:refuel_if_need()

    return true
end

function Robot.update_face_left(self)
    if self.face == Z_NEG then self.face = X_NEG
    elseif self.face == X_NEG then self.face = Z_POS
    elseif self.face == Z_POS then self.face = X_POS
    elseif self.face == X_POS then self.face = Z_NEG
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
        self:move_horizontal(directions[2], dig_path)
        print_coords(self.coord)
    end
    -- X
    while self.coord[1] ~= target_coord[1] do
        self:face_axis(1, directions[1])
        self:move_forward(1, directions[1], dig_path)
        print_coords(self.coord)
    end
    -- Z
    while self.coord[3] ~= target_coord[3] do
        self:face_axis(3, directions[3])
        self:move_forward(3, directions[3], dig_path)
        print_coords(self.coord)
    end

end

function Robot.restock_fuel_if_need(self)
    -- already on a restocking trip, don't recurse hang
    if self.refueling then return end

    local current_slot = turtle.getSelectedSlot()
    turtle.select(FUEL_SLOT)
    if turtle.getItemCount() < REFUEL_THRESHOLD then
        self.refueling = true
        local current_coord = {self.coord[1], self.coord[2], self.coord[3]}
        self:go_home_and_restock()
        self:exit_home()
        self:move_to_coord(current_coord)
        self.refueling = false
    end
    turtle.select(current_slot)
end

function Robot.restock_if_need(self)
    if self.build_index > table.getn(BUILD_SLOTS) then
        local current_coord = {self.coord[1], self.coord[2], self.coord[3]}
        self:go_home_and_restock()
        self:exit_home()
        self:move_to_coord(current_coord)
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
        turtle.refuel(n)
        self:restock_fuel_if_need()
        -- back to original selected slot
        turtle.select(current_slot)
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

function Robot.home_enter_node(self)
    local exit_offset = {0,0,0}
    local axis, d = face_to_axis_direction(INITIAL_FACE)
    exit_offset[axis] = exit_offset[axis] + 2*d
    return add_coords(HOME_COORDS, exit_offset)
end

function Robot.go_home_and_restock(self)
    local enter_node = self:home_enter_node()
    local return_h = math.max(self.coord[2], enter_node[2])
    enter_node = add_coords(enter_node, {0,return_h,0})
    self:move_to_coord(self:home_enter_node(), BREAK_THINGS_GOING_HOME)
    self:move_to_coord(HOME_COORDS, false)
    self:face_axis(face_to_axis_direction(INITIAL_FACE))
    self:restock_fuel()
    self:restock_blocks()
    self:refuel_if_need()
    self:restock_fuel()
end

function Robot.exit_home(self)
    self:face_axis(face_to_axis_direction(INITIAL_FACE))
    self:move_to_coord(self:home_enter_node(), false)
end

function Robot.build_line(self, end_coord, axis)
    local direction = get_directions(self.coord, end_coord)
    self:build(false)
    while self.coord[axis] ~= end_coord[axis] do
        self:move_to_coord(add_coords(self.coord, direction), BREAK_THINGS)
        self:build(true)
    end
end

function Robot.build_object(self, schematic)
    self:restock_fuel()
    self:restock_blocks()
    self:refuel_if_need()
    self:restock_fuel()

    self:exit_home()
    --- START ---
    local build_offset = {0, 0, 1} -- vector offset of turtle placing blocks

    -- place each block
    while true do
        local _, coord = coroutine.resume(schematic, CORNER_NEAR, CORNER_FAR)
        print(coord)
        if coord then
            print(coord)
            self:move_to_coord(add_coords(coord, build_offset), BREAK_THINGS)
            self:build(BREAK_THINGS)
        else
            break
        end
    end

    --- END ---
    self:go_home_and_restock()
end

function pyramid_schematic(near, far)
    -- yields coordinates from pyramid schematic one by one
    --local layers = {}
    local bottom_y = near[2]
    local y = bottom_y
    local directions = get_directions(near, far)
    while true do
        --layer = {}
        -- x-side 1 (not both in same loop to optimize building order)
        for x = near[1], far[1], directions[1] do
            --table.insert(layer, {x, y, near[3]})
            coroutine.yield({x, y, near[3]})
        end
        -- z-side 1
        for z = near[3], far[3], directions[3] do
            --table.insert(layer, {far[1], y, z})
            coroutine.yield({far[1], y, z})
        end
        -- x-side 2
        for x = far[1], near[1], -directions[1] do
            --table.insert(layer, {x, y, far[3]})
            coroutine.yield({x, y, far[3]})
        end
        -- z-side 2
        for z = far[3], near[3], -directions[3] do
            --table.insert(layer, {near[1], y, z})
            coroutine.yield({near[1], y, z})
        end
        -- append layer
        -- table.insert(layers, layer)

        -- final layer, break out
        final_x = (far[1] - near[1])*directions[1] <= 0
        final_z = (far[3] - near[3])*directions[3] <= 0
        if final_x or final_y then
            break
        end

        -- update square coords
        near = add_coords(near, directions)
        far = substract_coords(far, directions)
        y = y+1
    end

    --return layers
    return false
end

function main()
    local schematic = coroutine.create(pyramid_schematic)

    if PHASE_BUILD_WALLS then
        Robot:build_object(schematic)
    end

end

main()
