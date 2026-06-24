local storage = minetest.get_mod_storage()
local modpath = minetest.get_modpath("human_fortress")

-- Використовуємо worldpath для JSON файлу
local worldpath = minetest.get_worldpath()
local shop_config_path = worldpath .. "/human_fortress_shop.json"

-- Дані гравців
local player_data = minetest.deserialize(storage:get_string("market_player_data")) or {}

-- Збереження даних
local function save_data()
    storage:set_string("market_player_data", minetest.serialize(player_data))
end

-- Завантаження конфігурації товарів
local function load_shop_config()
    local file = io.open(shop_config_path, "r")
    if not file then
        -- Створюємо дефолтний конфіг в папці світу
        local default_config = {
            categories = {
                {
                    id = 1,
                    name = "Базові ресурси",
                    description = "Повсякденні матеріали",
                    icon = "default_wood.png",
                    always_available = true,
                    items = {
                        {name = "default:wood", price = 5, max_per_day = 64},
                        {name = "default:cobble", price = 2, max_per_day = 99},
                        {name = "default:dirt", price = 1, max_per_day = 99},
                        {name = "default:sand", price = 3, max_per_day = 64},
                        {name = "default:gravel", price = 2, max_per_day = 64},
                        {name = "default:clay_lump", price = 8, max_per_day = 32}
                    }
                },
                {
                    id = 2,
                    name = "Руди та метали",
                    description = "З'являються випадково",
                    icon = "default_steel_ingot.png",
                    always_available = false,
                    items = {
                        {name = "default:coal_lump", price = 10, max_per_day = 32},
                        {name = "default:iron_lump", price = 25, max_per_day = 16},
                        {name = "default:copper_lump", price = 20, max_per_day = 16},
                        {name = "default:tin_lump", price = 18, max_per_day = 16},
                        {name = "default:gold_lump", price = 50, max_per_day = 8},
                        {name = "default:diamond", price = 100, max_per_day = 5},
                        {name = "default:mese_crystal", price = 80, max_per_day = 8}
                    }
                },
                {
                    id = 3,
                    name = "Фермерство",
                    description = "Їжа та рослини",
                    icon = "default_apple.png",
                    always_available = false,
                    items = {
                        {name = "farming:bread", price = 15, max_per_day = 32},
                        {name = "farming:cotton", price = 8, max_per_day = 48},
                        {name = "farming:wheat", price = 6, max_per_day = 64},
                        {name = "farming:carrot", price = 12, max_per_day = 32},
                        {name = "farming:potato", price = 10, max_per_day = 32},
                        {name = "farming:tomato", price = 14, max_per_day = 24},
                        {name = "farming:apple", price = 8, max_per_day = 40}
                    }
                },
                {
                    id = 4,
                    name = "Рідкісне",
                    description = "Дуже рідкісні предмети",
                    icon = "default_mese_crystal.png",
                    always_available = false,
                    items = {
                        {name = "default:mese", price = 500, max_per_day = 2},
                        {name = "default:diamondblock", price = 800, max_per_day = 1},
                        {name = "default:goldblock", price = 400, max_per_day = 2},
                        {name = "default:steelblock", price = 200, max_per_day = 3},
                        {name = "default:obsidian", price = 150, max_per_day = 5},
                        {name = "default:meselamp", price = 120, max_per_day = 4}
                    }
                }
            }
        }
        
        file = io.open(shop_config_path, "w")
        file:write(minetest.write_json(default_config, true))
        file:close()
        
        return default_config
    end
    
    local content = file:read("*all")
    file:close()
    return minetest.parse_json(content) or {}
end

local shop_config = load_shop_config()

-- Оновлення щоденних лімітів за ІГРОВИМ часом
local function update_daily_limits()
    -- Безпечно отримуємо час доби
    local timeofday = minetest.get_timeofday()
    if not timeofday then
        timeofday = 0.5 -- Якщо nil, встановлюємо полудень
    end
    
    -- 0-47 (20 хвилин = 1 ігровий день) * 48 = кожні ~20 хвилин
    local current_game_day = math.floor(timeofday * 48)
    local last_update = storage:get_int("market_last_game_day")
    
    if last_update ~= current_game_day then
        minetest.log("action", "[human_fortress] Новий ігровий день! Оновлення ринку. День: " .. current_game_day)
        
        -- Скидаємо ліміти для всіх гравців
        for player_name, data in pairs(player_data) do
            if data.daily_sales then
                data.daily_sales = {}
            end
            if data.market_state then
                data.market_state = nil
            end
        end
        
        -- Оновлюємо доступні товари для непостійних категорій
        for _, category in ipairs(shop_config.categories) do
            if not category.always_available then
                category.available_today = {}
                -- Випадково вибираємо 6-9 товарів на сьогодні
                local available_count = math.random(6, 9)
                local shuffled = {}
                for i, item in ipairs(category.items) do
                    table.insert(shuffled, i)
                end
                
                -- Перемішуємо
                for i = #shuffled, 2, -1 do
                    local j = math.random(i)
                    shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
                end
                
                -- Беремо перші available_count
                for i = 1, available_count do
                    local index = shuffled[i]
                    if index then
                        category.available_today[category.items[index].name] = true
                        minetest.log("action", "[human_fortress] Додано товар: " .. category.items[index].name)
                    end
                end
            else
                -- Постійні категорії завжди мають всі товари
                category.available_today = {}
                for _, item in ipairs(category.items) do
                    category.available_today[item.name] = true
                end
            end
        end
        
        -- Зберігаємо номер ігрового дня
        storage:set_int("market_last_game_day", current_game_day)
        save_data()
        
        -- Сповіщення всім гравцям
        for _, player in ipairs(minetest.get_connected_players()) do
            local name = player:get_player_name()
        end
    end
end

-- Перевірка ліміту продажів
local function check_daily_limit(player_name, item_name, amount)
    player_data[player_name] = player_data[player_name] or {
        daily_sales = {},
        market_state = {category = 1, page = 0}
    }
    
    local daily_sales = player_data[player_name].daily_sales or {}
    local sold_today = daily_sales[item_name] or 0
    
    -- Знаходимо товар у конфігу
    for _, category in ipairs(shop_config.categories) do
        for _, item in ipairs(category.items) do
            if item.name == item_name then
                if sold_today + amount > item.max_per_day then
                    return false, item.max_per_day - sold_today
                end
                return true, item.max_per_day
            end
        end
    end
    
    return false, 0
end

-- Додавання продажу до ліміту
local function add_daily_sale(player_name, item_name, amount)
    player_data[player_name] = player_data[player_name] or {
        daily_sales = {},
        market_state = {category = 1, page = 0}
    }
    
    player_data[player_name].daily_sales = player_data[player_name].daily_sales or {}
    player_data[player_name].daily_sales[item_name] = (player_data[player_name].daily_sales[item_name] or 0) + amount
    save_data()
end

-- Видача EDOS гравцю
local function give_edos(player, amount)
    local inv = player:get_inventory()
    local given = 0
    local stack_max = 99999
    
    while amount > 0 do
        local stack_size = math.min(amount, stack_max)
        local stack = ItemStack("human_fortress:edos " .. stack_size)
        
        if inv:room_for_item("main", stack) then
            inv:add_item("main", stack)
            given = given + stack_size
            amount = amount - stack_size
        else
            local pos = player:get_pos()
            pos.y = pos.y + 1
            minetest.add_item(pos, stack)
            given = given + stack_size
            amount = amount - stack_size
        end
    end
    
    return given
end

-- Підрахунок EDOS в інвентарі
local function count_edos(player)
    local inv = player:get_inventory()
    local count = 0
    local list = inv:get_list("main")
    
    for i = 1, #list do
        local stack = list[i]
        if stack:get_name() == "human_fortress:edos" then
            count = count + stack:get_count()
        end
    end
    
    return count
end

-- Отримання доступних товарів для категорії
local function get_available_items(category)
    local available = {}
    for _, item in ipairs(category.items) do
        if category.available_today and category.available_today[item.name] then
            table.insert(available, item)
        end
    end
    return available
end

-- Отримання стану ринку для гравця
local function get_market_state(player_name)
    player_data[player_name] = player_data[player_name] or {
        daily_sales = {},
        market_state = {category = 1, page = 0}
    }
    
    if not player_data[player_name].market_state then
        player_data[player_name].market_state = {category = 1, page = 0}
    end
    
    return player_data[player_name].market_state
end

-- Збереження стану ринку
local function set_market_state(player_name, category, page)
    player_data[player_name] = player_data[player_name] or {
        daily_sales = {},
        market_state = {category = 1, page = 0}
    }
    
    player_data[player_name].market_state = {
        category = category,
        page = page
    }
    save_data()
end

-- Показ інтерфейсу ринку з сіткою та скролом
local function show_market(player_name, category_id, page)
    update_daily_limits()
    local player = minetest.get_player_by_name(player_name)
    if not player then return end
    
    -- Якщо категорія не вказана, беремо збережену
    if not category_id then
        local state = get_market_state(player_name)
        category_id = state.category or 1
        page = state.page or 0
    end
    
    -- Валідація категорії
    category_id = tonumber(category_id) or 1
    if category_id < 1 then category_id = 1 end
    if category_id > 4 then category_id = 4 end
    
    local edos_count = count_edos(player)
    local current_category = shop_config.categories[category_id] or shop_config.categories[1]
    local available_items = get_available_items(current_category)
    
    -- Розрахунок пагінації (9 товарів на сторінку - 3x3)
    local items_per_page = 9
    local total_pages = math.ceil(#available_items / items_per_page)
    if total_pages == 0 then total_pages = 1 end
    
    -- Валідація сторінки
    page = tonumber(page) or 0
    if page < 0 then page = 0 end
    if page >= total_pages then page = total_pages - 1 end
    
    -- Зберігаємо стан
    set_market_state(player_name, category_id, page)
    
    local start_idx = page * items_per_page + 1
    local end_idx = math.min(start_idx + items_per_page - 1, #available_items)
    
    local formspec = "size[15,10.5]" ..
        "background[0,0;15,10.5;human_fortress_market_bg.png]" ..
        "bgcolor[#1E1E2E;false]" ..
        
        -- Заголовок
        "label[0.5,0.2;🏪 Міський ринок]" ..
        "label[0.5,0.8;Гравець: " .. player_name .. "]" ..
        
        -- Баланс EDOS
        "box[11,0.8;3.8,0.8;#2D2D44]" ..
        "item_image[11.2,0.9;0.6,0.6;human_fortress:edos]" ..
        "label[12,0.95;× " .. edos_count .. "]"
    
    -- Вкладки (4 категорії)
    local tab_x = 0.5
    for i = 1, 4 do
        local category = shop_config.categories[i]
        if category then
            local selected = (i == category_id)
            local color = selected and "#4A4A6A" or "#2D2D44"
            formspec = formspec .. "box[" .. tab_x .. ",1.2;3.5,0.5;" .. color .. "]" ..
                "image[" .. (tab_x + 0.2) .. ",1.25;0.4,0.4;" .. (category.icon or "unknown_item.png") .. "]" ..
                "label[" .. (tab_x + 0.7) .. ",1.3;" .. category.name .. "]"
            
            if not selected then
                formspec = formspec .. "button[" .. tab_x .. ",1.2;3.5,0.5;category_" .. i .. ";]"
            end
        end
        tab_x = tab_x + 3.6
    end
    
    -- Опис категорії
    formspec = formspec .. "box[0.5,2;14,0.8;#3A3A5A]" ..
        "label[1,2.2;📋 " .. (current_category.description or "") .. "]"
    
    if not current_category.always_available then
        formspec = formspec .. "label[11,2.2;✨ Сьогодні в наявності: " .. #available_items .. "]"
    end
    
    -- Контейнер для сітки товарів
    formspec = formspec .. "container[0.5,3]" ..
        "box[0,0;14,6.2;#2D2D44]"
    
    -- Скролбар тільки якщо є більше 1 сторінки
    if total_pages > 1 then
        local scroll_value = 0
        if total_pages > 1 then
            scroll_value = page / (total_pages - 1)
        end
        formspec = formspec .. "scrollbar[13.2,0;0.4,6.2;vertical;market_scroll;" .. scroll_value .. "]"
    end
    
    -- Сітка 3x3 товарів
    local cols = 3
    local rows = 3
    local card_width = 4.2
    local card_height = 1.9
    local start_x = 0.3
    local start_y = 0.2
    
    for i = start_idx, end_idx do
        local item = available_items[i]
        if item then
            local idx = i - start_idx
            local row = math.floor(idx / cols)
            local col = idx % cols
            local x = start_x + (col * card_width)
            local y = start_y + (row * card_height)
            
            -- Інформація про продажі
            local sold_today = 0
            if player_data[player_name] and player_data[player_name].daily_sales then
                sold_today = player_data[player_name].daily_sales[item.name] or 0
            end
            
            -- Назва предмета (обрізаємо якщо довга)
            local item_desc = "?"
            if minetest.registered_items[item.name] and minetest.registered_items[item.name].description then
                item_desc = minetest.registered_items[item.name].description
            end
            if #item_desc > 15 then
                item_desc = string.sub(item_desc, 1, 12) .. "..."
            end
            
            -- Карточка товару
            formspec = formspec ..
                -- Рамка карточки
                "box[" .. x .. "," .. y .. ";4,1.8;#35354A]" ..
                "box[" .. (x+0.05) .. "," .. (y+0.05) .. ";3.9,1.7;#2A2A3A]" ..
                
                -- Предмет (велика іконка)
                "item_image[" .. (x+1.2) .. "," .. (y+0.2) .. ";1.6,1.6;" .. item.name .. "]" ..
                
                -- Назва предмета
                "label[" .. (x+0.2) .. "," .. (y+1.4) .. ";" .. item_desc .. "]" ..
                
                -- Ціна
                "item_image[" .. (x+0.2) .. "," .. (y+1.6) .. ";0.3,0.3;human_fortress:edos]" ..
                "label[" .. (x+0.6) .. "," .. (y+1.6) .. ";×" .. item.price .. "]" ..
                
                -- Ліміт
                "label[" .. (x+2.2) .. "," .. (y+1.6) .. ";📊 " .. sold_today .. "/" .. item.max_per_day .. "]" ..
                
                -- Поле для кількості
                "field[" .. (x+0.2) .. "," .. (y+1.1) .. ";1.2,0.6;amount_" .. item.name .. ";;1]" ..
                
                -- Кнопка продажу
                "button[" .. (x+1.6) .. "," .. (y+1.0) .. ";2.2,0.7;sell_" .. item.name .. ";📤 Продати]"
        end
    end
    
    -- Якщо немає товарів
    if #available_items == 0 then
        formspec = formspec .. "label[5.5,3;📭 Сьогодні немає товарів]"
    end
    
    formspec = formspec .. "container_end[]"
    
    -- Пагінація
    if total_pages > 1 then
        formspec = formspec .. "button[5,9.3;2,0.8;prev_page;◀ Попередня]" ..
            "label[7.3,9.5;Сторінка " .. (page + 1) .. "/" .. total_pages .. "]" ..
            "button[9.8,9.3;2,0.8;next_page;Наступна ▶]"
    end
    
    -- Кнопка виходу
    formspec = formspec .. "button[13,9.3;1.5,0.8;exit;🚪 Вихід]"
    
    minetest.show_formspec(player_name, "human_fortress:market", formspec)
end

-- Обробка продажу
local function handle_sale(player, item_name, amount_str)
    local player_name = player:get_player_name()
    amount_str = amount_str or "1"
    local amount = tonumber(amount_str) or 1
    
    if amount < 1 then amount = 1 end
    if amount > 64 then amount = 64 end
    
    -- Знаходимо товар у конфігу
    local item_data = nil
    local category_data = nil
    
    for _, category in ipairs(shop_config.categories) do
        for _, item in ipairs(category.items) do
            if item.name == item_name then
                item_data = item
                category_data = category
                break
            end
        end
        if item_data then break end
    end
    
    if not item_data then
        minetest.chat_send_player(player_name, "❌ Товар не знайдено!")
        return false
    end
    
    -- Перевіряємо чи доступний товар сьогодні
    if not category_data.always_available then
        if not category_data.available_today or not category_data.available_today[item_name] then
            minetest.chat_send_player(player_name, "❌ Цей товар сьогодні не приймають!")
            return false
        end
    end
    
    -- Перевіряємо ліміт
    local limit_ok, remaining = check_daily_limit(player_name, item_name, amount)
    if not limit_ok then
        minetest.chat_send_player(player_name, "❌ Ви досягли денного ліміту! Залишилось: " .. remaining)
        return false
    end
    
    -- Перевіряємо чи є предмети в інвентарі
    local inv = player:get_inventory()
    if not inv:contains_item("main", item_name .. " " .. amount) then
        minetest.chat_send_player(player_name, "❌ У вас недостатньо предметів!")
        return false
    end
    
    -- Забираємо предмети
    inv:remove_item("main", ItemStack(item_name .. " " .. amount))
    
    -- Видаємо EDOS
    local total_price = item_data.price * amount
    local given = give_edos(player, total_price)
    
    -- Додаємо до денного ліміту
    add_daily_sale(player_name, item_name, amount)
    
    -- Повідомлення
    local item_description = "предмет"
    if minetest.registered_items[item_name] and minetest.registered_items[item_name].description then
        item_description = minetest.registered_items[item_name].description
    end
    
    minetest.chat_send_player(player_name, 
        "✅ Продано " .. amount .. "x " .. item_description .. 
        " за " .. total_price .. " EDOS! (отримано: " .. given .. ")")
    
    return true
end

-- Обробник форм
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "human_fortress:market" then return end
    
    local player_name = player:get_player_name()
    
    if fields.exit then
        return
    end
    
    -- Отримуємо поточний стан
    local state = get_market_state(player_name)
    local current_category = state.category or 1
    local current_page = state.page or 0
    
    -- Перемикання категорій
    for i = 1, 4 do
        if fields["category_" .. i] then
            show_market(player_name, i, 0)
            return
        end
    end
    
    -- Пагінація
    if fields.prev_page then
        show_market(player_name, current_category, current_page - 1)
        return
    elseif fields.next_page then
        show_market(player_name, current_category, current_page + 1)
        return
    end
    
    -- Обробка скролбару
    if fields.market_scroll then
        local category = shop_config.categories[current_category]
        local available_items = get_available_items(category)
        local total_pages = math.ceil(#available_items / 9)
        if total_pages > 1 then
            local scroll_value = tonumber(fields.market_scroll) or 0
            local page = math.floor(scroll_value * (total_pages - 1) + 0.5)
            show_market(player_name, current_category, page)
        end
        return
    end
    
    -- Обробка продажів
    for field, value in pairs(fields) do
        if string.sub(field, 1, 5) == "sell_" then
            local item_name = string.sub(field, 6)
            local amount_field = "amount_" .. item_name
            local amount_str = fields[amount_field] or "1"
            
            handle_sale(player, item_name, amount_str)
            
            -- Оновлюємо інтерфейс зі збереженою категорією та сторінкою
            show_market(player_name, current_category, current_page)
            return
        end
    end
end)

-- Реєстрація блоку ринку
minetest.register_node("human_fortress:market", {
    description = "Міський ринок",

    drawtype = "mesh",
    mesh = "market.obj",
    tiles = {"human_fortress_market_texture.png"}, -- одна текстура

    paramtype = "light",
    paramtype2 = "facedir",

    groups = {},

    sounds = default.node_sound_wood_defaults(),
    
    on_rightclick = function(pos, node, clicker)
        local player_name = clicker:get_player_name()
        update_daily_limits()
        show_market(player_name, nil, nil)
    end,
    
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", "Міський ринок\nПКМ - продати ресурси за EDOS")
    end
})

-- Крафт ринку
minetest.register_craft({
    output = "human_fortress:market",
    recipe = {
        {"default:wood", "default:gold_ingot", "default:wood"},
        {"default:cobble", "default:chest", "default:cobble"},
        {"default:wood", "human_fortress:edos", "default:wood"}
    }
})

-- Команда для перевірки EDOS
minetest.register_chatcommand("edos", {
    description = "Перевірити кількість EDOS в інвентарі",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            local count = count_edos(player)
            minetest.chat_send_player(name, "💰 У вас є " .. count .. " EDOS")
        end
    end
})

-- Перевірка нового ігрового дня
local last_timeofday = 0
minetest.register_globalstep(function(dtime)
    -- Безпечно отримуємо час доби
    local timeofday = minetest.get_timeofday()
    if timeofday then
        -- Якщо час перейшов через 0.0 (новий день)
        if timeofday < 0.1 and last_timeofday > 0.9 then
            update_daily_limits()
        end
        last_timeofday = timeofday
    end
end)

-- Ініціалізація при завантаженні
minetest.after(1.0, function()
    update_daily_limits()
end)