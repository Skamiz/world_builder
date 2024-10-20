local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local modprefix = modname .. ":"

local players = {}

-- buttons copy/cut/paste
-- TODO: gridsnapp
-- TODO: individual clipboards
-- TODO: multiplier for placement distance based on schem size should be a player option not a tool option
-- TODO: when in fixed_pos mode add buttons to the formspec for moving pos along axes for finetunig of large schems

-- TODO: consider making the path game specific so as to limit schems to world in which they could potentially work
local schem_path = world_builder.schem_path
minetest.mkdir(schem_path)


local vector_1 = vector.new(1, 1, 1)

-- preview positioning section
local function move_preview(player, pos)
	local p_data = players[player]
	if p_data.fixed_pos or pos == p_data.ghost.pos then return end
	p_data.ghost:set_placement(pos)
end

local function update_flag_string(player)
	local opt = players[player].options

	local t = {}
	for flag, bool in pairs(opt.flags) do
		if bool then
			t[#t + 1] = flag
		end
	end
	opt.flag_string = table.concat(t, ", ")
end

local function rotate_schematic(player, angle)
	local p_data = players[player]
	if not p_data.ghost then return end

	local rot = p_data.options.rot
	rot = rot + angle
	if rot > 270 then rot = rot - 360 end
	if rot < 0 then rot = rot + 360 end
	p_data.options.rot = rot

	p_data.ghost:set_placement(nil, rot)
end


-- clipboard section
local function copy_area_to_clipboard(player)
	local pos1, pos2 = world_builder.get_area(player)
	if not (pos1 and pos2) then
		world_builder.hud_display(player, "You first must select an area to copy.")
		return
	end
	local p_data = players[player]
	p_data.fixed_pos = nil


	local place_air  = p_data.options.place_air

	local schem = world_builder.schematics.make_schematic(pos1, pos2, place_air and 255 or 0)
	p_data.schem = schem

	p_data.distance = math.max(schem.size.x, schem.size.y, schem.size.z)/1.5 + 3
	p_data.options.rot = 0
	p_data.formspec.name = "un-named"

	if p_data.ghost then p_data.ghost:delete() end
	local ghost = world_builder.schem_prev.new(schem, player)
	ghost:set_placement(nil, nil, p_data.options.flags)
	p_data.ghost = ghost
end

local function cut_area_to_clipboard(player)
	copy_area_to_clipboard(player)
	local pos1, pos2 = world_builder.get_area(player)
	if not (pos1 and pos2) then
		world_builder.hud_display(player, "You first must select an area to cut.")
		return
	end
	local node = {name = "air"}

	local minp, maxp = vector.sort(pos1, pos2)
	local va = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})
	local all_pos = {}
	for i in va:iterp(minp, maxp) do
		table.insert(all_pos, va:position(i))
	end
	world_builder.execute_with_undo(player, minp, maxp, function()
		minetest.bulk_set_node(all_pos, node)
		return "Cut selection"
	end)

	world_builder.set_area(player, nil, nil)
end

local function place_from_clipboard(player, pos)
	local p_data = players[player]
	pos = p_data.fixed_pos or pos
	p_data.fixed_pos = nil


	local schem = p_data.schem
	local options = p_data.options
	if not schem.data then
		world_builder.hud_display(player, "Nothing to place. The clipboard is empty.")
		return
	end

	local size = vector.copy(schem.size)
	if options.rot == 90 or options.rot == 270 then
		size.x, size.z = size.z, size.x
	end

	local minp = vector.copy(pos)
	for flag, bool in pairs(options.flags) do
		local axis = flag:sub(-1)
		if bool then
			minp[axis] = minp[axis] - math.floor((size[axis] - 1)/2)
		end
	end
	local maxp = minp + (size - vector_1)

	world_builder.execute_with_undo(player, minp, maxp, function()
		minetest.place_schematic(pos, schem, tostring(options.rot), nil, options.force_placement, options.flag_string)
		return "Placed schematic"
	end)
end


local function get_schem_list(player)
	local list = minetest.get_dir_list(schem_path, false)
	players[player].formspec.list = list

	local s = "textlist[0,1;4,4;schem_select;"
	for k, v in pairs(list) do
		s = s .. v .. ","
	end
	if #list > 0 then
		s = s:sub(1, -2)
	end
	s = s .. "]"

	return s
end

local function show_clipboard_fs(player)
	local opt = players[player].options
	local fs = {
		"formspec_version[6]",
		"size[6.5,12,false]",
		"container[0.5,0.5]",
		"container[0,0]",
		"button[0,0;1.5,0.75;copy;Copy]",
		"tooltip[copy;Copy selection to clipboard]",
		"button[2,0;1.5,0.75;cut;Cut]",
		"tooltip[cut;Copy selection to clipboard and clear selected area]",
		"button[4,0;1.5,0.75;paste;Paste]",
		"tooltip[paste;Place current schem into the world]",
		"button[0,1;1.5,0.75;rotate90;Rotate 90°]",
		"tooltip[rotate90;Rotate schematic preview 90° clockwise]",
		"button[2,1;1.5,0.75;rotate270;Rotate -90°]",
		"tooltip[rotate270;Rotate schematic preview 90° counter-clockwise]",
		"button[4,1;1.5,0.75;fixate;Fixate]",
		"tooltip[fixate;Fix/Unfix current preview position in space]",
		"button[4,2;1.5,0.75;clear;Clear CB]",
		"tooltip[clear;Clears current schematic from clipboard]",
		"button[4,4;1.5,0.75;replace_undefined;Fix Undef]",
		"tooltip[replace_undefined;Show formspec to replace undefined nodes in schematic preview]",
		"container_end[]",
		"set_focus[place_air;true]",
		"container[0,2.5]",
		"label[0,0;Schematic placement options:]",
		"checkbox[0,0.5;place_center_x;place_center_x;" .. tostring(opt.flags.place_center_x) .. "]",
		"checkbox[0,1;place_center_y;place_center_y;" .. tostring(opt.flags.place_center_y) .. "]",
		"checkbox[0,1.5;place_center_z;place_center_z;" .. tostring(opt.flags.place_center_z) .. "]",
		"checkbox[3,0.5;force_placement;force_placement;" .. tostring(opt.force_placement) .. "]",
		"checkbox[3,1;place_air;place_air;" .. tostring(opt.place_air) .. "]",
		"container_end[]",
		"container[0.75,5]",
		-- "set_focus[schem_name;true]",
		"field[0,0;2,0.75;schem_name;file name;" .. minetest.formspec_escape(players[player].formspec.name) .. "]",
		"button[2.25,0;1.5,0.75;save;Save]",
		"tooltip[save;Save schematic to file]",
		"button[0.25,5.25;1.5,0.75;load;Load]",
		"tooltip[load;Load selected schematic from file]",
		"button[2.25,5.25;1.5,0.75;delete;Delete]",
		"tooltip[delete;Delete selected schematic file]",
		get_schem_list(player),
		"container_end[]",
		"container_end[]",
	}

	fs = table.concat(fs)
	minetest.show_formspec(player:get_player_name(), modprefix .. "clipboard", fs)
end

local function load_from_file(player, file)
	local p_data = players[player]
	p_data.fixed_pos = nil

	local s = minetest.read_schematic(schem_path .. "/" .. file, {write_yslice_prob = "none"})

	p_data.schem.data = s.data
	p_data.schem.size = s.size

	p_data.distance = math.max(s.size.x, s.size.y, s.size.z)/2 + 4
	p_data.options.rot = 0

	for _, node in pairs(s.data) do
		if node.name == "air" then
			if node.prob == 0 then
				p_data.options.place_air = false
			elseif node.prob >= 254 then
				p_data.options.place_air = true
			end
			break
		end
	end

	p_data.formspec.name = file:sub(1, -5)

	-- make_preview(player)
	if p_data.ghost then p_data.ghost:delete() end
	local ghost = world_builder.schem_prev.new(p_data.schem, player)
	ghost:set_placement(nil, nil, players[player].options.flags)
	p_data.ghost = ghost
	show_clipboard_fs(player)
end

local function clipboard_lmb(player)
	if player:get_player_control().aux1 then
		copy_area_to_clipboard(player)
	elseif player:get_player_control().sneak then
		rotate_schematic(player, -90)
	else
		show_clipboard_fs(player)
	end
end

local function clipboard_rmb(player)
	local p_data = players[player]
	local pos = vector.round(world_builder.get_looked_pos(player, players[player].distance))
	if player:get_player_control().aux1 then
		if p_data.ghost then
			if p_data.fixed_pos then
				p_data.fixed_pos = nil
			elseif p_data.ghost.obj then
				p_data.fixed_pos = pos
			end
		end
	elseif player:get_player_control().sneak then
		rotate_schematic(player, 90)
	else
		place_from_clipboard(player, pos)
	end
end

minetest.register_craftitem(modprefix .."clipboard", {
	description = "Area Clipboard"
			.. "\n" .. minetest.colorize("#e3893b", "LMB") .. ": Clipboard options."
			.. "\n" .. minetest.colorize("#3dafd2", "RMB") .. ": Place clipboard schem."
			.. "\n" .. minetest.colorize("#ff7070", "Sneak") .. " + " .. minetest.colorize("#e3893b", "LMB") .. ": Rotate right."
			.. "\n" .. minetest.colorize("#ff7070", "Sneak") .. " + " .. minetest.colorize("#3dafd2", "RMB") .. ": Rotate left."
			.. "\n" .. minetest.colorize("#67a943", "Aux1") .. " + " .. minetest.colorize("#e3893b", "LMB") .. ": Copy area to clipboard."
			.. "\n" .. minetest.colorize("#67a943", "Aux1") .. " + " .. minetest.colorize("#3dafd2", "RMB") .. ": Fixate preview."
	,
	short_description = "Area Clipboard",
	inventory_image = "wb_clipboard.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		clipboard_lmb(user)
	end,
	on_place = function(itemstack, placer, pointed_thing)
		clipboard_rmb(placer)
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		clipboard_rmb(user)
	end,
})

minetest.register_on_joinplayer(function(player, last_login)
	players[player] = {
		-- schematic info
		schem = {
			data = nil,
			size = nil,
		},

		-- placement options
		options = {
			rot = 0,
			force_placement = false,
			place_air = false,
			flags = {
				place_center_x = true,
				place_center_y = false,
				place_center_z = true,
			},
			flag_string = "place_center_x, place_center_z",
		},
		-- preview stuff
		fixed_pos = nil,
		distance = 5,
		obj = nil,
		visible = true,

		-- saving and loading
		formspec = {
			list = nil,
			name = "un-named",
			selected = nil,
		},
	}
end)

minetest.register_on_leaveplayer(function(player, timed_out)
	if players[player].ghost then players[player].ghost:delete() end
	players[player] = nil
end)

minetest.register_globalstep(function(dtime)
	for player, p_data in pairs(players) do
		if p_data.ghost then
			if player:get_wielded_item():get_name() == modprefix .."clipboard" then
				if not p_data.visible then
					p_data.visible = true
					p_data.ghost:show()
						if p_data.fixed_pos then
							-- WARNING: for some reason larger previews fail to be moved
							p_data.ghost:set_placement(p_data.fixed_pos)
						end
				end

				local new_pos = vector.round(world_builder.get_looked_pos(player, p_data.distance))
				move_preview(player, new_pos)

			elseif p_data.visible then
				p_data.visible = false
				p_data.ghost:hide()
			end
		end
	end
end)

local function print_table(t)
	for k, v in pairs(t) do
		minetest.chat_send_all(type(k) .. " : " .. tostring(k) .. " | " .. type(v) .. " : " .. tostring(v))
		-- print(type(k) .. " : " .. tostring(k) .. " | " .. type(v) .. " : " .. tostring(v))
	end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= modprefix .."clipboard" then return end
	-- print_table(fields)
	local p_data = players[player]
	local opt = p_data.options

	if fields.copy then
		copy_area_to_clipboard(player)
	end
	if fields.cut then
		cut_area_to_clipboard(player)
	end
	if fields.paste then
		local pos = vector.round(world_builder.get_looked_pos(player, players[player].distance))
		place_from_clipboard(player, pos)
	end
	if fields.rotate90 then
		rotate_schematic(player, 90)
	end
	if fields.rotate270 then
		rotate_schematic(player, -90)
	end
	if fields.fixate then
		local pos = vector.round(world_builder.get_looked_pos(player, players[player].distance))
		if p_data.ghost then
			if p_data.fixed_pos then
				p_data.fixed_pos = nil
			elseif p_data.ghost.obj then
				p_data.fixed_pos = pos
			end
		end
	end
	if fields.clear then
		local p_data = players[player]
		p_data.options.rot = 0
		p_data.formspec.name = "un-named"
		if p_data.ghost then p_data.ghost:delete() end
		p_data.ghost = nil
		p_data.schem = {}
	end
	if fields.replace_undefined then
		if not p_data.schem.data then return true end
		local undefined_nodes = world_builder.schematics.find_undefined_nodes(p_data.schem)
		local callback = function(replacements)
			if not replacements then return end
			p_data.schem = world_builder.schematics.apply_replacements(p_data.schem, replacements)
			if p_data.ghost then p_data.ghost:delete() end
			p_data.ghost = world_builder.schem_prev.new(p_data.schem, player)
			p_data.ghost:set_placement(nil, nil, p_data.options.flags)
			p_data.formspec.name = "un-named"
		end
		world_builder.show_replace_undefined_fs(player, undefined_nodes, callback)
	end


	-- schematic flags
	if fields.force_placement then
		opt.force_placement = not opt.force_placement
	end
	if fields.place_air then
		opt.place_air = not opt.place_air
		if not p_data.schem.data then return true end
		world_builder.schematics.set_node_probability(p_data.schem, "air", opt.place_air and 255 or 0)
	end

	for flag, bool in pairs(opt.flags) do
		if fields[flag] then
			opt.flags[flag] = not opt.flags[flag]
			if not p_data.schem.data then return true end
			p_data.ghost:set_placement(nil, nil, opt.flags)
			update_flag_string(player)
		end
	end

	-- schematic saving/loading
	if fields.save then
		if not p_data.schem.data then
			world_builder.hud_display(player, "Can't save an empty clipboard.")
			return true
		end
		if fields.schem_name == "" then
			world_builder.hud_display(player, "Cant save schematic under an empty name.")
			return true
		end
		world_builder.schematics.save(fields.schem_name, p_data.schem)
		show_clipboard_fs(player)
	end

	if fields.load then
		local file = p_data.formspec.list[p_data.formspec.selected]
		if not file then
			world_builder.hud_display(player, "No file selected.")
			return true
		end
		load_from_file(player, file)
	end
	if fields.delete then
		local file = p_data.formspec.list[p_data.formspec.selected]
		if not file then
			world_builder.hud_display(player, "No file selected.")
			return true
		end
		os.remove(schem_path .. "/" .. file)
		-- minetest.close_formspec(player:get_player_name(), modprefix .. "clipboard")
		show_clipboard_fs(player)
	end

	if fields.schem_select and fields.schem_select:find("CHG") then
		local index = tonumber(fields.schem_select:match("%d+"))
		p_data.formspec.selected = index
		p_data.formspec.name = p_data.formspec.list[index]:sub(1, -5)
		show_clipboard_fs(player)
	end
	if fields.schem_select and fields.schem_select:find("DCL") then
		local index = tonumber(fields.schem_select:match("%d+"))
		local file = p_data.formspec.list[index]
		load_from_file(player, file)
	end
	if fields.quit then
		p_data.formspec.selected = nil
	end

	return true
end)
