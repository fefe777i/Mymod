-- Super Give Mod)
-- Credits: XsDragonFenixXs.

local search_results = {}
local selected_index = {}
local current_color = {} 
local current_name_color = {} 
local current_filter = {} 
local custom_names = {} 
local custom_dmg = {}
local custom_time = {}
local custom_range = {}
local custom_glow = {}       
local custom_durability = {}

-- Color List ]:
local colors_list = {
    "white", "black", "red", "green", "blue", "yellow", "magenta", "cyan", 
    "orange", "brown", "pink", "violet", "grey", "gold"
}
local colors_string = table.concat(colors_list, ",")

-- =================================
-- Editor Menu
-- ======================= ):
local function show_editor_menu(name, page)
    page = page or 1
    local index = selected_index[name] or 0
    local item_id = (search_results[name] and search_results[name][index]) or "None selected"
    
    local item_col = current_color[name] or "default"
    local text_col = current_name_color[name] or "default"
    local c_name = custom_names[name] or ""

    local formspec = 
        "size[10,10]" ..
        "background9[0,0;0,0;my_custom_background.png;true;10]" .. 
        "label[0.5,0.5;Item Editor: " .. minetest.formspec_escape(item_id) .. "]"

    if page == 1 then
        formspec = formspec ..
        "box[0.5,1.2;9,1.5;#E0E0E022]" ..
        "field[0.8,2;6,1;edit_name;New Item Name;" .. minetest.formspec_escape(c_name) .. "]" ..
        "box[0.5,3.2;9,4;#E0E0E022]" ..
        "label[0.8,3.5;Select Physical Item Color (current: " .. item_col .. ")]" ..
        "textlist[0.8,4;4,3;edit_color_select;" .. colors_string .. "]" ..
        "label[5.5,4.5;Text Color: " .. text_col .. "]" ..
        -- Текстурная кнопка смены цвета текста
        "image_button[5.5,5;3,0.8;btn_text_color.png;pick_text_color;Text Color]" ..
        -- Текстурная кнопка Next
        "image_button[7.5,9.2;2,0.8;btn_next.png;go_page_2;Next ->]" ..
        
        -- Кнопка Back на 1-й странице (текстурная)
        "image_button[0.5,8.2;2.5,0.8;btn_back.png;back_to_main;<- Back]"
    else -- page 2
        formspec = formspec ..
        "box[0.5,1.2;9,6.5;#E0E0E022]" ..
        "label[0.8,1.5;->->]" ..
        "field[0.8,2.3;3,1;edit_dmg;Damage;" .. (custom_dmg[name] or "1") .. "]" ..
        "field[4.5,2.3;3,1;edit_time;Time;" .. (custom_time[name] or "0.5") .. "]" ..
        "field[0.8,4.0;3,1;edit_range;Range;" .. (custom_range[name] or "4") .. "]" ..
        
        -- Glow and Durability
        "field[0.8,5.7;3,1;edit_glow;Glow (0-14);" .. (custom_glow[name] or "0") .. "]" ..
        "field[4.5,5.7;3,1;edit_durability;Durability (Uses);" .. (custom_durability[name] or "0") .. "]" ..
        
        -- Кнопка Back на 2-й странице (текстурная)
        "image_button[0.5,8.2;2.5,0.8;btn_back.png;back_to_page1;<- Back]"
    end
        
    formspec = formspec ..
        "image_button[3.5,8.2;2.5,0.8;btn_reset.png;reset_editor;Reset]" ..
        "image_button[6.5,8.2;2.5,0.8;btn_give.png;get_item_edited;Give]"

    minetest.show_formspec(name, "super_give:editor", formspec)
end

-- ==================================
-- Confirm Menu
-- ==================================
local function show_confirm_menu(name)
    local formspec = 
        "size[6,4]" ..
        "background9[0,0;0,0;my_custom_background.png;true;10]" .. 
        "label[0.5,0.5;Do you confirm?]" ..
        "label[0.5,1.2;All custom nodes that you created and\ngave a name and characteristics will be deleted!]" ..
        "image_button[0.5,2.5;2,0.8;btn_yes.png;confirm_del_yes;Yes]" ..
        "image_button[3.5,2.5;2,0.8;btn_back.png;confirm_del_back;Back]"
    minetest.show_formspec(name, "super_give:confirm", formspec)
end

-- ==================================
-- Menu 1
-- ===============================
local function show_give_menu(name, filter)
    if not minetest.check_player_privs(name, {give = true}) then
        minetest.chat_send_player(name, "У вас нет прав (give)!")
        return
    end

    filter = (filter or ""):lower()
    current_filter[name] = filter
    local item_list = ""
    search_results[name] = {}
    
    for item_name, def in pairs(minetest.registered_items) do
        if item_name ~= "" and item_name ~= "unknown" then
            local description = (def.description or ""):lower()
            if item_name:lower():find(filter, 1, true) or description:find(filter, 1, true) then
                table.insert(search_results[name], item_name)
                local display_name = def.description or item_name
                item_list = item_list .. minetest.formspec_escape(item_name .. " (" .. display_name:gsub("\n"," ") .. ")") .. ","
            end
        end
    end

    local formspec = 
        "size[9,9.5]" ..
        "background9[0,0;0,0;my_custom_background.png;true;10]" .. 
        
        "label[0.5,0.1;SuperGive Menu]" .. 
        "field[0.8,1.2;4,1;search_box;Search items...;" .. minetest.formspec_escape(filter) .. "]" ..
        "image_button[5,0.9;2,1;btn_search.png;search_btn;Search]" ..
        "field[7.5,1.2;1.2,1;count;Qty;1]" ..
        
        "textlist[0.5,2;8,6;item_selection;" .. item_list .. "]" ..
        
        -- Текстурные кнопки внизу главного меню
        "image_button[0.5,8.5;2.5,0.8;btn_give.png;get_item_fast;Give]" ..
        "image_button[3.5,8.5;2.5,0.8;btn_edit.png;open_editor;Edit]" ..
        "image_button[6.5,8.5;2,0.8;btn_del_all.png;open_confirm;Del All]"

    minetest.show_formspec(name, "super_give:menu", formspec)
end

-- ==================================
-- Command and Reset
-- ==================================
minetest.register_chatcommand("sgive", {
    params = "[filter]",
    description = "Open advanced item granting menu",
    privs = {give = true},
    func = function(name, param)
        selected_index[name] = 0
        current_color[name] = nil
        current_name_color[name] = nil
        custom_names[name] = nil
        current_filter[name] = ""
        
        show_give_menu(name, param)
        return true
    end
})

-- =================================
-- Field Processing
-- =================================
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if not player then return end
    local name = player:get_player_name()

    if formname == "super_give:confirm" then
        if fields.confirm_del_yes then
            local inv = player:get_inventory()
            for i, stack in ipairs(inv:get_list("main")) do
                if stack:get_meta():get_int("is_super_give") == 1 then inv:set_stack("main", i, nil) end
            end
            minetest.chat_send_player(name, "Custom items removed!")
            minetest.close_formspec(name, "super_give:confirm")
        end
        if fields.confirm_del_back or fields.quit then
            show_give_menu(name, current_filter[name])
        end
    end

    if formname == "super_give:editor" then
        if fields.edit_name then custom_names[name] = fields.edit_name end
        if fields.edit_dmg then custom_dmg[name] = fields.edit_dmg end
        if fields.edit_time then custom_time[name] = fields.edit_time end
        if fields.edit_range then custom_range[name] = fields.edit_range end
        if fields.edit_glow then custom_glow[name] = fields.edit_glow end
        if fields.edit_durability then custom_durability[name] = fields.edit_durability end

        if fields.go_page_2 then show_editor_menu(name, 2) end
        
        if fields.edit_color_select then
            local event = minetest.explode_textlist_event(fields.edit_color_select)
            if event.type == "CHG" or event.type == "DCL" then
                current_color[name] = colors_list[event.index]
                show_editor_menu(name, 1)
            end
        end

        if fields.pick_text_color then
            local cur = current_name_color[name] or "white"
            for i, v in ipairs(colors_list) do
                if v == cur then
                    current_name_color[name] = colors_list[i+1] or colors_list[1]
                    break
                end
            end
            show_editor_menu(name, 1)
        end
        
        -- processing Back
        if fields.back_to_main then 
            show_give_menu(name, current_filter[name]) 
        end
        if fields.back_to_page1 then 
            show_editor_menu(name, 1) 
        end

        if fields.reset_editor then
            current_color[name] = nil
            current_name_color[name] = nil
            custom_names[name] = nil
            custom_dmg[name] = nil
            custom_time[name] = nil
            custom_range[name] = nil
            custom_glow[name] = nil
            custom_durability[name] = nil
            show_editor_menu(name, 1)
        end

        if fields.get_item_edited then
            fields.get_item_fast = true
        else
            return
        end
    end

    if formname ~= "super_give:menu" and formname ~= "super_give:editor" then return end
    if not minetest.check_player_privs(name, {give = true}) then return end

    if fields.open_confirm then
        show_confirm_menu(name)
        return
    end

    if fields.item_selection then
        local event = minetest.explode_textlist_event(fields.item_selection)
        if event.type == "CHG" or event.type == "DCL" then 
            selected_index[name] = event.index 
        end
    end

    if fields.search_btn or fields.key_enter_field == "search_box" then
        show_give_menu(name, fields.search_box or "")
        return
    end

    if fields.open_editor then
        if (selected_index[name] or 0) > 0 then 
            show_editor_menu(name, 1)
        else 
            minetest.chat_send_player(name, "[!] Please select an item first!") 
        end
        return
    end

    if fields.get_item_fast or fields.get_item_edited then
        local index = selected_index[name] or 0
        if index > 0 and search_results[name] and search_results[name][index] then
            local item_id = search_results[name][index]
            local count = tonumber(fields.count) or 1
            if count < 1 then count = 1 end
            
            local stack = ItemStack(item_id .. " " .. count)
            local meta = stack:get_meta()
            meta:set_int("is_super_give", 1)
            
            local final_name = custom_names[name] or ""
            if final_name ~= "" then
                if current_name_color[name] then
                    final_name = minetest.colorize(current_name_color[name], final_name)
                end
                meta:set_string("description", final_name)
            end

            if current_color[name] and current_color[name] ~= "none" then 
                meta:set_string("color", current_color[name]) 
            end
            
            local dmg = tonumber(custom_dmg[name] or 1) or 1
            local time = tonumber(custom_time[name] or 0.5) or 0.5
            local rng = tonumber(custom_range[name] or 4) or 4
            local glow = tonumber(custom_glow[name] or 0) or 0
            local durability = tonumber(custom_durability[name] or 0) or 0
            
            local capabilities = {
                full_punch_interval = time,
                damage_groups = {fleshy = dmg},
                range = rng
            }
            
            if durability > 0 then
                capabilities.tool_capabilities = {
                    uses = durability,
                    max_drop_level = 3
                }
            end

            meta:set_string("tool_capabilities", minetest.write_json(capabilities))

            if glow > 0 then
                meta:set_int("glow", math.min(math.max(glow, 0), 14))
            end
            
            local inv = player:get_inventory()
            if inv:room_for_item("main", stack) then
                inv:add_item("main", stack)
                minetest.chat_send_player(name, "[Success] Received: " .. item_id)
                if fields.get_item_edited then 
                    minetest.close_formspec(name, "super_give:editor") 
                end
            else
                minetest.chat_send_player(name, "Inventory is full!")
            end
        else
            minetest.chat_send_player(name, "[!] Please select an item first!")
        end
    end
end)

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    search_results[name] = nil
    selected_index[name] = nil
    current_color[name] = nil
    current_name_color[name] = nil
    current_filter[name] = nil
    custom_names[name] = nil
    custom_dmg[name] = nil
    custom_time[name] = nil
    custom_range[name] = nil
    custom_glow[name] = nil
    custom_durability[name] = nil
end)
