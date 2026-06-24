-- ============================================
-- БУДІВЛЯ: РИНОК (market.lua) - ПРОСТА ВЕРСІЯ
-- ============================================

local storage = minetest.get_mod_storage()

-- Допоміжна функція для ресурсів
local function get_player_resources(player_name)
    local data = human_fortress.edos_data and human_fortress.edos_data[player_name]
    if not data then return {score=0, wood=0, stone=0, food=0, gold=0, level=1} end
    return {
        score = data.score or 0,
        wood  = data.wood  or 0,
        stone = data.stone or 0,
        food  = data.food  or 0,
        gold  = data.gold  or 0,
        level = data.level or 1,
    }
end

-- Перевірка чи відкритий елітний найманець
local function is_elite_available(player_name)
    local data = human_fortress.edos_data and human_fortress.edos_data[player_name]
    if not data then return false end
    if data.level < 30 then return false end
    local last_hire = data.last_elite_hire or 0
    local current_day = tonumber(os.date("%j"))
    return current_day > last_hire
end

-- Дані будівлі
local building_data = {
    name = "🏪 Ринок",
    description = "Торговельна площа, найм елітних воїнів",
    level = 2,
    cost = {
        score = 300,
        wood = 100,
        stone = 80,
    },
    schematic = "market.we",
    icon = "human_fortress_market.png",
    color = "#FFA500",
    unlock_required = "market",
    
    on_built = function(player_name, pos)
        local computer_pos = {x = pos.x + 0.5, y = pos.y + 1, z = pos.z + 0.5}
        
        minetest.set_node(computer_pos, {name = "human_fortress:building_computer"})
        
        local meta = minetest.get_meta(computer_pos)
        meta:set_string("building_type", "market")
        meta:set_string("owner", player_name)
        meta:set_string("building_pos", minetest.serialize(pos))
        meta:set_int("building_cost", 300)
        meta:set_string("infotext", "🏪 Ринок\nВласник: " .. player_name)
        
        if not human_fortress.buildings then human_fortress.buildings = {} end
        if not human_fortress.buildings[player_name] then
            human_fortress.buildings[player_name] = {}
        end
        table.insert(human_fortress.buildings[player_name], {
            type = "market",
            pos = pos
        })
        
        minetest.chat_send_player(player_name, "🏪 Ринок побудований!")
        minetest.chat_send_player(player_name, "📌 Комп'ютер на " .. minetest.pos_to_string(computer_pos))
    end
}

-- ============================================
-- РЕЄСТРАЦІЯ МЕНЮ
-- ============================================

if not BUILDING_MENUS then BUILDING_MENUS = {} end

BUILDING_MENUS.market = function(player_name, computer_pos)
    minetest.chat_send_player(player_name, "✅ МЕНЮ РИНКУ ВІДКРИТО!")
    
    local meta = minetest.get_meta(computer_pos)
    local owner = meta:get_string("owner")
    
    if owner ~= player_name then
        minetest.chat_send_player(player_name, "❌ Це чужа будівля!")
        return
    end
    
    local tmp = minetest.deserialize(storage:get_string("tmp_computer")) or {}
    tmp[player_name] = computer_pos
    storage:set_string("tmp_computer", minetest.serialize(tmp))
    
    local resources = get_player_resources(player_name)
    local elite_available = is_elite_available(player_name)
    
    local formspec = "size[8,6]" ..
        "bgcolor[#0A0A1A;true]" ..
        "box[0,0;8,0.8;#2D2D44]" ..
        "label[0.5,0.2;🏪 РИНОК]" ..
        "label[5,0.2;💰 " .. (resources.score or 0) .. "]" ..
        "label[6.5,0.2;🪙 " .. (resources.gold or 0) .. "]" ..
        
        "box[0.5,1;7,2;#1E1E2E]" ..
        "label[1,1.2;⚔️ ЕЛІТНИЙ НАЙМАНЕЦЬ]" ..
        "label[1,1.6;❤️ ЗДОРОВ'Я: +100]" ..
        "label[1,2.0;⚔️ ШКОДА: +50]" ..
        "label[1,2.4;🏃 ШВИДКІСТЬ: +30%]" ..
        
        "button[0.5,3.5;7,1;hire_elite;⚔️ НАЙНЯТИ (1000💰 + 200🌲 + 150🪨)]" ..
        
        "button[3,4.5;2,1;close;❌ ЗАКРИТИ]"
    
    minetest.show_formspec(player_name, "human_fortress:market", formspec)
end

-- ============================================
-- ФУНКЦІЯ НАЙМУ
-- ============================================

local function hire_elite_warrior(player_name, computer_pos)
    local player = minetest.get_player_by_name(player_name)
    if not player then return false end
    
    local resources = get_player_resources(player_name)
    
    if resources.level < 30 then
        minetest.chat_send_player(player_name, "❌ Потрібен 30 рівень!")
        return false
    end
    
    if not is_elite_available(player_name) then
        minetest.chat_send_player(player_name, "❌ Раз на 3 дні!")
        return false
    end
    
    if (resources.score or 0) < 1000 then
        minetest.chat_send_player(player_name, "❌ Не вистачає EDOS! Треба 1000")
        return false
    end
    
    if (resources.wood or 0) < 200 then
        minetest.chat_send_player(player_name, "❌ Не вистачає дерева! Треба 200")
        return false
    end
    
    if (resources.stone or 0) < 150 then
        minetest.chat_send_player(player_name, "❌ Не вистачає каменю! Треба 150")
        return false
    end
    
    local data = human_fortress.edos_data[player_name]
    data.score = data.score - 1000
    data.wood = data.wood - 200
    data.stone = data.stone - 150
    data.last_elite_hire = tonumber(os.date("%j"))
    human_fortress.save_data(player_name)
    
    local pos = player:get_pos()
    local spawn_pos = {x = pos.x + 2, y = pos.y + 1, z = pos.z + 2}
    
    if human_fortress.create_unit then
        human_fortress.create_unit("elite_warrior", spawn_pos, player_name)
    else
        local entity = minetest.add_entity(spawn_pos, "human_fortress:elite_warrior")
        if entity then
            entity.unit_data.owner = player_name
        end
    end
    
    minetest.chat_send_player(player_name, "⚔️ ЕЛІТНИЙ ВОЇН НАЙНЯТИЙ!")
    return true
end

-- ============================================
-- ОБРОБНИК
-- ============================================

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "human_fortress:market" then return end
    
    local player_name = player:get_player_name()
    local tmp = minetest.deserialize(storage:get_string("tmp_computer")) or {}
    local computer_pos = tmp[player_name]
    
    if fields.close then
        return true
    end
    
    if fields.hire_elite then
        if computer_pos then
            hire_elite_warrior(player_name, computer_pos)
            BUILDING_MENUS.market(player_name, computer_pos)
        end
        return true
    end
    
    return true
end)

-- ============================================
-- ПОВЕРНЕННЯ
-- ============================================

return {
    id = "market",
    data = building_data
}