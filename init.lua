local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local modprefix = modname .. ":"

world_builder = {}

-- misc
dofile(modpath .. "/functions.lua")
dofile(modpath .. "/hotbar_select.lua")
dofile(modpath .. "/pointed_pos.lua")
dofile(modpath .. "/schematics.lua")
dofile(modpath .. "/schematic_preview.lua")
dofile(modpath .. "/color_nodes.lua")
-- dofile(modpath .. "/undo.lua")

-- formspec stuff
dofile(modpath .. "/palette.lua")
dofile(modpath .. "/color_picker.lua")

-- tools
dofile(modpath .. "/teleporter.lua")
dofile(modpath .. "/selector.lua")
dofile(modpath .. "/area_options.lua")
dofile(modpath .. "/random_node.lua")
-- dofile(modpath .. "/builders_tool.lua")
dofile(modpath .. "/clipboard.lua")
-- dofile(modpath .. "/terrain_brush.lua")


-- TODO: Make the tools unstackable
-- TODO: when loading a schematic, check that all the required nodes are registered
-- 		if not display warning instead / formspec listing all missing nodes
-- 		eventually maybe also a formspec letting the player select replacementss
-- TODO: a mechanism equivalent to fill bucket in painting
-- TODO: move color blocks to this mod
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

-- TODO: make all formspecs be built in table format
-- TODO: make all apropriate places use hotbar select callbacks

-- TODO: generalized undo functionality

-- TODO: flood fill tool

-- TODO: read keybind settings to provide acurate tooltips in singleplayer
-- 		in multiplayer fall back on 'aux1', 'sneak', etc...


local function print_table(t)
	for k, v in pairs(t) do
		minetest.chat_send_all(type(k) .. " : " .. tostring(k) .. " | " .. type(v) .. " : " .. tostring(v))
	end
end
