local REQUIRED_GAME_ID = 8795154789
if game.GameId ~= REQUIRED_GAME_ID then return end

local uiurl = "https://raw.githubusercontent.com/Walidname113/Roblox-scr/main/uncoded.lua"
local success, source = pcall(function()
    return game:HttpGet(uiurl)
end)

if not success then
    warn("Error load UI:", source)
    return
end

local moduleFunc, err = loadstring(source)
if not moduleFunc then
    warn("Error module func:", err)
    return
end

local uiModule = moduleFunc()
local ui = uiModule.CreateUI("Flick by Kiyatsuka | Version: 1.1.0 Public.")
ui.SetMinimizedImage("97837481633367")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = localPlayer:GetMouse()

local scriptRunning = true
local connections = {}

local function trackConnection(conn)
    table.insert(connections, conn)
end

local ESP_Settings = {
    Master = false,
    Box = false,
    BoxColor = Color3.fromRGB(255, 255, 0),
    Names = false,
    NamesColor = Color3.fromRGB(255, 0, 0),
    HP = false,
    Lines = false,
    LinesColor = Color3.fromRGB(0, 255, 255),
    Distance = false,
    DistanceColor = Color3.fromRGB(255, 255, 255)
}

local Aim_Settings = {
    Enabled = false,
    TargetPart = "Head",
    MaxDistance = 100,
    WallCheck = false,
    Smoothness = 0.12,
    HitboxActive = false,
    HitboxSize = 3,
    Triggerbot = false
}

local originalHeadSizes = {}
local isTouchDevice = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local isClicking = false

local R6_Bones = {
    {Name = "Head", Value = "Head"},
    {Name = "Torso", Value = "HumanoidRootPart"},
    {Name = "Left Arm", Value = "Left Arm"},
    {Name = "Right Arm", Value = "Right Arm"},
    {Name = "Left Leg", Value = "Left Leg"},
    {Name = "Right Leg", Value = "Right Leg"}
}
local currentBoneIndex = 1

local function performAutoShot()
    if isClicking then return end
    isClicking = true
    
    task.spawn(function()
        if isTouchDevice then
            local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
            VirtualInputManager:SendTouchEvent(0, Enum.UserInputState.Begin, center.X, center.Y)
            task.wait(0.05)
            VirtualInputManager:SendTouchEvent(0, Enum.UserInputState.End, center.X, center.Y)
        else
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
        task.wait(0.1)
        isClicking = false
    end)
end

local miscCategory = ui.CreateCategory("Misc")

local aimbotSubConfig = {
    {
        Type = "Checkbox",
        Text = "Triggerbot",
        State = Aim_Settings.Triggerbot,
        LayoutOrder = 1,
        Callback = function(state) Aim_Settings.Triggerbot = state end
    },
    {
        Type = "Checkbox",
        Text = "Wall Check",
        State = Aim_Settings.WallCheck,
        LayoutOrder = 2,
        Callback = function(state) Aim_Settings.WallCheck = state end
    },
    {
        Type = "Input",
        Text = "Aimbot Range",
        DefaultText = tostring(Aim_Settings.MaxDistance),
        Placeholder = "Studs (e.g. 100)",
        LayoutOrder = 3,
        Callback = function(text, enterPressed)
            local num = tonumber(text)
            if num then Aim_Settings.MaxDistance = num end
        end
    },
    {
        Type = "Button",
        Text = "Cycle R6 Bone (Current: Head)",
        LayoutOrder = 4,
        Callback = function()
            currentBoneIndex = currentBoneIndex + 1
            if currentBoneIndex > #R6_Bones then currentBoneIndex = 1 end
            
            local chosen = R6_Bones[currentBoneIndex]
            Aim_Settings.TargetPart = chosen.Value
            
            print("Aimbot target bone changed to: " .. chosen.Name)
        end
    }
}

ui.CreateToggle(
    "Aimbot", 
    miscCategory, 
    function(state) Aim_Settings.Enabled = state end,
    "Automatically locks your camera onto enemies within the selected range. Includes R6 body part filters, custom input distance, and built-in triggerbot tracking.",
    aimbotSubConfig
)

local hitboxCategory = ui.CreateCategory("Hitboxes")
ui.CreateToggle("Head Hitbox Expander", hitboxCategory, function(state)
    Aim_Settings.HitboxActive = state
end)

local espCategory = ui.CreateCategory("ESP Settings")

local espSubConfig = {
    {
        Type = "Checkbox",
        Text = "Box ESP",
        State = ESP_Settings.Box,
        LayoutOrder = 1,
        Callback = function(state) ESP_Settings.Box = state end
    },
    {
        Type = "Color",
        Text = "Box Color RGB",
        DefaultColor = ESP_Settings.BoxColor,
        LayoutOrder = 2,
        Callback = function(color) ESP_Settings.BoxColor = color end
    },
    {
        Type = "Checkbox",
        Text = "Names ESP",
        State = ESP_Settings.Names,
        LayoutOrder = 3,
        Callback = function(state) ESP_Settings.Names = state end
    },
    {
        Type = "Color",
        Text = "Names Color RGB",
        DefaultColor = ESP_Settings.NamesColor,
        LayoutOrder = 4,
        Callback = function(color) ESP_Settings.NamesColor = color end
    },
    {
        Type = "Checkbox",
        Text = "HP ESP",
        State = ESP_Settings.HP,
        LayoutOrder = 5,
        Callback = function(state) ESP_Settings.HP = state end
    },
    {
        Type = "Checkbox",
        Text = "Line ESP",
        State = ESP_Settings.Lines,
        LayoutOrder = 6,
        Callback = function(state) ESP_Settings.Lines = state end
    },
    {
        Type = "Color",
        Text = "Lines Color RGB",
        DefaultColor = ESP_Settings.LinesColor,
        LayoutOrder = 7,
        Callback = function(color) ESP_Settings.LinesColor = color end
    },
    {
        Type = "Checkbox",
        Text = "Distance ESP",
        State = ESP_Settings.Distance,
        LayoutOrder = 8,
        Callback = function(state) ESP_Settings.Distance = state end
    },
    {
        Type = "Color",
        Text = "Distance Color RGB",
        DefaultColor = ESP_Settings.DistanceColor,
        LayoutOrder = 9,
        Callback = function(color) ESP_Settings.DistanceColor = color end
    }
}

ui.CreateToggle(
    "Master ESP", 
    espCategory, 
    function(state) ESP_Settings.Master = state end,
    "Renders elements through walls to reveal opponent positions. Customize precise indicators and full RGB colors inside this module.",
    espSubConfig
)

local function isTargetVisible(part, char)
    local origin = camera.CFrame.Position
    local direction = part.Position - origin
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {localPlayer.Character, camera}
    params.FilterType = Enum.RaycastFilterType.Exclude
    
    local result = workspace:Raycast(origin, direction, params)
    return not result or result.Instance:IsDescendantOf(char)
end

local function getClosestPlayerToCursor()
    local targetPlr, targetPart = nil, nil
    local shortestDistance = math.huge

    local myChar = localPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil, nil end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= localPlayer and p.Character then
            local char = p.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local part = char:FindFirstChild(Aim_Settings.TargetPart)

            if part and hum and hum.Health > 0 then
                local distToTarget = (myHrp.Position - part.Position).Magnitude
                if distToTarget <= Aim_Settings.MaxDistance then
                    if Aim_Settings.WallCheck and not isTargetVisible(part, char) then continue end

                    local _, onScreen = camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        if distToTarget < shortestDistance then
                            shortestDistance = distToTarget
                            targetPlr = p
                            targetPart = part
                        end
                    end
                end
            end
        end
    end
    return targetPlr, targetPart
end

local function CreateESP(plr)
    local highlight = Instance.new("Highlight")
    highlight.Enabled = false
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = ui.ScreenGui

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 70)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    billboard.MaxDistance = 5000
    billboard.Parent = ui.ScreenGui

    local nameL = Instance.new("TextLabel", billboard)
    nameL.Size = UDim2.new(1, 0, 0, 20)
    nameL.BackgroundTransparency = 1
    nameL.Font = Enum.Font.SourceSansBold
    nameL.TextSize = 16
    Instance.new("UIStroke", nameL).Color = Color3.new(1,1,1)

    local hpL = Instance.new("TextLabel", billboard)
    hpL.Size = UDim2.new(1, 0, 0, 20)
    hpL.Position = UDim2.new(0, 0, 0, -20)
    hpL.BackgroundTransparency = 1
    hpL.Font = Enum.Font.SourceSansBold
    hpL.TextSize = 14
    Instance.new("UIStroke", hpL).Color = Color3.new(1,1,1)

    local distL = Instance.new("TextLabel", billboard)
    distL.Size = UDim2.new(1, 0, 0, 20)
    distL.BackgroundTransparency = 1
    distL.Font = Enum.Font.SourceSansBold
    distL.TextSize = 14
    Instance.new("UIStroke", distL).Color = Color3.new(1,1,1)

    local lineFrame = Instance.new("Frame", ui.ScreenGui)
    lineFrame.BorderSizePixel = 0
    lineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    lineFrame.ZIndex = 0
    lineFrame.Visible = false

    local renderConnection
    renderConnection = RunService.RenderStepped:Connect(function()
        if not scriptRunning then
            renderConnection:Disconnect()
            return
        end

        if not plr or not plr.Parent or not plr.Character then
            highlight.Enabled = false
            billboard.Enabled = false
            lineFrame.Visible = false
            return
        end

        local character = plr.Character
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        local hum = character:FindFirstChildOfClass("Humanoid")
        
        if head and head:IsA("BasePart") then
            if not originalHeadSizes[plr] then
                originalHeadSizes[plr] = {Size = head.Size, CanCollide = head.CanCollide}
            end
            
            if Aim_Settings.HitboxActive then
                head.Size = Vector3.new(Aim_Settings.HitboxSize, Aim_Settings.HitboxSize, Aim_Settings.HitboxSize)
                head.Transparency = 0.5
                head.CanCollide = false
            else
                head.Size = originalHeadSizes[plr].Size
                head.Transparency = 0
                head.CanCollide = originalHeadSizes[plr].CanCollide
            end
        end

        if not hrp or not hum or hum.Health <= 0 then
            highlight.Enabled = false
            billboard.Enabled = false
            lineFrame.Visible = false
            return
        end

        if not ESP_Settings.Master then
            highlight.Enabled = false
            billboard.Enabled = false
            lineFrame.Visible = false
            return
        end

        highlight.Adornee = character
        highlight.Enabled = ESP_Settings.Box
        highlight.FillColor = ESP_Settings.BoxColor

        billboard.Adornee = hrp
        billboard.Enabled = (ESP_Settings.Names or ESP_Settings.HP or ESP_Settings.Distance)
        
        local sizeOffset = (character:GetExtentsSize().Y / 2)
        billboard.StudsOffset = Vector3.new(0, sizeOffset + 1.5, 0)

        nameL.Visible = ESP_Settings.Names
        nameL.Text = plr.Name
        nameL.TextColor3 = ESP_Settings.NamesColor

        hpL.Visible = ESP_Settings.HP
        hpL.Text = "HP: " .. math.floor(hum.Health)
        hpL.TextColor3 = Color3.fromHSV(math.clamp(hum.Health/hum.MaxHealth, 0, 1) * 0.3, 1, 1)

        distL.Visible = ESP_Settings.Distance
        distL.TextColor3 = ESP_Settings.DistanceColor
        distL.Position = UDim2.new(0, 0, 0, 60) 
        
        local charDist = 0
        local myChar = localPlayer.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myHrp then
            charDist = (myHrp.Position - hrp.Position).Magnitude
            distL.Text = math.floor(charDist) .. " studs"
        end

        if ESP_Settings.Lines and ESP_Settings.Box then
            local bottomPos = hrp.Position - Vector3.new(0, sizeOffset, 0)
            local pos, onScreen = camera:WorldToViewportPoint(bottomPos)
            if onScreen then
                lineFrame.Visible = true
                local startPos = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                local endPos = Vector2.new(pos.X, pos.Y)
                local diff = endPos - startPos
                lineFrame.Size = UDim2.new(0, diff.Magnitude, 0, 1)
                lineFrame.Position = UDim2.new(0, (startPos.X + endPos.X) / 2, 0, (startPos.Y + endPos.Y) / 2)
                lineFrame.Rotation = math.deg(math.atan2(diff.Y, diff.X))
                lineFrame.BackgroundColor3 = ESP_Settings.LinesColor
            else
                lineFrame.Visible = false
            end
        else
            lineFrame.Visible = false
        end
    end)
    trackConnection(renderConnection)
end

for _, p in ipairs(Players:GetPlayers()) do 
    if p ~= localPlayer then CreateESP(p) end 
end

trackConnection(Players.PlayerAdded:Connect(function(p) 
    if p ~= localPlayer then CreateESP(p) end 
end))

trackConnection(Players.PlayerRemoving:Connect(function(p)
    originalHeadSizes[p] = nil
end))

local aimConnection
aimConnection = RunService.RenderStepped:Connect(function()
    if not scriptRunning then
        aimConnection:Disconnect()
        return
    end

    if Aim_Settings.Enabled then
        local targetPlr, targetPart = getClosestPlayerToCursor()
        if targetPart then
            local targetPos = targetPart.Position
            local targetChar = targetPlr.Character
            local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                targetPos = targetPos + (targetRoot.AssemblyLinearVelocity * 0.015)
            end
            
            local targetCFrame = CFrame.new(camera.CFrame.Position, targetPos)
            local mouseDelta = UserInputService:GetMouseDelta()
            local handResistance = mouseDelta.Magnitude
            local adaptiveSmoothness = Aim_Settings.Smoothness
            
            if handResistance > 0 then
                adaptiveSmoothness = math.clamp(Aim_Settings.Smoothness + (handResistance * 0.02), Aim_Settings.Smoothness, 0.85)
            end
            
            camera.CFrame = camera.CFrame:Lerp(targetCFrame, adaptiveSmoothness)
        end
    end

    if Aim_Settings.Triggerbot then
        local centerRay = camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {localPlayer.Character, camera}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude

        local raycastResult = workspace:Raycast(centerRay.Origin, centerRay.Direction * 1000, raycastParams)
        if raycastResult and raycastResult.Instance then
            local hitInstance = raycastResult.Instance
            local model = hitInstance:FindFirstAncestorOfClass("Model")
            if model then
                local player = Players:GetPlayerFromCharacter(model)
                if player and player ~= localPlayer then
                    local humanoid = model:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        performAutoShot()
                    end
                end
            end
        end
    end
end)
trackConnection(aimConnection)

ui.OpenFirstCategory()

ui.OnClose(function()
    scriptRunning = false
    
    Aim_Settings.Enabled = false
    Aim_Settings.Triggerbot = false
    Aim_Settings.HitboxActive = false
    for k in pairs(ESP_Settings) do ESP_Settings[k] = false end

    for _, conn in ipairs(connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(connections)

    for p, data in pairs(originalHeadSizes) do
        if p and p.Character then
            local head = p.Character:FindFirstChild("Head")
            if head then
                head.Size = data.Size
                head.Transparency = 0
                head.CanCollide = data.CanCollide
            end
        end
    end
    table.clear(originalHeadSizes)

    print("Flick Script completely deactivated and memory freed!")
end)
