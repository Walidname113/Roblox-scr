local requiredGameId = 5926583186
if game.GameId ~= requiredGameId then return end

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
local ui = uiModule.CreateUI("No Jump Obby by Kiyatsuka | Version: 1.0.0 Public")

local mainCat = ui.CreateCategory("Main")

local autoEnabled = false
local autoConn = nil

local function autoCheckpointsFunc()
    local plr = game:GetService("Players").LocalPlayer
    if not plr or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = plr.Character.HumanoidRootPart
    local ls = plr:FindFirstChild("leaderstats")
    if not ls then return end
    local stageVal = ls:FindFirstChild("Stage")
    if not stageVal then return end
    local nextStage = tostring(stageVal.Value + 1)
    local cps = workspace:FindFirstChild("Checkpoints")
    if cps and cps:FindFirstChild(nextStage) then
        hrp.CFrame = cps[nextStage].CFrame + Vector3.new(0, 3, 0)
    end
end

ui.CreateToggle("Auto Checkpoints", mainCat, function(state)
    autoEnabled = state
    if autoConn then autoConn:Disconnect() autoConn = nil end
    if state then
        autoCheckpointsFunc()
        local plr = game:GetService("Players").LocalPlayer
        local ls = plr and plr:FindFirstChild("leaderstats")
        local stageVal = ls and ls:FindFirstChild("Stage")
        if stageVal then
            autoConn = stageVal.Changed:Connect(autoCheckpointsFunc)
        end
    end
end)

local noclipConn = nil
ui.CreateToggle("Noclip", mainCat, function(state)
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    if state then
        local RunService = game:GetService("RunService")
        local plr = game:GetService("Players").LocalPlayer
        noclipConn = RunService.Stepped:Connect(function()
            if plr.Character then
                for _, part in ipairs(plr.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end)

ui.OpenFirstCategory()
