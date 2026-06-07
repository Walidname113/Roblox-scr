local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")

local localPlayer = Players.LocalPlayer

local oldGui = CoreGui:FindFirstChild("AdminRigCheckerGui")
if oldGui then oldGui:Destroy() end

local currentLang = "EN"
local locales = {
	EN = {
		title = "RigType Checker v1.0.4:",
		notifText = "Player: <b>%s</b>\nRig: <font color='#0078FF'><b>%s</b></font>",
		notNotResponded = "Not spawned, wait until this player spawned.",
		systemNotifText = "This place only supports <font color='#0078FF'><b>%s</b></font> rigs.",
		confirmTitle = "Are you sure?",
		confirmYes = "Yes",
		confirmNo = "No"
	},
	RU = {
		title = "Чекер RigType v1.0.4:",
		notifText = "Игрок: <b>%s</b>\nТело: <font color='#0078FF'><b>%s</b></font>",
		notNotResponded = "Игрок мёртв (тело не найдено), подождите его возрождения.",
		systemNotifText = "Этот плейс поддерживает только <font color='#0078FF'><b>%s</b></font> скелеты.",
		confirmTitle = "Вы уверены?",
		confirmYes = "Да",
		confirmNo = "Нет"
	}
}

local HEADER_HEIGHT = 42
local BLUE = Color3.fromRGB(0, 120, 255)
local BTN_NORMAL = Color3.fromRGB(45, 45, 50)
local BTN_PRESS  = Color3.fromRGB(30, 30, 36)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminRigCheckerGui"
screenGui.IgnoreGuiInset = true
screenGui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 350)
mainFrame.Position = UDim2.new(0.05, 0, 0.4, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.ClipsDescendants = false
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local clipFrame = Instance.new("Frame")
clipFrame.Size = UDim2.new(1, 0, 1, -HEADER_HEIGHT)
clipFrame.Position = UDim2.new(0, 0, 0, HEADER_HEIGHT)
clipFrame.BackgroundTransparency = 1
clipFrame.ClipsDescendants = true
clipFrame.ZIndex = 1
clipFrame.Parent = mainFrame

Instance.new("UICorner", clipFrame).CornerRadius = UDim.new(0, 8)

local dragHeader = Instance.new("Frame")
dragHeader.Size = UDim2.new(1, 0, 0, 40)
dragHeader.Position = UDim2.new(0, 0, 0, 0)
dragHeader.BackgroundTransparency = 1
dragHeader.ZIndex = 5
dragHeader.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.Size = UDim2.new(1, -110, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = locales[currentLang].title
titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 5
titleLabel.Parent = dragHeader

local line = Instance.new("Frame")
line.Size = UDim2.new(1, 0, 0, 2)
line.Position = UDim2.new(0, 0, 0, 40)
line.BackgroundColor3 = BLUE
line.BorderSizePixel = 0
line.ZIndex = 5
line.Parent = mainFrame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 26, 0, 26)
toggleButton.Position = UDim2.new(1, -65, 0, 7)
toggleButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
toggleButton.Text = "−"
toggleButton.TextColor3 = Color3.fromRGB(240, 240, 240)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 16
toggleButton.ZIndex = 5
toggleButton.Parent = dragHeader
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 6)

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 26, 0, 26)
closeButton.Position = UDim2.new(1, -33, 0, 7)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "×"
closeButton.TextColor3 = Color3.fromRGB(240, 240, 240)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.ZIndex = 5
closeButton.Parent = dragHeader
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 6)

local langButton = Instance.new("TextButton")
langButton.Size = UDim2.new(0, 32, 0, 26)
langButton.Position = UDim2.new(1, -102, 0, 7)
langButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
langButton.Text = "EN"
langButton.TextColor3 = BLUE
langButton.Font = Enum.Font.GothamBold
langButton.TextSize = 12
langButton.ZIndex = 5
langButton.Parent = dragHeader
Instance.new("UICorner", langButton).CornerRadius = UDim.new(0, 6)

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Size = UDim2.new(1, -20, 1, -10)
scrollingFrame.Position = UDim2.new(0, 10, 0, 8)
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.BorderSizePixel = 0
scrollingFrame.ScrollBarThickness = 4
scrollingFrame.ScrollBarImageColor3 = BLUE
scrollingFrame.ClipsDescendants = false
scrollingFrame.ZIndex = 2
scrollingFrame.Parent = clipFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollingFrame

local confirmOverlay = Instance.new("Frame")
confirmOverlay.Size = UDim2.new(1, 0, 1, 0)
confirmOverlay.Position = UDim2.new(0, 0, 0, 0)
confirmOverlay.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
confirmOverlay.BackgroundTransparency = 1
confirmOverlay.BorderSizePixel = 0
confirmOverlay.ZIndex = 20
confirmOverlay.Visible = false
confirmOverlay.Parent = mainFrame
Instance.new("UICorner", confirmOverlay).CornerRadius = UDim.new(0, 8)

local confirmTitleLabel = Instance.new("TextLabel")
confirmTitleLabel.Size = UDim2.new(1, -20, 0, 40)
confirmTitleLabel.Position = UDim2.new(0, 10, 0, 105)
confirmTitleLabel.BackgroundTransparency = 1
confirmTitleLabel.Text = locales[currentLang].confirmTitle
confirmTitleLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
confirmTitleLabel.Font = Enum.Font.GothamBold
confirmTitleLabel.TextSize = 16
confirmTitleLabel.ZIndex = 21
confirmTitleLabel.Parent = confirmOverlay

local yesButton = Instance.new("TextButton")
yesButton.Size = UDim2.new(0, 95, 0, 32)
yesButton.Position = UDim2.new(0.5, -105, 0.5, 10)
yesButton.BackgroundColor3 = Color3.fromRGB(210, 60, 60)
yesButton.Text = locales[currentLang].confirmYes
yesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
yesButton.Font = Enum.Font.GothamBold
yesButton.TextSize = 13
yesButton.ZIndex = 21
yesButton.Parent = confirmOverlay
Instance.new("UICorner", yesButton).CornerRadius = UDim.new(0, 5)

local noButton = Instance.new("TextButton")
noButton.Size = UDim2.new(0, 95, 0, 32)
noButton.Position = UDim2.new(0.5, 10, 0.5, 10)
noButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
noButton.Text = locales[currentLang].confirmNo
noButton.TextColor3 = Color3.fromRGB(230, 230, 230)
noButton.Font = Enum.Font.GothamBold
noButton.TextSize = 13
noButton.ZIndex = 21
noButton.Parent = confirmOverlay
Instance.new("UICorner", noButton).CornerRadius = UDim.new(0, 5)

local function showConfirmOverlay()
	confirmOverlay.Visible = true
	confirmOverlay.BackgroundTransparency = 1
	for _, child in ipairs(confirmOverlay:GetDescendants()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			child.TextTransparency = 1
			TweenService:Create(child, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
		elseif child:IsA("Frame") then
			child.BackgroundTransparency = 1
			TweenService:Create(child, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
		end
	end
	TweenService:Create(confirmOverlay, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.05}):Play()
end

local function hideConfirmOverlay(callback)
	TweenService:Create(confirmOverlay, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
	for _, child in ipairs(confirmOverlay:GetDescendants()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			TweenService:Create(child, TweenInfo.new(0.12), {TextTransparency = 1}):Play()
		end
	end
	task.delay(0.15, function()
		confirmOverlay.Visible = false
		if callback then callback() end
	end)
end

local function updateHeaderStretch()
	local text = locales[currentLang].title
	local baseBounds = TextService:GetTextSize(text, 15, Enum.Font.GothamBold, Vector2.new(1000, 40))
	local currentWidth = math.max(250, baseBounds.X + 130)
	mainFrame.Size = UDim2.new(0, currentWidth, mainFrame.Size.Y.Scale, mainFrame.Size.Y.Offset)
	titleLabel.Size = UDim2.new(1, -110, 1, 0)
end

updateHeaderStretch()

local dragging, dragInput, dragStart, startPos

local function update(input)
	local delta = input.Position - dragStart
	mainFrame.Position = UDim2.new(
		startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y
	)
end

local dragBeganConn = dragHeader.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		local moveConn
		moveConn = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				if moveConn then moveConn:Disconnect() end
			end
		end)
	end
end)

local dragChangedConn = dragHeader.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

local uiChangedConn = UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)

local isCollapsed = false
local isConfirming = false
local originalHeight = 350
local wasCollapsedBeforeClose = false

local toggleConn = toggleButton.MouseButton1Click:Connect(function()
	if isConfirming then return end
	isCollapsed = not isCollapsed
	if isCollapsed then
		scrollingFrame.Visible = false
		line.Visible = false
		toggleButton.Text = "+"
		TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, 40)
		}):Play()
	else
		local tween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, originalHeight)
		})
		tween:Play()
		tween.Completed:Connect(function()
			if not isCollapsed then
				scrollingFrame.Visible = true
				line.Visible = true
			end
		end)
		toggleButton.Text = "−"
	end
end)

local activeNotifications = {}
local NOTIF_WIDTH = 250
local NOTIF_HEIGHT = 60
local NOTIF_SPACING = 5
local SCREEN_PADDING = 10
local systemNotifLabel = nil
local currentRigRestriction = "Both"

local function rearrangeNotifications()
	local currentYOffset = -SCREEN_PADDING
	local tInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for _, notif in ipairs(activeNotifications) do
		local targetPos = UDim2.new(1, -NOTIF_WIDTH - SCREEN_PADDING, 1, currentYOffset - NOTIF_HEIGHT)
		TweenService:Create(notif, tInfo, {Position = targetPos}):Play()
		currentYOffset = currentYOffset - (NOTIF_HEIGHT + NOTIF_SPACING)
	end
end

local function removeNotification(notifFrame, textLabel, sideLine)
	for i = 1, #activeNotifications do
		if activeNotifications[i] == notifFrame then
			table.remove(activeNotifications, i)
			break
		end
	end
	if notifFrame and notifFrame.Parent then
		local tween = TweenService:Create(notifFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1.2, 0, notifFrame.Position.Y.Scale, notifFrame.Position.Y.Offset),
			BackgroundTransparency = 1
		})
		if textLabel then TweenService:Create(textLabel, TweenInfo.new(0.1), {TextTransparency = 1}):Play() end
		if sideLine then TweenService:Create(sideLine, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play() end
		tween:Play()
		tween.Completed:Connect(function() notifFrame:Destroy() end)
		rearrangeNotifications()
	end
end

local function showNotification(playerName, rigType)
	local notifFrame = Instance.new("Frame")
	notifFrame.Size = UDim2.new(0, NOTIF_WIDTH, 0, NOTIF_HEIGHT)
	notifFrame.Position = UDim2.new(1.2, 0, 1, -NOTIF_HEIGHT - SCREEN_PADDING)
	notifFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	notifFrame.BorderSizePixel = 0
	notifFrame.Parent = screenGui
	Instance.new("UICorner", notifFrame).CornerRadius = UDim.new(0, 6)

	local sideLine = Instance.new("Frame")
	sideLine.Name = "SideLine"
	sideLine.Size = UDim2.new(0, 4, 1, 0)
	sideLine.BackgroundColor3 = BLUE
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

	if #activeNotifications > 0 and systemNotifLabel then
		table.insert(activeNotifications, 2, notifFrame)
	else
		table.insert(activeNotifications, 1, notifFrame)
	end
	rearrangeNotifications()

	local screenHeight = screenGui.AbsoluteSize.Y
	local currentTotalHeight = #activeNotifications * (NOTIF_HEIGHT + NOTIF_SPACING) + SCREEN_PADDING
	if currentTotalHeight > screenHeight - 5 then
		for i = #activeNotifications, 1, -1 do
			local target = activeNotifications[i]
			if target and (not systemNotifLabel or target:FindFirstChildOfClass("TextLabel") ~= systemNotifLabel) then
				removeNotification(target, target:FindFirstChildOfClass("TextLabel"), target:FindFirstChild("SideLine"))
				break
			end
		end
	end

	task.delay(4, function()
		if notifFrame and notifFrame.Parent then
			removeNotification(notifFrame, textLabel, sideLine)
		end
	end)
end

local function showSystemNotification(rigRestriction)
	currentRigRestriction = rigRestriction

	local notifFrame = Instance.new("Frame")
	notifFrame.Size = UDim2.new(0, NOTIF_WIDTH, 0, NOTIF_HEIGHT)
	notifFrame.Position = UDim2.new(1.2, 0, 1, -NOTIF_HEIGHT - SCREEN_PADDING)
	notifFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	notifFrame.BorderSizePixel = 0
	notifFrame.Parent = screenGui
	Instance.new("UICorner", notifFrame).CornerRadius = UDim.new(0, 6)

	local sideLine = Instance.new("Frame")
	sideLine.Name = "SideLine"
	sideLine.Size = UDim2.new(0, 4, 1, 0)
	sideLine.BackgroundColor3 = BLUE
	sideLine.BorderSizePixel = 0
	sideLine.Parent = notifFrame
	Instance.new("UICorner", sideLine).CornerRadius = UDim.new(0, 4)

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -40, 1, 0)
	textLabel.Position = UDim2.new(0, 12, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = string.format(locales[currentLang].systemNotifText, rigRestriction)
	textLabel.RichText = true
	textLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
	textLabel.Font = Enum.Font.GothamMedium
	textLabel.TextSize = 13
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Parent = notifFrame
	systemNotifLabel = textLabel

	local customClose = Instance.new("TextButton")
	customClose.Size = UDim2.new(0, 20, 0, 20)
	customClose.Position = UDim2.new(1, -24, 0, 6)
	customClose.BackgroundTransparency = 1
	customClose.Text = "×"
	customClose.TextColor3 = Color3.fromRGB(150, 150, 150)
	customClose.Font = Enum.Font.GothamBold
	customClose.TextSize = 16
	customClose.Parent = notifFrame

	local enterConn = customClose.MouseEnter:Connect(function() customClose.TextColor3 = Color3.fromRGB(240, 240, 240) end)
	local leaveConn = customClose.MouseLeave:Connect(function() customClose.TextColor3 = Color3.fromRGB(150, 150, 150) end)
	local clickConn
	clickConn = customClose.MouseButton1Click:Connect(function()
		systemNotifLabel = nil
		enterConn:Disconnect()
		leaveConn:Disconnect()
		clickConn:Disconnect()
		removeNotification(notifFrame, textLabel, sideLine)
	end)

	table.insert(activeNotifications, 1, notifFrame)
	rearrangeNotifications()
end

local function checkPlaceRigType()
	local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	local myRig = humanoid.RigType.Name
	local animateService = game:FindFirstChild("Animate")
	local hasGlobalR15 = animateService and animateService:FindFirstChild("R15ArtistIntent") ~= nil
	if myRig == "R6" then
		if not hasGlobalR15 then showSystemNotification("R6") end
	elseif myRig == "R15" then
		local r15Script = workspace:FindFirstChild("R15Anim") or workspace:FindFirstChild("R15ArtistIntent")
		local animScript = char:FindFirstChild("Animate")
		local isLockedR15 = animScript and animScript:FindFirstChild("Content") == nil
		if r15Script or isLockedR15 then showSystemNotification("R15") end
	end
end

local function getRigType(player)
	local char = player.Character
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then return humanoid.RigType.Name end
	end
	return locales[currentLang].notNotResponded
end

local playButtonsConnections = {}
local SCROLL_DRAG_THRESHOLD = 6

local function updatePlayerList()
	for _, conn in ipairs(playButtonsConnections) do conn:Disconnect() end
	table.clear(playButtonsConnections)

	for _, child in ipairs(scrollingFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local displayName = player.DisplayName
		local hasDisplay = displayName ~= player.Name
		local btnHeight = hasDisplay and 52 or 35

		local playBtn = Instance.new("TextButton")
		playBtn.Size = UDim2.new(1, -6, 0, btnHeight)
		playBtn.BackgroundColor3 = BTN_NORMAL
		playBtn.BorderSizePixel = 0
		playBtn.Text = ""
		playBtn.AutoButtonColor = false
		playBtn.ZIndex = 3
		playBtn.Parent = scrollingFrame
		Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 6)

		local pStroke = Instance.new("UIStroke")
		pStroke.Color = BLUE
		pStroke.Thickness = 1.5
		pStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		pStroke.Parent = playBtn

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -12, 0, 20)
		nameLabel.Position = UDim2.new(0, 10, 0, hasDisplay and 8 or 8)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = player.Name
		nameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 14
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.ZIndex = 4
		nameLabel.Parent = playBtn

		if hasDisplay then
			local dispLabel = Instance.new("TextLabel")
			dispLabel.Size = UDim2.new(1, -12, 0, 16)
			dispLabel.Position = UDim2.new(0, 10, 0, 28)
			dispLabel.BackgroundTransparency = 1
			dispLabel.Text = "(" .. displayName .. ")"
			dispLabel.TextColor3 = Color3.fromRGB(130, 130, 140)
			dispLabel.Font = Enum.Font.GothamMedium
			dispLabel.TextSize = 11
			dispLabel.TextXAlignment = Enum.TextXAlignment.Left
			dispLabel.ZIndex = 4
			dispLabel.Parent = playBtn
		end

		local downPos = nil
		local isScrolling = false

		local pressDown = playBtn.MouseButton1Down:Connect(function(x, y)
			downPos = Vector2.new(x, y)
			isScrolling = false
			TweenService:Create(playBtn, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {BackgroundColor3 = BTN_PRESS}):Play()
			TweenService:Create(pStroke, TweenInfo.new(0.08), {Thickness = 2.5}):Play()
		end)

		local pressUp = playBtn.MouseButton1Up:Connect(function()
			TweenService:Create(playBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = BTN_NORMAL}):Play()
			TweenService:Create(pStroke, TweenInfo.new(0.15), {Thickness = 1.5}):Play()
		end)

		local moveConn = UserInputService.InputChanged:Connect(function(input)
			if downPos and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = Vector2.new(input.Position.X, input.Position.Y) - downPos
				if delta.Magnitude > SCROLL_DRAG_THRESHOLD then
					isScrolling = true
					TweenService:Create(playBtn, TweenInfo.new(0.1), {BackgroundColor3 = BTN_NORMAL}):Play()
					TweenService:Create(pStroke, TweenInfo.new(0.1), {Thickness = 1.5}):Play()
				end
			end
		end)

		local clickConn = playBtn.MouseButton1Click:Connect(function()
			if isConfirming then return end
			if isScrolling then return end
			showNotification(player.Name, getRigType(player))
		end)

		table.insert(playButtonsConnections, pressDown)
		table.insert(playButtonsConnections, pressUp)
		table.insert(playButtonsConnections, moveConn)
		table.insert(playButtonsConnections, clickConn)
	end

	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end

local langConn = langButton.MouseButton1Click:Connect(function()
	if isConfirming then return end
	currentLang = (currentLang == "EN") and "RU" or "EN"
	langButton.Text = currentLang
	titleLabel.Text = locales[currentLang].title
	confirmTitleLabel.Text = locales[currentLang].confirmTitle
	yesButton.Text = locales[currentLang].confirmYes
	noButton.Text = locales[currentLang].confirmNo
	if systemNotifLabel then
		systemNotifLabel.Text = string.format(locales[currentLang].systemNotifText, currentRigRestriction)
	end
	updateHeaderStretch()
	updatePlayerList()
end)

local function closeGuiWithAnimation()
	dragBeganConn:Disconnect()
	dragChangedConn:Disconnect()
	uiChangedConn:Disconnect()
	toggleConn:Disconnect()
	langConn:Disconnect()
	for _, conn in ipairs(playButtonsConnections) do conn:Disconnect() end
	confirmOverlay.Visible = false

	for _, child in ipairs(mainFrame:GetDescendants()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			TweenService:Create(child, TweenInfo.new(0.15), {TextTransparency = 1}):Play()
		elseif child:IsA("Frame") then
			TweenService:Create(child, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
		end
	end

	local t1 = TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, 0),
		BackgroundTransparency = 1
	})
	t1:Play()
	t1.Completed:Connect(function() screenGui:Destroy() end)
end

local closeConn = closeButton.MouseButton1Click:Connect(function()
	if isConfirming then return end
	isConfirming = true
	wasCollapsedBeforeClose = isCollapsed

	if isCollapsed then
		isCollapsed = false
		toggleButton.Text = "−"
		scrollingFrame.Visible = true
		line.Visible = true
		local expandTween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, originalHeight)
		})
		expandTween:Play()
		expandTween.Completed:Connect(function()
			showConfirmOverlay()
		end)
	else
		showConfirmOverlay()
	end
end)

local yesConn = yesButton.MouseButton1Click:Connect(function()
	closeGuiWithAnimation()
end)

local noConn = noButton.MouseButton1Click:Connect(function()
	hideConfirmOverlay(function()
		isConfirming = false
		if wasCollapsedBeforeClose then
			isCollapsed = true
			toggleButton.Text = "+"
			scrollingFrame.Visible = false
			line.Visible = false
			TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
				Size = UDim2.new(0, mainFrame.Size.X.Offset, 0, 40)
			}):Play()
		end
	end)
end)

yesButton.MouseEnter:Connect(function() TweenService:Create(yesButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(240, 70, 70)}):Play() end)
yesButton.MouseLeave:Connect(function() TweenService:Create(yesButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(210, 60, 60)}):Play() end)
noButton.MouseEnter:Connect(function() TweenService:Create(noButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 60, 65)}):Play() end)
noButton.MouseLeave:Connect(function() TweenService:Create(noButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(45, 45, 50)}):Play() end)

updatePlayerList()
task.spawn(checkPlaceRigType)

local pAdded = Players.PlayerAdded:Connect(updatePlayerList)
local pRemoved = Players.PlayerRemoving:Connect(updatePlayerList)

local destroyingConn
destroyingConn = screenGui.Destroying:Connect(function()
	pAdded:Disconnect()
	pRemoved:Disconnect()
	closeConn:Disconnect()
	yesConn:Disconnect()
	noConn:Disconnect()
	destroyingConn:Disconnect()
	for _, conn in ipairs(playButtonsConnections) do conn:Disconnect() end
end)
