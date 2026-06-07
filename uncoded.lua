--[[
Copyright (c) 2025 Kiyatsuka
Licensed under the Kiyatsuka GUI Proprietary License v1.1
GUI Source Code: https://raw.githubusercontent.com/Walidname113/Roblox-scr/refs/heads/main/uncoded.lua
Full license text: https://raw.githubusercontent.com/Walidname113/Roblox-scr/refs/heads/main/LICENSE

Key points:
- "Software" = this GUI source code, scripts, and resources.
- Users may download, run, integrate, and call public functions.
- Users MAY NOT modify, redistribute modified code, reverse-engineer, or violate laws.
- By downloading, installing, copying, or using, the User explicitly accepts all terms.
- Educational copying (review, study, evaluation) allowed without modification.
--]]

-- v18 --
local module = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local connections = {}
local trackedObjects = {}

local Theme = {
    Background = Color3.fromRGB(15, 15, 18),
    SecondaryBg = Color3.fromRGB(22, 22, 26),
    AccentGlow = Color3.fromRGB(168, 85, 247),
    TextMain = Color3.fromRGB(243, 244, 246),
    TextMuted = Color3.fromRGB(156, 163, 175),
    Border = Color3.fromRGB(39, 39, 42),
    Success = Color3.fromRGB(34, 197, 94),
    Danger = Color3.fromRGB(239, 68, 68),
    FontMain = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
}

local function trackConnection(conn) table.insert(connections, conn) end
local function trackObject(obj) table.insert(trackedObjects, obj) end

local function disconnectAll()
    for _, conn in ipairs(connections) do if conn.Connected then conn:Disconnect() end end
    connections = {}
end

local function destroyAll()
    for _, obj in ipairs(trackedObjects) do if obj and obj.Parent then obj:Destroy() end end
    trackedObjects = {}
end

local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    trackConnection(frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            trackConnection(input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end))
        end
    end))
    trackConnection(frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))
    trackConnection(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            TweenService:Create(frame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            }):Play()
        end
    end))
end

function module.CreateUI(title)
    local headerText = title or "Modern Suite"
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ModernScriptUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 9999
    screenGui.Parent = player:WaitForChild("PlayerGui")
    trackObject(screenGui)

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 620, 0, 420)
    mainFrame.Position = UDim2.new(0.5, -310, 0.5, -210)
    mainFrame.BackgroundColor3 = Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.ClipsDescendants = false
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)
    makeDraggable(mainFrame)
    trackObject(mainFrame)

    local mainStroke = Instance.new("UIStroke", mainFrame)
    mainStroke.Color = Theme.Border
    mainStroke.Thickness = 1
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local headerLine = Instance.new("Frame", mainFrame)
    headerLine.Size = UDim2.new(1, 0, 0, 1)
    headerLine.Position = UDim2.new(0, 0, 0, 45)
    headerLine.BackgroundColor3 = Theme.Border
    headerLine.BorderSizePixel = 0

    local header = Instance.new("TextLabel", mainFrame)
    header.Size = UDim2.new(1, -120, 0, 45)
    header.Position = UDim2.new(0, 20, 0, 0)
    header.Text = headerText:upper()
    header.TextColor3 = Theme.TextMain
    header.BackgroundTransparency = 1
    header.Font = Theme.FontBold
    header.TextSize = 14
    header.TextXAlignment = Enum.TextXAlignment.Left
    
    local uigrad = Instance.new("UIGradient", header)
    uigrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.TextMain),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
    })

    local controlButtons = Instance.new("Frame", mainFrame)
    controlButtons.Size = UDim2.new(0, 90, 0, 45)
    controlButtons.Position = UDim2.new(1, -105, 0, 0)
    controlButtons.BackgroundTransparency = 1

    local function createControlBtn(text, posX, color)
        local btn = Instance.new("TextButton", controlButtons)
        btn.Size = UDim2.new(0, 24, 0, 24)
        btn.Position = UDim2.new(0, posX, 0.5, -12)
        btn.BackgroundColor3 = Theme.SecondaryBg
        btn.Text = text
        btn.Font = Theme.FontBold
        btn.TextSize = 11
        btn.TextColor3 = Theme.TextMuted
        local cr = Instance.new("UICorner", btn)
        cr.CornerRadius = UDim.new(0, 6)
        local strk = Instance.new("UIStroke", btn)
        strk.Color = Theme.Border
        
        trackConnection(btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color, TextColor3 = Theme.TextMain}):Play()
        end))
        trackConnection(btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SecondaryBg, TextColor3 = Theme.TextMuted}):Play()
        end))
        return btn
    end

    local minimizeButton = createControlBtn("—", 0, Color3.fromRGB(234, 179, 8))
    local scaleButton = createControlBtn("⤢", 30, Theme.AccentGlow)
    local closeButton = createControlBtn("✕", 60, Theme.Danger)

    local confirmFrame = Instance.new("Frame", screenGui)
    confirmFrame.Size = UDim2.new(0, 320, 0, 140)
    confirmFrame.Position = UDim2.new(0.5, -160, 0.5, -70)
    confirmFrame.BackgroundColor3 = Theme.SecondaryBg
    confirmFrame.ClipsDescendants = true
    confirmFrame.BackgroundTransparency = 1
    confirmFrame.Visible = false
    Instance.new("UICorner", confirmFrame).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", confirmFrame).Color = Theme.Border
    trackObject(confirmFrame)

    local confirmText = Instance.new("TextLabel", confirmFrame)
    confirmText.Size = UDim2.new(1, -40, 0, 60)
    confirmText.Position = UDim2.new(0, 20, 0, 15)
    confirmText.Text = "Вы уверены, что хотите закрыть интерфейс?"
    confirmText.TextColor3 = Theme.TextMain
    confirmText.BackgroundTransparency = 1
    confirmText.Font = Theme.FontMain
    confirmText.TextSize = 14
    confirmText.TextWrapped = true

    local function createModalBtn(text, posX, bg, textColor)
        local btn = Instance.new("TextButton", confirmFrame)
        btn.Size = UDim2.new(0, 130, 0, 36)
        btn.Position = UDim2.new(0, posX, 1, -50)
        btn.Text = text
        btn.BackgroundColor3 = bg
        btn.TextColor3 = textColor
        btn.Font = Theme.FontBold
        btn.TextSize = 13
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        return btn
    end

    local yesBtn = createModalBtn("Да", 20, Theme.Danger, Theme.TextMain)
    local noBtn = createModalBtn("Отмена", 170, Color3.fromRGB(39, 39, 42), Theme.TextMain)

    local function animateModal(show)
        if show then
            confirmFrame.Size = UDim2.new(0, 320, 0, 120)
            confirmFrame.BackgroundTransparency = 1
            confirmFrame.Visible = true
            TweenService:Create(confirmFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0, 320, 0, 140), BackgroundTransparency = 0}):Play()
        else
            local tw = TweenService:Create(confirmFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 320, 0, 120), BackgroundTransparency = 1})
            tw:Play()
            tw.Completed:Connect(function() confirmFrame.Visible = false end)
        end
    end

    trackConnection(closeButton.MouseButton1Click:Connect(function() animateModal(true) end))
    trackConnection(noBtn.MouseButton1Click:Connect(function() animateModal(false) end))
    trackConnection(yesBtn.MouseButton1Click:Connect(function()
        disconnectAll()
        destroyAll()
    end))

    local isScaledDown = false
    local normalSize = UDim2.new(0, 620, 0, 420)
    local smallSize = UDim2.new(0, 620, 0, 200)

    trackConnection(scaleButton.MouseButton1Click:Connect(function()
        isScaledDown = not isScaledDown
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = isScaledDown and smallSize or normalSize}):Play()
    end))

    local minimizedFrame = Instance.new("ImageButton")
    minimizedFrame.Size = UDim2.new(0, 48, 0, 48)
    minimizedFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
    minimizedFrame.BackgroundColor3 = Theme.Background
    minimizedFrame.Visible = false
    Instance.new("UICorner", minimizedFrame).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", minimizedFrame).Color = Theme.AccentGlow
    makeDraggable(minimizedFrame)
    minimizedFrame.Parent = screenGui

    local plusIcon = Instance.new("TextLabel", minimizedFrame)
    plusIcon.Size = UDim2.new(1, 0, 1, 0)
    plusIcon.Text = "+"
    plusIcon.TextColor3 = Theme.AccentGlow
    plusIcon.BackgroundTransparency = 1
    plusIcon.Font = Theme.FontBold
    plusIcon.TextSize = 24
    module.MinimizedFrame = minimizedFrame

    local function setMinimizedImage(assetId)
        if assetId and assetId ~= "" then
            minimizedFrame.Image = "rbxassetid://" .. assetId
            plusIcon.Visible = false
        else
            minimizedFrame.Image = ""
            plusIcon.Visible = true
        end
    end

    local function toggleMinimize(minimize)
        if minimize then
            TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = UDim2.new(0,0,0,0), BackgroundTransparency = 1}):Play()
            task.delay(0.2, function()
                mainFrame.Visible = false
                minimizedFrame.Visible = true
                minimizedFrame.Size = UDim2.new(0,0,0,0)
                TweenService:Create(minimizedFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0, 48, 0, 48)}):Play()
            end)
        else
            TweenService:Create(minimizedFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(0,0,0,0)}):Play()
            task.delay(0.15, function()
                minimizedFrame.Visible = false
                mainFrame.Visible = true
                TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = isScaledDown and smallSize or normalSize, BackgroundTransparency = 0}):Play()
            end)
        end
    end

    trackConnection(minimizeButton.MouseButton1Click:Connect(function() toggleMinimize(true) end))
    trackConnection(minimizedFrame.MouseButton1Click:Connect(function() toggleMinimize(false) end))

    local categoryFrame = Instance.new("ScrollingFrame", mainFrame)
    categoryFrame.Size = UDim2.new(0, 160, 1, -65)
    categoryFrame.Position = UDim2.new(0, 12, 0, 55)
    categoryFrame.CanvasSize = UDim2.new(0,0,0,0)
    categoryFrame.ScrollBarThickness = 0
    categoryFrame.BackgroundTransparency = 1
    categoryFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    trackObject(categoryFrame)

    local categoryLayout = Instance.new("UIListLayout", categoryFrame)
    categoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
    categoryLayout.Padding = UDim.new(0, 8)

    local contentFrame = Instance.new("Frame", mainFrame)
    contentFrame.Size = UDim2.new(1, -196, 1, -65)
    contentFrame.Position = UDim2.new(0, 184, 0, 55)
    contentFrame.BackgroundColor3 = Theme.SecondaryBg
    contentFrame.BorderSizePixel = 0
    Instance.new("UICorner", contentFrame).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", contentFrame).Color = Theme.Border
    trackObject(contentFrame)

    local contentScroll = Instance.new("ScrollingFrame", contentFrame)
    contentScroll.Size = UDim2.new(1, -16, 1, -16)
    contentScroll.Position = UDim2.new(0, 8, 0, 8)
    contentScroll.BackgroundTransparency = 1
    contentScroll.ScrollBarThickness = 4
    contentScroll.ScrollBarImageColor3 = Theme.Border
    contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentScroll.CanvasSize = UDim2.new(0,0,0,0)
    trackObject(contentScroll)

    local contentPadding = Instance.new("UIPadding", contentScroll)
    contentPadding.PaddingBottom = UDim.new(0, 10)

    local categories = {}

    function module.CreateCategory(name)
        local button = Instance.new("TextButton", categoryFrame)
        button.Size = UDim2.new(1, -5, 0, 38)
        button.Text = "  " .. name
        button.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
        button.TextColor3 = Theme.TextMuted
        button.Font = Theme.FontMain
        button.TextSize = 13
        button.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
        local bStroke = Instance.new("UIStroke", button)
        bStroke.Color = Theme.Border
        trackObject(button)

        local selectionBar = Instance.new("Frame", button)
        selectionBar.Size = UDim2.new(0, 4, 0, 16)
        selectionBar.Position = UDim2.new(0, 6, 0.5, -8)
        selectionBar.BackgroundColor3 = Theme.AccentGlow
        selectionBar.Visible = false
        Instance.new("UICorner", selectionBar)

        local holder = Instance.new("Frame", contentScroll)
        holder.Size = UDim2.new(1, 0, 0, 0)
        holder.BackgroundTransparency = 1
        holder.Visible = false
        trackObject(holder)

        local layout = Instance.new("UIListLayout", holder)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 8)

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            holder.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
            if holder.Visible then contentScroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y) end
        end)

        trackConnection(button.MouseButton1Click:Connect(function()
            for _, cat in ipairs(categories) do
                cat.holder.Visible = false
                cat.bar.Visible = false
                TweenService:Create(cat.button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(24,24,27), TextColor3 = Theme.TextMuted}):Play()
            end
            holder.Visible = true
            selectionBar.Visible = true
            contentScroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
            TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SecondaryBg, TextColor3 = Theme.TextMain}):Play()
        end))

        table.insert(categories, {holder = holder, button = button, bar = selectionBar})
        return holder
    end

    function module.CreateToggle(text, parent, callback)
        local container = Instance.new("Frame", parent)
        container.Size = UDim2.new(1, -4, 0, 42)
        container.BackgroundColor3 = Theme.Background
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
        Instance.new("UIStroke", container).Color = Theme.Border
        trackObject(container)

        local label = Instance.new("TextLabel", container)
        label.Size = UDim2.new(1, -60, 1, 0)
        label.Position = UDim2.new(0, 14, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.Font = Theme.FontMain
        label.TextSize = 13
        label.TextColor3 = Theme.TextMain
        label.TextXAlignment = Enum.TextXAlignment.Left

        local switch = Instance.new("Frame", container)
        switch.Size = UDim2.new(0, 42, 0, 22)
        switch.Position = UDim2.new(1, -54, 0.5, -11)
        switch.BackgroundColor3 = Theme.SecondaryBg
        Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)
        local sStroke = Instance.new("UIStroke", switch)
        sStroke.Color = Theme.Border

        local knob = Instance.new("Frame", switch)
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = UDim2.new(0, 3, 0.5, -8)
        knob.BackgroundColor3 = Theme.TextMuted
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local enabled = false
        local function updateVisual(animate)
            local tInfo = TweenInfo.new(animate and 0.25 or 0, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            local bgInfo = TweenInfo.new(animate and 0.2 or 0)
            if enabled then
                TweenService:Create(switch, bgInfo, {BackgroundColor3 = Theme.AccentGlow}):Play()
                TweenService:Create(knob, tInfo, {Position = UDim2.new(1, -19, 0.5, -8), BackgroundColor3 = Theme.TextMain}):Play()
            else
                TweenService:Create(switch, bgInfo, {BackgroundColor3 = Theme.SecondaryBg}):Play()
                TweenService:Create(knob, tInfo, {Position = UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = Theme.TextMuted}):Play()
            end
        end

        trackConnection(container.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                enabled = not enabled
                updateVisual(true)
                if callback then callback(enabled) end
            end
        end))

        updateVisual(false)
        return container
    end

    function module.CreateButton(text, parent, callback)
        local button = Instance.new("TextButton", parent)
        button.Size = UDim2.new(1, -4, 0, 40)
        button.Text = text
        button.BackgroundColor3 = Theme.SecondaryBg
        button.TextColor3 = Theme.TextMain
        button.Font = Theme.FontBold
        button.TextSize = 13
        button.AutoButtonColor = false
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
        local bStroke = Instance.new("UIStroke", button)
        bStroke.Color = Theme.Border
        trackObject(button)

        trackConnection(button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 37)}):Play()
            TweenService:Create(bStroke, TweenInfo.new(0.2), {Color = Theme.AccentGlow}):Play()
        end))
        trackConnection(button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SecondaryBg}):Play()
            TweenService:Create(bStroke, TweenInfo.new(0.2), {Color = Theme.Border}):Play()
        end))
        trackConnection(button.MouseButton1Click:Connect(function()
            local bounceDown = TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {Size = UDim2.new(1, -12, 0, 36)})
            local bounceUp = TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Back), {Size = UDim2.new(1, -4, 0, 40)})
            bounceDown:Play()
            bounceDown.Completed:Connect(function() bounceUp:Play() end)
            if callback then callback() end
        end))

        return button
    end

    function module.CreatePlayerList(parentFrame)
        local selectedPlayer = "---"
        local tracking = false

        local container = Instance.new("Frame", parentFrame)
        container.Size = UDim2.new(1, -4, 0, 46)
        container.BackgroundColor3 = Theme.Background
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
        Instance.new("UIStroke", container).Color = Theme.Border
        trackObject(container)

        local dropdownButton = Instance.new("TextButton", container)
        dropdownButton.Size = UDim2.new(1, -120, 0, 32)
        dropdownButton.Position = UDim2.new(0, 10, 0.5, -16)
        dropdownButton.Text = "  Игрок: " .. selectedPlayer
        dropdownButton.TextColor3 = Theme.TextMain
        dropdownButton.Font = Theme.FontMain
        dropdownButton.TextSize = 13
        dropdownButton.BackgroundColor3 = Theme.SecondaryBg
        dropdownButton.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", dropdownButton).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", dropdownButton).Color = Theme.Border

        local trackBtn = Instance.new("TextButton", container)
        trackBtn.Size = UDim2.new(0, 80, 0, 32)
        trackBtn.Position = UDim2.new(1, -90, 0.5, -16)
        trackBtn.Text = "Следить"
        trackBtn.Font = Theme.FontBold
        trackBtn.TextSize = 12
        trackBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
        trackBtn.TextColor3 = Theme.TextMuted
        Instance.new("UICorner", trackBtn).CornerRadius = UDim.new(0, 6)
        local tStroke = Instance.new("UIStroke", trackBtn)
        tStroke.Color = Theme.Border

        local dropdownFrame = Instance.new("ScrollingFrame", container)
        dropdownFrame.Size = UDim2.new(1, -120, 0, 0)
        dropdownFrame.Position = UDim2.new(0, 10, 1, 4)
        dropdownFrame.BackgroundColor3 = Theme.SecondaryBg
        dropdownFrame.Visible = false
        dropdownFrame.ZIndex = 2000
        dropdownFrame.ScrollBarThickness = 2
        Instance.new("UICorner", dropdownFrame).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", dropdownFrame).Color = Theme.AccentGlow
        trackObject(dropdownFrame)

        local dropdownLayout = Instance.new("UIListLayout", dropdownFrame)
        dropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local function refreshPlayers()
            for _, c in ipairs(dropdownFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player then
                    local btn = Instance.new("TextButton", dropdownFrame)
                    btn.Size = UDim2.new(1, 0, 0, 30)
                    btn.Text = "  " .. plr.Name
                    btn.BackgroundColor3 = Theme.SecondaryBg
                    btn.TextColor3 = Theme.TextMain
                    btn.Font = Theme.FontMain
                    btn.TextSize = 12
                    btn.TextXAlignment = Enum.TextXAlignment.Left
                    btn.ZIndex = 2001
                    
                    trackConnection(btn.MouseButton1Click:Connect(function()
                        selectedPlayer = plr.Name
                        dropdownButton.Text = "  Игрок: " .. selectedPlayer
                        dropdownFrame.Visible = false
                    end))
                end
            end
        end

        trackConnection(dropdownButton.MouseButton1Click:Connect(function()
            refreshPlayers()
            dropdownFrame.Visible = not dropdownFrame.Visible
            local targetHeight = math.clamp(dropdownLayout.AbsoluteContentSize.Y, 0, 120)
            dropdownFrame.Size = UDim2.new(1, -120, 0, targetHeight)
        end))

        trackConnection(trackBtn.MouseButton1Click:Connect(function()
            tracking = not tracking
            if tracking then
                TweenService:Create(trackBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Success, TextColor3 = Theme.TextMain}):Play()
                tStroke.Color = Theme.Success
            else
                TweenService:Create(trackBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(24, 24, 27), TextColor3 = Theme.TextMuted}):Play()
                tStroke.Color = Theme.Border
            end
        end))

        trackConnection(RunService.RenderStepped:Connect(function()
            if tracking and selectedPlayer ~= "---" then
                local target = Players:FindFirstChild(selectedPlayer)
                if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
                end
            end
        end))

        return container
    end

    local function openFirstCategory()
        if #categories > 0 then
            categories[1].holder.Visible = true
            categories[1].bar.Visible = true
            categories[1].button.BackgroundColor3 = Theme.SecondaryBg
            categories[1].button.TextColor3 = Theme.TextMain
            contentScroll.CanvasSize = UDim2.new(0, 0, 0, categories[1].holder:FindFirstChildWhichIsA("UIListLayout").AbsoluteContentSize.Y)
        end
    end

    return {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        MinimizedFrame = minimizedFrame,
        CategoryFrame = categoryFrame,
        ContentFrame = contentScroll,
        CreateToggle = module.CreateToggle,
        CreateCategory = module.CreateCategory,
        CreatePlayerList = module.CreatePlayerList,
        CreateButton = module.CreateButton,
        Close = function() disconnectAll() destroyAll() end,
        SetMinimizedImage = setMinimizedImage,
        OpenFirstCategory = openFirstCategory,
        Categories = categories,
        Hide = function() toggleMinimize(true) end,
        Show = function() toggleMinimize(false) end
    }
end

return module
