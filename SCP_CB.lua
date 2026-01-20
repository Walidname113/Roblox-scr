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
local ui = uiModule.CreateUI("SCP:RB by Kiyatsuka | Version: 1.0.5 Public.")
ui.SetMinimizedImage("130805202254686")

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local MAX_DISTANCE = 1200
local UPDATE_INTERVAL = 0.1

local highlights = {}
local billboards = {}
local healthGuis = {}
local teamSettings = {}
local espAllEnabled = false
local hpEspEnabled = false

local aimbotEnabled = false
local aimWallCheck = false
local aimTeamCheck = false
local aimDegreeEnabled = false
local aimDegreeValue = 10 

local function getHealthColor(perc)
	if perc >= 70 then
		return Color3.fromRGB(0, 255, 0):Lerp(Color3.fromRGB(255, 165, 0), (100 - perc) / 30)
	elseif perc >= 45 then
		return Color3.fromRGB(255, 165, 0):Lerp(Color3.fromRGB(255, 80, 80), (70 - perc) / 25)
	elseif perc >= 1 then
		return Color3.fromRGB(255, 80, 80):Lerp(Color3.fromRGB(139, 0, 0), (45 - perc) / 44)
	else
		return Color3.fromRGB(0, 0, 0)
	end
end

local function isVisible(part)
	local origin = camera.CFrame.Position
	local dest = part.Position
	local direction = dest - origin
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {localPlayer.Character, camera}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local result = workspace:Raycast(origin, direction, rayParams)
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

	local gui = Instance.new("BillboardGui")
	gui.Name = "HealthESP"
	gui.Adornee = head
	gui.Size = UDim2.new(0, 100, 0, 20)
	gui.StudsOffset = Vector3.new(0, 1.2, 0)
	gui.AlwaysOnTop = true
	gui.Parent = head

	local label = Instance.new("TextLabel")
	label.Parent = gui
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.Unknown
	label.FontFace = Font.new("rbxasset://fonts/families/PressStart2P.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	label.TextSize = 8
	label.TextStrokeTransparency = 0
	label.Text = ""
	
	healthGuis[player] = gui
end

local function setupVisuals(player)
	if player == localPlayer then return end
	cleanupPlayerEffects(player)
	local character = player.Character
	if not character then return end
    
    task.spawn(function()
        createHealthESP(player, character)
        if player.Team and player.Team.Name == "Lobby" then return end
        
        local role = player:GetAttribute("Role")
        if role == "SCP-966" then
            local hrp = character:WaitForChild("HumanoidRootPart", 5)
            if hrp then
                local gui = Instance.new("BillboardGui", hrp)
                gui.Name = "966Visual"
                gui.AlwaysOnTop = true
                gui.Size = UDim2.new(4,0,6,0)
                billboards[player] = gui
            end
        else
            local h = Instance.new("Highlight", character)
            h.FillTransparency = 0.5
            highlights[player] = h
        end
    end)
end

local mainCategory = ui.CreateCategory("Main")
ui.CreateToggle("Aimbot", mainCategory, function(state) aimbotEnabled = state end)
ui.CreateToggle("  > Wall Check", mainCategory, function(state) aimWallCheck = state end)
ui.CreateToggle("  > Team Check", mainCategory, function(state) aimTeamCheck = state end)
ui.CreateToggle("  > Degree Process (10°)", mainCategory, function(state) aimDegreeEnabled = state end)

local espCategory = ui.CreateCategory("ESP")
ui.CreateToggle("ESP All (No Lobby)", espCategory, function(state) espAllEnabled = state end)
ui.CreateToggle("HP ESP", espCategory, function(state) hpEspEnabled = state end)

local targetTeams = {"Chaos Insurgency", "Serpents Hand", "Security Department", "Mobile Task Forces", "SCP", "Foundation Personnel", "Global Occult Coalition", "Class-D"}
for _, teamName in ipairs(targetTeams) do
    teamSettings[teamName] = false
    ui.CreateToggle("ESP " .. teamName .. " Team", espCategory, function(state) teamSettings[teamName] = state end)
end

ui.OpenFirstCategory()

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		setupVisuals(player)
	end)
	if player.Character then setupVisuals(player) end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end
Players.PlayerRemoving:Connect(cleanupPlayerEffects)

RunService.RenderStepped:Connect(function()
    if not aimbotEnabled then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end

    local closest = nil
    local shortestDist = math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == localPlayer or not plr.Character then continue end
        if aimTeamCheck and plr.Team == localPlayer.Team then continue end
        
        local root = plr.Character:FindFirstChild("HumanoidRootPart")
        local hum = plr.Character:FindFirstChild("Humanoid")
        if not root or not hum or hum.Health <= 0 then continue end
        
        local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
        if not onScreen then continue end
        
        if aimWallCheck and not isVisible(root) then continue end

        local distToMouse = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        
        if aimDegreeEnabled then
            if distToMouse <= (aimDegreeValue * 10) then 
                if distToMouse < shortestDist then
                    shortestDist = distToMouse
                    closest = root
                end
            end
        else
            local distToPlayer = (camera.CFrame.Position - root.Position).Magnitude
            if distToPlayer < shortestDist then
                shortestDist = distToPlayer
                closest = root
            end
        end
    end

    if closest then
        camera.CFrame = CFrame.new(camera.CFrame.Position, closest.Position)
    end
end)

task.spawn(function()
	while true do
		local myChar = localPlayer.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		
		for _, player in ipairs(Players:GetPlayers()) do
            if player == localPlayer then continue end
            if not healthGuis[player] and player.Character then setupVisuals(player) end

			local gui = healthGuis[player]
			if gui then
				local char = player.Character
				local hum = char and char:FindFirstChild("Humanoid")
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local tName = player.Team and player.Team.Name or ""
				
				local dist = myRoot and root and (myRoot.Position - root.Position).Magnitude or 9999
				if hpEspEnabled and tName ~= "Lobby" and dist <= MAX_DISTANCE and hum then
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
			end

            local highlight = highlights[player]
            if highlight then
                local tName = player.Team and player.Team.Name or ""
                local isEnabled = (espAllEnabled or teamSettings[tName]) and tName ~= "Lobby"
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local dist = myRoot and root and (myRoot.Position - root.Position).Magnitude or 9999
                highlight.Enabled = isEnabled and dist <= MAX_DISTANCE
            end
		end
		task.wait(UPDATE_INTERVAL)
	end
end)
