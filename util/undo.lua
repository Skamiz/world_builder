local modname = minetest.get_current_modname()
local modprefix = modname .. ":"

--[[
WARNING: UNDO might not work properly if the affected area isn't completely loaded
]]

local undo_limit = tonumber(minetest.settings:get("wb_undo_limit")) or 50


local players = {}

minetest.register_on_joinplayer(function(player, last_login)
	players[player] = {}
end)
minetest.register_on_leaveplayer(function(player, timed_out)
	players[player] = nil
end)


function world_builder.execute_with_undo(player, pos1, pos2, func, ...)
	local undo_data = players[player]

	local schemA = world_builder.schematics.make_schematic(pos1, pos2, 255)
	local desc = func(...) or "no description"
	local schemB = world_builder.schematics.make_schematic(pos1, pos2, 255)
	local dif = world_builder.schematics.diff(schemA, schemB)
	local minp = vector.sort(pos1, pos2)

	local undo_def = {
		schematic = dif,
		pos = minp,
		description = desc,
	}
	table.insert(undo_data, undo_def)
	if #undo_data > undo_limit then
		table.remove(undo_data, 1)
	end
end

local function undo(player, index)
	local undo_data = players[player]
	if #undo_data == 0 then return end
	index = index or #undo_data
	local undo_def = undo_data[index]
	-- print(dump(undo_data))
	-- assert(vector.check(minp))
	minetest.place_schematic(undo_def.pos, undo_def.schematic, nil, nil, true, nil)
	table.remove(undo_data, index)
end

local function get_undo_list(player)
	local undo_data = players[player]
	local fs = {
		"textlist[0,0.5;5,6;undo_list;"
	}
	for i, undo_def in ipairs(undo_data) do
		fs[#fs + 1] = i
		fs[#fs + 1] = " - "
		fs[#fs + 1] = undo_def.description
		fs[#fs + 1] = ","
	end
	fs[#fs + 1] = "]"
	fs = table.concat(fs)
	return fs
end
local function get_undo_fs(player)
	local fs = {
		"formspec_version[6]",
		"size[6,8,false]",
		"container[0.5,0.5]",
		"label[0,0;Undo History:]",
		get_undo_list(player),
		"label[0,7;Undo Limit: " .. undo_limit .. "]",
		"container_end[]",
	}
	fs = table.concat(fs)
	return fs
end
local function show_udno_fs(player)
	local fs = get_undo_fs(player)
	minetest.show_formspec(player:get_player_name(), modprefix .."undo", fs)
end
minetest.register_craftitem(modprefix .."undo", {
	short_description = "Undo",
	description = "Undo"
			.. "\n" .. minetest.colorize("#e3893b", "LMB") .. ": Undo last action."
			.. "\n" .. minetest.colorize("#3dafd2", "RMB") .. ": View undo history."
	,
	inventory_image = "wb_undo.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		undo(user)
	end,
	on_place = function(itemstack, placer, pointed_thing)
		show_udno_fs(placer)
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		show_udno_fs(user)
	end,
})
