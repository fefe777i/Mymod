local CORE_NODE = "human_fortress:core_heart"
local CORE_ENTITY = "human_fortress:core_visual"

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

local function remove_core_visual(pos)
    for _, obj in ipairs(minetest.get_objects_inside_radius(vector.add(pos, {x = 0.5, y = 0.5, z = 0.5}), 0.8)) do
        local ent = obj:get_luaentity()
        if ent and ent.name == CORE_ENTITY then
            obj:remove()
        end
    end
end

local function add_core_visual(pos, original_node)
    if not original_node or original_node == "" or original_node == "air" then
        return
    end

    remove_core_visual(pos)

    local obj = minetest.add_entity(
        vector.add(pos, {x = 0.5, y = 0.5, z = 0.5}),
        CORE_ENTITY
    )

    if obj then
        local ent = obj:get_luaentity()
        if ent then
            ent.core_pos = vector.new(pos)
            ent.original_node = original_node
        end
        obj:set_properties({wield_item = original_node})
    end
end

minetest.register_entity(CORE_ENTITY, {
    initial_properties = {
        physical = false,
        collide_with_objects = false,
        pointable = false,
        visual = "wielditem",
        visual_size = {x = 1, y = 1},
        static_save = true,
        textures = {"air.png"},
    },

    core_pos = nil,
    original_node = "",

    get_staticdata = function(self)
        return minetest.serialize({
            core_pos = self.core_pos,
            original_node = self.original_node,
        })
    end,

    on_activate = function(self, staticdata)
        if staticdata and staticdata ~= "" then
            local data = minetest.deserialize(staticdata)
            if data then
                self.core_pos = data.core_pos
                self.original_node = data.original_node or ""
                if self.original_node ~= "" then
                    self.object:set_properties({wield_item = self.original_node})
                end
            end
        end
    end,
})

local function open_building_menu(player, pos)
    local data = get_core_building(pos)
    local player_name = player:get_player_name()

    if data.owner ~= "" and data.owner ~= player_name then
        minetest.chat_send_player(player_name, "🏠 Це будівля гравця " .. data.owner)
        return
    end

    if data.building_type == "" then
        minetest.chat_send_player(player_name, "⚠️ Дані будівлі не знайдено.")
        return
    end

    if BUILDING_MENUS and BUILDING_MENUS[data.building_type] then
        BUILDING_MENUS[data.building_type](player_name, pos, data)
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

minetest.register_node(CORE_NODE, {
    description = "Серце будівлі",
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = true,
    pointable = true,
    diggable = true,
    groups = {
        cracky = 1,
        level = 1,
        not_in_creative_inventory = 1,
        building_core = 1
    },
    sounds = default.node_sound_stone_defaults(),
    is_ground_content = false,

    selection_box = {
        type = "regular"
    },

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
        if clicker and clicker:is_player() then
            open_building_menu(clicker, pos)
        end
    end,

    on_punch = function(pos, node, puncher)
        if not puncher or not puncher:is_player() then
            return
        end

        local data = get_core_building(pos)
        if data.owner ~= "" then
            minetest.chat_send_player(
                puncher:get_player_name(),
                "🏗️ Будівля: " .. data.building_type .. " | Власник: " .. data.owner
            )
        end
    end,

    on_destruct = function(pos)
        remove_core_visual(pos)
    end,
})

function human_fortress.set_core_data(pos, data)
    if minetest.get_node(pos).name ~= CORE_NODE then
        return false
    end

    local meta = minetest.get_meta(pos)
    meta:set_string("owner", data.owner or "")
    meta:set_string("building_type", data.building_type or "")

    if data.building_pos then
        meta:set_string("building_pos", minetest.serialize(data.building_pos))
    end
    if data.min then
        meta:set_string("building_min", minetest.serialize(data.min))
    end
    if data.max then
        meta:set_string("building_max", minetest.serialize(data.max))
    end

    meta:set_string("original_node", data.original_node or "")

    local infotext = "🏗️ " .. (data.building_type or "Будівля")
    if data.owner and data.owner ~= "" then
        infotext = infotext .. "\nВласник: " .. data.owner
    end
    meta:set_string("infotext", infotext)

    add_core_visual(pos, data.original_node)
    return true
end

function human_fortress.get_core_data(pos)
    if minetest.get_node(pos).name ~= CORE_NODE then
        return nil
    end
    return get_core_building(pos)
end

function human_fortress.find_building_core(pos, radius)
    radius = radius or 50

    local cores = minetest.find_nodes_in_area(
        {x = pos.x - radius, y = pos.y - radius, z = pos.z - radius},
        {x = pos.x + radius, y = pos.y + radius, z = pos.z + radius},
        {CORE_NODE}
    )

    local closest
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

function human_fortress.is_inside_building(pos, core_pos)
    if not core_pos then
        core_pos = human_fortress.find_building_core(pos)
    end
    if not core_pos then
        return false
    end

    local data = human_fortress.get_core_data(core_pos)
    if not data or not data.min or not data.max then
        return false
    end

    return pos.x >= data.min.x and pos.x <= data.max.x
       and pos.y >= data.min.y and pos.y <= data.max.y
       and pos.z >= data.min.z and pos.z <= data.max.z
end

local function get_building_blocks(building_type, anchor_pos)
    local schematic = BUILDING_SCHEMATICS and BUILDING_SCHEMATICS[building_type]
    if not schematic then
        return {}
    end

    local filepath = minetest.get_modpath("human_fortress") .. "/schematics/" .. schematic.schematic
    local data = minetest.read_schematic(filepath, {})
    if not data then
        return {}
    end

    local blocks = {}
    local i = 1

    for z = 0, data.size.z - 1 do
        for y = 0, data.size.y - 1 do
            for x = 0, data.size.x - 1 do
                local cell = data.data[i]
                i = i + 1
                if cell and cell.name ~= "air" and cell.name ~= "ignore" then
                    table.insert(blocks, {
                        x = anchor_pos.x + x,
                        y = anchor_pos.y + y,
                        z = anchor_pos.z + z,
                        node = cell.name
                    })
                end
            end
        end
    end

    return blocks
end

local function create_core_for_building(player_name, building_type, pos)
    local blocks = get_building_blocks(building_type, pos)
    if #blocks == 0 then
        return false
    end

    local minp = vector.new(blocks[1])
    local maxp = vector.new(blocks[1])

    for _, block in ipairs(blocks) do
        minp.x = math.min(minp.x, block.x)
        minp.y = math.min(minp.y, block.y)
        minp.z = math.min(minp.z, block.z)
        maxp.x = math.max(maxp.x, block.x)
        maxp.y = math.max(maxp.y, block.y)
        maxp.z = math.max(maxp.z, block.z)
    end

    local candidates = {}
    for _, block in ipairs(blocks) do
        local node = minetest.get_node(block)
        if node.name == block.node then
            table.insert(candidates, block)
        end
    end

    if #candidates == 0 then
        return false
    end

    local chosen = candidates[math.random(#candidates)]
    local original = minetest.get_node(chosen)

    minetest.set_node(chosen, {name = CORE_NODE})

    return human_fortress.set_core_data(chosen, {
        owner = player_name,
        building_type = building_type,
        building_pos = pos,
        min = minp,
        max = maxp,
        original_node = original.name
    })
end

local function wrap_building(building_type, building_data)
    if not building_data or building_data._core_heart_wrapped then
        return
    end

    local old_on_built = building_data.on_built

    building_data.on_built = function(player_name, pos, ...)
        if old_on_built then
            old_on_built(player_name, pos, ...)
        end

        minetest.after(0, function()
            create_core_for_building(player_name, building_type, pos)
        end)
    end

    building_data._core_heart_wrapped = true
end

for building_type, building_data in pairs(BUILDING_SCHEMATICS or {}) do
    wrap_building(building_type, building_data)
end

minetest.register_lbm({
    label = "Відновлення візуалу сердець будівель",
    name = "human_fortress:restore_core_visuals",
    nodenames = {CORE_NODE},
    run_at_every_load = true,
    action = function(pos)
        local original = minetest.get_meta(pos):get_string("original_node")
        if original ~= "" then
            add_core_visual(pos, original)
        end
    end,
})
