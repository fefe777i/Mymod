-- ============================================
-- СИСТЕМА КЕРУВАННЯ - РЕЖИМ КОМАНДУВАННЯ
-- ============================================

local cmd_mode = {}
local storage = minetest.get_mod_storage()

local function save_cmd_mode(name)
    if cmd_mode[name] then
        local data = { pos = cmd_mode[name].pos, inv = cmd_mode[name].inv }
        storage:set_string("cmd_mode_" .. name, minetest.serialize(data))
    else
        storage:set_string("cmd_mode_" .. name, "")
    end
end

local function load_cmd_mode(name)
    local raw = storage:get_string("cmd_mode_" .. name)
    if raw and raw ~= "" then return minetest.deserialize(raw) end
    return nil
end

-- ============================================
-- РЕЄСТРАЦІЯ НОДІВ-ГОЛОГРАМ ДЛЯ КОЖНОЇ БУДІВЛІ
-- Кожна будівля має свій унікальний блок-прев'ю.
-- Ти сам робиш текстури: human_fortress_preview_<тип>.png
-- ============================================

-- Кожна будівля має:
--   mesh  = назва .obj файлу в папці models/  (ти робиш сам)
--   tiles = текстура для mesh (ти робиш сам)
--   label = назва в меню
--
-- Структура файлів:
--   mods/human_fortress/models/human_fortress_preview_barracks.obj
--   mods/human_fortress/textures/human_fortress_preview_barracks.png
--   ... і так для кожної будівлі

local BUILDING_PREVIEWS = {
    townhall = {
        label = "🏛️ Ратуша",
        mesh  = "human_fortress_preview_townhall.obj",
        icon  = "human_fortress_preview_townhall.png",
    },
    farm = {
        label = "🌾 Ферма",
        mesh  = "human_fortress_preview_farm.obj",
        icon  = "human_fortress_preview_farm.png",
    },
    barracks = {
        label = "⚔️ Казарми",
        mesh  = "human_fortress_preview_barracks.obj",
        icon  = "human_fortress_preview_barracks.png",
    },
    wall = {
        label = "🧱 Стіна",
        mesh  = "human_fortress_preview_wall.obj",
        icon  = "human_fortress_preview_wall.png",
    },
    tower = {
        label = "🗼 Вежа",
        mesh  = "human_fortress_preview_tower.obj",
        icon  = "human_fortress_preview_tower.png",
    },
    house = {
        label = "🏠 Дім",
        mesh  = "human_fortress_preview_house.obj",
        icon  = "human_fortress_preview_house.png",
    },
    market = {
        label = "🏪 Ринок",
        mesh  = "human_fortress_preview_market.obj",
        icon  = "human_fortress_preview_market.png",
    },
}

-- Реєструємо нод-голограму для кожної будівлі
for btype, bdata in pairs(BUILDING_PREVIEWS) do
    minetest.register_node("human_fortress:preview_" .. btype, {
        description = "Голограма: " .. bdata.label,
        drawtype = "mesh",
        mesh = bdata.mesh,          -- твій .obj файл
        tiles = { bdata.icon },     -- твоя текстура
        paramtype = "light",
        paramtype2 = "facedir",     -- підтримує поворот на 0/90/180/270°
        sunlight_propagates = true,
        walkable = false,           -- крізь неї можна ходити
        pointable = true,           -- можна клікати
        diggable = false,
        buildable_to = false,
        light_source = 6,
        use_texture_alpha = "blend", -- напівпрозорість якщо текстура має alpha
        groups = { not_in_creative_inventory = 1 },
        on_dig = function() return false end,
    })
end

-- ============================================
-- ДОПОМІЖНІ ФУНКЦІЇ ДЛЯ ЮНІТІВ
-- ============================================

local function get_selected_units(player)
    local name = player:get_player_name()
    if not human_fortress.players or not human_fortress.players[name] then return {} end
    return human_fortress.players[name].selected or {}
end

local function set_selected_units(player, units)
    local name = player:get_player_name()
    if not human_fortress.players then human_fortress.players = {} end
    if not human_fortress.players[name] then human_fortress.players[name] = {units = {}, selected = {}} end
    human_fortress.players[name].selected = units
end

-- ============================================
-- СИСТЕМА ПРЕВ'Ю: ПОСТАВИТИ / ПРИБРАТИ / ПЕРЕМІСТИТИ
-- ============================================

-- Прибрати голограму гравця зі світу
local function clear_preview(player_name)
    local pdata = cmd_mode[player_name]
    if not pdata or not pdata.preview_pos then return end
    local cur = minetest.get_node(pdata.preview_pos)
    -- Видаляємо лише якщо це наш нод-голограма
    if cur.name:find("^human_fortress:preview_") then
        minetest.remove_node(pdata.preview_pos)
    end
    pdata.preview_pos = nil
end

-- Поставити голограму на нову позицію
local function place_preview(player_name, pos)
    local pdata = cmd_mode[player_name]
    if not pdata or not pdata.build then return end
    local btype = pdata.build.selected_type
    if not btype then return end

    -- Прибираємо стару голограму
    clear_preview(player_name)

    local preview_node = "human_fortress:preview_" .. btype
    if not minetest.registered_nodes[preview_node] then
        minetest.chat_send_player(player_name, "❌ Немає голограми для типу: " .. btype)
        return
    end

    -- Перевіряємо чи місце вільне
    local cur = minetest.get_node(pos)
    local is_free = (cur.name == "air" or
                     cur.name == "default:grass_1" or
                     cur.name:find("^default:grass") or
                     cur.name:find("^human_fortress:preview_"))

    -- Ставимо голограму з поворотом
    local rotation = pdata.build.rotation or 0
    local facedir = math.floor((rotation % 360) / 90)
    minetest.set_node(pos, { name = preview_node, param2 = facedir })
    pdata.preview_pos = pos

    if is_free then
        minetest.chat_send_player(player_name, "✨ Місце вільне — можна будувати! (підтверди або перемісти)")
    else
        minetest.chat_send_player(player_name, "⚠️ Увага: на цьому місці щось є! Голограму поставлено, але будівництво може не вдатись.")
    end
end

-- ============================================
-- ФІНАЛЬНЕ БУДІВНИЦТВО ЧЕРЕЗ MTS ФАЙЛИ
-- ============================================

local function build_structure(player_name, building_type, pos, rotation)
    -- Перевірка: чи є схема для цього типу
    if not BUILDING_SCHEMATICS or not BUILDING_SCHEMATICS[building_type] then
        minetest.chat_send_player(player_name, "❌ Немає схеми для: " .. tostring(building_type))
        return false
    end
    local schematic = BUILDING_SCHEMATICS[building_type]
    rotation = rotation or 0

    -- Перевірка місця
    local cur = minetest.get_node(pos)
    if cur.name ~= "air" and
       cur.name ~= "default:grass_1" and
       not cur.name:find("^default:grass") and
       not cur.name:find("^human_fortress:preview_") then
        minetest.chat_send_player(player_name, "❌ Будівництво скасовано! На місці знаходиться: " .. cur.name)
        return false
    end

    -- Списання ресурсів (якщо є)
    if human_fortress.edos_data and human_fortress.edos_data[player_name] and schematic.cost then
        local resources = human_fortress.edos_data[player_name]
        for res, amount in pairs(schematic.cost) do
            if (resources[res] or 0) < amount then
                minetest.chat_send_player(player_name, "❌ Недостатньо ресурсів: " .. res)
                return false
            end
        end
        for res, amount in pairs(schematic.cost) do
            resources[res] = resources[res] - amount
        end
    end

    -- Прибираємо голограму
    minetest.remove_node(pos)

    -- Шлях до .mts файлу
    local filepath = minetest.get_modpath("human_fortress") .. "/schematics/" .. schematic.schematic
    
    -- Перевіряємо чи існує файл
    local file = io.open(filepath, "rb")
    if not file then
        minetest.chat_send_player(player_name, "❌ Файл схеми не знайдено: " .. tostring(schematic.schematic))
        return false
    end
    file:close()
    
    -- Поворот: mts підтримує "0", "90", "180", "270"
    local rotation_str = tostring(rotation)
    
    -- Ставимо схему
    local result = minetest.place_schematic(pos, filepath, rotation_str, nil, false)
    
    if not result then
        minetest.chat_send_player(player_name, "❌ Не вдалося звести будівлю!")
        return false
    end

    if schematic.on_built then
        schematic.on_built(player_name, pos)
    end
    
    minetest.chat_send_player(player_name, "🏗️ Будівлю зведено!")
    return true
end
-- ============================================
-- ІНВЕНТАРІ
-- ============================================

local function give_build_inventory(player, building_type)
    local name = player:get_player_name()
    local inv = player:get_inventory()
    inv:set_list("main", {})

    if not cmd_mode[name] then cmd_mode[name] = {} end
    if not cmd_mode[name].build then cmd_mode[name].build = {} end
    cmd_mode[name].build.selected_type = building_type
    cmd_mode[name].build.rotation = cmd_mode[name].build.rotation or 0
    -- Позиція береться з того місця де гравець клікнув у меню
    local start_pos = cmd_mode[name].build.pos or player:get_pos()
    cmd_mode[name].placed_previews = cmd_mode[name].placed_previews or {}

    local items = {
        "human_fortress:build_move",
        "human_fortress:build_rotate",
        "human_fortress:build_confirm",
        "human_fortress:build_cancel"
    }
    for i, item in ipairs(items) do
        inv:set_stack("main", i, item .. " 1")
    end

    local binfo = BUILDING_PREVIEWS[building_type]
    local label = binfo and binfo.label or building_type
    minetest.chat_send_player(name, "🏗️ Вибрано: " .. label)
    minetest.chat_send_player(name, "📌 ПКМ по землі — встановити голограму")
    minetest.chat_send_player(name, "🔄 ЛКМ/ПКМ rotate — повернути | ✅ confirm — збудувати")

    -- Ставимо голограму одразу на збережену позицію
    if start_pos then
        place_preview(name, start_pos)
    end
end

local function give_command_inventory(player)
    local inv = player:get_inventory()
    inv:set_list("main", {})
    local items = {
        "human_fortress:cmd_select",
        "human_fortress:cmd_move",
        "human_fortress:cmd_gather",
        "human_fortress:cmd_build",
        "human_fortress:cmd_attack",
        "human_fortress:cmd_enter",
        "human_fortress:cmd_repair",
        "human_fortress:cmd_destroy",
        "human_fortress:cmd_exit"
    }
    for i, item in ipairs(items) do
        inv:set_stack("main", i, item .. " 1")
    end
end

-- ============================================
-- ВХІД / ВИХІД З РЕЖИМУ КОМАНДУВАННЯ
-- ============================================

local function enter_command_mode(player)
    local name = player:get_player_name()
    if cmd_mode[name] then return end
    local inv = player:get_inventory()
    local pos = player:get_pos()
    cmd_mode[name] = { inv = {}, pos = pos, build = {}, placed_previews = {}, base_y = pos.y }

    for i = 1, inv:get_size("main") do
        local stack = inv:get_stack("main", i)
        if not stack:is_empty() then cmd_mode[name].inv[i] = stack:to_string() end
    end

    give_command_inventory(player)
    local fly_pos = player:get_pos()
    fly_pos.y = fly_pos.y + 15
    player:set_pos(fly_pos)

    local privs = minetest.get_player_privs(name)
    privs.fly = true
    minetest.set_player_privs(name, privs)
    player:set_properties({ reach = 35.0 })
    save_cmd_mode(name)
    minetest.chat_send_player(name, "🎮 Режим командування активовано!")
end

local function exit_command_mode(player)
    local name = player:get_player_name()
    -- Прибираємо голограму якщо є
    clear_preview(name)
    local data = cmd_mode[name]
    if not data then return end
    if data.pos then player:set_pos(data.pos) end

    local privs = minetest.get_player_privs(name)
    privs.fly = nil
    minetest.set_player_privs(name, privs)
    player:set_properties({ reach = 4.0 })

    local inv = player:get_inventory()
    inv:set_list("main", {})
    if data.inv then
        for i, stack in pairs(data.inv) do
            inv:set_stack("main", i, ItemStack(stack))
        end
    end

    cmd_mode[name] = nil
    storage:set_string("cmd_mode_" .. name, "")
    minetest.chat_send_player(name, "🚪 Вийшли з режиму командування")
end

-- ============================================
-- TOGGLE
-- ============================================

function toggle_command_mode(player)
    local name = player:get_player_name()
    if cmd_mode[name] then
        exit_command_mode(player)
    else
        enter_command_mode(player)
    end
end

-- ============================================
-- ДОПОМІЖНА ФУНКЦІЯ ПОЛЬОТУ
-- ============================================

local function apply_fly_mode(player)
    local name = player:get_player_name()
    local privs = minetest.get_player_privs(name)
    privs.fly = true
    minetest.set_player_privs(name, privs)
end

-- ============================================
-- ОБМЕЖЕННЯ ПОЛЬОТУ (30 блоків вгору)
-- ============================================

minetest.register_globalstep(function(dtime)
    for name, data in pairs(cmd_mode) do
        local player = minetest.get_player_by_name(name)
        if player and data.base_y then
            local pos = player:get_pos()
            local max_y = data.base_y + 30
            if pos.y > max_y then
                player:set_pos({ x = pos.x, y = max_y, z = pos.z })
                local vel = player:get_velocity()
                if vel and vel.y > 0 then
                    player:add_velocity({ x = 0, y = -vel.y, z = 0 })
                end
            end
        end
    end
end)

-- ============================================
-- ЗБЕРЕЖЕННЯ ПРИ ВИХОДІ / ВІДНОВЛЕННЯ ПРИ ВХОДІ
-- ============================================

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    if cmd_mode[name] then
        clear_preview(name)
        save_cmd_mode(name)
    end
end)

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    local saved = load_cmd_mode(name)
    if saved then
        cmd_mode[name] = saved
        cmd_mode[name].build = cmd_mode[name].build or {}
        cmd_mode[name].placed_previews = {}
        local pos = player:get_pos()
        cmd_mode[name].base_y = pos.y
        apply_fly_mode(player)
        player:set_properties({ reach = 30.0 })
        give_command_inventory(player)
        minetest.after(1, function()
            minetest.chat_send_player(name, "🎮 Режим командування відновлено!")
        end)
    end
end)

-- ============================================
-- 1. ВИДІЛЕННЯ ЮНІТІВ
-- ============================================

minetest.register_tool("human_fortress:cmd_select", {
    description = "🎮 Виділення юнітів (ЛКМ - область 10б, Shift+ЛКМ - всі)",
    inventory_image = "human_fortress_cmd_select.png",

    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        if not cmd_mode[name] then return end
        local ctrl = user:get_player_control()
        local selected = {}

        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.under
            if ctrl.aux1 then
                -- Shift: всі юніти
                if human_fortress.players and human_fortress.players[name] then
                    for id, unit in pairs(human_fortress.players[name].units or {}) do
                        if unit and unit.object then table.insert(selected, id) end
                    end
                end
                minetest.chat_send_player(name, "✅ Виділено ВСІХ юнітів: " .. #selected)
            else
                -- Область 10 блоків
                if human_fortress.players and human_fortress.players[name] then
                    for id, unit in pairs(human_fortress.players[name].units or {}) do
                        if unit and unit.object then
                            local upos = unit.object:get_pos()
                            if upos and vector.distance(pos, upos) < 10 then
                                table.insert(selected, id)
                            end
                        end
                    end
                end
                minetest.chat_send_player(name, "✅ Виділено юнітів: " .. #selected)
            end
            set_selected_units(user, selected)
        end
        return itemstack
    end,

    on_place = function(itemstack, placer)
        local name = placer:get_player_name()
        if not cmd_mode[name] then return end
        local selected = {}
        if human_fortress.players and human_fortress.players[name] then
            for id, unit in pairs(human_fortress.players[name].units or {}) do
                if unit and unit.object then table.insert(selected, id) end
            end
        end
        set_selected_units(placer, selected)
        minetest.chat_send_player(name, "✅ Виділено ВСІХ юнітів: " .. #selected)
        return itemstack
    end
})

-- ============================================
-- 2. РУХ ЮНІТІВ
-- ============================================

minetest.register_tool("human_fortress:cmd_move", {
    description = "🎮 Рух юнітів (ПКМ - точка призначення)",
    inventory_image = "human_fortress_cmd_move.png",

    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        if not cmd_mode[name] then return end

        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.under
            local target = { x = pos.x + 0.5, y = pos.y + 1, z = pos.z + 0.5 }
            local selected = get_selected_units(user)
            if #selected == 0 then
                minetest.chat_send_player(name, "❌ Немає виділених юнітів!")
                return itemstack
            end
            for _, id in ipairs(selected) do
                local unit = human_fortress.players[name].units[id]
                if unit and unit.object then
                    unit.unit_data.command = "move"
                    unit.unit_data.target = target
                end
            end
            minetest.chat_send_player(name, "🚶 Рух: " .. #selected .. " юнітів")
        end
        return itemstack
    end
})

-- ============================================
-- 3. ЗБІР РЕСУРСІВ
-- ============================================

minetest.register_tool("human_fortress:cmd_gather", {
    description = "🎮 Збір ресурсів (ПКМ - по ресурсу)",
    inventory_image = "human_fortress_cmd_gather.png",

    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        if not cmd_mode[name] then return end

        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.under
            local node = minetest.get_node(pos)
            local node_def = minetest.registered_nodes[node.name]
            local is_resource = false

            if (node_def and node_def.groups and node_def.groups.ether_tree) or
               node.name:find("tree") or node.name:find("wood") or node.name:find("ether") then
                is_resource = true
            elseif node.name:find("stone") or node.name:find("cobble") or node.name:find("versiforn") then
                is_resource = true
            elseif node.name:find("wheat") or node.name:find("food") then
                is_resource = true
            end

            if is_resource then
                local selected = get_selected_units(user)
                if #selected == 0 then
                    minetest.chat_send_player(name, "❌ Немає виділених юнітів!")
                    return itemstack
                end
                for _, id in ipairs(selected) do
                    local unit = human_fortress.players[name].units[id]
                    if unit and unit.object then
                        unit.unit_data.command = "gather"
                        unit.unit_data.target = pos
                    end
                end
                minetest.chat_send_player(name, "📦 Збір: " .. #selected .. " юнітів")
            else
                minetest.chat_send_player(name, "❌ Це не ресурс!")
            end
        end
        return itemstack
    end
})

-- ============================================
-- 4. БУДІВНИЦТВО — відкриває меню вибору будівлі
-- ============================================

-- Допоміжна функція для отримання списку відкритих будівель гравця
local function get_player_upgrades(name)
    local path = minetest.get_worldpath() .. "/upgrades.json"
    local file = io.open(path, "r")
    if not file then return {} end
    local content = file:read("*all")
    file:close()
    
    local data = minetest.parse_json(content) or {}
    return data[name] or {} 
end

minetest.register_tool("human_fortress:cmd_build", {
    description = "🎮 Будівництво (ПКМ по землі — відкрити меню)",
    inventory_image = "human_fortress_cmd_build.png",

    on_place = function(itemstack, placer, pointed_thing)
        local name = placer:get_player_name()
        if not cmd_mode[name] then
            minetest.chat_send_player(name, "❌ Ти не в режимі командування!")
            return itemstack
        end

        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.under
            if not cmd_mode[name].build then cmd_mode[name].build = {} end
            cmd_mode[name].build.pos = pos

            -- Отримуємо список відкритих будівель гравця
            local my_upgrades = get_player_upgrades(name)

            -- Будуємо formspec лише з відкритих будівель
            local fs = "size[6,9]" ..
                "bgcolor[#0A0A1A;true]" ..
                "box[0,0;6,0.8;#2D2D44]" ..
                "label[0.5,0.2;🏗️ ВИБІР БУДІВЛІ]"
            local y = 1.2
            for btype, bdata in pairs(BUILDING_PREVIEWS) do
                if my_upgrades[btype] then
                    fs = fs .. "button[0.5," .. y .. ";5,0.8;build_" .. btype .. ";" .. bdata.label .. "]"
                    y = y + 0.8
                end
            end
            minetest.show_formspec(name, "human_fortress:build", fs)
        else
            minetest.chat_send_player(name, "❌ Натисни ПКМ на блок землі!")
        end
        return itemstack
    end
})

-- Обробник меню вибору будівлі з перевіркою доступності
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "human_fortress:build" then return end
    local name = player:get_player_name()

    if not cmd_mode[name] or not cmd_mode[name].build then
        minetest.chat_send_player(name, "❌ Помилка: не в режимі командування")
        return
    end
    if not cmd_mode[name].build.pos then
        minetest.chat_send_player(name, "❌ Не вибрано позицію")
        return
    end

    for field, _ in pairs(fields) do
        if field:sub(1, 6) == "build_" then
            local building_type = field:sub(7)
            
            -- Перевіряємо, чи відкрита ця будівля у гравця
            local my_upgrades = get_player_upgrades(name)
            if my_upgrades[building_type] then
                minetest.close_formspec(name, "human_fortress:build")
                give_build_inventory(player, building_type)
            else
                minetest.chat_send_player(name, "❌ Ця будівля ще не куплена!")
            end
            break
        end
    end
end)
-- ============================================
-- 5. АТАКА
-- ============================================

minetest.register_tool("human_fortress:cmd_attack", {
    description = "🎮 Атака (ПКМ - по ворогу або точці)",
    inventory_image = "human_fortress_cmd_attack.png",

    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        if not cmd_mode[name] then return end

        local target_pos = nil
        if pointed_thing and pointed_thing.type == "object" then
            local obj = pointed_thing.ref
            if obj then target_pos = obj:get_pos() end
        elseif pointed_thing and pointed_thing.type == "node" then
            target_pos = pointed_thing.under
        end

        if target_pos then
            local selected = get_selected_units(user)
            if #selected == 0 then
                minetest.chat_send_player(name, "❌ Немає виділених юнітів!")
                return itemstack
            end
            for _, id in ipairs(selected) do
                local unit = human_fortress.players[name].units[id]
                if unit and unit.object then
                    unit.unit_data.command = "attack"
                    unit.unit_data.target = target_pos
                end
            end
            minetest.chat_send_player(name, "⚔️ Атака: " .. #selected .. " юнітів")
        end
        return itemstack
    end
})

-- ============================================
-- 6. УВІЙТИ В БУДІВЛЮ
-- ============================================

minetest.register_tool("human_fortress:cmd_enter", {
    description = "🎮 Увійти в будівлю",
    inventory_image = "human_fortress_cmd_enter.png",

    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        if not cmd_mode[name] then return end

        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.under
            local selected = get_selected_units(user)
            if #selected == 0 then
                minetest.chat_send_player(name, "❌ Немає виділених юнітів!")
                return itemstack
            end
            for _, id in ipairs(selected) do
                local unit = human_fortress.players[name].units[id]
                if unit and unit.object then
                    unit.unit_data.command = "enter"
                    unit.unit_data.target = pos
                end
            end
            minetest.chat_send_player(name, "🚪 Вхід: " .. #selected .. " юнітів")
        end
        return itemstack
    end
})

-- ============================================
-- 7. РЕМОНТ
-- ============================================

minetest.register_tool("human_fortress:cmd_repair", {
    description = "🎮 Ремонт будівлі",
    inventory_image = "human_fortress_cmd_repair.png",

    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        if not cmd_mode[name] then return end

        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.under
            local selected = get_selected_units(user)
            if #selected == 0 then
                minetest.chat_send_player(name, "❌ Немає виділених юнітів!")
                return itemstack
            end
            for _, id in ipairs(selected) do
                local unit = human_fortress.players[name].units[id]
                if unit and unit.object then
                    unit.unit_data.command = "repair"
                    unit.unit_data.target = pos
                end
            end
            minetest.chat_send_player(name, "🔧 Ремонт: " .. #selected .. " юнітів")
        end
        return itemstack
    end
})

-- ============================================
-- 8. ЗНИЩЕННЯ
-- ============================================

minetest.register_tool("human_fortress:cmd_destroy", {
    description = "🎮 Знищення будівлі (Shift+ПКМ)",
    inventory_image = "human_fortress_cmd_destroy.png",

    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        if not cmd_mode[name] then return end
        local ctrl = user:get_player_control()

        if pointed_thing and pointed_thing.type == "node" and ctrl.aux1 then
            minetest.remove_node(pointed_thing.under)
            minetest.chat_send_player(name, "💥 Будівлю знищено!")
        elseif pointed_thing and pointed_thing.type == "node" then
            minetest.chat_send_player(name, "⚠️ Утримуй Shift для знищення")
        end
        return itemstack
    end
})

-- ============================================
-- 9. ВИХІД
-- ============================================

minetest.register_tool("human_fortress:cmd_exit", {
    description = "🚪 Вийти з режиму командування",
    inventory_image = "human_fortress_cmd_exit.png",

    on_use = function(itemstack, user)
        exit_command_mode(user)
        return itemstack
    end
})

-- ============================================
-- БУДІВЕЛЬНІ ІНСТРУМЕНТИ (після вибору будівлі)
-- ============================================

-- 1. ПЕРЕМІСТИТИ ГОЛОГРАМУ
minetest.register_tool("human_fortress:build_move", {
    description = "📌 Перемістити голограму (ПКМ по блоку)",
    inventory_image = "human_fortress_cmd_move.png",

    on_place = function(itemstack, placer, pointed_thing)
        local name = placer:get_player_name()
        if not cmd_mode[name] or not cmd_mode[name].build then return itemstack end

        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.above  -- ставимо голограму НАД блоком
            cmd_mode[name].build.pos = pos
            place_preview(name, pos)
            minetest.chat_send_player(name, "📌 Голограму переміщено: " .. minetest.pos_to_string(pos))
        end
        return itemstack
    end
})

-- 2. ПОВЕРНУТИ ГОЛОГРАМУ
minetest.register_tool("human_fortress:build_rotate", {
    description = "🔄 Повернути (ЛКМ = -90°, ПКМ = +90°)",
    inventory_image = "human_fortress_cmd_select.png",

    on_use = function(itemstack, user, pointed_thing)
        -- ЛКМ: -90°
        local name = user:get_player_name()
        if not cmd_mode[name] or not cmd_mode[name].build then return itemstack end
        local rot = (cmd_mode[name].build.rotation or 0)
        rot = (rot - 90) % 360
        cmd_mode[name].build.rotation = rot
        -- Оновлюємо param2 голограми на місці
        local ppos = cmd_mode[name].preview_pos
        if ppos then
            local cur = minetest.get_node(ppos)
            if cur.name:find("^human_fortress:preview_") then
                minetest.set_node(ppos, { name = cur.name, param2 = math.floor(rot / 90) })
            end
        end
        minetest.chat_send_player(name, "🔄 Поворот: " .. rot .. "° (ЛКМ = -90°)")
        return itemstack
    end,

    on_place = function(itemstack, placer, pointed_thing)
        -- ПКМ: +90°
        local name = placer:get_player_name()
        if not cmd_mode[name] or not cmd_mode[name].build then return itemstack end
        local rot = (cmd_mode[name].build.rotation or 0)
        rot = (rot + 90) % 360
        cmd_mode[name].build.rotation = rot
        local ppos = cmd_mode[name].preview_pos
        if ppos then
            local cur = minetest.get_node(ppos)
            if cur.name:find("^human_fortress:preview_") then
                minetest.set_node(ppos, { name = cur.name, param2 = math.floor(rot / 90) })
            end
        end
        minetest.chat_send_player(name, "🔄 Поворот: " .. rot .. "° (ПКМ = +90°)")
        return itemstack
    end
})

-- 3. ПІДТВЕРДИТИ БУДІВНИЦТВО
minetest.register_tool("human_fortress:build_confirm", {
    description = "✅ Підтвердити будівництво",
    inventory_image = "human_fortress_cmd_build.png",

    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        if not cmd_mode[name] or not cmd_mode[name].build then return itemstack end

        local bdata = cmd_mode[name].build
        local pos = cmd_mode[name].preview_pos or bdata.pos
        local building_type = bdata.selected_type
        local rotation = bdata.rotation or 0

        if not pos then
            minetest.chat_send_player(name, "❌ Постав голограму спочатку (build_move)!")
            return itemstack
        end
        if not building_type then
            minetest.chat_send_player(name, "❌ Не вибрано тип будівлі!")
            return itemstack
        end

        minetest.chat_send_player(name, "🏗️ Будую " .. building_type .. " (поворот " .. rotation .. "°)...")

        -- Прибираємо голограму і будуємо
        clear_preview(name)
        if build_structure(name, building_type, pos, rotation) then
            cmd_mode[name].build = {}
            give_command_inventory(user)
        else
            -- Повертаємо голограму якщо не вдалось
            place_preview(name, pos)
        end
        return itemstack
    end
})

-- 4. СКАСУВАТИ
minetest.register_tool("human_fortress:build_cancel", {
    description = "❌ Скасувати вибір будівлі",
    inventory_image = "human_fortress_cmd_exit.png",

    on_use = function(itemstack, user)
        local name = user:get_player_name()
        if not cmd_mode[name] then return itemstack end
        clear_preview(name)
        cmd_mode[name].build = {}
        give_command_inventory(user)
        minetest.chat_send_player(name, "↩️ Повернуто в режим командування")
        return itemstack
    end
})

-- ============================================
-- ДЕБАГ
-- ============================================

minetest.after(5, function()
    local path = minetest.get_modpath("human_fortress") .. "/schematics"
    minetest.chat_send_all("📁 Папка schematics: " .. path)
    local files = minetest.get_dir_list(path, false)
    if files and #files > 0 then
        for _, file in ipairs(files) do
            minetest.chat_send_all("   📄 " .. file)
        end
    else
        minetest.chat_send_all("⚠️ Папка порожня або не знайдена")
    end
end)

print("[Human Fortress] Система керування завантажена!")
