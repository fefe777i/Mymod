local interactions = {}

-- Dummy backward-compatible for older mods.
local modname = minetest.get_current_modname() or "steamified"
minetest.register_entity(modname..":raycollider", {
	visible = false,
	physical = false,
})

-- Pure math Ray-AABB intersection to find the exact face clicked in local LVAE space
local function ray_intersect_aabb(eye, dir, min_pos, max_pos)
	local tmin = -math.huge
	local tmax = math.huge
	local normal = {x = 0, y = 0, z = 0}

	for _, axis in ipairs({"x", "y", "z"}) do
		if math.abs(dir[axis]) < 0.0001 then
			if eye[axis] < min_pos[axis] or eye[axis] > max_pos[axis] then
				return nil
			end
		else
			local t1 = (min_pos[axis] - eye[axis]) / dir[axis]
			local t2 = (max_pos[axis] - eye[axis]) / dir[axis]
			local n1, n2 = -1, 1

			if t1 > t2 then
				t1, t2 = t2, t1
				n1, n2 = 1, -1
			end

			if t1 > tmin then
				tmin = t1
				normal = {x = 0, y = 0, z = 0}
				normal[axis] = n1
			end

			if t2 < tmax then
				tmax = t2
			end

			if tmin > tmax then
				return nil
			end
		end
	end

	if tmax < 0 then return nil end
	return normal, tmin
end


-- Helper function to calculate param2 based on local look direction and local click normal
local function get_local_param2(local_dir, local_normal, paramtype2)
	if paramtype2 == "facedir" or paramtype2 == "colorfacedir" then
		-- Convert the local face normal to a Minetest direction index
		-- 0=Y+, 1=Z+, 2=Z-, 3=X+, 4=X-, 5=Y-
		local face_idx = 0
		if local_normal.y > 0 then face_idx = 0
		elseif local_normal.z > 0 then face_idx = 1
		elseif local_normal.z < 0 then face_idx = 2
		elseif local_normal.x > 0 then face_idx = 3
		elseif local_normal.x < 0 then face_idx = 4
		elseif local_normal.y < 0 then face_idx = 5
		end

		-- Determine player's local primary look direction on the horizontal plane
		local dir_idx = 0
		if math.abs(local_dir.x) > math.abs(local_dir.z) then
			dir_idx = local_dir.x > 0 and 3 or 1 -- 3 = +X, 1 = -X
		else
			dir_idx = local_dir.z > 0 and 0 or 2 -- 0 = +Z, 2 = -Z
		end

		-- Standard Minetest facedir derivation formula: (axis_dir * 4) + rotation
		return minetest.dir_to_facedir(local_dir, face_idx == 0 or face_idx == 5)
		
	elseif paramtype2 == "wallmounted" or paramtype2 == "colorwallmounted" then
		-- 0=Y+, 1=Y-, 2=X+, 3=X-, 4=Z+, 5=Z-
		if local_normal.y > 0 then return 0
		elseif local_normal.y < 0 then return 1
		elseif local_normal.x > 0 then return 2
		elseif local_normal.x < 0 then return 3
		elseif local_normal.z > 0 then return 4
		elseif local_normal.z < 0 then return 5
		end
	end
	
	return 0
end

interactions.place = function(entity, player)
	local stack = player:get_wielded_item()
	local itemname = stack:get_name()
	local def = minetest.registered_nodes[itemname]
	if not def then return end
	if string.find(itemname, "steamified:", 1, true) then return end

	-- Get player eye position and viewing direction
	local eye = player:get_pos()
	eye.y = eye.y + player:get_properties().eye_height
	eye = vector.add(eye, player:get_eye_offset())
	local look_dir = player:get_look_dir()

	local reach = minetest.is_creative_enabled(player:get_player_name()) and 10 or (def.range or 4)

	local parent_obj, _, _ = entity.object:get_attach()
	if not parent_obj or not parent_obj:get_pos() then return end
	local parent = parent_obj:get_luaentity()
	if not parent then return end
	local parent_pos = parent_obj:get_pos()
	local parent_ent = parent_obj:get_luaentity()

	local rot_deg = (parent_ent and parent_ent._rotation) or parent_obj:get_rotation() or {x = 0, y = 0, z = 0}
	local rot_rad = parent_ent and parent_ent._rotation and vector.multiply(rot_deg, math.pi / 180) or rot_deg

	-- 1. Transform ray origin (eye) to LVAE local space
	local rel_eye = vector.subtract(eye, parent_pos)

	-- Apply inverse rotation (Roll -> Yaw -> Pitch) to counter MT's rotation order
	local local_eye = rel_eye
	local_eye = vector.rotate_around_axis(local_eye, {x = 0, y = 0, z = 1}, -rot_rad.z)
	local_eye = vector.rotate_around_axis(local_eye, {x = 0, y = 1, z = 0}, -rot_rad.y)
	local_eye = vector.rotate_around_axis(local_eye, {x = 1, y = 0, z = 0}, -rot_rad.x)

	-- 2. Transform ray direction to LVAE local space
	local local_dir = look_dir
	local_dir = vector.rotate_around_axis(local_dir, {x = 0, y = 0, z = 1}, -rot_rad.z)
	local_dir = vector.rotate_around_axis(local_dir, {x = 0, y = 1, z = 0}, -rot_rad.y)
	local_dir = vector.rotate_around_axis(local_dir, {x = 1, y = 0, z = 0}, -rot_rad.x)

	-- 3. Intersect against the clicked node's local AABB (1x1x1 box centered at entity.pos)
	local min_pos = vector.subtract(entity.pos, 0.5)
	local max_pos = vector.add(entity.pos, 0.5)

	-- Get the local normal (which face was clicked) and the distance
	local local_normal, dist = ray_intersect_aabb(local_eye, local_dir, min_pos, max_pos)

	-- 4. Validate the hit distance and place the block
	if local_normal and dist <= reach then
		local pos = vector.add(entity.pos, local_normal)
		local existing_node = parent:get_node(pos)
		if existing_node.name == "air" or existing_node.name == "ignore" or 
		   (minetest.registered_nodes[existing_node.name] and minetest.registered_nodes[existing_node.name].buildable_to) then
			local param2 = get_local_param2(local_dir, local_normal, def.paramtype2)
			parent:place_node(pos, {name = itemname, param2 = param2})
			if not minetest.is_creative_enabled(player:get_player_name()) then
				stack:take_item()
				player:set_wielded_item(stack)
			end
		end
	end
end

-- Digging functions work immediately as they trace directly back to the clicked local coordinate
interactions.dig = function(entity, player)
	entity.parent:remove_node(entity.pos)
end

interactions.ray_intersect_aabb = ray_intersect_aabb

return interactions