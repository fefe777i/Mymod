-- ============================================
-- ЕФІРНІ ДЕРЕВА (ether_trees.lua) - ПРОСТА ВЕРСІЯ
-- ============================================

local modpath = minetest.get_modpath("human_fortress")

-- Таблиця для зберігання позицій гравців (для меню)
ether_trees = ether_trees or {}
ether_trees.player_pos = {}
ether_trees.refresh = {}

-- ============================================
-- ДОПОМІЖНІ ФУНКЦІЇ
-- ============================================

local function get_player_ether(player_name)
    if not human_fortress.edos_data[player_name] then
        human_fortress.edos_data[player_name] = {ether = 0}
    end
    return human_fortress.edos_data[player_name].ether or 0
end

local function add_player_ether(player_name, amount)
    if not human_fortress.edos_data[player_name] then
        human_fortress.edos_data[player_name] = {ether = 0}
    end
    human_fortress.edos_data[player_name].ether = (human_fortress.edos_data[player_name].ether or 0) + amount
    
    -- Оновлюємо GUI
    local player = minetest.get_player_by_name(player_name)
    if player and human_fortress.update_gui then
        human_fortress.update_gui(player)
    end
end

-- ============================================
-- МЕНЮ ДЕРЕВА
-- ============================================

local function tree_overview(pos, tree_name, max_amount)
    local meta = minetest.get_meta(pos)
    local remaining = meta:get_int("remaining")
    if remaining == 0 then 
        remaining = max_amount
        meta:set_int("remaining", max_amount)
    end
    local scale = (remaining / max_amount) * 3
    
    local formspec = "size[8,5]" ..
        "bgcolor[#0A0A1A;true]" ..
        "box[0,0;8,0.8;#2D2D44]" ..
        "label[0.5,0.2;" .. tree_name .. "]" ..
        "label[5,0.2;Ефір: " .. remaining .. "]" ..
        "image[0.5,1;2,2;human_fortress_ether_tree.png]" ..
        "textarea[2.5,1;5,2;;;Зрубай дерево щоб отримати ефір.\n" ..
        "Залишилось: " .. remaining .. " ефіру.]" ..
        "box[0.5,3.5;3,0.5;#2D2D44]" ..
        "box[0.5,3.5;" .. scale .. ",0.5;#00AA00]" ..
        "button[2,4.2;2,0.8;close;❌ ЗАКРИТИ]" ..  -- ← ДОДАНО!
        "button[5,3.5;2,0.8;remove;❌ ЗНИЩИТИ]"
    
    return formspec
end

local function tree_overview_wrapper(player_name, pos, tree_name, max_amount)
    if ether_trees.refresh[player_name] then
        minetest.show_formspec(player_name, "human_fortress:ether_tree", tree_overview(pos, tree_name, max_amount))
        minetest.after(0.25, function()
            tree_overview_wrapper(player_name, pos, tree_name, max_amount)
        end)
    end
end

-- ============================================
-- БОКСИ
-- ============================================

local sel_box = {
    type = "fixed",
    fixed = {{-0.45, 0.0, -0.45, 0.45, 0.5, 0.45}}
}

local col_box = {
    type = "fixed",
    fixed = {{-0.45, -0.5, -0.45, 0.45, 0.125, 0.45}}
}

-- ============================================
-- МАЛЕНЬКЕ ЕФІРНЕ ДЕРЕВО (50 ефіру)
-- ============================================

minetest.register_node("human_fortress:ether_tree_small", {
    description = "Маленьке ефірне дерево",
    drawtype = "mesh",
    mesh = "human_fortress_tree_small.obj",
    tiles = {"human_fortress_tree_small.png"},
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {choppy = 2, ether_tree = 1},
    selection_box = sel_box,
    collision_box = col_box,
    _max_ether = 50,
    
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_int("remaining", 50)
    end,
    
    on_rightclick = function(pos, node, clicker)
        local player_name = clicker:get_player_name()
        ether_trees.player_pos[player_name] = pos
        ether_trees.refresh[player_name] = true
        tree_overview_wrapper(player_name, pos, "🌱 Маленьке дерево", 50)
    end,
    
    on_punch = function(pos, node, puncher)
        if not puncher or not puncher:is_player() then return end
        
        local player_name = puncher:get_player_name()
        local meta = minetest.get_meta(pos)
        local remaining = meta:get_int("remaining")
        
        if remaining <= 1 then
            add_player_ether(player_name, 1)
            minetest.remove_node(pos)
            minetest.chat_send_player(player_name, "🌱 Маленьке дерево зрубано!")
        else
            add_player_ether(player_name, 1)
            meta:set_int("remaining", remaining - 1)
        end
    end,
})

-- ============================================
-- НЕВЕЛИКЕ ЕФІРНЕ ДЕРЕВО (100 ефіру)
-- ============================================

minetest.register_node("human_fortress:ether_tree_small_plus", {
    description = "Невелике ефірне дерево",
    drawtype = "mesh",
    mesh = "human_fortress_tree_small_plus.obj",
    tiles = {"human_fortress_tree_small_plus.png"},
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {choppy = 2, ether_tree = 1},
    selection_box = sel_box,
    collision_box = col_box,
    _max_ether = 100,
    
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_int("remaining", 100)
    end,
    
    on_rightclick = function(pos, node, clicker)
        local player_name = clicker:get_player_name()
        ether_trees.player_pos[player_name] = pos
        ether_trees.refresh[player_name] = true
        tree_overview_wrapper(player_name, pos, "🌿 Невелике дерево", 100)
    end,
    
    on_punch = function(pos, node, puncher)
        if not puncher or not puncher:is_player() then return end
        
        local player_name = puncher:get_player_name()
        local meta = minetest.get_meta(pos)
        local remaining = meta:get_int("remaining")
        
        if remaining <= 1 then
            add_player_ether(player_name, 1)
            minetest.remove_node(pos)
            minetest.chat_send_player(player_name, "🌿 Невелике дерево зрубано!")
        else
            add_player_ether(player_name, 1)
            meta:set_int("remaining", remaining - 1)
        end
    end,
})

-- ============================================
-- СЕРЕДНЄ ЕФІРНЕ ДЕРЕВО (200 ефіру)
-- ============================================

minetest.register_node("human_fortress:ether_tree_medium", {
    description = "Середнє ефірне дерево",
    drawtype = "mesh",
    mesh = "human_fortress_tree_medium.obj",
    tiles = {"human_fortress_tree_medium.png"},
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {choppy = 2, ether_tree = 1},
    selection_box = sel_box,
    collision_box = col_box,
    _max_ether = 200,
    
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_int("remaining", 200)
    end,
    
    on_rightclick = function(pos, node, clicker)
        local player_name = clicker:get_player_name()
        ether_trees.player_pos[player_name] = pos
        ether_trees.refresh[player_name] = true
        tree_overview_wrapper(player_name, pos, "🌳 Середнє дерево", 200)
    end,
    
    on_punch = function(pos, node, puncher)
        if not puncher or not puncher:is_player() then return end
        
        local player_name = puncher:get_player_name()
        local meta = minetest.get_meta(pos)
        local remaining = meta:get_int("remaining")
        
        if remaining <= 1 then
            add_player_ether(player_name, 1)
            minetest.remove_node(pos)
            minetest.chat_send_player(player_name, "🌳 Середнє дерево зрубано!")
        else
            add_player_ether(player_name, 1)
            meta:set_int("remaining", remaining - 1)
        end
    end,
})

-- ============================================
-- ВЕЛИКЕ ЕФІРНЕ ДЕРЕВО (500 ефіру)
-- ============================================

minetest.register_node("human_fortress:ether_tree_big", {
    description = "Велике ефірне дерево",
    drawtype = "mesh",
    mesh = "human_fortress_tree_big.obj",
    tiles = {"human_fortress_tree_big.png"},
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {choppy = 3, ether_tree = 1},
    selection_box = sel_box,
    collision_box = col_box,
    _max_ether = 500,
    
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_int("remaining", 500)
    end,
    
    on_rightclick = function(pos, node, clicker)
        local player_name = clicker:get_player_name()
        ether_trees.player_pos[player_name] = pos
        ether_trees.refresh[player_name] = true
        tree_overview_wrapper(player_name, pos, "🌲 Велике дерево", 500)
    end,
    
    on_punch = function(pos, node, puncher)
        if not puncher or not puncher:is_player() then return end
        
        local player_name = puncher:get_player_name()
        local meta = minetest.get_meta(pos)
        local remaining = meta:get_int("remaining")
        
        if remaining <= 1 then
            add_player_ether(player_name, 1)
            minetest.remove_node(pos)
            minetest.chat_send_player(player_name, "🌲 Велике дерево зрубано!")
        else
            add_player_ether(player_name, 1)
            meta:set_int("remaining", remaining - 1)
        end
    end,
})

-- ============================================
-- ОБРОБНИК ФОРМ (ВИПРАВЛЕНО!)
-- ============================================

minetest.register_on_player_receive_fields(function(player, formname, fields)
    -- ДЛЯ ЕФІРНИХ ДЕРЕВ
    if formname == "human_fortress:ether_tree" then
        local name = player:get_player_name()
        local pos = ether_trees.player_pos[name]
        
        if fields.close then
            -- ПРОСТО ЗАКРИВАЄМО МЕНЮ
            ether_trees.refresh[name] = false
            return true
        end
        
        if fields.remove then
            if pos then
                minetest.remove_node(pos)
                minetest.chat_send_player(name, "🌳 Дерево знищено!")
            end
            ether_trees.refresh[name] = false
            return true
        end
    end
end)

print("[Human Fortress] Ефірні дерева завантажено!")