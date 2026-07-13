local KryptexUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/MrWolfGamerz/KryptexUILibrary/main/dist/KryptexUI.lua"))()

local function getUiParent()
	if type(gethui) == "function" then
		local ok, container = pcall(gethui)

		if ok and typeof(container) == "Instance" then
			return container
		end
	end

	local ok, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)

	if ok and coreGui then
		return coreGui
	end

	return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

local Window = KryptexUI:CreateWindow({
	Name = "Kryptex UI",
	LoadingTitle = "Kryptex UI",
	LoadingSubtitle = "Standalone loader ready",
	Theme = "Kryptex",
	Parent = getUiParent(),
})

local MainTab = Window:CreateTab("Main")

MainTab:CreateParagraph({
	Title = "Standalone Ready",
	Content = "This UI was loaded from the generated dist file and can still use the full component API.",
})

MainTab:CreateButton({
	Name = "Test Button",
	ButtonText = "Run",
	Callback = function()
		Window:Notify({
			Title = "Kryptex",
			Content = "The standalone loader is working.",
			Duration = 3,
		})
	end,
})

MainTab:CreateToggle({
	Name = "Example Toggle",
	CurrentValue = false,
	Callback = function(value)
		print("Kryptex toggle:", value)
	end,
})

MainTab:CreateSlider({
	Name = "Example Slider",
	Range = { 0, 100 },
	Increment = 1,
	CurrentValue = 50,
	Callback = function(value)
		print("Kryptex slider:", value)
	end,
})

MainTab:CreateDropdown({
	Name = "Example Dropdown",
	Options = { "Alpha", "Beta", "Gamma" },
	CurrentOption = "Alpha",
	Callback = function(option)
		print("Kryptex dropdown:", option)
	end,
})

MainTab:CreateKeybind({
	Name = "Toggle UI",
	CurrentKeybind = Enum.KeyCode.RightShift,
	Callback = function()
		Window:Toggle()
	end,
})
