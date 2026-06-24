--STONE BRICK

minetest.register_node("coloredstonebricks:stonebricks_red", {
	groups = {cracky =2},
	tiles = {"default_stone_brick.png^[colorize:red:80"},
	description = "Red Stonebricks",
})

minetest.register_node("coloredstonebricks:stonebricks_green_dark", {
	groups = {cracky =2},
	tiles = {"default_stone_brick.png^[colorize:green:100"},
	description = "Dark Green Stonebricks",
})

minetest.register_node("coloredstonebricks:stonebricks_cyan", {
	groups = {cracky =2},
	tiles = {"default_stone_brick.png^[colorize:cyan:80"},
	description = "Cyan Stonebricks",
})

minetest.register_node("coloredstonebricks:stonebricks_purple", {
	groups = {cracky =2},
	tiles = {"default_stone_brick.png^[colorize:purple:80"},
	description = "Purple Stonebricks",
})

minetest.register_node("coloredstonebricks:stonebricks_pink", {
	groups = {cracky =2},
	tiles = {"default_stone_brick.png^[colorize:pink:100"},
	description = "Pink Stonebricks",
})

minetest.register_node("coloredstonebricks:stonebricks_yellow", {
	groups = {cracky =2},
	tiles = {"default_stone_brick.png^[colorize:yellow:100"},
	description = "Yellow Stonebricks",
})

minetest.register_node("coloredstonebricks:stonebricks_orange", {
	groups = {cracky =2},
	tiles = {"default_stone_brick.png^[colorize:orange:100"},
	description = "Orange Stonebricks",
})

minetest.register_node("coloredstonebricks:stonebricks_blue_dark", {
	groups = {cracky =2},
	tiles = {"default_stone_brick.png^[colorize:blue:100"},
	description = "Dark Blue Stonebricks",
})

minetest.register_node("coloredstonebricks:stonebricks_black", {
	groups = {cracky =2},
	tiles = {"default_stone_brick.png^[colorize:black:80"},
	description = "Black Stonebricks",
})

minetest.register_node("coloredstonebricks:stonebricks_green_light", {
	groups = {cracky =2},
	tiles = {"default_stone_brick.png^[colorize:green:50"},
	description = "Light Green Stonebricks",
})

minetest.register_node("coloredstonebricks:stonebricks_blue_light", {
	groups = {cracky =2},
	tiles = {"default_stone_brick.png^[colorize:blue:50"},
	description = "Light Blue Stonebricks",
})

-- Червоний полублок
minetest.register_node("coloredstonebricks:slabstonebricksred", {
    description = "Red Stonebricks Slab",
    tiles = {"default_stone_brick.png^[colorize:red:80"},
    groups = {cracky = 2, slab = 1},
    
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
    },
    paramtype = "light",
    sunlight_propagates = true,
    walkable = true,
})

minetest.register_craft({
    output = "coloredstonebricks:slabstonebricksred 6",
    recipe = {
        {"coloredstonebricks:stonebricks_red", "coloredstonebricks:stonebricks_red", "coloredstonebricks:stonebricks_red"},
    },
})

-- Темно-зелений полублок
minetest.register_node("coloredstonebricks:slabstonebricksgreendark", {
    description = "Dark Green Stonebricks Slab",
    tiles = {"default_stone_brick.png^[colorize:green:100"},
    groups = {cracky = 2, slab = 1},
    
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
    },
    paramtype = "light",
    sunlight_propagates = true,
    walkable = true,
})

minetest.register_craft({
    output = "coloredstonebricks:slabstonebricksgreendark 6",
    recipe = {
        {"coloredstonebricks:stonebricks_green_dark", "coloredstonebricks:stonebricks_green_dark", "coloredstonebricks:stonebricks_green_dark"},
    },
})

-- Блакитний полублок
minetest.register_node("coloredstonebricks:slabstonebrickscyan", {
    description = "Cyan Stonebricks Slab",
    tiles = {"default_stone_brick.png^[colorize:cyan:80"},
    groups = {cracky = 2, slab = 1},
    
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
    },
    paramtype = "light",
    sunlight_propagates = true,
    walkable = true,
})

minetest.register_craft({
    output = "coloredstonebricks:slabstonebrickscyan 6",
    recipe = {
        {"coloredstonebricks:stonebricks_cyan", "coloredstonebricks:stonebricks_cyan", "coloredstonebricks:stonebricks_cyan"},
    },
})

-- Фіолетовий полублок
minetest.register_node("coloredstonebricks:slabstonebrickspurple", {
    description = "Purple Stonebricks Slab",
    tiles = {"default_stone_brick.png^[colorize:purple:80"},
    groups = {cracky = 2, slab = 1},
    
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
    },
    paramtype = "light",
    sunlight_propagates = true,
    walkable = true,
})

minetest.register_craft({
    output = "coloredstonebricks:slabstonebrickspurple 6",
    recipe = {
        {"coloredstonebricks:stonebricks_purple", "coloredstonebricks:stonebricks_purple", "coloredstonebricks:stonebricks_purple"},
    },
})

-- Рожевий полублок
minetest.register_node("coloredstonebricks:slabstonebrickspink", {
    description = "Pink Stonebricks Slab",
    tiles = {"default_stone_brick.png^[colorize:pink:100"},
    groups = {cracky = 2, slab = 1},
    
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
    },
    paramtype = "light",
    sunlight_propagates = true,
    walkable = true,
})

minetest.register_craft({
    output = "coloredstonebricks:slabstonebrickspink 6",
    recipe = {
        {"coloredstonebricks:stonebricks_pink", "coloredstonebricks:stonebricks_pink", "coloredstonebricks:stonebricks_pink"},
    },
})

-- Жовтий полублок
minetest.register_node("coloredstonebricks:slabstonebricksyellow", {
    description = "Yellow Stonebricks Slab",
    tiles = {"default_stone_brick.png^[colorize:yellow:100"},
    groups = {cracky = 2, slab = 1},
    
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
    },
    paramtype = "light",
    sunlight_propagates = true,
    walkable = true,
})

minetest.register_craft({
    output = "coloredstonebricks:slabstonebricksyellow 6",
    recipe = {
        {"coloredstonebricks:stonebricks_yellow", "coloredstonebricks:stonebricks_yellow", "coloredstonebricks:stonebricks_yellow"},
    },
})

-- Помаранчевий полублок
minetest.register_node("coloredstonebricks:slabstonebricksorange", {
    description = "Orange Stonebricks Slab",
    tiles = {"default_stone_brick.png^[colorize:orange:100"},
    groups = {cracky = 2, slab = 1},
    
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
    },
    paramtype = "light",
    sunlight_propagates = true,
    walkable = true,
})

minetest.register_craft({
    output = "coloredstonebricks:slabstonebricksorange 6",
    recipe = {
        {"coloredstonebricks:stonebricks_orange", "coloredstonebricks:stonebricks_orange", "coloredstonebricks:stonebricks_orange"},
    },
})

-- Темно-синій полублок
minetest.register_node("coloredstonebricks:slabstonebricksbluedark", {
    description = "Dark Blue Stonebricks Slab",
    tiles = {"default_stone_brick.png^[colorize:blue:100"},
    groups = {cracky = 2, slab = 1},
    
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
    },
    paramtype = "light",
    sunlight_propagates = true,
    walkable = true,
})

minetest.register_craft({
    output = "coloredstonebricks:slabstonebricksbluedark 6",
    recipe = {
        {"coloredstonebricks:stonebricks_blue_dark", "coloredstonebricks:stonebricks_blue_dark", "coloredstonebricks:stonebricks_blue_dark"},
    },
})

-- Чорний полублок
minetest.register_node("coloredstonebricks:slabstonebricksblack", {
    description = "Black Stonebricks Slab",
    tiles = {"default_stone_brick.png^[colorize:black:80"},
    groups = {cracky = 2, slab = 1},
    
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
    },
    paramtype = "light",
    sunlight_propagates = true,
    walkable = true,
})

minetest.register_craft({
    output = "coloredstonebricks:slabstonebricksblack 6",
    recipe = {
        {"coloredstonebricks:stonebricks_black", "coloredstonebricks:stonebricks_black", "coloredstonebricks:stonebricks_black"},
    },
})

-- Світло-зелений полублок
minetest.register_node("coloredstonebricks:slabstonebricksgreenlight", {
    description = "Light Green Stonebricks Slab",
    tiles = {"default_stone_brick.png^[colorize:green:50"},
    groups = {cracky = 2, slab = 1},
    
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
    },
    paramtype = "light",
    sunlight_propagates = true,
    walkable = true,
})

minetest.register_craft({
    output = "coloredstonebricks:slabstonebricksgreenlight 6",
    recipe = {
        {"coloredstonebricks:stonebricks_green_light", "coloredstonebricks:stonebricks_green_light", "coloredstonebricks:stonebricks_green_light"},
    },
})

-- Світло-синій полублок
minetest.register_node("coloredstonebricks:slabstonebricksbluelight", {
    description = "Light Blue Stonebricks Slab",
    tiles = {"default_stone_brick.png^[colorize:blue:50"},
    groups = {cracky = 2, slab = 1},
    
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
    },
    paramtype = "light",
    sunlight_propagates = true,
    walkable = true,
})

minetest.register_craft({
    output = "coloredstonebricks:slabstonebricksbluelight 6",
    recipe = {
        {"coloredstonebricks:stonebricks_blue_light", "coloredstonebricks:stonebricks_blue_light", "coloredstonebricks:stonebricks_blue_light"},
    },
})