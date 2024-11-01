local wagon_util = require("wagon_util")

local horizontal_offset = 2
local vertical_offset = -0.325

local function init()
    ---@type Storage
    storage = storage or {}
    storage.wagons = storage.wagons or {}
    storage.turret2wagon = storage.turret2wagon or {}
end

script.on_init(init)
script.on_configuration_changed(init)

local ev = defines.events

--- create turrets + store wagon info
---@param event
---| EventData.on_built_entity
---| EventData.on_robot_built_entity
---| EventData.script_raised_built
---| EventData.script_raised_revive
local function wagon_built(event)
    local entity = event.entity

    if not entity or not entity.valid then return end
    local surface = entity.surface

    local pos_a, pos_b, orientation = wagon_util.get_positions(entity, horizontal_offset, vertical_offset)

    local other_orient = orientation + 0.5
    if other_orient >= 1 then other_orient = other_orient - 1 end

    local turret_a = surface.create_entity({
        name = "flamethrower-wagon-turret",
        position = pos_a,
        force = entity.force,
        player = entity.last_user,
        create_build_effect_smoke = false,
        direction = wagon_util.orientation2direction(orientation),
        raise_built = false,
    })

    if turret_a == nil then
        entity.destroy({
            raise_destroy = false,
        })
        return
    end

    local turret_b = surface.create_entity({
        name = "flamethrower-wagon-turret",
        position = pos_b,
        force = entity.force,
        player = entity.last_user,
        create_build_effect_smoke = false,
        direction = wagon_util.orientation2direction(other_orient),
        raise_built = false,
    })

    if turret_b == nil then
        turret_a.destroy({
            raise_destroy = false,
        })
        entity.destroy({
            raise_destroy = false,
        })
        return
    end

    local front = entity.train.front_stock ---@type LuaEntity

    storage.wagons[entity.unit_number] = {
        wagon = entity,
        turret_a = turret_a,
        turret_b = turret_b,
        front = front,
        last_front_pos = front.position,
    }

    storage.turret2wagon[turret_a.unit_number] = entity.unit_number
    storage.turret2wagon[turret_b.unit_number] = entity.unit_number

    -- no need to store registration number since wagons / turrets have a unit_number
    script.register_on_object_destroyed(entity)
    script.register_on_object_destroyed(turret_a)
    script.register_on_object_destroyed(turret_b)
end

script.on_event(ev.on_built_entity, wagon_built, { { filter = "name", name = "flamethrower-wagon" } })
script.on_event(ev.on_robot_built_entity, wagon_built, { { filter = "name", name = "flamethrower-wagon" } })
script.on_event(ev.script_raised_built, wagon_built, { { filter = "name", name = "flamethrower-wagon" } })
script.on_event(ev.script_raised_revive, wagon_built, { { filter = "name", name = "flamethrower-wagon" } })


---@param unit_number uint
local function destroy_wagon(unit_number)
    local wagon_data = storage.wagons[unit_number]

    if not wagon_data then
        local wagon_id = storage.turret2wagon[unit_number]

        if not wagon_id then return end

        wagon_data = storage.wagons[wagon_id]
    end

    local wagon = wagon_data.wagon
    local turret_a = wagon_data.turret_a
    local turret_b = wagon_data.turret_b

    if wagon and wagon.valid then
        wagon.destroy()
    end

    if turret_a and turret_a.valid then
        storage.turret2wagon[turret_a.unit_number] = nil
        turret_a.destroy({
            raise_destroy = false,
        })
    end

    if turret_b and turret_b.valid then
        storage.turret2wagon[turret_b.unit_number] = nil
        turret_b.destroy({
            raise_destroy = false,
        })
    end

    storage.wagons[unit_number] = nil
end

script.on_event(ev.on_object_destroyed, function(event)
    if event.type ~= defines.target_type.entity then return end

    destroy_wagon(event.useful_id)
end)

-- turret position updating
script.on_event(ev.on_tick, function(_event)
    for id, wagon_data in pairs(storage.wagons) do
        local wagon = wagon_data.wagon
        local turret_a = wagon_data.turret_a
        local turret_b = wagon_data.turret_b

        if not wagon or not wagon.valid or
            not turret_a or not turret_a.valid or
            not turret_b or not turret_b.valid then
            destroy_wagon(id)
            goto continue
        end

        if wagon.speed == 0 then goto continue end

        local pos_a, pos_b = wagon_util.get_positions(wagon, horizontal_offset, vertical_offset)

        turret_a.teleport(pos_a)
        turret_b.teleport(pos_b)

        ::continue::
    end
end)

-- turret fluid updating

--- fill the fluidbox of a fluid turret
---@param turret LuaEntity FluidTurret to fill
---@param fluid string Fluid name to use
---@param amount double Max amount available to fill with
---@return double transfer_amount Amount of fluid filled
local function fill_turret(turret, fluid, amount)
    if amount == 0 then return 0 end

    local max = turret.fluidbox.get_capacity(1)
    local current = turret.fluidbox[1] --- @type Fluid

    if current == nil then
        current = {
            name = fluid,
            amount = 0,
        }
    end

    local missing = max - current.amount

    if current.name ~= fluid or missing <= 0 then return 0 end

    local transfer_amount = math.min(missing, amount)

    turret.fluidbox[1] = {
        name = fluid,
        amount = current.amount + transfer_amount,
        temperature = current.temperature
    }

    return transfer_amount
end

script.on_nth_tick(30, function(_event)
    for id, wagon_data in pairs(storage.wagons) do
        local wagon = wagon_data.wagon
        local turret_a = wagon_data.turret_a
        local turret_b = wagon_data.turret_b

        if not wagon or not wagon.valid or
            not turret_a or not turret_a.valid or
            not turret_b or not turret_b.valid then
            destroy_wagon(id)
            goto continue
        end

        local available --- @type double
        local fluid     --- @type string

        for f, a in pairs(wagon.get_fluid_contents()) do
            fluid = f
            available = a
        end

        -- flush turrets if tank is empty
        if available == nil or available == 0 then
            turret_a.fluidbox.flush(1)
            turret_b.fluidbox.flush(1)
            goto continue
        end

        if fluid == nil then goto continue end

        local transfer_a = fill_turret(turret_a, fluid, available)
        local transfer_b = fill_turret(turret_b, fluid, available - transfer_a)

        local removed = transfer_a + transfer_b

        if removed > 0 then
            wagon.remove_fluid({
                name = fluid,
                amount = removed,
            })
        end

        ::continue::
    end
end)


-- handle cloning

---@param event EventData.on_entity_cloned
local function wagon_cloned(event)
    local new_wagon = event.destination
    local old_wagon = event.source
    local old_data = storage.wagons[ old_wagon.unit_number --[[@as uint]] ]
    local old_turret_a = old_data.turret_a
    local old_turret_b = old_data.turret_b

    if not old_turret_a or not old_turret_a.valid or
        not old_turret_b or not old_turret_b.valid then
        event.destination.destroy({
            raise_destroy = false,
        })
        destroy_wagon(old_wagon.unit_number)
        return
    end

    local pos_a, pos_b = wagon_util.get_positions(new_wagon, horizontal_offset, vertical_offset)

    local new_turret_a = old_turret_a.clone({
        position = pos_a,
        surface = new_wagon.surface,
        force = new_wagon.force,
        create_build_effect_smoke = false,
    })

    if not new_turret_a or not new_turret_a.valid then
        event.destination.destroy({
            raise_destroy = false,
        })
        destroy_wagon(old_wagon.unit_number)
        return
    end

    local new_turret_b = old_turret_b.clone({
        position = pos_b,
        surface = new_wagon.surface,
        force = new_wagon.force,
        create_build_effect_smoke = false,
    })

    if not new_turret_b or not new_turret_b.valid then
        new_turret_a.destroy({
            raise_destroy = false,
        })
        event.destination.destroy({
            raise_destroy = false,
        })
        destroy_wagon(old_wagon.unit_number)
        return
    end

    storage.wagons[ new_wagon.unit_number --[[@as uint]] ] = {
        wagon = new_wagon,
        turret_a = new_turret_a,
        turret_b = new_turret_b,
    }

    storage.turret2wagon[new_turret_a.unit_number] = new_wagon.unit_number
    storage.turret2wagon[new_turret_b.unit_number] = new_wagon.unit_number

    -- no need to store registration number since wagons / turrets have a unit_number
    script.register_on_object_destroyed(new_wagon)
    script.register_on_object_destroyed(new_turret_a)
    script.register_on_object_destroyed(new_turret_b)

    destroy_wagon(old_wagon.unit_number)
end

script.on_event(ev.on_entity_cloned, wagon_cloned, { { filter = "name", name = "flamethrower-wagon" } })
