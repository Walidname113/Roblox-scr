local REQUIRED_GAME_ID = 1526814825
if game.GameId ~= REQUIRED_GAME_ID then return end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local function safeWaitForChild(parent, name, timeout)
    timeout = timeout or 10
    if not parent then return nil end
    local obj = parent:FindFirstChild(name)
    if obj then return obj end
    local elapsed = 0
    local conn
    local resolved = false
    conn = parent.DescendantAdded:Connect(function(desc)
        if desc.Name == name and desc.Parent == parent then
            resolved = true
        end
    end)
    while elapsed < timeout and not obj do
        obj = parent:FindFirstChild(name)
        if obj then break end
        task.wait(0.1)
        elapsed = elapsed + 0.1
    end
    if conn then conn:Disconnect() end
    return obj
end

local function safeFindChain(root, names, timeoutPer)
    timeoutPer = timeoutPer or 10
    local cur = root
    for _, n in ipairs(names) do
        if not cur then return nil end
        cur = safeWaitForChild(cur, n, timeoutPer)
        if not cur then return nil end
    end
    return cur
end

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
local ui = uiModule.CreateUI("Violence District by Kiyatsuka | Version: 1.0.0 Public.")
ui.SetMinimizedImage("108856686741748")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")
local player = Players.LocalPlayer

local badClasses = {
    "BillboardGui",
    "SurfaceGui",
    "ParticleEmitter",
    "Trail",
    "Explosion",
    "Highlight",
    "Beam"
}

local function isTrash(obj)
    for _, class in ipairs(badClasses) do
        if obj:IsA(class) then
            return true
        end
    end
    return false
end

local function clean()
    local cam = workspace.CurrentCamera
    if cam then
        for _, obj in ipairs(cam:GetChildren()) do
            if isTrash(obj) then
                obj:Destroy()
            end
        end
    end
    if player:FindFirstChild("PlayerGui") then
        for _, gui in ipairs(player.PlayerGui:GetDescendants()) do
            if isTrash(gui) then
                gui:Destroy()
            end
        end
    end
end

local antiLagEnabled = false
local heartbeatConn
local logConn
local oldPrint, oldWarn, oldError = print, warn, error

local function enableAntiLag()
    if antiLagEnabled then return end
    antiLagEnabled = true

    heartbeatConn = RunService.Heartbeat:Connect(function()
        if tick() % 10 < 0.03 then
            clean()
        end
    end)

    print = function(...) end
    warn  = function(...) end
    error = function(...) end

    logConn = LogService.MessageOut:Connect(function() end)
end

local function disableAntiLag()
    if not antiLagEnabled then return end
    antiLagEnabled = false

    if heartbeatConn then
        heartbeatConn:Disconnect()
        heartbeatConn = nil
    end
    if logConn then
        logConn:Disconnect()
        logConn = nil
    end

    print = oldPrint
    warn  = oldWarn
    error = oldError
end

local mainCategory = ui.CreateCategory("Main")
ui.CreateToggle("Anti-lag Mode", mainCategory, function(state)
    if state then
        enableAntiLag()
    else
        disableAntiLag()
    end
end)

ui.OpenFirstCategory()
