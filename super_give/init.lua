-- Super Give Mod)
-- Credits: XsDragonFenixXs, Zeleborov, Toy_Tailer, LexFlex, ADIDAS, Danil009, Avoma

local search_results = {}
local selected_index = {} -- Store player selection

-- =========================
-- Function to show the menu)
local function show_give_menu(name, filter)
    filter = (filter or ""):lower()
    local item_list = ""
    search_results[name] = {}
    selected_index[name] = 0 -- Reset selection on new search

    for item_name, def in pairs(minetest.registered_items) do
        if item_name ~= "" and item_name ~= "unknown" then
            local desc = (def.description or ""):lower()
            if item_name:lower():find(filter) or desc:find(filter) then
                table.insert(search_results[name], item_name)
                local display_name = def.description or item_name
                if #display_name > 40 then display_name = display_name:sub(1,37).."..." end
                item_list = item_list .. item_name .. " (" .. display_name .. "),"
            end
        end
    end

    local formspec = 
        "size[9,9]" ..
        "background[0,0;9,9;gui_formbg.png;true]" ..
        "label[0.5,0.2;ITEM GRANTING MENU]" ..
        "field[0.8,1.2;4,1;search_box;Search items...;" .. filter .. "]" ..
        "button[5,0.9;2,1;search_btn;SEARCH]" ..
        "textlist[0.5,2;8,5;item_selection;" .. item_list .. "]" ..
        "field[0.8,7.8;1.5,1;count;Qty;1]" ..
        "field[2.8,7.8;5.5,1;custom_desc;Custom Name (Optional);]" ..
        "button[3,8.5;3,0.8;get_item;RECEIVE ITEM]"

    minetest.show_formspec(name, "super_give:menu", formspec)
end

-- =========================================
-- Register command as /sgive
minetest.register_chatcommand("sgive", {
    params = "[filter]",
    description = "Open advanced item granting menu",
    privs = {give = true},
    func = function(name, param)
        show_give_menu(name, param)
        return true
    end
})

-- ==============
-- Field processing)
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "super_give:menu" then return end
    local name = player:get_player_name()

    -- =============
    -- logic selector)
    if fields.item_selection then
        local event = minetest.explode_textlist_event(fields.item_selection)
        if event.type == "CHG" or event.type == "DCL" then
            selected_index[name] = event.index
        end
    end

    -- ============
    -- Search Button)
    if fields.search_btn or fields.key_enter_field == "search_box" then
        show_give_menu(name, fields.search_box)
        return
    end

    -- ========
    -- get item) 
    if fields.get_item then
        local index = selected_index[name] or 0
        
        if index > 0 and search_results[name] and search_results[name][index] then
            local item_id = search_results[name][index]
            local count = tonumber(fields.count) or 1
            local stack = ItemStack(item_id .. " " .. count)
            
            if fields.custom_desc and fields.custom_desc ~= "" then
                local meta = stack:get_meta()
                meta:set_string("description", fields.custom_desc)
            end
            
            local inv = player:get_inventory()
            if inv:room_for_item("main", stack) then
                inv:add_item("main", stack)
                minetest.chat_send_player(name, "[Success] Received: " .. item_id)
            else
                minetest.chat_send_player(name, "Inventory is full!")
            end
        else
            minetest.chat_send_player(name, "[!] Please select an item from the list first!")
        end
    end
end)

