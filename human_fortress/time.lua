-------------------------------------------------
-- Human Fortress RTS - Система часу (Атлас 24 кадри)
-------------------------------------------------

human_fortress.clock_huds = human_fortress.clock_huds or {}

-- ДАНІ ДЛЯ КОЖНОГО ГРАВЦЯ (коли востаннє здавав)
local last_tax = {}  -- {player_name = день_року}

-- ДАНІ ПРО ОСТАННІЙ ВХІД
local last_login = {} -- {player_name = день_року}

-- ФУНКЦІЯ ДЛЯ ОТРИМАННЯ ПОТОЧНОГО ДНЯ
local function get_current_day()
    return tonumber(os.date("%j"))  -- день року (1-366)
end

-- ОТРИМАТИ ВАРТІСТЬ НАСТУПНОГО РІВНЯ
local function get_next_level_cost(level)
    if level < 10 then return level * 5 + 5
    elseif level < 20 then return level * 20
    elseif level < 30 then return 400 + (level - 20) * 50
    elseif level < 40 then return 1000 + (level - 30) * 250
    elseif level < 100 then return 3500 + (level - 40) * 500
    else 
        local extra = math.floor((level - 100) / 10) * 1000
        return 35000 + extra
    end
end

-- ФУНКЦІЯ ДЛЯ ПЕРЕВІРКИ ЧИ МОЖНА ЗДАВАТЬ СЬОГОДНІ
local function can_pay_today(player_name)
    local data = human_fortress.edos_data[player_name]
    if not data then return false end
    
    local current_day = get_current_day()
    local last = last_tax[player_name] or 0
    
    -- Для рівнів 1-29 можна здавати щодня
    if data.level < 30 then
        return current_day ~= last
    end
    
    -- Для 30-59: раз на 2 дні
    if data.level >= 30 and data.level < 60 then
        return current_day >= last + 2
    end
    
    -- Для 60-89: раз на 3 дні
    if data.level >= 60 and data.level < 90 then
        return current_day >= last + 3
    end
    
    -- Для 90+: раз на 4 дні
    if data.level >= 90 then
        return current_day >= last + 4
    end
    
    return false
end

-- ФУНКЦІЯ ДЛЯ ПЕРЕВІРКИ ЧИ ТРЕБА БУЛО ЗДАВАТИ В ПРОПУЩЕНІ ДНІ
local function check_missed_taxes(player_name)
    local data = human_fortress.edos_data[player_name]
    if not data then return end
    
    local current_day = get_current_day()
    local last_tax_day = last_tax[player_name] or 0
    local last_login_day = last_login[player_name] or current_day
    
    -- Якщо гравець тільки зайшов, і останній вхід був раніше
    if last_login_day < current_day then
        local days_missed = current_day - last_login_day
        local missed_penalties = 0
        
        -- Перевіряємо кожен пропущений день
        for day = last_login_day + 1, current_day do
            -- Визначаємо чи в цей день треба було здавати
            local should_pay = false
            
            if data.level < 30 then
                should_pay = true  -- Щодня
            elseif data.level >= 30 and data.level < 60 then
                should_pay = ((day - (last_tax_day or 0)) % 2 == 1)  -- Кожен другий день
            elseif data.level >= 60 and data.level < 90 then
                should_pay = ((day - (last_tax_day or 0)) % 3 == 1)  -- Кожен третій день
            elseif data.level >= 90 then
                should_pay = ((day - (last_tax_day or 0)) % 4 == 1)  -- Кожен четвертий день
            end
            
            if should_pay then
                missed_penalties = missed_penalties + 1
            end
        end
        
        if missed_penalties > 0 then
            local cost = get_next_level_cost(data.level) * missed_penalties
            data.score = data.score - cost
            
            minetest.chat_send_player(player_name, "§E[ГОЛОС]§F Ти пропустив " .. missed_penalties .. " днів податків! Я забираю §R" .. cost .. "§F ейдосів.")
            
            -- Оновлюємо останню здачу
            last_tax[player_name] = current_day
        end
    end
    
    -- Оновлюємо останній вхід
    last_login[player_name] = current_day
end

-- ПОЗНАЧИТИ ЩО ЗДАВ
local function mark_tax_paid(player_name)
    last_tax[player_name] = get_current_day()
end

-- 1. Створення HUD
local function create_time_hud(player)
    local name = player:get_player_name()
    
    if human_fortress.clock_huds[name] then
        player:hud_remove(human_fortress.clock_huds[name].base)
        player:hud_remove(human_fortress.clock_huds[name].hand)
    end

    -- СТРІЛКА (Hand) - z_index нижче, ніж у бази
    local hand_id = player:hud_add({
        hud_elem_type = "image",
        position = {x = 0.8, y = 0.2},
        offset = {x = 0, y = 0},
        text = "clock_hand_sheet.png^[sheet:1x24:0,0",
        scale = {x = 4, y = 4},
        alignment = {x = 0, y = 0},
        z_index = 9, 
    })

    -- ОСНОВА (Base) - z_index вище
    local base_id = player:hud_add({
        hud_elem_type = "image",
        position = {x = 0.8, y = 0.2},
        offset = {x = 0, y = 0},
        text = "clock_base.png",
        scale = {x = 4, y = 4},
        alignment = {x = 0, y = 0},
        z_index = 10,
    })
    
    human_fortress.clock_huds[name] = {base = base_id, hand = hand_id}
end

-- 2. Логіка оновлення та штрафів
local tax_warnings = {} -- {player_name = true/false}

minetest.register_globalstep(function(dtime)
    local time_raw = minetest.get_timeofday()
    local total_minutes = time_raw * 24000
    local hour = math.floor(time_raw * 24) -- 0-23 для атласу
    local minute = math.floor((total_minutes % 1000) / 1000 * 60)
    
    -- Оновлення стрілки для всіх гравців
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local huds = human_fortress.clock_huds[name]
        if huds then
            local frame = math.floor(hour)
            if frame > 23 then frame = 23 end
            if frame < 0 then frame = 0 end
            
            local sheet_mod = "^[sheet:1x24:0," .. tostring(frame)
            player:hud_change(huds.hand, "text", "clock_hand_sheet.png" .. sheet_mod)
        end
    end

    -- ЛОГІКА ШТРАФУ
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local data = human_fortress.edos_data[name]
        
        if not data then goto continue end
        
        -- Ініціалізуємо статус попередження
        if tax_warnings[name] == nil then
            tax_warnings[name] = false
        end
        
        -- Попередження о 21:30
        if hour == 21 and minute == 30 and not tax_warnings[name] and not data.tax_paid then
            -- Перевіряємо чи можна здавати сьогодні
            if can_pay_today(name) then
                minetest.chat_send_player(name, "§E[Податки]§F Зараз 21:30! Здай Ейдоси до 22:10, або штраф!")
                tax_warnings[name] = true
            else
                -- Якщо не можна здавати, то й попередження не треба
                tax_warnings[name] = false
            end
        end

        -- Час здачі податку (22:10)
        if hour == 22 and minute == 10 then
            -- Якщо отримував попередження і ще не здав
            if tax_warnings[name] and not data.tax_paid then
                if can_pay_today(name) then
                    local cost = get_next_level_cost(data.level)
                    data.score = data.score - cost
                    data.level = data.level + 1
                    mark_tax_paid(name)
                    
                    -- ВИБІР СЛОВА!
                    if human_fortress.on_level_up then
                        human_fortress.on_level_up(name)
                    end
                    
                    minetest.sound_play("default_tool_breaks", {to_player = name, gain = 1.0})
                    minetest.chat_send_player(name, "§E[ГОЛОС]§F Час вийшов! Я забираю ейдоси які потрібні і це: §R" .. cost .. "§F і перевожу тебе на новий рівень.")
                    
                    if human_fortress.update_gui then 
                        local player = minetest.get_player_by_name(name)
                        if player then
                            human_fortress.update_gui(player) 
                        end
                    end
                else
                    -- Якщо не повинен був здавати, то нічого не робимо
                    minetest.chat_send_player(name, "§E[ГОЛОС]§F Сьогодні не твій день для податків.")
                end
                
                tax_warnings[name] = false
            end
            
            -- Якщо здав вчасно
            if data.tax_paid and tax_warnings[name] then
                minetest.chat_send_player(name, "§G[ГОЛОС]§F Молодець що перейшов на рівень вчасно.")
                tax_warnings[name] = false
                
                if human_fortress.update_gui then 
                    local player = minetest.get_player_by_name(name)
                    if player then
                        human_fortress.update_gui(player) 
                    end
                end
            end
        end

        -- О 00:00 скидаємо статус податку
        if hour == 0 and minute == 0 then
            data.tax_paid = false
            tax_warnings[name] = false
        end

        ::continue::
    end
end)

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    
    -- Перевіряємо чи не пропустив податки
    check_missed_taxes(name)
    
    minetest.after(3, function() 
        create_time_hud(player)
        tax_warnings[name] = false
    end)
end)

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    tax_warnings[name] = nil
    -- Не видаляємо last_tax і last_login, бо це дані про прогрес
end)

-- КОМАНДА ДЛЯ ПЕРЕВІРКИ СТАТУСУ ПОДАТКІВ
minetest.register_chatcommand("tax_status", {
    func = function(name)
        local data = human_fortress.edos_data[name]
        if not data then
            minetest.chat_send_player(name, "§RПомилка: дані не знайдені!")
            return
        end
        
        local last = last_tax[name] or 0
        local current = get_current_day()
        local can = can_pay_today(name)
        
        minetest.chat_send_player(name, "=== СТАТУС ПОДАТКІВ ===")
        minetest.chat_send_player(name, "Рівень: " .. data.level)
        minetest.chat_send_player(name, "Остання здача: день " .. last)
        minetest.chat_send_player(name, "Поточний день: " .. current)
        minetest.chat_send_player(name, "Можна здати сьогодні: " .. (can and "✅ ТАК" or "❌ НІ"))
        
        if data.level >= 30 and data.level < 60 then
            minetest.chat_send_player(name, "Режим: раз на 2 дні")
        elseif data.level >= 60 and data.level < 90 then
            minetest.chat_send_player(name, "Режим: раз на 3 дні")
        elseif data.level >= 90 then
            minetest.chat_send_player(name, "Режим: раз на 4 дні")
        else
            minetest.chat_send_player(name, "Режим: щодня")
        end
    end
})