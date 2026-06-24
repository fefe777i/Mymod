local modname = minetest.get_current_modname()
local http = minetest.request_http_api()
local API_KEY = "AIzaSyBZUOSlfTb3SIF04ImxU6ooKr_XCZeEfRc"  -- ТВІЙ КЛЮЧ

-- ЗБЕРІГАЄМО ЗГЕНЕРОВАНІ СВІТИ
local generated_worlds = {}
local next_height = 5000

-- ФУНКЦІЯ ГЕНЕРАЦІЇ СВІТУ ЧЕРЕЗ GEMINI
local function generate_world_with_gemini(player_name, description, height, callback)
    if not http then
        minetest.chat_send_player(player_name, "§c[Помилка] HTTP API не доступний!")
        return
    end
    
    local prompt = [[
Ти генератор світів для гри Minetest. Створи код на Lua для генерації унікального світу.

Опис світу: ]] .. description .. [[

Вимоги:
1. Світ має генеруватись на висоті ]] .. height .. [[ (Y координата)
2. Використовуй стандартні блоки: default:stone, default:dirt, default:sand, default:water_source, default:tree, default:leaves, default:desert_stone, default:ice, default:snowblock
3. Зроби цікавий ландшафт з горами, печерами, водою
4. Не зачіпай інші висоти, тільки навколо ]] .. height .. [[

ФОРМАТ ВІДПОВІДІ (ТІЛЬКИ LUA КОД, без пояснень):

local function generate_world_]] .. height .. [[(minp, maxp, seed)
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local data = vm:get_data()
    local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
    
    for z = minp.z, maxp.z do
        for y = minp.y, maxp.y do
            for x = minp.x, maxp.x do
                local index = area:index(x, y, z)
                
                -- ТВІЙ КОД ГЕНЕРАЦІЇ ТУТ
                -- Використовуй height = ]] .. height .. [[
                
            end
        end
    end
    
    vm:set_data(data)
    vm:calc_lighting()
    vm:write_to_map(data)
end

minetest.register_on_generated(function(minp, maxp, seed)
    if minp.y <= ]] .. height .. [[ and maxp.y >= ]] .. height .. [[ then
        generate_world_]] .. height .. [[(minp, maxp, seed)
    end
end)
]]

    local url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" .. API_KEY
    
    local payload = {
        contents = {{
            parts = {{ text = prompt }}
        }}
    }
    
    http.fetch({
        url = url,
        method = "POST",
        extra_headers = { "Content-Type: application/json" },
        data = minetest.write_json(payload),
        timeout = 30
    }, function(res)
        if not res.succeeded then
            callback(false, "Помилка з'єднання")
            return
        end
        
        local data = minetest.parse_json(res.data)
        if not data or not data.candidates then
            callback(false, "Невірна відповідь API")
            return
        end
        
        local code = data.candidates[1].content.parts[1].text
        
        -- Видаляємо markdown якщо є
        code = code:gsub("```lua", ""):gsub("```", ""):gsub("`", "")
        
        -- Виконуємо код
        local func, err = loadstring(code)
        if not func then
            callback(false, "Помилка компіляції: " .. err)
            return
        end
        
        local success, exec_err = pcall(func)
        if not success then
            callback(false, "Помилка виконання: " .. exec_err)
            return
        end
        
        callback(true, code)
    end)
end

-- ФУНКЦІЯ ТЕЛЕПОРТАЦІЇ
local function teleport_to_world(player, world_name, height)
    local pos = player:get_pos()
    local target_pos = {x = 0, y = height + 5, z = 0}
    
    minetest.add_particlespawner({
        amount = 500,
        time = 3,
        minpos = vector.subtract(pos, 3),
        maxpos = vector.add(pos, 3),
        texture = "wool_purple.png"
    })
    
    minetest.after(2, function()
        if not player or not player.is_player then return end
        player:set_pos(target_pos)
        
        -- Зберігаємо в мета
        local meta = player:get_meta()
        local worlds_list = meta:get_string("worlds_list")
        local worlds = worlds_list ~= "" and minetest.parse_json(worlds_list) or {}
        table.insert(worlds, {
            name = world_name,
            height = height,
            pos = target_pos
        })
        meta:set_string("worlds_list", minetest.write_json(worlds))
        
        minetest.chat_send_player(player:get_player_name(), 
            "§a✨ Телепортовано в світ §e'" .. world_name .. "' §aна висоті §e" .. height)
    end)
end

-- МЕНЮ ГЕНЕРАЦІЇ
local function show_generate_menu(player)
    minetest.show_formspec(player:get_player_name(), "generate_menu",
        "size[8,6]"..
        "label[2,0;§b🤖 СТВОРИ СВІЙ СВІТ]"..
        "textarea[0.5,1;7,2;description;;" ..
        "Наприклад:\nсвіт де все пустеля але є деколи вода\nлітаючі острови з кришталем\nпідземне царство з лавою\nліс з гігантськими грибами\nзамерзлий океан з айсбергами]"..
        "button[3,3.5;2,1;generate;§a🚀 СТВОРИТИ]"..
        "button_exit[3,5;2,1;close;§c❌]"
    )
end

-- МЕНЮ ТВОЇХ СВІТІВ
local function show_my_worlds(player)
    local meta = player:get_meta()
    local worlds_list = meta:get_string("worlds_list")
    local worlds = worlds_list ~= "" and minetest.parse_json(worlds_list) or {}
    
    local formspec = "size[6,7]"..
        "label[1,0;§b🌟 ТВОЇ СВІТИ]"
    
    if #worlds == 0 then
        formspec = formspec .. "label[0.5,3;§7Поки немає світів]"
    else
        for i, world in ipairs(worlds) do
            formspec = formspec .. 
                "button[0.5," .. i .. ";5,1;world_" .. i .. ";§e" .. world.name .. " §7(" .. world.height .. ")]"
        end
    end
    
    formspec = formspec .. "button[2,6;2,1;back;§7⬅ Назад]"
    
    minetest.show_formspec(player:get_player_name(), "my_worlds_menu", formspec)
end

-- ГОЛОВНЕ МЕНЮ
local function show_main_menu(player)
    minetest.show_formspec(player:get_player_name(), "main_menu",
        "size[6,5]"..
        "label[1.5,0;§6🚀 ІСКРА ТЕЛЕПОРТ]"..
        "button[0.5,1;2,1;block;§b📦 До блоку]"..
        "button[3.5,1;2,1;generate;§e🤖 Створити світ]"..
        "button[2,2.5;2,1;my_worlds;§a🌟 Мої світи]"..
        "button_exit[2,4;2,1;close;§c❌]"
    )
end

-- КОМАНДА /iskra
minetest.register_chatcommand("iskra", {
    description = "Відкрити меню телепортації",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            show_main_menu(player)
        end
    end,
})

-- КОМАНДА /worlds (список світів)
minetest.register_chatcommand("worlds", {
    description = "Показати твої світи",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            show_my_worlds(player)
        end
    end,
})

-- ОБРОБНИК НАТИСКАНЬ
minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    
    if formname == "main_menu" then
        if fields.block then
            minetest.show_formspec(name, "spark_menu",
                "size[6,3]field[0.5,1;5,1;input;Напиши блок;]button_exit[2,2;2,1;ok;§a🚀 Запуск]"
            )
        elseif fields.generate then
            show_generate_menu(player)
        elseif fields.my_worlds then
            show_my_worlds(player)
        end
        return true
    end
    
    if formname == "generate_menu" and fields.generate then
        local description = fields.description
        if description and description ~= "" then
            minetest.chat_send_player(name, "§7[Генерація] Створюю світ: §f" .. description)
            minetest.chat_send_player(name, "§7[Генерація] Висота: §f" .. next_height)
            
            generate_world_with_gemini(name, description, next_height, function(success, result)
                if success then
                    minetest.chat_send_player(name, "§a✅ Світ згенеровано!")
                    teleport_to_world(player, description, next_height)
                    next_height = next_height + 2000
                else
                    minetest.chat_send_player(name, "§c❌ Помилка: " .. result)
                end
            end)
        end
        return true
    end
    
    if formname == "my_worlds_menu" then
        if fields.back then
            show_main_menu(player)
            return true
        end
        
        for field, _ in pairs(fields) do
            if field:find("world_") then
                local meta = player:get_meta()
                local worlds = minetest.parse_json(meta:get_string("worlds_list")) or {}
                local index = tonumber(field:match("world_(%d+)"))
                if index and worlds[index] then
                    teleport_to_world(player, worlds[index].name, worlds[index].height)
                end
                return true
            end
        end
    end
    
    if formname == "spark_menu" and fields.ok then
        local block_name = fields.input
        if block_name and block_name ~= "" then
            minetest.add_particlespawner({
                amount = 200,
                time = 2,
                minpos = vector.subtract(player:get_pos(), 2),
                maxpos = vector.add(player:get_pos(), 2),
                texture = "wool_yellow.png"
            })
            
            minetest.after(1, function()
                if not player or not player.is_player then return end
                local target = minetest.find_node_near(player:get_pos(), 100, {block_name})
                if target then
                    player:set_pos(target)
                    minetest.chat_send_player(name, "§aТелепортовано до " .. block_name)
                else
                    minetest.chat_send_player(name, "§cБлок не знайдено!")
                end
            end)
        end
        return true
    end
end)

print("[Іскра] Завантажено! Використовуй /iskra")