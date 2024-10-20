

local players = {}

local function save_undef_nodes(player, nodes, callback)
	players[player] = {
		nodes = nodes,
		callback = callback,
	}
end
local function clear_undef_nodes(player)
	players[player] = nil
end


local function show_replace_undefined_fs(player, nodes, callback)
	save_undef_nodes(player, nodes, callback)
	local p_name = player:get_player_name()
	local inv = minetest.create_detached_inventory("fix_nodes_" .. p_name)
	inv:set_size("main", #nodes)

	local fs = {
		"formspec_version[6]",
		"size[10,10,false]",
		"padding[0,0]",
		"list[current_player;main;0,5;8,5;0]",
		"button_exit[5,0;3,0.75;apply_undef_rep;Apply Replacements]",
	}
	if #nodes <= 4 then
		fs[#fs + 1] = "container[0,0]"
		fs[#fs + 1] = "list[detached:fix_nodes_" .. p_name .. ";main;3.25,0;1,50;0]"
		fs[#fs + 1] = "listring[]"
		for n, node_name in ipairs(nodes) do
			fs[#fs + 1] = "label[0," .. ((n - 1) * 1.25) + 0.5 .. ";" .. node_name .. "]"
		end
		fs[#fs + 1] = "container_end[]"
	else
		fs[#fs + 1] = "scrollbaroptions[min=0;max=" .. (#nodes - 3) * 10 .. "]"
		fs[#fs + 1] = "scrollbar[4.5,0;0.25,4.75;vertical;s_bar;0]"
		fs[#fs + 1] = "scroll_container[0,0;4.75,4.75;s_bar;vertical;0.1]"
		fs[#fs + 1] = "list[detached:fix_nodes_" .. p_name .. ";main;3.25,0;1,50;0]"
		fs[#fs + 1] = "listring[]"
		for n, node_name in ipairs(nodes) do
			fs[#fs + 1] = "label[0," .. ((n - 1) * 1.25) + 0.5 .. ";" .. node_name .. "]"
		end
		fs[#fs + 1] = "scroll_container_end[]"
	end


	fs = table.concat(fs)
	-- return fs

	minetest.show_formspec(player:get_player_name(), world_builder.modprefix .."fix_undefined", fs)
end
world_builder.show_replace_undefined_fs = show_replace_undefined_fs

local function get_undefined_nodes_in_area(pos1, pos2)
	local minp, maxp = vector.sort(pos1, pos2)
	local va = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local undefined = {}

	for i in va:iterp(minp, maxp) do
		local node = minetest.get_node_or_nil(va:position(i))
		if not minetest.registered_nodes[node.name] then
			undefined[node.name] = true
		end
	end

	local nodes = {}
	for node_name, _ in pairs(undefined) do
		table.insert(nodes, node_name)
	end
	table.sort(nodes)

	return nodes
end
world_builder.get_undefined_nodes_in_area = get_undefined_nodes_in_area




minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= world_builder.modprefix .."fix_undefined" then return end
	print(formname)
	print(dump(fields))
	if fields.apply_undef_rep then
		local inv_location = {
			type = "detached",
			name = "fix_nodes_" .. player:get_player_name()
		}
		local inv = minetest.get_inventory(inv_location)

		local undef_nodes = players[player].nodes

		local replacements = {}

		for i, u_node in ipairs(undef_nodes) do
			local r_node = inv:get_stack("main", i):get_name()
			if r_node ~= "" and minetest.registered_nodes[r_node] then
				replacements[u_node] = r_node
			end
		end

		players[player].callback(replacements)

		clear_undef_nodes(player)
		minetest.remove_detached_inventory("fix_nodes_" .. player:get_player_name())
	end

	if fields.quit then
		clear_undef_nodes(player)
		minetest.remove_detached_inventory("fix_nodes_" .. player:get_player_name())
	end


end)
