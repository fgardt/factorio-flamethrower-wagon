local function apply_shift(shift, shift_x, shift_y)
    local tmp = util.by_pixel(shift_x, shift_y)

    shift[1] = shift[1] + tmp[1]
    shift[2] = shift[2] + tmp[2]
end

local function apply_shift_sprite(sprite, shift_x, shift_y)
    apply_shift(sprite.shift, shift_x, shift_y)

    if sprite.hr_version ~= nil then
        apply_shift(sprite.hr_version.shift, shift_x, shift_y)
    end
end

local function apply_shift_layers(direction_layer, shift_x, shift_y)
    local layer = direction_layer.layers

    for _, sprite in pairs(layer) do
        apply_shift_sprite(sprite, shift_x, shift_y)
    end
end

local function shift_direction(entity, direction_name, shift_x, shift_y)
    apply_shift_layers(entity.attacking_animation[direction_name], shift_x, shift_y)
    apply_shift_layers(entity.ending_attack_animation[direction_name], shift_x, shift_y)
    apply_shift_layers(entity.folded_animation[direction_name], shift_x, shift_y)
    apply_shift_layers(entity.folding_animation[direction_name], shift_x, shift_y)
    apply_shift_layers(entity.prepared_animation[direction_name], shift_x, shift_y)
    apply_shift_layers(entity.preparing_animation[direction_name], shift_x, shift_y)

    apply_shift(entity.attack_parameters.gun_center_shift[direction_name], shift_x, shift_y)
    apply_shift(entity.attacking_muzzle_animation_shift.direction_shift[direction_name], shift_x, shift_y)
end

local turret = table.deepcopy(data.raw["fluid-turret"]["flamethrower-turret"])
turret.name = "flamethrower-wagon-turret"
turret.minable = table.deepcopy(data.raw["fluid-wagon"]["flamethrower-wagon"].minableinable)

turret.attack_parameters.range = 30
turret.attack_parameters.min_range = 2.5
turret.attack_parameters.turn_range = 1
turret.attack_parameters.lead_target_for_projectile_speed = 0.225 * 1.5

turret.prepare_range = 50
turret.preparing_speed = 0.06
turret.rotation_speed = 0.0225

turret.fluid_box.hide_connection_info = true
turret.fluid_box.production_type = "input-output"
turret.fluid_box.pipe_covers = nil
turret.fluid_box.pipe_connections = { { position = { 0, 1.25 } } }
turret.fluid_box.height = 0.25
turret.fluid_buffer_size = 25
turret.fluid_buffer_input_flow = 1

turret.collision_box = { { -0.75, -0.75 }, { 0.75, 0.75 } }
turret.selection_box = { { -0.85, -0.85 }, { 0.85, 0.85 } }
turret.drawing_box = { { -1.5, -2.5 }, { 1.5, 0 } }
turret.selection_priority = 100
turret.collision_mask = { "train-layer" }
turret.flags = {
    "player-creation",
    "placeable-off-grid",
    "not-on-map",
    -- "not-repairable",
    "not-upgradable",
    "not-blueprintable",
    -- "not-deconstructable",
}

turret.enough_fuel_indicator_light = nil
turret.enough_fuel_indicator_picture = nil
turret.not_enough_fuel_indicator_light = nil
turret.not_enough_fuel_indicator_picture = nil

turret.gun_animation_render_layer = "higher-object-under"

turret.base_picture = nil
turret.turret_base_has_direction = true -- required

--turret.alert_icon_shift = { 0, 1 }

shift_direction(turret, "north", 0, 15 - 32)
shift_direction(turret, "east", -18.5, -0.5 - 32)
shift_direction(turret, "south", 0, -10 - 32)
shift_direction(turret, "west", 12, 3.5 - 32)

data:extend({ turret })
