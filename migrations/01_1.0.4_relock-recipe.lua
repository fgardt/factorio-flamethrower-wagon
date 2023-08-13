for _idx, force in pairs(game.forces) do
    local techs = force.technologies
    local recipes = force.recipes

    recipes["flamethrower-wagon"].enabled = techs["flamethrower-wagon"].researched
end
