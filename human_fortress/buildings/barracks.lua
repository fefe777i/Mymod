-- ============================================
-- БУДІВЛЯ: КАЗАРМИ (barracks.lua) - ЧИТАЄ З JSON!
-- ============================================

local storage = minetest.get_mod_storage()

-- Функція для отримання апгрейдів з JSON (ТА САМА, ЩО Й В upgrades.lua)
local function get_player_upgrades_from_json(player_name)
    local world_path = minetest.get_worldpath()
    local upgrades_file = world_path .. "/upgrades.json"
    
    local file = io.open(upgrades_file, "r")
    if not file then return {} end
    
    local content = file:read("*all")
    file:close()
    local data = minetest.parse_json(content) or {}
    return data[player_name] or {}
end

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

-- Дані будівлі
local building_data = {
    name = "⚔️ Казарми",
    description = "Тренування воїнів та лучників",
    level = 2,
    cost = {
        score = 200,
        wood = 100,
        stone = 50
    },
    size = {x=3, y=2, z=3},
    nodes = {
        {pos={x=0,y=0,z=0}, name="default:stonebrick"},
        {pos={x=1,y=0,z=0}, name="default:stonebrick"},
        {pos={x=0,y=0,z=1}, name="default:stonebrick"},
        {pos={x=1,y=0,z=1}, name="default:stonebrick"},
        {pos={x=0,y=1,z=0}, name="default:steelblock"},
        {pos={x=1,y=1,z=0}, name="default:steelblock"},
        {pos={x=0.5,y=2,z=0.5}, name="default:torch"},
        {pos={x=0.5,y=1,z=0.5}, name="human_fortress:building_computer"},
    },
    icon = "human_fortress_barracks.png",
    color = "#CD5C5C",
    unlock_required = "barracks",
}

-- Функція знищення будівлі
local function destroy_building(player_name, computer_pos)
    local meta = minetest.get_meta(computer_pos)
    local owner = meta:get_string("owner")
    
    if owner ~= player_name then
        minetest.chat_send_player(player_name, "❌ Це чужа будівля!")
        return false
    end
    
    local building_type = meta:get_string("building_type")
    local building_pos = minetest.deserialize(meta:get_string("building_pos"))
    local building_cost = meta:get_int("building_cost")
    local nodes = minetest.deserialize(meta:get_string("building_nodes"))
    
    if not building_pos or not nodes then
        minetest.chat_send_player(player_name, "❌ Помилка даних будівлі!")
        return false
    end
    
    local refund = math.floor(building_cost * 0.7)
    if human_fortress.edos_data and human_fortress.edos_data[player_name] then
        human_fortress.edos_data[player_name].score = (human_fortress.edos_data[player_name].score or 0) + refund
    end
    
    for _, node_data in ipairs(nodes) do
        local np = vector.add(building_pos, node_data.pos)
        local node_name = minetest.get_node(np).name
        if node_name ~= "air" and node_name ~= "ignore" then
            minetest.remove_node(np)
        end
    end
    
    if minetest.get_node(computer_pos).name == "human_fortress:building_computer" then
        minetest.remove_node(computer_pos)
    end
    
    if human_fortress.buildings and human_fortress.buildings[player_name] then
        for i, b in ipairs(human_fortress.buildings[player_name]) do
            if b.type == building_type and vector.equals(b.pos, building_pos) then
                table.remove(human_fortress.buildings[player_name], i)
                break
            end
        end
    end
    
    minetest.chat_send_player(player_name, "💥 Будівлю знищено, повернено " .. refund .. " EDOS")
    return true
end

-- ============================================
-- МЕНЮ КАЗАРМИ - ЧИТАЄ АПГРЕЙДИ З JSON!
-- ============================================

function BUILDING_MENUS.barracks(player_name, computer_pos)
    minetest.chat_send_player(player_name, "🔍 ВІДКРИТТЯ МЕНЮ КАЗАРМИ")
    
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
    
    -- ОТРИМУЄМО АПГРЕЙДИ З JSON!
    local upgrades = get_player_upgrades_from_json(player_name)
    local resources = get_player_resources(player_name)
    
    -- ДЕБАГ
    minetest.chat_send_player(player_name, "📊 Апгрейди з JSON:")
    minetest.chat_send_player(player_name, "   blacksmith = " .. tostring(upgrades.blacksmith))
    minetest.chat_send_player(player_name, "   archery = " .. tostring(upgrades.archery))
    
    local formspec = "size[6,9]" ..
        "bgcolor[#0A0A1A;true]" ..
        "box[0,0;6,0.8;#2D2D44]" ..
        "label[0.5,0.2;⚔️ КАЗАРМИ]" ..
        "label[4,0.2;💰 " .. (resources.score or 0) .. "]"
    
    local y = 1.2
    
    -- ВОЇН (завжди доступний)
    formspec = formspec .. "button[0.5," .. y .. ";5,0.8;spawn_warrior;⚔️ Воїн (30 дер, 40 кам, 50 їжі)]"
    y = y + 0.9
    
    -- САМУРАЙ (тільки якщо є blacksmith)
    if upgrades.blacksmith then
        formspec = formspec .. "button[0.5," .. y .. ";5,0.8;spawn_samurai;⚔️ Самурай (50 дер, 50 кам, 70 їжі)]"
        y = y + 0.9
    else
        formspec = formspec .. "label[0.5," .. y .. ";🔒 Самурай (потрібна Кузня)]"
        y = y + 0.9
    end
    
    -- ЛУЧНИК (тільки якщо є archery)
    if upgrades.archery then
        formspec = formspec .. "button[0.5," .. y .. ";5,0.8;spawn_archer;🏹 Лучник (40 дер, 40 їжі)]"
        y = y + 0.9
    else
        formspec = formspec .. "label[0.5," .. y .. ";🔒 Лучник (потрібне Стрільбище)]"
        y = y + 0.9
    end
    
    formspec = formspec ..
        "button[1,7.5;4,1;destroy_building;💥 ЗНИЩИТИ БУДІВЛЮ]" ..
        "button[2,8.5;2,0.8;close;❌ ЗАКРИТИ]"
    
    minetest.show_formspec(player_name, "human_fortress:barracks", formspec)
end

-- ============================================
-- ОБРОБНИК ПОДІЙ КАЗАРМИ
-- ============================================

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "human_fortress:barracks" then return end
    
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
    
    -- Створення воїна
    if fields.spawn_warrior then
        local pos = player:get_pos()
        if pos and computer_pos and human_fortress.create_unit then
            local spawn_pos = {x=pos.x+2, y=pos.y+1, z=pos.z+2}
            human_fortress.create_unit("warrior", spawn_pos, player_name)
            BUILDING_MENUS.barracks(player_name, computer_pos)
        end
        return true
    end
    
    -- Створення самурая
    if fields.spawn_samurai then
        local pos = player:get_pos()
        if pos and computer_pos and human_fortress.create_unit then
            if human_fortress.units_list and human_fortress.units_list.samurai then
                local spawn_pos = {x=pos.x+2, y=pos.y+1, z=pos.z+2}
                human_fortress.create_unit("samurai", spawn_pos, player_name)
            else
                minetest.chat_send_player(player_name, "⚠️ Самурай не доданий в units.lua")
                local spawn_pos = {x=pos.x+2, y=pos.y+1, z=pos.z+2}
                human_fortress.create_unit("warrior", spawn_pos, player_name)
            end
            BUILDING_MENUS.barracks(player_name, computer_pos)
        end
        return true
    end
    
    -- Створення лучника
    if fields.spawn_archer then
        local pos = player:get_pos()
        if pos and computer_pos and human_fortress.create_unit then
            local spawn_pos = {x=pos.x+2, y=pos.y+1, z=pos.z+2}
            human_fortress.create_unit("archer", spawn_pos, player_name)
            BUILDING_MENUS.barracks(player_name, computer_pos)
        end
        return true
    end
    
    return true
end)

-- ============================================
-- ПОВЕРНЕННЯ БУДІВЛІ
-- ============================================

local building_to_return = {
    id = "barracks",
    data = {
        name = building_data.name,
        description = building_data.description,
        level = building_data.level,
        cost = building_data.cost,
        size = building_data.size,
        nodes = building_data.nodes,
        icon = building_data.icon,
        color = building_data.color,
        unlock_required = building_data.unlock_required,
        
        on_built = function(player_name, pos)
            local computer_pos = vector.add(pos, {x=0.5, y=1, z=0.5})
            local meta = minetest.get_meta(computer_pos)
            meta:set_string("building_type", "barracks")
            meta:set_string("owner", player_name)
            meta:set_string("building_pos", minetest.serialize(pos))
            meta:set_int("building_cost", building_data.cost.score)
            meta:set_string("building_nodes", minetest.serialize(building_data.nodes))
            meta:set_string("infotext", "⚔️ Казарми\nВласник: " .. player_name .. "\nПКМ - меню")
            
            if not human_fortress.buildings then human_fortress.buildings = {} end
            if not human_fortress.buildings[player_name] then
                human_fortress.buildings[player_name] = {}
            end
            table.insert(human_fortress.buildings[player_name], {
                type = "barracks",
                pos = pos
            })
            
            minetest.chat_send_player(player_name, "⚔️ Казарми побудовані! Натисни ПКМ на комп'ютері щоб відкрити меню.")
        end
    }
}

return building_to_return