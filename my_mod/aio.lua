local nausea_players = {}

-- ===========================================
-- ЗЕЛЕНА ПШЕНИЦЯ (ВИСОКА)
-- ===========================================

-- Насіння зеленої пшениці
minetest.register_craftitem("my_mod:seed_green_wheat", {
    description = "Насіння зеленої дивної пшениці",
    inventory_image = "farming_wheat_seed.png^[colorize:#00ff00:180",
    on_place = function(itemstack, placer, pointed_thing)
        return farming.place_seed(itemstack, placer, pointed_thing, "my_mod:green_wheat_1")
    end,
})

-- Текстури для різних стадій
local green_wheat_stages = {
    "farming_wheat_1.png^[colorize:#00ff00:180",
    "farming_wheat_2.png^[colorize:#00ff00:180",
    "farming_wheat_3.png^[colorize:#00ff00:180",
    "farming_wheat_4.png^[colorize:#00ff00:180",
    "farming_wheat_5.png^[colorize:#00ff00:180",
    "farming_wheat_6.png^[colorize:#00ff00:180",
    "farming_wheat_7.png^[colorize:#00ff00:180",
    "farming_wheat_8.png^[colorize:#00ff00:180",
}

-- Функція для оновлення верхньої частини (для 2-блокової рослини)
local function update_top(pos, stage)
    local top_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
    local top_node = minetest.get_node(top_pos)
    
    -- Якщо це 8 стадія - має бути верхівка
    if stage == 8 then
        if top_node.name ~= "my_mod:green_wheat_top" then
            minetest.set_node(top_pos, {name = "my_mod:green_wheat_top"})
        end
    else
        -- Якщо не 8 стадія - видаляємо верхівку якщо вона є
        if top_node.name == "my_mod:green_wheat_top" then
            minetest.remove_node(top_pos)
        end
    end
end

-- Функція для перевірки чи можна рости
local function check_growth(pos)
    local node = minetest.get_node(pos)
    local stage = node.name:match("green_wheat_(%d+)")
    stage = stage and tonumber(stage) or 1
    
    -- Якщо це 8 стадія - перевіряємо чи є місце зверху
    if stage == 8 then
        local top_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
        local top_node = minetest.get_node(top_pos)
        if top_node.name ~= "air" and top_node.name ~= "my_mod:green_wheat_top" then
            return false -- Немає місця для росту
        end
    end
    
    return true
end

-- Реєструємо всі стадії (1-7 - звичайні, 8 - нижня частина)
for i = 1, 7 do
    local height = i * 2/16 -- висота selection_box залежить від стадії
    
    minetest.register_node("my_mod:green_wheat_" .. i, {
        description = "Зелена пшениця (стадія " .. i .. ")",
        drawtype = "plantlike",
        tiles = {green_wheat_stages[i]},
        paramtype = "light",
        paramtype2 = "meshoptions",
        place_param2 = 3,
        walkable = false,
        buildable_to = true,
        drop = "",
        selection_box = {
            type = "fixed",
            fixed = {-0.5, -0.5, -0.5, 0.5, -0.5 + height, 0.5},
        },
        groups = {snappy=3, flammable=3, plant=1, attached_node=1, not_in_creative_inventory=1},
        sounds = default.node_sound_leaves_defaults(),
        
        on_construct = function(pos)
            minetest.get_node_timer(pos):start(300) -- Випадковий таймер
        end,
        
        on_timer = function(pos, elapsed)
            local node = minetest.get_node(pos)
            local stage = node.name:match("green_wheat_(%d+)")
            stage = tonumber(stage)
            
            -- Випадковий ріст
            if stage < 8 and math.random(1, 3) == 1 then
                if stage == 7 then
                    -- Перевіряємо чи є місце зверху перед ростом до 8
                    local top_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
                    local top_node = minetest.get_node(top_pos)
                    if top_node.name == "air" then
                        minetest.set_node(pos, {name = "my_mod:green_wheat_8"})
                        minetest.set_node(top_pos, {name = "my_mod:green_wheat_top"})
                    end
                else
                    minetest.set_node(pos, {name = "my_mod:green_wheat_" .. (stage + 1)})
                end
            end
            
            -- Запускаємо таймер знову
            minetest.get_node_timer(pos):start(300)
            return true
        end,
        
        after_destruct = function(pos, oldnode)
            -- При видаленні нижньої частини видаляємо верхню
            local top_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
            local top_node = minetest.get_node(top_pos)
            if top_node.name == "my_mod:green_wheat_top" then
                minetest.remove_node(top_pos)
            end
        end
    })
end

-- 8 стадія (нижня частина)
minetest.register_node("my_mod:green_wheat_8", {
    description = "Зелена пшениця (стигла)",
    drawtype = "plantlike",
    tiles = {green_wheat_stages[8]},
    paramtype = "light",
    paramtype2 = "meshoptions",
    place_param2 = 3,
    walkable = false,
    buildable_to = true,
    drop = {
        max_items = 4,
        items = {
            {items = {"my_mod:green_wheat"}, rarity = 1},
            {items = {"my_mod:green_wheat"}, rarity = 2},
            {items = {"my_mod:seed_green_wheat"}, rarity = 2},
            {items = {"my_mod:seed_green_wheat"}, rarity = 3},
        }
    },
    selection_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}, -- Висота 1 блок
    },
    groups = {snappy=3, flammable=3, plant=1, attached_node=1, not_in_creative_inventory=1},
    sounds = default.node_sound_leaves_defaults(),
    
    on_construct = function(pos)
        -- Створюємо верхню частину
        local top_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
        minetest.set_node(top_pos, {name = "my_mod:green_wheat_top"})
    end,
    
    after_destruct = function(pos, oldnode)
        -- При видаленні нижньої частини видаляємо верхню
        local top_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
        local top_node = minetest.get_node(top_pos)
        if top_node.name == "my_mod:green_wheat_top" then
            minetest.remove_node(top_pos)
        end
    end
})

-- Верхня частина (тільки для 8 стадії)
minetest.register_node("my_mod:green_wheat_top", {
    description = "Зелена пшениця (верхівка)",
    drawtype = "plantlike",
    tiles = {"farming_wheat_8.png^[colorize:#00ff00:180"}, -- Верхня частина текстури
    paramtype = "light",
    paramtype2 = "meshoptions",
    place_param2 = 3,
    walkable = false,
    buildable_to = true,
    drop = "",
    selection_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
    },
    groups = {snappy=3, flammable=3, plant=1, attached_node=1, not_in_creative_inventory=1},
    sounds = default.node_sound_leaves_defaults(),
    
    after_destruct = function(pos, oldnode)
        -- При видаленні верхньої частини перевіряємо нижню
        local bottom_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
        local bottom_node = minetest.get_node(bottom_pos)
        if bottom_node.name == "my_mod:green_wheat_8" then
            -- Якщо нижня частина ще є, перетворюємо її назад на 7 стадію
            minetest.set_node(bottom_pos, {name = "my_mod:green_wheat_7"})
        end
    end
})

-- Додаємо підтримку bonemeal
if minetest.get_modpath("bonemeal") and bonemeal then
    bonemeal:add_crop({
        {"my_mod:green_wheat_", 8, "my_mod:seed_green_wheat", true}
    })
end

-- ===========================================
-- ПРЕДМЕТ ЗЕЛЕНОЇ ПШЕНИЦІ (той самий що й раніше)
-- ===========================================

minetest.register_craftitem("my_mod:green_wheat", {
    description = "Зелена дивна пшениця",
    inventory_image = "farming_wheat.png^[colorize:#00ff00:180",
    on_use = function(itemstack, user)
        local name = user:get_player_name()
        
        -- Видаляємо старий ефект якщо є
        if nausea_players[name] then
            for _, id in ipairs(nausea_players[name].wool_huds or {}) do
                user:hud_remove(id)
            end
            user:hud_remove(nausea_players[name].hud)
        end
        
        -- додай у таблицю даних
        nausea_players[name] = {
            time = 10,
            -- Основний HUD (напівпрозорий червоний)
            hud = user:hud_add({
                hud_elem_type = "image",
                position = {x=0.5, y=0.5},
                scale = {x=-100, y=-100},
                text = "blank.png^[colorize:#ff0000:255^[opacity:80",
                alignment = {x=0, y=0}
            }),
            wool_timer = 0,
            wool_huds = {}
        }
        
        -- TNT частинки
        minetest.add_particlespawner({
            amount = 80,
            time = 0.3,
            minpos = vector.subtract(user:get_pos(), 1),
            maxpos = vector.add(user:get_pos(), 1),
            minvel = {x=-5, y=1, z=-5},
            maxvel = {x=5, y=5, z=5},
            minsize = 3,
            maxsize = 6,
            texture = "tnt_smoke.png",
            glow = 5
        })
        
        itemstack:take_item()
        return itemstack
    end
})

-- Крафт насіння (якщо треба)
minetest.register_craft({
    output = "my_mod:seed_green_wheat",
    recipe = {
        {"my_mod:green_wheat"},
    }
})

-- ===========================================
-- ЕФЕКТИ НУДОТИ
-- ===========================================

local t = 0
minetest.register_globalstep(function(dtime)
    t = t + dtime
    
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local data = nausea_players[name]
        
        if data then
            data.time = data.time - dtime
            
            -- хитання камери
            local yaw = player:get_look_horizontal()
            player:set_look_horizontal(yaw + math.sin(t * 6) * 0.03)
            
            -- переливання кольорів для HUD
            local r = math.floor((math.sin(t * 2) + 1) * 120)
            local g = math.floor((math.sin(t * 3) + 1) * 120)
            local b = math.floor((math.sin(t * 4) + 1) * 120)
            
            -- Оновлюємо основний HUD (з напівпрозорістю)
            player:hud_change(
                data.hud,
                "text",
                "blank.png^[colorize:#" .. string.format("%02x%02x%02x", r, g, b) .. ":255^[opacity:90"
            )
            
            -- Додаємо випадкові кольорові HUD елементи (напівпрозорі)
            data.wool_timer = data.wool_timer + dtime
            if data.wool_timer > 0.3 then
                data.wool_timer = 0
                
                local r2 = math.random(0, 255)
                local g2 = math.random(0, 255)
                local b2 = math.random(0, 255)
                local color = string.format("%02x%02x%02x", r2, g2, b2)
                local size = math.random(20, 120)
                local opacity = math.random(30, 150)
                
                local id = player:hud_add({
                    hud_elem_type = "image",
                    position = {
                        x = math.random(),
                        y = math.random()
                    },
                    scale = {x = size, y = size},
                    text = "wool_white.png^[colorize:#" .. color .. ":255^[opacity:" .. opacity,
                    alignment = {x = 0, y = 0}
                })
                
                table.insert(data.wool_huds, id)
            end
            
            -- Завершення ефекту
            if data.time <= 0 then
                for _, id in ipairs(data.wool_huds) do
                    player:hud_remove(id)
                end
                player:hud_remove(data.hud)
                nausea_players[name] = nil
            end
        end
    end
end)

-- ВІДКЛАДЕНА ІНТЕГРАЦІЯ З BONEMEAL
local function setup_bonemeal_later()
    -- Чекаємо поки завантажиться bonemeal
    minetest.after(0, function()
        -- Перевіряємо чи є bonemeal
        if minetest.get_modpath("bonemeal") and bonemeal and bonemeal.add_crop then
            -- Додаємо зелену пшеницю
            bonemeal:add_crop({
                {"my_mod:green_wheat_", 8, "my_mod:seed_green_wheat", true}
            })
            
            -- Додаємо насіння до групи seed
            minetest.override_item("my_mod:seed_green_wheat", {
                groups = {seed = 1, flammable = 2}
            })
            
            minetest.log("action", "[my_mod] Зелену пшеницю інтегровано з bonemeal")
        else
            -- Якщо все ще немає - спробуємо ще раз пізніше
            minetest.after(1, setup_bonemeal_later)
        end
    end)
end

-- Запускаємо інтеграцію
setup_bonemeal_later()
print("[Зелена пшениця] Завантажено! Сади насіння на городі")