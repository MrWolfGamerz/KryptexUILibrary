# Kryptex UI Library

Kryptex UI is a Roblox Luau UI library with a Rayfield-style API. It is early, but the first version includes windows, tabs, sections, labels, buttons, toggles, sliders, dropdowns, inputs, notifications, themes, draggable windows, and cleanup.

## Quick Start

Put `src/KryptexUI` in `ReplicatedStorage`, then require it from a `LocalScript`:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KryptexUI = require(ReplicatedStorage:WaitForChild("KryptexUI"))

local Window = KryptexUI:CreateWindow({
	Name = "Kryptex UI",
	Theme = "Kryptex",
})

local MainTab = Window:CreateTab("Main")

MainTab:CreateButton({
	Name = "Say Hello",
	ButtonText = "Run",
	Callback = function()
		print("Hello from Kryptex UI")
	end,
})
```

## Standalone Loader

For your own experiences and testing environments where you want a single raw GitHub URL, use the bundled file in `dist`:

```lua
local KryptexUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/MrWolfGamerz/KryptexUILibrary/main/dist/KryptexUI.lua"))()

local Window = KryptexUI:CreateWindow({
	Name = "Kryptex UI",
	Theme = "Kryptex",
	Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"),
})

local MainTab = Window:CreateTab("Main")

MainTab:CreateButton({
	Name = "Say Hello",
	ButtonText = "Run",
	Callback = function()
		print("Hello from Kryptex UI")
	end,
})
```

See `examples/standalone-loader.lua` for a fuller loader example with UI parent fallback support.

## Components

```lua
MainTab:CreateSection("Basics")

MainTab:CreateLabel("Small helper text.")

MainTab:CreateButton({
	Name = "Button",
	ButtonText = "Run",
	Callback = function()
		print("clicked")
	end,
})

MainTab:CreateToggle({
	Name = "Toggle",
	CurrentValue = false,
	Flag = "MyToggle",
	Callback = function(value)
		print(value)
	end,
})

MainTab:CreateSlider({
	Name = "Slider",
	Range = { 0, 100 },
	Increment = 1,
	CurrentValue = 50,
	Flag = "MySlider",
	Callback = function(value)
		print(value)
	end,
})

MainTab:CreateDropdown({
	Name = "Dropdown",
	Options = { "One", "Two", "Three" },
	CurrentOption = "One",
	Flag = "MyDropdown",
	Callback = function(option)
		print(option)
	end,
})

MainTab:CreateInput({
	Name = "Input",
	PlaceholderText = "Type here",
	Callback = function(text)
		print(text)
	end,
})
```

## Notifications

```lua
Window:Notify({
	Title = "Kryptex",
	Content = "Loaded successfully.",
	Duration = 3,
})
```

## Development With Rojo

This repo includes `default.project.json`, so you can use Rojo to sync the library into Roblox Studio:

```powershell
rojo serve default.project.json
```

Then connect from the Rojo plugin in Studio.

## Building The Standalone File

After editing files in `src/KryptexUI`, rebuild the loadstring-friendly file:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build-dist.ps1
```

## Current API

- `KryptexUI:CreateWindow(config)`
- `Window:CreateTab(nameOrConfig)`
- `Window:Notify(config)`
- `Window:Destroy()`
- `Window:CreateSection(nameOrConfig)`
- `Tab:CreateSection(nameOrConfig)`
- `Tab:CreateLabel(nameOrConfig)`
- `Tab:CreateButton(config)`
- `Tab:CreateToggle(config)`
- `Tab:CreateSlider(config)`
- `Tab:CreateDropdown(config)`
- `Tab:CreateInput(config)`

## Themes

Built-in themes:

- `Kryptex`
- `Midnight`

You can pass a custom theme table into `CreateWindow({ Theme = { ... } })` using the same color keys found in `src/KryptexUI/Utility/Theme.lua`.
