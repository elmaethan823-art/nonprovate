-- // Rayfield & Services Setup
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local CS = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

if not game:IsLoaded() then game.Loaded:Wait() end

local EnumLibrary, UtilityModule, GameplayUtilityModule, FighterController, SpectateController

pcall(function()
    EnumLibrary = require(ReplicatedStorage.Modules:WaitForChild("EnumLibrary"))
    UtilityModule = require(ReplicatedStorage.Modules:WaitForChild("Utility"))
    GameplayUtilityModule = require(ReplicatedStorage.Modules:WaitForChild("GameplayUtility"))
    EnumLibrary:WaitForEnumBuilder()
end)

pcall(function()
    local ctrl = LocalPlayer.PlayerScripts:WaitForChild("Controllers")
    FighterController = require(ctrl:WaitForChild("FighterController"))
    SpectateController = require(ctrl:WaitForChild("SpectateController"))
end)

local CameraController
pcall(function()
    local ctrl = LocalPlayer.PlayerScripts:WaitForChild("Controllers")
    CameraController = require(ctrl:WaitForChild("CameraController"))
end)

pcall(function()
    local gunModule = require(LocalPlayer.PlayerScripts:WaitForChild("Modules"):WaitForChild("ItemTypes"):WaitForChild("Gun"))
    if gunModule and gunModule.IsFullyAiming then
        gunModule.IsFullyAiming = function() return true end
    end
end)

local Config = {
    AimbotEnabled = false, AimbotActive = false, BindMode = "Toggle",
    AimbotKeybind = Enum.KeyCode.Q, AimbotIsMouse = false, AimbotMouseEnum = nil,
    TargetPart = "Head", FOVRadius = 150, ShowFOV = false,
    FOVColor = Color3.fromRGB(255, 255, 255), Smoothness = 0.12, Strength = 1.0,
    TeamCheck = false, WallCheck = false,

    SilentAimEnabled = false, SilentAimActive = true, SilentBindMode = "Always",
    SilentAimKeybind = Enum.KeyCode.E, SilentIsMouse = false, SilentMouseEnum = nil,
    SilentAimHitPart = "Head", SilentFOVRadius = 200, ShowSilentFOV = false,
    SilentFOVColor = Color3.fromRGB(255, 100, 100), SilentTeamCheck = false,
    SilentWallCheck = false, SilentHitChance = 100, ShowSilentTarget = false,
    ShowSilentTracer = false, SilentTargetColor = Color3.fromRGB(0, 255, 150),
    SilentAimUsePrediction = true, SilentAimPredictionFactor = 0.05,

    ESPEnabled = false, ESPBoxes = false, ESPNames = false, ESPHealth = false,
    ESPDistance = false, ESPTracers = false, ESPHeadDots = false,
    ESPTeamCheck = false, ESPTeamColor = false,
    BoxColor = Color3.fromRGB(255, 50, 50), NameColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(255, 255, 255), HeadDotColor = Color3.fromRGB(255, 255, 0),

    WalkSpeedEnabled = false, WalkSpeedValue = 16, JumpPowerEnabled = false,
    JumpPowerValue = 50, InfJump = false, Noclip = false, FlyEnabled = false, FlySpeed = 50,

    TargetTPEnabled = false, StaticTPEnabled = false,
    StaticTPPos = Vector3.new(7000, 3954, 2000),
    TargetTPActive = false, CurrentTPTarget = nil,
    TPOffsetX = 0, TPOffsetY = 0, TPOffsetZ = -3, TPTeamCheck = false,

    RagebotEnabled = false, WeaponSlot = "Primary",
    EnableVoidhide = false, AttackDuration = 0.15, VoidDuration = 0.35,
    RagebotPositionMode = "Behind",
    CustomOffsetX = 0, CustomOffsetY = 0, CustomOffsetZ = -3,
    EnablePrediction = true, PredictionFactor = 0.05,
    EnableNotifications = true, NotifDuration = 1.25,
    RagebotMaxRange = 500, RagebotHitChance = 100, TargetPriority = "Crosshair",
    FireDelay = 0.01,      -- seconds between loop iterations
    BurstCount = 3,        -- shots per iteration

    AutoResolver = true, HitboxExtender = true, HitboxSize = 2.5,
    Multipoint = true, AntiAimBypass = true, FastRecovery = true,

    AntiAimEnabled = false, YawMode = "Spin", SpinSpeed = 15,
    PitchMode = "None", AntiAimDesync = false,

    RapidFireEnabled = false
}

local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RagebotNotifications"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999999
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local container = Instance.new("Frame")
container.Size = UDim2.new(0, 320, 0, 500)
container.Position = UDim2.new(0.5, 0, 0.95, 0)
container.AnchorPoint = Vector2.new(0.5, 1)
container.BackgroundTransparency = 1
container.Parent = screenGui

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = container

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 400, 0, 20)
statusLabel.AnchorPoint = Vector2.new(0.5, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.Text = "ragebot: off"
statusLabel.Parent = screenGui

local statusStroke = Instance.new("UIStroke")
statusStroke.Color = Color3.fromRGB(0, 0, 0)
statusStroke.Thickness = 1
statusStroke.Parent = statusLabel

local function createNotif(titleText, bodyText, duration)
    if not Config.EnableNotifications then return end
    duration = duration or 2
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 48)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = container
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = frame
    local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(35, 35, 35); stroke.Thickness = 1; stroke.Transparency = 0.7; stroke.Parent = frame
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 18); title.Position = UDim2.new(0, 10, 0, 4); title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold; title.Text = titleText; title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16; title.TextXAlignment = Enum.TextXAlignment.Left; title.TextTransparency = 1; title.Parent = frame
    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, -20, 0, 16); body.Position = UDim2.new(0, 10, 0, 22); body.BackgroundTransparency = 1
    body.Font = Enum.Font.SourceSans; body.Text = bodyText; body.TextColor3 = Color3.fromRGB(180, 180, 190)
    body.TextSize = 13; body.TextXAlignment = Enum.TextXAlignment.Left; body.TextTransparency = 1; body.Parent = frame
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 0, 2); progressBar.Position = UDim2.new(0, 0, 1, -2)
    progressBar.BackgroundColor3 = Color3.fromRGB(180, 180, 190); progressBar.BorderSizePixel = 0
    progressBar.BackgroundTransparency = 1; progressBar.Parent = frame
    local fadeInInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(frame, fadeInInfo, {BackgroundTransparency = 0.2}):Play()
    TweenService:Create(stroke, fadeInInfo, {Transparency = 0}):Play()
    TweenService:Create(title, fadeInInfo, {TextTransparency = 0}):Play()
    TweenService:Create(body, fadeInInfo, {TextTransparency = 0}):Play()
    TweenService:Create(progressBar, fadeInInfo, {BackgroundTransparency = 0.25}):Play()
    TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()
    task.delay(duration, function()
        local fadeOutInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local fadeTween = TweenService:Create(frame, fadeOutInfo, {BackgroundTransparency = 1})
        TweenService:Create(stroke, fadeOutInfo, {Transparency = 1}):Play()
        TweenService:Create(title, fadeOutInfo, {TextTransparency = 1}):Play()
        TweenService:Create(body, fadeOutInfo, {TextTransparency = 1}):Play()
        TweenService:Create(progressBar, fadeOutInfo, {BackgroundTransparency = 1}):Play()
        fadeTween:Play()
        fadeTween.Completed:Connect(function() frame:Destroy() end)
    end)
end

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5; FOVCircle.NumSides = 64; FOVCircle.Filled = false; FOVCircle.Transparency = 1; FOVCircle.Visible = false

local SilentFOVCircle = Drawing.new("Circle")
SilentFOVCircle.Thickness = 1.5; SilentFOVCircle.NumSides = 64; SilentFOVCircle.Filled = false; SilentFOVCircle.Transparency = 1; SilentFOVCircle.Visible = false

local TargetHighlight = Drawing.new("Circle")
TargetHighlight.Thickness = 2; TargetHighlight.NumSides = 32; TargetHighlight.Filled = false; TargetHighlight.Transparency = 1; TargetHighlight.Visible = false

local TargetTracer = Drawing.new("Line")
TargetTracer.Thickness = 1.5; TargetTracer.Transparency = 1; TargetTracer.Visible = false

local ESPCache = {}

local Window = Rayfield:CreateWindow({
    Name = "Rivals HvH Ultimate Suite",
    LoadingTitle = "Rivals HvH Suite Loading...",
    LoadingSubtitle = "Optimized Hitscan & Rage Framework",
    ConfigurationSaving = { Enabled = true, FolderName = "RivalsSuite", FileName = "RivalsRagebotConfig" },
    Discord = { Enabled = false }, KeySystem = false
})

local RagebotTab = Window:CreateTab("Ragebot", 4483362458)
local HvHTab = Window:CreateTab("HvH / Exploits", 4483362458)
local AntiAimTab = Window:CreateTab("Anti-Aim", 4483362458)
local AimbotTab = Window:CreateTab("Aimbot", 4483362458)
local SilentTab = Window:CreateTab("Silent Aim", 4483362458)
local ESPTab = Window:CreateTab("Visuals", 4483362458)
local MovementTab = Window:CreateTab("Movement", 4483362458)
local CombatTab = Window:CreateTab("Target TP", 4483362458)

local function IsVisible(part, targetCharacter)
    if not part or not part:IsA("BasePart") then return false end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local ignoreList = {Camera, LocalPlayer.Character}
    if targetCharacter then table.insert(ignoreList, targetCharacter) end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.CanCollide then table.insert(ignoreList, obj) end
    end
    raycastParams.FilterDescendantsInstances = ignoreList
    raycastParams.IgnoreWater = true
    local origin = Camera.CFrame.Position
    local direction = part.Position - origin
    local rayResult = Workspace:Raycast(origin, direction, raycastParams)
    return rayResult == nil
end

local function getLocalTeam()
    if SpectateController then
        local duel = SpectateController.CurrentDuelSubject
        local localDueler = duel and duel:GetDueler(LocalPlayer)
        local localTeam = localDueler and localDueler:Get("TeamID") or nil
        if localTeam ~= nil then return localTeam end
    end
    return LocalPlayer:GetAttribute("TeamID") or LocalPlayer:GetAttribute("Team")
end

local function IsEnemy(player, checkEnabled)
    if not checkEnabled or not player or player == LocalPlayer then return false end
    local localTeam = getLocalTeam()
    if SpectateController then
        local duel = SpectateController.CurrentDuelSubject
        if localTeam and duel and duel.Duelers then
            for _, dueler in duel.Duelers do
                if dueler.Player == player then
                    return dueler:Get("TeamID") ~= localTeam
                end
            end
        end
    end
    local pTeam = player:GetAttribute("TeamID") or player:GetAttribute("Team")
    if pTeam and localTeam then return pTeam ~= localTeam end
    return true
end

local function GetTPTarget()
    local bestPlayer, bestDist = nil, math.huge
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if not IsEnemy(p, true) then continue end
        local char = p.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hum or hum.Health <= 0 or not root then continue end
        local dist = (myRoot.Position - root.Position).Magnitude
        if dist < bestDist then
            bestDist = dist
            bestPlayer = p
        end
    end
    return bestPlayer
end

local function GetClosestTarget()
    local targetPlayer = GetTPTarget()
    if not targetPlayer or not targetPlayer.Character then return nil end
    local char = targetPlayer.Character
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    local targetPart = char:FindFirstChild(Config.TargetPart) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    if targetPart and Config.WallCheck and not IsVisible(targetPart, char) then return nil end
    return targetPart
end

-- SILENT AIM
local currentSilentTarget = nil

local function GetSilentTarget()
    if not Config.SilentAimEnabled then return nil end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local bestPart, bestDist = nil, Config.SilentFOVRadius
    local myEnv = LocalPlayer:GetAttribute("EnvironmentID")
    local myChar = LocalPlayer.Character

    for _, entity in ipairs(CS:GetTagged("Entity")) do
        if entity == myChar then continue end
        local player = Players:GetPlayerFromCharacter(entity)
        if player then
            if myEnv and player:GetAttribute("EnvironmentID") ~= myEnv then continue end
            if not IsEnemy(player, Config.SilentTeamCheck) then continue end
        end
        local humanoid = entity:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health <= 0 then continue end
        local part = entity:FindFirstChild(Config.SilentAimHitPart, true)
            or entity:FindFirstChild("HumanoidRootPart")
            or entity:FindFirstChild("Head")
        if not part or not part:IsA("BasePart") then continue end
        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        if Config.SilentWallCheck and not IsVisible(part, entity) then continue end
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist < bestDist then
            bestDist = dist
            bestPart = part
        end
    end

    if not bestPart then
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            if myEnv and p:GetAttribute("EnvironmentID") ~= myEnv then continue end
            if not IsEnemy(p, Config.SilentTeamCheck) then continue end
            local char = p.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not char or not hum or hum.Health <= 0 then continue end
            local part = char:FindFirstChild(Config.SilentAimHitPart)
                or char:FindFirstChild("HumanoidRootPart")
                or char:FindFirstChild("Head")
            if not part then continue end
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if not onScreen then continue end
            if Config.SilentWallCheck and not IsVisible(part, char) then continue end
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
            if dist < bestDist then
                bestDist = dist
                bestPart = part
            end
        end
    end
    return bestPart
end

local function CreateCamData(shootPos, targetPart)
    if not UtilityModule then return {} end
    local targetPos = targetPart.Position
    local data = {}
    data[utf8.char(1)] = {
        [utf8.char(0)] = UtilityModule:EncodeCFrame(CFrame.new(shootPos, targetPos)),
        [utf8.char(1)] = UtilityModule:EncodeCFrame(CFrame.new(shootPos, targetPos)),
        [utf8.char(2)] = targetPart,
        [utf8.char(3)] = UtilityModule:EncodeCFrame(CFrame.new(0.43, 0.25, 0.42)),
    }
    return data
end

if GameplayUtilityModule and GameplayUtilityModule.GetEntitiesFromRaycast then
    local originalRaycast = GameplayUtilityModule.GetEntitiesFromRaycast
    GameplayUtilityModule.GetEntitiesFromRaycast = function(self, envID, params, origin, dir, maxDist, ...)
        local isSilentActive = Config.SilentAimEnabled and (Config.SilentBindMode == "Always" or Config.SilentAimActive)
        if isSilentActive and math.random(1, 100) <= Config.SilentHitChance then
            local targetPart = GetSilentTarget()
            if targetPart then
                local targetPos = targetPart.Position
                if Config.SilentAimUsePrediction then
                    local targetPlayer = Players:GetPlayerFromCharacter(targetPart.Parent)
                    if targetPlayer then
                        local root = targetPart.Parent:FindFirstChild("HumanoidRootPart")
                        if root then
                            targetPos = targetPos + root.AssemblyLinearVelocity * (Config.SilentAimPredictionFactor or 0.05)
                        end
                    end
                end
                local dist = (targetPos - origin).Magnitude
                dir = (targetPos - origin).Unit
                maxDist = dist + 10
            end
        end
        return originalRaycast(self, envID, params, origin, dir, maxDist, ...)
    end
end

local useItemRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Replication"):WaitForChild("Fighter"):WaitForChild("UseItem")
local hookOriginal

hookOriginal = hookfunction(useItemRemote.FireServer, newcclosure(function(self, objID, enumVal, camdata, extra)
    if checkcaller() then return hookOriginal(self, objID, enumVal, camdata, extra) end
    local isSilentActive = Config.SilentAimEnabled and (Config.SilentBindMode == "Always" or Config.SilentAimActive)
    if isSilentActive and math.random(1, 100) <= Config.SilentHitChance then
        local targetPart = GetSilentTarget()
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and targetPart then
            if typeof(camdata) == "table" or camdata == nil then
                camdata = CreateCamData(root.Position, targetPart)
            end
        end
    end
    return hookOriginal(self, objID, enumVal, camdata, extra)
end))

local function SmoothLookAt(targetCFrame)
    if not CameraController then return end
    local weight = math.clamp(Config.Smoothness * Config.Strength, 0.01, 1)
    local smoothedCFrame = Camera.CFrame:Lerp(targetCFrame, weight)
    CameraController:MimicRotation(smoothedCFrame.Rotation)
end

local TargetTPLabel = nil

local function HandleAimbotInput(inputType, keyCode, isBegan)
    if not Config.AimbotEnabled or Config.BindMode == "Always" then return end
    local matched = Config.AimbotIsMouse and (inputType == Config.AimbotMouseEnum) or (keyCode == Config.AimbotKeybind)
    if matched then
        if isBegan then
            if Config.BindMode == "Hold" then Config.AimbotActive = true
            elseif Config.BindMode == "Toggle" then Config.AimbotActive = not Config.AimbotActive end
        else
            if Config.BindMode == "Hold" then Config.AimbotActive = false end
        end
    end
end

local function HandleSilentInput(inputType, keyCode, isBegan)
    if not Config.SilentAimEnabled or Config.SilentBindMode == "Always" then return end
    local matched = Config.SilentIsMouse and (inputType == Config.SilentMouseEnum) or (keyCode == Config.SilentAimKeybind)
    if matched then
        if isBegan then
            if Config.SilentBindMode == "Hold" then Config.SilentAimActive = true
            elseif Config.SilentBindMode == "Toggle" then Config.SilentAimActive = not Config.SilentAimActive end
        else
            if Config.SilentBindMode == "Hold" then Config.SilentAimActive = false end
        end
    end
end

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    HandleAimbotInput(input.UserInputType, input.KeyCode, true)
    HandleSilentInput(input.UserInputType, input.KeyCode, true)
    if Config.InfJump and input.KeyCode == Enum.KeyCode.Space then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

UIS.InputEnded:Connect(function(input)
    HandleAimbotInput(input.UserInputType, input.KeyCode, false)
    HandleSilentInput(input.UserInputType, input.KeyCode, false)
end)

local activeListeners = {}

local function listenToHumanoid(player, humanoid)
    if activeListeners[player] then activeListeners[player]:Disconnect() end
    local lastHealth = humanoid.Health
    activeListeners[player] = humanoid.HealthChanged:Connect(function(newHealth)
        if Config.EnableNotifications and Config.RagebotEnabled and getLocalTeam() ~= nil then
            if newHealth < lastHealth then
                local damageDealt = math.floor((lastHealth - newHealth) + 0.5)
                if damageDealt > 0 then
                    createNotif("Rivals HvH", string.format("Hit %s for %d damage.", player.DisplayName or player.Name, damageDealt), Config.NotifDuration or 2)
                end
            end
            if newHealth <= 0 and lastHealth > 0 then
                createNotif("Rivals HvH", string.format("Eliminated %s", player.DisplayName or player.Name), 2)
            end
        end
        lastHealth = newHealth
    end)
end

local function trackPlayer(player)
    if player == LocalPlayer then return end
    local function onCharacterAdded(char)
        local humanoid = char:WaitForChild("Humanoid", 5)
        if humanoid then listenToHumanoid(player, humanoid) end
    end
    if player.Character then onCharacterAdded(player.Character) end
    player.CharacterAdded:Connect(onCharacterAdded)
end

for _, player in Players:GetPlayers() do trackPlayer(player) end
Players.PlayerAdded:Connect(trackPlayer)
Players.PlayerRemoving:Connect(function(player)
    if activeListeners[player] then activeListeners[player]:Disconnect(); activeListeners[player] = nil end
end)

local function CreateESP(player)
    if ESPCache[player] then return end
    local boxOutline = Drawing.new("Square"); boxOutline.Thickness = 3; boxOutline.Color = Color3.fromRGB(0,0,0); boxOutline.Filled = false
    local box = Drawing.new("Square"); box.Thickness = 1; box.Filled = false
    local nameTag = Drawing.new("Text"); nameTag.Size = 14; nameTag.Center = true; nameTag.Outline = true; nameTag.Color = Color3.fromRGB(255,255,255)
    local healthBarOutline = Drawing.new("Square"); healthBarOutline.Thickness = 1; healthBarOutline.Color = Color3.fromRGB(0,0,0); healthBarOutline.Filled = true
    local healthBar = Drawing.new("Square"); healthBar.Filled = true
    local tracer = Drawing.new("Line"); tracer.Thickness = 1
    local headDot = Drawing.new("Circle"); headDot.Thickness = 1; headDot.Filled = true; headDot.NumSides = 16
    ESPCache[player] = { BoxOutline = boxOutline, Box = box, NameTag = nameTag, HealthOutline = healthBarOutline, Health = healthBar, Tracer = tracer, HeadDot = headDot }
end

local function RemoveESP(player)
    if ESPCache[player] then
        for _, obj in pairs(ESPCache[player]) do obj:Remove() end
        ESPCache[player] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateESP(p) end end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

RS.Heartbeat:Connect(function()
    if not Config.HitboxExtender then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if IsEnemy(p, true) and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                root.Transparency = 0.8
                root.CanCollide = false
            end
        end
    end
end)

RS.RenderStepped:Connect(function()
    local mousePos = UIS:GetMouseLocation()
    statusLabel.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y + 38)
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if Config.StaticTPEnabled and myChar and myRoot then
        myRoot.AssemblyLinearVelocity = Vector3.zero
        myRoot.AssemblyAngularVelocity = Vector3.zero
        myChar:PivotTo(CFrame.new(Config.StaticTPPos))
        if TargetTPLabel then TargetTPLabel:Set("Static TP: (7000, 3954, 2000)") end
    elseif Config.TargetTPEnabled then
        local target = GetTPTarget()
        if target and target.Character then
            local targetHum = target.Character:FindFirstChildOfClass("Humanoid")
            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if targetHum and targetHum.Health > 0 and targetRoot and myRoot then
                myRoot.AssemblyLinearVelocity = Vector3.zero
                myRoot.AssemblyAngularVelocity = Vector3.zero
                local targetCFrame = targetRoot.CFrame * CFrame.new(Config.TPOffsetX, Config.TPOffsetY, Config.TPOffsetZ)
                myChar:PivotTo(targetCFrame)
                if TargetTPLabel then TargetTPLabel:Set("Target: " .. target.Name) end
            else
                if TargetTPLabel then TargetTPLabel:Set("Target: None") end
            end
        else
            if TargetTPLabel then TargetTPLabel:Set("Target: None") end
        end
    end
end)

local aaRestoreCounter = 0
RS.Heartbeat:Connect(function()
    if not Config.AntiAimEnabled or Config.StaticTPEnabled then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local yawAngle = 0
    if Config.YawMode == "Spin" then yawAngle = (tick() * (Config.SpinSpeed * 50)) % 360
    elseif Config.YawMode == "Jitter" then yawAngle = math.random(-180, 180)
    elseif Config.YawMode == "Backward" then yawAngle = 180 end
    local pitchAngle = 0
    if Config.PitchMode == "Up" then pitchAngle = 89
    elseif Config.PitchMode == "Down" then pitchAngle = -89
    elseif Config.PitchMode == "Jitter" then pitchAngle = math.random(-89, 89) end
    local currentPos = root.Position
    local antiAimCF = CFrame.new(currentPos) * CFrame.Angles(math.rad(pitchAngle), math.rad(yawAngle), 0)
    if Config.AntiAimDesync then
        local oldCF = root.CFrame
        root.CFrame = antiAimCF
        aaRestoreCounter = aaRestoreCounter + 1
        local id = "__aa_restore_" .. aaRestoreCounter
        RS:BindToRenderStep(id, 202, function()
            if root then root.CFrame = oldCF end
            RS:UnbindFromRenderStep(id)
        end)
    else
        root.CFrame = antiAimCF
    end
end)

-- ============================================================
-- RAGEBOT SETUP
-- ============================================================
local slots = { Primary = 1, Secondary = 2, Melee = 3 }
local function getSlotNumber() return slots[Config.WeaponSlot] or 1 end

local VelHistory = {}
local VEL_SAMPLES = 8

local function pushVelocity(player, vel)
    local h = VelHistory[player]
    if not h then h = { x = {}, y = {}, z = {} }; VelHistory[player] = h end
    table.insert(h.x, vel.X); table.insert(h.y, vel.Y); table.insert(h.z, vel.Z)
    if #h.x > VEL_SAMPLES then
        table.remove(h.x, 1); table.remove(h.y, 1); table.remove(h.z, 1)
    end
end

local function avgVelocity(player)
    local h = VelHistory[player]
    if not h or #h.x == 0 then return Vector3.zero end
    local sx, sy, sz = 0, 0, 0
    for i = 1, #h.x do sx = sx + h.x[i]; sy = sy + h.y[i]; sz = sz + h.z[i] end
    local n = #h.x
    return Vector3.new(sx/n, sy/n, sz/n)
end

local RageTarget = { Player = nil, Part = nil, Root = nil, LockedAt = 0 }

local function acquireRageTarget(force)
    local now = tick()
    if not force and RageTarget.Player and RageTarget.Root and now - RageTarget.LockedAt < 0.2 then
        local hum = RageTarget.Root.Parent:FindFirstChildOfClass("Humanoid")
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hum and hum.Health > 0 and myRoot then
            local dist = (myRoot.Position - RageTarget.Root.Position).Magnitude
            if dist <= Config.RagebotMaxRange then
                return RageTarget.Player, RageTarget.Part, RageTarget.Root
            end
        end
    end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local bestP, bestPart, bestRoot, bestScore = nil, nil, nil, math.huge
    local crosshair = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, p in ipairs(Players:GetPlayers()) do
        if not IsEnemy(p, true) then continue end
        local char = p.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not hum or hum.Health <= 0 or not root then continue end
        local worldDist = (myRoot.Position - root.Position).Magnitude
        if worldDist > Config.RagebotMaxRange then continue end
        local score
        if Config.TargetPriority == "Distance" then score = worldDist
        elseif Config.TargetPriority == "Health" then score = hum.Health
        else
            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - crosshair).Magnitude
                score = screenDist + worldDist * 0.3
            else score = worldDist end
        end
        if score < bestScore then
            local part
            local order = Config.Multipoint
                and {"Head", "UpperTorso", "HumanoidRootPart", "LeftUpperArm", "RightUpperArm"}
                or  {"Head", "UpperTorso", "HumanoidRootPart"}
            for _, name in ipairs(order) do
                local q = char:FindFirstChild(name)
                if q and q:IsA("BasePart") then part = q; break end
            end
            if part then
                bestScore = score
                bestP, bestPart, bestRoot = p, part, root
            end
        end
    end
    if bestP then
        RageTarget.Player = bestP
        RageTarget.Part = bestPart
        RageTarget.Root = bestRoot
        RageTarget.LockedAt = now
    else
        RageTarget.Player = nil
    end
    return bestP, bestPart, bestRoot
end

RS.Heartbeat:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if root then pushVelocity(p, root.AssemblyLinearVelocity) end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    VelHistory[player] = nil
    if RageTarget.Player == player then
        RageTarget.Player = nil; RageTarget.Part = nil; RageTarget.Root = nil
    end
end)

task.spawn(function()
    while true do
        task.wait(0.25)
        if not Config.RagebotEnabled then continue end
        if getLocalTeam() == nil then continue end
        if FighterController and FighterController.LocalFighter then
            pcall(function() FighterController.LocalFighter:EquipItem(getSlotNumber()) end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        if not Config.RagebotEnabled or getLocalTeam() == nil then
            statusLabel.Text = "ragebot: off"
        elseif RageTarget.Player then
            statusLabel.Text = "ragebot: " .. (RageTarget.Player.DisplayName or RageTarget.Player.Name)
        else
            statusLabel.Text = "ragebot: scanning"
        end
    end
end)

-- Desync positioning loop (unchanged)
local rageDesyncCounter = 0
RS.Heartbeat:Connect(function()
    if not Config.RagebotEnabled or getLocalTeam() == nil then return end
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local targetPlayer, _, targetRoot = acquireRageTarget(false)
    if not targetPlayer or not targetRoot then return end
    local now = tick()
    local offsetMode = Config.RagebotPositionMode or "Behind"
    local desyncPos
    if offsetMode == "Behind" then
        desyncPos = (targetRoot.CFrame * CFrame.new(0, 0, -3)).Position
    elseif offsetMode == "Above" then
        desyncPos = (targetRoot.CFrame * CFrame.new(0, 4, 0)).Position
    elseif offsetMode == "Below" then
        desyncPos = (targetRoot.CFrame * CFrame.new(0, -4, 0)).Position
    elseif offsetMode == "Under" then
        desyncPos = (targetRoot.CFrame * CFrame.new(0, -8, 0)).Position
    elseif offsetMode == "Around" then
        local angle = now * 8
        desyncPos = (targetRoot.CFrame * CFrame.new(math.cos(angle) * 4, 0, math.sin(angle) * 4)).Position
    elseif offsetMode == "Orbit Above" then
        local angle = now * 10
        desyncPos = (targetRoot.CFrame * CFrame.new(math.cos(angle) * 5, 3, math.sin(angle) * 5)).Position
    elseif offsetMode == "Orbit Below" then
        local angle = now * 10
        desyncPos = (targetRoot.CFrame * CFrame.new(math.cos(angle) * 5, -3, math.sin(angle) * 5)).Position
    elseif offsetMode == "Helix" then
        local angle = now * 12
        desyncPos = (targetRoot.CFrame * CFrame.new(math.cos(angle) * 3.5, math.sin(now * 5) * 2, math.sin(angle) * 3.5)).Position
    elseif offsetMode == "Custom" then
        desyncPos = (targetRoot.CFrame * CFrame.new(Config.CustomOffsetX, Config.CustomOffsetY, Config.CustomOffsetZ)).Position
    else
        desyncPos = targetRoot.Position
    end
    local oldCF = myRoot.CFrame
    local oldVel = myRoot.AssemblyLinearVelocity
    local oldRot = myRoot.AssemblyAngularVelocity
    myRoot.CFrame = CFrame.lookAt(desyncPos, targetRoot.Position)
    myRoot.AssemblyLinearVelocity = Vector3.zero
    myRoot.AssemblyAngularVelocity = Vector3.zero
    rageDesyncCounter = rageDesyncCounter + 1
    local id = "__rage_pos_" .. rageDesyncCounter
    RS:BindToRenderStep(id, 201, function()
        if myRoot and myRoot.Parent then
            myRoot.CFrame = oldCF
            myRoot.AssemblyLinearVelocity = oldVel
            myRoot.AssemblyAngularVelocity = oldRot
        end
        RS:UnbindFromRenderStep(id)
    end)
end)

-- ============================================================
-- MAIN RAGEBOT FIRE LOOP — FAST VERSION
-- Fires BurstCount shots per FireDelay interval
-- ============================================================
local shotsFired = 0
local hits = 0
local lastTargetRef = nil
local lastTargetHealth = nil

task.spawn(function()
    while true do
        task.wait()  -- yield to avoid script timeout; rate is controlled by FireDelay below

        if not Config.RagebotEnabled then continue end
        if getLocalTeam() == nil then continue end
        if not FighterController or not FighterController.LocalFighter then continue end

        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then continue end

        local item = FighterController.LocalFighter.EquippedItem
        if not item then continue end

        local targetPlayer, targetPart, targetRoot = acquireRageTarget(false)
        if not targetPlayer or not targetPart or not targetRoot then continue end

        if math.random(1, 100) > (Config.RagebotHitChance or 100) then continue end

        -- Prediction
        local avgVel = avgVelocity(targetPlayer)
        local ping = 0
        pcall(function() ping = LocalPlayer:GetNetworkPing() end)
        local flightTime = (Config.PredictionFactor or 0.05) + (ping * 0.5)

        -- Compute desync shootPos for this batch
        local shootPos = myRoot.Position
        if Config.RagebotPositionMode ~= "None" and targetRoot then
            local offsetMode = Config.RagebotPositionMode
            if offsetMode == "Behind" then
                shootPos = (targetRoot.CFrame * CFrame.new(0, 0, -3)).Position
            elseif offsetMode == "Above" then
                shootPos = (targetRoot.CFrame * CFrame.new(0, 4, 0)).Position
            elseif offsetMode == "Below" then
                shootPos = (targetRoot.CFrame * CFrame.new(0, -4, 0)).Position
            elseif offsetMode == "Under" then
                shootPos = (targetRoot.CFrame * CFrame.new(0, -8, 0)).Position
            elseif offsetMode == "Around" then
                local angle = tick() * 8
                shootPos = (targetRoot.CFrame * CFrame.new(math.cos(angle) * 4, 0, math.sin(angle) * 4)).Position
            elseif offsetMode == "Orbit Above" then
                local angle = tick() * 10
                shootPos = (targetRoot.CFrame * CFrame.new(math.cos(angle) * 5, 3, math.sin(angle) * 5)).Position
            elseif offsetMode == "Orbit Below" then
                local angle = tick() * 10
                shootPos = (targetRoot.CFrame * CFrame.new(math.cos(angle) * 5, -3, math.sin(angle) * 5)).Position
            elseif offsetMode == "Helix" then
                local angle = tick() * 12
                shootPos = (targetRoot.CFrame * CFrame.new(math.cos(angle) * 3.5, math.sin(tick() * 5) * 2, math.sin(angle) * 3.5)).Position
            elseif offsetMode == "Custom" then
                shootPos = (targetRoot.CFrame * CFrame.new(Config.CustomOffsetX, Config.CustomOffsetY, Config.CustomOffsetZ)).Position
            end
        end

        local objectID = item:Get("ObjectID")
        local enumVal = EnumLibrary and EnumLibrary:ToEnum("StartShooting") or 1

        -- Burst fire
        local burst = math.max(1, Config.BurstCount or 3)
        for i = 1, burst do
            -- Cycle through parts across burst for better hit registration
            local partToHit = targetPart
            local char = targetPlayer.Character
            if char then
                if i % 3 == 0 then
                    partToHit = char:FindFirstChild("Head") or targetPart
                elseif i % 3 == 1 then
                    partToHit = char:FindFirstChild("UpperTorso") or targetPart
                else
                    partToHit = char:FindFirstChild("HumanoidRootPart") or targetPart
                end
            end

            local predictedPos = partToHit.Position + avgVel * flightTime
            local aimCF = CFrame.new(shootPos, predictedPos)

            local cameradata = {}
            cameradata[utf8.char(1)] = {
                [utf8.char(0)] = UtilityModule:EncodeCFrame(aimCF),
                [utf8.char(1)] = UtilityModule:EncodeCFrame(aimCF),
                [utf8.char(2)] = partToHit,
                [utf8.char(3)] = UtilityModule:EncodeCFrame(CFrame.new(0.43, 0.25, 0.42)),
            }

            shotsFired = shotsFired + 1

            pcall(function()
                useItemRemote:FireServer(objectID, enumVal, cameradata, nil)
            end)
        end

        -- Configurable delay between bursts (much smaller than 1 frame)
        local delay = Config.FireDelay or 0.01
        if delay > 0 then
            task.wait(delay)
        end
    end
end)

-- Hit tracker (watch target health)
task.spawn(function()
    while true do
        task.wait(0.1)
        if RageTarget.Player and RageTarget.Player.Character then
            local hum = RageTarget.Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                if lastTargetRef == RageTarget.Player and lastTargetHealth and hum.Health < lastTargetHealth then
                    hits = hits + 1
                end
                lastTargetRef = RageTarget.Player
                lastTargetHealth = hum.Health
            end
        end
    end
end)

-- Show rate in status label
task.spawn(function()
    while true do
        task.wait(1)
        if Config.RagebotEnabled and getLocalTeam() ~= nil then
            local rate = math.floor((Config.BurstCount or 3) / math.max(Config.FireDelay or 0.01, 0.001))
            local acc = shotsFired > 0 and math.floor((hits / shotsFired) * 100) or 0
            local name = RageTarget.Player and (RageTarget.Player.DisplayName or RageTarget.Player.Name) or "scanning"
            statusLabel.Text = string.format("ragebot: %s | %d/s | hits: %d (%d%%)", name, rate, hits, acc)
        end
    end
end)

-- Visual loops
RS.Heartbeat:Connect(function()
    if Config.ShowFOV then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius = Config.FOVRadius
        FOVCircle.Color = Config.FOVColor
        FOVCircle.Visible = true
    else FOVCircle.Visible = false end

    if Config.ShowSilentFOV then
        SilentFOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        SilentFOVCircle.Radius = Config.SilentFOVRadius
        SilentFOVCircle.Color = Config.SilentFOVColor
        SilentFOVCircle.Visible = true
    else SilentFOVCircle.Visible = false end

    currentSilentTarget = GetSilentTarget()
    if Config.ShowSilentTarget and currentSilentTarget then
        local screenPos, onScreen = Camera:WorldToViewportPoint(currentSilentTarget.Position)
        if onScreen then
            TargetHighlight.Position = Vector2.new(screenPos.X, screenPos.Y)
            TargetHighlight.Radius = 8
            TargetHighlight.Color = Config.SilentTargetColor
            TargetHighlight.Visible = true
            if Config.ShowSilentTracer then
                TargetTracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                TargetTracer.To = Vector2.new(screenPos.X, screenPos.Y)
                TargetTracer.Color = Config.SilentTargetColor
                TargetTracer.Visible = true
            else TargetTracer.Visible = false end
        else
            TargetHighlight.Visible = false
            TargetTracer.Visible = false
        end
    else
        TargetHighlight.Visible = false
        TargetTracer.Visible = false
    end

    local shouldAim = Config.AimbotEnabled and (Config.BindMode == "Always" or Config.AimbotActive)
    if shouldAim then
        local targetPart = GetClosestTarget()
        if targetPart then SmoothLookAt(CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)) end
    end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")

    if Config.FlyEnabled and myRoot and myHum then
        local moveDir = myHum.MoveDirection
        local flyVel = Vector3.zero
        if moveDir.Magnitude > 0 then flyVel = moveDir * Config.FlySpeed end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then flyVel = flyVel + Vector3.new(0, Config.FlySpeed, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then flyVel = flyVel - Vector3.new(0, Config.FlySpeed, 0) end
        myRoot.AssemblyLinearVelocity = flyVel
    end

    if myHum then
        if Config.WalkSpeedEnabled then myHum.WalkSpeed = Config.WalkSpeedValue end
        if Config.JumpPowerEnabled then
            myHum.UseJumpPower = true
            myHum.JumpPower = Config.JumpPowerValue
        end
    end

    if myChar then
        for _, part in ipairs(myChar:GetDescendants()) do
            if part:IsA("BasePart") and Config.Noclip then part.CanCollide = false end
        end
    end
end)

RS.RenderStepped:Connect(function()
    for player, drawings in pairs(ESPCache) do
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if Config.ESPEnabled and char and hum and root and hum.Health > 0 and IsEnemy(player, Config.ESPTeamCheck) then
            local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local head = char:FindFirstChild("Head")
                local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
                local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                local height = math.abs(headPos.Y - legPos.Y)
                local width = height / 2
                local boxColor = Config.BoxColor
                if Config.ESPTeamColor and player.TeamColor then boxColor = player.TeamColor.Color end
                if Config.ESPBoxes then
                    drawings.BoxOutline.Size = Vector2.new(width, height)
                    drawings.BoxOutline.Position = Vector2.new(rootPos.X - width / 2, rootPos.Y - height / 2)
                    drawings.BoxOutline.Visible = true
                    drawings.Box.Size = Vector2.new(width, height)
                    drawings.Box.Position = Vector2.new(rootPos.X - width / 2, rootPos.Y - height / 2)
                    drawings.Box.Color = boxColor
                    drawings.Box.Visible = true
                else
                    drawings.BoxOutline.Visible = false; drawings.Box.Visible = false
                end
                if Config.ESPNames or Config.ESPDistance then
                    local labelText = ""
                    if Config.ESPNames then labelText = player.Name end
                    if Config.ESPDistance then
                        local dist = math.floor((root.Position - Camera.CFrame.Position).Magnitude)
                        labelText = labelText .. (labelText ~= "" and " [" or "[") .. dist .. "m]"
                    end
                    drawings.NameTag.Text = labelText
                    drawings.NameTag.Color = Config.NameColor
                    drawings.NameTag.Position = Vector2.new(rootPos.X, rootPos.Y - height / 2 - 16)
                    drawings.NameTag.Visible = true
                else drawings.NameTag.Visible = false end
                if Config.ESPHealth then
                    local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    local barHeight = height * healthPercent
                    drawings.HealthOutline.Size = Vector2.new(4, height + 2)
                    drawings.HealthOutline.Position = Vector2.new(rootPos.X - width / 2 - 7, rootPos.Y - height / 2 - 1)
                    drawings.HealthOutline.Visible = true
                    drawings.Health.Size = Vector2.new(2, barHeight)
                    drawings.Health.Position = Vector2.new(rootPos.X - width / 2 - 6, rootPos.Y + height / 2 - barHeight)
                    drawings.Health.Color = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), healthPercent)
                    drawings.Health.Visible = true
                else
                    drawings.HealthOutline.Visible = false; drawings.Health.Visible = false
                end
                if Config.ESPTracers then
                    drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    drawings.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                    drawings.Tracer.Color = Config.TracerColor
                    drawings.Tracer.Visible = true
                else drawings.Tracer.Visible = false end
                if Config.ESPHeadDots and head then
                    local headScreenPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
                    if headOnScreen then
                        drawings.HeadDot.Position = Vector2.new(headScreenPos.X, headScreenPos.Y)
                        drawings.HeadDot.Radius = math.clamp(height / 10, 2, 8)
                        drawings.HeadDot.Color = Config.HeadDotColor
                        drawings.HeadDot.Visible = true
                    else drawings.HeadDot.Visible = false end
                else drawings.HeadDot.Visible = false end
            else
                for _, d in pairs(drawings) do d.Visible = false end
            end
        else
            for _, d in pairs(drawings) do d.Visible = false end
        end
    end
end)

-- ============================================================
-- UI
-- ============================================================

RagebotTab:CreateToggle({ Name = "Ragebot Enabled", CurrentValue = false, Flag = "RagebotToggle",
    Callback = function(Value) Config.RagebotEnabled = Value end })

RagebotTab:CreateDropdown({ Name = "Weapon Slot", Options = {"Primary", "Secondary", "Melee"},
    CurrentOption = {"Primary"}, MultipleOptions = false, Flag = "RagebotWeaponSlot",
    Callback = function(Option) Config.WeaponSlot = Option[1] end })

RagebotTab:CreateDropdown({ Name = "Position Mode",
    Options = {"None", "Behind", "Above", "Below", "Under", "Around", "Orbit Above", "Orbit Below", "Helix", "Custom"},
    CurrentOption = {"Behind"}, MultipleOptions = false, Flag = "RagebotPositionMode",
    Callback = function(Option) Config.RagebotPositionMode = Option[1] end })

RagebotTab:CreateSlider({ Name = "Custom Offset X", Range = {-20, 20}, Increment = 0.5, CurrentValue = 0,
    Flag = "RageCustomX", Callback = function(Value) Config.CustomOffsetX = Value end })
RagebotTab:CreateSlider({ Name = "Custom Offset Y", Range = {-20, 20}, Increment = 0.5, CurrentValue = 0,
    Flag = "RageCustomY", Callback = function(Value) Config.CustomOffsetY = Value end })
RagebotTab:CreateSlider({ Name = "Custom Offset Z", Range = {-20, 20}, Increment = 0.5, CurrentValue = -3,
    Flag = "RageCustomZ", Callback = function(Value) Config.CustomOffsetZ = Value end })

RagebotTab:CreateDropdown({ Name = "Target Priority", Options = {"Crosshair", "Distance", "Health"},
    CurrentOption = {"Crosshair"}, MultipleOptions = false, Flag = "RagebotTargetPriority",
    Callback = function(Option) Config.TargetPriority = Option[1] end })

RagebotTab:CreateSlider({ Name = "Max Target Range", Range = {50, 2000}, Increment = 25, Suffix = "studs",
    CurrentValue = 500, Flag = "RagebotMaxRange",
    Callback = function(Value) Config.RagebotMaxRange = Value end })

RagebotTab:CreateSlider({ Name = "Hit Chance", Range = {1, 100}, Increment = 1, Suffix = "%",
    CurrentValue = 100, Flag = "RagebotHitChance",
    Callback = function(Value) Config.RagebotHitChance = Value end })

RagebotTab:CreateSection("Fire Rate")

RagebotTab:CreateSlider({ Name = "Fire Delay (seconds)", Range = {0.001, 0.2}, Increment = 0.001,
    CurrentValue = 0.01, Flag = "RagebotFireDelay",
    Callback = function(Value) Config.FireDelay = Value end })

RagebotTab:CreateSlider({ Name = "Burst Count (shots per tick)", Range = {1, 10}, Increment = 1,
    CurrentValue = 3, Flag = "RagebotBurstCount",
    Callback = function(Value) Config.BurstCount = Value end })

RagebotTab:CreateSection("Accuracy")
RagebotTab:CreateToggle({ Name = "Multipoint Hitscan", CurrentValue = true, Flag = "RagebotMultipoint",
    Callback = function(Value) Config.Multipoint = Value end })
RagebotTab:CreateToggle({ Name = "Enable Prediction", CurrentValue = true, Flag = "RagebotPredictionToggle",
    Callback = function(Value) Config.EnablePrediction = Value end })
RagebotTab:CreateSlider({ Name = "Prediction Factor", Range = {0.01, 0.2}, Increment = 0.005,
    CurrentValue = 0.05, Flag = "RagebotPredictionFactor",
    Callback = function(Value) Config.PredictionFactor = Value end })

RagebotTab:CreateSection("Notifications")
RagebotTab:CreateToggle({ Name = "Damage Notifications", CurrentValue = true, Flag = "RagebotNotifToggle",
    Callback = function(Value) Config.EnableNotifications = Value end })

HvHTab:CreateSection("Rivals HvH Enhancements")
HvHTab:CreateToggle({ Name = "Hitbox Extender", CurrentValue = true, Flag = "HitboxExtenderToggle",
    Callback = function(Value) Config.HitboxExtender = Value end })
HvHTab:CreateSlider({ Name = "Hitbox Size Scale", Range = {1.0, 6.0}, Increment = 0.2,
    CurrentValue = 2.5, Flag = "HitboxSizeSlider",
    Callback = function(Value) Config.HitboxSize = Value end })
HvHTab:CreateToggle({ Name = "Auto-Wall Check Bypass", CurrentValue = true, Flag = "AutoWallToggle",
    Callback = function(Value) Config.WallCheck = not Value end })

AntiAimTab:CreateToggle({ Name = "Enable Anti-Aim", CurrentValue = false, Flag = "AntiAimToggle",
    Callback = function(Value) Config.AntiAimEnabled = Value end })
AntiAimTab:CreateDropdown({ Name = "Yaw Mode", Options = {"Spin", "Jitter", "Backward", "Static"},
    CurrentOption = {"Spin"}, MultipleOptions = false, Flag = "AntiAimYawMode",
    Callback = function(Option) Config.YawMode = Option[1] end })
AntiAimTab:CreateSlider({ Name = "Spin Speed", Range = {1, 50}, Increment = 1, CurrentValue = 15,
    Flag = "AntiAimSpinSpeed", Callback = function(Value) Config.SpinSpeed = Value end })
AntiAimTab:CreateDropdown({ Name = "Pitch Mode", Options = {"None", "Up", "Down", "Jitter"},
    CurrentOption = {"None"}, MultipleOptions = false, Flag = "AntiAimPitchMode",
    Callback = function(Option) Config.PitchMode = Option[1] end })
AntiAimTab:CreateToggle({ Name = "Desync / Render Shift", CurrentValue = false, Flag = "AntiAimDesyncToggle",
    Callback = function(Value) Config.AntiAimDesync = Value end })

AimbotTab:CreateToggle({ Name = "Aimbot Enabled", CurrentValue = false, Flag = "AimbotToggle",
    Callback = function(Value) Config.AimbotEnabled = Value end })
AimbotTab:CreateDropdown({ Name = "Activation Mode", Options = {"Hold", "Toggle", "Always"},
    CurrentOption = {"Toggle"}, MultipleOptions = false, Flag = "BindModeDropdown",
    Callback = function(Option) Config.BindMode = Option[1] end })
AimbotTab:CreateKeybind({ Name = "Aimbot Keybind", CurrentKeybind = "Q", HoldToInteract = false,
    Flag = "AimbotKeybind",
    Callback = function(Key)
        local keyStr = tostring(Key)
        if keyStr:find("MouseButton1") or keyStr == "MB1" then
            Config.AimbotIsMouse = true; Config.AimbotMouseEnum = Enum.UserInputType.MouseButton1
        elseif keyStr:find("MouseButton2") or keyStr == "MB2" then
            Config.AimbotIsMouse = true; Config.AimbotMouseEnum = Enum.UserInputType.MouseButton2
        else
            Config.AimbotIsMouse = false; Config.AimbotKeybind = Key
        end
    end })
AimbotTab:CreateDropdown({ Name = "Target Part", Options = {"Head", "HumanoidRootPart", "Closest Part"},
    CurrentOption = {"Head"}, MultipleOptions = false, Flag = "TargetPartDropdown",
    Callback = function(Option) Config.TargetPart = Option[1] end })
AimbotTab:CreateToggle({ Name = "Team Check (TeamID)", CurrentValue = false, Flag = "TeamCheckToggle",
    Callback = function(Value) Config.TeamCheck = Value end })
AimbotTab:CreateSlider({ Name = "Smoothness", Range = {0.01, 0.5}, Increment = 0.01, Suffix = "Lerp Factor",
    CurrentValue = 0.12, Flag = "SmoothnessSlider",
    Callback = function(Value) Config.Smoothness = Value end })
AimbotTab:CreateSlider({ Name = "Aimbot Strength", Range = {0.1, 2.0}, Increment = 0.1, Suffix = "x Multiplier",
    CurrentValue = 1.0, Flag = "StrengthSlider",
    Callback = function(Value) Config.Strength = Value end })
AimbotTab:CreateSection("FOV Settings")
AimbotTab:CreateToggle({ Name = "Show FOV Circle", CurrentValue = false, Flag = "ShowFOVToggle",
    Callback = function(Value) Config.ShowFOV = Value end })
AimbotTab:CreateSlider({ Name = "FOV Radius", Range = {20, 800}, Increment = 5, Suffix = "px",
    CurrentValue = 150, Flag = "FOVRadiusSlider",
    Callback = function(Value) Config.FOVRadius = Value end })
AimbotTab:CreateColorPicker({ Name = "FOV Circle Color", Color = Color3.fromRGB(255, 255, 255),
    Flag = "FOVColorPicker", Callback = function(Value) Config.FOVColor = Value end })

SilentTab:CreateToggle({ Name = "Silent Aim Enabled", CurrentValue = false, Flag = "SilentAimToggle",
    Callback = function(Value) Config.SilentAimEnabled = Value end })
SilentTab:CreateDropdown({ Name = "Activation Mode", Options = {"Always", "Hold", "Toggle"},
    CurrentOption = {"Always"}, MultipleOptions = false, Flag = "SilentBindModeDropdown",
    Callback = function(Option) Config.SilentBindMode = Option[1] end })
SilentTab:CreateDropdown({ Name = "Hit Part", Options = {"Head", "HumanoidRootPart", "UpperTorso"},
    CurrentOption = {"Head"}, MultipleOptions = false, Flag = "SilentHitPartDropdown",
    Callback = function(Option) Config.SilentAimHitPart = Option[1] end })
SilentTab:CreateSlider({ Name = "Hit Chance", Range = {1, 100}, Increment = 1, Suffix = "%",
    CurrentValue = 100, Flag = "SilentHitChanceSlider",
    Callback = function(Value) Config.SilentHitChance = Value end })
SilentTab:CreateToggle({ Name = "Enable Prediction", CurrentValue = true, Flag = "SilentPredictionToggle",
    Callback = function(Value) Config.SilentAimUsePrediction = Value end })
SilentTab:CreateSlider({ Name = "Prediction Factor", Range = {0.01, 0.15}, Increment = 0.005,
    CurrentValue = 0.05, Flag = "SilentPredictionFactor",
    Callback = function(Value) Config.SilentAimPredictionFactor = Value end })
SilentTab:CreateToggle({ Name = "Team Check (TeamID)", CurrentValue = false, Flag = "SilentTeamCheckToggle",
    Callback = function(Value) Config.SilentTeamCheck = Value end })
SilentTab:CreateSection("Target Visualizer")
SilentTab:CreateToggle({ Name = "Show Target Circle", CurrentValue = false, Flag = "ShowSilentTargetToggle",
    Callback = function(Value) Config.ShowSilentTarget = Value end })
SilentTab:CreateToggle({ Name = "Show Line to Target", CurrentValue = false, Flag = "ShowSilentTracerToggle",
    Callback = function(Value) Config.ShowSilentTracer = Value end })

ESPTab:CreateToggle({ Name = "Enable ESP", CurrentValue = false, Flag = "ESPEnabledToggle",
    Callback = function(Value) Config.ESPEnabled = Value end })
ESPTab:CreateToggle({ Name = "Team Check (TeamID)", CurrentValue = false, Flag = "ESPTeamCheckToggle",
    Callback = function(Value) Config.ESPTeamCheck = Value end })
ESPTab:CreateToggle({ Name = "Use Team Colors", CurrentValue = false, Flag = "ESPTeamColorToggle",
    Callback = function(Value) Config.ESPTeamColor = Value end })
ESPTab:CreateSection("ESP Elements")
ESPTab:CreateToggle({ Name = "2D Box ESP", CurrentValue = false, Flag = "ESPBoxesToggle",
    Callback = function(Value) Config.ESPBoxes = Value end })
ESPTab:CreateToggle({ Name = "Name Tags", CurrentValue = false, Flag = "ESPNamesToggle",
    Callback = function(Value) Config.ESPNames = Value end })
ESPTab:CreateToggle({ Name = "Distance ESP", CurrentValue = false, Flag = "ESPDistanceToggle",
    Callback = function(Value) Config.ESPDistance = Value end })
ESPTab:CreateToggle({ Name = "Dynamic Health Bar", CurrentValue = false, Flag = "ESPHealthToggle",
    Callback = function(Value) Config.ESPHealth = Value end })
ESPTab:CreateToggle({ Name = "Snapline Tracers", CurrentValue = false, Flag = "ESPTracersToggle",
    Callback = function(Value) Config.ESPTracers = Value end })
ESPTab:CreateToggle({ Name = "Head Dot Indicator", CurrentValue = false, Flag = "ESPHeadDotsToggle",
    Callback = function(Value) Config.ESPHeadDots = Value end })

MovementTab:CreateToggle({ Name = "Enable WalkSpeed Override", CurrentValue = false, Flag = "WalkSpeedToggle",
    Callback = function(Value)
        Config.WalkSpeedEnabled = Value
        if not Value then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end })
MovementTab:CreateSlider({ Name = "WalkSpeed Value", Range = {16, 250}, Increment = 1, CurrentValue = 16,
    Flag = "WalkSpeedSlider", Callback = function(Value) Config.WalkSpeedValue = Value end })
MovementTab:CreateToggle({ Name = "Enable JumpPower Override", CurrentValue = false, Flag = "JumpPowerToggle",
    Callback = function(Value)
        Config.JumpPowerEnabled = Value
        if not Value then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = 50 end
        end
    end })
MovementTab:CreateSlider({ Name = "JumpPower Value", Range = {50, 300}, Increment = 5, CurrentValue = 50,
    Flag = "JumpPowerSlider", Callback = function(Value) Config.JumpPowerValue = Value end })
MovementTab:CreateToggle({ Name = "Infinite Jump", CurrentValue = false, Flag = "InfJumpToggle",
    Callback = function(Value) Config.InfJump = Value end })
MovementTab:CreateToggle({ Name = "Noclip (Wall Pass)", CurrentValue = false, Flag = "NoclipToggle",
    Callback = function(Value)
        Config.Noclip = Value
        if not Value and LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end })
MovementTab:CreateSection("Flight Controls")
MovementTab:CreateToggle({ Name = "Velocity Fly", CurrentValue = false, Flag = "FlyToggle",
    Callback = function(Value) Config.FlyEnabled = Value end })
MovementTab:CreateSlider({ Name = "Fly Speed", Range = {10, 300}, Increment = 5, CurrentValue = 50,
    Flag = "FlySpeedSlider", Callback = function(Value) Config.FlySpeed = Value end })

TargetTPLabel = CombatTab:CreateLabel("Target: None")
CombatTab:CreateToggle({ Name = "Static Location TP (7000, 3954, 2000)", CurrentValue = false, Flag = "StaticTPToggle",
    Callback = function(Value)
        Config.StaticTPEnabled = Value
        if Value then Config.TargetTPEnabled = false end
        if not Value and TargetTPLabel then TargetTPLabel:Set("Target: None") end
    end })
CombatTab:CreateToggle({ Name = "Auto Target TP Enabled", CurrentValue = false, Flag = "TargetTPToggle",
    Callback = function(Value)
        Config.TargetTPEnabled = Value
        if Value then Config.StaticTPEnabled = false end
        if not Value and TargetTPLabel then TargetTPLabel:Set("Target: None") end
    end })
CombatTab:CreateSection("Target Offset Adjustments")
CombatTab:CreateSlider({ Name = "Offset X (Left / Right)", Range = {-50, 50}, Increment = 0.5, CurrentValue = 0,
    Flag = "TPOffsetXSlider", Callback = function(Value) Config.TPOffsetX = Value end })
CombatTab:CreateSlider({ Name = "Offset Y (Up / Down)", Range = {-50, 50}, Increment = 0.5, CurrentValue = 0,
    Flag = "TPOffsetYSlider", Callback = function(Value) Config.TPOffsetY = Value end })
CombatTab:CreateSlider({ Name = "Offset Z (Forward / Back)", Range = {-50, 50}, Increment = 0.5, CurrentValue = -3,
    Flag = "TPOffsetZSlider", Callback = function(Value) Config.TPOffsetZ = Value end })

CombatTab:CreateSection("Weapon Modifications")
CombatTab:CreateToggle({ Name = "Rapid Fire", CurrentValue = false, Flag = "RapidFireToggle",
    Callback = function(Value)
        Config.RapidFireEnabled = Value
        local function toggleTableAttribute(attribute, value)
            for _, gcVal in pairs(getgc(true)) do
                if type(gcVal) == "table" and rawget(gcVal, attribute) then
                    gcVal[attribute] = value
                end
            end
        end
        if Value then
            toggleTableAttribute("ShootCooldown", 0)
            toggleTableAttribute("AttackCooldown", 0)
            toggleTableAttribute("ShootSpread", 0)
            toggleTableAttribute("ShootRecoil", 0)
        else
            toggleTableAttribute("ShootCooldown", 0.2)
            toggleTableAttribute("AttackCooldown", 0.5)
            toggleTableAttribute("ShootSpread", 1)
            toggleTableAttribute("ShootRecoil", 1)
        end
    end })

Rayfield:LoadConfiguration()

createNotif("Rivals HvH", "Ultimate Suite Loaded Successfully", 3)