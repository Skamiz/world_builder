local modname = minetest.get_current_modname()
local mod_prefix = modname .. ":"

local colors = {
	["white"] = "#ddd",
	["grey"] = "#777",
	["dark_gray"] = "#444",
	["black"] = "#222",
	["brown"] = "#694110",
	["red"] = "#a11",
	["green"] = "#008000",
	["blue"] = "#119",
	["yellow"] = "#cbcb00",
	["lime"] = "#17d01e",
	["bright_blue"] = "#44d1d1",
	["orange"] = "#ff8000",
	["purple"] = "#8000ff",
	["pink"] = "#e165e2",
	["magenta"] = "#b220b2",
	["cyan"] = "#00baab",
}

local function capitalize(s)
	return s:gsub(".", string.upper, 1)
end

for name, color in pairs(colors) do
	minetest.register_node(mod_prefix .. "color_" .. name, {
		description = capitalize(name),
		tiles = {"wb_color_node.png"},
		color = color,
	})
end
