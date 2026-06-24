local tables_chairs = {}

-- If true, you can sit on chairs and benches, when right-click them.
tables_chairs.enable_sitting = core.settings:get_bool("tables_chairs.enable_sitting", true)
tables_chairs.globalstep = core.settings:get_bool("tables_chairs.globalstep", true)

local game = core.get_game_info().id
local mod_mcl_player = core.get_modpath("mcl_player")
local mod_player_api = core.get_modpath("player_api")
local S = core.get_translator("tables_chairs")

-- Get texture by node name
local T = function (node_name)
	local def = core.registered_nodes[node_name]
	if not (def and def.tiles) then
		return ""
	end
	local tile = def.tiles[5] or def.tiles[4] or def.tiles[3] or def.tiles[2] or def.tiles[1]
	if type(tile) == "string" then
		return tile
	elseif type(tile) == "table" and tile.name then
		return tile.name
	end
	return ""
end
local vector_y_plus_1 = {x=0, y=1, z=0}
if mod_player_api or mod_mcl_player then
	local set_animation
	local player_api
	if mod_mcl_player then
		player_api = mcl_player
		set_animation = mcl_player.player_set_animation
	else
		player_api = _G.player_api
		set_animation = player_api.set_animation
	end
	-- The following code is from "Get Comfortable [cozy]" (by everamzah; published under WTFPL)
	-- Thomas S. modified it, so that it can be used in this mod
	if tables_chairs.enable_sitting then
		tables_chairs.sit = function(pos, node, player)
			if core.get_node(vector.add(pos,vector_y_plus_1)).name ~= "air" then
				core.chat_send_player(player:get_player_name(), S("You tried to sit but hit your head."))
				return
			end
			local name = player:get_player_name()
			if not player_api.player_attached[name] then
				if vector.length(player:get_velocity()) > 0.5 then
					core.chat_send_player(player:get_player_name(), S('You can only sit down when you are not moving.'))
					return
				end

				if core.get_item_group(node.name, "tables_chairs_bench") == 1 then
					
					if
					node.param2 == 0 then pos.z=pos.z+0.25 elseif
					node.param2 == 2 then pos.z=pos.z-0.25 elseif
					node.param2 == 1 then pos.x=pos.x+0.25 elseif
					node.param2 == 3 then pos.x=pos.x-0.25
					end
				end
				player:move_to(pos)
				
				
				player:set_physics_override({speed = 0, jump = 0, gravity = 0})
				player_api.player_attached[name] = true
				--core.after(0.1, function()
				--	if player then
						set_animation(player, "sit" , 30)
						player:set_eye_offset({x = 0, y = (0.8 - player:get_properties().eye_height)*10, z = 0}, {x = 0, y = 0, z = 0})
				--	end
				--end)
			else
				tables_chairs.stand(player, name)
			end
		end

		tables_chairs.up = function(_, _, player)
			local name = player:get_player_name()
			if player_api.player_attached[name] then
				tables_chairs.stand(player, name)
			end
		end

		tables_chairs.stand = function(player, name)
			player:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
			player:set_physics_override({speed = 1, jump = 1, gravity = 1})
			player_api.player_attached[name] = false
			set_animation(player, "stand", 30)
		end

		-- The player will stand at the beginning of the movement
		if tables_chairs.globalstep and not core.get_modpath("cozy") then
			core.register_globalstep(function(dtime)
				local players = core.get_connected_players()
				for i = 1, #players do
					local player = players[i]
					local name = player:get_player_name()
					local ctrl = player:get_player_control()
					if player_api.player_attached[name] and not player:get_attach() and
					(ctrl.up or ctrl.down or ctrl.left or ctrl.right or ctrl.jump) then
						tables_chairs.up(nil, nil, player)
					end
				end
			end)
		end
	end
	-- End of [cozy] code
end

local furnitures = {
	["chair"] = {
		description = "Chair",
		sitting = true,
		nodebox = {
			{ -0.3, -0.5, 0.2, -0.2, 0.5, 0.3 }, -- foot 1
			{ 0.2, -0.5, 0.2, 0.3, 0.5, 0.3 }, -- foot 2
			{ 0.2, -0.5, -0.3, 0.3, -0.1, -0.2 }, -- foot 3
			{ -0.3, -0.5, -0.3, -0.2, -0.1, -0.2 }, -- foot 4
			{ -0.3, -0.1, -0.3, 0.3, 0, 0.2 }, -- seating
			{ -0.2, 0.1, 0.25, 0.2, 0.4, 0.26 } -- conector 1-2
		},
		craft = function(recipe)
			return {
				{ "", "group:stick" },
				{ recipe, recipe },
				{ "group:stick", "group:stick" }
			}
		end
	},
	["stool"] = {
		description = "Stool",
		sitting = true,
		nodebox = {
			{ -0.3, -0.5, 0.2, -0.2, -0.1, 0.3 }, -- foot 1
			{ 0.2, -0.5, 0.2, 0.3, -0.1, 0.3 }, -- foot 2
			{ 0.2, -0.5, -0.3, 0.3, -0.1, -0.2 }, -- foot 3
			{ -0.3, -0.5, -0.3, -0.2, -0.1, -0.2 }, -- foot 4
			{ -0.3, -0.1, -0.3, 0.3, 0, 0.3 }, -- seating
		},
		craft = function(recipe)
			return {
				{ "group:stick", recipe, "group:stick" },
				{ "group:stick", "", "group:stick" }
			}
		end
	},
	["bench_backrest"] = {
		description = "Comfortable Bench",
		sitting = true,
		nodebox = {
			{ 0.5, -0.5, 0.5, -0.5, 0.5, 5/16 }, -- back
			{ 6/16, -0.5, -0.3, 0.5, -0.1, -0.2 }, -- foot 3
			{ -0.5, -0.5, -0.3, -6/16, -0.1, -0.2 }, -- foot 4
			{ -0.5, -0.1, -0.3, 0.5, 0, 5/16 }, -- seating
		},
		craft = function(recipe)
			return {
				{ "group:stick", "" },
				{ recipe, recipe },
				{ "group:stick", "group:stick" }
			}
		end
	},
	["table"] = {
		description = "Table",
		nodebox = {
			{ -0.4, -0.5, -0.4, -0.3, 0.4, -0.3 }, -- foot 1
			{ 0.3, -0.5, -0.4, 0.4, 0.4, -0.3 }, -- foot 2
			{ -0.4, -0.5, 0.3, -0.3, 0.4, 0.4 }, -- foot 3
			{ 0.3, -0.5, 0.3, 0.4, 0.4, 0.4 }, -- foot 4
			{ -0.5, 0.4, -0.5, 0.5, 0.5, 0.5 } -- table top
		},
		craft = function(recipe)
			return {
				{ recipe, recipe, recipe },
				{ "group:stick", "", "group:stick" },
				{ "group:stick", "", "group:stick" }
			}
		end
	},
	["small_table"] = {
		description = "Small Table",
		nodebox = {
			{ -0.4, -0.5, -0.4, -0.3, 0.1, -0.3 }, -- foot 1
			{ 0.3, -0.5, -0.4, 0.4, 0.1, -0.3 }, -- foot 2
			{ -0.4, -0.5, 0.3, -0.3, 0.1, 0.4 }, -- foot 3
			{ 0.3, -0.5, 0.3, 0.4, 0.1, 0.4 }, -- foot 4
			{ -0.5, 0.1, -0.5, 0.5, 0.2, 0.5 } -- table top
		},
		craft = function(recipe)
			return {
				{ recipe, recipe, recipe },
				{ "group:stick", "", "group:stick" }
			}
		end
	},
	["tiny_table"] = {
		description = "Tiny Table",
		nodebox = {
			{ -0.5, -0.1, -0.5, 0.5, 0, 0.5 }, -- table top
			{ -0.4, -0.5, -0.5, -0.3, -0.1, 0.5 }, -- foot 1
			{ 0.3, -0.5, -0.5, 0.4, -0.1, 0.5 }, -- foot 2
		},
		craft = function(recipe)
			local bench_name = "tables_chairs:" .. recipe:sub(recipe:find(":")+1) .. "_bench"
			return {
				{ bench_name, bench_name }
			}
		end
	},
	["bench"] = {
		description = "Bench",
		sitting = true,
		bench = true,
		nodebox = {
			{ -0.5, -0.1, 0, 0.5, 0, 0.5 }, -- seating
			{ -0.4, -0.5, 0, -0.3, -0.1, 0.5 }, -- foot 1
			{ 0.3, -0.5, 0, 0.4, -0.1, 0.5 } -- foot 2
		},
		craft = function(recipe)
			return {
				{ recipe, recipe },
				{ "group:stick", "group:stick" }
			}
		end
	}
}

local ignore_groups = {
	["wood"] = true,
	["stone"] = true,
	["tree"] = true
}

function tables_chairs.register_legacy_alias(recipe)
	for furniture, def in pairs(furnitures) do
		local node_name = "tables_chairs:" .. recipe:sub(recipe:find(":")+1) .. "_" .. furniture
		local old_node_name = "ts_furniture:" .. recipe:gsub(":", "_") .. "_" .. furniture
		core.register_alias_force(old_node_name,node_name)
	end
end

function tables_chairs.register_furniture(recipe, tiles)
	if not tiles then
		tiles = T(recipe)
	end

	local recipe_def = core.registered_items[recipe]
	if not recipe_def then
		return
	end

	local groups = {}
	for k, v in pairs(recipe_def.groups) do
		if not ignore_groups[k] then
			groups[k] = v
		end
	end

	for furniture, def in pairs(furnitures) do
		local node_name = "tables_chairs:" .. recipe:sub(recipe:find(":")+1) .. "_" .. furniture
	
		if def.sitting and tables_chairs.enable_sitting then
			def.on_rightclick = tables_chairs.sit
			def.on_punch = tables_chairs.up
		end
		
		local groups2 = table.copy(groups)
		if def.bench then
			groups2.tables_chairs_bench = 1
		end
		
		core.register_node(":" .. node_name, {
			description = S(def.description) .. S(" of ") .. core.registered_nodes[recipe].description,
			drawtype = "nodebox",
			paramtype = "light",
			paramtype2 = "facedir",
			sunlight_propagates = true,
			tiles = { tiles },
			groups = groups2,
			node_box = {
				type = "fixed",
				fixed = def.nodebox
			},
			on_rightclick = def.on_rightclick,
			on_punch = def.on_punch
		})

		core.register_craft({
			output = node_name,
			recipe = def.craft(recipe)
		})
	end
end

if (core.get_modpath("default")) then
	tables_chairs.register_legacy_alias("default:aspen_wood")
	tables_chairs.register_legacy_alias("default:pine_wood")
	tables_chairs.register_legacy_alias("default:acacia_wood")
	tables_chairs.register_legacy_alias("default:wood")
	tables_chairs.register_legacy_alias("default:junglewood")
end


if (core.get_modpath("moretrees")) then
	tables_chairs.register_legacy_alias("moretrees:apple_tree_planks")
	tables_chairs.register_legacy_alias("moretrees:beech_planks")
	tables_chairs.register_legacy_alias("moretrees:birch_planks")
	tables_chairs.register_legacy_alias("moretrees:fir_planks")
	tables_chairs.register_legacy_alias("moretrees:oak_planks")
	tables_chairs.register_legacy_alias("moretrees:palm_planks")
	tables_chairs.register_legacy_alias("moretrees:rubber_tree_planks")
	tables_chairs.register_legacy_alias("moretrees:sequoia_planks")
	tables_chairs.register_legacy_alias("moretrees:spruce_planks")
	tables_chairs.register_legacy_alias("moretrees:willow_planks")
end

if core.get_modpath("ethereal") then
	tables_chairs.register_legacy_alias("ethereal:banana_wood")
	tables_chairs.register_legacy_alias("ethereal:birch_wood")
	tables_chairs.register_legacy_alias("ethereal:frost_wood")
	tables_chairs.register_legacy_alias("ethereal:mushroom_trunk")
	tables_chairs.register_legacy_alias("ethereal:palm_wood")
	tables_chairs.register_legacy_alias("ethereal:redwood_wood")
	tables_chairs.register_legacy_alias("ethereal:sakura_wood")
	tables_chairs.register_legacy_alias("ethereal:scorched_tree")
	tables_chairs.register_legacy_alias("ethereal:willow_wood")
	tables_chairs.register_legacy_alias("ethereal:yellow_wood")

	tables_chairs.register_furniture("ethereal:mushroom_trunk")
	tables_chairs.register_furniture("ethereal:scorched_tree")
end

if game == "exile" then
	local function register_furniture_exile(recipe,craft_recipe,tileside)
		for furniture, def in pairs(furnitures) do
			crafting.register_recipe({
				type="carpentry_bench",
				output = "tables_chairs:" .. recipe:sub(recipe:find(":")+1) .. "_" .. furniture,
				items = craft_recipe,
				level = 1,
				always_known = true,
			})
		end
		tables_chairs.register_furniture(recipe,core.registered_nodes[recipe].tiles[tileside])
	end
	table.insert(core.registered_on_mods_loaded, 1, function()
		register_furniture_exile("tech:wooden_floor_boards",{"group:log","tech:vegetable_oil"},1)
		register_furniture_exile("tech:wattle",{"tech:wattle"},3)
		register_furniture_exile("nodes_nature:maraka_log",{"group:log"},3)
	end)
else
	table.insert(core.registered_on_mods_loaded, 1, function()
		for k,v in pairs(core.registered_nodes) do
			if v.groups["wood"] then
				tables_chairs.register_furniture(k)
			end
		end
	end)
end
