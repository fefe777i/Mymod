
minetest.register_node("my_mod:super_white", {
    description = "Супер Білий Блок",
    tiles = {{
        name = "super_white.png",
        glow = 14
    }},
    light_source = minetest.LIGHT_MAX,
    paramtype = "light",
    sunlight_propagates = true,
    groups = {cracky = 1, level = 3},
})




minetest.register_tool("my_mod:voice_item", {
    description = "Голос",
    inventory_image = "default_book.png",

    on_use = function(itemstack, user)
        minetest.show_formspec(user:get_player_name(), "voice_form",
            "size[6,3]" ..
            "field[0.5,1;5.5,1;text;Введи текст;]" ..
            "button_exit[2,2;2,1;send;Говорити]")
        return itemstack
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "voice_form" then return end
    if fields.text and fields.text ~= "" then
        minetest.chat_send_all("Голос: " .. fields.text)
    end
end)

minetest.register_tool("my_mod:voice_screen", {
    description = "Екран Голосу",
    inventory_image = "default_paper.png",

    on_use = function(itemstack, user)
        minetest.show_formspec(user:get_player_name(), "voice_screen_form",
            "size[6,3]" ..
            "field[0.5,1;5.5,1;text;Введи текст;]" ..
            "button_exit[2,2;2,1;send;Показати]")
        return itemstack
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "voice_screen_form" then return end
    if not fields.text or fields.text == "" then return end

    for _, pl in ipairs(minetest.get_connected_players()) do
        minetest.show_formspec(pl:get_player_name(), "voice_screen_display",
            "formspec_version[4]" ..
            "size[10,6]" ..
            "bgcolor[#00000000;true]" ..
            "background[0,0;10,6;my_voice_texture.png]" ..
            "textarea[0.7,0.8;8.8,4;;;"

            .. minetest.formspec_escape(fields.text) .. "]" ..

            "button_exit[4,5;2,1;exit;Закрити]")
    end
end)



minetest.register_node("my_mod:noblock", {
    description = " no block",
    tiles = {"noblock.png"},
    use_texture_alpha = "blend",
    paramtype = "light",
	sunlight_propagates = true,
	drawtype = "glasslike",
drop = {
    max_items = 3,
    items = {
        {items = {"human_fortress:edos 4"}},
        {items = {"human_fortress:ether 2"}},
        {items = {"human_fortress:versi 5"}},
    }
},
    groups = {cracky = 3},

    -- Перевірка для руди: тільки камінь, залізо, алмаз (і наша фіолетова)
    can_dig = function(pos, digger)
        if not digger then return false end
        local tool = digger:get_wielded_item():get_name()
        
        -- Список дозволених кірок
        local allowed_tools = {
            ["default:pick_stone"] = true,
            ["default:pick_steel"] = true,
            ["default:pick_diamond"] = true
        }
        if allowed_tools[tool] then
            return true
        end
        return false
    end,
    -- Після видобутку ставимо виснажений камінь
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        minetest.set_node(pos, {name = "my_mod:teleport_block"})
    end,
})

minetest.register_node("my_mod:teleport_block", {
    description = "Телепорт",
    drawtype = "glasslike",
    tiles = {"teleport_block.png"},
    light_source = minetest.LIGHT_MAX,
    paramtype = "light",
    walkable = true,
    groups = {cracky = 1},
})

-- ТЕПЕР окремо globalstep
minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local pos = vector.round(player:get_pos())
        pos.y = pos.y - 1

        local node = minetest.get_node(pos)

        if node.name == "my_mod:teleport_block" then
            local new_pos = {
                x = pos.x + math.random(-10, 10),
                y = pos.y + 1,
                z = pos.z + math.random(-10, 10)
            }

            player:set_pos(new_pos)
        end
    end
end)






local my_mod = minetest.get_modpath(minetest.get_current_modname())

dofile(my_mod .. "/aio.lua")