local REQUIRED_GAME_ID = 8773050457
if game.GameId ~= REQUIRED_GAME_ID then return end

local uiurl = "https://raw.githubusercontent.com/Walidname113/Roblox-scr/main/uncoded.lua"
local success, source = pcall(function()
    return game:HttpGet(uiurl)
end)

if not success then return end

local moduleFunc = loadstring(source)
if not moduleFunc then return end

local uiModule = moduleFunc()
local ui = uiModule.CreateUI("SCP:RB by Kiyatsuka | Version: 1.0.6 Public.")
ui.SetMinimizedImage("130805202254686")

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local cam = workspace.CurrentCamera
local MAX_DISTANCE = 1200
local UPDATE_INTERVAL = 0.1

local highlights = {}
local billboards = {}
local healthGuis = {}
local teamSettings = {}
local espAllEnabled = false
local hpEspEnabled = false

local aimbotEnabled = false
local currentTarget = nil
local studs = 100
local switchAngle = 10
local aimWallCheck = false
local aimTeamCheck = false

local function getHealthColor(perc)
	if perc >= 70 then return Color3.fromRGB(0, 255, 0):Lerp(Color3.fromRGB(255, 165, 0), (100 - perc) / 30)
	elseif perc >= 45 then return Color3.fromRGB(255, 165, 0):Lerp(Color3.fromRGB(255, 80, 80), (70 - perc) / 25)
	elseif perc >= 1 then return Color3.fromRGB(255, 80, 80):Lerp(Color3.fromRGB(139, 0, 0), (45 - perc) / 44)
	else return Color3.fromRGB(0, 0, 0) end
end

local function isVisible(part)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {localPlayer.Character, cam}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(cam.CFrame.Position, (part.Position - cam.CFrame.Position), rayParams)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

local function cleanupPlayerEffects(player)
	if highlights[player] then highlights[player]:Destroy(); highlights[player] = nil end
	if billboards[player] then billboards[player]:Destroy(); billboards[player] = nil end
	if healthGuis[player] then healthGuis[player]:Destroy(); healthGuis[player] = nil end
end

local function createHealthESP(player, character)
	local head = character:WaitForChild("Head", 10)
	if not head or healthGuis[player] then return end
	local gui = Instance.new("BillboardGui", head)
	gui.Name = "HealthESP"; gui.Size = UDim2.new(0, 100, 0, 20); gui.StudsOffset = Vector3.new(0, 1.2, 0)
	gui.AlwaysOnTop = true
	local label = Instance.new("TextLabel", gui)
	label.BackgroundTransparency = 1; label.Size = UDim2.new(1, 0, 1, 0); label.TextSize = 8
	label.Font = Enum.Font.Unknown; label.FontFace = Font.new("rbxasset://fonts/families/PressStart2P.json")
    label.TextStrokeTransparency = 0
	healthGuis[player] = gui
end

local mainCategory = ui.CreateCategory("Main")
local aimbotContainer = Instance.new("Frame", mainCategory)
aimbotContainer.Size = UDim2.new(1, -10, 0, 40); aimbotContainer.BackgroundTransparency = 1

local aimbotToggle = ui.CreateToggle("Aimbot", aimbotContainer, function(state)
    aimbotEnabled = state
    if not state then currentTarget = nil end
end)
aimbotToggle.Size = UDim2.new(1, -140, 1, 0)

local function createInput(placeholder, pos, callback)
    local input = Instance.new("TextBox", aimbotContainer)
    input.Size = UDim2.new(0, 60, 0, 30); input.Position = pos; input.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    input.PlaceholderText = placeholder; input.TextColor3 = Color3.new(1,1,1); input.Text = ""
    Instance.new("UICorner", input)
    input.FocusLost:Connect(function() callback(input) end)
    return input
end

createInput("100 studs", UDim2.new(1, -130, 0.5, -15), function(i) 
    local v = tonumber(i.Text); studs = v or 100; if not v then i.Text = "" end 
end)
createInput("10°", UDim2.new(1, -65, 0.5, -15), function(i) 
    local v = tonumber(i.Text); switchAngle = v or 10; if not v then i.Text = "" end 
end)

ui.CreateToggle("  > Wall check", mainCategory, function(state) aimWallCheck = state end)
ui.CreateToggle("  > Team check", mainCategory, function(state) aimTeamCheck = state end)

local espCategory = ui.CreateCategory("ESP")
ui.CreateToggle("ESP All (No Lobby)", espCategory, function(state) espAllEnabled = state end)
ui.CreateToggle("HP ESP", espCategory, function(state) hpEspEnabled = state end)

local targetTeams = {"Chaos Insurgency", "Serpents Hand", "Security Department", "Mobile Task Forces", "SCP", "Foundation Personnel", "Global Occult Coalition", "Class-D"}
for _, t in ipairs(targetTeams) do
    teamSettings[t] = false
    ui.CreateToggle("ESP " .. t .. " Team", espCategory, function(state) teamSettings[t] = state end)
end

ui.OpenFirstCategory()

RunService.RenderStepped:Connect(function()
    if not aimbotEnabled then return end
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local camDir = cam.CFrame.LookVector
    local camPos = cam.CFrame.Position

    if currentTarget and (not currentTarget.Parent or not currentTarget.Parent:FindFirstChild("Humanoid") 
        or currentTarget.Parent.Humanoid.Health <= 0 
        or (currentTarget.Position - root.Position).Magnitude > studs) then
        currentTarget = nil
    end

    local best, bestAngle = nil, math.rad(switchAngle)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= localPlayer and plr.Character then
            if aimTeamCheck and plr.Team == localPlayer.Team then continue end
            local head = plr.Character:FindFirstChild("Head")
            local hum = plr.Character:FindFirstChild("Humanoid")
            if head and hum and hum.Health > 0 then
                if aimWallCheck and not isVisible(head) then continue end
                local dir = (head.Position - camPos).Unit
                local angle = math.acos(math.clamp(camDir:Dot(dir), -1, 1))
                local d = (head.Position - root.Position).Magnitude
                if d < studs and angle < bestAngle then
                    best = head; bestAngle = angle
                end
            end
        end
    end

    if best then currentTarget = best end
    if currentTarget and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        cam.CFrame = CFrame.new(cam.CFrame.Position, currentTarget.Position)
    end
end)

-- Исправленный Цикл ESP
task.spawn(function()
	while true do
		local myChar = localPlayer.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= localPlayer and p.Character then
                if not healthGuis[p] then 
                    local role = p:GetAttribute("Role")
                    if role == "SCP-966" then
                        local hrp = p.Character:WaitForChild("HumanoidRootPart", 5)
                        if hrp and not billboards[p] then
                            local gui = Instance.new("BillboardGui", hrp)
                            gui.Size = UDim2.new(4,0,6,0); gui.AlwaysOnTop = true
                            billboards[p] = gui
                        end
                    elseif not highlights[p] then
                        local h = Instance.new("Highlight", p.Character)
                        h.FillTransparency = 0.5; highlights[p] = h
                    end
                    createHealthESP(p, p.Character) 
                end
            end
        end

		for player, gui in pairs(healthGuis) do
			local char = player.Character
			local hum = char and char:FindFirstChild("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local tName = player.Team and player.Team.Name or ""
            local espActive = (espAllEnabled or teamSettings[tName]) and tName ~= "Lobby"
			local dist = (myRoot and root) and (myRoot.Position - root.Position).Magnitude or 9999
            
			if hpEspEnabled and espActive and dist <= MAX_DISTANCE and hum then
				local perc = math.clamp(math.floor((hum.Health / hum.MaxHealth) * 100), 0, 100)
				local label = gui:FindFirstChildWhichIsA("TextLabel")
				if label then
					label.Text = "HP: " .. perc .. "%"
					label.TextColor3 = getHealthColor(perc)
				end
				gui.Enabled = true
			else
				gui.Enabled = false
			end
            if highlights[player] then
                highlights[player].Enabled = espActive and dist <= MAX_DISTANCE
            end
            if billboards[player] then
                billboards[player].Enabled = espActive and dist <= MAX_DISTANCE
            end
		end
		task.wait(UPDATE_INTERVAL)
	end
end)
