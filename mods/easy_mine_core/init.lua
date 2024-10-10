easy_mine_core = {}

local is_digging = {}
local dig_direction = {}
local mode_digging_state = {}
local last_pointed_thing = {}

local mode_digging = {
    "normal",
    "mining",
    "escape",
    "shapeless",
    "line",
    "square",
    "line_square"
}

local as_stone_nodes = {}
local as_dirt_nodes = {}
local as_sand_nodes = {}
local as_crops_nodes = {}
local as_nodes_define = {}

function easy_mine_core.set_as_stone_nodes(nodes)
    as_stone_nodes = nodes
end

function easy_mine_core.set_as_dirt_nodes(nodes)
    as_dirt_nodes = nodes
end

function easy_mine_core.set_as_sand_nodes(nodes)
    as_sand_nodes = nodes
end

function easy_mine_core.set_as_crops_nodes(nodes)
    as_crops_nodes = nodes
end

function easy_mine_core.update_as_nodes_define()
    as_nodes_define = {}
    local function define(nodes, as)
        for _, n in pairs(nodes) do
            as_nodes_define[n] = as
        end
    end
    define(as_stone_nodes, "stone")
    define(as_dirt_nodes, "dirt")
    define(as_sand_nodes, "sand")
    define(as_crops_nodes, "crops")
end

local function get_is_digging(name)
    return is_digging[name]
end
local function set_is_digging(name, b)
    is_digging[name] = b
end

local function get_dig_direction(name)
    return dig_direction[name]
end
local function set_dig_direction(name, above, under)
    dig_direction[name] = vector.direction(above, under)
end

local function get_mode_index(name)
    return mode_digging_state[name]
end
local function set_mode_index(name, i)
    mode_digging_state[name] = i
end

local function get_mode(name)
    local index = get_mode_index(name)
    return mode_digging[index]
end

local function get_last_pointed_thing(name)
    return last_pointed_thing[name]
end
local function set_last_pointed_thing(name, pointed_thing)
    last_pointed_thing[name] = pointed_thing
end

local function get_area(pos1, pos2)
    local area = {}
    local function sign(a, b)
        if a > b then
            return -1
        else
            return 1
        end
    end
    local sign_x = sign(pos1.x, pos2.x)
    local sign_y = sign(pos1.y, pos2.y)
    local sign_z = sign(pos1.z, pos2.z)
    for x = pos1.x, pos2.x, sign_x do
        for y = pos1.y, pos2.y, sign_y do
            for z = pos1.z, pos2.z, sign_z do
                table.insert(area, vector.new(x, y, z))
            end
        end
    end
    return area
end

local function get_dig_node_as(digger, as)
    local function f(pos)
        local node = minetest.get_node(pos)
        if as_nodes_define[node.name] == as then
            minetest.node_dig(pos, node, digger)
            return true
        else
            return false
        end
    end
    return f
end

local function get_dig_node_func(oldnode, digger)
    local name = oldnode.name
    local as = as_nodes_define[name]
    if not as then
        return function(pos)
            local node = minetest.get_node(pos)
            if node.name == oldnode.name then
                minetest.node_dig(pos, oldnode, digger)
                return true
            else
                return false
            end
        end
    else
        return get_dig_node_as(digger, as)
    end
end

local function dig_node_as_stone(pos, oldnode, digger)
    dig_node_as(pos, oldnode, digger, "stone")
end

local function dig_node_as_dirt()
    dig_node_as(pos, oldnode, digger, "dirt")
end

local function dig_node_as_sand()
    dig_node_as(pos, oldnode, digger, "sand")
end

local function dig_node_as_crops()
    dig_node_as(pos, oldnode, digger, "crops")
end

local function dig_node_range(pos1, pos2, oldnode, digger)
    local dig = get_dig_node_func(oldnode, digger)
    local pos_list = get_area(pos1, pos2)
    local count = 0
    for _, pos in pairs(pos_list) do
        if dig(pos) then
            count = count + 1
        end
    end
    return count
end
local function dig_node_stair(pos, offset, oldnode, digger)
    local dig = get_dig_node_func(oldnode, digger)
    local count = 0
    for i = 1, 20 do
        local offset_i = vector.multiply(offset, i)
        local p = vector.add(pos, offset_i)
        if dig(p) then
            count = count + 1
        end
    end
    return count
end
local function get_offset_mining(pos, dir)
    local pos_offset = nil
    if dir.x == 0 and dir.z == 0 then
        pos_offset = vector.zero()
    else
        pos_offset = vector.offset(vector.zero(), dir.x, -1, dir.z)
    end
    return pos_offset
end
local function get_offset_escape(pos, dir)
    local pos_offset = nil
    if dir.x == 0 and dir.z == 0 then
        pos_offset = vector.zero()
    else
        pos_offset = vector.offset(vector.zero(), dir.x, 1, dir.z)
    end
    return pos_offset
end
local function get_around_poss(p)
    local around = {1, -1, 0}
    local result = {}
    for _, x in ipairs(around) do
        for _, y in ipairs(around) do
            for _, z in ipairs(around) do
                table.insert(result, vector.offset(p, x, y, z))
            end
        end
    end
    table.remove(result)
    return result
end
local function get_pos_square(pos, dir)
    local pos1 = nil
    local pos2 = nil
    local pos_offset = nil
    if dir.x ~= 0 then
        pos_offset = vector.new(0, 1, 1)
    elseif dir.y ~= 0 then
        pos_offset = vector.new(1, 0, 1)
    elseif dir.z ~= 0 then
        pos_offset = vector.new(1, 1, 0)
    else
        pos_offset = vector.new(0, 0, 0)
    end
    pos1 = vector.subtract(pos, pos_offset)
    pos2 = vector.add(pos, pos_offset)
    return pos1, pos2
end
local function get_pos_line_square(pos, dir)
    local pos1, pos2 = get_pos_square(pos, dir)
    local pos_offset = vector.multiply(dir, 20)
    local pos3 = vector.add(pos2, pos_offset)
    return pos1, pos3
end

function easy_mine_core.get_formspec(name)
    local version = "formspec_version[7]"
    local size = "size[3.75,10]"
    local state_table = {
        "label[0.375,0.5;",
        "dig mode: ",
        get_mode(name),
        "]"
    }
    local state = table.concat(state_table, "")
    local button_table = {}
    for i, mode in ipairs(mode_digging) do
        button_table[i] = "button_exit[0.375,"
            .. tostring(0.5+1.0*i) .. ";"
            .. "3,0.8;"
            .. mode .. ";"
            .. mode .. "]"
    end
    local buttons = table.concat(button_table, "")
    local formspec_table = {
        version, size, state, buttons
    }
    return table.concat(formspec_table, "")
end

function easy_mine_core.show_change_dig(name)
    local fs = easy_mine_core.get_formspec(name)
    minetest.show_formspec(name, "easy_mine_core:changedig", fs)
end

easy_mine_core.dignode = {}
function easy_mine_core.call_dignode(mode, pos, oldnode, digger)
    local f = easy_mine_core.dignode[mode]
    return f(pos, oldnode, digger)
end
function easy_mine_core.dignode.normal(pos, oldnode, digger)
    return 0
end
function easy_mine_core.dignode.mining(pos, oldnode, digger)
    local player_name = digger:get_player_name()
    local dir = get_dig_direction(player_name)
    local offset = get_offset_mining(pos, dir)
    local count = dig_node_stair(pos, offset, oldnode, digger)
    return count
end
function easy_mine_core.dignode.escape(pos, oldnode, digger)
    local player_name = digger:get_player_name()
    local dir = get_dig_direction(player_name)
    local offset = get_offset_escape(pos, dir)
    local count = dig_node_stair(pos, offset, oldnode, digger)
    return count
end
function easy_mine_core.dignode.shapeless(pos, oldnode, digger)
    local target_name = oldnode.name
    local to_destory_node = {}
    local not_to_destory_node = {}
    local base_poss = {pos}
    local next_base_poss = {}
    local MAX_DESTORY_NUM = 30
    local destory_count = 0
    local dig = get_dig_node_func(oldnode, digger)
    while base_poss[1] and destory_count < MAX_DESTORY_NUM do
        for _, base in ipairs(base_poss) do
            local arounds = get_around_poss(base)
            for _, p in ipairs(arounds) do
                if not(to_destory_node[p] or not_to_destory_node[p]) then
                    if dig(p) then
                        to_destory_node[p] = true
                        table.insert(next_base_poss, p)
                        destory_count = destory_count + 1
                    else
                        not_to_destory_node[p] = true
                    end
                end
            end
        end
        base_poss = next_base_poss
        next_base_poss = {}
    end
    return destory_count
end
function easy_mine_core.dignode.line(pos, oldnode, digger)
    local player_name = digger:get_player_name()
    local dir = get_dig_direction(player_name)
    local pos_offset = vector.multiply(dir, 20)
    local pos_end = vector.add(pos, pos_offset)
    local count = dig_node_range(pos, pos_end, oldnode, digger)
    return count
end
function easy_mine_core.dignode.square(pos, oldnode, digger)
    local player_name = digger:get_player_name()
    local dir = get_dig_direction(player_name)
    local pos1, pos2 = get_pos_square(pos, dir)
    local count = dig_node_range(pos1, pos2, oldnode, digger)
    return count
end
function easy_mine_core.dignode.line_square(pos, oldnode, digger)
    local player_name = digger:get_player_name()
    local dir = get_dig_direction(player_name)
    local pos1, pos2 = get_pos_line_square(pos, dir)
    local count = dig_node_range(pos1, pos2, oldnode, digger)
    return count
end

local function dignode(pos, oldnode, digger)
    local name = digger:get_player_name()
    if name == "" then
        return
    end
    local mode = get_mode(name)
    local count = easy_mine_core.call_dignode(mode, pos, oldnode, digger)
    return count
end

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
    local name = puncher:get_player_name()
    if name ~= "" then
        set_last_pointed_thing(name, pointed_thing)
    end
end)

minetest.register_on_dignode(function(pos, oldnode, digger)
    if not digger then
        return
    end

    if not digger:is_player() or digger:get_player_control().sneak then
        return
    end

    local player_name = digger:get_player_name()
    if get_is_digging(player_name) then
        return
    end

    local as_node_type = as_nodes_define[oldnode.name]
    if not as_node_type or as_node_type ~= "crops" then
        local wielded_item = digger:get_wielded_item()
        local tools = minetest.registered_tools[wielded_item:get_name()]
        if not tools then
            return
        end

        local tool_capabilities = wielded_item:get_tool_capabilities()
        local groupcaps = tool_capabilities["groupcaps"]
        local is_best_tool = false
        local oldnode_def = minetest.registered_nodes[oldnode.name]
        for g, caps in pairs(groupcaps) do
            local node_group_level = oldnode_def.groups[g]
            if node_group_level then
                is_best_tool = true
                break
            end
        end
        if not is_best_tool then
            return
        end
    end

    local pointed_thing = get_last_pointed_thing(player_name)
    if pointed_thing.type == "node" then
        set_is_digging(player_name, true)
        local under = pointed_thing.under
        local above = pointed_thing.above
        dig_direction[player_name] = vector.direction(above, under)
        local count = dignode(pos, oldnode, digger)
        set_is_digging(player_name, false)
    end
end)

minetest.register_on_joinplayer(function(player, last_login)
    local name = player:get_player_name()
    set_mode_index(name, 1)
end)

minetest.register_on_leaveplayer(function(player, timed_out)
    local name = player:get_player_name()
    set_mode_index(name, nil)
end)

minetest.register_chatcommand("changedig", {
    func = function(name)
        local fs = easy_mine_core.get_formspec(name)
        minetest.show_formspec(name, "easy_mine_core:changedig", fs)
    end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "easy_mine_core:changedig" then
        return
    end
    
    local name = player:get_player_name()
    for i, mode in ipairs(mode_digging) do
        if fields[mode] then
            set_mode_index(name, i)
            break
        end
    end
end)
