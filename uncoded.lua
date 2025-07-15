local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local gui_framework = {}

-- Настройки
gui_framework.Theme = {
	BackgroundColor = Color3.fromRGB(20, 20, 20),
	Transparency = 0.25,
	TextColor = Color3.fromRGB(255, 255, 255),
	Font = Enum.Font.GothamSemibold
}

local function apply_rounding(obj, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = obj
end

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
	button.LayoutOrder = #self.Tabs:GetChildren()
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
	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(1, -10, 0, 30)
	toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	toggle.Text = text .. (default and " [ON]" or " [OFF]")
	toggle.Font = self.Theme.Font
	toggle.TextColor3 = self.Theme.TextColor
	toggle.TextSize = 14
	apply_rounding(toggle)
	toggle.Parent = parent
	toggle.LayoutOrder = 0

	local state = default or false
	toggle.MouseButton1Click:Connect(function()
		state = not state
		toggle.Text = text .. (state and " [ON]" or " [OFF]")
		pcall(function() if callback then callback(state) end end)
	end)
end

function gui_framework:CreateDropdown(parent, list, callback)
	local dropdown = Instance.new("TextButton")
	dropdown.Size = UDim2.new(1, -10, 0, 30)
	dropdown.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	dropdown.Text = "Select..."
	dropdown.Font = self.Theme.Font
	dropdown.TextColor3 = self.Theme.TextColor
	dropdown.TextSize = 14
	apply_rounding(dropdown)
	dropdown.Parent = parent
	dropdown.LayoutOrder = 0

	local dropdownFrame = Instance.new("Frame")
	dropdownFrame.Size = UDim2.new(1, -10, 0, math.clamp(#list,1,5) * 25)
	dropdownFrame.Position = UDim2.new(0, 5, 0, 35)
	dropdownFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	dropdownFrame.Visible = false
	dropdownFrame.ClipsDescendants = true
	apply_rounding(dropdownFrame)
	dropdownFrame.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.Parent = dropdownFrame

	for _, item in ipairs(list) do
		local option = Instance.new("TextButton")
		option.Size = UDim2.new(1, 0, 0, 25)
		option.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		option.Text = item
		option.TextColor3 = Color3.new(1, 1, 1)
		option.Font = self.Theme.Font
		option.TextSize = 14
		option.Parent = dropdownFrame

		option.MouseButton1Click:Connect(function()
			dropdown.Text = item
			dropdownFrame.Visible = false
			if callback then callback(item) end
		end)
	end

	dropdown.MouseButton1Click:Connect(function()
		dropdownFrame.Visible = not dropdownFrame.Visible
	end)
end

function gui_framework:CreatePlayerDropdown(parent, callback)
	local players = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			table.insert(players, p.Name)
		end
	end
	self:CreateDropdown(parent, players, callback)
end

function gui_framework:CheckGameId(expected)
	return game.GameId == expected
end

return gui_framework
