local util = {}

--- convert RealOrientation to radians
---@param orientation float
---@return RealOrientation
local function orientation2rad(orientation)
    return orientation * 2 * math.pi
end

--- check if target is facing the same way as front
---@param target LuaEntity
---@param front LuaEntity
---@param train LuaTrain
---@return boolean
local function facing_same_way_as_front(target, front, train)
    if target == front then return true end

    -- check if front is facing backwards or not
    local fe, _fd = front.get_connected_rolling_stock(defines.rail_direction.front)
    local front_facing_front = fe == nil

    -- get carriage in front direction
    local tfe, _tfd = target.get_connected_rolling_stock(defines.rail_direction.front)
    local tfe_pos = -1
    local target_pos = -1

    -- facing backwards
    if tfe == nil then return not front_facing_front end

    -- get indexes of the carriages
    for idx, carriage in pairs(train.carriages) do
        if carriage == tfe then
            tfe_pos = idx
        elseif carriage == target then
            target_pos = idx
        end

        if tfe_pos ~= -1 and target_pos ~= -1 then
            break
        end
    end

    return front_facing_front == (tfe_pos < target_pos)
end

--- calculate train wagon sprite shift amount
---@param wagon LuaEntity Wagon to get the shift for
---@return number shift_amount, RealOrientation orientation amount to shift and shifted orientation
local function get_shift(wagon)
    if not wagon or not wagon.valid then return 0, 0 end

    -- is not exposed :( (yet, 1.1.89 does expose it, boskid <3)
    --local base_shift = entity.prototype.vertical_selection_shift
    local base_shift = -0.796875

    local train = wagon.train

    if not train or not train.valid then return base_shift, wagon.orientation end

    local front = train.front_stock

    if not front or not front.valid then return base_shift, wagon.orientation end

    -- check if entity and front are facing the same way
    -- 1.1.89: entity.is_headed_to_trains_front (boskid <3)
    local shift_direction = 1

    if not facing_same_way_as_front(wagon, front, train) then
        shift_direction = -1
    end

    -- selection box orientation might be nil if vertical
    local orientation = wagon.selection_box.orientation
    if orientation == nil then
        local entity_orient = wagon.orientation
        if entity_orient < 0.25 or entity_orient > 0.75 then
            orientation = 0
        else
            orientation = 0.5
        end
    end

    return base_shift * shift_direction * math.cos(orientation2rad(front.orientation)), orientation
end

---@param entity LuaEntity
---@param color Color?
---@param move number?
local function draw_circ(entity, color, move)
    if not entity or not entity.valid then return end

    local offset = {
        x = 0,
        y = 0,
    }

    if color == nil then
        color = {
            r = 0,
            g = 1,
            b = 1,
            a = 1
        }
    end

    if move ~= nil then
        local orientation = entity.selection_box.orientation
        if orientation == nil then
            local entity_orient = entity.orientation
            if entity_orient < 0.25 or entity_orient > 0.75 then
                orientation = 0
            else
                orientation = 0.5
            end
        end

        local rad = orientation * 2 * math.pi
        local cos = math.cos(rad)
        local sin = math.sin(rad)

        offset.x = offset.x + move * sin
        offset.y = offset.y + move * -cos
    end

    rendering.draw_circle({
        surface = entity.surface,
        time_to_live = 2,
        color = color,
        radius = 0.5,
        width = 2,
        filled = false,
        target = entity,
        target_offset = offset,
    })
end

---@param wagon LuaEntity Wagon to get the positions for
---@param horizontal number Horizontal offset from center
---@param vertical number Vertical offset
---@return MapPosition, MapPosition, RealOrientation
util.get_positions = function(wagon, horizontal, vertical)
    local shift_amount, orientation = get_shift(wagon)

    -- draw_circ(wagon, { r = 1, g = 0, b = 0, a = 1 }, shift_amount)
    -- draw_circ(wagon, { r = 0, g = 1, b = 0, a = 1 }, shift_amount + horizontal)
    -- draw_circ(wagon, { r = 0, g = 1, b = 1, a = 1 }, shift_amount - horizontal)

    local rad = orientation2rad(orientation)
    local cos = math.cos(rad)
    local sin = math.sin(rad)

    local shifted_speed = shift_amount + (wagon.speed or 0)
    local full1 = shifted_speed + horizontal
    local full2 = shifted_speed - horizontal

    local x1 = full1 * sin
    local y1 = full1 * -cos
    local x2 = full2 * sin
    local y2 = full2 * -cos

    local pos = wagon.position

    return { pos.x + x1, pos.y + y1 + vertical }, { pos.x + x2, pos.y + y2 + vertical }, orientation
end

---@param orientation RealOrientation
---@return defines.direction
util.orientation2direction = function(orientation)
    if orientation <= 0.125 or orientation > 0.875 then
        return defines.direction.north
    elseif orientation <= 0.375 then
        return defines.direction.east
    elseif orientation <= 0.625 then
        return defines.direction.south
    else
        return defines.direction.west
    end
end

return util
