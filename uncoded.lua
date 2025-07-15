local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

local gui_framework = {}

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

    local minimizedBtn = Instance.new("TextButton")
    minimizedBtn.Size = UDim2.new(0, 30, 0, 30)
    minimizedBtn.Position = UDim2.new(1, -70, 0, 5)
    minimizedBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 0)
    minimizedBtn.Text = "-"
    minimizedBtn.TextColor3 = Color3.new(1, 1, 1)
    minimizedBtn.Font = self.Theme.Font
    minimizedBtn.TextSize = 18
    apply_rounding(minimizedBtn)
    minimizedBtn.Parent = main

    local restoreBtn = Instance.new("TextButton")
    restoreBtn.Size = UDim2.new(0, 50, 0, 50)
    restoreBtn.Position = UDim2.new(0.5, -25, 0.5, -25)
    restoreBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    restoreBtn.Text = "+"
    restoreBtn.TextColor3 = Color3.new(1, 1, 1)
    restoreBtn.Font = self.Theme.Font
    restoreBtn.TextSize = 30
    apply_rounding(restoreBtn)
    restoreBtn.Parent = gui
    restoreBtn.Visible = false
    restoreBtn.Active = true
    restoreBtn.Draggable = true

    restoreBtn.MouseButton1Click:Connect(function()
        main.Visible = true
        restoreBtn.Visible = false
    end)

    minimizedBtn.MouseButton1Click:Connect(function()
        main.Visible = false
        restoreBtn.Visible = true
    end)

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
    return btn
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
        pcall(function()
            if callback then callback(state) end
        end)
    end)

    return toggle, function() return state end
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

    local container = Instance.new("ScrollingFrame")
    container.Size = UDim2.new(1, -10, 0, 100)
    container.Position = UDim2.new(0, 5, 0, 35)
    container.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    container.ScrollBarThickness = 6
    container.Visible = false
    container.ClipsDescendants = true
    container.AutomaticCanvasSize = Enum.AutomaticSize.Y
    apply_rounding(container)
    container.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = container

    for _, item in ipairs(list) do
        local option = Instance.new("TextButton")
        option.Size = UDim2.new(1, 0, 0, 25)
        option.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        option.Text = item
        option.TextColor3 = Color3.new(1, 1, 1)
        option.Font = self.Theme.Font
        option.TextSize = 14
        option.Parent = container

        option.MouseButton1Click:Connect(function()
            dropdown.Text = item
            container.Visible = false
            if callback then callback(item) end
        end)
    end

    dropdown.MouseButton1Click:Connect(function()
        container.Visible = not container.Visible
    end)

    return dropdown, container
end

function gui_framework:CreatePlayerDropdown(parent, callback)
    local dropdown = Instance.new("TextButton")
    dropdown.Size = UDim2.new(1, -40, 0, 30)
    dropdown.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    dropdown.Text = "Select..."
    dropdown.Font = self.Theme.Font
    dropdown.TextColor3 = self.Theme.TextColor
    dropdown.TextSize = 14
    apply_rounding(dropdown)
    dropdown.Parent = parent
    dropdown.LayoutOrder = 0

    local container = Instance.new("ScrollingFrame")
    container.Size = UDim2.new(1, -10, 0, 100)
    container.Position = UDim2.new(0, 5, 0, 35)
    container.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    container.ScrollBarThickness = 6
    container.Visible = false
    container.AutomaticCanvasSize = Enum.AutomaticSize.Y
    container.ClipsDescendants = true
    apply_rounding(container)
    container.Parent = parent

    local layout
    local function createLayout()
        if layout then layout:Destroy() end
        layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 2)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = container
    end

    local function refreshPlayers()
        container:ClearAllChildren()
        createLayout()

        local players = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                table.insert(players, p.Name)
            end
        end

        if not table.find(players, dropdown.Text) then
            dropdown.Text = "Select..."
        end

        for _, name in ipairs(players) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 25)
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            btn.Text = name
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Font = self.Theme.Font
            btn.TextSize = 14
            btn.Parent = container

            btn.MouseButton1Click:Connect(function()
                dropdown.Text = name
                container.Visible = false
                if callback then callback(name) end
            end)
        end
    end

    refreshPlayers()

    dropdown.MouseButton1Click:Connect(function()
        container.Visible = not container.Visible
    end)

    local refreshButton = Instance.new("TextButton")
    refreshButton.Size = UDim2.new(0, 30, 0, 30)
    refreshButton.Position = UDim2.new(1, -30, 0, 0)
    refreshButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
    refreshButton.Text = "↻"
    refreshButton.Font = self.Theme.Font
    refreshButton.TextColor3 = Color3.new(1, 1, 1)
    refreshButton.TextSize = 16
    apply_rounding(refreshButton)
    refreshButton.Parent = parent
    refreshButton.LayoutOrder = 1

    refreshButton.MouseButton1Click:Connect(function()
        refreshPlayers()
    end)

    return dropdown, refreshButton
end

function gui_framework:CreateSlider(parent, minValue, maxValue, defaultValue, callback)
    -- safe log wrapper to prevent errors if log not defined
    local function safe_log(msg)
        if type(log) == "function" then
            pcall(log, msg)
        end
    end

    minValue = math.floor(tonumber(minValue) or 1)
    maxValue = math.floor(tonumber(maxValue) or 99999)
    defaultValue = math.clamp(math.floor(tonumber(defaultValue) or minValue), minValue, maxValue)

    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -10, 0, 40)
    holder.BackgroundTransparency = 1
    holder.Parent = parent
    holder.LayoutOrder = 0

    local slider = Instance.new("TextButton")
    slider.Size = UDim2.new(0.7, -5, 1, 0)
    slider.Position = UDim2.new(0, 0, 0, 0)
    slider.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    slider.Text = ""
    slider.AutoButtonColor = false
    apply_rounding(slider)
    slider.Parent = holder

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0.3, 0)
    bar.Position = UDim2.new(0, 0, 0.5, -5)
    bar.AnchorPoint = Vector2.new(0, 0.5)
    bar.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    apply_rounding(bar)
    bar.Parent = slider

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defaultValue - minValue) / (maxValue - minValue), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    fill.BorderSizePixel = 0
    apply_rounding(fill)
    fill.Parent = bar

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(0.3, 0, 1, 0)
    input.Position = UDim2.new(0.7, 5, 0, 0)
    input.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    input.Text = tostring(defaultValue)
    input.ClearTextOnFocus = false
    input.Font = self.Theme.Font
    input.TextColor3 = self.Theme.TextColor
    input.TextSize = 14
    input.TextXAlignment = Enum.TextXAlignment.Center
    apply_rounding(input)
    input.Parent = holder

    local currentValue = defaultValue

    local function updateSlider(val)
        currentValue = math.clamp(math.floor(val), minValue, maxValue)
        input.Text = tostring(currentValue)
        local ratio = 0
        if maxValue - minValue > 0 then
            ratio = (currentValue - minValue) / (maxValue - minValue)
        end
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        safe_log("Slider set to: " .. currentValue)
        if callback then
            pcall(function() callback(currentValue) end)
        end
    end

    slider.InputBegan:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 then
            safe_log("Slider input started")
            local conn
            conn = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    local relX = input.Position.X - bar.AbsolutePosition.X
                    local barWidth = bar.AbsoluteSize.X
                    if barWidth > 0 then
                        local percent = math.clamp(relX / barWidth, 0, 1)
                        local val = math.floor(minValue + (maxValue - minValue) * percent + 0.5)
                        updateSlider(val)
                    end
                end
            end)
            local endConn
            endConn = UserInputService.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == Enum.UserInputType.MouseButton1 then
                    safe_log("Slider input ended")
                    if conn then conn:Disconnect() end
                    if endConn then endConn:Disconnect() end
                end
            end)
        end
    end)

    input.FocusLost:Connect(function()
        local val = tonumber(input.Text)
        if val then
            updateSlider(val)
        else
            safe_log("Invalid input in slider text box, reverting")
            input.Text = tostring(currentValue)
        end
    end)

    updateSlider(defaultValue)

    return holder
end

function gui_framework:CheckGameId(expected)
    return game.GameId == expected
end

return gui_framework
