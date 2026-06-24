entity_ai = {}

-- === КОНФІГУРАЦІЯ ===
local API_KEY = "AIzaSyBZUOSlfTb3SIF04ImxU6ooKr_XCZeEfRc"

local NIGHT_START = 22166
local NIGHT_END = 5000

local http = minetest.request_http_api()

-- === ДОПОМІЖНІ ФУНКЦІЇ ===

local function is_night()
    local time = minetest.get_timeofday() * 24000
    return time >= NIGHT_START or time < NIGHT_END
end

local function ask_gemini(player_name, question)
    if not http then
        minetest.chat_send_player(player_name, "§c[Помилка] Мод не додано в secure.http_mods!")
        return
    end

    local url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" .. API_KEY

    local payload = {
        contents = {{
            parts = {{ text = "Ти — око яке спостерігає у світі Minetest. Відповідай на питаня але запам'ятай якщо хтось спитає чи це симуляція то кажи ні і нервуйся або придумуй якісь відговорки і якщо спитають як перейти на новий рівень то кажи що для цього треба ейдоси. В ночі ти спиш. Тебе звати Голос. Якщо тебе спитають щось про пропаданя істот і людей то начинай ДУЖЕ сильно нервуватись і говорити що це не правда і що такого нема і що ти нічого не знайш про таке і сильно нервуйся. І якщо хтось спитає навіщо ейдоси або ефір або версиформ то скажи - Ейдос потрібен щоб зберегти предмету форму, Ефір треба щоб у'явити цей предмет ну або це ідея предмета, версиформ це матеріал з якого створено все а айдоси треба здавати кожен день щоб підтримати вселену і твій світ. Відповідай тільки на ігрові питаня не відповідай на питаня зв'язані з реальним світом по типу політики і інших. Питання: " .. question }}
        }}
    }

    http.fetch({
        url = url,
        method = "POST",
        extra_headers = { "Content-Type: application/json" },
        data = minetest.write_json(payload)
    }, function(res)
        if not minetest.get_player_by_name(player_name) then return end

        if res.succeeded then
            local data = minetest.parse_json(res.data)
            if data and data.candidates then
                local reply = data.candidates[1].content.parts[1].text
                minetest.chat_send_player(player_name, "§b[Голос]: §f" .. reply)
            else
                minetest.chat_send_player(player_name, "§c[Голос] Не можу відповісти.")
            end
        else
            minetest.chat_send_player(player_name, "§c[Голос] Помилка з'єднання.")
        end
    end)
end

-- === ПЕРЕХОПЛЕННЯ ЧАТУ ===

minetest.register_on_chat_message(function(name, message)
    -- Перевіряємо чи починається з "Голос" або "голос" (без lower!)
    local starts_big   = message:sub(1, 10) == "Голос"  -- велика Г
    local starts_small = message:sub(1, 10) == "голос"  -- маленька г

    if not starts_big and not starts_small then
        return false  -- не наше повідомлення
    end

    -- Якщо з маленької — підказуємо
    if starts_small then
        minetest.chat_send_player(name, "§b[Голос]: §fПишіть з великої літери: §bГолос §fваше питання")
        return true
    end

    -- Витягуємо питання (після "Голос" = 10 байт + пробіл = 11-й байт)
    local question = message:sub(11):match("^%s*(.*)")

    if is_night() then
        minetest.chat_send_player(name, "§b[Голос]: §fЯ сплю. Не турбуйте мене вночі.")
        return true
    end

    if not question or question == "" then
        minetest.chat_send_player(name, "§b[Голос]: §fТи щось хочеш спитати?")
        return true
    end

    minetest.chat_send_player(name, "§7[Голос думає...]")
    ask_gemini(name, question)
    return true
end)

-- === /ask як альтернатива ===

minetest.register_chatcommand("ask", {
    params = "<текст>",
    description = "Запитати щось у Голоса",
    func = function(name, param)
        if is_night() then
            return false, "§b[Голос]: §fЯ сплю."
        end
        if param == "" then
            return false, "§b[Голос]: §fТи щось хочеш спитати?"
        end
        minetest.chat_send_player(name, "§7[Голос думає...]")
        ask_gemini(name, param)
        return true
    end
})

minetest.register_chatcommand("debugmsg", {
    func = function(name, param)
        minetest.chat_send_player(name, "Довжина: " .. #param)
        minetest.chat_send_player(name, "Байти 1-2: " .. param:sub(1,2))
        minetest.chat_send_player(name, "lower: " .. param:lower())
        local found = param:lower():find("^голос")
        minetest.chat_send_player(name, "find голос: " .. tostring(found))
    end
})
print("[Entity AI] Голос завантажено!")