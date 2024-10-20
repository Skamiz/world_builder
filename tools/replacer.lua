local modname = minetest.get_current_modname()
local modprefix = modname .. ":"


local function replacer_inv_to_table(player)
	local inv = player:get_inventory()

	local from_list = inv:get_list("replacer_from")
	local to_list = inv:get_list("replacer_to")

	local replacements = {}

	for i = 10, 1, -1 do
		local f = from_list[i]
		local t = to_list[i]
		if (not f:is_empty()) and (not t:is_empty()) then
			replacements[f:get_name()] = t:get_name()
		end
	end

	return replacements
end
local function replace(pos1, pos2, replacements, player)
	local minp, maxp = vector.sort(pos1, pos2)
	local va = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local positions, nodes = {}, {}
	for i in va:iterp(minp, maxp) do
		local pos = va:position(i)
		local node = minetest.get_node(pos)
		if replacements[node.name] then
			node.name = replacements[node.name]
			table.insert(positions, pos)
			table.insert(nodes, node)
		end
	end

	world_builder.execute_with_undo(player, minp, maxp, function()
		for k, pos in pairs(positions) do
			minetest.swap_node(pos, nodes[k])
		end
		return "Replace Nodes"
	end)
end
world_builder.replace = replace

local function save_replacer_inv_to_meta(player, itemstack)
	if not itemstack then itemstack = player:get_wielded_item() end
	local meta = itemstack:get_meta()
	local inv = player:get_inventory()

	local from_list = inv:get_list("replacer_from")
	local to_list = inv:get_list("replacer_to")
	for k, v in pairs(from_list) do
		from_list[k] = v:to_string()
	end
	for k, v in pairs(to_list) do
		to_list[k] = v:to_string()
	end

	meta:set_string("from_list", minetest.serialize(from_list))
	meta:set_string("to_list", minetest.serialize(to_list))

	player:set_wielded_item(itemstack)
	return itemstack
end
local function load_replacer_inv_from_meta(player, itemstack)
	if not itemstack then itemstack = player:get_wielded_item() end
	local meta = itemstack:get_meta()
	local inv = player:get_inventory()

	local from_list = meta:get("from_list")
	local to_list = meta:get("to_list")

	if from_list then
		from_list = minetest.deserialize(from_list)
	else
		from_list = {}
	end
	if to_list then
		to_list = minetest.deserialize(to_list)
	else
		to_list = {}
	end

	inv:set_list("replacer_from", from_list)
	inv:set_list("replacer_to", to_list)
end
local function swap_replacer_direction(player)
	local inv = player:get_inventory()

	local from_list = inv:get_list("replacer_from")
	local to_list = inv:get_list("replacer_to")

	inv:set_list("replacer_from", to_list)
	inv:set_list("replacer_to", from_list)
end



local function get_replacer_formspec(player)
	load_replacer_inv_from_meta(player)
	local fs = {
		"button[10,-1;2.25,0.75;swap_replacements;Invert]",
		"tooltip[swap_replacements;Switch replacement direction.]",
		"list[current_player;replacer_from;0,0;10,1]",
		"listring[]",
		"list[current_player;replacer_to;0,2;10,1]",
		"listring[current_player;replacer_to]",
	}

	for i = 1, 10 do
		fs[#fs + 1] = "image[" .. (i - 1) * 1.25 .. ",1;1,1;wb_swap_arrow.png]"
	end
	fs = table.concat(fs)
	return fs
end

local function show_replacer_fs(player)
	local fs = {
		"formspec_version[6]",
		"size[12.75,10.75,false]",
		"container[0.25,0.25]",
		palette.get_creative_form(player),
		"container_end[]",
		"container[0.25,7.5.25]",
		get_replacer_formspec(player),
		"container_end[]",
	}
	fs = table.concat(fs)
	minetest.show_formspec(player:get_player_name(), modprefix .."formspec_replacer", fs)
end
palette.register_callbacks(modprefix .."formspec_replacer", show_replacer_fs)

minetest.register_craftitem(modprefix .."tool_replacer", {
	short_description = "Replacer",
	description = "Replacer"
			.. "\n" .. minetest.colorize("#e3893b", "LMB") .. ": Swap nodes."
			.. "\n" .. minetest.colorize("#3dafd2", "RMB") .. ": Configuration."
	,
	inventory_image = "wb_tool_replacer.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		local pos1, pos2 = world_builder.get_area(user)
		if not (pos1 and pos2) then
			world_builder.hud_display(user, "You first need to select an area.")
			return
		end
		load_replacer_inv_from_meta(user, itemstack)
		local replacements = replacer_inv_to_table(user)
		replace(pos1, pos2, replacements, user)
	end,
	on_place = function(itemstack, placer, pointed_thing)
		show_replacer_fs(placer)
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		show_replacer_fs(user)
	end,
})

minetest.register_on_joinplayer(function(player, last_login)
	local inv = player:get_inventory()
	inv:set_size("replacer_from", 10)
	inv:set_size("replacer_to", 10)

end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= modprefix .. "formspec_replacer" then return end

	if fields.swap_replacements then
		swap_replacer_direction(player)
	end
	save_replacer_inv_to_meta(player)
end)
