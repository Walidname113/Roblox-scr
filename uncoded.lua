-- v10
local module = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local connections = {}
local trackedObjects = {}

local function trackConnection(conn)
    table.insert(connections, conn)
end

local function trackObject(obj)
    table.insert(trackedObjects, obj)
end

local function disconnectAll()
    for _, conn in ipairs(connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    connections = {}
end

local function destroyAll()
    for _, obj in ipairs(trackedObjects) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    trackedObjects = {}
end

local function makeDraggable(frame)
    local dragging = false
    local dragInput, dragStart, startPos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            trackConnection(input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end))
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    trackConnection(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end))
end

function module.CreateUI(title)
    local headerText = title or "Unnamed UI"

    local screenGui
    local function ensureScreenGui()
        if not screenGui or not screenGui.Parent then
            screenGui = Instance.new("ScreenGui")
            screenGui.Name = "CustomScriptUI"
            screenGui.ResetOnSpawn = false
            screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            screenGui.Parent = player:WaitForChild("PlayerGui")
            trackObject(screenGui)
        end
        return screenGui
    end

    screenGui = ensureScreenGui()

    local function makeUIAboveAll(screenGui)
        screenGui.DisplayOrder = 9999
        local function setZIndexRecursive(obj, z)
            if obj:IsA("GuiObject") then
                obj.ZIndex = z
            end
            for _, child in ipairs(obj:GetChildren()) do
                setZIndexRecursive(child, z)
            end
        end
        setZIndexRecursive(screenGui, 1000)
    end

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 600, 0, 400)
    mainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 1000
    mainFrame.Active = true
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
    makeDraggable(mainFrame)
    trackObject(mainFrame)

    local header = Instance.new("TextLabel", mainFrame)
    header.Size = UDim2.new(1, -70, 0, 30)
    header.Position = UDim2.new(0, 10, 0, 5)
    header.Text = headerText
    header.TextColor3 = Color3.new(1, 1, 1)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.SourceSansBold
    header.TextSize = 18
    header.TextXAlignment = Enum.TextXAlignment.Left
    trackObject(header)

    local closeButton = Instance.new("TextButton", mainFrame)
    closeButton.Text = "X"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Size = UDim2.new(0, 25, 0, 25)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 6)
    trackObject(closeButton)

    local confirmFrame = Instance.new("Frame", screenGui)
    confirmFrame.Size = UDim2.new(0, 300, 0, 120)
    confirmFrame.Position = UDim2.new(0.5, -150, 0.5, -60)
    confirmFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    confirmFrame.Visible = false
    Instance.new("UICorner", confirmFrame)
    trackObject(confirmFrame)

    local confirmText = Instance.new("TextLabel", confirmFrame)
    confirmText.Size = UDim2.new(1, -20, 0, 50)
    confirmText.Position = UDim2.new(0, 10, 0, 10)
    confirmText.Text = "Are you sure you want to close the UI?"
    confirmText.TextColor3 = Color3.new(1,1,1)
    confirmText.BackgroundTransparency = 1
    confirmText.Font = Enum.Font.SourceSansBold
    confirmText.TextSize = 16
    confirmText.TextWrapped = true
    confirmText.TextXAlignment = Enum.TextXAlignment.Center
    confirmText.TextYAlignment = Enum.TextYAlignment.Center
    trackObject(confirmText)

    local yesBtn = Instance.new("TextButton", confirmFrame)
    yesBtn.Size = UDim2.new(0.4, 0, 0.3, 0)
    yesBtn.Position = UDim2.new(0.05, 0, 0.6, 0)
    yesBtn.Text = "Yes"
    yesBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    yesBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", yesBtn)
    trackObject(yesBtn)

    local noBtn = Instance.new("TextButton", confirmFrame)
    noBtn.Size = UDim2.new(0.4, 0, 0.3, 0)
    noBtn.Position = UDim2.new(0.55, 0, 0.6, 0)
    noBtn.Text = "No"
    noBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    noBtn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", noBtn)
    trackObject(noBtn)

    trackConnection(closeButton.MouseButton1Click:Connect(function()
        confirmFrame.Visible = true
    end))

    local function closeUI()
        disconnectAll()
        destroyAll()
    end

    trackConnection(yesBtn.MouseButton1Click:Connect(closeUI))
    trackConnection(noBtn.MouseButton1Click:Connect(function()
        confirmFrame.Visible = false
    end))

    local minimizeButton = Instance.new("TextButton", mainFrame)
    minimizeButton.Text = "—"
    minimizeButton.Font = Enum.Font.GothamBold
    minimizeButton.Size = UDim2.new(0, 25, 0, 25)
    minimizeButton.Position = UDim2.new(1, -65, 0, 5)
    minimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    minimizeButton.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", minimizeButton)
    trackObject(minimizeButton)

    local minimizedFrame
    if not module.MinimizedFrame or not module.MinimizedFrame.Parent then
        minimizedFrame = Instance.new("ImageButton")
        minimizedFrame.Size = UDim2.new(0, 40, 0, 40)
        minimizedFrame.Position = UDim2.new(0.5, -20, 0.5, -20)
        minimizedFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        minimizedFrame.Visible = false
        Instance.new("UICorner", minimizedFrame)
        makeDraggable(minimizedFrame)
        minimizedFrame.Parent = screenGui

        local plusIcon = Instance.new("TextLabel", minimizedFrame)
        plusIcon.Size = UDim2.new(1, 0, 1, 0)
        plusIcon.Text = "+"
        plusIcon.TextColor3 = Color3.new(1,1,1)
        plusIcon.BackgroundTransparency = 1
        plusIcon.Font = Enum.Font.GothamBold
        plusIcon.TextSize = 24

        module.MinimizedFrame = minimizedFrame
    else
        minimizedFrame = module.MinimizedFrame
    end

    local function setMinimizedImage(assetId)
        if assetId and typeof(assetId) == "string" and assetId ~= "" then
            minimizedFrame.Image = "rbxassetid://" .. assetId
            minimizedFrame.ImageTransparency = 0
            minimizedFrame:FindFirstChildWhichIsA("TextLabel").Visible = false
        else
            minimizedFrame.Image = ""
            minimizedFrame:FindFirstChildWhichIsA("TextLabel").Visible = true
        end
    end

    trackConnection(minimizeButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        minimizedFrame.Visible = true
    end))

    trackConnection(minimizedFrame.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        minimizedFrame.Visible = false
    end))

    makeUIAboveAll(screenGui)

    local categoryFrame = Instance.new("ScrollingFrame", mainFrame)
    categoryFrame.Size = UDim2.new(0, 150, 1, -55)
    categoryFrame.Position = UDim2.new(0, 10, 0, 45)
    categoryFrame.CanvasSize = UDim2.new(0,0,0,0)
    categoryFrame.ScrollBarThickness = 4
    categoryFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    categoryFrame.BorderSizePixel = 0
    categoryFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", categoryFrame)
    trackObject(categoryFrame)

    local categoryLayout = Instance.new("UIListLayout")
    categoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
    categoryLayout.Padding = UDim.new(0, 6)
    categoryLayout.Parent = categoryFrame

    local contentFrame = Instance.new("Frame", mainFrame)
    contentFrame.Size = UDim2.new(1, -180, 1, -55)
    contentFrame.Position = UDim2.new(0, 170, 0, 45)
    contentFrame.BackgroundColor3 = Color3.fromRGB(35,35,35)
    contentFrame.BorderSizePixel = 0
    Instance.new("UICorner", contentFrame)
    trackObject(contentFrame)

    local contentScroll = Instance.new("ScrollingFrame", contentFrame)
    contentScroll.Size = UDim2.new(1, -10, 1, -10)
    contentScroll.Position = UDim2.new(0,5,0,5)
    contentScroll.BackgroundTransparency = 1
    contentScroll.BorderSizePixel = 0
    contentScroll.ScrollBarThickness = 6
    contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentScroll.CanvasSize = UDim2.new(0,0,0,0)
    trackObject(contentScroll)

    local categories = {}

    function module.CreateCategory(name)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -10, 0, 35)
        button.Text = name
        button.BackgroundColor3 = Color3.fromRGB(70,70,70)
        button.TextColor3 = Color3.new(1,1,1)
        button.Font = Enum.Font.SourceSans
        button.TextSize = 16
        Instance.new("UICorner", button)
        button.Parent = categoryFrame
        trackObject(button)

        local selectionBar = Instance.new("Frame", button)
        selectionBar.Size = UDim2.new(0, 4, 1, 0)
        selectionBar.Position = UDim2.new(0,0,0,0)
        selectionBar.BackgroundColor3 = Color3.fromRGB(255,0,255)
        selectionBar.Visible = false
        trackObject(selectionBar)

        local holder = Instance.new("Frame", contentScroll)
        holder.Size = UDim2.new(1,0,0,0)
        holder.BackgroundTransparency = 1
        holder.Visible = false
        trackObject(holder)

        local layout = Instance.new("UIListLayout", holder)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0,6)
        trackObject(layout)

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            holder.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
            contentScroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
        end)

        trackConnection(button.MouseButton1Click:Connect(function()
            for _, frame in ipairs(contentScroll:GetChildren()) do
                if frame:IsA("Frame") then
                    frame.Visible = false
                end
            end
            holder.Visible = true

            for _, btn in ipairs(categoryFrame:GetChildren()) do
                if btn:IsA("TextButton") then
                    local bar = btn:FindFirstChildWhichIsA("Frame")
                    if bar then bar.Visible = false end
                end
            end
            selectionBar.Visible = true
        end))

        table.insert(categories,{holder=holder,button=button,bar=selectionBar})
        return holder
    end

    function module.CreateToggle(text, parent, callback)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, -10, 0, 35)
        container.BackgroundColor3 = Color3.fromRGB(45,45,45)
        container.BorderSizePixel = 0
        Instance.new("UICorner", container)
        container.Parent = parent
        trackObject(container)

        local label = Instance.new("TextLabel", container)
        label.Size = UDim2.new(1, -50, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.Font = Enum.Font.SourceSans
        label.TextSize = 16
        label.TextColor3 = Color3.new(1,1,1)
        label.TextXAlignment = Enum.TextXAlignment.Left
        trackObject(label)

        local switch = Instance.new("Frame", container)
        switch.Size = UDim2.new(0, 40, 0, 20)
        switch.Position = UDim2.new(1, -45, 0.5, -10)
        switch.BackgroundColor3 = Color3.fromRGB(70,70,70)
        switch.BorderSizePixel = 0
        Instance.new("UICorner", switch).CornerRadius = UDim.new(1,0)
        trackObject(switch)

        local knob = Instance.new("Frame", switch)
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.Position = UDim2.new(0, 1, 0.5, -9)
        knob.BackgroundColor3 = Color3.fromRGB(200,200,200)
        knob.BorderSizePixel = 0
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
        trackObject(knob)

        local enabled = false
        local tweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        local function updateVisual()
            if enabled then
                TweenService:Create(switch, tweenInfo, {BackgroundColor3 = Color3.fromRGB(0,170,0)}):Play()
                TweenService:Create(knob, tweenInfo, {Position = UDim2.new(1, -19, 0.5, -9)}):Play()
            else
                TweenService:Create(switch, tweenInfo, {BackgroundColor3 = Color3.fromRGB(70,70,70)}):Play()
                TweenService:Create(knob, tweenInfo, {Position = UDim2.new(0, 1, 0.5, -9)}):Play()
            end
        end

        trackConnection(container.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local startPos = input.Position
                local moved = false
                local moveConn

                moveConn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.Change then
                        if (input.Position - startPos).Magnitude > 5 then
                            moved = true
                            moveConn:Disconnect()
                        end
                    elseif input.UserInputState == Enum.UserInputState.End then
                        if not moved then
                            enabled = not enabled
                            updateVisual()
                            if callback then callback(enabled) end
                        end
                        if moveConn.Connected then moveConn:Disconnect() end
                    end
                end)
            end
        end))

        updateVisual()
        return container
    end

    function module.CreateButton(text, parent, callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1,-10,0,35)
        button.Text = text
        button.BackgroundColor3 = Color3.fromRGB(60,60,60)
        button.TextColor3 = Color3.new(1,1,1)
        button.Font = Enum.Font.GothamBold
        button.TextSize = 16
        button.AutoButtonColor = false
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
        button.Parent = parent
        trackObject(button)

        local gradient = Instance.new("UIGradient", button)
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(80,80,80)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(50,50,50))
        })

        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        trackConnection(button.MouseEnter:Connect(function()
            TweenService:Create(button, tweenInfo, {BackgroundColor3 = Color3.fromRGB(90,90,90)}):Play()
        end))
        trackConnection(button.MouseLeave:Connect(function()
            TweenService:Create(button, tweenInfo, {BackgroundColor3 = Color3.fromRGB(60,60,60)}):Play()
        end))

        trackConnection(button.MouseButton1Click:Connect(function()
            local down = TweenService:Create(button, TweenInfo.new(0.1), {Size = UDim2.new(1,-12,0,33)})
            local up = TweenService:Create(button, TweenInfo.new(0.1), {Size = UDim2.new(1,-10,0,35)})
            down:Play()
            down.Completed:Connect(function()
                up:Play()
            end)
            if callback then callback() end
        end))

        return button
    end

    function module.CreatePlayerList(parentFrame)
        local selectedPlayer = "---"

        local container = Instance.new("Frame", parentFrame)
        container.Size = UDim2.new(1, -10, 0, 35)
        container.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        container.BorderSizePixel = 0
        container.ClipsDescendants = false
        Instance.new("UICorner", container)
        trackObject(container)

        local dropdownButton = Instance.new("TextButton", container)
        dropdownButton.Size = UDim2.new(1, -35, 1, 0)
        dropdownButton.Position = UDim2.new(0, 5, 0, 0)
        dropdownButton.Text = "Player: " .. selectedPlayer
        dropdownButton.TextColor3 = Color3.new(1, 1, 1)
        dropdownButton.Font = Enum.Font.Gotham
        dropdownButton.TextSize = 14
        dropdownButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        dropdownButton.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", dropdownButton)
        trackObject(dropdownButton)

        local reloadButton = Instance.new("TextButton", container)
        reloadButton.Size = UDim2.new(0, 25, 0, 25)
        reloadButton.Position = UDim2.new(1, -30, 0, 5)
        reloadButton.Text = "@"
        reloadButton.TextColor3 = Color3.new(1, 1, 1)
        reloadButton.Font = Enum.Font.Gotham
        reloadButton.TextSize = 16
        reloadButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
        Instance.new("UICorner", reloadButton)
        trackObject(reloadButton)

        local listFrame = Instance.new("ScrollingFrame")
        listFrame.Parent = parentFrame
        listFrame.Size = UDim2.new(1, -20, 0, 120)
        listFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        listFrame.BorderSizePixel = 0
        listFrame.ScrollBarThickness = 6
        listFrame.Visible = false
        listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        Instance.new("UICorner", listFrame)
        trackObject(listFrame)

        local layout = Instance.new("UIListLayout", listFrame)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 4)
        trackObject(layout)

        local function updateListPosition()
            local absPos = container.AbsolutePosition
            listFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + container.AbsoluteSize.Y)
        end

        local function refreshList()
            for _, child in ipairs(listFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end

            selectedPlayer = "---"
            dropdownButton.Text = "Player: " .. selectedPlayer

            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player then
                    local nameBtn = Instance.new("TextButton", listFrame)
                    nameBtn.Size = UDim2.new(1, 0, 0, 30)
                    nameBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
                    nameBtn.Text = p.Name
                    nameBtn.TextColor3 = Color3.new(1, 1, 1)
                    nameBtn.Font = Enum.Font.Gotham
                    nameBtn.TextSize = 14
                    Instance.new("UICorner", nameBtn)
                    trackObject(nameBtn)

                    trackConnection(nameBtn.MouseButton1Click:Connect(function()
                        selectedPlayer = p.Name
                        dropdownButton.Text = "Player: " .. selectedPlayer
                        listFrame.Visible = false
                    end))
                end
            end
        end

        trackConnection(dropdownButton.MouseButton1Click:Connect(function()
            listFrame.Visible = not listFrame.Visible
            if listFrame.Visible then
                updateListPosition()
            end
        end))

        trackConnection(reloadButton.MouseButton1Click:Connect(refreshList))

        refreshList()

        return {
            Container = container,
            GetSelected = function()
                return Players:FindFirstChild(selectedPlayer)
            end
        }
    end

    makeUIAboveAll(screenGui)

    local function openFirstCategory()
        if #categories > 0 then
            for _, cat in ipairs(categories) do
                cat.holder.Visible = false
                cat.bar.Visible = false
            end
            categories[1].holder.Visible = true
            categories[1].bar.Visible = true
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
        Close = closeUI,
        SetMinimizedImage = setMinimizedImage,
        OpenFirstCategory = openFirstCategory,
        Categories = categories,
        Hide = function()
            mainFrame.Visible = false
            minimizedFrame.Visible = true
        end,
        Show = function()
            mainFrame.Visible = true
            minimizedFrame.Visible = false
        end
    }
end

return module
