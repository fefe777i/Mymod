-- ============================================
-- БУДІВЛЯ: ФЕРМА (farm.lua)
-- ============================================

local world_path = minetest.get_worldpath()
local upgrades_file = world_path .. "/upgrades.json"

-- Функція завантаження апгрейдів з JSON
local function load_upgrades_from_json()
    local file = io.open(upgrades_file, "r")
    if not file then
        local default = {}
        file = io.open(upgrades_file, "w")
        file:write(minetest.write_json(default, true))
        file:close()
        return {}
    end
    local content = file:read("*all")
    file:close()
    return minetest.parse_json(content) or {}
end

-- Функція збереження апгрейдів в JSON
local function save_upgrades_to_json(data)
    local file = io.open(upgrades_file, "w")
    file:write(minetest.write_json(data, true))
    file:close()
end

local player_upgrades = load_upgrades_from_json()
local storage = minetest.get_mod_storage()

-- Допоміжна функція для ресурсів
local function get_player_resources(player_name)
    local data = human_fortress.edos_data and human_fortress.edos_data[player_name]
    if not data then return {score=0, wood=0, stone=0, food=0} end
    return {
        score = data.score or 0,
        wood  = data.wood  or 0,
        stone = data.stone or 0,
        food  = data.food  or 0,
    }
end

-- ============================================
-- ДАНІ БУДІВЛІ (farm.lua)
-- ============================================

local building_data = {
    name = "🌾 Ферма",
    description = "Виробляє їжу для міста",
    level = 1,
    cost = {
        score = 80,
        wood  = 40,
    },
    schematic = "rice_field.mts",
    icon = "human_fortress_farm.png",
    color = "#8B4513",
    unlock_required = "rice_field",

    on_built = function(player_name, pos)
        -- ⚠️ Підлаштуй зміщення під свою schematic farm.mts
        local computer_pos = {x = pos.x + 1, y = pos.y + 1, z = pos.z + 1}

        -- Встановлюємо блок комп'ютера
        minetest.set_node(computer_pos, {name = "human_fortress:building_computer"})

        -- Записуємо метадані
        local meta = minetest.get_meta(computer_pos)
        meta:set_string("building_type", "farm")
        meta:set_string("owner", player_name)
        meta:set_int("building_cost", 80)
        meta:set_string("infotext", "🌾 Ферма\nВласник: " .. player_name .. "\nПКМ - меню")
        meta:set_string("building_pos", minetest.serialize(pos))

        -- Додаємо до списку будівель
        if not human_fortress.buildings then human_fortress.buildings = {} end
        if not human_fortress.buildings[player_name] then
            human_fortress.buildings[player_name] = {}
        end
        table.insert(human_fortress.buildings[player_name], {
            type = "farm",
            pos = pos
        })

        minetest.chat_send_player(player_name, "🌾 Ферма побудована! Рис буде зростати на мокрій землі.")
    end
}

-- ============================================
-- ФУНКЦІЯ ЗНИЩЕННЯ
-- ============================================

local function destroy_building(player_name, computer_pos)
    local meta = minetest.get_meta(computer_pos)
    local owner = meta:get_string("owner")

    if owner ~= player_name then
        minetest.chat_send_player(player_name, "❌ Це чужа будівля!")
        return false
    end

    local building_pos = minetest.deserialize(meta:get_string("building_pos"))
    local building_cost = meta:get_int("building_cost")

    if not building_pos then
        minetest.chat_send_player(player_name, "❌ Помилка даних будівлі!")
        return false
    end

    local refund = math.floor(building_cost * 0.7)
    if human_fortress.edos_data and human_fortress.edos_data[player_name] then
        human_fortress.edos_data[player_name].score = (human_fortress.edos_data[player_name].score or 0) + refund
    end

    -- Видаляємо комп'ютер
    if minetest.get_node(computer_pos).name == "human_fortress:building_computer" then
        minetest.remove_node(computer_pos)
    end

    -- Видаляємо зі списку будівель
    if human_fortress.buildings and human_fortress.buildings[player_name] then
        for i, b in ipairs(human_fortress.buildings[player_name]) do
            if b.type == "farm" and vector.equals(b.pos, building_pos) then
                table.remove(human_fortress.buildings[player_name], i)
                break
            end
        end
    end

    minetest.chat_send_player(player_name, "💥 Ферму знищено, повернено " .. refund .. " EDOS")
    return true
end

-- ============================================
-- МЕНЮ ФЕРМИ (тільки Знищити + Закрити)
-- ============================================

function BUILDING_MENUS.farm(player_name, computer_pos)
    local meta = minetest.get_meta(computer_pos)
    local owner = meta:get_string("owner")

    if owner ~= player_name then
        minetest.chat_send_player(player_name, "❌ Це чужа будівля!")
        return
    end

    -- Зберігаємо позицію комп'ютера для обробника форми
    local tmp = minetest.deserialize(storage:get_string("tmp_farm")) or {}
    tmp[player_name] = computer_pos
    storage:set_string("tmp_farm", minetest.serialize(tmp))

    local resources = get_player_resources(player_name)

    local formspec = "size[6,4]" ..
        "bgcolor[#0A0A1A;true]" ..
        "box[0,0;6,0.8;#2D2D44]" ..
        "label[0.5,0.2;🌾 ФЕРМА]" ..
        "label[4,0.2;💰 " .. (resources.score or 0) .. "]" ..

        "button[1,1.5;4,1;destroy_building;💥 ЗНИЩИТИ БУДІВЛЮ]" ..
        "button[2,2.7;2,0.8;close;❌ ЗАКРИТИ]"

    minetest.show_formspec(player_name, "human_fortress:farm", formspec)
end

-- ============================================
-- ОБРОБНИК ПОДІЙ
-- ============================================

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "human_fortress:farm" then return end

    local player_name = player:get_player_name()
    if not player_name then return end

    local tmp = minetest.deserialize(storage:get_string("tmp_farm")) or {}
    local computer_pos = tmp[player_name]

    if fields.close then
        return true
    end

    if fields.destroy_building then
        if computer_pos then
            destroy_building(player_name, computer_pos)
            tmp[player_name] = nil
            storage:set_string("tmp_farm", minetest.serialize(tmp))
        end
        return true
    end

    return true
end)

-- ============================================
-- АВТОМАТИЧНИЙ РОСТ РИСУ НА ФЕРМІ
-- ============================================

minetest.register_abm({
    label = "Farm rice growth",
    nodenames = {"farming:soil_wet"},
    interval = 30,
    chance = 3,
    action = function(pos, node, active_object_count, active_object_count_wider)
        local above = {x = pos.x, y = pos.y + 1, z = pos.z}

        -- Якщо зверху не повітря — не ставимо
        if minetest.get_node(above).name ~= "air" then
            return
        end

        -- Шукаємо комп'ютер ферми в радіусі 5 блоків
        local computers = minetest.find_nodes_in_area(
            {x = pos.x - 5, y = pos.y - 2, z = pos.z - 5},
            {x = pos.x + 5, y = pos.y + 2, z = pos.z + 5},
            {"human_fortress:building_computer"}
        )

        for _, cp in ipairs(computers) do
            local meta = minetest.get_meta(cp)
            if meta:get_string("building_type") == "farm" then
                -- Ставимо рис
                minetest.set_node(above, {name = "human_fortress:rice"})
                return
            end
        end
    end
})

return {
    id = "rice_field",
    data = building_data
}