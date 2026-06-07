local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer

local oldGui = CoreGui:FindFirstChild("AdminRigCheckerGui")
if oldGui then oldGui:Destroy() end

local currentLang = "EN"
local locales = {
	EN = {
		title = "RigType Checker:",
		notifText = "Player: <b>%s</b>\nRig: <font color='#0078FF'><b>%s</b></font>",
		notNotResponded = "Not spawned, wait until this player spawned.",
	},
	RU = {
		title = "Чекер RigType:",
		notifText = "Игрок: <b>%s</b>\nТело: <font color='#0078FF'><b>%s</b></font>",
		notNotResponded = "Игрок мёртв (тело не найдено), подождите его возрождения.",
	}
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminRigCheckerGui"
screenGui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 350)
mainFrame.Position = UDim2.new(0.05, 0, 0.4, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local dragHeader = Instance.new("Frame")
dragHeader.Size = UDim2.new(1, 0, 0, 40)
dragHeader.BackgroundTransparency = 1
dragHeader.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -110, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = locales[currentLang].title
titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = dragHeader

local line = Instance.new("Frame")
line.Size = UDim2.new(1, 0, 0, 2)
line.Position = UDim2.new(0, 0, 0, 40)
line.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
line.BorderSizePixel = 0
line.Parent = mainFrame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 26, 0, 26)
toggleButton.Position = UDim2.new(1, -65, 0, 7)
toggleButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
toggleButton.Text = "−"
toggleButton.TextColor3 = Color3.fromRGB(240, 240, 240)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 16
toggleButton.Parent = dragHeader

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = toggleButton

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 26, 0, 26)
closeButton.Position = UDim2.new(1, -33, 0, 7)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "×"
closeButton.TextColor3 = Color3.fromRGB(240, 240, 240)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.Parent = dragHeader

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

local langButton = Instance.new("TextButton")
langButton.Size = UDim2.new(0, 32, 0, 26)
langButton.Position = UDim2.new(1, -102, 0, 7)
langButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
langButton.Text = "EN"
langButton.TextColor3 = Color3.fromRGB(0, 120, 255)
langButton.Font = Enum.Font.GothamBold
langButton.TextSize = 12
langButton.Parent = dragHeader

local langCorner = Instance.new("UICorner")
langCorner.CornerRadius = UDim.new(0, 6)
langCorner.Parent = langButton

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Size = UDim2.new(1, -20, 1, -60)
scrollingFrame.Position = UDim2.new(0, 10, 0, 50)
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.BorderSizePixel = 0
scrollingFrame.ScrollBarThickness = 4
scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 120, 255)
scrollingFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollingFrame

local dragging, dragInput, dragStart, startPos

local function update(input)
	local delta = input.Position - dragStart
	mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

dragHeader.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

dragHeader.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)

local isCollapsed = false
local originalSize = mainFrame.Size

toggleButton.MouseButton1Click:Connect(function()
	isCollapsed = not isCollapsed
	if isCollapsed then
		scrollingFrame.Visible = false
		line.Visible = false
		toggleButton.Text = "+"
		TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 250, 0, 40)}):Play()
	else
		TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = originalSize}):Play()
		task.wait(0.15)
		scrollingFrame.Visible = true
		line.Visible = true
		toggleButton.Text = "−"
	end
end)

local activeNotifications = {}
local NOTIF_WIDTH = 250
local NOTIF_HEIGHT = 60
local NOTIF_SPACING = 8
local SCREEN_PADDING = 15

local function rearrangeNotifications()
	for index, notif in ipairs(activeNotifications) do
		local targetYOffset = -SCREEN_PADDING - (index * (NOTIF_HEIGHT + NOTIF_SPACING)) + NOTIF_SPACING
		local targetPos = UDim2.new(1, -NOTIF_WIDTH - SCREEN_PADDING, 1, targetYOffset)
		TweenService:Create(notif, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
	end
end

local function showNotification(playerName, rigType)
	local notifFrame = Instance.new("Frame")
	notifFrame.Size = UDim2.new(0, NOTIF_WIDTH, 0, NOTIF_HEIGHT)
	notifFrame.Position = UDim2.new(1.2, 0, 1, -NOTIF_HEIGHT - SCREEN_PADDING)
	notifFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	notifFrame.BorderSizePixel = 0
	notifFrame.Parent = screenGui

	local nCorner = Instance.new("UICorner")
	nCorner.CornerRadius = UDim.new(0, 6)
	nCorner.Parent = notifFrame

	local sideLine = Instance.new("Frame")
	sideLine.Size = UDim2.new(0, 4, 1, 0)
	sideLine.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
	sideLine.BorderSizePixel = 0
	sideLine.Parent = notifFrame
	Instance.new("UICorner", sideLine).CornerRadius = UDim.new(0, 4)

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -20, 1, 0)
	textLabel.Position = UDim2.new(0, 12, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = string.format(locales[currentLang].notifText, playerName, rigType)
	textLabel.RichText = true
	textLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	textLabel.Font = Enum.Font.GothamMedium
	textLabel.TextSize = 13
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Parent = notifFrame

	table.insert(activeNotifications, 1, notifFrame)
	rearrangeNotifications()

	task.delay(4, function()
		for i, v in ipairs(activeNotifications) do
			if v == notifFrame then
				table.remove(activeNotifications, i)
				break
			end
		end
		local targetPos = UDim2.new(1.2, 0, notifFrame.Position.Y.Scale, notifFrame.Position.Y.Offset)
		local tween = TweenService:Create(notifFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = targetPos, BackgroundTransparency = 1})
		TweenService:Create(textLabel, TweenInfo.new(0.1), {TextTransparency = 1}):Play()
		TweenService:Create(sideLine, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
		tween:Play()
		tween.Completed:Connect(function()
			notifFrame:Destroy()
		end)
		rearrangeNotifications()
	end)
end

local function getRigType(player)
	local char = player.Character
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			return humanoid.RigType.Name
		end
	end
	return locales[currentLang].notNotResponded
end

local function updatePlayerList()
	for _, child in ipairs(scrollingFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local playBtn = Instance.new("TextButton")
		playBtn.Size = UDim2.new(1, -6, 0, 35)
		playBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
		playBtn.BorderSizePixel = 0
		playBtn.Text = "  " .. player.Name
		playBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
		playBtn.Font = Enum.Font.GothamMedium
		playBtn.TextSize = 14
		playBtn.TextXAlignment = Enum.TextXAlignment.Left
		playBtn.Parent = scrollingFrame

		local pCorner = Instance.new("UICorner")
		pCorner.CornerRadius = UDim.new(0, 4)
		pCorner.Parent = playBtn

		playBtn.MouseButton1Click:Connect(function()
			showNotification(player.Name, getRigType(player))
		end)
	end
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end

langButton.MouseButton1Click:Connect(function()
	currentLang = (currentLang == "EN") and "RU" or "EN"
	langButton.Text = currentLang
	titleLabel.Text = locales[currentLang].title
	updatePlayerList()
end)

closeButton.MouseButton1Click:Connect(function()
	screenGui:Destroy() 
end)

updatePlayerList()
local pAdded = Players.PlayerAdded:Connect(updatePlayerList)
local pRemoved = Players.PlayerRemoving:Connect(updatePlayerList)

screenGui.Destroying:Connect(function()
	pAdded:Disconnect()
	pRemoved:Disconnect()
end)
