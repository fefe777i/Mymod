return {
    id = "house",
    data = {
        name = "🏠 Дім",
        description = "Житло для юнітів",
        unlock_required = "town_hall",
        cost = {
            score = 50,
            wood  = 30,
            stone = 20,
        },
        nodes = {
            -- Підлога
            {pos={x=0,y=0,z=0}, name="default:wood"},
            {pos={x=1,y=0,z=0}, name="default:wood"},
            {pos={x=0,y=0,z=1}, name="default:wood"},
            {pos={x=1,y=0,z=1}, name="default:wood"},
            -- Стіни
            {pos={x=0,y=1,z=0}, name="default:wood"},
            {pos={x=1,y=1,z=0}, name="default:wood"},
            {pos={x=0,y=1,z=1}, name="default:wood"},
            {pos={x=1,y=1,z=1}, name="default:wood"},
            -- Вікна
            {pos={x=0,y=2,z=0}, name="default:glass"},
            {pos={x=1,y=2,z=0}, name="default:glass"},
            {pos={x=0,y=2,z=1}, name="default:glass"},
            {pos={x=1,y=2,z=1}, name="default:glass"},
            -- Дах
            {pos={x=0,y=3,z=0}, name="default:wood"},
            {pos={x=1,y=3,z=0}, name="default:wood"},
            {pos={x=0,y=3,z=1}, name="default:wood"},
            {pos={x=1,y=3,z=1}, name="default:wood"},
        },
        on_built = function(player_name, pos)
            minetest.chat_send_player(player_name, "🏠 Дім побудовано!")
        end,
    }
}