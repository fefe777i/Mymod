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
  edit_skin.skins = {{
   id="default", name="Default",
   lvl0="character.png", lvl10="character.png", lvl20="character.png",
   lvl30="character.png", lvl40="character.png", lvl50="character.png"
  }}
  minetest.log("error", "[edit_skin] skins.json НЕ ЗНАЙДЕНО!")
 end
end
load_skins()

-- 2. Дані моделей за рівнем (модель + розмір для прев'ю)
local LEVEL_MODELS = {
 [0]  = { mesh = "player_lvl_0.obj"  },
 [10] = { mesh = "player_lvl_10.obj" },
 [20] = { mesh = "player_lvl_20.obj" },
 [30] = { mesh = "player_lvl_30.obj" },
 [40] = { mesh = "player_lvl_40.obj" },
 [50] = { mesh = "character.b3d"     },
}

local PREVIEW_LEVELS = {0, 10, 20, 30, 40, 50}

-- 3. Отримати текстуру скіна за рівнем
local function get_texture_for_level(skin, level)
 if level >= 50 then return skin.lvl50
 elseif level >= 40 then return skin.lvl40
 elseif level >= 30 then return skin.lvl30
 elseif level >= 20 then return skin.lvl20
 elseif level >= 10 then return skin.lvl10
 else return skin.lvl0 end
end

-- 4. Отримати модель за рівнем
local function get_mesh_for_level(level)
 if level >= 50 then return LEVEL_MODELS[50].mesh
 elseif level >= 40 then return LEVEL_MODELS[40].mesh
 elseif level >= 30 then return LEVEL_MODELS[30].mesh
 elseif level >= 20 then return LEVEL_MODELS[20].mesh
 elseif level >= 10 then return LEVEL_MODELS[10].mesh
 else return LEVEL_MODELS[0].mesh end
end

-- 5. Отримати текстуру гравця (для реального оновлення)
local function get_skin_texture(player)
 local name = player:get_player_name()
 local level = 0
 local selected_id = edit_skin.skins[1] and edit_skin.skins[1].id

 if human_fortress and human_fortress.edos_data[name] then
  local data = human_fortress.edos_data[name]
  level = data.level or 0
  selected_id = data.skin or selected_id
 end

 for _, s in ipairs(edit_skin.skins) do
  if s.id == selected_id then
   return get_texture_for_level(s, level)
  end
 end
 return "character.png"
end

-- 6. Оновлення текстури гравця
function edit_skin.update_player_skin(player)
 if not player or not player:is_player() then return end
 local texture = get_skin_texture(player)
 player:set_properties({ textures = {texture} })
end

-- 7. Стан меню
local player_menu_view = {}
local player_preview_level = {}

-- 8. Формспек
function edit_skin.show_formspec(player)
 local name = player:get_player_name()

 -- Поточний скін у прев'ю
 local current_id = player_menu_view[name]
 if not current_id then
  current_id = (human_fortress.edos_data[name] and human_fortress.edos_data[name].skin)
   or (edit_skin.skins[1] and edit_skin.skins[1].id)
  player_menu_view[name] = current_id
 end

 local current_idx = 1
 for i, s in ipairs(edit_skin.skins) do
  if s.id == current_id then current_idx = i break end
 end

 -- Поточний рівень прев'ю
 local preview_level_idx = player_preview_level[name] or 1
 local preview_level = PREVIEW_LEVELS[preview_level_idx] or 0

 local skin = edit_skin.skins[current_idx]

 -- Модель і текстура залежно від вибраного рівня прев'ю
 local preview_mesh = get_mesh_for_level(preview_level)
 local preview_tex  = get_texture_for_level(skin, preview_level)

 local level_label = "Рівень: " .. preview_level

 local formspec = "formspec_version[4]size[10,9]" ..
  "background[0,0;10,9;gui_formbg.png]" ..

  -- Кнопки вибору рівня прев'ю (верхній лівий кут)
  "image_button[0.2,0.2;0.6,0.6;edit_skin_arrow.png^[transformFX;level_prev;]" ..
  "button[0.85,0.2;1.8,0.6;level_select;" .. minetest.formspec_escape(level_label) .. "]" ..
  "image_button[2.7,0.2;0.6,0.6;edit_skin_arrow.png;level_next;]" ..

  -- Заголовок
  "label[3.8,0.5;ВИБІР СКІНА]" ..

  -- Модель прев'ю — mesh і текстура змінюються разом
  "model[3,1.2;4,5;preview_mesh;" .. preview_mesh .. ";" .. preview_tex .. ";0,180;false;true;0,0]" ..

  -- Стрілки скінів
  "image_button[1,3.5;1,1;edit_skin_arrow.png^[transformFX;prev;]" ..
  "image_button[8,3.5;1,1;edit_skin_arrow.png;next;]" ..

  -- Назва скіна
  "label[4.2,6.5;" .. minetest.formspec_escape(skin.name) .. "]" ..

  -- Кнопка застосування
  "button[3,7.5;4,0.8;select;ЗАСТОСУВАТИ]"

 minetest.show_formspec(name, "edit_skin:main", formspec)
end

-- 9. Обробка кнопок
minetest.register_on_player_receive_fields(function(player, formname, fields)
 if formname ~= "edit_skin:main" then return end
 local name = player:get_player_name()

 local current_id = player_menu_view[name] or (edit_skin.skins[1] and edit_skin.skins[1].id)
 local idx = 1
 for i, s in ipairs(edit_skin.skins) do
  if s.id == current_id then idx = i break end
 end

 -- Перемикання рівня прев'ю
 if fields.level_next then
  local lvl_idx = (player_preview_level[name] or 1) + 1
  if lvl_idx > #PREVIEW_LEVELS then lvl_idx = 1 end
  player_preview_level[name] = lvl_idx
  edit_skin.show_formspec(player)

 elseif fields.level_prev then
  local lvl_idx = (player_preview_level[name] or 1) - 1
  if lvl_idx < 1 then lvl_idx = #PREVIEW_LEVELS end
  player_preview_level[name] = lvl_idx
  edit_skin.show_formspec(player)

 -- Перемикання скінів
 elseif fields.next then
  idx = idx + 1
  if idx > #edit_skin.skins then idx = 1 end
  player_menu_view[name] = edit_skin.skins[idx].id
  edit_skin.show_formspec(player)

 elseif fields.prev then
  idx = idx - 1
  if idx < 1 then idx = #edit_skin.skins end
  player_menu_view[name] = edit_skin.skins[idx].id
  edit_skin.show_formspec(player)

 -- Застосування
 elseif fields.select then
  local selected_skin_id = player_menu_view[name]
   or (human_fortress.edos_data[name] and human_fortress.edos_data[name].skin)
   or (edit_skin.skins[1] and edit_skin.skins[1].id)

  if human_fortress and human_fortress.edos_data[name] then
   human_fortress.edos_data[name].skin = selected_skin_id
   if human_fortress.save_data then
    human_fortress.save_data(name)
   end
  end

  edit_skin.update_player_skin(player)
  minetest.chat_send_player(name, "§a[Skin] Скін збережено!")
  minetest.close_formspec(name, "edit_skin:main")
  player_menu_view[name] = nil
  player_preview_level[name] = nil

 elseif fields.quit then
  player_menu_view[name] = nil
  player_preview_level[name] = nil
 end
end)

-- 10. Команди
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

-- 11. Автоматичне оновлення кожні 15 секунд
local UPDATE_INTERVAL = 15
local last_update = {}

function edit_skin.auto_update_all()
 for _, player in ipairs(minetest.get_connected_players()) do
  edit_skin.update_player_skin(player)
 end
end

minetest.register_globalstep(function(dtime)
 for _, player in ipairs(minetest.get_connected_players()) do
  local name = player:get_player_name()
  if not last_update[name] then last_update[name] = 0 end
  last_update[name] = last_update[name] + dtime
  if last_update[name] >= UPDATE_INTERVAL then
   edit_skin.update_player_skin(player)
   last_update[name] = 0
  end
 end
end)

minetest.register_on_leaveplayer(function(player)
 last_update[player:get_player_name()] = nil
end)

minetest.log("action", "[edit_skin] Автоматичне оновлення скінів увімкнено (кожні " .. UPDATE_INTERVAL .. " секунд)")

-- 12. Оновлення при вході
minetest.register_on_joinplayer(function(player)
 minetest.after(1.5, function()
  edit_skin.update_player_skin(player)
 end)
end)