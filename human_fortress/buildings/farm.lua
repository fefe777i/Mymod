return {
    id = "farm",
    data = {
        name = "🌾 Ферма",
        description = "Виробляє їжу для міста",
        unlock_required = "farm",
        cost = {
            score = 80,
            wood  = 40,
        },
        nodes = {
            {pos={x=0,y=0,z=0}, name="farming:soil_wet"},
            {pos={x=1,y=0,z=0}, name="farming:soil_wet"},
            {pos={x=2,y=0,z=0}, name="farming:soil_wet"},
            {pos={x=0,y=0,z=1}, name="farming:soil_wet"},
            {pos={x=1,y=0,z=1}, name="farming:soil_wet"},
            {pos={x=2,y=0,z=1}, name="farming:soil_wet"},
            -- Пшениця
            {pos={x=0,y=1,z=0}, name="farming:wheat_8"},
            {pos={x=1,y=1,z=0}, name="farming:wheat_8"},
            {pos={x=2,y=1,z=0}, name="farming:wheat_8"},
            {pos={x=0,y=1,z=1}, name="farming:wheat_8"},
            {pos={x=1,y=1,z=1}, name="farming:wheat_8"},
            {pos={x=2,y=1,z=1}, name="farming:wheat_8"},
        },
        on_built = function(player_name, pos)
            minetest.chat_send_player(player_name, "🌾 Ферма побудована! Починає виробляти їжу.")
        end,
    }
}