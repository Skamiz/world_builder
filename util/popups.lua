local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

--[[
A popup system.

Because I want a way to tell the player why any given operation isn't working
without cluttering their chat.

world_builder.hud_display(player, text)
--]]


local players = {}


local function remove_hud(player)
	player:hud_remove(players[player].hud_id)
	players[player] = nil
end
local function add_hud(player)
	players[player].hud_id = player:hud_add({
		hud_elem_type = "text",
		position = {x = 0.5, y = 0.9},
		alignment = {x = 0, y = 0},
		name = "popup_hud",
		text = "",
		number = 0xffffff,
		z_index = 52,
		-- direction = 2,
	})
end
local function set_hud_text(player, text)
	if players[player].hud_id then
		player:hud_change(players[player].hud_id, "text", text)
	end
end

function world_builder.hud_display(player, text)
	local p_data = players[player]
	if p_data.job then
		p_data.job:cancel()
	end
	set_hud_text(player, text)
	p_data.job = minetest.after((#text * 0.125) + 1, function()
		set_hud_text(player, "")
		p_data.job = nil
	end)
end

minetest.register_on_joinplayer(function(player, last_login)
	players[player] = {}
	add_hud(player)
end)

minetest.register_on_leaveplayer(function(player, timed_out)
	if p_data.job then
		p_data.job:cancel()
	end
	remove_hud(player)
	players[player] = nil
end)
