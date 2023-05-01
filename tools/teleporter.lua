local modname = minetest.get_current_modname()
local modprefix = modname .. ":"


--[[
A tool for fast relocation
- LMB to teleport forward
	- +aux1 to teleport backward

TODO:
	formspec cleanup
	a more elaobrate description of the waypoint system in the formspec?
	set formspec focus to a button

]]

-- waypiont stuff
local players = {}

local function save_waypoints(player)
	local waypoints = players[player]
	local meta = player:get_meta()
	meta:set_string("waypoints", minetest.serialize(waypoints))
end

local function load_waypoints(player)
	local meta = player:get_meta()
	local waypoints = meta:get("waypoints")

	if not waypoints then
		players[player] = {}
		save_waypoints(player)
		return
	end

	players[player] = minetest.deserialize(waypoints)
end

minetest.register_on_joinplayer(function(player, last_login)
	load_waypoints(player)
end)

minetest.register_on_leaveplayer(function(player, timed_out)
	save_waypoints(player)
	players[player] = nil
end)


local function add_waypoint(player, waypoint_name)
	local waypoints = players[player]
	local waypoint = {
		name = waypoint_name,
		pos = player:get_pos(),
		yaw = player:get_look_horizontal(),
		pitch = player:get_look_vertical(),
	}
	table.insert(waypoints, waypoint)
	save_waypoints(player)
end

local function remove_waypoint(player, i)
	local waypoints = players[player]
	table.remove(waypoints, i)
	save_waypoints(player)
	return
end

local function go_to_waypoint(player, i)
	local waypoint = players[player][i]
	player:set_pos(waypoint.pos)
	player:set_look_horizontal(waypoint.yaw)
	player:set_look_vertical(waypoint.pitch)
end


-- formspec stuff
local function get_waypoint_fs(player)
	local fs = {}
	local waypoints = players[player]
	for i, waypoint in ipairs(waypoints) do
		local x = math.floor((i-1)/10) * 4
		local y = ((i-1) % 10) + 1.75
		-- fs[#fs + 1] = "label[" .. x .. "," .. y + 1 .. ";" .. minetest.pos_to_string(vector.round(waypoint.pos)) .. "]"
		fs[#fs + 1] = "button[" .. x .. "," .. y .. ";3,0.75;goto_" .. i .. ";" .. waypoint.name .. "]"
		fs[#fs + 1] = "tooltip[goto_" .. i .. ";" .. minetest.pos_to_string(vector.round(waypoint.pos)) .. "]"
		fs[#fs + 1] = "button[" .. x + 3.0 .. "," .. y .. ";0.75,0.75;remove_" .. i .. ";X]"
		fs[#fs + 1] = "tooltip[remove_" .. i .. ";Remove waypoint]"
	end
	fs = table.concat(fs)
	return fs
end
local function get_teleporter_fs(player, wielded)
	local fs = {
		"field[0,0;3,0.75;waypoint_name;Waypoint Name:;]",
		"set_focus[add_waypoint;false]",
		"button[3,0;1,0.75;add_waypoint;Add]",
		"tooltip[add_waypoint;Add new waypoint to the list]",
	}
	fs = table.concat(fs)
	return fs
end
local function show_teelporter_fs(player, wielded)
	wielded = wielded or player:get_wielded_item()
	local fs = {
		"formspec_version[6]",
		"size[12.75,12.5,false]",
		"container[0.5,0.5]",
		get_teleporter_fs(player, wielded),
		get_waypoint_fs(player),
		"container_end[]",
		"field[8.5,0.5;1.5,0.75;distance;TP distance:;" .. wielded:get_meta():get_string("distance") .. "]",
		"tooltip[distance;Overrides the distance teleported when using LMB (default: 32)]",
		"checkbox[10.5,0.875;noclip_mode;Noclip mode;" .. wielded:get_meta():get_string("noclip_mode") .. "]",
		"tooltip[noclip_mode;Enable if you want to teleport into terrain, rather then just to the surface.]",
	}
	fs = table.concat(fs)
	minetest.show_formspec(player:get_player_name(), modprefix .."teleporter", fs)
end


local function teleport_forward(player, distance, noclip)
	print(noclip)
	distance = distance or 32
	-- if aux1 then go backwards
	distance = player:get_player_control().aux1 and -distance or distance
	noclip = noclip or false

	local dir = player:get_look_dir()
	local pos = player:get_pos()
	local target_pos = pos + dir * distance

	if not noclip then
		local eye_offset = player:get_eye_offset()
		eye_offset.y = eye_offset.y + player:get_properties().eye_height
		-- collision detection is lifted to eye hight to be more intuitive
		local ray = minetest.raycast(pos + eye_offset, target_pos + eye_offset, false, false)

		local pt = ray:next()
		if pt then
			target_pos = pt.above
		end
	end

	player:set_pos(target_pos)
end

minetest.register_craftitem(modprefix .."tool_teleporter", {
	description = "Teleporter"
			.. "\n" .. minetest.colorize("#e3893b", "LMB") .. ": Teleport forward."
			.. "\n" .. minetest.colorize("#67a943", "Aux1") .. " + " .. minetest.colorize("#e3893b", "LMB") .. ": Teleport backward."
			.. "\n" .. minetest.colorize("#3dafd2", "RMB") .. ": Options."
	,
	short_description = "Teleporter",
	inventory_image = "wb_tool_teleporter.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		local meta = itemstack:get_meta()
		local distance = meta:get("distance")
		if distance then distance = tonumber(distance) end
		local noclip_mode = meta:get_string("noclip_mode") == "true"

		teleport_forward(user, distance, noclip_mode)
	end,
	on_place = function(itemstack, placer, pointed_thing)
		show_teelporter_fs(placer, itemstack)
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		show_teelporter_fs(user, itemstack)
	end,
})


minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= modprefix .."teleporter" then return end

	if fields.add_waypoint or fields.key_enter_field == "waypoint_name" then
		local waypoint_name = fields.waypoint_name
		if not type(waypoint_name) == "string" or waypoint_name == "" then
			minetest.chat_send_player(player:get_player_name(), "Couldn't add waypoint. Invalid waypoint name.")
			return true
		end
		add_waypoint(player, waypoint_name)
		show_teelporter_fs(player)
	end

	for field, v in pairs(fields) do
		local goto_index = field:match("goto_(%d+)")
		if goto_index then
			go_to_waypoint(player, tonumber(goto_index))
		end
		local remove_index = field:match("remove_(%d+)")
		if remove_index then
			remove_waypoint(player, tonumber(remove_index))
			show_teelporter_fs(player)
		end
	end

	if fields.noclip_mode or tonumber(fields.distance) then
		local wielded = player:get_wielded_item()
		if wielded:get_name() ~= modprefix .."tool_teleporter" then return end
		local meta = wielded:get_meta()
		if fields.noclip_mode then
			meta:set_string("noclip_mode", fields.noclip_mode)
		end
		if tonumber(fields.distance) then
			meta:set_string("distance", fields.distance)
		end
		player:set_wielded_item(wielded)
	end

	return true
end)
