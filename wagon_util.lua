local util = {}

--- convert RealOrientation to radians
---@param orientation float
---@return RealOrientation
local function orientation2rad(orientation)
    return orientation * 2 * math.pi
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
    local draw_data = wagon.draw_data
    local orientation = draw_data.orientation
    local pos = draw_data.position

    local rad = orientation2rad(orientation)
    local cos = math.cos(rad)
    local sin = math.sin(rad)

    local speed = wagon.speed or 0
    local full1 = speed + horizontal
    local full2 = speed - horizontal

    local x1 = full1 * sin
    local y1 = full1 * -cos
    local x2 = full2 * sin
    local y2 = full2 * -cos

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
