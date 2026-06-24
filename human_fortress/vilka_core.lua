-- Реєстрація блоку вилки (НЕАКТИВОВАНОЇ)
minetest.register_node("human_fortress:vilka_inactive", {
    description = "Вилка Фортеці (неактивована)",
    tiles = {"human_fortress_vilka_inactive.png"},
    drawtype = "mesh",
    mesh = "human_fortress_vilka.obj",
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {cracky = 1, level = 2},
    sounds = default.node_sound_stone_defaults(),
    
    on_rightclick = function(pos, node, clicker)
        local player_name = clicker:get_player_name()
        show_vilka_inactive_menu(player_name, pos)
    end,
    
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", "❌ Вилка Фортеці (неактивована)\nПКМ - активувати за 10 Ейдосів")
        meta:set_string("owner", "")
    end
})

-- Реєстрація блоку вилки (АКТИВОВАНОЇ)
minetest.register_node("human_fortress:vilka_active", {
    description = "Вилка Фортеці",
    tiles = {"human_fortress_vilka.png"},
    drawtype = "mesh",
    mesh = "human_fortress_vilka_on.obj",
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {cracky = 1, level = 2},
    sounds = default.node_sound_stone_defaults(),
    
    on_rightclick = function(pos, node, clicker)
        local player_name = clicker:get_player_name()
        local meta = minetest.get_meta(pos)
        local owner = meta:get_string("owner")
        
        if owner ~= "" and owner ~= player_name then
            minetest.chat_send_player(player_name, "❌ Це чужа вилка! Ви не можете її використовувати.")
            return
        end
        
        show_vilka_menu(player_name)
    end,
    
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", "Вилка Фортеці\nПКМ - відкрити меню")
    end
})

-- Крафт НЕАКТИВОВАНОЇ вилки
minetest.register_craft({
    output = "human_fortress:vilka_inactive",
    recipe = {
        {"default:steel_ingot", "default:mese_crystal", "default:steel_ingot"},
        {"default:obsidian", "human_fortress:edos", "default:obsidian"},
        {"default:steel_ingot", "default:mese_crystal", "default:steel_ingot"}
    }
})

-- Функція активації вилки
local function activate_vilka(player_name, pos)
    local player = minetest.get_player_by_name(player_name)
    if not player then return false end
    
    -- Перевіряємо чи є 10 Ейдосів (через вашу систему)
    local resources = get_player_resources(player_name)
    if (resources.score or 0) < 10 then
        minetest.chat_send_player(player_name, "❌ Недостатньо Ейдосів! Потрібно 10. У вас: " .. (resources.score or 0))
        return false
    end
    
    -- Знімаємо 10 Ейдосів
    local success = remove_resources(player_name, {score = 10})
    if not success then
        minetest.chat_send_player(player_name, "❌ Помилка при активації!")
        return false
    end
    
    -- Замінюємо блок на активований
    minetest.set_node(pos, {name = "human_fortress:vilka_active", param2 = minetest.get_node(pos).param2})
    
    -- Встановлюємо власника
    local meta = minetest.get_meta(pos)
    meta:set_string("owner", player_name)
    meta:set_string("infotext", "🏰 Вилка Фортеці\nВласник: " .. player_name .. "\nПКМ - відкрити меню")
    
    minetest.chat_send_player(player_name, "✅ Вилку активовано! Тепер це ваша власна вилка.")
    
    -- Оновлюємо GUI якщо є
    if human_fortress and human_fortress.update_gui then
        human_fortress.update_gui(player)
    end
    
    return true
end

-- МЕНЮ НЕАКТИВОВАНОЇ ВИЛКИ
function show_vilka_inactive_menu(player_name, pos)
    local resources = get_player_resources(player_name)
    local score = resources.score or 0
    
    local formspec = "size[8,5]" ..
        "bgcolor[#0A0A1A;true]" ..
        
        -- Заголовок
        "box[0,0;8,0.8;#2D2D44]" ..
        "label[0.5,0.2;❌ ВИЛКА ФОРТЕЦІ (НЕАКТИВОВАНА)]" ..
        "label[6,0.2;💰 " .. score .. "]" ..
        
        -- Інформація
        "box[0.5,1;7,2.5;#1E1E2E]" ..
        "label[1,1.2;Ця вилка ще не активована.]" ..
        "label[1,1.6;Щоб активувати, потрібно 10 Ейдосів.]" ..
        "item_image[1,2;0.5,0.5;human_fortress:edos]" ..
        "label[1.6,2.05;× 10]" ..
        
        -- Кнопка активації
        "button[2.5,3.2;3,0.8;activate_vilka;🔓 АКТИВУВАТИ]"
    
    -- Зберігаємо позицію в player_data
    local data = get_player_data(player_name)
    data.pending_activation_pos = pos
    save_fortress_data()
    
    minetest.show_formspec(player_name, "human_fortress:vilka_inactive", formspec)
end

-- Обробник для неактивованої вилки
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "human_fortress:vilka_inactive" then return end
    
    local player_name = player:get_player_name()
    local data = get_player_data(player_name)
    local pos = data.pending_activation_pos
    
    if fields.activate_vilka then
        if pos then
            activate_vilka(player_name, pos)
            -- Очищаємо збережену позицію
            data.pending_activation_pos = nil
            save_fortress_data()
        else
            minetest.chat_send_player(player_name, "❌ Помилка: позицію вилки не знайдено!")
        end
        return
    end
end)

-- ============================================
-- БЛОК КОМП'ЮТЕР ДЛЯ БУДІВЕЛЬ - ВИПРАВЛЕНО!
-- ============================================

-- Спочатку створюємо глобальну таблицю (ЯКЩО ЩЕ НЕ СТВОРЕНО)
if not BUILDING_MENUS then
    BUILDING_MENUS = {}
end

minetest.register_node("human_fortress:building_computer", {
    description = "Комп'ютер будівлі",
    tiles = {"human_fortress_pc_texture.png"},
    drawtype = "mesh",
    mesh = "pc.obj",
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {cracky = 1, level = 2, building_computer = 1},
    sounds = default.node_sound_metal_defaults(),
    
    on_rightclick = function(pos, node, clicker)
        local player_name = clicker:get_player_name()
        local meta = minetest.get_meta(pos)
        local building_type = meta:get_string("building_type")
        local owner = meta:get_string("owner")
        
        minetest.chat_send_player(player_name, "🔍 Клік по комп'ютеру: " .. building_type)
        
        if owner and owner ~= "" and owner ~= player_name then
            minetest.chat_send_player(player_name, "❌ Це чужа будівля!")
            return
        end
        
        -- ПЕРЕВІРКА BUILDING_MENUS
        minetest.chat_send_player(player_name, "   BUILDING_MENUS = " .. tostring(BUILDING_MENUS))
        
        if building_type and building_type ~= "" then
            if BUILDING_MENUS and BUILDING_MENUS[building_type] then
                minetest.chat_send_player(player_name, "✅ Відкриваю меню " .. building_type)
                BUILDING_MENUS[building_type](player_name, pos)
            else
                minetest.chat_send_player(player_name, "❌ Меню для " .. building_type .. " не знайдено!")
                -- ПОКАЗУЄМО ЩО Є В BUILDING_MENUS
                if BUILDING_MENUS then
                    local list = ""
                    for k,_ in pairs(BUILDING_MENUS) do
                        list = list .. k .. " "
                    end
                    if list ~= "" then
                        minetest.chat_send_player(player_name, "   Доступні меню: " .. list)
                    else
                        minetest.chat_send_player(player_name, "   BUILDING_MENUS порожній!")
                    end
                end
            end
        else
            minetest.chat_send_player(player_name, "💻 Комп'ютер без типу")
        end
    end,
    
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", "Комп'ютер будівлі\nПКМ - відкрити меню")
        meta:set_string("building_type", "")
        meta:set_string("owner", "")
        meta:set_string("building_pos", "")
        meta:set_int("building_cost", 0)
        meta:set_string("building_nodes", "")
    end
})

-- НЕ СТВОРЮЙ BUILDING_MENUS ТУТ, ВОНА ВЖЕ СТВОРЕНА!
-- BUILDING_MENUS = {}  ← ВИДАЛИ ЦЕ!

-- Команда для отримання тестової неактивованої вилки
minetest.register_chatcommand("give_vilka", {
    description = "Отримати неактивовану вилку (для тесту)",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            local inv = player:get_inventory()
            inv:add_item("main", "human_fortress:vilka_inactive")
            minetest.chat_send_player(name, "✅ Отримано неактивовану вилку! Поставте її та активуйте за 10 Ейдосів.")
        end
    end
})