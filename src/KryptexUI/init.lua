local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Create = require(script.Utility.Create)
local Maid = require(script.Utility.Maid)
local Theme = require(script.Utility.Theme)

local KryptexUI = {
	Version = "0.3.4",
}

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local DEFAULT_FONT = Enum.Font.Gotham
local DEFAULT_BOLD_FONT = Enum.Font.GothamBold
local MOTION = {
	Fast = 0.1,
	Normal = 0.16,
	Slow = 0.28,
}
local activeTweens = setmetatable({}, {
	__mode = "k",
})

local function corner(radius)
	return Create.new("UICorner", {
		CornerRadius = UDim.new(0, radius or 8),
	})
end

local function stroke(theme, transparency)
	return Create.new("UIStroke", {
		Color = theme.Stroke,
		Transparency = transparency or 0,
		Thickness = 1,
	})
end

local function gradient(theme, rotation)
	return Create.new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.Accent),
			ColorSequenceKeypoint.new(1, theme.Accent2 or theme.AccentLight or theme.Accent),
		}),
		Rotation = rotation or 0,
	})
end

local function padding(left, top, right, bottom)
	return Create.new("UIPadding", {
		PaddingLeft = UDim.new(0, left or 0),
		PaddingTop = UDim.new(0, top or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
	})
end

local function listLayout(paddingPixels)
	return Create.new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, paddingPixels or 8),
	})
end

local function getName(config, fallback)
	if type(config) == "table" then
		return config.Name or config.Title or config.Text or fallback
	end

	return config or fallback
end

local function formatNumber(value)
	if math.abs(value - math.floor(value)) < 0.001 then
		return tostring(math.floor(value))
	end

	return string.format("%.2f", value)
end

local function getViewportSize()
	local camera = workspace.CurrentCamera

	if camera then
		return camera.ViewportSize
	end

	return Vector2.new(1280, 720)
end

local function resolveResponsiveSize(requestedSize, viewportSize, compact)
	local margin = compact and 16 or 24
	local maxWidth = math.max(viewportSize.X - margin, 280)
	local maxHeight = math.max(viewportSize.Y - margin, 260)

	local width = compact and math.min(500, maxWidth) or math.min(560, maxWidth)
	local height = compact and math.min(560, maxHeight) or math.min(420, maxHeight)

	if typeof(requestedSize) == "UDim2" then
		width = (viewportSize.X * requestedSize.X.Scale) + requestedSize.X.Offset
		height = (viewportSize.Y * requestedSize.Y.Scale) + requestedSize.Y.Offset
	end

	return UDim2.fromOffset(
		math.floor(math.clamp(width, 280, maxWidth)),
		math.floor(math.clamp(height, 260, maxHeight))
	)
end

local function isCompactViewport(viewportSize)
	return viewportSize.X <= 560 or (UserInputService.TouchEnabled and viewportSize.X <= 720)
end

local function resolveKeyCode(keyCode)
	if typeof(keyCode) == "EnumItem" then
		return keyCode
	end

	if type(keyCode) == "string" then
		local ok, enumItem = pcall(function()
			return Enum.KeyCode[keyCode]
		end)

		if ok and enumItem then
			return enumItem
		end
	end

	return Enum.KeyCode.Unknown
end

local function mixColor(a, b, alpha)
	return Color3.new(
		a.R + ((b.R - a.R) * alpha),
		a.G + ((b.G - a.G) * alpha),
		a.B + ((b.B - a.B) * alpha)
	)
end

local function lighten(color, amount)
	return mixColor(color, Color3.fromRGB(255, 255, 255), amount or 0.08)
end

local function darken(color, amount)
	return mixColor(color, Color3.fromRGB(0, 0, 0), amount or 0.08)
end

local function safePlayerGui()
	local localPlayer = Players.LocalPlayer
	assert(localPlayer, "KryptexUI must be required from a LocalScript.")

	return localPlayer:WaitForChild("PlayerGui")
end

local function animate(instance, goals, duration)
	if activeTweens[instance] then
		activeTweens[instance]:Cancel()
	end

	local tween = TweenService:Create(
		instance,
		TweenInfo.new(duration or MOTION.Normal, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		goals
	)

	activeTweens[instance] = tween
	tween.Completed:Connect(function()
		if activeTweens[instance] == tween then
			activeTweens[instance] = nil
		end
	end)

	tween:Play()
	return tween
end

local function connectAutoCanvas(scrollingFrame, layout, maid)
	local function resize()
		scrollingFrame.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 24)
	end

	maid:Give(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize))
	resize()
end

function Window:_run(callback, ...)
	if type(callback) ~= "function" then
		return
	end

	local args = table.pack(...)

	task.spawn(function()
		local ok, err = pcall(callback, table.unpack(args, 1, args.n))

		if not ok then
			warn("[KryptexUI] Callback error:", err)
		end
	end)
end

function Window:_tween(instance, goals, duration)
	return animate(instance, goals, duration)
end

function Window:_bindButtonMotion(button, normalColor, hoverColor, pressedColor)
	local hovering = false
	local holding = false

	self._maid:Give(button.MouseEnter:Connect(function()
		hovering = true

		if not holding then
			self:_tween(button, {
				BackgroundColor3 = hoverColor,
			}, MOTION.Fast)
		end
	end))

	self._maid:Give(button.MouseLeave:Connect(function()
		hovering = false

		if not holding then
			self:_tween(button, {
				BackgroundColor3 = normalColor,
			}, MOTION.Fast)
		end
	end))

	self._maid:Give(button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			holding = true
			self:_tween(button, {
				BackgroundColor3 = pressedColor,
			}, MOTION.Fast)
		end
	end))

	self._maid:Give(button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			holding = false
			self:_tween(button, {
				BackgroundColor3 = hovering and hoverColor or normalColor,
			}, MOTION.Fast)
		end
	end))
end

function Window:_bindTabMotion(tab)
	local hovering = false
	local holding = false

	local function normalColor()
		return self.CurrentTab == tab and self.Theme.SurfaceLight or self.Theme.SurfaceMuted
	end

	local function hoverColor()
		return self.CurrentTab == tab and lighten(self.Theme.SurfaceLight, 0.04) or self.Theme.Surface
	end

	self._maid:Give(tab.Button.MouseEnter:Connect(function()
		hovering = true

		if not holding then
			self:_tween(tab.Button, {
				BackgroundColor3 = hoverColor(),
			}, MOTION.Fast)
		end
	end))

	self._maid:Give(tab.Button.MouseLeave:Connect(function()
		hovering = false

		if not holding then
			self:_tween(tab.Button, {
				BackgroundColor3 = normalColor(),
			}, MOTION.Fast)
		end
	end))

	self._maid:Give(tab.Button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			holding = true
			self:_tween(tab.Button, {
				BackgroundColor3 = darken(hoverColor(), 0.08),
			}, MOTION.Fast)
		end
	end))

	self._maid:Give(tab.Button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			holding = false
			self:_tween(tab.Button, {
				BackgroundColor3 = hovering and hoverColor() or normalColor(),
			}, MOTION.Fast)
		end
	end))
end

function Window:_bindStrokeFocus(instance, uiStroke)
	self._maid:Give(instance.Focused:Connect(function()
		self:_tween(uiStroke, {
			Color = self.Theme.Accent,
			Transparency = 0,
		}, MOTION.Fast)
	end))

	self._maid:Give(instance.FocusLost:Connect(function()
		self:_tween(uiStroke, {
			Color = self.Theme.Stroke,
			Transparency = 0.35,
		}, MOTION.Fast)
	end))
end

function Window:_applyOrTween(instance, goals, animated, duration)
	if animated then
		self:_tween(instance, goals, duration or MOTION.Normal)
		return
	end

	for property, value in pairs(goals) do
		instance[property] = value
	end
end

function Window:_refreshTabCanvas()
	if not self.TabList or not self.TabLayout then
		return
	end

	local contentSize = self.TabLayout.AbsoluteContentSize

	if self._compact then
		self.TabList.CanvasSize = UDim2.fromOffset(contentSize.X + 16, 0)
	else
		self.TabList.CanvasSize = UDim2.fromOffset(0, contentSize.Y + 16)
	end
end

function Window:_applyResponsiveLayout(animated)
	if not self._responsive then
		return
	end

	local viewportSize = getViewportSize()
	local compact = isCompactViewport(viewportSize)
	local nextSize = resolveResponsiveSize(self._requestedSize, viewportSize, compact)
	local collapsedHeight = compact and 52 or 48

	self._compact = compact
	self._windowSize = nextSize

	self:_applyOrTween(self.Container, {
		Size = self._minimized and UDim2.new(nextSize.X.Scale, nextSize.X.Offset, 0, collapsedHeight) or nextSize,
	}, animated, MOTION.Slow)

	if self.TitleLabel then
		self.TitleLabel.Position = UDim2.fromOffset(compact and 14 or 18, 0)
		self.TitleLabel.Size = UDim2.new(1, compact and -108 or -164, 1, 0)
		self.TitleLabel.TextSize = compact and 14 or 16
	end

	if self.VersionLabel then
		self.VersionLabel.Visible = not compact
	end

	if self.MinimizeButton then
		self.MinimizeButton.Position = UDim2.new(1, compact and -54 or -50, 0.5, 0)
		self.MinimizeButton.Size = compact and UDim2.fromOffset(36, 34) or UDim2.fromOffset(28, 28)
	end

	if self.CloseButton then
		self.CloseButton.Position = UDim2.new(1, compact and -12 or -14, 0.5, 0)
		self.CloseButton.Size = compact and UDim2.fromOffset(36, 34) or UDim2.fromOffset(28, 28)
	end

	if compact then
		self:_applyOrTween(self.Sidebar, {
			Position = UDim2.fromOffset(10, 58),
			Size = UDim2.new(1, -20, 0, 50),
		}, animated, MOTION.Normal)
		self:_applyOrTween(self.ContentHolder, {
			Position = UDim2.fromOffset(10, 118),
			Size = UDim2.new(1, -20, 1, -128),
		}, animated, MOTION.Normal)

		self.TabList.ScrollingDirection = Enum.ScrollingDirection.X
		self.TabLayout.FillDirection = Enum.FillDirection.Horizontal
		self.TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		self.TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	else
		self:_applyOrTween(self.Sidebar, {
			Position = UDim2.fromOffset(14, 62),
			Size = UDim2.new(0, 140, 1, -76),
		}, animated, MOTION.Normal)
		self:_applyOrTween(self.ContentHolder, {
			Position = UDim2.fromOffset(168, 62),
			Size = UDim2.new(1, -182, 1, -76),
		}, animated, MOTION.Normal)

		self.TabList.ScrollingDirection = Enum.ScrollingDirection.Y
		self.TabLayout.FillDirection = Enum.FillDirection.Vertical
		self.TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		self.TabLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	end

	for _, tab in ipairs(self.Tabs) do
		tab.Button.Size = compact and UDim2.fromOffset(118, 38) or UDim2.new(1, 0, 0, 38)
		tab.Button.TextXAlignment = compact and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left

		if tab.Accent then
			tab.Accent.Position = compact and UDim2.new(0, 10, 1, -3) or UDim2.fromOffset(0, 8)
			tab.Accent.Size = compact and UDim2.new(1, -20, 0, 3) or UDim2.new(0, 3, 1, -16)
		end
	end

	self.NotificationHolder.Position = UDim2.new(1, compact and -10 or -16, 1, compact and -10 or -16)
	self.NotificationHolder.Size = UDim2.fromOffset(math.min(320, math.max(viewportSize.X - 20, 260)), math.min(320, math.max(viewportSize.Y - 20, 220)))

	self:_refreshTabCanvas()
end

function Window:_selectTab(selectedTab)
	for _, tab in ipairs(self.Tabs) do
		local selected = tab == selectedTab

		tab.Content.Visible = selected
		self:_tween(tab.Button, {
			BackgroundColor3 = selected and self.Theme.SurfaceLight or self.Theme.SurfaceMuted,
			TextColor3 = selected and self.Theme.Text or self.Theme.MutedText,
		})

		if tab.Accent then
			self:_tween(tab.Accent, {
				BackgroundTransparency = selected and 0 or 1,
			}, MOTION.Fast)
		end
	end

	self.CurrentTab = selectedTab
end

function Window:_activeTab()
	if not self.CurrentTab then
		return self:CreateTab("Main")
	end

	return self.CurrentTab
end

function Window:CreateTab(tabConfig, icon)
	local name = getName(tabConfig, "Tab")
	if type(tabConfig) == "table" then
		icon = icon or tabConfig.Icon
	end

	local buttonText = icon and (tostring(icon) .. "  " .. tostring(name)) or tostring(name)

	local button = Create.new("TextButton", {
		Name = name .. "TabButton",
		Size = self._compact and UDim2.fromOffset(118, 38) or UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = self.Theme.SurfaceMuted,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Font = DEFAULT_BOLD_FONT,
		Text = buttonText,
		TextColor3 = self.Theme.MutedText,
		TextSize = 13,
		TextXAlignment = self._compact and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
		Parent = self.TabList,
		Children = {
			corner(7),
			padding(12, 0, 8, 0),
		},
	})

	local tabAccent = Create.new("Frame", {
		Name = "Accent",
		Position = self._compact and UDim2.new(0, 10, 1, -3) or UDim2.fromOffset(0, 8),
		Size = self._compact and UDim2.new(1, -20, 0, 3) or UDim2.new(0, 3, 1, -16),
		BackgroundColor3 = self.Theme.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = button,
		Children = {
			corner(2),
		},
	})

	local content = Create.new("ScrollingFrame", {
		Name = name .. "Content",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		ScrollBarImageColor3 = self.Theme.Accent,
		ScrollBarThickness = UserInputService.TouchEnabled and 3 or 4,
		Visible = false,
		Parent = self.ContentHolder,
		Children = {
			padding(2, 2, 8, 16),
		},
	})

	local layout = listLayout(8)
	layout.Parent = content
	connectAutoCanvas(content, layout, self._maid)

	local tab = setmetatable({
		Name = name,
		Button = button,
		Accent = tabAccent,
		Content = content,
		Layout = layout,
		Window = self,
	}, Tab)

	table.insert(self.Tabs, tab)
	self:_bindTabMotion(tab)
	self:_applyResponsiveLayout(false)

	self._maid:Give(button.Activated:Connect(function()
		self:_selectTab(tab)
	end))

	if #self.Tabs == 1 then
		self:_selectTab(tab)
	end

	return tab
end

function Window:CreateLabel(config)
	return self:_activeTab():CreateLabel(config)
end

function Window:CreateSection(config)
	return self:_activeTab():CreateSection(config)
end

function Window:CreateParagraph(config)
	return self:_activeTab():CreateParagraph(config)
end

function Window:CreateDivider(config)
	return self:_activeTab():CreateDivider(config)
end

function Window:CreateButton(config)
	return self:_activeTab():CreateButton(config)
end

function Window:CreateToggle(config)
	return self:_activeTab():CreateToggle(config)
end

function Window:CreateSlider(config)
	return self:_activeTab():CreateSlider(config)
end

function Window:CreateDropdown(config)
	return self:_activeTab():CreateDropdown(config)
end

function Window:CreateInput(config)
	return self:_activeTab():CreateInput(config)
end

function Window:CreateKeybind(config)
	return self:_activeTab():CreateKeybind(config)
end

function Window:Notify(config)
	config = config or {}

	local title = config.Title or config.Name or "KryptexUI"
	local content = config.Content or config.Text or config.Description or ""
	local duration = config.Duration or 4

	local toast = Create.new("Frame", {
		Name = "Notification",
		Size = UDim2.new(1, 0, 0, 74),
		BackgroundColor3 = self.Theme.Surface,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = self.NotificationHolder,
		Children = {
			corner(8),
			stroke(self.Theme, 0.2),
		},
	})

	Create.new("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -44, 0, 20),
		Font = DEFAULT_BOLD_FONT,
		Text = title,
		TextColor3 = self.Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = toast,
	})

	Create.new("TextLabel", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 34),
		Size = UDim2.new(1, -28, 0, 30),
		Font = DEFAULT_FONT,
		Text = content,
		TextColor3 = self.Theme.MutedText,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = toast,
	})

	local progress = Create.new("Frame", {
		Name = "Progress",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = self.Theme.Accent,
		BorderSizePixel = 0,
		Parent = toast,
		Children = {
			gradient(self.Theme, 0),
		},
	})

	local close = Create.new("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.fromOffset(24, 24),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Font = DEFAULT_BOLD_FONT,
		Text = "X",
		TextColor3 = self.Theme.MutedText,
		TextSize = 12,
		Parent = toast,
	})

	local closing = false
	local function dismiss()
		if toast.Parent and not closing then
			closing = true
			animate(toast, {
				BackgroundTransparency = 1,
			}, 0.12)

			task.delay(0.14, function()
				if toast.Parent then
					toast:Destroy()
				end
			end)
		end
	end

	animate(toast, {
		BackgroundTransparency = 0,
	}, MOTION.Normal)
	animate(progress, {
		Size = UDim2.new(0, 0, 0, 3),
	}, duration)
	self:_bindButtonMotion(close, self.Theme.Surface, self.Theme.SurfaceLight, darken(self.Theme.SurfaceLight, 0.08))
	self._maid:Give(close.Activated:Connect(dismiss))
	task.delay(duration, dismiss)

	return toast
end

function Window:SetMinimized(minimized)
	if self._minimized == minimized then
		return
	end

	self._minimized = minimized
	if self.MinimizeButton then
		self.MinimizeButton.Text = minimized and "+" or "-"
	end

	if not minimized then
		self.Sidebar.Visible = true
		self.ContentHolder.Visible = true
	end

	local collapsedHeight = self._compact and 52 or 48

	self:_tween(self.Container, {
		Size = minimized and UDim2.new(self._windowSize.X.Scale, self._windowSize.X.Offset, 0, collapsedHeight) or self._windowSize,
	}, MOTION.Slow)

	self:_tween(self.Sidebar, {
		BackgroundTransparency = minimized and 1 or 0,
	}, MOTION.Normal)

	self:_tween(self.ContentHolder, {
		BackgroundTransparency = minimized and 1 or 0,
	}, MOTION.Normal)

	if minimized then
		task.delay(MOTION.Normal, function()
			if self._minimized then
				self.Sidebar.Visible = false
				self.ContentHolder.Visible = false
			end
		end)
	end
end

function Window:Toggle()
	self:SetMinimized(not self._minimized)
end

function Window:Destroy()
	if self._destroying then
		return
	end

	self._destroying = true

	if self.Scale then
		self:_tween(self.Scale, {
			Scale = 0.96,
		}, MOTION.Fast)
	end

	if self.Root then
		self:_tween(self.Root, {
			BackgroundTransparency = 1,
		}, MOTION.Fast)
	end

	task.delay(MOTION.Fast + 0.02, function()
		self._maid:Clean()
	end)
end

function Tab:_createRow(name, height)
	local rowHeight = self.Window._compact and math.max(height or 48, 56) or (height or 48)
	local labelRightPadding = self.Window._compact and 154 or 196

	local row = Create.new("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 0, rowHeight),
		BackgroundColor3 = self.Window.Theme.Surface,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.Content,
		Children = {
			corner(8),
			stroke(self.Window.Theme, 0.35),
			Create.new("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, self.Window.Theme.Surface),
					ColorSequenceKeypoint.new(1, self.Window.Theme.SurfaceMuted),
				}),
				Rotation = 90,
			}),
		},
	})

	Create.new("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -labelRightPadding, 0, math.min(rowHeight, 56)),
		Font = DEFAULT_BOLD_FONT,
		Text = name,
		TextColor3 = self.Window.Theme.Text,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})

	return row
end

function Tab:CreateSection(config)
	local name = getName(config, "Section")

	local holder = Create.new("Frame", {
		Name = name .. "Section",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Parent = self.Content,
	})

	Create.new("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(0.55, 0, 1, 0),
		Font = DEFAULT_BOLD_FONT,
		Text = name,
		TextColor3 = self.Window.Theme.Accent,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = holder,
	})

	Create.new("Frame", {
		Name = "Line",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0.42, 0, 0, 1),
		BackgroundColor3 = self.Window.Theme.Stroke,
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Parent = holder,
		Children = {
			gradient(self.Window.Theme, 0),
		},
	})

	return holder
end

function Tab:CreateLabel(config)
	local text = getName(config, "Label")

	return Create.new("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Font = DEFAULT_FONT,
		Text = text,
		TextColor3 = self.Window.Theme.MutedText,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.Content,
	})
end

function Tab:CreateParagraph(config)
	config = config or {}

	local title = config.Title or config.Name or "Paragraph"
	local content = config.Content or config.Text or config.Description or ""
	local height = config.Height or 92

	local row = Create.new("Frame", {
		Name = title,
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = self.Window.Theme.Surface,
		BorderSizePixel = 0,
		Parent = self.Content,
		Children = {
			corner(8),
			stroke(self.Window.Theme, 0.35),
			padding(14, 12, 14, 12),
			listLayout(6),
			Create.new("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, self.Window.Theme.Surface),
					ColorSequenceKeypoint.new(1, self.Window.Theme.SurfaceMuted),
				}),
				Rotation = 90,
			}),
		},
	})

	local titleLabel = Create.new("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Font = DEFAULT_BOLD_FONT,
		Text = title,
		TextColor3 = self.Window.Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})

	local bodyLabel = Create.new("TextLabel", {
		Name = "Body",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -26),
		Font = DEFAULT_FONT,
		Text = content,
		TextColor3 = self.Window.Theme.MutedText,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = row,
	})

	return {
		Instance = row,
		Set = function(_, nextConfig)
			if type(nextConfig) == "table" then
				titleLabel.Text = nextConfig.Title or nextConfig.Name or titleLabel.Text
				bodyLabel.Text = nextConfig.Content or nextConfig.Text or nextConfig.Description or bodyLabel.Text
			else
				bodyLabel.Text = tostring(nextConfig)
			end
		end,
	}
end

function Tab:CreateDivider(config)
	local name = getName(config, "Divider")

	return Create.new("Frame", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 12),
		BackgroundTransparency = 1,
		Parent = self.Content,
		Children = {
			Create.new("Frame", {
				Name = "Line",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = self.Window.Theme.Stroke,
				BackgroundTransparency = 0.35,
				BorderSizePixel = 0,
			}),
		},
	})
end

function Tab:CreateButton(config)
	config = config or {}

	local compact = self.Window._compact
	local row = self:_createRow(config.Name or config.Text or "Button", 48)
	local button = Create.new("TextButton", {
		Name = "Action",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = compact and UDim2.fromOffset(104, 36) or UDim2.fromOffset(116, 30),
		BackgroundColor3 = self.Window.Theme.Accent,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Font = DEFAULT_BOLD_FONT,
		Text = config.ButtonText or "Run",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		Parent = row,
		Children = {
			corner(7),
			gradient(self.Window.Theme, 0),
		},
	})

	self.Window:_bindButtonMotion(button, self.Window.Theme.Accent, self.Window.Theme.AccentLight, self.Window.Theme.AccentDark)
	self.Window._maid:Give(button.Activated:Connect(function()
		self.Window:_run(config.Callback)
	end))

	return {
		Instance = row,
		Button = button,
		SetText = function(_, text)
			button.Text = tostring(text)
		end,
	}
end

function Tab:CreateToggle(config)
	config = config or {}

	local compact = self.Window._compact
	local row = self:_createRow(config.Name or "Toggle", 48)
	row.Active = true
	local value = config.CurrentValue == true

	local switch = Create.new("TextButton", {
		Name = "Switch",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = compact and UDim2.fromOffset(54, 30) or UDim2.fromOffset(48, 26),
		BackgroundColor3 = value and self.Window.Theme.Accent or self.Window.Theme.SurfaceLight,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Text = "",
		Parent = row,
		Children = {
			corner(13),
			stroke(self.Window.Theme, 0.55),
		},
	})

	local knob = Create.new("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = value and UDim2.new(1, compact and -26 or -22, 0.5, 0) or UDim2.new(0, 4, 0.5, 0),
		Size = compact and UDim2.fromOffset(22, 22) or UDim2.fromOffset(18, 18),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = switch,
		Children = {
			corner(9),
		},
	})

	local toggle = {}

	local function render()
		self.Window:_tween(switch, {
			BackgroundColor3 = value and self.Window.Theme.Accent or self.Window.Theme.SurfaceLight,
		})
		self.Window:_tween(knob, {
			Position = value and UDim2.new(1, compact and -26 or -22, 0.5, 0) or UDim2.new(0, 4, 0.5, 0),
		})
	end

	function toggle:Set(newValue, silent)
		value = newValue == true

		if config.Flag then
			self.Window.Flags[config.Flag] = value
		end

		render()

		if not silent then
			self.Window:_run(config.Callback, value)
		end
	end

	function toggle:Get()
		return value
	end

	local toggleLocked = false

	local function flipToggle()
		if toggleLocked then
			return
		end

		toggleLocked = true
		toggle:Set(not value)

		task.defer(function()
			toggleLocked = false
		end)
	end

	local function inputIsInsideSwitch(input)
		local position = input.Position
		local switchPosition = switch.AbsolutePosition
		local switchSize = switch.AbsoluteSize

		return position.X >= switchPosition.X
			and position.X <= switchPosition.X + switchSize.X
			and position.Y >= switchPosition.Y
			and position.Y <= switchPosition.Y + switchSize.Y
	end

	self.Window._maid:Give(switch.Activated:Connect(flipToggle))

	self.Window._maid:Give(row.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if inputIsInsideSwitch(input) then
				return
			end

			flipToggle()
		end
	end))

	toggle:Set(value, true)

	return toggle
end

function Tab:CreateSlider(config)
	config = config or {}

	local compact = self.Window._compact
	local range = config.Range or { 0, 100 }
	local minimum = tonumber(range[1]) or 0
	local maximum = tonumber(range[2]) or 100
	local increment = tonumber(config.Increment) or 1
	local value = tonumber(config.CurrentValue) or minimum

	local row = self:_createRow(config.Name or "Slider", 70)
	row.Active = true

	local valueLabel = Create.new("TextLabel", {
		Name = "Value",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 0),
		Size = UDim2.fromOffset(84, 48),
		BackgroundTransparency = 1,
		Font = DEFAULT_BOLD_FONT,
		Text = formatNumber(value),
		TextColor3 = self.Window.Theme.MutedText,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})

	local track = Create.new("Frame", {
		Name = "Track",
		Position = UDim2.fromOffset(14, compact and 52 or 50),
		Size = UDim2.new(1, -28, 0, compact and 8 or 6),
		BackgroundColor3 = self.Window.Theme.SurfaceLight,
		BorderSizePixel = 0,
		Active = true,
		Parent = row,
		Children = {
			corner(3),
		},
	})

	local fill = Create.new("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = self.Window.Theme.Accent,
		BorderSizePixel = 0,
		Parent = track,
		Children = {
			corner(3),
			gradient(self.Window.Theme, 0),
		},
	})

	local knob = Create.new("TextButton", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = compact and UDim2.fromOffset(20, 20) or UDim2.fromOffset(16, 16),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Text = "",
		Active = true,
		Parent = track,
		Children = {
			corner(8),
			stroke(self.Window.Theme, 0.3),
		},
	})

	local hitbox = Create.new("TextButton", {
		Name = "Hitbox",
		Position = UDim2.fromOffset(8, compact and 38 or 36),
		Size = UDim2.new(1, -16, 0, compact and 40 or 34),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Text = "",
		Active = true,
		ZIndex = 8,
		Parent = row,
	})

	local slider = {}
	local dragging = false
	local dragInput = nil

	local function snap(newValue)
		newValue = math.clamp(newValue, minimum, maximum)

		if increment > 0 then
			newValue = math.floor(((newValue - minimum) / increment) + 0.5) * increment + minimum
		end

		return math.clamp(newValue, minimum, maximum)
	end

	local function render()
		local alpha = 0

		if maximum ~= minimum then
			alpha = math.clamp((value - minimum) / (maximum - minimum), 0, 1)
		end

		valueLabel.Text = formatNumber(value)
		self.Window:_tween(fill, {
			Size = UDim2.new(alpha, 0, 1, 0),
		})
		self.Window:_tween(knob, {
			Position = UDim2.new(alpha, 0, 0.5, 0),
		})
	end

	function slider:Set(newValue, silent)
		value = snap(tonumber(newValue) or value)

		if config.Flag then
			self.Window.Flags[config.Flag] = value
		end

		render()

		if not silent then
			self.Window:_run(config.Callback, value)
		end
	end

	function slider:Get()
		return value
	end

	local function updateFromX(x)
		local width = track.AbsoluteSize.X

		if width <= 0 then
			return
		end

		local alpha = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
		slider:Set(minimum + ((maximum - minimum) * alpha))
	end

	local function beginDrag(input)
		dragging = true
		dragInput = input
		updateFromX(input.Position.X)
	end

	self.Window._maid:Give(hitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end))

	self.Window._maid:Give(track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end))

	self.Window._maid:Give(knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end))

	self.Window._maid:Give(UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input == dragInput
			or input.UserInputType == Enum.UserInputType.Touch then
			updateFromX(input.Position.X)
		end
	end))

	self.Window._maid:Give(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input == dragInput
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
			dragInput = nil
		end
	end))

	self.Window:_bindButtonMotion(knob, Color3.fromRGB(255, 255, 255), self.Window.Theme.AccentLight, self.Window.Theme.Accent)
	slider:Set(value, true)

	return slider
end

function Tab:CreateDropdown(config)
	config = config or {}

	local compact = self.Window._compact
	local optionRowHeight = compact and 36 or 32
	local options = config.Options or {}
	local selected = config.CurrentOption or options[1]
	if type(selected) == "table" then
		selected = selected[1]
	end

	local open = false
	local row = self:_createRow(config.Name or "Dropdown", 48)

	local dropdownButton = Create.new("TextButton", {
		Name = "DropdownButton",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, compact and 10 or 9),
		Size = compact and UDim2.fromOffset(138, 36) or UDim2.fromOffset(156, 30),
		BackgroundColor3 = self.Window.Theme.SurfaceLight,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Font = DEFAULT_BOLD_FONT,
		Text = selected and tostring(selected) or "Select",
		TextColor3 = self.Window.Theme.Text,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
		Children = {
			corner(7),
			padding(8, 0, 8, 0),
		},
	})

	local optionHolder = Create.new("Frame", {
		Name = "Options",
		Position = UDim2.fromOffset(12, 48),
		Size = UDim2.new(1, -24, 0, 0),
		BackgroundTransparency = 1,
		Parent = row,
	})

	local optionLayout = listLayout(6)
	optionLayout.Parent = optionHolder

	local dropdown = {}

	local function optionHeight()
		return (#options * optionRowHeight) + math.max(#options - 1, 0) * 6
	end

	local function renderOpen()
		local height = open and ((compact and 64 or 58) + optionHeight()) or (compact and 56 or 48)
		self.Window:_tween(row, {
			Size = UDim2.new(1, 0, 0, height),
		}, MOTION.Normal)
		self.Window:_tween(optionHolder, {
			Size = UDim2.new(1, -24, 0, optionHeight()),
		}, MOTION.Normal)
	end

	function dropdown:Set(option, silent)
		selected = option
		dropdownButton.Text = selected and tostring(selected) or "Select"

		if config.Flag then
			self.Window.Flags[config.Flag] = selected
		end

		if not silent then
			self.Window:_run(config.Callback, selected)
		end
	end

	local function buildOptions()
		for _, child in ipairs(optionHolder:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		for _, option in ipairs(options) do
			local optionButton = Create.new("TextButton", {
				Name = tostring(option) .. "Option",
				Size = UDim2.new(1, 0, 0, optionRowHeight),
				BackgroundColor3 = self.Window.Theme.SurfaceLight,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Font = DEFAULT_FONT,
				Text = tostring(option),
				TextColor3 = self.Window.Theme.Text,
				TextSize = 12,
				Parent = optionHolder,
				Children = {
					corner(7),
				},
			})

			self.Window:_bindButtonMotion(optionButton, self.Window.Theme.SurfaceLight, lighten(self.Window.Theme.SurfaceLight, 0.08), darken(self.Window.Theme.SurfaceLight, 0.06))
			self.Window._maid:Give(optionButton.Activated:Connect(function()
				dropdown:Set(option)
				open = false
				renderOpen()
			end))
		end

		renderOpen()
	end

	function dropdown:Refresh(newOptions, keepCurrent)
		options = newOptions or {}

		if not keepCurrent then
			dropdown:Set(options[1], true)
		end

		buildOptions()
	end

	function dropdown:Get()
		return selected
	end

	self.Window:_bindButtonMotion(dropdownButton, self.Window.Theme.SurfaceLight, lighten(self.Window.Theme.SurfaceLight, 0.08), darken(self.Window.Theme.SurfaceLight, 0.06))
	self.Window._maid:Give(dropdownButton.Activated:Connect(function()
		open = not open
		renderOpen()
	end))

	buildOptions()
	dropdown:Set(selected, true)

	return dropdown
end

function Tab:CreateInput(config)
	config = config or {}

	local compact = self.Window._compact
	local row = self:_createRow(config.Name or "Input", 58)
	local boxStroke = stroke(self.Window.Theme, 0.35)

	local box = Create.new("TextBox", {
		Name = "TextBox",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = compact and UDim2.fromOffset(148, 36) or UDim2.fromOffset(174, 32),
		BackgroundColor3 = self.Window.Theme.SurfaceLight,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = DEFAULT_FONT,
		PlaceholderText = config.PlaceholderText or "Type here",
		PlaceholderColor3 = self.Window.Theme.MutedText,
		Text = config.CurrentValue or "",
		TextColor3 = self.Window.Theme.Text,
		TextSize = 13,
		Parent = row,
		Children = {
			corner(7),
			boxStroke,
			padding(10, 0, 10, 0),
		},
	})

	local inputObject = {}

	function inputObject:Set(text, silent)
		box.Text = tostring(text or "")

		if config.Flag then
			self.Window.Flags[config.Flag] = box.Text
		end

		if not silent then
			self.Window:_run(config.Callback, box.Text)
		end
	end

	function inputObject:Get()
		return box.Text
	end

	self.Window._maid:Give(box.FocusLost:Connect(function(enterPressed)
		if config.FireOnEnter and not enterPressed then
			return
		end

		inputObject:Set(box.Text)

		if config.RemoveTextAfterFocusLost then
			box.Text = ""
		end
	end))

	self.Window:_bindStrokeFocus(box, boxStroke)
	inputObject:Set(box.Text, true)

	return inputObject
end

function Tab:CreateKeybind(config)
	config = config or {}

	local compact = self.Window._compact
	local row = self:_createRow(config.Name or "Keybind", 48)
	local currentKey = resolveKeyCode(config.CurrentKeybind or config.Keybind or config.Key or Enum.KeyCode.Unknown)
	local listening = false

	local keyButton = Create.new("TextButton", {
		Name = "KeyButton",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = compact and UDim2.fromOffset(104, 36) or UDim2.fromOffset(116, 30),
		BackgroundColor3 = self.Window.Theme.SurfaceLight,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Font = DEFAULT_BOLD_FONT,
		Text = currentKey ~= Enum.KeyCode.Unknown and currentKey.Name or "None",
		TextColor3 = self.Window.Theme.Text,
		TextSize = 13,
		Parent = row,
		Children = {
			corner(7),
			stroke(self.Window.Theme, 0.45),
		},
	})

	local keybind = {}

	function keybind:Set(nextKey, silent)
		currentKey = resolveKeyCode(nextKey)
		keyButton.Text = currentKey ~= Enum.KeyCode.Unknown and currentKey.Name or "None"

		if config.Flag then
			self.Window.Flags[config.Flag] = currentKey
		end

		if not silent and config.Changed then
			self.Window:_run(config.Changed, currentKey)
		end
	end

	function keybind:Get()
		return currentKey
	end

	self.Window:_bindButtonMotion(keyButton, self.Window.Theme.SurfaceLight, lighten(self.Window.Theme.SurfaceLight, 0.08), darken(self.Window.Theme.SurfaceLight, 0.06))
	self.Window._maid:Give(keyButton.Activated:Connect(function()
		listening = true
		keyButton.Text = "..."
	end))

	self.Window._maid:Give(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed and not config.IgnoreGameProcessed then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		if listening then
			listening = false
			keybind:Set(input.KeyCode)
			return
		end

		if currentKey ~= Enum.KeyCode.Unknown and input.KeyCode == currentKey then
			self.Window:_run(config.Callback, currentKey)
		end
	end))

	keybind:Set(currentKey, true)

	return keybind
end

local function makeWindow(config)
	config = config or {}

	local theme = Theme.resolve(config.Theme)
	local screenGui = Create.new("ScreenGui", {
		Name = config.ScreenGuiName or "KryptexUI",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = config.Parent or safePlayerGui(),
	})

	local responsive = config.Responsive ~= false
	local viewportSize = getViewportSize()
	local initialCompact = responsive and isCompactViewport(viewportSize) or false
	local windowSize = responsive and resolveResponsiveSize(config.Size, viewportSize, initialCompact) or (config.Size or UDim2.fromOffset(560, 420))

	local container = Create.new("Frame", {
		Name = "KryptexContainer",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = config.Position or UDim2.fromScale(0.5, 0.5),
		Size = windowSize,
		BackgroundTransparency = 1,
		Parent = screenGui,
	})

	local windowScale = Create.new("UIScale", {
		Scale = 0.96,
		Parent = container,
	})

	local shadow = Create.new("Frame", {
		Name = "Shadow",
		Position = UDim2.fromOffset(0, 10),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Shadow,
		BackgroundTransparency = 0.65,
		BorderSizePixel = 0,
		ZIndex = 0,
		Parent = container,
		Children = {
			corner(14),
		},
	})

	local glow = Create.new("Frame", {
		Name = "Glow",
		Position = UDim2.fromOffset(-1, -1),
		Size = UDim2.new(1, 2, 1, 2),
		BackgroundColor3 = theme.Glow or theme.Accent,
		BackgroundTransparency = 0.96,
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = container,
		Children = {
			corner(12),
			gradient(theme, 35),
		},
	})

	local root = Create.new("Frame", {
		Name = "Window",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = container,
		Children = {
			corner(10),
			stroke(theme, 0.15),
		},
	})

	local topbar = Create.new("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		Parent = root,
		Children = {
			corner(10),
		},
	})

	Create.new("Frame", {
		Name = "TopbarBottomFix",
		Position = UDim2.new(0, 0, 1, -10),
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundColor3 = theme.Surface,
		BorderSizePixel = 0,
		Parent = topbar,
	})

	Create.new("Frame", {
		Name = "AccentBar",
		Position = UDim2.new(0, 0, 1, -2),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Parent = topbar,
		Children = {
			gradient(theme, 0),
		},
	})

	local titleLabel = Create.new("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(1, -80, 1, 0),
		Font = DEFAULT_BOLD_FONT,
		Text = config.Name or config.Title or "Kryptex UI",
		TextColor3 = theme.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = topbar,
	})

	local versionLabel = Create.new("TextLabel", {
		Name = "Version",
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -88, 0.5, 0),
		Size = UDim2.fromOffset(72, 20),
		Font = DEFAULT_BOLD_FONT,
		Text = "v" .. KryptexUI.Version,
		TextColor3 = theme.MutedText,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = topbar,
	})

	local minimize = Create.new("TextButton", {
		Name = "Minimize",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -50, 0.5, 0),
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = theme.SurfaceLight,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Font = DEFAULT_BOLD_FONT,
		Text = "-",
		TextColor3 = theme.MutedText,
		TextSize = 16,
		Parent = topbar,
		Children = {
			corner(7),
		},
	})

	local close = Create.new("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = theme.SurfaceLight,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Font = DEFAULT_BOLD_FONT,
		Text = "X",
		TextColor3 = theme.MutedText,
		TextSize = 12,
		Parent = topbar,
		Children = {
			corner(7),
		},
	})

	local sidebar = Create.new("Frame", {
		Name = "Sidebar",
		Position = UDim2.fromOffset(14, 62),
		Size = UDim2.new(0, 140, 1, -76),
		BackgroundColor3 = theme.SurfaceMuted,
		BorderSizePixel = 0,
		Parent = root,
		Children = {
			corner(9),
			stroke(theme, 0.45),
		},
	})

	local tabLayout = listLayout(8)
	local tabList = Create.new("ScrollingFrame", {
		Name = "TabList",
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.new(1, -16, 1, -16),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		ScrollBarImageColor3 = theme.Accent,
		ScrollBarThickness = UserInputService.TouchEnabled and 3 or 4,
		ScrollingDirection = initialCompact and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y,
		Parent = sidebar,
		Children = {
			tabLayout,
		},
	})

	local contentHolder = Create.new("Frame", {
		Name = "ContentHolder",
		Position = UDim2.fromOffset(168, 62),
		Size = UDim2.new(1, -182, 1, -76),
		BackgroundColor3 = theme.SurfaceMuted,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = root,
		Children = {
			corner(9),
			stroke(theme, 0.45),
		},
	})

	local notificationHolder = Create.new("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.fromOffset(320, 320),
		BackgroundTransparency = 1,
		Parent = screenGui,
		Children = {
			Create.new("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
			}),
		},
	})

	local window = setmetatable({
		Gui = screenGui,
		Container = container,
		Root = root,
		Shadow = shadow,
		Glow = glow,
		Scale = windowScale,
		Topbar = topbar,
		TitleLabel = titleLabel,
		VersionLabel = versionLabel,
		MinimizeButton = minimize,
		CloseButton = close,
		Sidebar = sidebar,
		TabList = tabList,
		TabLayout = tabLayout,
		ContentHolder = contentHolder,
		NotificationHolder = notificationHolder,
		Theme = theme,
		Tabs = {},
		Flags = {},
		_minimized = false,
		_compact = initialCompact,
		_requestedSize = config.Size,
		_responsive = responsive,
		_windowSize = windowSize,
		_maid = Maid.new(),
	}, Window)

	window._maid:Give(screenGui)
	window._maid:Give(tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		window:_refreshTabCanvas()
	end))
	window:_applyResponsiveLayout(false)
	window:_bindButtonMotion(minimize, theme.SurfaceLight, lighten(theme.SurfaceLight, 0.08), darken(theme.SurfaceLight, 0.08))
	window:_bindButtonMotion(close, theme.SurfaceLight, theme.Danger, darken(theme.Danger, 0.12))
	window._maid:Give(minimize.Activated:Connect(function()
		window:Toggle()
	end))

	window._maid:Give(close.Activated:Connect(function()
		window:Destroy()
	end))

	local dragging = false
	local dragInput = nil
	local dragStart = nil
	local startPosition = nil

	window._maid:Give(topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPosition = container.Position

			local endConnection
			endConnection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false

					if endConnection then
						endConnection:Disconnect()
					end
				end
			end)
		end
	end))

	window._maid:Give(topbar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end))

	window._maid:Give(UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			local delta = input.Position - dragStart
			container.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end
	end))

	local function watchCamera(camera)
		if camera then
			window._maid:Give(camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				window:_applyResponsiveLayout(true)
			end))
		end
	end

	watchCamera(workspace.CurrentCamera)
	window._maid:Give(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		watchCamera(workspace.CurrentCamera)
		window:_applyResponsiveLayout(true)
	end))

	window:_tween(windowScale, {
		Scale = 1,
	}, MOTION.Slow)
	window:_tween(shadow, {
		BackgroundTransparency = 0.38,
	}, MOTION.Slow)
	window:_tween(glow, {
		BackgroundTransparency = 0.9,
	}, MOTION.Slow)

	if config.LoadingTitle or config.LoadingSubtitle then
		window:Notify({
			Title = config.LoadingTitle or "KryptexUI",
			Content = config.LoadingSubtitle or "Loaded",
			Duration = 2,
		})
	end

	return window
end

function KryptexUI:CreateWindow(config)
	if self ~= KryptexUI and config == nil then
		config = self
	end

	return makeWindow(config)
end

KryptexUI.CreateWindow = KryptexUI.CreateWindow

return KryptexUI
