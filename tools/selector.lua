local modname = minetest.get_current_modname()
local modprefix = modname .. ":"


local players = {}
local pointing_distance = 4.5

-- get rounded pointed_pos for area selction tool
local function get_pointed_pos(player)
	return vector.round(world_builder.pointed_pos(player, pointing_distance, "under"))
end

-- HUD section
local v1 = vector.new(1, 1, 1)
local function get_hud_string(player)
	local pos_1, pos_2 = world_builder.get_area(player)
	local pointed_pos = get_pointed_pos(player)

	pos_1 = pos_1 or pointed_pos
	pos_2 = pos_2 or pointed_pos

	local size = pos_1 - pos_2
	size.x = math.abs(size.x) + 1
	size.y = math.abs(size.y) + 1
	size.z = math.abs(size.z) + 1
	local s = {
		"Pos_1: ",
		minetest.pos_to_string(pos_1),
		"\nPos_2: ",
		minetest.pos_to_string(pos_2),
		"\nSize: ",
		minetest.pos_to_string(size),
	}
	s = table.concat(s)
	return s
end

local function add_hud(player)
	players[player].hud_id = player:hud_add({
		hud_elem_type = "text",
		position = {x = 0, y = 1},
		alignment = {x = 1, y = -1},
		name = "selection area info",
		text = get_hud_string(player),
		-- number = 0xe3893b,
		z_index = 53,
		direction = 2,
	})
end
local function remove_hud(player)
	player:hud_remove(players[player].hud_id)
	players[player].hud_id = nil
end
local function update_hud(player)
	-- minetest.chat_send_player(player:get_player_name(), "updating area selection hud")
	player:hud_change(players[player].hud_id, "text", get_hud_string(player))
end


-- object managment togethere with functionality section
do
	-- WARNING: if texture is made any more transparent it will become completely invissible
	local tex = "wb_pixel.png^[opacity:129"
	local scale = 1.002
	minetest.register_entity(modprefix .."selector", {
		pointable = false,
		visual = "cube",
		visual_size = {x = scale, y = scale, z = scale},
		textures = {tex, tex, tex, tex, tex, tex},
		use_texture_alpha = true,
		-- is_visible = true,
		-- backface_culling = false,
		glow = -1,
		static_save = false,
	})
end

-- creates and moves object denoting selected area
local one_node_vector = vector.new(1.001, 1.001, 1.001)
local function update_selection(player, pos_1, pos_2)
	local p_data = players[player]

	-- if a position isn't provided use indicator pos a backup
	pos_1 = pos_1 or p_data.pos_1.pos
	pos_2 = pos_2 or p_data.pos_2.pos

	-- if no position is selected remove selection object
	if not (pos_1 or pos_2) then
		if p_data.selection then
			p_data.selection:remove()
			p_data.selection = nil
		end
		return
	end
	if not (pos_1 and pos_2) then
		pos_1 = pos_1 or pos_2
		pos_2 = get_pointed_pos(player)
	end

	-- if selection entity doesn' exist, create it
	-- TODO: this should be moved to the on_change_wield section, maybe
	if not p_data.selection or p_data.selection:get_pos() == nil then
		p_data.selection = minetest.add_entity(player:get_pos(), modprefix .."selector")
		local t = "wb_pixel.png^[colorize:#c8c837^[opacity:129"
		p_data.selection:set_properties({textures = {t, t, t, t, t, t}})
	end

	local minp, maxp = vector.sort(pos_1, pos_2)

	local dif = maxp - minp
	p_data.selection:set_properties({visual_size = (dif + one_node_vector)})
	local mid = dif / 2
	p_data.selection:set_pos(minp + mid)
end

-- creates and moves pos_1, pos_2, and selector objects
local function set_indicator_position(player, indicator, pos)
	local ind = players[player][indicator]
	-- if it doesn't exist already, create it
	if not ind.obj or ind.obj:get_pos() == nil then
		ind.obj = minetest.add_entity(pos, modprefix .."selector")
		ind.obj:set_properties({textures = {ind.tex, ind.tex, ind.tex, ind.tex, ind.tex, ind.tex}})
		ind.pos = pos
	end
	-- only set new pos when it's different from the previous one
	if not pos:equals(ind.pos) then
		ind.pos = pos
		ind.obj:set_pos(ind.pos)
	end

	update_selection(player)
	update_hud(player)
end

-- also could have used marker instead of indicator, oh well
local function remove_indicator(player, indicator)
	local ind = players[player][indicator]
	ind.pos = nil
	if ind.obj then ind.obj:remove() end
	ind.obj = nil
	update_selection(player)
	update_hud(player)
end


-- API section
function world_builder.set_area(player, pos_1, pos_2)
	local p_data = players[player]

	set_indicator_position(player, "pos_1", pos_1)
	set_indicator_position(player, "pos_2", pos_2)
end

function world_builder.get_area(player)
	local p_data = players[player]
	-- if one or both positions aren't set 'nil' is returned in teir stead
	return p_data.pos_1.pos, p_data.pos_2.pos
end


-- Tool section
local function use_selector(player, indicator)
	if player:get_player_control().aux1 then
		remove_indicator(player, indicator)
	else
		local pos = get_pointed_pos(player)
		set_indicator_position(player, indicator, pos)
	end
end

minetest.register_craftitem(modprefix .."selector", {
	description = "Area Selector"
			.. "\n" .. minetest.colorize("#e3893b", "LMB") .. ": Set pos_1."
			.. "\n" .. minetest.colorize("#3dafd2", "RMB") .. ": Set pos_2."
			.. "\n" .. minetest.colorize("#67a943", "Aux1") .. " + " .. minetest.colorize("#e3893b", "LMB") .. ": Unset pos_1."
			.. "\n" .. minetest.colorize("#67a943", "Aux1") .. " + " .. minetest.colorize("#3dafd2", "RMB") .. ": Unset pos_2."
	,
	short_description = "Area Selector",
	inventory_image = "wb_selector.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		use_selector(user, "pos_1")
	end,
	on_place = function(itemstack, placer, pointed_thing)
		use_selector(placer, "pos_2")
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		use_selector(user, "pos_2")
	end,
})



-- handling updates section
minetest.register_on_joinplayer(function(player, last_login)
	players[player] = {
		active = false,
		selection = nil,
		selector = {tex = "wb_pos_selector.png^[opacity:129"},
		pos_1 = {tex = "wb_pos_1.png^[colorize:#e3893b^[opacity:129"},
		pos_2 = {tex = "wb_pos_2.png^[colorize:#3dafd2^[opacity:129"},
		hud_id = nil,
		pointed_pos = nil,
	}
end)

minetest.register_on_leaveplayer(function(player, timed_out)
	local p_data = players[player]
	if p_data.selector.obj:get_pos() then p_data.selector.obj:remove() end
	if p_data.pos_1.obj:get_pos() then p_data.pos_1.obj:remove() end
	if p_data.pos_2.obj:get_pos() then p_data.pos_2.obj:remove() end
	if p_data.selection:get_pos() then p_data.selection:remove() end
	players[player] = nil

end)

minetest.register_globalstep(function(dtime)
	for player, p_data in pairs(players) do
		if p_data.active then
			local old_pos = p_data.pointed_pos
			local new_pos = get_pointed_pos(player)
			if new_pos ~= old_pos then
				set_indicator_position(player, "selector", new_pos)
				p_data.pointed_pos = new_pos
				local pos_1, pos_2 = p_data.pos_1.pos, p_data.pos_2.pos
				if (pos_1 or pos_2) and not (pos_1 and pos_2) then
					update_selection(player)
				end
			end
		end
	end
end)

world_builder.register_on_change_wielded(function(player, new_item, old_item)
	local p_data = players[player]
	local select = new_item == modprefix .. "selector"
	local deselect = old_item == modprefix .. "selector"

	if deselect and not select then
		p_data.active = false

		if p_data.selector.pos then
			remove_indicator(player, "selector")
			if p_data.selection then
				p_data.selection:remove()
				p_data.selection = nil
			end
		end
		remove_hud(player)
	end
	if select and not deselect then
		p_data.active = true
		add_hud(player)
		update_selection(player)
		set_indicator_position(player, "selector", get_pointed_pos(player))
	end
end)
