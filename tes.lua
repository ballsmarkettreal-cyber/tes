--[[
    EX COMMUNITY | STEAL AN EGG  -  V22
    Perubahan utama dari V21:
      * Deteksi telur lewat ProximityPrompt (tidak bergantung struktur folder)
      * Mendukung prompt yang parent-nya Attachment/Model (penyebab utama "tidak dapat telur")
      * Gerak terbang pakai Heartbeat (tidak melawan fisika) + reset velocity
      * Fire prompt dengan retry + fallback InputHoldBegin/End
      * Filter "milik sendiri" tidak lagi memblokir semua telur
      * UI baru, tab baru, efek bintang jatuh arahnya benar
      * Tab DEBUG untuk melihat apa yang dideteksi script
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Bersihkan versi sebelumnya
if _G.EX_STEAL_EGG_CLEANUP then pcall(_G.EX_STEAL_EGG_CLEANUP) end
for _, v in ipairs(playerGui:GetChildren()) do
    if v.Name:match("EX_StealAnEgg") then v:Destroy() end
end

-- ==========================================
-- KONFIGURASI
-- ==========================================
local VERSION = "V22"

-- Titik untuk memancing map ter-load (StreamingEnabled). Tambah/ubah sesuai kebutuhan.
local WAYPOINTS = {
    Forest = Vector3.new(597, 10, -324),
}

local config = {
    running = false,
    eventRunning = false,
    perfAnti = false,
    method = "Fly",        -- "Fly" | "Instant"
    targetMode = "All",    -- "All" | "Filter"
    filterValue = nil,
    flySpeed = 90,
    flyHeight = 12,
}

local stats = { stolen = 0, failed = 0 }
local baseCFrame = nil
local loopToken = 0
local connections = {}
local uiAlive = true
local ui = {}

local function track(conn)
    table.insert(connections, conn)
    return conn
end

-- ==========================================
-- TEMA & HELPER UI
-- ==========================================
local THEME = {
    bg1 = Color3.fromRGB(28, 16, 46),
    bg2 = Color3.fromRGB(8, 5, 16),
    card = Color3.fromRGB(38, 26, 62),
    off = Color3.fromRGB(52, 38, 82),
    accent = Color3.fromRGB(128, 62, 230),
    accent2 = Color3.fromRGB(110, 210, 255),
    text = Color3.fromRGB(240, 236, 255),
    sub = Color3.fromRGB(160, 148, 195),
    good = Color3.fromRGB(74, 222, 128),
    warn = Color3.fromRGB(250, 204, 21),
    bad = Color3.fromRGB(248, 113, 113),
}

local function new(class, props, children)
    local inst = Instance.new(class)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else inst[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    inst.Parent = parent
    return inst
end

local function corner(inst, radius)
    return new("UICorner", { CornerRadius = UDim.new(0, radius), Parent = inst })
end

local function stroke(inst, color, thickness, transparency)
    return new("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = inst,
    })
end

local function pad(inst, top, right, bottom, left)
    return new("UIPadding", {
        PaddingTop = UDim.new(0, top), PaddingRight = UDim.new(0, right),
        PaddingBottom = UDim.new(0, bottom), PaddingLeft = UDim.new(0, left),
        Parent = inst,
    })
end

local function tween(inst, duration, props)
    local tw = TweenService:Create(inst, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

-- ==========================================
-- LOG & STATUS
-- ==========================================
local logLines = {}
local function log(msg)
    msg = os.date("%H:%M:%S") .. "  " .. tostring(msg)
    table.insert(logLines, msg)
    if #logLines > 60 then table.remove(logLines, 1) end
    if ui.logLabel then
        ui.logLabel.Text = table.concat(logLines, "\n")
        task.defer(function()
            if ui.logScroll then ui.logScroll.CanvasPosition = Vector2.new(0, 1e6) end
        end)
    end
end

local function setStatus(text, color)
    if ui.statusText then ui.statusText.Text = text end
    if ui.statusDot then ui.statusDot.BackgroundColor3 = color or THEME.sub end
end

local function refreshStats()
    if ui.statsText then
        ui.statsText.Text = ("Berhasil: %d    Gagal: %d"):format(stats.stolen, stats.failed)
    end
    if ui.modeText then
        local move = config.method == "Fly" and "Terbang" or "Teleport"
        local target = "Semua"
        if config.targetMode == "Filter" then target = config.filterValue or "Filter (belum dipilih)" end
        ui.modeText.Text = ("Gerak: %s    Target: %s"):format(move, target)
    end
end

-- ==========================================
-- LOGIKA: DETEKSI TELUR
-- ==========================================
local function getHRP()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getInstPosition(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst.Position end
    if inst:IsA("Attachment") then return inst.WorldPosition end
    if inst:IsA("Model") then
        local ok, cf = pcall(function() return inst:GetPivot() end)
        if ok then return cf.Position end
    end
    return nil
end

-- ProximityPrompt sering ditaruh di Attachment/Model, bukan di Part (bug V21: prompt tidak pernah ketemu)
local function getPromptPosition(prompt)
    local pos = getInstPosition(prompt.Parent)
    if pos then return pos end
    local model = prompt:FindFirstAncestorOfClass("Model")
    if model then
        pos = getInstPosition(model)
        if pos then return pos end
    end
    local part = prompt.Parent and prompt.Parent:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

local function isEggPrompt(p)
    if not p:IsA("ProximityPrompt") then return false end
    local name = p.Name:lower()
    local action = (p.ActionText or ""):lower()
    if name:find("carryareaegg", 1, true) then return true end
    if action:find("carry", 1, true) or action:find("steal", 1, true) then return true end
    if name:find("egg", 1, true) and (action:find("grab", 1, true) or action:find("take", 1, true) or action:find("pick", 1, true)) then
        return true
    end
    return false
end

local function collectEggPrompts()
    local result = {}
    local function scan(root)
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("ProximityPrompt") and isEggPrompt(d) then
                table.insert(result, d)
            end
        end
    end
    local folder = Workspace:FindFirstChild("AreaEggSlotsClient")
    if folder then scan(folder) end
    if #result == 0 then scan(Workspace) end
    return result
end

-- Hanya menganggap "milik sendiri" jika benar-benar ada penanda pemilik (V21 terlalu agresif:
-- nama mengandung "plot"/"base" langsung dibuang, sehingga semua telur ikut terfilter)
local OWNER_ATTRS = { "Owner", "OwnerId", "OwnerUserId", "OwnerName", "UserId", "PlayerName", "Player" }
local function ownedByMe(inst)
    local myName = player.Name:lower()
    local myDisplay = player.DisplayName:lower()
    local myId = tostring(player.UserId)
    local cur = inst
    while cur and cur ~= Workspace do
        if cur == player.Character then return true end
        for _, a in ipairs(OWNER_ATTRS) do
            local v = cur:GetAttribute(a)
            if v ~= nil then
                local s = tostring(v):lower()
                if s == myName or s == myId or s == myDisplay then return true end
            end
        end
        local ov = cur:FindFirstChild("Owner")
        if ov then
            if ov:IsA("ObjectValue") and ov.Value == player then return true end
            if ov:IsA("StringValue") and ov.Value:lower() == myName then return true end
            if ov:IsA("IntValue") and tostring(ov.Value) == myId then return true end
        end
        if cur.Name:lower() == myName then return true end
        cur = cur.Parent
    end
    return false
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

local function collectEggText(root)
    local parts = { root.Name:lower() }
    local function addAttrs(inst)
        for k, v in pairs(inst:GetAttributes()) do
            table.insert(parts, tostring(k):lower() .. ":" .. tostring(v):lower())
        end
    end
    addAttrs(root)
    local count = 0
    for _, d in ipairs(root:GetDescendants()) do
        count += 1
        if count > 80 then break end
        table.insert(parts, d.Name:lower())
        addAttrs(d)
        if d:IsA("TextLabel") then table.insert(parts, d.Text:lower()) end
    end
    return table.concat(parts, " ")
end

local function matchesFilter(root, key)
    if not root or not key then return false end
    key = key:lower()
    local text = collectEggText(root)

    if key == "normal" then
        return not (text:find("golden", 1, true) or text:find("rainbow", 1, true) or text:find("dark", 1, true))
    end
    if key == "common" then
        text = (text:gsub("uncommon", ""))
    end
    if text:find(key, 1, true) then return true end

    if root:IsA("Model") and (key == "small" or key == "medium" or key == "large" or key == "giant") then
        local ok, _, size = pcall(function() return root:GetBoundingBox() end)
        if ok and size then
            local m = math.max(size.X, size.Y, size.Z)
            if key == "small" then return m <= 3.5 end
            if key == "medium" then return m > 3.5 and m <= 7 end
            if key == "large" then return m > 7 and m <= 15 end
            if key == "giant" then return m > 15 end
        end
    end
    return false
end

local lastNoTargetLog = 0
local function findTarget(hrp, silent)
    local best
    local c = { total = 0, disabled = 0, mine = 0, filtered = 0, nopos = 0 }
    for _, prompt in ipairs(collectEggPrompts()) do
        c.total += 1
        local pos = getPromptPosition(prompt)
        if not pos then
            c.nopos += 1
        elseif not prompt.Enabled then
            c.disabled += 1
        elseif ownedByMe(prompt) then
            c.mine += 1
        elseif config.targetMode == "Filter" and config.filterValue
            and not matchesFilter(getEggRoot(prompt), config.filterValue) then
            c.filtered += 1
        else
            local d = (pos - hrp.Position).Magnitude
            if not best or d < best.dist then
                best = { prompt = prompt, pos = pos, dist = d }
            end
        end
    end
    if not best and not silent and os.clock() - lastNoTargetLog > 3 then
        lastNoTargetLog = os.clock()
        log(("Tidak ada target: %d prompt | %d nonaktif | %d milikku | %d tak lolos filter | %d tanpa posisi")
            :format(c.total, c.disabled, c.mine, c.filtered, c.nopos))
    end
    return best
end

-- ==========================================
-- LOGIKA: GERAK
-- ==========================================
local function flyTo(hrp, targetPos, speed, alive)
    while alive() do
        if not hrp.Parent then return false end
        local delta = targetPos - hrp.Position
        local dist = delta.Magnitude
        if dist < 1.5 then break end
        local dt = RunService.Heartbeat:Wait()
        local step = math.min(dist, speed * dt)
        local rot = hrp.CFrame - hrp.CFrame.Position
        hrp.CFrame = CFrame.new(hrp.Position + delta.Unit * step) * rot
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
    return true
end

local function goTo(hrp, targetPos, alive)
    if config.method == "Instant" then
        hrp.CFrame = CFrame.new(targetPos)
        hrp.AssemblyLinearVelocity = Vector3.zero
        task.wait(0.2)
        return
    end

    local speed = config.flySpeed
    if (hrp.Position - targetPos).Magnitude < 15 then
        flyTo(hrp, targetPos, speed, alive)
        return
    end

    local cruiseY = math.max(hrp.Position.Y, targetPos.Y) + config.flyHeight
    flyTo(hrp, Vector3.new(hrp.Position.X, cruiseY, hrp.Position.Z), speed, alive)
    flyTo(hrp, Vector3.new(targetPos.X, cruiseY, targetPos.Z), speed, alive)
    flyTo(hrp, targetPos, speed, alive)
end

-- ==========================================
-- LOGIKA: AMBIL TELUR
-- ==========================================
local function triggerPrompt(prompt)
    pcall(function()
        prompt.HoldDuration = 0
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance, 25)
    end)
    if typeof(fireproximityprompt) == "function" then
        local ok = pcall(fireproximityprompt, prompt)
        if ok then return true end
    end
    -- Fallback jika executor tidak punya fireproximityprompt
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.05)
        prompt:InputHoldEnd()
    end)
    return ok
end

local function isCarrying()
    local function hasCarryAttr(inst)
        for name, value in pairs(inst:GetAttributes()) do
            if tostring(name):lower():find("carry", 1, true) and value then return true end
        end
        return false
    end
    if hasCarryAttr(player) then return true end
    local char = player.Character
    if not char then return false end
    if hasCarryAttr(char) then return true end
    for _, d in ipairs(char:GetDescendants()) do
        if d.Name:lower():find("egg", 1, true) then return true end
    end
    return false
end

local function waitForTarget(hrp, alive)
    local target = findTarget(hrp, false)
    if target then return target end

    for name, pos in pairs(WAYPOINTS) do
        if not alive() then return nil end
        setStatus("Memuat area " .. name .. "...", THEME.warn)
        hrp.CFrame = CFrame.new(pos)
        hrp.AssemblyLinearVelocity = Vector3.zero
        pcall(function() player:RequestStreamAroundAsync(pos, 3) end)
        local t0 = os.clock()
        repeat
            task.wait(0.25)
            target = findTarget(hrp, true)
        until target or not alive() or os.clock() - t0 > 3
        if target then return target end
    end
    return nil
end

local function stealCycle(alive)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then
        task.wait(1)
        return
    end

    setStatus("Mencari telur...", THEME.accent2)
    local target = waitForTarget(hrp, alive)
    if not alive() then return end
    if not target then
        setStatus("Tidak ada telur ditemukan", THEME.warn)
        task.wait(1.5)
        return
    end

    local prompt = target.prompt
    log(("Target: %s (%d stud)"):format(prompt:GetFullName(), math.floor(target.dist)))

    setStatus(config.method == "Fly" and "Terbang ke telur..." or "Teleport ke telur...", THEME.accent2)
    goTo(hrp, target.pos + Vector3.new(0, 3, 0), alive)
    if not alive() then return end
    task.wait(0.3)

    setStatus("Mengambil telur...", THEME.accent)
    local success = false
    for _ = 1, 3 do
        if not alive() then return end
        if not prompt.Parent then success = true break end
        triggerPrompt(prompt)
        task.wait(0.4)
        if isCarrying() or not prompt.Parent or not prompt.Enabled then
            success = true
            break
        end
    end

    if success then
        stats.stolen += 1
        log("Telur berhasil diambil")
    else
        stats.failed += 1
        log("Gagal mengambil telur (prompt tidak merespon)")
    end
    refreshStats()

    if baseCFrame and alive() then
        setStatus("Pulang ke base...", THEME.good)
        goTo(hrp, baseCFrame.Position, alive)
        task.wait(0.5)
    end
end

local function startAutoSteal()
    loopToken += 1
    local myToken = loopToken
    local function alive()
        return config.running and myToken == loopToken and uiAlive
    end
    task.spawn(function()
        log("Auto Steal dimulai")
        while alive() do
            local ok, err = pcall(stealCycle, alive)
            if not ok then
                log("Error: " .. tostring(err))
                task.wait(1)
            end
            task.wait(0.25)
        end
        setStatus("Idle", THEME.sub)
        log("Auto Steal berhenti")
    end)
end

-- ==========================================
-- LOGIKA: EVENT / PERFORMA
-- ==========================================
local function findBossPart()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and not Players:GetPlayerFromCharacter(v) then
            local n = v.Name:lower()
            if n:find("boss", 1, true) or n:find("event", 1, true) or n:find("mob", 1, true) or n:find("monster", 1, true) then
                local part = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
                if part then return part end
            end
        end
    end
    return nil
end

local function startBossLoop()
    task.spawn(function()
        local boss
        local lastScan = 0
        while config.eventRunning and uiAlive do
            task.wait(0.4)
            local hrp = getHRP()
            if not hrp then continue end
            if (not boss or not boss.Parent) and os.clock() - lastScan > 1.5 then
                lastScan = os.clock()
                boss = findBossPart()
            end
            if boss and boss.Parent then
                hrp.CFrame = boss.CFrame + Vector3.new(0, 3, 5)
                pcall(function()
                    local char = player.Character
                    local tool = char:FindFirstChildWhichIsA("Tool") or player.Backpack:FindFirstChildWhichIsA("Tool")
                    if tool then
                        tool.Parent = char
                        tool:Activate()
                    end
                end)
            end
        end
    end)
end

local function isEggRelated(inst)
    local cur = inst
    while cur and cur ~= Workspace do
        if cur.Name:lower():find("egg", 1, true) then return true end
        cur = cur.Parent
    end
    return false
end

local antiLagConn
local function setAntiLag(state)
    config.perfAnti = state
    if antiLagConn then antiLagConn:Disconnect() antiLagConn = nil end
    if not state then return end
    local function clean(v)
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
            pcall(function() v.Enabled = false end)
        end
    end
    task.spawn(function()
        for _, v in ipairs(Workspace:GetDescendants()) do clean(v) end
    end)
    antiLagConn = Workspace.DescendantAdded:Connect(clean)
    track(antiLagConn)
end

-- ==========================================
-- UI: WINDOW
-- ==========================================
local camera = Workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
local WIN_W = math.clamp(math.floor(viewport.X * 0.85), 400, 560)
local WIN_H = math.clamp(math.floor(viewport.Y * 0.85), 280, 380)

local sg = new("ScreenGui", {
    Name = "EX_StealAnEgg_" .. VERSION,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
    IgnoreGuiInset = true,
    Parent = playerGui,
})

local whiteScreen = new("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 0,
    Parent = sg,
})

local main = new("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(WIN_W, WIN_H),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 1,
    Parent = sg,
})
corner(main, 12)
new("UIGradient", { Color = ColorSequence.new(THEME.bg1, THEME.bg2), Rotation = 45, Parent = main })

local mainStroke = stroke(main, Color3.new(1, 1, 1), 2, 0)
local strokeGrad = new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 30, 210)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(80, 200, 255)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(255, 80, 200)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 30, 210)),
    }),
    Parent = mainStroke,
})
track(RunService.RenderStepped:Connect(function(dt)
    strokeGrad.Rotation = (strokeGrad.Rotation + dt * 50) % 360
end))

-- Drag manual (mendukung mouse & touch)
local function makeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    track(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
end

-- ==========================================
-- UI: BINTANG JATUH (arah & ekor sudah benar)
-- Bintang bergerak kiri-atas -> kanan-bawah, kepala terang di ujung depan, ekor memudar di belakang.
-- ==========================================
local starContainer = new("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    ZIndex = 1,
    Parent = main,
})

local function spawnStar(rng)
    local angle = math.rad(rng:NextNumber(32, 42))               -- sudut jatuh (derajat dari horizontal)
    local dir = Vector2.new(math.cos(angle), math.sin(angle))    -- arah gerak (kanan-bawah)
    local len = rng:NextInteger(90, 160)
    local start = Vector2.new(rng:NextNumber(-0.3 * WIN_W, 0.8 * WIN_W), -40)
    local travel = (WIN_H + 80) / dir.Y
    local finish = start + dir * travel
    local duration = travel / rng:NextNumber(300, 480)

    local star = new("Frame", {
        Size = UDim2.fromOffset(len, 2),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(start.X, start.Y),
        Rotation = math.deg(angle),                               -- sama dengan arah gerak
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 1,
        Parent = starContainer,
    })
    corner(star, 2)
    new("UIGradient", {
        -- kiri (ekor) ungu transparan -> kanan (kepala) putih terang
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 30, 210)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(200, 150, 255)),
            ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.6, 0.7),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Parent = star,
    })
    local head = new("Frame", {
        Size = UDim2.fromOffset(5, 5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(1, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = star,
    })
    corner(head, 3)

    TweenService:Create(star, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Position = UDim2.fromOffset(finish.X, finish.Y),
    }):Play()
    task.delay(duration + 0.1, function() star:Destroy() end)
end

task.spawn(function()
    local rng = Random.new()
    while uiAlive and main.Parent do
        task.wait(rng:NextNumber(0.35, 0.8))
        if main.Visible then spawnStar(rng) end
    end
end)

-- ==========================================
-- UI: HEADER
-- ==========================================
local header = new("Frame", {
    Size = UDim2.new(1, 0, 0, 46),
    BackgroundTransparency = 1,
    Active = true,
    ZIndex = 3,
    Parent = main,
})
makeDraggable(header, main)

local logo = new("TextLabel", {
    Size = UDim2.fromOffset(28, 28),
    Position = UDim2.fromOffset(14, 9),
    BackgroundColor3 = Color3.new(1, 1, 1),
    Text = "EX",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 12,
    Font = Enum.Font.GothamBlack,
    Parent = header,
})
corner(logo, 8)
new("UIGradient", { Color = ColorSequence.new(THEME.accent, Color3.fromRGB(70, 150, 255)), Rotation = 45, Parent = logo })

new("TextLabel", {
    Size = UDim2.new(1, -140, 0, 18),
    Position = UDim2.fromOffset(52, 7),
    BackgroundTransparency = 1,
    Text = "EX COMMUNITY",
    TextColor3 = THEME.text,
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = header,
})
new("TextLabel", {
    Size = UDim2.new(1, -140, 0, 14),
    Position = UDim2.fromOffset(52, 25),
    BackgroundTransparency = 1,
    Text = "Steal an Egg  •  " .. VERSION,
    TextColor3 = THEME.sub,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = header,
})

local function headerButton(text, xOffset, color)
    local b = new("TextButton", {
        Size = UDim2.fromOffset(26, 26),
        Position = UDim2.new(1, xOffset, 0.5, -13),
        BackgroundColor3 = color,
        BackgroundTransparency = 0.35,
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        Parent = header,
    })
    corner(b, 7)
    b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundTransparency = 0.05 }) end)
    b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundTransparency = 0.35 }) end)
    return b
end
local minBtn = headerButton("–", -68, THEME.warn)
local closeBtn = headerButton("X", -36, THEME.bad)

new("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.fromOffset(0, 46),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 0.88,
    BorderSizePixel = 0,
    ZIndex = 3,
    Parent = main,
})

local minIcon = new("TextButton", {
    Size = UDim2.fromOffset(46, 46),
    Position = UDim2.fromOffset(30, 30),
    BackgroundColor3 = Color3.fromRGB(24, 14, 40),
    BackgroundTransparency = 0.1,
    Text = "EX",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    Font = Enum.Font.GothamBlack,
    AutoButtonColor = false,
    Visible = false,
    Active = true,
    Parent = sg,
})
corner(minIcon, 14)
stroke(minIcon, THEME.accent, 2, 0)
makeDraggable(minIcon, minIcon)

-- ==========================================
-- UI: SIDEBAR (TAB) & KONTEN
-- ==========================================
local SIDEBAR_W = 124

local sidebar = new("Frame", {
    Size = UDim2.new(0, SIDEBAR_W, 1, -47),
    Position = UDim2.fromOffset(0, 47),
    BackgroundTransparency = 1,
    ZIndex = 3,
    Parent = main,
})
local tabList = new("Frame", {
    Size = UDim2.new(1, 0, 1, -30),
    BackgroundTransparency = 1,
    Parent = sidebar,
})
pad(tabList, 10, 10, 0, 10)
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabList })

new("TextLabel", {
    Size = UDim2.new(1, -16, 0, 22),
    Position = UDim2.new(0, 8, 1, -26),
    BackgroundTransparency = 1,
    Text = "RightShift = tampil/sembunyi",
    TextColor3 = THEME.sub,
    TextTransparency = 0.3,
    TextSize = 8,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
    Parent = sidebar,
})
new("Frame", {
    Size = UDim2.new(0, 1, 1, -47),
    Position = UDim2.fromOffset(SIDEBAR_W, 47),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 0.88,
    BorderSizePixel = 0,
    ZIndex = 3,
    Parent = main,
})

local content = new("Frame", {
    Size = UDim2.new(1, -(SIDEBAR_W + 2), 1, -48),
    Position = UDim2.fromOffset(SIDEBAR_W + 2, 48),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    ZIndex = 3,
    Parent = main,
})

local tabs = {}
local function selectTab(index)
    for i, t in ipairs(tabs) do
        local on = i == index
        tween(t.btn, 0.18, { BackgroundTransparency = on and 0.8 or 1 })
        tween(t.bar, 0.18, { BackgroundTransparency = on and 0 or 1 })
        tween(t.lbl, 0.18, { TextColor3 = on and Color3.new(1, 1, 1) or THEME.sub })
        t.page.Visible = on
        t.active = on
    end
end

local function createTab(name)
    local index = #tabs + 1
    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = THEME.accent,
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = index,
        Parent = tabList,
    })
    corner(btn, 8)
    local bar = new("Frame", {
        Size = UDim2.fromOffset(3, 16),
        Position = UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = THEME.accent2,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = btn,
    })
    corner(bar, 2)
    local lbl = new("TextLabel", {
        Size = UDim2.new(1, -22, 1, 0),
        Position = UDim2.fromOffset(16, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = THEME.sub,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = btn,
    })

    local page = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = THEME.accent,
        ScrollBarImageTransparency = 0.3,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        Parent = content,
    })
    pad(page, 10, 12, 14, 10)
    new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })

    local entry = { btn = btn, bar = bar, lbl = lbl, page = page, active = false }
    tabs[index] = entry

    btn.MouseEnter:Connect(function()
        if not entry.active then tween(btn, 0.12, { BackgroundTransparency = 0.92 }) end
    end)
    btn.MouseLeave:Connect(function()
        if not entry.active then tween(btn, 0.12, { BackgroundTransparency = 1 }) end
    end)
    btn.MouseButton1Click:Connect(function() selectTab(index) end)
    return page
end

-- ==========================================
-- UI: KOMPONEN
-- ==========================================
local orders = {}
local function nextOrder(parent)
    orders[parent] = (orders[parent] or 0) + 1
    return orders[parent]
end

local function card(parent, height)
    local c = new("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = THEME.card,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(parent),
        Parent = parent,
    })
    corner(c, 8)
    stroke(c, Color3.new(1, 1, 1), 1, 0.92)
    return c
end

local function section(parent, text)
    return new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = THEME.accent2,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = nextOrder(parent),
        Parent = parent,
    })
end

local function toggle(parent, title, desc, cb)
    local c = card(parent, desc and 50 or 40)
    new("TextLabel", {
        Size = UDim2.new(1, -74, 0, 18),
        Position = UDim2.fromOffset(12, desc and 7 or 11),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = THEME.text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = c,
    })
    if desc then
        new("TextLabel", {
            Size = UDim2.new(1, -74, 0, 14),
            Position = UDim2.fromOffset(12, 26),
            BackgroundTransparency = 1,
            Text = desc,
            TextColor3 = THEME.sub,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = c,
        })
    end
    local sw = new("Frame", {
        Size = UDim2.fromOffset(42, 22),
        Position = UDim2.new(1, -54, 0.5, -11),
        BackgroundColor3 = THEME.off,
        BorderSizePixel = 0,
        Parent = c,
    })
    corner(sw, 11)
    local knob = new("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.fromOffset(3, 3),
        BackgroundColor3 = Color3.fromRGB(200, 190, 225),
        BorderSizePixel = 0,
        Parent = sw,
    })
    corner(knob, 8)
    local hit = new("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 5,
        Parent = c,
    })

    local state = false
    local function set(v, silent)
        state = v
        tween(knob, 0.18, {
            Position = v and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
            BackgroundColor3 = v and Color3.new(1, 1, 1) or Color3.fromRGB(200, 190, 225),
        })
        tween(sw, 0.18, { BackgroundColor3 = v and THEME.accent or THEME.off })
        if not silent then cb(v) end
    end
    hit.MouseButton1Click:Connect(function() set(not state) end)
    return { Set = set, Get = function() return state end }
end

local function segmented(parent, options, default, cb)
    local c = card(parent, 38)
    local buttons = {}
    local n = #options
    local function paint(sel)
        for id, b in pairs(buttons) do
            local on = id == sel
            tween(b, 0.15, { BackgroundTransparency = on and 0.1 or 1 })
            b.TextColor3 = on and Color3.new(1, 1, 1) or THEME.sub
        end
    end
    for i, opt in ipairs(options) do
        local b = new("TextButton", {
            Size = UDim2.new(1 / n, -6, 1, -8),
            Position = UDim2.new((i - 1) / n, 3, 0, 4),
            BackgroundColor3 = THEME.accent,
            BackgroundTransparency = 1,
            Text = opt.label,
            TextColor3 = THEME.sub,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
            Parent = c,
        })
        corner(b, 6)
        buttons[opt.id] = b
        b.MouseButton1Click:Connect(function()
            paint(opt.id)
            cb(opt.id)
        end)
    end
    paint(default)
    return { Set = paint }
end

local function stepper(parent, title, minV, maxV, stepV, value, suffix, cb)
    local c = card(parent, 40)
    new("TextLabel", {
        Size = UDim2.new(1, -140, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = THEME.text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = c,
    })
    local val = new("TextLabel", {
        Size = UDim2.fromOffset(54, 26),
        Position = UDim2.new(1, -92, 0.5, -13),
        BackgroundTransparency = 1,
        Text = value .. suffix,
        TextColor3 = THEME.accent2,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Parent = c,
    })
    local function set(v)
        value = math.clamp(v, minV, maxV)
        val.Text = value .. suffix
        cb(value)
    end
    local function mk(text, xOffset, delta)
        local b = new("TextButton", {
            Size = UDim2.fromOffset(26, 26),
            Position = UDim2.new(1, xOffset, 0.5, -13),
            BackgroundColor3 = THEME.off,
            Text = text,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
            Parent = c,
        })
        corner(b, 7)
        b.MouseButton1Click:Connect(function() set(value + delta) end)
    end
    mk("-", -122, -stepV)
    mk("+", -36, stepV)
end

local function button(parent, text, color, cb)
    local b = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = color,
        BackgroundTransparency = 0.25,
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        LayoutOrder = nextOrder(parent),
        Parent = parent,
    })
    corner(b, 8)
    b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundTransparency = 0.05 }) end)
    b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundTransparency = 0.25 }) end)
    b.MouseButton1Click:Connect(cb)
    return b
end

-- ==========================================
-- UI: ISI TAB
-- ==========================================
local pageMain = createTab("Main")
local pageEvents = createTab("Events")
local pagePerf = createTab("Performance")
local pageDebug = createTab("Debug")

-- ---------- MAIN ----------
section(pageMain, "STATUS")
do
    local c = card(pageMain, 62)
    ui.statusDot = new("Frame", {
        Size = UDim2.fromOffset(10, 10),
        Position = UDim2.fromOffset(14, 13),
        BackgroundColor3 = THEME.sub,
        BorderSizePixel = 0,
        Parent = c,
    })
    corner(ui.statusDot, 5)
    ui.statusText = new("TextLabel", {
        Size = UDim2.new(1, -40, 0, 16),
        Position = UDim2.fromOffset(32, 10),
        BackgroundTransparency = 1,
        Text = "Idle",
        TextColor3 = THEME.text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = c,
    })
    ui.statsText = new("TextLabel", {
        Size = UDim2.new(1, -24, 0, 14),
        Position = UDim2.fromOffset(14, 30),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = THEME.sub,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = c,
    })
    ui.modeText = new("TextLabel", {
        Size = UDim2.new(1, -24, 0, 14),
        Position = UDim2.fromOffset(14, 44),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = THEME.sub,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = c,
    })
end

section(pageMain, "AUTO STEAL")
toggle(pageMain, "Auto Steal", "Mulai dari base / safe zone", function(on)
    config.running = on
    if on then
        local hrp = getHRP()
        if hrp then baseCFrame = hrp.CFrame + Vector3.new(0, 3, 0) end
        startAutoSteal()
    else
        loopToken += 1
        setStatus("Idle", THEME.sub)
    end
end)
toggle(pageMain, "Mode Teleport Instan", "Mati = terbang (lebih aman)", function(on)
    config.method = on and "Instant" or "Fly"
    refreshStats()
end)

section(pageMain, "MODE TARGET")

-- Filter (dibuat dulu supaya bisa di-toggle oleh segmented)
local filterBox
local chipButtons = {}
local function refreshChips()
    for value, b in pairs(chipButtons) do
        local on = config.filterValue == value
        b.BackgroundColor3 = on and THEME.accent or THEME.off
        b.BackgroundTransparency = on and 0 or 0.25
        b.TextColor3 = on and Color3.new(1, 1, 1) or THEME.sub
    end
    if ui.filterLabel then
        ui.filterLabel.Text = "Filter aktif: " .. (config.filterValue or "-")
    end
    refreshStats()
end

segmented(pageMain, {
    { id = "All", label = "Steal All" },
    { id = "Filter", label = "Steal by Filter" },
}, "All", function(id)
    config.targetMode = id
    if filterBox then filterBox.Visible = id == "Filter" end
    refreshStats()
end)

filterBox = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    Visible = false,
    LayoutOrder = nextOrder(pageMain),
    Parent = pageMain,
})
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = filterBox })

do
    local c = card(filterBox, 32)
    ui.filterLabel = new("TextLabel", {
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        Text = "Filter aktif: -",
        TextColor3 = THEME.text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = c,
    })
    local reset = new("TextButton", {
        Size = UDim2.fromOffset(56, 22),
        Position = UDim2.new(1, -64, 0.5, -11),
        BackgroundColor3 = THEME.off,
        Text = "Reset",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        Parent = c,
    })
    corner(reset, 6)
    reset.MouseButton1Click:Connect(function()
        config.filterValue = nil
        refreshChips()
    end)
end

local FILTERS = {
    { "Size", { "Small", "Medium", "Large", "Giant" } },
    { "Rarity", { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Cosmic", "Eternal", "Divine" } },
    { "Variant", { "Normal", "Golden", "Rainbow", "Dark" } },
}

for _, cat in ipairs(FILTERS) do
    local catName, opts = cat[1], cat[2]
    local block = new("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = THEME.card,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(filterBox),
        Parent = filterBox,
    })
    corner(block, 8)
    stroke(block, Color3.new(1, 1, 1), 1, 0.92)
    new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = block })

    local head = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Text = "  + " .. catName,
        TextColor3 = THEME.text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        Parent = block,
    })
    local chips = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = false,
        LayoutOrder = 2,
        Parent = block,
    })
    pad(chips, 2, 8, 8, 8)
    new("UIGridLayout", {
        CellSize = UDim2.new(1 / 3, -6, 0, 26),
        CellPadding = UDim2.fromOffset(6, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = chips,
    })
    for i, opt in ipairs(opts) do
        local chip = new("TextButton", {
            BackgroundColor3 = THEME.off,
            BackgroundTransparency = 0.25,
            Text = opt,
            TextColor3 = THEME.sub,
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            AutoButtonColor = false,
            LayoutOrder = i,
            Parent = chips,
        })
        corner(chip, 6)
        chipButtons[opt] = chip
        chip.MouseButton1Click:Connect(function()
            config.filterValue = (config.filterValue == opt) and nil or opt
            refreshChips()
        end)
    end
    local open = false
    head.MouseButton1Click:Connect(function()
        open = not open
        chips.Visible = open
        head.Text = (open and "  - " or "  + ") .. catName
    end)
end

section(pageMain, "PENGATURAN TERBANG")
stepper(pageMain, "Kecepatan", 30, 200, 10, config.flySpeed, " st/s", function(v) config.flySpeed = v end)
stepper(pageMain, "Ketinggian", 4, 40, 2, config.flyHeight, " st", function(v) config.flyHeight = v end)

-- ---------- EVENTS ----------
section(pageEvents, "EVENT")
toggle(pageEvents, "Auto Farm Boss / Event", "Teleport ke boss lalu serang", function(on)
    config.eventRunning = on
    if on then startBossLoop() end
end)

-- ---------- PERFORMANCE ----------
section(pagePerf, "RENDER")
toggle(pagePerf, "Disable 3D (Layar Putih)", "Hemat GPU / baterai", function(on)
    whiteScreen.Visible = on
    pcall(function() RunService:Set3dRenderingEnabled(not on) end)
end)
toggle(pagePerf, "Anti-Lag Efek", "Matikan partikel, trail, beam", function(on)
    setAntiLag(on)
end)
section(pagePerf, "PERMANEN (SAMPAI REJOIN)")
toggle(pagePerf, "Super FPS Boost", "Grafik kentang, bayangan mati", function(on)
    if not on then return end
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            end
        end
    end)
end)
toggle(pagePerf, "Hapus Plot, Pet & Pohon", "Jangan aktif bersama Auto Steal", function(on)
    if not on then return end
    pcall(function()
        for _, v in ipairs(Workspace:GetDescendants()) do
            if not isEggRelated(v) then
                local n = v.Name:lower()
                if v:IsA("Model") and (n:find("pet", 1, true) or n:find("guardian", 1, true)) and not Players:GetPlayerFromCharacter(v) then
                    v:Destroy()
                elseif v:IsA("BasePart") and (n:find("plot", 1, true) or n:find("tree", 1, true)) then
                    v:Destroy()
                end
            end
        end
    end)
end)

-- ---------- DEBUG ----------
section(pageDebug, "LOG")
do
    local c = card(pageDebug, 180)
    ui.logScroll = new("ScrollingFrame", {
        Size = UDim2.new(1, -12, 1, -12),
        Position = UDim2.fromOffset(6, 6),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Parent = c,
    })
    ui.logLabel = new("TextLabel", {
        Size = UDim2.new(1, -6, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = THEME.text,
        TextSize = 10,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = ui.logScroll,
    })
end

section(pageDebug, "ALAT")
button(pageDebug, "Scan Telur Sekarang", THEME.accent, function()
    local folder = Workspace:FindFirstChild("AreaEggSlotsClient")
    log("AreaEggSlotsClient: " .. (folder and ("ada (" .. #folder:GetChildren() .. " anak)") or "TIDAK ADA"))
    local prompts = collectEggPrompts()
    log("Prompt telur ditemukan: " .. #prompts)
    local hrp = getHRP()
    for i, p in ipairs(prompts) do
        if i > 8 then
            log("... +" .. (#prompts - 8) .. " lainnya")
            break
        end
        local pos = getPromptPosition(p)
        local d = (pos and hrp) and math.floor((pos - hrp.Position).Magnitude) or -1
        log(("[%d] %s | aksi='%s' | on=%s | milikku=%s | jarak=%d"):format(
            i, p:GetFullName(), p.ActionText, tostring(p.Enabled), tostring(ownedByMe(p)), d))
    end
    log("fireproximityprompt: " .. (typeof(fireproximityprompt) == "function" and "tersedia" or "TIDAK tersedia"))
end)
button(pageDebug, "Print Posisi Saya", THEME.off, function()
    local hrp = getHRP()
    if hrp then
        local p = hrp.Position
        log(("Posisi: Vector3.new(%d, %d, %d)"):format(p.X, p.Y, p.Z))
    else
        log("Karakter tidak ditemukan")
    end
end)
button(pageDebug, "Bersihkan Log", THEME.off, function()
    table.clear(logLines)
    ui.logLabel.Text = ""
end)

-- ==========================================
-- UI: KONTROL WINDOW
-- ==========================================
local function setWindowVisible(v)
    main.Visible = v
    minIcon.Visible = not v
end

minBtn.MouseButton1Click:Connect(function() setWindowVisible(false) end)
minIcon.MouseButton1Click:Connect(function() setWindowVisible(true) end)
track(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        setWindowVisible(not main.Visible)
    end
end))

local function cleanup()
    uiAlive = false
    config.running = false
    config.eventRunning = false
    config.perfAnti = false
    loopToken += 1
    for _, c in ipairs(connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(connections)
    pcall(function() RunService:Set3dRenderingEnabled(true) end)
    if sg then sg:Destroy() end
end
_G.EX_STEAL_EGG_CLEANUP = cleanup
closeBtn.MouseButton1Click:Connect(cleanup)

-- ==========================================
-- START
-- ==========================================
selectTab(1)
refreshStats()
setStatus("Idle", THEME.sub)
log("EX Steal an Egg " .. VERSION .. " siap")
log("Jika masih gagal, buka tab Debug lalu tekan 'Scan Telur Sekarang'")
