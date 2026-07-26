local modname = "human_fortress"

-- 1. РЕЄСТРАЦІЯ ПРЕДМЕТІВ
local resources = {
	{name = "edos", desc = "Ейдос", tex = "edos.png"},
	{name = "ether", desc = "Ефір", tex = "ef.png"},
	{name = "rice_item", desc = "Рис", tex = "r.png"},
	{name = "versiform", desc = "Версиформ", tex = "v.png"},
}

for _, res in ipairs(resources) do
	local item_id = modname .. ":" .. res.name
	if not minetest.registered_items[item_id] then
		minetest.register_craftitem(item_id, {
			description = res.desc,
			inventory_image = res.tex,
			stack_max = 99,
		})
	end
end

-- 2. ОСНОВНА ФУНКЦІЯ ПОГЛИНАННЯ

local function process_player_resources(player)
	if not player or not player:is_player() then return end
	local name = player:get_player_name()
	local inv = player:get_inventory()
	local data = human_fortress.edos_data[name]
	if not data then return end

	-- ВАЖЛИВО: Карта відповідності предметів до твоїх ключів у системі
	local consume_map = {
		[modname .. ":edos"]      = "score", -- Ейдоси
		[modname .. ":ether"]     = "wood",  -- Ефір -> wood
		[modname .. ":versiform"] = "stone", -- Версиформ -> stone
		[modname .. ":rice_item"] = "food",  -- Рис -> food
	}

	local changed = false
	for item_id, key in pairs(consume_map) do
		if inv:contains_item("main", item_id) then
			local stack = inv:remove_item("main", item_id .. " 99999")
			local count = stack:get_count()
			if count > 0 then
				data[key] = (data[key] or 0) + count
				changed = true
			end
		end
	end

	if changed then
		-- КРИТИЧНО: Примусова синхронізація інвентаря для мультиплеєра
		minetest.after(0.1, function()
			if player and player:is_player() then
				-- Оновлюємо HUD
				if human_fortress.update_gui then
					human_fortress.update_gui(player)
				end
				
				-- Примусово оновлюємо інвентар на клієнті
				local inv_refresh = player:get_inventory()
				player:get_inventory():set_lists(inv_refresh:get_lists())
				
				-- Звук
				minetest.sound_play("default_gravel_footstep", {to_player = name, gain = 0.5}, true)
			end
		end)
		
		-- Примусово зберігаємо дані гравця
		if human_fortress.save_data then
			human_fortress.save_data()
		end
	end
end

-- 3. БЕЗПЕЧНІ ОБРОБНИКИ (без рекурсії)

-- Перевірка інвентарю щосекунди (для піднятих предметів)
local timer = 0
minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer >= 1.0 then
		for _, player in ipairs(minetest.get_connected_players()) do
			process_player_resources(player)
		end
		timer = 0
	end
end)

-- Перевірка при будь-якій зміні в інвентарі (крафт, перекладання)
minetest.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
	-- Затримка для уникнення конфліктів
	minetest.after(0.05, function()
		if player and player:is_player() then
			process_player_resources(player)
		end
	end)
end)

-- Перевірка при вході гравця (на випадок, якщо щось залишилось з минулого разу)
minetest.register_on_joinplayer(function(player)
	minetest.after(2, function()
		if player and player:is_player() then
			process_player_resources(player)
		end
	end)
end)

minetest.register_tool("human_fortress:purple_diamond_pickaxe", {
    description = "Фіолетова алмазна кірка",
    inventory_image = "default_tool_diamondpick.png^[colorize:#8b00ff:80", -- Текстура алмазної кірки, зафарбована у фіолетовий
    tool_capabilities = {
        full_punch_interval = 0.9,
        max_drop_level = 3,
        groupcaps = {
            cracky = {times = {[1] = 2.0, [2] = 1.0, [3] = 0.5}, uses = 40, maxlevel = 3},
        },
        damage_groups = {fleshy = 5},
    },
})

minetest.register_node("human_fortress:wood", {
    description = "Wood Resource",
    tiles = {"human_fortress_wood.png"},
    groups = {choppy = 2, resource = 1},
    drop = "human_fortress:wood_item"
})

minetest.register_node("human_fortress:stone", {
    description = "Stone Resource",
    tiles = {"human_fortress_stone.png"},
    groups = {cracky = 2, resource = 1},
    drop = "human_fortress:stone_item"
})

minetest.register_node("human_fortress:food_source", {
    description = "Food Source",
    tiles = {"human_fortress_food.png"},
    groups = {dig_immediate = 2, resource = 1},
    drop = "human_fortress:food_item"
})
-- 1. Виснажений камінь (той, що з'являється після руди)
minetest.register_node("human_fortress:versiform_depleted_stone", {
    description = "Виснажений версиформ камінь",
    tiles = {"default_stone.png^[colorize:#8b00ff:30"},
    groups = {cracky = 1, not_in_creative_inventory = 1},
    
    can_dig = function(pos, digger)
        if not digger then return false end
        local tool = digger:get_wielded_item():get_name()
        
        -- Тільки фіолетова кірка ламає цей блок
        if tool == "human_fortress:purple_diamond_pickaxe" then
            return true
        end
        
        
        return false
    end,
})

-- 2. Версиформ руда
minetest.register_node("human_fortress:versiforn_source", {
    description = "Версиформ руда",
    tiles = {"versib.png"},
    -- Міняємо групу на cracky, щоб потрібна була кірка
    groups = {cracky = 3, resource = 1},
    drop = "human_fortress:versiform 70",

    -- Перевірка для руди: тільки камінь, залізо, алмаз (і наша фіолетова)
    can_dig = function(pos, digger)
        if not digger then return false end
        local tool = digger:get_wielded_item():get_name()
        
        -- Список дозволених кірок
        local allowed_tools = {
            ["default:pick_stone"] = true,
            ["default:pick_steel"] = true,
            ["default:pick_diamond"] = true,
            ["human_fortress:purple_diamond_pickaxe"] = true
        }

        if allowed_tools[tool] then
            return true
        end

        
        return false
    end,
    
    -- Після видобутку ставимо виснажений камінь
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        minetest.set_node(pos, {name = "human_fortress:versiform_depleted_stone"})
    end,
})


minetest.register_node("human_fortress:red_acacia_wood", {
    description = "Red Acacia Wood",
    tiles = {
        "default_acacia_wood.png^[colorize:#ff0000:100"
    },
    groups = {choppy = 2, oddly_breakable_by_hand = 2, wood = 1},
    sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("human_fortress:red_acacia_tree", {
    description = "Red Acacia Tree",
    tiles = {
        "default_acacia_tree_top.png^[colorize:#aa0000:100", -- верх
        "default_acacia_tree_top.png^[colorize:#aa0000:100", -- низ
        "default_acacia_tree.png^[colorize:#aa0000:100"      -- боки
    },
    paramtype2 = "facedir",
    is_ground_content = false,
    groups = {tree = 1, choppy = 2, oddly_breakable_by_hand = 1},
    sounds = default.node_sound_wood_defaults(),
})


minetest.register_craftitem("human_fortress:wood_item", {
    description = "Wood",
    inventory_image = "human_fortress_wood_item.png",
})

minetest.register_craftitem("human_fortress:stone_item", {
    description = "Stone",
    inventory_image = "human_fortress_stone_item.png",
})

minetest.register_craftitem("human_fortress:food_item", {
    description = "Food",
    inventory_image = "human_fortress_food_item.png",
})

-- Реєстрація базового блоку (обов'язково)
minetest.register_node("human_fortress:verrsi", {
    description = "Verrsi Block",
    tiles = {"human_fortress_verrsi.png"},
    groups = {cracky = 3, stone = 1},
    sounds = default.node_sound_stone_defaults(),
})

-- Реєстрація всіх похідних форм (сходинки, плити)
if minetest.get_modpath("stairs") then
    stairs.register_stair_and_slab(
        "verrsi",                          -- Назва (буде stairs:stair_verrsi та stairs:slab_verrsi)
        "human_fortress:verrsi",           -- Матеріал
        {cracky = 3, stone = 1},           -- Групи
        {"human_fortress_verrsi.png"},     -- Текстура
        "Verrsi Stair",                    -- Відображуване ім'я сходинки
        "Verrsi Slab",                     -- Відображуване ім'я плити
        default.node_sound_stone_defaults(),
        true                               -- Вмикає "full copy" для відображення в інвентарі
    )
end


minetest.register_node("human_fortress:townhall", {
    description = "Townhall (Acacia Fence)",
    drawtype = "fencelike",
    tiles = {"default_acacia_wood.png"}, -- Використання текстури акацієвого паркану
    inventory_image = "default_acacia_wood.png",
    wield_image = "default_acacia_wood.png",
    paramtype = "light",
    is_ground_content = false,
    sunlight_propagates = true,
    selection_box = {
        type = "fixed",
        fixed = {-1/8, -1/2, -1/8, 1/8, 1/2, 1/8},
    },
    -- Використання стандартної моделі огорожі
    collision_box = {
        type = "fixed",
        fixed = {-1/8, -1/2, -1/8, 1/8, 1/2, 1/8},
    },
    groups = {choppy = 2, oddly_breakable_by_hand = 2, fence = 1},
    sounds = default.node_sound_wood_defaults(),
})


local player_hud = {} -- Таблиця для зберігання ID HUD елементів
local gathering_data = {}

-- Функція оновлення прогресу
local function check_gathering(player_name, pos)
    local player = minetest.get_player_by_name(player_name)
    if not player then return end
    
    local data = gathering_data[player_name]
    if not data then return end -- Збір скасовано

 -- Перевірка дистанції
    if vector.distance(player:get_pos(), pos) > 3 then
        local hud_id = player_hud[player_name]
        if hud_id then
            player:hud_remove(hud_id)
            player_hud[player_name] = nil
        end
        gathering_data[player_name] = nil
        return
    end

    -- Оновлення прогресу
    data.progress = data.progress + 2 -- 2 одиниці за 0.1с = 100 за 5 сек
    
-- Оновлення або створення HUD
    if not player_hud[player_name] then
        player_hud[player_name] = player:hud_add({
            hud_elem_type = "statbar",
            position = {x = 0.5, y = 1.0}, -- Нижня частина екрану
            text = "ricebar.png",         -- Ваша текстура (наприклад, 16x16 пікселів)
            number = 0,                   -- Починаємо з 0
            direction = 0,                -- 0 = зліва направо
            size = {x = 16, y = 16},      -- Зменшили розмір (було 24)
            offset = {x = -80, y = -150}, -- Підняли над серцями (x - вліво, y - вгору)
        })
    else
        -- Оновлюємо прогрес. 
        -- Якщо у вас прогрес іде до 100, а ви хочете 10 поділок, 
        -- ділимо на 10: (data.progress / 10)
        player:hud_change(player_hud[player_name], "number", data.progress / 10)
    end

    if data.progress >= 100 then
        -- Успіх
        player:hud_remove(player_hud[player_name])
        player_hud[player_name] = nil
        gathering_data[player_name] = nil
        minetest.remove_node(pos)
-- Замість статичного ItemStack
local amount = math.random(3, 10) -- Генерує число від 3 до 10
local stack = ItemStack("human_fortress:rice_item " .. amount)

-- Використовуємо цей стек для дропу
minetest.item_drop(stack, player, pos)
    else
        -- Продовжуємо цикл
        minetest.after(0.1, function() check_gathering(player_name, pos) end)
    end
end

minetest.register_node("human_fortress:rice", {
    description = "Рис",
    tiles = {"rice_texture.png"},
    drawtype = "plantlike",
    paramtype = "light",
    walkable = false,
    groups = {snappy = 3, flora = 1, attached_node = 1},
    
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        -- 1. Перевірка дистанції ДО запуску логіки
        if vector.distance(clicker:get_pos(), pos) > 3 then
            minetest.chat_send_player(clicker:get_player_name(), "Ви надто далеко!")
            return
        end

        local name = clicker:get_player_name()
        
        -- 2. Перевірка, чи гравець вже збирає
        if gathering_data[name] then return end 
        
        gathering_data[name] = {pos = pos, progress = 0}
        
        -- 3. Запуск збору
        check_gathering(name, pos)
    end,
})




minetest.register_node("human_fortress:berry_bush", {
    description = "Кущ ягід",
    tiles = {"default_blueberry_bush_leaves.png^default_blueberry_overlay.png"}, -- Замініть на текстуру повного куща
    groups = {snappy = 3},
    
    -- При натисканні правою кнопкою миші
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local meta = minetest.get_meta(pos)
        local is_empty = meta:get_int("is_empty")
        
        if is_empty == 1 then
            minetest.chat_send_player(clicker:get_player_name(), "Кущ ще не відновився!")
            return
        end

        local inv = clicker:get_inventory()
        
        -- Визначаємо випадкові кількості
        local count_v = math.random(1, 20) -- від 1 до 3
        local count_et = math.random(1, 60) -- від 1 до 6
        local count_ed = math.random(1, 90) -- від 1 до 9

        -- Роздача предметів
        local items = {
            {name = "human_fortress:versiform", count = count_v},
            {name = "human_fortress:ether", count = count_et},
            {name = "human_fortress:edos", count = count_ed}
        }

        for _, item in ipairs(items) do
            local stack = ItemStack(item.name .. " " .. item.count)
            if inv:room_for_item("main", stack) then
                inv:add_item("main", stack)
            else
                minetest.add_item(pos, stack) -- Кидаємо на землю, якщо інвентар повний
            end
        end

        minetest.chat_send_player(clicker:get_player_name(), "Ви зібрали ресурси!")

        -- Робимо кущ пустим
        meta:set_int("is_empty", 1)
        minetest.swap_node(pos, {name = "human_fortress:berry_bush_empty"}) -- Замініть на назву пустої текстури/вузла
        
        -- Запускаємо таймер на 10 хвилин (600 секунд)
        minetest.get_node_timer(pos):start(600)
    end,
})

-- Таймер для відновлення
minetest.register_node("human_fortress:berry_bush_empty", {
    description = "Порожній кущ",
    tiles = {"default_blueberry_bush_leaves.png"},
    groups = {snappy = 3, not_in_creative_inventory = 1},
    drop = "human_fortress:berry_bush",
    
    on_timer = function(pos, elapsed)
        minetest.swap_node(pos, {name = "human_fortress:berry_bush"})
        minetest.get_meta(pos):set_int("is_empty", 0)
        return false -- зупиняємо таймер
    end,
})