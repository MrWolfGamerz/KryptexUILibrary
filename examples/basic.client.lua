local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KryptexUI = require(ReplicatedStorage:WaitForChild("KryptexUI"))

local Window = KryptexUI:CreateWindow({
	Name = "Kryptex UI",
	LoadingTitle = "Kryptex UI",
	LoadingSubtitle = "Interface loaded",
	Theme = "Kryptex",
})

local MainTab = Window:CreateTab("Main")

MainTab:CreateSection("Basics")

MainTab:CreateLabel("This is the first Kryptex UI demo.")

MainTab:CreateParagraph({
	Title = "Polished Controls",
	Content = "Kryptex UI includes animated tabs, hover states, focused inputs, notifications, and a standalone loader build.",
})

MainTab:CreateButton({
	Name = "Notification",
	ButtonText = "Show",
	Callback = function()
		Window:Notify({
			Title = "Kryptex",
			Content = "Button clicked.",
			Duration = 3,
		})
	end,
})

MainTab:CreateToggle({
	Name = "Example Toggle",
	CurrentValue = false,
	Flag = "ExampleToggle",
	Callback = function(value)
		print("Toggle:", value)
	end,
})

MainTab:CreateSlider({
	Name = "WalkSpeed",
	Range = { 16, 100 },
	Increment = 1,
	CurrentValue = 16,
	Flag = "WalkSpeed",
	Callback = function(value)
		print("Slider:", value)
	end,
})

MainTab:CreateDropdown({
	Name = "Mode",
	Options = { "Legit", "Balanced", "Rage" },
	CurrentOption = "Balanced",
	Flag = "Mode",
	Callback = function(option)
		print("Dropdown:", option)
	end,
})

MainTab:CreateInput({
	Name = "Command",
	PlaceholderText = "Type a command",
	RemoveTextAfterFocusLost = true,
	Callback = function(text)
		print("Input:", text)
	end,
})

MainTab:CreateKeybind({
	Name = "Toggle Window",
	CurrentKeybind = Enum.KeyCode.RightShift,
	Callback = function()
		Window:Toggle()
	end,
})

local SettingsTab = Window:CreateTab("Settings")

SettingsTab:CreateSection("Window")

SettingsTab:CreateButton({
	Name = "Print Flags",
	ButtonText = "Print",
	Callback = function()
		print(Window.Flags)
	end,
})

SettingsTab:CreateDivider("Footer")

SettingsTab:CreateLabel("Kryptex UI v" .. KryptexUI.Version)
