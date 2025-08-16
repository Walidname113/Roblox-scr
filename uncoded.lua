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

    local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    screenGui.Name = "CustomScriptUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    trackObject(screenGui)

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

    local minimizedFrame = Instance.new("ImageButton", screenGui)
    minimizedFrame.Size = UDim2.new(0, 40, 0, 40)
    minimizedFrame.Position = UDim2.new(0.5, -20, 0.5, -20)
    minimizedFrame.Image = ""
    minimizedFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    minimizedFrame.Visible = false
    Instance.new("UICorner", minimizedFrame)
    makeDraggable(minimizedFrame)
    trackObject(minimizedFrame)

    local plusIcon = Instance.new("TextLabel", minimizedFrame)
    plusIcon.Text = "+"
    plusIcon.Size = UDim2.new(1, 0, 1, 0)
    plusIcon.TextColor3 = Color3.new(1,1,1)
    plusIcon.BackgroundTransparency = 1
    plusIcon.Font = Enum.Font.GothamBold
    plusIcon.TextSize = 24
    trackObject(plusIcon)

    trackConnection(minimizeButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        minimizedFrame.Visible = true
    end))

    trackConnection(minimizedFrame.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        minimizedFrame.Visible = false
    end))

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

    function module.CreateToggle(text,parent,callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -10, 0, 35)
        button.Text = text
        button.BackgroundColor3 = Color3.fromRGB(60,60,60)
        button.TextColor3 = Color3.new(1,1,1)
        button.Font = Enum.Font.SourceSans
        button.TextSize = 16
        Instance.new("UICorner", button)
        button.Parent = parent
        trackObject(button)

        local enabled = false
        trackConnection(button.MouseButton1Click:Connect(function()
            enabled = not enabled
            button.BackgroundColor3 = enabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(60,60,60)
            if callback then callback(enabled) end
        end))

        return button
    end

    function module.CreateButton(text,parent,callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1,-10,0,35)
        button.Text = text
        button.BackgroundColor3 = Color3.fromRGB(60,60,60)
        button.TextColor3 = Color3.new(1,1,1)
        button.Font = Enum.Font.SourceSansBold
        button.TextSize = 16
        Instance.new("UICorner", button)
        button.Parent = parent
        trackObject(button)

        if callback then
            trackConnection(button.MouseButton1Click:Connect(callback))
        end

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
        Hide = function()
            mainFrame.Visible = false
            minimizedFrame.Visible = true
        end,
        Show = function()
            mainFrame.Visible = true
            minimizedFrame.Visible = false
        end,
        SetMinimizedImage = function(assetId)
            if assetId and typeof(assetId) == "string" and assetId ~= "" then
                minimizedFrame.Image = "rbxassetid://" .. assetId
                plusIcon.Visible = false
            else
                minimizedFrame.Image = ""
                plusIcon.Visible = true
            end
        end,
        OpenFirstCategory = openFirstCategory,
        Categories = categories
    }
end

return module
