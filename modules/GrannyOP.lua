local requiredGameId = 2165551367
if game.GameId ~= requiredGameId then return end

local uiurl = "https://raw.githubusercontent.com/Walidname113/Roblox-scr/main/uncoded.lua"
local success, source = pcall(function()
    return game:HttpGet(uiurl)
end)
if not success then warn("Error load UI:", source) return end
local moduleFunc, err = loadstring(source)
if not moduleFunc then warn("Error module func:", err) return end

local uiModule = moduleFunc()
local ui = uiModule.CreateUI("Granny by Kiyatsuka | Version: 1.0.3 Public")

function ui.CreateToggleWithInput(title, parent, data)  
    local container = Instance.new("Frame")  
    container.Size = UDim2.new(1, 0, 0, 30)  
    container.BackgroundTransparency = 1  
    container.Parent = parent  
  
    local toggle = Instance.new("TextButton")  
    toggle.Size = UDim2.new(0, 100, 1, 0)  
    toggle.Position = UDim2.new(0, 0, 0, 0)  
    toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)  
    toggle.TextColor3 = Color3.new(1, 1, 1)  
    toggle.Text = title  
    toggle.Parent = container  
  
    local input = Instance.new("TextBox")  
    input.Size = UDim2.new(0, 60, 1, 0)  
    input.Position = UDim2.new(0, 110, 0, 0)  
    input.BackgroundColor3 = Color3.fromRGB(30, 30, 30)  
    input.TextColor3 = Color3.new(1, 1, 1)  
    input.Text = type(data.default) == "function" and data.default() or (data.default or "")  
    input.Parent = container  
  
    local reset = Instance.new("TextButton")  
    reset.Size = UDim2.new(0, 30, 1, 0)  
    reset.Position = UDim2.new(0, 180, 0, 0)  
    reset.BackgroundColor3 = Color3.fromRGB(80, 30, 30)  
    reset.TextColor3 = Color3.new(1, 1, 1)  
    reset.Text = "X"  
    reset.Parent = container  
  
    local state = false  
  
    toggle.MouseButton1Click:Connect(function()  
        state = not state  
        toggle.BackgroundColor3 = state and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(50, 50, 50)  
        if data.onToggle then  
            data.onToggle(state, input.Text)  
        end  
    end)  
  
    input.FocusLost:Connect(function()  
        if data.onToggle then  
            data.onToggle(state, input.Text)  
        end  
    end)  
  
    reset.MouseButton1Click:Connect(function()  
        input.Text = type(data.default) == "function" and data.default() or (data.default or "")  
        if data.reset then  
            data.reset()  
        end  
    end)  
  
    return container  
end

local highlightsMap = {} -- [object] = {highlight, type="player"/"tool"/etc}

local function addHighlight(obj, espType, color, extra)
    if not obj or not obj.Parent then return end
    local old = highlightsMap[obj]
    if old then
        old.highlight:Destroy()
        local bb = obj:FindFirstChild("ToolESP_Billboard")
        if bb then bb:Destroy() end
        highlightsMap[obj] = nil
    end
    local hl = Instance.new("Highlight")
    hl.Adornee = obj
    hl.FillColor = color
    hl.FillTransparency = extra and extra.FillTransparency or 1
    hl.OutlineColor = color
    hl.OutlineTransparency = extra and extra.OutlineTransparency or 0
    hl.Parent = obj
    highlightsMap[obj] = {highlight = hl, type = espType}
end

local function removeHighlight(obj)
    if highlightsMap[obj] then
        highlightsMap[obj].highlight:Destroy()
        highlightsMap[obj] = nil
    end
    local bb = obj:FindFirstChild("ToolESP_Billboard")
    if bb then bb:Destroy() end
end

local function clearESPByType(t)
    for obj, data in pairs(highlightsMap) do
        if data.type == t then
            data.highlight:Destroy()
            local bb = obj:FindFirstChild("ToolESP_Billboard")
            if bb then bb:Destroy() end
            highlightsMap[obj] = nil
        end
    end
end

local player = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local mainContainer = ui.CreateCategory("Main")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

local noclipConnection
local originalCameraMode
local originalWalkSpeed
local originalJumpPower
local infinityJumpEnabled = false

local function showJumpButton()
    local touchGui = player:WaitForChild("PlayerGui"):FindFirstChild("TouchGui")
    if touchGui then
        local jumpButton = touchGui:FindFirstChild("JumpButton", true)
        if jumpButton then
            jumpButton.Visible = true
        end
    end
end

local function cacheOriginalValues()
    task.wait(1)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        originalWalkSpeed = humanoid.WalkSpeed
        originalJumpPower = humanoid.JumpPower
    end
    if not originalCameraMode then
        originalCameraMode = player.CameraMode
    end
end

if player.Character then
    cacheOriginalValues()
else
    player.CharacterAdded:Once(cacheOriginalValues)
end

player.CharacterAdded:Connect(function()
    task.wait(1)
    if noclipConnection then enableNoclip() end
    cacheOriginalValues()
end)

local function enableNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        local char = player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

ui.CreateToggle("Noclip", mainContainer, function(state)
    if state then
        enableNoclip()
    else
        disableNoclip()
    end
end)

ui.CreateToggle("Freecam", mainContainer, function(state)
    if state then
        player.CameraMode = Enum.CameraMode.Classic
    else
        if originalCameraMode then
            player.CameraMode = originalCameraMode
        end
    end
end)

ui.CreateToggle("InfinityJump", mainContainer, function(state)
    infinityJumpEnabled = state
    if state then
        showJumpButton()
    end
end)

UserInputService.JumpRequest:Connect(function()
    if infinityJumpEnabled and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

ui.CreateToggleWithInput("SpeedHack", mainContainer, {
    default = function()
        return tostring(originalWalkSpeed or 16)
    end,
    reset = function()
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and originalWalkSpeed then
            humanoid.WalkSpeed = originalWalkSpeed
        end
    end,
    onToggle = function(state, inputValue)
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        local speed = tonumber(inputValue)
        if humanoid and speed then
            humanoid.WalkSpeed = state and speed or (originalWalkSpeed or 16)
        end
    end
})

ui.CreateToggleWithInput("JumpHack", mainContainer, {
    default = function()
        return tostring(originalJumpPower or 50)
    end,
    reset = function()
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and originalJumpPower then
            humanoid.JumpPower = originalJumpPower
        end
    end,
    onToggle = function(state, inputValue)
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        local power = tonumber(inputValue)
        if humanoid and power then
            humanoid.JumpPower = state and power or (originalJumpPower or 50)
        end
        if state then
            showJumpButton()
        end
    end
})

local contentContainer = ui.CreateCategory("ESP")

local toolESPEnabled = false
local toolsESPManuallyEnabled = false
local playerESPEnabled = false
local enemyESPEnabled = false
local trapESPEnabled = false

local function setupToolESP()
    clearESPByType("tool")

    local map = workspace:FindFirstChild("Map")
    if not map then return end
    local currentMap
    for _, folder in ipairs(map:GetChildren()) do
        if folder:IsA("Folder") and folder.Name ~= "Players" and folder.Name ~= "Traps" then
            currentMap = folder
            break
        end
    end
    if not currentMap then return end
    local toolsFolder = currentMap:FindFirstChild("Tools")
    if not toolsFolder then return end

    local function addToolESP(toolModel)
        if not toolModel:IsA("Model") then return end

        addHighlight(toolModel, "tool", Color3.fromRGB(255,105,180), {FillTransparency=0.8, OutlineTransparency=1})

        local primary = toolModel.PrimaryPart or toolModel:FindFirstChildWhichIsA("BasePart")
        if primary then
            local bb = toolModel:FindFirstChild("ToolESP_Billboard")
            if bb then bb:Destroy() end  -- удаляем старый, если есть

            bb = Instance.new("BillboardGui")
            bb.Name = "ToolESP_Billboard"
            bb.Size = UDim2.new(0, 100, 0, 20)
            bb.Adornee = primary
            bb.AlwaysOnTop = true
            bb.StudsOffset = Vector3.new(0, 2, 0)
            bb.Parent = toolModel

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = toolModel.Name
            lbl.TextColor3 = Color3.fromRGB(255,105,180)
            lbl.TextScaled = true
            lbl.Font = Enum.Font.SourceSans
            lbl.TextStrokeTransparency = 0.5
            lbl.Parent = bb
        end
    end

    for _, tool in ipairs(toolsFolder:GetChildren()) do
        addToolESP(tool)
    end

    toolsFolder.ChildAdded:Connect(function(child)
        if toolESPEnabled then
            addToolESP(child)
        end
    end)

    toolsFolder.ChildRemoved:Connect(removeHighlight)
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "Map" then
        task.wait(1)
        if toolESPEnabled then
            clearESPByType("tool")
            setupToolESP()
        end
        if enemyESPEnabled then
            clearESPByType("enemy")
            for _, p in ipairs(child.Players:GetChildren()) do
                if p.Name == "Enemy" then
                    addHighlight(p, "enemy", Color3.fromRGB(255,0,0))
                end
            end
        end
        if playerESPEnabled then
            clearESPByType("player")
            for _, p in ipairs(child.Players:GetChildren()) do
                if p.Name ~= "Enemy" then
                    addHighlight(p, "player", Color3.fromRGB(0,255,0))
                end
            end
        end
        if trapESPEnabled then
            clearESPByType("trap")
            for _, trap in ipairs(child.Traps:GetChildren()) do
                if trap:IsA("Model") then
                    addHighlight(trap, "trap", Color3.fromRGB(255,0,0))
                end
            end
        end
    end
end)

ui.CreateToggle("Tools ESP", contentContainer, function(state)
    toolESPEnabled = state
    toolsESPManuallyEnabled = state
    clearESPByType("tool")
    if state then setupToolESP() end
end)

ui.CreateToggle("Players ESP", contentContainer, function(state)
    playerESPEnabled = state
    clearESPByType("player")

    local folder = workspace:FindFirstChild("Map")
    local players = folder and folder:FindFirstChild("Players")
    if not players then return end

    if state then
        for _, obj in ipairs(players:GetChildren()) do
            if obj.Name ~= "Enemy" then
                addHighlight(obj, "player", Color3.fromRGB(0,255,0))
            end
        end
    elseif toolsESPManuallyEnabled then
        setupToolESP()
    end
end)

ui.CreateToggle("Enemy ESP", contentContainer, function(state)
    enemyESPEnabled = state
    clearESPByType("enemy")

    local folder = workspace:FindFirstChild("Map")
    local players = folder and folder:FindFirstChild("Players")
    if not players then return end

    if state then
        for _, obj in ipairs(players:GetChildren()) do
            if obj.Name == "Enemy" then
                addHighlight(obj, "enemy", Color3.fromRGB(255,0,0))
            end
        end
    end
end)

ui.CreateToggle("Traps ESP", contentContainer, function(state)
    trapESPEnabled = state
    clearESPByType("trap")

    local folder = workspace:FindFirstChild("Map")
    local traps = folder and folder:FindFirstChild("Traps")
    if not traps then return end

    if state then
        for _, obj in ipairs(traps:GetChildren()) do
            if obj:IsA("Model") then
                addHighlight(obj, "trap", Color3.fromRGB(255,0,0))
            end
        end
    end
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "Map" then
        task.wait(1)
        if enemyESPEnabled then
            for _, p in ipairs(child.Players:GetChildren()) do
                if p.Name == "Enemy" then
                    addHighlight(p, "enemy", Color3.fromRGB(255,0,0))
                end
            end
        end
        if playerESPEnabled then
            for _, p in ipairs(child.Players:GetChildren()) do
                if p.Name ~= "Enemy" then
                    addHighlight(p, "player", Color3.fromRGB(0,255,0))
                end
            end
        end
        if trapESPEnabled then
            for _, trap in ipairs(child.Traps:GetChildren()) do
                if trap:IsA("Model") then
                    addHighlight(trap, "trap", Color3.fromRGB(255,0,0))
                end
            end
        end
        if toolESPEnabled then
            setupToolESP()
        end
    end
end)

ui.OpenFirstCategory()
