local area = {}
world_builder.area = area


area.fill_volume = function(pos1, pos2, node)
	local minp, maxp = vector.sort(pos1, pos2)
	local va = VoxelArea(minp, maxp)
	local all_pos = {}

	for i in va:iterp(minp, maxp) do
		table.insert(all_pos, va:position(i))
	end

	minetest.bulk_set_node(all_pos, node)

	return string.format("Fill Volume from %s to %s using '%s'.", pos1, pos2, node.name)
end


area.fill_surface = function(pos1, pos2, node)
	local minp, maxp = vector.sort(pos1, pos2)
	local va = VoxelArea(minp, maxp)
	local all_pos = {}

	for i in va:iterp(minp, maxp) do
		local pos = va:position(i)
		if pos.x == minp.x or pos.x == maxp.x or
			pos.y == minp.y or pos.y == maxp.y or
			pos.z == minp.z or pos.z == maxp.z then
			table.insert(all_pos, pos)
		end
	end

	minetest.bulk_set_node(all_pos, node)

	return string.format("Fill Surface from %s to %s using '%s'.", pos1, pos2, node.name)
end


local axes = {"x", "y", "z"}
local function sides_touching(pos, minp, maxp)
	local matching = 0
	for _, axis in pairs(axes) do
		if pos[axis] == minp[axis] or pos[axis] == maxp[axis] then
			matching = matching + 1
		end
	end
	return matching
end

area.fill_frame = function(pos1, pos2, node)
	local minp, maxp = vector.sort(pos1, pos2)
	local va = VoxelArea(minp, maxp)
	local all_pos = {}

	for i in va:iterp(minp, maxp) do
		local pos = va:position(i)
		if sides_touching(pos, minp, maxp) >= 2 then
			table.insert(all_pos, pos)
		end
	end

	minetest.bulk_set_node(all_pos, node)
	return string.format("Fill Frame from %s to %s using '%s'.", pos1, pos2, node.name)
end
