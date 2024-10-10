local tool_type = {
    "pick",
    "shovel",
    "axe",
    "sword"
}

local tool_material = {
    "wood",
    "stone",
    "iron",
    "gold",
    "diamond",
    "netherite"
}

local as_stone_node = {
    "mcl_core:stone",
    "mcl_core:granite",
    "mcl_core:diorite",
    "mcl_core:andesite",
    "mcl_deepslate:deepslate"
}

local as_dirt_node = {
    "mcl_core:dirt",
    "mcl_core:dirt_with_grass",
    "mcl_core:dirt_with_grass_snow"
}

local as_sand_node = {
    "mcl_core:sand",
    "mcl_core:red_sand"
}

local as_crops_node = {
    "mcl_farming:wheat",
    "mcl_farming:potato",
    "mcl_farming:carrot",
    "mcl_farming:beetroot",
    "mcl_core:reeds",
    "mcl_ocean:kelp_dirt",
    "mcl_ocean:kelp_sand",
    "mcl_ocean:kelp_red_sand",
    "mcl_ocean:kelp_gravel",
    "mcl_nether:nether_wart"
}

easy_mine_core.set_as_stone_nodes(as_stone_node)
easy_mine_core.set_as_dirt_nodes(as_dirt_node)
easy_mine_core.set_as_sand_nodes(as_sand_node)
easy_mine_core.set_as_crops_nodes(as_crops_node)
easy_mine_core.update_as_nodes_define()

local function override_tool(name)
    local old_def = minetest.registered_tools[name]
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
    minetest.override_item(name, {
        on_place = override_func(old_def.on_place),
        on_secondary_use = override_func(old_def.on_secondary_use)
    })
end

for _, type in pairs(tool_type) do
    for _, material in pairs(tool_material) do
        local tool_name = "mcl_tools:" .. type .. "_" .. material
        override_tool(tool_name)
    end
end
override_tool("mcl_tools:shears")

for _, material in pairs(tool_material) do
    local tool_name = "mcl_farming:hoe_" .. material
    override_tool(tool_name)
end
