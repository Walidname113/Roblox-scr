local module = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local mouse = player:GetMouse()

local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "CustomScriptUI"
screenGui.ResetOnSpawn = false

local dragging = false
local dragInput, dragStart, startPos

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 400)
mainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = false
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

local function makeDraggable(frame)
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	game:GetService("UserInputService").InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

makeDraggable(mainFrame)

-- HEADER
local header = Instance.new("TextLabel", mainFrame)
header.Size = UDim2.new(1, -70, 0, 30)
header.Position = UDim2.new(0, 10, 0, 5)
header.Text = "Zephyr V4"
header.TextColor3 = Color3.new(1, 1, 1)
header.BackgroundTransparency = 1
header.Font = Enum.Font.SourceSansBold
header.TextSize = 18
header.TextXAlignment = Enum.TextXAlignment.Left

-- CLOSE BUTTON
local closeButton = Instance.new("TextButton", mainFrame)
closeButton.Text = "✕"
closeButton.Size = UDim2.new(0, 25, 0, 25)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
closeButton.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 6)

-- MINIMIZE BUTTON
local minimizeButton = Instance.new("TextButton", mainFrame)
minimizeButton.Text = "-"
minimizeButton.Size = UDim2.new(0, 25, 0, 25)
minimizeButton.Position = UDim2.new(1, -65, 0, 5)
minimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
minimizeButton.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", minimizeButton)

-- SCROLLING AREA
local scrollFrame = Instance.new("ScrollingFrame", mainFrame)
scrollFrame.Position = UDim2.new(0, 10, 0, 45)
scrollFrame.Size = UDim2.new(1, -20, 1, -55)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 600)
scrollFrame.ScrollBarThickness = 6
scrollFrame.BackgroundTransparency = 1
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
local layout = Instance.new("UIListLayout", scrollFrame)
layout.Padding = UDim.new(0, 5)
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Dummy buttons
for i = 1, 20 do
	local item = Instance.new("TextButton", scrollFrame)
	item.Size = UDim2.new(1, -10, 0, 30)
	item.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	item.TextColor3 = Color3.new(1, 1, 1)
	item.Text = "Function " .. i
	Instance.new("UICorner", item)
end

-- CONFIRMATION DIALOG
local confirmFrame = Instance.new("Frame", screenGui)
confirmFrame.Size = UDim2.new(0, 250, 0, 120)
confirmFrame.Position = UDim2.new(0.5, -125, 0.5, -60)
confirmFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
confirmFrame.Visible = false
Instance.new("UICorner", confirmFrame)

local confirmLabel = Instance.new("TextLabel", confirmFrame)
confirmLabel.Size = UDim2.new(1, 0, 0, 50)
confirmLabel.Text = "Are you sure you want to close this script??"
confirmLabel.TextColor3 = Color3.new(1, 1, 1)
confirmLabel.BackgroundTransparency = 1
confirmLabel.Font = Enum.Font.SourceSans
confirmLabel.TextWrapped = true
confirmLabel.TextSize = 16

local confirmBtn = Instance.new("TextButton", confirmFrame)
confirmBtn.Text = "Confirm"
confirmBtn.Size = UDim2.new(0.4, 0, 0, 30)
confirmBtn.Position = UDim2.new(0.05, 0, 1, -40)
confirmBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Instance.new("UICorner", confirmBtn)

local cancelBtn = Instance.new("TextButton", confirmFrame)
cancelBtn.Text = "Cancel"
cancelBtn.Size = UDim2.new(0.4, 0, 0, 30)
cancelBtn.Position = UDim2.new(0.55, 0, 1, -40)
cancelBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Instance.new("UICorner", cancelBtn)

-- MINIMIZED UI
local minimized = false
local minimizedFrame = Instance.new("TextButton", screenGui)
minimizedFrame.Size = UDim2.new(0, 40, 0, 40)
minimizedFrame.Position = UDim2.new(0.5, -20, 0.5, -20)
minimizedFrame.Text = "+"
minimizedFrame.TextColor3 = Color3.new(1, 1, 1)
minimizedFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
minimizedFrame.Visible = false
Instance.new("UICorner", minimizedFrame)
makeDraggable(minimizedFrame)

-- BUTTON LOGIC
closeButton.MouseButton1Click:Connect(function()
	confirmFrame.Visible = true
end)

confirmBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

cancelBtn.MouseButton1Click:Connect(function()
	confirmFrame.Visible = false
end)

minimizeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	minimizedFrame.Visible = true
end)

minimizedFrame.MouseButton1Click:Connect(function()
	mainFrame.Visible = true
	minimizedFrame.Visible = false
end)

function module.Close()
	screenGui:Destroy()
end

function module.Hide()
	mainFrame.Visible = false
	minimizedFrame.Visible = true
end

function module.Show()
	mainFrame.Visible = true
	minimizedFrame.Visible = false
end

function module.GetScreenGui()
	return screenGui
end

return module
