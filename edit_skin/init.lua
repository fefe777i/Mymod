edit_skin = {
	skins = {},
}

-- 1. Завантаження даних з JSON
local function load_skins()
	local path = minetest.get_modpath("edit_skin") .. "/skins.json"
	local file = io.open(path, "r")
	if file then
		local content = file:read("*all")
		edit_skin.skins = minetest.parse_json(content)
		file:close()
	else
		-- Запасний варіант, якщо файл не знайдено
		edit_skin.skins = {{
			id="default", 
			name="Default", 
			lvl0="character.png", lvl10="character.png", lvl20="character.png", 
			lvl30="character.png", lvl40="character.png", lvl50="character.png"
		}}
		minetest.log("error", "[edit_skin] skins.json НЕ ЗНАЙДЕНО!")
	end
end
load_skins()

-- 2. Логіка отримання текстури з RTS бази
local function get_skin_texture(player)
	local name = player:get_player_name()
	local level = 0
	local selected_id = "default"

	-- Тягнемо дані з твого головного мода
	if human_fortress and human_fortress.edos_data[name] then
		local data = human_fortress.edos_data[name]
		level = data.level or 0
		selected_id = data.skin or (edit_skin.skins[1] and edit_skin.skins[1].id)
	end
	
	for _, s in ipairs(edit_skin.skins) do
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

-- 3. Оновлення текстури гравця
function edit_skin.update_player_skin(player)
	if not player or not player:is_player() then return end
	local texture = get_skin_texture(player)
	
	player:set_properties({
		textures = {texture},
	})
end

-- 4. Формспек (Меню)
-- Додаємо перемінну current_view_id, щоб гортати скіни без миттєвого збереження
local player_menu_view = {} 

function edit_skin.show_formspec(player)
	local name = player:get_player_name()
	
	-- Визначаємо, який скін зараз показати в прев'ю
	local current_id = player_menu_view[name]
	if not current_id then
		current_id = (human_fortress.edos_data[name] and human_fortress.edos_data[name].skin) or edit_skin.skins[1].id
		player_menu_view[name] = current_id
	end
	
	local current_idx = 1
	for i, s in ipairs(edit_skin.skins) do
		if s.id == current_id then current_idx = i break end
	end
	
	local skin = edit_skin.skins[current_idx]
	local preview_tex = skin.preview or skin.lvl0 or "character.png"

	local formspec = "formspec_version[4]size[10,9]" ..
		"background[0,0;10,9;gui_formbg.png]" ..
		"label[3.8,0.5;ВИБІР СКІНА]" ..
		"model[3,1.2;4,5;preview_mesh;character.b3d;" .. preview_tex .. ";0,180;false;true;0,0]" ..
		"image_button[1,3.5;1,1;edit_skin_arrow.png^[transformFX;prev;]" ..
		"image_button[8,3.5;1,1;edit_skin_arrow.png;next;]" ..
		"style[s_name;font_size=20]" ..
		"label[4.2,6.5;" .. minetest.formspec_escape(skin.name) .. "]" ..
		"button[3,7.5;4,0.8;select;ЗАСТОСУВАТИ]"

	minetest.show_formspec(name, "edit_skin:main", formspec)
end

-- 5. Обробка кнопок
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "edit_skin:main" then return end
	local name = player:get_player_name()
	
	local current_id = player_menu_view[name] or edit_skin.skins[1].id
	local idx = 1
	for i, s in ipairs(edit_skin.skins) do
		if s.id == current_id then idx = i break end
	end

	if fields.next then
		idx = idx + 1
		if idx > #edit_skin.skins then idx = 1 end
		player_menu_view[name] = edit_skin.skins[idx].id
		edit_skin.show_formspec(player)
	elseif fields.prev then
		idx = idx - 1
		if idx < 1 then idx = #edit_skin.skins end
		player_menu_view[name] = edit_skin.skins[idx].id
		edit_skin.show_formspec(player)
	elseif fields.select then
		-- ЗБЕРЕЖЕННЯ В БАЗУ RTS
		-- Отримуємо актуальний вибраний скін з player_menu_view
		local selected_skin_id = player_menu_view[name]
		
		if not selected_skin_id then
			-- Якщо не знайдено, беремо поточний (можливо це перший відкриття)
			selected_skin_id = (human_fortress.edos_data[name] and human_fortress.edos_data[name].skin) or edit_skin.skins[1].id
		end
		
		if human_fortress and human_fortress.edos_data[name] then
			human_fortress.edos_data[name].skin = selected_skin_id
			-- Викликаємо збереження RTS мода
			if human_fortress.save_data then
				human_fortress.save_data(name)
			end
		end
		
		edit_skin.update_player_skin(player)
		minetest.chat_send_player(name, "§a[Skin] Скін збережено!")
		minetest.close_formspec(name, "edit_skin:main")
		player_menu_view[name] = nil
	elseif fields.quit then
		player_menu_view[name] = nil
	end
end)

-- 6. Команди
minetest.register_chatcommand("skin", {
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if player then edit_skin.show_formspec(player) end
	end
})

minetest.register_chatcommand("s", {
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if player then edit_skin.show_formspec(player) end
	end
})
-- Автоматичне оновлення скіна кожні 15 секунд
local UPDATE_INTERVAL = 15 -- секунди

-- Таблиця для зберігання часів останнього оновлення
local last_update = {}

-- Глобальна функція оновлення
function edit_skin.auto_update_all()
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        edit_skin.update_player_skin(player)
    end
end

-- Запуск таймера
minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        
        if not last_update[name] then
            last_update[name] = 0
        end
        
        last_update[name] = last_update[name] + dtime
        
        if last_update[name] >= UPDATE_INTERVAL then
            edit_skin.update_player_skin(player)
            last_update[name] = 0
        end
    end
end)

-- Очищення даних при виході
minetest.register_on_leaveplayer(function(player)
    last_update[player:get_player_name()] = nil
end)

minetest.log("action", "[edit_skin] Автоматичне оновлення скінів увімкнено (кожні " .. UPDATE_INTERVAL .. " секунд)")
-- 7. Оновлення при вході
minetest.register_on_joinplayer(function(player)
	minetest.after(1.5, function()
		edit_skin.update_player_skin(player)
	end)
end)