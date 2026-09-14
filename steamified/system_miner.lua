local machine_timer = 0

local function dig_node_if_valid(pos)
    local target_node = minetest.get_node_or_nil(pos)
    if not target_node or target_node.name == "air" or target_node.name == "ignore" then
        return false
    end

    local def = minetest.registered_nodes[target_node.name]
    if not def or def.liquidtype ~= "none" or def.diggable == false then
        return false
    end

    if minetest.node_dig then
        minetest.node_dig(pos, target_node, nil)
    else
        minetest.remove_node(pos)
    end
    return true
end

local function process_miner(pos, power)
    if not power then return end
    local source = steamified.get_power_source(power.source)
    if not source then return end
    if steamified.motors[power.source] and source.current_stress > steamified.config.STRESS_THRESHOLD then return end
    if steamified.power_generators[power.source] and source.def.output and source.current_stress > source.def.output then return end

    for depth = 1, 16 do
        local target_pos = vector.add(pos, {x = 0, y = -depth, z = 0})
        if dig_node_if_valid(target_pos) then
            break
        end
    end
end

local function process_saw(pos, node, power)
    if not power then return end
    local source = steamified.get_power_source(power.source)
    if not source then return end
    if steamified.motors[power.source] and source.current_stress > steamified.config.STRESS_THRESHOLD then return end
    if steamified.power_generators[power.source] and source.def.output and source.current_stress > source.def.output then return end

    local direction = steamified.get_axis_direction(node.param2)
    for depth = 1, 8 do
        local target_pos = vector.add(pos, vector.multiply(direction, depth))
        local target_node = minetest.get_node_or_nil(target_pos)
        if target_node and target_node.name ~= "air" and target_node.name ~= "ignore" then
            local def = minetest.registered_nodes[target_node.name]
            local tree_group = minetest.get_item_group(target_node.name, "tree")
            local choppy_group = minetest.get_item_group(target_node.name, "choppy")
            if def and def.liquidtype == "none" and def.diggable ~= false and (tree_group > 0 or choppy_group > 0) then
                if minetest.node_dig then
                    minetest.node_dig(target_pos, target_node, nil)
                else
                    minetest.remove_node(target_pos)
                end
            end
            break
        end
    end
end

local function process_conveyor(pos, node, power)
    if not power then return end
    local source = steamified.get_power_source(power.source)
    if not source then return end
    if steamified.motors[power.source] and source.current_stress > steamified.config.STRESS_THRESHOLD then return end
    if steamified.power_generators[power.source] and source.def.output and source.current_stress > source.def.output then return end

    local direction = steamified.get_axis_direction(node.param2)
    local center = vector.add(pos, {x = 0, y = 0.2, z = 0})
    for _, obj in ipairs(minetest.get_objects_inside_radius(center, 0.75)) do
        if not obj:is_player() then
            local ent = obj:get_luaentity()
            if ent and ent.name == "__builtin:item" then
                local obj_pos = obj:get_pos()
                if obj_pos and math.abs(obj_pos.y - (pos.y + 0.2)) < 0.6 then
                    obj:set_velocity(vector.multiply(direction, 3))
                end
            end
        end
    end
end

minetest.register_globalstep(function(dtime)
    machine_timer = machine_timer + dtime
    if machine_timer < 0.2 then return end
    machine_timer = 0

    for h, pos in pairs(steamified.miners) do
        process_miner(pos, steamified.powered_positions[h])
    end
end)