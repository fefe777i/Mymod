return {
    id = "wall",
    data = {
        name = "🧱 Стіна",
        description = "Захисна споруда",
        unlock_required = "wall",
        cost = {
            score = 30,
            stone = 30,
        },
        nodes = {
            {pos={x=0,y=0,z=0}, name="default:cobble"},
            {pos={x=0,y=1,z=0}, name="default:cobble"},
            {pos={x=0,y=2,z=0}, name="default:cobble"},
        },
        on_built = function(player_name, pos)
            minetest.chat_send_player(player_name, "🧱 Стіну побудовано!")
        end,
    }
}