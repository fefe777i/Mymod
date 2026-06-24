local modname = "human_fortress"
filter = { registered_on_violations = {} }
local words = {}
local exceptions = {}
local muted = {}
local violations = {}
local s = minetest.get_mod_storage()

function filter.init()
	local sw = s:get_string("words")
	if sw and sw ~= "" then
		words = minetest.parse_json(sw)
	end
	
	-- завантажуємо винятки
	local se = s:get_string("exceptions")
	if se and se ~= "" then
		exceptions = minetest.parse_json(se)
	end

	if #words == 0 then
		filter.import_file(minetest.get_modpath("filter") .. "/words.txt")
	end
end

-- Перевірка чи може гравець говорити (рівень >= 3)
local function can_player_speak(name)
    if not human_fortress or not human_fortress.edos_data then
        return true -- Якщо мод не завантажено - дозволяємо
    end
    
    local data = human_fortress.edos_data[name]
    if not data then return true end
    
    return (data.level or 1) >= 3
end

-- Змініть існуючий обробник чату
table.insert(minetest.registered_on_chat_messages, 1, function(name, message)
    if message:sub(1, 1) == "/" then
        return
    end

    -- ПЕРЕВІРКА РІВНЯ
    if not can_player_speak(name) then
        minetest.chat_send_player(name, "❌ Ви досягнете 3 рівня, щоб говорити в чаті!")
        return true
    end

    local privs = minetest.get_player_privs(name)
    if not privs.shout and muted[name] then
        minetest.chat_send_player(name, "ТИ ПОМРЕШ В МУКАХ.")
        return true
    end

    local is_clean, censored_msg = filter.check_message(name, message)
    if not is_clean then
        minetest.chat_send_all("<" .. name .. "> " .. censored_msg)
        filter.on_violation(name, message)
        return true
    end
end)

function filter.import_file(filepath)
	local file = io.open(filepath, "r")
	if file then
		for line in file:lines() do
			line = line:trim()
			if line ~= "" then
				words[#words + 1] = line:trim()
			end
		end
		return true
	else
		return false
	end
end

function filter.register_on_violation(func)
	table.insert(filter.registered_on_violations, func)
end

function filter.check_message(name, message)
	local lower_msg = message:lower()
	local original_msg = message
	local has_bad_word = false
	
	-- спочатку перевіряємо винятки
	for _, e in ipairs(exceptions) do
		if string.find(lower_msg, e) then
			return true, original_msg
		end
	end
	
	-- перевіряємо заборонені слова
	for _, w in ipairs(words) do
		-- шукаємо слово як окреме
		local pattern = "[^%a%а-яіїєґ]" .. w .. "[^%a%а-яіїєґ]"
		if string.find(lower_msg, pattern) or 
		   string.find(lower_msg, "^" .. w .. "[^%a%а-яіїєґ]") or
		   string.find(lower_msg, "[^%a%а-яіїєґ]" .. w .. "$") or
		   string.find(lower_msg, "^" .. w .. "$") then
			
			has_bad_word = true
			-- замінюємо слово на зірочки
			local stars = string.rep("*", #w)
			original_msg = original_msg:gsub(w, stars)
		end
	end

	return not has_bad_word, original_msg
end

function filter.mute(name, duration)
	-- Функція більше не використовується (замінено на штраф ейдосами)
end

function filter.show_warning_formspec(name)
	local formspec = "size[7,3]bgcolor[#080808BB;true]" .. default.gui_bg .. default.gui_bg_img .. [[
		image[0,0;2,2;filter_warning.png]
		label[2.3,0.5;ДИВИСЬ ЗА СВОЇМ ЯЗИКОМ! А ТО БУДЕШ ЇСТИ МИЛО!]
	]]

	if minetest.global_exists("rules") and rules.show then
		formspec = formspec .. [[
				button[0.5,2.1;3,1;rules;Show Rules]
				button_exit[3.5,2.1;3,1;close;Добре]
			]]
	else
		formspec = formspec .. [[
				button_exit[2,2.1;3,1;close;Вибачте]
			]]
	end
	minetest.show_formspec(name, "filter:warning", formspec)
end

table.insert(minetest.registered_on_chat_messages, 1, function(name, message)
	if message:sub(1, 1) == "/" then
		return
	end

	local privs = minetest.get_player_privs(name)
	if not privs.shout and muted[name] then
		minetest.chat_send_player(name, "ТИ ПОБАЧЕШ ЩО ЦЕ ПОГАНО.")
		return true
	end

	local is_clean, censored_msg = filter.check_message(name, message)
	if not is_clean then
		-- відправляємо цензуроване повідомлення
		minetest.chat_send_all("<" .. name .. "> " .. censored_msg)
		-- покарання
		filter.on_violation(name, message)
		return true
	end
end)


local function make_checker(old_func)
	return function(name, param)
		if not filter.check_message(name, param) then
			filter.on_violation(name, param)
			return false
		end

		return old_func(name, param)
	end
end

for name, def in pairs(minetest.registered_chatcommands) do
	if def.privs and def.privs.shout then
		def.func = make_checker(def.func)
	end
end

local old_register_chatcommand = minetest.register_chatcommand
function minetest.register_chatcommand(name, def)
	if def.privs and def.privs.shout then
		def.func = make_checker(def.func)
	end
	return old_register_chatcommand(name, def)
end


local function step()
	for name, v in pairs(violations) do
		violations[name] = math.floor(v * 0.5)
		if violations[name] < 1 then
			violations[name] = nil
		end
	end
	minetest.after(10*60, step)
end
minetest.after(10*60, step)

minetest.register_chatcommand("filter", {
	params = "filter server",
	description = "manage swear word filter",
	privs = {server = true},
	func = function(name, param)
		local cmd, val = param:match("(%w+) (.+)")
		if param == "list" then
			return true, #words .. " words: " .. table.concat(words, ", ")
		elseif cmd == "add" then
			table.insert(words, val)
			s:set_string("words", minetest.write_json(words))
			return true, "Added \"" .. val .. "\"."
		elseif cmd == "remove" then
			for i, w in ipairs(words) do
				if w == val then
					table.remove(words, i)
					s:set_string("words", minetest.write_json(words))
					return true, "Removed \"" .. val .. "\"."
				end
			end
			return true, "\"" .. val .. "\" not found in list."
		else
			return true, "I know " .. #words .. " words.\nUsage: /filter <add|remove|list> [<word>]"
		end
	end,
})

if minetest.global_exists("rules") and rules.show then
	minetest.register_on_player_receive_fields(function(player, formname, fields)
		if formname == "filter:warning" and fields.rules then
			rules.show(player)
		end
	end)
end

-- створюємо одну функцію для обох команд
local function handle_exceptions(name, param)
	local cmd, val = param:match("(%w+) (.+)")
	if param == "list" then
		return true, "Винятки: " .. table.concat(exceptions, ", ")
	elseif cmd == "add" then
		table.insert(exceptions, val:lower())
		s:set_string("exceptions", minetest.write_json(exceptions))
		return true, "Додано виняток \"" .. val .. "\"."
	elseif cmd == "remove" then
		for i, e in ipairs(exceptions) do
			if e == val:lower() then
				table.remove(exceptions, i)
				s:set_string("exceptions", minetest.write_json(exceptions))
				return true, "Видалено виняток \"" .. val .. "\"."
			end
		end
		return true, "\"" .. val .. "\" не знайдено в списку винятків."
	else
		return true, "Використання: команда <add|remove|list> [слово]"
	end
end

-- довга назва
minetest.register_chatcommand("filter_except", {
	params = "<add|remove|list> [слово]",
	description = "керування винятками фільтра",
	privs = {server = true},
	func = handle_exceptions,
})

-- коротка назва
minetest.register_chatcommand("fe", {
	params = "<add|remove|list> [слово]",
	description = "керування винятками фільтра (скорочено)",
	privs = {server = true},
	func = handle_exceptions,
})

minetest.register_on_shutdown(function()
	for name, _ in pairs(muted) do
		local privs = minetest.get_player_privs(name)
		privs.shout = true
		minetest.set_player_privs(name, privs)
	end
end)

-- ===========================================
-- НОВА СИСТЕМА ШТРАФІВ ЕЙДОСАМИ (З МІНУСОМ)
-- ===========================================

-- Налаштування штрафів ейдосами
local edos_penalties = {
	{max_violations = 5, penalty = 100},      -- перші 5 порушень по 100
	{max_violations = 10, penalty = 200},     -- 6-10 порушень по 200
	{max_violations = 15, penalty = 300},     -- 11-15 порушень по 300
	{max_violations = 20, penalty = 400},     -- 16-20 порушень по 400
	{max_violations = 25, penalty = 500},     -- 21-25 порушень по 500
	{max_violations = 30, penalty = 700},     -- 26-30 порушень по 700
	{max_violations = 35, penalty = 900},     -- 31-35 порушень по 900
	{max_violations = 40, penalty = 1100},    -- 36-40 порушень по 1100
	{max_violations = 45, penalty = 1500},    -- 41-45 порушень по 1500
	{max_violations = 50, penalty = 2000},    -- 46-50 порушень по 2000
	{max_violations = 999, penalty = 3000},   -- 51+ порушень по 3000
}

-- Функція для отримання штрафу за кількістю порушень
local function get_penalty_for_violations(count)
	for _, level in ipairs(edos_penalties) do
		if count <= level.max_violations then
			return level.penalty
		end
	end
	return 3000 -- максимальний штраф якщо щось пішло не так
end

-- Функція зняття SCORE (балансу) з можливістю мінуса
local function take_edos(name, amount)
	if not human_fortress then
		minetest.log("error", "human_fortress не завантажено!")
		return false
	end
	
	local player = minetest.get_player_by_name(name)
	if not player then return false end
	
	-- Створюємо таблицю для гравця якщо її немає
	if not human_fortress.edos_data then
		human_fortress.edos_data = {}
	end
	if not human_fortress.edos_data[name] then
		human_fortress.edos_data[name] = {score = 0}
	end
	
	-- Знімаємо score (навіть якщо баланс піде в мінус)
	local old_score = human_fortress.edos_data[name].score
	human_fortress.edos_data[name].score = old_score - amount
	
	-- Красиве повідомлення
	if old_score >= amount then
		-- Вистачило ейдосів
		minetest.chat_send_player(name, "💰 Знято " .. amount .. " ейдосів за мат. Баланс: " .. (old_score - amount))
	else
		-- Не вистачило ейдосів
		local debt = amount - old_score
		minetest.chat_send_player(name, "💰 Знято " .. amount .. " ейдосів за мат. (Було: " .. old_score .. ")")
		minetest.chat_send_player(name, "⚠️ ВИ В МІНУСІ НА " .. debt .. " ЕЙДОСІВ! Поточний баланс: " .. (old_score - amount))
	end
	
	-- Зберігаємо дані (якщо є функція збереження)
	if human_fortress.save_data then
		human_fortress.save_data()
	end
	
	return true
end

-- Змінна для зберігання часу останнього порушення (щоб не спамити)
local last_violation_time = {}

-- НОВА функція on_violation (з ейдосами, без кіка)
function filter.on_violation(name, message)
	local current_time = minetest.get_us_time() / 1000000 -- в секундах
	
	-- Захист від спаму (не рахуємо порушення частіше ніж раз на 5 секунд)
	if last_violation_time[name] and (current_time - last_violation_time[name]) < 5 then
		return
	end
	last_violation_time[name] = current_time
	
	-- Збільшуємо лічильник порушень
	violations[name] = (violations[name] or 0) + 1
	local v_count = violations[name]
	
	-- Отримуємо розмір штрафу
	local penalty = get_penalty_for_violations(v_count)
	
	-- Знімаємо ейдоси (навіть якщо піде в мінус)
	take_edos(name, penalty)
	local resolution = "edos_penalty"

	-- Логування
	local logmsg = "VIOLATION (" .. resolution .. " -" .. penalty .. " edos): <" .. name .. "> " .. message
	minetest.log("action", logmsg)

	-- Email сповіщення (якщо налаштовано)
	local email_to = minetest.settings:get("filter.email_to")
	if email_to and minetest.global_exists("email") then
		email.send_mail(name, email_to, logmsg)
	end
	
	-- Показуємо попередження гравцю
	filter.show_warning_formspec(name)
	
	-- Підказка скільки ще до наступного рівня штрафу
	local next_penalty = get_penalty_for_violations(v_count + 1)
	if next_penalty ~= penalty then
		minetest.chat_send_player(name, "Наступне порушення коштуватиме " .. next_penalty .. " ейдосів!")
	end
end

filter.init()