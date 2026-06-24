-- Шлях до твоєї збереженої схеми (.mts)
local SCHEMATIC_PATH = minetest.get_modpath(minetest.get_current_modname()) .. "/schematics/fortress.mts"

-- Твої точні розміри структури
local STRUCT_X = 600
local STRUCT_Y = 104
local STRUCT_Z = 642

local DIST_BETWEEN = 30 
local SIDE_ZONE    = 10 

local CELL_SIZE_X = STRUCT_X + (SIDE_ZONE * 2) + DIST_BETWEEN
local CELL_SIZE_Z = STRUCT_Z 

minetest.register_on_generated(function(minp, maxp, blockseed)
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local data = vm:get_data()
    local area = VoxelArea:new({imin=emin, imax=emax})

    -- [ОСЬ ТУТ ЦЕ ПРАЦЮВАТИМЕ ІДЕАЛЬНО!]
    -- Отримуємо ID тільки під час генерації, коли гра вже знає ВСІ блоки
    local c_air     = minetest.get_content_id("air")
    local c_special = minetest.get_content_id("default:dirt") -- Тепер твій dirt спрацює!
    local c_lamp    = minetest.get_content_id("default:dirt") -- Тимчасово теж бруд для перевірки

    -- 1. Повне очищення чанка від стандартної генерації
    for i in area:iterp(minp, maxp) do
        data[i] = c_air
    end
    vm:set_data(data)

    -- Визначаємо діапазон осередків сітки
    local start_cell_x = math.floor(minp.x / CELL_SIZE_X) * CELL_SIZE_X
    local end_cell_x   = math.ceil(maxp.x / CELL_SIZE_X) * CELL_SIZE_X
    local start_cell_z = math.floor(minp.z / CELL_SIZE_Z) * CELL_SIZE_Z
    local end_cell_z   = math.ceil(maxp.z / CELL_SIZE_Z) * CELL_SIZE_Z

    for x_cell = start_cell_x, end_cell_x, CELL_SIZE_X do
        for z_cell = start_cell_z, end_cell_z, CELL_SIZE_Z do
            
            local str_pos = {
                x = x_cell + SIDE_ZONE + math.floor(DIST_BETWEEN / 2),
                y = 0, 
                z = z_cell
            }

            -- 2. Перевірка: чи перетинає чанк саму структуру?
            if maxp.x >= str_pos.x and minp.x <= str_pos.x + STRUCT_X - 1 and
               maxp.z >= str_pos.z and minp.z <= str_pos.z + STRUCT_Z - 1 and
               maxp.y >= str_pos.y and minp.y <= str_pos.y + STRUCT_Y - 1 then
                
                minetest.place_schematic_on_vmanip(
                    vm, str_pos, SCHEMATIC_PATH, "0", nil, true
                )
            end

            data = vm:get_data()

            -- 3. Малюємо спец. зони
            local function check_and_draw_zone(x_start, x_end)
                local r_min_x = math.max(minp.x, x_start)
                local r_max_x = math.min(maxp.x, x_end)
                local r_min_z = math.max(minp.z, str_pos.z)
                local r_max_z = math.min(maxp.z, str_pos.z + STRUCT_Z - 1)

                if r_min_x <= r_max_x and r_min_z <= r_max_z then
                    for x = r_min_x, r_max_x do
                        for z = r_min_z, r_max_z do
                            
                            if minp.y <= -1 and maxp.y >= -1 then
                                data[area:index(x, -1, z)] = c_lamp
                            end

                            if minp.y <= 0 and maxp.y >= 0 then
                                data[area:index(x, 0, z)] = c_special
                            end

                            if minp.y <= 10 and maxp.y >= 10 then
                                data[area:index(x, 10, z)] = c_special
                            end
                        end
                    end
                end
            end

            check_and_draw_zone(str_pos.x - SIDE_ZONE, str_pos.x - 1)
            check_and_draw_zone(str_pos.x + STRUCT_X, str_pos.x + STRUCT_X + SIDE_ZONE - 1)

            vm:set_data(data)
        end
    end

    vm:set_lighting({day=15, night=0})
    vm:calc_lighting()
    vm:write_to_map()
end)








-- Базові налаштування твоєї сітки
local GRID_START_X = 320
local GRID_START_Z = 170
local STEP_X = 650
local STEP_Z = 640
local SPAWN_Y = 41

-- Функція для телепортації на випадкову точку сітки
local function teleport_to_grid(player)
    local cell_x = math.random(-30, 30)
    local cell_z = math.random(-30, 30)

    local tp_pos = {
        x = GRID_START_X + (cell_x * STEP_X),
        y = SPAWN_Y + 1, -- на 1 блок вище сітки
        z = GRID_START_Z + (cell_z * STEP_Z)
    }

    player:set_pos(tp_pos)
end

-- Реєструємо привілей, щоб звичайні гравці після вибору спавну не могли користуватися командами
minetest.register_privilege("spawn_search", {
    description = "Дозволяє шукати свій стартовий блок за сіткою",
    give_to_singleplayer = false,
})

-- 1. Коли новий гравець заходить вперше
minetest.register_on_newplayer(function(player)
    local player_name = player:get_player_name()
    
    -- Даємо йому флай (тимчасово) і право на пошук
    local privs = minetest.get_player_privs(player_name)
    privs.fly = true
    privs.spawn_search = true
    minetest.set_player_privs(player_name, privs)

    -- Перший безкоштовний телепорт на випадкову точку сітки
    teleport_to_grid(player)

    -- Інструкція в чат
    minetest.after(2, function()
        minetest.chat_send_player(player_name, "§b========================================")
        minetest.chat_send_player(player_name, "§b[human_fortress] Оберіть свій стартовий блок!")
        minetest.chat_send_player(player_name, "§eЯкщо чанк прогрузився і блоку ТУТ НЕМАЄ — пишіть: §c/nextsb")
        minetest.chat_send_player(player_name, "§eЯкщо ви ЗНАЙШЛИ свій блок — пишіть: §a/exitsb")
        minetest.chat_send_player(player_name, "§b========================================")
    end)
end)

-- 2. Команда для стрибка на НАСТУПНУ точку
minetest.register_chatcommand("nextsb", {
    description = "Стрибнути на наступну точку сітки спавну",
    privs = {spawn_search = true}, -- Тільки для тих, хто ще шукає
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false end

        teleport_to_grid(player)
        minetest.chat_send_player(name, "§e[Сканер] Переліт на нові координати сітки...")
        return true
    end,
})

-- 3. Команда для ЗАВЕРШЕННЯ пошуку
minetest.register_chatcommand("exitsb", {
    description = "Зафіксувати цей спавн і почати гру",
    privs = {spawn_search = true},
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false end

        -- Перевіряємо, чи під ногами реально є твій блок (на всяк випадок, щоб не хитрували)
        local p_pos = player:get_pos()
        local check_pos = {x = math.round(p_pos.x), y = SPAWN_Y, z = math.round(p_pos.z)}
        local node = minetest.get_node(check_pos)

        if node.name == "human_fortress:vilka_inactive" then
            -- Забираємо права на пошук і політ
            local privs = minetest.get_player_privs(name)
            privs.spawn_search = nil
            privs.fly = nil -- вимикаємо флай (якщо він не адмін)
            minetest.set_player_privs(name, privs)

            minetest.chat_send_player(name, "§a[human_fortress] Спавн успішно закріплено! Приємної гри.")
            return true
        else
            return false, "§c[Помилка] Ви повинні стояти прямо на блоці human_fortress:vilka_inactive, щоб завершити пошук!"
        end
    end,
})

-- Допоміжна функція округлення координат
function math.round(num)
    return math.floor(num + 0.5)
end