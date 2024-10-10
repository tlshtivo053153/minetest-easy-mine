local tool_type = {
    "pick",
    "shovel",
    "axe",
    "sword"
}

local tool_material = {
    "wood",
    "stone",
    "bronze",
    "steel",
    "mese",
    "diamond"
}

for _, type in pairs(tool_type) do
    for _, material in pairs(tool_material) do
        local tool_name = "default:" .. type .. "_" .. material
        local old_def = minetest.registered_tools[tool_name]
        local old_on_place = old_def.on_place
        local old_on_secondary_use = old_def.on_secondary_use
        local function override_func(old_func)
            local function f(itemstack, placer, pointed_thing)
                if not placer:get_player_control().sneak then
                    old_func(itemstack, placer, pointed_thing)
                    return
                end
                local name = placer:get_player_name()
                easy_mine_core.show_change_dig(name)
            end
            return f
        end
        minetest.override_item(tool_name, {
            on_place = override_func(old_def.on_place),
            on_secondary_use = override_func(old_def.on_secondary_use)
        })
    end
end
