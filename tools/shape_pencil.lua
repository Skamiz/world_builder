--[[
pencil, for drawign simple geometric shapes

shapes to be added:
	circle/donut
	wall/slope
	pyramid
	cylinder
	triangle/quadrat?
]]

local pencil = {}
local pencil_description = table.concat({
	"Shape Pencil",
	minetest.colorize("#e3893b", "LMB") .. ": Draw.",
	minetest.colorize("#3dafd2", "RMB") .. ": Select draw node.",
	minetest.colorize("#67a943", "Aux1") .. ": Configure.",
}, "\n")
--------------------------------------------------------------------------------
-- shape definitions
--------------------------------------------------------------------------------
pencil.shapes = {
	["line"] = {
		name = "line",
		-- icon = "wb_shape_line.png",
		-- description = "Line",
		points_required = 2,
		get_node_positions = function(pos1, pos2)
			-- IMPORTANT: without this safeguard a 0 length line causes not just
			-- Luanti, but the whole PC to freeze, had to hard reboot
			if pos1 == pos2 then return {pos1} end

			local direction = pos2 - pos1
			local length = math.max(math.abs(direction.x), math.abs(direction.y), math.abs(direction.z))
			direction = direction / length
			local positions = {}

			for n = 0, length do
				local pos = pos1 + (direction * n)
				table.insert(positions, pos:round())
			end

			return positions
		end,
		get_draw_description = function(node, pos1, pos2)
			local desc = "Draw line from %s to %s, using '%s'."
			return desc:format(pos1, pos2, node.name)
		end,
		-- get_preview_obj = function(pos) end,
		-- position_preview = function(obj, pos1, pos2) end,
	},
	["cube"] = {
		name = "cube",
		points_required = 2,
		get_node_positions = function(pos1, pos2)
			local minp, maxp = vector.sort(pos1, pos2)
			local positions = {}

			for x = minp.x, maxp.x do
				for y = minp.y, maxp.y do
					for z = minp.z, maxp.z do
						local pos = vector.new(x, y, z)
						table.insert(positions, pos)
					end
				end
			end

			return positions
		end,
		get_draw_description = function(node, pos1, pos2)
			local desc = "Draw cube from %s to %s, using '%s'."
			return desc:format(pos1, pos2, node.name)
		end,
	},
	["sphere"] = {
		name = "sphere",
		points_required = 2,
		get_node_positions = function(pos1, pos2)
			local delta = pos2 - pos1
			local radius = delta:length()
			local rounded_r = math.ceil(radius)
			local positions = {}

			for x = pos1.x - rounded_r, pos1.x + rounded_r do
				for y = pos1.y - rounded_r, pos1.y + rounded_r do
					for z = pos1.z - rounded_r, pos1.z + rounded_r do
						local pos = vector.new(x, y, z)
						if (pos - pos1):length() <= radius then
							table.insert(positions, pos)
						end
					end
				end
			end

			return positions
		end,
		get_draw_description = function(node, pos1, pos2)
			local radius = (pos2 - pos1):length()
			local desc = "Draw sphere at %s with radius %.1f, using '%s'."
			return desc:format(pos1, radius, node.name)
		end,
	},
}

--------------------------------------------------------------------------------
-- pencil configuration section
--------------------------------------------------------------------------------
local function set_draw_node(itemstack, node)
	local meta = itemstack:get_meta()
	meta:set_string("node_name", node.name)
	meta:set_int("node_param2", node.param2)
	pencil.update_pencil_description(itemstack)
end
local function get_draw_node(itemstack)
	local meta = itemstack:get_meta()

	if not meta:contains("node_name") then return end

	local node_name = meta:get_string("node_name")
	local node_param2 = meta:get_int("node_param2")

	local node = {name = node_name, param2 = node_param2}

	return node
end

local function set_draw_shape(itemstack, shape)
	local meta = itemstack:get_meta()
	meta:set_string("shape", shape)
	pencil.update_pencil_description(itemstack)
end
local function get_draw_shape(itemstack)
	local meta = itemstack:get_meta()
	local shape = meta:get("shape") or "line"

	return shape
end

local function set_draw_mode(itemstack, mode)
	local meta = itemstack:get_meta()
	meta:set_string("mode", mode)
	pencil.update_pencil_description(itemstack)
end
local function get_draw_mode(itemstack)
	local meta = itemstack:get_meta()
	local mode = meta:get("mode") or "fill"

	return mode
end

function pencil.update_pencil_description(itemstack)
	local meta = itemstack:get_meta()
	local node = get_draw_node(itemstack)
	local shape = get_draw_shape(itemstack)
	local mode = get_draw_mode(itemstack)

	local node_string
	if node then
		node_string = "node: " .. node.name .. " " .. node.param2
	else
		node_string = "node: -nil-"
	end
	local shape_string = "shape: " .. shape
	local mode_string = "mode: " .. mode

	local description = {
		pencil_description,
		node_string,
		shape_string,
		mode_string,
	}
	description = table.concat(description, "\n")

	meta:set_string("description", description)
end

local menu_def = {
	name = "pencil_config",
	options = {
		{name = "shape_cube", description = "Cube", image = "wb_shape_cube.png"},
		{name = "shape_sphere", description = "Sphere", image = "wb_shape_sphere.png"},
		{name = "mode_erase", description = "Erase", image = nil},
		-- {name = "mode_hollow", description = "Hollow", image = nil},
		{name = "mode_fill", description = "Fill", image = nil},
		{name = "shape_line", description = "Line", image = "wb_shape_line.png"},
	},
	callback = function(player, selected)
		local wielded = player:get_wielded_item()
		if selected == "no_selection" then return end
		if wielded:get_name() ~= world_builder.modprefix .."tool_shape_pencil" then return end

		local category, selection = selected:match("^(%a+)_(%a+)$")
		if category == "shape" then
			set_draw_shape(wielded, selection)
		elseif category == "mode" then
			set_draw_mode(wielded, selection)
		else
			minetest.chat_send_player(player:get_player_name(), "There is no callback for your selection: '" .. selected .. "'. This is probabaly a bug.")
		end

		player:set_wielded_item(wielded)
	end,
}
inputs.register_callback(function(player, key, event, time_since_pressed)
	local wielded = player:get_wielded_item()
	if wielded:get_name() == world_builder.modprefix .."tool_shape_pencil" then
		wheel_menu.show(player, menu_def)
	end
end, "aux1", "pressed")
inputs.register_callback(function(player, key, event, time_since_pressed)
	wheel_menu.confim_selection(player, "pencil_config")
end, "aux1", "released")
world_builder.register_on_change_wielded(function(player, new_item, old_item)
	if wheel_menu.get_active(player) == "pencil_config" then
		wheel_menu.abort(player, "pencil_config")
	end
end)


--------------------------------------------------------------------------------
-- active drawing section
--------------------------------------------------------------------------------
-- currently active drawing actions indexed by player
local drawers = {}

local function start_drawing(player, pencil)
	local data = {
		node = get_draw_node(pencil),
		shape = get_draw_shape(pencil),
		mode = get_draw_mode(pencil),

		points = {},
		point_objects = {},
		preview_obj = nil,
	}

	drawers[player] = data
end

local function clear_draw(player)
	local data = drawers[player]
	if not data then return end
	for _, point_obj in pairs(data.point_objects) do
		point_obj:remove()
	end
	drawers[player] = nil
end

-- return minp and maxp of the bounding box of the given positioins
local function get_extent(positions)
	local max_x, max_y, max_z = -60000, -60000, -60000
	local min_x, min_y, min_z = 60000, 60000, 60000

	for _, pos in pairs(positions) do
		if pos.x < min_x then min_x = pos.x end
		if pos.x > max_x then max_x = pos.x end
		if pos.y < min_y then min_y = pos.y end
		if pos.y > max_y then max_y = pos.y end
		if pos.z < min_z then min_z = pos.z end
		if pos.z > max_z then max_z = pos.z end
	end

	local minp = vector.new(min_x, min_y, min_z)
	local maxp = vector.new(max_x, max_y, max_z)

	return minp, maxp
end

local function finish_drawing(player)
	local data = drawers[player]
	local shape_def = pencil.shapes[data.shape]

	local positions = shape_def.get_node_positions(unpack(data.points))
	if data.mode == "hollow" then
		-- TODO: filter out enclosed positions
	end

	local minp, maxp = get_extent(positions)
	world_builder.execute_with_undo(player, minp, maxp, function()
		if data.mode == "erase" then
			data.node.name = "air"
			for _, pos in ipairs(positions) do
				core.remove_node(pos)
			end
		else
			for _, pos in ipairs(positions) do
				core.set_node(pos, data.node)
			end
		end
		return shape_def.get_draw_description(data.node, unpack(data.points))
	end)

	clear_draw(player)
end

local function add_draw_point(player)
	if not drawers[player] then
		local pencil = player:get_wielded_item()
		if not get_draw_node(pencil) then
			world_builder.hud_display(player, "No node selected.")
			return
		end
		start_drawing(player, pencil)
	end

	local data = drawers[player]
	local shape_def = pencil.shapes[data.shape]
	local draw_point = world_builder.pointed_pos(player, 4.5, "under")
	local point_obj = core.add_entity(draw_point, "world_builder:draw_point")

	table.insert(data.points, draw_point)
	table.insert(data.point_objects, point_obj)

	if #data.points >= shape_def.points_required then
		finish_drawing(player)
	end
end


local function new_drawing(node, shape, mode, player)
	local drawing = {
		node = node,
		shape = shape,
		mode = mode,

		player = player, --the one who is drawing

		control_points = {},
		point_objects = {},
		preview_object = nil,

		remove = function(self)
			for _, point_obj in pairs(self.point_objects) do
				point_obj:remove()
			end
			-- self.preview_object:remove()
		end,
		add_control_point_from_player = function(self, player)
			local pos = world_builder.pointed_pos(player, 4.5, "under")
			self:add_control_point(pos)
		end,
		add_control_point = function(self, pos)
			local point_obj = core.add_entity(draw_point, "world_builder:draw_point")

			table.insert(self.control_points, pos)
			table.insert(self.point_objects, point_obj)
			if #self.points >= self.shape.points_required then
				self:finalize()
			end
		end,
		finalize = function(self)
			local positions = self.shape.get_node_positions(unpack(self.control_points))
			if self.mode == "hollow" then
				-- TODO: filter out enclosed positions
			end

			local minp, maxp = get_extent(positions)
			world_builder.execute_with_undo(self.player, minp, maxp, function()
				if self.mode == "erase" then
					for _, pos in ipairs(positions) do
						core.remove_node(pos)
					end
				else
					for _, pos in ipairs(positions) do
						core.set_node(pos, self.node)
					end
				end
				return self.shape.get_draw_description(self.node, unpack(self.control_points))
			end)

			self:remove()
		end
	}


end





world_builder.register_on_change_wielded(function(player, new_item, old_item)
	if old_item == world_builder.modprefix .."tool_shape_pencil" then
		clear_draw(player)
	end
end)

-- addd draw point
-- if not active draw
-- 	start new draw
-- add point
-- if point is last point
-- 	finish draw -> place nodes
-- 		clear draw
-- 			remove preview object
--
-- update loop
-- 	for active draws
-- 		set preview (list of points + player look pos, extended to needed amount of points)
--
-- list of shapes
-- 	shape name
-- 		place function
-- 		preveiw object
-- 		preview function


--------------------------------------------------------------------------------
-- pencil item definition
--------------------------------------------------------------------------------

minetest.register_craftitem(world_builder.modprefix .."tool_shape_pencil", {
	short_description = "Shape Pencil",
	description = pencil_description .. "\n-unconfigured-",
	inventory_image = "wb_tool_shape_pencil.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		add_draw_point(user)
		-- local pos = world_builder.pointed_pos(user, 4, "under")
		-- local point_obj = core.add_entity(pos, "world_builder:draw_point")
		-- add draw point
	end,
	on_place = function(itemstack, placer, pointed_thing)
		local node = minetest.get_node(pointed_thing.under)
		set_draw_node(itemstack, node)

		return itemstack
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		clear_draw(user)
	end,
})


--------------------------------------------------------------------------------
-- entity for display of selected positions
--------------------------------------------------------------------------------

core.register_entity("world_builder:draw_point", {
	initial_properties = {
		visual = "mesh",
		mesh = "draw_pointer.obj",
		visual_size = {x = 20, y = 20, z = 20},
		textures = {"wb_draw_point.png"},
		use_texture_alpha = true,
		glow = -1,

		physical = false,
		pointable = false,
		static_save = false,
		-- shaded = false,
	}
})


--------------------------------------------------------------------------------
-- display of the position currently being pointed at by the pencil holding players
--------------------------------------------------------------------------------

local pencil_wielders = {}

world_builder.register_on_change_wielded(function(player, new_item, old_item)
	if old_item == world_builder.modprefix .."tool_shape_pencil" then
		local point_obj = pencil_wielders[player]
		pencil_wielders[player] = nil
		if point_obj and point_obj:is_valid() then
			point_obj:remove()
		end
	end


	if new_item == world_builder.modprefix .."tool_shape_pencil" then
		local pos = world_builder.pointed_pos(player, 4.5, "under")
		local point_obj = core.add_entity(pos, "world_builder:draw_point")
		point_obj:set_properties({
			-- visual_size = {x = 0.5, y = 0.5, z = 0.5},
		})
		pencil_wielders[player] = point_obj
	end
end)

core.register_globalstep(function(dtime)
	for player, point_obj in pairs(pencil_wielders) do
		point_obj:set_pos(world_builder.pointed_pos(player, 4.5, "under"))
	end
end)
