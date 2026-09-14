local storage = minetest.get_mod_storage()
local MESSAGE_COOLDOWN = 5
local GIFT_COOLDOWN = 60
local INTERCEPT_CHANCE = 0.2

-- Таблиця подарунків для 6 кнопок
local GIFT_PACKAGES = {
    {
        name = "📦 Стандартний",
        desc = "Базові ресурси",
        items = {
            {name = "default:wood", count = 10},
            {name = "default:cobble", count = 15},
            {name = "default:coal_lump", count = 5}
        },
        color = "#808080"
    },
    {
        name = "📦 Гірничий",
        desc = "Корисні копалини",
        items = {
            {name = "default:steel_ingot", count = 8},
            {name = "default:copper_ingot", count = 12},
            {name = "default:tin_ingot", count = 10},
            {name = "default:coal_lump", count = 8}
        },
        color = "#FFA500"
    },
    {
        name = "📦 Дорогоцінний",
        desc = "Цінні матеріали",
        items = {
            {name = "default:gold_ingot", count = 5},
            {name = "default:diamond", count = 2},
            {name = "default:mese_crystal", count = 1}
        },
        color = "#FFD700"
    },
    {
        name = "📦 Бойовий",
        desc = "Зброя та обладунки",
        items = {
            {name = "default:sword_steel", count = 1},
            {name = "default:steel_ingot", count = 15},
            {name = "default:obsidian_shard", count = 3}
        },
        color = "#FF0000"
    },
    {
        name = "📦 Будівельний",
        desc = "Будівельні матеріали",
        items = {
            {name = "default:glass", count = 20},
            {name = "default:bronze_ingot", count = 10},
            {name = "default:clay_brick", count = 15}
        },
        color = "#00BFFF"
    },
    {
        name = "📦 Елітний",
        desc = "Найкращі предмети",
        items = {
            {name = "default:mese", count = 3},
            {name = "default:diamondblock", count = 1},
            {name = "default:goldblock", count = 2},
            {name = "default:sword_diamond", count = 1}
        },
        color = "#9400D3"
    }
}

-- Зберігання даних
local messages_data = minetest.deserialize(storage:get_string("messages")) or {}
local cooldowns = minetest.deserialize(storage:get_string("cooldowns")) or {}
local intercepted = minetest.deserialize(storage:get_string("intercepted")) or {}

-- Збереження даних
local function save_data()
    storage:set_string("messages", minetest.serialize(messages_data))
    storage:set_string("cooldowns", minetest.serialize(cooldowns))
    storage:set_string("intercepted", minetest.serialize(intercepted))
end

-- Перевірка затримки
local function check_cooldown(player_name, type)
    local key = player_name .. "_" .. type
    local last_time = cooldowns[key] or 0
    local current_time = os.time()
    local cooldown = (type == "message") and MESSAGE_COOLDOWN or GIFT_COOLDOWN
    
    if current_time - last_time < cooldown then
        return false, cooldown - (current_time - last_time)
    end
    return true, 0
end

-- Оновлення затримки
local function update_cooldown(player_name, type)
    local key = player_name .. "_" .. type
    cooldowns[key] = os.time()
    save_data()
end

-- Отримання повідомлень гравця
local function get_player_messages(player_name)
    messages_data[player_name] = messages_data[player_name] or {}
    intercepted[player_name] = intercepted[player_name] or {}
    return messages_data[player_name], intercepted[player_name]
end

-- Надсилання повідомлення
local function send_message(sender, receiver, text)
    local messages = messages_data[receiver] or {}
    table.insert(messages, {
        sender = sender,
        text = text,
        time = os.time(),
        type = "message"
    })
    messages_data[receiver] = messages
    
    if math.random() < INTERCEPT_CHANCE then
        local intercepted_msgs = intercepted[sender] or {}
        table.insert(intercepted_msgs, {
            original_receiver = receiver,
            text = text,
            time = os.time(),
            intercepted_by = sender
        })
        intercepted[sender] = intercepted_msgs
    end
    
    save_data()
    return true
end

-- Функція для створення падаючого ШАРА (ОДНА функція!)
local function spawn_gift_drop(receiver_name, gift_index, sender_name)
    local player = minetest.get_player_by_name(receiver_name)
    if not player then return false end
    
    local pos = player:get_pos()
    -- Шар з'являється вище гравця з випадковим зміщенням
    pos.y = pos.y + 25
    pos.x = pos.x + math.random(-3, 3)
    pos.z = pos.z + math.random(-3, 3)
    
    -- Створюємо сутність шара
    local obj = minetest.add_entity(pos, "human_fortress:gift_drop")
    if obj then
        local entity = obj:get_luaentity()
        if entity then
            entity.gift_data = GIFT_PACKAGES[gift_index]
            entity.receiver = receiver_name
            entity.sender = sender_name
            entity.dropped_items = false
            entity.has_landed = false
            entity.timer = 0
            
            -- Встановлюємо фізику падіння!
            obj:set_velocity({x = 0, y = -2, z = 0})
            obj:set_acceleration({x = 0, y = -4.81, z = 0})
            
            -- Ефект появи
            minetest.add_particlespawner({
                amount = 20,
                time = 0.5,
                minpos = {x = pos.x - 0.5, y = pos.y - 0.5, z = pos.z - 0.5},
                maxpos = {x = pos.x + 0.5, y = pos.y + 0.5, z = pos.z + 0.5},
                minvel = {x = -1, y = 1, z = -1},
                maxvel = {x = 1, y = 3, z = 1},
                minacc = {x = 0, y = -5, z = 0},
                maxacc = {x = 0, y = -5, z = 0},
                texture = "edos.png",
            })
        end
        return true
    end
    return false
end

-- Надсилання подарунка з падінням
local function send_gift_with_drop(sender, receiver, gift_index)
    -- Додаємо запис про подарунок
    local messages = messages_data[receiver] or {}
    table.insert(messages, {
        sender = sender,
        gift_index = gift_index,
        gift_name = GIFT_PACKAGES[gift_index].name,
        time = os.time(),
        type = "gift_drop"
    })
    messages_data[receiver] = messages
    
    -- Шанс перехоплення
    if math.random() < INTERCEPT_CHANCE then
        local intercepted_msgs = intercepted[sender] or {}
        table.insert(intercepted_msgs, {
            original_receiver = receiver,
            gift_index = gift_index,
            gift_name = GIFT_PACKAGES[gift_index].name,
            time = os.time(),
            intercepted_by = sender,
            type = "gift_drop"
        })
        intercepted[sender] = intercepted_msgs
    end
    
    -- Створюємо падаючий шар через 1 секунду
    minetest.after(1, function()
        spawn_gift_drop(receiver, gift_index, sender)
    end)
    
    save_data()
    return true
end

-- Реєстрація сутності падаючого ШАРА (ОДНА реєстрація!)
minetest.register_entity("human_fortress:gift_drop", {
    initial_properties = {
        physical = true,
        collide_with_objects = true,
        collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
        visual = "mesh",
        mesh = "human_fortress_gift.obj",
        textures = {"human_fortress_gift_texture.png"},
        visual_size = {x = 7.2, y = 7.2},
        pointable = true,
        static_save = false,
        glow = 8
    },
    
    gift_data = nil,
    receiver = nil,
    sender = nil,
    dropped_items = false,
    timer = 0,
    has_landed = false,
    
    on_step = function(self, dtime)
        self.timer = self.timer + dtime
        
        local pos = self.object:get_pos()
        if not pos then return end
        
        -- Красиве обертання шара
        local rot = self.object:get_rotation()
        rot.y = rot.y + 0.02
        rot.x = rot.x + 0
        rot.z = rot.z + 0
        self.object:set_rotation(rot)
        
        -- Перевіряємо швидкість для визначення приземлення
        local vel = self.object:get_velocity()
        if vel and math.abs(vel.y) < 0.1 and not self.has_landed then
            self.has_landed = true
            
            -- Зупиняємо шар
            self.object:set_velocity({x = 0, y = 0, z = 0})
            self.object:set_acceleration({x = 0, y = 0, z = 0})
            
            -- Ефект розбивання через 0.3 секунди
            minetest.after(1.3, function()
                if not self.dropped_items and self.gift_data then
                    self.dropped_items = true
                    
                    -- Випадання предметів
                    for _, item in ipairs(self.gift_data.items) do
                        local item_stack = ItemStack(item.name .. " " .. item.count)
                        minetest.add_item(pos, item_stack)
                    end
                    
                    -- Повідомлення гравцю
                    if self.receiver then
                        minetest.chat_send_player(self.receiver, 
                            "🎁 Отримано подарунок '" .. self.gift_data.name .. "' від " .. (self.sender or "невідомого"))
                    end
                    
                    -- Ефект частинок при розбиванні
                    minetest.add_particlespawner({
                        amount = 50,
                        time = 1,
                        minpos = {x = pos.x - 1, y = pos.y, z = pos.z - 1},
                        maxpos = {x = pos.x + 1, y = pos.y + 1, z = pos.z + 1},
                        minvel = {x = -2, y = 3, z = -2},
                        maxvel = {x = 2, y = 6, z = 2},
                        minacc = {x = 0, y = -9.81, z = 0},
                        maxacc = {x = 0, y = -9.81, z = 0},
                        minexptime = 0.5,
                        maxexptime = 1.5,
                        minsize = 0.5,
                        maxsize = 1.5,
                        collisiondetection = true,
                        texture = "edos.png",
                    })
                    
                    -- Видалення сутності
                    self.object:remove()
                end
            end)
        end
        
        -- Автовидалення якщо загубився
        if self.timer > 30 then
            self.object:remove()
        end
    end,
    
    on_punch = function(self, puncher)
        -- Якщо гравець вдарив шар, він прискорює падіння
        if puncher:is_player() and self.receiver and puncher:get_player_name() == self.receiver then
            local vel = self.object:get_velocity()
            self.object:set_velocity({x = vel.x, y = -15, z = vel.z})
            minetest.chat_send_player(self.receiver, "💥 Шар прискорився!")
        end
    end
})

-- Показ планшета (той самий код)
local function show_tablet(player_name, page, target_player)
    local formspec = ""
    local messages, intercepted_msgs = get_player_messages(player_name)
    
    if page == "main" then
        formspec = "size[15,9.5]" ..
            "background[0,0;15,9.5;human_fortress_tablet_bg.png]" ..
            "bgcolor[#1E1E2E;false]" ..
            
            -- ОДНА ТЕКСТУРА ДЛЯ ВСІХ КНОПОК
            "style_type[button;bgimg=human_fortress_button_bg.png;text_color=#FFFFFF;border=false]" ..
            
            "label[0.5,0.2;📡 Вишка]" ..
            "label[0.5,0.8;" .. player_name .. "]" ..
            "image[13.5,0.2;1.2,1.2;human_fortress_tablet_icon.png]" ..
            
            
            "button[0.5,2.2;3,0.8;messages;📨 Мої повідомлення]" ..
            "button[0.5,3.2;3,0.8;intercepted;📡 Перехоплені]" ..
            "button[0.5,4.2;3,0.8;send_msg;✉️ Надіслати повідомлення]" ..
            "button[0.5,5.2;3,0.8;send_gift;🎁 Надіслати подарунок]" ..
            "button[0.5,7.2;3,0.8;back;🔙 Вихід]" ..
            
            "container[4,1.5]" ..
            "box[0,0;10.5,0.5;#3A3A5A]" ..
            "label[0.2,0.1;💬 Система листування]" ..
            "label[0,1.5;Ласкаво просимо до системи листування вишки!]" ..
            "label[0,2.2;Ви можете:]" ..
            "label[0,2.8;• Читати отримані повідомлення]" ..
            "label[0,3.4;• Надсилати повідомлення іншим гравцям]" ..
            "label[0,4.0;• Надсилати подарунки (падають з неба!)💫]" ..
            "label[0,4.6;• Переглядати перехоплені повідомлення (шанс 20%)]" ..
            "label[0,5.5;🔄 Оберіть розділ у лівому меню]" ..
            "container_end[]"
            
    elseif page == "messages" then
        formspec = "size[15,9.5]" ..
            "background[0,0;15,9.5;human_fortress_tablet_bg.png]" ..
            "bgcolor[#1E1E2E;false]" ..
            
            -- ТЕКСТУРА ДЛЯ КНОПКИ НАЗАД
            "style_type[button;bgimg=human_fortress_button_bg.png;text_color=#FFFFFF;border=false]" ..
            
            "button[0.5,0.5;3,0.8;back;🔙 Назад]" ..
            "label[4,0.5;📨 Мої повідомлення]" ..
            "box[0.5,1.5;14,7;#2D2D44]"
        
        local y = 1.7
        for i = #messages, 1, -1 do
            local msg = messages[i]
            if y < 8.5 then
                if msg.type == "message" then
                    formspec = formspec .. "label[1," .. y .. ";Від: " .. msg.sender .. "]" ..
                        "label[1," .. (y + 0.4) .. ";📝 " .. (msg.text or "") .. "]" ..
                        "label[12," .. y .. ";" .. os.date("%H:%M", msg.time) .. "]"
                elseif msg.type == "gift_drop" then
                    formspec = formspec .. "label[1," .. y .. ";🎁 Подарунок від: " .. msg.sender .. "]" ..
                        "label[1," .. (y + 0.4) .. ";Тип: " .. (msg.gift_name or "Невідомо") .. "]" ..
                        "label[1," .. (y + 0.8) .. ";💫 Прибуде з неба!]" ..
                        "label[12," .. y .. ";" .. os.date("%H:%M", msg.time) .. "]"
                end
                formspec = formspec .. "image[0.5," .. (y + 0.1) .. ";0.5,0.5;human_fortress_icon_msg.png]"
                y = y + (msg.type == "gift_drop" and 1.6 or 1.2)
            end
        end
        
        if #messages == 0 then
            formspec = formspec .. "label[6,4;Немає повідомлень]"
        end
        
    elseif page == "intercepted" then
        formspec = "size[15,9.5]" ..
            "background[0,0;15,9.5;human_fortress_tablet_bg.png]" ..
            "bgcolor[#1E1E2E;false]" ..
            
            -- ТЕКСТУРА ДЛЯ КНОПКИ НАЗАД
            "style_type[button;bgimg=human_fortress_button_bg.png;text_color=#FFFFFF;border=false]" ..
            
            "button[0.5,0.5;3,0.8;back;🔙 Назад]" ..
            "label[4,0.5;📡 Перехоплені повідомлення]" ..
            "box[0.5,1.5;14,7;#2D2D44]"
        
        local y = 1.7
        for i = #intercepted_msgs, 1, -1 do
            local msg = intercepted_msgs[i]
            if y < 8.5 then
                if msg.type == "gift_drop" then
                    formspec = formspec .. "label[1," .. y .. ";🎁 ПЕРЕХОПЛЕНО]" ..
                        "label[1," .. (y + 0.4) .. ";Для: " .. msg.original_receiver .. "]" ..
                        "label[1," .. (y + 0.8) .. ";Тип: " .. (msg.gift_name or "Невідомо") .. "]" ..
                        "label[12," .. y .. ";" .. os.date("%H:%M", msg.time) .. "]"
                else
                    formspec = formspec .. "label[1," .. y .. ";📝 ПЕРЕХОПЛЕНО]" ..
                        "label[1," .. (y + 0.4) .. ";Для: " .. msg.original_receiver .. "]" ..
                        "label[1," .. (y + 0.8) .. ";Повідомлення: " .. (msg.text or "") .. "]" ..
                        "label[12," .. y .. ";" .. os.date("%H:%M", msg.time) .. "]"
                end
                formspec = formspec .. "image[0.5," .. (y + 0.1) .. ";0.5,0.5;human_fortress_icon_intercept.png]"
                y = y + 1.6
            end
        end
        
        if #intercepted_msgs == 0 then
            formspec = formspec .. "label[6,4;Немає перехоплених повідомлень]"
        end
        
    elseif page == "send_message" then
        local cooldown_ok, time_left = check_cooldown(player_name, "message")
        formspec = "size[15,9.5]" ..
            "background[0,0;15,9.5;human_fortress_tablet_bg.png]" ..
            "bgcolor[#1E1E2E;false]" ..
            
            -- ТЕКСТУРА ДЛЯ ВСІХ КНОПОК
            "style_type[button;bgimg=human_fortress_button_bg.png;text_color=#FFFFFF;border=false]" ..
            
            "button[0.5,0.5;3,0.8;back;🔙 Назад]" ..
            "label[4,0.5;✉️ Надіслати повідомлення]" ..
            "field[1,2;13,1;receiver;Отримувач:;]" ..
            "textarea[1,3.5;13,4;message;Повідомлення:;]" ..
            "button[5,8;5,1;send;Надіслати]"
        
        if not cooldown_ok then
            formspec = formspec .. "label[1,7.5;Зачекайте " .. math.ceil(time_left) .. " сек.]"
        end
        
    elseif page == "send_gift" then
        local cooldown_ok, time_left = check_cooldown(player_name, "gift")
        formspec = "size[15,9.5]" ..
            "background[0,0;15,9.5;human_fortress_tablet_bg.png]" ..
            "bgcolor[#1E1E2E;false]" ..
            
            -- ТЕКСТУРА ДЛЯ ВСІХ КНОПОК
            "style_type[button;bgimg=human_fortress_button_bg.png;text_color=#FFFFFF;border=false]" ..
            
            "button[0.5,0.5;3,0.8;back;🔙 Назад]" ..
            "label[4,0.5;🎁 Надіслати подарунок]" ..
            "field[1,1.5;13,1;gift_receiver;Отримувач:;]" ..
            "label[1,2.5;Оберіть тип подарунка:]" ..
            "box[0.5,3;14,5.5;#2D2D44]"
        
        local start_x = 1
        local start_y = 3.3
        
        for i = 1, 6 do
            local gift = GIFT_PACKAGES[i]
            local row = math.floor((i-1) / 3)
            local col = (i-1) % 3
            local x = start_x + (col * 4.5)
            local y = start_y + (row * 2.2)
            
            formspec = formspec .. 
                "button[" .. x .. "," .. y .. ";4,0.8;gift_" .. i .. ";" .. gift.name .. "]" ..
                "label[" .. x .. "," .. (y + 0.9) .. ";" .. gift.desc .. "]"
            
            formspec = formspec .. 
                "box[" .. x .. "," .. (y + 0.85) .. ";4,0.05;" .. gift.color .. "]"
        end
    end
    
    minetest.show_formspec(player_name, "human_fortress:tablet", formspec)
end

-- Обробник форм
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "human_fortress:tablet" then return end
    
    local player_name = player:get_player_name()
    
    if fields.back then
        show_tablet(player_name, "main")
        return
    elseif fields.messages then
        show_tablet(player_name, "messages")
        return
    elseif fields.intercepted then
        show_tablet(player_name, "intercepted")
        return
    elseif fields.send_msg then
        show_tablet(player_name, "send_message")
        return
    elseif fields.send_gift then
        show_tablet(player_name, "send_gift")
        return
        
    -- Обробка кнопок подарунків
    elseif fields.gift_1 or fields.gift_2 or fields.gift_3 or 
           fields.gift_4 or fields.gift_5 or fields.gift_6 then
        
        local gift_index
        if fields.gift_1 then gift_index = 1
        elseif fields.gift_2 then gift_index = 2
        elseif fields.gift_3 then gift_index = 3
        elseif fields.gift_4 then gift_index = 4
        elseif fields.gift_5 then gift_index = 5
        elseif fields.gift_6 then gift_index = 6
        end
        
        local receiver = fields.gift_receiver or ""
        
        if receiver == "" then
            minetest.chat_send_player(player_name, "Введіть ім'я отримувача!")
            return
        end
        
        if not minetest.get_player_by_name(receiver) then
            minetest.chat_send_player(player_name, "Гравець не знайдений або не в грі!")
            return
        end
        
        local cooldown_ok, time_left = check_cooldown(player_name, "gift")
        if not cooldown_ok then
            minetest.chat_send_player(player_name, "Зачекайте " .. math.ceil(time_left) .. " секунд!")
            return
        end
        
        if send_gift_with_drop(player_name, receiver, gift_index) then
            minetest.chat_send_player(player_name, "🎁 Подарунок '" .. GIFT_PACKAGES[gift_index].name .. "' відправлено!")
            minetest.chat_send_player(receiver, "💫 До вас летить подарунок від " .. player_name .. "!")
            update_cooldown(player_name, "gift")
            show_tablet(player_name, "main")
        end
        return
        
    elseif fields.send then
        local receiver = fields.receiver or ""
        local message = fields.message or ""
        
        if receiver == "" or message == "" then
            minetest.chat_send_player(player_name, "Заповніть усі поля!")
            return
        end
        
        if not minetest.get_player_by_name(receiver) then
            minetest.chat_send_player(player_name, "Гравець не знайдений або не в грі!")
            return
        end
        
        local cooldown_ok, time_left = check_cooldown(player_name, "message")
        if not cooldown_ok then
            minetest.chat_send_player(player_name, "Зачекайте " .. math.ceil(time_left) .. " секунд!")
            return
        end
        
        if send_message(player_name, receiver, message) then
            minetest.chat_send_player(player_name, "✉️ Повідомлення надіслано!")
            update_cooldown(player_name, "message")
            show_tablet(player_name, "main")
        end
        return
    end
end)

-- Реєстрація комп'ютера
minetest.register_node("human_fortress:pc", {
    description = "Комп'ютер вишки",
    drawtype = "mesh",
    mesh = "pc.obj",
    tiles = {"human_fortress_pc_texture.png"},
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {cracky = 2, oddly_breakable_by_hand = 2},
    sounds = default.node_sound_metal_defaults(),
    
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local player_name = clicker:get_player_name()
        show_tablet(player_name, "main")
    end,
    
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", "Комп'ютер вишки\nПКМ - відкрити")
    end
})

-- Реєстрація крафту
minetest.register_craft({
    output = "human_fortress:pc",
    recipe = {
        {"default:steel_ingot", "default:mese_crystal", "default:steel_ingot"},
        {"default:copper_ingot", "default:glass", "default:copper_ingot"},
        {"default:steel_ingot", "default:coal_lump", "default:steel_ingot"}
    }
})

-- Автозбереження
minetest.register_globalstep(function(dtime)
    local timer = (timer or 0) + dtime
    if timer > 300 then
        save_data()
        timer = 0
    end
end)

-- Дебаг-команда для тестування
minetest.register_chatcommand("test_gift", {
    description = "Тестовий подарунок",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            spawn_gift_drop(name, 1, "admin")
            minetest.chat_send_player(name, "✨ Тестовий шар створено!")
        end
    end
})