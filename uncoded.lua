local module = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local function makeDraggable(frame)
local dragging = false
local dragInput, dragStart, startPos

frame.InputBegan:Connect(function(input)  
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then  
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
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then  
        dragInput = input  
    end  
end)  

UserInputService.InputChanged:Connect(function(input)  
    if input == dragInput and dragging then  
        local delta = input.Position - dragStart  
        frame.Position = UDim2.new(  
            startPos.X.Scale,  
            startPos.X.Offset + delta.X,  
            startPos.Y.Scale,  
            startPos.Y.Offset + delta.Y  
        )  
    end  
end)

end

function module.CreateUI(title)
local headerText = title or "Unnamed UI"

local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))  
screenGui.Name = "CustomScriptUI"  
screenGui.ResetOnSpawn = false    
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

local mainFrame = Instance.new("Frame")  
mainFrame.Size = UDim2.new(0, 600, 0, 400)  
mainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)  
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)  
mainFrame.BorderSizePixel = 0  
mainFrame.ZIndex = 1000  
mainFrame.Active = true  
mainFrame.Draggable = false  
mainFrame.Parent = screenGui  
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)  
makeDraggable(mainFrame)  

local header = Instance.new("TextLabel", mainFrame)  
header.Size = UDim2.new(1, -70, 0, 30)  
header.Position = UDim2.new(0, 10, 0, 5)  
header.Text = headerText  
header.TextColor3 = Color3.new(1, 1, 1)  
header.BackgroundTransparency = 1  
header.Font = Enum.Font.SourceSansBold  
header.TextSize = 18  
header.TextXAlignment = Enum.TextXAlignment.Left  

local closeButton = Instance.new("TextButton", mainFrame)  
closeButton.Text = "X"  
closeButton.Font = Enum.Font.GothamBold  
closeButton.Size = UDim2.new(0, 25, 0, 25)  
closeButton.Position = UDim2.new(1, -35, 0, 5)  
closeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)  
closeButton.TextColor3 = Color3.new(1, 1, 1)  
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 6)  

local minimizeButton = Instance.new("TextButton", mainFrame)  
minimizeButton.Text = "—"  
minimizeButton.Font = Enum.Font.GothamBold  
minimizeButton.Size = UDim2.new(0, 25, 0, 25)  
minimizeButton.Position = UDim2.new(1, -65, 0, 5)  
minimizeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)  
minimizeButton.TextColor3 = Color3.new(1, 1, 1)  
Instance.new("UICorner", minimizeButton)  

local categoryFrame = Instance.new("ScrollingFrame", mainFrame)  
categoryFrame.Name = "CategoryFrame"  
categoryFrame.Size = UDim2.new(0, 150, 1, -55)  
categoryFrame.Position = UDim2.new(0, 10, 0, 45)  
categoryFrame.CanvasSize = UDim2.new(0, 0, 0, 600)  
categoryFrame.ScrollBarThickness = 4  
categoryFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)  
categoryFrame.BorderSizePixel = 0  
categoryFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y  
Instance.new("UICorner", categoryFrame)  
local categoryLayout = Instance.new("UIListLayout", categoryFrame)  
categoryLayout.Padding = UDim.new(0, 6)  
categoryLayout.SortOrder = Enum.SortOrder.LayoutOrder  

local contentFrame = Instance.new("Frame", mainFrame)  
contentFrame.Name = "ContentFrame"  
contentFrame.Size = UDim2.new(1, -180, 1, -55)  
contentFrame.Position = UDim2.new(0, 170, 0, 45)  
contentFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)  
contentFrame.BorderSizePixel = 0  
Instance.new("UICorner", contentFrame)  

local contentScroll = Instance.new("ScrollingFrame", contentFrame)  
contentScroll.Size = UDim2.new(1, -10, 1, -10)  
contentScroll.Position = UDim2.new(0, 5, 0, 5)  
contentScroll.BackgroundTransparency = 1  
contentScroll.BorderSizePixel = 0  
contentScroll.ScrollBarThickness = 6  
contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y  
contentScroll.CanvasSize = UDim2.new(0, 0, 0, 600)  
local contentLayout = Instance.new("UIListLayout", contentScroll)  
contentLayout.Padding = UDim.new(0, 6)  
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder  

local minimizedFrame = Instance.new("ImageButton", screenGui)  
minimizedFrame.Size = UDim2.new(0, 40, 0, 40)  
minimizedFrame.Position = UDim2.new(0.5, -20, 0.5, -20)  
minimizedFrame.Image = ""  
minimizedFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)  
minimizedFrame.Visible = false  
Instance.new("UICorner", minimizedFrame)  
makeDraggable(minimizedFrame)  

local plusIcon = Instance.new("TextLabel", minimizedFrame)  
plusIcon.Text = "+"  
plusIcon.Size = UDim2.new(1, 0, 1, 0)  
plusIcon.TextColor3 = Color3.new(1, 1, 1)  
plusIcon.BackgroundTransparency = 1  
plusIcon.Font = Enum.Font.GothamBold  
plusIcon.TextSize = 24  

function module.SetMinimizedImage(assetId)  
    if assetId and typeof(assetId) == "string" and assetId ~= "" then  
        minimizedFrame.Image = "rbxassetid://" .. assetId  
        plusIcon.Visible = false  
    else  
        minimizedFrame.Image = ""  
        plusIcon.Visible = true  
    end  
end  

closeButton.MouseButton1Click:Connect(function()  
    screenGui:Destroy()  
end)  

minimizeButton.MouseButton1Click:Connect(function()  
    mainFrame.Visible = false  
    minimizedFrame.Visible = true  
end)  

minimizedFrame.MouseButton1Click:Connect(function()  
    mainFrame.Visible = true  
    minimizedFrame.Visible = false  
end)  

local categories = {}  

function module.CreateToggle(text, parent, callback)  
    local button = Instance.new("TextButton")  
    button.Size = UDim2.new(1, -10, 0, 35)  
    button.Text = text  
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)  
    button.TextColor3 = Color3.new(1, 1, 1)  
    button.Font = Enum.Font.SourceSans  
    button.TextSize = 16  
    Instance.new("UICorner", button)  
    button.Parent = parent  

    local enabled = false  
    button.MouseButton1Click:Connect(function()  
        enabled = not enabled  
        button.BackgroundColor3 = enabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)  
        if callback then callback(enabled) end  
    end)  

    return button  
end  

function module.CreateCategory(name)  
    local button = Instance.new("TextButton")  
    button.Size = UDim2.new(1, -10, 0, 35)  
    button.Text = name  
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)  
    button.TextColor3 = Color3.new(1, 1, 1)  
    button.Font = Enum.Font.SourceSans  
    button.TextSize = 16  
    Instance.new("UICorner", button)  
    button.Parent = categoryFrame  

    local selectionBar = Instance.new("Frame")  
    selectionBar.Size = UDim2.new(0, 4, 1, 0)  
    selectionBar.Position = UDim2.new(0, 0, 0, 0)  
    selectionBar.BackgroundColor3 = Color3.fromRGB(255, 0, 255)  
    selectionBar.Visible = false  
    selectionBar.Parent = button  

    local holder = Instance.new("Frame", contentScroll)  
    holder.Size = UDim2.new(1, 0, 0, 0)  
    holder.BackgroundTransparency = 1  
    holder.Visible = false  
    local layout = Instance.new("UIListLayout", holder)  
    layout.SortOrder = Enum.SortOrder.LayoutOrder  
    layout.Padding = UDim.new(0, 6)  

    button.MouseButton1Click:Connect(function()  
        for _, frame in ipairs(contentScroll:GetChildren()) do  
            if frame:IsA("Frame") then  
                frame.Visible = false  
            end  
        end  
        holder.Visible = true  

        for _, btn in ipairs(categoryFrame:GetChildren()) do  
            if btn:IsA("TextButton") then  
                local bar = btn:FindFirstChildWhichIsA("Frame")  
                if bar then  
                    bar.Visible = false  
                end  
            end  
        end  
        selectionBar.Visible = true  
    end)  

    table.insert(categories, {holder = holder, button = button, bar = selectionBar})  

    return holder  
end  

local function openFirstCategory()  
    if #categories > 0 then  
        categories[1].holder.Visible = true  
        categories[1].bar.Visible = true  
    end  
end  

function module.CreatePlayerList(parentFrame)  
    local selectedPlayer = "---"  

    local container = Instance.new("Frame", parentFrame)  
    container.Size = UDim2.new(1, -10, 0, 35)  
    container.BackgroundColor3 = Color3.fromRGB(45, 45, 45)  
    container.BorderSizePixel = 0  
    container.ClipsDescendants = false  
    Instance.new("UICorner", container)  

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

    local reloadButton = Instance.new("TextButton", container)  
    reloadButton.Size = UDim2.new(0, 25, 0, 25)  
    reloadButton.Position = UDim2.new(1, -30, 0, 5)  
    reloadButton.Text = "@"  
    reloadButton.TextColor3 = Color3.new(1, 1, 1)  
    reloadButton.Font = Enum.Font.Gotham  
    reloadButton.TextSize = 16  
    reloadButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)  
    Instance.new("UICorner", reloadButton)  

    local listFrame = Instance.new("ScrollingFrame")  
    listFrame.Parent = parentFrame  
    listFrame.Size = UDim2.new(1, -20, 0, 120)  
    listFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)  
    listFrame.BorderSizePixel = 0  
    listFrame.ScrollBarThickness = 6  
    listFrame.Visible = false  
    listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y  
    listFrame.CanvasSize = UDim2.new(0, 0, 0, 600)  
    listFrame.ZIndex = 10  
    Instance.new("UICorner", listFrame)  

    local layout = Instance.new("UIListLayout", listFrame)  
    layout.SortOrder = Enum.SortOrder.LayoutOrder  
    layout.Padding = UDim.new(0, 4)  

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

                nameBtn.MouseButton1Click:Connect(function()  
                    selectedPlayer = p.Name  
                    dropdownButton.Text = "Player: " .. selectedPlayer  
                    listFrame.Visible = false  
                end)  
            end  
        end  
    end  

    dropdownButton.MouseButton1Click:Connect(function()  
        listFrame.Visible = not listFrame.Visible  
        if listFrame.Visible then  
            updateListPosition()  
        end  
    end)  

    reloadButton.MouseButton1Click:Connect(refreshList)  

    refreshList()  

    return {  
        Container = container,  
        GetSelected = function()  
            return Players:FindFirstChild(selectedPlayer)  
        end  
    }  
end  
  
function module.CreateButton(text, parentFrame, callback)  
    local button = Instance.new("TextButton")  
    button.Size = UDim2.new(1, -10, 0, 35)  
    button.Text = text  
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)  
    button.TextColor3 = Color3.new(1, 1, 1)  
    button.Font = Enum.Font.SourceSansBold  
    button.TextSize = 16  
    Instance.new("UICorner", button)  
    button.Parent = parentFrame  

    button.MouseButton1Click:Connect(function()  
        if callback then  
            callback()  
        end  
    end)  

    return button  
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
    Close = function() screenGui:Destroy() end,  
    Hide = function()  
        mainFrame.Visible = false  
        minimizedFrame.Visible = true  
    end,  
    Show = function()  
        mainFrame.Visible = true  
        minimizedFrame.Visible = false  
    end,  
    SetMinimizedImage = module.SetMinimizedImage,  
    OpenFirstCategory = openFirstCategory,  
    Categories = categories,  
}

end

return module
