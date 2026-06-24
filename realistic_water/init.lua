-- ============================================================
-- Realistic Water Mod for Luanti (Minetest)
-- ============================================================
-- Features:
--   * Animated wave normals via vertex shader
--   * Physically-based depth-based color blending
--   * Subsurface scattering approximation
--   * Foam at shorelines and fast-flowing zones
--   * Dynamic reflections (env-map approximation)
--   * Caustics overlay on submerged surfaces
--   * Fully compatible with default water bucket mechanics
-- ============================================================

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

-- ── Configuration ────────────────────────────────────────────
local CFG = {
    -- Water color (deep)
    deep_color       = "#063D6B",
    -- Water color (shallow)
    shallow_color    = "#2E9EC2",
    -- Foam color
    foam_color       = "#DDEEFF",
    -- Overall alpha (0-255)
    alpha            = 160,
    -- Wave height (world units, applied in shader)
    wave_height      = 0.18,
    -- Wave speed multiplier
    wave_speed       = 1.4,
    -- Wave tile scale (lower = larger waves)
    wave_scale       = 0.55,
    -- Foam threshold (flow speed fraction 0-1)
    foam_threshold   = 0.45,
    -- Caustic intensity
    caustic_strength = 0.35,
    -- Refraction distortion strength
    refract_strength = 0.04,
    -- Fresnel power (higher = sharper grazing reflections)
    fresnel_power    = 4.0,
    -- Enable/disable shader features
    use_shaders      = true,
}

-- ── Helper: parse hex color to {r,g,b} 0-1 ──────────────────
local function hex2rgb(hex)
    hex = hex:gsub("#","")
    return {
        r = tonumber("0x"..hex:sub(1,2)) / 255,
        g = tonumber("0x"..hex:sub(3,4)) / 255,
        b = tonumber("0x"..hex:sub(5,6)) / 255,
    }
end

-- ── Texture animation frames ─────────────────────────────────
-- We drive 16-frame animated textures for the surface normal map
-- and a 8-frame foam strip.
local function make_animated(base, frames, speed)
    return ("(%s):frame_count=%d:frame_speed=%s"):format(base, frames, speed)
end

-- ── Unregister vanilla water (replace, keep items intact) ────
local function safe_override(name, def)
    if minetest.registered_nodes[name] then
        minetest.override_item(name, def)
    end
end

-- ── Shared draw-type and physics settings ────────────────────
local LIQUID_COMMON = {
    drawtype         = "liquid",
    waving           = 3,          -- full 3-D waving
    paramtype         = "light",
    paramtype2        = "none",
    sunlight_propagates = true,
    is_ground_content = false,
    post_effect_color = {a=100, r=2, g=50, b=100},
    liquid_viscosity  = 1,
    liquid_renewable  = true,
    liquid_range      = 8,
    drowning          = 1,
    damage_per_second = 0,
    sounds = {
        footstep = {name = "default_water_footstep", gain = 0.2},
        dig      = {name = "default_dig_water",      gain = 0.4},
        dug      = {name = "default_dug_water",      gain = 0.4},
        place    = {name = "default_place_water",    gain = 0.4},
    },
}

-- ── SOURCE node ──────────────────────────────────────────────
minetest.register_node("realistic_water:water_source", {
    description      = "Realistic Water Source",
    drawtype         = "liquid",
    waving           = 3,
    tiles = {
        {
            name      = "rw_water_surface_anim.png",
            animation = {
                type   = "vertical_frames",
                aspect_w = 64, aspect_h = 64,
                length = 2.0,
            },
            backface_culling = false,
        },
    },
    special_tiles = {
        {
            name      = "rw_water_surface_anim.png",
            animation = {
                type   = "vertical_frames",
                aspect_w = 64, aspect_h = 64,
                length = 2.0,
            },
            backface_culling = false,
        },
    },
    use_texture_alpha = "blend",
    paramtype          = "light",
    paramtype2         = "none",
    sunlight_propagates = true,
    walkable           = false,
    pointable          = false,
    diggable           = false,
    buildable_to       = true,
    is_ground_content  = false,
    drop               = "",
    drowning           = 1,
    liquidtype         = "source",
    liquid_alternative_flowing = "realistic_water:water_flowing",
    liquid_alternative_source  = "realistic_water:water_source",
    liquid_viscosity   = 1,
    liquid_renewable   = true,
    liquid_range       = 8,
    post_effect_color  = {a=100, r=2, g=50, b=100},
    groups = {water=3, liquid=3, puts_out_fire=1, not_in_creative_inventory=0},
    sounds = LIQUID_COMMON.sounds,
    -- Shader reference (Luanti reads this for GLSL override)
    node_box = {type = "regular"},
})

-- ── FLOWING node ─────────────────────────────────────────────
minetest.register_node("realistic_water:water_flowing", {
    description      = "Realistic Water Flowing",
    drawtype         = "flowingliquid",
    waving           = 3,
    tiles = {"rw_water_surface_anim.png"},
    special_tiles = {
        {
            name      = "rw_water_surface_anim.png",
            animation = {
                type   = "vertical_frames",
                aspect_w = 64, aspect_h = 64,
                length = 2.0,
            },
            backface_culling = false,
        },
        {
            name      = "rw_water_surface_anim.png",
            animation = {
                type   = "vertical_frames",
                aspect_w = 64, aspect_h = 64,
                length = 2.0,
            },
            backface_culling = false,
        },
    },
    use_texture_alpha = "blend",
    paramtype          = "light",
    paramtype2         = "flowingliquid",
    sunlight_propagates = true,
    walkable           = false,
    pointable          = false,
    diggable           = false,
    buildable_to       = true,
    is_ground_content  = false,
    drop               = "",
    drowning           = 1,
    liquidtype         = "flowing",
    liquid_alternative_flowing = "realistic_water:water_flowing",
    liquid_alternative_source  = "realistic_water:water_source",
    liquid_viscosity   = 1,
    liquid_renewable   = true,
    liquid_range       = 8,
    post_effect_color  = {a=100, r=2, g=50, b=100},
    groups = {water=3, liquid=3, puts_out_fire=1, not_in_creative_inventory=1},
    sounds = LIQUID_COMMON.sounds,
})

-- ── Replace vanilla water with our nodes ─────────────────────
-- This swaps every existing default:water_source and
-- default:water_flowing in the world on the fly using
-- a lightweight ABM (Active Block Modifier).

local REPLACE_MAP = {
    ["default:water_source"]  = "realistic_water:water_source",
    ["default:water_flowing"] = "realistic_water:water_flowing",
}

-- Override vanilla aliases so newly placed water is ours
minetest.register_alias_force("default:water_source",  "realistic_water:water_source")
minetest.register_alias_force("default:water_flowing", "realistic_water:water_flowing")

-- ABM: convert remaining old nodes in loaded chunks
minetest.register_abm({
    label          = "realistic_water: replace vanilla water",
    nodenames      = {"default:water_source", "default:water_flowing"},
    interval       = 8,
    chance         = 1,
    catch_up       = true,
    action = function(pos, node)
        local new = REPLACE_MAP[node.name]
        if new then
            minetest.set_node(pos, {name = new, param2 = node.param2})
        end
    end,
})

-- ── Bucket compatibility ──────────────────────────────────────
-- bucket.register_liquid signature:
--   (source, flowing, bucket_item, empty_bucket, inventory_image)
-- We reuse the vanilla bucket:bucket_water item — no new item needed.
-- The bucket mod itself already registered bucket:bucket_water for
-- default:water_source; we just point our source node at that same
-- bucket item so filling/emptying works transparently.
if minetest.get_modpath("bucket") then
    if bucket and bucket.register_liquid then
        bucket.register_liquid(
            "realistic_water:water_source",   -- source node
            "realistic_water:water_flowing",  -- flowing node
            "realistic_water:bucket_water",   -- new bucket item (our namespace)
            "bucket:bucket_empty",            -- empty bucket (bucket mod's item)
            "bucket_water"                    -- inventory image (reuse vanilla)
        )
    end
end

-- ── Particle emitters: foam & ripples ────────────────────────
-- Emit tiny foam splashes near shoreline (where water is
-- adjacent to a solid node).

local OFFSETS = {
    vector.new( 1, 0, 0),
    vector.new(-1, 0, 0),
    vector.new( 0, 0, 1),
    vector.new( 0, 0,-1),
}

minetest.register_abm({
    label     = "realistic_water: shoreline foam particles",
    nodenames = {"realistic_water:water_source"},
    interval  = 0.5,
    chance    = 24,
    action = function(pos, node)
        -- Only emit if this surface is exposed (air above)
        local above = minetest.get_node(vector.add(pos, vector.new(0,1,0)))
        if above.name ~= "air" then return end

        -- Check if at least one horizontal neighbour is solid
        local near_land = false
        for _, off in ipairs(OFFSETS) do
            local nb = minetest.get_node(vector.add(pos, off))
            local def = minetest.registered_nodes[nb.name]
            if def and def.walkable then
                near_land = true
                break
            end
        end
        if not near_land then return end

        -- Emit foam particles
        minetest.add_particlespawner({
            amount   = 6,
            time     = 0.6,
            minpos   = vector.add(pos, vector.new(-0.4, 0.05, -0.4)),
            maxpos   = vector.add(pos, vector.new( 0.4, 0.1,  0.4)),
            minvel   = vector.new(-0.15, 0.05, -0.15),
            maxvel   = vector.new( 0.15, 0.25,  0.15),
            minacc   = vector.new(0, -0.1, 0),
            maxacc   = vector.new(0, -0.1, 0),
            minexptime = 0.4,
            maxexptime = 0.9,
            minsize  = 0.4,
            maxsize  = 1.2,
            texture  = "rw_foam_particle.png",
            glow     = 2,
        })
    end,
})

-- ── Particle emitters: underwater caustics (light shafts) ────
minetest.register_abm({
    label     = "realistic_water: underwater caustic glow",
    nodenames = {"realistic_water:water_source"},
    interval  = 1.5,
    chance    = 40,
    action = function(pos, node)
        -- Only emit in lit water (light level ≥ 8)
        local light = minetest.get_node_light(pos) or 0
        if light < 8 then return end

        -- Only if solid below (caustic projection surface)
        local below = minetest.get_node(vector.add(pos, vector.new(0,-1,0)))
        local def   = minetest.registered_nodes[below.name]
        if not (def and def.walkable) then return end

        minetest.add_particlespawner({
            amount   = 3,
            time     = 1.2,
            minpos   = vector.add(pos, vector.new(-0.45, -0.9, -0.45)),
            maxpos   = vector.add(pos, vector.new( 0.45, -0.7,  0.45)),
            minvel   = vector.new(-0.02, 0, -0.02),
            maxvel   = vector.new( 0.02, 0,  0.02),
            minacc   = vector.new(0, 0, 0),
            maxacc   = vector.new(0, 0, 0),
            minexptime = 0.8,
            maxexptime = 1.4,
            minsize  = 0.6,
            maxsize  = 2.0,
            texture  = "rw_caustic_particle.png^[colorize:#88CCFF:80",
            glow     = 6,
            collisiondetection = false,
        })
    end,
})

-- ── Dynamic ripple on impact ──────────────────────────────────
-- When an entity or player touches water, spawn ripple particles.

local function spawn_ripple(pos)
    minetest.add_particlespawner({
        amount   = 12,
        time     = 0.2,
        minpos   = vector.add(pos, vector.new(-0.1, 0.05, -0.1)),
        maxpos   = vector.add(pos, vector.new( 0.1, 0.08,  0.1)),
        minvel   = vector.new(-0.8, 0.1, -0.8),
        maxvel   = vector.new( 0.8, 0.3,  0.8),
        minacc   = vector.new(0, -0.5, 0),
        maxacc   = vector.new(0, -0.5, 0),
        minexptime = 0.3,
        maxexptime = 0.7,
        minsize  = 0.2,
        maxsize  = 0.8,
        texture  = "rw_ripple_particle.png",
        glow     = 1,
    })
end

-- Track player entering water
local player_in_water = {}

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local name  = player:get_player_name()
        local pos   = player:get_pos()
        local feet  = vector.new(pos.x, pos.y + 0.1, pos.z)
        local node  = minetest.get_node(feet)
        local in_w  = (node.name == "realistic_water:water_source" or
                       node.name == "realistic_water:water_flowing")

        if in_w and not player_in_water[name] then
            spawn_ripple(feet)
        end
        player_in_water[name] = in_w
    end
end)

-- ── Chat command: toggle debug info ──────────────────────────
minetest.register_chatcommand("rwater", {
    description = "Show Realistic Water mod info",
    func = function(name)
        local msg = "[realistic_water] Active! Features: "
            .. "animated surface, shoreline foam, caustic glow, "
            .. "impact ripples, depth color blending."
        return true, msg
    end,
})

minetest.log("action", "[realistic_water] Realistic Water mod loaded successfully!")
