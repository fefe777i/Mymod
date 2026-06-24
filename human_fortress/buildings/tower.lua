return {
    id = "tower",
    data = {
        name = "🗼 Вежа",
        description = "Оборонна споруда",
        unlock_required = "guard_tower",
        cost = {
            score = 280,
            stone = 200,
            wood  = 50,
        },
        nodes = {
            -- Основа
            {pos={x=0,y=0,z=0}, name="default:stonebrick"},
            {pos={x=1,y=0,z=0}, name="default:stonebrick"},
            {pos={x=0,y=0,z=1}, name="default:stonebrick"},
            {pos={x=1,y=0,z=1}, name="default:stonebrick"},
            -- Поверх 1
            {pos={x=0,y=1,z=0}, name="default:stonebrick"},
            {pos={x=1,y=1,z=0}, name="default:stonebrick"},
            {pos={x=0,y=1,z=1}, name="default:stonebrick"},
            {pos={x=1,y=1,z=1}, name="default:stonebrick"},
            -- Поверх 2
            {pos={x=0,y=2,z=0}, name="default:stonebrick"},
            {pos={x=1,y=2,z=0}, name="default:stonebrick"},
            {pos={x=0,y=2,z=1}, name="default:stonebrick"},
            {pos={x=1,y=2,z=1}, name="default:stonebrick"},
            -- Поверх 3
            {pos={x=0,y=3,z=0}, name="default:stonebrick"},
            {pos={x=1,y=3,z=0}, name="default:stonebrick"},
            {pos={x=0,y=3,z=1}, name="default:stonebrick"},
            {pos={x=1,y=3,z=1}, name="default:stonebrick"},
            -- Факел
            {pos={x=0,y=4,z=0}, name="default:torch"},
            {pos={x=1,y=4,z=0}, name="default:torch"},
        },
        on_built = function(player_name, pos)
            minetest.chat_send_player(player_name, "🗼 Вежу побудовано!")
        end,
        on_enter = function(player_name, unit, pos)
            minetest.chat_send_player(player_name, "🗼 Юніт зайшов у вежу")
        end,
    }
}