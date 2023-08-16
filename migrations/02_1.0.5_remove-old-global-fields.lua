---@type Global
global = global

for _, wagon_data in pairs(global.wagons) do
    wagon_data.front = nil
    wagon_data.last_front_pos = nil
end
