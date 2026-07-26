-- ============================================
-- БУДІВЛЯ: РАТУША (townhall.lua)
-- ============================================
-- ============================================
-- ФУНКЦІЇ ДЛЯ РОБОТИ З АПГРЕЙДАМИ (ДОДАЙ!)
-- ============================================

local world_path = minetest.get_worldpath()
local upgrades_file = world_path .. "/upgrades.json"

-- Функція завантаження апгрейдів з JSON
local function load_upgrades_from_json()
    local file = io.open(upgrades_file, "r")
    if not file then
        -- Створюємо пустий файл
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

-- Глобальна таблиця апгрейдів (завантажується з JSON)
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
-- ПЕРЕВІРКА РОЗБЛОКУВАННЯ ЮНІТІВ (ВИПРАВЛЕНО!)
-- ============================================

local function is_unit_unlocked_for_townhall(player_name, unit_id)
    -- Завантажуємо апгрейди гравця з JSON
    local upgrades = load_upgrades_from_json()
    local player_upgrades = upgrades[player_name] or {}
    
    -- ВСІ ЮНІТИ ЗАВЖДИ РОЗБЛОКОВАНІ ДЛЯ ТЕСТУ!
    return true
    
    -- АБО ЯКЩО ХОЧЕШ ПОСТАРОВАНСЬКИ:
    --[[
    if unit_id == "worker" then return true end
    if unit_id == "lumberjack" then return true end
    if unit_id == "miner" then return true end
    if unit_id == "farmer" then return true end
    if unit_id == "warrior" and player_upgrades.barracks then return true end
    if unit_id == "archer" and player_upgrades.archery then return true end
    if unit_id == "knight" and player_upgrades.blacksmith then return true end
    if unit_id == "ranger" and player_upgrades.archery then return true end
    return false
    --]]
end

-- ============================================
-- ДАНІ БУДІВЛІ (townhall.lua)
-- ============================================

local building_data = {
    name = "🏛️ Ратуша",
    description = "Центр управління",
    level = 1,
    cost = {
        score = 100,
        wood = 50,
        stone = 30
    },
    schematic = "townhall.mts",
    icon = "human_fortress_townhall.png",
    color = "#FFD700",
    unlock_required = "town_hall",
    
    on_built = function(player_name, pos)
        -- 1. Твої нові координати (зміщені)
        local computer_pos = {x = pos.x + 4, y = pos.y + 2, z = pos.z + 5}
        
        -- 2. Встановлюємо блок
        minetest.set_node(computer_pos, {name = "human_fortress:building_computer"})
        
        -- 3. Записуємо метадані
        local meta = minetest.get_meta(computer_pos)
        meta:set_string("building_type", "townhall")
        meta:set_string("owner", player_name)
        meta:set_int("building_cost", 100)
        meta:set_string("infotext", "🏛️ Ратуша\nВласник: " .. player_name .. "\nПКМ - меню")
        meta:set_string("building_pos", minetest.serialize(pos)) -- Важливо для видалення!
        
        -- Список будівель
        if not human_fortress.buildings then human_fortress.buildings = {} end
        if not human_fortress.buildings[player_name] then
            human_fortress.buildings[player_name] = {}
        end
        table.insert(human_fortress.buildings[player_name], {
            type = "townhall",
            pos = pos
        })
        
        minetest.chat_send_player(player_name, "🏛️ Ратуша побудована! Комп'ютер встановлено.")
    end -- Кінець функції on_built
} -- Кінець таблиці building_data (ОСЬ ЦЯ ДУЖКА МАЛА БУТИ НА 82 РЯДКУ)

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
    
    -- Видаляємо зі списку
    if human_fortress.buildings and human_fortress.buildings[player_name] then
        for i, b in ipairs(human_fortress.buildings[player_name]) do
            if b.type == "townhall" and vector.equals(b.pos, building_pos) then
                table.remove(human_fortress.buildings[player_name], i)
                break
            end
        end
    end
    
    minetest.chat_send_player(player_name, "💥 Будівлю знищено, повернено " .. refund .. " EDOS")
    return true
end

-- ============================================
-- МЕНЮ РАТУШІ
-- ============================================

function BUILDING_MENUS.townhall(player_name, computer_pos)
    local meta = minetest.get_meta(computer_pos)
    local owner = meta:get_string("owner")
    
    if owner ~= player_name then
        minetest.chat_send_player(player_name, "❌ Це чужа будівля!")
        return
    end
    
    -- Зберігаємо позицію компа
    local tmp = minetest.deserialize(storage:get_string("tmp_computer")) or {}
    tmp[player_name] = computer_pos
    storage:set_string("tmp_computer", minetest.serialize(tmp))
    
    local resources = get_player_resources(player_name)
    
    local formspec = "size[6,10]" ..
        "bgcolor[#0A0A1A;true]" ..
        "box[0,0;6,0.8;#2D2D44]" ..
        "label[0.5,0.2;🏛️ РАТУША]" ..
        "label[4,0.2;💰 " .. (resources.score or 0) .. "]" ..
        
        "button[1,8.5;4,1;destroy_building;💥 ЗНИЩИТИ БУДІВЛЮ]" ..
        "button[2,9.6;2,0.8;close;❌ ЗАКРИТИ]"
    
    local y = 1.2
    for unit_id, unit_def in pairs(human_fortress.units_list or {}) do
        if is_unit_unlocked_for_townhall(player_name, unit_id) then
            local cost_text = ""
            local has_resources = true
            
            for res, amount in pairs(unit_def.cost or {}) do
                cost_text = cost_text .. res .. ":" .. amount .. " "
                if (resources[res] or 0) < amount then
                    has_resources = false
                end
            end
            
            local button_text = unit_def.profession or unit_id
            if not has_resources then
                button_text = button_text .. " (не вистачає)"
            end
            
            formspec = formspec ..
                "button[0.5," .. y .. ";5,0.8;spawn_" .. unit_id .. ";" .. 
                button_text .. " (" .. cost_text .. ")]"
            y = y + 0.9
        end
    end
    
    minetest.show_formspec(player_name, "human_fortress:townhall", formspec)
end

-- ============================================
-- ОБРОБНИК ПОДІЙ
-- ============================================

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "human_fortress:townhall" then return end
    
    local player_name = player:get_player_name()
    if not player_name then return end
    
    local tmp = minetest.deserialize(storage:get_string("tmp_computer")) or {}
    local computer_pos = tmp[player_name]
    
    if fields.close then
        return true
    end
    
    if fields.destroy_building then
        if computer_pos then
            destroy_building(player_name, computer_pos)
            tmp[player_name] = nil
            storage:set_string("tmp_computer", minetest.serialize(tmp))
        end
        return true
    end
    
    for field, _ in pairs(fields) do
        if string.sub(field, 1, 6) == "spawn_" then
            local unit_type = string.sub(field, 7)
            local pos = player:get_pos() 
            if pos and computer_pos and human_fortress.create_unit then
                local spawn_pos = {x=pos.x+2, y=pos.y+1, z=pos.z+2}
                human_fortress.create_unit(unit_type, spawn_pos, player_name)
                BUILDING_MENUS.townhall(player_name, computer_pos)
            end
            break
        end
    end  
    return true
end)
return {
    id = "townhall",
    data = building_data
}