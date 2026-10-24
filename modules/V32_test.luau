local uiurl = "https://raw.githubusercontent.com/Walidname113/Roblox-scr/refs/heads/main/ModernUI_v32.lua"

local success, source = pcall(function()
    return game:HttpGet(uiurl)
end)

if not success then
    warn("ModernUI: failed to download source")
    return
end

local moduleFunc, err = loadstring(source)
if not moduleFunc then
    warn("ModernUI: failed to compile source:", err)
    return
end

local ok, uiModule = pcall(moduleFunc)
if not ok or type(uiModule) ~= "table" then
    warn("ModernUI: failed to initialize module")
    return
end

local okWindow, ui = pcall(function()
    return uiModule.new({
        Title = "ModernUI v32 | Test",
        MinimizedImage = "",
    })
end)

if not okWindow or not ui then
    warn("ModernUI: failed to create window:", ui)
    return
end

ui:Button({
    Name = "TestButton",
    Text = "press me",
    Callback = function()
        print("Button clicked")
    end,
})

ui:Toggle({
    Name = "TestToggle",
    Text = "Test_toggle",
    Default = false,
    Callback = function(value)
        print("Toggle state:", value)
    end,
})
