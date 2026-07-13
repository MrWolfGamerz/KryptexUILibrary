# Kryptex UI Library

Kryptex UI is a Roblox Luau UI library with a Rayfield-style API. It includes polished windows, animated tabs, sections, labels, paragraphs, buttons, toggles, sliders, dropdowns, inputs, keybinds, notifications, themes, draggable/minimizable windows, and cleanup.

Current version: `v0.4.0`

## Mobile Support

Kryptex UI is responsive by default. On smaller/touch screens it clamps the window to the viewport, moves tabs into a horizontal scroll strip, increases touch target sizes, resizes notifications, and recalculates layout when the viewport changes.

Interactive controls are designed to work across mouse, touch, keyboard, and gamepad where Roblox exposes the matching input. Buttons, toggles, dropdowns, inputs, and keybinds support whole-row tapping. Sliders support drag, tap-to-set on the slider area, keyboard nudging with arrow/WASD keys, and gamepad nudging with D-pad/L1/R1.

```lua
local Window = KryptexUI:CreateWindow({
	Name = "Kryptex UI",
	Responsive = true, -- default
})
```

Set `Responsive = false` only if you want a fixed desktop-style layout.

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

## QA Script

Use `examples/qa-input.client.lua` when testing executor/mobile behavior. It loads the standalone bundle, creates every current component, logs each callback, exposes flags, and includes buttons that call `Set`, `Get`, and `Refresh` on controls.

Recommended checks:

- Tap/click whole button, toggle, dropdown, input, and keybind rows.
- Drag sliders slowly and quickly with mouse and touch.
- Use arrow/WASD keys or D-pad/L1/R1 to nudge the focused slider.
- Open dropdowns and select options.
- Resize the viewport or rotate a mobile emulator.
- Press `Print Flags` and confirm values match the UI.

## Components

```lua
MainTab:CreateSection("Basics")

MainTab:CreateLabel("Small helper text.")

MainTab:CreateParagraph({
	Title = "Paragraph",
	Content = "Use paragraphs for longer descriptions or status text.",
})

MainTab:CreateDivider("Line")

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

MainTab:CreateKeybind({
	Name = "Toggle UI",
	CurrentKeybind = Enum.KeyCode.RightShift,
	Callback = function()
		Window:Toggle()
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
- `Window:Toggle()`
- `Window:SetMinimized(boolean)`
- `Window:Destroy()`
- `Window:CreateSection(nameOrConfig)`
- `Window:CreateParagraph(config)`
- `Window:CreateDivider(nameOrConfig)`
- `Tab:CreateSection(nameOrConfig)`
- `Tab:CreateLabel(nameOrConfig)`
- `Tab:CreateParagraph(config)`
- `Tab:CreateDivider(nameOrConfig)`
- `Tab:CreateButton(config)`
- `Tab:CreateToggle(config)`
- `Tab:CreateSlider(config)`
- `Tab:CreateDropdown(config)`
- `Tab:CreateInput(config)`
- `Tab:CreateKeybind(config)`

## Themes

Built-in themes:

- `Kryptex`
- `Midnight`

You can pass a custom theme table into `CreateWindow({ Theme = { ... } })` using the same color keys found in `src/KryptexUI/Utility/Theme.lua`.
