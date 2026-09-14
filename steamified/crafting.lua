minetest.register_craft({
    output = "steamified:axle 4",
    recipe = {
        {"", "default:steel_ingot", ""},
        {"", "default:stick", ""},
        {"", "default:steel_ingot", ""},
    },
})

minetest.register_craft({
    output = "steamified:cog",
    recipe = {
        {"", "default:stick", ""},
        {"default:wood", "default:stick", "default:wood"},
        {"", "default:stick", ""},
    },
})

minetest.register_craft({
    output = "steamified:gearbox",
    recipe = {
        {"steamified:axle", "default:steel_ingot", "steamified:axle"},
        {"default:steel_ingot", "steamified:cog", "default:steel_ingot"},
        {"steamified:axle", "default:steel_ingot", "steamified:axle"},
    },
})

minetest.register_craft({
    output = "steamified:miner",
    recipe = {
        {"default:steel_ingot", "default:mese_crystal_fragment", "default:steel_ingot"},
        {"default:steel_ingot", "steamified:axle", "default:steel_ingot"},
        {"", "default:stick", ""},
    },
})

minetest.register_craft({
    output = "steamified:motor",
    recipe = {
        {"default:furnace", "", "default:furnace"},
        {"default:steel_ingot", "steamified:axle", "default:steel_ingot"},
        {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
    },
})

minetest.register_craft({
    output = "steamified:water_wheel",
    recipe = {
        {"", "default:wood", ""},
        {"steamified:cog", "default:wood", "steamified:cog"},
        {"", "default:stick", ""},
    },
})

minetest.register_craft({
    output = "steamified:crank",
    recipe = {
        {"default:stick", "", "default:stick"},
        {"default:stick", "steamified:axle", "default:stick"},
        {"", "default:wood", ""},
    },
})
