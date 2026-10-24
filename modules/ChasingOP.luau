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
    Title = "{gamename} | By Kiyatsuka v1.0.2",
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

    local root = getCharacterRoot(character)
    local grounded = false
    if root then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { character }
        local result = workspace:Raycast(root.Position, Vector3.new(0, -4.5, 0), params)
        grounded = result ~= nil
    end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if noclipOriginal[part] == nil then
                noclipOriginal[part] = part.CanCollide
            end
            local lowerPart = part.Name:find("Leg") or part.Name:find("Foot") or part.Name == "LeftLowerLeg" or part.Name == "RightLowerLeg"
            part.CanCollide = grounded and lowerPart ~= nil or false
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
