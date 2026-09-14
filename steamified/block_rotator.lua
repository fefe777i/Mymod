-- Configuration setup
if not steamified.rotators then steamified.rotators = {} end
if not steamified.nodeentities then steamified.nodeentities = {} end

local function pos_key(pos)
    return pos.x .. "," .. pos.y .. "," .. pos.z
end

local function get_guid_object(guid)
    if not guid or guid == "" or not core.objects_by_guid then
        return nil
    end
    local obj = core.objects_by_guid[guid]
    if obj and obj:is_valid() then
        return obj
    end
    return nil
end

local function get_rotator_attached_nodes(center)
    local node = minetest.get_node_or_nil(center)
    if not node or node.name == "air" or node.name == "ignore" then
        return {}, vector.new(center), vector.new(center)
    end
    return {{pos = vector.new(center), node = node}}, vector.new(center), vector.new(center)
end

local function remove_rotator_visuals(rotator_pos)
    local meta = minetest.get_meta(rotator_pos)
    local master_id = meta:get_string("rotated_nodeset_id")
    local removed_any = false

    local function remove_master_entity(master_entity)
        if not master_entity then return end
        if master_entity._attachments then
            for _, child_guid in pairs(master_entity._attachments) do
                local child_obj = get_guid_object(child_guid)
                if child_obj then
                    child_obj:remove()
                end
            end
        end
        if master_entity.object and master_entity.object:is_valid() then
            master_entity.object:remove()
        end
        if master_entity._eID then
            steamified.nodeentities[master_entity._eID] = nil
        end
        removed_any = true
    end

    if master_id and master_id ~= "" then
        local master_entity = steamified.nodeentities[master_id]
        if master_entity then
            remove_master_entity(master_entity)
        else
            local master_obj = get_guid_object(master_id)
            if master_obj then
                remove_master_entity(master_obj:get_luaentity())
            end
        end
    end

    if not removed_any then
        local target_hash = steamified.hash_pos(rotator_pos)
        for _, ent in pairs(steamified.nodeentities) do
            if ent and ent._rotator_hash == target_hash then
                remove_master_entity(ent)
            end
        end
    end

    meta:set_string("rotated_nodeset_id", "")
end

local function create_rotator_visuals(rotator_pos, top_pos)
    remove_rotator_visuals(rotator_pos)

    local attached_nodes, minp, maxp = get_rotator_attached_nodes(top_pos)
    if #attached_nodes == 0 then return end

    local nodeset_obj = steamified.read_world(top_pos, top_pos, minp, maxp)
    if not nodeset_obj then return end

    local nodeset_ent = nodeset_obj:get_luaentity()
    if nodeset_ent then
        -- FIX: Always link via engine GUIDs to avoid tracking desyncs
        local guid = tostring(nodeset_obj:get_guid())
        nodeset_ent._eID = guid
        steamified.nodeentities[guid] = nodeset_ent
        nodeset_ent._rotator_hash = steamified.hash_pos(rotator_pos)

        local meta = minetest.get_meta(rotator_pos)
        meta:set_string("rotated_nodeset_id", guid)
        -- Restore any stored rotation value (degrees) from the rotator meta so visuals keep spinning
        local rot_ser = meta:get_string("rotated_nodeset_rotation")
        if rot_ser and rot_ser ~= "" then
            local ok, rot = pcall(minetest.deserialize, rot_ser)
            if ok and rot then
                nodeset_ent._rotation = rot
                if nodeset_ent.object and nodeset_ent.object:is_valid() then
                    nodeset_ent.object:set_rotation(vector.multiply(rot, math.pi / 180))
                end
            end
        end
    end

    for _, entry in ipairs(attached_nodes) do
        minetest.set_node(entry.pos, {name = "air"})
    end
end

local function restore_rotator_nodes(rotator_pos)
    local meta = minetest.get_meta(rotator_pos)
    local master_id = meta:get_string("rotated_nodeset_id")
    local master_entity

    if master_id and master_id ~= "" then
        master_entity = steamified.nodeentities[master_id]
        if not master_entity then
            local master_obj = get_guid_object(master_id)
            if master_obj then
                master_entity = master_obj:get_luaentity()
            end
        end
    end

    if not master_entity then
        local target_hash = steamified.hash_pos(rotator_pos)
        for _, ent in pairs(steamified.nodeentities) do
            if ent and ent._rotator_hash == target_hash then
                master_entity = ent
                break
            end
        end
    end

    if master_entity and master_entity._attachments then
        local top_pos = vector.add(rotator_pos, {x = 0, y = 1, z = 0})

        for pos_str, child_guid in pairs(master_entity._attachments) do
            local obj = get_guid_object(child_guid)
            if obj then
                local child_ent = obj:get_luaentity()
                if child_ent and child_ent.get_node then
                    local listpos = pos_str:split("|")
                    local relative_offset = vector.new(
                        tonumber(listpos[1], 16) - 32768,
                        tonumber(listpos[2], 16) - 32768,
                        tonumber(listpos[3], 16) - 32768
                    )
                    local real_world_pos = vector.add(top_pos, relative_offset)

                    local original_node = child_ent:get_node()
                    minetest.set_node(real_world_pos, original_node)

                    if child_ent._metadata then
                        local world_meta = minetest.get_meta(real_world_pos)
                        world_meta:from_table(child_ent._metadata:to_table())
                    end
                end
            end
        end
    end

    remove_rotator_visuals(rotator_pos)
end

minetest.register_node("steamified:rotator", {
    description = "Rotator\n" .. minetest.colorize("#888888", "Stress impact: " .. steamified.config.ROTATOR_LOAD .. " SU") .. minetest.colorize("#cfc17f", "\nRotates all blocks connected to the block above it"),
    drawtype = "mesh",
    mesh = "rotator.obj",
    tiles = {"steamified_steel_block.png"},
    inventory_image = "steamified_rotator_inv.png",
    wield_image = "steamified_rotator_inv.png",
    paramtype = "light",
    paramtype2 = "facedir",
    groups = steamified.power_node_groups({groups = {cracky = 1, iron = 1}, has_shaft = true}),
    
    selection_box = { type = "fixed", fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5} },
    collision_box = { type = "fixed", fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5} },

    after_place_node = function(pos)
        local h = steamified.hash_pos(pos)
        steamified.rotators[h] = pos
        steamified.add_power_node(pos, "steamified:rotator")
        
        -- FIX: Keep natural placement facedir orientation rather than assigning invalid 24
        local node = minetest.get_node(pos)
        if node.param2 == 24 or node.param2 == nil then
            node.param2 = 0
            minetest.swap_node(pos, node)
        end
        
        local above_pos = vector.add(pos, {x = 0, y = 1, z = 0})
        local above_node = minetest.get_node_or_nil(above_pos)
        
        if above_node and above_node.name ~= "air" and above_node.name ~= "ignore" then
            local def = minetest.registered_nodes[above_node.name]
            if def and (not def.liquidtype or def.liquidtype == "none") and minetest.get_item_group(above_node.name, "liquid") == 0 then
                create_rotator_visuals(pos, above_pos)
            end
        end

        steamified.save_data()
        steamified.update_power_network()
    end,

    on_destruct = function(pos)
        local h = steamified.hash_pos(pos)
        steamified.rotators[h] = nil
        steamified.remove_power_node(pos)

        restore_rotator_nodes(pos)

        steamified.save_data()
        steamified.update_power_network()
    end,

    get_axis = function(node)
        local p2 = node.param2
        if p2 == 24 then p2 = 0 end
        return steamified.get_axis_vector(p2)
    end,
})

steamified.register_power_node("steamified:rotator", {
    component_type = "consumer",
    has_shaft = true,
    has_cog = false,
    get_load = function() return steamified.config.ROTATOR_LOAD end,
    get_axis = function(node) 
        local p2 = node.param2
        if p2 == 24 then p2 = 0 end
        return steamified.get_axis_vector(p2) 
    end,
})

minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
    local below_pos = vector.add(pos, {x = 0, y = -1, z = 0})
    local below = minetest.get_node_or_nil(below_pos)
    if not below then return end
    if below.name ~= "steamified:rotator" then return end

    if newnode.name == "air" or newnode.name == "ignore" then return end

    local def = minetest.registered_nodes[newnode.name]
    if not def then return end
    if def.liquidtype and def.liquidtype ~= "none" then return end
    if minetest.get_item_group(newnode.name, "liquid") > 0 then return end

    create_rotator_visuals(below_pos, pos)
    steamified.save_data()
    steamified.update_power_network()
end)

minetest.register_on_dignode(function(pos, oldnode, digger)
    local below_pos = vector.add(pos, {x = 0, y = -1, z = 0})
    local below = minetest.get_node_or_nil(below_pos)
    if not below then return end
    if below.name ~= "steamified:rotator" then return end

    restore_rotator_nodes(below_pos)
    steamified.save_data()
    steamified.update_power_network()
end)

minetest.register_globalstep(function(dtime)
    if not steamified.rotators then return end
    for h, rotator_pos in pairs(steamified.rotators) do
        local power = steamified.powered_positions[h]
        if not power then goto continue end
        
        local rot_node = minetest.get_node_or_nil(rotator_pos)
        if not rot_node or rot_node.name ~= "steamified:rotator" then
            steamified.rotators[h] = nil
            goto continue
        end

        local source = steamified.get_power_source(power.source)
        local should_spin = false

        if not power.axis then goto continue end
        
        -- FIX: Normalize param2 if it evaluates out-of-bounds to prevent failing axis matches
        local p2 = rot_node.param2
        if p2 == 24 then p2 = 0 end
        
        local rot_axis = steamified.get_axis_vector(p2)
        if not rot_axis then goto continue end
        if not steamified.axes_match(power.axis, rot_axis) then goto continue end

        local src = steamified.get_power_source(power.source)
        if not src then goto continue end
        local allowed = steamified.config.STRESS_THRESHOLD or 2000
        if steamified.creative_engines and steamified.creative_engines[power.source] then
            allowed = math.huge
        elseif src.def and src.def.output then
            allowed = src.def.output
        end
        local current_stress = src.current_stress
        if not current_stress then goto continue end
        if current_stress > allowed then goto continue end
        should_spin = true

        if should_spin then
            local meta = minetest.get_meta(rotator_pos)
            local master_id = meta:get_string("rotated_nodeset_id")
            local master_entity = nil
            
            if master_id and master_id ~= "" then
                master_entity = steamified.nodeentities[master_id]
                if not master_entity then
                    local master_obj = get_guid_object(master_id)
                    if master_obj then
                        master_entity = master_obj:get_luaentity()
                    end
                end
            end
            
            -- Fallback area scanner covering any variation of the nodeset name
            if not master_entity then
                local objects = minetest.get_objects_inside_radius(vector.add(rotator_pos, {x=0,y=1,z=0}), 1.5)
                for _, obj in ipairs(objects) do
                    local ent = obj:get_luaentity()
                    if ent and (ent.name == "steamified:nodeset" or ent.name:sub(-8) == ":nodeset") then
                        local guid = tostring(obj:get_guid())
                        ent._eID = guid
                        master_entity = ent
                        meta:set_string("rotated_nodeset_id", guid)
                        steamified.nodeentities[guid] = ent
                        break
                    end
                end
            end

            local speed = src.speed or 10
            if master_entity and master_entity.object and master_entity.object:is_valid() then
                local rotation = master_entity.object:get_rotation()
                rotation.y = (rotation.y + (speed * dtime * 0.05)) % (math.pi * 2)
                master_entity.object:set_rotation(rotation)
                -- store degree representation on the master entity for other code paths
                master_entity._rotation = vector.multiply(rotation, 180 / math.pi)
                -- persist rotation in rotator node meta so it survives when the nodeset entity is unloaded
                local meta = minetest.get_meta(rotator_pos)
                local ok, ser = pcall(minetest.serialize, master_entity._rotation)
                if ok and ser then meta:set_string("rotated_nodeset_rotation", ser) end
            else
                -- master entity not present; update stored rotation in meta so it continues to advance
                local meta = minetest.get_meta(rotator_pos)
                local rot_ser = meta:get_string("rotated_nodeset_rotation")
                local rot = nil
                if rot_ser and rot_ser ~= "" then
                    local ok, deser = pcall(minetest.deserialize, rot_ser)
                    if ok and deser then rot = deser end
                end
                if not rot then rot = {x = 0, y = 0, z = 0} end
                -- advance degrees by the same angular delta used above (convert rad->deg)
                local delta_deg = (speed * dtime * 0.05) * (180 / math.pi)
                rot.y = (rot.y + delta_deg) % 360
                local ok2, ser2 = pcall(minetest.serialize, rot)
                if ok2 and ser2 then meta:set_string("rotated_nodeset_rotation", ser2) end
            end
        end
        ::continue::
    end
end)

minetest.register_lbm({
    label = "Steamified rotator cache restoration",
    name = "steamified:restore_rotator_cache",
    nodenames = {"steamified:rotator"},
    run_at_every_load = true,
    action = function(pos, node)
        local h = steamified.hash_pos(pos)
        if not steamified.rotators then steamified.rotators = {} end
        steamified.rotators[h] = pos
    end,
})