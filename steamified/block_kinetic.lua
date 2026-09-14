steamified.register_kinetic_node("steamified:axle", {
    description = "Axle\n" .. minetest.colorize("#888888", "No stress impact") .. minetest.colorize("#cfc17f", "\nTransmits rotation along one axis"),
    type = "shaft",
    textures = {"steamified_shaft.png"},
    inventory_image = "steamified_axle_inv.png",
    wield_image = "steamified_axle_inv_2.png"
})

steamified.register_kinetic_node("steamified:cog", {
    description = "Cog\n" .. minetest.colorize("#888888", "No stress impact") .. minetest.colorize("#cfc17f", "\nTransmits rotation along two axes"),
    type = "cog",
    textures = {"steamified_wood.png", "steamified_shaft.png"},
    inventory_image = "steamified_cog_inv.png",
    wield_image = "steamified_cog_inv_2.png"
})