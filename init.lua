local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local modprefix = modname .. ":"

local worldpath = minetest.get_worldpath()
local data_path = minetest.get_mod_data_path()

world_builder = {}
world_builder.modname = modname
world_builder.modpath = modpath
world_builder.modprefix = modprefix

world_builder.worldpath = minetest.get_worldpath()
world_builder.data_path = minetest.get_mod_data_path()

if minetest.settings:get("wb_schem_dir") == "world" then
	world_builder.schem_path = world_builder.worldpath .. "/schematics"
else
	world_builder.schem_path = world_builder.data_path .. "/schematics"
end

world_builder.debug_toos = minetest.settings:get_bool("wb_debug_tools", false)

-- misc
-- dofile(modpath .. "/functions.lua")
dofile(modpath .. "/util/popups.lua")
dofile(modpath .. "/util/hotbar_length.lua")
dofile(modpath .. "/util/hotbar_select.lua")
dofile(modpath .. "/util/pointed_pos.lua")
dofile(modpath .. "/util/schematics.lua")
dofile(modpath .. "/util/schematic_preview.lua")
dofile(modpath .. "/color_nodes.lua")
dofile(modpath .. "/fix_undefined.lua")
dofile(modpath .. "/util/undo.lua")

-- formspec stuff
dofile(modpath .. "/modular_formspecs/palette.lua")
dofile(modpath .. "/modular_formspecs/color_picker.lua")

-- tools
dofile(modpath .. "/tools/teleporter.lua")
dofile(modpath .. "/tools/selector.lua")
dofile(modpath .. "/tools/area_options.lua")
dofile(modpath .. "/tools/random_node.lua")
dofile(modpath .. "/tools/replacer.lua")
-- dofile(modpath .. "/builders_tool.lua")
dofile(modpath .. "/tools/clipboard.lua")
-- dofile(modpath .. "/terrain_brush.lua")


-- TODO: path building tool
-- 		specify width and node distribution(probably in probabilities)
-- 		one mouse button starts/stops building process, the other, once the proces has started specifies individual points and immediatelly connects them
-- TODO: add stop_time functionality
-- TODO: trimm function, shrinks area so that all outer layers contain somethig else than only air
-- TODO: when loading a schematic, check that all the required nodes are registered
-- 		if not display warning instead / formspec listing all missing nodes
-- 		eventually maybe also a formspec letting the player select replacements
-- TODO: a mechanism equivalent to fill bucket in painting
-- TODO: the terrainbrush needs an option to inverse mask
--  paintbrush for color not terrain
-- TODO: scripter, writing and library of scripts to run on each node in selection
-- in addition to smooth also have versions biased to take away/add
-- TODO: line tool, places a straight line of nodes prom one pos to another
-- 		or just stright take inspiration from dires building tool
-- 		like placing an orthogonal line from the pointed node to the players pos
-- TODO: maybe colorful names for the tool items?

-- TODO: some player options like reach distance

-- INSPIRATION: https://www.curseforge.com/minecraft/mc-mods/effortless-building/

-- TODO: make all apropriate places use hotbar select callbacks

-- TODO: flood fill tool

-- TODO: read keybind settings to provide acurate tooltips in singleplayer
-- 		in multiplayer fall back on 'aux1', 'sneak', etc...

-- for brush, raise/lower terrain while keeping the node composition same


local function print_table(t)
	for k, v in pairs(t) do
		minetest.chat_send_all(type(k) .. " : " .. tostring(k) .. " | " .. type(v) .. " : " .. tostring(v))
	end
end
