local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end

local RequiredGameId = 8157263243

if game.GameId ~= RequiredGameId then
    return
end

LocalPlayer:WaitForChild("PlayerGui")

local uiModule
local loaded = false
for attempt = 1, 30 do
    loaded, uiModule = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Walidname113/Roblox-scr/refs/heads/main/ModernUI_v32.lua"))()
    end)
    if loaded and type(uiModule) == "table" and type(uiModule.new) == "function" then
        break
    end
    loaded = false
    task.wait(1)
end

if not loaded or type(uiModule) ~= "table" or type(uiModule.new) ~= "function" then
    warn("ModernUI failed to load after 30 attempts")
    return
end

local Window = uiModule.new({
    Name = "ModernUI",
    Title = "{gamename} | By Kiyatsuka v1.0.7",
})

if MinimizedIcon ~= "" then
    Window:SetMinimizedImage(MinimizedIcon)
end

local Main = Window:Category("Main")
local ESP = Window:Category("ESP")
local Visuals = Window:Category("Visuals")
local Movement = Window:Category("Movement")

local ESP_INTERVAL = 0.2
local MOVEMENT_INTERVAL = 0.5

local ESPState = {
    Killer = { Enabled = false, Distance = false, Health = false, Level = false },
    Survivors = { Enabled = false, Distance = false, Health = false, Level = false },
}

local ESPObjects = {}
local ESPHighlights = {}
local originalLighting = nil
local fullbrightEnabled = false
local noFogEnabled = false
local atmosphereState = {}
local gameValues = nil
local speedControl = nil
local jumpControl = nil
local speedEnabled = false
local jumpEnabled = false
local speedBase = 16
local jumpBase = 50
local speedApplied = nil
local jumpApplied = nil
local noclipEnabled = false
local noclipOriginal = {}
local originalMovement = {}

local function getValue(instance, default)
    if not instance then
        return default
    end
    if instance:IsA("ValueBase") then
        return instance.Value
    end
    return default
end

local function refreshGameValues()
    local values = ReplicatedStorage:FindFirstChild("Values")
    local gameFolder = values and values:FindFirstChild("Game")
    gameValues = gameFolder
    return gameFolder
end

local function formatNumber(value)
    local number = tonumber(value)
    if not number then
        return tostring(value)
    end
    local result = string.format("%.2f", number)
    result = result:gsub("0+$", ""):gsub("%.$", "")
    return result
end

local function getKillerName()
    local folder = gameValues or refreshGameValues()
    local killer = folder and folder:FindFirstChild("Killer")
    local value = getValue(killer, nil)
    if typeof(value) == "Instance" then
        return value.Name
    end
    if value ~= nil then
        return tostring(value)
    end
    return nil
end

local function getCharacterRoot(model)
    return model and (model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso"))
end

local function getPlayerValue(player, name)
    local item = player and player:FindFirstChild(name)
    if item then
        return getValue(item, nil)
    end
    local character = player and player.Character
    local value = character and character:FindFirstChild(name)
    if value then
        return getValue(value, nil)
    end
    return nil
end

local function isInGame(player)
    local value = getPlayerValue(player, "InGame")
    if value == nil then
        value = player:GetAttribute("InGame")
    end
    return value == true
end

local function getCharacterRole(model)
    local killerName = getKillerName()
    if killerName and model.Name == killerName then
        return "Killer"
    end
    if killerName then
        return "Survivors"
    end
    return nil
end

local function removeESP(model)
    local gui = ESPObjects[model]
    if gui then
        gui:Destroy()
        ESPObjects[model] = nil
    end
    local highlight = ESPHighlights[model]
    if highlight then
        highlight:Destroy()
        ESPHighlights[model] = nil
    end
end

local function updateHighlight(model, role)
    local enabled = role and ESPState[role] and ESPState[role].Enabled
    if not enabled then
        if ESPHighlights[model] then
            ESPHighlights[model]:Destroy()
            ESPHighlights[model] = nil
        end
        return
    end
    local highlight = ESPHighlights[model]
    if not highlight or not highlight.Parent then
        highlight = Instance.new("Highlight")
        highlight.Name = "ModernUI_ESP_Highlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillTransparency = 0.82
        highlight.OutlineTransparency = 0.1
        highlight.Parent = model
        ESPHighlights[model] = highlight
    end
    highlight.FillColor = role == "Killer" and Color3.fromRGB(255, 45, 45) or Color3.fromRGB(50, 135, 255)
    highlight.OutlineColor = role == "Killer" and Color3.fromRGB(110, 0, 0) or Color3.fromRGB(0, 40, 120)
end

local function createESP(model)
    local gui = Instance.new("BillboardGui")
    gui.Name = "ModernUI_ESP"
    gui.AlwaysOnTop = true
    gui.Size = UDim2.fromOffset(220, 100)
    gui.SizeOffset = Vector2.new(0, 0.5)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.Adornee = getCharacterRoot(model)
    gui.Parent = model

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextStrokeTransparency = 0.25
    label.TextWrapped = true
    label.TextYAlignment = Enum.TextYAlignment.Bottom
    label.Parent = gui

    ESPObjects[model] = gui
    return gui
end

local function updateESP()
    local characters = workspace:FindFirstChild("Characters")
    if not characters then
        return
    end

    local killerName = getKillerName()
    local activeModels = {}

    for _, model in ipairs(characters:GetChildren()) do
        if model:IsA("Model") and model ~= LocalPlayer.Character then
            local role = getCharacterRole(model)
            local player = Players:FindFirstChild(model.Name)
            local allowed = role and ESPState[role].Enabled
            if role == "Survivors" and player and not isInGame(player) then
                allowed = false
            end
            if allowed and getCharacterRoot(model) then
                activeModels[model] = true
                local gui = ESPObjects[model] or createESP(model)
                gui.Adornee = getCharacterRoot(model)
                local label = gui:FindFirstChild("Label")
                local lines = { model.Name }
                local state = ESPState[role]
                local root = getCharacterRoot(model)
                local localRoot = getCharacterRoot(LocalPlayer.Character)
                if state.Distance and root and localRoot then
                    table.insert(lines, "Distance: " .. formatNumber((root.Position - localRoot.Position).Magnitude))
                end
                local humanoid = model:FindFirstChildOfClass("Humanoid")
                if state.Health and humanoid then
                    table.insert(lines, "Health: " .. formatNumber(humanoid.Health) .. "/" .. formatNumber(humanoid.MaxHealth))
                end
                if state.Level and player then
                    local level = getPlayerValue(player, "Level")
                    if level ~= nil then
                        table.insert(lines, "Level: " .. tostring(level))
                    end
                end
                if role == "Killer" then
                    local folder = gameValues or refreshGameValues()
                    local rage = folder and folder:FindFirstChild("KillerRage")
                    local multiplier = folder and folder:FindFirstChild("KillerDamageMultiplier")
                    if rage then
                        table.insert(lines, "Killer rage: " .. formatNumber(getValue(rage, 0)))
                    end
                    if multiplier then
                        table.insert(lines, "Damage Multiplier: " .. formatNumber(getValue(multiplier, 1)))
                    end
                end
                label.Text = table.concat(lines, "\n")
                label.TextColor3 = role == "Killer" and Color3.fromRGB(255, 75, 75) or Color3.fromRGB(100, 180, 255)
                gui.Size = UDim2.fromOffset(220, math.max(40, #lines * 17))
                updateHighlight(model, role)
            else
                removeESP(model)
            end
        end
    end

    for model in pairs(ESPObjects) do
        if not activeModels[model] or not model.Parent then
            removeESP(model)
        end
    end
    for model in pairs(ESPHighlights) do
        if not activeModels[model] or not model.Parent then
            if ESPHighlights[model] then
                ESPHighlights[model]:Destroy()
                ESPHighlights[model] = nil
            end
        end
    end
end

local function setFullbright(enabled)
    if enabled then
        if not originalLighting then
            originalLighting = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
                GlobalShadows = Lighting.GlobalShadows,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
            }
        end
        fullbrightEnabled = true
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1000000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
    else
        fullbrightEnabled = false
        if originalLighting then
            for property, value in pairs(originalLighting) do
                pcall(function()
                    Lighting[property] = value
                end)
            end
        end
    end
end

local function setNoFog(enabled)
    noFogEnabled = enabled
    local found = {}
    for _, item in ipairs(Lighting:GetDescendants()) do
        if item:IsA("Atmosphere") then
            found[item] = true
            if enabled then
                if atmosphereState[item] == nil then
                    atmosphereState[item] = {
                        Density = item.Density,
                        Haze = item.Haze,
                    }
                end
                item.Density = 0
                item.Haze = 0
            elseif atmosphereState[item] then
                item.Density = atmosphereState[item].Density
                item.Haze = atmosphereState[item].Haze
            end
        end
    end
    if not enabled then
        for item, state in pairs(atmosphereState) do
            if item.Parent then
                item.Density = state.Density
                item.Haze = state.Haze
            end
        end
    end
end

local function getHumanoid()
    local character = LocalPlayer.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function readJumpProperty(humanoid)
    if not humanoid then
        return 50
    end
    if humanoid.UseJumpPower then
        return humanoid.JumpPower
    end
    return humanoid.JumpHeight
end

local function writeJumpProperty(humanoid, value)
    if not humanoid then
        return
    end
    if humanoid.UseJumpPower then
        humanoid.JumpPower = value
    else
        humanoid.JumpHeight = value
    end
end

local function clampMovementValue(value)
    local number = tonumber(value)
    if not number then
        return nil
    end
    return math.clamp(number, 1, 999999)
end

local function createMovementControl(title, initialValue, callback)
    local page = Movement._page
    local root = Instance.new("Frame")
    root.Name = title:gsub("%s+", "") .. "Control"
    root.BackgroundTransparency = 1
    root.Size = UDim2.new(1, -20, 0, 74)
    root.Parent = page

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.fromOffset(4, 0)
    titleLabel.Size = UDim2.new(0.58, -4, 0, 22)
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
    titleLabel.Text = title
    titleLabel.Parent = root

    local input = Instance.new("TextBox")
    input.Name = "ValueInput"
    input.AnchorPoint = Vector2.new(1, 0)
    input.Position = UDim2.new(1, -2, 0, 0)
    input.Size = UDim2.fromOffset(92, 22)
    input.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    input.BorderSizePixel = 0
    input.Font = Enum.Font.Gotham
    input.TextSize = 12
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.ClearTextOnFocus = false
    input.Text = tostring(math.floor(initialValue))
    input.Parent = root
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 5)

    local track = Instance.new("TextButton")
    track.Name = "SliderTrack"
    track.AutoButtonColor = false
    track.Text = ""
    track.Position = UDim2.fromOffset(4, 35)
    track.Size = UDim2.new(1, -8, 0, 12)
    track.BackgroundColor3 = Color3.fromRGB(48, 48, 58)
    track.BorderSizePixel = 0
    track.Parent = root
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(70, 140, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.Size = UDim2.fromOffset(16, 16)
    knob.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local rangeLabel = Instance.new("TextLabel")
    rangeLabel.BackgroundTransparency = 1
    rangeLabel.Position = UDim2.fromOffset(4, 51)
    rangeLabel.Size = UDim2.new(1, -8, 0, 17)
    rangeLabel.Font = Enum.Font.Gotham
    rangeLabel.TextSize = 10
    rangeLabel.TextColor3 = Color3.fromRGB(165, 165, 175)
    rangeLabel.TextXAlignment = Enum.TextXAlignment.Left
    rangeLabel.Parent = root

    local control = {
        Root = root,
        Value = initialValue,
        Base = math.max(1, initialValue),
        Enabled = false,
    }

    local function visualBounds()
        return control.Base, math.max(1000, control.Base)
    end

    local function render()
        local minimum, maximum = visualBounds()
        local pct
        if maximum <= minimum then
            pct = 0
        else
            pct = math.clamp((control.Value - minimum) / (maximum - minimum), 0, 1)
        end
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        rangeLabel.Text = tostring(math.floor(minimum)) .. "  —  " .. tostring(math.floor(maximum)) .. "  |  Max input: 999999"
        input.Text = tostring(math.floor(control.Value))
    end

    function control:SetBase(value)
        control.Base = math.max(1, tonumber(value) or 1)
        render()
    end

    function control:Set(value, silent)
        local clamped = clampMovementValue(value)
        if not clamped then
            return
        end
        control.Value = clamped
        render()
        if not silent and callback then
            callback(control.Value)
        end
    end

    local dragging = false

    local function setFromX(x)
        local minimum, maximum = visualBounds()
        local width = math.max(1, track.AbsoluteSize.X)
        local pct = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
        control:Set(minimum + (maximum - minimum) * pct, false)
    end

    track.InputBegan:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(inputObject.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(inputObject)
        if dragging and (inputObject.UserInputType == Enum.UserInputType.MouseMovement or inputObject.UserInputType == Enum.UserInputType.Touch) then
            setFromX(inputObject.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    input.FocusLost:Connect(function()
        local value = clampMovementValue(input.Text)
        if not value then
            render()
            return
        end
        control:Set(value, false)
    end)

    render()
    return control
end

local function applySpeed(value)
    local humanoid = getHumanoid()
    if not humanoid then
        return
    end
    local actual = clampMovementValue(value)
    if not actual then
        return
    end
    humanoid.WalkSpeed = actual
    speedApplied = actual
end

local function applyJump(value)
    local humanoid = getHumanoid()
    if not humanoid then
        return
    end
    local actual = clampMovementValue(value)
    if not actual then
        return
    end
    writeJumpProperty(humanoid, actual)
    jumpApplied = actual
end

local function setSpeedhack(enabled)
    speedEnabled = enabled
    local humanoid = getHumanoid()
    if not humanoid then
        return
    end
    if enabled then
        speedBase = humanoid.WalkSpeed
        if speedControl then
            speedControl:SetBase(speedBase)
            applySpeed(speedControl.Value)
        else
            applySpeed(speedBase)
        end
    else
        humanoid.WalkSpeed = speedBase
        speedApplied = nil
    end
end

local function setJumphack(enabled)
    jumpEnabled = enabled
    local humanoid = getHumanoid()
    if not humanoid then
        return
    end
    if enabled then
        jumpBase = readJumpProperty(humanoid)
        if jumpControl then
            jumpControl:SetBase(jumpBase)
            applyJump(jumpControl.Value)
        else
            applyJump(jumpBase)
        end
    else
        writeJumpProperty(humanoid, jumpBase)
        jumpApplied = nil
    end
end

local function restoreNoclip()
    for part, value in pairs(noclipOriginal) do
        if part and part.Parent then
            part.CanCollide = value
        end
    end
    table.clear(noclipOriginal)
end

local function updateNoclip()
    local character = LocalPlayer.Character
    if not character then
        return
    end
    if not noclipEnabled then
        restoreNoclip()
        return
    end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if noclipOriginal[part] == nil then
                noclipOriginal[part] = part.CanCollide
            end
            part.CanCollide = false
        end
    end
end

local function createProfileCard()
    local page = Main._page
    local card = Instance.new("Frame")
    card.Name = "ProfileCard"
    card.Size = UDim2.new(1, -20, 0, 74)
    card.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
    card.BorderSizePixel = 0
    card.Parent = page
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local avatar = Instance.new("ImageLabel")
    avatar.Name = "Avatar"
    avatar.BackgroundTransparency = 1
    avatar.Position = UDim2.fromOffset(10, 10)
    avatar.Size = UDim2.fromOffset(54, 54)
    avatar.Image = ""
    avatar.Parent = card
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.fromOffset(74, 13)
    nameLabel.Size = UDim2.new(1, -84, 0, 22)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
    nameLabel.Text = LocalPlayer.DisplayName
    nameLabel.Parent = card

    local userLabel = Instance.new("TextLabel")
    userLabel.BackgroundTransparency = 1
    userLabel.Position = UDim2.fromOffset(74, 36)
    userLabel.Size = UDim2.new(1, -84, 0, 18)
    userLabel.Font = Enum.Font.Gotham
    userLabel.TextSize = 11
    userLabel.TextXAlignment = Enum.TextXAlignment.Left
    userLabel.TextColor3 = Color3.fromRGB(165, 165, 175)
    userLabel.Text = "@" .. LocalPlayer.Name
    userLabel.Parent = card

    task.spawn(function()
        local ok, image = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if ok then
            avatar.Image = image
        end
    end)
end

createProfileCard()

local selectedTeleportPlayer = nil
local teleportOptionPlayers = {}
local playerPickerGui
local playerPickerPanel
local playerPickerList
local playerPickerSearch
local playerPickerSelectionLabel
local playerPickerOpen = false
local playerRowConnections = {}

local function getPlayerCharacter(player)
    local characters = workspace:FindFirstChild("Characters")
    local model = characters and characters:FindFirstChild(player.Name)
    if model and getCharacterRoot(model) then
        return model
    end
    if player.Character and getCharacterRoot(player.Character) then
        return player.Character
    end
    return nil
end

local function teleportToModel(model)
    local targetRoot = getCharacterRoot(model)
    local localCharacter = LocalPlayer.Character
    local localRoot = getCharacterRoot(localCharacter)
    if not targetRoot then
        warn("Teleport failed: target character root not found")
        return
    end
    if not localRoot then
        warn("Teleport failed: local character root not found")
        return
    end
    localRoot.CFrame = targetRoot.CFrame * CFrame.new(3, 0, 0)
end

local function teleportToCFrame(targetCFrame, label)
    local localRoot = getCharacterRoot(LocalPlayer.Character)
    if not localRoot then
        warn((label or "Teleport") .. ": local character root not found")
        return
    end
    localRoot.CFrame = targetCFrame * CFrame.new(0, 3, 0)
end

local function getCurrentMap()
    local mapFolder = workspace:FindFirstChild("Map")
    if not mapFolder then
        return nil
    end
    for _, child in ipairs(mapFolder:GetChildren()) do
        if child.Name ~= "Lobby" and child:IsA("Model") then
            return child
        end
    end
    return nil
end

local function getInstanceCFrame(instance)
    if instance:IsA("BasePart") then
        return instance.CFrame
    end
    if instance:IsA("Model") then
        return instance:GetPivot()
    end
    local part = instance:FindFirstChildWhichIsA("BasePart", true)
    return part and part.CFrame or nil
end

local function teleportToRandomMapObject(folderName, label)
    local currentMap = getCurrentMap()
    if not currentMap then
        warn(label .. ": current map was not found")
        return
    end
    local folder = currentMap:FindFirstChild(folderName)
    if not folder then
        warn(label .. ": " .. folderName .. " was not found on " .. currentMap.Name)
        return
    end
    local candidates = {}
    for _, object in ipairs(folder:GetChildren()) do
        if getInstanceCFrame(object) then
            candidates[#candidates + 1] = object
        end
    end
    if #candidates == 0 then
        for _, object in ipairs(folder:GetDescendants()) do
            if object:IsA("BasePart") then
                candidates[#candidates + 1] = object
            end
        end
    end
    if #candidates == 0 then
        warn(label .. ": no teleportable objects found")
        return
    end
    local target = candidates[math.random(1, #candidates)]
    local targetCFrame = getInstanceCFrame(target)
    if targetCFrame then
        teleportToCFrame(targetCFrame, label)
    else
        warn(label .. ": selected object has no position")
    end
end

local function clearPlayerRows()
    for _, connection in ipairs(playerRowConnections) do
        connection:Disconnect()
    end
    table.clear(playerRowConnections)
    if playerPickerList then
        for _, child in ipairs(playerPickerList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
    end
end

local function playerMatchesSearch(player, query)
    if query == "" then
        return true
    end
    query = query:lower()
    return player.DisplayName:lower():find(query, 1, true) ~= nil
        or player.Name:lower():find(query, 1, true) ~= nil
end

local function chooseTeleportPlayer(player)
    if not player or player.Parent ~= Players then
        return
    end
    selectedTeleportPlayer = player
    if playerPickerSelectionLabel then
        playerPickerSelectionLabel.Text = "Selected: " .. player.DisplayName .. "  (@" .. player.Name .. ")"
    end
    if playerPickerOpen and playerPickerPanel then
        playerPickerPanel.Visible = false
        local backdrop = playerPickerGui and playerPickerGui:FindFirstChild("Backdrop")
        if backdrop then
            backdrop.Visible = false
        end
        playerPickerOpen = false
    end
end

local function refreshTeleportPlayers()
    if not playerPickerList then
        return
    end
    clearPlayerRows()
    local players = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and playerMatchesSearch(player, playerPickerSearch and playerPickerSearch.Text or "") then
            players[#players + 1] = player
        end
    end
    table.sort(players, function(a, b)
        local ad = a.DisplayName:lower()
        local bd = b.DisplayName:lower()
        if ad == bd then
            return a.Name:lower() < b.Name:lower()
        end
        return ad < bd
    end)
    teleportOptionPlayers = {}
    for _, player in ipairs(players) do
        teleportOptionPlayers[player.Name] = player
        local row = Instance.new("TextButton")
        row.Name = "Player_" .. player.Name
        row.Size = UDim2.new(1, -8, 0, 52)
        row.BackgroundColor3 = Color3.fromRGB(36, 38, 48)
        row.BorderSizePixel = 0
        row.AutoButtonColor = false
        row.Text = ""
        row.Parent = playerPickerList
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local display = Instance.new("TextLabel")
        display.BackgroundTransparency = 1
        display.Position = UDim2.fromOffset(12, 6)
        display.Size = UDim2.new(1, -24, 0, 20)
        display.Font = Enum.Font.GothamSemibold
        display.TextSize = 13
        display.TextColor3 = Color3.fromRGB(245, 245, 250)
        display.TextXAlignment = Enum.TextXAlignment.Left
        display.TextTruncate = Enum.TextTruncate.AtEnd
        display.Text = player.DisplayName
        display.Parent = row

        local username = Instance.new("TextLabel")
        username.BackgroundTransparency = 1
        username.Position = UDim2.fromOffset(12, 27)
        username.Size = UDim2.new(1, -24, 0, 16)
        username.Font = Enum.Font.Gotham
        username.TextSize = 11
        username.TextColor3 = Color3.fromRGB(155, 162, 178)
        username.TextXAlignment = Enum.TextXAlignment.Left
        username.TextTruncate = Enum.TextTruncate.AtEnd
        username.Text = "@" .. player.Name
        username.Parent = row

        if player == selectedTeleportPlayer then
            row.BackgroundColor3 = Color3.fromRGB(42, 72, 112)
        end

        local press = nil
        local startPosition = nil
        local maxMovement = 0
        local beganTouch = false
        table.insert(playerRowConnections, row.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                press = input
                startPosition = input.Position
                maxMovement = 0
                beganTouch = input.UserInputType == Enum.UserInputType.Touch
            end
        end))
        table.insert(playerRowConnections, UserInputService.InputChanged:Connect(function(input)
            if press and beganTouch and input == press then
                maxMovement = math.max(maxMovement, (input.Position - startPosition).Magnitude)
            elseif press and beganTouch and input.UserInputType == Enum.UserInputType.Touch then
                maxMovement = math.max(maxMovement, (input.Position - startPosition).Magnitude)
            end
        end))
        table.insert(playerRowConnections, UserInputService.InputEnded:Connect(function(input)
            if not press then
                return
            end
            local matchingEnd = input == press or (beganTouch and input.UserInputType == Enum.UserInputType.Touch)
            if not matchingEnd then
                return
            end
            local endPosition = input.Position
            local moved = math.max(maxMovement, (endPosition - startPosition).Magnitude)
            local rowPosition = row.AbsolutePosition
            local rowSize = row.AbsoluteSize
            local inside = endPosition.X >= rowPosition.X and endPosition.X <= rowPosition.X + rowSize.X
                and endPosition.Y >= rowPosition.Y and endPosition.Y <= rowPosition.Y + rowSize.Y
            local shouldSelect = moved <= 10 and inside
            press = nil
            startPosition = nil
            beganTouch = false
            if shouldSelect then
                chooseTeleportPlayer(player)
            end
        end))
    end
    playerPickerList.CanvasSize = UDim2.new(0, 0, 0, #players * 58)
    if playerPickerSelectionLabel then
        if selectedTeleportPlayer and selectedTeleportPlayer.Parent == Players then
            playerPickerSelectionLabel.Text = "Selected: " .. selectedTeleportPlayer.DisplayName .. "  (@" .. selectedTeleportPlayer.Name .. ")"
        else
            selectedTeleportPlayer = nil
            playerPickerSelectionLabel.Text = "Selected: none"
        end
    end
end

local function createPlayerPicker()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild("ChasingOPPlayerPicker")
    if old then
        old:Destroy()
    end
    playerPickerGui = Instance.new("ScreenGui")
    playerPickerGui.Name = "ChasingOPPlayerPicker"
    playerPickerGui.ResetOnSpawn = false
    playerPickerGui.IgnoreGuiInset = true
    playerPickerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    playerPickerGui.Parent = playerGui

    local backdrop = Instance.new("TextButton")
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.45
    backdrop.BorderSizePixel = 0
    backdrop.Text = ""
    backdrop.Visible = false
    backdrop.Parent = playerPickerGui
    backdrop.Activated:Connect(function()
        playerPickerPanel.Visible = false
        playerPickerOpen = false
    end)

    playerPickerPanel = Instance.new("Frame")
    playerPickerPanel.Name = "PlayerPickerPanel"
    playerPickerPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    playerPickerPanel.Position = UDim2.fromScale(0.5, 0.5)
    playerPickerPanel.Size = UDim2.new(0.88, 0, 0, 390)
    playerPickerPanel.BackgroundColor3 = Color3.fromRGB(23, 25, 33)
    playerPickerPanel.BorderSizePixel = 0
    playerPickerPanel.Visible = false
    playerPickerPanel.Parent = playerPickerGui
    playerPickerPanel.ZIndex = 10
    Instance.new("UICorner", playerPickerPanel).CornerRadius = UDim.new(0, 14)
    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MaxSize = Vector2.new(380, 430)
    sizeConstraint.MinSize = Vector2.new(270, 340)
    sizeConstraint.Parent = playerPickerPanel

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(16, 12)
    title.Size = UDim2.new(1, -58, 0, 24)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = Color3.fromRGB(245, 245, 250)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Select player"
    title.Parent = playerPickerPanel
    title.ZIndex = 11

    local close = Instance.new("TextButton")
    close.AnchorPoint = Vector2.new(1, 0)
    close.Position = UDim2.new(1, -10, 0, 9)
    close.Size = UDim2.fromOffset(32, 30)
    close.BackgroundColor3 = Color3.fromRGB(45, 47, 58)
    close.BorderSizePixel = 0
    close.Font = Enum.Font.GothamBold
    close.TextSize = 17
    close.TextColor3 = Color3.fromRGB(220, 222, 230)
    close.Text = "×"
    close.Parent = playerPickerPanel
    close.ZIndex = 11
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)
    close.Activated:Connect(function()
        playerPickerPanel.Visible = false
        backdrop.Visible = false
        playerPickerOpen = false
    end)

    playerPickerSearch = Instance.new("TextBox")
    playerPickerSearch.Position = UDim2.fromOffset(12, 48)
    playerPickerSearch.Size = UDim2.new(1, -24, 0, 36)
    playerPickerSearch.BackgroundColor3 = Color3.fromRGB(35, 37, 47)
    playerPickerSearch.BorderSizePixel = 0
    playerPickerSearch.ClearTextOnFocus = false
    playerPickerSearch.Font = Enum.Font.Gotham
    playerPickerSearch.TextSize = 13
    playerPickerSearch.TextColor3 = Color3.fromRGB(240, 240, 245)
    playerPickerSearch.PlaceholderColor3 = Color3.fromRGB(145, 150, 165)
    playerPickerSearch.PlaceholderText = "Search display name or username..."
    playerPickerSearch.Text = ""
    playerPickerSearch.Parent = playerPickerPanel
    playerPickerSearch.ZIndex = 11
    Instance.new("UICorner", playerPickerSearch).CornerRadius = UDim.new(0, 8)

    playerPickerList = Instance.new("ScrollingFrame")
    playerPickerList.Position = UDim2.fromOffset(8, 92)
    playerPickerList.Size = UDim2.new(1, -16, 1, -154)
    playerPickerList.BackgroundTransparency = 1
    playerPickerList.BorderSizePixel = 0
    playerPickerList.ScrollBarThickness = 4
    playerPickerList.ScrollBarImageColor3 = Color3.fromRGB(95, 125, 180)
    playerPickerList.CanvasSize = UDim2.new()
    playerPickerList.AutomaticCanvasSize = Enum.AutomaticSize.None
    playerPickerList.ScrollingDirection = Enum.ScrollingDirection.Y
    playerPickerList.Parent = playerPickerPanel
    playerPickerList.ZIndex = 11
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = playerPickerList

    playerPickerSelectionLabel = Instance.new("TextLabel")
    playerPickerSelectionLabel.BackgroundTransparency = 1
    playerPickerSelectionLabel.Position = UDim2.new(0, 14, 1, -51)
    playerPickerSelectionLabel.Size = UDim2.new(1, -28, 0, 38)
    playerPickerSelectionLabel.Font = Enum.Font.Gotham
    playerPickerSelectionLabel.TextSize = 11
    playerPickerSelectionLabel.TextColor3 = Color3.fromRGB(175, 182, 198)
    playerPickerSelectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerPickerSelectionLabel.TextYAlignment = Enum.TextYAlignment.Center
    playerPickerSelectionLabel.TextTruncate = Enum.TextTruncate.AtEnd
    playerPickerSelectionLabel.Text = "Selected: none"
    playerPickerSelectionLabel.Parent = playerPickerPanel
    playerPickerSelectionLabel.ZIndex = 11

    playerPickerSearch:GetPropertyChangedSignal("Text"):Connect(refreshTeleportPlayers)
    backdrop.ZIndex = 9
end

Main:Button({
    Text = "Teleport to Killer",
    Callback = function()
        local killerName = getKillerName()
        if not killerName then
            warn("Teleport failed: killer is not available")
            return
        end
        local characters = workspace:FindFirstChild("Characters")
        local killerModel = characters and characters:FindFirstChild(killerName)
        if not killerModel then
            local killerPlayer = Players:FindFirstChild(killerName)
            killerModel = killerPlayer and getPlayerCharacter(killerPlayer)
        end
        if not killerModel then
            warn("Teleport failed: killer character not found")
            return
        end
        teleportToModel(killerModel)
    end,
})

Main:Button({
    Text = "Random Survivor",
    Callback = function()
        local killerName = getKillerName()
        local candidates = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Name ~= killerName and isInGame(player) then
                local character = getPlayerCharacter(player)
                if character and getCharacterRoot(character) then
                    candidates[#candidates + 1] = character
                end
            end
        end
        if #candidates == 0 then
            warn("Random Survivor: no eligible survivors found")
            return
        end
        teleportToModel(candidates[math.random(1, #candidates)])
    end,
})

Main:Button({
    Text = "Select Player (Display Name / @Username)",
    Callback = function()
        if not playerPickerGui then
            createPlayerPicker()
        end
        playerPickerOpen = not playerPickerOpen
        playerPickerPanel.Visible = playerPickerOpen
        local backdrop = playerPickerGui:FindFirstChild("Backdrop")
        if backdrop then
            backdrop.Visible = playerPickerOpen
        end
        if playerPickerOpen then
            refreshTeleportPlayers()
        end
    end,
})

Main:Button({
    Text = "Teleport to Current Map",
    Callback = function()
        local currentMap = getCurrentMap()
        if not currentMap then
            warn("Teleport to Current Map: current map was not found")
            return
        end
        teleportToCFrame(currentMap:GetPivot(), "Teleport to Current Map")
    end,
})

Main:Button({
    Text = "Teleport to Random Phone",
    Callback = function()
        teleportToRandomMapObject("_Phones", "Teleport to Random Phone")
    end,
})

Main:Button({
    Text = "Teleport to Random Power",
    Callback = function()
        teleportToRandomMapObject("_Powers", "Teleport to Random Power")
    end,
})

Main:Button({
    Text = "Teleport To",
    Callback = function()
        local player = selectedTeleportPlayer
        if not player or player.Parent ~= Players then
            warn("Teleport To: select an available player first")
            return
        end
        local character = getPlayerCharacter(player)
        if not character then
            warn("Teleport To: selected player's character not found")
            return
        end
        teleportToModel(character)
    end,
})

createPlayerPicker()
refreshTeleportPlayers()
Window:Connect(Players.PlayerAdded, refreshTeleportPlayers)
Window:Connect(Players.PlayerRemoving, function(player)
    if player == selectedTeleportPlayer then
        selectedTeleportPlayer = nil
    end
    task.defer(refreshTeleportPlayers)
end)

local function createESPGroup(category, title, role)
    local childrenHolder = nil
    local parentToggle = nil

    local function setChildrenVisible(visible)
        if not childrenHolder or not childrenHolder.Parent then
            return
        end
        childrenHolder.Visible = visible
        local padding = parentToggle.Frame:FindFirstChildOfClass("UIPadding")
        if padding then
            padding.PaddingBottom = UDim.new(0, visible and 10 or 0)
        end
    end

    local function childToggle(text, key)
        return {
            Type = "Toggle",
            Text = text,
            Default = false,
            Callback = function(state)
                ESPState[role][key] = state
                updateESP()
            end,
        }
    end

    parentToggle = category:Toggle({
        Text = title,
        Default = false,
        Callback = function(state)
            ESPState[role].Enabled = state
            setChildrenVisible(state)
            updateESP()
        end,
        Sub = {
            childToggle("Distance", "Distance"),
            childToggle("Health", "Health"),
            childToggle("Level", "Level"),
        },
    })

    local firstChild = parentToggle.Subs and parentToggle.Subs[1]
    childrenHolder = firstChild and firstChild.Frame.Parent
    setChildrenVisible(false)

    return parentToggle
end

createESPGroup(ESP, "Killer ESP", "Killer")
createESPGroup(ESP, "Survivors ESP", "Survivors")

Visuals:Toggle({
    Text = "Fullbright",
    Default = false,
    Callback = setFullbright,
})

Visuals:Toggle({
    Text = "No Fog",
    Default = false,
    Callback = setNoFog,
})

Movement:Toggle({
    Text = "Noclip",
    Default = false,
    Callback = function(state)
        noclipEnabled = state
        if not state then
            restoreNoclip()
        end
    end,
})

Movement:Toggle({
    Text = "Speedhack",
    Default = false,
    Callback = function(state)
        if speedControl then
            speedControl.Enabled = state
        end
        setSpeedhack(state)
    end,
})

Movement:Toggle({
    Text = "Jumphack",
    Default = false,
    Callback = function(state)
        if jumpControl then
            jumpControl.Enabled = state
        end
        setJumphack(state)
    end,
})

local humanoid = getHumanoid()
if humanoid then
    speedBase = humanoid.WalkSpeed
    jumpBase = readJumpProperty(humanoid)
end

speedControl = createMovementControl("Speed value", speedBase, function(value)
    if speedControl and speedControl.Enabled then
        applySpeed(value)
    end
end)

jumpControl = createMovementControl("Jump value", jumpBase, function(value)
    if jumpControl and jumpControl.Enabled then
        applyJump(value)
    end
end)

speedControl.Enabled = speedEnabled
jumpControl.Enabled = jumpEnabled

Window:Loop(ESP_INTERVAL, function()
    if ESPState.Killer.Enabled or ESPState.Survivors.Enabled then
        updateESP()
    else
        for model in pairs(ESPObjects) do
            removeESP(model)
        end
        for model in pairs(ESPHighlights) do
            removeESP(model)
        end
    end

    if noFogEnabled then
        setNoFog(true)
    end
end)

Window:Loop(MOVEMENT_INTERVAL, function()
    local currentHumanoid = getHumanoid()
    if currentHumanoid then
        if not speedEnabled then
            speedBase = currentHumanoid.WalkSpeed
            if speedControl then
                speedControl:SetBase(speedBase)
                speedControl:Set(speedBase, true)
            end
        elseif speedApplied == nil or math.abs(currentHumanoid.WalkSpeed - speedApplied) > 0.01 then
            if speedApplied ~= nil then
                speedBase = currentHumanoid.WalkSpeed
                if speedControl then
                    speedControl:SetBase(speedBase)
                end
            end
            applySpeed(speedControl and speedControl.Value or speedBase)
        end

        local currentJump = readJumpProperty(currentHumanoid)
        if not jumpEnabled then
            jumpBase = currentJump
            if jumpControl then
                jumpControl:SetBase(jumpBase)
                jumpControl:Set(jumpBase, true)
            end
        elseif jumpApplied == nil or math.abs(currentJump - jumpApplied) > 0.01 then
            if jumpApplied ~= nil then
                jumpBase = currentJump
                if jumpControl then
                    jumpControl:SetBase(jumpBase)
                end
            end
            applyJump(jumpControl and jumpControl.Value or jumpBase)
        end
    end
end)

Window:Connect(RunService.Stepped, function()
    if noclipEnabled then
        updateNoclip()
    end
end)

Window:Connect(LocalPlayer.CharacterAdded, function(character)
    local newHumanoid = character:WaitForChild("Humanoid", 15)
    if newHumanoid then
        speedBase = newHumanoid.WalkSpeed
        jumpBase = readJumpProperty(newHumanoid)
        speedApplied = nil
        jumpApplied = nil
        if speedEnabled then
            applySpeed(speedControl and speedControl.Value or speedBase)
        end
        if jumpEnabled then
            applyJump(jumpControl and jumpControl.Value or jumpBase)
        end
    end
end)

Window:OnClose(function()
    setFullbright(false)
    setNoFog(false)
    speedEnabled = false
    jumpEnabled = false
    local currentHumanoid = getHumanoid()
    if currentHumanoid then
        currentHumanoid.WalkSpeed = speedBase
        writeJumpProperty(currentHumanoid, jumpBase)
    end
    noclipEnabled = false
    restoreNoclip()
    for model in pairs(ESPObjects) do
        removeESP(model)
    end
    for model in pairs(ESPHighlights) do
        removeESP(model)
    end
end)
