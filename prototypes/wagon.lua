local item = table.deepcopy(data.raw["item-with-entity-data"]["fluid-wagon"])
item.name = "flamethrower-wagon"
item.order = "c[rolling-stock]-d[aaflamethrower-wagon]"
item.place_result = "flamethrower-wagon"
item.localised_name = { "entity-name.flamethrower-wagon" }
item.localised_description = { "entity-description.flamethrower-wagon" }
item.icon = "__flamethrower-wagon__/graphics/icon.png"
item.icon_size = 64
item.icon_mipmaps = 4

local entity = table.deepcopy(data.raw["fluid-wagon"]["fluid-wagon"])
entity.name = "flamethrower-wagon"
entity.minable.result = "flamethrower-wagon"
entity.icon = "__flamethrower-wagon__/graphics/icon.png"
entity.icon_size = 64
entity.icon_mipmaps = 4
entity.minimap_representation = {
    filename = "__flamethrower-wagon__/graphics/minimap-representation.png",
    flags = { "icon" },
    size = { 20, 40 },
    scale = 0.5
}
entity.selected_minimap_representation = {
    filename = "__flamethrower-wagon__/graphics/selected-minimap-representation.png",
    flags = { "icon" },
    size = { 20, 40 },
    scale = 0.5
}
entity.allow_passengers = false
entity.tank_count = 1
entity.capacity = 8000
entity.max_health = 800
local fire_resistance = entity.resistances[1]
fire_resistance.decrease = nil
fire_resistance.percent = 100

local recipe = table.deepcopy(data.raw.recipe["fluid-wagon"])
recipe.name = "flamethrower-wagon"
recipe.results = { { type = "item", name = "flamethrower-wagon", amount = 1 } }
recipe.localised_name = { "entity-name.flamethrower-wagon" }
recipe.ingredients = {
    { type = "item", name = "fluid-wagon",         amount = 1 },
    { type = "item", name = "flamethrower-turret", amount = 2 },
    { type = "item", name = "engine-unit",         amount = 6 },
    { type = "item", name = "steel-plate",         amount = 10 },
}

local technology = table.deepcopy(data.raw.technology["flamethrower"])
technology.name = "flamethrower-wagon"
technology.prerequisites = {
    "fluid-wagon",
    "flamethrower",
    "chemical-science-pack",
}
technology.icon = "__flamethrower-wagon__/graphics/technology.png"
technology.icon_size = 256
technology.icon_mipmaps = 4
technology.unit = {
    count = 350,
    ingredients = {
        { "automation-science-pack", 1 },
        { "logistic-science-pack",   1 },
        { "chemical-science-pack",   1 },
        { "military-science-pack",   1 }
    },
    time = 30
}
technology.effects = {
    {
        type = "unlock-recipe",
        recipe = "flamethrower-wagon"
    }
}

data:extend({ entity, item, recipe, technology })
