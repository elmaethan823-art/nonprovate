-- ============================================================
-- 1. LOAD LINORIA + THEMEMANAGER + SAVEMANAGER
-- ============================================================
local repo = 'https://raw.githubusercontent.com/bocaj111004/Linoria/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

-- ============================================================
-- 2. CONFIG (shared)
-- ============================================================
getgenv().Config = {
    EnableSilentAim = true,
    EnableWallbang = false,
    HitPart = "Head",
    FOVRadius = 300,
    ShowFOV = true
}

-- ============================================================
-- 3. FOV CIRCLE DRAWING
-- ============================================================
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = getgenv().Config.ShowFOV
fovCircle.Radius = getgenv().Config.FOVRadius
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 1
fovCircle.Filled = false

game:GetService("RunService").RenderStepped:Connect(function()
    fovCircle.Position = workspace.CurrentCamera.ViewportSize / 2
    fovCircle.Radius = getgenv().Config.FOVRadius
    fovCircle.Visible = getgenv().Config.ShowFOV
end)

-- ============================================================
-- 4. YOUR ORIGINAL SILENT AIM
-- ============================================================
local phem1_plrs = game:GetService("Players")
local phem2_cs = game:GetService("CollectionService")
local phem5 = game:GetService("ReplicatedStorage")
local phem6 = phem1_plrs.LocalPlayer
local phem7 = require(phem5.Modules.Utility)
local phem8 = phem7.Raycast

local silentAimActive = getgenv().Config.EnableSilentAim

local function phem9()
    if not silentAimActive then return nil end
    local phem10 = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
    local phem11 = nil
    local phem12 = getgenv().Config.FOVRadius
    for phem13, phem14 in phem2_cs:GetTagged("Entity") do
        if phem14 == phem6.Character then continue end
        local phem15 = phem14:FindFirstChild(getgenv().Config.HitPart, true)
        if not phem15 or not phem15:IsA("BasePart") then continue end
        local phem16, phem17 = workspace.CurrentCamera:WorldToViewportPoint(phem15.Position)
        if not phem17 then continue end
        local phem18 = (phem10 - Vector2.new(phem16.X, phem16.Y)).Magnitude
        if phem18 < phem12 then
            phem12 = phem18
            phem11 = phem15
        end
    end
    return phem11
end

local originalRaycast = phem7.Raycast
phem7.Raycast = function(self, phem19, phem20, phem21, phem22, phem23, phem24)
    if not silentAimActive then
        return originalRaycast(self, phem19, phem20, phem21, phem22, phem23, phem24)
    end
    if type(phem21) ~= "number" or phem21 < 100 then
        return originalRaycast(self, phem19, phem20, phem21, phem22, phem23, phem24)
    end
    local phem25 = phem9()
    if not phem25 then
        return originalRaycast(self, phem19, phem20, phem21, phem22, phem23, phem24)
    end
    local phem26 = phem25.Position
    local phem27 = (phem26 - phem19).Unit
    local phem28 = (phem26 - phem19).Magnitude
    if phem28 > phem21 then
        phem28 = phem21
        phem26 = phem19 + (phem27 * phem21)
    end
    return {
        Position = phem26,
        Distance = phem28,
        Instance = phem25,
        Material = phem25.Material,
        Normal = -phem27
    }
end

-- ============================================================
-- 5. WALLBANG SCRIPT (now desyncs on HEAD)
-- ============================================================
local wallbangActive = getgenv().Config.EnableWallbang
local wallbangInstance = nil

local function setupWallbang()
    if wallbangInstance then return end
    local __a1b2c3 = setmetatable({}, {
        __index = function(__d4e5f6, __g7h8i9)
            local __j0k1l2, __m3n4o5 = pcall(function()
                return game:GetService(__g7h8i9)
            end)
            if __m3n4o5 then
                return cloneref(__m3n4o5)
            end
            return nil
        end
    })

    local __p6q7r8 = getgenv()
    if __p6q7r8.__s9t0u1 then
        __p6q7r8.__s9t0u1:Shutdown()
    end

    local __v2w3x4 = __a1b2c3.Players
    local __y5z6a7 = __a1b2c3.RunService
    local __b8c9d0 = __a1b2c3.ReplicatedStorage
    local __e1f2g3 = __a1b2c3.Workspace
    local __k7l8m9 = __v2w3x4.LocalPlayer
    local __n0o1p2 = __e1f2g3.CurrentCamera
    local __q3r4s5 = __k7l8m9.PlayerScripts
    local __t6u7v8 = require(__q3r4s5.Modules.ItemTypes.Gun)
    local __w9x0y1 = require(__b8c9d0.Modules.Utility)

    local __z2a3b4 = setmetatable({}, {
        __index = function(_, __c5d6e7)
            local __f8g9h0 = __k7l8m9.Character
            if not __f8g9h0 then return nil end
            if __c5d6e7 == "__root" then
                return __f8g9h0:FindFirstChild("HumanoidRootPart")
            elseif __c5d6e7 == "__head" then
                return __f8g9h0:FindFirstChild("Head")
            end
            return nil
        end
    })

    __p6q7r8.__s9t0u1 = {}

    do
        local __i1j2k3 = __p6q7r8.__s9t0u1

        function __i1j2k3:__init()
            self.__active = true
            self.__target = nil
            self.__desync = false
            self.__conn1 = nil
            self.__conn2 = nil
            self.__task1 = nil
            self.__oldfunc = nil
            self:__setup()
        end

        function __i1j2k3:__setup()
            self.__conn1 = __y5z6a7.Heartbeat:Connect(function()
                if not self.__active or not wallbangActive then 
                    self.__target = nil
                    return 
                end
                self.__target = self:__find()
            end)

            local __l4m5n6 = __t6u7v8.StartShooting
            self.__oldfunc = __l4m5n6
            __t6u7v8.StartShooting = function(__o7p8q9, ...)
                if not wallbangActive then
                    return __l4m5n6(__o7p8q9, ...)
                end
                local __r0s1t2 = {__l4m5n6(__o7p8q9, ...)}
                if not __o7p8q9.ClientFighter or not __o7p8q9.ClientFighter.IsLocalPlayer then
                    return unpack(__r0s1t2)
                end

                local __u3v4w5 = __r0s1t2[3]
                if not __u3v4w5 or typeof(__u3v4w5) ~= "table" then
                    return unpack(__r0s1t2)
                end

                __r0s1t2[4] = true
                local __x6y7z8 = self.__target

                if not self.__active or not __x6y7z8 or not __x6y7z8.Character then
                    return unpack(__r0s1t2)
                end

                if not self.__desync or self.__curr ~= __x6y7z8 then
                    self:__desync_start(__x6y7z8)
                    task.wait(0.1)
                end

                if self.__task1 then
                    task.cancel(self.__task1)
                    self.__task1 = nil
                end

                -- ALWAYS HEAD
                local __a9b0c1 = __x6y7z8.Character:FindFirstChild("Head")
                if not __a9b0c1 then return unpack(__r0s1t2) end

                local __d2e3f4 = __a9b0c1.Position
                local __g5h6i7 = __a9b0c1.CFrame
                local __j8k9l0 = __d2e3f4 - Vector3.new(0, 5, 0)
                local __m1n2o3 = CFrame.lookAt(__j8k9l0, __d2e3f4)
                local __p4q5r6 = __g5h6i7:ToObjectSpace(CFrame.new(__d2e3f4 + Vector3.new(math.random(), math.random(), math.random())))

                __u3v4w5[utf8.char(0)] = __w9x0y1:EncodeCFrame(CFrame.new(__j8k9l0, __d2e3f4) * CFrame.Angles(__m1n2o3:ToOrientation()))
                __u3v4w5[utf8.char(1)] = __w9x0y1:EncodeCFrame(CFrame.new(__d2e3f4) * CFrame.Angles(__m1n2o3:ToOrientation()))
                __u3v4w5[utf8.char(2)] = __a9b0c1
                __u3v4w5[utf8.char(3)] = __w9x0y1:EncodeCFrame(__p4q5r6)

                self.__task1 = task.delay(0.15, function()
                    self:__desync_stop()
                end)

                return unpack(__r0s1t2)
            end
        end

        function __i1j2k3:__find()
            local myChar = __k7l8m9.Character
            if not myChar then return nil end
            local myRoot = myChar:FindFirstChild("HumanoidRootPart")
            if not myRoot then return nil end

            local closest = nil
            local closestDist = math.huge
            local MAX_DISTANCE = 400
            local fovRadius = getgenv().Config.FOVRadius

            local cam = __n0o1p2
            local viewport = cam.ViewportSize
            local center = Vector2.new(viewport.X / 2, viewport.Y / 2)

            for _, player in next, __v2w3x4:GetPlayers() do
                if player == __k7l8m9 then continue end
                if player:GetAttribute("TeamID") == __k7l8m9:GetAttribute("TeamID") then continue end

                local char = player.Character
                if not char then continue end

                local root = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                local hum = char:FindFirstChildWhichIsA("Humanoid")

                if not (root and head and hum and hum.Health > 0) then continue end

                local dist = (myRoot.Position - root.Position).Magnitude
                if dist > MAX_DISTANCE then continue end

                local headPos = head.Position
                local screenPos, onScreen = cam:WorldToViewportPoint(headPos)
                if not onScreen then continue end
                local screenVec = Vector2.new(screenPos.X, screenPos.Y)
                local fovDist = (center - screenVec).Magnitude
                if fovDist > fovRadius then continue end

                if dist < closestDist then
                    closestDist = dist
                    closest = player
                end
            end

            return closest
        end

        function __i1j2k3:__desync_start(__c3d4e5)
            if self.__conn2 then self.__conn2:Disconnect() end
            self.__desync = true
            self.__curr = __c3d4e5

            self.__conn2 = __y5z6a7.Heartbeat:Connect(function()
                if not self.__desync then return end
                local __f6g7h8 = __z2a3b4.__root
                if not __f6g7h8 then return end

                local __i9j0k1 = __c3d4e5.Character and __c3d4e5.Character:FindFirstChild("HumanoidRootPart")
                if not __i9j0k1 then
                    self:__desync_stop()
                    return
                end

                local __l2m3n4 = __f6g7h8.CFrame
                local __o5p6q7 = __f6g7h8.Velocity
                local __r8s9t0 = __f6g7h8.RotVelocity

                -- DESYNC ON HEAD (offset 2.5 studs above enemy root, roughly head height)
                __f6g7h8.CFrame = __i9j0k1.CFrame * CFrame.new(0, 7.5, 0)

                __y5z6a7:BindToRenderStep("__restore", 101, function()
                    __f6g7h8.CFrame = __l2m3n4
                    __f6g7h8.Velocity = __o5p6q7
                    __f6g7h8.RotVelocity = __r8s9t0
                    __y5z6a7:UnbindFromRenderStep("__restore")
                end)
            end)
        end

        function __i1j2k3:__desync_stop()
            self.__desync = false
            self.__curr = nil
            if self.__conn2 then
                self.__conn2:Disconnect()
                self.__conn2 = nil
            end
        end

        function __i1j2k3:Shutdown()
            self.__active = false
            if self.__conn1 then self.__conn1:Disconnect() end
            if self.__conn2 then self.__conn2:Disconnect() end
            if self.__task1 then task.cancel(self.__task1) end
            if self.__oldfunc then
                __t6u7v8.StartShooting = self.__oldfunc
            end
        end

        __i1j2k3:__init()
        wallbangInstance = __i1j2k3
    end
end

-- ============================================================
-- 6. BUILD LINORIA UI
-- ============================================================
local Window = Library:CreateWindow({
    Title = "Aim Assist",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local MainTab = Window:AddTab("Aim")
local MainGroup = MainTab:AddLeftGroupbox("Configuration")

-- Silent Aim Toggle
MainGroup:AddToggle("EnableSilentAim", {
    Text = "Enable Silent Aim",
    Description = "Uses raycast to aim at selected body part.",
    Default = getgenv().Config.EnableSilentAim,
    Callback = function(v)
        getgenv().Config.EnableSilentAim = v
        silentAimActive = v
    end
})

-- Wallbang Toggle
MainGroup:AddToggle("EnableWallbang", {
    Text = "Enable Wallbang (Desync on Head)",
    Description = "Uses desync to always hit head (max 400 studs, respects FOV).",
    Default = getgenv().Config.EnableWallbang,
    Callback = function(v)
        getgenv().Config.EnableWallbang = v
        wallbangActive = v
        if v then
            if not wallbangInstance then
                setupWallbang()
            end
        else
            if wallbangInstance then
                wallbangInstance:Shutdown()
                wallbangInstance = nil
            end
        end
    end
})

-- FOV Slider
MainGroup:AddSlider("FOVRadius", {
    Text = "FOV Radius",
    Description = "Max pixel distance from crosshair to target.",
    Default = getgenv().Config.FOVRadius,
    Min = 0,
    Max = 900,
    Rounding = 0,
    Compact = false,
    Callback = function(v)
        getgenv().Config.FOVRadius = v
    end
})

-- HitPart Dropdown
MainGroup:AddDropdown("HitPart", {
    Text = "Hit Part (Silent Aim only)",
    Description = "Which body part to aim for.",
    Values = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" },
    Default = getgenv().Config.HitPart,
    Callback = function(v)
        getgenv().Config.HitPart = v
    end
})

-- Show FOV Toggle
MainGroup:AddToggle("ShowFOV", {
    Text = "Show FOV Circle",
    Default = getgenv().Config.ShowFOV,
    Callback = function(v)
        getgenv().Config.ShowFOV = v
    end
})

-- --- Theme & Save Tab ---
local ThemeTab = Window:AddTab("UI Settings")

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("AimAssist")
ThemeManager:ApplyToTab(ThemeTab, "AimAssist")

SaveManager:SetLibrary(Library)
SaveManager:SetFolder("AimAssist/saves")
SaveManager:SetIgnoreIndexes({ "Theme", "ThemeFolder" })
SaveManager:BuildConfigSection(ThemeTab)

SaveManager:LoadAutoloadConfig()

-- Ensure wallbang is set up if it was enabled from saved config
if getgenv().Config.EnableWallbang and not wallbangInstance then
    setupWallbang()
end

-- ============================================================
-- 7. ADDED: RAPID FIRE (from message.txt)
-- ============================================================
task.spawn(function()
    pcall(function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local Gun = require(player.PlayerScripts.Modules.ItemTypes.Gun)
        if Gun and Gun.Update then
            local oldUpdate = Gun.Update
            Gun.Update = function(self, dt, ...)
                if self._shoot_cooldown then
                    self._shoot_cooldown = 0
                end
                return oldUpdate(self, dt, ...)
            end
        end
    end)
end)

-- ============================================================
-- 8. ADDED: UNLOCK ALL (from message.txt)
-- ============================================================
task.spawn(function()
    pcall(function()
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local HttpService = game:GetService("HttpService")
        local player = Players.LocalPlayer
        local playerScripts = player.PlayerScripts
        local controllers = playerScripts.Controllers
        local EnumLibrary = require(ReplicatedStorage.Modules:WaitForChild("EnumLibrary", 10))
        if EnumLibrary then EnumLibrary:WaitForEnumBuilder() end
        local CosmeticLibrary = require(ReplicatedStorage.Modules:WaitForChild("CosmeticLibrary", 10))
        local ItemLibrary = require(ReplicatedStorage.Modules:WaitForChild("ItemLibrary", 10))
        local DataController = require(controllers:WaitForChild("PlayerDataController", 10))
        local equipped, favorites = {}, {}
        local constructingWeapon, viewingProfile = nil, nil
        local lastUsedWeapon = nil
        local function cloneCosmetic(name, cosmeticType, options)
            local base = CosmeticLibrary.Cosmetics[name]
            if not base then return nil end
            local data = {}
            for key, value in pairs(base) do data[key] = value end
            data.Name = name
            data.Type = data.Type or cosmeticType
            data.Seed = data.Seed or math.random(1, 1000000)
            if EnumLibrary then
                local success, enumId = pcall(EnumLibrary.ToEnum, EnumLibrary, name)
                if success and enumId then data.Enum, data.ObjectID = enumId, data.ObjectID or enumId end
            end
            if options then
                if options.inverted ~= nil then data.Inverted = options.inverted end
                if options.favoritesOnly ~= nil then data.OnlyUseFavorites = options.favoritesOnly end
            end
            return data
        end
        local saveFile = "unlockall/config.json"
        local function saveConfig()
            if not writefile then return end
            pcall(function()
                local config = {equipped = {}, favorites = favorites}
                for weapon, cosmetics in pairs(equipped) do
                    config.equipped[weapon] = {}
                    for cosmeticType, cosmeticData in pairs(cosmetics) do
                        if cosmeticData and cosmeticData.Name then
                            config.equipped[weapon][cosmeticType] = {
                                name = cosmeticData.Name, seed = cosmeticData.Seed, inverted = cosmeticData.Inverted
                            }
                        end
                    end
                end
                makefolder("unlockall")
                writefile(saveFile, HttpService:JSONEncode(config))
            end)
        end
        local function loadConfig()
            if not readfile or not isfile or not isfile(saveFile) then return end
            pcall(function()
                local config = HttpService:JSONDecode(readfile(saveFile))
                if config.equipped then
                    for weapon, cosmetics in pairs(config.equipped) do
                        equipped[weapon] = {}
                        for cosmeticType, cosmeticData in pairs(cosmetics) do
                            local cloned = cloneCosmetic(cosmeticData.name, cosmeticType, {inverted = cosmeticData.inverted})
                            if cloned then cloned.Seed = cosmeticData.seed equipped[weapon][cosmeticType] = cloned end
                        end
                    end
                end
                favorites = config.favorites or {}
            end)
        end
        CosmeticLibrary.OwnsCosmeticNormally = function() return true end
        CosmeticLibrary.OwnsCosmeticUniversally = function() return true end
        CosmeticLibrary.OwnsCosmeticForWeapon = function() return true end
        local originalOwnsCosmetic = CosmeticLibrary.OwnsCosmetic
        CosmeticLibrary.OwnsCosmetic = function(self, inventory, name, weapon)
            if name:find("MISSING_") then return originalOwnsCosmetic(self, inventory, name, weapon) end
            return true
        end
        local originalGet = DataController.Get
        DataController.Get = function(self, key)
            local data = originalGet(self, key)
            if key == "CosmeticInventory" then
                local proxy = {}
                if data then for k, v in pairs(data) do proxy[k] = v end end
                return setmetatable(proxy, {__index = function() return true end})
            end
            if key == "FavoritedCosmetics" then
                local result = data and table.clone(data) or {}
                for weapon, favs in pairs(favorites) do
                    result[weapon] = result[weapon] or {}
                    for name, isFav in pairs(favs) do result[weapon][name] = isFav end
                end
                return result
            end
            return data
        end
        local originalGetWeaponData = DataController.GetWeaponData
        DataController.GetWeaponData = function(self, weaponName)
            local data = originalGetWeaponData(self, weaponName)
            if not data then return nil end
            
            local merged = {}
            for key, value in pairs(data) do merged[key] = value end
            merged.Name = weaponName
            if equipped[weaponName] then
                for cosmeticType, cosmeticData in pairs(equipped[weaponName]) do merged[cosmeticType] = cosmeticData end
            end
            return merged
        end
        local FighterController
        pcall(function() FighterController = require(controllers:WaitForChild("FighterController", 10)) end)
        if hookmetamethod then
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            local dataRemotes = remotes and remotes:FindFirstChild("Data")
            local equipRemote = dataRemotes and dataRemotes:FindFirstChild("EquipCosmetic")
            local favoriteRemote = dataRemotes and dataRemotes:FindFirstChild("FavoriteCosmetic")
            local replicationRemotes = remotes and remotes:FindFirstChild("Replication")
            local fighterRemotes = replicationRemotes and replicationRemotes:FindFirstChild("Fighter")
            local useItemRemote = fighterRemotes and fighterRemotes:FindFirstChild("UseItem")
            if equipRemote then
                local oldNamecall
                oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                    if getnamecallmethod() ~= "FireServer" then return oldNamecall(self, ...) end
                    local args = {...}
                    if useItemRemote and self == useItemRemote then
                        local objectID = args[1]
                        if FighterController then
                            pcall(function()
                                local fighter = FighterController:GetFighter(player)
                                if fighter and fighter.Items then
                                    for _, item in pairs(fighter.Items) do
                                        if item:Get("ObjectID") == objectID then
                                            lastUsedWeapon = item.Name
                                            break
                                        end
                                    end
                                end
                            end)
                        end
                    end            
                    if self == equipRemote then
                        local weaponName, cosmeticType, cosmeticName, options = args[1], args[2], args[3], args[4] or {}                
                        if cosmeticName and cosmeticName ~= "None" and cosmeticName ~= "" then
                            local inventory = DataController:Get("CosmeticInventory")
                            if inventory and rawget(inventory, cosmeticName) then return oldNamecall(self, ...) end
                        end                
                        equipped[weaponName] = equipped[weaponName] or {}                
                        if not cosmeticName or cosmeticName == "None" or cosmeticName == "" then
                            equipped[weaponName][cosmeticType] = nil
                            if not next(equipped[weaponName]) then equipped[weaponName] = nil end
                        else
                            local cloned = cloneCosmetic(cosmeticName, cosmeticType, {inverted = options.IsInverted, favoritesOnly = options.OnlyUseFavorites})
                            if cloned then equipped[weaponName][cosmeticType] = cloned end
                        end                
                        task.defer(function()
                            pcall(function() DataController.CurrentData:Replicate("WeaponInventory") end)
                            task.wait(0.2)
                            saveConfig()
                        end)
                        return
                    end            
                    if self == favoriteRemote then
                        favorites[args[1]] = favorites[args[1]] or {}
                        favorites[args[1]][args[2]] = args[3] or nil
                        saveConfig()
                        task.spawn(function() pcall(function() DataController.CurrentData:Replicate("FavoritedCosmetics") end) end)
                        return
                    end            
                    return oldNamecall(self, ...)
                end)
            end
        end
        local ClientItem
        pcall(function() ClientItem = require(player.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem) end)
        if ClientItem and ClientItem._CreateViewModel then
            local originalCreateViewModel = ClientItem._CreateViewModel
            ClientItem._CreateViewModel = function(self, viewmodelRef)
                local weaponName = self.Name
                local weaponPlayer = self.ClientFighter and self.ClientFighter.Player
                constructingWeapon = (weaponPlayer == player) and weaponName or nil    
                if weaponPlayer == player and equipped[weaponName] and equipped[weaponName].Skin and viewmodelRef then
                    local dataKey, skinKey, nameKey = self:ToEnum("Data"), self:ToEnum("Skin"), self:ToEnum("Name")
                    if viewmodelRef[dataKey] then
                        viewmodelRef[dataKey][skinKey] = equipped[weaponName].Skin
                        viewmodelRef[dataKey][nameKey] = equipped[weaponName].Skin.Name
                    elseif viewmodelRef.Data then
                        viewmodelRef.Data.Skin = equipped[weaponName].Skin
                        viewmodelRef.Data.Name = equipped[weaponName].Skin.Name
                    end
                end
                local result = originalCreateViewModel(self, viewmodelRef)
                constructingWeapon = nil
                return result
            end
        end
        local viewModelModule = player.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
        if viewModelModule then
            local ClientViewModel = require(viewModelModule)
            if ClientViewModel.GetWrap then
                local originalGetWrap = ClientViewModel.GetWrap
                ClientViewModel.GetWrap = function(self)
                    local weaponName = self.ClientItem and self.ClientItem.Name
                    local weaponPlayer = self.ClientItem and self.ClientItem.ClientFighter and self.ClientItem.ClientFighter.Player
                    if weaponName and weaponPlayer == player and equipped[weaponName] and equipped[weaponName].Wrap then
                        return equipped[weaponName].Wrap
                    end
                    return originalGetWrap(self)
                end
            end
            local originalNew = ClientViewModel.new
            ClientViewModel.new = function(replicatedData, clientItem)
                local weaponPlayer = clientItem.ClientFighter and clientItem.ClientFighter.Player
                local weaponName = constructingWeapon or clientItem.Name
                if weaponPlayer == player and equipped[weaponName] then
                    local ReplicatedClass = require(ReplicatedStorage.Modules.ReplicatedClass)
                    local dataKey = ReplicatedClass:ToEnum("Data")
                    replicatedData[dataKey] = replicatedData[dataKey] or {}
                    local cosmetics = equipped[weaponName]
                    if cosmetics.Skin then replicatedData[dataKey][ReplicatedClass:ToEnum("Skin")] = cosmetics.Skin end
                    if cosmetics.Wrap then replicatedData[dataKey][ReplicatedClass:ToEnum("Wrap")] = cosmetics.Wrap end
                    if cosmetics.Charm then replicatedData[dataKey][ReplicatedClass:ToEnum("Charm")] = cosmetics.Charm end
                end
                local result = originalNew(replicatedData, clientItem)
                if weaponPlayer == player and equipped[weaponName] and equipped[weaponName].Wrap and result._UpdateWrap then
                    result:_UpdateWrap()
                    task.delay(0.1, function() if not result._destroyed then result:_UpdateWrap() end end)
                end
                return result
            end
        end
        local originalGetViewModelImage = ItemLibrary.GetViewModelImageFromWeaponData
        ItemLibrary.GetViewModelImageFromWeaponData = function(self, weaponData, highRes)
            if not weaponData then return originalGetViewModelImage(self, weaponData, highRes) end
            local weaponName = weaponData.Name
            local shouldShowSkin = (weaponData.Skin and equipped[weaponName] and weaponData.Skin == equipped[weaponName].Skin) or (viewingProfile == player and equipped[weaponName] and equipped[weaponName].Skin)
            if shouldShowSkin and equipped[weaponName] and equipped[weaponName].Skin then
                local skinInfo = self.ViewModels[equipped[weaponName].Skin.Name]
                if skinInfo then return skinInfo[highRes and "ImageHighResolution" or "Image"] or skinInfo.Image end
            end
            return originalGetViewModelImage(self, weaponData, highRes)
        end
        pcall(function()
            local ViewProfile = require(player.PlayerScripts.Modules.Pages.ViewProfile)
            if ViewProfile and ViewProfile.Fetch then
                local originalFetch = ViewProfile.Fetch
                ViewProfile.Fetch = function(self, targetPlayer)
                    viewingProfile = targetPlayer
                    return originalFetch(self, targetPlayer)
                end
            end
        end)
        local ClientEntity
        pcall(function() ClientEntity = require(player.PlayerScripts.Modules.ClientReplicatedClasses.ClientEntity) end)
        if ClientEntity and ClientEntity.ReplicateFromServer then
            local originalReplicateFromServer = ClientEntity.ReplicateFromServer
            ClientEntity.ReplicateFromServer = function(self, action, ...)
                if action == "FinisherEffect" then
                    local args = {...}
                    local killerName = args[3]            
                    local decodedKiller = killerName
                    if type(killerName) == "userdata" and EnumLibrary and EnumLibrary.FromEnum then
                        local ok, decoded = pcall(EnumLibrary.FromEnum, EnumLibrary, killerName)
                        if ok and decoded then decodedKiller = decoded end
                    end            
                    local isOurKill = tostring(decodedKiller) == player.Name or tostring(decodedKiller):lower() == player.Name:lower()            
                    if isOurKill and lastUsedWeapon and equipped[lastUsedWeapon] and equipped[lastUsedWeapon].Finisher then
                        local finisherData = equipped[lastUsedWeapon].Finisher
                        local finisherEnum = finisherData.Enum                
                        if not finisherEnum and EnumLibrary then
                            local ok, result = pcall(EnumLibrary.ToEnum, EnumLibrary, finisherData.Name)
                            if ok and result then finisherEnum = result end
                        end                
                        if finisherEnum then
                            args[1] = finisherEnum
                            return originalReplicateFromServer(self, action, unpack(args))
                        end
                    end
                end        
                return originalReplicateFromServer(self, action, ...)
            end
        end
        loadConfig()
    end)
end)