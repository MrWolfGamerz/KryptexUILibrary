local SOURCE_URL = "https://raw.githubusercontent.com/MrWolfGamerz/KryptexUILibrary/main/dist/KryptexUI.lua"

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

local function loadKryptexUI()
	if type(loadstring) == "function" then
		local ok, library = pcall(function()
			return loadstring(game:HttpGet(SOURCE_URL))()
		end)

		if ok and type(library) == "table" then
			return library
		end
	end

	local replicatedStorage = game:GetService("ReplicatedStorage")
	local module = replicatedStorage:FindFirstChild("KryptexUI")

	if module then
		return require(module)
	end

	error("KryptexUI could not be loaded from the dist URL or ReplicatedStorage.")
end

local KryptexUI = loadKryptexUI()

local Window = KryptexUI:CreateWindow({
	Name = "Kryptex QA v" .. tostring(KryptexUI.Version),
	LoadingTitle = "Kryptex QA",
	LoadingSubtitle = "Testing every control",
	Theme = "Kryptex",
	Parent = getUiParent(),
})

local Main = Window:CreateTab("Controls")
local Actions = Window:CreateTab("Actions")
local Touch = Window:CreateTab("Touch")

local logCount = 0
local status = Main:CreateParagraph({
	Title = "Callback Status",
	Content = "Use mouse, keyboard, gamepad, or mobile touch. Callback logs appear here and in the console.",
	Height = 96,
})

local function log(name, value)
	logCount = logCount + 1
	local message = "#" .. tostring(logCount) .. " " .. tostring(name) .. " -> " .. tostring(value)

	print("[Kryptex QA]", message)
	status:Set({
		Content = message,
	})
end

Main:CreateSection("Interactive")

Main:CreateButton({
	Name = "Button Row",
	ButtonText = "Run",
	Callback = function()
		log("Button", "pressed")
		Window:Notify({
			Title = "Kryptex QA",
			Content = "Button callback fired.",
			Duration = 2,
		})
	end,
})

local toggleControl = Main:CreateToggle({
	Name = "Toggle Row",
	CurrentValue = false,
	Flag = "qa_toggle",
	Callback = function(value)
		log("Toggle", value)
	end,
})

local sliderControl = Main:CreateSlider({
	Name = "Drag Slider",
	Range = { 0, 100 },
	Increment = 1,
	CurrentValue = 50,
	Flag = "qa_slider",
	Callback = function(value)
		log("Slider", value)
	end,
})

local fineSlider = Main:CreateSlider({
	Name = "Fine Slider",
	Range = { 0, 1 },
	Increment = 0.05,
	CurrentValue = 0.5,
	Flag = "qa_fine_slider",
	Callback = function(value)
		log("FineSlider", value)
	end,
})

local dropdownControl = Main:CreateDropdown({
	Name = "Dropdown Row",
	Options = { "Alpha", "Beta", "Gamma" },
	CurrentOption = "Beta",
	Flag = "qa_dropdown",
	Callback = function(option)
		log("Dropdown", option)
	end,
})

local inputControl = Main:CreateInput({
	Name = "Input Row",
	PlaceholderText = "Type then press enter or unfocus",
	Flag = "qa_input",
	Callback = function(text)
		log("Input", text)
	end,
})

Main:CreateKeybind({
	Name = "Keybind Row",
	CurrentKeybind = Enum.KeyCode.RightShift,
	Flag = "qa_keybind",
	Changed = function(keyCode)
		log("KeybindChanged", keyCode.Name)
	end,
	Callback = function(keyCode)
		log("Keybind", keyCode.Name)
		Window:Toggle()
	end,
})

Actions:CreateSection("Programmatic API")

Actions:CreateButton({
	Name = "Set Toggle On",
	ButtonText = "Set",
	Callback = function()
		toggleControl:Set(true)
		log("SetToggle", toggleControl:Get())
	end,
})

Actions:CreateButton({
	Name = "Set Slider 75",
	ButtonText = "Set",
	Callback = function()
		sliderControl:Set(75)
		log("SetSlider", sliderControl:Get())
	end,
})

Actions:CreateButton({
	Name = "Set Fine Slider",
	ButtonText = "Set",
	Callback = function()
		fineSlider:Set(0.85)
		log("SetFineSlider", fineSlider:Get())
	end,
})

Actions:CreateButton({
	Name = "Refresh Dropdown",
	ButtonText = "Refresh",
	Callback = function()
		dropdownControl:Refresh({ "Delta", "Epsilon", "Zeta", "Omega" }, false)
		log("RefreshDropdown", dropdownControl:Get())
	end,
})

Actions:CreateButton({
	Name = "Set Input Text",
	ButtonText = "Set",
	Callback = function()
		inputControl:Set("QA text")
		log("SetInput", inputControl:Get())
	end,
})

Actions:CreateButton({
	Name = "Print Flags",
	ButtonText = "Print",
	Callback = function()
		for key, value in pairs(Window.Flags) do
			print("[Kryptex QA Flag]", key, value)
		end

		Window:Notify({
			Title = "Kryptex QA",
			Content = "Flags printed to console.",
			Duration = 2,
		})
	end,
})

Touch:CreateSection("Mobile Checks")

Touch:CreateParagraph({
	Title = "Touch Checklist",
	Content = "Tap whole rows, drag both sliders slowly and quickly, open dropdowns, focus input rows, and rotate or resize the viewport.",
	Height = 96,
})

Touch:CreateToggle({
	Name = "Full Row Tap",
	CurrentValue = false,
	Callback = function(value)
		log("TouchToggle", value)
	end,
})

Touch:CreateSlider({
	Name = "Touch Drag",
	Range = { 10, 200 },
	Increment = 5,
	CurrentValue = 80,
	Callback = function(value)
		log("TouchSlider", value)
	end,
})

Touch:CreateButton({
	Name = "Show Notification",
	ButtonText = "Show",
	Callback = function()
		Window:Notify({
			Title = "Kryptex QA",
			Content = "Mobile tap callback fired.",
			Duration = 2,
		})
	end,
})
