local modname = minetest.get_current_modname()
local modprefix = modname .. ":"

--[[
Utility for finding the position the player is currently pointing at.
has 3 modes:
"distance" returned position is exact distance from player, regardless of in between nodes
"above" returned position is one node above the one the player points at
"under" returned position is the the node the player points at

]]

function world_builder.get_eye_pos(player)
	local eye_pos = player:get_pos()
	local eye_height = player:get_properties().eye_height
	local eye_offset = player:get_eye_offset() / 10

	eye_pos.y = eye_pos.y + eye_height
	eye_pos = eye_pos + eye_offset

	return eye_pos
end

function world_builder.get_looked_pos(player, distance)
	distance = distance or 5
	local eye_pos = world_builder.get_eye_pos(player)
	local look_dir = player:get_look_dir()
	local pos = eye_pos + (look_dir * distance)

	return pos
end


function world_builder.pointed_pos(player, distance, mode)
	if type(player) == "string" then
		player = minetest.get_player_by_name(player)
	end
	mode = mode or "distance"
	distance = distance or 4

	local eye_pos = world_builder.get_eye_pos(player)
	local look_dir = player:get_look_dir()
	local target_pos = eye_pos + (look_dir * distance)

	if mode == "above" or mode == "under" then
		local ray = minetest.raycast(eye_pos, target_pos, false, false)
		local pt = ray:next()
		-- if there simply isn't a node in the pointed direction
		if not pt then return target_pos end
		if mode == "above" then
			return pt.above
		else
			return pt.under
		end
	end

	-- distance mode is also used as fallback
	return target_pos
end


-- just debug stuff
--------------------------------------------------------------------------------
if not world_builder.debug_toos then return end
do
	-- WARNING: if texture is made any more opaque it will become completely invissible
	-- local tex = "wb_selector.png"
	local tex = "wb_pointer.png^[colorize:#6bd23d^[opacity:129"
	local scale = 1.002
	minetest.register_entity(modprefix .."pointer", {
		pointable = false,
		visual = "cube",
		visual_size = {x = scale, y = scale, z = scale},
		textures = {tex, tex, tex, tex, tex, tex},
		use_texture_alpha = true,
		-- is_visible = true,
		-- backface_culling = false,
		glow = -1,
		static_save = false,
	})
end

local players = {}

minetest.register_globalstep(function(dtime)
	for player, pointer in pairs(players) do
		local wielded = player:get_wielded_item()
		local meta = wielded:get_meta()
		local pos = world_builder.pointed_pos(player, tonumber(meta:get("distance")) or 5, meta:get("pointing_mode") or "under"):round()
		pointer:set_pos(pos)
	end
end)

local function show_pointer(player)
	local pos = player:get_pos()
	players[player] = minetest.add_entity(pos, modprefix .."pointer")
end

local function remove_pointer(player)
	if players[player] then players[player]:remove() end
	players[player] = nil
end

minetest.register_on_leaveplayer(remove_pointer)

local mode_index = {
	["distance"] = 1,
	["above"] = 2,
	["under"] = 3,
}
local function show_poniter_formspec(player)
	local wielded = player:get_wielded_item()
	local meta = wielded:get_meta()
	local fs = {
		"formspec_version[6]",
		"size[3,3,false]",
		"field[0.5,0.75;2,0.75;distance;TP distance:;" .. meta:get_string("distance") .. "]",
		"tooltip[distance;Overrides the pointed distance. (default: 5)]",
		"dropdown[0.5,1.75;2,0.75;pointing_mode;distance,above,under;" .. (mode_index[meta:get("pointing_mode")] or "1") .. ";false]",
		"tooltip[pointing_mode;Determines how the pointing ray interacts with colliding nodes.]",
	}
	fs = table.concat(fs)
	minetest.show_formspec(player:get_player_name(), modprefix .."pointer", fs)
end

minetest.register_craftitem(modprefix .."pointer", {
	short_description = "pointer",
	description = "pointer\ndev item",
	inventory_image = "wb_pointer_item.png",
	stack_max = 1,
	on_place = function(itemstack, placer, pointed_thing)
		show_poniter_formspec(placer)
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		show_poniter_formspec(user)
	end,
})


world_builder.register_on_change_wielded(function(player, new_item, old_item)
	if old_item == modprefix .. "pointer" then
		remove_pointer(player)
	end
	if new_item == modprefix .. "pointer" then
		show_pointer(player)
	end
end)


minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= modprefix .."pointer" then return end

	local wielded = player:get_wielded_item()
	if wielded:get_name() ~= modprefix .."pointer" then return end
	local meta = wielded:get_meta()

	if tonumber(fields.distance) then
		meta:set_string("distance", fields.distance)
	end
	if fields.pointing_mode then
		meta:set_string("pointing_mode", fields.pointing_mode)
	end

	player:set_wielded_item(wielded)

	return true
end)
