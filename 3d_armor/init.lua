-- ======================================================================
-- 3d_armor_all — merged single-file build of the 3d_armor modpack
-- Auto-generated: all submods concatenated into one init.lua, each
-- wrapped in do...end to keep local variables from colliding.
-- Original modpack: https://github.com/minetest-mods/3d_armor
-- ======================================================================

if not core.features.use_texture_alpha_string_modes then
	error("3d_armor_all requires Luanti/Minetest 5.4.0 or newer. Please update.")
end


-- ================= 3d_armor (core) =================
do
local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local worldpath = minetest.get_worldpath()
local last_punch_time = {}
local timer = 0

armor = {
	version = "0.4.13"
}

-- inlined gamecompat.lua
-- 3d_armor defaults to support unknown games
local sounds = {
	wood = {
		footstep = { name = "armor_wood_walk", gain = 0.5 },
		dig = { name = "armor_wood_dig", gain = 0.5 },
		dug = { name = "armor_wood_walk", gain = 0.5 }
	},
	metal = {
		dig = { name = "armor_metal_dig", gain = 0.5 },
		dug = { name = "armor_metal_break", gain = 0.5 },
	},
	glass = {
		dig = { name = "armor_glass_hit", gain = 0.5 },
		dug = { name = "armor_glass_break", gain = 0.5 },
	},
}

local formspec_list_template = "list[%s;%s;%f,%f;%f,%f;%s]"
-- Allow custom slot styling
armor.add_formspec_list = function(location, listname, x, y, w, h, offset)
	return formspec_list_template:format(location, listname, x, y, w, h, tostring(offset) or "")
end


if core.get_modpath("default") then
	sounds = {
		wood  = default.node_sound_wood_defaults(),
		metal = default.node_sound_metal_defaults(),
		glass = default.node_sound_glass_defaults(),
	}
	-- armor.add_formspec_list : use formspec prepends for styling
end


-- Sanity checks
for name, def in pairs(sounds) do
	assert(type(def) == "table", "Incorrect registration of sound " .. name)
end


armor.sounds = sounds

-- inlined api.lua

--- 3D Armor API
--
--  @topic api


local transparent_armor = minetest.settings:get_bool("armor_transparent", false)


--- Tables
--
--  @section tables

--- Armor definition table used for registering armor.
--
--  @table ArmorDef
--  @tfield string description Human-readable name/description.
--  @tfield string inventory_image Image filename used for icon.
--  @tfield table groups See: `ArmorDef.groups`
--  @tfield table armor_groups See: `ArmorDef.armor_groups`
--  @tfield table damage_groups See: `ArmorDef.damage_groups`
--  @see ItemDef
--  @usage local def = {
--    description = "Wood Helmet",
--    inventory_image = "3d_armor_inv_helmet_wood.png",
--    groups = {armor_head=1, armor_heal=0, armor_use=2000, flammable=1},
--    armor_groups = {fleshy=5},
--    damage_groups = {cracky=3, snappy=2, choppy=3, crumbly=2, level=1},
--  }

--- Groups table.
--
--  General groups defining item behavior.
--
--  Some commonly used groups: ***armor\_&lt;type&gt;***, ***armor\_heal***, ***armor\_use***
--
--  @table ArmorDef.groups
--  @tfield int armor_type The armor type. "head", "torso", "hands", "shield", etc.
--  (**Note:** replace "type" with actual type).
--  @tfield int armor_heal Healing value of armor when equipped.
--  @tfield int armor_use Amount of uses/damage before armor "breaks".
--  @see groups
--  @usage groups = {
--    armor_head = 1,
--    armor_heal = 5,
--    armor_use = 2000,
--    flammable = 1,
--  }

--- Armor groups table.
--
--  Groups that this item is effective against when taking damage.
--
--  Some commonly used groups: ***fleshy***
--
--  @table ArmorDef.armor_groups
--  @usage armor_groups = {
--    fleshy = 5,
--  }

--- Damage groups table.
--
--  Groups that this item is effective on when used as a weapon/tool.
--
--  Some commonly used groups: ***cracky***, ***snappy***, ***choppy***, ***crumbly***, ***level***
--
--  @table ArmorDef.damage_groups
--  @see entity_damage_mechanism
--  @usage damage_groups = {
--    cracky = 3,
--    snappy = 2,
--    choppy = 3,
--    crumbly = 2,
--    level = 1,
--  }

--- @section end


-- support for i18n
local S = minetest.get_translator(minetest.get_current_modname())

local skin_previews = {}
local use_player_monoids = minetest.global_exists("player_monoids")
local use_armor_monoid = minetest.global_exists("armor_monoid")
local use_pova_mod = minetest.get_modpath("pova")
local armor_def = setmetatable({}, {
	__index = function()
		return setmetatable({
			groups = setmetatable({}, {
				__index = function()
					return 0
				end})
			}, {
			__index = function()
				return 0
			end
		})
	end,
})
local armor_textures = setmetatable({}, {
	__index = function()
		return setmetatable({}, {
			__index = function()
				return "blank.png"
			end
		})
	end
})

local armor_fields = {
	timer = 0,
	elements = {"head", "torso", "legs", "feet"},
	physics = {"jump", "speed", "gravity"},
	attributes = {"heal", "fire", "water", "feather"},
	formspec = (
		"image[2.5,0;2,4;armor_preview]" ..
		armor.add_formspec_list("current_player", "main", 0, 4.7, 8, 1) ..
		armor.add_formspec_list("current_player", "main", 0, 5.85, 8, 3, 8)
	),
	def = armor_def,
	textures = armor_textures,
	default_skin = "character",
	materials = {
		wood = "group:wood",
		cactus = "default:cactus",
		steel = "default:steel_ingot",
		bronze = "default:bronze_ingot",
		diamond = "default:diamond",
		gold = "default:gold_ingot",
		mithril = "moreores:mithril_ingot",
		crystal = "ethereal:crystal_ingot",
		nether = "nether:nether_ingot",
	},
	-- damage node = fire protection level required
	fire_nodes = {
		["nether:lava_source"] = 5,
		["default:lava_source"] = 5,
		["default:lava_flowing"] = 5,
		["fire:basic_flame"] = 3,
		["fire:permanent_flame"] = 3,
		["ethereal:crystal_spike"] = 2,
		["ethereal:fire_flower"] = 2,
		["nether:lava_crust"] = 2,
		["default:torch"] = 1,
		["default:torch_ceiling"] = 1,
		["default:torch_wall"] = 1,
	},
	registered_groups = {["fleshy"]=100},
	registered_callbacks = {
		on_update = {},
		on_equip = {},
		on_unequip = {},
		on_damage = {},
		on_destroy = {},
	},
	migrate_old_inventory = true,
  get_translator = S
}

for k, v in pairs(armor_fields) do
	armor[k] = v
end

armor.config = {
	init_delay = 2,
	bones_delay = 1,
	update_time = 1,
	drop = minetest.get_modpath("bones") ~= nil,
	destroy = false,
	level_multiplier = 1,
	heal_multiplier = 1,
	material_wood = true,
	material_cactus = true,
	material_steel = true,
	material_bronze = true,
	material_diamond = true,
	material_gold = true,
	material_mithril = true,
	material_crystal = true,
	material_nether = true,
	set_elements = "head torso legs feet shield",
	set_multiplier = 1.1,
	water_protect = true,
	fire_protect = minetest.settings:get_bool("armor_fire_protect") ~= false,
	fire_protect_torch = minetest.settings:get_bool("armor_fire_protect_torch"),
	feather_fall = true,
	punch_damage = true,
}


--- Methods
--
--  @section methods

--- Registers a new armor item.
--
--  @function armor:register_armor
--  @tparam string name Armor item technical name (ex: "3d\_armor:helmet\_gold").
--  @tparam ArmorDef def Armor definition table.
--  @usage armor:register_armor("3d_armor:helmet_wood", {
--    description = "Wood Helmet",
--    inventory_image = "3d_armor_inv_helmet_wood.png",
--    groups = {armor_head=1, armor_heal=0, armor_use=2000, flammable=1},
--    armor_groups = {fleshy=5},
--    damage_groups = {cracky=3, snappy=2, choppy=3, crumbly=2, level=1},
--  })
armor.register_armor = function(self, name, def)
	def.on_secondary_use = function(itemstack, player)
		return armor:equip(player, itemstack)
	end
	def.on_place = function(itemstack, player, pointed_thing)
		if pointed_thing.type == "node" and player and not player:get_player_control().sneak then
			local node = minetest.get_node(pointed_thing.under)
			local ndef = minetest.registered_nodes[node.name]
			if ndef and ndef.on_rightclick then
				return ndef.on_rightclick(pointed_thing.under, node, player, itemstack, pointed_thing)
			end
		end
		return armor:equip(player, itemstack)
	end
	-- The below is a very basic check to try and see if a material name exists as part
	-- of the item name. However this check is very simple and just checks theres "_something"
	-- at the end of the item name and logging an error to debug if not.
	local check_mat_exists = string.match(name, "%:.+_(.+)$")
	if check_mat_exists == nil then
		minetest.log("warning:[3d_armor] Registered armor "..name..
		" does not have \"_material\" specified at the end of the item registration name")
	end
	minetest.register_tool(name, def)
end

--- Registers a new armor group.
--
--  @function armor:register_armor_group
--  @tparam string group Group ID.
--  @tparam int base Base armor value.
armor.register_armor_group = function(self, group, base)
	base = base or 100
	self.registered_groups[group] = base
	if use_armor_monoid then
		armor_monoid.register_armor_group(group, base)
	end
end

--- Armor Callbacks Registration
--
--  @section callbacks

--- Registers a callback for when player visuals are update.
--
--  @function armor:register_on_update
--  @tparam function func Function to be executed.
--  @see armor:update_player_visuals
--  @usage armor:register_on_update(function(player, index, stack)
--    -- code to execute
--  end)
armor.register_on_update = function(self, func)
	if type(func) == "function" then
		table.insert(self.registered_callbacks.on_update, func)
	end
end

--- Registers a callback for when armor is equipped.
--
--  @function armor:register_on_equip
--  @tparam function func Function to be executed.
--  @usage armor:register_on_equip(function(player, index, stack)
--    -- code to execute
--  end)
armor.register_on_equip = function(self, func)
	if type(func) == "function" then
		table.insert(self.registered_callbacks.on_equip, func)
	end
end

--- Registers a callback for when armor is unequipped.
--
--  @function armor:register_on_unequip
--  @tparam function func Function to be executed.
--  @usage armor:register_on_unequip(function(player, index, stack)
--    -- code to execute
--  end)
armor.register_on_unequip = function(self, func)
	if type(func) == "function" then
		table.insert(self.registered_callbacks.on_unequip, func)
	end
end

--- Registers a callback for when armor is damaged.
--
--  @function armor:register_on_damage
--  @tparam function func Function to be executed.
--  @see armor:damage
--  @usage armor:register_on_damage(function(player, index, stack)
--    -- code to execute
--  end)
armor.register_on_damage = function(self, func)
	if type(func) == "function" then
		table.insert(self.registered_callbacks.on_damage, func)
	end
end

--- Registers a callback for when armor is destroyed.
--
--  @function armor:register_on_destroy
--  @tparam function func Function to be executed.
--  @see armor:damage
--  @usage armor:register_on_destroy(function(player, index, stack)
--    -- code to execute
--  end)
armor.register_on_destroy = function(self, func)
	if type(func) == "function" then
		table.insert(self.registered_callbacks.on_destroy, func)
	end
end

--- @section end


--- Methods
--
--  @section methods

--- Runs callbacks.
--
--  @function armor:run_callbacks
--  @tparam function callback Function to execute.
--  @tparam ObjectRef player First parameter passed to callback.
--  @tparam int index Second parameter passed to callback.
--  @tparam ItemStack stack Callback owner.
armor.run_callbacks = function(self, callback, player, index, stack)
	if stack then
		local def = stack:get_definition() or {}
		if type(def[callback]) == "function" then
			def[callback](player, index, stack)
		end
	end
	local callbacks = self.registered_callbacks[callback]
	if callbacks then
		for _, func in pairs(callbacks) do
			func(player, index, stack)
		end
	end
end

--- Updates visuals.
--
--  @function armor:update_player_visuals
--  @tparam ObjectRef player
armor.update_player_visuals = function(self, player)
	if not player then
		return
	end
	local name = player:get_player_name()
	if self.textures[name] then
		player_api.set_textures(player, {
			self.textures[name].skin,
			self.textures[name].armor,
			self.textures[name].wielditem,
		})
	end
	self:run_callbacks("on_update", player)
end

--- Sets player's armor attributes.
--
--  @function armor:set_player_armor
--  @tparam ObjectRef player
armor.set_player_armor = function(self, player)
	local name, armor_inv = self:get_valid_player(player, "[set_player_armor]")
	if not name then
		return
	end
	local state = 0
	local count = 0
	local preview = armor:get_preview(name)
	local texture = "blank.png"
	local physics = {}
	local attributes = {}
	local levels = {}
	local groups = {}
	local change = {}
	local set_worn = {}
	local armor_multi = 0
	local worn_armor = armor:get_weared_armor_elements(player)
	for _, phys in pairs(self.physics) do
		physics[phys] = 1
	end
	for _, attr in pairs(self.attributes) do
		attributes[attr] = 0
	end
	for group, _ in pairs(self.registered_groups) do
		change[group] = 1
		levels[group] = 0
	end
	local list = armor_inv:get_list("armor")
	if type(list) ~= "table" then
		return
	end
	for i, stack in pairs(list) do
		if stack:get_count() == 1 then
			local def = stack:get_definition()
			for _, element in pairs(self.elements) do
				if def.groups["armor_"..element] then
					if def.armor_groups then
						for group, level in pairs(def.armor_groups) do
							if levels[group] then
								levels[group] = levels[group] + level
							end
						end
					else
						local level = def.groups["armor_"..element]
						levels["fleshy"] = levels["fleshy"] + level
					end
					break
				end
				-- DEPRECATED, use armor_groups instead
				if def.groups["armor_radiation"] and levels["radiation"] then
					levels["radiation"] = levels["radiation"] + def.groups["armor_radiation"]
				end
			end
			local item = stack:get_name()
			local tex
			-- Allow empty texture names for convenience
			if def.texture ~= "" then
				tex = def.texture or item:gsub("%:", "_")
				tex = tex:gsub(".png$", "")
			end
			if def.preview ~= "" then
				local prev = def.preview or tex and tex.."_preview"
				if prev then
					prev = prev:gsub(".png$", "")
					preview = preview.."^"..prev..".png"
				end
			end
			if not transparent_armor and tex then
				texture = texture .. "^" .. tex .. ".png"
			end
			state = state + stack:get_wear()
			count = count + 1
			for _, phys in pairs(self.physics) do
				local value = def.groups["physics_"..phys] or 0
				physics[phys] = physics[phys] + value
			end
			for _, attr in pairs(self.attributes) do
				local value = def.groups["armor_"..attr] or 0
				attributes[attr] = attributes[attr] + value
			end
		end
	end
	-- The following code compares player worn armor items against requirements
	-- of which armor pieces are needed to be worn to meet set bonus requirements
	for loc,item in pairs(worn_armor) do
		local item_mat = string.match(item, "%:.+_(.+)$")
		local worn_key = item_mat or "unknown"

		-- Perform location checks to ensure the armor is worn correctly
		for k,set_loc in pairs(armor.config.set_elements)do
			if set_loc == loc then
				if set_worn[worn_key] == nil then
					set_worn[worn_key] = 0
					set_worn[worn_key] = set_worn[worn_key] + 1
				else
					set_worn[worn_key] = set_worn[worn_key] + 1
				end
			end
		end
	end

	-- Apply the armor multiplier only if the player is wearing a full set of armor
	for mat_name,arm_piece_num in pairs(set_worn) do
		if arm_piece_num == #armor.config.set_elements then
			armor_multi = armor.config.set_multiplier
		end
	end
	for group, level in pairs(levels) do
		if level > 0 then
			level = level * armor.config.level_multiplier
			if armor_multi ~= 0 then
				level = level * armor.config.set_multiplier
			end
		end
		local base = self.registered_groups[group]
		self.def[name].groups[group] = level
		if level > base then
			level = base
		end
		groups[group] = base - level
		change[group] = groups[group] / base
	end
	for _, attr in pairs(self.attributes) do
		local mult = attr == "heal" and self.config.heal_multiplier or 1
		self.def[name][attr] = attributes[attr] * mult
	end
	for _, phys in pairs(self.physics) do
		self.def[name][phys] = physics[phys]
	end
	if use_armor_monoid then
		armor_monoid.monoid:add_change(player, change, "3d_armor:armor")
	else
		-- Preserve immortal group (damage disabled for player)
		local player_groups = player:get_armor_groups()
		local immortal = player_groups.immortal
		if immortal and immortal ~= 0 then
			groups.immortal = 1
		end
		-- Preserve fall_damage_add_percent group (fall damage modifier)
		groups.fall_damage_add_percent = player_groups.fall_damage_add_percent
		player:set_armor_groups(groups)
	end
	if use_player_monoids then
		player_monoids.speed:add_change(player, physics.speed,
			"3d_armor:physics")
		player_monoids.jump:add_change(player, physics.jump,
			"3d_armor:physics")
		player_monoids.gravity:add_change(player, physics.gravity,
			"3d_armor:physics")
	elseif use_pova_mod then
		-- only add the changes, not the default 1.0 for each physics setting
		pova.add_override(name, "3d_armor", {
			speed = physics.speed - 1,
			jump = physics.jump - 1,
			gravity = physics.gravity - 1,
		})
		pova.do_override(player)
	else
		local player_physics_locked = player:get_meta():get_int("player_physics_locked")
		if player_physics_locked == nil or player_physics_locked == 0 then
			player:set_physics_override(physics)
		end
	end
	self.textures[name].armor = texture
	self.textures[name].preview = preview
	self.def[name].level = self.def[name].groups.fleshy or 0
	self.def[name].state = state
	self.def[name].count = count
	self:update_player_visuals(player)
end

--- Action when armor is punched.
--
--  @function armor:punch
--  @tparam ObjectRef player Player wearing the armor.
--  @tparam ObjectRef hitter Entity attacking player.
--  @tparam[opt] int time_from_last_punch Time in seconds since last punch action.
--  @tparam[opt] table tool_capabilities See `entity_damage_mechanism`.
armor.punch = function(self, player, hitter, time_from_last_punch, tool_capabilities)
	local name, armor_inv = self:get_valid_player(player, "[punch]")
	if not name then
		return
	end
	local set_state
	local set_count
	local state = 0
	local count = 0
	local recip = true
	local default_groups = {cracky=3, snappy=3, choppy=3, crumbly=3, level=1}
	local list = armor_inv:get_list("armor")
	for i, stack in pairs(list) do
		if stack:get_count() == 1 then
			local itemname = stack:get_name()
			local use = minetest.get_item_group(itemname, "armor_use") or 0
			local damage = use > 0
			local def = stack:get_definition() or {}
			if type(def.on_punched) == "function" then
				damage = def.on_punched(player, hitter, time_from_last_punch,
					tool_capabilities) ~= false and damage == true
			end
			if damage == true and tool_capabilities then
				local damage_groups = def.damage_groups or default_groups
				local level = damage_groups.level or 0
				local groupcaps = tool_capabilities.groupcaps or {}
				local uses = 0
				damage = false
				if next(groupcaps) == nil then
					damage = true
				end
				for group, caps in pairs(groupcaps) do
					local maxlevel = caps.maxlevel or 0
					local diff = maxlevel - level
					if diff == 0 then
						diff = 1
					end
					if diff > 0 and caps.times then
						local group_level = damage_groups[group]
						if group_level then
							local time = caps.times[group_level]
							if time then
								local dt = time_from_last_punch or 0
								if dt > time / diff then
									if caps.uses then
										uses = caps.uses * math.pow(3, diff)
									end
									damage = true
									break
								end
							end
						end
					end
				end
				if damage == true and recip == true and hitter and
						def.reciprocate_damage == true and uses > 0 then
					local item = hitter:get_wielded_item()
					if item and item:get_name() ~= "" then
						item:add_wear(65535 / uses)
						hitter:set_wielded_item(item)
					end
					-- reciprocate tool damage only once
					recip = false
				end
			end
			if damage == true and hitter == "fire" then
				damage = minetest.get_item_group(itemname, "flammable") > 0
			end
			if damage == true then
				self:damage(player, i, stack, use)
				set_state = self.def[name].state
				set_count = self.def[name].count
			end
			state = state + stack:get_wear()
			count = count + 1
		end
	end
	if set_count and set_count ~= count then
		state = set_state or state
		count = set_count or count
	end
	self.def[name].state = state
	self.def[name].count = count
end

--- Action when armor is damaged.
--
--  @function armor:damage
--  @tparam ObjectRef player
--  @tparam int index Inventory index where armor is equipped.
--  @tparam ItemStack stack Armor item receiving damaged.
--  @tparam int use Amount of wear to add to armor item.
armor.damage = function(self, player, index, stack, use)
	local old_stack = ItemStack(stack)
	local worn_armor = armor:get_weared_armor_elements(player)
	if not worn_armor then
		return
	end
	local armor_worn_cnt = 0
	for k,v in pairs(worn_armor) do
		armor_worn_cnt = armor_worn_cnt + 1
	end
	use = math.ceil(use/armor_worn_cnt)
	stack:add_wear(use)
	self:run_callbacks("on_damage", player, index, stack)
	self:set_inventory_stack(player, index, stack)
	if stack:get_count() == 0 then
		self:run_callbacks("on_unequip", player, index, old_stack)
		self:run_callbacks("on_destroy", player, index, old_stack)
		self:set_player_armor(player)
	end
end

--- Get elements of equipped armor.
--
--  @function armor:get_weared_armor_elements
--  @tparam ObjectRef player
--  @treturn table List of equipped armors.
armor.get_weared_armor_elements = function(self, player)
    local name, inv = self:get_valid_player(player, "[get_weared_armor]")
	local weared_armor = {}
	if not name then
		return
	end
    for i=1, inv:get_size("armor") do
        local item_name = inv:get_stack("armor", i):get_name()
        local element = self:get_element(item_name)
        if element ~= nil then
            weared_armor[element] = item_name
        end
	end
	return weared_armor
end

--- Equips a piece of armor to a player.
--
--  @function armor:equip
--  @tparam ObjectRef player Player to whom item is equipped.
--  @tparam ItemStack itemstack Armor item to be equipped.
--  @treturn ItemStack Leftover item stack.
armor.equip = function(self, player, itemstack)
    local name, armor_inv = self:get_valid_player(player, "[equip]")
    local armor_element = self:get_element(itemstack:get_name())
	if name and armor_element then
		local index, old_stack
		for i, stack in ipairs(armor_inv:get_list("armor")) do
			if self:get_element(stack:get_name()) == armor_element then
				-- prevents equiping an armor that would unequip a cursed armor.
				if minetest.get_item_group(stack:get_name(), "cursed") ~= 0 then
					return itemstack
				end
				index = i
				old_stack = stack
				self:run_callbacks("on_unequip", player, i, stack)
				break
			elseif not index and stack:is_empty() then
				index = i
			end
		end
		if not index then -- armor inventory is full with other armor elements
			return itemstack
		end
		-- Swap the stack at 'index' with 'itemstack'
		armor_inv:set_stack("armor", index, itemstack)
		self:run_callbacks("on_equip", player, index, itemstack)
		self:set_player_armor(player)
		self:save_armor_inventory(player)
		-- Remainder: the previous slot content
		return old_stack or ItemStack()
	end
	return itemstack
end

--- Unequips a piece of armor from a player.
--
--  @function armor:unequip
--  @tparam ObjectRef player Player from whom item is removed.
--  @tparam string armor_element Armor type identifier associated with the item
--  to be removed ("head", "torso", "hands", "shield", "legs", "feet", etc.).
armor.unequip = function(self, player, armor_element)
    local name, armor_inv = self:get_valid_player(player, "[unequip]")
	if not name then
		return
	end
	for i=1, armor_inv:get_size("armor") do
		local stack = armor_inv:get_stack("armor", i)
		if self:get_element(stack:get_name()) == armor_element then
			armor_inv:set_stack("armor", i, "")
			minetest.after(0, function()
				local pplayer = minetest.get_player_by_name(name)
				if pplayer then -- player is still online
					local inv = pplayer:get_inventory()
					if inv:room_for_item("main", stack) then
						inv:add_item("main", stack)
					else
						minetest.add_item(pplayer:get_pos(), stack)
					end
				end
			end)
			self:run_callbacks("on_unequip", player, i, stack)
			self:set_player_armor(player)
			self:save_armor_inventory(player)
			return
		end
	end
end

--- Removes all armor worn by player.
--
--  @function armor:remove_all
--  @tparam ObjectRef player
armor.remove_all = function(self, player)
    local name, inv = self:get_valid_player(player, "[remove_all]")
	if not name then
		return
    end
	inv:set_list("armor", {})
	self:set_player_armor(player)
	self:save_armor_inventory(player)
end

local skin_mod

--- Retrieves player's current skin.
--
--  @function armor:get_player_skin
--  @tparam string name Player name.
--  @treturn string Skin filename.
armor.get_player_skin = function(self, name)
	if (skin_mod == "skins" or skin_mod == "simple_skins") and skins.skins[name] then
		return skins.skins[name]..".png"
	elseif skin_mod == "u_skins" and u_skins.u_skins[name] then
		return u_skins.u_skins[name]..".png"
	elseif skin_mod == "wardrobe" and wardrobe.playerSkins and wardrobe.playerSkins[name] then
		return wardrobe.playerSkins[name]
	end
	return armor.default_skin..".png"
end

--- Updates skin.
--
--  @function armor:update_skin
--  @tparam string name Player name.
armor.update_skin = function(self, name)
	minetest.after(0, function()
		local pplayer = minetest.get_player_by_name(name)
		if pplayer then
			self.textures[name].skin = self:get_player_skin(name)
			self:set_player_armor(pplayer)
		end
	end)
end

--- Adds preview for armor inventory.
--
--  @function armor:add_preview
--  @tparam string preview Preview image filename.
armor.add_preview = function(self, preview)
	skin_previews[preview] = true
end

--- Retrieves preview for armor inventory.
--
--  @function armor:get_preview
--  @tparam string name Player name.
--  @treturn string Preview image filename.
armor.get_preview = function(self, name)
	local preview = string.gsub(armor:get_player_skin(name), ".png", "_preview.png")
	if skin_previews[preview] then
		return preview
	end
	return "character_preview.png"
end

--- Retrieves armor formspec.
--
--  @function armor:get_armor_formspec
--  @tparam string name Player name.
--  @tparam[opt] bool listring Use `listring` formspec element (default: `false`).
--  @treturn string Formspec formatted string.
armor.get_armor_formspec = function(self, name, listring)
	local formspec = armor.formspec..
		"list[detached:"..name.."_armor;armor;0,0.5;2,3;]"
	if listring == true then
		formspec = formspec.."listring[current_player;main]"..
			"listring[detached:"..name.."_armor;armor]"
	end
	formspec = formspec:gsub("armor_preview", armor.textures[name].preview)
	formspec = formspec:gsub("armor_level", armor.def[name].level)
	for _, attr in pairs(self.attributes) do
		formspec = formspec:gsub("armor_attr_"..attr, armor.def[name][attr])
	end
	for group, _ in pairs(self.registered_groups) do
		formspec = formspec:gsub("armor_group_"..group,
			armor.def[name].groups[group])
	end
	return formspec
end

--- Retrieves element.
--
--  @function armor:get_element
--  @tparam string item_name
--  @return Armor element.
armor.get_element = function(self, item_name)
	for _, element in pairs(armor.elements) do
		if minetest.get_item_group(item_name, "armor_"..element) > 0 then
			return element
		end
	end
end

--- Serializes armor inventory.
--
--  @function armor:serialize_inventory_list
--  @tparam table list Inventory contents.
--  @treturn string
armor.serialize_inventory_list = function(self, list)
	local list_table = {}
	for _, stack in ipairs(list) do
		table.insert(list_table, stack:to_string())
	end
	return minetest.serialize(list_table)
end

--- Deserializes armor inventory.
--
--  @function armor:deserialize_inventory_list
--  @tparam string list_string Serialized inventory contents.
--  @treturn table
armor.deserialize_inventory_list = function(self, list_string)
	local list_table = minetest.deserialize(list_string)
	local list = {}
	for _, stack in ipairs(list_table or {}) do
		table.insert(list, ItemStack(stack))
	end
	return list
end

--- Loads armor inventory.
--
--  @function armor:load_armor_inventory
--  @tparam ObjectRef player
--  @treturn bool
armor.load_armor_inventory = function(self, player)
	local _, inv = self:get_valid_player(player, "[load_armor_inventory]")
	if inv then
		local meta = player:get_meta()
		local armor_list_string = meta:get_string("3d_armor_inventory")
		if armor_list_string then
			inv:set_list("armor",
				self:deserialize_inventory_list(armor_list_string))
			return true
		end
	end
end

--- Saves armor inventory.
--
--  Inventory is stored in `PlayerMetaRef` string "3d\_armor\_inventory".
--
--  @function armor:save_armor_inventory
--  @tparam ObjectRef player
armor.save_armor_inventory = function(self, player)
	local _, inv = self:get_valid_player(player, "[save_armor_inventory]")
	if inv then
		local meta = player:get_meta()
		meta:set_string("3d_armor_inventory",
			self:serialize_inventory_list(inv:get_list("armor")))
	end
end

--- Updates inventory.
--
--  DEPRECATED: Legacy inventory support.
--
--  @function armor:update_inventory
--  @param player
armor.update_inventory = function(self, player)
	-- DEPRECATED: Legacy inventory support
end

--- Sets inventory stack.
--
--  @function armor:set_inventory_stack
--  @tparam ObjectRef player
--  @tparam int i Armor inventory index.
--  @tparam ItemStack stack Armor item.
armor.set_inventory_stack = function(self, player, i, stack)
	local _, inv = self:get_valid_player(player, "[set_inventory_stack]")
	if inv then
		inv:set_stack("armor", i, stack)
		self:save_armor_inventory(player)
	end
end

--- Checks for a player that can use armor.
--
--  @function armor:get_valid_player
--  @tparam ObjectRef player
--  @tparam string msg Additional info for log messages.
--  @treturn list Player name & armor inventory.
--  @usage local name, inv = armor:get_valid_player(player, "[equip]")
armor.get_valid_player = function(self, player, msg)
	msg = msg or ""
	if not player then
		minetest.log("warning", ("3d_armor%s: Player reference is nil"):format(msg))
		return
	end
	if type(player) ~= "userdata" then
		-- Fake player, fail silently
		return
	end
	local name = player:get_player_name()
	if not name then
		minetest.log("warning", ("3d_armor%s: Player name is nil"):format(msg))
		return
	end
	local inv = minetest.get_inventory({type="detached", name=name.."_armor"})
	if not inv then
		-- This check may fail when called inside `on_joinplayer`
		-- in that case, the armor will be initialized/updated later on
		minetest.log("warning", ("3d_armor%s: Detached armor inventory is nil"):format(msg))
		return
	end
	return name, inv
end

--- Drops armor item at given position.
--
--  @tparam vector pos
--  @tparam ItemStack stack Armor item to be dropped.
armor.drop_armor = function(pos, stack)
	local node = minetest.get_node_or_nil(pos)
	if node then
		local obj = minetest.add_item(pos, stack)
		if obj then
			obj:set_velocity({x=math.random(-1, 1), y=5, z=math.random(-1, 1)})
		end
	end
end

--- Allows skin mod to be set manually.
--
--  Useful for skin mod forks that do not use the same name.
--
--  @tparam string mod Name of skin mod. Recognized names are "simple\_skins", "u\_skins", & "wardrobe".
armor.set_skin_mod = function(mod)
	skin_mod = mod
end


-- local functions
local F = minetest.formspec_escape
local S = armor.get_translator

-- integration test omitted (merged single-file build)


-- Legacy Config Support

local input = io.open(modpath.."/armor.conf", "r")
if input then
	dofile(modpath.."/armor.conf")
	input:close()
end
input = io.open(worldpath.."/armor.conf", "r")
if input then
	dofile(worldpath.."/armor.conf")
	input:close()
end
for name, _ in pairs(armor.config) do
	local global = "ARMOR_"..name:upper()
	if minetest.global_exists(global) then
		armor.config[name] = _G[global]
	end
end
if minetest.global_exists("ARMOR_MATERIALS") then
	armor.materials = table.copy(ARMOR_MATERIALS)
end
if minetest.global_exists("ARMOR_FIRE_NODES") then
	armor.fire_nodes = table.copy(ARMOR_FIRE_NODES)
end

-- Load Configuration

for name, config in pairs(armor.config) do
	local setting = minetest.settings:get("armor_"..name)
	if type(config) == "number" then
		setting = tonumber(setting)
	elseif type(config) == "string" then
		setting = tostring(setting)
	elseif type(config) == "boolean" then
		setting = minetest.settings:get_bool("armor_"..name)
	end
	if setting ~= nil then
		armor.config[name] = setting
	end
end
for material, _ in pairs(armor.materials) do
	local key = "material_"..material
	if armor.config[key] == false then
		armor.materials[material] = nil
	end
end

-- Convert set_elements to a Lua table splitting on blank spaces
local t_set_elements = armor.config.set_elements
armor.config.set_elements = string.split(t_set_elements, " ")

-- Mod Compatibility

if minetest.get_modpath("technic") then
	armor.formspec = armor.formspec..
		"label[5,2.5;"..F(S("Radiation"))..": armor_group_radiation]"
	armor:register_armor_group("radiation")
end
local skin_mods = {"skins", "u_skins", "simple_skins", "wardrobe"}
for _, mod in pairs(skin_mods) do
	local path = minetest.get_modpath(mod)
	if path then
		local dir_list = minetest.get_dir_list(path.."/textures")
		for _, fn in pairs(dir_list) do
			if fn:find("_preview.png$") then
				armor:add_preview(fn)
			end
		end
		armor.set_skin_mod(mod)
	end
end


-- Armor Initialization

armor.formspec = armor.formspec..
	"label[5,1;"..F(S("Level"))..": armor_level]"..
	"label[5,1.5;"..F(S("Heal"))..": armor_attr_heal]"
if armor.config.fire_protect then
	armor.formspec = armor.formspec.."label[5,2;"..F(S("Fire"))..": armor_attr_fire]"
end
local players_warned = {}
armor:register_on_damage(function(player, index, stack)
	local name = player:get_player_name()
	local def = stack:get_definition()
	if name and def and def.description and stack:get_wear() > 60100 then
		local tname = name .. " " .. stack:get_name()
		if not players_warned[tname] then
			players_warned[tname] = true
			minetest.chat_send_player(name, S("Your @1 is almost broken!", def.description))
			core.after(8, function() players_warned[tname] = nil end)
		end
		minetest.sound_play("default_tool_breaks", {to_player = name, gain = 2.0}, true)
	end
end)
armor:register_on_destroy(function(player, index, stack)
	local name = player:get_player_name()
	local def = stack:get_definition()
	if name and def and def.description then
		minetest.chat_send_player(name, S("Your @1 got destroyed!", def.description))
		minetest.sound_play("default_tool_breaks", {to_player = name, gain = 2.0})
	end
end)

local function validate_armor_inventory(player)
	-- Workaround for detached inventory swap exploit
	local _, inv = armor:get_valid_player(player, "[validate_armor_inventory]")
	local pos = player:get_pos()
	if not inv then
		return
	end
	local armor_prev = {}
	local attribute_meta = player:get_meta() -- I know, the function's name is weird but let it be like that. ;)
	local armor_list_string = attribute_meta:get_string("3d_armor_inventory")
	if armor_list_string then
		local armor_list = armor:deserialize_inventory_list(armor_list_string)
		for i, stack in ipairs(armor_list) do
			if stack:get_count() > 0 then
				armor_prev[stack:get_name()] = i
			end
		end
	end
	local elements = {}
	local player_inv = player:get_inventory()
	for i = 1, 6 do
		local stack = inv:get_stack("armor", i)
		if stack:get_count() > 0 then
			local item = stack:get_name()
			local element = armor:get_element(item)
			if element and not elements[element] then
				if armor_prev[item] then
					armor_prev[item] = nil
				else
					-- Item was not in previous inventory
					armor:run_callbacks("on_equip", player, i, stack)
				end
				elements[element] = true;
			else
				inv:remove_item("armor", stack)
				minetest.item_drop(stack, player, pos)
				-- The following code returns invalid items to the player's main
				-- inventory but could open up the possibity for a hacked client
				-- to receive items back they never really had. I am not certain
				-- so remove the is_singleplayer check at your own risk :]
				if minetest.is_singleplayer() and player_inv and
						player_inv:room_for_item("main", stack) then
					player_inv:add_item("main", stack)
				end
			end
		end
	end
	for item, i in pairs(armor_prev) do
		local stack = ItemStack(item)
		-- Previous item is not in current inventory
		armor:run_callbacks("on_unequip", player, i, stack)
	end
end

local function init_player_armor(initplayer)
	local name = assert(initplayer:get_player_name())
	local armor_inv = minetest.create_detached_inventory(name.."_armor", {
		on_put = function(inv, listname, index, stack, player)
			validate_armor_inventory(player)
			armor:save_armor_inventory(player)
			armor:set_player_armor(player)
		end,
		on_take = function(inv, listname, index, stack, player)
			validate_armor_inventory(player)
			armor:save_armor_inventory(player)
			armor:set_player_armor(player)
		end,
		on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			validate_armor_inventory(player)
			armor:save_armor_inventory(player)
			armor:set_player_armor(player)
		end,
		allow_put = function(inv, listname, index, put_stack, player)
			if player:get_player_name() ~= name then
				return 0
			end
			local element = armor:get_element(put_stack:get_name())
			if not element then
				return 0
			end
			for i = 1, 6 do
				local stack = inv:get_stack("armor", i)
				local def = stack:get_definition() or {}
				if def.groups and def.groups["armor_"..element]
						and i ~= index then
					return 0
				end
			end
			return 1
		end,
		allow_take = function(inv, listname, index, stack, player)
			if player:get_player_name() ~= name then
				return 0
			end
			--cursed items cannot be unequiped by the player
			local is_cursed = minetest.get_item_group(stack:get_name(), "cursed") ~= 0
			if not minetest.is_creative_enabled(player) and is_cursed then
				return 0
			end
			return stack:get_count()
		end,
		allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			if player:get_player_name() ~= name then
				return 0
			end
			return count
		end,
	}, name)
	armor_inv:set_size("armor", 6)
	if not armor:load_armor_inventory(initplayer) and armor.migrate_old_inventory then
		local player_inv = initplayer:get_inventory()
		player_inv:set_size("armor", 6)
		for i=1, 6 do
			local stack = player_inv:get_stack("armor", i)
			armor_inv:set_stack("armor", i, stack)
		end
		armor:save_armor_inventory(initplayer)
		player_inv:set_size("armor", 0)
	end
	for i=1, 6 do
		local stack = armor_inv:get_stack("armor", i)
		if stack:get_count() > 0 then
			armor:run_callbacks("on_equip", initplayer, i, stack)
		end
	end
	armor.def[name] = {
		level = 0,
		state = 0,
		count = 0,
		groups = {},
	}
	for _, phys in pairs(armor.physics) do
		armor.def[name][phys] = 1
	end
	for _, attr in pairs(armor.attributes) do
		armor.def[name][attr] = 0
	end
	for group, _ in pairs(armor.registered_groups) do
		armor.def[name].groups[group] = 0
	end
	local skin = armor:get_player_skin(name)
	armor.textures[name] = {
		skin = skin,
		armor = "blank.png",
		wielditem = "blank.png",
		preview = armor.default_skin.."_preview.png",
	}
	local texture_path = minetest.get_modpath("player_textures")
	if texture_path then
		local dir_list = minetest.get_dir_list(texture_path.."/textures")
		for _, fn in pairs(dir_list) do
			if fn == "player_"..name..".png" then
				armor.textures[name].skin = fn
				break
			end
		end
	end
	armor:set_player_armor(initplayer)
end

-- Armor Player Model

player_api.register_model("3d_armor_character.b3d", {
	animation_speed = 30,
	textures = {
		armor.default_skin..".png",
		"blank.png",
		"blank.png",
	},
	animations = {
		stand = {x=0, y=79},
		lay = {x=162, y=166, eye_height = 0.3, override_local = true,
			collisionbox = {-0.6, 0.0, -0.6, 0.6, 0.3, 0.6}},
		walk = {x=168, y=187},
		mine = {x=189, y=198},
		walk_mine = {x=200, y=219},
		sit = {x=81, y=160, eye_height = 0.8, override_local = true,
			collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.0, 0.3}},
		-- compatibility w/ the emote mod
		wave = {x = 192, y = 196, override_local = true},
		point = {x = 196, y = 196, override_local = true},
		freeze = {x = 205, y = 205, override_local = true},
	},
	collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
	-- stepheight: use default
	eye_height = 1.47,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = armor:get_valid_player(player, "[on_player_receive_fields]")
	if not name then
		return
	end
	local player_name = player:get_player_name()
	for field, _ in pairs(fields) do
		if string.find(field, "skins_set") then
			armor:update_skin(player_name)
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	player_api.set_model(player, "3d_armor_character.b3d")
	init_player_armor(player)
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if name then
		armor.def[name] = nil
		armor.textures[name] = nil
	end
end)

if armor.config.drop == true or armor.config.destroy == true then
	minetest.register_on_dieplayer(function(player)
		local name, armor_inv = armor:get_valid_player(player, "[on_dieplayer]")
		if not name then
			return
		end
		local drop = {}
		for i=1, armor_inv:get_size("armor") do
			local stack = armor_inv:get_stack("armor", i)
			if stack:get_count() > 0 then
				--soulbound armors remain equipped after death
				if minetest.get_item_group(stack:get_name(), "soulbound") == 0 then
					table.insert(drop, stack)
					armor:run_callbacks("on_unequip", player, i, stack)
					armor_inv:set_stack("armor", i, nil)
				end
			end
		end
		armor:save_armor_inventory(player)
		armor:set_player_armor(player)
		local pos = player:get_pos()
		if pos and armor.config.destroy == false then
			minetest.after(armor.config.bones_delay, function()
				local meta = nil
				local maxp = vector.add(pos, 16)
				local minp = vector.subtract(pos, 16)
				local bones = minetest.find_nodes_in_area(minp, maxp, {"bones:bones"})
				for _, p in pairs(bones) do
					local m = minetest.get_meta(p)
					if m:get_string("owner") == name then
						meta = m
						break
					end
				end
				if meta then
					local inv = meta:get_inventory()
					for _,stack in ipairs(drop) do
						if inv:room_for_item("main", stack) then
							inv:add_item("main", stack)
						else
							armor.drop_armor(pos, stack)
						end
					end
				else
					for _,stack in ipairs(drop) do
						armor.drop_armor(pos, stack)
					end
				end
			end)
		end
	end)
	minetest.register_on_respawnplayer(function(player)
		-- reset un-dropped armor and it's effects
		armor:set_player_armor(player)
	end)
end

if armor.config.punch_damage == true then
	minetest.register_on_punchplayer(function(player, hitter,
			time_from_last_punch, tool_capabilities)
		local name = player:get_player_name()
		if hitter then
			local hit_ip = hitter and hitter:is_player()
			if name and hit_ip and minetest.is_protected(player:get_pos(), "") then
				return
			end
		end

		if name then
			armor:punch(player, hitter, time_from_last_punch, tool_capabilities)
			last_punch_time[name] = minetest.get_gametime()
		end
	end)
end

minetest.register_on_player_hpchange(function(player, hp_change, reason)
	if not minetest.is_player(player) then
		return hp_change
	end

	if reason.type == "drown" or reason.hunger or hp_change >= 0 then
		return hp_change
	end

	local name = player:get_player_name()
	local properties = player:get_properties()
	local hp = player:get_hp()
	if hp + hp_change < properties.hp_max then
		local heal = armor.def[name].heal
		if heal >= math.random(100) then
			hp_change = 0
		end
		-- check if armor damage was handled by fire or on_punchplayer
		local time = last_punch_time[name] or 0
		if time == 0 or time + 1 < minetest.get_gametime() then
			armor:punch(player)
		end
	end

	return hp_change
end, true)

minetest.register_globalstep(function(dtime)
	timer = timer + dtime

	if armor.config.feather_fall == true then
		for _,player in pairs(minetest.get_connected_players()) do
			local name = player:get_player_name()
			if armor.def[name].feather > 0 then
				local vel_y = player:get_velocity().y
				if vel_y < -0.5 then
					vel_y = -(vel_y * 0.05)
					player:add_velocity({x = 0, y = vel_y, z = 0})
				end
			end
		end
	end

	if timer <= armor.config.init_delay then
		return
	end
	timer = 0

	-- water breathing protection, added by TenPlus1
	if armor.config.water_protect == true then
		for _,player in pairs(minetest.get_connected_players()) do
			local name = player:get_player_name()
			if armor.def[name].water > 0 and
					player:get_breath() < 10 then
				player:set_breath(10)
			end
		end
	end
end)

if armor.config.fire_protect then

	if core.get_modpath("default") and armor.config.fire_protect_torch then
		-- make torches hurt
		minetest.override_item("default:torch", {damage_per_second = 1})
		minetest.override_item("default:torch_wall", {damage_per_second = 1})
		minetest.override_item("default:torch_ceiling", {damage_per_second = 1})
	end

	-- check player damage for any hot nodes we may be protected against
	minetest.register_on_player_hpchange(function(player, hp_change, reason)

		if reason.type == "node_damage" and reason.node then
			-- fire protection
			if armor.config.fire_protect and hp_change < 0 then
				local name = player:get_player_name()
				local fire_prot = armor.fire_nodes[reason.node]
				if fire_prot and armor.def[name].fire >= fire_prot then
					hp_change = 0
				end
			end
		end
		return hp_change
	end, true)
end
end

-- ================= wieldview =================
do
local time = 0
local update_time = tonumber(minetest.settings:get("wieldview_update_time"))
if not update_time then
	update_time = 2
	minetest.settings:set("wieldview_update_time", tostring(update_time))
end

wieldview = {
	wielded_item = {},
	transform = {},
}

-- inlined get_texture.lua
local f = string.format

local node_tiles = minetest.settings:get_bool("wieldview_node_tiles")
if not node_tiles then
	node_tiles = false
	minetest.settings:set("wieldview_node_tiles", "false")
end

-- https://github.com/minetest/minetest/blob/9fc018ded10225589d2559d24a5db739e891fb31/doc/lua_api.txt#L453-L462
local function escape_texture(texturestring)
	-- store in a variable so we don't return both rvs of gsub
	local v = texturestring:gsub("%^", "\\^"):gsub(":", "\\:")
	return v
end

local function memoize(func)
	local memo = {}
	return function(arg)
		if arg == nil then
			return func(arg)
		end
		local rv = memo[arg]

		if not rv then
			rv = func(arg)
			memo[arg] = rv
		end

		return rv
	end
end

local function is_vertical_frames(animation)
	return (
		animation.type == "vertical_frames" and
		animation.aspect_w and
		animation.aspect_h
	)
end

local function get_single_frame(animation, image_name)
	return ("[combine:%ix%i^[noalpha^[colorize:#FFF:255^[mask:%s"):format(
		animation.aspect_w,
		animation.aspect_h,
		image_name
	)
end

local function is_sheet_2d(animation)
	return (
		animation.type == "sheet_2d" and
		animation.frames_w and
		animation.frames_h
	)
end

local function get_sheet_2d(animation, image_name)
	return ("%s^[sheet:%ix%i:0,0"):format(
		image_name,
		animation.frames_w,
		animation.frames_h
	)
end

local get_image_from_tile = memoize(function(tile)
	if type(tile) == "string" then
		return tile

	elseif type(tile) == "table" then
		local image_name

		if type(tile.image) == "string" then
			image_name = tile.image

		elseif type(tile.name) == "string" then
			image_name = tile.name

		end

		if image_name then
			local animation = tile.animation
			if animation then
				if is_vertical_frames(animation) then
					return get_single_frame(animation, image_name)

				elseif is_sheet_2d(animation) then
					return get_sheet_2d(animation, image_name)
				end
			end

			return image_name
		end
	end

	return "blank.png"
end)

local function get_image_cube(tiles)
	if #tiles >= 6 then
		return minetest.inventorycube(
			get_image_from_tile(tiles[1] or "no_texture.png"),
			get_image_from_tile(tiles[6] or "no_texture.png"),
			get_image_from_tile(tiles[3] or "no_texture.png")
		)

	elseif #tiles == 5 then
		return minetest.inventorycube(
			get_image_from_tile(tiles[1] or "no_texture.png"),
			get_image_from_tile(tiles[5] or "no_texture.png"),
			get_image_from_tile(tiles[3] or "no_texture.png")
		)

	elseif #tiles == 4 then
		return minetest.inventorycube(
			get_image_from_tile(tiles[1] or "no_texture.png"),
			get_image_from_tile(tiles[4] or "no_texture.png"),
			get_image_from_tile(tiles[3] or "no_texture.png")
		)

	elseif #tiles == 3 then
		return minetest.inventorycube(
			get_image_from_tile(tiles[1] or "no_texture.png"),
			get_image_from_tile(tiles[3] or "no_texture.png"),
			get_image_from_tile(tiles[3] or "no_texture.png")
		)

	elseif #tiles == 2 then
		return minetest.inventorycube(
			get_image_from_tile(tiles[1] or "no_texture.png"),
			get_image_from_tile(tiles[2] or "no_texture.png"),
			get_image_from_tile(tiles[2] or "no_texture.png")
		)

	elseif #tiles == 1 then
		return minetest.inventorycube(
			get_image_from_tile(tiles[1] or "no_texture.png"),
			get_image_from_tile(tiles[1] or "no_texture.png"),
			get_image_from_tile(tiles[1] or "no_texture.png")
		)
	end

	return "blank.png"
end

local function is_normal_node(drawtype)
	return (
		drawtype == "normal" or
		drawtype == "allfaces" or
		drawtype == "allfaces_optional" or
		drawtype == "glasslike" or
		drawtype == "glasslike_framed" or
		drawtype == "glasslike_framed_optional" or
		drawtype == "liquid"
	)
end

armor.get_wield_image = memoize(function(item)
	item = ItemStack(item)

	if item:is_empty() then
		return "blank.png"
	end

	local def = item:get_definition()
	if not def then
		return "unknown_item.png"
	end

	local meta = item:get_meta()
	local color = meta:get("color") or def.color

	local image = "blank.png"

	if def.wield_image and def.wield_image ~= "" then
		local parts = {def.wield_image}
		if color then
			parts[#parts + 1] = f("[colorize:%s:alpha", escape_texture(color))
		end
		if def.wield_overlay then
			parts[#parts + 1] = def.wield_overlay
		end
		image = table.concat(parts, "^")

	elseif def.inventory_image and def.inventory_image ~= "" then
		local parts = {def.inventory_image}
		if color then
			parts[#parts + 1] = f("[colorize:%s:alpha", escape_texture(color))
		end
		if def.inventory_overlay then
			parts[#parts + 1] = def.inventory_overlay
		end
		image = table.concat(parts, "^")

	elseif def.type == "node" then
		if def.drawtype == "nodebox" or def.drawtype == "mesh" then
			image = "blank.png"

		else
			local tiles = def.tiles
			if type(tiles) == "string" then
				image = get_image_from_tile(tiles)

			elseif type(tiles) == "table" then
				if is_normal_node(def.drawtype) and node_tiles then
					image = get_image_cube(tiles)

				else
					image = get_image_from_tile(tiles[1])
				end
			end
		end
	end

	return image
end)

-- inlined transform.lua
-- Wielded Item Transformations - http://dev.minetest.net/texture

wieldview.transform = {
	["default:torch"]="R270",
	["default:sapling"]="R270",
	["flowers:dandelion_white"]="R270",
	["flowers:dandelion_yellow"]="R270",
	["flowers:geranium"]="R270",
	["flowers:rose"]="R270",
	["flowers:tulip"]="R270",
	["flowers:viola"]="R270",
	["bucket:bucket_empty"]="R270",
	["bucket:bucket_water"]="R270",
	["bucket:bucket_lava"]="R270",
	["screwdriver:screwdriver"]="R270",
	["screwdriver:screwdriver1"]="R270",
	["screwdriver:screwdriver2"]="R270",
	["screwdriver:screwdriver3"]="R270",
	["screwdriver:screwdriver4"]="R270",
	["vessels:glass_bottle"]="R270",
	["vessels:drinking_glass"]="R270",
	["vessels:steel_bottle"]="R270",
}



wieldview.get_item_texture = function(self, item)
	local texture = "blank.png"
	if item ~= "" then
		texture = armor.get_wield_image(item)

		-- Get item image transformation, first from group, then from transform.lua
		local transform = minetest.get_item_group(item, "wieldview_transform")
		if transform == 0 then
			transform = wieldview.transform[item]
		end
		if transform then
			-- This actually works with groups ratings because transform1, transform2, etc.
			-- have meaning and transform0 is used for identidy, so it can be ignored
			texture = texture.."^[transform"..tostring(transform)
		end
	end
	return texture
end

wieldview.update_wielded_item = function(self, player)
	if not player then
		return
	end
	local name = player:get_player_name()
	local stack = player:get_wielded_item()
	local item = stack:get_name()
	if not item then
		return
	end
	if self.wielded_item[name] then
		if player:get_meta():get_int("show_wielded_item") == 2 then
			item = ""
		end
		if self.wielded_item[name] == item then
			return
		end
		armor.textures[name].wielditem = self:get_item_texture(item)
		armor:update_player_visuals(player)
	end
	self.wielded_item[name] = item
end

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	wieldview.wielded_item[name] = ""
	minetest.after(0, function(pname)
		local pplayer = minetest.get_player_by_name(pname)
		if pplayer then
			wieldview:update_wielded_item(pplayer)
		end
	end, name)
end)

minetest.register_globalstep(function(dtime)
	time = time + dtime
	if time > update_time then
		for _,player in ipairs(minetest.get_connected_players()) do
			wieldview:update_wielded_item(player)
		end
		time = 0
	end
end)
end

-- ================= 3d_armor_stand =================
do
-- support for i18n
local S = minetest.get_translator(minetest.get_current_modname())

local armor_stand_formspec = "size[8,7]" ..
	armor.add_formspec_list("current_name", "main", 3, 0.5, 2, 1) ..
	armor.add_formspec_list("current_name", "main", 3, 1.5, 2, 1, 2) ..
	"image[3,0.5;1,1;3d_armor_stand_head.png]" ..
	"image[4,0.5;1,1;3d_armor_stand_torso.png]" ..
	"image[3,1.5;1,1;3d_armor_stand_legs.png]" ..
	"image[4,1.5;1,1;3d_armor_stand_feet.png]" ..
	"list[current_player;main;0,3;8,1;]" ..
	"list[current_player;main;0,4.25;8,3;8]" ..
	"listring[current_name;main]" ..
	"listring[current_player;main]"

local elements = {"head", "torso", "legs", "feet"}

local function drop_armor(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	for i = 1, 4 do
		local stack = inv:get_stack("main", i)
		if stack and stack:get_count() > 0 then
			armor.drop_armor(pos, stack)
			inv:set_stack("main", i, nil)
		end
	end
end

local function get_stand_object(pos)
	local object = nil
	local objects = minetest.get_objects_inside_radius(pos, 0.5) or {}
	for _, obj in pairs(objects) do
		local ent = obj:get_luaentity()
		if ent then
			if ent.name == ":3d_armor_stand_armor_entity" then
				-- Remove duplicates
				if object then
					obj:remove()
				else
					object = obj
				end
			end
		end
	end
	return object
end

local function update_entity(pos)
	local node = minetest.get_node(pos)
	local object = get_stand_object(pos)
	if object then
		if not string.find(node.name, "3d_armor_stand:") then
			object:remove()
			return
		end
	else
		object = minetest.add_entity(pos, ":3d_armor_stand_armor_entity")
	end
	if object then
		local texture = "blank.png"
		local textures = {}
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local yaw = 0
		if inv then
			for i, element in ipairs(elements) do
				local stack = inv:get_stack("main", i)
				if stack:get_count() == 1 then
					local item = stack:get_name() or ""
					local def = stack:get_definition() or {}
					local groups = def.groups or {}
					if groups["armor_"..element] then
						if def.texture then
							table.insert(textures, def.texture)
						else
							table.insert(textures, item:gsub("%:", "_")..".png")
						end
					end
				end
			end
		end
		if #textures > 0 then
			texture = table.concat(textures, "^")
		end
		if node.param2 then
			local rot = node.param2 % 4
			if rot == 1 then
				yaw = 3 * math.pi / 2
			elseif rot == 2 then
				yaw = math.pi
			elseif rot == 3 then
				yaw = math.pi / 2
			end
		end
		object:set_yaw(yaw)
		object:set_properties({textures={texture}})
	end
end

local function has_locked_armor_stand_privilege(meta, player)
	local name = ""
	if player then
		if minetest.check_player_privs(player, "protection_bypass") then
			return true
		end
		name = player:get_player_name()
	end
	if name ~= meta:get_string("owner") then
		return false
	end
	return true
end

local function add_hidden_node(pos, player)
	local p = {x=pos.x, y=pos.y + 1, z=pos.z}
	local name = player:get_player_name()
	local node = minetest.get_node(p)
	if node.name == "air" and not minetest.is_protected(pos, name) then
		minetest.set_node(p, {name=":3d_armor_stand_top"})
	end
end

local function remove_hidden_node(pos)
	local p = {x=pos.x, y=pos.y + 1, z=pos.z}
	local node = minetest.get_node(p)
	if node.name == ":3d_armor_stand_top" then
		minetest.remove_node(p)
	end
end

minetest.register_node(":3d_armor_stand_top", {
	description = S("Armor Stand Top"),
	paramtype = "light",
	drawtype = "plantlike",
	sunlight_propagates = true,
	walkable = true,
	pointable = false,
	diggable = false,
	buildable_to = false,
	drop = "",
	groups = {not_in_creative_inventory = 1},
	is_ground_content = false,
	on_blast = function() end,
	tiles = {"blank.png"},
})

local function register_armor_stand(def)
	local function owns_armor_stand(pos, meta, player)
		if def.name == "locked_armor_stand" and not has_locked_armor_stand_privilege(meta, player) then
			return false
		end
		local has_access = minetest.is_player(player) and not minetest.is_protected(pos, player:get_player_name())
		if def.name == "shared_armor_stand" and not has_access then
			return false
		end
		return true
	end

	minetest.register_node(":3d_armor_stand:" .. def.name, {
		description = def.description,
		drawtype = "mesh",
		mesh = "3d_armor_stand.obj",
		tiles = {def.texture},
		use_texture_alpha = "clip",
		paramtype = "light",
		paramtype2 = "facedir",
		walkable = false,
		selection_box = {
			type = "fixed",
			fixed = {
				{-0.25, -0.4375, -0.25, 0.25, 1.4, 0.25},
				{-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5},
			},
		},
		groups = {choppy=2, oddly_breakable_by_hand=2},
		is_ground_content = false,
		sounds = armor.sounds.wood,
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec", armor_stand_formspec)
			meta:set_string("infotext", def.description)
			if def.name == "locked_armor_stand" then
				meta:set_string("owner", "")
			end
			local inv = meta:get_inventory()
			inv:set_size("main", 4)
		end,
		can_dig = function(pos, player)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if not inv:is_empty("main") then
				return false
			end
			return true
		end,
		after_place_node = function(pos, placer)
			local meta = minetest.get_meta(pos)
			minetest.add_entity(pos, ":3d_armor_stand_armor_entity")
			if def.name == "locked_armor_stand" then
				meta:set_string("owner", placer:get_player_name() or "")
				meta:set_string("infotext", S("Armor Stand (owned by @1)", meta:get_string("owner")))
			elseif def.name == "shared_armor_stand" then
				meta:set_string("infotext", def.description)
			end
			add_hidden_node(pos, placer)
		end,
		allow_metadata_inventory_put = function(pos, listname, index, stack, player)
			local meta = minetest.get_meta(pos)
			if not owns_armor_stand(pos, meta, player) then
				return 0
			end
			local inv = meta:get_inventory()
			local stack_def = stack:get_definition() or {}
			local groups = stack_def.groups or {}
			for i, element in ipairs(elements) do
				if groups["armor_"..element] and inv:get_stack(listname, i):is_empty() then
					return 1
				end
			end
			return 0
		end,
		allow_metadata_inventory_take = function(pos, listname, index, stack, player)
			local meta = minetest.get_meta(pos)
			if not owns_armor_stand(pos, meta, player) then
				return 0
			end
			return 1
		end,
		allow_metadata_inventory_move = function(pos)
			return 0
		end,
		on_metadata_inventory_put = function(pos, listname, index, stack)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			local stack_def = stack:get_definition() or {}
			local groups = stack_def.groups or {}
			for i, element in ipairs(elements) do
				if groups["armor_"..element] then
					inv:set_stack(listname, i, stack)
					if index ~= i then
						inv:set_stack(listname, index, nil)
					end
					break
				end
			end
			update_entity(pos)
		end,
		on_metadata_inventory_take = function(pos)
			update_entity(pos)
		end,
		after_destruct = function(pos)
			update_entity(pos)
			remove_hidden_node(pos)
		end,
		on_blast = def.on_blast
	})
end

register_armor_stand({
	name = "armor_stand",
	description = S("Armor Stand"),
	texture = "3d_armor_stand.png",
	on_blast = function(pos)
		drop_armor(pos)
		armor.drop_armor(pos, "::3d_armor_stand_armor_stand")
		minetest.remove_node(pos)
	end
})

register_armor_stand({
	name = "locked_armor_stand",
	description = S("Locked Armor Stand"),
	texture = "3d_armor_stand_locked.png"
})

register_armor_stand({
	name = "shared_armor_stand",
	description = S("Shared Armor Stand"),
	texture = "3d_armor_stand_shared.png"
})

minetest.register_entity(":3d_armor_stand:armor_entity", {
	initial_properties = {
		physical = true,
		visual = "mesh",
		mesh = "3d_armor_entity.obj",
		visual_size = {x=1, y=1},
		collisionbox = {0,0,0,0,0,0},
		textures = {"blank.png"},
	},
	_pos = nil,
	on_activate = function(self)
		local pos = self.object:get_pos()
		if pos then
			self._pos = vector.round(pos)
			update_entity(pos)
		end
	end,
	on_blast = function(self, damage)
		local drops = {}
		local node = minetest.get_node(self._pos)
		if node.name == "::3d_armor_stand_armor_stand" then
			drop_armor(self._pos)
			self.object:remove()
		end
		return false, false, drops
	end,
})

minetest.register_abm({
	nodenames = {"::3d_armor_stand_locked", "::3d_armor_stand_shared", "::3d_armor_stand_armor_stand"},
	interval = 15,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local num
		num = #minetest.get_objects_inside_radius(pos, 0.5)
		if num > 0 then return end
		update_entity(pos)
	end
})

minetest.register_lbm({
	label = "Update armor stand inventories",
	name = ":3d_armor_stand_update_inventories",
	nodenames = {"::3d_armor_stand_locked", "::3d_armor_stand_shared", "::3d_armor_stand_armor_stand"},
	run_at_every_load = false,
	action = function(pos, node)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local lists = inv:get_lists()
		for _, element in pairs(elements) do
			if not lists["armor_"..element] then
				-- Abort to avoid item loss in case env_meta.txt is corrupted/deleted
				return
			end
		end
		inv:set_lists({main = {
			lists.armor_head[1],
			lists.armor_torso[1],
			lists.armor_legs[1],
			lists.armor_feet[1]
		}})
		meta:set_string("formspec", armor_stand_formspec)
		update_entity(pos)
	end
})

minetest.register_craft({
	output = "::3d_armor_stand_armor_stand",
	recipe = {
		{"", "group:fence", ""},
		{"", "group:fence", ""},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	}
})

minetest.register_craft({
	output = "::3d_armor_stand_locked",
	recipe = {
		{"::3d_armor_stand_armor_stand", "default:steel_ingot"},
	}
})

minetest.register_craft({
	output = "::3d_armor_stand_shared",
	recipe = {
		{"::3d_armor_stand_armor_stand", "default:copper_ingot"},
	}
})
end

-- ================= shields =================
do

--- 3D Armor Shields
--
--  @topic shields


-- support for i18n
local S = minetest.get_translator(minetest.get_current_modname())

local disable_sounds = minetest.settings:get_bool("shields_disable_sounds")
local function play_sound_effect(player, sounds, field_main, field_fallback)
	if disable_sounds or not player then
		return
	end

	local soundspec = sounds[field_main] or (field_fallback and sounds[field_fallback])
	if not soundspec then
		core.log("warning", "3d_armor: no shield sound available in " .. dump(sounds))
		return
	end

	local pos = player:get_pos()
	if pos then
		minetest.sound_play(soundspec, {
			pos = pos,
			max_hear_distance = 10,
			gain = 1.0,
		})
	end
end

-- Helper functions to play a sound in "on_damage" and "on_destroy" callbacks
local function on_damage_play_sound(sounds)
	return function(player, index, stack)
		play_sound_effect(player, sounds, "dig", "footstep")
	end
end
local function on_destroy_play_sound(sounds)
	return function(player, index, stack)
		play_sound_effect(player, sounds, "dug")
	end
end

if minetest.global_exists("armor") and armor.elements then
	table.insert(armor.elements, "shield")
end

-- Regisiter Shields

--- Admin Shield
--
--  @shield :shields_shield_admin
--  @img shields_inv_shield_admin.png
--  @grp armor_shield 1000
--  @grp armor_heal 100
--  @grp armor_use 0
--  @grp not_int_creative_inventory 1
armor:register_armor(":shields_shield_admin", {
	description = S("Admin Shield"),
	inventory_image = "shields_inv_shield_admin.png",
	groups = {armor_shield=1000, armor_heal=100, armor_use=0, not_in_creative_inventory=1},
})

minetest.register_alias("adminshield", ":shields_shield_admin")


if armor.materials.wood then
	--- Wood Shield
	--
	--  @shield :shields_shield_wood
	--  @img shields_inv_shield_wood.png
	--  @grp armor_shield 1
	--  @grp armor_heal 0
	--  @grp armor_use 2000
	--  @grp flammable 1
	--  @armorgrp fleshy 5
	--  @damagegrp cracky 3
	--  @damagegrp snappy 2
	--  @damagegrp choppy 3
	--  @damagegrp crumbly 2
	--  @damagegrp level 1
	armor:register_armor(":shields_shield_wood", {
		description = S("Wooden Shield"),
		inventory_image = "shields_inv_shield_wood.png",
		groups = {armor_shield=1, armor_heal=0, armor_use=2000, flammable=1},
		armor_groups = {fleshy=5},
		damage_groups = {cracky=3, snappy=2, choppy=3, crumbly=2, level=1},
		reciprocate_damage = true,
		on_damage  = on_damage_play_sound(armor.sounds.wood),
		on_destroy = on_destroy_play_sound(armor.sounds.wood),
	})
	--- Enhanced Wood Shield
	--
	--  @shield :shields_shield_enhanced_wood
	--  @img shields_inv_shield_enhanced_wood.png
	--  @grp armor_shield 1
	--  @grp armor_heal 0
	--  @grp armor_use 2000
	--  @armorgrp fleshy 8
	--  @damagegrp cracky 3
	--  @damagegrp snappy 2
	--  @damagegrp choppy 3
	--  @damagegrp crumbly 2
	--  @damagegrp level 2
	armor:register_armor(":shields_shield_enhanced_wood", {
		description = S("Enhanced Wood Shield"),
		inventory_image = "shields_inv_shield_enhanced_wood.png",
		groups = {armor_shield=1, armor_heal=0, armor_use=2000},
		armor_groups = {fleshy=8},
		damage_groups = {cracky=3, snappy=2, choppy=3, crumbly=2, level=2},
		reciprocate_damage = true,
		on_damage  = on_damage_play_sound(armor.sounds.metal),
		on_destroy = on_destroy_play_sound(armor.sounds.metal),
	})
	minetest.register_craft({
		output = ":shields_shield_enhanced_wood",
		recipe = {
			{"default:steel_ingot"},
			{":shields_shield_wood"},
			{"default:steel_ingot"},
		},
	})
	minetest.register_craft({
		type = "fuel",
		recipe = ":shields_shield_wood",
		burntime = 8,
	})
end

if armor.materials.cactus then
	--- Cactus Shield
	--
	--  @shield shields:shield_cactus
	--  @img shields_inv_shield_cactus.png
	--  @grp armor_shield 1
	--  @grp armor_heal 0
	--  @grp armor_use 1000
	--  @armorgrp fleshy 5
	--  @damagegrp cracky 3
	--  @damagegrp snappy 3
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 2
	--  @damagegrp level 1
	armor:register_armor(":shields_shield_cactus", {
		description = S("Cactus Shield"),
		inventory_image = "shields_inv_shield_cactus.png",
		groups = {armor_shield=1, armor_heal=0, armor_use=1000},
		armor_groups = {fleshy=5},
		damage_groups = {cracky=3, snappy=3, choppy=2, crumbly=2, level=1},
		reciprocate_damage = true,
		on_damage  = on_damage_play_sound(armor.sounds.wood),
		on_destroy = on_destroy_play_sound(armor.sounds.wood),
	})
	--- Enhanced Cactus Shield
	--
	--  @shield shields:shield_enhanced_cactus
	--  @img shields_inv_shield_enhanced_cactus.png
	--  @grp armor_shield 1
	--  @grp armor_heal 0
	--  @grp armor_use 1000
	--  @armorgrp fleshy 8
	--  @damagegrp cracky 3
	--  @damagegrp snappy 3
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 2
	--  @damagegrp level 2
	armor:register_armor(":shields_shield_enhanced_cactus", {
		description = S("Enhanced Cactus Shield"),
		inventory_image = "shields_inv_shield_enhanced_cactus.png",
		groups = {armor_shield=1, armor_heal=0, armor_use=1000},
		armor_groups = {fleshy=8},
		damage_groups = {cracky=3, snappy=3, choppy=2, crumbly=2, level=2},
		reciprocate_damage = true,
		on_damage  = on_damage_play_sound(armor.sounds.metal),
		on_destroy = on_destroy_play_sound(armor.sounds.metal),
	})
	minetest.register_craft({
		output = ":shields_shield_enhanced_cactus",
		recipe = {
			{"default:steel_ingot"},
			{":shields_shield_cactus"},
			{"default:steel_ingot"},
		},
	})
	minetest.register_craft({
		type = "fuel",
		recipe = ":shields_shield_cactus",
		burntime = 16,
	})
end

if armor.materials.steel then
	--- Steel Shield
	--
	--  @shield shields:shield_steel
	--  @img shields_inv_shield_steel.png
	--  @grp armor_shield 1
	--  @grp armor_heal 0
	--  @grp armor_use 800
	--  @grp physics_speed -0.03
	--  @grp physics_gravity 0.03
	--  @armorgrp fleshy 10
	--  @damagegrp cracky 2
	--  @damagegrp snappy 3
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 1
	--  @damagegrp level 2
	armor:register_armor(":shields_shield_steel", {
		description = S("Steel Shield"),
		inventory_image = "shields_inv_shield_steel.png",
		groups = {armor_shield=1, armor_heal=0, armor_use=800,
			physics_speed=-0.03, physics_gravity=0.03},
		armor_groups = {fleshy=10},
		damage_groups = {cracky=2, snappy=3, choppy=2, crumbly=1, level=2},
		reciprocate_damage = true,
		on_damage  = on_damage_play_sound(armor.sounds.metal),
		on_destroy = on_destroy_play_sound(armor.sounds.metal),
	})
end

if armor.materials.bronze then
	--- Bronze Shield
	--
	--  @shield shields:shield_bronze
	--  @img shields_inv_shield_bronze.png
	--  @grp armor_shield 1
	--  @grp armor_heal 6
	--  @grp armor_use 400
	--  @grp physics_speed -0.03
	--  @grp physics_gravity 0.03
	--  @armorgrp fleshy 10
	--  @damagegrp cracky 2
	--  @damagegrp snappy 3
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 1
	--  @damagegrp level 2
	armor:register_armor(":shields_shield_bronze", {
		description = S("Bronze Shield"),
		inventory_image = "shields_inv_shield_bronze.png",
		groups = {armor_shield=1, armor_heal=6, armor_use=400,
			physics_speed=-0.03, physics_gravity=0.03},
		armor_groups = {fleshy=10},
		damage_groups = {cracky=2, snappy=3, choppy=2, crumbly=1, level=2},
		reciprocate_damage = true,
		on_damage  = on_damage_play_sound(armor.sounds.metal),
		on_destroy = on_destroy_play_sound(armor.sounds.metal),
	})
end

if armor.materials.diamond then
	--- Diamond Shield
	--
	--  @shield shields:shield_diamond
	--  @img shields_inv_shield_diamond.png
	--  @grp armor_shield 1
	--  @grp armor_heal 12
	--  @grp armor_use 200
	--  @armorgrp fleshy 15
	--  @damagegrp cracky 2
	--  @damagegrp snappy 1
	--  @damagegrp choppy 1
	--  @damagegrp level 3
	armor:register_armor(":shields_shield_diamond", {
		description = S("Diamond Shield"),
		inventory_image = "shields_inv_shield_diamond.png",
		groups = {armor_shield=1, armor_heal=12, armor_use=200},
		armor_groups = {fleshy=15},
		damage_groups = {cracky=2, snappy=1, choppy=1, level=3},
		reciprocate_damage = true,
		on_damage  = on_damage_play_sound(armor.sounds.glass),
		on_destroy = on_destroy_play_sound(armor.sounds.glass),
	})
end

if armor.materials.gold then
	--- Gold Shield
	--
	--  @shield shields:shield_gold
	--  @img shields_inv_shield_gold.png
	--  @grp armor_shield 1
	--  @grp armor_heal 6
	--  @grp armor_use 300
	--  @grp physics_speed -0.04
	--  @grp physics_gravity 0.04
	--  @armorgrp fleshy 10
	--  @damagegrp cracky 1
	--  @damagegrp snappy 2
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 3
	--  @damagegrp level 2
	armor:register_armor(":shields_shield_gold", {
		description = S("Gold Shield"),
		inventory_image = "shields_inv_shield_gold.png",
		groups = {armor_shield=1, armor_heal=6, armor_use=300,
			physics_speed=-0.04, physics_gravity=0.04},
		armor_groups = {fleshy=10},
		damage_groups = {cracky=1, snappy=2, choppy=2, crumbly=3, level=2},
		reciprocate_damage = true,
		on_damage  = on_damage_play_sound(armor.sounds.metal),
		on_destroy = on_destroy_play_sound(armor.sounds.metal),
	})
end

if armor.materials.mithril then
	--- Mithril Shield
	--
	--  @shield shields:shield_mithril
	--  @img shields_inv_shield_mithril.png
	--  @grp armor_shield 1
	--  @grp armor_heal 12
	--  @grp armor_use 100
	--  @armorgrp fleshy 15
	--  @damagegrp cracky 2
	--  @damagegrp snappy 1
	--  @damagegrp level 3
	armor:register_armor(":shields_shield_mithril", {
		description = S("Mithril Shield"),
		inventory_image = "shields_inv_shield_mithril.png",
		groups = {armor_shield=1, armor_heal=13, armor_use=66},
		armor_groups = {fleshy=16},
		damage_groups = {cracky=2, snappy=1, level=3},
		reciprocate_damage = true,
		on_damage  = on_damage_play_sound(armor.sounds.glass),
		on_destroy = on_destroy_play_sound(armor.sounds.glass),
	})
end

if armor.materials.crystal then
	--- Crystal Shield
	--
	--  @shield shields:shield_crystal
	--  @img shields_inv_shield_crystal.png
	--  @grp armor_shield 1
	--  @grp armor_heal 12
	--  @grp armor_use 100
	--  @grp armor_fire 1
	--  @armorgrp fleshy 15
	--  @damagegrp cracky 2
	--  @damagegrp snappy 1
	--  @damagegrp level 3
	armor:register_armor(":shields_shield_crystal", {
		description = S("Crystal Shield"),
		inventory_image = "shields_inv_shield_crystal.png",
		groups = {armor_shield=1, armor_heal=12, armor_use=100, armor_fire=1},
		armor_groups = {fleshy=15},
		damage_groups = {cracky=2, snappy=1, level=3},
		reciprocate_damage = true,
		on_damage  = on_damage_play_sound(armor.sounds.glass),
		on_destroy = on_destroy_play_sound(armor.sounds.glass),
	})
end

if armor.materials.nether then
	--- Nether Shield
	--
	--  @shield shields:shield_nether
	--  @img shields_inv_shield_nether.png
	--  @grp armor_shield 1
	--  @grp armor_heal 17
	--  @grp armor_use 200
	--  @grp armor_fire 1
	--  @armorgrp fleshy 20
	--  @damagegrp cracky 3
	--  @damagegrp snappy 2
	--  @damagegrp level 3
	armor:register_armor(":shields_shield_nether", {
		description = S("Nether Shield"),
		inventory_image = "shields_inv_shield_nether.png",
		groups = {armor_shield=1, armor_heal=17, armor_use=200, armor_fire=1},
		armor_groups = {fleshy=20},
		damage_groups = {cracky=3, snappy=2, level=3},
		reciprocate_damage = true,
		on_damage  = on_damage_play_sound(armor.sounds.glass),
		on_destroy = on_destroy_play_sound(armor.sounds.glass),
	})
end

for k, v in pairs(armor.materials) do
	minetest.register_craft({
		output = ":shields_shield_"..k,
		recipe = {
			{v, v, v},
			{v, v, v},
			{"", v, ""},
		},
	})
end
end

-- ================= armor_admin =================
do

--- Registered armors.
--
--  @topic armor


-- support for i18n
local S = minetest.get_translator(minetest.get_current_modname())

--- Admin Helmet
--
--  @helmet 3d_armor:helmet_admin
--  @img 3d_armor_inv_helmet_admin.png
--  @grp armor_head 1
--  @grp armor_heal 100
--  @grp armor_use 0
--  @grp armor_water 1
--  @grp not_in_creative_inventory 1
--  @armorgrp fleshy 100
armor:register_armor(":3d_armor:helmet_admin", {
	description = S("Admin Helmet"),
	inventory_image = "3d_armor_inv_helmet_admin.png",
	armor_groups = {fleshy=100},
	groups = {armor_head=1, armor_heal=100, armor_use=0, armor_water=1,
			not_in_creative_inventory=1},
	on_drop = function(itemstack, dropper, pos)
		return
	end,
})

--- Admin Chestplate
--
--  @chestplate 3d_armor:chestplate_admin
--  @img 3d_armor_inv_chestplate_admin.png
--  @grp armor_torso 1
--  @grp armor_heal 100
--  @grp armor_use 0
--  @grp not_in_creative_inventory 1
--  @armorgrp fleshy 100
armor:register_armor(":3d_armor:chestplate_admin", {
	description = S("Admin Chestplate"),
	inventory_image = "3d_armor_inv_chestplate_admin.png",
	armor_groups = {fleshy=100},
	groups = {armor_torso=1, armor_heal=100, armor_use=0, armor_water=1,
			not_in_creative_inventory=1},
	on_drop = function(itemstack, dropper, pos)
		return
	end,
})

--- Admin Leggings
--
--  @leggings 3d_armor:leggings_admin
--  @img 3d_armor_inv_leggings_admin.png
--  @grp armor_legs 1
--  @grp armor_heal 100
--  @grp armor_use 0
--  @grp not_in_creative_inventory 1
--  @armorgrp fleshy 100
armor:register_armor(":3d_armor:leggings_admin", {
	description = S("Admin Leggings"),
	inventory_image = "3d_armor_inv_leggings_admin.png",
	armor_groups = {fleshy=100},
	groups = {armor_legs=1, armor_heal=100, armor_use=0, armor_water=1,
			not_in_creative_inventory=1},
	on_drop = function(itemstack, dropper, pos)
		return
	end,
})

--- Admin Boots
--
--  @boots 3d_armor:boots_admin
--  @img 3d_armor_inv_boots_admin.png
--  @grp armor_feet 1
--  @grp armor_heal 100
--  @grp armor_use 0
--  @grp not_in_creative_inventory 1
--  @armorgrp fleshy 100
armor:register_armor(":3d_armor:boots_admin", {
	description = S("Admin Boots"),
	inventory_image = "3d_armor_inv_boots_admin.png",
	armor_groups = {fleshy=100},
	groups = {armor_feet=1, armor_heal=100, armor_use=0, physics_speed=1,
			armor_water=1, not_in_creative_inventory=1},
	on_drop = function(itemstack, dropper, pos)
		return
	end,
})

minetest.register_alias("adminboots", "3d_armor:boots_admin")
minetest.register_alias("adminhelmet", "3d_armor:helmet_admin")
minetest.register_alias("adminchestplate", "3d_armor:chestplate_admin")
minetest.register_alias("adminleggings", "3d_armor:leggings_admin")
end

-- ================= armor_bronze =================
do

--- Registered armors.
--
--  @topic armor


-- support for i18n
local S = minetest.get_translator(minetest.get_current_modname())
--- Bronze
--
--  Requires setting `armor_material_bronze`.
--
--  @section bronze

if armor.materials.bronze then
	--- Bronze Helmet
	--
	--  @helmet 3d_armor:helmet_bronze
	--  @img 3d_armor_inv_helmet_bronze.png
	--  @grp armor_head 1
	--  @grp armor_heal 6
	--  @grp armor_use 400
	--  @grp physics_speed -0.01
	--  @grp physics_gravity 0.01
	--  @armorgrp fleshy 10
	--  @damagegrp cracky 3
	--  @damagegrp snappy 2
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 1
	--  @damagegrp level 2
	armor:register_armor(":3d_armor:helmet_bronze", {
		description = S("Bronze Helmet"),
		inventory_image = "3d_armor_inv_helmet_bronze.png",
		groups = {armor_head=1, armor_heal=6, armor_use=400,
			physics_speed=-0.01, physics_gravity=0.01},
		armor_groups = {fleshy=10},
		damage_groups = {cracky=3, snappy=2, choppy=2, crumbly=1, level=2},
	})
	--- Bronze Chestplate
	--
	--  @chestplate 3d_armor:chestplate_bronze
	--  @img 3d_armor_inv_chestplate_bronze.png
	--  @grp armor_torso 1
	--  @grp armor_heal 6
	--  @grp armor_use 400
	--  @grp physics_speed -0.04
	--  @grp physics_gravity 0.04
	--  @armorgrp fleshy 15
	--  @damagegrp cracky 3
	--  @damagegrp snappy 2
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 1
	--  @damagegrp level 2
	armor:register_armor(":3d_armor:chestplate_bronze", {
		description = S("Bronze Chestplate"),
		inventory_image = "3d_armor_inv_chestplate_bronze.png",
		groups = {armor_torso=1, armor_heal=6, armor_use=400,
			physics_speed=-0.04, physics_gravity=0.04},
		armor_groups = {fleshy=15},
		damage_groups = {cracky=3, snappy=2, choppy=2, crumbly=1, level=2},
	})
	--- Bronze Leggings
	--
	--  @leggings 3d_armor:leggings_bronze
	--  @img 3d_armor_inv_leggings_bronze.png
	--  @grp armor_legs 1
	--  @grp armor_heal 6
	--  @grp armor_use 400
	--  @grp physics_speed -0.03
	--  @grp physics_gravity 0.03
	--  @armorgrp fleshy 15
	--  @damagegrp cracky 3
	--  @damagegrp snappy 2
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 1
	--  @damagegrp level 2
	armor:register_armor(":3d_armor:leggings_bronze", {
		description = S("Bronze Leggings"),
		inventory_image = "3d_armor_inv_leggings_bronze.png",
		groups = {armor_legs=1, armor_heal=6, armor_use=400,
			physics_speed=-0.03, physics_gravity=0.03},
		armor_groups = {fleshy=15},
		damage_groups = {cracky=3, snappy=2, choppy=2, crumbly=1, level=2},
	})
	--- Bronze Boots
	--
	--  @boots 3d_armor:boots_bronze
	--  @img 3d_armor_inv_boots_bronze.png
	--  @grp armor_feet 1
	--  @grp armor_heal 6
	--  @grp armor_use 400
	--  @grp physics_speed -0.01
	--  @grp physics_gravity 0.01
	--  @armorgrp fleshy 10
	--  @damagegrp cracky 3
	--  @damagegrp snappy 2
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 1
	--  @damagegrp level 2
	armor:register_armor(":3d_armor:boots_bronze", {
		description = S("Bronze Boots"),
		inventory_image = "3d_armor_inv_boots_bronze.png",
		groups = {armor_feet=1, armor_heal=6, armor_use=400,
			physics_speed=-0.01, physics_gravity=0.01},
		armor_groups = {fleshy=10},
		damage_groups = {cracky=3, snappy=2, choppy=2, crumbly=1, level=2},
	})

	--- Crafting
	--
	--  @section craft

	--- Craft recipes for helmets, chestplates, leggings, boots, & shields.
	--
	--  @craft armor
	--  @usage
	--  Key:
	--  - m: material
	--    - wood:    group:wood
	--    - cactus:  default:cactus
	--    - steel:   default:steel_ingot
	--    - bronze:  default:bronze_ingot
	--    - diamond: default:diamond
	--    - gold:    default:gold_ingot
	--    - mithril: moreores:mithril_ingot
	--    - crystal: ethereal:crystal_ingot
	--    - nether:  nether:nether_ingot
	--
	--  helmet:        chestplate:    leggings:
	--  ┌───┬───┬───┐  ┌───┬───┬───┐  ┌───┬───┬───┐
	--  │ m │ m │ m │  │ m │   │ m │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │ m │ m │ m │  │ m │   │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤  ├───┼───┼───┤
	--  │   │   │   │  │ m │ m │ m │  │ m │   │ m │
	--  └───┴───┴───┘  └───┴───┴───┘  └───┴───┴───┘
	--
	--  boots:         shield:
	--  ┌───┬───┬───┐  ┌───┬───┬───┐
	--  │   │   │   │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │   │ m │   │
	--  └───┴───┴───┘  └───┴───┴───┘

	local s = "bronze"
	local m = armor.materials.bronze
	minetest.register_craft({
		output = "3d_armor:helmet_"..s,
		recipe = {
			{m, m, m},
			{m, "", m},
			{"", "", ""},
		},
	})
	minetest.register_craft({
		output = "3d_armor:chestplate_"..s,
		recipe = {
			{m, "", m},
			{m, m, m},
			{m, m, m},
		},
	})
	minetest.register_craft({
		output = "3d_armor:leggings_"..s,
		recipe = {
			{m, m, m},
			{m, "", m},
			{m, "", m},
		},
	})
	minetest.register_craft({
		output = "3d_armor:boots_"..s,
		recipe = {
			{m, "", m},
			{m, "", m},
		},
	})
end
end

-- ================= armor_cactus =================
do

--- Registered armors.
--
--  @topic armor


-- support for i18n
local S = minetest.get_translator(minetest.get_current_modname())

--- Cactus
--
--  Requires setting `armor_material_cactus`.
--
--  @section cactus

if armor.materials.cactus then
	--- Cactus Helmet
	--
	--  @helmet 3d_armor:helmet_cactus
	--  @img 3d_armor_inv_helmet_cactus.png
	--  @grp armor_head 1
	--  @grp armor_heal 0
	--  @grp armor_use 1000
	--  @armorgrp fleshy 5
	--  @damagegrp cracky 3
	--  @damagegrp snappy 3
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 2
	--  @damagegrp level 1
	armor:register_armor(":3d_armor:helmet_cactus", {
		description = S("Cactus Helmet"),
		inventory_image = "3d_armor_inv_helmet_cactus.png",
		groups = {armor_head=1, armor_heal=0, armor_use=1000},
		armor_groups = {fleshy=5},
		damage_groups = {cracky=3, snappy=3, choppy=2, crumbly=2, level=1},
	})
	--- Cactus Chestplate
	--
	--  @chestplate 3d_armor:chestplate_cactus
	--  @img 3d_armor_inv_chestplate_cactus.png
	--  @grp armor_torso 1
	--  @grp armor_heal 0
	--  @grp armor_use 1000
	--  @armorgrp fleshy 10
	--  @damagegrp cracky 3
	--  @damagegrp snappy 3
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 2
	--  @damagegrp level 1
	armor:register_armor(":3d_armor:chestplate_cactus", {
		description = S("Cactus Chestplate"),
		inventory_image = "3d_armor_inv_chestplate_cactus.png",
		groups = {armor_torso=1, armor_heal=0, armor_use=1000},
		armor_groups = {fleshy=10},
		damage_groups = {cracky=3, snappy=3, choppy=2, crumbly=2, level=1},
	})
	--- Cactus Leggings
	--
	--  @leggings 3d_armor:leggings_cactus
	--  @img 3d_armor_inv_leggings_cactus.png
	--  @grp armor_legs 1
	--  @grp armor_heal 0
	--  @grp armor_use 1000
	--  @armorgrp fleshy 10
	--  @damagegrp cracky 3
	--  @damagegrp snappy 3
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 2
	--  @damagegrp level 1
	armor:register_armor(":3d_armor:leggings_cactus", {
		description = S("Cactus Leggings"),
		inventory_image = "3d_armor_inv_leggings_cactus.png",
		groups = {armor_legs=1, armor_heal=0, armor_use=1000},
		armor_groups = {fleshy=10},
		damage_groups = {cracky=3, snappy=3, choppy=2, crumbly=2, level=1},
	})
	--- Cactus Boots
	--
	--  @boots 3d_armor:boots_cactus
	--  @img 3d_armor_inv_boots_cactus.png
	--  @grp armor_feet 1
	--  @grp armor_heal 0
	--  @grp armor_use 1000
	--  @armorgrp fleshy 5
	--  @damagegrp cracky 3
	--  @damagegrp snappy 3
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 2
	--  @damagegrp level 1
	armor:register_armor(":3d_armor:boots_cactus", {
		description = S("Cactus Boots"),
		inventory_image = "3d_armor_inv_boots_cactus.png",
		groups = {armor_feet=1, armor_heal=0, armor_use=1000},
		armor_groups = {fleshy=5},
		damage_groups = {cracky=3, snappy=3, choppy=2, crumbly=2, level=1},
	})
	local cactus_armor_fuel = {
		helmet = 14,
		chestplate = 16,
		leggings = 15,
		boots = 13
	}
	for armor, burn in pairs(cactus_armor_fuel) do
		minetest.register_craft({
			type = "fuel",
			recipe = "3d_armor:" .. armor .. "_cactus",
			burntime = burn,
		})
	end


	--- Crafting
	--
	--  @section craft

	--- Craft recipes for helmets, chestplates, leggings, boots, & shields.
	--
	--  @craft armor
	--  @usage
	--  Key:
	--  - m: material
	--    - wood:    group:wood
	--    - cactus:  default:cactus
	--    - steel:   default:steel_ingot
	--    - bronze:  default:bronze_ingot
	--    - diamond: default:diamond
	--    - gold:    default:gold_ingot
	--    - mithril: moreores:mithril_ingot
	--    - crystal: ethereal:crystal_ingot
	--    - nether:  nether:nether_ingot
	--
	--  helmet:        chestplate:    leggings:
	--  ┌───┬───┬───┐  ┌───┬───┬───┐  ┌───┬───┬───┐
	--  │ m │ m │ m │  │ m │   │ m │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │ m │ m │ m │  │ m │   │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤  ├───┼───┼───┤
	--  │   │   │   │  │ m │ m │ m │  │ m │   │ m │
	--  └───┴───┴───┘  └───┴───┴───┘  └───┴───┴───┘
	--
	--  boots:         shield:
	--  ┌───┬───┬───┐  ┌───┬───┬───┐
	--  │   │   │   │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │   │ m │   │
	--  └───┴───┴───┘  └───┴───┴───┘

	local s = "cactus"
	local m = armor.materials.cactus
	minetest.register_craft({
		output = "3d_armor:helmet_"..s,
		recipe = {
			{m, m, m},
			{m, "", m},
			{"", "", ""},
		},
	})
	minetest.register_craft({
		output = "3d_armor:chestplate_"..s,
		recipe = {
			{m, "", m},
			{m, m, m},
			{m, m, m},
		},
	})
	minetest.register_craft({
		output = "3d_armor:leggings_"..s,
		recipe = {
			{m, m, m},
			{m, "", m},
			{m, "", m},
		},
	})
	minetest.register_craft({
		output = "3d_armor:boots_"..s,
		recipe = {
			{m, "", m},
			{m, "", m},
		},
	})
end
end

-- ================= armor_crystal =================
do

--- Registered armors.
--
--  @topic armor


-- support for i18n
local S = minetest.get_translator(minetest.get_current_modname())

--- Crystal
--
--  Requires `armor_material_crystal`.
--
--  @section crystal

if armor.materials.crystal then
	--- Crystal Helmet
	--
	--  @helmet 3d_armor:helmet_crystal
	--  @img 3d_armor_inv_helmet_crystal.png
	--  @grp armor_head 1
	--  @grp armor_heal 12
	--  @grp armor_use 100
	--  @grp armor_fire 1
	--  @armorgrp fleshy 15
	--  @damagegrp cracky 2
	--  @damagegrp snappy 1
	--  @damagegrp level 3
	armor:register_armor(":3d_armor:helmet_crystal", {
		description = S("Crystal Helmet"),
		inventory_image = "3d_armor_inv_helmet_crystal.png",
		groups = {armor_head=1, armor_heal=12, armor_use=100, armor_fire=1},
		armor_groups = {fleshy=15},
		damage_groups = {cracky=2, snappy=1, level=3},
	})
	--- Crystal Chestplate
	--
	--  @chestplate 3d_armor:chestplate_crystal
	--  @img 3d_armor_inv_chestplate_crystal.png
	--  @grp armor_torso 1
	--  @grp armor_heal 12
	--  @grp armor_use 100
	--  @grp armor_fire 1
	--  @armorgrp fleshy 20
	--  @damagegrp cracky 2
	--  @damagegrp snappy 1
	--  @damagegrp level 3
	armor:register_armor(":3d_armor:chestplate_crystal", {
		description = S("Crystal Chestplate"),
		inventory_image = "3d_armor_inv_chestplate_crystal.png",
		groups = {armor_torso=1, armor_heal=12, armor_use=100, armor_fire=1},
		armor_groups = {fleshy=20},
		damage_groups = {cracky=2, snappy=1, level=3},
	})
	--- Crystal Leggings
	--
	--  @leggings 3d_armor:leggings_crystal
	--  @img 3d_armor_inv_leggings_crystal.png
	--  @grp armor_legs 1
	--  @grp armor_heal 12
	--  @grp armor_use 100
	--  @grp armor_fire 1
	--  @armorgrp fleshy 20
	--  @damagegrp cracky 2
	--  @damagegrp snappy 1
	--  @damagegrp level 3
	armor:register_armor(":3d_armor:leggings_crystal", {
		description = S("Crystal Leggings"),
		inventory_image = "3d_armor_inv_leggings_crystal.png",
		groups = {armor_legs=1, armor_heal=12, armor_use=100, armor_fire=1},
		armor_groups = {fleshy=20},
		damage_groups = {cracky=2, snappy=1, level=3},
	})
	--- Crystal Boots
	--
	--  @boots 3d_armor:boots_crystal
	--  @img 3d_armor_inv_boots_crystal.png
	--  @grp armor_feet 1
	--  @grp armor_heal 12
	--  @grp armor_use 100
	--  @grp physics_speed 1
	--  @grp physics_jump 0.5
	--  @grp armor_fire 1
	--  @armorgrp fleshy 15
	--  @damagegrp cracky 2
	--  @damagegrp snappy 1
	--  @damagegrp level 3
	armor:register_armor(":3d_armor:boots_crystal", {
		description = S("Crystal Boots"),
		inventory_image = "3d_armor_inv_boots_crystal.png",
		groups = {armor_feet=1, armor_heal=12, armor_use=100, physics_speed=1,
				physics_jump=0.5, armor_fire=1},
		armor_groups = {fleshy=15},
		damage_groups = {cracky=2, snappy=1, level=3},
	})


	--- Crafting
	--
	--  @section craft

	--- Craft recipes for helmets, chestplates, leggings, boots, & shields.
	--
	--  @craft armor
	--  @usage
	--  Key:
	--  - m: material
	--    - wood:    group:wood
	--    - cactus:  default:cactus
	--    - steel:   default:steel_ingot
	--    - bronze:  default:bronze_ingot
	--    - diamond: default:diamond
	--    - gold:    default:gold_ingot
	--    - mithril: moreores:mithril_ingot
	--    - crystal: ethereal:crystal_ingot
	--    - nether:  nether:nether_ingot
	--
	--  helmet:        chestplate:    leggings:
	--  ┌───┬───┬───┐  ┌───┬───┬───┐  ┌───┬───┬───┐
	--  │ m │ m │ m │  │ m │   │ m │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │ m │ m │ m │  │ m │   │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤  ├───┼───┼───┤
	--  │   │   │   │  │ m │ m │ m │  │ m │   │ m │
	--  └───┴───┴───┘  └───┴───┴───┘  └───┴───┴───┘
	--
	--  boots:         shield:
	--  ┌───┬───┬───┐  ┌───┬───┬───┐
	--  │   │   │   │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │   │ m │   │
	--  └───┴───┴───┘  └───┴───┴───┘

	local s = "crystal"
	local m = armor.materials.crystal
	minetest.register_craft({
		output = "3d_armor:helmet_"..s,
		recipe = {
			{m, m, m},
			{m, "", m},
			{"", "", ""},
		},
	})
	minetest.register_craft({
		output = "3d_armor:chestplate_"..s,
		recipe = {
			{m, "", m},
			{m, m, m},
			{m, m, m},
		},
	})
	minetest.register_craft({
		output = "3d_armor:leggings_"..s,
		recipe = {
			{m, m, m},
			{m, "", m},
			{m, "", m},
		},
	})
	minetest.register_craft({
		output = "3d_armor:boots_"..s,
		recipe = {
			{m, "", m},
			{m, "", m},
		},
	})
end
end

-- ================= armor_diamond =================
do

--- Registered armors.
--
--  @topic armor


-- support for i18n
local S = minetest.get_translator(minetest.get_current_modname())

--- Diamond
--
--  Requires setting `armor_material_diamond`.
--
--  @section diamond

if armor.materials.diamond then
	--- Diamond Helmet
	--
	--  @helmet 3d_armor:helmet_diamond
	--  @img 3d_armor_inv_helmet_diamond.png
	--  @grp armor_head 1
	--  @grp armor_heal 12
	--  @grp armor_use 200
	--  @armorgrp fleshy 15
	--  @damagegrp cracky 2
	--  @damagegrp snappy 1
	--  @damagegrp choppy 1
	--  @damagegrp level 3
	armor:register_armor(":3d_armor:helmet_diamond", {
		description = S("Diamond Helmet"),
		inventory_image = "3d_armor_inv_helmet_diamond.png",
		groups = {armor_head=1, armor_heal=12, armor_use=200},
		armor_groups = {fleshy=15},
		damage_groups = {cracky=2, snappy=1, choppy=1, level=3},
	})
	--- Diamond Chestplate
	--
	--  @chestplate 3d_armor:chestplate_diamond
	--  @img 3d_armor_inv_chestplate_diamond.png
	--  @grp armor_torso 1
	--  @grp armor_heal 12
	--  @grp armor_use 200
	--  @armorgrp fleshy 20
	--  @damagegrp cracky 2
	--  @damagegrp snappy 1
	--  @damagegrp choppy 1
	--  @damagegrp level 3
	armor:register_armor(":3d_armor:chestplate_diamond", {
		description = S("Diamond Chestplate"),
		inventory_image = "3d_armor_inv_chestplate_diamond.png",
		groups = {armor_torso=1, armor_heal=12, armor_use=200},
		armor_groups = {fleshy=20},
		damage_groups = {cracky=2, snappy=1, choppy=1, level=3},
	})
	--- Diamond Leggings
	--
	--  @leggings 3d_armor:leggings_diamond
	--  @img 3d_armor_inv_leggings_diamond.png
	--  @grp armor_legs 1
	--  @grp armor_heal 12
	--  @grp armor_use 200
	--  @armorgrp fleshy 20
	--  @damagegrp cracky 2
	--  @damagegrp snappy 1
	--  @damagegrp choppy 1
	--  @damagegrp level 3
	armor:register_armor(":3d_armor:leggings_diamond", {
		description = S("Diamond Leggings"),
		inventory_image = "3d_armor_inv_leggings_diamond.png",
		groups = {armor_legs=1, armor_heal=12, armor_use=200},
		armor_groups = {fleshy=20},
		damage_groups = {cracky=2, snappy=1, choppy=1, level=3},
	})
	--- Diamond Boots
	--
	--  @boots 3d_armor:boots_diamond
	--  @img 3d_armor_inv_boots_diamond.png
	--  @grp armor_feet 1
	--  @grp armor_heal 12
	--  @grp armor_use 200
	--  @armorgrp fleshy 15
	--  @damagegrp cracky 2
	--  @damagegrp snappy 1
	--  @damagegrp choppy 1
	--  @damagegrp level 3
	armor:register_armor(":3d_armor:boots_diamond", {
		description = S("Diamond Boots"),
		inventory_image = "3d_armor_inv_boots_diamond.png",
		groups = {armor_feet=1, armor_heal=12, armor_use=200},
		armor_groups = {fleshy=15},
		damage_groups = {cracky=2, snappy=1, choppy=1, level=3},
	})


	--- Crafting
	--
	--  @section craft

	--- Craft recipes for helmets, chestplates, leggings, boots, & shields.
	--
	--  @craft armor
	--  @usage
	--  Key:
	--  - m: material
	--    - wood:    group:wood
	--    - cactus:  default:cactus
	--    - steel:   default:steel_ingot
	--    - bronze:  default:bronze_ingot
	--    - diamond: default:diamond
	--    - gold:    default:gold_ingot
	--    - mithril: moreores:mithril_ingot
	--    - crystal: ethereal:crystal_ingot
	--    - nether:  nether:nether_ingot
	--
	--  helmet:        chestplate:    leggings:
	--  ┌───┬───┬───┐  ┌───┬───┬───┐  ┌───┬───┬───┐
	--  │ m │ m │ m │  │ m │   │ m │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │ m │ m │ m │  │ m │   │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤  ├───┼───┼───┤
	--  │   │   │   │  │ m │ m │ m │  │ m │   │ m │
	--  └───┴───┴───┘  └───┴───┴───┘  └───┴───┴───┘
	--
	--  boots:         shield:
	--  ┌───┬───┬───┐  ┌───┬───┬───┐
	--  │   │   │   │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │   │ m │   │
	--  └───┴───┴───┘  └───┴───┴───┘

	local s = "diamond"
	local m = armor.materials.diamond
	minetest.register_craft({
		output = "3d_armor:helmet_"..s,
		recipe = {
			{m, m, m},
			{m, "", m},
			{"", "", ""},
		},
	})
	minetest.register_craft({
		output = "3d_armor:chestplate_"..s,
		recipe = {
			{m, "", m},
			{m, m, m},
			{m, m, m},
		},
	})
	minetest.register_craft({
		output = "3d_armor:leggings_"..s,
		recipe = {
			{m, m, m},
			{m, "", m},
			{m, "", m},
		},
	})
	minetest.register_craft({
		output = "3d_armor:boots_"..s,
		recipe = {
			{m, "", m},
			{m, "", m},
		},
	})
end
end

-- ================= armor_gold =================
do

--- Registered armors.
--
--  @topic armor


-- support for i18n
local S = minetest.get_translator(minetest.get_current_modname())


--- Gold
--
--  Requires `armor_material_gold`.
--
--  @section gold

if armor.materials.gold then
	--- Gold Helmet
	--
	--  @helmet 3d_armor:helmet_gold
	--  @img 3d_armor_inv_helmet_gold.png
	--  @grp armor_head 1
	--  @grp armor_heal 6
	--  @grp armor_use 300
	--  @grp physics_speed -0.02
	--  @grp physics_gravity 0.02
	--  @armorgrp fleshy 10
	--  @damagegrp cracky 1
	--  @damagegrp snappy 2
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 3
	--  @damagegrp level 2
	armor:register_armor(":3d_armor:helmet_gold", {
		description = S("Gold Helmet"),
		inventory_image = "3d_armor_inv_helmet_gold.png",
		groups = {armor_head=1, armor_heal=6, armor_use=300,
			physics_speed=-0.02, physics_gravity=0.02},
		armor_groups = {fleshy=10},
		damage_groups = {cracky=1, snappy=2, choppy=2, crumbly=3, level=2},
	})
	--- Gold Chestplate
	--
	--  @chestplate 3d_armor:chestplate_gold
	--  @img 3d_armor_inv_chestplate_gold.png
	--  @grp armor_torso 1
	--  @grp armor_heal 6
	--  @grp armor_use 300
	--  @grp physics_speed -0.05
	--  @grp physics_gravity 0.05
	--  @armorgrp fleshy 15
	--  @damagegrp cracky 1
	--  @damagegrp snappy 2
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 3
	--  @damagegrp level 2
	armor:register_armor(":3d_armor:chestplate_gold", {
		description = S("Gold Chestplate"),
		inventory_image = "3d_armor_inv_chestplate_gold.png",
		groups = {armor_torso=1, armor_heal=6, armor_use=300,
			physics_speed=-0.05, physics_gravity=0.05},
		armor_groups = {fleshy=15},
		damage_groups = {cracky=1, snappy=2, choppy=2, crumbly=3, level=2},
	})
	--- Gold Leggings
	--
	--  @leggings 3d_armor:leggings_gold
	--  @img 3d_armor_inv_leggings_gold.png
	--  @grp armor_legs 1
	--  @grp armor_heal 6
	--  @grp armor_use 300
	--  @grp physics_speed -0.04
	--  @grp physics_gravity 0.04
	--  @armorgrp fleshy 15
	--  @damagegrp cracky 1
	--  @damagegrp snappy 2
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 3
	--  @damagegrp level 2
	armor:register_armor(":3d_armor:leggings_gold", {
		description = S("Gold Leggings"),
		inventory_image = "3d_armor_inv_leggings_gold.png",
		groups = {armor_legs=1, armor_heal=6, armor_use=300,
			physics_speed=-0.04, physics_gravity=0.04},
		armor_groups = {fleshy=15},
		damage_groups = {cracky=1, snappy=2, choppy=2, crumbly=3, level=2},
	})
	--- Gold Boots
	--
	--  @boots 3d_armor:boots_gold
	--  @img 3d_armor_inv_boots_gold.png
	--  @grp armor_feet 1
	--  @grp armor_heal 6
	--  @grp armor_use 300
	--  @grp physics_speed -0.02
	--  @grp physics_gravity 0.02
	--  @armorgrp fleshy 10
	--  @damagegrp cracky 1
	--  @damagegrp snappy 2
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 3
	--  @damagegrp level 2
	armor:register_armor(":3d_armor:boots_gold", {
		description = S("Gold Boots"),
		inventory_image = "3d_armor_inv_boots_gold.png",
		groups = {armor_feet=1, armor_heal=6, armor_use=300,
			physics_speed=-0.02, physics_gravity=0.02},
		armor_groups = {fleshy=10},
		damage_groups = {cracky=1, snappy=2, choppy=2, crumbly=3, level=2},
	})


	--- Crafting
	--
	--  @section craft

	--- Craft recipes for helmets, chestplates, leggings, boots, & shields.
	--
	--  @craft armor
	--  @usage
	--  Key:
	--  - m: material
	--    - wood:    group:wood
	--    - cactus:  default:cactus
	--    - steel:   default:steel_ingot
	--    - bronze:  default:bronze_ingot
	--    - diamond: default:diamond
	--    - gold:    default:gold_ingot
	--    - mithril: moreores:mithril_ingot
	--    - crystal: ethereal:crystal_ingot
	--    - nether:  nether:nether_ingot
	--
	--  helmet:        chestplate:    leggings:
	--  ┌───┬───┬───┐  ┌───┬───┬───┐  ┌───┬───┬───┐
	--  │ m │ m │ m │  │ m │   │ m │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │ m │ m │ m │  │ m │   │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤  ├───┼───┼───┤
	--  │   │   │   │  │ m │ m │ m │  │ m │   │ m │
	--  └───┴───┴───┘  └───┴───┴───┘  └───┴───┴───┘
	--
	--  boots:         shield:
	--  ┌───┬───┬───┐  ┌───┬───┬───┐
	--  │   │   │   │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │   │ m │   │
	--  └───┴───┴───┘  └───┴───┴───┘

	local s = "gold"
	local m = armor.materials.gold
	minetest.register_craft({
		output = "3d_armor:helmet_"..s,
		recipe = {
			{m, m, m},
			{m, "", m},
			{"", "", ""},
		},
	})
	minetest.register_craft({
		output = "3d_armor:chestplate_"..s,
		recipe = {
			{m, "", m},
			{m, m, m},
			{m, m, m},
		},
	})
	minetest.register_craft({
		output = "3d_armor:leggings_"..s,
		recipe = {
			{m, m, m},
			{m, "", m},
			{m, "", m},
		},
	})
	minetest.register_craft({
		output = "3d_armor:boots_"..s,
		recipe = {
			{m, "", m},
			{m, "", m},
		},
	})
end
end

-- ================= armor_mithril =================
do

--- Registered armors.
--
--  @topic armor


-- support for i18n
local S = minetest.get_translator(minetest.get_current_modname())

--- Mithril
--
--  Requires `armor_material_mithril`.
--
--  @section mithril

if armor.materials.mithril then
	--- Mithril Helmet
	--
	--  @helmet 3d_armor:helmet_mithril
	--  @img 3d_armor_inv_helmet_mithril.png
	--  @grp armor_head 1
	--  @grp armor_heal 12
	--  @grp armor_use 100
	--  @armorgrp fleshy 15
	--  @damagegrp cracky 2
	--  @damagegrp snappy 1
	--  @damagegrp level 3
	armor:register_armor(":3d_armor:helmet_mithril", {
		description = S("Mithril Helmet"),
		inventory_image = "3d_armor_inv_helmet_mithril.png",
		groups = {armor_head=1, armor_heal=13, armor_use=66},
		armor_groups = {fleshy=16},
		damage_groups = {cracky=2, snappy=1, level=3},
	})
	--- Mithril Chestplate
	--
	--  @chestplate 3d_armor:chestplate_mithril
	--  @img 3d_armor_inv_chestplate_mithril.png
	--  @grp armor_torso 1
	--  @grp armor_heal 12
	--  @grp armor_use 100
	--  @armorgrp fleshy 20
	--  @damagegrp cracky 2
	--  @damagegrp snappy 1
	--  @damagegrp level 3
	armor:register_armor(":3d_armor:chestplate_mithril", {
		description = S("Mithril Chestplate"),
		inventory_image = "3d_armor_inv_chestplate_mithril.png",
		groups = {armor_torso=1, armor_heal=13, armor_use=66},
		armor_groups = {fleshy=21},
		damage_groups = {cracky=2, snappy=1, level=3},
	})
	--- Mithril Leggings
	--
	--  @leggings 3d_armor:leggings_mithril
	--  @img 3d_armor_inv_leggings_mithril.png
	--  @grp armor_legs 1
	--  @grp armor_heal 12
	--  @grp armor_use 100
	--  @armorgrp fleshy 20
	--  @damagegrp cracky 2
	--  @damagegrp snappy 1
	--  @damagegrp level 3
	armor:register_armor(":3d_armor:leggings_mithril", {
		description = S("Mithril Leggings"),
		inventory_image = "3d_armor_inv_leggings_mithril.png",
		groups = {armor_legs=1, armor_heal=13, armor_use=66},
		armor_groups = {fleshy=21},
		damage_groups = {cracky=2, snappy=1, level=3},
	})
	--- Mithril Boots
	--
	--  @boots 3d_armor:boots_mithril
	--  @img 3d_armor_inv_boots_mithril.png
	--  @grp armor_feet 1
	--  @grp armor_heal 12
	--  @grp armor_use 100
	--  @armorgrp fleshy 15
	--  @damagegrp cracky 2
	--  @damagegrp snappy 1
	--  @damagegrp level 3
	armor:register_armor(":3d_armor:boots_mithril", {
		description = S("Mithril Boots"),
		inventory_image = "3d_armor_inv_boots_mithril.png",
		groups = {armor_feet=1, armor_heal=13, armor_use=66},
		armor_groups = {fleshy=16},
		damage_groups = {cracky=2, snappy=1, level=3},
	})


	--- Crafting
	--
	--  @section craft

	--- Craft recipes for helmets, chestplates, leggings, boots, & shields.
	--
	--  @craft armor
	--  @usage
	--  Key:
	--  - m: material
	--    - wood:    group:wood
	--    - cactus:  default:cactus
	--    - steel:   default:steel_ingot
	--    - bronze:  default:bronze_ingot
	--    - diamond: default:diamond
	--    - gold:    default:gold_ingot
	--    - mithril: moreores:mithril_ingot
	--    - crystal: ethereal:crystal_ingot
	--    - nether:  nether:nether_ingot
	--
	--  helmet:        chestplate:    leggings:
	--  ┌───┬───┬───┐  ┌───┬───┬───┐  ┌───┬───┬───┐
	--  │ m │ m │ m │  │ m │   │ m │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │ m │ m │ m │  │ m │   │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤  ├───┼───┼───┤
	--  │   │   │   │  │ m │ m │ m │  │ m │   │ m │
	--  └───┴───┴───┘  └───┴───┴───┘  └───┴───┴───┘
	--
	--  boots:         shield:
	--  ┌───┬───┬───┐  ┌───┬───┬───┐
	--  │   │   │   │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │   │ m │   │
	--  └───┴───┴───┘  └───┴───┴───┘

	local s = "mithril"
	local m = armor.materials.mithril
	minetest.register_craft({
		output = "3d_armor:helmet_"..s,
		recipe = {
			{m, m, m},
			{m, "", m},
			{"", "", ""},
		},
	})
	minetest.register_craft({
		output = "3d_armor:chestplate_"..s,
		recipe = {
			{m, "", m},
			{m, m, m},
			{m, m, m},
		},
	})
	minetest.register_craft({
		output = "3d_armor:leggings_"..s,
		recipe = {
			{m, m, m},
			{m, "", m},
			{m, "", m},
		},
	})
	minetest.register_craft({
		output = "3d_armor:boots_"..s,
		recipe = {
			{m, "", m},
			{m, "", m},
		},
	})
end
end

-- ================= armor_nether =================
do

--- Registered armors.
--
--  @topic armor


-- support for i18n
local S = minetest.get_translator(minetest.get_current_modname())


--- Nether
--
--  Requires `armor_material_nether`.
--
--  @section nether

if armor.materials.nether then
	--- Nether Helmet
	--
	--  @helmet 3d_armor:helmet_nether
	--  @img 3d_armor_inv_helmet_nether.png
	--  @grp armor_head 1
	--  @grp armor_heal 14
	--  @grp armor_use 200
	--  @grp armor_fire 1
	--  @armorgrp fleshy 18
	--  @damagegrp cracky 3
	--  @damagegrp snappy 2
	--  @damagegrp level 3
	armor:register_armor(":3d_armor:helmet_nether", {
		description = S("Nether Helmet"),
		inventory_image = "3d_armor_inv_helmet_nether.png",
		groups = {armor_head=1, armor_heal=14, armor_use=100, armor_fire=1},
		armor_groups = {fleshy=18},
		damage_groups = {cracky=3, snappy=2, level=3},
	})
	--- Nether Chestplate
	--
	--  @chestplate 3d_armor:chestplate_nether
	--  @img 3d_armor_inv_chestplate_nether.png
	--  @grp armor_torso 1
	--  @grp armor_heal 14
	--  @grp armor_use 200
	--  @grp armor_fire 1
	--  @armorgrp fleshy 25
	--  @damagegrp cracky 3
	--  @damagegrp snappy 2
	--  @damagegrp level 3
	armor:register_armor(":3d_armor:chestplate_nether", {
		description = S("Nether Chestplate"),
		inventory_image = "3d_armor_inv_chestplate_nether.png",
		groups = {armor_torso=1, armor_heal=14, armor_use=200, armor_fire=1},
		armor_groups = {fleshy=25},
		damage_groups = {cracky=3, snappy=2, level=3},
	})
	--- Nether Leggings
	--
	--  @leggings 3d_armor:leggings_nether
	--  @img 3d_armor_inv_leggings_nether.png
	--  @grp armor_legs 1
	--  @grp armor_heal 14
	--  @grp armor_use 200
	--  @grp armor_fire 1
	--  @armorgrp fleshy 25
	--  @damagegrp cracky 3
	--  @damagegrp snappy 2
	--  @damagegrp level 3
	armor:register_armor(":3d_armor:leggings_nether", {
		description = S("Nether Leggings"),
		inventory_image = "3d_armor_inv_leggings_nether.png",
		groups = {armor_legs=1, armor_heal=14, armor_use=200, armor_fire=1},
		armor_groups = {fleshy=25},
		damage_groups = {cracky=3, snappy=2, level=3},
	})
	--- Nether Boots
	--
	--  @boots 3d_armor:boots_nether
	--  @img 3d_armor_inv_boots_nether.png
	--  @grp armor_feet 1
	--  @grp armor_heal 14
	--  @grp armor_use 200
	--  @grp armor_fire 1
	--  @armorgrp fleshy 18
	--  @damagegrp cracky 3
	--  @damagegrp snappy 2
	--  @damagegrp level 3
	armor:register_armor(":3d_armor:boots_nether", {
		description = S("Nether Boots"),
		inventory_image = "3d_armor_inv_boots_nether.png",
		groups = {armor_feet=1, armor_heal=14, armor_use=200, armor_fire=1},
		armor_groups = {fleshy=18},
		damage_groups = {cracky=3, snappy=2, level=3},
	})


	--- Crafting
	--
	--  @section craft

	--- Craft recipes for helmets, chestplates, leggings, boots, & shields.
	--
	--  @craft armor
	--  @usage
	--  Key:
	--  - m: material
	--    - wood:    group:wood
	--    - cactus:  default:cactus
	--    - steel:   default:steel_ingot
	--    - bronze:  default:bronze_ingot
	--    - diamond: default:diamond
	--    - gold:    default:gold_ingot
	--    - mithril: moreores:mithril_ingot
	--    - crystal: ethereal:crystal_ingot
	--    - nether:  nether:nether_ingot
	--
	--  helmet:        chestplate:    leggings:
	--  ┌───┬───┬───┐  ┌───┬───┬───┐  ┌───┬───┬───┐
	--  │ m │ m │ m │  │ m │   │ m │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │ m │ m │ m │  │ m │   │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤  ├───┼───┼───┤
	--  │   │   │   │  │ m │ m │ m │  │ m │   │ m │
	--  └───┴───┴───┘  └───┴───┴───┘  └───┴───┴───┘
	--
	--  boots:         shield:
	--  ┌───┬───┬───┐  ┌───┬───┬───┐
	--  │   │   │   │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │   │ m │   │
	--  └───┴───┴───┘  └───┴───┴───┘

	local s = "nether"
	local m = armor.materials.nether
	minetest.register_craft({
		output = "3d_armor:helmet_"..s,
		recipe = {
			{m, m, m},
			{m, "", m},
			{"", "", ""},
		},
	})
	minetest.register_craft({
		output = "3d_armor:chestplate_"..s,
		recipe = {
			{m, "", m},
			{m, m, m},
			{m, m, m},
		},
	})
	minetest.register_craft({
		output = "3d_armor:leggings_"..s,
		recipe = {
			{m, m, m},
			{m, "", m},
			{m, "", m},
		},
	})
	minetest.register_craft({
		output = "3d_armor:boots_"..s,
		recipe = {
			{m, "", m},
			{m, "", m},
		},
	})

end
end

-- ================= armor_steel =================
do

--- Registered armors.
--
--  @topic armor


-- support for i18n
local S = minetest.get_translator(minetest.get_current_modname())

--- Steel
--
--  Requires setting `armor_material_steel`.
--
--  @section steel

if armor.materials.steel then
	--- Steel Helmet
	--
	--  @helmet 3d_armor:helmet_steel
	--  @img 3d_armor_inv_helmet_steel.png
	--  @grp armor_head 1
	--  @grp armor_heal 0
	--  @grp armor_use 800
	--  @grp physics_speed -0.01
	--  @grp physica_gravity 0.01
	--  @armorgrp fleshy 10
	--  @damagegrp cracky 2
	--  @damagegrp snappy 3
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 1
	--  @damagegrp level 2
	armor:register_armor(":3d_armor:helmet_steel", {
		description = S("Steel Helmet"),
		inventory_image = "3d_armor_inv_helmet_steel.png",
		groups = {armor_head=1, armor_heal=0, armor_use=800,
			physics_speed=-0.01, physics_gravity=0.01},
		armor_groups = {fleshy=10},
		damage_groups = {cracky=2, snappy=3, choppy=2, crumbly=1, level=2},
	})
	--- Steel Chestplate
	--
	--  @chestplate 3d_armor:chestplate_steel
	--  @img 3d_armor_inv_chestplate_steel.png
	--  @grp armor_torso 1
	--  @grp armor_heal 0
	--  @grp armor_use 800
	--  @grp physics_speed
	--  @grp physics_gravity
	--  @armorgrp fleshy
	--  @damagegrp cracky 2
	--  @damagegrp snappy 3
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 1
	--  @damagegrp level 2
	armor:register_armor(":3d_armor:chestplate_steel", {
		description = S("Steel Chestplate"),
		inventory_image = "3d_armor_inv_chestplate_steel.png",
		groups = {armor_torso=1, armor_heal=0, armor_use=800,
			physics_speed=-0.04, physics_gravity=0.04},
		armor_groups = {fleshy=15},
		damage_groups = {cracky=2, snappy=3, choppy=2, crumbly=1, level=2},
	})
	--- Steel Leggings
	--
	--  @leggings 3d_armor:leggings_steel
	--  @img 3d_armor_inv_leggings_steel.png
	--  @grp armor_legs 1
	--  @grp armor_heal 0
	--  @grp armor_use 800
	--  @grp physics_speed -0.03
	--  @grp physics_gravity 0.03
	--  @armorgrp fleshy 15
	--  @damagegrp cracky 2
	--  @damagegrp snappy 3
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 1
	--  @damagegrp level 2
	armor:register_armor(":3d_armor:leggings_steel", {
		description = S("Steel Leggings"),
		inventory_image = "3d_armor_inv_leggings_steel.png",
		groups = {armor_legs=1, armor_heal=0, armor_use=800,
			physics_speed=-0.03, physics_gravity=0.03},
		armor_groups = {fleshy=15},
		damage_groups = {cracky=2, snappy=3, choppy=2, crumbly=1, level=2},
	})
	--- Steel Boots
	--
	--  @boots 3d_armor:boots_steel
	--  @img 3d_armor_inv_boots_steel.png
	--  @grp armor_feet 1
	--  @grp armor_heal 0
	--  @grp armor_use 800
	--  @grp physics_speed -0.01
	--  @grp physics_gravity 0.01
	--  @armorgrp fleshy 10
	--  @damagegrp cracky 2
	--  @damagegrp snappy 3
	--  @damagegrp choppy 2
	--  @damagegrp crumbly 1
	--  @damagegrp level 2
	armor:register_armor(":3d_armor:boots_steel", {
		description = S("Steel Boots"),
		inventory_image = "3d_armor_inv_boots_steel.png",
		groups = {armor_feet=1, armor_heal=0, armor_use=800,
			physics_speed=-0.01, physics_gravity=0.01},
		armor_groups = {fleshy=10},
		damage_groups = {cracky=2, snappy=3, choppy=2, crumbly=1, level=2},
	})

	--- Crafting
	--
	--  @section craft

	--- Craft recipes for helmets, chestplates, leggings, boots, & shields.
	--
	--  @craft armor
	--  @usage
	--  Key:
	--  - m: material
	--    - wood:    group:wood
	--    - cactus:  default:cactus
	--    - steel:   default:steel_ingot
	--    - bronze:  default:bronze_ingot
	--    - diamond: default:diamond
	--    - gold:    default:gold_ingot
	--    - mithril: moreores:mithril_ingot
	--    - crystal: ethereal:crystal_ingot
	--    - nether:  nether:nether_ingot
	--
	--  helmet:        chestplate:    leggings:
	--  ┌───┬───┬───┐  ┌───┬───┬───┐  ┌───┬───┬───┐
	--  │ m │ m │ m │  │ m │   │ m │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │ m │ m │ m │  │ m │   │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤  ├───┼───┼───┤
	--  │   │   │   │  │ m │ m │ m │  │ m │   │ m │
	--  └───┴───┴───┘  └───┴───┴───┘  └───┴───┴───┘
	--
	--  boots:         shield:
	--  ┌───┬───┬───┐  ┌───┬───┬───┐
	--  │   │   │   │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │   │ m │   │
	--  └───┴───┴───┘  └───┴───┴───┘

	local s = "steel"
	local m = armor.materials.steel
	minetest.register_craft({
		output = "3d_armor:helmet_"..s,
		recipe = {
			{m, m, m},
			{m, "", m},
			{"", "", ""},
		},
	})
	minetest.register_craft({
		output = "3d_armor:chestplate_"..s,
		recipe = {
			{m, "", m},
			{m, m, m},
			{m, m, m},
		},
	})
	minetest.register_craft({
		output = "3d_armor:leggings_"..s,
		recipe = {
			{m, m, m},
			{m, "", m},
			{m, "", m},
		},
	})
	minetest.register_craft({
		output = "3d_armor:boots_"..s,
		recipe = {
			{m, "", m},
			{m, "", m},
		},
	})
end
end

-- ================= armor_wood =================
do

--- Registered armors.
--
--  @topic armor


-- support for i18n
local S = minetest.get_translator(minetest.get_current_modname())

--- Wood
--
--  Requires setting `armor_material_wood`.
--
--  @section wood

if armor.materials.wood then
	--- Wood Helmet
	--
	--  @helmet 3d_armor:helmet_wood
	--  @img 3d_armor_inv_helmet_wood.png
	--  @grp armor_head 1
	--  @grp armor_heal 0
	--  @grp armor_use 2000
	--  @grp flammable 1
	--  @armorgrp fleshy 5
	--  @damagegrp cracky 3
	--  @damagegrp snappy 2
	--  @damagegrp choppy 3
	--  @damagegrp crumbly 2
	--  @damagegrp level 1
	armor:register_armor(":3d_armor:helmet_wood", {
		description = S("Wood Helmet"),
		inventory_image = "3d_armor_inv_helmet_wood.png",
		groups = {armor_head=1, armor_heal=0, armor_use=2000, flammable=1},
		armor_groups = {fleshy=5},
		damage_groups = {cracky=3, snappy=2, choppy=3, crumbly=2, level=1},
	})
	--- Wood Chestplate
	--
	--  @chestplate 3d_armor:chestplate_wood
	--  @img 3d_armor_inv_chestplate_wood.png
	--  @grp armor_torso 1
	--  @grp armor_heal 0
	--  @grp armor_use 2000
	--  @grp flammable 1
	--  @armorgrp fleshy 10
	--  @damagegrp cracky 3
	--  @damagegrp snappy 2
	--  @damagegrp choppy 3
	--  @damagegrp crumbly 2
	--  @damagegrp level 1
	armor:register_armor(":3d_armor:chestplate_wood", {
		description = S("Wood Chestplate"),
		inventory_image = "3d_armor_inv_chestplate_wood.png",
		groups = {armor_torso=1, armor_heal=0, armor_use=2000, flammable=1},
		armor_groups = {fleshy=10},
		damage_groups = {cracky=3, snappy=2, choppy=3, crumbly=2, level=1},
	})
	--- Wood Leggings
	--
	--  @leggings 3d_armor:leggings_wood
	--  @img 3d_armor_inv_leggings_wood.png
	--  @grp armor_legs 1
	--  @grp armor_heal 0
	--  @grp armor_use 1000
	--  @grp flammable 1
	--  @armorgrp fleshy 10
	--  @damagegrp cracky 3
	--  @damagegrp snappy 2
	--  @damagegrp choppy 3
	--  @damagegrp crumbly 2
	--  @damagegrp level 1
	armor:register_armor(":3d_armor:leggings_wood", {
		description = S("Wood Leggings"),
		inventory_image = "3d_armor_inv_leggings_wood.png",
		groups = {armor_legs=1, armor_heal=0, armor_use=2000, flammable=1},
		armor_groups = {fleshy=10},
		damage_groups = {cracky=3, snappy=2, choppy=3, crumbly=2, level=1},
	})
	--- Wood Boots
	--
	--  @boots 3d_armor:boots_wood
	--  @img 3d_armor_inv_boots_wood.png
	--  @grp armor_feet 1
	--  @grp armor_heal 0
	--  @grp armor_use 2000
	--  @grp flammable 1
	--  @armorgrp fleshy 5
	--  @damagegrp cracky 3
	--  @damagegrp snappy 2
	--  @damagegrp choppy 3
	--  @damagegrp crumbly 2
	--  @damagegrp level 1
	armor:register_armor(":3d_armor:boots_wood", {
		description = S("Wood Boots"),
		inventory_image = "3d_armor_inv_boots_wood.png",
		armor_groups = {fleshy=5},
		damage_groups = {cracky=3, snappy=2, choppy=3, crumbly=2, level=1},
		groups = {armor_feet=1, armor_heal=0, armor_use=2000, flammable=1},
	})
	local wood_armor_fuel = {
		helmet = 6,
		chestplate = 8,
		leggings = 7,
		boots = 5
	}
	for armor, burn in pairs(wood_armor_fuel) do
		minetest.register_craft({
			type = "fuel",
			recipe = "3d_armor:" .. armor .. "_wood",
			burntime = burn,
		})
	end

	--- Crafting
	--
	--  @section craft

	--- Craft recipes for helmets, chestplates, leggings, boots, & shields.
	--
	--  @craft armor
	--  @usage
	--  Key:
	--  - m: material
	--    - wood:    group:wood
	--    - cactus:  default:cactus
	--    - steel:   default:steel_ingot
	--    - bronze:  default:bronze_ingot
	--    - diamond: default:diamond
	--    - gold:    default:gold_ingot
	--    - mithril: moreores:mithril_ingot
	--    - crystal: ethereal:crystal_ingot
	--    - nether:  nether:nether_ingot
	--
	--  helmet:        chestplate:    leggings:
	--  ┌───┬───┬───┐  ┌───┬───┬───┐  ┌───┬───┬───┐
	--  │ m │ m │ m │  │ m │   │ m │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │ m │ m │ m │  │ m │   │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤  ├───┼───┼───┤
	--  │   │   │   │  │ m │ m │ m │  │ m │   │ m │
	--  └───┴───┴───┘  └───┴───┴───┘  └───┴───┴───┘
	--
	--  boots:         shield:
	--  ┌───┬───┬───┐  ┌───┬───┬───┐
	--  │   │   │   │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │ m │ m │ m │
	--  ├───┼───┼───┤  ├───┼───┼───┤
	--  │ m │   │ m │  │   │ m │   │
	--  └───┴───┴───┘  └───┴───┴───┘

	local s = "wood"
	local m = armor.materials.wood
	minetest.register_craft({
		output = "3d_armor:helmet_"..s,
		recipe = {
			{m, m, m},
			{m, "", m},
			{"", "", ""},
		},
	})
	minetest.register_craft({
		output = "3d_armor:chestplate_"..s,
		recipe = {
			{m, "", m},
			{m, m, m},
			{m, m, m},
		},
	})
	minetest.register_craft({
		output = "3d_armor:leggings_"..s,
		recipe = {
			{m, m, m},
			{m, "", m},
			{m, "", m},
		},
	})
	minetest.register_craft({
		output = "3d_armor:boots_"..s,
		recipe = {
			{m, "", m},
			{m, "", m},
		},
	})
end
end

-- ================= 3d_armor_ip =================
do
-- support for i18n
local S = minetest.get_translator(minetest.get_current_modname())
local F = minetest.formspec_escape

if not minetest.global_exists("inventory_plus") then
	minetest.log("warning", "3d_armor_ip: Mod loaded but unused.")
	return
end

armor.formspec = "size[8,8.5]button[6,0;2,0.5;main;"..F(S("Back")).."]"..armor.formspec
armor:register_on_update(function(player)
	local name = player:get_player_name()
	local formspec = armor:get_armor_formspec(name, true)
	local page = player:get_inventory_formspec()
	if page:find("detached:"..name.."_armor") then
		inventory_plus.set_inventory_formspec(player, formspec)
	end
end)

if minetest.get_modpath("crafting") then
	inventory_plus.get_formspec = function(player, page)
	end
end

minetest.register_on_joinplayer(function(player)
	inventory_plus.register_button(player,"armor", S("Armor"))
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if fields.armor then
		local name = armor:get_valid_player(player, "[on_player_receive_fields]")
		if not name then
			return
		end
		local formspec = armor:get_armor_formspec(name, true)
		inventory_plus.set_inventory_formspec(player, formspec)
	end
end)
end

-- ================= 3d_armor_sfinv =================
do
-- support for i18n
local S = minetest.get_translator(minetest.get_current_modname())

if not minetest.global_exists("sfinv") then
	minetest.log("warning", "3d_armor_sfinv: Mod loaded but unused.")
	return
end

sfinv.register_page("3d_armor:armor", {
	title = S("Armor"),
	get = function(self, player, context)
		local name = player:get_player_name()
		local formspec = armor:get_armor_formspec(name, true)
		return sfinv.make_formspec(player, context, formspec, false)
	end
})
armor:register_on_update(function(player)
	if sfinv.enabled and sfinv.get_page(player) == "3d_armor:armor" then
		sfinv.set_player_inventory_formspec(player)
	end
end)
end

-- ================= 3d_armor_ui =================
do
-- support for i18n
local S = minetest.get_translator(minetest.get_current_modname())
local F = minetest.formspec_escape
local has_technic = minetest.get_modpath("technic") ~= nil

if not minetest.global_exists("unified_inventory") then
	minetest.log("warning", "3d_armor_ui: Mod loaded but unused.")
	return
end

local ui = unified_inventory
if ui.sfinv_compat_layer then
	return
end

armor:register_on_update(function(player)
	local name = player:get_player_name()
	if unified_inventory.current_page[name] == "armor" then
		unified_inventory.set_inventory_formspec(player, "armor")
	end
end)

unified_inventory.register_button("armor", {
	type = "image",
	image = "inventory_plus_armor.png",
	tooltip = S("3D Armor")
})

unified_inventory.register_page("armor", {
	get_formspec = function(player, perplayer_formspec)
		local fy = perplayer_formspec.form_header_y + 0.5
		local gridx = perplayer_formspec.std_inv_x
		local gridy = 0.6

		local name = player:get_player_name()
		local formspec = perplayer_formspec.standard_inv_bg..
			perplayer_formspec.standard_inv..
			ui.make_inv_img_grid(gridx, gridy, 2, 3)..
			string.format("label[%f,%f;%s]",
				perplayer_formspec.form_header_x, perplayer_formspec.form_header_y, F(S("Armor")))..
			string.format("list[detached:%s_armor;armor;%f,%f;2,3;]",
				name, gridx + ui.list_img_offset, gridy + ui.list_img_offset) ..
			"image[3.5,"..(fy - 0.25)..";2,4;"..armor.textures[name].preview.."]"..
			"label[6.0,"..(fy + 0.0)..";"..F(S("Level"))..": "..armor.def[name].level.."]"..
			"label[6.0,"..(fy + 0.5)..";"..F(S("Heal"))..":  "..armor.def[name].heal.."]"..
			"listring[current_player;main]"..
			"listring[detached:"..name.."_armor;armor]"
		if armor.config.fire_protect then
			formspec = formspec.."label[6.0,"..(fy + 1.0)..";"..
				F(S("Fire"))..":  "..armor.def[name].fire.."]"
		end
		if has_technic then
			formspec = formspec.."label[6.0,"..(fy + 1.5)..";"..
				F(S("Radiation"))..":  "..armor.def[name].groups["radiation"].."]"
		end
		return {formspec=formspec}
	end,
})
end
