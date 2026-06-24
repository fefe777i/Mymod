-- Рівні скринь: h — це кількість робочих рядів
local ender_tiers = {
    {name = "basic", desc = "Звичайна (9)", h = 1},
    {name = "improved", desc = "Покращена (18)", h = 2},
    {name = "master", desc = "Майстер (27)", h = 3},
    {name = "advanced", desc = "Просунута (36)", h = 4},
    {name = "elite", desc = "Елітна (45)", h = 5},
    {name = "ultimate", desc = "Максимальна (54)", h = 6},
}

-- Функція інвентарю (без змін)
local function get_ender_inv(player)
    local name = player:get_player_name()
    local inv_id = "ender_storage:" .. name
    local inv = minetest.get_inventory({type="detached", name=inv_id})
    if not inv then
        inv = minetest.create_detached_inventory(inv_id, {
            on_put = function(inv, listname, index, stack, player)
                local items = {}
                for i=1, 54 do items[i] = inv:get_stack("main", i):to_string() end
                player:set_attribute("ender_items", minetest.serialize(items))
            end,
            on_take = function(inv, listname, index, stack, player)
                local items = {}
                for i=1, 54 do items[i] = inv:get_stack("main", i):to_string() end
                player:set_attribute("ender_items", minetest.serialize(items))
            end,
        })
        inv:set_size("main", 54)
        local saved = player:get_attribute("ender_items")
        if saved then
            local items = minetest.deserialize(saved)
            for i, it in ipairs(items or {}) do inv:set_stack("main", i, it) end
        end
    end
    return inv_id
end

for i, tier in ipairs(ender_tiers) do
    minetest.register_node("ender_expansion:chest_t" .. i, {
        description = tier.desc,
          drawtype = "mesh",
    mesh = "ender.obj",
    tiles = {"ender.png"},
        groups = {choppy = 2},
        
        on_rightclick = function(pos, node, clicker)
            local name = clicker:get_player_name()
            local inv_id = "ender_storage:" .. name
            get_ender_inv(clicker)
            
            -- Фіксований розмір вікна для всіх рівнів
            local fs = "size[9,8.5]" ..
                       "background[0,0;9,8.5;my_bg.png;true]" ..
                       "listcolors[#00000000;#00000000;#00000000;#ffffff;#ffffff]"

            -- 1. Малюємо текстуру слотів ТІЛЬКИ ДЛЯ ДОСТУПНИХ рядів скрині
            for y = 0, tier.h - 1 do
                for x = 0, 8 do
                    fs = fs .. "image[" .. x .. "," .. (0.5 + y) .. ";1,1;my_slot.png]"
                end
            end

            -- 2. Малюємо текстуру слотів для ХОТБАРА (завжди внизу на одному місці)
            for x = 0, 8 do
                fs = fs .. "image[" .. x .. ",7.2;1,1;my_slot.png]"
            end

            -- 3. Текстові підписи
            fs = fs .. "label[0.3,0.2;" .. minetest.colorize("#ffcc00", tier.desc) .. "]" ..
                 "label[0.3,6.9;Ваш хотбар]"

            -- 4. Реальні функціональні списки предметів
            fs = fs .. "list[detached:" .. inv_id .. ";main;0,0.5;9," .. tier.h .. ";]" ..
                 "list[current_player;main;0,7.2;9,1;]" ..
                 
                 "listring[detached:" .. inv_id .. ";main]" ..
                 "listring[current_player;main]"
            
            minetest.show_formspec(name, "ender_expansion:chest", fs)
        end,
    })
end