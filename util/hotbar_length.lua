--[[
Ths is a fallback, in case the user doesn't have any other way to change the hotbar length.

Uses it's own hotbar textures, so they can be reliabley adjusted to the desired number of slots.
--]]


-- cuts up a one slot hotbar immage and reasembles it with the requested amount of slots
-- assumes that original hotbar image is 30 * 30 pixels
local function get_hotbar_image(base, length)
	length = math.min(32, math.max(1, length))

	local left_edge = "[combine\\:1x30\\:0,0=" .. base
	local middle = "[combine\\:28x30\\:-1,0=" .. base
	local right_edge = "[combine\\:1x30\\:-29,0=" .. base

	local hotbar_image = "[combine:" .. 28 * length + 2 .. "x30"

	for i = 0, length - 1 do
		hotbar_image = hotbar_image .. ":" .. 1 + i * 28 .. ",0=" .. middle
	end
	hotbar_image = hotbar_image .. ":0,0=" .. left_edge
	hotbar_image = hotbar_image .. ":" .. 28 * length + 1 .. ",0=" .. right_edge

	return hotbar_image
end

function world_builder.set_hotbar_length(player, hotbar_length)
	player:hud_set_hotbar_itemcount(hotbar_length)
	player:hud_set_hotbar_image(get_hotbar_image("wb_hotbar.png", hotbar_length))
	player:hud_set_hotbar_selected_image("wb_hotbar_selected.png")
end

minetest.register_chatcommand("wb_hotbar", {
	params = "length",
	description = "Sets number of hotbar slots. Length must be between 1 and 32.",
	-- privs = {},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		hotbar_length = tonumber(param)
		if not hotbar_length then
			minetest.chat_send_player(name, "leght parameter must be a number")
			return
		end
		world_builder.set_hotbar_length(player, hotbar_length)
	end,
})
