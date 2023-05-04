local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local modprefix = modname .. ":"

world_builder = {}
world_builder.debug_toos = minetest.settings:get_bool("wb_debug_tools", false)

-- misc
-- dofile(modpath .. "/functions.lua")
dofile(modpath .. "/util/hotbar_select.lua")
dofile(modpath .. "/util/pointed_pos.lua")
dofile(modpath .. "/util/schematics.lua")
dofile(modpath .. "/util/schematic_preview.lua")
dofile(modpath .. "/color_nodes.lua")
dofile(modpath .. "/util/undo.lua")

-- formspec stuff
dofile(modpath .. "/modular_formspecs/palette.lua")
dofile(modpath .. "/modular_formspecs/color_picker.lua")

-- tools
dofile(modpath .. "/tools/teleporter.lua")
dofile(modpath .. "/tools/selector.lua")
dofile(modpath .. "/tools/area_options.lua")
dofile(modpath .. "/tools/random_node.lua")
-- dofile(modpath .. "/builders_tool.lua")
dofile(modpath .. "/tools/clipboard.lua")
-- dofile(modpath .. "/terrain_brush.lua")

-- TODO: popup system to temporarily display text inf oto the player without cluttering their chat
-- 		things like: "You first need to select an area", etc...
-- 		popup time is proportianal to message length + some time for the eyes to focus on the text
-- 		if a new popup comes in while a previous is up, imediately replace it

-- TODO: when loading a schematic, check that all the required nodes are registered
-- 		if not display warning instead / formspec listing all missing nodes
-- 		eventually maybe also a formspec letting the player select replacements
-- TODO: a mechanism equivalent to fill bucket in painting
-- TODO: the terrainbrush needs an option to inverse mask
--  paintbrush for color not terrain
-- TODO: scripter, writing and library of scripts to run on each node in selection
-- in addition to smooth also have versions biased to take away/add
-- TODO: replacement sets, to make it possible: stone->cobble, sotne stair-> cobble stair, etc...
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

-- TODO: chatcomand for setting players hotbar length as a backup if they have no other option for it




local function print_table(t)
	for k, v in pairs(t) do
		minetest.chat_send_all(type(k) .. " : " .. tostring(k) .. " | " .. type(v) .. " : " .. tostring(v))
	end
end
