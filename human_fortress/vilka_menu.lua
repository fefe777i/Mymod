function show_vilka_menu(player_name)
    local formspec = "formspec_version[6]" ..
        "size[16,9]" ..
        -- 1. СКИДАЄМО СТИЛЬ ФОРМСПЕКА:
        -- Ми явно кажемо рушію, що для цієї форми bgimg має бути порожнім.
        -- Також скидаємо bgcolor, щоб прибрати стандартний сірий колір.
        "style_type[formspec;bgimg=;bgcolor=#00000000]" ..
        
        -- 2. МАЛЮЄМО ВАШ ФОН:
        -- Тепер, коли "нижній" фон скинуто, малюємо ваш прозорий фон.
        "image[0,0;16,9;hf_hud_bg.png]" ..
        
        -- 3. КНОПКИ:
        "button[1.5,5.8;3.5,1;words_menu;ПОЗНАЧЕННЯ]" .. 
        "button[6.2,5.2;3.6,1;world_menu;СВІТ]" ..
        "button[11.0,5.8;3.5,1;upgrade_menu;Я]" ..
        "button[4.8,6.8;6.4,1.5;command_mode;РЕЖИМ КОНТРОЛЮ]"

    minetest.show_formspec(player_name, "human_fortress:vilka", formspec)
end

-- ОБРОБНИК ФОРМ
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "human_fortress:vilka" then return end
    if fields.quit then return end -- Ігноруємо закриття меню

    local player_name = player:get_player_name()
    
    -- Логіка перемикання меню
    if fields.upgrade_menu then
        if show_upgrades_menu then show_upgrades_menu(player_name) 
        else minetest.chat_send_player(player_name, "❌ Прокачка недоступна") end
        
    elseif fields.world_menu then
        if show_world_menu then show_world_menu(player_name)
        else minetest.chat_send_player(player_name, "❌ Світ недоступний") end
        
    elseif fields.words_menu then
        if show_words_menu then show_words_menu(player_name)
        else minetest.chat_send_player(player_name, "❌ Слова недоступні") end
        
    elseif fields.command_mode then
        if toggle_command_mode then
            toggle_command_mode(player)
            minetest.chat_send_player(player_name, "✅ Режим командування активовано!")
            minetest.close_formspec(player_name, "")
        else
            minetest.chat_send_player(player_name, "❌ ПОМИЛКА: функція не знайдена!")
        end
    end
end)