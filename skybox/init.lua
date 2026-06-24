-- Функція для встановлення "вічного світлого неба"
local function set_eternal_day(player)
    -- 1. Налаштування кольору неба (світло-блакитне)
    player:set_sky({
        base_color = "#8cbafa",
        type = "plain",       -- "plain" прибирає градієнти та стандартне небо
        clouds = false,       -- Вимикаємо хмари
    })

    -- 2. Повністю вимикаємо всі світила
    player:set_sun({visible = false})
    player:set_moon({visible = false})
    player:set_stars({visible = false})

    -- 3. Фіксуємо рівень освітлення для гравця (Day-Night Ratio)
    -- Значення 1.0 означає "максимальне денне світло" завжди
    player:override_day_night_ratio(1.0)
end

-- Застосовуємо при вході гравця
minetest.register_on_joinplayer(function(player)
    set_eternal_day(player)
end)

-- Про всяк випадок перевіряємо кожні кілька секунд, 
-- щоб налаштування не злетіли (наприклад, після смерті чи зміни режиму)
local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer > 5 then
        for _, player in ipairs(minetest.get_connected_players()) do
            player:override_day_night_ratio(1.0)
        end
        timer = 0
    end
end)

-- Бонус: команда, щоб вручну повернути світло, якщо щось пішло не так
minetest.register_chatcommand("fix_light", {
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            set_eternal_day(player)
            return true, "Світло виправлено! Тепер завжди день."
        end
    end
})