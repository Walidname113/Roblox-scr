-- v29 (Refactor: instance isolation, CreateLabel, CreateSeparator, CreateColorPicker top-level,
--       CreateMultiDropdown, SetValue/GetValue on all widgets, dropdown overlay fix,
--       slider AbsoluteSize defer fix, auto LayoutOrder, backward compat) --

local module = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local Theme = {
    Background    = Color3.fromRGB(15, 15, 18),
    SecondaryBg   = Color3.fromRGB(22, 22, 26),
    AccentGlow    = Color3.fromRGB(168, 85, 247),
    TextMain      = Color3.fromRGB(243, 244, 246),
    TextMuted     = Color3.fromRGB(156, 163, 175),
    Border        = Color3.fromRGB(39, 39, 42),
    Success       = Color3.fromRGB(34, 197, 94),
    Danger        = Color3.fromRGB(239, 68, 68),
    FontMain      = Enum.Font.Gotham,
    FontBold      = Enum.Font.GothamBold,
}

-- ─── per-instance state ───────────────────────────────────────────────────────
local function newInstanceState()
    return {
        connections   = {},
        trackedObjects = {},
        onCloseCallback = nil,
        activePicker  = nil,
        autoOrder     = 0,
    }
end

local function trackConnection(state, conn)
    table.insert(state.connections, conn)
    return conn
end

local function trackObject(state, obj)
    table.insert(state.trackedObjects, obj)
    return obj
end

local function nextOrder(state)
    state.autoOrder = state.autoOrder + 1
    return state.autoOrder
end

local function disconnectAll(state)
    for i = #state.connections, 1, -1 do
        local c = state.connections[i]
        if c and c.Connected then c:Disconnect() end
        state.connections[i] = nil
    end
    if state.onCloseCallback then
        pcall(state.onCloseCallback)
        state.onCloseCallback = nil
    end
end

local function destroyAll(state)
    for i = #state.trackedObjects, 1, -1 do
        local o = state.trackedObjects[i]
        if o and o.Parent then o:Destroy() end
        state.trackedObjects[i] = nil
    end
end

-- ─── draggable ────────────────────────────────────────────────────────────────
local function makeDraggable(state, frame, handle)
    local dragHandle = handle or frame
    local dragging, dragInput, dragStart, startPos

    trackConnection(state, dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
            local ec
            ec = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if ec.Connected then ec:Disconnect() end
                end
            end)
            trackConnection(state, ec)
        end
    end))

    trackConnection(state, frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    trackConnection(state, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            TweenService:Create(frame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            }):Play()
        end
    end))
end

-- ─── color picker (shared impl, per-instance activePicker) ───────────────────
local function createColorPickerUI(state, screenGui, defaultColor, callback)
    if state.activePicker then return end

    local pickerFrame = Instance.new("Frame", screenGui)
    pickerFrame.Size         = UDim2.new(0, 340, 0, 350)
    pickerFrame.Position     = UDim2.new(0.5, -170, 0.5, -175)
    pickerFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    pickerFrame.ZIndex       = 5000
    pickerFrame.Active       = true
    Instance.new("UICorner", pickerFrame).CornerRadius = UDim.new(0, 12)
    local pStroke = Instance.new("UIStroke", pickerFrame)
    pStroke.Color     = Theme.Border
    pStroke.Thickness = 1
    trackObject(state, pickerFrame)
    state.activePicker = pickerFrame

    local dragHandle = Instance.new("Frame", pickerFrame)
    dragHandle.Size = UDim2.new(1, 0, 0, 40)
    dragHandle.BackgroundTransparency = 1
    dragHandle.ZIndex = 5001
    makeDraggable(state, pickerFrame, dragHandle)

    local title = Instance.new("TextLabel", dragHandle)
    title.Size             = UDim2.new(1, -40, 1, 0)
    title.Position         = UDim2.new(0, 16, 0, 0)
    title.Text             = "Color Palette"
    title.TextColor3       = Theme.TextMain
    title.Font             = Theme.FontBold
    title.TextSize         = 15
    title.TextXAlignment   = Enum.TextXAlignment.Left
    title.BackgroundTransparency = 1
    title.ZIndex           = 5002

    local xBtn = Instance.new("TextButton", pickerFrame)
    xBtn.Size     = UDim2.new(0, 24, 0, 24)
    xBtn.Position = UDim2.new(1, -36, 0, 8)
    xBtn.Text     = "×"
    xBtn.Font     = Theme.FontBold
    xBtn.TextSize = 18
    xBtn.TextColor3 = Theme.TextMuted
    xBtn.BackgroundTransparency = 1
    xBtn.ZIndex   = 5005

    local topDisplay = Instance.new("Frame", pickerFrame)
    topDisplay.Size = UDim2.new(1, -32, 0, 130)
    topDisplay.Position = UDim2.new(0, 16, 0, 45)
    topDisplay.BackgroundTransparency = 1
    topDisplay.ZIndex = 5001

    local leftColorShow = Instance.new("Frame", topDisplay)
    leftColorShow.Size = UDim2.new(0.4, 0, 1, 0)
    leftColorShow.BackgroundColor3 = defaultColor
    leftColorShow.ZIndex = 5001
    Instance.new("UICorner", leftColorShow).CornerRadius = UDim.new(0, 6)

    local rightSatVal = Instance.new("ImageLabel", topDisplay)
    rightSatVal.Size     = UDim2.new(0.6, -8, 1, 0)
    rightSatVal.Position = UDim2.new(0.4, 8, 0, 0)
    rightSatVal.Image    = "rbxassetid://4155801252"
    rightSatVal.ZIndex   = 5001
    rightSatVal.Active   = true
    Instance.new("UICorner", rightSatVal).CornerRadius = UDim.new(0, 6)

    local satValSel = Instance.new("Frame", rightSatVal)
    satValSel.Size = UDim2.new(0, 14, 0, 14)
    satValSel.AnchorPoint = Vector2.new(0.5, 0.5)
    satValSel.BackgroundTransparency = 1
    satValSel.ZIndex = 5002
    local sRing = Instance.new("UIStroke", satValSel)
    sRing.Color     = Color3.new(1, 1, 1)
    sRing.Thickness = 2
    Instance.new("UICorner", satValSel).CornerRadius = UDim.new(1, 0)

    local hueSlider = Instance.new("Frame", pickerFrame)
    hueSlider.Size     = UDim2.new(1, -32, 0, 16)
    hueSlider.Position = UDim2.new(0, 16, 0, 190)
    hueSlider.BackgroundColor3 = Color3.new(1, 1, 1)
    hueSlider.ZIndex   = 5001
    hueSlider.Active   = true
    Instance.new("UICorner", hueSlider).CornerRadius = UDim.new(1, 0)
    local hueGrad = Instance.new("UIGradient", hueSlider)
    hueGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0/6, Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(6/6, Color3.fromRGB(255,0,0)),
    })

    local hueKnob = Instance.new("Frame", hueSlider)
    hueKnob.Size     = UDim2.new(0, 18, 0, 18)
    hueKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    hueKnob.Position = UDim2.new(0, 0, 0.5, 0)
    hueKnob.BackgroundColor3 = Color3.new(1, 1, 1)
    hueKnob.ZIndex   = 5002
    Instance.new("UICorner", hueKnob).CornerRadius = UDim.new(1, 0)
    local hRing = Instance.new("UIStroke", hueKnob)
    hRing.Color     = Color3.new(0, 0, 0)
    hRing.Thickness = 1.5

    local rgbContainer = Instance.new("Frame", pickerFrame)
    rgbContainer.Size     = UDim2.new(1, -32, 0, 45)
    rgbContainer.Position = UDim2.new(0, 16, 0, 222)
    rgbContainer.BackgroundColor3 = Theme.SecondaryBg
    rgbContainer.ZIndex   = 5001
    rgbContainer.Active   = true
    Instance.new("UICorner", rgbContainer).CornerRadius = UDim.new(0, 8)
    local rStroke = Instance.new("UIStroke", rgbContainer)
    rStroke.Color = Theme.Border

    local rgbLabel = Instance.new("TextLabel", rgbContainer)
    rgbLabel.Size     = UDim2.new(0, 45, 1, 0)
    rgbLabel.Position = UDim2.new(0, 12, 0, 0)
    rgbLabel.Text     = "RGB"
    rgbLabel.Font     = Theme.FontBold
    rgbLabel.TextSize = 12
    rgbLabel.TextColor3 = Theme.TextMuted
    rgbLabel.TextXAlignment = Enum.TextXAlignment.Left
    rgbLabel.BackgroundTransparency = 1
    rgbLabel.ZIndex   = 5002

    local rgbInput = Instance.new("TextBox", rgbContainer)
    rgbInput.Size     = UDim2.new(1, -65, 1, 0)
    rgbInput.Position = UDim2.new(0, 55, 0, 0)
    rgbInput.TextXAlignment = Enum.TextXAlignment.Left
    rgbInput.Font     = Theme.FontMain
    rgbInput.TextSize = 13
    rgbInput.TextColor3 = Theme.TextMain
    rgbInput.BackgroundTransparency = 1
    rgbInput.ClearTextOnFocus = false
    rgbInput.ZIndex   = 5002

    local currentH, currentS, currentV = defaultColor:ToHSV()

    local function updatePicker()
        rightSatVal.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
        local fc = Color3.fromHSV(currentH, currentS, currentV)
        leftColorShow.BackgroundColor3 = fc
        hueKnob.Position  = UDim2.new(currentH, 0, 0.5, 0)
        satValSel.Position = UDim2.new(currentS, 0, 1 - currentV, 0)
        if not rgbInput:IsFocused() then
            rgbInput.Text = string.format("%d, %d, %d",
                math.round(fc.R*255), math.round(fc.G*255), math.round(fc.B*255))
        end
    end

    local function parseRGBText(text)
        local r,g,b = text:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
        if r and g and b then
            local col = Color3.fromRGB(
                math.clamp(tonumber(r),0,255),
                math.clamp(tonumber(g),0,255),
                math.clamp(tonumber(b),0,255))
            currentH,currentS,currentV = col:ToHSV()
            updatePicker()
        end
    end
    trackConnection(state, rgbInput.FocusLost:Connect(function() parseRGBText(rgbInput.Text) end))

    local isSettingHue = false
    local function processHue(input)
        currentH = math.clamp((input.Position.X - hueSlider.AbsolutePosition.X) / hueSlider.AbsoluteSize.X, 0, 1)
        updatePicker()
    end
    trackConnection(state, hueSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            isSettingHue = true; processHue(input)
        end
    end))
    trackConnection(state, UserInputService.InputChanged:Connect(function(input)
        if isSettingHue and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            processHue(input)
        end
    end))

    local isSettingSV = false
    local function processSV(input)
        currentS = math.clamp((input.Position.X - rightSatVal.AbsolutePosition.X) / rightSatVal.AbsoluteSize.X, 0, 1)
        currentV = 1 - math.clamp((input.Position.Y - rightSatVal.AbsolutePosition.Y) / rightSatVal.AbsoluteSize.Y, 0, 1)
        updatePicker()
    end
    trackConnection(state, rightSatVal.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            isSettingSV = true; processSV(input)
        end
    end))
    trackConnection(state, UserInputService.InputChanged:Connect(function(input)
        if isSettingSV and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            processSV(input)
        end
    end))
    trackConnection(state, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            isSettingHue = false; isSettingSV = false
        end
    end))

    local applyBtn = Instance.new("TextButton", pickerFrame)
    applyBtn.Size     = UDim2.new(0, 140, 0, 36)
    applyBtn.Position = UDim2.new(0, 16, 1, -52)
    applyBtn.Text     = "Apply"
    applyBtn.Font     = Theme.FontBold
    applyBtn.TextSize = 13
    applyBtn.BackgroundColor3 = Theme.Success
    applyBtn.TextColor3 = Theme.TextMain
    applyBtn.ZIndex   = 5001
    Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0, 6)

    local cancelBtn = Instance.new("TextButton", pickerFrame)
    cancelBtn.Size     = UDim2.new(0, 140, 0, 36)
    cancelBtn.Position = UDim2.new(1, -156, 1, -52)
    cancelBtn.Text     = "Cancel"
    cancelBtn.Font     = Theme.FontBold
    cancelBtn.TextSize = 13
    cancelBtn.BackgroundColor3 = Theme.SecondaryBg
    cancelBtn.TextColor3 = Theme.TextMuted
    cancelBtn.ZIndex   = 5001
    Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 6)
    local cStrk = Instance.new("UIStroke", cancelBtn)
    cStrk.Color = Theme.Border

    local function closeWithAnimation(save)
        local oSize = pickerFrame.Size
        local oPos  = pickerFrame.Position
        local tSize = UDim2.new(0, oSize.X.Offset*0.8, 0, oSize.Y.Offset*0.8)
        local tPos  = UDim2.new(oPos.X.Scale, oPos.X.Offset + oSize.X.Offset*0.1,
                                 oPos.Y.Scale, oPos.Y.Offset + oSize.Y.Offset*0.1)
        for _, d in ipairs(pickerFrame:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                TweenService:Create(d, TweenInfo.new(0.12), {TextTransparency=1}):Play()
            elseif d:IsA("Frame") then
                TweenService:Create(d, TweenInfo.new(0.12), {BackgroundTransparency=1}):Play()
            elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
                TweenService:Create(d, TweenInfo.new(0.12), {BackgroundTransparency=1,ImageTransparency=1}):Play()
            elseif d:IsA("UIStroke") then
                TweenService:Create(d, TweenInfo.new(0.12), {Transparency=1}):Play()
            end
        end
        local t = TweenService:Create(pickerFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Size=tSize, Position=tPos, BackgroundTransparency=1})
        t:Play()
        local ec
        ec = t.Completed:Connect(function()
            ec:Disconnect()
            if save and callback then callback(Color3.fromHSV(currentH, currentS, currentV)) end
            if state.activePicker == pickerFrame then state.activePicker = nil end
            pickerFrame:Destroy()
        end)
    end

    trackConnection(state, applyBtn.MouseButton1Click:Connect(function() closeWithAnimation(true) end))
    trackConnection(state, cancelBtn.MouseButton1Click:Connect(function() closeWithAnimation(false) end))
    trackConnection(state, xBtn.MouseButton1Click:Connect(function() closeWithAnimation(false) end))

    pickerFrame.Size = UDim2.new(0, 272, 0, 280)
    pickerFrame.Position = UDim2.new(0.5, -136, 0.5, -140)
    pickerFrame.BackgroundTransparency = 1
    TweenService:Create(pickerFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 340, 0, 350),
        Position = UDim2.new(0.5, -170, 0.5, -175),
        BackgroundTransparency = 0,
    }):Play()
    updatePicker()
end

-- ─── dropdown overlay (fixes ClipsDescendants clipping) ──────────────────────
-- Opens a floating ScrollingFrame directly on screenGui so nothing clips it.
local function openDropdownOverlay(state, screenGui, anchorFrame, options, onSelect)
    -- close existing overlay
    local existing = screenGui:FindFirstChild("__DropOverlay")
    if existing then existing:Destroy() end

    local overlay = Instance.new("Frame", screenGui)
    overlay.Name = "__DropOverlay"
    overlay.BackgroundTransparency = 1
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.ZIndex = 3000

    -- click-away dismiss
    local dimBtn = Instance.new("TextButton", overlay)
    dimBtn.Size = UDim2.new(1, 0, 1, 0)
    dimBtn.BackgroundTransparency = 1
    dimBtn.Text = ""
    dimBtn.ZIndex = 3000

    local abs = anchorFrame.AbsolutePosition
    local absS = anchorFrame.AbsoluteSize

    local ROW_H = 30
    local maxRows = math.min(#options, 5)
    local dropH = maxRows * ROW_H

    local scroll = Instance.new("ScrollingFrame", overlay)
    scroll.Size     = UDim2.new(0, absS.X, 0, dropH)
    scroll.Position = UDim2.new(0, abs.X, 0, abs.Y + absS.Y + 4)
    scroll.BackgroundColor3 = Theme.SecondaryBg
    scroll.ScrollBarThickness = 2
    scroll.CanvasSize = UDim2.new(0, 0, 0, #options * ROW_H)
    scroll.ZIndex = 3001
    Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", scroll).Color = Theme.AccentGlow

    local layout = Instance.new("UIListLayout", scroll)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    for i, opt in ipairs(options) do
        local btn = Instance.new("TextButton", scroll)
        btn.Size     = UDim2.new(1, 0, 0, ROW_H)
        btn.Text     = "  " .. tostring(opt)
        btn.BackgroundColor3 = Theme.SecondaryBg
        btn.TextColor3 = Theme.TextMuted
        btn.Font     = Theme.FontMain
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.LayoutOrder = i
        btn.ZIndex   = 3002
        trackConnection(state, btn.MouseEnter:Connect(function() btn.TextColor3 = Theme.TextMain end))
        trackConnection(state, btn.MouseLeave:Connect(function() btn.TextColor3 = Theme.TextMuted end))
        trackConnection(state, btn.MouseButton1Click:Connect(function()
            overlay:Destroy()
            onSelect(opt)
        end))
    end

    trackConnection(state, dimBtn.MouseButton1Click:Connect(function() overlay:Destroy() end))
    return overlay
end

-- ─── applyFeatureExtensions (subConfig renderer) ─────────────────────────────
local function applyFeatureExtensions(state, screenGui, container, description, subConfig, descStyle)
    local layout = container:FindFirstChildWhichIsA("UIListLayout")
    if not layout then
        layout = Instance.new("UIListLayout", container)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding   = UDim.new(0, 6)
    end

    local padding = container:FindFirstChildWhichIsA("UIPadding")
    if not padding then
        padding = Instance.new("UIPadding", container)
        padding.PaddingTop    = UDim.new(0, 0)
        padding.PaddingBottom = UDim.new(0, 0)
        padding.PaddingLeft   = UDim.new(0, 0)
        padding.PaddingRight  = UDim.new(0, 0)
    end

    if (description and description ~= "") or (subConfig and #subConfig > 0) then
        container.AutomaticSize = Enum.AutomaticSize.Y
        padding.PaddingBottom   = UDim.new(0, 10)
    end

    if subConfig and #subConfig > 0 then
        local subFrame = Instance.new("Frame", container)
        subFrame.Size = UDim2.new(1, 0, 0, 0)
        subFrame.BackgroundTransparency = 1
        subFrame.AutomaticSize = Enum.AutomaticSize.Y
        subFrame.LayoutOrder   = 2

        local subLayout = Instance.new("UIListLayout", subFrame)
        subLayout.SortOrder = Enum.SortOrder.LayoutOrder
        subLayout.Padding    = UDim.new(0, 6)

        local subPad = Instance.new("UIPadding", subFrame)
        subPad.PaddingLeft  = UDim.new(0, 14)
        subPad.PaddingRight = UDim.new(0, 14)

        local subOrder = 0
        local function nextSubOrder(item)
            subOrder = subOrder + 1
            return item.LayoutOrder or subOrder
        end

        for _, item in ipairs(subConfig) do
            local itemContainer

            if item.Type == "Checkbox" then
                itemContainer = Instance.new("Frame", subFrame)
                itemContainer.Size = UDim2.new(1, 0, 0, 24)
                itemContainer.BackgroundTransparency = 1
                itemContainer.LayoutOrder = nextSubOrder(item)

                local chk = Instance.new("TextButton", itemContainer)
                chk.Size = UDim2.new(1, 0, 1, 0)
                chk.BackgroundTransparency = 1
                chk.Text = ""

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
                trackConnection(state, chk.MouseButton1Click:Connect(function()
                    active = not active
                    checkMark.Visible = active
                    TweenService:Create(lbl, TweenInfo.new(0.2), {TextColor3 = active and Theme.TextMain or Theme.TextMuted}):Play()
                    if item.Callback then item.Callback(active) end
                end))

            elseif item.Type == "Color" then
                itemContainer = Instance.new("Frame", subFrame)
                itemContainer.Size = UDim2.new(1, 0, 0, 26)
                itemContainer.BackgroundTransparency = 1
                itemContainer.LayoutOrder = nextSubOrder(item)

                local lbl = Instance.new("TextLabel", itemContainer)
                lbl.Size = UDim2.new(0, 100, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = item.Text or "Color"
                lbl.TextColor3 = Theme.TextMuted
                lbl.Font = Theme.FontMain
                lbl.TextSize = 12
                lbl.TextXAlignment = Enum.TextXAlignment.Left

                local activeColor = item.DefaultColor or Color3.fromRGB(168, 85, 247)

                local cBtn = Instance.new("TextButton", itemContainer)
                cBtn.Size = UDim2.new(0, 36, 0, 18)
                cBtn.Position = UDim2.new(1, -36, 0.5, -9)
                cBtn.BackgroundColor3 = activeColor
                cBtn.Text = ""
                Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 4)
                Instance.new("UIStroke", cBtn).Color = Theme.Border

                trackConnection(state, cBtn.MouseButton1Click:Connect(function()
                    createColorPickerUI(state, screenGui, activeColor, function(c)
                        activeColor = c
                        cBtn.BackgroundColor3 = c
                        if item.Callback then item.Callback(c) end
                    end)
                end))

            elseif item.Type == "Input" then
                local inputHeight = item.Height or 28
                local inputSizeY  = item.InputHeight or 28
                local textSize    = item.TextSize or 12
                local inType      = item.InputType or "Any"
                local minVal      = item.Min
                local maxVal      = item.Max
                local defaultVal  = item.Default or (inType == "Number" and 0 or "")

                itemContainer = Instance.new("Frame", subFrame)
                itemContainer.Size = UDim2.new(1, 0, 0, math.max(inputHeight, inputSizeY))
                itemContainer.BackgroundTransparency = 1
                itemContainer.LayoutOrder = nextSubOrder(item)

                local lbl = Instance.new("TextLabel", itemContainer)
                lbl.Size = UDim2.new(0, 100, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = item.Text or "Input"
                lbl.TextColor3 = Theme.TextMuted
                lbl.Font = Theme.FontMain
                lbl.TextSize = textSize
                lbl.TextXAlignment = Enum.TextXAlignment.Left

                local box = Instance.new("TextBox", itemContainer)
                box.Size = UDim2.new(1, -105, 0, inputSizeY)
                box.Position = UDim2.new(0, 105, 0.5, -inputSizeY/2)
                box.BackgroundColor3 = Theme.SecondaryBg
                box.Text = tostring(defaultVal)
                box.PlaceholderText = item.Placeholder or "Type here..."
                box.PlaceholderColor3 = Color3.fromRGB(100, 100, 105)
                box.TextColor3 = Theme.TextMain
                box.Font = Theme.FontMain
                box.TextSize = textSize
                box.ClearTextOnFocus = false
                Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
                Instance.new("UIStroke", box).Color = Theme.Border

                trackConnection(state, box.FocusLost:Connect(function(enterPressed)
                    local txt = box.Text
                    if inType == "Number" then
                        local num = tonumber(txt) or defaultVal
                        if minVal then num = math.max(minVal, num) end
                        if maxVal then num = math.min(maxVal, num) end
                        box.Text = tostring(num)
                        if item.Callback then item.Callback(num, enterPressed) end
                    else
                        if item.Callback then item.Callback(txt, enterPressed) end
                    end
                end))

            elseif item.Type == "Button" then
                itemContainer = Instance.new("Frame", subFrame)
                itemContainer.Size = UDim2.new(1, 0, 0, 28)
                itemContainer.BackgroundTransparency = 1
                itemContainer.LayoutOrder = nextSubOrder(item)

                local btn = Instance.new("TextButton", itemContainer)
                btn.Size = UDim2.new(1, 0, 1, 0)
                btn.BackgroundColor3 = Theme.SecondaryBg
                btn.Text = item.Text or "Button"
                btn.TextColor3 = Theme.TextMain
                btn.Font = Theme.FontBold
                btn.TextSize = 11
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
                local bStroke = Instance.new("UIStroke", btn)
                bStroke.Color = Theme.Border

                trackConnection(state, btn.MouseEnter:Connect(function()
                    TweenService:Create(bStroke, TweenInfo.new(0.2), {Color=Theme.AccentGlow}):Play()
                end))
                trackConnection(state, btn.MouseLeave:Connect(function()
                    TweenService:Create(bStroke, TweenInfo.new(0.2), {Color=Theme.Border}):Play()
                end))
                trackConnection(state, btn.MouseButton1Click:Connect(function()
                    if item.Callback then item.Callback() end
                end))

            elseif item.Type == "Slider" then
                itemContainer = Instance.new("Frame", subFrame)
                itemContainer.Size = UDim2.new(1, 0, 0, 42)
                itemContainer.BackgroundTransparency = 1
                itemContainer.LayoutOrder = nextSubOrder(item)
                itemContainer.AutomaticSize = Enum.AutomaticSize.Y

                local sliderTop = Instance.new("Frame", itemContainer)
                sliderTop.Size = UDim2.new(1, 0, 0, 42)
                sliderTop.BackgroundTransparency = 1

                local lbl = Instance.new("TextLabel", sliderTop)
                lbl.Size = UDim2.new(1, -60, 0, 16)
                lbl.Position = UDim2.new(0, 0, 0, 4)
                lbl.BackgroundTransparency = 1
                lbl.Text = item.Text or "Slider"
                lbl.TextColor3 = Theme.TextMuted
                lbl.Font = Theme.FontMain
                lbl.TextSize = 12
                lbl.TextXAlignment = Enum.TextXAlignment.Left

                local valLbl = Instance.new("TextLabel", sliderTop)
                valLbl.Size = UDim2.new(0, 50, 0, 16)
                valLbl.Position = UDim2.new(1, -50, 0, 4)
                valLbl.BackgroundTransparency = 1
                valLbl.TextColor3 = Theme.TextMain
                valLbl.Font = Theme.FontBold
                valLbl.TextSize = 12
                valLbl.TextXAlignment = Enum.TextXAlignment.Right

                local slideBg = Instance.new("Frame", sliderTop)
                slideBg.Size = UDim2.new(1, 0, 0, 6)
                slideBg.Position = UDim2.new(0, 0, 0, 26)
                slideBg.BackgroundColor3 = Theme.SecondaryBg
                Instance.new("UICorner", slideBg).CornerRadius = UDim.new(1, 0)
                Instance.new("UIStroke", slideBg).Color = Theme.Border

                local fill = Instance.new("Frame", slideBg)
                fill.Size = UDim2.new(0, 0, 1, 0)
                fill.BackgroundColor3 = Theme.AccentGlow
                Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

                local sType  = item.SliderType or "Number"
                local list   = item.List or {}
                local minVal = item.Min or 0
                local maxVal = item.Max or 100
                local defVal = item.Default

                local function setSliderVisual(pct)
                    fill.Size = UDim2.new(math.clamp(pct,0,1), 0, 1, 0)
                end
                local function getVal(pct)
                    if sType == "Text" then
                        return list[math.clamp(math.floor(pct * #list)+1, 1, #list)]
                    else
                        return math.floor(minVal + (maxVal - minVal) * pct)
                    end
                end

                if sType == "Text" then
                    defVal = defVal or list[1]
                    valLbl.Text = tostring(defVal)
                    local si = 1
                    for i,v in ipairs(list) do if v == defVal then si = i break end end
                    setSliderVisual(#list > 1 and ((si-1)/(#list-1)) or 0)
                else
                    defVal = defVal or minVal
                    valLbl.Text = tostring(defVal)
                    setSliderVisual((maxVal-minVal) > 0 and ((defVal-minVal)/(maxVal-minVal)) or 0)
                end

                local isDragging = false
                -- фикс: defer чтение AbsolutePosition до реального drag
                local function updateDrag(input)
                    local bgSize = slideBg.AbsoluteSize.X
                    if bgSize <= 0 then return end
                    local pct = math.clamp((input.Position.X - slideBg.AbsolutePosition.X) / bgSize, 0, 1)
                    setSliderVisual(pct)
                    local v = getVal(pct)
                    valLbl.Text = tostring(v)
                    if item.Callback then item.Callback(v) end
                end
                trackConnection(state, slideBg.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        isDragging = true; updateDrag(input)
                    end
                end))
                trackConnection(state, UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        isDragging = false
                    end
                end))
                trackConnection(state, UserInputService.InputChanged:Connect(function(input)
                    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                        updateDrag(input)
                    end
                end))

            elseif item.Type == "Dropdown" then
                itemContainer = Instance.new("Frame", subFrame)
                itemContainer.Size = UDim2.new(1, 0, 0, 32)
                itemContainer.BackgroundTransparency = 1
                itemContainer.LayoutOrder = nextSubOrder(item)
                itemContainer.AutomaticSize = Enum.AutomaticSize.Y

                local dropTop = Instance.new("Frame", itemContainer)
                dropTop.Size = UDim2.new(1, 0, 0, 32)
                dropTop.BackgroundTransparency = 1

                local btn = Instance.new("TextButton", dropTop)
                btn.Size = UDim2.new(1, 0, 0, 32)
                btn.BackgroundColor3 = Theme.SecondaryBg
                btn.Text = "  " .. (item.Text or "Dropdown") .. ": " .. tostring(item.Default or "---")
                btn.TextColor3 = Theme.TextMain
                btn.Font = Theme.FontMain
                btn.TextSize = 12
                btn.TextXAlignment = Enum.TextXAlignment.Left
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
                Instance.new("UIStroke", btn).Color = Theme.Border

                local arrow = Instance.new("TextLabel", btn)
                arrow.Size = UDim2.new(0, 20, 1, 0)
                arrow.Position = UDim2.new(1, -25, 0, 0)
                arrow.BackgroundTransparency = 1
                arrow.Text = "▼"
                arrow.TextColor3 = Theme.TextMuted
                arrow.Font = Theme.FontMain
                arrow.TextSize = 10

                local isOpen = false
                trackConnection(state, btn.MouseButton1Click:Connect(function()
                    if isOpen then
                        local ov = screenGui:FindFirstChild("__DropOverlay")
                        if ov then ov:Destroy() end
                        isOpen = false
                        arrow.Rotation = 0
                    else
                        isOpen = true
                        arrow.Rotation = 180
                        openDropdownOverlay(state, screenGui, btn, item.Options or {}, function(opt)
                            btn.Text = "  " .. (item.Text or "Dropdown") .. ": " .. tostring(opt)
                            isOpen = false
                            arrow.Rotation = 0
                            if item.Callback then item.Callback(opt) end
                        end)
                    end
                end))
            end

            if itemContainer and item.subConfig then
                applyFeatureExtensions(state, screenGui, itemContainer, item.Description, item.subConfig, item.DescStyle)
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
        local dp = Instance.new("UIPadding", dLabel)
        dp.PaddingLeft  = UDim.new(0, 14)
        dp.PaddingRight = UDim.new(0, 14)
    end
end

-- ═════════════════════════════════════════════════════════════════════════════
function module.CreateUI(title)
    local headerText = title or "Modern Suite"
    local S = newInstanceState()   -- all per-instance state lives here

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name            = "ModernScriptUI"
    screenGui.ResetOnSpawn    = false
    screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder    = 9999
    screenGui.Parent          = player:WaitForChild("PlayerGui")
    trackObject(S, screenGui)

    local mainFrame = Instance.new("Frame")
    mainFrame.Size     = UDim2.new(0, 620, 0, 420)
    mainFrame.Position = UDim2.new(0.5, -310, 0.5, -210)
    mainFrame.BackgroundColor3 = Theme.Background
    mainFrame.BorderSizePixel  = 0
    mainFrame.Active           = true
    mainFrame.ClipsDescendants = true
    mainFrame.Parent           = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)
    makeDraggable(S, mainFrame)
    trackObject(S, mainFrame)

    local mainStroke = Instance.new("UIStroke", mainFrame)
    mainStroke.Color           = Theme.Border
    mainStroke.Thickness       = 1
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local headerLine = Instance.new("Frame", mainFrame)
    headerLine.Size     = UDim2.new(1, 0, 0, 1)
    headerLine.Position = UDim2.new(0, 0, 0, 45)
    headerLine.BackgroundColor3 = Theme.Border
    headerLine.BorderSizePixel  = 0

    local header = Instance.new("TextLabel", mainFrame)
    header.Size     = UDim2.new(1, -120, 0, 45)
    header.Position = UDim2.new(0, 20, 0, 0)
    header.Text     = headerText:upper()
    header.TextColor3 = Theme.TextMain
    header.BackgroundTransparency = 1
    header.Font     = Theme.FontBold
    header.TextSize = 14
    header.TextXAlignment = Enum.TextXAlignment.Left
    local uigrad = Instance.new("UIGradient", header)
    uigrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.TextMain),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200,200,200)),
    })

    local controlButtons = Instance.new("Frame", mainFrame)
    controlButtons.Size = UDim2.new(0, 90, 0, 45)
    controlButtons.Position = UDim2.new(1, -105, 0, 0)
    controlButtons.BackgroundTransparency = 1

    local function createControlBtn(text, posX, color)
        local btn = Instance.new("TextButton", controlButtons)
        btn.Size     = UDim2.new(0, 24, 0, 24)
        btn.Position = UDim2.new(0, posX, 0.5, -12)
        btn.BackgroundColor3 = Theme.SecondaryBg
        btn.Text     = text
        btn.Font     = Theme.FontBold
        btn.TextSize = 11
        btn.TextColor3 = Theme.TextMuted
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        local strk = Instance.new("UIStroke", btn)
        strk.Color = Theme.Border
        trackConnection(S, btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3=color, TextColor3=Theme.TextMain}):Play()
        end))
        trackConnection(S, btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3=Theme.SecondaryBg, TextColor3=Theme.TextMuted}):Play()
        end))
        return btn
    end

    local minimizeButton = createControlBtn("—", 0, Color3.fromRGB(234,179,8))
    local scaleButton    = createControlBtn("~", 30, Theme.AccentGlow)
    local closeButton    = createControlBtn("×", 60, Theme.Danger)

    -- confirm modal
    local confirmFrame = Instance.new("Frame", screenGui)
    confirmFrame.Size     = UDim2.new(0, 320, 0, 140)
    confirmFrame.Position = UDim2.new(0.5, -160, 0.5, -70)
    confirmFrame.BackgroundColor3 = Theme.SecondaryBg
    confirmFrame.ClipsDescendants = true
    confirmFrame.BackgroundTransparency = 1
    confirmFrame.Visible  = false
    Instance.new("UICorner", confirmFrame).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", confirmFrame).Color = Theme.Border
    trackObject(S, confirmFrame)

    local confirmText = Instance.new("TextLabel", confirmFrame)
    confirmText.Size     = UDim2.new(1, -40, 0, 60)
    confirmText.Position = UDim2.new(0, 20, 0, 15)
    confirmText.Text     = "Are you sure?"
    confirmText.TextColor3 = Theme.TextMain
    confirmText.BackgroundTransparency = 1
    confirmText.Font     = Theme.FontMain
    confirmText.TextSize = 14
    confirmText.TextWrapped = true

    local function createModalBtn(text, posX, bg, tc)
        local btn = Instance.new("TextButton", confirmFrame)
        btn.Size     = UDim2.new(0, 130, 0, 36)
        btn.Position = UDim2.new(0, posX, 1, -50)
        btn.Text     = text
        btn.BackgroundColor3 = bg
        btn.TextColor3 = tc
        btn.Font     = Theme.FontBold
        btn.TextSize = 13
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        return btn
    end
    local yesBtn = createModalBtn("Yes", 20, Theme.Danger, Theme.TextMain)
    local noBtn  = createModalBtn("No",  170, Color3.fromRGB(39,39,42), Theme.TextMain)

    local function animateModal(show)
        if show then
            confirmFrame.Size = UDim2.new(0,320,0,120)
            confirmFrame.BackgroundTransparency = 1
            confirmFrame.Visible = true
            TweenService:Create(confirmFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size=UDim2.new(0,320,0,140), BackgroundTransparency=0}):Play()
        else
            local tw = TweenService:Create(confirmFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size=UDim2.new(0,320,0,120), BackgroundTransparency=1})
            tw:Play()
            tw.Completed:Connect(function() confirmFrame.Visible = false end)
        end
    end

    trackConnection(S, closeButton.MouseButton1Click:Connect(function() animateModal(true) end))
    trackConnection(S, noBtn.MouseButton1Click:Connect(function() animateModal(false) end))
    trackConnection(S, yesBtn.MouseButton1Click:Connect(function()
        disconnectAll(S)
        destroyAll(S)
    end))

    local isScaledDown = false
    local normalSize   = UDim2.new(0, 620, 0, 420)
    local smallSize    = UDim2.new(0, 620, 0, 200)

    trackConnection(S, scaleButton.MouseButton1Click:Connect(function()
        isScaledDown = not isScaledDown
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = isScaledDown and smallSize or normalSize}):Play()
    end))

    local minimizedFrame = Instance.new("ImageButton")
    minimizedFrame.Size   = UDim2.new(0, 48, 0, 48)
    minimizedFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
    minimizedFrame.BackgroundColor3 = Theme.Background
    minimizedFrame.Visible = false
    Instance.new("UICorner", minimizedFrame).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", minimizedFrame).Color = Theme.AccentGlow
    makeDraggable(S, minimizedFrame)
    minimizedFrame.Parent = screenGui

    local plusIcon = Instance.new("TextLabel", minimizedFrame)
    plusIcon.Size  = UDim2.new(1, 0, 1, 0)
    plusIcon.Text  = "+"
    plusIcon.TextColor3 = Theme.AccentGlow
    plusIcon.BackgroundTransparency = 1
    plusIcon.Font  = Theme.FontBold
    plusIcon.TextSize = 24

    local function setMinimizedImage(assetId)
        if assetId and assetId ~= "" then
            minimizedFrame.Image = "rbxassetid://" .. assetId
            plusIcon.Visible = false
        else
            minimizedFrame.Image = "rbxthumb://type=Asset&id=" .. game.PlaceId .. "&w=150&h=150"
            plusIcon.Visible = false
        end
    end

    local function toggleMinimize(minimize)
        if minimize then
            local t = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size=UDim2.new(0,0,0,0), BackgroundTransparency=1})
            t:Play()
            local c; c = t.Completed:Connect(function()
                c:Disconnect()
                mainFrame.Visible = false
                minimizedFrame.Visible = true
                minimizedFrame.Size = UDim2.new(0,0,0,0)
                TweenService:Create(minimizedFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Size=UDim2.new(0,48,0,48)}):Play()
            end)
        else
            local t = TweenService:Create(minimizedFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size=UDim2.new(0,0,0,0)})
            t:Play()
            local c; c = t.Completed:Connect(function()
                c:Disconnect()
                minimizedFrame.Visible = false
                mainFrame.Visible = true
                TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back),
                    {Size = isScaledDown and smallSize or normalSize, BackgroundTransparency=0}):Play()
            end)
        end
    end

    trackConnection(S, minimizeButton.MouseButton1Click:Connect(function() toggleMinimize(true) end))
    trackConnection(S, minimizedFrame.MouseButton1Click:Connect(function() toggleMinimize(false) end))

    local categoryFrame = Instance.new("ScrollingFrame", mainFrame)
    categoryFrame.Size     = UDim2.new(0, 160, 1, -65)
    categoryFrame.Position = UDim2.new(0, 12, 0, 55)
    categoryFrame.CanvasSize = UDim2.new(0,0,0,0)
    categoryFrame.ScrollBarThickness = 0
    categoryFrame.BackgroundTransparency = 1
    categoryFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    trackObject(S, categoryFrame)

    local categoryLayout = Instance.new("UIListLayout", categoryFrame)
    categoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
    categoryLayout.Padding   = UDim.new(0, 8)

    local contentFrame = Instance.new("Frame", mainFrame)
    contentFrame.Size     = UDim2.new(1, -196, 1, -65)
    contentFrame.Position = UDim2.new(0, 184, 0, 55)
    contentFrame.BackgroundColor3 = Theme.SecondaryBg
    contentFrame.BorderSizePixel  = 0
    Instance.new("UICorner", contentFrame).CornerRadius = UDim.new(0, 10)
    Instance.new("UIStroke", contentFrame).Color = Theme.Border
    trackObject(S, contentFrame)

    local contentScroll = Instance.new("ScrollingFrame", contentFrame)
    contentScroll.Size     = UDim2.new(1, -16, 1, -16)
    contentScroll.Position = UDim2.new(0, 8, 0, 8)
    contentScroll.BackgroundTransparency = 1
    contentScroll.ScrollBarThickness = 4
    contentScroll.ScrollBarImageColor3 = Theme.Border
    contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentScroll.CanvasSize = UDim2.new(0,0,0,0)
    trackObject(S, contentScroll)

    local contentPadding = Instance.new("UIPadding", contentScroll)
    contentPadding.PaddingBottom = UDim.new(0, 10)

    local categories = {}

    -- ── widgets ──────────────────────────────────────────────────────────────

    local uiData = {}

    function uiData.CreateCategory(name)
        local button = Instance.new("TextButton", categoryFrame)
        button.Size     = UDim2.new(1, -5, 0, 38)
        button.Text     = "    " .. name
        button.BackgroundColor3 = Color3.fromRGB(24,24,27)
        button.TextColor3 = Theme.TextMuted
        button.Font     = Theme.FontMain
        button.TextSize = 13
        button.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
        local bStroke = Instance.new("UIStroke", button)
        bStroke.Color = Theme.Border
        trackObject(S, button)

        local selBar = Instance.new("Frame", button)
        selBar.Size   = UDim2.new(0, 4, 0, 16)
        selBar.Position = UDim2.new(0, 6, 0.5, -8)
        selBar.BackgroundColor3 = Theme.AccentGlow
        selBar.Visible = false
        Instance.new("UICorner", selBar)

        local holder = Instance.new("Frame", contentScroll)
        holder.Size = UDim2.new(1, 0, 0, 0)
        holder.BackgroundTransparency = 1
        holder.Visible = false
        trackObject(S, holder)

        local layout = Instance.new("UIListLayout", holder)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding   = UDim.new(0, 8)

        trackConnection(S, layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            holder.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
            if holder.Visible then
                contentScroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
            end
        end))

        trackConnection(S, button.MouseButton1Click:Connect(function()
            for _, cat in ipairs(categories) do
                cat.holder.Visible = false
                cat.bar.Visible    = false
                TweenService:Create(cat.button, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(24,24,27), TextColor3=Theme.TextMuted}):Play()
            end
            holder.Visible  = true
            selBar.Visible  = true
            contentScroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
            TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3=Theme.SecondaryBg, TextColor3=Theme.TextMain}):Play()
        end))

        table.insert(categories, {holder=holder, button=button, bar=selBar})
        return holder
    end

    -- backward compat: module.CreateCategory → uiData.CreateCategory
    module.CreateCategory = uiData.CreateCategory

    -- ── Toggle ───────────────────────────────────────────────────────────────
    function uiData.CreateToggle(text, parent, callback, description, subConfig, descStyle)
        local container = Instance.new("Frame", parent)
        container.Size  = UDim2.new(1, -4, 0, 42)
        container.BackgroundColor3 = Theme.Background
        container.LayoutOrder = nextOrder(S)
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
        Instance.new("UIStroke", container).Color = Theme.Border
        trackObject(S, container)

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
                TweenService:Create(switch, bgInfo, {BackgroundColor3=Theme.AccentGlow}):Play()
                TweenService:Create(knob, tInfo, {Position=UDim2.new(1,-19,0.5,-8), BackgroundColor3=Theme.TextMain}):Play()
            else
                TweenService:Create(switch, bgInfo, {BackgroundColor3=Theme.SecondaryBg}):Play()
                TweenService:Create(knob, tInfo, {Position=UDim2.new(0,3,0.5,-8), BackgroundColor3=Theme.TextMuted}):Play()
            end
        end

        local touchPos
        trackConnection(S, topRow.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                touchPos = input.Position
            end
        end))
        trackConnection(S, topRow.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
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
        applyFeatureExtensions(S, screenGui, container, description, subConfig, descStyle)

        local widget = {_container = container}
        function widget:SetValue(val)
            enabled = val
            updateVisual(true)
            if callback then callback(enabled) end
        end
        function widget:GetValue() return enabled end
        return widget
    end
    module.CreateToggle = uiData.CreateToggle

    -- ── Button ───────────────────────────────────────────────────────────────
    function uiData.CreateButton(text, parent, callback, description, subConfig, descStyle)
        local container = Instance.new("Frame", parent)
        container.Size  = UDim2.new(1, -4, 0, 40)
        container.BackgroundColor3 = Theme.SecondaryBg
        container.LayoutOrder = nextOrder(S)
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
        local bStroke = Instance.new("UIStroke", container)
        bStroke.Color = Theme.Border
        trackObject(S, container)

        local button = Instance.new("TextButton", container)
        button.Size   = UDim2.new(1, 0, 0, 40)
        button.Text   = text
        button.BackgroundTransparency = 1
        button.TextColor3 = Theme.TextMain
        button.Font   = Theme.FontBold
        button.TextSize = 13
        button.AutoButtonColor = false
        button.LayoutOrder = 1

        trackConnection(S, button.MouseEnter:Connect(function()
            TweenService:Create(container, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(30,30,37)}):Play()
            TweenService:Create(bStroke, TweenInfo.new(0.2), {Color=Theme.AccentGlow}):Play()
        end))
        trackConnection(S, button.MouseLeave:Connect(function()
            TweenService:Create(container, TweenInfo.new(0.2), {BackgroundColor3=Theme.SecondaryBg}):Play()
            TweenService:Create(bStroke, TweenInfo.new(0.2), {Color=Theme.Border}):Play()
        end))
        trackConnection(S, button.MouseButton1Click:Connect(function()
            local bd = TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {Size=UDim2.new(1,0,0,36)})
            local bu = TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Back), {Size=UDim2.new(1,0,0,40)})
            bd:Play()
            local bc; bc = bd.Completed:Connect(function() bc:Disconnect(); bu:Play() end)
            if callback then callback() end
        end))

        applyFeatureExtensions(S, screenGui, container, description, subConfig, descStyle)

        local widget = {_container = container}
        function widget:SetText(t) button.Text = t end
        function widget:GetText() return button.Text end
        return widget
    end
    module.CreateButton = uiData.CreateButton

    -- ── Slider ───────────────────────────────────────────────────────────────
    function uiData.CreateSlider(text, parent, config, description, subConfig, descStyle)
        local container = Instance.new("Frame", parent)
        container.Size  = UDim2.new(1, -4, 0, 52)
        container.BackgroundColor3 = Theme.Background
        container.LayoutOrder = nextOrder(S)
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
        Instance.new("UIStroke", container).Color = Theme.Border
        trackObject(S, container)

        local sliderTop = Instance.new("Frame", container)
        sliderTop.Size = UDim2.new(1, 0, 0, 52)
        sliderTop.BackgroundTransparency = 1
        sliderTop.LayoutOrder = 1

        local lbl = Instance.new("TextLabel", sliderTop)
        lbl.Size = UDim2.new(1, -60, 0, 20)
        lbl.Position = UDim2.new(0, 14, 0, 8)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Theme.TextMain
        lbl.Font = Theme.FontMain
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local valLbl = Instance.new("TextLabel", sliderTop)
        valLbl.Size = UDim2.new(0, 50, 0, 20)
        valLbl.Position = UDim2.new(1, -64, 0, 8)
        valLbl.BackgroundTransparency = 1
        valLbl.TextColor3 = Theme.TextMuted
        valLbl.Font = Theme.FontBold
        valLbl.TextSize = 13
        valLbl.TextXAlignment = Enum.TextXAlignment.Right

        local slideBg = Instance.new("Frame", sliderTop)
        slideBg.Size = UDim2.new(1, -28, 0, 6)
        slideBg.Position = UDim2.new(0, 14, 0, 36)
        slideBg.BackgroundColor3 = Theme.SecondaryBg
        Instance.new("UICorner", slideBg).CornerRadius = UDim.new(1, 0)
        Instance.new("UIStroke", slideBg).Color = Theme.Border

        local fill = Instance.new("Frame", slideBg)
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = Theme.AccentGlow
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        config = config or {}
        local sType  = config.SliderType or "Number"
        local list   = config.List or {}
        local minVal = config.Min or 0
        local maxVal = config.Max or 100
        local defVal = config.Default

        local function setSliderVisual(pct)
            fill.Size = UDim2.new(math.clamp(pct,0,1), 0, 1, 0)
        end
        local function getVal(pct)
            if sType == "Text" then
                return list[math.clamp(math.floor(pct * #list)+1, 1, #list)]
            else
                return math.floor(minVal + (maxVal - minVal) * pct)
            end
        end
        local function pctFromVal(v)
            if sType == "Text" then
                for i,x in ipairs(list) do if x == v then return #list > 1 and (i-1)/(#list-1) or 0 end end
                return 0
            else
                return (maxVal - minVal) > 0 and (v - minVal)/(maxVal - minVal) or 0
            end
        end

        if sType == "Text" then
            defVal = defVal or list[1]
        else
            defVal = defVal or minVal
        end
        valLbl.Text = tostring(defVal)
        setSliderVisual(pctFromVal(defVal))

        local isDragging = false
        local function updateDrag(input)
            local bgSize = slideBg.AbsoluteSize.X
            if bgSize <= 0 then return end
            local pct = math.clamp((input.Position.X - slideBg.AbsolutePosition.X) / bgSize, 0, 1)
            setSliderVisual(pct)
            local v = getVal(pct)
            valLbl.Text = tostring(v)
            if config.Callback then config.Callback(v) end
        end
        trackConnection(S, slideBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = true; updateDrag(input)
            end
        end))
        trackConnection(S, UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = false
            end
        end))
        trackConnection(S, UserInputService.InputChanged:Connect(function(input)
            if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
                updateDrag(input)
            end
        end))

        applyFeatureExtensions(S, screenGui, container, description, subConfig, descStyle)

        local widget = {_container = container}
        function widget:SetValue(v)
            defVal = v
            valLbl.Text = tostring(v)
            setSliderVisual(pctFromVal(v))
            if config.Callback then config.Callback(v) end
        end
        function widget:GetValue() return getVal(fill.Size.X.Scale) end
        return widget
    end
    module.CreateSlider = uiData.CreateSlider

    -- ── Input ────────────────────────────────────────────────────────────────
    function uiData.CreateInput(text, parent, config, description, subConfig, descStyle)
        local container = Instance.new("Frame", parent)
        container.Size  = UDim2.new(1, -4, 0, 42)
        container.BackgroundColor3 = Theme.Background
        container.LayoutOrder = nextOrder(S)
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
        Instance.new("UIStroke", container).Color = Theme.Border
        trackObject(S, container)

        local inTop = Instance.new("Frame", container)
        inTop.Size = UDim2.new(1, 0, 0, 42)
        inTop.BackgroundTransparency = 1
        inTop.LayoutOrder = 1

        local lbl = Instance.new("TextLabel", inTop)
        lbl.Size = UDim2.new(0, 120, 1, 0)
        lbl.Position = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Theme.TextMain
        lbl.Font = Theme.FontMain
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        config = config or {}
        local inType    = config.InputType or "Any"
        local minVal    = config.Min
        local maxVal    = config.Max
        local defaultVal = config.Default or (inType == "Number" and 0 or "")

        local box = Instance.new("TextBox", inTop)
        box.Size     = UDim2.new(1, -150, 0, 28)
        box.Position = UDim2.new(0, 136, 0.5, -14)
        box.BackgroundColor3 = Theme.SecondaryBg
        box.Text     = tostring(defaultVal)
        box.PlaceholderText = config.Placeholder or "Type here..."
        box.PlaceholderColor3 = Color3.fromRGB(100,100,105)
        box.TextColor3 = Theme.TextMain
        box.Font     = Theme.FontMain
        box.TextSize = 12
        box.ClearTextOnFocus = false
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", box).Color = Theme.Border

        trackConnection(S, box.FocusLost:Connect(function(enterPressed)
            local txt = box.Text
            if inType == "Number" then
                local num = tonumber(txt) or defaultVal
                if minVal then num = math.max(minVal, num) end
                if maxVal then num = math.min(maxVal, num) end
                box.Text = tostring(num)
                if config.Callback then config.Callback(num, enterPressed) end
            else
                if config.Callback then config.Callback(txt, enterPressed) end
            end
        end))

        applyFeatureExtensions(S, screenGui, container, description, subConfig, descStyle)

        local widget = {_container = container}
        function widget:SetValue(v)
            box.Text = tostring(v)
            if config.Callback then config.Callback(v, false) end
        end
        function widget:GetValue() return box.Text end
        return widget
    end
    module.CreateInput = uiData.CreateInput

    -- ── Dropdown ─────────────────────────────────────────────────────────────
    function uiData.CreateDropdown(text, parent, config, description, subConfig, descStyle)
        local container = Instance.new("Frame", parent)
        container.Size  = UDim2.new(1, -4, 0, 46)
        container.BackgroundColor3 = Theme.Background
        container.LayoutOrder = nextOrder(S)
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
        Instance.new("UIStroke", container).Color = Theme.Border
        trackObject(S, container)

        local dropTop = Instance.new("Frame", container)
        dropTop.Size = UDim2.new(1, 0, 0, 46)
        dropTop.BackgroundTransparency = 1
        dropTop.LayoutOrder = 1

        local btn = Instance.new("TextButton", dropTop)
        btn.Size     = UDim2.new(1, -20, 0, 32)
        btn.Position = UDim2.new(0, 10, 0.5, -16)
        btn.BackgroundColor3 = Theme.SecondaryBg
        btn.Text     = "  " .. text .. ": " .. tostring(config.Default or "---")
        btn.TextColor3 = Theme.TextMain
        btn.Font     = Theme.FontMain
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", btn).Color = Theme.Border

        local arrow = Instance.new("TextLabel", btn)
        arrow.Size = UDim2.new(0, 20, 1, 0)
        arrow.Position = UDim2.new(1, -25, 0, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = "▼"
        arrow.TextColor3 = Theme.TextMuted
        arrow.Font = Theme.FontMain
        arrow.TextSize = 12

        local selected = config.Default or "---"
        local isOpen   = false

        trackConnection(S, btn.MouseButton1Click:Connect(function()
            if isOpen then
                local ov = screenGui:FindFirstChild("__DropOverlay")
                if ov then ov:Destroy() end
                isOpen = false; arrow.Rotation = 0
            else
                isOpen = true; arrow.Rotation = 180
                openDropdownOverlay(S, screenGui, btn, config.Options or {}, function(opt)
                    selected = opt
                    btn.Text = "  " .. text .. ": " .. tostring(opt)
                    isOpen = false; arrow.Rotation = 0
                    if config.Callback then config.Callback(opt) end
                end)
            end
        end))

        applyFeatureExtensions(S, screenGui, container, description, subConfig, descStyle)

        local widget = {_container = container}
        function widget:SetValue(v)
            selected = v
            btn.Text = "  " .. text .. ": " .. tostring(v)
            if config.Callback then config.Callback(v) end
        end
        function widget:GetValue() return selected end
        function widget:SetOptions(opts)
            config.Options = opts
        end
        return widget
    end
    module.CreateDropdown = uiData.CreateDropdown

    -- ── MultiDropdown ─────────────────────────────────────────────────────────
    function uiData.CreateMultiDropdown(text, parent, config, description, subConfig, descStyle)
        config = config or {}
        local selected = {}
        if config.Default then
            for _, v in ipairs(config.Default) do selected[v] = true end
        end

        local container = Instance.new("Frame", parent)
        container.Size  = UDim2.new(1, -4, 0, 46)
        container.BackgroundColor3 = Theme.Background
        container.LayoutOrder = nextOrder(S)
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
        Instance.new("UIStroke", container).Color = Theme.Border
        trackObject(S, container)

        local dropTop = Instance.new("Frame", container)
        dropTop.Size = UDim2.new(1, 0, 0, 46)
        dropTop.BackgroundTransparency = 1
        dropTop.LayoutOrder = 1

        local function buildLabel()
            local keys = {}
            for k in pairs(selected) do table.insert(keys, k) end
            if #keys == 0 then return "  " .. text .. ": ---" end
            return "  " .. text .. ": " .. table.concat(keys, ", ")
        end

        local btn = Instance.new("TextButton", dropTop)
        btn.Size     = UDim2.new(1, -20, 0, 32)
        btn.Position = UDim2.new(0, 10, 0.5, -16)
        btn.BackgroundColor3 = Theme.SecondaryBg
        btn.Text     = buildLabel()
        btn.TextColor3 = Theme.TextMain
        btn.Font     = Theme.FontMain
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.TextTruncate = Enum.TextTruncate.AtEnd
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", btn).Color = Theme.Border

        local arrow = Instance.new("TextLabel", btn)
        arrow.Size = UDim2.new(0, 20, 1, 0)
        arrow.Position = UDim2.new(1, -25, 0, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = "▼"
        arrow.TextColor3 = Theme.TextMuted
        arrow.Font = Theme.FontMain
        arrow.TextSize = 12

        local isOpen = false

        local function openMultiOverlay()
            local existing = screenGui:FindFirstChild("__DropOverlay")
            if existing then existing:Destroy() end

            local overlay = Instance.new("Frame", screenGui)
            overlay.Name = "__DropOverlay"
            overlay.BackgroundTransparency = 1
            overlay.Size = UDim2.new(1, 0, 1, 0)
            overlay.ZIndex = 3000

            local dimBtn2 = Instance.new("TextButton", overlay)
            dimBtn2.Size = UDim2.new(1, 0, 1, 0)
            dimBtn2.BackgroundTransparency = 1
            dimBtn2.Text = ""
            dimBtn2.ZIndex = 3000

            local abs  = btn.AbsolutePosition
            local absS = btn.AbsoluteSize
            local ROW_H   = 30
            local opts    = config.Options or {}
            local maxRows = math.min(#opts, 5)

            local scroll = Instance.new("ScrollingFrame", overlay)
            scroll.Size     = UDim2.new(0, absS.X, 0, maxRows * ROW_H)
            scroll.Position = UDim2.new(0, abs.X, 0, abs.Y + absS.Y + 4)
            scroll.BackgroundColor3 = Theme.SecondaryBg
            scroll.ScrollBarThickness = 2
            scroll.CanvasSize = UDim2.new(0, 0, 0, #opts * ROW_H)
            scroll.ZIndex = 3001
            Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)
            Instance.new("UIStroke", scroll).Color = Theme.AccentGlow

            local layout2 = Instance.new("UIListLayout", scroll)
            layout2.SortOrder = Enum.SortOrder.LayoutOrder

            local rowBtns = {}
            local function refreshRows()
                for optName, rb in pairs(rowBtns) do
                    rb.TextColor3 = selected[optName] and Theme.AccentGlow or Theme.TextMuted
                end
            end

            for i, opt in ipairs(opts) do
                local rb = Instance.new("TextButton", scroll)
                rb.Size     = UDim2.new(1, 0, 0, ROW_H)
                rb.Text     = "  " .. tostring(opt)
                rb.BackgroundColor3 = Theme.SecondaryBg
                rb.TextColor3 = selected[opt] and Theme.AccentGlow or Theme.TextMuted
                rb.Font     = Theme.FontMain
                rb.TextSize = 12
                rb.TextXAlignment = Enum.TextXAlignment.Left
                rb.LayoutOrder = i
                rb.ZIndex   = 3002
                rowBtns[opt] = rb
                trackConnection(S, rb.MouseButton1Click:Connect(function()
                    selected[opt] = not selected[opt] or nil
                    refreshRows()
                    btn.Text = buildLabel()
                    local vals = {}
                    for k in pairs(selected) do table.insert(vals, k) end
                    if config.Callback then config.Callback(vals) end
                end))
            end

            trackConnection(S, dimBtn2.MouseButton1Click:Connect(function()
                overlay:Destroy()
                isOpen = false; arrow.Rotation = 0
            end))
        end

        trackConnection(S, btn.MouseButton1Click:Connect(function()
            if isOpen then
                local ov = screenGui:FindFirstChild("__DropOverlay")
                if ov then ov:Destroy() end
                isOpen = false; arrow.Rotation = 0
            else
                isOpen = true; arrow.Rotation = 180
                openMultiOverlay()
            end
        end))

        applyFeatureExtensions(S, screenGui, container, description, subConfig, descStyle)

        local widget = {_container = container}
        function widget:SetValue(tbl)
            selected = {}
            for _, v in ipairs(tbl) do selected[v] = true end
            btn.Text = buildLabel()
        end
        function widget:GetValue()
            local vals = {}
            for k in pairs(selected) do table.insert(vals, k) end
            return vals
        end
        function widget:SetOptions(opts)
            config.Options = opts
        end
        return widget
    end
    module.CreateMultiDropdown = uiData.CreateMultiDropdown

    -- ── ColorPicker (top-level widget) ────────────────────────────────────────
    function uiData.CreateColorPicker(text, parent, config, description, subConfig, descStyle)
        config = config or {}
        local activeColor = config.Default or Color3.fromRGB(168, 85, 247)

        local container = Instance.new("Frame", parent)
        container.Size  = UDim2.new(1, -4, 0, 42)
        container.BackgroundColor3 = Theme.Background
        container.LayoutOrder = nextOrder(S)
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
        Instance.new("UIStroke", container).Color = Theme.Border
        trackObject(S, container)

        local row = Instance.new("Frame", container)
        row.Size = UDim2.new(1, 0, 0, 42)
        row.BackgroundTransparency = 1
        row.LayoutOrder = 1

        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(1, -70, 1, 0)
        lbl.Position = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Theme.TextMain
        lbl.Font = Theme.FontMain
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local cBtn = Instance.new("TextButton", row)
        cBtn.Size     = UDim2.new(0, 42, 0, 22)
        cBtn.Position = UDim2.new(1, -56, 0.5, -11)
        cBtn.BackgroundColor3 = activeColor
        cBtn.Text     = ""
        Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 6)
        local cStrk = Instance.new("UIStroke", cBtn)
        cStrk.Color = Theme.Border

        trackConnection(S, cBtn.MouseButton1Click:Connect(function()
            createColorPickerUI(S, screenGui, activeColor, function(c)
                activeColor = c
                cBtn.BackgroundColor3 = c
                if config.Callback then config.Callback(c) end
            end)
        end))

        applyFeatureExtensions(S, screenGui, container, description, subConfig, descStyle)

        local widget = {_container = container}
        function widget:SetValue(c)
            activeColor = c
            cBtn.BackgroundColor3 = c
            if config.Callback then config.Callback(c) end
        end
        function widget:GetValue() return activeColor end
        return widget
    end
    module.CreateColorPicker = uiData.CreateColorPicker

    -- ── Label ────────────────────────────────────────────────────────────────
    function uiData.CreateLabel(text, parent, config)
        config = config or {}
        local container = Instance.new("Frame", parent)
        container.Size  = UDim2.new(1, -4, 0, config.Height or 28)
        container.BackgroundTransparency = 1
        container.LayoutOrder = nextOrder(S)
        trackObject(S, container)

        local lbl = Instance.new("TextLabel", container)
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.Position = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = config.Color or Theme.TextMuted
        lbl.Font = config.Bold and Theme.FontBold or Theme.FontMain
        lbl.TextSize = config.TextSize or 12
        lbl.TextXAlignment = config.Align or Enum.TextXAlignment.Left
        lbl.TextWrapped = true

        local widget = {_container = container}
        function widget:SetText(t) lbl.Text = t end
        function widget:GetText() return lbl.Text end
        function widget:SetColor(c) lbl.TextColor3 = c end
        return widget
    end
    module.CreateLabel = uiData.CreateLabel

    -- ── Separator ────────────────────────────────────────────────────────────
    function uiData.CreateSeparator(parent, config)
        config = config or {}
        local h = config.Height or 1
        local vpad = config.Padding or 6

        local container = Instance.new("Frame", parent)
        container.Size  = UDim2.new(1, -4, 0, h + vpad * 2)
        container.BackgroundTransparency = 1
        container.LayoutOrder = nextOrder(S)
        trackObject(S, container)

        local line = Instance.new("Frame", container)
        line.Size     = UDim2.new(1, -28, 0, h)
        line.Position = UDim2.new(0, 14, 0.5, -math.floor(h/2))
        line.BackgroundColor3 = config.Color or Theme.Border
        line.BorderSizePixel  = 0
        Instance.new("UICorner", line).CornerRadius = UDim.new(1, 0)

        if config.Label and config.Label ~= "" then
            local bg = Instance.new("Frame", line)
            bg.Size     = UDim2.new(0, 0, 1, 8)
            bg.Position = UDim2.new(0.5, 0, 0.5, 0)
            bg.AnchorPoint = Vector2.new(0.5, 0.5)
            bg.BackgroundColor3 = Theme.SecondaryBg
            bg.BorderSizePixel  = 0
            bg.AutomaticSize    = Enum.AutomaticSize.X

            local sepLbl = Instance.new("TextLabel", bg)
            sepLbl.Size     = UDim2.new(0, 0, 1, 0)
            sepLbl.AutomaticSize = Enum.AutomaticSize.X
            sepLbl.BackgroundTransparency = 1
            sepLbl.Text     = " " .. config.Label .. " "
            sepLbl.TextColor3 = config.LabelColor or Theme.TextMuted
            sepLbl.Font     = Theme.FontMain
            sepLbl.TextSize = config.LabelSize or 11
        end

        local widget = {_container = container}
        function widget:SetColor(c) line.BackgroundColor3 = c end
        return widget
    end
    module.CreateSeparator = uiData.CreateSeparator

    -- ── PlayerList (unchanged logic, returns widget table) ────────────────────
    function uiData.CreatePlayerList(parentFrame)
        local selectedPlayer = "---"
        local tracking = false

        local container = Instance.new("Frame", parentFrame)
        container.Size  = UDim2.new(1, -4, 0, 46)
        container.BackgroundColor3 = Theme.Background
        container.LayoutOrder = nextOrder(S)
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
        Instance.new("UIStroke", container).Color = Theme.Border
        trackObject(S, container)

        local dropdownButton = Instance.new("TextButton", container)
        dropdownButton.Size     = UDim2.new(1, -120, 0, 32)
        dropdownButton.Position = UDim2.new(0, 10, 0.5, -16)
        dropdownButton.Text     = "  Player: " .. selectedPlayer
        dropdownButton.TextColor3 = Theme.TextMain
        dropdownButton.Font     = Theme.FontMain
        dropdownButton.TextSize = 13
        dropdownButton.BackgroundColor3 = Theme.SecondaryBg
        dropdownButton.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", dropdownButton).CornerRadius = UDim.new(0, 6)
        Instance.new("UIStroke", dropdownButton).Color = Theme.Border

        local trackBtn = Instance.new("TextButton", container)
        trackBtn.Size     = UDim2.new(0, 80, 0, 32)
        trackBtn.Position = UDim2.new(1, -90, 0.5, -16)
        trackBtn.Text     = "Track"
        trackBtn.Font     = Theme.FontBold
        trackBtn.TextSize = 12
        trackBtn.BackgroundColor3 = Color3.fromRGB(24,24,27)
        trackBtn.TextColor3 = Theme.TextMuted
        Instance.new("UICorner", trackBtn).CornerRadius = UDim.new(0, 6)
        local tStroke = Instance.new("UIStroke", trackBtn)
        tStroke.Color = Theme.Border

        trackConnection(S, dropdownButton.MouseButton1Click:Connect(function()
            local opts = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player then table.insert(opts, p.Name) end
            end
            openDropdownOverlay(S, screenGui, dropdownButton, opts, function(name)
                selectedPlayer = name
                dropdownButton.Text = "  Player: " .. selectedPlayer
            end)
        end))

        trackConnection(S, trackBtn.MouseButton1Click:Connect(function()
            tracking = not tracking
            if tracking then
                TweenService:Create(trackBtn, TweenInfo.new(0.2), {BackgroundColor3=Theme.Success, TextColor3=Theme.TextMain}):Play()
                tStroke.Color = Theme.Success
            else
                TweenService:Create(trackBtn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(24,24,27), TextColor3=Theme.TextMuted}):Play()
                tStroke.Color = Theme.Border
            end
        end))

        trackConnection(S, RunService.RenderStepped:Connect(function()
            if tracking and selectedPlayer ~= "---" then
                local target = Players:FindFirstChild(selectedPlayer)
                if target and target.Character
                and target.Character:FindFirstChild("HumanoidRootPart")
                and player.Character
                and player.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame =
                        target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
                end
            end
        end))

        local widget = {_container = container}
        function widget:GetSelected() return selectedPlayer end
        function widget:IsTracking() return tracking end
        return widget
    end
    module.CreatePlayerList = uiData.CreatePlayerList

    -- ── misc uiData fields ────────────────────────────────────────────────────
    local function openFirstCategory()
        if #categories > 0 then
            categories[1].holder.Visible = true
            categories[1].bar.Visible    = true
            categories[1].button.BackgroundColor3 = Theme.SecondaryBg
            categories[1].button.TextColor3 = Theme.TextMain
            local l = categories[1].holder:FindFirstChildWhichIsA("UIListLayout")
            contentScroll.CanvasSize = UDim2.new(0, 0, 0, l and l.AbsoluteContentSize.Y or 0)
        end
    end

    uiData.ScreenGui      = screenGui
    uiData.MainFrame      = mainFrame
    uiData.MinimizedFrame = minimizedFrame
    uiData.CategoryFrame  = categoryFrame
    uiData.ContentFrame   = contentScroll
    uiData.Categories     = categories

    uiData.SetMinimizedImage = setMinimizedImage
    uiData.OpenFirstCategory = openFirstCategory
    uiData.Hide  = function() toggleMinimize(true) end
    uiData.Show  = function() toggleMinimize(false) end
    uiData.Close = function() disconnectAll(S); destroyAll(S) end
    uiData.OnClose = function(cb) S.onCloseCallback = cb end

    return uiData
end

return module
