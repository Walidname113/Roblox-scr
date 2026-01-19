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
local ui = uiModule.CreateUI("SCP:RB by Kiyatsuka | Version: 1.0.0 Public.")
ui.SetMinimizedImage("130805202254686")

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local MAX_DISTANCE = 1200
local UPDATE_INTERVAL = 0.2

local highlights = {}
local billboards = {}
local teamSettings = {}

local function getSCPColor()
	local scp = Teams:FindFirstChild("SCP")
	return scp and scp.TeamColor.Color or Color3.new(1, 0, 0)
end

local function cleanupPlayerEffects(player)
	if highlights[player] then highlights[player]:Destroy(); highlights[player] = nil end
	if billboards[player] then billboards[player]:Destroy(); billboards[player] = nil end
end

local function create966Billboard(player, character)
	local head = character:WaitForChild("Head", 5)
	if not head or billboards[player] then return end

	local color = getSCPColor()
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(4, 0, 6, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 2000
	gui.Parent = head

	local container = Instance.new("Frame", gui)
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0

	local function drawPart(rx, ry, rw, rh, isLine)
		local f = Instance.new("Frame", container)
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.new(rx, 0, ry, 0)
		f.Size = UDim2.new(rw, 0, rh, 0)
		f.BackgroundColor3 = isLine and Color3.new(0,0,0) or color
		f.BackgroundTransparency = isLine and 0.1 or 0.2
		f.BorderSizePixel = 0
	end

	drawPart(0.5, 0.15, 0.25, 0.20, false)
	drawPart(0.5, 0.45, 0.35, 0.40, false)
	drawPart(0.15, 0.45, 0.15, 0.35, false)
	drawPart(0.85, 0.45, 0.15, 0.35, false)
	drawPart(0.40, 0.80, 0.20, 0.35, false)
	drawPart(0.60, 0.80, 0.20, 0.35, false)

	billboards[player] = gui
end

local function createHighlight(player, character)
	if highlights[player] then return end
	local h = Instance.new("Highlight")
	h.Adornee = character
	h.FillTransparency = 0.5
	h.OutlineTransparency = 0
	h.Enabled = false
	
	local teamColor = player.Team and player.Team.TeamColor.Color or Color3.new(1, 1, 1)
	h.FillColor = teamColor
	h.OutlineColor = teamColor
	
	h.Parent = character
	highlights[player] = h
end

local function setupVisuals(player)
	cleanupPlayerEffects(player)
	if player.Team and player.Team.Name == "Lobby" then return end
	local character = player.Character
	if not character then return end
	local role = player:GetAttribute("Role")
	if role == "SCP-966" then
		create966Billboard(player, character)
	else
		createHighlight(player, character)
	end
end

local espCategory = ui.CreateCategory("ESP")

local targetTeams = {
    "Serpents Hand", "Security Department", "Mobile Task Forces", 
    "SCP", "Foundation Personnel", "Global Occult Coalition", 
    "Class-D", "FFA"
}

for _, teamName in ipairs(targetTeams) do
    teamSettings[teamName] = false
    ui.CreateToggle("ESP [" .. teamName .. "] Team", espCategory, function(state)
        teamSettings[teamName] = state
        if not state then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Team and plr.Team.Name == teamName then
                    if highlights[plr] then highlights[plr].Enabled = false end
                    if billboards[plr] then billboards[plr].Enabled = false end
                end
            end
        end
    end)
end

ui.OpenFirstCategory()

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		setupVisuals(player)
	end)
    player:GetPropertyChangedSignal("Team"):Connect(function()
        setupVisuals(player)
    end)
	player:GetAttributeChangedSignal("Role"):Connect(function()
		setupVisuals(player)
	end)
	if player.Character then setupVisuals(player) end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	if p ~= localPlayer then onPlayerAdded(p) end
end

Players.PlayerRemoving:Connect(cleanupPlayerEffects)

task.spawn(function()
	while true do
		local myChar = localPlayer.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		
		for player, highlight in pairs(highlights) do
            local tName = player.Team and player.Team.Name or ""
            local isEnabled = teamSettings[tName] or false
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if isEnabled and myRoot and root then
				highlight.Enabled = (myRoot.Position - root.Position).Magnitude <= MAX_DISTANCE
			else
				highlight.Enabled = false
			end
		end

		for player, billboard in pairs(billboards) do
            local tName = player.Team and player.Team.Name or ""
            local isEnabled = teamSettings[tName] or false
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if isEnabled and myRoot and root then
				billboard.Enabled = (myRoot.Position - root.Position).Magnitude <= MAX_DISTANCE
			else
				billboard.Enabled = false
			end
		end
		task.wait(UPDATE_INTERVAL)
	end
end)
