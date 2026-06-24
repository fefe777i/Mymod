-- ============================================================
--  item_builder — Custom Item Builder Mod
--  Команда /itembuilder відкриває GUI конструктора предметів.
--  Дані зберігаються у <worldpath>/custom_items/
-- ============================================================

local IB = {}
IB.modpath   = minetest.get_modpath("item_builder")
IB.worldpath = minetest.get_worldpath() .. "/custom_items"

-- ── Утиліти ──────────────────────────────────────────────────

local function ensure_dir(path)
	-- minetest.mkdir доступний з 5.0
	minetest.mkdir(path)
end

local function safe_name(s)
	-- Залишаємо лише букви, цифри, _
	return (s:lower():gsub("[^a-z0-9_]", "_"):sub(1, 32))
end

local function item_path(iname)
	return IB.worldpath .. "/" .. iname .. ".lua"
end

local function tex_path(iname)
	return IB.worldpath .. "/" .. iname .. ".png"
end

-- ── Pixel-art текстура за замовчуванням (16×16, base64 PNG) ──
-- Проста сіра іконка — використовується якщо юзер не намалював
local DEFAULT_TEX_B64 = [[
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJ
bWFnZVJlYWR5ccllPAAAAFdJREFUeNpiYBgFgx0wMjD8Z8ABGEkxgIlIgxjRNTAxkGYAIy4NTBQY
wMSAmwEsJBvATLIBzCQbwEyGASxkGMBCpgGsZBjASoYBrGQYwEqGAQMdAAIMABZuC/laAAAAAElF
TkSuQmCC
]]

-- ── Збереження PNG текстури (base64 → бінарний файл) ─────────

local function b64decode(data)
	local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	data = data:gsub("[^"..b.."=]", "")
	return (data:gsub(".", function(x)
		if x == "=" then return "" end
		local r, f = "", b:find(x) - 1
		for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i-1) > 0 and "1" or "0") end
		return r
	end):gsub("%d%d%d%d%d%d%d%d", function(x)
		local c = 0
		for i = 1, 8 do c = c + (x:sub(i,i)=="1" and 2^(8-i) or 0) end
		return string.char(c)
	end))
end

local function save_texture_b64(iname, b64)
	local raw = b64decode(b64:gsub("%s",""))
	local f = io.open(tex_path(iname), "wb")
	if f then f:write(raw); f:close() end
end

-- ── Збереження / завантаження визначення предмета ────────────

local function save_item_def(def)
	ensure_dir(IB.worldpath)
	local iname = def.name  -- вже safe_name
	local f = io.open(item_path(iname), "w")
	if not f then return false, "не вдалося відкрити файл" end
	-- Серіалізуємо def як Lua-таблицю
	f:write("-- Автоматично згенеровано item_builder\n")
	f:write("return " .. minetest.serialize(def) .. "\n")
	f:close()
	return true
end

local function load_item_def(iname)
	local f = io.open(item_path(iname), "r")
	if not f then return nil end
	local src = f:read("*a"); f:close()
	-- Безпечне виконання: тільки minetest.deserialize
	local chunk = src:match("return%s*(.*)")
	if not chunk then return nil end
	return minetest.deserialize(chunk)
end

local function list_saved_items()
	local names = {}
	-- Проходимо по файлах у worldpath/custom_items/
	-- minetest не має readdir, тому тримаємо окремий індекс
	local idx_path = IB.worldpath .. "/_index.txt"
	local f = io.open(idx_path, "r")
	if f then
		for line in f:lines() do
			if line ~= "" then names[#names+1] = line end
		end
		f:close()
	end
	return names
end

local function add_to_index(iname)
	local names = list_saved_items()
	for _, n in ipairs(names) do if n == iname then return end end
	names[#names+1] = iname
	local idx_path = IB.worldpath .. "/_index.txt"
	local f = io.open(idx_path, "w")
	if f then
		for _, n in ipairs(names) do f:write(n.."\n") end
		f:close()
	end
end

local function remove_from_index(iname)
	local names = list_saved_items()
	local idx_path = IB.worldpath .. "/_index.txt"
	local f = io.open(idx_path, "w")
	if f then
		for _, n in ipairs(names) do
			if n ~= iname then f:write(n.."\n") end
		end
		f:close()
	end
end

-- ── Реєстрація предмета ───────────────────────────────────────

local function register_custom_item(def)
	local fullname = "item_builder:" .. def.name
	if minetest.registered_items[fullname] then
		minetest.override_item(fullname, {
			description = def.display_name .. "\n" .. def.description,
		})
		return
	end

	-- Визначаємо тип предмету
	local item_type = def.item_type or "craftitem"

	local reg_def = {
		description    = def.display_name .. "\n\n" .. def.description,
		inventory_image = "item_builder_" .. def.name .. ".png",
		groups = { custom_item = 1 },
	}

	-- Виконуємо користувацький Lua-код (sandbox)
	if def.lua_code and def.lua_code ~= "" then
		local env = {
			minetest        = minetest,
			ItemStack       = ItemStack,
			vector          = vector,
			math            = math,
			string          = string,
			table           = table,
			pairs           = pairs,
			ipairs          = ipairs,
			tostring        = tostring,
			tonumber        = tonumber,
			print           = function(...) minetest.log("action","[item_builder] "..tostring(...)) end,
			def             = reg_def,   -- дає змогу змінювати on_use, on_place, тощо
		}
		local fn, err = load(def.lua_code, "item:"..def.name, "t", env)
		if fn then
			local ok, err2 = pcall(fn)
			if not ok then
				minetest.log("error","[item_builder] lua error in "..def.name..": "..tostring(err2))
			end
		else
			minetest.log("error","[item_builder] compile error in "..def.name..": "..tostring(err))
		end
	end

	if item_type == "node" then
		minetest.register_node(fullname, reg_def)
	elseif item_type == "tool" then
		reg_def.tool_capabilities = {}
		minetest.register_tool(fullname, reg_def)
	else
		minetest.register_craftitem(fullname, reg_def)
	end
end

-- ── Стан редактора (per-player) ───────────────────────────────

local editor = {}  -- editor[playername] = {page, fields...}

local function get_ed(name)
	if not editor[name] then
		editor[name] = {
			page        = "main",     -- "main" | "edit" | "tex" | "list"
			iname       = "",
			display_name= "",
			description = "",
			item_type   = "craftitem",
			lua_code    = "",
			-- Піксель-арт: 16×16, кожен елемент — "#RRGGBB" або "transparent"
			pixels      = {},
			sel_color   = "#FF0000",
			selected    = nil,        -- ім'я для перегляду/видалення
		}
		-- Ініціалізуємо всі пікселі сірим
		for i = 1, 256 do editor[name].pixels[i] = "#888888" end
	end
	return editor[name]
end

-- ── Допоміжний рендер піксель-арт сітки у formspec ───────────

local COLORS_PALETTE = {
	"#000000","#FFFFFF","#FF0000","#00CC00","#0000FF",
	"#FFFF00","#FF8800","#CC00CC","#00CCCC","#884400",
	"#FFAAAA","#AAFFAA","#AAAAFF","#FFCC88","#888888",
	"#CCCCCC",
}

local GRID = 16  -- 16×16

local function pixel_idx(x, y) return (y-1)*GRID + x end

local function build_tex_page(ed)
	-- Малюємо 16×16 сітку кнопками 0.35×0.35
	local fs = "formspec_version[4]"..
		"size[10,10.5]"..
		"bgcolor[#1a1a2e]"..
		"label[0.2,0.3;🎨 Піксель-арт редактор (16×16)]"..
		"label[0.2,0.75;Активний колір:]"..
		"box[1.8,0.55;0.6,0.4;"..ed.sel_color.."]"

	-- Кнопки кольорів (палітра)
	for i, c in ipairs(COLORS_PALETTE) do
		local cx = 0.2 + (i-1)*0.52
		local cy = 1.1
		if i > 8 then
			cx = 0.2 + (i-9)*0.52
			cy = 1.55
		end
		local border = (c == ed.sel_color) and "1,1,1" or "0,0,0"
		fs = fs .. string.format(
			"box[%.2f,%.2f;0.45,0.38;%s]button[%.2f,%.2f;0.45,0.38;pal_%d;]",
			cx-0.02, cy-0.02, border,
			cx, cy, i
		)
	end

	-- Custom hex input
	fs = fs ..
		"label[0.2,2.1;Власний (#RRGGBB):]"..
		"field[2.3,1.95;1.8,0.5;custom_hex;;"..ed.sel_color.."]"..
		"button[4.15,1.95;0.9,0.5;set_hex;OK]"..
		"button[5.1,1.95;1.0,0.5;clear_color;Прозоро]"

	-- Сітка пікселів
	local ox, oy = 0.2, 2.6
	local ps = 0.42  -- розмір пікселя
	for y = 1, GRID do
		for x = 1, GRID do
			local idx = pixel_idx(x, y)
			local col = ed.pixels[idx]
			if col == "transparent" then col = "#111122" end
			fs = fs .. string.format(
				"box[%.2f,%.2f;%.2f,%.2f;%s]"..
				"button[%.2f,%.2f;%.2f,%.2f;px_%d_%d;]",
				ox+(x-1)*ps, oy+(y-1)*ps, ps, ps, col,
				ox+(x-1)*ps, oy+(y-1)*ps, ps, ps, x, y
			)
		end
	end

	fs = fs ..
		"button[0.2,9.9;2,0.5;tex_ok;✔ Готово]"..
		"button[2.4,9.9;2,0.5;tex_fill;Залити все]"..
		"button[4.6,9.9;2,0.5;tex_clear;Очистити]"..
		"button[7.0,9.9;2.5,0.5;tex_back;← Назад]"

	return fs
end

local function build_edit_page(ed)
	local types = "craftitem,tool,node"
	local sel_idx = 0
	for i, t in ipairs({"craftitem","tool","node"}) do
		if t == (ed.item_type or "craftitem") then sel_idx = i-1 end
	end

	return "formspec_version[4]"..
		"size[9,9.5]"..
		"bgcolor[#1a1a2e]"..
		"label[0.3,0.3;🔧 Конструктор предмета]"..
		"label[0.3,0.9;Системна назва (англ., без пробілів):]"..
		"field[0.3,1.2;8.4,0.6;f_iname;;"..minetest.formspec_escape(ed.iname).."]"..
		"label[0.3,1.95;Відображувана назва:]"..
		"field[0.3,2.25;8.4,0.6;f_display;;"..minetest.formspec_escape(ed.display_name).."]"..
		"label[0.3,3.0;Опис предмета:]"..
		"textarea[0.3,3.3;8.4,1.6;f_desc;;"..minetest.formspec_escape(ed.description).."]"..
		"label[0.3,5.05;Тип предмета:]"..
		"dropdown[0.3,5.35;3,0.6;f_type;craftitem,tool,node;"..tostring(sel_idx+1).."]"..
		"label[0.3,6.05;Lua-код (необов'язково):]"..
		"textarea[0.3,6.35;8.4,2.2;f_lua;;"..minetest.formspec_escape(ed.lua_code).."]"..
		"button[0.3,8.8;2.2,0.55;go_tex;🎨 Текстура]"..
		"button[2.7,8.8;2.2,0.55;do_save;💾 Зберегти]"..
		"button[5.1,8.8;1.8,0.55;do_give;📦 Видати]"..
		"button[7.1,8.8;1.7,0.55;go_main;← Меню]"
end

local function build_list_page(names)
	local h = math.max(4, math.min(#names * 0.7 + 2.5, 10))
	local fs = "formspec_version[4]"..
		"size[7,"..string.format("%.1f",h).."]"..
		"bgcolor[#1a1a2e]"..
		"label[0.3,0.3;📋 Збережені предмети]"

	if #names == 0 then
		fs = fs .. "label[0.3,1.0;Список порожній]"
	else
		local items_str = table.concat(names, ",")
		fs = fs ..
			"textlist[0.3,0.7;6.4,"..(h-2.4)..";item_list;"..
			minetest.formspec_escape(items_str)..";1]"
	end

	fs = fs ..
		"button[0.3,"..(h-1.5)..";2.5,0.55;list_edit;✏ Редагувати]"..
		"button[3.0,"..(h-1.5)..";1.7,0.55;list_del;🗑 Видалити]"..
		"button[4.9,"..(h-1.5)..";1.8,0.55;go_main;← Назад]"
	return fs, h
end

local function build_main_page()
	return "formspec_version[4]"..
		"size[7,6]"..
		"bgcolor[#1a1a2e]"..
		"label[0.3,0.5;⚒ Item Builder]"..
		"label[0.3,1.1;Створюйте власні предмети для цього світу.]"..
		"button[1.5,2.2;4,0.7;go_new;✨ Новий предмет]"..
		"button[1.5,3.1;4,0.7;go_list;📋 Список предметів]"..
		"button[1.5,4.0;4,0.7;go_close;✖ Закрити]"
end

-- ── Показ formspec ────────────────────────────────────────────

local function show_main(player)
	local name = player:get_player_name()
	local ed = get_ed(name)
	ed.page = "main"
	minetest.show_formspec(name, "item_builder:main", build_main_page())
end

local function show_edit(player)
	local name = player:get_player_name()
	local ed = get_ed(name)
	ed.page = "edit"
	minetest.show_formspec(name, "item_builder:edit", build_edit_page(ed))
end

local function show_tex(player)
	local name = player:get_player_name()
	local ed = get_ed(name)
	ed.page = "tex"
	minetest.show_formspec(name, "item_builder:tex", build_tex_page(ed))
end

local function show_list(player)
	local name   = player:get_player_name()
	local ed     = get_ed(name)
	ed.page = "list"
	local names  = list_saved_items()
	local fs, _  = build_list_page(names)
	minetest.show_formspec(name, "item_builder:list", fs)
end

-- ── Генерація PNG текстури з пікселів ────────────────────────
-- Сумісно з Lua 5.1 (Luanti/Android) — використовуємо бібліотеку bit

-- Lua 5.1 bit operations (Luanti надає глобальний `bit`)
local _band  = bit and bit.band  or function(a,b) -- fallback pure-lua
	local r,m = 0,2147483648
	for _ = 1,32 do
		if a >= m and b >= m then r = r + m end
		if a >= m then a = a - m end
		if b >= m then b = b - m end
		m = m * 0.5
	end
	return r
end
local _bxor  = bit and bit.bxor  or function(a,b)
	local r,m = 0,2147483648
	for _ = 1,32 do
		if (a >= m) ~= (b >= m) then r = r + m end
		if a >= m then a = a - m end
		if b >= m then b = b - m end
		m = m * 0.5
	end
	return r
end
local _bnot  = bit and bit.bnot  or function(a) return _bxor(a, 0xFFFFFFFF) end
local _rshift = bit and bit.rshift or function(a,n) return math.floor(a / 2^n) end
local _lshift = bit and bit.lshift or function(a,n) return (a * 2^n) % 4294967296 end
-- bor через xor+band
local _bor   = bit and bit.bor   or function(a,b) return _bxor(a, _bxor(b, _band(a,b))) end

local function pixels_to_png(pixels)
	-- ── CRC32 ─────────────────────────────────────────────────
	local crc_table = {}
	for n = 0, 255 do
		local c = n
		for _ = 1, 8 do
			if _band(c, 1) ~= 0 then
				c = _bxor(0xEDB88320, _rshift(c, 1))
			else
				c = _rshift(c, 1)
			end
		end
		crc_table[n] = c
	end

	local function crc32(data, crc)
		crc = crc or 0xFFFFFFFF
		for i = 1, #data do
			local b = data:byte(i)
			local idx = _band(_bxor(crc, b), 0xFF)
			crc = _bxor(crc_table[idx], _rshift(crc, 8))
		end
		return _bxor(crc, 0xFFFFFFFF)
	end

	-- ── u32 big-endian ────────────────────────────────────────
	local function u32be(n)
		n = n % 4294967296  -- обрізаємо до 32 біт
		return string.char(
			math.floor(n / 16777216) % 256,
			math.floor(n /    65536) % 256,
			math.floor(n /      256) % 256,
			n % 256
		)
	end

	local function chunk(ctype, data)
		local c = crc32(ctype .. data)
		return u32be(#data) .. ctype .. data .. u32be(c)
	end

	-- ── Hex → RGBA ────────────────────────────────────────────
	local function hex_to_rgba(col)
		if col == "transparent" then return 0, 0, 0, 0 end
		local r = tonumber(col:sub(2,3), 16) or 128
		local g = tonumber(col:sub(4,5), 16) or 128
		local b = tonumber(col:sub(6,7), 16) or 128
		return r, g, b, 255
	end

	-- ── Сирі дані рядків (filter=None) ───────────────────────
	local raw = {}
	for y = 1, GRID do
		raw[#raw+1] = "\0"  -- filter byte
		for x = 1, GRID do
			local r, g, b, a = hex_to_rgba(pixels[pixel_idx(x, y)])
			raw[#raw+1] = string.char(r, g, b, a)
		end
	end
	local raw_data = table.concat(raw)

	-- ── Adler-32 ──────────────────────────────────────────────
	local function adler32(data)
		local s1, s2 = 1, 0
		for i = 1, #data do
			s1 = (s1 + data:byte(i)) % 65521
			s2 = (s2 + s1) % 65521
		end
		-- s2*65536 + s1  (не бітові зсуви, просто множення)
		return (s2 * 65536 + s1) % 4294967296
	end

	-- ── DEFLATE stored block (BFINAL=1, BTYPE=00) ────────────
	local LEN  = #raw_data
	local NLEN = _band(_bnot(LEN), 0xFFFF)
	local deflate_block =
		"\1" ..   -- BFINAL=1, BTYPE=00 (stored)
		string.char(LEN % 256, math.floor(LEN / 256) % 256) ..
		string.char(NLEN % 256, math.floor(NLEN / 256) % 256) ..
		raw_data

	local adl = adler32(raw_data)
	local zlib_data = "\120\1" .. deflate_block .. u32be(adl)
	--                  ^   ^ zlib header (CMF=0x78, FLG=0x01)

	-- ── PNG ───────────────────────────────────────────────────
	local png =
		"\137PNG\r\n\26\n" ..
		chunk("IHDR",
			u32be(GRID) .. u32be(GRID) ..
			"\8\6\0\0\0"   -- 8bpp RGBA, deflate, standard filter, no interlace
		) ..
		chunk("IDAT", zlib_data) ..
		chunk("IEND", "")

	return png
end

local function save_pixels_as_png(iname, pixels)
	ensure_dir(IB.worldpath)
	local png = pixels_to_png(pixels)
	local f = io.open(tex_path(iname), "wb")
	if f then f:write(png); f:close(); return true end
	return false
end

-- ── Копіювання текстури у медіа-папку мода ───────────────────
-- Luanti подає медіа з папок модів. Ми зберігаємо PNG у worldpath,
-- але також реєструємо через dynamic_add_media щоб клієнти отримали.

local function push_texture_to_clients(iname)
	local path = tex_path(iname)
	if not minetest.dynamic_add_media then return end
	-- Старіші Luanti/Minetest: dynamic_add_media(filepath, callback)
	-- Новіші: dynamic_add_media({filepath=...}[, callback])
	local ok = pcall(minetest.dynamic_add_media, path, function() end)
	if not ok then
		pcall(minetest.dynamic_add_media, {filepath = path}, function() end)
	end
end

-- ── Обробник форми ────────────────────────────────────────────

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if not (formname:sub(1,13) == "item_builder:") then return end
	local name = player:get_player_name()
	local ed   = get_ed(name)

	-- ── Головна сторінка ──
	if formname == "item_builder:main" then
		if fields.go_new then
			-- Скидаємо редактор для нового предмету
			ed.iname = ""
			ed.display_name = ""
			ed.description = ""
			ed.item_type = "craftitem"
			ed.lua_code = ""
			for i = 1,256 do ed.pixels[i] = "#888888" end
			show_edit(player)
		elseif fields.go_list then
			show_list(player)
		elseif fields.go_close or fields.quit then
			-- просто закриваємо
		end

	-- ── Редактор ──
	elseif formname == "item_builder:edit" then
		-- Зчитуємо поля завжди
		if fields.f_iname       then ed.iname        = safe_name(fields.f_iname) end
		if fields.f_display     then ed.display_name  = fields.f_display end
		if fields.f_desc        then ed.description   = fields.f_desc end
		if fields.f_lua         then ed.lua_code      = fields.f_lua end
		if fields.f_type        then ed.item_type     = fields.f_type end

		if fields.go_tex then
			show_tex(player)
		elseif fields.go_main then
			show_main(player)
		elseif fields.do_save or fields.do_give then
			if ed.iname == "" then
				minetest.chat_send_player(name, "§c[Item Builder] Вкажіть системну назву!")
				show_edit(player)
				return
			end
			if ed.display_name == "" then ed.display_name = ed.iname end

			-- Зберігаємо PNG
			ensure_dir(IB.worldpath)
			save_pixels_as_png(ed.iname, ed.pixels)
			push_texture_to_clients(ed.iname)

			-- Зберігаємо визначення
			local def = {
				name         = ed.iname,
				display_name = ed.display_name,
				description  = ed.description,
				item_type    = ed.item_type,
				lua_code     = ed.lua_code,
			}
			local ok, err = save_item_def(def)
			if not ok then
				minetest.chat_send_player(name, "§c[Item Builder] Помилка збереження: "..(err or "?"))
				return
			end
			add_to_index(ed.iname)

			-- Реєструємо предмет
			register_custom_item(def)
			minetest.chat_send_player(name, "§a[Item Builder] Предмет 'item_builder:"..ed.iname.."' збережено!")

			if fields.do_give then
				local stack = ItemStack("item_builder:" .. ed.iname)
				local inv = player:get_inventory()
				if inv:room_for_item("main", stack) then
					inv:add_item("main", stack)
					minetest.chat_send_player(name, "§a[Item Builder] Предмет видано до інвентаря.")
				else
					minetest.chat_send_player(name, "§e[Item Builder] Немає місця в інвентарі.")
				end
			end
			show_main(player)
		end

	-- ── Піксель-арт редактор ──
	elseif formname == "item_builder:tex" then
		-- Клік на піксель
		for k, _ in pairs(fields) do
			local x, y = k:match("^px_(%d+)_(%d+)$")
			if x then
				local idx = pixel_idx(tonumber(x), tonumber(y))
				ed.pixels[idx] = ed.sel_color
				show_tex(player)
				return
			end
			-- Клік на палітру
			local pi = k:match("^pal_(%d+)$")
			if pi then
				ed.sel_color = COLORS_PALETTE[tonumber(pi)] or ed.sel_color
				show_tex(player)
				return
			end
		end

		if fields.set_hex then
			local hex = (fields.custom_hex or ""):upper():gsub("[^0-9A-F#]","")
			if hex:sub(1,1) ~= "#" then hex = "#"..hex end
			if #hex == 7 then
				ed.sel_color = hex:lower()
			else
				minetest.chat_send_player(name, "§c[Item Builder] Невірний hex-колір.")
			end
			show_tex(player)
		elseif fields.clear_color then
			ed.sel_color = "transparent"
			show_tex(player)
		elseif fields.tex_fill then
			for i = 1, 256 do ed.pixels[i] = ed.sel_color end
			show_tex(player)
		elseif fields.tex_clear then
			for i = 1, 256 do ed.pixels[i] = "transparent" end
			show_tex(player)
		elseif fields.tex_ok or fields.tex_back then
			show_edit(player)
		end

	-- ── Список предметів ──
	elseif formname == "item_builder:list" then
		local names = list_saved_items()
		-- Визначаємо вибраний елемент
		if fields.item_list then
			local idx = tonumber(fields.item_list:match("CHG:(%d+)") or fields.item_list:match("(%d+)"))
			if idx then ed.selected = names[idx] end
		end

		if fields.list_edit then
			if not ed.selected then
				minetest.chat_send_player(name,"§e[Item Builder] Виберіть предмет зі списку.")
				show_list(player); return
			end
			local def = load_item_def(ed.selected)
			if def then
				ed.iname        = def.name
				ed.display_name = def.display_name or ""
				ed.description  = def.description or ""
				ed.item_type    = def.item_type or "craftitem"
				ed.lua_code     = def.lua_code or ""
			end
			show_edit(player)
		elseif fields.list_del then
			if not ed.selected then
				minetest.chat_send_player(name,"§e[Item Builder] Виберіть предмет зі списку.")
				show_list(player); return
			end
			-- Видаляємо файли
			os.remove(item_path(ed.selected))
			os.remove(tex_path(ed.selected))
			remove_from_index(ed.selected)
			minetest.chat_send_player(name,"§a[Item Builder] Предмет '"..ed.selected.."' видалено (потрібен перезапуск для очищення реєстру).")
			ed.selected = nil
			show_list(player)
		elseif fields.go_main then
			show_main(player)
		end
	end
end)

-- ── Привілей ─────────────────────────────────────────────────

minetest.register_privilege("item_builder", {
	description = "Дозволяє використовувати конструктор предметів (/itembuilder)",
	give_to_singleplayer = true,
	give_to_admin = true,
})

-- ── Команда ──────────────────────────────────────────────────

minetest.register_chatcommand("itembuilder", {
	privs       = { item_builder = true },
	description = "Відкрити конструктор власних предметів",
	func        = function(pname, _)
		local player = minetest.get_player_by_name(pname)
		if not player then return false, "Гравець не знайдений." end
		show_main(player)
		return true
	end,
})

-- Аліас
minetest.register_chatcommand("ib", {
	privs       = { item_builder = true },
	description = "Аліас /itembuilder",
	func        = function(pname, _)
		local player = minetest.get_player_by_name(pname)
		if not player then return false, "Гравець не знайдений." end
		show_main(player)
		return true
	end,
})

-- ── Завантаження збережених предметів при старті ──────────────

ensure_dir(IB.worldpath)

minetest.register_on_mods_loaded(function()
	local names = list_saved_items()
	if #names == 0 then return end
	minetest.log("action", "[item_builder] Завантаження "..#names.." збережених предметів...")
	for _, iname in ipairs(names) do
		local def = load_item_def(iname)
		if def then
			-- Реєструємо текстуру через dynamic_add_media якщо файл існує
			local tpath = tex_path(iname)
			local f = io.open(tpath, "rb")
			if f then
				f:close()
				if minetest.dynamic_add_media then
					local ok2 = pcall(minetest.dynamic_add_media, tpath, function() end)
					if not ok2 then
						pcall(minetest.dynamic_add_media, {filepath=tpath}, function() end)
					end
				end
			end
			local ok, err = pcall(register_custom_item, def)
			if ok then
				minetest.log("action","[item_builder] Зареєстровано: item_builder:"..iname)
			else
				minetest.log("error","[item_builder] Помилка реєстрації "..iname..": "..tostring(err))
			end
		end
	end
end)

minetest.log("action", "[item_builder] Мод завантажено. Папка даних: " .. IB.worldpath)
