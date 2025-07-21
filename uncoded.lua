return function()
    local CoreGui = game:GetService("CoreGui")
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local dragging, dragInput, dragStart, startPos

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

        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    local gui = Instance.new("ScreenGui", CoreGui)
    gui.Name = "DeltaUI"

    local main = Instance.new("Frame", gui)
    main.Size = UDim2.new(0, 500, 0, 400)
    main.Position = UDim2.new(0.5, -250, 0.5, -200)
    main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    main.BorderSizePixel = 0

    local corner = Instance.new("UICorner", main)
    corner.CornerRadius = UDim.new(0, 8)

    makeDraggable(main)

    -- header bar
    local topBar = Instance.new("Frame", main)
    topBar.Size = UDim2.new(1, 0, 0, 28)
    topBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    topBar.BorderSizePixel = 0
    makeDraggable(topBar)

    local close = Instance.new("TextButton", topBar)
    close.Size = UDim2.new(0, 28, 1, 0)
    close.Position = UDim2.new(1, -28, 0, 0)
    close.Text = "X"
    close.BackgroundColor3 = Color3.fromRGB(170, 30, 30)
    close.TextColor3 = Color3.new(1, 1, 1)
    close.Font = Enum.Font.SourceSansBold
    close.TextSize = 16
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 4)

    local minimize = Instance.new("TextButton", topBar)
    minimize.Size = UDim2.new(0, 28, 1, 0)
    minimize.Position = UDim2.new(1, -56, 0, 0)
    minimize.Text = "_"
    minimize.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    minimize.TextColor3 = Color3.new(1, 1, 1)
    minimize.Font = Enum.Font.SourceSansBold
    minimize.TextSize = 16
    Instance.new("UICorner", minimize).CornerRadius = UDim.new(0, 4)

    local scroll = Instance.new("ScrollingFrame", main)
    scroll.Size = UDim2.new(1, 0, 1, -28)
    scroll.Position = UDim2.new(0, 0, 0, 28)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 6

    local list = Instance.new("UIListLayout", scroll)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 6)

    -- mini icon
    local mini = Instance.new("TextButton")
    mini.Size = UDim2.new(0, 100, 0, 30)
    mini.Position = UDim2.new(0.5, -50, 0.5, -15)
    mini.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    mini.Text = "Delta UI"
    mini.TextColor3 = Color3.new(1, 1, 1)
    mini.Font = Enum.Font.SourceSansBold
    mini.TextSize = 14
    mini.Visible = false
    mini.Parent = gui
    Instance.new("UICorner", mini).CornerRadius = UDim.new(0, 6)

    makeDraggable(mini)

    minimize.MouseButton1Click:Connect(function()
        main.Visible = false
        mini.Visible = true
    end)

    mini.MouseButton1Click:Connect(function()
        main.Visible = true
        mini.Visible = false
    end)

    close.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    local Modules = {}

    function Modules.CreateCategory(Name)
        local Category = Instance.new("Frame")
        Category.Size = UDim2.new(1, -12, 0, 28)
        Category.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        Category.Parent = scroll

        local CategoryText = Instance.new("TextLabel", Category)
        CategoryText.Text = Name
        CategoryText.Font = Enum.Font.SourceSansBold
        CategoryText.TextSize = 18
        CategoryText.TextColor3 = Color3.fromRGB(255, 255, 255)
        CategoryText.Size = UDim2.new(1, -10, 1, 0)
        CategoryText.Position = UDim2.new(0, 5, 0, 0)
        CategoryText.BackgroundTransparency = 1
        CategoryText.TextXAlignment = Enum.TextXAlignment.Left

        local Container = Instance.new("Frame", scroll)
        Container.Size = UDim2.new(1, -12, 0, 0)
        Container.BackgroundTransparency = 1
        Container.AutomaticSize = Enum.AutomaticSize.Y

        local Layout = Instance.new("UIListLayout", Container)
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Padding = UDim.new(0, 4)

        return Container
    end

    function Modules.CreateButton(Parent, ButtonText, Callback)
        local ButtonFrame = Instance.new("Frame", Parent)
        ButtonFrame.Size = UDim2.new(1, 0, 0, 28)
        ButtonFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

        local Label = Instance.new("TextLabel", ButtonFrame)
        Label.Text = ButtonText
        Label.Font = Enum.Font.SourceSans
        Label.TextSize = 16
        Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        Label.Size = UDim2.new(0.7, 0, 1, 0)
        Label.BackgroundTransparency = 1
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Position = UDim2.new(0, 8, 0, 0)

        local Button = Instance.new("TextButton", ButtonFrame)
        Button.Size = UDim2.new(0.25, -8, 0.8, 0)
        Button.Position = UDim2.new(0.75, 0, 0.1, 0)
        Button.Text = "Кнопка"
        Button.Font = Enum.Font.SourceSansBold
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
        Button.TextSize = 14

        local Corner = Instance.new("UICorner", Button)
        Corner.CornerRadius = UDim.new(0, 4)

        Button.MouseButton1Click:Connect(function()
            if type(Callback) == "function" then
                Callback()
            end
        end)
    end

    function Modules.CreateToggle(Parent, ToggleText, StateChanged)
        local Toggle = Instance.new("Frame", Parent)
        Toggle.Size = UDim2.new(1, 0, 0, 28)
        Toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

        local Label = Instance.new("TextLabel", Toggle)
        Label.Text = ToggleText
        Label.Font = Enum.Font.SourceSans
        Label.TextSize = 16
        Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        Label.Size = UDim2.new(0.7, 0, 1, 0)
        Label.BackgroundTransparency = 1
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Position = UDim2.new(0, 8, 0, 0)

        local Btn = Instance.new("TextButton", Toggle)
        Btn.Size = UDim2.new(0.25, -8, 0.8, 0)
        Btn.Position = UDim2.new(0.75, 0, 0.1, 0)
        Btn.Text = "OFF"
        Btn.Font = Enum.Font.SourceSansBold
        Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Btn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        Btn.TextSize = 14

        local Corner = Instance.new("UICorner", Btn)
        Corner.CornerRadius = UDim.new(0, 4)

        local state = false
        Btn.MouseButton1Click:Connect(function()
            state = not state
            Btn.Text = state and "ON" or "OFF"
            Btn.BackgroundColor3 = state and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
            if type(StateChanged) == "function" then
                StateChanged(state)
            end
        end)
    end

    function Modules.CreateInputInt(Parent, LabelText, OnChange)
        local InputFrame = Instance.new("Frame", Parent)
        InputFrame.Size = UDim2.new(1, 0, 0, 28)
        InputFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

        local Label = Instance.new("TextLabel", InputFrame)
        Label.Text = LabelText
        Label.Font = Enum.Font.SourceSans
        Label.TextSize = 16
        Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        Label.Size = UDim2.new(0.7, 0, 1, 0)
        Label.BackgroundTransparency = 1
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Position = UDim2.new(0, 8, 0, 0)

        local TextBox = Instance.new("TextBox", InputFrame)
        TextBox.Size = UDim2.new(0.25, -8, 0.8, 0)
        TextBox.Position = UDim2.new(0.75, 0, 0.1, 0)
        TextBox.Font = Enum.Font.SourceSansBold
        TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        TextBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        TextBox.TextSize = 14
        TextBox.Text = "0"

        local Corner = Instance.new("UICorner", TextBox)
        Corner.CornerRadius = UDim.new(0, 4)

        TextBox.FocusLost:Connect(function()
            local val = tonumber(TextBox.Text)
            if val and OnChange then
                OnChange(val)
            else
                TextBox.Text = "0"
            end
        end)
    end

    return Modules
end
