-- allows registering callbacks for when the players wielded item changes

local players = {}
local registered_on_change_wielded = {}

world_builder.register_on_change_wielded = function(callback)
	table.insert(registered_on_change_wielded, callback)
end

local function call_callbacks(player, new_item, old_item)
	for k_, callback in pairs(registered_on_change_wielded) do
		callback(player, new_item, old_item)
	end
end

minetest.register_on_joinplayer(function(player, last_login)
	players[player] = {
		index = player:get_wield_index(),
		item = player:get_wielded_item():get_name(),
	}
	minetest.after(0.001, call_callbacks, player, players[player].item, nil)
end)

minetest.register_on_leaveplayer(function(player, timed_out)
	players[player] = nil
end)


minetest.register_globalstep(function(dtime)
	for player, wielded in pairs(players) do
		local new_index = player:get_wield_index()
		local new_item = player:get_wielded_item():get_name()
		if new_index ~= wielded.index or new_item ~= wielded.item then
			call_callbacks(player, new_item, wielded.item)
			wielded.index = new_index
			wielded.item = new_item
		end
	end
end)
