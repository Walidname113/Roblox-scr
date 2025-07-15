--!strict
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local gui_framework = {}

-- Theme
gui_framework.Theme = {
	BackgroundColor = Color3.fromRGB(20, 20, 20),
	Transparency = 0.25,
	TextColor = Color3.fromRGB(255, 255, 255),
	Font = Enum.Font.GothamSemibold
}

-- Rounded corners
local function apply_rounding(obj, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = obj
end

-- Icons
local RESTART_ICON = "↻"

function gui_framework:CreateWindow(title, author)
	local gui = Instance.new("ScreenGui")
	gui.Name = "UniversalUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = game:GetService("CoreGui")

	local main = Instance.new("Frame")
	main.Name = "MainUI"
	main.Size = UDim2.new(0, 400, 0, 320)
	main.Position = UDim2.new(0.5, -200, 0.5, -160)
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.BackgroundColor3 = self.Theme.BackgroundColor
	main.BackgroundTransparency = self.Theme.Transparency
	main.Active = true
	main.Draggable = true
	apply_rounding(main)
	main.Parent = gui

	local titleBar = Instance.new("TextLabel")
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.BackgroundTransparency = 1
	titleBar.Text = string.format("%s | by %s", title or "UI", author or "unknown")
	titleBar.Font = self.Theme.Font
	titleBar.TextColor3 = self.Theme.TextColor
	titleBar.TextSize = 20
	titleBar.Parent = main

	local minimizedBtn = Instance.new("TextButton")
	minimizedBtn.Size = UDim2.new(0, 30, 0, 30)
	minimizedBtn.Position = UDim2.new(1, -70, 0, 5)
	minimizedBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 0)
	minimizedBtn.Text = "-"
	minimizedBtn.TextColor3 = Color3.new(1, 1, 1)
	minimizedBtn.Font = self.Theme.Font
	minimizedBtn.TextSize = 18
	apply_rounding(minimizedBtn)
	minimizedBtn.Parent = main

	local restoreBtn = Instance.new("TextButton")
	restoreBtn.Size = UDim2.new(0, 50, 0, 50)
	restoreBtn.Position = UDim2.new(0.5, -25, 0.5, -25)
	restoreBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	restoreBtn.Text = "+"
	restoreBtn.TextColor3 = Color3.new(1, 1, 1)
	restoreBtn.Font = self.Theme.Font
	restoreBtn.TextSize = 30
	apply_rounding(restoreBtn)
	restoreBtn.Parent = gui
	restoreBtn.Visible = false
	restoreBtn.Active = true
	restoreBtn.Draggable = true

	restoreBtn.MouseButton1Click:Connect(function()
		main.Visible = true
		restoreBtn.Visible = false
	end)

	minimizedBtn.MouseButton1Click:Connect(function()
		main.Visible = false
		restoreBtn.Visible = true
	end)

	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 30, 0, 30)
	close.Position = UDim2.new(1, -35, 0, 5)
	close.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	close.Text = "X"
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Font = self.Theme.Font
	close.TextSize = 18
	apply_rounding(close)
	close.Parent = main
	close.MouseButton1Click:Connect(function()
		gui:Destroy()
	end)

	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "Tabs"
	tabContainer.Position = UDim2.new(0, 0, 0, 40)
	tabContainer.Size = UDim2.new(0, 100, 1, -40)
	tabContainer.BackgroundTransparency = 1
	tabContainer.Parent = main

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Padding = UDim.new(0, 5)
	tabLayout.Parent = tabContainer

	local contentHolder = Instance.new("Frame")
	contentHolder.Name = "Content"
	contentHolder.Position = UDim2.new(0, 100, 0, 40)
	contentHolder.Size = UDim2.new(1, -100, 1, -40)
	contentHolder.BackgroundTransparency = 1
	contentHolder.Parent = main

	self.ScreenGui = gui
	self.MainFrame = main
	self.Tabs = tabContainer
	self.Content = contentHolder
	return self
end

function gui_framework:AddCategory(name)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 30)
	button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	button.Text = name
	button.Font = self.Theme.Font
	button.TextColor3 = self.Theme.TextColor
	button.TextSize = 16
	apply_rounding(button)
	button.Parent = self.Tabs

	local content = Instance.new("Frame")
	content.Visible = false
	content.Size = UDim2.new(1, 0, 1, 0)
	content.BackgroundTransparency = 1
	content.Name = name .. "_Content"
	content.Parent = self.Content

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = content

	button.MouseButton1Click:Connect(function()
		for _, tab in ipairs(self.Content:GetChildren()) do
			tab.Visible = false
		end
		content.Visible = true
	end)

	return content
end

function gui_framework:CreateButton(parent, text, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -10, 0, 30)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	btn.Text = text
	btn.Font = self.Theme.Font
	btn.TextColor3 = self.Theme.TextColor
	btn.TextSize = 14
	apply_rounding(btn)
	btn.Parent = parent
	btn.LayoutOrder = 0
	btn.MouseButton1Click:Connect(function()
		pcall(callback or function() end)
	end)
end

function gui_framework:CreateToggle(parent, text, default, callback)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, -10, 0, 30)
	holder.BackgroundTransparency = 1
	holder.Parent = parent
	holder.LayoutOrder = 0

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -40, 1, 0)
	label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = self.Theme.Font
	label.TextColor3 = self.Theme.TextColor
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = holder

	local box = Instance.new("TextButton")
	box.Size = UDim2.new(0, 24, 0, 24)
	box.Position = UDim2.new(1, -30, 0.5, -12)
	box.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	box.Text = ""
	apply_rounding(box)
	box.Parent = holder

	local check = Instance.new("TextLabel")
	check.Size = UDim2.new(1, 0, 1, 0)
	check.BackgroundTransparency = 1
	check.Text = default and "✔" or ""
	check.Font = self.Theme.Font
	check.TextColor3 = Color3.new(1, 1, 1)
	check.TextScaled = true
	check.Parent = box

	local state = default or false
	box.MouseButton1Click:Connect(function()
		state = not state
		check.Text = state and "✔" or ""
		if callback then pcall(callback, state) end
	end)
end

function gui_framework:CreatePlayerDropdown(parent, callback)
	local dropdownHolder = Instance.new("Frame")
	dropdownHolder.Size = UDim2.new(1, -10, 0, 30)
	dropdownHolder.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	dropdownHolder.ClipsDescendants = true
	apply_rounding(dropdownHolder)
	dropdownHolder.Parent = parent

	local dropdown = Instance.new("TextButton")
	dropdown.Size = UDim2.new(1, -30, 1, 0)
	dropdown.Position = UDim2.new(0, 0, 0, 0)
	dropdown.Text = "Select Player"
	dropdown.TextColor3 = self.Theme.TextColor
	dropdown.Font = self.Theme.Font
	dropdown.TextSize = 14
	dropdown.BackgroundTransparency = 1
	dropdown.Parent = dropdownHolder

	local restartBtn = Instance.new("TextButton")
	restartBtn.Size = UDim2.new(0, 30, 1, 0)
	restartBtn.Position = UDim2.new(1, -30, 0, 0)
	restartBtn.Text = RESTART_ICON
	restartBtn.TextColor3 = Color3.new(1, 1, 1)
	restartBtn.Font = self.Theme.Font
	restartBtn.TextSize = 18
	restartBtn.BackgroundTransparency = 1
	restartBtn.Parent = dropdownHolder

	local container = Instance.new("ScrollingFrame")
	container.Size = UDim2.new(1, 0, 0, 100)
	container.Position = UDim2.new(0, 0, 1, 0)
	container.CanvasSize = UDim2.new(0, 0, 0, 0)
	container.Visible = false
	container.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	container.ScrollBarThickness = 6
	apply_rounding(container)
	container.Parent = dropdownHolder

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.Parent = container

	local function refresh()
		container:ClearAllChildren()
		layout.Parent = container

		local found = false
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(1, 0, 0, 25)
				b.Text = p.Name
				b.Font = self.Theme.Font
				b.TextColor3 = self.Theme.TextColor
				b.TextSize = 14
				b.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
				b.Parent = container
				b.MouseButton1Click:Connect(function()
					dropdown.Text = p.Name
					container.Visible = false
					if callback then pcall(callback, p.Name) end
				end)
				if dropdown.Text == p.Name then
					found = true
				end
			end
		end
		if not found then
			dropdown.Text = "Select Player"
		end
	end

	dropdown.MouseButton1Click:Connect(function()
		container.Visible = not container.Visible
	end)

	restartBtn.MouseButton1Click:Connect(function()
		refresh()
	end)

	refresh()
end

function gui_framework:CheckGameId(expected)
	return game.GameId == expected
end

return gui_framework
