local REQUIRED_GAME_ID = 9464360885
if game.GameId ~= REQUIRED_GAME_ID then return end

local uiurl = "https://raw.githubusercontent.com/Walidname113/Roblox-scr/main/uncoded.lua"
local success, source = pcall(function()
    return game:HttpGet(uiurl)
end)

if not success then return end

local moduleFunc, err = loadstring(source)
if not moduleFunc then return end

local uiModule = moduleFunc()
local ui = uiModule.CreateUI("FurrInf by Kiyatsuka | Version: 1.0.0 Public.")
ui.SetMinimizedImage("")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local localPlayer = Players.LocalPlayer

local EspConfig = {
    MasterEnabled = false,
    FurryEnabled = false,
    SurvivorsEnabled = false,
    NickEnabled = false,
    InfectedTextEnabled = false,
    FurryColor = Color3.fromRGB(255, 105, 180),
    SurvivorColor = Color3.fromRGB(0, 191, 255)
}

local MiscConfig = {
    NoJumpCooldown = false,
    HitboxEnabled = false,
    HitboxSize = 2,
    HitboxColor = Color3.fromRGB(168, 85, 247),
    TargetFurry = true,
    TargetHumans = false
}

local activeHighlights = {}
local activeTags = {}
local savedCooldownScripts = {}
local originalSizes = {} 
local storageFolder = Instance.new("Folder")
storageFolder.Name = "JumpCooldownStorage"
storageFolder.Parent = game:GetService("CoreGui")

local charactersFolder = Workspace:WaitForChild("Characters", 10)

local function removeEsp(character)
    if activeHighlights[character] then
        pcall(function() activeHighlights[character]:Destroy() end)
        activeHighlights[character] = nil
    end
    if activeTags[character] then
        pcall(function() activeTags[character]:Destroy() end)
        activeTags[character] = nil
    end
end

local function updateCharacterEsp(character)
    if not character or character.Name == localPlayer.Name then 
        removeEsp(character)
        return 
    end
    
    if not EspConfig.MasterEnabled then
        removeEsp(character)
        return
    end

    local player = Players:GetPlayerFromCharacter(character)
    if not player or not player.Team then return end

    local head = character:FindFirstChild("Head") or character:FindFirstChildWhichIsA("BasePart")
    if not head then return end

    local teamName = player.Team.Name
    local isInfected = (teamName == "Infected")
    
    local isRoleEnabled = (isInfected and EspConfig.FurryEnabled) or (not isInfected and EspConfig.SurvivorsEnabled)
    local targetColor = isInfected and EspConfig.FurryColor or EspConfig.SurvivorColor
    local statusText = isInfected and "Furry" or "Survivor"

    if isRoleEnabled then
        local highlight = activeHighlights[character]
        
        if highlight and highlight.FillColor ~= targetColor then
            pcall(function() highlight:Destroy() end)
            activeHighlights[character] = nil
            highlight = nil
        end

        if not highlight or not highlight.Parent or highlight.Parent ~= character then
            pcall(function() if highlight then highlight:Destroy() end end)
            local success, newHighlight = pcall(function()
                local hl = Instance.new("Highlight")
                hl.Name = "EspHighlight"
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0.2
                hl.Adornee = character
                hl.Parent = character
                return hl
            end)
            if success then
                activeHighlights[character] = newHighlight
                highlight = newHighlight
            end
        end
        if highlight then
            highlight.FillColor = targetColor
            highlight.OutlineColor = targetColor
        end
    else
        if activeHighlights[character] then
            pcall(function() activeHighlights[character]:Destroy() end)
            activeHighlights[character] = nil
        end
    end

    if isRoleEnabled and (EspConfig.NickEnabled or EspConfig.InfectedTextEnabled) then
        local bbGui = activeTags[character]
        
        if bbGui then
            local statusLabel = bbGui:FindFirstChild("StatusLabel")
            if statusLabel and statusLabel.Text ~= statusText then
                pcall(function() bbGui:Destroy() end)
                activeTags[character] = nil
                bbGui = nil
            end
        end

        if not bbGui or not bbGui.Parent or bbGui.Adornee ~= head then
            pcall(function() if bbGui then bbGui:Destroy() end end)
            local success, newGui = pcall(function()
                local gui = Instance.new("BillboardGui")
                gui.Name = "EspTag"
                gui.Size = UDim2.new(0, 200, 0, 40)
                gui.AlwaysOnTop = true
                gui.MaxDistance = 1000
                gui.StudsOffset = Vector3.new(0, 3, 0)
                
                local nameLabel = Instance.new("TextLabel", gui)
                nameLabel.Name = "NameLabel"
                nameLabel.Size = UDim2.new(1, 0, 0, 18)
                nameLabel.Position = UDim2.new(0, 0, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextSize = 13
                nameLabel.TextColor3 = Color3.new(1, 1, 1)
                nameLabel.TextStrokeTransparency = 0
                
                local statusLabel = Instance.new("TextLabel", gui)
                statusLabel.Name = "StatusLabel"
                statusLabel.Size = UDim2.new(1, 0, 0, 14)
                statusLabel.Position = UDim2.new(0, 0, 0, 18)
                statusLabel.BackgroundTransparency = 1
                statusLabel.Font = Enum.Font.GothamBold
                statusLabel.TextSize = 11
                statusLabel.TextStrokeTransparency = 0
                
                gui.Adornee = head
                gui.Parent = head
                return gui
            end)
            if success then
                activeTags[character] = newGui
                bbGui = newGui
            end
        end

        if bbGui then
            local nameLabel = bbGui:FindFirstChild("NameLabel")
            local statusLabel = bbGui:FindFirstChild("StatusLabel")
            
            if nameLabel then
                nameLabel.Visible = EspConfig.NickEnabled
                nameLabel.Text = character.Name
            end
            
            if statusLabel then
                statusLabel.Visible = EspConfig.InfectedTextEnabled
                statusLabel.Text = statusText
                statusLabel.TextColor3 = targetColor
            end
            
            if EspConfig.NickEnabled and not EspConfig.InfectedTextEnabled then
                if nameLabel then nameLabel.Position = UDim2.new(0, 0, 0, 10) end
            elseif not EspConfig.NickEnabled and EspConfig.InfectedTextEnabled then
                if statusLabel then statusLabel.Position = UDim2.new(0, 0, 0, 10) end
            else
                if nameLabel then nameLabel.Position = UDim2.new(0, 0, 0, 0) end
                if statusLabel then statusLabel.Position = UDim2.new(0, 0, 0, 18) end
            end
        end
    else
        if activeTags[character] then
            pcall(function() activeTags[character]:Destroy() end)
            activeTags[character] = nil
        end
    end
end

local function clearAllEsp()
    for char, _ in pairs(activeHighlights) do
        removeEsp(char)
    end
    for char, _ in pairs(activeTags) do
        removeEsp(char)
    end
end

local function updateJumpCooldownState(character)
    if not character then return end
    
    if MiscConfig.NoJumpCooldown then
        table.clear(savedCooldownScripts)
        for _, scr in ipairs(character:GetChildren()) do
            if scr.Name == "JumpCooldown" and (scr:IsA("Script") or scr:IsA("LocalScript")) then
                table.insert(savedCooldownScripts, scr)
                scr.Parent = storageFolder
            end
        end
    else
        if #savedCooldownScripts > 0 then
            for _, scr in ipairs(savedCooldownScripts) do
                if scr and scr.Parent == storageFolder then
                    scr.Parent = character
                end
            end
            table.clear(savedCooldownScripts)
        end
    end
end

local function resetCharacterHitbox(character)
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then
        hrp.Size = originalSizes[character] or Vector3.new(2, 2, 1)
        hrp.Transparency = 1
        hrp.Color = Color3.fromRGB(163, 162, 165)
        hrp.Material = Enum.Material.Plastic
        hrp.CanCollide = false
    end
end

local function updateHitboxes()
    if not charactersFolder then return end

    for _, char in ipairs(charactersFolder:GetChildren()) do
        if char:IsA("Model") and char.Name ~= localPlayer.Name then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local plr = Players:GetPlayerFromCharacter(char)

            if hrp and hrp:IsA("BasePart") and plr and plr.Team then
                if not originalSizes[char] then
                    originalSizes[char] = hrp.Size
                end

                local teamName = plr.Team.Name
                local isFurry = (teamName == "Infected")
                local isHuman = not isFurry

                local shouldExpand = false
                if MiscConfig.HitboxEnabled then
                    if isFurry and MiscConfig.TargetFurry then
                        shouldExpand = true
                    elseif isHuman and MiscConfig.TargetHumans then
                        shouldExpand = true
                    end
                end

                if shouldExpand then
                    local size = MiscConfig.HitboxSize
                    hrp.Size = Vector3.new(size, size, size)
                    hrp.Transparency = 0.7
                    hrp.Color = MiscConfig.HitboxColor
                    hrp.Material = Enum.Material.Neon
                    hrp.CanCollide = false
                else
                    resetCharacterHitbox(char)
                end
            end
        end
    end
end

if charactersFolder then
    charactersFolder.ChildRemoved:Connect(function(child)
        removeEsp(child)
        originalSizes[child] = nil
    end)
    
    charactersFolder.ChildAdded:Connect(function(child)
        if child.Name == localPlayer.Name then
            task.wait(0.5)
            updateJumpCooldownState(child)
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(0.1)
        if charactersFolder then
            if EspConfig.MasterEnabled then
                pcall(function()
                    for _, char in ipairs(charactersFolder:GetChildren()) do
                        if char:IsA("Model") then
                            updateCharacterEsp(char)
                        end
                    end
                end)
                
                for char, _ in pairs(activeHighlights) do
                    if not char or not char.Parent or char.Parent ~= charactersFolder then
                        removeEsp(char)
                    end
                end
                for char, _ in pairs(activeTags) do
                    if not char or not char.Parent or char.Parent ~= charactersFolder then
                        removeEsp(char)
                    end
                end
            else
                if next(activeHighlights) ~= nil or next(activeTags) ~= nil then
                    clearAllEsp()
                end
            end
        end
        pcall(updateHitboxes)
    end
end)

-- РАЗДЕЛ ESP
local espCategory = ui.CreateCategory("ESP")

local espSubConfig = {
    {
        Type = "Checkbox",
        Text = "Furry ESP",
        State = false,
        LayoutOrder = 1,
        Callback = function(state) EspConfig.FurryEnabled = state end
    },
    {
        Type = "Checkbox",
        Text = "Survivors ESP",
        State = false,
        LayoutOrder = 2,
        Callback = function(state) EspConfig.SurvivorsEnabled = state end
    },
    {
        Type = "Checkbox",
        Text = "Nick ESP",
        State = false,
        LayoutOrder = 3,
        Callback = function(state) EspConfig.NickEnabled = state end
    },
    {
        Type = "Checkbox",
        Text = "Infected ESP",
        State = false,
        LayoutOrder = 4,
        Callback = function(state) EspConfig.InfectedTextEnabled = state end
    }
}

ui.CreateToggle(
    "Enable ESP",
    espCategory,
    function(state)
        EspConfig.MasterEnabled = state
        if not state then clearAllEsp() end
    end,
    "Highlights players based on their current status.",
    espSubConfig
)

-- РАЗДЕЛ MISC
local miscCategory = ui.CreateCategory("Misc")

ui.CreateToggle(
    "No jump cooldown",
    miscCategory,
    function(state)
        MiscConfig.NoJumpCooldown = state
        if charactersFolder then
            local myChar = charactersFolder:FindFirstChild(localPlayer.Name)
            if myChar then updateJumpCooldownState(myChar) end
        end
    end,
    "Removes the delay between jumps.",
    {}
)

local hitboxSubConfig = {
    {
        Type = "Checkbox",
        Text = "Target Furry (Infected)",
        State = true,
        LayoutOrder = 1,
        Callback = function(state)
            MiscConfig.TargetFurry = state
        end
    },
    {
        Type = "Checkbox",
        Text = "Target Humans",
        State = false,
        LayoutOrder = 2,
        Callback = function(state)
            MiscConfig.TargetHumans = state
        end
    },
    {
        Type = "Color",
        Text = "Hitbox Color",
        DefaultColor = Color3.fromRGB(168, 85, 247),
        LayoutOrder = 3,
        Callback = function(color)
            MiscConfig.HitboxColor = color
        end
    },
    {
        Type = "Input",
        Text = "Size (Max 20)",
        InputType = "Number",
        Min = 2,
        Max = 20,
        Default = 2,
        Placeholder = "Enter size...",
        LayoutOrder = 4,
        Callback = function(num, enterPressed)
            MiscConfig.HitboxSize = num
        end
    }
}

ui.CreateToggle(
    "Hitbox Expander",
    miscCategory,
    function(state)
        MiscConfig.HitboxEnabled = state
        if not state then
            if charactersFolder then
                for _, char in ipairs(charactersFolder:GetChildren()) do
                    resetCharacterHitbox(char)
                end
            end
        end
    end,
    "Expands humanoids root parts for selected team with highlight color.",
    hitboxSubConfig
)

ui.OpenFirstCategory()
