wheel_menu = {}
--[[
{
	name = "name"
	options = {
		{name = "foobar", description = S("FooBar"), image = "dingus.png"},
		{name = "foobar", description = S("FooBar"), image = "dingus.png"},
		{name = "foobar", description = S("FooBar"), image = "dingus.png"},
		{name = "foobar", description = S("FooBar"), image = "dingus.png"},
	},
	callback = function(player, selected_option_name) end,

	last_look_dir = {},*
	selected_option = n,*
	hud_ids = {
		{description_id = n, image_id = n},
		{description_id = n, image_id = n},
		{description_id = n, image_id = n},
		{description_id = n, image_id = n},
	},*
}
]]
local players = {}

local function create_menu_item(player, rotation, description, image)
	rotation = math.rad(rotation * 360)
	local offset = vector.new(math.sin(rotation), -math.cos(rotation), 0) * (32*6)
	local description_id, image_id

	if image then
		image_id = player:hud_add({
			name = "wheel_menu_item_image",
			position = {x = 0.5, y = 0.5},
			z_index = 120,
			type = "image",
			text = image,
			scale = {x = 4, y = 4},
			offset = offset,
		})
		offset = offset + vector.new(0, -48, 0)
	end
	if description then
		description_id = player:hud_add({
			name = "wheel_menu_item_description",
			position = {x = 0.5, y = 0.5},
			z_index = 121,
			type = "text",
			text = description,
			offset = offset,
		})
	end

	return description_id, image_id
end

wheel_menu.show = function(player, menu_def)
	if wheel_menu.get_active(player) then
		wheel_menu.abort(player)
	end
	menu_def = table.copy(menu_def)
	if not menu_def.name then menu_def.name = "wheel_menu" end

	players[player] = menu_def

	-- innitial look direction
	menu_def.ver = player:get_look_vertical()
	menu_def.hor = player:get_look_horizontal()

	-- create hud elements and save their ids
	menu_def.hud_ids = {}
	local item_count = #menu_def.options

	for i, menu_item in ipairs(menu_def.options) do
		if not menu_item.name then
			menu_item.name = "menu_item_" .. i
		end
		local description, image
		if not (menu_item.description or menu_item.image) then
			description = menu_item.name
		else
			description = menu_item.description
			image = menu_item.image
		end
		local description_id, image_id = create_menu_item(player, (i - 1) / item_count, description, image)
		table.insert(menu_def.hud_ids, {
			description_id = description_id,
			image_id = image_id,
		})
	end

	table.insert(menu_def.hud_ids, {image_id = player:hud_add({
		name = "wheel_menu_background_circle",
		position = {x = 0.5, y = 0.5},
		z_index = 111,
		type = "image",
		text = "wb_wheel_menu.png",
		scale = {x = 4, y = 4},
	})})
end

local function clear_hud(player)
	local menu = players[player]
	for _, ids in pairs(menu.hud_ids) do
		if ids.description_id then
			player:hud_remove(ids.description_id)
		end
		if ids.image_id then
			player:hud_remove(ids.image_id)
		end
	end
end
local function remove_wheel(player)
	if not wheel_menu.get_active(player) then return false end
	clear_hud(player)
	players[player] = nil
	return true
end

wheel_menu.abort = function(player, name)
	if name and name ~= players[player].name then return end
	remove_wheel(player)
end

wheel_menu.confim_selection = function(player, name)
	local active_menu = wheel_menu.get_active(player)
	if not active_menu then return end
	if name and name ~= active_menu then return end

	local menu_def = players[player]
	local selected = menu_def.selected or "no_selection"

	if menu_def.callback then
		menu_def.callback(player, selected)
	end

	remove_wheel(player)
	return selected
end

wheel_menu.get_active = function(player)
	if players[player] then
		return players[player].name
	else
		return false
	end
end

local function calculate_look_dir(last_ver, last_hor, new_ver, new_hor)
	local d_ver = new_ver - last_ver
	local d_hor = new_hor - last_hor

	if d_ver == 0 and d_hor == 0 then return end

	-- acount for wraparound
	if math.abs(d_hor) > math.pi then
		d_hor = (-math.sign(d_hor) * 2 * math.pi + new_hor) - last_hor
	end

	-- filter out very small movemnts, since they are often enorous
	if math.abs(d_ver) < 0.02 and math.abs(d_hor) < 0.02 then return end

	-- angle is 0 at 12 o'clock and increases counter clock wise
	local angle = math.atan2(d_hor, d_ver) + math.pi
	angle = math.deg(angle)
	return angle
end


local function angle_to_selected_index(item_count, angle)
	local offset = 360 / (item_count * 2)
	angle = angle + offset

	if angle >= 360 then
		angle = angle - 360
	end

	local index = math.ceil((angle / 360) * item_count)

	return index
end

local function select_hud(player, menu_item_index)
	if not menu_item_index then return end
	local menu_data = players[player]
	local option = menu_data.hud_ids[menu_item_index]
	if option.image_id then
		player:hud_change(option.image_id, "scale", {x = 5, y = 5})
	end
	if option.description_id then
		player:hud_change(option.description_id, "style", 1)
	end
	-- SOUND: click of an item being selected
end
local function deselect_hud(player, menu_item_index)
	if not menu_item_index then return end
	local menu_data = players[player]
	local option = menu_data.hud_ids[menu_item_index]
	if option.image_id then
		player:hud_change(option.image_id, "scale", {x = 4, y = 4})
	end
	if option.description_id then
		player:hud_change(option.description_id, "style", 0)
	end
end

local function track_eye_movement(dtime)
	for player, menu_data in pairs(players) do
		local new_ver = player:get_look_vertical()
		local new_hor = player:get_look_horizontal()

		local angle = calculate_look_dir(menu_data.ver, menu_data.hor, new_ver, new_hor)
		menu_data.hor = new_hor
		menu_data.ver = new_ver

		if angle then
			local selected_index = angle_to_selected_index(#menu_data.options, angle)
			local selected = menu_data.options[selected_index].name

			if selected_index ~= menu_data.selected_index then
				deselect_hud(player, menu_data.selected_index)
				select_hud(player, selected_index)

				menu_data.selected_index = selected_index
				menu_data.selected = selected
			end
		end
	end
end

minetest.register_globalstep(track_eye_movement)



-- just debug stuff
--------------------------------------------------------------------------------
if not world_builder.debug_toos then return end

minetest.register_craftitem(world_builder.modprefix .."wheel_menu_dev", {
	short_description = "wheel_menu",
	description = "wheel_menu\ndev item",
	inventory_image = "wb_wheel_menu_item.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		wheel_menu.confim_selection(user)
	end,
	on_place = function(itemstack, placer, pointed_thing)
		wheel_menu.abort(placer)
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		wheel_menu.show(user, {
			name = "debug_wheel_menu",
			options = {
				{name = "one", description = "One", image = "wb_random_node.png"},
				{name = "two", image = "wb_undo.png"},
				{name = "three", description = "Three"},
				{name = "four"},
				{},
			},
			callback = function(player, selected)
				minetest.chat_send_player(player:get_player_name(), selected)
			end,
		})
	end,
})
