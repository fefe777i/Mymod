-- Configuration constants
steamified.config = {
    RPM = 64,                    -- Standard rotation speed for generators
    STRESS_THRESHOLD = 2000,     -- Load threshold to stall network
    MOTOR_OUTPUT = 2048,         -- Furnace motor output (SU)
    WATER_WHEEL_OUTPUT = 1000,   -- Water wheel generator output (SU)
    WATER_WHEEL_RPM = 24,        -- Water wheel rotation speed
    MINER_LOAD = 500,            -- Miner stress consumption
    SAW_LOAD = 500,              -- Saw stress consumption
    CONVEYOR_LOAD = 250,         -- Conveyor stress consumption
    SHAFTLESS_COG_LOAD = 500,    -- Shaftless cog stress consumption
    ROTATOR_LOAD = 300           -- Rotator stress consumption
}

steamified.active_visual_entities = {} 

function steamified.hash_pos(pos)
    return minetest.hash_node_position(pos)
end

function steamified.get_axis_vector(param2)
    if param2 >= 20 then 
        return {x = 0, y = 1, z = 0} 
    end
    local dir = minetest.facedir_to_dir(param2)
    return {x = math.abs(dir.x), y = math.abs(dir.y), z = math.abs(dir.z)}
end

function steamified.get_axis_direction(param2)
    if param2 >= 20 and param2 <= 23 then 
        return vector.new(0, 1, 0)
    elseif param2 >= 24 then 
        return vector.new(0, -1, 0) 
    end
    return minetest.facedir_to_dir(param2)
end

function steamified.is_adjacent_fluid(pos)
    local offsets = {
        vector.new(1, 0, 0), vector.new(-1, 0, 0),
        vector.new(0, 1, 0), vector.new(0, -1, 0),
        vector.new(0, 0, 1), vector.new(0, 0, -1),
    }
    for _, offset in ipairs(offsets) do
        local neighbor = minetest.get_node_or_nil(vector.add(pos, offset))
        if neighbor then
            local def = minetest.registered_nodes[neighbor.name]
            if def and def.liquidtype and def.liquidtype ~= "none" then
                return true
            end
            if minetest.get_item_group(neighbor.name, "liquid") > 0 then
                return true
            end
        end
    end
    return false
end

function steamified.axes_match(axis1, axis2)
    if not axis1 or not axis2 then return false end
    return axis1.x == axis2.x and axis1.y == axis2.y and axis1.z == axis2.z
end

steamified.power_node_defs = {}
steamified.power_generators = {}
steamified.power_consumers = {}

function steamified.power_node_groups(def)
    local groups = {}
    if def.groups then
        for k, v in pairs(def.groups) do groups[k] = v end
    end
    groups.kinetic_component = 1
    if def.has_shaft then groups.kinetic_axle = 1 end
    if def.has_cog then groups.kinetic_cog = 1 end
    return groups
end

function steamified.register_power_node(name, def)
    steamified.power_node_defs[name] = def
    return def
end

function steamified.add_power_node(pos, name)
    local def = steamified.power_node_defs[name]
    if not def then return end
    local h = steamified.hash_pos(pos)
    local node = minetest.get_node_or_nil(pos)
    if not node then return end
    local entry = {pos = pos, name = name, def = def}
    if def.component_type == "generator" then
        steamified.power_generators[h] = entry
    else
        steamified.power_consumers[h] = entry
    end
    if def.has_shaft or def.has_cog then
        steamified.add_power_node_visuals(pos, node, def)
    end
end

function steamified.remove_power_node(pos)
    local h = steamified.hash_pos(pos)
    steamified.power_generators[h] = nil
    steamified.power_consumers[h] = nil
    for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 0.5)) do
        local ent = obj:get_luaentity()
        if ent and ent.name == "steamified:baked_entity" then
            obj:remove()
        end
    end
end

function steamified.get_power_source(source_hash)
    return steamified.motors[source_hash] or steamified.creative_engines[source_hash] or steamified.power_generators[source_hash]
end

local function is_matching_node(node, expected_name)
    return node and (node.name == expected_name or node.name == expected_name .. "_node")
end

local function is_pos_table(value)
    return type(value) == "table" and type(value.x) == "number" and type(value.y) == "number" and type(value.z) == "number"
end

local function get_saved_pos(value)
    if is_pos_table(value) then
        return value
    end
    if type(value) == "table" and is_pos_table(value.pos) then
        return value.pos
    end
    return nil
end

function steamified.restore_saved_power_nodes()
    local function restore(tbl, node_name)
        for h, value in pairs(tbl) do
            local entry_pos = get_saved_pos(value)
            if entry_pos then
                local node = minetest.get_node_or_nil(entry_pos)
                if node == nil then
                    -- Mapblock not loaded yet; keep the saved entry for later
                elseif is_matching_node(node, node_name) then
                    steamified.add_power_node(entry_pos, node_name)
                else
                    -- Node at position is not the expected type; drop the saved entry
                    tbl[h] = nil
                end
            else
                tbl[h] = nil
            end
        end
    end

    restore(steamified.motors, "steamified:motor")
    restore(steamified.creative_engines, "steamified:creative_engine")
    restore(steamified.miners, "steamified:miner")
    restore(steamified.cogs, "steamified:cog")
    restore(steamified.water_wheels, "steamified:water_wheel")

    for h, entry in pairs(steamified.water_wheels) do
        if entry and entry.pos then
            local pos = entry.pos
            local active = steamified.is_adjacent_fluid(pos)
            if not active then
                local above = minetest.get_node_or_nil(vector.add(pos, {x=0, y=1, z=0}))
                if above then
                    local def = minetest.registered_nodes[above.name]
                    if (def and def.liquidtype and def.liquidtype ~= "none") or (minetest.get_item_group(above.name, "liquid") > 0) then
                        active = true
                    end
                end
            end
            entry.active = active
        end
    end
end

function steamified.restore_gearbox_visuals()
    for h, entry in pairs(steamified.gearboxes) do
        local pos = get_saved_pos(entry)
        if not pos then
            steamified.gearboxes[h] = nil
        else
            local node = minetest.get_node_or_nil(pos)
            if node == nil then
                -- Mapblock not loaded yet; keep gearbox entry for LBMs or later restoration
            elseif not is_matching_node(node, "steamified:gearbox") then
                steamified.gearboxes[h] = nil
            else
                local core_obj = minetest.add_entity(pos, "steamified:baked_entity")
                if core_obj then
                    local core_ent = core_obj:get_luaentity()
                    core_ent._param2 = node.param2
                    core_ent._is_motor_shaft = true
                    core_ent._mesh_prefix = "gearbox_inner"
                    core_ent._is_static_part = true
                    core_ent._custom_textures = {"steamified_wood.png"}
                    core_ent:refresh_properties()
                end

                local axes_planes = {"x", "y", "z"}
                for _, plane in ipairs(axes_planes) do
                    local obj = minetest.add_entity(pos, "steamified:baked_entity")
                    if obj then
                        local ent = obj:get_luaentity()
                        ent._param2 = node.param2
                        ent._is_motor_shaft = true
                        ent._mesh_prefix = "shaft"
                        ent._gearbox_axis_plane = plane
                        ent._custom_textures = {"steamified_shaft.png"}
                        ent:refresh_properties()
                    end
                end
            end
        end
    end
end

function steamified.restore_saved_state()
    steamified.restore_saved_power_nodes()
    steamified.restore_gearbox_visuals()
    steamified.update_power_network()
end

function steamified.add_power_node_visuals(pos, node, def)
    if def.has_shaft == true then
        local obj = minetest.add_entity(pos, "steamified:baked_entity")
        if obj then
            local ent = obj:get_luaentity()
            ent._param2 = node.param2
            ent._mesh_prefix = "shaft"
            ent._custom_textures = def.shaft_textures or {"steamified_shaft.png"}
            ent._rpm = def.rpm or steamified.config.RPM  
            ent:refresh_properties()
        end
    end
    if def.has_wheel == true then
        local obj = minetest.add_entity(pos, "steamified:baked_entity")
        if obj then
            local ent = obj:get_luaentity()
            ent._param2 = node.param2
            ent._mesh_prefix = "wheel"
            ent._custom_textures = def.wheel_textures or {"steamified_wood.png"}
            ent._rpm = def.rpm or steamified.config.RPM  
            ent:refresh_properties()
        end
    end
    if def.has_cog == true then
        local obj = minetest.add_entity(pos, "steamified:baked_entity")
        if obj then
            local ent = obj:get_luaentity()
            ent._param2 = node.param2
            ent._mesh_prefix = "cog"
            ent._custom_textures = def.cog_textures or {"steamified_wood.png"}
            ent._speed_factor = def.speed_factor or 1
            ent:refresh_properties()
        end
    end
end

function steamified.update_power_network()
    steamified.powered_positions = {}
    local network_loads = {}
    local network_stalled = {} 
    local queue = {}
    local visited = {}

    for hash_str, motor in pairs(steamified.motors) do
        local node = minetest.get_node_or_nil(motor.pos)
        if node and node.name == "steamified:motor" then
            local h = steamified.hash_pos(motor.pos)
            network_loads[h] = 0
            if motor.is_active then
                local motor_axis = steamified.get_axis_vector(node.param2)
                queue[#queue + 1] = {pos = motor.pos, axis = motor_axis, source = h, dir = 1, is_cog = false, rpm = steamified.config.RPM}
                visited[h] = true
                steamified.powered_positions[h] = {pos = motor.pos, axis = motor_axis, source = h, direction = 1, rpm = steamified.config.RPM}
                network_loads[h] = 0
            end
        end
    end

    if steamified.creative_engines then
        for hash_str, engine in pairs(steamified.creative_engines) do
            local node = minetest.get_node_or_nil(engine.pos)
            if node and node.name == "steamified:creative_engine" then
                local h = steamified.hash_pos(engine.pos)
                local motor_axis = steamified.get_axis_vector(node.param2)
                queue[#queue + 1] = {pos = engine.pos, axis = motor_axis, source = h, dir = 1, is_cog = false, rpm = steamified.config.RPM}
                visited[h] = true
                steamified.powered_positions[h] = {pos = engine.pos, axis = motor_axis, source = h, direction = 1, rpm = steamified.config.RPM}
                network_loads[h] = 0
            end
        end
    end

    for h, entry in pairs(steamified.power_generators) do
        local node = minetest.get_node_or_nil(entry.pos)
        if node and node.name == entry.name then
            local active = true
            if entry.def.is_active then
                active = entry.def.is_active(entry.pos)
            end
            if active then
                local motor_axis = entry.def.get_axis and entry.def.get_axis(node) or steamified.get_axis_vector(node.param2)
                local gen_rpm = entry.def.rpm or steamified.config.RPM
                queue[#queue + 1] = {pos = entry.pos, axis = motor_axis, source = h, dir = 1, is_cog = entry.def.has_cog, rpm = gen_rpm}
                visited[h] = true
                steamified.powered_positions[h] = {pos = entry.pos, axis = motor_axis, source = h, direction = 1, rpm = gen_rpm}
                network_loads[h] = 0
            end
        end
    end

    local head = 1
    local consumer_loaded = {}
    while head <= #queue do
        local current = queue[head]
        head = head + 1

        local scan_offsets = {}
        local current_node = minetest.get_node_or_nil(current.pos)
        
        local current_is_shaft = current_node and (minetest.get_item_group(current_node.name, "kinetic_axle") > 0)
        local current_is_cog = current_node and (minetest.get_item_group(current_node.name, "kinetic_cog") > 0)
        local current_is_gearbox = current_node and (minetest.get_item_group(current_node.name, "kinetic_gearbox") > 0)

        if current_is_gearbox or current_is_cog then
            scan_offsets = {
                vector.new(1, 0, 0), vector.new(-1, 0, 0),
                vector.new(0, 1, 0), vector.new(0, -1, 0),
                vector.new(0, 0, 1), vector.new(0, 0, -1)
            }
        else
            local forward = steamified.get_axis_direction(current_node.param2)
            local backward = vector.multiply(forward, -1)
            scan_offsets[1] = forward
            scan_offsets[2] = backward
        end

        for _, offset in ipairs(scan_offsets) do
            local neighbor_pos = vector.add(current.pos, offset)
            local n_hash = steamified.hash_pos(neighbor_pos)
            local node = minetest.get_node_or_nil(neighbor_pos)

            if node then
                local neighbor_is_shaft = (minetest.get_item_group(node.name, "kinetic_axle") > 0)
                local neighbor_is_cog = (minetest.get_item_group(node.name, "kinetic_cog") > 0)
                local neighbor_is_gearbox = (minetest.get_item_group(node.name, "kinetic_gearbox") > 0)
                
                local target_axis = (neighbor_is_shaft or neighbor_is_cog) and steamified.get_axis_vector(node.param2) or nil
                
                local is_meshed_cog_connection = false
                if current_is_cog and neighbor_is_cog and steamified.axes_match(current.axis, target_axis) then
                    local axial_dot = (current.axis.x * offset.x) + (current.axis.y * offset.y) + (current.axis.z * offset.z)
                    if math.abs(axial_dot) < 0.001 then 
                        is_meshed_cog_connection = true 
                    end
                end
                
                local is_axial_connection = false
                if current.axis and target_axis and steamified.axes_match(current.axis, target_axis) then
                    local dot_product = (current.axis.x * offset.x) + (current.axis.y * offset.y) + (current.axis.z * offset.z)
                    if math.abs(dot_product) > 0.001 then is_axial_connection = true end
                end

                local connection_valid = is_axial_connection or (is_meshed_cog_connection and not is_axial_connection) or current_is_gearbox or neighbor_is_gearbox

                if connection_valid then
                    local next_dir = current.dir
                    
                    if is_meshed_cog_connection and not is_axial_connection then
                        next_dir = -current.dir
                    elseif neighbor_is_gearbox then
                        next_dir = current.dir
                    end

                    if steamified.powered_positions[n_hash] then
                        if steamified.powered_positions[n_hash].source == current.source and 
                           steamified.powered_positions[n_hash].direction ~= next_dir then
                            network_stalled[current.source] = true
                        end
                    elseif not visited[n_hash] then
                        if neighbor_is_gearbox then
                            visited[n_hash] = true
                            steamified.powered_positions[n_hash] = {pos = neighbor_pos, axis = {x=1,y=1,z=1}, source = current.source, direction = next_dir, rpm = current.rpm}
                            queue[#queue + 1] = {pos = neighbor_pos, axis = {x=1,y=1,z=1}, source = current.source, dir = next_dir, is_cog = false, rpm = current.rpm}
                        elseif neighbor_is_shaft and not neighbor_is_cog then
                            visited[n_hash] = true
                            steamified.powered_positions[n_hash] = {pos = neighbor_pos, axis = target_axis, source = current.source, direction = next_dir, rpm = current.rpm}
                            queue[#queue + 1] = {pos = neighbor_pos, axis = target_axis, source = current.source, dir = next_dir, is_cog = false, rpm = current.rpm}
                        elseif neighbor_is_cog then
                            visited[n_hash] = true
                            steamified.powered_positions[n_hash] = {pos = neighbor_pos, axis = target_axis, source = current.source, direction = next_dir, rpm = current.rpm}
                            queue[#queue + 1] = {pos = neighbor_pos, axis = target_axis, source = current.source, dir = next_dir, is_cog = true, rpm = current.rpm}
                        end
                    end
                end

                local pdef = steamified.power_node_defs[node.name]
                if pdef and pdef.component_type == "consumer" and not consumer_loaded[n_hash] then
                    local load = 500
                    if pdef.get_load then load = pdef.get_load(neighbor_pos) end
                    local src = current.source
                    local accept_load = true

                    if pdef.get_axis then
                        local consumer_axis = pdef.get_axis(node)
                        accept_load = false
                        if consumer_axis and current.axis and steamified.axes_match(consumer_axis, current.axis) then
                            local axial_dot = (current.axis.x * offset.x) + (current.axis.y * offset.y) + (current.axis.z * offset.z)
                            if math.abs(axial_dot) > 0.001 then
                                accept_load = true
                            end
                        end
                    end

                    if accept_load and network_loads[src] then
                        network_loads[src] = network_loads[src] + load
                        consumer_loaded[n_hash] = true
                        if not steamified.powered_positions[n_hash] then
                            steamified.powered_positions[n_hash] = {pos = neighbor_pos, axis = nil, source = src, direction = current.dir, rpm = current.rpm}
                        end
                    end
                end
            end
        end
    end

    local unions = {}
    local function uf_find(a)
        if unions[a] == nil then unions[a] = a end
        if unions[a] ~= a then unions[a] = uf_find(unions[a]) end
        return unions[a]
    end
    local function uf_union(a, b)
        local ra, rb = uf_find(a), uf_find(b)
        if ra ~= rb then unions[rb] = ra end
    end

    for pos_hash, p in pairs(steamified.powered_positions) do
        if p and p.source then uf_find(p.source) end
    end

    local pos_sources = {}
    for ph, p in pairs(steamified.powered_positions) do
        if p and p.source then
            pos_sources[ph] = pos_sources[ph] or {}
            pos_sources[ph][#pos_sources[ph] + 1] = p.source
        end
    end
    for _, srcs in pairs(pos_sources) do
        if #srcs > 1 then
            for i = 2, #srcs do uf_union(srcs[1], srcs[i]) end
        end
    end

    local groups = {}
    for src, _ in pairs(network_loads) do
        local root = uf_find(src)
        groups[root] = groups[root] or {sources = {}, total_load = 0, total_output = 0, max_rpm = 0}
        groups[root].sources[src] = true
        groups[root].total_load = groups[root].total_load + (network_loads[src] or 0)
        local out = 0
        if steamified.motors[src] then
            out = steamified.config.MOTOR_OUTPUT
        elseif steamified.creative_engines and steamified.creative_engines[src] then
            out = math.huge
        elseif steamified.power_generators[src] then
            local gdef = steamified.power_generators[src].def
            out = (gdef and gdef.output) or 0
        end
        groups[root].total_output = groups[root].total_output + out
        local src_rpm = 0
        for ph, p in pairs(steamified.powered_positions) do
            if p and p.source == src and p.rpm then src_rpm = p.rpm break end
        end
        if src_rpm > groups[root].max_rpm then groups[root].max_rpm = src_rpm end
    end

    for root, info in pairs(groups) do
        local is_stalled = false
        if info.total_output ~= math.huge and info.total_load > info.total_output then is_stalled = true end
        for src, _ in pairs(info.sources) do
            if steamified.motors[src] then
                steamified.motors[src].current_stress = is_stalled and (steamified.config.STRESS_THRESHOLD + 1) or info.total_load
            end
            if steamified.creative_engines and steamified.creative_engines[src] then
                steamified.creative_engines[src].current_stress = is_stalled and (math.huge) or info.total_load
            end
            if steamified.power_generators[src] then
                local gen = steamified.power_generators[src]
                gen.current_stress = is_stalled and (info.total_output ~= math.huge and (info.total_output + 1) or math.huge) or info.total_load
            end
        end
        for ph, p in pairs(steamified.powered_positions) do
            if p and p.source and info.sources[p.source] then
                p.rpm = info.max_rpm
                p.source = root
            end
        end
    end

    for h, motor in pairs(steamified.motors) do
        local node = minetest.get_node_or_nil(motor.pos)
        if node and node.name == "steamified:motor" then
            local meta = minetest.get_meta(motor.pos)
            local stress = motor.current_stress or 0
            meta:set_string("infotext", "Furnace Engine: Running\nOutput: " .. steamified.config.MOTOR_OUTPUT .. " SU / " .. steamified.config.RPM .. " RPM\nStress: " .. stress .. "/" .. steamified.config.MOTOR_OUTPUT .. " SU")
        end
    end

    for h, entry in pairs(steamified.power_generators) do
        local node = minetest.get_node_or_nil(entry.pos)
        if node and node.name == entry.name then
            local meta = minetest.get_meta(entry.pos)
            local gen = entry
            local stress = gen.current_stress or 0
            local out = gen.def and gen.def.output or 0
            local rpm = (steamified.powered_positions[h] and steamified.powered_positions[h].rpm) or gen.def.rpm or steamified.config.RPM
            meta:set_string("infotext", entry.name .. ": Output: " .. out .. " SU / " .. rpm .. " RPM\nStress: " .. stress .. "/" .. out .. " SU")
        end
    end

    if steamified.creative_engines then
        for h, eng in pairs(steamified.creative_engines) do
            local node = minetest.get_node_or_nil(eng.pos)
            if node and node.name == "steamified:creative_engine" then
                local meta = minetest.get_meta(eng.pos)
                local stress = eng.current_stress or 0
                local rpm = (steamified.powered_positions[h] and steamified.powered_positions[h].rpm) or steamified.config.RPM
                meta:set_string("infotext", "Creative Generator: ∞ SU / " .. rpm .. " RPM\nStress: " .. stress .. "/∞ SU")
            end
        end
    end

    for h, entry in pairs(steamified.power_consumers) do
        local node = minetest.get_node_or_nil(entry.pos)
        if node and node.name == entry.name then
            local meta = minetest.get_meta(entry.pos)
            local load = 0
            if entry.def and entry.def.get_load then
                load = entry.def.get_load(entry.pos)
            end
            local power = steamified.powered_positions[h]
            local s = "No power"
            if power and power.source then
                local src = power.source
                local rpm = power.rpm or 0
                local src_obj = steamified.get_power_source(src)
                local src_stress = (src_obj and src_obj.current_stress) or 0
                s = "Load: " .. load .. " SU | Source rpm: " .. rpm .. " | Source stress: " .. src_stress
            else
                s = "Load: " .. load .. " SU | No source"
            end
            meta:set_string("infotext", entry.name .. "\n" .. s)
        end
    end

    for ph, p in pairs(steamified.powered_positions) do
        if p and p.pos then
            local node = minetest.get_node_or_nil(p.pos)
            if node then
                local is_axle = (minetest.get_item_group(node.name, "kinetic_axle") > 0)
                local is_cog = (minetest.get_item_group(node.name, "kinetic_cog") > 0)
                if is_axle or is_cog then
                    local meta = minetest.get_meta(p.pos)
                    local root = uf_find(p.source)
                    local info = groups[root]
                    local total_load = info and info.total_load or 0
                    local total_output = info and info.total_output or 0
                    local out_str = (total_output == math.huge) and "∞" or tostring(total_output)
                    local rpm = p.rpm or 0
                    meta:set_string("infotext", node.name .. "\nNetwork: " .. total_load .. " / " .. out_str .. " SU | RPM: " .. rpm)
                end
            end
        end
    end
end

minetest.register_entity("steamified:baked_entity", {
    initial_properties = {
        visual = "mesh", mesh = "shaft_0.obj", textures = {"steamified_shaft.png"},
        visual_size = {x = 10, y = 10, z = 10}, physical = false, 
        pointable = false, 
        shaded = true,
    },
    _param2 = 0, _last_step = -1, _mesh_prefix = "shaft", _sound_handle = nil, _gearbox_axis_plane = nil, _is_static_part = false, _rpm = 16,

    refresh_properties = function(self)
        local p2 = tonumber(self._param2)
        if not p2 or p2 < 0 or p2 > 23 then
            p2 = 0
        end
        self._param2 = p2
        if self._is_static_part then
            self.object:set_properties({
                mesh = "gearbox_inner.obj", 
                textures = self._custom_textures or {"steamified_wood.png"}
            })
        elseif self._mesh_prefix == "cog" then
            self.object:set_properties({mesh = "cog_0.obj", textures = self._custom_textures or {"steamified_wood.png"}})
        elseif self._mesh_prefix == "wheel" then
            self.object:set_properties({mesh = "wheel_0.obj", textures = self._custom_textures or {"steamified_wood.png"}})
        elseif self._mesh_prefix == "block" then
            self.object:set_properties({mesh = "block_0.obj", textures = self._custom_textures or {"steamified_shaft.png"}})
        else
            self.object:set_properties({mesh = "shaft_0.obj", textures = self._custom_textures or {"steamified_shaft.png"}})
        end

        if self._gearbox_axis_plane or self._is_static_part then
            local gp = self._gearbox_axis_plane
            if gp == "x" then
                self.object:set_rotation({x = 0, y = math.pi / 2, z = 0})
            elseif gp == "y" then
                self.object:set_rotation({x = math.pi / 2, y = 0, z = 0})
            else
                local dir = minetest.facedir_to_dir(self._param2)
                if self._param2 >= 20 and self._param2 <= 23 then
                    self.object:set_rotation({x = math.pi / 2, y = 0, z = 0})
                elseif self._param2 >= 24 then
                    self.object:set_rotation({x = -math.pi / 2, y = 0, z = 0})
                elseif dir and type(dir) == "table" and dir.x and dir.x ~= 0 then
                    self.object:set_rotation({x = 0, y = math.pi / 2, z = 0})
                else 
                    self.object:set_rotation({x = 0, y = 0, z = 0}) 
                end
            end
            return
        end

        local dir = minetest.facedir_to_dir(self._param2)
        if self._param2 >= 20 and self._param2 <= 23 then
            self.object:set_rotation({x = math.pi / 2, y = 0, z = 0})
        elseif self._param2 >= 24 then
            self.object:set_rotation({x = -math.pi / 2, y = 0, z = 0})
        elseif dir.x ~= 0 then 
            self.object:set_rotation({x = 0, y = math.pi / 2, z = 0})
        else 
            self.object:set_rotation({x = 0, y = 0, z = 0}) 
        end
    end,

    get_staticdata = function(self) 
        return minetest.serialize({
            param2 = self._param2, 
            mesh_prefix = self._mesh_prefix, 
            custom_textures = self._custom_textures,
            gearbox_axis_plane = self._gearbox_axis_plane,
            is_static_part = self._is_static_part,
            is_motor_shaft = self._is_motor_shaft,
            rpm = self._rpm,
            speed_factor = self._speed_factor
        }) 
    end,
    on_activate = function(self, staticdata)
        if staticdata and staticdata ~= "" then
            local data = minetest.deserialize(staticdata)
            if data then 
                self._param2 = data.param2 or 0 
                self._mesh_prefix = data.mesh_prefix or "shaft"
                self._custom_textures = data.custom_textures
                self._gearbox_axis_plane = data.gearbox_axis_plane
                self._is_static_part = data.is_static_part or false
                self._is_motor_shaft = data.is_motor_shaft or false
                self._rpm = data.rpm or self._rpm
                self._speed_factor = data.speed_factor or self._speed_factor
            end
        end
        self:refresh_properties()
        steamified.active_visual_entities[self.object] = self
    end,
    on_deactivate = function(self) 
        steamified.active_visual_entities[self.object] = nil 
    end,
})

minetest.register_globalstep(function(dtime)
    steamified.visual_time = (steamified.visual_time or 0) + dtime
    local master_time = steamified.visual_time
    for obj, ent in pairs(steamified.active_visual_entities) do
        if not obj:get_pos() then
            steamified.active_visual_entities[obj] = nil
        else
            if not ent._is_static_part then
                local pos = obj:get_pos()
                local h = steamified.hash_pos(vector.round(pos))
                local power = steamified.powered_positions[h]
                if not power and ent._mesh_prefix == "block" then
                    local parent_obj = obj:get_attach()
                    if parent_obj then
                        local parent_ent = parent_obj:get_luaentity()
                        if parent_ent and parent_ent._rotator_hash then
                            power = steamified.powered_positions[parent_ent._rotator_hash]
                        end
                    end
                    if not power then
                        local rotator_pos = vector.add(vector.round(pos), {x = 0, y = -1, z = 0})
                        power = steamified.powered_positions[steamified.hash_pos(rotator_pos)]
                    end
                end
                local should_spin = false

                if power then
                    local source = steamified.get_power_source(power.source)
                    if source then
                        if steamified.motors[power.source] then
                            if source.current_stress <= steamified.config.STRESS_THRESHOLD then
                                should_spin = true
                            end
                        elseif steamified.power_generators[power.source] and source.def and source.def.output then
                            if source.current_stress <= source.def.output then
                                should_spin = true
                            end
                        else
                            should_spin = true
                        end
                    end
                end

                if should_spin then
                    -- Dynamically configure steps based on mesh prefix
                    local is_block = (ent._mesh_prefix == "block")
                    local total_steps = is_block and 360 or 32
                    local dynamic_rpm = (power and power.rpm) or ent._rpm or steamified.config.RPM
                    
                    local step_index = math.floor((master_time * dynamic_rpm * total_steps) / 60) % total_steps
                    if power.direction < 0 then step_index = (total_steps - step_index) % total_steps end

                    if step_index ~= ent._last_step then
                        ent._last_step = step_index
                        
                        -- Fallback textures safely
                        local fallback_tex = {"steamified_shaft.png"}
                        if ent._mesh_prefix == "cog" or ent._mesh_prefix == "wheel" then
                            fallback_tex = {"steamified_wood.png"}
                        elseif is_block then
                            fallback_tex = ent._custom_textures or {"steamified_shaft.png"}
                        end

                        -- If it's a block, we keep using block_0.obj but programmatically spin the entity object!
                        if is_block then
                            obj:set_properties({
                                mesh = "block_0.obj", -- Stop searching for block_1.obj, block_2.obj etc.
                                textures = ent._custom_textures or fallback_tex
                            })
                            
                            -- Calculate the continuous angle in radians (0 to 2*pi)
                            local angle = (step_index / total_steps) * (2 * math.pi)
                            
                            -- Rotators face up, meaning they rotate around the Y axis
                            obj:set_rotation({x = 0, y = angle, z = 0})
                        else
                            -- Keep original behavior for pre-baked shafts/cogs/gearboxes
                            local target_mesh = ent._mesh_prefix .. "_" .. step_index .. ".obj"
                            obj:set_properties({
                                mesh = target_mesh,
                                textures = ent._custom_textures or fallback_tex
                            })
                            
                            if ent._gearbox_axis_plane then
                                local gp = ent._gearbox_axis_plane
                                if gp == "x" then
                                    obj:set_rotation({x = 0, y = math.pi / 2, z = 0})
                                elseif gp == "y" then
                                    obj:set_rotation({x = math.pi / 2, y = 0, z = 0})
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Keep players standing on a rotator contraption attached to the moving entity
    for _, player in ipairs(minetest.get_connected_players()) do
        local attach_parent = player:get_attach()
        local is_attached_to_rotator = false
        if attach_parent then
            local attach_ent = attach_parent:get_luaentity()
            is_attached_to_rotator = attach_ent and attach_ent._rotator_hash
        end

        local player_pos = player:get_pos()
        local below_pos = vector.round({x = player_pos.x, y = player_pos.y - 1.2, z = player_pos.z})
        local node_below = minetest.get_node_or_nil(below_pos)
        local should_attach = false
        local rotator_parent = nil

        if node_below and node_below.name ~= "air" and node_below.name ~= "ignore" then
            for _, nearby in ipairs(minetest.get_objects_inside_radius(below_pos, 0.8)) do
                if nearby ~= player then
                    local ent = nearby:get_luaentity()
                    if ent then
                        local parent = nearby:get_attach()
                        if parent then
                            local parent_ent = parent:get_luaentity()
                            if parent_ent and parent_ent._rotator_hash then
                                should_attach = true
                                rotator_parent = parent
                                break
                            end
                        end
                    end
                end
            end
        end

        if should_attach then
            if not is_attached_to_rotator or attach_parent ~= rotator_parent then
                local parent_pos = rotator_parent:get_pos()
                local offset = vector.multiply(vector.subtract(player_pos, parent_pos), 10)
                player:set_attach(rotator_parent, "", offset, {x = 0, y = 0, z = 0})
            end
        elseif is_attached_to_rotator then
            player:set_attach(nil, "", {x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})
        end
    end
end)

function steamified.register_kinetic_node(name, def)
    local is_cog = (def.type == "cog")
    local base_groups = {stone = 1, kinetic_component = 1}
    if is_cog then
        base_groups.choppy = 2
        base_groups.wood = 1
        base_groups.kinetic_cog = 1
    else
        base_groups.cracky = 3
        base_groups.kinetic_axle = 1
    end

    if def.groups then
        for k, v in pairs(def.groups) do base_groups[k] = v end
    end

    local hidden_node_name = name .. "_node"
    local box_dimensions
    
    if is_cog then
        box_dimensions = {
            type = "facedir",
            fixed = {
                {-0.48, -0.48, -0.15, 0.48, 0.48, 0.15}, 
                {-0.18, -0.18, -0.5,  0.18, 0.18, 0.5 } 
            }
        }
    else
        box_dimensions = {
            type = "facedir",
            fixed = {{-0.18, -0.18, -0.5, 0.18, 0.18, 0.5}}
        }
    end

    local hidden_groups = {not_in_creative_inventory = 1, kinetic_component = 1, kinetic_axle = is_cog and 0 or 1, kinetic_cog = is_cog and 1 or 0}
    for k, v in pairs(base_groups) do hidden_groups[k] = v end

    minetest.register_node(hidden_node_name, {
        drawtype = "nodebox", 
        use_texture_alpha = "clip", 
        node_box = box_dimensions, 
        selection_box = box_dimensions, 
        collision_box = box_dimensions,
        paramtype = "light", sunlight_propagates = true, walkable = true, pointable = true, diggable = true,
        paramtype2 = "facedir", 
        tiles = {"invisible.png"}, 
        groups = hidden_groups, _drop_on_punch = name,

        on_dig = function(pos, node, digger)
            for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 0.1)) do
                local ent = obj:get_luaentity()
                if ent and ent.name == "steamified:baked_entity" then
                    obj:remove()
                end
            end
            
            minetest.node_dig(pos, node, digger)
            if digger and not minetest.is_creative_enabled(digger:get_player_name()) then
                local drop_stack = ItemStack(name)
                local leftovers = digger:get_inventory():add_item("main", drop_stack)
                if leftovers and not leftovers:is_empty() then minetest.add_item(pos, leftovers) end
            end
            steamified.update_power_network()
        end,
    })

    minetest.register_node(name, {
        description = def.description or "Kinetic Component",
        drawtype = "airlike", paramtype = "light", paramtype2 = "facedir",
        groups = base_groups, _drop_on_punch = name,
        inventory_image = def.inventory_image, wield_image = def.wield_image,

        on_place = function(itemstack, placer, pointed_thing)
            if pointed_thing.type ~= "node" then return minetest.item_place(itemstack, placer, pointed_thing) end

            local under = pointed_thing.under
            local above = pointed_thing.above
            local side_vector = vector.subtract(above, under)
            local p2 = minetest.dir_to_facedir(side_vector)

            if side_vector.y ~= 0 then
                local player_dir = placer:get_look_dir()
                p2 = minetest.dir_to_facedir(player_dir)
                if side_vector.y > 0 then p2 = p2 + 20 else p2 = p2 + 24 end
            end

            return minetest.item_place(itemstack, placer, pointed_thing, p2)
        end,

        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local node = minetest.get_node(pos)
            if is_cog then
                steamified.cogs[steamified.hash_pos(pos)] = pos
                steamified.save_data()
            end

            minetest.set_node(pos, {name = hidden_node_name, param2 = node.param2})
            
            if is_cog then
                local obj1 = minetest.add_entity(pos, "steamified:baked_entity")
                if obj1 then
                    local ent1 = obj1:get_luaentity()
                    ent1._param2 = node.param2
                    ent1._mesh_prefix = "shaft"
                    ent1._custom_textures = {"steamified_shaft.png"}
                    ent1:refresh_properties()
                end
                
                local obj2 = minetest.add_entity(pos, "steamified:baked_entity")
                if obj2 then
                    local ent2 = obj2:get_luaentity()
                    ent2._param2 = node.param2
                    ent2._mesh_prefix = "cog"
                    ent2._custom_textures = {"steamified_wood.png"}
                    ent2:refresh_properties()
                end
            else
                local obj = minetest.add_entity(pos, "steamified:baked_entity")
                if obj then
                    local ent = obj:get_luaentity()
                    ent._param2 = node.param2
                    ent._mesh_prefix = "shaft"
                    if def.textures then ent._custom_textures = def.textures end
                    ent:refresh_properties()
                end
            end
            steamified.update_power_network()
        end,
    })
end