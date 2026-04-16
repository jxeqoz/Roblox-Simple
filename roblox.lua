task.wait()
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local scriptConnections = {}

local Window = Library:CreateWindow({
    Title = "RobloxSimple",
    Footer = "github.com/jxeqoz",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = true,
    AutoShow = true
})

local isMenuOpen = true

local Tabs = {
    Main = Window:AddTab("Main","crosshair"),
    Visuals = Window:AddTab("Visuals","eye"),
    Player = Window:AddTab("Player","users"),
    Settings = Window:AddTab("UI Settings","settings")
}

local Toggles = Library.Toggles
local Options = Library.Options

Tabs.Settings:AddLeftGroupbox("Github"):AddButton({
    Text="Copy Github",
    Func=function()
        setclipboard("https://github.com/jxeqoz")
        Library:Notify("Copied!")
    end
})

Tabs.Settings:AddRightGroupbox("PC Toggle"):AddLabel("Toggle UI"):AddKeyPicker("ToggleUIKeybind",{
    Default="RightShift",
    Mode="Toggle",
    Callback=function()
        isMenuOpen = not isMenuOpen
        Library:Toggle()
    end
})

local MainBox = Tabs.Main:AddLeftGroupbox("Combat")

MainBox:AddToggle("Aimbot",{Text="Aimbot", Default=false})
MainBox:AddToggle("TeamCheck",{Text="Team Check",Default=false})
MainBox:AddToggle("WallCheck",{Text="Wall Check",Default=true})
MainBox:AddToggle("FOVCircle",{Text="FOV Circle",Default=false})
MainBox:AddToggle("LockFOV",{Text="Lock FOV To Center",Default=true})
MainBox:AddToggle("EnableHitbox",{Text="Hitbox Expander"})
MainBox:AddToggle("CameraNoRecoil",{Text="Camera No Recoil"})
MainBox:AddToggle("InfiniteAmmo",{Text="Infinite Ammo"})

MainBox:AddDropdown("TargetPart",{
    Values={"Head","HumanoidRootPart","Left Arm","Right Arm"},
    Default=1,
    Text="Aimbot Target"
})

local AimbotBox = Tabs.Main:AddRightGroupbox("Aimbot Settings")

local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.new(1,1,1)
fovCircle.Thickness = 2
fovCircle.NumSides = 100
fovCircle.Radius = 100
fovCircle.Filled = false

local Smoothness = 0.15
local hitboxSize = 10
local hitboxTransparency = 0.4

AimbotBox:AddSlider("FOVRadius",{Text="FOV Radius",Min=20,Max=400,Default=100,
    Callback=function(v) fovCircle.Radius=v end})

AimbotBox:AddSlider("Smoothness",{
    Text="Smoothness",
    Min=0.01,
    Max=1,
    Default=0.15,
    Rounding=2,
    Callback=function(v) Smoothness=v end
})

AimbotBox:AddSlider("CameraRecoilReduction",{
    Text="Cam Recoil Reduction %",
    Min=0,
    Max=100,
    Default=80,
    Rounding=0,
    Callback=function(v) end
})

MainBox:AddSlider("HitboxSize",{Text="Hitbox Size",Min=2,Max=100,Default=50,
    Callback=function(v) hitboxSize=v end})

MainBox:AddSlider("HitboxTransparency",{
    Text="Hitbox Transparency",
    Min=0,
    Max=1,
    Default=0.4,
    Rounding=2,
    Callback=function(v) hitboxTransparency=v end
})

MainBox:AddSlider("RecoilMod1", {Text="Recoil/Spread Float Mod", Min=1, Max=10, Default=1})
MainBox:AddSlider("RecoilMod2", {Text="Recoil/Spread Max Mod", Min=1, Max=100, Default=1})
MainBox:AddSlider("RecoilMod3", {Text="Recoil/Spread MinMax Mod", Min=1, Max=10, Default=1})

local function IsTeammate(plr)
    if not Toggles.TeamCheck.Value then return false end
    if plr.Team ~= nil and LocalPlayer.Team ~= nil and plr.Team == LocalPlayer.Team then return true end
    return false
end

local function GetPart(char,name)
    if name=="Left Arm" then
        return char:FindFirstChild("Left Arm") or char:FindFirstChild("LeftHand") or char:FindFirstChild("LeftUpperArm")
    elseif name=="Right Arm" then
        return char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand") or char:FindFirstChild("RightUpperArm")
    else
        return char:FindFirstChild(name)
    end
end

local function IsVisible(part)
    if not Toggles.WallCheck.Value then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, part.Parent}
    params.IgnoreWater = true
    return not workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
end

local function GetClosest()
    local closest,dist = nil,math.huge
    for _,plr in pairs(Players:GetPlayers()) do
        if plr~=LocalPlayer and plr.Character then
            if IsTeammate(plr) then continue end
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then continue end
            
            local part = GetPart(plr.Character,Options.TargetPart.Value)
            if part and IsVisible(part) then
                local pos,vis = Camera:WorldToViewportPoint(part.Position)
                local diff = (Vector2.new(pos.X,pos.Y)-fovCircle.Position).Magnitude
                if vis and diff<fovCircle.Radius and diff<dist then
                    closest,dist = plr,diff
                end
            end
        end
    end
    return closest
end

local lastCamLook
local spinAngle = 0

table.insert(scriptConnections, RunService.RenderStepped:Connect(function()
    fovCircle.Visible = Toggles.FOVCircle.Value
    fovCircle.Position = Toggles.LockFOV.Value
        and Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        or UIS:GetMouseLocation()

    if Toggles.Aimbot.Value then
        local target = GetClosest()
        if target and target.Character then
            local part = GetPart(target.Character, Options.TargetPart.Value)
            if part then
                local dir = (part.Position - Camera.CFrame.Position).Unit
                Camera.CFrame = CFrame.new(
                    Camera.CFrame.Position,
                    Camera.CFrame.Position + Camera.CFrame.LookVector:Lerp(dir, Smoothness)
                )
            end
        end
    end

    if Toggles.CameraNoRecoil and Toggles.CameraNoRecoil.Value then
        if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and lastCamLook then
            local delta = UIS:GetMouseDelta()
            local releaseMult = math.clamp(1 - (delta.Magnitude / 10), 0, 1)
            local reduction = ((Options.CameraRecoilReduction.Value or 80) / 100) * releaseMult
            
            local current = Camera.CFrame.LookVector
            local stabilized = lastCamLook:Lerp(current, 1 - reduction)
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + stabilized)
        end
    end
    lastCamLook = Camera.CFrame.LookVector

    if Toggles.SpinBot and Toggles.SpinBot.Value and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            spinAngle = spinAngle + math.rad(Options.SpinSpeed.Value)
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, spinAngle, 0)
        end
    end
end))

local stored = {}
local heartbeatFrame = 0
local ammoCache = {}
local ammoValues = {}

local function CollectAmmo(container)
    if not container then return end
    for _, item in pairs(container:GetChildren()) do
        if item:IsA("Tool") or item:IsA("Model") then
            for _, v in pairs(item:GetDescendants()) do
                if (v:IsA("IntValue") or v:IsA("NumberValue")) then
                    local n = v.Name:lower()
                    if n:find("ammo") or n:find("bullet") or n:find("clip") or n:find("mag") or n:find("round") then
                        if not ammoCache[v] and v.Value > 0 then
                            ammoCache[v] = v.Value
                        end
                        ammoValues[v] = true
                    end
                end
            end
        end
    end
end

table.insert(scriptConnections, RunService.Heartbeat:Connect(function()
    heartbeatFrame = heartbeatFrame + 1

    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not plr.Character then continue end
        local root = plr.Character:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
        local isAlive = hum and hum.Health > 0 and hum:GetState() ~= Enum.HumanoidStateType.Dead

        if Toggles.EnableHitbox.Value and not IsTeammate(plr) and isAlive then
            if not stored[plr] or stored[plr].Part ~= root then
                if stored[plr] and stored[plr].Part and stored[plr].Part.Parent then
                    stored[plr].Part.Size = stored[plr].Size
                    stored[plr].Part.Transparency = stored[plr].Transparency
                    stored[plr].Part.Material = stored[plr].Material
                    stored[plr].Part.Color = stored[plr].Color
                    local oldBox = stored[plr].Part:FindFirstChild("HitboxOutline_VH")
                    if oldBox then oldBox:Destroy() end
                end

                stored[plr] = {
                    Part = root,
                    Size = root.Size,
                    Transparency = root.Transparency,
                    Material = root.Material,
                    Color = root.Color,
                    CanCollide = root.CanCollide
                }
            end

            root.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
            root.Transparency = hitboxTransparency
            root.Material = Enum.Material.Neon
            root.Color = Color3.fromRGB(0, 255, 0)
            root.CanCollide = false
            
            local box = root:FindFirstChild("HitboxOutline_VH")
            if not box then
                box = Instance.new("SelectionBox")
                box.Name = "HitboxOutline_VH"
                box.Adornee = root
                box.LineThickness = 0.03
                box.Color3 = Color3.fromRGB(0, 255, 0)
                box.Transparency = 0
                box.Parent = root
                game:GetService("CollectionService"):AddTag(box, "MyHitbox_VH")
            end
        else
            if not isAlive then
                stored[plr] = nil
            end
            
            if stored[plr] then
                if stored[plr].Part and stored[plr].Part.Parent then
                    stored[plr].Part.Size = stored[plr].Size
                    stored[plr].Part.Transparency = stored[plr].Transparency
                    stored[plr].Part.Material = stored[plr].Material
                    stored[plr].Part.Color = stored[plr].Color
                    if stored[plr].CanCollide ~= nil then stored[plr].Part.CanCollide = stored[plr].CanCollide end
                    local box = stored[plr].Part:FindFirstChild("HitboxOutline_VH")
                    if box then box:Destroy() end
                end
                stored[plr] = nil
            end

            if root then
                local b = root:FindFirstChild("HitboxOutline_VH")
                if b then b:Destroy() end
            end
            
            if not isAlive and plr.Character then
                pcall(function()
                    plr.Character:Destroy()
                end)
            end
        end
    end

    if Toggles.InfiniteAmmo and Toggles.InfiniteAmmo.Value then
        for v in pairs(ammoValues) do
            if ammoCache[v] and v.Value < ammoCache[v] then
                v.Value = ammoCache[v]
            end
        end
    end

    if heartbeatFrame % 30 == 0 then
        table.clear(ammoValues)
        CollectAmmo(LocalPlayer.Character)
        CollectAmmo(LocalPlayer:FindFirstChild("Backpack"))
    end

    if heartbeatFrame % 6 == 0 then
        for _, box in pairs(game:GetService("CollectionService"):GetTagged("MyHitbox_VH")) do
            if box and box.Adornee then
                local isPlayer = false
                if box.Adornee.Parent then
                    for _, p in pairs(Players:GetPlayers()) do
                        if p.Character == box.Adornee.Parent then
                            isPlayer = true
                            break
                        end
                    end
                end
                
                if not isPlayer then
                    pcall(function()
                        box.Adornee.Size = Vector3.new(0, 0, 0)
                        box.Adornee.CanCollide = false
                        box.Adornee.CanQuery = false
                        box.Adornee.Transparency = 1
                        box:Destroy()
                    end)
                end
            end
        end
    end
end))

table.insert(scriptConnections, Players.PlayerRemoving:Connect(function(plr) stored[plr] = nil end))

local VisualsBox = Tabs.Visuals:AddLeftGroupbox("ESP")

VisualsBox:AddToggle("ESPEnabled",{Text="Enable ESP",Default=true})
VisualsBox:AddToggle("ESPName",{Text="Show Name",Default=true})
VisualsBox:AddToggle("ESPDistance",{Text="Show Distance",Default=true})

local espDrawings = {}

local function CreateESPDrawing(plr)
    local text = Drawing.new("Text")
    text.Size = 14
    text.Center = true
    text.Outline = true
    text.Color = Color3.new(1, 1, 1)
    text.Visible = false
    espDrawings[plr] = text
end

local function RemoveESPDrawing(plr)
    if espDrawings[plr] then
        espDrawings[plr]:Remove()
        espDrawings[plr] = nil
    end
end

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then CreateESPDrawing(p) end
end
table.insert(scriptConnections, Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then CreateESPDrawing(p) end
end))
table.insert(scriptConnections, Players.PlayerRemoving:Connect(function(p) RemoveESPDrawing(p) end))

table.insert(scriptConnections, RunService.RenderStepped:Connect(function()
    for plr, text in pairs(espDrawings) do
        local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
        local isAlive = hum and hum.Health > 0
        
        if not Toggles.ESPEnabled.Value or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") or IsTeammate(plr) or not isAlive then
            text.Visible = false
        else
            local hrp = plr.Character.HumanoidRootPart
            local pos, vis = Camera:WorldToViewportPoint(hrp.Position)
            if vis then
                local label = ""
                if Toggles.ESPName.Value then label = plr.Name .. " " end
                if Toggles.ESPDistance.Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                    label = label .. "[" .. math.floor(dist) .. "m]"
                end
                text.Text = label
                text.Position = Vector2.new(pos.X, pos.Y)
                text.Visible = true
            else
                text.Visible = false
            end
        end
    end
end))

local MoveBox = Tabs.Visuals:AddRightGroupbox("Movement")
local noclipConn

MoveBox:AddToggle("NoClip",{Text="NoClip"}):OnChanged(function(v)
    if v then
        noclipConn = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _,part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide=false end
                end
            end
        end)
    elseif noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end
end)

local infJump = false
MoveBox:AddToggle("InfJump",{Text="Infinite Jump"}):OnChanged(function(v)
    infJump = v
end)

table.insert(scriptConnections, UIS.JumpRequest:Connect(function()
    if infJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState("Jumping") end
    end
end))

MoveBox:AddSlider("Speed",{Text="WalkSpeed",Min=16,Max=100,Default=16,
    Callback=function(v)
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed=v end
        end
    end})

MoveBox:AddToggle("SpinBot",{Text="SpinBot"}):OnChanged(function(v)
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = not v end
    end
end)

MoveBox:AddSlider("SpinSpeed", {Text="Spin Speed", Min=10, Max=200, Default=50})

local PlayerBox = Tabs.Player:AddLeftGroupbox("Players")

local function GetPlayersList()
    local list = {}
    for _,plr in pairs(Players:GetPlayers()) do
        if plr~=LocalPlayer then table.insert(list,plr.Name) end
    end
    return list
end

PlayerBox:AddDropdown("PlayerList",{Values=GetPlayersList(),Default=1,Text="Select Player"})

PlayerBox:AddButton({Text="Refresh List",Func=function()
    Options.PlayerList:SetValues(GetPlayersList())
end})

PlayerBox:AddToggle("Spectate",{Text="Spectate Player"}):OnChanged(function(v)
    local target = Players:FindFirstChild(Options.PlayerList.Value)
    if target and target.Character then
        Camera.CameraSubject = v and
            target.Character:FindFirstChildOfClass("Humanoid")
            or LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    end
end)

PlayerBox:AddButton({Text="Teleport to Player",Func=function()
    local target = Players:FindFirstChild(Options.PlayerList.Value)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character:SetPrimaryPartCFrame(target.Character.HumanoidRootPart.CFrame)
    end
end})

local UnloadBox = Tabs.Settings:AddRightGroupbox("System Operations")

UnloadBox:AddButton("Unload & Exit", function()
    for _, conn in pairs(scriptConnections) do
        if conn and conn.Connected then conn:Disconnect() end
    end
    table.clear(scriptConnections)
    
    if noclipConn then noclipConn:Disconnect() end
    
    if fovCircle then fovCircle:Remove() end
    for plr, data in pairs(stored) do
        if data.Part and data.Part.Parent then
            data.Part.Size = data.Size
            data.Part.Transparency = data.Transparency
            data.Part.Material = data.Material
            data.Part.Color = data.Color
            if data.CanCollide ~= nil then data.Part.CanCollide = data.CanCollide end
            local box = data.Part:FindFirstChild("HitboxOutline_VH")
            if box then box:Destroy() end
        end
    end
    table.clear(stored)

    for _, box in pairs(workspace:GetDescendants()) do
        if box:IsA("SelectionBox") and box.Name == "HitboxOutline_VH" then box:Destroy() end
    end
    
    for _, draw in pairs(espDrawings) do
        if draw then draw:Remove() end
    end
    table.clear(espDrawings)
    
    if workspace.CurrentCamera then
        workspace.CurrentCamera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    end

    pcall(function() if oldRandom then hookfunction(math.random, oldRandom) end end)
    Library:Unload()
end)
local oldRandom
oldRandom = hookfunction(math.random, function(...)
    if not (Toggles and Toggles.NoRecoil and Toggles.NoRecoil.Value) then
        return oldRandom(...)
    end

    local args = {...}
    
    if args[1] == nil then
        local div = (Options.RecoilMod1 and Options.RecoilMod1.Value) or 1
        return oldRandom() / div
    end

    if args[2] == nil then
        local div = (Options.RecoilMod2 and Options.RecoilMod2.Value) or 1
        local upper = args[1] / div
        return oldRandom(math.max(1, math.floor(upper)))
    end

    local div = (Options.RecoilMod3 and Options.RecoilMod3.Value) or 1
    local lower = args[1] / div
    local upper = args[2] / div
    
    if lower > upper then lower, upper = upper, lower end
    return oldRandom(math.floor(lower), math.max(math.floor(lower), math.floor(upper)))
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({'MenuKeybind'})
ThemeManager:SetFolder('RobloxSimple')
SaveManager:SetFolder('RobloxSimple/Main')
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()
