local modname = minetest.get_current_modname()
local modprefix = modname .. ":"

--[[
Move stuff here which is for determining what the player is pointing at.
above/bellow/distance


probably best not to mess with max distance here
	or maybe dynamicaly get the current max reach distance?


Actually I notice that I already have this in the functions.lua file ... >.<
still need to do the raycast even if it's to figure above/below pos since I need a way to move the indicator

]]

function world_builder.get_eye_pos(player)
	local eye_pos = player:get_pos()
	local eye_height = player:get_properties().eye_height
	local eye_offset = player:get_eye_offset()

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
		local pos = world_builder.pointed_pos(player, 5, "under"):round()
		pointer:set_pos(pos)
	end
end)

local function show_pointer(player)
	local pos = player:get_pos()
	players[player] = minetest.add_entity(pos, modprefix .."pointer")
end

local function remove_pointer(player)
	players[player]:remove()
	players[player] = nil
end

minetest.register_on_leaveplayer(remove_pointer)

minetest.register_craftitem(modprefix .."pointer", {
	short_description = "pointer",
	description = "pointer\ndev item",
	inventory_image = "wb_pointer_item.png",
})


world_builder.register_on_change_wielded(function(player, new_item, old_item)
	if old_item == modprefix .."pointer" then
		remove_pointer(player)
	end
	if new_item == modprefix .."pointer" then
		show_pointer(player)
	end
end)
