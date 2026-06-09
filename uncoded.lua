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

-- v22 (Added Custom Input, Sub-Buttons, and Full RGB Color Picker for subConfig) --
local module = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local connections = {}
local trackedObjects = {}
local onCloseCallback = nil

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
    for i = #connections, 1, -1 do
        local conn = connections[i]
        if conn and conn.Connected then conn:Disconnect() end
        connections[i] = nil
    end
    if onCloseCallback then
        local success, err = pcall(onCloseCallback)
        if not success then warn("Error executing OnClose callback: " .. tostring(err)) end
        onCloseCallback = nil
    end
end

local function destroyAll()
    for i = #trackedObjects, 1, -1 do
        local obj = trackedObjects[i]
        if obj and obj.Parent then obj:Destroy() end
        trackedObjects[i] = nil
    end
end

local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    trackConnection(frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            local endConn
            endConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then 
                    dragging = false 
                    if endConn.Connected then endConn:Disconnect() end
                end
            end)
            trackConnection(endConn)
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

local function createColorPickerUI(screenGui, defaultColor, callback)
    local pickerFrame = Instance.new("Frame", screenGui)
    pickerFrame.Size = UDim2.new(0, 240, 0, 180)
    pickerFrame.Position = UDim2.new(0.5, -120, 0.5, -90)
    pickerFrame.BackgroundColor3 = Theme.Background
    pickerFrame.ZIndex = 5000
    Instance.new("UICorner", pickerFrame).CornerRadius = UDim.new(0, 10)
    local pStroke = Instance.new("UIStroke", pickerFrame)
    pStroke.Color = Theme.AccentGlow
    pStroke.Thickness = 1
    makeDraggable(pickerFrame)
    trackObject(pickerFrame)

    local title = Instance.new("TextLabel", pickerFrame)
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "RGB Color Picker"
    title.TextColor3 = Theme.TextMain
    title.Font = Theme.FontBold
    title.TextSize = 12
    title.BackgroundTransparency = 1
    title.ZIndex = 5001

    local preview = Instance.new("Frame", pickerFrame)
    preview.Size = UDim2.new(0, 40, 0, 40)
    preview.Position = UDim2.new(1, -55, 0, 45)
    preview.BackgroundColor3 = defaultColor
    preview.ZIndex = 5001
    Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", preview).Color = Theme.Border

    local sliders = {}
    local channels = {"R", "G", "B"}
    local startColor = {defaultColor.R * 255, defaultColor.G * 255, defaultColor.B * 255}

    local function updateColor()
        local r = tonumber(sliders["R"].Text) or 0
        local g = tonumber(sliders["G"].Text) or 0
        local b = tonumber(sliders["B"].Text) or 0
        local newColor = Color3.fromRGB(r, g, b)
        preview.BackgroundColor3 = newColor
        if callback then callback(newColor) end
    end

    for i, ch in ipairs(channels) do
        local row = Instance.new("Frame", pickerFrame)
        row.Size = UDim2.new(1, -75, 0, 30)
        row.Position = UDim2.new(0, 15, 0, 15 + (i * 32))
        row.BackgroundTransparency = 1
        row.ZIndex = 5001

        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(0, 15, 1, 0)
        lbl.Text = ch
        lbl.TextColor3 = Theme.TextMuted
        lbl.Font = Theme.FontBold
        lbl.TextSize = 12
        lbl.BackgroundTransparency = 1
        lbl.ZIndex = 5001

        local box = Instance.new("TextBox", row)
        box.Size = UDim2.new(1, -20, 1, 0)
        box.Position = UDim2.new(0, 20, 0, 0)
        box.BackgroundColor3 = Theme.SecondaryBg
        box.Text = tostring(math.round(startColor[i]))
        box.TextColor3 = Theme.TextMain
        box.Font = Theme.FontMain
        box.TextSize = 12
        box.ClearTextOnFocus = false
        box.ZIndex = 5001
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", box).Color = Theme.Border

        sliders[ch] = box

        trackConnection(box:GetPropertyChangedSignal("Text"):Connect(function()
            local val = tonumber(box.Text)
            if val then
                local clamped = math.clamp(val, 0, 255)
                if tostring(clamped) ~= box.Text then box.Text = tostring(clamped) end
                updateColor()
            end
        end))
    end

    local saveBtn = Instance.new("TextButton", pickerFrame)
    saveBtn.Size = UDim2.new(0, 80, 0, 28)
    saveBtn.Position = UDim2.new(0, 40, 1, -38)
    saveBtn.Text = "Apply"
    saveBtn.Font = Theme.FontBold
    saveBtn.TextSize = 12
    saveBtn.BackgroundColor3 = Theme.Success
    saveBtn.TextColor3 = Theme.TextMain
    saveBtn.ZIndex = 5001
    Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 6)

    local closeBtn = Instance.new("TextButton", pickerFrame)
    closeBtn.Size = UDim2.new(0, 80, 0, 28)
    closeBtn.Position = UDim2.new(1, -120, 1, -38)
    closeBtn.Text = "Close"
    closeBtn.Font = Theme.FontBold
    closeBtn.TextSize = 12
    closeBtn.BackgroundColor3 = Theme.SecondaryBg
    closeBtn.TextColor3 = Theme.TextMuted
    closeBtn.ZIndex = 5001
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", closeBtn).Color = Theme.Border

    trackConnection(saveBtn.MouseButton1Click:Connect(function()
        updateColor()
        pickerFrame:Destroy()
    end))

    trackConnection(closeBtn.MouseButton1Click:Connect(function()
        pickerFrame:Destroy()
    end))
end

local function applyFeatureExtensions(container, description, subConfig, descStyle, screenGui)
    local layout = Instance.new("UIListLayout", container)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)

    local padding = Instance.new("UIPadding", container)
    padding.PaddingTop = UDim.new(0, 0)
    padding.PaddingBottom = UDim.new(0, 0)
    padding.PaddingLeft = UDim.new(0, 0)
    padding.PaddingRight = UDim.new(0, 0)

    if (description and description ~= "") or (subConfig and #subConfig > 0) then
        container.AutomaticSize = Enum.AutomaticSize.Y
        padding.PaddingBottom = UDim.new(0, 10)
    end

    if subConfig and #subConfig > 0 then
        local subFrame = Instance.new("Frame", container)
        subFrame.Size = UDim2.new(1, 0, 0, 0)
        subFrame.BackgroundTransparency = 1
        subFrame.AutomaticSize = Enum.AutomaticSize.Y
        subFrame.LayoutOrder = 2

        local subLayout = Instance.new("UIListLayout", subFrame)
        subLayout.SortOrder = Enum.SortOrder.LayoutOrder
        subLayout.Padding = UDim.new(0, 6)
        
        local subPadding = Instance.new("UIPadding", subFrame)
        subPadding.PaddingLeft = UDim.new(0, 14)
        subPadding.PaddingRight = UDim.new(0, 14)

        for _, item in ipairs(subConfig) do
            if item.Type == "Checkbox" then
                local chk = Instance.new("TextButton", subFrame)
                chk.Size = UDim2.new(1, 0, 0, 24)
                chk.BackgroundTransparency = 1
                chk.Text = ""
                chk.LayoutOrder = item.LayoutOrder or 1

                local box = Instance.new("Frame", chk)
                box.Size = UDim2.new(0, 16, 0, 16)
                box.Position = UDim2.new(0, 0, 0.5, -8)
                box.BackgroundColor3 = Theme.SecondaryBg
                Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
                Instance.new("UIStroke", box).Color = Theme.Border

                local checkMark = Instance.new("TextLabel", box)
                checkMark.Size = UDim2.new(1, 0, 1, 0)
                checkMark.Text = "✓"
                checkMark.TextColor3 = Theme.TextMain
                checkMark.Font = Theme.FontBold
                checkMark.TextSize = 12
                checkMark.BackgroundTransparency = 1
                checkMark.Visible = item.State or false

                local lbl = Instance.new("TextLabel", chk)
                lbl.Size = UDim2.new(1, -24, 1, 0)
                lbl.Position = UDim2.new(0, 24, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = item.Text or "Option"
                lbl.TextColor3 = Theme.TextMuted
                lbl.Font = Theme.FontMain
                lbl.TextSize = 12
                lbl.TextXAlignment = Enum.TextXAlignment.Left

                local active = item.State or false
                trackConnection(chk.MouseButton1Click:Connect(function()
                    active = not active
                    checkMark.Visible = active
                    TweenService:Create(lbl, TweenInfo.new(0.2), {TextColor3 = active and Theme.TextMain or Theme.TextMuted}):Play()
                    if item.Callback then item.Callback(active) end
                end))

            elseif item.Type == "Color" then
                local colFrame = Instance.new("Frame", subFrame)
                colFrame.Size = UDim2.new(1, 0, 0, 26)
                colFrame.BackgroundTransparency = 1
                colFrame.LayoutOrder = item.LayoutOrder or 1

                local lbl = Instance.new("TextLabel", colFrame)
                lbl.Size = UDim2.new(0, 100, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = item.Text or "Color"
                lbl.TextColor3 = Theme.TextMuted
                lbl.Font = Theme.FontMain
                lbl.TextSize = 12
                lbl.TextXAlignment = Enum.TextXAlignment.Left

                local activeColor = item.DefaultColor or Color3.fromRGB(168, 85, 247)

                local cBtn = Instance.new("TextButton", colFrame)
                cBtn.Size = UDim2.new(0, 36, 0, 18)
                cBtn.Position = UDim2.new(1, -36, 0.5, -9)
                cBtn.BackgroundColor3 = activeColor
                cBtn.Text = ""
                Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 4)
                local cStroke = Instance.new("UIStroke", cBtn)
                cStroke.Color = Theme.Border

                trackConnection(cBtn.MouseButton1Click:Connect(function()
                    createColorPickerUI(screenGui, activeColor, function(selectedColor)
                        activeColor = selectedColor
                        cBtn.BackgroundColor3 = selectedColor
                        if item.Callback then item.Callback(selectedColor) end
                    end)
                end))

            elseif item.Type == "Input" then
                local inputFrame = Instance.new("Frame", subFrame)
                inputFrame.Size = UDim2.new(1, 0, 0, 28)
                inputFrame.BackgroundTransparency = 1
                inputFrame.LayoutOrder = item.LayoutOrder or 1

                local lbl = Instance.new("TextLabel", inputFrame)
                lbl.Size = UDim2.new(0, 100, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = item.Text or "Input"
                lbl.TextColor3 = Theme.TextMuted
                lbl.Font = Theme.FontMain
                lbl.TextSize = 12
                lbl.TextXAlignment = Enum.TextXAlignment.Left

                local box = Instance.new("TextBox", inputFrame)
                box.Size = UDim2.new(1, -105, 1, 0)
                box.Position = UDim2.new(0, 105, 0, 0)
                box.BackgroundColor3 = Theme.SecondaryBg
                box.Text = item.DefaultText or ""
                box.PlaceholderText = item.Placeholder or "Type here..."
                box.PlaceholderColor3 = Color3.fromRGB(100, 100, 105)
                box.TextColor3 = Theme.TextMain
                box.Font = Theme.FontMain
                box.TextSize = 12
                box.ClearTextOnFocus = false
                Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
                local bStroke = Instance.new("UIStroke", box)
                bStroke.Color = Theme.Border

                trackConnection(box.FocusLost:Connect(function(enterPressed)
                    if item.Callback then item.Callback(box.Text, enterPressed) end
                end))

            elseif item.Type == "Button" then
                local btnFrame = Instance.new("Frame", subFrame)
                btnFrame.Size = UDim2.new(1, 0, 0, 28)
                btnFrame.BackgroundTransparency = 1
                btnFrame.LayoutOrder = item.LayoutOrder or 1

                local btn = Instance.new("TextButton", btnFrame)
                btn.Size = UDim2.new(1, 0, 1, 0)
                btn.BackgroundColor3 = Theme.SecondaryBg
                btn.Text = item.Text or "Button"
                btn.TextColor3 = Theme.TextMain
                btn.Font = Theme.FontBold
                btn.TextSize = 11
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
                local bStroke = Instance.new("UIStroke", btn)
                bStroke.Color = Theme.Border

                trackConnection(btn.MouseEnter:Connect(function()
                    TweenService:Create(bStroke, TweenInfo.new(0.2), {Color = Theme.AccentGlow}):Play()
                end))
                trackConnection(btn.MouseLeave:Connect(function()
                    TweenService:Create(bStroke, TweenInfo.new(0.2), {Color = Theme.Border}):Play()
                end))
                trackConnection(btn.MouseButton1Click:Connect(function()
                    if item.Callback then item.Callback() end
                end))
            end
        end
    end

    if description and description ~= "" then
        descStyle = descStyle or {}
        local dLabel = Instance.new("TextLabel", container)
        dLabel.Size = UDim2.new(1, -28, 0, 0)
        dLabel.Position = UDim2.new(0, 14, 0, 0)
        dLabel.BackgroundTransparency = 1
        dLabel.Text = description
        dLabel.TextColor3 = descStyle.Color or Color3.fromRGB(255, 255, 255)
        dLabel.TextTransparency = descStyle.Transparency or 0
        dLabel.Font = descStyle.Font or Theme.FontMain
        dLabel.TextSize = descStyle.TextSize or 11
        dLabel.TextXAlignment = Enum.TextXAlignment.Left
        dLabel.TextWrapped = true
        dLabel.AutomaticSize = Enum.AutomaticSize.Y
        dLabel.LayoutOrder = 3

        local descPadding = Instance.new("UIPadding", dLabel)
        descPadding.PaddingLeft = UDim.new(0, 14)
        descPadding.PaddingRight = UDim.new(0, 14)
    end
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
    mainFrame.ClipsDescendants = true
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
    local scaleButton = createControlBtn("~", 30, Theme.AccentGlow)
    local closeButton = createControlBtn("×", 60, Theme.Danger)

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
    confirmText.Text = "Are you sure?"
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

    local yesBtn = createModalBtn("Yes", 20, Theme.Danger, Theme.TextMain)
    local noBtn = createModalBtn("No", 170, Color3.fromRGB(39, 39, 42), Theme.TextMain)

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
            local t = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
            t:Play()
            local c
            c = t.Completed:Connect(function()
                c:Disconnect()
                mainFrame.Visible = false
                minimizedFrame.Visible = true
                minimizedFrame.Size = UDim2.new(0, 0, 0, 0)
                TweenService:Create(minimizedFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Size = UDim2.new(0, 48, 0, 48)}):Play()
            end)
        else
            local t = TweenService:Create(minimizedFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 0, 0, 0)})
            t:Play()
            local c
            c = t.Completed:Connect(function()
                c:Disconnect()
                minimizedFrame.Visible = false
                mainFrame.Visible = true
                TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Size = isScaledDown and smallSize or normalSize, BackgroundTransparency = 0}):Play()
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
        button.Text = "    " .. name
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

        local cSig = layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            holder.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
            if holder.Visible then contentScroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y) end
        end)
        trackConnection(cSig)

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

    function module.CreateToggle(text, parent, callback, description, subConfig, descStyle)
        local container = Instance.new("Frame", parent)
        container.Size = UDim2.new(1, -4, 0, 42)
        container.BackgroundColor3 = Theme.Background
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
        Instance.new("UIStroke", container).Color = Theme.Border
        trackObject(container)

        local topRow = Instance.new("Frame", container)
        topRow.Size = UDim2.new(1, 0, 0, 42)
        topRow.BackgroundTransparency = 1
        topRow.LayoutOrder = 1

        local label = Instance.new("TextLabel", topRow)
        label.Size = UDim2.new(1, -60, 1, 0)
        label.Position = UDim2.new(0, 14, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.Font = Theme.FontMain
        label.TextSize = 13
        label.TextColor3 = Theme.TextMain
        label.TextXAlignment = Enum.TextXAlignment.Left

        local switch = Instance.new("Frame", topRow)
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

        local touchPos
        trackConnection(topRow.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                touchPos = input.Position
            end
        end))

        trackConnection(topRow.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if touchPos then
                    local delta = (input.Position - touchPos).Magnitude
                    touchPos = nil
                    if delta < 8 then
                        enabled = not enabled
                        updateVisual(true)
                        if callback then callback(enabled) end
                    end
                end
            end
        end))

        updateVisual(false)
        applyFeatureExtensions(container, description, subConfig, descStyle, screenGui)
        return container
    end

    function module.CreateButton(text, parent, callback, description, subConfig, descStyle)
        local container = Instance.new("Frame", parent)
        container.Size = UDim2.new(1, -4, 0, 40)
        container.BackgroundColor3 = Theme.SecondaryBg
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
        local bStroke = Instance.new("UIStroke", container)
        bStroke.Color = Theme.Border
        trackObject(container)

        local button = Instance.new("TextButton", container)
        button.Size = UDim2.new(1, 0, 0, 40)
        button.Text = text
        button.BackgroundTransparency = 1
        button.TextColor3 = Theme.TextMain
        button.Font = Theme.FontBold
        button.TextSize = 13
        button.AutoButtonColor = false
        button.LayoutOrder = 1

        trackConnection(button.MouseEnter:Connect(function()
            TweenService:Create(container, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 37)}):Play()
            TweenService:Create(bStroke, TweenInfo.new(0.2), {Color = Theme.AccentGlow}):Play()
        end))
        trackConnection(button.MouseLeave:Connect(function()
            TweenService:Create(container, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SecondaryBg}):Play()
            TweenService:Create(bStroke, TweenInfo.new(0.2), {Color = Theme.Border}):Play()
        end))
        trackConnection(button.MouseButton1Click:Connect(function()
            local bounceDown = TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, 36)})
            local bounceUp = TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Back), {Size = UDim2.new(1, 0, 0, 40)})
            bounceDown:Play()
            local bConn
            bConn = bounceDown.Completed:Connect(function() 
                bConn:Disconnect()
                bounceUp:Play() 
            end)
            if callback then callback() end
        end))

        applyFeatureExtensions(container, description, subConfig, descStyle, screenGui)
        return container
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

    local uiData = {
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
        Show = function() toggleMinimize(false) end,
        OnClose = function(callback) onCloseCallback = callback end
    }
    return uiData
end

return module
