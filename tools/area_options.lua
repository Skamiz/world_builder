local modname = minetest.get_current_modname()
local modprefix = modname .. ":"

--[[
TODO: it might be worth it to eventually split mirroring into into it's own thing
	with a sparate item which doesn't use formspecs, but the players look direction
	and position instead
	mirror can be place din world to act while the player is building
	on unloading it deactivates and has to be activated to be effective again

	Move all of "You first need to select an area" code to the begining of formspec recieve

]]

-- get first node from the players inventory
local function get_first_node(player)
	local inv = player:get_inventory()
	local list = inv:get_list("main")
	for _, stack in pairs(list) do
		local node_name = stack:get_name()
		if minetest.registered_nodes[node_name] then
			return node_name
		end
	end
	return false
end

local function show_fs(player)
	local fs = {
		"formspec_version[6]",
		"size[10,10,false]",
		"container[0,0]",
		"label[1.125,0.5;Mirror:]",
		"button[0.125,1;0.75,0.75;x+;+X]",
		"tooltip[x+;Mirror selection towards the East]",
		"button[0.125,2;0.75,0.75;x-;-X]",
		"tooltip[x-;Mirror selection towards the West]",
		"button[1.125,1;0.75,0.75;y+;+Y]",
		"tooltip[y+;Mirror selection upwards.]",
		"button[1.125,2;0.75,0.75;y-;-Y]",
		"tooltip[y-;Mirror selection downwards.]",
		"button[2.125,1;0.75,0.75;z+;+Z]",
		"tooltip[z+;Mirror selection towards the North.]",
		"button[2.125,2;0.75,0.75;z-;-Z]",
		"tooltip[z-;Mirror selection towards the South.]",
		"container_end[]",

		"container[4,0]",
		"label[1.75,0.5;Fill:]",
		"button[0.25,1;1.5,0.75;clear_area;Air]",
		"tooltip[clear_area;Replace everyting in selected area with air.]",
		"button[2.25,1;1.5,0.75;fill_volume;Volume]",
		"tooltip[fill_volume;Fill selected area with first node from inventory.]",
		"button[0.25,2;1.5,0.75;fill_surface;Surface]",
		"tooltip[fill_surface;Fill surface of selected area with first node from inventory.]",
		"button[2.25,2;1.5,0.75;fill_frame;Frame]",
		"tooltip[fill_frame;Build frame around selected area with first node from inventory.]",
		"container_end[]",

		"button[0,5;1.5,0.75;draw_line;Line]",
		"tooltip[draw_line;Draws a line from pos_1 to pos_2.]",
		"button[0,6;1.5,0.75;build_wall;Wall]",
		"tooltip[draw_line;Builds a wall between pos_1 to pos_2.]",
	}

	fs = table.concat(fs)

	minetest.show_formspec(player:get_player_name(), modprefix .."area_options", fs)
end


minetest.register_craftitem(modprefix .."area_options", {
	short_description = "Area Option",
	description = "Area Option (WIP)",
	inventory_image = "wb_area_options.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		show_fs(user)
	end,
})

local function mirror_area(player, axis, direction)
	local p1, p2 = world_builder.get_area(player)
	if not (p1 and p2) then
		minetest.chat_send_player(player:get_player_name(), "You first need to select an area.")
		return
	end

	local minp, maxp = vector.sort(p1, p2)
	local schem = world_builder.schematics.make_schematic(minp, maxp, 255)

	schem = world_builder.schematics.mirror(schem, axis)

	local target_pos = vector.new(minp)
	local offset = (maxp[axis] - minp[axis]) + 1
	if direction == "-" then offset = -offset end
	target_pos[axis] = target_pos[axis] + offset
	world_builder.execute_with_undo(player, target_pos, target_pos + schem.size, function()
		minetest.place_schematic(target_pos, schem, "0", nil, true, nil)
		return "Mirror Area"
	end)
end

local function fill_volume(player, node)
	local p1, p2 = world_builder.get_area(player)
	if not (p1 and p2) then
		minetest.chat_send_player(player:get_player_name(), "You first need to select an area.")
		return
	end

	local minp, maxp = vector.sort(p1, p2)
	local va = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local all_pos = {}
	for i in va:iterp(minp, maxp) do
		table.insert(all_pos, va:position(i))
	end
	world_builder.execute_with_undo(player, minp, maxp, function()
		minetest.bulk_set_node(all_pos, node)
		return "Fill Volume"
	end)
end

local axes = {"x", "y", "z"}
local function num_matching(pos, minp, maxp)
	local matching = 0
	for _, axis in pairs(axes) do
		if pos[axis] == minp[axis] or pos[axis] == maxp[axis] then
			matching = matching + 1
		end
	end
	return matching
end
local function fill_surface(player, node)
	local p1, p2 = world_builder.get_area(player)
	if not (p1 and p2) then
		minetest.chat_send_player(player:get_player_name(), "You first need to select an area.")
		return
	end

	local minp, maxp = vector.sort(p1, p2)
	local va = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local all_pos = {}
	for i in va:iterp(minp, maxp) do
		local pos = va:position(i)
		if pos.x == minp.x or pos.x == maxp.x or
			pos.y == minp.y or pos.y == maxp.y or
			pos.z == minp.z or pos.z == maxp.z then
			table.insert(all_pos, pos)
		end
	end

	world_builder.execute_with_undo(player, minp, maxp, function()
		minetest.bulk_set_node(all_pos, node)
		return "Fill Surface"
	end)
end
local function fill_frame(player, node)
	local p1, p2 = world_builder.get_area(player)
	if not (p1 and p2) then
		minetest.chat_send_player(player:get_player_name(), "You first need to select an area.")
		return
	end

	local minp, maxp = vector.sort(p1, p2)
	local va = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local all_pos = {}
	for i in va:iterp(minp, maxp) do
		local pos = va:position(i)
		if num_matching(pos, minp, maxp) >= 2 then
			table.insert(all_pos, pos)
		end
	end

	world_builder.execute_with_undo(player, minp, maxp, function()
		minetest.bulk_set_node(all_pos, node)
		return "Fill Frame"
	end)
end

local function draw_line(player, node)
	local p1, p2 = world_builder.get_area(player)
	if not (p1 and p2) then
		minetest.chat_send_player(player:get_player_name(), "You first need to select an area.")
		return
	end

	local direction = p2 - p1

	local length = math.max(math.abs(direction.x), math.abs(direction.y), math.abs(direction.z))
	direction = direction / length

	world_builder.execute_with_undo(player, p1, p2, function()
		for n = 0, length do
			local pos = p1 + (direction * n)
			minetest.set_node(pos:round(), node)
		end
		return "Draw Line"
	end)
end
local function build_wall(player, node, axis)
	local pos1, pos2 = world_builder.get_area(player)
	if not (pos1 and pos2) then
		minetest.chat_send_player(player:get_player_name(), "You first need to select an area.")
		return
	end
	axis = axis or "y"
	local direction = pos2 - pos1
	local length = math.max(math.abs(direction.x), math.abs(direction.y), math.abs(direction.z))
	direction = direction / length

	world_builder.execute_with_undo(player, pos1, pos2, function()
		for n = 0, length do
			local pos = pos1 + (direction * n)
			for n = math.min(pos1[axis], pos2[axis]), math.max(pos1[axis], pos2[axis]) do
				local w_pos = vector.new(pos)
				w_pos[axis] = n
				minetest.set_node(w_pos:round(), node)
			end
		end
		return "Build Wall"
	end)
end



minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= modprefix .."area_options" then return end

	for k, v in pairs(fields) do
		if k:match("[xyz][+-]") then
			local axis, direction = k:match("([xyz])([+-])")
			mirror_area(player, axis, direction)
			return true
		end
	end
	if fields.clear_area then
		fill_volume(player, {name = "air"})
		return true
	end
	if fields.fill_volume then
		local node_name = get_first_node(player)
		if node_name then
			fill_volume(player, {name = node_name})
		else
			minetest.chat_send_player(player:get_player_name(), "You need at least one node in your inventory.")
		end
		return true
	end
	if fields.fill_surface then
		local node_name = get_first_node(player)
		if node_name then
			fill_surface(player, {name = node_name})
		else
			minetest.chat_send_player(player:get_player_name(), "You need at least one node in your inventory.")
		end
		return true
	end
	if fields.fill_frame then
		local node_name = get_first_node(player)
		if node_name then
			fill_frame(player, {name = node_name})
		else
			minetest.chat_send_player(player:get_player_name(), "You need at least one node in your inventory.")
		end
		return true
	end
	if fields.draw_line then
		local node_name = get_first_node(player)
		if node_name then
			draw_line(player, {name = node_name})
		else
			minetest.chat_send_player(player:get_player_name(), "You need at least one node in your inventory.")
		end
		return true
	end
	if fields.build_wall then
		local node_name = get_first_node(player)
		if node_name then
			build_wall(player, {name = node_name})
		else
			minetest.chat_send_player(player:get_player_name(), "You need at least one node in your inventory.")
		end
		return true
	end

end)
