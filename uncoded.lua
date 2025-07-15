--// Roblox UI Framework for Exploit Developers (Delta / Others) --// ONLY UI, all logic/function binding left to devs using this framework

local Players = game:GetService("Players") local LocalPlayer = Players.LocalPlayer

-- UI library object gui_framework = {}

-- Global UI handle gui_framework.ScreenGui = Instance.new("ScreenGui") gui_framework.ScreenGui.Name = "UniversalUI" gui_framework.ScreenGui.ResetOnSpawn = false gui_framework.ScreenGui.IgnoreGuiInset = true gui_framework.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling gui_framework.ScreenGui.Parent = game.CoreGui

-- Styles gui_framework.Theme = { BackgroundColor = Color3.fromRGB(20, 20, 20), Transparency = 0.25, TextColor = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamSemibold }

-- Rounded corner utility local function apply_rounding(obj, radius) local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, radius or 6) corner.Parent = obj end

-- Create main container function gui_framework:CreateWindow(title, author) local main = Instance.new("Frame") main.Name = "MainUI" main.Size = UDim2.new(0, 500, 0, 400) main.Position = UDim2.new(0.5, -250, 0.5, -200) main.AnchorPoint = Vector2.new(0.5, 0.5) main.BackgroundColor3 = self.Theme.BackgroundColor main.BackgroundTransparency = self.Theme.Transparency main.Active = true main.Draggable = true apply_rounding(main) main.Parent = self.ScreenGui

-- Title bar
local titleBar = Instance.new("TextLabel")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundTransparency = 1
titleBar.Text = string.format("%s | by %s", title or "UI", author or "unknown")
titleBar.Font = self.Theme.Font
titleBar.TextColor3 = self.Theme.TextColor
titleBar.TextSize = 20
titleBar.Parent = main

-- Close button
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
	gui_framework.ScreenGui:Destroy()
end)

-- Tab container
local tabContainer = Instance.new("Frame")
tabContainer.Name = "Tabs"
tabContainer.Position = UDim2.new(0, 0, 0, 40)
tabContainer.Size = UDim2.new(0, 120, 1, -40)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = main

-- Category content holder
local contentHolder = Instance.new("Frame")
contentHolder.Name = "Content"
contentHolder.Position = UDim2.new(0, 120, 0, 40)
contentHolder.Size = UDim2.new(1, -120, 1, -40)
contentHolder.BackgroundTransparency = 1
contentHolder.Parent = main

gui_framework.MainFrame = main
gui_framework.Tabs = tabContainer
gui_framework.Content = contentHolder
return self

end

function gui_framework:AddCategory(name) local button = Instance.new("TextButton") button.Size = UDim2.new(1, 0, 0, 30) button.BackgroundColor3 = Color3.fromRGB(30, 30, 30) button.Text = name button.Font = self.Theme.Font button.TextColor3 = self.Theme.TextColor button.TextSize = 16 apply_rounding(button) button.Parent = self.Tabs

local content = Instance.new("Frame")
content.Visible = false
content.Size = UDim2.new(1, 0, 1, 0)
content.BackgroundTransparency = 1
content.Parent = self.Content

button.MouseButton1Click:Connect(function()
	for _, tab in ipairs(self.Content:GetChildren()) do
		tab.Visible = false
	end
	content.Visible = true
end)

return content

end

function gui_framework:CreateButton(parent, text, callback) local btn = Instance.new("TextButton") btn.Size = UDim2.new(1, -10, 0, 30) btn.Position = UDim2.new(0, 5, 0, 0) btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) btn.Text = text btn.Font = self.Theme.Font btn.TextColor3 = self.Theme.TextColor btn.TextSize = 14 apply_rounding(btn) btn.Parent = parent btn.MouseButton1Click:Connect(callback or function() end) end

function gui_framework:CreateToggle(parent, text, default, callback) local toggle = Instance.new("TextButton") toggle.Size = UDim2.new(1, -10, 0, 30) toggle.Position = UDim2.new(0, 5, 0, 0) toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50) toggle.Text = text .. (default and " [ON]" or " [OFF]") toggle.Font = self.Theme.Font toggle.TextColor3 = self.Theme.TextColor toggle.TextSize = 14 apply_rounding(toggle) toggle.Parent = parent

local state = default or false
toggle.MouseButton1Click:Connect(function()
	state = not state
	toggle.Text = text .. (state and " [ON]" or " [OFF]")
	if callback then callback(state) end
end)

end

function gui_framework:CreateSlider(parent, min, max, callback) local box = Instance.new("TextBox") box.Size = UDim2.new(1, -10, 0, 30) box.Position = UDim2.new(0, 5, 0, 0) box.BackgroundColor3 = Color3.fromRGB(60, 60, 60) box.Text = tostring(min) box.ClearTextOnFocus = false box.Font = self.Theme.Font box.TextColor3 = self.Theme.TextColor box.TextSize = 14 apply_rounding(box) box.Parent = parent

box.FocusLost:Connect(function()
	local val = tonumber(box.Text)
	if val and val >= min and val <= max then
		if callback then callback(val) end
	else
		box.Text = tostring(min)
	end
end)

end

function gui_framework:CreateDropdown(parent, list, callback) local dropdown = Instance.new("TextButton") dropdown.Size = UDim2.new(1, -10, 0, 30) dropdown.Position = UDim2.new(0, 5, 0, 0) dropdown.BackgroundColor3 = Color3.fromRGB(70, 70, 70) dropdown.Text = "Select..." dropdown.Font = self.Theme.Font dropdown.TextColor3 = self.Theme.TextColor dropdown.TextSize = 14 apply_rounding(dropdown) dropdown.Parent = parent

dropdown.MouseButton1Click:Connect(function()
	print("Dropdown clicked. Devs must implement their own list UI popup")
	if callback then callback() end
end)

end

function gui_framework:CreatePlayerDropdown(parent, callback) local players = {} for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(players, p.Name) end end self:CreateDropdown(parent, players, callback) end

return gui_framework
