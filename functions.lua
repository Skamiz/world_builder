function world_builder.get_eye_pos(player)
	local eye_pos = player:get_pos()
	local eye_height = player:get_properties().eye_height
	local eye_offset = player:get_eye_offset()

	eye_pos.y = eye_pos.y + eye_height
	eye_pos = eye_pos + eye_offset

	return eye_pos
end

function world_builder.get_looked_pos(player, distance)
	distance = distance or 5
	local eye_pos = world_builder.get_eye_pos(player)
	local look_dir = player:get_look_dir()
	local pos = eye_pos + (look_dir * distance)

	return pos
end
