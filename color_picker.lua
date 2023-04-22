local modname = minetest.get_current_modname()

color_picker = {}

local colors = {
	{"white", "White", "#ddd"},
	{"grey", "Grey", "#777"},
	{"dark_gray", "Dark Gray", "#444"},
	{"black", "Black", "#222"},
	{"red", "Red", "#a11"},
	{"green", "Green", "#008000"},
	{"blue", "Blue", "#119"},
	{"yellow", "Yellow", "#cbcb00"},
	{"purple", "Purple", "#8000ff"},
	{"lime", "Lime", "#17d01e"},
	{"bright_blue", "Bright Blue", "#44d1d1"},
	{"orange", "Orange", "#ff8000"},
	{"magenta", "Magenta", "#b220b2"},
	{"pink", "Pink", "#e165e2"},
	{"cyan", "Cyan", "#00baab"},
	{"brown", "Brown", "#694110"},
}

function color_picker.get_color_picker_fs(width)
	width = width or 4
	local fs = ""
	for i, color in ipairs(colors) do
		fs = fs .. "image_button[" .. (i-1)%width/2 .. "," .. (math.ceil(i/width) - 1)/2 .. ";0.5,0.5;wb_color.png^[colorize:" .. color[3] .. ";color_" .. color[1] .. ";;false;false]"
			.. "tooltip[color_" .. color[1] .. ";" .. color[2] .. "]"
	end
	return fs
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= modname ..":testing" then return end
	for k, v in pairs(colors) do
		if fields["color_" .. v[1]] then
			local wielded = player:get_wielded_item()
			local meta = wielded:get_meta()
			meta:set_string("color", v[3])
			player:set_wielded_item(wielded)
			return true
		end
	end
end)

local function show_test_fs(player)
	local fs = ""
	.. "formspec_version[6]"
	.. "size[2.5,2.5,false]"
	-- .. "list[current_player;main;0.25,8;10,4]"
	.. "container[0.25,0.25]"
	.. color_picker.get_color_picker_fs(4)
	.. "container_end[]"
	-- .. "listring[]"

	minetest.show_formspec(player:get_player_name(), modname ..":testing", fs)
end

minetest.register_craftitem(modname ..":test_item", {
	short_description = "color picker",
	description = "color picker\ndev item",
	inventory_image = "wb_color_orb.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		show_test_fs(user)
	end,
	-- on_place = function(itemstack, placer, pointed_thing)
	-- end,
})
