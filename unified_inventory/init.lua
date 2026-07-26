-- FULL RTS INVENTORY WITH CREATIVE BROWSER & ATTRIBUTE LEVELS
if not minetest.features.formspec_version_element then
    error("This mod requires Minetest version 5.4.0 or newer.")
end

unified_inventory = { version = 1 }
local ui = unified_inventory

-- Функція розрахунку ціни
local function get_next_level_cost(level)
    if level < 10 then 
        return level * 5 + 5
    elseif level < 20 then 
        return level * 20 
    elseif level < 30 then 
        return 400 + (level - 20) * 50 
    elseif level < 40 then 
        return 1000 + (level - 30) * 250
    elseif level < 100 then
        return 3500 + (level - 40) * 500
    else 
        local extra = math.floor((level - 100) / 10) * 1000
        return 35000 + extra
    end
end

-- Функція для отримання даних атрибутів гравця
local function get_player_attributes(player_name)
    -- Спочатку пробуємо отримати з глобальної таблиці human_fortress
    if human_fortress and human_fortress.get_player_attributes then
        return human_fortress.get_player_attributes(player_name)
    end
    
    -- Якщо є глобальна таблиця player_attributes
    if player_attributes and player_attributes[player_name] then
        return player_attributes[player_name]
    end
    
    -- Якщо дані є в human_fortress.edos_data
    if human_fortress and human_fortress.edos_data and human_fortress.edos_data[player_name] then
        return human_fortress.edos_data[player_name].attributes or {
            mind = 0,
            strength = 0,
            will = 0,
            speed = 1.0,
            health_bonus = 0,
            damage_bonus = 0
        }
    end
    
    -- Повертаємо значення за замовчуванням
    return {
        mind = 0,
        strength = 0,
        will = 0,
        speed = 1.0,
        health_bonus = 0,
        damage_bonus = 0
    }
end

-- Функція для отримання текстури атрибута на основі його рівня
local function get_attribute_texture(attr_name, attr_level)
    local textures = {
        mind = {
            [0] = "mind_texture_0.png",
            [1] = "mind_texture_1.png",
            [2] = "mind_texture_2.png",
            [3] = "mind_texture_3.png",
            [4] = "mind_texture_4.png"
        },
        strength = {
            [0] = "strength_texture_0.png",
            [1] = "strength_texture_1.png",
            [2] = "strength_texture_2.png",
            [3] = "strength_texture_3.png",
            [4] = "strength_texture_4.png"
        },
        will = {
            [0] = "will_texture_0.png",
            [1] = "will_texture_1.png",
            [2] = "will_texture_2.png",
            [3] = "will_texture_3.png",
            [4] = "will_texture_4.png"
        }
    }
    
    -- Визначаємо рівень для текстури (0-4)
    local texture_level = math.min(4, math.floor(attr_level))
    return textures[attr_name][texture_level] or textures[attr_name][0]
end

-- Функція для отримання рівня атрибута (ціла частина + дробова для анімації)
local function get_attribute_display_level(attr_value)
    local whole_part = math.floor(attr_value)
    local fractional = attr_value - whole_part
    return whole_part, fractional
end

-- 1. КОНФІГУРАЦІЯ
ui.config = {
    form_width = 12.0, form_height = 10.0,  -- Збільшив ширину для атрибутів
    slot_size = 1.0, slot_spacing = 0.1,
    slot_positions = {
        [0] = {x = 2.2, y = 4.0}, [1] = {x = 2.2, y = 3.0}, [2] = {x = 2.2, y = 2.0},
        [3] = {x = 2.2, y = 1.0}, [4] = {x = 3.2, y = 0},   [5] = {x = 4.2, y = 0},
        [6] = {x = 5.2, y = 0},   [7] = {x = 5.6, y = 1.0}, [8] = {x = 5.6, y = 2.0},
        [9] = {x = 5.6, y = 3.0}, [10] = {x = 5.6, y = 4.0},
    },
    background_texture = "my_background.png",
    background_x = 2, background_y = 0, background_width = 5.0, background_height = 8.0,  -- Збільшив ширину фону
    slot_textures = {
        [0] = "slot_texture_0.png", [1] = "slot_texture_1.png", [2] = "slot_texture_2.png",
        [3] = "slot_texture_3.png", [4] = "slot_texture_4.png", [5] = "slot_texture_5.png",
        [6] = "slot_texture_6.png", [7] = "slot_texture_7.png", [8] = "slot_texture_8.png",
        [9] = "slot_texture_9.png", [10] = "slot_texture_10.png",
    },
    default_slot_texture = "default_slot.png",
}

function ui.add_background(formspec)
    local cfg = ui.config
    -- background[x,y;w,h;texture]
    return formspec .. string.format("background[%f,%f;%f,%f;%s]",
        cfg.background_x, cfg.background_y, cfg.background_width, cfg.background_height, cfg.background_texture)
end

function ui.add_slot(formspec, slot_num, player)
    local cfg = ui.config
    local tex = cfg.slot_textures[slot_num] or cfg.default_slot_texture
    local pos = cfg.slot_positions[slot_num]
    if not pos then pos = {x = 0, y = 0} end
    
    -- 1. Малюємо ТІЛЬКИ фон слота (текстуру)
    local new_formspec = formspec .. string.format("image[%f,%f;%f,%f;%s]",
        pos.x, pos.y, cfg.slot_size, cfg.slot_size, tex)
    
    -- 2. Додаємо сам функціональний слот. 
    -- Minetest сам намалює іконку предмета і кількість поверх фону.
    new_formspec = new_formspec .. string.format("list[current_player;main;%f,%f;1,1;%d]", 
        pos.x, pos.y, slot_num)
        
    return new_formspec
end

-- Функція для додавання атрибутів до формспека
function ui.add_attributes(formspec, player)
    local name = player:get_player_name()
    local data = human_fortress.edos_data[name] or {level = 1, score = 0}
    
    -- Отримуємо дані атрибутів через безпечну функцію
    local attr_data = get_player_attributes(name)
    
    -- Отримуємо рівні для відображення (фракції нам тепер не потрібні для барів, але залишаємо для виклику функції)
    local mind_level, _ = get_attribute_display_level(attr_data.mind or 0)
    local strength_level, _ = get_attribute_display_level(attr_data.strength or 0)
    local will_level, _ = get_attribute_display_level(attr_data.will or 0)

    -- Відображаємо тільки картинки атрибутів
    -- Я вирівняв їх по осі X (9.5), щоб вони йшли один під одним
    formspec = formspec .. string.format("image[3.2,5.5;1,1;%s]", get_attribute_texture("mind", mind_level))
    formspec = formspec .. string.format("image[4.0,6.0;1,1;%s]", get_attribute_texture("strength", strength_level))
    formspec = formspec .. string.format("image[4.7,5.4;1,1;%s]", get_attribute_texture("will", will_level))

    return formspec
end

-- 3. ГОЛОВНА ФУНКЦІЯ ГЕНЕРАЦІЇ RTS МЕНЮ
-- Додай цю функцію (або переконайся, що вона доступна)
local function get_skin_texture_for_inv(player)
    local name = player:get_player_name()
    if not human_fortress or not human_fortress.edos_data[name] then 
        return "character.png" 
    end
    
    local data = human_fortress.edos_data[name]
    local level = data.level or 0
    local selected_id = data.skin or "default"
    
    -- Тут ми беремо скіни з того самого JSON, що і в edit_skin
    -- Якщо edit_skin завантажений, звертаємось до його таблиці
    local skins = (edit_skin and edit_skin.skins) or {}
    
    for _, s in ipairs(skins) do
        if s.id == selected_id then
            if level >= 50 then return s.lvl50
            elseif level >= 40 then return s.lvl40
            elseif level >= 30 then return s.lvl30
            elseif level >= 20 then return s.lvl20
            elseif level >= 10 then return s.lvl10
            else return s.lvl0 end
        end
    end
    return "character.png"
end

-- Оновлена функція генерації GUI
function ui.get_formspec(player)
    local cfg = ui.config
    local name = player:get_player_name()
    local data = human_fortress.edos_data[name] or {level = 1, score = 0}
    local cost = get_next_level_cost(data.level)
    
    -- Отримуємо текстуру для прев'ю
    local skin_tex = get_skin_texture_for_inv(player)
    
    local formspec = string.format("size[%f,%f]", cfg.form_width, cfg.form_height)
        .. "no_prepend[]bgcolor[#0000]listcolors[#0000;#0000]"
    
    formspec = ui.add_background(formspec)
    for i = 0, 10 do formspec = ui.add_slot(formspec, i, player) end
    
    -- ДОДАЄМО ПРЕВ'Ю МОДЕЛІ
    -- x, y, w, h, name, mesh, texture, rotation_y, animation(false), transparent(true), eye_bone
    formspec = formspec .. string.format("model[3.8,1.5;1.5,3;preview_mesh;character.b3d;%s;0,180;false;true;0,0]", skin_tex)
    
    -- Додаємо атрибути
    formspec = ui.add_attributes(formspec, player)
    
    formspec = formspec .. string.format("label[7.8,1.5;Рівень: %d]", data.level)
    formspec = formspec .. string.format("label[7.8,1.9;Ейдоси: %d / %d]", data.score, cost)
    formspec = formspec .. "button[7.8,2.4;2.5,0.8;btn_levelup;📈 ПІДВИЩИТИ]"
    
    return formspec
end

-- 4. КОМАНДИ ПЕРЕМИКАННЯ
minetest.register_chatcommand("i", {
    description = "Увімкнути креативний інвентар (тільки для адмінів)",
    privs = {creative = true},
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Гравець не знайдений" end
        
        player:set_attribute("hf_admin_mode", "true")
        minetest.show_formspec(name, "main", "")
        
        local privs = minetest.get_player_privs(name)
        if not privs.creative then
            privs.creative = true
            minetest.set_player_privs(name, privs)
        end
        
        return true, "§G[Fortress]§F Креативний інвентар увімкнено. Напиши §E/ii§F щоб повернутись."
    end,
})

minetest.register_chatcommand("ii", {
    description = "Повернути RTS інвентар",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Гравець не знайдений" end
        
        player:set_attribute("hf_admin_mode", "false")
        player:set_inventory_formspec(ui.get_formspec(player))
        
        return true, "§G[Fortress]§F RTS інвентар повернуто."
    end,
})

-- 5. ОБРОБНИК ПОДІЙ
minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    
    if player:get_attribute("hf_admin_mode") == "true" then
        return false 
    end

if fields.btn_levelup then
        local data = human_fortress.edos_data[name]
        local player = minetest.get_player_by_name(name) -- Переконайтеся, що ви отримали об'єкт гравця
        
        if data and player then
            local current_cost = get_next_level_cost(data.level)
            if data.score >= current_cost then
                data.score = data.score - current_cost
                data.tax_paid = true
                data.level = data.level + 1
                
                minetest.sound_play("default_tool_breaks", {to_player = name, gain = 1.0})
                minetest.close_formspec(name, "")
                
                -- ОСЬ ТУТ ДОДАЄМО ВИКЛИК ОНОВЛЕННЯ СКІНА:
                if human_fortress.update_player_model then
                      edit_skin.update_player_skin(player)
                end
                
                if human_fortress.on_level_up then
                    human_fortress.on_level_up(name)
                end
                
                if human_fortress.update_gui then 
                    human_fortress.update_gui(player) 
                end
            else
                minetest.chat_send_player(name, "§RНедостатньо! Треба " .. current_cost)
            end
        end
    end
    
    
    if formname == "" then
        minetest.after(0.05, function()
            if player and player:is_player() and player:get_attribute("hf_admin_mode") ~= "true" then 
                player:set_inventory_formspec(ui.get_formspec(player)) 
            end
        end)
    end
end)

-- Оновлення при вході
minetest.register_on_joinplayer(function(player)
    minetest.after(0.5, function()
        if player and player:is_player() and player:get_attribute("hf_admin_mode") ~= "true" then 
            player:set_inventory_formspec(ui.get_formspec(player)) 
        end
    end)
end)