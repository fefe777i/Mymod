-- ============================================
-- СИСТЕМА КЕРУВАННЯ - РЕЖИМ КОМАНДУВАННЯ
-- ============================================

local cmd_mode = {}
local storage = minetest.get_mod_storage()
local exit_command_mode -- forward declaration, визначається нижче

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
-- ДАНІ ПРО БУДІВЛІ (без кастомних моделей-голограм!)
-- Прев'ю тепер малюється на клієнті через фантомні блоки (ghost nodes),
-- тому НЕ потрібно робити .obj/.png для кожної будівлі окремо.
-- Просто вкажи, яким існуючим блоком показувати прев'ю для кожного типу.
-- ============================================

local BUILDING_PREVIEWS = {
    townhall = { label = "🏛️ Ратуша",  preview_node = "default:brick" },
    farm     = { label = "🌾 Ферма",   preview_node = "default:dirt_with_grass" },
    barracks = { label = "⚔️ Казарми", preview_node = "default:stonebrick" },
    wall     = { label = "🧱 Стіна",   preview_node = "default:stonebrick" },
    tower    = { label = "🗼 Вежа",    preview_node = "default:stone" },
    house    = { label = "🏠 Дім",     preview_node = "default:wood" },
    market   = { label = "🏪 Ринок",   preview_node = "default:junglewood" },
}
-- ^ Заміни preview_node на будь-який реальний зареєстрований нод, який
--   виглядає доречно для конкретної будівлі (можна навіть використати
--   головний матеріал зі схеми будівлі, якщо знаєш його).

-- ============================================
-- МІСТ ДО КЛІЄНТА: MOD CHANNEL ДЛЯ ФАНТОМНИХ БЛОКІВ
-- Сервер НЕ може напряму викликати core.set_ghost_node (це CSM-функція,
-- вона існує лише в клієнтських модах). Тому сервер надсилає повідомлення
-- через mod channel, а окремий клієнтський мод (CSM) його приймає і сам
-- викликає core.set_ghost_node/clear_ghost_nodes.
-- Дивись файл human_fortress_ghost_csm/init.lua - його треба покласти
-- в ТЕКУ КЛІЄНТСЬКИХ МОДІВ (client-side mods), а не в звичайні mods/!
-- ============================================

-- ============================================
-- ФАНТОМНИЙ БЛОК ЧЕРЕЗ ENTITY (visual = "wielditem")
-- Той самий спосіб, яким рендеряться викинуті предмети - надійний,
-- вбудований, не потребує ані CSM, ані змін в рушії.
-- Кубічний нод виглядає ІДЕНТИЧНО реальному блоку такого типу.
-- ============================================

minetest.register_entity("human_fortress:ghost_preview", {
    initial_properties = {
        visual = "wielditem",
        wield_item = "air",
        visual_size = { x = 1.0, y = 1.0 }, -- 1.0 = повний розмір ноду (не як у викинутого предмета 0.4)
        physical = false,
        collide_with_objects = false,
        pointable = false,
        static_save = false, -- не зберігати між рестартами світу
        glow = 6,
        color = "#FFFFFF9A", -- спроба напівпрозорості (може не спрацювати на всіх типах нодів)
    },
    on_activate = function(self)
        self.object:set_armor_groups({ immortal = 1 })
    end,
})

-- ============================================
-- ХУД-КНОПКИ ЗАМІСТЬ ХОТБАРУ (сенсорні кнопки)
-- Потребує рушій з touchable HUD (workshop47 fork)
-- ============================================

local MAIN_BUTTONS = {
    {key = "select",  tool = "human_fortress:cmd_select",  icon = "human_fortress_cmd_select.png"},
    {key = "move",    tool = "human_fortress:cmd_move",    icon = "human_fortress_cmd_move.png"},
    {key = "gather",  tool = "human_fortress:cmd_gather",  icon = "human_fortress_cmd_gather.png"},
    {key = "build",   tool = "human_fortress:cmd_build",   icon = "human_fortress_cmd_build.png"},
    {key = "attack",  tool = "human_fortress:cmd_attack",  icon = "human_fortress_cmd_attack.png"},
    {key = "enter",   tool = "human_fortress:cmd_enter",   icon = "human_fortress_cmd_enter.png"},
    {key = "repair",  tool = "human_fortress:cmd_repair",  icon = "human_fortress_cmd_repair.png"},
    {key = "destroy", tool = "human_fortress:cmd_destroy", icon = "human_fortress_cmd_destroy.png"},
    {key = "exit",    tool = "human_fortress:cmd_exit",    icon = "human_fortress_cmd_exit.png"},
}

local BUILD_BUTTONS = {
    {key = "b_move",    tool = "human_fortress:build_move",    icon = "human_fortress_cmd_move.png"},
    {key = "b_rotate",  tool = "human_fortress:build_rotate",  icon = "human_fortress_cmd_select.png"},
    {key = "b_confirm", tool = "human_fortress:build_confirm", icon = "human_fortress_cmd_build.png"},
    {key = "b_cancel",  tool = "human_fortress:build_cancel",  icon = "human_fortress_cmd_exit.png"},
}

local BUTTON_LOOKUP = {}
for _, b in ipairs(MAIN_BUTTONS) do BUTTON_LOOKUP[b.key] = b end
for _, b in ipairs(BUILD_BUTTONS) do BUTTON_LOOKUP[b.key] = b end

local function clear_hud_buttons(player)
    local name = player:get_player_name()
    local data = cmd_mode[name]
    if not data or not data.hud_buttons then return end
    for _, id in pairs(data.hud_buttons) do
        player:hud_remove(id)
    end
    data.hud_buttons = {}
end

local function show_hud_buttons(player, button_list)
    local name = player:get_player_name()
    if not cmd_mode[name] then return end
    clear_hud_buttons(player)
    cmd_mode[name].hud_buttons = {}

    local count = #button_list
    local spacing = 0.09
    local start_x = 0.5 - (count - 1) * spacing / 2

    for i, b in ipairs(button_list) do
        local id = player:hud_add({
            hud_elem_type = "image",
            type = "image",
            text = b.icon,
            position = {x = start_x + (i - 1) * spacing, y = 0.93},
            scale = {x = 3.5, y = 3.5},
            alignment = {x = 0, y = 0},
            name = "hf_btn_" .. b.key,
            touchable = true,
            z_index = 100,
        })
        cmd_mode[name].hud_buttons[b.key] = id
    end
end

local function select_tool(player, tool_name)
    local inv = player:get_inventory()
    local idx = player:get_wield_index()
    inv:set_stack("main", idx, tool_name .. " 1")
end

core.register_on_hud_touch(function(player, hud_element_name)
    local key = hud_element_name:match("^hf_btn_(.+)$")
    if not key then return end
    local b = BUTTON_LOOKUP[key]
    if not b then return end

    local name = player:get_player_name()
    if not cmd_mode[name] then return end

    if b.tool == "human_fortress:cmd_exit" then
        exit_command_mode(player)
        return
    end

    -- Кнопки, що виконуються одразу (не потребують націлювання)
    if b.tool == "human_fortress:build_confirm" then
        select_tool(player, b.tool)
        local def = minetest.registered_tools[b.tool]
        if def and def.on_use then def.on_use(player:get_wielded_item(), player) end
        return
    end
    if b.tool == "human_fortress:build_cancel" then
        select_tool(player, b.tool)
        local def = minetest.registered_tools[b.tool]
        if def and def.on_use then def.on_use(player:get_wielded_item(), player) end
        return
    end
    if b.tool == "human_fortress:build_rotate" then
        select_tool(player, b.tool)
        local def = minetest.registered_tools[b.tool]
        if def and def.on_place then def.on_place(player:get_wielded_item(), player, nil) end
        return
    end

    -- Кнопки, що потребують націлювання: озброюємо і чекаємо на тап по екрану
    select_tool(player, b.tool)
    minetest.chat_send_player(name, "🎯 Вибрано: " .. key .. " — тапни по цілі на екрані")
end)

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
-- Тепер це суто клієнтський фантом - сервер лише повідомляє клієнта,
-- що і де показати. Мапа сервера НІКОЛИ не змінюється прев'ю-блоками.
-- ============================================

-- ============================================
-- ЧИТАННЯ СХЕМИ Й ПОКАЗ УСІХ ЇЇ БЛОКІВ ЯК ФАНТОМІВ
-- ============================================

-- Підбери ці два числа під свою збірку дослідним шляхом:
local GHOST_VISUAL_SIZE = 1.0   -- 1.0 = "нібито повний блок"; зменш якщо завеликий
local GHOST_POS_OFFSET  = 0.5   -- зсув до центру ноду; постав 0, якщо фантоми "між блоків"

local SCHEMATIC_CACHE = {}

local function get_schematic_data(building_type)
    if SCHEMATIC_CACHE[building_type] ~= nil then
        return SCHEMATIC_CACHE[building_type]
    end
    local schematic = BUILDING_SCHEMATICS and BUILDING_SCHEMATICS[building_type]
    if not schematic then
        SCHEMATIC_CACHE[building_type] = false
        return false
    end
    local filepath = minetest.get_modpath("human_fortress") .. "/schematics/" .. schematic.schematic
    local data = minetest.read_schematic(filepath, {})
    SCHEMATIC_CACHE[building_type] = data or false
    return SCHEMATIC_CACHE[building_type]
end

-- Повертає {x_out, z_out} з урахуванням повороту навколо Y - та сама
-- математика, яку рушій використовує в minetest.place_schematic, щоб
-- фантом точно збігався з реальним результатом будівництва.
local function rotate_xz(x, z, sx, sz, rotation)
    if rotation == 90 then
        return z, sx - 1 - x
    elseif rotation == 180 then
        return sx - 1 - x, sz - 1 - z
    elseif rotation == 270 then
        return sz - 1 - z, x
    end
    return x, z
end

-- Повертає список { {pos=v3s16, node=name}, ... } - усі реальні (не
-- air/ignore) блоки схеми, вже зі зміщенням pos і врахованим поворотом.
local function get_ghost_blocks(building_type, anchor_pos, rotation)
    local data = get_schematic_data(building_type)
    if not data then return {} end

    local sx, sy, sz = data.size.x, data.size.y, data.size.z
    local blocks = {}

    local i = 1 -- Lua-таблиці 1-індексовані
    for z = 0, sz - 1 do
        for y = 0, sy - 1 do
            for x = 0, sx - 1 do
                local cell = data.data[i]
                i = i + 1
                if cell and cell.name ~= "air" and cell.name ~= "ignore" then
                    local prob = cell.prob or cell.param1 or 255
                    if prob > 1 then -- 0 і 1 = блок ніколи не з'явиться
                        local ox, oz = rotate_xz(x, z, sx, sz, rotation)
                        table.insert(blocks, {
                            pos = {
                                x = anchor_pos.x + ox,
                                y = anchor_pos.y + y,
                                z = anchor_pos.z + oz,
                            },
                            node = cell.name,
                        })
                    end
                end
            end
        end
    end

    return blocks
end

-- Прибрати всі фантомні блоки гравця
local function clear_preview(player_name)
    local pdata = cmd_mode[player_name]
    if not pdata then return end
    if pdata.preview_objs then
        for _, obj in ipairs(pdata.preview_objs) do
            if obj and obj:is_valid() then
                obj:remove()
            end
        end
    end
    pdata.preview_objs = nil
    pdata.preview_pos = nil
end

-- Показати повний фантомний контур будівлі на новій позиції
local function place_preview(player_name, pos)
    local pdata = cmd_mode[player_name]
    if not pdata or not pdata.build then return end
    local btype = pdata.build.selected_type
    if not btype then return end

    local binfo = BUILDING_PREVIEWS[btype]
    if not binfo then
        minetest.chat_send_player(player_name, "❌ Немає даних для типу: " .. btype)
        return
    end

    clear_preview(player_name)

    local rotation = (pdata.build.rotation or 0) % 360
    local blocks = get_ghost_blocks(btype, pos, rotation)

    if #blocks == 0 then
        -- Немає схеми (ще не зроблена) - показуємо хоча б один маркер
        local center = {
            x = pos.x + GHOST_POS_OFFSET,
            y = pos.y + GHOST_POS_OFFSET,
            z = pos.z + GHOST_POS_OFFSET,
        }
        local obj = minetest.add_entity(center, "human_fortress:ghost_preview")
        if obj then
            obj:set_properties({ wield_item = binfo.preview_node or "default:glass" })
            pdata.preview_objs = { obj }
        end
    else
        local objs = {}
        for _, block in ipairs(blocks) do
            local center = {
                x = block.pos.x + GHOST_POS_OFFSET,
                y = block.pos.y + GHOST_POS_OFFSET,
                z = block.pos.z + GHOST_POS_OFFSET,
            }
            local obj = minetest.add_entity(center, "human_fortress:ghost_preview")
            if obj then
                obj:set_properties({ wield_item = block.node })
                table.insert(objs, obj)
            end
        end
        pdata.preview_objs = objs
    end

    pdata.preview_pos = pos

    local cur = minetest.get_node(pos)
    local is_free = (cur.name == "air" or
                     cur.name == "default:grass_1" or
                     cur.name:find("^default:grass"))
    if is_free then
        minetest.chat_send_player(player_name, "✨ Місце вільне — можна будувати! (підтверди або перемісти)")
    else
        minetest.chat_send_player(player_name, "⚠️ Увага: на цьому місці щось є! Фантом показано, але будівництво може не вдатись.")
    end
end

-- ============================================
-- ФІНАЛЬНЕ БУДІВНИЦТВО ЧЕРЕЗ MTS ФАЙЛИ
-- ============================================

local function build_structure(player_name, building_type, pos, rotation)
    if not BUILDING_SCHEMATICS or not BUILDING_SCHEMATICS[building_type] then
        minetest.chat_send_player(player_name, "❌ Немає схеми для: " .. tostring(building_type))
        return false
    end
    local schematic = BUILDING_SCHEMATICS[building_type]
    rotation = rotation or 0

    -- Перевірка місця (фантомний блок ніколи не був реальним нодом на мапі,
    -- тож тут дивимось лише на те, що там реально лежить)
    local cur = minetest.get_node(pos)
    if cur.name ~= "air" and
       cur.name ~= "default:grass_1" and
       not cur.name:find("^default:grass") then
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

    local filepath = minetest.get_modpath("human_fortress") .. "/schematics/" .. schematic.schematic

    local file = io.open(filepath, "rb")
    if not file then
        minetest.chat_send_player(player_name, "❌ Файл схеми не знайдено: " .. tostring(schematic.schematic))
        return false
    end
    file:close()

    local rotation_str = tostring(rotation)
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
    if not cmd_mode[name] then cmd_mode[name] = {} end
    if not cmd_mode[name].build then cmd_mode[name].build = {} end
    cmd_mode[name].build.selected_type = building_type
    cmd_mode[name].build.rotation = cmd_mode[name].build.rotation or 0
    local start_pos = cmd_mode[name].build.pos or player:get_pos()
    cmd_mode[name].placed_previews = cmd_mode[name].placed_previews or {}

    player:hud_set_flags({hotbar = false})
    show_hud_buttons(player, BUILD_BUTTONS)

    local binfo = BUILDING_PREVIEWS[building_type]
    local label = binfo and binfo.label or building_type
    minetest.chat_send_player(name, "🏗️ Вибрано: " .. label)
    minetest.chat_send_player(name, "📌 'перемістити' → тапни по блоку")
    minetest.chat_send_player(name, "🔄 'повернути' | ✅ 'підтвердити' | ❌ 'скасувати'")

    if start_pos then
        place_preview(name, start_pos)
    end
end

local function give_command_inventory(player)
    player:get_inventory():set_list("main", {})
    player:hud_set_flags({hotbar = false})
    show_hud_buttons(player, MAIN_BUTTONS)
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

exit_command_mode = function(player)
    local name = player:get_player_name()
    clear_preview(name)
    clear_hud_buttons(player)
    player:hud_set_flags({hotbar = true})
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
                if human_fortress.players and human_fortress.players[name] then
                    for id, unit in pairs(human_fortress.players[name].units or {}) do
                        if unit and unit.object then table.insert(selected, id) end
                    end
                end
                minetest.chat_send_player(name, "✅ Виділено ВСІХ юнітів: " .. #selected)
            else
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
            elseif node.name:find("rice") or node.name:find("food") then
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

            local my_upgrades = get_player_upgrades(name)

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

minetest.register_tool("human_fortress:build_move", {
    description = "📌 Перемістити фантом (ПКМ по блоку)",
    inventory_image = "human_fortress_cmd_move.png",

    on_place = function(itemstack, placer, pointed_thing)
        local name = placer:get_player_name()
        if not cmd_mode[name] or not cmd_mode[name].build then return itemstack end

        if pointed_thing and pointed_thing.type == "node" then
            local pos = pointed_thing.above
            cmd_mode[name].build.pos = pos
            place_preview(name, pos)
            minetest.chat_send_player(name, "📌 Фантом переміщено: " .. minetest.pos_to_string(pos))
        end
        return itemstack
    end
})

minetest.register_tool("human_fortress:build_rotate", {
    description = "🔄 Повернути (ЛКМ = -90°, ПКМ = +90°)",
    inventory_image = "human_fortress_cmd_select.png",

    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        if not cmd_mode[name] or not cmd_mode[name].build then return itemstack end
        local rot = (cmd_mode[name].build.rotation or 0)
        rot = (rot - 90) % 360
        cmd_mode[name].build.rotation = rot
        if cmd_mode[name].preview_pos then
            place_preview(name, cmd_mode[name].preview_pos)
        end
        minetest.chat_send_player(name, "🔄 Поворот: " .. rot .. "° (ЛКМ = -90°)")
        return itemstack
    end,

    on_place = function(itemstack, placer, pointed_thing)
        local name = placer:get_player_name()
        if not cmd_mode[name] or not cmd_mode[name].build then return itemstack end
        local rot = (cmd_mode[name].build.rotation or 0)
        rot = (rot + 90) % 360
        cmd_mode[name].build.rotation = rot
        if cmd_mode[name].preview_pos then
            place_preview(name, cmd_mode[name].preview_pos)
        end
        minetest.chat_send_player(name, "🔄 Поворот: " .. rot .. "° (ПКМ = +90°)")
        return itemstack
    end
})

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
            minetest.chat_send_player(name, "❌ Постав фантом спочатку (перемістити)!")
            return itemstack
        end
        if not building_type then
            minetest.chat_send_player(name, "❌ Не вибрано тип будівлі!")
            return itemstack
        end

        minetest.chat_send_player(name, "🏗️ Будую " .. building_type .. " (поворот " .. rotation .. "°)...")

        clear_preview(name)
        if build_structure(name, building_type, pos, rotation) then
            cmd_mode[name].build = {}
            give_command_inventory(user)
        else
            place_preview(name, pos)
        end
        return itemstack
    end
})

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

print("[Human Fortress] Система керування завантажена (фантомні блоки замість моделей)!")