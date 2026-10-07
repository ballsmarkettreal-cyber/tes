--[[
    EX COMMUNITY | STEAL AN EGG - V24 ULTIMATE SAFE
    Fitur: Anti-Cheat Bypassed, Multi-Select Filters, Config Menu (Auto-Save 2s), Raycast Landing (Anti Tenggelam)
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Bersihkan versi sebelumnya
for _, v in ipairs(playerGui:GetChildren()) do
    if v.Name:match("EX_StealAnEgg") then v:Destroy() end
end

local VERSION = "V24-Safe"
local SAVE_FILE = "EX_StealAnEgg_V24.json"
local BASE_RADIUS = 140

-- ==========================================
-- SISTEM CONFIG & AUTO-SAVE
-- ==========================================
local config = {
    running = false,
    method = "Fly",
    targetMode = "All",
    flySpeed = 70,
    flyHeight = 10,
    autoSave = true, -- Default ON
    antiAfk = true,
    filters = {
        Size = {},
        Rarity = {},
        Variant = {}
    },
    areas = {},
}

local function loadSettings()
    if typeof(readfile) == "function" and typeof(isfile) == "function" then
        local ok, data = pcall(function()
            if isfile(SAVE_FILE) then return HttpService:JSONDecode(readfile(SAVE_FILE)) end
            return nil
        end)
        if ok and type(data) == "table" then
            if data.flySpeed then config.flySpeed = data.flySpeed end
            if data.flyHeight then config.flyHeight = data.flyHeight end
            if data.autoSave ~= nil then config.autoSave = data.autoSave end
            if data.filters then config.filters = data.filters end
        end
    end
end
loadSettings()

local function saveSettings()
    if typeof(writefile) ~= "function" then return end
    local data = {
        flySpeed = config.flySpeed,
        flyHeight = config.flyHeight,
        autoSave = config.autoSave,
        filters = config.filters,
    }
    pcall(writefile, SAVE_FILE, HttpService:JSONEncode(data))
end

-- Background Auto-Save Loop (Setiap 2 detik jika aktif)
task.spawn(function()
    while true do
        task.wait(2)
        if config.autoSave then
            saveSettings()
        end
    end
end)

-- ==========================================
-- TEMA & UI UTAMA
-- ==========================================
local THEME = {
    bg1 = Color3.fromRGB(15, 10, 25),
    accent = Color3.fromRGB(120, 30, 210),
    accent2 = Color3.fromRGB(80, 200, 255),
    text = Color3.fromRGB(240, 240, 255),
    sub = Color3.fromRGB(180, 170, 200),
}

local sg = Instance.new("ScreenGui")
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

-- Glowing RGB Border
local bgStroke = Instance.new("UIStroke", f)
bgStroke.Color = Color3.fromRGB(255, 255, 255)
bgStroke.Thickness = 2
local strokeGrad = Instance.new("UIGradient", bgStroke)
strokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 30, 210)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 200, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 200))
})
RunService.RenderStepped:Connect(function(dt)
    if sg.Parent then strokeGrad.Rotation = (strokeGrad.Rotation + (dt * 50)) % 360 end
end)

-- Animasi Bintang Jatuh (Tebal & Estetik)
local starContainer = Instance.new("Frame", f)
starContainer.Size = UDim2.new(1, 0, 1, 0)
starContainer.BackgroundTransparency = 1
starContainer.ZIndex = 0
starContainer.ClipsDescendants = true

task.spawn(function()
    local rng = Random.new()
    while f.Parent do
        task.wait(rng:NextNumber(0.2, 0.4))
        local star = Instance.new("Frame", starContainer)
        star.Size = UDim2.new(0, rng:NextInteger(80, 140), 0, rng:NextInteger(3, 5))
        star.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        star.Rotation = 35
        star.Position = UDim2.new(rng:NextNumber(-0.2, 0.5), 0, -0.2, 0)
        
        local grad = Instance.new("UIGradient", star)
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, THEME.accent)
        })
        Instance.new("UICorner", star).CornerRadius = UDim.new(1, 0)
        
        local dur = rng:NextNumber(0.8, 1.3)
        local tw = TweenService:Create(star, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Position = UDim2.new(rng:NextNumber(0.4, 0.9), 0, 1.2, 0)})
        tw:Play()
        task.delay(dur, function() star:Destroy() end)
    end
end)

-- HEADER
local header = Instance.new("Frame", f)
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundTransparency = 1
header.ZIndex = 2

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 16, 0, 0)
title.BackgroundTransparency = 1
title.Text = "EX COMMUNITY | STEAL AN EGG (V24 SAFE)"
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

-- MINIMIZED ICON
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
local iconStroke = Instance.new("UIStroke", minIcon)
iconStroke.Color = THEME.accent
iconStroke.Thickness = 2

minBtn.MouseButton1Click:Connect(function() f.Visible = false; minIcon.Visible = true end)
minIcon.MouseButton1Click:Connect(function() f.Visible = true; minIcon.Visible = false end)

-- SIDEBAR & HALAMAN
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
    page.CanvasSize = UDim2.new(0, 0, 0, 800)
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

-- ==========================================
// HELPERKARAKTER & ANTI-CHEAT SAFE MOVEMENT
-- ==========================================
local function getChar()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hrp, hum, char
end

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

-- Gerak Aman Anti-Cheat (Tween + PlatformStand agar tidak ditendang server)
local function goTo(hrp, hum, targetCF, alive)
    local finalCF = getGroundCFrame(targetCF)
    local startCF = hrp.CFrame
    local dist = (startCF.Position - finalCF.Position).Magnitude
    
    if hum then hum.PlatformStand = true end
    
    local speed = config.flySpeed
    local dur = math.max(dist / speed, 0.1)
    
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
    task.wait(0.15)
end

-- ==========================================
-- LOGIKA TARGET & MULTI-SELECT FILTER
-- ==========================================
local function collectEggPrompts()
    local result = {}
    local folder = Workspace:FindFirstChild("AreaEggSlotsClient")
    local function scan(root)
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("ProximityPrompt") and d.Name:lower() == "carryareaegg" then
                table.insert(result, d)
            end
        end
    end
    if folder then scan(folder) end
    if #result == 0 then scan(Workspace) end
    return result
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
        -- Jika kategori tersebut menyalakan filter, maka harus cocok dengan salah satunya (AND antar kategori, OR di dalam kategori)
        if hasAnyActive and not matchedAny then return false end
    end
    return true
end

local function findTarget(hrp)
    local best, bestDist = nil, math.huge
    for _, prompt in ipairs(collectEggPrompts()) do
        local part = prompt.Parent and (prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent:FindFirstChildWhichIsA("BasePart"))
        if part then
            local root = getEggRoot(prompt)
            if checkMultiFilters(root) then
                local d = (part.Position - hrp.Position).Magnitude
                if d < bestDist then
                    best, bestDist = part, d
                end
            end
        end
    end
    return best
end

-- ==========================================
-- AUTO STEAL UTAMA
-- ==========================================
local baseCFrame = nil
local loopToken = 0

local function startAutoStealLoop()
    loopToken += 1
    local myToken = loopToken
    task.spawn(function()
        while config.running and myToken == loopToken do
            task.wait(0.3)
            local hrp, hum = getChar()
            if not hrp or not hum or hum.Health <= 0 then continue end

            -- Teleport sebentar ke Forest agar map ter-load
            hrp.CFrame = CFrame.new(597, 10, -324)
            task.wait(0.4)

            local part = findTarget(hrp)
            if not part then task.wait(0.5); continue end

            -- 1. Terbang ke telur secara mulus & aman
            goTo(hrp, hum, part.CFrame * CFrame.new(0, 3, 0), function() return config.running and myToken == loopToken end)
            task.wait(0.3)

            -- 2. Ambil telur
            local prompt = nil
            for _, p in ipairs(Workspace:GetDescendants()) do
                if p:IsA("ProximityPrompt") and p.Name:lower() == "carryareaegg" then
                    local pPart = p.Parent and (p.Parent:IsA("BasePart") and p.Parent or p.Parent:FindFirstChildWhichIsA("BasePart"))
                    if pPart and (pPart.Position - part.Position).Magnitude < 15 then
                        prompt = p; break
                    end
                end
            end

            if prompt then
                prompt.HoldDuration = 0
                pcall(fireproximityprompt, prompt)
            end
            task.wait(0.5)

            -- 3. Pulang ke Base dengan aman (Anti tenggelam)
            if baseCFrame and config.running and myToken == loopToken then
                goTo(hrp, hum, baseCFrame, function() return config.running and myToken == loopToken end)
                task.wait(0.6)
            end
        end
    end)
end

-- ==========================================
-- PEMBUATAN UI TAB MAIN
-- ==========================================
local mainList = Instance.new("UIListLayout", pageMain)
mainList.SortOrder = Enum.SortOrder.LayoutOrder
mainList.Padding = UDim.new(0, 8)

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

createToggle(pageMain, "Auto Steal (Start from Safe Zone)", false, function(st)
    config.running = st
    if config.running then
        local hrp = getChar()
        if hrp then baseCFrame = hrp.CFrame + Vector3.new(0, 3, 0) end
        startAutoStealLoop()
    else
        loopToken += 1
    end
end)

-- Target Mode Selection
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

-- Expandable Multi-Select Filter Menu
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
            -- Toggle multi-select
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
-- PEMBUATAN UI TAB CONFIG
-- ==========================================
local configList = Instance.new("UIListLayout", pageConfig)
configList.SortOrder = Enum.SortOrder.LayoutOrder
configList.Padding = UDim.new(0, 8)

createToggle(pageConfig, "Auto Save Config (Every 2s)", config.autoSave, function(st)
    config.autoSave = st
end)

-- Tombol Save Now
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
