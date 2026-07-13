local Theme = {}

Theme.Presets = {
	Kryptex = {
		Background = Color3.fromRGB(15, 17, 24),
		Surface = Color3.fromRGB(23, 26, 36),
		SurfaceLight = Color3.fromRGB(32, 36, 48),
		SurfaceMuted = Color3.fromRGB(19, 22, 31),
		Stroke = Color3.fromRGB(52, 58, 76),
		Text = Color3.fromRGB(240, 244, 252),
		MutedText = Color3.fromRGB(154, 164, 184),
		Accent = Color3.fromRGB(0, 190, 170),
		AccentDark = Color3.fromRGB(0, 137, 125),
		AccentLight = Color3.fromRGB(48, 231, 211),
		Accent2 = Color3.fromRGB(106, 139, 255),
		Glow = Color3.fromRGB(0, 190, 170),
		Success = Color3.fromRGB(63, 216, 132),
		Warning = Color3.fromRGB(255, 190, 92),
		Danger = Color3.fromRGB(244, 84, 84),
		Shadow = Color3.fromRGB(5, 6, 10),
	},

	Midnight = {
		Background = Color3.fromRGB(11, 13, 18),
		Surface = Color3.fromRGB(19, 22, 30),
		SurfaceLight = Color3.fromRGB(29, 34, 45),
		SurfaceMuted = Color3.fromRGB(16, 19, 26),
		Stroke = Color3.fromRGB(48, 56, 72),
		Text = Color3.fromRGB(238, 242, 248),
		MutedText = Color3.fromRGB(148, 158, 176),
		Accent = Color3.fromRGB(89, 178, 255),
		AccentDark = Color3.fromRGB(42, 127, 204),
		AccentLight = Color3.fromRGB(137, 203, 255),
		Accent2 = Color3.fromRGB(131, 116, 255),
		Glow = Color3.fromRGB(89, 178, 255),
		Success = Color3.fromRGB(74, 215, 140),
		Warning = Color3.fromRGB(255, 194, 94),
		Danger = Color3.fromRGB(239, 86, 86),
		Shadow = Color3.fromRGB(4, 5, 8),
	},
}

local function copyTheme(source)
	local result = {}

	for key, value in pairs(source) do
		result[key] = value
	end

	return result
end

function Theme.resolve(theme)
	local resolved = copyTheme(Theme.Presets.Kryptex)

	if type(theme) == "string" and Theme.Presets[theme] then
		for key, value in pairs(Theme.Presets[theme]) do
			resolved[key] = value
		end
	elseif type(theme) == "table" then
		for key, value in pairs(theme) do
			resolved[key] = value
		end
	end

	return resolved
end

return Theme
