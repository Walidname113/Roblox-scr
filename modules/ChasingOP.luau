local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

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

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local legacyPlayerPicker = PlayerGui:FindFirstChild("ChasingOPPlayerPicker")
if legacyPlayerPicker then
    legacyPlayerPicker:Destroy()
end

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
    Title = "{gamename} | By Kiyatsuka v1.4.0",
})

if MinimizedIcon ~= "" then
    Window:SetMinimizedImage(MinimizedIcon)
end

local Main = Window:Category("Main")
local ESP = Window:Category("ESP")
local Halloween = Window:Category("Halloween Event")
local Visuals = Window:Category("Visuals")
local Movement = Window:Category("Movement")

local ESP_INTERVAL = 0.2
local MOVEMENT_INTERVAL = 0.5

local ESPState = {
    Killer = { Enabled = false, Distance = false, Health = false, Level = false },
    Survivors = { Enabled = false, Distance = false, Health = false, Level = false },
}

local smartESPEnabled = false
local smartUsePresets = false
local SMART_DEFAULT_INFO = { Distance = true, Health = false, Level = false }

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
local collectNoclipActive = false
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

local function getSmartTargetRole()
    local killerName = getKillerName()
    if not killerName then
        return nil
    end
    if LocalPlayer.Name == killerName then
        return "Survivors"
    end
    if isInGame(LocalPlayer) then
        return "Killer"
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
    local enabled = role ~= nil
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

    local smartTarget = smartESPEnabled and getSmartTargetRole() or nil
    local activeModels = {}

    for _, model in ipairs(characters:GetChildren()) do
        if model:IsA("Model") and model ~= LocalPlayer.Character then
            local role = getCharacterRole(model)
            local player = Players:FindFirstChild(model.Name)
            local state = nil
            local allowed = false
            if role then
                if smartESPEnabled then
                    allowed = role == smartTarget
                    state = smartUsePresets and ESPState[role] or SMART_DEFAULT_INFO
                else
                    allowed = ESPState[role].Enabled
                    state = ESPState[role]
                end
            end
            if role == "Survivors" and player and not isInGame(player) then
                allowed = false
            end
            if allowed and getCharacterRoot(model) then
                activeModels[model] = true
                local gui = ESPObjects[model] or createESP(model)
                gui.Adornee = getCharacterRoot(model)
                local label = gui:FindFirstChild("Label")
                local lines = { model.Name }
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

local FREE_ZOOM_MIN = 0.5
local FREE_ZOOM_MAX = 100000
local freeZoomEnabled = false
local freeZoomOriginal = nil

local function setFreeZoom(enabled)
    if enabled then
        if not freeZoomOriginal then
            freeZoomOriginal = {
                Min = LocalPlayer.CameraMinZoomDistance,
                Max = LocalPlayer.CameraMaxZoomDistance,
                Mode = LocalPlayer.CameraMode,
            }
        end
        freeZoomEnabled = true
    else
        freeZoomEnabled = false
        if freeZoomOriginal then
            local original = freeZoomOriginal
            freeZoomOriginal = nil
            pcall(function()
                LocalPlayer.CameraMaxZoomDistance = original.Max
                LocalPlayer.CameraMinZoomDistance = original.Min
                LocalPlayer.CameraMode = original.Mode
            end)
        end
    end
end

local function updateFreeZoom()
    if not freeZoomEnabled then
        return
    end
    if LocalPlayer.CameraMaxZoomDistance ~= FREE_ZOOM_MAX then
        LocalPlayer.CameraMaxZoomDistance = FREE_ZOOM_MAX
    end
    if LocalPlayer.CameraMinZoomDistance ~= FREE_ZOOM_MIN then
        LocalPlayer.CameraMinZoomDistance = FREE_ZOOM_MIN
    end
    if LocalPlayer.CameraMode ~= Enum.CameraMode.Classic then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
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
    if not noclipEnabled and not collectNoclipActive then
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

local MainTheme = {
    Card = Color3.fromRGB(17, 18, 25),
    CardHover = Color3.fromRGB(24, 23, 35),
    Border = Color3.fromRGB(47, 45, 61),
    Accent = Color3.fromRGB(168, 85, 247),
    AccentSoft = Color3.fromRGB(111, 65, 171),
    Text = Color3.fromRGB(246, 243, 252),
}

local function createMainSection(text)
    return Main:Label({
        Text = string.upper(text),
        Bold = true,
        TextSize = 11,
        Color = MainTheme.Accent,
        Height = 20,
    })
end

local function createMainButton(config)
    local widget = Main:Button({
        Text = config.Text,
        Description = config.Description,
        Callback = config.Callback,
        DescStyle = {
            Color = Color3.fromRGB(151, 148, 166),
            TextSize = 11,
        },
    })

    local card = widget.Frame
    local top = card:FindFirstChildWhichIsA("Frame")
    card.BackgroundColor3 = MainTheme.Card
    card.BorderSizePixel = 0

    local corner = card:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = card

    local stroke = card:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
    stroke.Color = MainTheme.Border
    stroke.Thickness = 1
    stroke.Transparency = 0.1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = card

    local gradient = card:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(224, 218, 235)),
    })
    gradient.Rotation = 25
    gradient.Parent = card

    if top then
        local accent = Instance.new("Frame")
        accent.Name = "MainActionAccent"
        accent.AnchorPoint = Vector2.new(0, 0.5)
        accent.Position = UDim2.new(0, 0, 0.5, 0)
        accent.Size = UDim2.fromOffset(3, 20)
        accent.BackgroundColor3 = MainTheme.Accent
        accent.BorderSizePixel = 0
        accent.ZIndex = 3
        accent.Parent = top
        local accentCorner = Instance.new("UICorner")
        accentCorner.CornerRadius = UDim.new(1, 0)
        accentCorner.Parent = accent

        local chevron = Instance.new("TextLabel")
        chevron.Name = "MainActionChevron"
        chevron.AnchorPoint = Vector2.new(1, 0.5)
        chevron.Position = UDim2.new(1, -12, 0.5, 0)
        chevron.Size = UDim2.fromOffset(16, 22)
        chevron.BackgroundTransparency = 1
        chevron.Font = Enum.Font.GothamBold
        chevron.Text = "›"
        chevron.TextSize = 22
        chevron.TextColor3 = MainTheme.AccentSoft
        chevron.ZIndex = 3
        chevron.Parent = top

        local hitbox = top:FindFirstChildWhichIsA("GuiButton", true)
        local hoverTarget = hitbox or top
        Window:Connect(hoverTarget.MouseEnter, function()
            TweenService:Create(card, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = MainTheme.CardHover,
            }):Play()
            TweenService:Create(stroke, TweenInfo.new(0.16), {
                Color = MainTheme.Accent,
                Transparency = 0,
            }):Play()
            TweenService:Create(accent, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(4, 28),
            }):Play()
            chevron.TextColor3 = MainTheme.Text
        end)
        Window:Connect(hoverTarget.MouseLeave, function()
            TweenService:Create(card, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = MainTheme.Card,
            }):Play()
            TweenService:Create(stroke, TweenInfo.new(0.16), {
                Color = MainTheme.Border,
                Transparency = 0.1,
            }):Play()
            TweenService:Create(accent, TweenInfo.new(0.16), {
                Size = UDim2.fromOffset(3, 20),
            }):Play()
            chevron.TextColor3 = MainTheme.AccentSoft
        end)
    end

    return widget
end

local TAP_SLOP = 10
local PICKER_ROW_HEIGHT = 44
local PICKER_ROW_GAP = 4
local PICKER_MAX_ROWS = 6
local PICKER_LIST_PADDING = 6
local PICKER_HEADER_HEIGHT = 48
local BOUND_TELEPORT_OFFSET = CFrame.new(0, 0, 3)
local MutedText = Color3.fromRGB(151, 148, 166)

local boundTeleportEnabled = false
local boundToggle = nil
local spectateTarget = nil
local teleportPicker = nil
local spectatePicker = nil

local function safeCall(callback, ...)
    local ok, err = pcall(callback, ...)
    if not ok then
        warn("[ChasingOP] " .. tostring(err))
    end
end

local function isPressInput(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function newGui(className, props, parent)
    local instance = Instance.new(className)
    if instance:IsA("GuiObject") then
        instance.BorderSizePixel = 0
        instance.BackgroundTransparency = (props.BackgroundColor3 and props.BackgroundTransparency == nil) and 0 or 1
        if instance:IsA("GuiButton") then
            instance.AutoButtonColor = false
        end
    end
    if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
        instance.Text = ""
        instance.Font = Enum.Font.Gotham
        instance.TextSize = 13
        instance.TextColor3 = MainTheme.Text
    end
    for key, value in pairs(props) do
        instance[key] = value
    end
    instance.Parent = parent
    return instance
end

local function roundify(instance, radius)
    return newGui("UICorner", { CornerRadius = UDim.new(0, radius) }, instance)
end

local function outline(instance, color, transparency)
    return newGui("UIStroke", {
        Color = color,
        Thickness = 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, instance)
end

local function tweenProperty(instance, duration, props)
    local tween = TweenService:Create(instance, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tween:Play()
    return tween
end

local function createScrollGuard(scroller)
    local guard = { LastMove = 0 }
    scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        guard.LastMove = os.clock()
    end)
    function guard.Begin()
        return {
            Canvas = scroller.CanvasPosition.Y,
            Settling = os.clock() - guard.LastMove < 0.15,
        }
    end
    function guard.Valid(snapshot)
        return not snapshot.Settling and math.abs(scroller.CanvasPosition.Y - snapshot.Canvas) < 2
    end
    return guard
end

local function bindTap(gui, callback, guard)
    local origin = nil
    local snapshot = nil
    gui.InputBegan:Connect(function(input)
        if isPressInput(input) then
            origin = input.Position
            snapshot = guard and guard.Begin() or nil
        end
    end)
    gui.InputEnded:Connect(function(input)
        if not isPressInput(input) or not origin then
            return
        end
        local moved = (input.Position - origin).Magnitude
        local valid = moved < TAP_SLOP and (not guard or guard.Valid(snapshot))
        origin = nil
        snapshot = nil
        if valid then
            callback()
        end
    end)
end

local pageGuard = createScrollGuard(Main._page)

local function reserveLayoutOrder(category)
    local placeholder = category:Label({ Text = "", Height = 0 })
    local order = placeholder.Frame.LayoutOrder
    placeholder:Destroy()
    return order
end

local function playerDisplayText(player)
    if player.DisplayName ~= player.Name then
        return player.DisplayName .. " (@" .. player.Name .. ")"
    end
    return player.Name
end

local function playerThumbnail(player)
    return "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=48&h=48"
end

local function collectPlayers()
    local result = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            result[#result + 1] = player
        end
    end
    table.sort(result, function(a, b)
        local left = a.DisplayName:lower()
        local right = b.DisplayName:lower()
        if left == right then
            return a.Name:lower() < b.Name:lower()
        end
        return left < right
    end)
    return result
end

local PLAYER_TAGS = {
    Killer = {
        Text = "KILLER",
        Fill = Color3.fromRGB(255, 45, 45),
        Ink = Color3.fromRGB(255, 110, 110),
    },
    Survivor = {
        Text = "SURVIVOR",
        Fill = Color3.fromRGB(50, 135, 255),
        Ink = Color3.fromRGB(100, 180, 255),
    },
    Lobby = {
        Text = "LOBBY",
        Fill = Color3.fromRGB(255, 255, 255),
        Ink = Color3.fromRGB(255, 255, 255),
    },
}

local function getPlayerTag(player, killerName)
    if killerName and player.Name == killerName then
        return PLAYER_TAGS.Killer
    end
    if isInGame(player) then
        return PLAYER_TAGS.Survivor
    end
    return PLAYER_TAGS.Lobby
end

local function createPlayerPicker(config)
    local picker = {}
    local selected = nil
    local actions = config.Actions or {}
    local inline = config.Inline == true and #actions > 0
    local inlineWidth = 92
    local step = PICKER_ROW_HEIGHT + PICKER_ROW_GAP

    local card = newGui("Frame", {
        Name = config.Name,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = MainTheme.Card,
        LayoutOrder = config.Order,
    }, Main._page)
    roundify(card, 10)
    outline(card, MainTheme.Border, 0.1)
    newGui("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, card)
    newGui("UIPadding", { PaddingBottom = UDim.new(0, 12) }, card)

    local header = newGui("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        LayoutOrder = 1,
    }, card)

    local selector = newGui("TextButton", {
        Name = "Selector",
        Size = UDim2.new(1, -(24 + (inline and inlineWidth + 8 or 0)), 0, 34),
        Position = UDim2.new(0, 12, 0.5, -17),
        BackgroundColor3 = MainTheme.CardHover,
    }, header)
    roundify(selector, 8)
    local selectorStroke = outline(selector, MainTheme.Border, 0)

    local avatar = newGui("ImageLabel", {
        Size = UDim2.fromOffset(22, 22),
        Position = UDim2.new(0, 8, 0.5, -11),
        BackgroundColor3 = MainTheme.Card,
        Visible = false,
    }, selector)
    roundify(avatar, 11)

    local selectorText = newGui("TextLabel", {
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -36, 1, 0),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, selector)

    newGui("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        Text = "▼",
        TextSize = 9,
        TextColor3 = MainTheme.AccentSoft,
    }, selector)

    selector.MouseEnter:Connect(function()
        tweenProperty(selectorStroke, 0.16, { Color = MainTheme.Accent })
    end)
    selector.MouseLeave:Connect(function()
        tweenProperty(selectorStroke, 0.16, { Color = MainTheme.Border })
    end)

    local function refreshSelector()
        if selected then
            avatar.Image = playerThumbnail(selected)
            avatar.Visible = true
            selectorText.Position = UDim2.fromOffset(38, 0)
            selectorText.Size = UDim2.new(1, -62, 1, 0)
            selectorText.Text = config.Label .. ": " .. playerDisplayText(selected)
            selectorText.TextColor3 = MainTheme.Text
        else
            avatar.Visible = false
            selectorText.Position = UDim2.fromOffset(12, 0)
            selectorText.Size = UDim2.new(1, -36, 1, 0)
            selectorText.Text = config.Empty or (config.Label .. ": ---")
            selectorText.TextColor3 = MutedText
        end
    end
    refreshSelector()

    local function choose(player)
        if player == selected then
            return
        end
        selected = player
        refreshSelector()
        if config.OnChange then
            safeCall(config.OnChange, player)
        end
    end

    local function createActionButton(parent, action, size, position)
        local primary = action.Primary == true
        local base = primary and MainTheme.Accent or MainTheme.CardHover
        local hover = primary and Color3.fromRGB(186, 117, 250) or MainTheme.Border
        local button = newGui("TextButton", {
            Size = size,
            Position = position,
            BackgroundColor3 = base,
            Text = action.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = MainTheme.Text,
        }, parent)
        roundify(button, 8)
        outline(button, primary and MainTheme.AccentSoft or MainTheme.Border, 0)
        button.MouseEnter:Connect(function()
            tweenProperty(button, 0.16, { BackgroundColor3 = hover })
        end)
        button.MouseLeave:Connect(function()
            tweenProperty(button, 0.16, { BackgroundColor3 = base })
        end)
        bindTap(button, function()
            tweenProperty(button, 0.08, { BackgroundColor3 = MainTheme.AccentSoft }).Completed:Once(function()
                tweenProperty(button, 0.16, { BackgroundColor3 = base })
            end)
            safeCall(action.Callback, selected)
        end, pageGuard)
        return button
    end

    if inline then
        createActionButton(
            header,
            actions[1],
            UDim2.fromOffset(inlineWidth, 34),
            UDim2.new(1, -(12 + inlineWidth), 0.5, -17)
        )
    elseif #actions > 0 then
        local row = newGui("Frame", {
            Size = UDim2.new(1, 0, 0, 34),
            LayoutOrder = 2,
        }, card)
        local holder = newGui("Frame", {
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -24, 1, 0),
        }, row)
        newGui("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
        }, holder)
        local count = #actions
        for index, action in ipairs(actions) do
            local button = createActionButton(
                holder,
                action,
                UDim2.new(1 / count, -8 * (count - 1) / count, 1, 0),
                UDim2.new()
            )
            button.LayoutOrder = index
        end
    end

    if type(config.Description) == "string" and config.Description ~= "" then
        local holder = newGui("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 3,
        }, card)
        newGui("UIPadding", {
            PaddingLeft = UDim.new(0, 14),
            PaddingRight = UDim.new(0, 14),
        }, holder)
        newGui("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = config.Description,
            TextColor3 = MutedText,
            TextSize = 11,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, holder)
    end

    local function openList()
        Window:_closePopup()
        local layer = Window._popups
        local players = collectPlayers()
        local killerName = getKillerName()

        local dim = newGui("TextButton", {
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 1,
        }, layer)

        local anchorPosition = selector.AbsolutePosition
        local anchorSize = selector.AbsoluteSize
        local viewport = layer.AbsoluteSize
        local width = math.max(anchorSize.X, 240)
        local visibleRows = math.clamp(#players + 1, 2, PICKER_MAX_ROWS)
        local listHeight = visibleRows * step - PICKER_ROW_GAP + PICKER_LIST_PADDING * 2
        local panelHeight = PICKER_HEADER_HEIGHT + listHeight + 8
        local below = viewport.Y - (anchorPosition.Y + anchorSize.Y + 4) - 8
        local above = anchorPosition.Y - 4 - 8
        local placeBelow = panelHeight <= below or below >= above
        local space = placeBelow and below or above
        if panelHeight > space then
            listHeight = math.max(2 * step, listHeight - (panelHeight - space))
            panelHeight = PICKER_HEADER_HEIGHT + listHeight + 8
        end
        local y = placeBelow and (anchorPosition.Y + anchorSize.Y + 4) or (anchorPosition.Y - 4 - panelHeight)
        y = math.max(y, 8)
        local x = math.clamp(anchorPosition.X, 8, math.max(8, viewport.X - width - 8))

        local panel = newGui("Frame", {
            Size = UDim2.fromOffset(width, panelHeight),
            Position = UDim2.fromOffset(x, y),
            BackgroundColor3 = MainTheme.Card,
            Active = true,
            ZIndex = 2,
        }, layer)
        roundify(panel, 10)
        outline(panel, MainTheme.Accent, 0.2)

        local search = newGui("TextBox", {
            Position = UDim2.fromOffset(8, 8),
            Size = UDim2.new(1, -16, 0, 32),
            BackgroundColor3 = MainTheme.CardHover,
            PlaceholderText = "Search player...",
            PlaceholderColor3 = Color3.fromRGB(110, 108, 125),
            ClearTextOnFocus = false,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, panel)
        roundify(search, 8)
        outline(search, MainTheme.Border, 0)
        newGui("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
        }, search)

        local list = newGui("ScrollingFrame", {
            Position = UDim2.fromOffset(0, PICKER_HEADER_HEIGHT),
            Size = UDim2.new(1, 0, 0, listHeight),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = MainTheme.Accent,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            CanvasSize = UDim2.new(),
        }, panel)
        newGui("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, PICKER_ROW_GAP),
        }, list)
        newGui("UIPadding", {
            PaddingTop = UDim.new(0, PICKER_LIST_PADDING),
            PaddingBottom = UDim.new(0, PICKER_LIST_PADDING),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
        }, list)

        local listGuard = createScrollGuard(list)

        local closed = false
        local function close()
            if closed then
                return
            end
            closed = true
            if Window._popupClose == close then
                Window._popupClose = nil
            end
            dim:Destroy()
            panel:Destroy()
        end
        Window._popupClose = close
        dim.Activated:Connect(close)

        local function addRow(order, player)
            local isNone = player == nil
            local isSelected = (isNone and selected == nil) or (not isNone and player == selected)
            local row = newGui("TextButton", {
                Name = isNone and "None" or player.Name,
                Size = UDim2.new(1, 0, 0, PICKER_ROW_HEIGHT),
                LayoutOrder = order,
                BackgroundColor3 = isSelected and MainTheme.AccentSoft or MainTheme.CardHover,
                BackgroundTransparency = isSelected and 0.55 or 1,
            }, list)
            roundify(row, 8)
            if isSelected then
                outline(row, MainTheme.Accent, 0.3)
            end
            row.MouseEnter:Connect(function()
                if not isSelected then
                    tweenProperty(row, 0.12, { BackgroundTransparency = 0.35 })
                end
            end)
            row.MouseLeave:Connect(function()
                if not isSelected then
                    tweenProperty(row, 0.12, { BackgroundTransparency = 1 })
                end
            end)

            if isNone then
                newGui("TextLabel", {
                    Position = UDim2.fromOffset(14, 0),
                    Size = UDim2.new(1, -28, 1, 0),
                    Text = "None",
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    TextColor3 = MutedText,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, row)
            else
                local thumb = newGui("ImageLabel", {
                    Position = UDim2.new(0, 8, 0.5, -15),
                    Size = UDim2.fromOffset(30, 30),
                    BackgroundColor3 = MainTheme.Card,
                    Image = playerThumbnail(player),
                }, row)
                roundify(thumb, 15)

                local sameName = player.DisplayName == player.Name
                newGui("TextLabel", {
                    Position = UDim2.fromOffset(48, sameName and 0 or 6),
                    Size = UDim2.new(1, -144, 0, sameName and PICKER_ROW_HEIGHT or 17),
                    Text = player.DisplayName,
                    Font = Enum.Font.GothamBold,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                }, row)
                if not sameName then
                    newGui("TextLabel", {
                        Position = UDim2.fromOffset(48, 23),
                        Size = UDim2.new(1, -144, 0, 14),
                        Text = "@" .. player.Name,
                        TextSize = 11,
                        TextColor3 = MutedText,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                    }, row)
                end
                local tag = getPlayerTag(player, killerName)
                local badge = newGui("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, isSelected and -30 or -8, 0.5, 0),
                    Size = UDim2.fromOffset(62, 18),
                    BackgroundColor3 = tag.Fill,
                    BackgroundTransparency = 0.78,
                    Text = tag.Text,
                    Font = Enum.Font.GothamBold,
                    TextSize = 10,
                    TextColor3 = tag.Ink,
                }, row)
                roundify(badge, 9)
                if isSelected then
                    newGui("TextLabel", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.new(1, -10, 0.5, 0),
                        Size = UDim2.fromOffset(16, 16),
                        Text = "✓",
                        Font = Enum.Font.GothamBold,
                        TextSize = 14,
                        TextColor3 = MainTheme.Accent,
                    }, row)
                end
            end

            bindTap(row, function()
                close()
                choose(player)
            end, listGuard)
        end

        local function rebuild()
            for _, child in ipairs(list:GetChildren()) do
                if child:IsA("GuiObject") then
                    child:Destroy()
                end
            end
            local query = string.lower(search.Text)
            local entries = {}
            if query == "" then
                entries[#entries + 1] = { None = true }
            end
            for _, player in ipairs(players) do
                if query == ""
                    or string.find(string.lower(player.DisplayName), query, 1, true)
                    or string.find(string.lower(player.Name), query, 1, true)
                then
                    entries[#entries + 1] = { Player = player }
                end
            end

            local selectedIndex = nil
            if #entries == 0 then
                newGui("TextLabel", {
                    Size = UDim2.new(1, 0, 0, PICKER_ROW_HEIGHT),
                    Text = "No players found",
                    TextSize = 12,
                    TextColor3 = MutedText,
                }, list)
            end
            for index, entry in ipairs(entries) do
                if (entry.None and selected == nil) or (entry.Player and entry.Player == selected) then
                    selectedIndex = index
                end
                addRow(index, entry.Player)
            end

            list.CanvasSize = UDim2.fromOffset(0, math.max(#entries, 1) * step - PICKER_ROW_GAP + PICKER_LIST_PADDING * 2)
            return selectedIndex
        end

        local selectedIndex = rebuild()
        if selectedIndex and selectedIndex > 2 then
            list.CanvasPosition = Vector2.new(0, (selectedIndex - 2) * step)
        end

        search:GetPropertyChangedSignal("Text"):Connect(function()
            list.CanvasPosition = Vector2.zero
            rebuild()
        end)
    end

    bindTap(selector, openList, pageGuard)

    Window:Connect(Players.PlayerRemoving, function(player)
        if selected == player then
            choose(nil)
        end
    end)

    picker.Frame = card
    function picker.Get()
        return selected
    end
    function picker.Set(player)
        choose(player)
    end
    return picker
end

local function updateBoundTeleport()
    if not boundTeleportEnabled or not teleportPicker then
        return
    end
    local target = teleportPicker.Get()
    if not target or target.Parent ~= Players then
        return
    end
    local character = getPlayerCharacter(target)
    local targetRoot = character and getCharacterRoot(character)
    local localRoot = getCharacterRoot(LocalPlayer.Character)
    if not targetRoot or not localRoot then
        return
    end
    localRoot.CFrame = targetRoot.CFrame * BOUND_TELEPORT_OFFSET
    localRoot.AssemblyLinearVelocity = Vector3.zero
    localRoot.AssemblyAngularVelocity = Vector3.zero
end

local function getSpectateHumanoid(player)
    local character = getPlayerCharacter(player)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function stopSpectate()
    spectateTarget = nil
    local camera = workspace.CurrentCamera
    local humanoid = getHumanoid()
    if camera and humanoid then
        camera.CameraSubject = humanoid
    end
end

local function startSpectate(player)
    if not player or player.Parent ~= Players then
        warn("Spectate: select an available player first")
        return
    end
    local camera = workspace.CurrentCamera
    local humanoid = getSpectateHumanoid(player)
    if not camera or not humanoid then
        warn("Spectate: selected player's character not found")
        return
    end
    spectateTarget = player
    camera.CameraSubject = humanoid
end

local function updateSpectate()
    if not spectateTarget then
        return
    end
    if spectateTarget.Parent ~= Players then
        stopSpectate()
        return
    end
    local camera = workspace.CurrentCamera
    local humanoid = getSpectateHumanoid(spectateTarget)
    if camera and humanoid and camera.CameraSubject ~= humanoid then
        camera.CameraSubject = humanoid
    end
end

createMainSection("Players")

teleportPicker = createPlayerPicker({
    Name = "TeleportPlayerPicker",
    Order = reserveLayoutOrder(Main),
    Label = "Target player",
    Description = "Open the list, choose a player, then press Teleport.",
    Inline = true,
    Actions = {
        {
            Text = "Teleport",
            Primary = true,
            Callback = function(player)
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
        },
    },
    OnChange = function(player)
        if player == nil and boundTeleportEnabled then
            boundTeleportEnabled = false
            if boundToggle then
                boundToggle:Set(false, true)
            end
        end
    end,
})

boundToggle = Main:Toggle({
    Text = "Bound teleport",
    Description = "Keep teleporting behind the selected target player while enabled.",
    Default = false,
    Callback = function(state)
        if state then
            local target = teleportPicker and teleportPicker.Get()
            if not target or target.Parent ~= Players then
                warn("Bound teleport: select an available player first")
                boundTeleportEnabled = false
                if boundToggle then
                    boundToggle:Set(false, true)
                end
                return
            end
        end
        boundTeleportEnabled = state
    end,
})

createMainSection("Spectate")

spectatePicker = createPlayerPicker({
    Name = "SpectatePlayerPicker",
    Order = reserveLayoutOrder(Main),
    Label = "Spectate at",
    Empty = "Spectate at...",
    Actions = {
        { Text = "Spectate", Primary = true, Callback = startSpectate },
        { Text = "Unspectate", Callback = stopSpectate },
    },
})

createMainSection("Map")

createMainButton({
    Text = "Current Map",
    Description = "Teleport to the active map's pivot point.",
    Callback = function()
        local currentMap = getCurrentMap()
        if not currentMap then
            warn("Teleport to Current Map: current map was not found")
            return
        end
        teleportToCFrame(currentMap:GetPivot(), "Teleport to Current Map")
    end,
})

createMainButton({
    Text = "Random Phone",
    Description = "Teleport to a random phone on the active map.",
    Callback = function()
        teleportToRandomMapObject("_Phones", "Teleport to Random Phone")
    end,
})

createMainButton({
    Text = "Random Power",
    Description = "Teleport to a random power object on the active map.",
    Callback = function()
        teleportToRandomMapObject("_Powers", "Teleport to Random Power")
    end,
})

local ESP_INFO_KEYS = { "Distance", "Health", "Level" }
local ESPGroups = {}

local function refreshESPGroups()
    for _, group in ipairs(ESPGroups) do
        group.Refresh()
    end
end

local function makeLockable(widget)
    local nativeSet = widget.Set
    local lock = { Locked = false }
    function widget.Set(self, value, silent)
        if lock.Locked then
            return
        end
        return nativeSet(self, value, silent)
    end
    function lock.Force(value)
        local previous = lock.Locked
        lock.Locked = false
        nativeSet(widget, value and true or false, true)
        lock.Locked = previous
    end
    return lock
end

local function setHolderVisible(toggle, holder, visible)
    if not holder or not holder.Parent then
        return
    end
    holder.Visible = visible
    local padding = toggle.Frame:FindFirstChildOfClass("UIPadding")
    if padding then
        padding.PaddingBottom = UDim.new(0, visible and 10 or 0)
    end
end

local function createESPGroup(category, title, role)
    local group = {}
    local parentToggle = nil
    local parentLock = nil
    local childrenHolder = nil
    local subLocks = {}

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
            group.Refresh()
            updateESP()
        end,
        Sub = {
            childToggle("Distance", "Distance"),
            childToggle("Health", "Health"),
            childToggle("Level", "Level"),
        },
    })

    parentLock = makeLockable(parentToggle)
    for index, subToggle in ipairs(parentToggle.Subs) do
        subLocks[index] = makeLockable(subToggle)
    end
    local firstChild = parentToggle.Subs and parentToggle.Subs[1]
    childrenHolder = firstChild and firstChild.Frame.Parent

    function group.Refresh()
        local smart = smartESPEnabled
        local info = ESPState[role]
        parentLock.Force(info.Enabled and not smart)
        parentLock.Locked = smart
        local subsShown = (not smart and info.Enabled) or (smart and smartUsePresets)
        setHolderVisible(parentToggle, childrenHolder, subsShown)
        local subsOn = (not smart) or smartUsePresets
        for index, key in ipairs(ESP_INFO_KEYS) do
            subLocks[index].Force(subsOn and info[key])
            subLocks[index].Locked = smart and not smartUsePresets
        end
    end

    ESPGroups[#ESPGroups + 1] = group
    group.Refresh()
    return parentToggle
end

local smartToggle = nil
local smartChildrenHolder = nil

smartToggle = ESP:Toggle({
    Text = "Smart ESP",
    Default = false,
    Callback = function(state)
        smartESPEnabled = state
        setHolderVisible(smartToggle, smartChildrenHolder, state)
        refreshESPGroups()
        updateESP()
    end,
    Sub = {
        {
            Type = "Toggle",
            Text = "Use your sub-toggle presets",
            Default = false,
            Callback = function(state)
                smartUsePresets = state
                refreshESPGroups()
                updateESP()
            end,
        },
    },
})

local smartFirstChild = smartToggle.Subs and smartToggle.Subs[1]
smartChildrenHolder = smartFirstChild and smartFirstChild.Frame.Parent
setHolderVisible(smartToggle, smartChildrenHolder, false)

createESPGroup(ESP, "Killer ESP", "Killer")
createESPGroup(ESP, "Survivors ESP", "Survivors")

local HIGHLIGHT_LIMIT = 31
local PUMPKIN_ESP_LIMIT = 20
local AUTO_COLLECT_INTERVAL = 0.2
local COLLECT_DEPTH = 40
local COLLECT_SPEED = 140
local COLLECT_WALK_TIME = 0.4
local COLLECT_WALK_INTERVAL = 0.05
local PUMPKIN_PATH = { "Pumpkin Coin", "Pumpkin Coin" }
local PUMPKIN_FILL = Color3.fromRGB(255, 140, 0)
local PUMPKIN_OUTLINE = Color3.fromRGB(150, 70, 0)

local pumpkinEspEnabled = false
local pumpkinHighlights = {}
local autoCollectEnabled = false
local autoCollectRunning = false

local function getDropObjects()
    local cantQuery = workspace:FindFirstChild("_CantQuery")
    return cantQuery and cantQuery:FindFirstChild("DropObjects")
end

local function collectByPath(root, path, depth, result)
    local name = path[depth]
    for _, child in ipairs(root:GetChildren()) do
        if child.Name == name then
            if depth == #path then
                result[#result + 1] = child
            else
                collectByPath(child, path, depth + 1, result)
            end
        end
    end
end

local function getPumpkins()
    local pumpkins = {}
    local dropObjects = getDropObjects()
    if not dropObjects then
        return pumpkins
    end
    local targets = {}
    collectByPath(dropObjects, PUMPKIN_PATH, 1, targets)
    for _, target in ipairs(targets) do
        if target:IsA("BasePart") or target:IsA("Model") then
            pumpkins[#pumpkins + 1] = target
        else
            for _, child in ipairs(target:GetChildren()) do
                if child:IsA("BasePart") or child:IsA("Model") then
                    pumpkins[#pumpkins + 1] = child
                end
            end
        end
    end
    return pumpkins
end

local function getPumpkinPosition(pumpkin)
    if pumpkin:IsA("BasePart") then
        return pumpkin.Position
    end
    return pumpkin:GetPivot().Position
end

local function destroyPumpkinHighlight(pumpkin)
    local highlight = pumpkinHighlights[pumpkin]
    if highlight then
        highlight:Destroy()
        pumpkinHighlights[pumpkin] = nil
    end
end

local function clearHalloween()
    for pumpkin in pairs(pumpkinHighlights) do
        destroyPumpkinHighlight(pumpkin)
    end
end

local function countPlayerHighlights()
    local count = 0
    for _, highlight in pairs(ESPHighlights) do
        if highlight and highlight.Parent then
            count = count + 1
        end
    end
    return count
end

local function updateHalloween()
    if not pumpkinEspEnabled then
        clearHalloween()
        return
    end

    local root = getCharacterRoot(LocalPlayer.Character)
    if not root then
        clearHalloween()
        return
    end

    local origin = root.Position
    local entries = {}
    for _, pumpkin in ipairs(getPumpkins()) do
        if pumpkin.Parent then
            entries[#entries + 1] = {
                Pumpkin = pumpkin,
                Distance = (getPumpkinPosition(pumpkin) - origin).Magnitude,
            }
        end
    end
    table.sort(entries, function(left, right)
        return left.Distance < right.Distance
    end)

    local limit = math.min(PUMPKIN_ESP_LIMIT, math.max(0, HIGHLIGHT_LIMIT - countPlayerHighlights()))
    local selected = {}
    for index = 1, math.min(limit, #entries) do
        selected[entries[index].Pumpkin] = true
    end

    for pumpkin, highlight in pairs(pumpkinHighlights) do
        if not selected[pumpkin] or not pumpkin.Parent or not highlight.Parent then
            destroyPumpkinHighlight(pumpkin)
        end
    end

    for pumpkin in pairs(selected) do
        local highlight = pumpkinHighlights[pumpkin]
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "ModernUI_Pumpkin_Highlight"
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.FillTransparency = 0.82
            highlight.OutlineTransparency = 0.1
            highlight.FillColor = PUMPKIN_FILL
            highlight.OutlineColor = PUMPKIN_OUTLINE
            highlight.Adornee = pumpkin
            highlight.Parent = pumpkin
            pumpkinHighlights[pumpkin] = highlight
        end
    end
end

local function canAutoCollect()
    if not autoCollectEnabled or not isInGame(LocalPlayer) then
        return false
    end
    local character = LocalPlayer.Character
    local root = getCharacterRoot(character)
    if not root then
        return false
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then
        return false
    end
    return true
end

local function flyTo(target)
    while canAutoCollect() do
        local dt = RunService.Heartbeat:Wait()
        local root = getCharacterRoot(LocalPlayer.Character)
        if not root then
            return false
        end
        local offset = target - root.Position
        local distance = offset.Magnitude
        local step = COLLECT_SPEED * dt
        local rotation = root.CFrame.Rotation
        if distance <= step then
            root.CFrame = CFrame.new(target) * rotation
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            return true
        end
        root.CFrame = CFrame.new(root.Position + offset.Unit * step) * rotation
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    return false
end

local function holdAt(position, duration)
    local elapsed = 0
    while elapsed < duration and canAutoCollect() do
        elapsed = elapsed + RunService.Heartbeat:Wait()
        local root = getCharacterRoot(LocalPlayer.Character)
        if not root then
            return false
        end
        root.CFrame = CFrame.new(position) * root.CFrame.Rotation
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    return canAutoCollect()
end

local function walkInside(pumpkin, center)
    local amplitude = 1
    if pumpkin:IsA("BasePart") then
        amplitude = math.clamp(math.min(pumpkin.Size.X, pumpkin.Size.Z) * 0.25, 0.2, 1.5)
    end
    local elapsed = 0
    local sinceFlip = 0
    local sign = 1
    while elapsed < COLLECT_WALK_TIME and canAutoCollect() do
        local dt = RunService.Heartbeat:Wait()
        elapsed = elapsed + dt
        sinceFlip = sinceFlip + dt
        if sinceFlip >= COLLECT_WALK_INTERVAL then
            sinceFlip = 0
            sign = -sign
        end
        local character = LocalPlayer.Character
        local root = getCharacterRoot(character)
        if not root then
            return false
        end
        root.CFrame = CFrame.new(center + Vector3.new(sign * amplitude, 0, 0)) * root.CFrame.Rotation
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:Move(Vector3.new(sign, 0, 0), false)
        end
    end
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:Move(Vector3.zero, false)
    end
    return canAutoCollect()
end

local function runCollectCycle()
    local character = LocalPlayer.Character
    local root = getCharacterRoot(character)
    if not root then
        return
    end

    autoCollectRunning = true
    collectNoclipActive = true

    local startCFrame = root.CFrame
    local home = Vector3.new(startCFrame.X, startCFrame.Y - COLLECT_DEPTH, startCFrame.Z)

    local active = flyTo(home)
    while active and canAutoCollect() do
        local pumpkins = getPumpkins()
        table.sort(pumpkins, function(left, right)
            return (getPumpkinPosition(left) - home).Magnitude < (getPumpkinPosition(right) - home).Magnitude
        end)

        if #pumpkins == 0 then
            active = holdAt(home, 0.2)
        end

        for _, pumpkin in ipairs(pumpkins) do
            if not active or not canAutoCollect() then
                active = false
                break
            end
            if pumpkin.Parent then
                local target = getPumpkinPosition(pumpkin)
                local under = Vector3.new(target.X, home.Y, target.Z)
                active = flyTo(under)
                    and flyTo(target)
                    and walkInside(pumpkin, target)
                    and flyTo(under)
                    and flyTo(home)
            end
        end
    end

    collectNoclipActive = false
    local finalCharacter = LocalPlayer.Character
    local finalRoot = getCharacterRoot(finalCharacter)
    local humanoid = finalCharacter and finalCharacter:FindFirstChildOfClass("Humanoid")
    if finalCharacter == character and finalRoot and humanoid and humanoid.Health > 0 and isInGame(LocalPlayer) then
        finalRoot.CFrame = startCFrame
        finalRoot.AssemblyLinearVelocity = Vector3.zero
        finalRoot.AssemblyAngularVelocity = Vector3.zero
    end
    autoCollectRunning = false
end

local function updateAutoCollect()
    if autoCollectRunning or not canAutoCollect() then
        return
    end
    task.spawn(function()
        local ok, err = pcall(runCollectCycle)
        collectNoclipActive = false
        autoCollectRunning = false
        if not ok then
            warn("Auto-collect pumpkins: " .. tostring(err))
        end
    end)
end

Halloween:Toggle({
    Text = "Pumpkin's ESP",
    Description = "Highlights the 20 nearest pumpkins through walls.",
    Default = false,
    Callback = function(state)
        pumpkinEspEnabled = state
        updateHalloween()
    end,
})

Halloween:Toggle({
    Text = "Auto-collect Pumpkins",
    Description = "Only on match.",
    Default = false,
    Callback = function(state)
        autoCollectEnabled = state
    end,
})

Window:Loop(AUTO_COLLECT_INTERVAL, function()
    pcall(updateAutoCollect)
end)

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

Visuals:Toggle({
    Text = "Free Zoom",
    Default = false,
    Callback = setFreeZoom,
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
    if smartESPEnabled or ESPState.Killer.Enabled or ESPState.Survivors.Enabled then
        updateESP()
    else
        for model in pairs(ESPObjects) do
            removeESP(model)
        end
        for model in pairs(ESPHighlights) do
            removeESP(model)
        end
    end

    pcall(updateHalloween)

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
    if noclipEnabled or collectNoclipActive then
        updateNoclip()
    end
end)

Window:Connect(RunService.Heartbeat, function()
    updateBoundTeleport()
end)

Window:Connect(RunService.RenderStepped, function()
    updateSpectate()
    pcall(updateFreeZoom)
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
    setFreeZoom(false)
    boundTeleportEnabled = false
    stopSpectate()
    speedEnabled = false
    jumpEnabled = false
    local currentHumanoid = getHumanoid()
    if currentHumanoid then
        currentHumanoid.WalkSpeed = speedBase
        writeJumpProperty(currentHumanoid, jumpBase)
    end
    noclipEnabled = false
    restoreNoclip()
    autoCollectEnabled = false
    collectNoclipActive = false
    clearHalloween()
    for model in pairs(ESPObjects) do
        removeESP(model)
    end
    for model in pairs(ESPHighlights) do
        removeESP(model)
    end
end)
