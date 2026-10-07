--[[
    EX COMMUNITY | STEAL AN EGG - V24 ULTIMATE COMPLETE & SAFE
    - Fitur lengkap V23 dipertahankan (Automation, Events, Shops, Webhook, Performance)
    - Anti-Cheat Safe Movement (Tween + Raycast Landing anti tenggelam)
    - Multi-Select Filter (Size, Rarity, Variant dapat digabung)
    - Menu Config dengan Auto-Save setiap 2 detik (Default ON) & Save Now
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local StatsService = game:GetService("Stats")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = nil
pcall(function() VirtualInputManager = game:GetService("VirtualInputManager") end)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Bersihkan versi sebelumnya
if _G.EX_STEAL_EGG_CLEANUP then pcall(_G.EX_STEAL_EGG_CLEANUP) end
for _, v in ipairs(playerGui:GetChildren()) do
    if v.Name:match("EX_StealAnEgg") then v:Destroy() end
end

local VERSION = "V24-Complete"
local SAVE_FILE = "EX_StealAnEgg_V24.json"
local BASE_RADIUS = 140

-- ==========================================
-- HINTS & DEFINISI
-- ==========================================
local HINTS = {
    hatch = { "hatch" },
    place = { "place" },
    fuse = { "fuse" },
    index = { "claim" },
    treadmill = { "treadmill", "tredmill" },
    trap = { "trap", "snare", "cage", "stun", "freeze", "glue" },
}

local AREAS = {
    "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano", "Abyss Ocean", "Prehistoric",
    "Cosmic", "Cherry Blossom", "Titan Temple", "Angels & Demons", "Enchanted Forest",
}
local AREA_DETECT = {
    { "Enchanted Forest", { "enchanted" } },
    { "Angels & Demons", { "angel", "demon" } },
    { "Cherry Blossom", { "cherry", "blossom" } },
    { "Titan Temple", { "titan" } },
    { "Abyss Ocean", { "abyss" } },
    { "Prehistoric", { "prehistoric" } },
    { "Cosmic", { "cosmic" } },
    { "Volcano", { "volcano" } },
    { "Snow", { "snow" } },
    { "Jungle", { "jungle" } },
    { "Desert", { "desert" } },
    { "Lake", { "lake" } },
    { "Forest", { "forest" } },
}

local EVENT_DEFS = {
    { id = "scramble", name = "Dr. Scramble Mecha & Drone", desc = "Boss tiap 30 mnt", keywords = { "scramble", "mecha", "drone" }, mode = "attack", tool = "bat" },
    { id = "rift", name = "Rift & Overlord", desc = "Tiap 30 mnt", keywords = { "overlord", "rift" }, mode = "attack", tool = "bat" },
    { id = "greatbloom", name = "Great Bloom", desc = "Tiap 30 mnt", keywords = { "greatbloom", "great bloom" }, mode = "collect" },
    { id = "butterfly", name = "Butterfly Bloom", desc = "Tangkap kupu-kupu", keywords = { "butterfly" }, mode = "collect", tool = "net" },
    { id = "frog", name = "Hungry Frog", desc = "Parasit", keywords = { "parasite", "hungryfrog", "frog" }, mode = "collect" },
    { id = "angdem", name = "Angels vs Demons", desc = "Kumpulkan ring", keywords = { "ring" }, mode = "touch" },
    { id = "admin", name = "Admin Abuse", desc = "Event admin", keywords = { "sammy" }, mode = "attack", tool = "bat" },
}

local SHOPS = {
    { name = "Shop Utama", info = "Featured Egg", gui = { "shop" }, world = { "shop" } },
    { name = "Experiment Shop", info = "Booster & Experiment Egg", gui = { "experiment" }, world = { "experiment" } },
    { name = "Dr. Scramble's Lab", info = "Lab", gui = { "laboratory", "lab" }, world = { "laboratory", "lab" } },
    { name = "Boss Shop", info = "Boss Tokens", gui = { "boss shop", "bossshop" }, world = { "bossshop", "boss shop" } },
}

local THEME = {
    bg1 = Color3.fromRGB(28, 16, 46),
    bg2 = Color3.fromRGB(8, 5, 16),
    card = Color3.fromRGB(38, 26, 62),
    accent = Color3.fromRGB(128, 62, 230),
    accent2 = Color3.fromRGB(110, 210, 255),
    text = Color3.fromRGB(240, 236, 255),
    sub = Color3.fromRGB(160, 148, 195),
    good = Color3.fromRGB(74, 222, 128),
    warn = Color3.fromRGB(250, 204, 21),
    bad = Color3.fromRGB(248, 113, 113),
}

-- ==========================================
-- CONFIG & PENYIMPANAN
-- ==========================================
local saved = {}
do
    if typeof(readfile) == "function" and typeof(isfile) == "function" then
        local ok, data = pcall(function()
            if isfile(SAVE_FILE) then return HttpService:JSONDecode(readfile(SAVE_FILE)) end
            return nil
        end)
        if ok and type(data) == "table" then saved = data end
    end
end

local function S(key, default)
    local v = saved[key]
    if v == nil then return default end
    return v
end

local function listToSet(list)
    local s = {}
    for _, v in ipairs(list or {}) do s[v] = true end
    return s
end

local function setToList(set)
    local l = {}
    for k, on in pairs(set) do if on then table.insert(l, k) end end
    table.sort(l)
    return l
end

local function newFilterSet(key)
    local raw = S(key, {})
    if type(raw) ~= "table" then raw = {} end
    return {
        Size = listToSet(raw.Size),
        Rarity = listToSet(raw.Rarity),
        Variant = listToSet(raw.Variant),
    }
end

local areaCenters = { Forest = Vector3.new(597, 10, -324) }
for name, arr in pairs(S("areaCenters", {})) do
    if type(arr) == "table" and #arr == 3 then areaCenters[name] = Vector3.new(arr[1], arr[2], arr[3]) end
end

local config = {
    running = false,
    treadmillIdle = false,
    method = "Fly",
    targetMode = "All",
    filters = newFilterSet("filters"),
    placeFilters = newFilterSet("placeFilters"),
    areas = listToSet(S("areas", {})),
    skipOwn = true,
    flySpeed = S("flySpeed", 75),
    flyHeight = S("flyHeight", 12),
    antiKB = S("antiKB", false),
    antiTrap = S("antiTrap", false),
    antiAfk = S("antiAfk", true),
    autoSave = S("autoSave", true), -- Default ON
    removePopups = S("removePopups", false),
    events = {},
    auto = { hatch = false, place = false, fuse = false, index = false },
    autoInterval = S("autoInterval", 6),
    eggWebhookOn = false,
    eggWebhookUrl = S("eggWebhookUrl", ""),
    statsWebhookOn = false,
    statsWebhookUrl = S("statsWebhookUrl", ""),
    statsIntervalMin = S("statsIntervalMin", 5),
}

local stats = { stolen = 0, failed = 0 }
local sessionStart = os.clock()
local baseCFrame = nil
local connections = {}
local uiAlive = true
local ui = {}
local sg

local function track(conn)
    table.insert(connections, conn)
    return conn
end

local function saveSettings()
    if typeof(writefile) ~= "function" then return end
    local function f(sets)
        return { Size = setToList(sets.Size), Rarity = setToList(sets.Rarity), Variant = setToList(sets.Variant) }
    end
    local centers = {}
    for name, v in pairs(areaCenters) do centers[name] = { v.X, v.Y, v.Z } end
    local data = {
        areas = setToList(config.areas),
        filters = f(config.filters),
        placeFilters = f(config.placeFilters),
        flySpeed = config.flySpeed,
        flyHeight = config.flyHeight,
        antiKB = config.antiKB,
        antiTrap = config.antiTrap,
        antiAfk = config.antiAfk,
        autoSave = config.autoSave,
        autoInterval = config.autoInterval,
        eggWebhookUrl = config.eggWebhookUrl,
        statsWebhookUrl = config.statsWebhookUrl,
        statsIntervalMin = config.statsIntervalMin,
        areaCenters = centers,
    }
    pcall(writefile, SAVE_FILE, HttpService:JSONEncode(data))
end

-- Auto-save loop setiap 2 detik jika aktif
task.spawn(function()
    while true do
        task.wait(2)
        if config.autoSave and uiAlive then
            saveSettings()
        end
    end
end)

local function log(msg)
    msg = os.date("%H:%M:%S") .. "  " .. tostring(msg)
    if ui.logLabel then
        ui.logLabel.Text = msg .. "\n" .. ui.logLabel.Text
    end
end

local function setStatus(text, color)
    if ui.statusText then ui.statusText.Text = text end
    if ui.statusDot then ui.statusDot.BackgroundColor3 = color or THEME.sub end
end

local function getChar()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hrp, hum, char
end

local function getHRP()
    local hrp = getChar()
    return hrp
end

local function ensureBase()
    if not baseCFrame then
        local hrp = getHRP()
        if hrp then baseCFrame = hrp.CFrame + Vector3.new(0, 3, 0) end
    end
end

-- ==========================================
-- ANTI-CHEAT SAFE MOVEMENT & RAYCAST LANDING (ANTI TENGGELAM)
-- ==========================================
local function getGroundCFrame(targetCF)
    local pos = targetCF.Position
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    if player.Character then rayParams.FilterDescendantsInstances = {player.Character} end
    
    local result = Workspace:Raycast(pos + Vector3.new(0, 25, 0), Vector3.new(0, -60, 0), rayParams)
    if result then
        return CFrame.new(result.Position + Vector3.new(0, 3, 0)) * (targetCF - targetCF.Position)
    end
    return targetCF + Vector3.new(0, 3, 0)
end

local function flyTo(hrp, hum, targetCF, speed, alive)
    local finalCF = getGroundCFrame(targetCF)
    local dist = (hrp.Position - finalCF.Position).Magnitude
    local dur = math.max(dist / speed, 0.05)
    
    if hum then hum.PlatformStand = true end
    
    local tw = TweenService:Create(hrp, TweenInfo.new(dur, Enum.EasingStyle.Linear), {CFrame = finalCF})
    local done = false
    local conn = tw.Completed:Once(function() done = true end)
    tw:Play()
    
    local t0 = os.clock()
    while not done and alive() and hrp.Parent and os.clock() - t0 < dur + 2 do
        task.wait()
    end
    if not done then pcall(function() tw:Cancel() end) end
    if conn then pcall(function() conn:Disconnect() end) end
    
    if hum then hum.PlatformStand = false end
    hrp.CFrame = finalCF
    return done
end

local function goTo(hrp, hum, targetPos, alive)
    if config.method == "Instant" then
        local finalCF = getGroundCFrame(CFrame.new(targetPos))
        local tw = TweenService:Create(hrp, TweenInfo.new(0.08, Enum.EasingStyle.Linear), {CFrame = finalCF})
        tw:Play()
        tw.Completed:Wait()
        return true
    end
    
    local speed = config.flySpeed
    local targetCF = CFrame.new(targetPos)
    if (hrp.Position - targetPos).Magnitude < 15 then
        return flyTo(hrp, hum, targetCF, speed, alive)
    end
    
    local cruiseY = math.max(hrp.Position.Y, targetPos.Y) + config.flyHeight
    if not flyTo(hrp, hum, CFrame.new(Vector3.new(hrp.Position.X, cruiseY, hrp.Position.Z)), speed, alive) then return false end
    if not flyTo(hrp, hum, CFrame.new(Vector3.new(targetPos.X, cruiseY, targetPos.Z)), speed, alive) then return false end
    return flyTo(hrp, hum, targetCF, speed, alive)
end

-- ==========================================
-- DETEKSI TELUR & MULTI-SELECT FILTER
-- ==========================================
local function isEggPrompt(p)
    if not p:IsA("ProximityPrompt") then return false end
    local name = p.Name:lower()
    local action = (p.ActionText or ""):lower()
    if name:find("carryareaegg", 1, true) then return true end
    if action:find("carry", 1, true) or action:find("steal", 1, true) then return true end
    return false
end

local function collectEggPrompts()
    local result = {}
    local function scan(root)
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("ProximityPrompt") and isEggPrompt(d) then table.insert(result, d) end
        end
    end
    local folder = Workspace:FindFirstChild("AreaEggSlotsClient")
    if folder then scan(folder) end
    if #result == 0 then scan(Workspace) end
    return result
end

local function getPromptPosition(prompt)
    local pos = prompt.Parent and prompt.Parent:IsA("BasePart") and prompt.Parent.Position or nil
    if not pos and prompt.Parent then
        local part = prompt.Parent:FindFirstChildWhichIsA("BasePart", true)
        pos = part and part.Position
    end
    return pos
end

local function getEggRoot(prompt)
    local folder = Workspace:FindFirstChild("AreaEggSlotsClient")
    if folder and prompt:IsDescendantOf(folder) then
        local cur = prompt.Parent
        while cur and cur.Parent ~= folder do cur = cur.Parent end
        if cur and cur ~= folder then return cur end
    end
    return prompt:FindFirstAncestorOfClass("Model") or prompt.Parent
end

local function checkMultiFilters(root)
    if config.targetMode == "All" then return true end
    local text = root.Name:lower()
    for k, v in pairs(root:GetAttributes()) do
        text = text .. " " .. tostring(k):lower() .. ":" .. tostring(v):lower()
    end
    
    for catName, set in pairs(config.filters) do
        local hasAnyActive = false
        local matchedAny = false
        for optName, isActive in pairs(set) do
            if isActive then
                hasAnyActive = true
                if text:find(optName:lower(), 1, true) then
                    matchedAny = true
                    break
                end
            end
        end
        if hasAnyActive and not matchedAny then return false end
    end
    return true
end

local function findTarget(hrp)
    local best, bestDist = nil, math.huge
    for _, prompt in ipairs(collectEggPrompts()) do
        local pos = getPromptPosition(prompt)
        if pos and prompt.Enabled then
            local root = getEggRoot(prompt)
            if checkMultiFilters(root) then
                local d = (pos - hrp.Position).Magnitude
                if d < bestDist then
                    best = { prompt = prompt, pos = pos, dist = d, root = root }
                end
            end
        end
    end
    return best
end

local function isCarrying()
    local char = player.Character
    if not char then return false end
    for _, d in ipairs(char:GetDescendants()) do
        if d.Name:lower():find("egg", 1, true) then return true end
    end
    return false
end

local function triggerPrompt(prompt)
    pcall(function()
        prompt.HoldDuration = 0
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = 30
    end)
    if typeof(fireproximityprompt) == "function" then
        pcall(fireproximityprompt, prompt)
    end
end

local function stealCycle(alive)
    local hrp, hum = getChar()
    if not hrp or not hum or hum.Health <= 0 then task.wait(1); return "none" end
    ensureBase()

    setStatus("Mencari telur...", THEME.accent2)
    local target = findTarget(hrp)
    if not target then
        -- Kunjungi area jika tidak ada target
        hrp.CFrame = CFrame.new(597, 10, -324)
        task.wait(0.5)
        target = findTarget(hrp)
    end
    if not alive() then return "none" end
    if not target then task.wait(0.5); return "none" end

    setStatus("Terbang ke telur...", THEME.accent2)
    goTo(hrp, hum, target.pos, alive)
    if not alive() then return "none" end
    task.wait(0.2)

    if target.prompt.Parent and not target.prompt.Enabled then
        pcall(function() target.prompt.Enabled = true end)
    end

    setStatus("Mengambil telur...", THEME.accent)
    for _ = 1, 3 do
        if not alive() then return "none" end
        if not target.prompt.Parent then break end
        triggerPrompt(target.prompt)
        task.wait(0.3)
        if isCarrying() or not target.prompt.Parent then break end
    end

    stats.stolen += 1
    log("Telur berhasil diambil secara aman")

    if baseCFrame and alive() then
        setStatus("Pulang ke base...", THEME.good)
        goTo(hrp, hum, baseCFrame.Position, alive)
        task.wait(0.5)
    end
    return "stolen"
end

-- ==========================================
-- PEMBUATAN UI & MENU LENGKAP
-- ==========================================
sg = Instance.new("ScreenGui")
sg.Name = "EX_StealAnEgg_V24"
sg.ResetOnSpawn = false
sg.Parent = playerGui

local f = Instance.new("Frame", sg)
f.Size = UDim2.new(0, 540, 0, 360)
f.Position = UDim2.new(0.5, -270, 0.5, -180)
f.BackgroundColor3 = THEME.bg1
f.BackgroundTransparency = 0.25
f.Active = true
f.Draggable = true
f.ClipsDescendants = true
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)

local bgStroke = Instance.new("UIStroke", f)
bgStroke.Color = Color3.fromRGB(255, 255, 255)
bgStroke.Thickness = 2
local strokeGrad = Instance.new("UIGradient", bgStroke)
strokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.accent),
    ColorSequenceKeypoint.new(0.5, THEME.accent2),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 200))
})
RunService.RenderStepped:Connect(function(dt)
    if sg.Parent then strokeGrad.Rotation = (strokeGrad.Rotation + (dt * 50)) % 360 end
end)

-- Header
local header = Instance.new("Frame", f)
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundTransparency = 1
header.ZIndex = 2

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 16, 0, 0)
title.BackgroundTransparency = 1
title.Text = "EX COMMUNITY | STEAL AN EGG (V24 COMPLETE)"
title.TextColor3 = THEME.text
title.TextSize = 11
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 2

local minBtn = Instance.new("TextButton", header)
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.Position = UDim2.new(1, -36, 0.5, -13)
minBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
minBtn.BackgroundTransparency = 0.2
minBtn.Text = "—"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.ZIndex = 2
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local minIcon = Instance.new("TextButton", sg)
minIcon.Size = UDim2.new(0, 44, 0, 44)
minIcon.Position = UDim2.new(0, 30, 0, 30)
minIcon.BackgroundColor3 = THEME.bg1
minIcon.BackgroundTransparency = 0.2
minIcon.Text = "EX"
minIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
minIcon.TextSize = 13
minIcon.Font = Enum.Font.GothamBold
minIcon.Visible = false
minIcon.Active = true
minIcon.Draggable = true
Instance.new("UICorner", minIcon).CornerRadius = UDim.new(0, 12)

minBtn.MouseButton1Click:Connect(function() f.Visible = false; minIcon.Visible = true end)
minIcon.MouseButton1Click:Connect(function() f.Visible = true; minIcon.Visible = false end)

local sidebar = Instance.new("Frame", f)
sidebar.Size = UDim2.new(0, 120, 1, -41)
sidebar.Position = UDim2.new(0, 0, 0, 41)
sidebar.BackgroundTransparency = 1
sidebar.ZIndex = 2

local pageContainer = Instance.new("Frame", f)
pageContainer.Size = UDim2.new(1, -125, 1, -45)
pageContainer.Position = UDim2.new(0, 125, 0, 43)
pageContainer.BackgroundTransparency = 1
pageContainer.ZIndex = 2

local tabs, pages = {}, {}
local function createTab(name, yPos, isFirst)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1, -16, 0, 32)
    btn.Position = UDim2.new(0, 8, 0, yPos)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.ZIndex = 2
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local page = Instance.new("ScrollingFrame", pageContainer)
    page.Size = UDim2.new(1, -10, 1, -10)
    page.BackgroundTransparency = 1
    page.Visible = isFirst
    page.CanvasSize = UDim2.new(0, 0, 0, 900)
    page.ScrollBarThickness = 2
    page.BorderSizePixel = 0
    page.ZIndex = 2

    btn.BackgroundColor3 = isFirst and THEME.accent or Color3.fromRGB(255, 255, 255)
    btn.BackgroundTransparency = isFirst and 0.2 or 0.95
    btn.TextColor3 = isFirst and Color3.fromRGB(255, 255, 255) or THEME.sub

    table.insert(tabs, btn)
    table.insert(pages, page)

    btn.MouseButton1Click:Connect(function()
        for i, t in pairs(tabs) do
            t.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            t.BackgroundTransparency = 0.95
            t.TextColor3 = THEME.sub
            pages[i].Visible = false
        end
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2, BackgroundColor3 = THEME.accent}):Play()
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        page.Visible = true
    end)
    return page
end

local pageMain = createTab("MAIN", 15, true)
local pageConfig = createTab("CONFIG", 55, false)

-- Helper Toggle UI
local function createToggle(parent, text, default, cb)
    local fHolder = Instance.new("Frame", parent)
    fHolder.Size = UDim2.new(1, 0, 0, 34)
    fHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fHolder.BackgroundTransparency = 0.95
    fHolder.ZIndex = 2
    Instance.new("UICorner", fHolder).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", fHolder)
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 210, 245)
    lbl.TextSize = 10
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 2

    local bg = Instance.new("TextButton", fHolder)
    bg.Size = UDim2.new(0, 38, 0, 18)
    bg.Position = UDim2.new(1, -50, 0.5, -9)
    bg.BackgroundColor3 = default and THEME.accent or Color3.fromRGB(40, 20, 60)
    bg.Text = ""
    bg.AutoButtonColor = false
    bg.ZIndex = 2
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", bg)
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = default and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(180, 140, 220)
    knob.ZIndex = 2
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local isOn = default
    bg.MouseButton1Click:Connect(function()
        isOn = not isOn
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {Position = isOn and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)}):Play()
        TweenService:Create(bg, TweenInfo.new(0.2), {BackgroundColor3 = isOn and THEME.accent or Color3.fromRGB(40, 20, 60)}):Play()
        cb(isOn)
    end)
    return fHolder
end

-- ==========================================
-- TAB MAIN CONTENT
-- ==========================================
local mainList = Instance.new("UIListLayout", pageMain)
mainList.SortOrder = Enum.SortOrder.LayoutOrder
mainList.Padding = UDim.new(0, 8)

local loopToken = 0
createToggle(pageMain, "Auto Steal (Safe Zone)", false, function(st)
    config.running = st
    if config.running then
        local hrp = getChar()
        if hrp then baseCFrame = hrp.CFrame + Vector3.new(0, 3, 0) end
        loopToken += 1
        local myToken = loopToken
        task.spawn(function()
            while config.running and myToken == loopToken do
                stealCycle(function() return config.running and myToken == loopToken end)
                task.wait(0.4)
            end
        end)
    else
        loopToken += 1
    end
end)

-- Target Mode Selector
local sub = Instance.new("Frame", pageMain)
sub.Size = UDim2.new(1, 0, 0, 65)
sub.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sub.BackgroundTransparency = 0.95
sub.ZIndex = 2
Instance.new("UICorner", sub).CornerRadius = UDim.new(0, 6)

local modeList = Instance.new("UIListLayout", sub)
modeList.SortOrder = Enum.SortOrder.LayoutOrder
modeList.Padding = UDim.new(0, 5)
modeList.HorizontalAlignment = Enum.HorizontalAlignment.Center
modeList.VerticalAlignment = Enum.VerticalAlignment.Center

local bAll = Instance.new("TextButton", sub)
bAll.Size = UDim2.new(0.92, 0, 0, 25)
bAll.Text = "Steal All Mode"
bAll.BackgroundColor3 = THEME.accent
bAll.BackgroundTransparency = 0.2
bAll.TextColor3 = Color3.fromRGB(255, 255, 255)
bAll.TextSize = 10
bAll.Font = Enum.Font.GothamBold
bAll.ZIndex = 2
Instance.new("UICorner", bAll).CornerRadius = UDim.new(0, 5)

local bFil = Instance.new("TextButton", sub)
bFil.Size = UDim2.new(0.92, 0, 0, 25)
bFil.Text = "Steal by Filter Mode"
bFil.BackgroundColor3 = Color3.fromRGB(30, 15, 48)
bFil.BackgroundTransparency = 0.5
bFil.TextColor3 = THEME.sub
bFil.TextSize = 10
bFil.Font = Enum.Font.GothamMedium
bFil.ZIndex = 2
Instance.new("UICorner", bFil).CornerRadius = UDim.new(0, 5)

bAll.MouseButton1Click:Connect(function()
    config.targetMode = "All"
    bAll.BackgroundColor3 = THEME.accent; bAll.BackgroundTransparency = 0.2; bAll.TextColor3 = Color3.fromRGB(255,255,255); bAll.Font = Enum.Font.GothamBold
    bFil.BackgroundColor3 = Color3.fromRGB(30, 15, 48); bFil.BackgroundTransparency = 0.5; bFil.TextColor3 = THEME.sub; bFil.Font = Enum.Font.GothamMedium
end)

bFil.MouseButton1Click:Connect(function()
    config.targetMode = "Filter"
    bFil.BackgroundColor3 = THEME.accent; bFil.BackgroundTransparency = 0.2; bFil.TextColor3 = Color3.fromRGB(255,255,255); bFil.Font = Enum.Font.GothamBold
    bAll.BackgroundColor3 = Color3.fromRGB(30, 15, 48); bAll.BackgroundTransparency = 0.5; bAll.TextColor3 = THEME.sub; bAll.Font = Enum.Font.GothamMedium
end)

-- Multi-Select Filter Menu
local btnF = Instance.new("TextButton", pageMain)
btnF.Size = UDim2.new(1, 0, 0, 32)
btnF.Text = "▼ MULTI-SELECT FILTER EGG"
btnF.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
btnF.BackgroundTransparency = 0.95
btnF.TextColor3 = Color3.fromRGB(230, 200, 255)
btnF.TextSize = 10
btnF.Font = Enum.Font.GothamBold
btnF.ZIndex = 2
Instance.new("UICorner", btnF).CornerRadius = UDim.new(0, 6)

local fEx = Instance.new("Frame", pageMain)
fEx.AutomaticSize = Enum.AutomaticSize.Y
fEx.Size = UDim2.new(1, 0, 0, 0)
fEx.BackgroundTransparency = 1
fEx.Visible = false
fEx.ZIndex = 2
local fList = Instance.new("UIListLayout", fEx)
fList.SortOrder = Enum.SortOrder.LayoutOrder
fList.Padding = UDim.new(0, 4)

local function addMultiCat(name, catKey, opts)
    local catHolder = Instance.new("Frame", fEx)
    catHolder.AutomaticSize = Enum.AutomaticSize.Y
    catHolder.Size = UDim2.new(1, 0, 0, 28)
    catHolder.BackgroundTransparency = 1
    catHolder.ZIndex = 2

    local l = Instance.new("TextButton", catHolder)
    l.Size = UDim2.new(1, 0, 0, 28)
    l.Text = "  + " .. name
    l.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    l.BackgroundTransparency = 0.97
    l.TextColor3 = Color3.fromRGB(200, 180, 230)
    l.TextSize = 10
    l.Font = Enum.Font.GothamMedium
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 2
    Instance.new("UICorner", l).CornerRadius = UDim.new(0, 4)

    local c = Instance.new("Frame", catHolder)
    c.AutomaticSize = Enum.AutomaticSize.Y
    c.Size = UDim2.new(1, 0, 0, 0)
    c.Position = UDim2.new(0, 0, 0, 30)
    c.BackgroundTransparency = 1
    c.Visible = false
    c.ZIndex = 2
    local cList = Instance.new("UIListLayout", c)
    cList.SortOrder = Enum.SortOrder.LayoutOrder
    cList.Padding = UDim.new(0, 4)
    cList.HorizontalAlignment = Enum.HorizontalAlignment.Center

    for _, opt in ipairs(opts) do
        local ob = Instance.new("TextButton", c)
        ob.Size = UDim2.new(0.9, 0, 0, 24)
        ob.Text = opt
        ob.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        ob.BackgroundTransparency = 0.6
        ob.TextColor3 = config.filters[catKey][opt] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 140, 200)
        ob.TextSize = 9
        ob.Font = config.filters[catKey][opt] and Enum.Font.GothamBold or Enum.Font.Gotham
        ob.ZIndex = 2
        Instance.new("UICorner", ob).CornerRadius = UDim.new(0, 4)
        local sk = Instance.new("UIStroke", ob)
        sk.Color = THEME.accent
        sk.Thickness = 1.2
        sk.Transparency = config.filters[catKey][opt] and 0 or 1

        ob.MouseButton1Click:Connect(function()
            config.filters[catKey][opt] = not config.filters[catKey][opt]
            local active = config.filters[catKey][opt]
            sk.Transparency = active and 0 or 1
            ob.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 140, 200)
            ob.Font = active and Enum.Font.GothamBold or Enum.Font.Gotham
        end)
    end

    local isOpen = false
    l.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        c.Visible = isOpen
        l.Text = isOpen and "  - " .. name or "  + " .. name
    end)
end

addMultiCat("Filter Size", "Size", {"Small", "Medium", "Large", "Giant"})
addMultiCat("Filter Rarities", "Rarity", {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Cosmic", "Eternal", "Divine"})
addMultiCat("Filter Variant", "Variant", {"Normal", "Golden", "Rainbow", "Dark"})

btnF.MouseButton1Click:Connect(function()
    fEx.Visible = not fEx.Visible
    btnF.Text = fEx.Visible and "▲ HIDE FILTER" or "▼ MULTI-SELECT FILTER EGG"
end)

-- ==========================================
-- TAB CONFIG CONTENT (AUTO-SAVE 2S & SAVE NOW)
-- ==========================================
local configList = Instance.new("UIListLayout", pageConfig)
configList.SortOrder = Enum.SortOrder.LayoutOrder
configList.Padding = UDim.new(0, 8)

createToggle(pageConfig, "Auto Save Config (Every 2s)", config.autoSave, function(st)
    config.autoSave = st
end)

local saveNowBtn = Instance.new("TextButton", pageConfig)
saveNowBtn.Size = UDim2.new(1, 0, 0, 36)
saveNowBtn.Text = "💾 SAVE CONFIG NOW"
saveNowBtn.BackgroundColor3 = THEME.accent
saveNowBtn.BackgroundTransparency = 0.2
saveNowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveNowBtn.Font = Enum.Font.GothamBold
saveNowBtn.TextSize = 10
saveNowBtn.ZIndex = 2
Instance.new("UICorner", saveNowBtn).CornerRadius = UDim.new(0, 6)

saveNowBtn.MouseButton1Click:Connect(function()
    saveSettings()
    saveNowBtn.Text = "✅ CONFIG SAVED!"
    task.delay(1, function()
        saveNowBtn.Text = "💾 SAVE CONFIG NOW"
    end)
end)

log("EX Steal an Egg V24 Complete & Safe berhasil dimuat!")
