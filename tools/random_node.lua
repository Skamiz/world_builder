--[[
Goal:
	TODO: param2 override
	TODO: placement mode which works by distance like area selector
	automatic percentage display
	TODO:There is some console warning when the node is used before being configured?
	TODO: don't close formspec when enter is pressend in text field

	Might be nice to have replacement mode as a geenral player setting rather than being item bound.
--]]
local function print_table(t)
	for k, v in pairs(t) do
		minetest.chat_send_all(type(k) .. " : " .. tostring(k) .. " | " .. type(v) .. " : " .. tostring(v))
	end
end



-- because serialize can't handle ItemStack userdata
local function inventory_to_table(invref)
	local inventory = {}
	for name, list in pairs(invref:get_lists()) do
		inventory[name] = {}
		for i, itemstack in pairs(list) do
			inventory[name][i] = itemstack:to_string()
		end
	end
	return inventory
end

local function stretch_list(list)
	local sl = {}
	for k, item in pairs(list) do
		local itemstack = ItemStack(item)
		for i = 1, itemstack:get_count() do
			sl[#sl + 1] = itemstack:get_name()
		end
	end
	return sl
end

local modname = minetest.get_current_modname()
local mod_prefix = modname .. ":"


local function get_random_node_fs(player)
	local itemstack = player:get_wielded_item()
	local meta = itemstack:get_meta()
	local fs = {
		"field[0,0;3,0.75;stack_name;;" .. (minetest.formspec_escape(meta:get("description")) or itemstack:get_short_description()) .. "]",
		"field_close_on_enter[search_text;false]",
		"button[3,0;0.75,0.75;save;R]",
		"tooltip[save;Rename Item]",
		"checkbox[4,0.375;replace_mode;Replace Mode;" .. meta:get_string("replace") .. "]",
		"tooltip[replace_mode;Replace pointed node instead of building on top of it.]",
		"list[detached:random_node;main;0,1;10,1]",
	}
	fs = table.concat(fs)
	return fs
end
local function show_random_node_formspec(player)
	local fs = {
		"formspec_version[6]",
		"size[12.75,9.75,false]",
		"container[0.25,0.25]",
		palette.get_creative_form(player),
		"container_end[]",
		"container[0.25,6.5.25]",
		color_picker.get_color_picker_fs(16),
		"container_end[]",
		"container[0.25,7.5.25]",
		get_random_node_fs(player),
		"container_end[]",
		"listring[]",
	}
	fs = table.concat(fs)
	minetest.show_formspec(player:get_player_name(), mod_prefix .."random_node", fs)
end

palette.register_callbacks(mod_prefix .."random_node", show_random_node_formspec)

local function random_node_rmb(itemstack, player, pointed_thing)
	local controls = player:get_player_control()
	if controls.aux1 and not controls.sneak then
		local meta = itemstack:get_meta()
		if meta:get("replace") == "true" then
			meta:set_string("replace", "false")
			world_builder.hud_display(player, "Replacement mode: off")
		else
			meta:set_string("replace", "true")
			world_builder.hud_display(player, "Replacement mode: on")
		end
		return itemstack
	elseif pointed_thing.type == "node" and not (controls.aux1 and controls.sneak) then
		local meta = itemstack:get_meta()
		local list = minetest.deserialize(meta:get("stretched"))
		if not list or #list == 0 then return end
		local node = list[math.random(#list)]
		local def = minetest.registered_nodes[node]
		if meta:get("replace") == "true" then
			-- minetest.set_node(pointed_thing.under, {name = node})
			minetest.remove_node(pointed_thing.under)
			def.on_place(ItemStack(node), player, pointed_thing)
		else
			def.on_place(ItemStack(node), player, pointed_thing)
		end
	else--if controls.aux1 and controls.sneak then
		local meta = itemstack:get_meta()
		local inv = minetest.create_detached_inventory("random_node")
		inv:set_lists(minetest.deserialize(meta:get("inv")) or {})
		inv:set_size("main", 10)

		show_random_node_formspec(player)
	end
end

minetest.register_node(mod_prefix .."random_node", {
	short_description = "Random Node",
	description = "Random Node"
			.. "\n" .. minetest.colorize("#67a943", "Aux1") .. " + " .. minetest.colorize("#3dafd2", "RMB") .. ": Toggle replacement mode."
			.. "\n" .. minetest.colorize("#67a943", "Aux1") .. " + " .. minetest.colorize("#ff7070", "Sneak") .. " + " .. minetest.colorize("#3dafd2", "RMB") .. ": Configuration."
	,
	tiles = {"wb_random_node.png"},
	overlay_tiles = {{name = "wb_random_node_overlay.png", color = "#fff"}},
	node_placement_prediction = "",
	stack_max = 1,
	groups = {not_in_palette = 1},
	on_place = random_node_rmb,
	on_secondary_use = random_node_rmb,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= mod_prefix .."random_node" then return end
	-- print_table(fields)

	local wield = player:get_wielded_item()
	local meta = wield:get_meta()
	local inv = minetest.get_inventory({type = "detached", name = "random_node"})

	meta:set_string("inv", minetest.serialize(inventory_to_table(inv)))
	meta:set_string("stretched", minetest.serialize(stretch_list(inv:get_list("main"))))
	if fields.replace_mode then
		meta:set_string("replace", fields.replace_mode)
	end
	if fields.stack_name and (fields.save or fields.key_enter_field == "stack_name") then
		meta:set_string("description", fields.stack_name)
	end
	-- meta:set_string("description", "minetest.serialize(inventory_to_table(inv))")

	player:set_wielded_item(wield)
	-- only remove on inventory close
	-- minetest.remove_detached_inventory("random_node")
end)
