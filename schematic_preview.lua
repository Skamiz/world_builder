local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local modprefix = modname .. ":"

--[[


TODO: large schematics are loosing nodes when rotated,
	I suspect that the individual objecs are moving into unlodad areas, which destroys them
	can be investigated by getting the number of children of the root objec after each manipulation
		add a callback to the objecs to know when they are being destroyed
	adjusting the distance scaling will help mittigate this
	also just put a stright up max limmit on it
	I am guessing that once the root is gone all others are also deleted
		amendment once the root is out of render distance all of them become invisible
		which does nothing against some simply dissapearing
	functions which convert to/from a schematic structure which only contains non-air nodes
	Would it be viable to use image waypoints in place of objects as a form of display?
	It should be possible to encapsulate the whole area in a large bounding box, whichs textures can be created dynamically to avoind scaling issues

]]

local rotations = dofile(modpath .. "/object_rotations.lua")

local schem_prev = {}
local schem_prev_meta = {}
schem_prev_meta.__index = schem_prev_meta
world_builder.schem_prev = schem_prev


local invi = "wb_pixel.png^[opacity:0"
minetest.register_entity(modprefix .."empty", {
	pointable = false,
	visual = "cube",
	use_texture_alpha = true,
	textures = {invi, invi, invi, invi, invi, invi},
	-- is_visible = true,
	static_save = false,
})
minetest.register_entity(modprefix .."preview", {
	pointable = false,
	visual = "item",
	wield_item = "air",
	visual_size = {x = 2/3 + 0.001, y = 2/3 + 0.001, z = 2/3 + 0.001},
	use_texture_alpha = true,
	-- is_visible = true,
	-- backface_culling = false,
	glow = -1,
	static_save = false,
})
local vector_1 = vector.new(1, 1, 1)

-- sets completely enclosed nodes to "air"
-- NOTE: are there better ways to select nodes for hiding?
local function trim_schematic(schem)
	local size = schem.size
	local min_size = math.min(size.x, size.y, size.z)

	if min_size < 3 then return schem end

	local va = VoxelArea:new({MinEdge = vector_1, MaxEdge = schem.size})
	local strides = {
		1,
		-1,
		va.ystride,
		-va.ystride,
		va.zstride,
		-va.zstride,
	}

	local to_be_removed = {}
	for i in va:iterp(vector_1 * 2, schem.size - vector_1) do
		local enclosed = true
		for _, n in pairs(strides) do
			if schem.data[i + n].name == "air" then
				enclosed = false
				break
			end
		end
		if enclosed then table.insert(to_be_removed, i) end
	end
	for _, i in pairs(to_be_removed) do
		schem.data[i].name = "air"
	end

	return schem
end

-- we need a player here so the schematic can be in a loaded area when hidden
schem_prev.new = function(schematic, attach_player)
	local pos = attach_player:get_pos()
	local schem = trim_schematic(table.copy(schematic))
	local root = minetest.add_entity(pos, modprefix .."empty")

	local va = VoxelArea:new({MinEdge = vector_1, MaxEdge = schem.size})

	local nnodes = 0
	for k, v in pairs(schem.data) do
		if v.name ~= "air" then
			nnodes = nnodes + 1
		end
	end


	for i in va:iterp(vector_1, schem.size) do
		local node = schem.data[i]
		local node_name = node.name
		local node_def = minetest.registered_nodes[node_name]
		if node_name ~= "air" and math.random() < (1000/nnodes) then
			local prev = minetest.add_entity(pos, modprefix .."preview")
			prev:set_properties({
				wield_item = node_name,
			})

			local rot = nil
			if node_def and node_def.paramtype2 == "facedir" then
				rot = rotations.facedir[node.param2]
			end

			prev:set_attach(root, nil, (va:position(i) - vector_1) * 10, rot)
		end
	end

	local schem_prev = {
		player = attach_player,
		schematic = schematic,
		obj = root,

		visible = true,

		pos = pos,
		rotation = 0,
		flags = {},
		offset = vector.zero()
	}
	setmetatable (schem_prev, schem_prev_meta)
	return schem_prev
end

schem_prev_meta.delete = function(schem_prev)
	local obj = schem_prev.obj
	for _, child in pairs(obj:get_children()) do
		child:remove()
	end
	obj:remove()
end

schem_prev_meta.show = function(schem_prev)
	if schem_prev.visible then return end
	schem_prev.visible = true
	local obj = schem_prev.obj
	obj:set_detach()
	for _, child in pairs(obj:get_children()) do
		child:set_properties({is_visible = true})
	end
	schem_prev:set_placement()
end

schem_prev_meta.hide = function(schem_prev)
	if not schem_prev.visible then return end
	schem_prev.visible = false
	local obj = schem_prev.obj
	for _, child in pairs(obj:get_children()) do
		child:set_properties({is_visible = false})
	end
	obj:set_attach(schem_prev.player)
end


schem_prev_meta.update_offset = function(schem_prev)
	local offset = vector.zero()
	local size = table.copy(schem_prev.schematic.size)

	if schem_prev.rotation == 90 then
		offset.z = size.x - 1
		size.x, size.z = size.z, size.x
	elseif schem_prev.rotation == 180 then
		offset.x = size.x - 1
		offset.z = size.z - 1
	elseif schem_prev.rotation == 270 then
		offset.x = size.z - 1
		size.x, size.z = size.z, size.x
	end

	for flag, present in pairs(schem_prev.flags) do
		local axis = flag:sub(-1)
		if present then
			offset[axis] = offset[axis] - math.floor((size[axis] - 1)/2)
		end
	end

	schem_prev.offset = offset
end

schem_prev_meta.set_placement = function(schem_prev, pos, rotation, flags)
	schem_prev.pos = pos or schem_prev.pos
	schem_prev.rotation = rotation or schem_prev.rotation
	schem_prev.flags = flags or schem_prev.flags

	schem_prev:update_offset()
	schem_prev.obj:set_rotation(vector.new(0, -math.rad(schem_prev.rotation), 0))
	schem_prev.obj:set_pos(schem_prev.pos + schem_prev.offset)
end

schem_prev_meta.rotate = function(schem_prev, angle)
	local rot = schem_prev.rotation
	rot = rot + angle
	if rot > 270 then rot = rot - 360 end
	if rot < 0 then rot = rot + 360 end
	schem_prev.rotation = rot

	schem_prev:set_placement()
end
