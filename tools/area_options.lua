local modname = minetest.get_current_modname()
local modprefix = modname .. ":"

--[[
TODO: it might be worth it to eventually split mirroring into into it's own thing
	with a sparate item which doesn't use formspecs, but the players look direction
	and position instead
	mirror can be placed in world to act while the player is building
	by punching the mirror a player can register/unregister themselves so their
	node placemnt/digging is mirrored along the mirrors configured axes
	consider: digging is only mirrored to nodes which are the same as the dug one

	nodebox node mirroring
	when the mirroring tables are generated add them to the nodes def

	button to fix light in area

	The individual placement functions shouldn't be player reliant and they should be globaly acessible

TODO: split area opperations to their own file
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
		"padding[0,0]",
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
		"tooltip[build_wall;Builds a wall between pos_1 to pos_2.]",

		"button[0,7;1.75,0.75;count_nodes;Count Nodes]",
		"tooltip[count_nodes;Show node counts in selected area.]",
		"button[0,8;1.75,0.75;fix_undefined;Fix Undefined]",
		"tooltip[fix_undefined;replace undefined nodes in selected area.]",
	}

	fs = table.concat(fs)

	minetest.show_formspec(player:get_player_name(), modprefix .."area_options", fs)
end


minetest.register_craftitem(modprefix .."area_options", {
	short_description = "Area Options (WIP)",
	description = "Area Options (WIP)"
			.. "\n" .. minetest.colorize("#e3893b", "LMB") .. ": Options."
	,
	inventory_image = "wb_area_options.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		show_fs(user)
	end,
})

local function get_node_counts(pos1, pos2)
	local minp, maxp = vector.sort(pos1, pos2)
	local va = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local nodes = {}

	for i in va:iterp(minp, maxp) do
		local node = minetest.get_node(va:position(i))
		if not nodes[node.name] then
			nodes[node.name] = 0
		end
		nodes[node.name] = nodes[node.name] + 1
	end
	nodes["air"] = nil

	local sorted_nodes = {}
	for name, count in pairs(nodes) do
		table.insert(sorted_nodes, {name = name, count = count})
	end
	table.sort(sorted_nodes, function(a, b)
		return a.count > b.count
	end)
	return sorted_nodes
end
local function show_node_count_formspec(player)
	local pos1, pos2 = world_builder.get_area(player)
	local sorted_nodes = get_node_counts(pos1, pos2)

	if #sorted_nodes == 0 then
		world_builder.hud_display(player, "Selected area is empty.")
		return
	end

	local fs = {
		"formspec_version[6]",
		"size[10.25,10.75,false]",
		"container[0.5,0.5]",
	}
	for i, node in ipairs(sorted_nodes) do
		local def = minetest.registered_nodes[node.name]
		local description = def and def.description or node.name

		-- local x = (math.floor((i - 1) / 8) * 2) * 1.25
		-- local y = ((i - 1) % 8) * 1.25
		local x = ((i - 1) % 4) * 2 * 1.25
		local y = math.floor((i - 1) / 4) * 1.25


		fs[#fs + 1] = "item_image[" .. x .. "," .. y .. ";1,1;" .. node.name .. "]"
		fs[#fs + 1] = "tooltip[" .. x .. "," .. y .. ";1,1;" .. description .. "]"
		fs[#fs + 1] = "label[" .. x + 1 .. "," .. y + 0.5 .. ";" .. " x " .. node.count .. "]"
	end
	fs[#fs + 1] = "container_end[]"

	fs = table.concat(fs)
	minetest.show_formspec(player:get_player_name(), modprefix .."area_options", fs)
end


local function mirror_area(pos1, pos2, axis, direction, player)
	local minp, maxp = vector.sort(pos1, pos2)
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

local function fill_volume(pos1, pos2, node, player)
	local minp, maxp = vector.sort(pos1, pos2)
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
local function fill_surface(pos1, pos2, node, player)
	local minp, maxp = vector.sort(pos1, pos2)
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
local function fill_frame(pos1, pos2, node, player)
	local minp, maxp = vector.sort(pos1, pos2)
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

local function draw_line(pos1, pos2, node, player)
	local direction = pos2 - pos1

	local length = math.max(math.abs(direction.x), math.abs(direction.y), math.abs(direction.z))
	direction = direction / length

	world_builder.execute_with_undo(player, pos1, pos2, function()
		for n = 0, length do
			local pos = pos1 + (direction * n)
			minetest.set_node(pos:round(), node)
		end
		return "Draw Line"
	end)
end
local function build_wall(pos1, pos2, node, axis, player)
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


local function fix_undefined(pos1, pos2, player)

	local undefined_nodes = world_builder.get_undefined_nodes_in_area(pos1, pos2)
	local callback = function(replacements)
		world_builder.replace(pos1, pos2, replacements, player)
	end
	world_builder.show_replace_undefined_fs(player, undefined_nodes, callback)
end



minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= modprefix .."area_options" then return end

	local pos1, pos2 = world_builder.get_area(player)
	if not (pos1 and pos2) then
		world_builder.hud_display(player, "You first need to select an area.")
		return true
	end

	-- mirroring
	for k, v in pairs(fields) do
		if k:match("[xyz][+-]") then
			local axis, direction = k:match("([xyz])([+-])")
			mirror_area(pos1, pos2, axis, direction, player)
		end
	end

	if fields.clear_area then
		fill_volume(pos1, pos2, {name = "air"}, player)
	end
	if fields.count_nodes then
		show_node_count_formspec(player)
	end

	local node_name = get_first_node(player)
	if not node_name then
		world_builder.hud_display(player, "You first need to select an area.")
		return true
	end

	if fields.fill_volume then
		fill_volume(pos1, pos2, {name = node_name}, player)
	end
	if fields.fill_surface then
		fill_surface(pos1, pos2, {name = node_name}, player)
	end
	if fields.fill_frame then
		fill_frame(pos1, pos2, {name = node_name}, player)
	end
	if fields.draw_line then
		draw_line(pos1, pos2, {name = node_name}, player)
	end
	if fields.build_wall then
		build_wall(pos1, pos2, {name = node_name}, "y", player)
	end
	if fields.fix_undefined then
		fix_undefined(pos1, pos2, player)
	end
	return true
end)
