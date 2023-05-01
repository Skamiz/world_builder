local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local modprefix = modname .. ":"

--[[
It seems Minetest has no direct way to just create a schematic,
the only thing it can do is write a schematic to file and then read it in.
--]]

local vector_1 = vector.new(1, 1, 1)
local schematics = {}
world_builder.schematics = schematics

schematics.make_schematic = function(pos1, pos2, air_prob)
	-- by default don't include "air"
	air_prob = air_prob or 0 -- this was commented out and I don't know why
	local minp, maxp = vector.sort(pos1, pos2)
	local va = VoxelArea:new({MinEdge = minp, MaxEdge = maxp})

	local data = {}
	for i in va:iterp(minp, maxp) do
		local node = minetest.get_node(va:position(i))
		node.param1 = nil
		if node.name == "air" then
			node.prob = air_prob
		end
		data[i] = node
	end

	local size = va:getExtent()

	local schematic = {
		data = data,
		size = size,
	}

	return schematic
end

schematics.set_node_probability = function(schematic, node_name, probability)
	for i, node in pairs(schematic.data) do
		if node.name == node_name then
			node.prob = probability
		end
	end
end

local flip_facedir = {
	x = {
	  [0] = 1, 0, 3, 2,
		 5,  4,  7,  6,
		 9,  8, 11, 10,
		17, 16, 19, 18,
		13, 12, 15, 14,
		21, 20, 23, 22,
	},
	y = {
	  [0] =21,20,23,22,
		 7,  6,  5,  4,
		11, 10,  9,  8,
		13, 12, 15, 14,
		17, 16, 19, 18,
		 1,  0,  3,  2,
	},
	z = {
	  [0] = 3, 2, 1, 0,
		11, 10,  9,  8,
		 7,  6,  5,  4,
		15, 14, 13, 12,
		19, 18, 17, 16,
		23, 22, 21, 20,
	},
}
local y_rot = {
	[0] = 1, 2, 3, 0,
	13, 14, 15, 12,
	17, 18, 19, 16,
	 9, 10, 11,  8,
	 5,  6,  7,  4,
	23, 20, 21, 22,
}

schematics.mirror = function(schematic, axis)
	local va = VoxelArea:new({MinEdge = vector_1, MaxEdge = schematic.size})
	local data = {}
	for i in va:iterp(vector_1, schematic.size) do
		local pos = va:position(i)

		pos[axis] = (schematic.size[axis] - pos[axis]) + 1

		local new_i = va:indexp(pos)
		local node = schematic.data[i]

		-- WARNING: no node rotation since there isn't a way to do it reliably
		-- correct rotation depens heavily on the shape of the node
		-- if minetest.registered_nodes[node.name].paramtype2 == "facedir" then
		-- 	node.param2 = y_rot[y_rot[node.param2]]
		-- end

		data[new_i] = node
	end

	local new_schematic = {
		data = data,
		size = schematic.size,
	}
	return new_schematic
end

local function nodes_equal(a, b)
	if a.name == b.name and a.param2 == b.param2 then
		return true
	end
	return false
end

-- This is an atempt to minimize the memory footprint of the undo schematics by
-- only having one table per node variation, instead of having one for each position
local function get_node_ref(nodes, node)
	local node_string = node.name .. node.param2
	if not nodes[node_string] then
		nodes[node_string] = table.copy(node)
	end
	return nodes[node_string]
end

local nil_node = {name = "air", prob = 0}
schematics.diff = function(schemA, schemB)
	if schemA.size ~= schemB.size then
		return nil, "Schems must be the same size"
	end

	local va = VoxelArea:new({MinEdge = vector_1, MaxEdge = schemA.size})
	local dataAB, dataBA = {}, {}
	local nodes = {}

	for i in va:iterp(vector_1, schemA.size) do
		local nodeA = schemA.data[i]
		local nodeB = schemB.data[i]

		if nodes_equal(nodeA, nodeB) then
			dataAB[i] = nil_node
			dataBA[i] = nil_node
		else
			dataAB[i] = get_node_ref(nodes, nodeA)
			dataBA[i] = get_node_ref(nodes, nodeB)
		end
	end

	local schemAB = {
		data = dataAB,
		size = vector.new(schemA.size),
	}
	local schemBA = {
		data = dataBA,
		size = vector.new(schemA.size),
	}

	return schemAB, schemBA
end
