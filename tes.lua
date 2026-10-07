local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

-- Bersihkan versi sebelumnya
for _, v in pairs(gui:GetChildren()) do
    if v.Name:match("EX_StealAnEgg") then
        v:Destroy()
    end
end

local sg = Instance.new("ScreenGui")
sg.Name = "EX_StealAnEgg_V21_Pro"
sg.ResetOnSpawn = false
sg.Parent = gui

local whiteScreen = Instance.new("Frame", sg)
whiteScreen.Size = UDim2.new(1, 0, 1, 0)
whiteScreen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
whiteScreen.Visible = false
whiteScreen.ZIndex = -10

-- ==========================================
-- UI UTAMA (TRANSPARAN & RAPI)
-- ==========================================
local f = Instance.new("Frame", sg)
f.Size = UDim2.new(0, 520, 0, 340)
f.Position = UDim2.new(0.5, -260, 0.5, -170)
f.BackgroundColor3 = Color3.fromRGB(15, 10, 25)
f.BackgroundTransparency = 0.35 -- Lebih transparan
f.Active = true
f.Draggable = true
f.ClipsDescendants = true
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

-- Background Glow/Gradient
local bgGrad = Instance.new("UIGradient", f)
bgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 15, 45)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 5, 20))
})
bgGrad.Rotation = 45

-- Animasi Border (Glowing Flowing Gradient)
local bgStroke = Instance.new("UIStroke", f)
bgStroke.Color = Color3.fromRGB(255, 255, 255) -- Harus putih agar gradient terlihat
bgStroke.Thickness = 2
local strokeGrad = Instance.new("UIGradient", bgStroke)
strokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 30, 210)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(80, 200, 255)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(255, 80, 200)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 30, 210))
})

-- Rotasi border animasi setiap frame
RunService.RenderStepped:Connect(function(dt)
    if sg.Parent then
        strokeGrad.Rotation = (strokeGrad.Rotation + (dt * 60)) % 360
    end
end)

-- HEADER
local header = Instance.new("Frame", f)
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundTransparency = 1 -- Menyatu dengan frame utama

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 16, 0, 0)
title.BackgroundTransparency = 1
title.Text = "EX COMMUNITY  |  STEAL AN EGG (V21)"
title.TextColor3 = Color3.fromRGB(240, 240, 255)
title.TextSize = 11
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left

local headerLine = Instance.new("Frame", header)
headerLine.Size = UDim2.new(1, 0, 0, 1)
headerLine.Position = UDim2.new(0, 0, 1, 0)
headerLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
headerLine.BackgroundTransparency = 0.85

local minBtn = Instance.new("TextButton", header)
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.Position = UDim2.new(1, -36, 0.5, -13)
minBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
minBtn.BackgroundTransparency = 0.2
minBtn.Text = "—"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

-- MINIMIZED ICON
local minIcon = Instance.new("TextButton", sg)
minIcon.Size = UDim2.new(0, 44, 0, 44)
minIcon.Position = UDim2.new(0, 30, 0, 30)
minIcon.BackgroundColor3 = Color3.fromRGB(20, 10, 35)
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
iconStroke.Color = Color3.fromRGB(150, 50, 255)
iconStroke.Thickness = 2

-- SIDEBAR & HALAMAN
local sidebar = Instance.new("Frame", f)
sidebar.Size = UDim2.new(0, 130, 1, -41)
sidebar.Position = UDim2.new(0, 0, 0, 41)
sidebar.BackgroundTransparency = 1
local sidebarLine = Instance.new("Frame", sidebar)
sidebarLine.Size = UDim2.new(0, 1, 1, -20)
sidebarLine.Position = UDim2.new(1, 0, 0, 10)
sidebarLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sidebarLine.BackgroundTransparency = 0.85

local pageContainer = Instance.new("Frame", f)
pageContainer.Size = UDim2.new(1, -135, 1, -45)
pageContainer.Position = UDim2.new(0, 135, 0, 43)
pageContainer.BackgroundTransparency = 1

local tabs, pages = {}, {}
local function createTab(name, yPos, isFirst)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1, -20, 0, 32)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local page = Instance.new("ScrollingFrame", pageContainer)
    page.Size = UDim2.new(1, -10, 1, -10)
    page.BackgroundTransparency = 1
    page.Visible = isFirst
    page.CanvasSize = UDim2.new(0, 0, 0, 650)
    page.ScrollBarThickness = 2
    page.ScrollBarImageTransparency = 0.5
    page.BorderSizePixel = 0

    btn.BackgroundColor3 = isFirst and Color3.fromRGB(120, 30, 210) or Color3.fromRGB(255, 255, 255)
    btn.BackgroundTransparency = isFirst and 0.2 or 0.95
    btn.TextColor3 = isFirst and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 170, 200)

    table.insert(tabs, btn)
    table.insert(pages, page)

    btn.MouseButton1Click:Connect(function()
        for i, t in pairs(tabs) do
            t.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            t.BackgroundTransparency = 0.95
            t.TextColor3 = Color3.fromRGB(180, 170, 200)
            pages[i].Visible = false
        end
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2, BackgroundColor3 = Color3.fromRGB(120, 30, 210)}):Play()
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        page.Visible = true
    end)
    return page
end

local pageMain = createTab("MAIN", 15, true)
local pageEvents = createTab("EVENTS", 55, false)
local pagePerf = createTab("PERFORMANCE", 95, false)

local config = {
    running = false,
    eventRunning = false,
    perfAnti = false,
    method = "Fly",
    targetMode = "All",
    activeFilterValue = nil
}
local baseCFrame = nil

local function createToggle(parent, text, cb)
    local fHolder = Instance.new("Frame", parent)
    fHolder.Size = UDim2.new(1, 0, 0, 34)
    fHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fHolder.BackgroundTransparency = 0.95
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

    local bg = Instance.new("TextButton", fHolder)
    bg.Size = UDim2.new(0, 38, 0, 18)
    bg.Position = UDim2.new(1, -50, 0.5, -9)
    bg.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
    bg.Text = ""
    bg.AutoButtonColor = false
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", bg)
    stroke.Color = Color3.fromRGB(80, 50, 120)
    stroke.Thickness = 1

    local knob = Instance.new("Frame", bg)
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(0, 3, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(180, 140, 220)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local isOn = false
    bg.MouseButton1Click:Connect(function()
        isOn = not isOn
        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {Position = isOn and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)}):Play()
        TweenService:Create(bg, TweenInfo.new(0.2), {BackgroundColor3 = isOn and Color3.fromRGB(120, 30, 210) or Color3.fromRGB(40, 20, 60)}):Play()
        stroke.Color = isOn and Color3.fromRGB(160, 80, 255) or Color3.fromRGB(80, 50, 120)
        cb(isOn)
    end)
    return fHolder
end

-- ==========================================
-- GABUNGAN: LOGIKA FILTER EGG (CHATGPT + CLAUDE)
-- ==========================================
local EGG_PROMPT_NAME = "CarryAreaEgg"
local loopToken = 0

local function toPart(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
    end
    return inst:FindFirstAncestorWhichIsA("BasePart")
        or (inst.Parent and inst.Parent:FindFirstChildWhichIsA("BasePart", true))
end

local function isPlayerOwned(inst)
    local myName = player.Name:lower()
    local p = inst
    while p and p ~= Workspace do
        if p:IsA("Model") and Players:GetPlayerFromCharacter(p) then return true end
        local n = p.Name:lower()
        if n:find(myName, 1, true) or n:find("plot", 1, true) or n:find("base", 1, true) then return true end
        p = p.Parent
    end
    return false
end

local function checkEggDataMatch(eggModel, filterKey)
    if not eggModel then return false end
    filterKey = filterKey:lower()
    local combinedDataString = eggModel.Name:lower() .. " "
    
    for attrName, attrValue in pairs(eggModel:GetAttributes()) do
        combinedDataString = combinedDataString .. tostring(attrName):lower() .. ":" .. tostring(attrValue):lower() .. " "
    end

    local psn = eggModel:GetAttribute("PreparedSourceName")
    if psn then combinedDataString = combinedDataString .. tostring(psn):lower() .. " " end

    if string.find(combinedDataString, filterKey, 1, true) then
        return true
    end

    if eggModel:IsA("Model") and (filterKey == "small" or filterKey == "medium" or filterKey == "large" or filterKey == "giant") then
        local ok, _, size = pcall(function() return eggModel:GetBoundingBox() end)
        if ok and size then
            local maxDim = math.max(size.X, size.Y, size.Z)
            if filterKey == "small" and maxDim <= 3.5 then return true
            elseif filterKey == "medium" and maxDim > 3.5 and maxDim <= 7 then return true
            elseif filterKey == "large" and maxDim > 7 and maxDim <= 15 then return true
            elseif filterKey == "giant" and maxDim > 15 then return true
            end
        end
    end
    return false
end

local function findGuardEgg(hrp)
    local bestPart, bestPrompt, bestDist = nil, nil, math.huge
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Name == EGG_PROMPT_NAME and v.Enabled and not isPlayerOwned(v) then
            local part = toPart(v.Parent)
            local eggModel = v:FindFirstAncestorOfClass("Model") or part

            if part then
                local passFilter = true
                if config.targetMode == "Filter" and config.activeFilterValue then
                    passFilter = checkEggDataMatch(eggModel, config.activeFilterValue)
                end

                if passFilter then
                    local d = (part.Position - hrp.Position).Magnitude
                    if d < bestDist then
                        bestPart, bestPrompt, bestDist = part, v, d
                    end
                end
            end
        end
    end
    return bestPart, bestPrompt
end

local function goTo(hrp, cf)
    if config.method == "Fly" then
        local dist = (hrp.Position - cf.Position).Magnitude
        local dur = math.max(dist / 80, 0.05)
        local tween = TweenService:Create(hrp, TweenInfo.new(dur, Enum.EasingStyle.Linear), {CFrame = cf})
        local done = false
        tween.Completed:Once(function() done = true end)
        tween:Play()
        local t0 = os.clock()
        while not done and os.clock() - t0 < dur + 2 do task.wait() end
    else
        hrp.CFrame = cf
        task.wait(0.1)
    end
end

function startAutoStealLoop()
    loopToken += 1
    local myToken = loopToken
    task.spawn(function()
        while config.running and myToken == loopToken do
            task.wait(0.3)
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then continue end

            local part, prompt = findGuardEgg(hrp)
            if not part then task.wait(0.5) continue end

            goTo(hrp, part.CFrame * CFrame.new(0, 3, 0))
            task.wait(0.2)
            if prompt and prompt.Parent then
                prompt.HoldDuration = 0
                pcall(fireproximityprompt, prompt)
            end

            task.wait(0.3)
            if baseCFrame and config.running and myToken == loopToken then
                goTo(hrp, baseCFrame)
            end
        end
    end)
end

-- ==========================================
-- MAIN TAB CONTENT (CLEAN LAYOUT)
-- ==========================================
local mainList = Instance.new("UIListLayout", pageMain)
mainList.SortOrder = Enum.SortOrder.LayoutOrder
mainList.Padding = UDim.new(0, 8)

createToggle(pageMain, "Instant Teleport Mode", function(st)
    config.method = st and "Instant" or "Fly"
end)

createToggle(pageMain, "Auto Steal Active", function(st)
    config.running = st
    if config.running then
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then baseCFrame = hrp.CFrame end
        startAutoStealLoop()
    else
        loopToken += 1
    end
end)

-- Target Mode Selector
local sub = Instance.new("Frame", pageMain)
sub.Size = UDim2.new(1, 0, 0, 70)
sub.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sub.BackgroundTransparency = 0.95
Instance.new("UICorner", sub).CornerRadius = UDim.new(0, 6)

local modeList = Instance.new("UIListLayout", sub)
modeList.SortOrder = Enum.SortOrder.LayoutOrder
modeList.Padding = UDim.new(0, 6)
modeList.HorizontalAlignment = Enum.HorizontalAlignment.Center
modeList.VerticalAlignment = Enum.VerticalAlignment.Center

local bAll = Instance.new("TextButton", sub)
bAll.Size = UDim2.new(0.92, 0, 0, 26)
bAll.Text = "Steal All Mode"
bAll.BackgroundColor3 = Color3.fromRGB(120, 30, 210)
bAll.BackgroundTransparency = 0.2
bAll.TextColor3 = Color3.fromRGB(255, 255, 255)
bAll.TextSize = 10
bAll.Font = Enum.Font.GothamBold
Instance.new("UICorner", bAll).CornerRadius = UDim.new(0, 5)

local bFil = Instance.new("TextButton", sub)
bFil.Size = UDim2.new(0.92, 0, 0, 26)
bFil.Text = "Steal by Filter Mode"
bFil.BackgroundColor3 = Color3.fromRGB(30, 15, 48)
bFil.BackgroundTransparency = 0.5
bFil.TextColor3 = Color3.fromRGB(170, 140, 210)
bFil.TextSize = 10
bFil.Font = Enum.Font.GothamMedium
Instance.new("UICorner", bFil).CornerRadius = UDim.new(0, 5)

bAll.MouseButton1Click:Connect(function()
    config.targetMode = "All"
    bAll.BackgroundColor3 = Color3.fromRGB(120, 30, 210)
    bAll.BackgroundTransparency = 0.2
    bAll.TextColor3 = Color3.fromRGB(255,255,255)
    bAll.Font = Enum.Font.GothamBold
    bFil.BackgroundColor3 = Color3.fromRGB(30, 15, 48)
    bFil.BackgroundTransparency = 0.5
    bFil.TextColor3 = Color3.fromRGB(170, 140, 210)
    bFil.Font = Enum.Font.GothamMedium
end)

bFil.MouseButton1Click:Connect(function()
    config.targetMode = "Filter"
    bFil.BackgroundColor3 = Color3.fromRGB(120, 30, 210)
    bFil.BackgroundTransparency = 0.2
    bFil.TextColor3 = Color3.fromRGB(255,255,255)
    bFil.Font = Enum.Font.GothamBold
    bAll.BackgroundColor3 = Color3.fromRGB(30, 15, 48)
    bAll.BackgroundTransparency = 0.5
    bAll.TextColor3 = Color3.fromRGB(170, 140, 210)
    bAll.Font = Enum.Font.GothamMedium
end)

-- Expandable Filter
local btnF = Instance.new("TextButton", pageMain)
btnF.Size = UDim2.new(1, 0, 0, 32)
btnF.Text = "▼ SELECT FILTER EGG"
btnF.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
btnF.BackgroundTransparency = 0.95
btnF.TextColor3 = Color3.fromRGB(230, 200, 255)
btnF.TextSize = 10
btnF.Font = Enum.Font.GothamBold
Instance.new("UICorner", btnF).CornerRadius = UDim.new(0, 6)

local fEx = Instance.new("Frame", pageMain)
fEx.Size = UDim2.new(1, 0, 0, 0)
fEx.BackgroundTransparency = 1
fEx.Visible = false
fEx.ClipsDescendants = true
local fList = Instance.new("UIListLayout", fEx)
fList.SortOrder = Enum.SortOrder.LayoutOrder
fList.Padding = UDim.new(0, 4)

local function addCat(name, opts)
    local catHolder = Instance.new("Frame", fEx)
    catHolder.Size = UDim2.new(1, 0, 0, 28)
    catHolder.BackgroundTransparency = 1
    catHolder.ClipsDescendants = true

    local l = Instance.new("TextButton", catHolder)
    l.Size = UDim2.new(1, 0, 0, 28)
    l.Text = "  + " .. name
    l.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    l.BackgroundTransparency = 0.97
    l.TextColor3 = Color3.fromRGB(200, 180, 230)
    l.TextSize = 10
    l.Font = Enum.Font.GothamMedium
    l.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", l).CornerRadius = UDim.new(0, 4)

    local c = Instance.new("Frame", catHolder)
    c.Size = UDim2.new(1, 0, 0, 0)
    c.Position = UDim2.new(0, 0, 0, 30)
    c.BackgroundTransparency = 1
    c.Visible = false
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
        ob.TextColor3 = Color3.fromRGB(160, 140, 200)
        ob.TextSize = 9
        ob.Font = Enum.Font.Gotham
        Instance.new("UICorner", ob).CornerRadius = UDim.new(0, 4)
        local sk = Instance.new("UIStroke", ob)
        sk.Color = Color3.fromRGB(180, 80, 255)
        sk.Thickness = 1.2
        sk.Transparency = 1

        ob.MouseButton1Click:Connect(function()
            for _, o in ipairs(c:GetChildren()) do
                if o:IsA("TextButton") then
                    o.UIStroke.Transparency = 1
                    o.TextColor3 = Color3.fromRGB(160, 140, 200)
                    o.Font = Enum.Font.Gotham
                end
            end
            sk.Transparency = 0
            ob.TextColor3 = Color3.fromRGB(255, 255, 255)
            ob.Font = Enum.Font.GothamBold
            config.activeFilterValue = opt
        end)
    end

    local isOpen = false
    l.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        c.Visible = isOpen
        TweenService:Create(catHolder, TweenInfo.new(0.2), {Size = isOpen and UDim2.new(1, 0, 0, 30 + (#opts * 28)) or UDim2.new(1, 0, 0, 28)}):Play()
        l.Text = isOpen and "  - " .. name or "  + " .. name
    end)
end

addCat("Filter with Size", {"Small", "Medium", "Large", "Giant"})
addCat("Filter with Rarities", {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Cosmic", "Eternal", "Divine"})
addCat("Filter with Variant", {"Normal", "Golden", "Rainbow", "Dark"})

btnF.MouseButton1Click:Connect(function()
    fEx.Visible = not fEx.Visible
    btnF.Text = fEx.Visible and "▲ HIDE FILTER" or "▼ SELECT FILTER EGG"
    TweenService:Create(fEx, TweenInfo.new(0.3), {Size = fEx.Visible and UDim2.new(1, 0, 0, 3 * 30 + 15) or UDim2.new(1, 0, 0, 0)}):Play()
end)

-- ==========================================
-- EVENTS & PERF TABS (CLEAN)
-- ==========================================
local evList = Instance.new("UIListLayout", pageEvents)
evList.SortOrder = Enum.SortOrder.LayoutOrder
evList.Padding = UDim.new(0, 8)

local btnEvent = Instance.new("TextButton", pageEvents)
btnEvent.Size = UDim2.new(1, 0, 0, 38)
btnEvent.Text = "AUTO FARM BOSS / EVENT"
btnEvent.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
btnEvent.BackgroundTransparency = 0.2
btnEvent.TextColor3 = Color3.fromRGB(255, 255, 255)
btnEvent.Font = Enum.Font.GothamBold
btnEvent.TextSize = 10
Instance.new("UICorner", btnEvent).CornerRadius = UDim.new(0, 6)

btnEvent.MouseButton1Click:Connect(function()
    config.eventRunning = not config.eventRunning
    btnEvent.Text = config.eventRunning and "STOP FARMING BOSS" or "AUTO FARM BOSS / EVENT"
    TweenService:Create(btnEvent, TweenInfo.new(0.2), {BackgroundColor3 = config.eventRunning and Color3.fromRGB(40, 160, 60) or Color3.fromRGB(150, 40, 40)}):Play()

    if config.eventRunning then
        task.spawn(function()
            while config.eventRunning do
                task.wait(0.5)
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end
                local bossPart = nil
                for _, v in pairs(Workspace:GetDescendants()) do
                    local n = v.Name:lower()
                    if v:IsA("Model") and (n:find("boss") or n:find("event") or n:find("mob") or n:find("monster")) and not Players:GetPlayerFromCharacter(v) then
                        bossPart = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
                        if bossPart then break end
                    end
                end
                if bossPart then
                    hrp.CFrame = bossPart.CFrame + Vector3.new(0, 3, 5)
                    pcall(function()
                        local tool = player.Character:FindFirstChildWhichIsA("Tool") or player.Backpack:FindFirstChildWhichIsA("Tool")
                        if tool then tool.Parent = player.Character tool:Activate() end
                    end)
                end
            end
        end)
    end
end)

local pList = Instance.new("UIListLayout", pagePerf)
pList.SortOrder = Enum.SortOrder.LayoutOrder
pList.Padding = UDim.new(0, 8)

createToggle(pagePerf, "Disable 3D (Pure White Screen)", function(st)
    whiteScreen.Visible = st
    pcall(function() RunService:Set3dRenderingEnabled(not st) end)
end)

createToggle(pagePerf, "Remove Plot, Pets & Map Decors", function(st)
    if st then
        pcall(function()
            for _, v in pairs(Workspace:GetDescendants()) do
                local n = v.Name:lower()
                if v:IsA("Model") and (n:find("pet") or n:find("guardian")) and not Players:GetPlayerFromCharacter(v) then v:Destroy()
                elseif v:IsA("BasePart") and (n:find("plot") or n:find("tree")) then v:Destroy() end
            end
        end)
    end
end)

createToggle(pagePerf, "Anti-Lag Treadmill (+Speed)", function(st)
    config.perfAnti = st
    task.spawn(function()
        while config.perfAnti do
            task.wait(0.2)
            pcall(function()
                for _, v in pairs(Workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") or v:IsA("BillboardGui") then v:Destroy() end
                end
            end)
        end
    end)
end)

createToggle(pagePerf, "Super FPS Boost (Potato Graphics)", function(st)
    if st then
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            game:GetService("Lighting").GlobalShadows = false
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic v.Reflectance = 0 end
            end
        end)
    end
end)

-- ==========================================
-- MINIMIZE BEHAVIOR
-- ==========================================
minBtn.MouseButton1Click:Connect(function()
    f.Visible = false
    minIcon.Visible = true
end)

minIcon.MouseButton1Click:Connect(function()
    f.Visible = true
    minIcon.Visible = false
end)
