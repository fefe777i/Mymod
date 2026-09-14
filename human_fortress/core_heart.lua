local function get_core_building(pos)
    local meta = minetest.get_meta(pos)

    local data = {
        owner = meta:get_string("owner"),
        building_type = meta:get_string("building_type"),
        building_pos = minetest.deserialize(meta:get_string("building_pos")),
        min = minetest.deserialize(meta:get_string("building_min")),
        max = minetest.deserialize(meta:get_string("building_max")),
        original_node = meta:get_string("original_node")
    }

    if not data.building_pos then
        data.building_pos = vector.new(pos)
    end

    return data
end


local function open_building_menu(player, pos)
    local data = get_core_building(pos)
    local player_name = player:get_player_name()

    if data.owner ~= "" and data.owner ~= player_name then
        minetest.chat_send_player(
            player_name,
            "🏠 Це будівля гравця " .. data.owner
        )
        return
    end

    if data.building_type == "" then
        minetest.chat_send_player(
            player_name,
            "⚠️ Дані будівлі не знайдено."
        )
        return
    end

    if BUILDING_MENUS and BUILDING_MENUS[data.building_type] then
        BUILDING_MENUS[data.building_type](player, pos, data)
        return
    end

    minetest.show_formspec(
        player_name,
        "human_fortress:core_heart",
        "formspec_version[4]" ..
        "size[8,6]" ..
        "label[0.5,0.5;🏗️ Будівля]" ..
        "label[0.5,1.1;Тип: " .. minetest.formspec_escape(data.building_type) .. "]" ..
        "label[0.5,1.6;Власник: " .. minetest.formspec_escape(data.owner) .. "]" ..
        "button_exit[2,4.5;4,1;close;Закрити]"
    )
end


minetest.register_node("human_fortress:core_heart", {
    description = "Серце будівлі",

    drawtype = "normal",

    tiles = {
        "default_dirt.png"
    },

    paramtype = "light",

    groups = {
        cracky = 1,
        level = 1,
        not_in_creative_inventory = 1,
        building_core = 1
    },

    sounds = default.node_sound_stone_defaults(),

    is_ground_content = false,

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)

        meta:set_string("infotext", "🏗️ Серце будівлі")
        meta:set_string("owner", "")
        meta:set_string("building_type", "")
        meta:set_string("building_pos", "")
        meta:set_string("building_min", "")
        meta:set_string("building_max", "")
        meta:set_string("original_node", "")
    end,

    on_rightclick = function(pos, node, clicker)
        if not clicker or not clicker:is_player() then
            return
        end

        open_building_menu(clicker, pos)
    end,

    on_punch = function(pos, node, puncher)
        if not puncher or not puncher:is_player() then
            return
        end

        local meta = minetest.get_meta(pos)
        local owner = meta:get_string("owner")
        local building_type = meta:get_string("building_type")

        if owner == "" then
            return
        end

        minetest.chat_send_player(
            puncher:get_player_name(),
            "🏗️ Будівля: " ..
            building_type ..
            " | Власник: " ..
            owner
        )
    end
})


function human_fortress.set_core_data(pos, data)
    local node = minetest.get_node(pos)

    if node.name ~= "human_fortress:core_heart" then
        return false
    end

    local meta = minetest.get_meta(pos)

    meta:set_string("owner", data.owner or "")
    meta:set_string("building_type", data.building_type or "")

    if data.building_pos then
        meta:set_string(
            "building_pos",
            minetest.serialize(data.building_pos)
        )
    end

    if data.min then
        meta:set_string(
            "building_min",
            minetest.serialize(data.min)
        )
    end

    if data.max then
        meta:set_string(
            "building_max",
            minetest.serialize(data.max)
        )
    end

    meta:set_string(
        "original_node",
        data.original_node or ""
    )

    local infotext =
        "🏗️ " ..
        (data.building_type or "Будівля")

    if data.owner and data.owner ~= "" then
        infotext = infotext .. "\nВласник: " .. data.owner
    end

    meta:set_string("infotext", infotext)

    return true
end


function human_fortress.get_core_data(pos)
    local node = minetest.get_node(pos)

    if node.name ~= "human_fortress:core_heart" then
        return nil
    end

    return get_core_building(pos)
end


function human_fortress.find_building_core(pos, radius)
    radius = radius or 50

    local minp = {
        x = pos.x - radius,
        y = pos.y - radius,
        z = pos.z - radius
    }

    local maxp = {
        x = pos.x + radius,
        y = pos.y + radius,
        z = pos.z + radius
    }

    local cores = minetest.find_nodes_in_area(
        minp,
        maxp,
        {"human_fortress:core_heart"}
    )

    if #cores == 0 then
        return nil
    end

    local closest = nil
    local closest_distance = math.huge

    for _, core_pos in ipairs(cores) do
        local distance = vector.distance(pos, core_pos)

        if distance < closest_distance then
            closest_distance = distance
            closest = core_pos
        end
    end

    return closest
end