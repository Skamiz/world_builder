local modname = minetest.get_current_modname()

-- is it possible ot make it so that scrolling in the page number showing area scrolls through the pages?
-- make a pallete item, which then can be used in place of other nodes as desired

-- pallete object which can display itself as a formspec element, on click opens menu which allows editing the pallete
-- pallete editable from pallete ?and player inv

palette = {}
local players = {}

local master_palette = {}
palette.master_palette = master_palette
minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_nodes) do
		if not (def.groups and (def.groups.not_in_creative_inventory or def.groups.not_in_palette)) then
			master_palette[#master_palette + 1] = name .. " " .. def.stack_max
		end
	end
	master_palette[#master_palette + 1] = "air 99"
	table.sort(master_palette)
end)


local function get_filtered_list(search_text)
	if not search_text or (search_text == "") then
		return table.copy(master_palette)
	end
	local list = {}
	for k, node in pairs(master_palette) do
		if node:find(search_text) then
			list[#list + 1] = node
		end
	end
	return list
end

local function update_pallete(player)
	local context = players[player:get_player_name()]
	local list = get_filtered_list(context.search_text)
	context.list = list
	context.current_page = math.min(context.current_page, math.ceil(#context.list/40))
	local inv = context.palette_inv
	-- +1 so that it's possible to shiftclick items into it
	inv:set_size("main", #list + 1)
	inv:set_list("main", list)
end


function palette.get_creative_form(player)
	local name = player:get_player_name()
	local context = players[name]
	local meta = player:get_meta()

	local fs = ""
		.. "list[detached:palette_" .. name .. ";main;0,1;10,4;" .. math.max((context.current_page * 40) - 40, 0) .. "]"
		.. "field[0,0;3,0.75;search_text;;" .. context.search_text .. "]"
		.. "field_close_on_enter[search_text;false]"
		.. "button[3,0;0.75,0.75;palette_search;S]"
		.. "tooltip[palette_search;Search]"
		.. "button[4,0;0.75,0.75;palette_clear;C]"
		.. "tooltip[palette_clear;Clear Search]"
		.. "button[8.75,0;0.75,0.75;palette_prev;P]"
		.. "tooltip[palette_prev;Previous Page]"
		.. "button[11.5,0;0.75,0.75;palette_next;N]"
		.. "tooltip[palette_next;Next Page]"
		.. "label[10.25,0.375;" .. context.current_page .. "/" .. math.ceil(#context.list/40) .. "]"

	return fs
end

-- When the palette needs to update the formspec then it will do so by calling the callback.
function palette.register_callbacks(form_name, callback)
	minetest.register_on_player_receive_fields(function(player, formname, fields)
		if formname ~= form_name then return end

		local context = players[player:get_player_name()]

		if fields.palette_next then
			context.current_page = math.min(context.current_page + 1, math.ceil(#context.list/40))
			callback(player)
			return true
		end
		if fields.palette_prev then
			context.current_page = math.max(context.current_page - 1, 1)
			callback(player)
			return true
		end
		if fields.palette_clear then
			context.search_text = ""
			update_pallete(player)
			callback(player)
			return true
		end
		if fields.palette_search or (fields.key_enter and fields.key_enter_field == "search_text") then
			context.search_text = fields.search_text
			update_pallete(player)
			callback(player)
			return true
		end
	end)
end


local palette_callbacks = {
    allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
		return 0
	end,
    allow_put = function(inv, listname, index, stack, player)
		return -1
	end,
    allow_take = function(inv, listname, index, stack, player)
		return -1
	end,
}

minetest.register_on_joinplayer(function(player, last_login)
	local name = player:get_player_name()
	players[name] = {
		current_page = 1,
		search_text = "",
		palette_inv = minetest.create_detached_inventory("palette_" .. name, palette_callbacks)
	}
	update_pallete(player)
end)

minetest.register_on_leaveplayer(function(player, timed_out)
	local name = player:get_player_name()
	players[name] = nil
	minetest.remove_detached_inventory("palette_" .. name)
end)

local function show_test_fs(player)
	local fs = ""
	.. "formspec_version[6]"
	.. "size[12.75,13,false]"
	.. "list[current_player;main;0.25,8;10,4]"
	.. "container[0.25,0.25]"
	.. palette.get_creative_form(player)
	.. "container_end[]"
	.. "listring[]"

	minetest.show_formspec(player:get_player_name(), modname ..":testing", fs)
end
palette.register_callbacks(modname ..":testing", show_test_fs)
