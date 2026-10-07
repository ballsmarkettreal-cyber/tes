--[[
    EX COMMUNITY | STEAL AN EGG  -  V23
    Daftar perubahan dari V22:
      * Auto Steal: telur dengan prompt nonaktif tidak lagi dibuang (penyebab "tidak menemukan telur"
        padahal ada 65 telur). Prompt dipaksa aktif saat sudah di dekat telur.
      * Filter multi-pilih (Size / Rarity / Variant) + Filter Area (13 biome)
      * Ping panel, Anti Knockback, Anti Trapped, Anti-AFK
      * Treadmill saat idle + pembersih popup "+speed" (anti lag)
      * Tab Automation (Hatch, Place + filter, Fuse, Claim Index)
      * Tab Shop (buka shop event), tab Events (semua event aktif), tab Webhook (Discord)
      * FPS Boost menghapus semua plot orang lain (plot milik sendiri tetap ada)
      * Tab Debug diperluas: scan telur / UI / prompt / remote / stats

    CATATAN: bagian yang bergantung pada nama objek di dalam game (event, hatch, place, fuse, index,
    shop, treadmill, stats) memakai deteksi kata kunci. Edit tabel HINTS / EVENT_DEFS / SHOPS di bawah
    kalau nama di game berbeda. Gunakan tab Debug untuk melihat nama aslinya.
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

local VERSION = "V23"
local SAVE_FILE = "EX_StealAnEgg_V23.json"
local BASE_RADIUS = 140   -- radius (stud) dari base untuk mencari prompt place/hatch/fuse milik sendiri

-- ==========================================
-- HINTS (kata kunci deteksi) - edit jika nama di game berbeda
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

local FILTERS = {
    { "Size", { "Small", "Medium", "Large", "Giant" } },
    { "Rarity", { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Cosmic", "Eternal", "Divine" } },
    { "Variant", { "Normal", "Golden", "Rainbow", "Dark" } },
}

-- Event yang aktif per 8 Okt 2026 (sumber: wiki & portal berita game)
local EVENT_DEFS = {
    { id = "scramble", name = "Dr. Scramble Mecha & Drone", desc = "Boss tiap 30 mnt, drop Samples",
      keywords = { "scramble", "mecha", "drone" }, mode = "attack", tool = "bat" },
    { id = "rift", name = "Rift & Overlord", desc = "Tiap 30 mnt, drop Boss Tokens",
      keywords = { "overlord", "rift" }, mode = "attack", tool = "bat" },
    { id = "greatbloom", name = "Great Bloom", desc = "Tiap 30 mnt",
      keywords = { "greatbloom", "great bloom" }, mode = "collect" },
    { id = "butterfly", name = "Butterfly Bloom (Enchanted)", desc = "Tangkap kupu-kupu (butuh Butterfly Net)",
      keywords = { "butterfly" }, mode = "collect", tool = "net" },
    { id = "frog", name = "Hungry Frog (parasit)", desc = "5 parasit = Monster Chest",
      keywords = { "parasite", "hungryfrog", "frog" }, mode = "collect" },
    { id = "angdem", name = "Angels vs Demons (ring)", desc = "Kumpulkan ring tim",
      keywords = { "ring" }, mode = "touch" },
    { id = "admin", name = "Admin Abuse (Sammy)", desc = "Event admin mingguan (Sabtu)",
      keywords = { "sammy" }, mode = "attack", tool = "bat" },
}

-- Shop yang berlaku per 8 Okt 2026. gui = kata kunci tombol HUD, world = kata kunci objek di map
local SHOPS = {
    { name = "Shop Utama", info = "Featured: Extinction Egg (Robux) sampai 10 Okt 2026",
      gui = { "shop" }, world = { "shop" } },
    { name = "Experiment Shop (Samples)", info = "Booster, mutasi Scrambled, Experiment Egg. Ada di bawah menu pet",
      gui = { "experiment" }, world = { "experiment" } },
    { name = "Dr. Scramble's Lab", info = "Tukar 3 egg jadi pet eksperimen (pengganti Rift altar)",
      gui = { "laboratory", "lab" }, world = { "laboratory", "lab" } },
    { name = "Boss Shop (Boss Tokens)", info = "Hadiah dari Rift / Overlord",
      gui = { "boss shop", "bossshop" }, world = { "bossshop", "boss shop" } },
}

-- ==========================================
-- TEMA
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

-- ==========================================
-- UTIL DASAR
-- ==========================================
local function listToSet(list)
    local s = {}
    for _, v in ipairs(list or {}) do s[v] = true end
    return s
end

local function setToList(set)
    local l = {}
    for k, on in pairs(set) do
        if on then table.insert(l, k) end
    end
    table.sort(l)
    return l
end

local function norm(s)
    return (tostring(s):lower():gsub("[^%w]", ""))
end

local function abbr(n)
    n = tonumber(n)
    if not n then return "?" end
    local units = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }
    local i = 1
    while math.abs(n) >= 1000 and i < #units do
        n = n / 1000
        i += 1
    end
    if i == 1 then return ("%.0f"):format(n) end
    return ("%.2f%s"):format(n, units[i])
end

-- cocokkan kata di awal "kata" (mendukung CamelCase), contoh: "ring" cocok "RingPickup" tapi tidak "Spring"
local function nameHas(name, kw)
    local lname = name:lower()
    kw = kw:lower()
    local init = 1
    while true do
        local s = lname:find(kw, init, true)
        if not s then return false end
        local prev = name:sub(s - 1, s - 1)
        local cur = name:sub(s, s)
        if s == 1 or not prev:match("%a") or (prev:match("%l") and cur:match("%u")) then
            return true
        end
        init = s + 1
    end
end

local function nameHasAny(name, list)
    for _, k in ipairs(list) do
        if nameHas(name, k) then return true end
    end
    return false
end

-- ==========================================
-- PENYIMPANAN SETTING
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
    if type(arr) == "table" and #arr == 3 then
        areaCenters[name] = Vector3.new(arr[1], arr[2], arr[3])
    end
end

local config = {
    running = false,          -- auto steal
    treadmillIdle = false,
    method = "Fly",           -- "Fly" | "Instant"
    targetMode = "All",       -- "All" | "Filter"
    filters = newFilterSet("filters"),
    placeFilters = newFilterSet("placeFilters"),
    areas = listToSet(S("areas", {})),
    skipOwn = true,
    flySpeed = S("flySpeed", 90),
    flyHeight = S("flyHeight", 12),
    antiKB = S("antiKB", false),
    antiTrap = S("antiTrap", false),
    antiAfk = S("antiAfk", true),
    pingPanel = S("pingPanel", true),
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
local sg  -- ScreenGui, dibuat di bagian UI

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
        pingPanel = config.pingPanel,
        removePopups = config.removePopups,
        autoInterval = config.autoInterval,
        eggWebhookUrl = config.eggWebhookUrl,
        statsWebhookUrl = config.statsWebhookUrl,
        statsIntervalMin = config.statsIntervalMin,
        areaCenters = centers,
    }
    pcall(writefile, SAVE_FILE, HttpService:JSONEncode(data))
end

local saveQueued = false
local function markDirty()
    if saveQueued then return end
    saveQueued = true
    task.delay(1, function()
        saveQueued = false
        saveSettings()
    end)
end

-- ==========================================
-- LOG & STATUS
-- ==========================================
local logLines = {}
local function log(msg)
    msg = os.date("%H:%M:%S") .. "  " .. tostring(msg)
    table.insert(logLines, msg)
    if #logLines > 80 then table.remove(logLines, 1) end
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
        local target = config.targetMode == "All" and "Semua" or "Filter"
        local areaCount = 0
        for _ in pairs(config.areas) do areaCount += 1 end
        ui.modeText.Text = ("Gerak: %s   Target: %s   Area: %s"):format(move, target, areaCount > 0 and (areaCount .. " dipilih") or "semua")
    end
end

-- ==========================================
-- HELPER KARAKTER, POSISI, PROMPT
-- ==========================================
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

-- ProximityPrompt sering ada di Attachment/Model, bukan di Part
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

-- Snapshot descendants Workspace (di-cache 1.5 detik supaya tidak berat)
local Snapshot = { t = 0, list = {} }
function Snapshot.get()
    if os.clock() - Snapshot.t > 1.5 then
        Snapshot.list = Workspace:GetDescendants()
        Snapshot.t = os.clock()
    end
    return Snapshot.list
end

local function promptText(p)
    return (p.Name .. " " .. (p.ActionText or "") .. " " .. (p.ObjectText or "")):lower()
end

local function promptMatches(p, kws)
    local t = promptText(p)
    for _, k in ipairs(kws) do
        if t:find(k, 1, true) then return true end
    end
    return false
end

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
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(0.05)
        prompt:InputHoldEnd()
    end)
    return ok
end

local function firePromptsNear(pos, radius, kws)
    local count = 0
    for _, p in ipairs(Snapshot.get()) do
        if p:IsA("ProximityPrompt") and p.Parent and p.Enabled then
            local pp = getPromptPosition(p)
            if pp and (pp - pos).Magnitude <= radius and (not kws or promptMatches(p, kws)) then
                if triggerPrompt(p) then count += 1 end
            end
        end
    end
    return count
end

-- ==========================================
-- HELPER GUI GAME (tombol HUD)
-- ==========================================
local function guiVisible(obj)
    local cur = obj
    while cur and cur ~= playerGui do
        if cur:IsA("GuiObject") and not cur.Visible then return false end
        if cur:IsA("ScreenGui") and not cur.Enabled then return false end
        cur = cur.Parent
    end
    return true
end

local function buttonLabel(btn)
    local t = ""
    if btn:IsA("TextButton") then t = btn.Text end
    if t == "" then
        for _, d in ipairs(btn:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text ~= "" then
                t = d.Text
                break
            end
        end
    end
    return t
end

local function findButtons(keywords, exact)
    local found = {}
    for _, d in ipairs(playerGui:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("ImageButton")) and not (sg and d:IsDescendantOf(sg)) and guiVisible(d) then
            local lab = buttonLabel(d):lower()
            local nm = d.Name:lower()
            for _, k in ipairs(keywords) do
                if exact then
                    if lab == k or nm == k then
                        table.insert(found, d)
                        break
                    end
                elseif lab:find(k, 1, true) or nm:find(k, 1, true) then
                    table.insert(found, d)
                    break
                end
            end
        end
    end
    return found
end

-- tidak pernah mengklik tombol pembelian
local function clickButton(btn)
    local label = (buttonLabel(btn) .. " " .. btn.Name):lower()
    if label:find("buy", 1, true) or label:find("purchase", 1, true) or label:find("robux", 1, true) or label:find("r$", 1, true) then
        return false
    end
    local clicked = false
    if typeof(firesignal) == "function" then
        pcall(firesignal, btn.MouseButton1Click)
        pcall(firesignal, btn.Activated)
        clicked = true
    elseif typeof(getconnections) == "function" then
        pcall(function()
            for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
        end)
        clicked = true
    end
    if not clicked and VirtualInputManager then
        local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
        local inset = GuiService:GetGuiInset()
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y + inset.Y, 0, true, game, 0)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y + inset.Y, 0, false, game, 0)
        end)
        clicked = true
    end
    return clicked
end

local function clickFirstMatching(keys)
    for _, k in ipairs(keys) do
        local btns = findButtons({ k }, false)
        for _, b in ipairs(btns) do
            if clickButton(b) then return true end
        end
    end
    return false
end

local function equipTool(kw)
    local hrp, hum, char = getChar()
    if not char or not hum then return nil end
    local function match(t)
        if not t:IsA("Tool") then return false end
        local n = t.Name:lower()
        if kw then return n:find(kw, 1, true) ~= nil end
        return not n:find("egg", 1, true)
    end
    for _, t in ipairs(char:GetChildren()) do
        if match(t) then return t end
    end
    for _, t in ipairs(player.Backpack:GetChildren()) do
        if match(t) then
            pcall(function() hum:EquipTool(t) end)
            task.wait(0.15)
            return t
        end
    end
    return nil
end

-- ==========================================
-- LOCK GERAK (supaya steal, event, automation tidak saling rebutan karakter)
-- ==========================================
local Lock = { queue = {}, held = false }
function Lock.acquire()
    local ticket = {}
    table.insert(Lock.queue, ticket)
    while uiAlive and (Lock.held or Lock.queue[1] ~= ticket) do
        task.wait(0.1)
    end
    local idx = table.find(Lock.queue, ticket)
    if idx then table.remove(Lock.queue, idx) end
    Lock.held = true
end
function Lock.release()
    Lock.held = false
end
function Lock.run(fn)
    Lock.acquire()
    local ok, err = pcall(fn)
    Lock.release()
    return ok, err
end

-- ==========================================
-- PROTEKSI: ANTI KNOCKBACK, ANTI TRAPPED, ANTI AFK
-- ==========================================
local Protect = { lastWalk = 16, flying = false, treadmillActive = false }
local BODY_MOVERS = {
    BodyVelocity = true, BodyPosition = true, BodyForce = true, BodyThrust = true,
    BodyAngularVelocity = true, LinearVelocity = true, VectorForce = true, LineForce = true,
}

function Protect.bindChar(char)
    if Protect.charConn then Protect.charConn:Disconnect() end
    Protect.charConn = char.DescendantAdded:Connect(function(d)
        if config.antiKB and not Protect.treadmillActive and BODY_MOVERS[d.ClassName] then
            task.defer(function() pcall(function() d:Destroy() end) end)
        end
    end)
end
track(player.CharacterAdded:Connect(Protect.bindChar))
if player.Character then Protect.bindChar(player.Character) end

function Protect.unstick(hrp)
    hrp.CFrame = hrp.CFrame + Vector3.new(0, 10, 0)
    hrp.AssemblyLinearVelocity = Vector3.zero
    local _, hum = getChar()
    if hum then
        hum.PlatformStand = false
        hum.Sit = false
    end
end

local protectAccum = 0
track(RunService.Heartbeat:Connect(function(dt)
    if not (config.antiKB or config.antiTrap) then return end
    local hrp, hum, char = getChar()
    if not hrp or not hum then return end

    if config.antiKB and not Protect.flying and not Protect.treadmillActive then
        local v = hrp.AssemblyLinearVelocity
        local horiz = Vector3.new(v.X, 0, v.Z)
        local allowed = math.max(hum.WalkSpeed, 16) * 1.6 + 10
        if horiz.Magnitude > allowed then
            local lim = horiz.Unit * allowed
            hrp.AssemblyLinearVelocity = Vector3.new(lim.X, math.min(v.Y, 80), lim.Z)
        elseif v.Y > 90 then
            hrp.AssemblyLinearVelocity = Vector3.new(v.X, 90, v.Z)
        end
    end

    protectAccum += dt
    if protectAccum < 0.25 then return end
    protectAccum = 0

    if config.antiKB then
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end

    if config.antiTrap then
        if hrp.Anchored then hrp.Anchored = false end
        if hum.PlatformStand then hum.PlatformStand = false end
        if hum.Sit then hum.Sit = false end
        if hum.WalkSpeed > 1 then
            Protect.lastWalk = hum.WalkSpeed
        else
            hum.WalkSpeed = Protect.lastWalk
        end
        for _, d in ipairs(char:GetDescendants()) do
            if not d:IsA("Tool") and not d:IsA("Accessory") and nameHasAny(d.Name, HINTS.trap) then
                pcall(function() d:Destroy() end)
            elseif d:IsA("JointInstance") or d:IsA("WeldConstraint") then
                local other
                if d.Part0 and not d.Part0:IsDescendantOf(char) then
                    other = d.Part0
                elseif d.Part1 and not d.Part1:IsDescendantOf(char) then
                    other = d.Part1
                end
                if other and nameHasAny(other:GetFullName(), HINTS.trap) then
                    pcall(function() d:Destroy() end)
                end
            end
        end
    end
end))

track(player.Idled:Connect(function()
    if config.antiAfk then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end))

-- ==========================================
-- DETEKSI TELUR
-- ==========================================
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

-- "Milik sendiri" hanya jika ada penanda pemilik yang jelas
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

local function collectAncestorText(inst)
    local parts = {}
    local cur = inst
    while cur and cur ~= Workspace do
        table.insert(parts, cur.Name:lower())
        for k, v in pairs(cur:GetAttributes()) do
            if type(v) == "string" then
                table.insert(parts, tostring(k):lower() .. ":" .. v:lower())
            end
        end
        cur = cur.Parent
    end
    return table.concat(parts, " ")
end

local function detectAreaFromText(normText)
    for _, entry in ipairs(AREA_DETECT) do
        for _, key in ipairs(entry[2]) do
            if normText:find(key, 1, true) then return entry[1] end
        end
    end
    return nil
end

local function nearestAreaByCenter(pos)
    local count, best, bestD = 0, nil, math.huge
    for name, c in pairs(areaCenters) do
        count += 1
        local d = (c - pos).Magnitude
        if d < bestD then
            best, bestD = name, d
        end
    end
    if count >= 2 then return best end
    return nil
end

local function matchesValue(root, text, key)
    key = key:lower()
    if key == "normal" then
        return not (text:find("golden", 1, true) or text:find("rainbow", 1, true) or text:find("dark", 1, true))
    end
    if key == "common" then
        text = (text:gsub("uncommon", ""))
    end
    if text:find(key, 1, true) then return true end
    if root and root:IsA("Model") and (key == "small" or key == "medium" or key == "large" or key == "giant") then
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

local function hasAnyFilter(filters)
    for _, cat in ipairs({ "Size", "Rarity", "Variant" }) do
        if next(filters[cat]) ~= nil then return true end
    end
    return false
end

-- AND antar kategori, OR di dalam kategori
local function passesFilters(root, text, filters)
    for _, cat in ipairs({ "Size", "Rarity", "Variant" }) do
        local set = filters[cat]
        if next(set) ~= nil then
            local ok = false
            for key, on in pairs(set) do
                if on and matchesValue(root, text, key) then
                    ok = true
                    break
                end
            end
            if not ok then return false end
        end
    end
    return true
end

local banned = {}
local lastNoTargetLog = 0

local function findTarget(hrp, silent)
    local c = { total = 0, mine = 0, filtered = 0, area = 0, nopos = 0, banned = 0, off = 0 }
    local best
    local filterOn = config.targetMode == "Filter" and hasAnyFilter(config.filters)
    local areaOn = next(config.areas) ~= nil

    for _, prompt in ipairs(collectEggPrompts()) do
        c.total += 1
        local pos = getPromptPosition(prompt)
        if not pos then
            c.nopos += 1
        elseif banned[prompt] and banned[prompt] > os.clock() then
            c.banned += 1
        elseif config.skipOwn and ownedByMe(prompt) then
            c.mine += 1
        else
            local root = getEggRoot(prompt)
            local text = (filterOn or areaOn) and collectEggText(root) or nil
            local area = nil
            local pass = true
            if areaOn then
                area = detectAreaFromText(norm(collectAncestorText(prompt) .. " " .. text)) or nearestAreaByCenter(pos)
                if not area or not config.areas[area] then
                    c.area += 1
                    pass = false
                end
            end
            if pass and filterOn and not passesFilters(root, text, config.filters) then
                c.filtered += 1
                pass = false
            end
            if pass then
                local enabled = prompt.Enabled
                if not enabled then c.off += 1 end
                local d = (pos - hrp.Position).Magnitude
                if not best or (enabled and not best.enabled) or (enabled == best.enabled and d < best.dist) then
                    best = { prompt = prompt, pos = pos, dist = d, enabled = enabled, root = root, area = area }
                end
            end
        end
    end

    if best and not best.area then
        best.area = detectAreaFromText(norm(collectAncestorText(best.prompt))) or nearestAreaByCenter(best.pos)
    end

    if not best and not silent and os.clock() - lastNoTargetLog > 3 then
        lastNoTargetLog = os.clock()
        log(("Tidak ada target | prompt %d | milik sendiri %d | filter %d | area %d | tanpa posisi %d | diblok %d")
            :format(c.total, c.mine, c.filtered, c.area, c.nopos, c.banned))
        if c.total > 0 and c.mine == c.total then
            log("Semua telur dianggap milik sendiri. Matikan 'Lewati telur milik sendiri' di tab Main.")
        end
    end
    return best, c
end

-- ==========================================
-- GERAK
-- ==========================================
local function flyToInner(hrp, targetPos, speed, alive)
    local lastPos, lastT, stalls = hrp.Position, os.clock(), 0
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

        -- deteksi macet (anti trapped): tidak bergerak > 1.2 detik
        if os.clock() - lastT > 1.2 then
            if (hrp.Position - lastPos).Magnitude < 1 then
                stalls += 1
                Protect.unstick(hrp)
                if stalls >= 3 then return false end
            else
                stalls = 0
            end
            lastPos, lastT = hrp.Position, os.clock()
        end
    end
    return true
end

local function flyTo(hrp, targetPos, speed, alive)
    Protect.flying = true
    local ok = flyToInner(hrp, targetPos, speed, alive)
    Protect.flying = false
    return ok
end

local function goTo(hrp, targetPos, alive)
    if config.method == "Instant" then
        hrp.CFrame = CFrame.new(targetPos)
        hrp.AssemblyLinearVelocity = Vector3.zero
        task.wait(0.2)
        return true
    end
    local speed = config.flySpeed
    if (hrp.Position - targetPos).Magnitude < 15 then
        return flyTo(hrp, targetPos, speed, alive)
    end
    local cruiseY = math.max(hrp.Position.Y, targetPos.Y) + config.flyHeight
    if not flyTo(hrp, Vector3.new(hrp.Position.X, cruiseY, hrp.Position.Z), speed, alive) then return false end
    if not flyTo(hrp, Vector3.new(targetPos.X, cruiseY, targetPos.Z), speed, alive) then return false end
    return flyTo(hrp, targetPos, speed, alive)
end

-- ==========================================
-- WEBHOOK DISCORD
-- ==========================================
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

local function validWebhook(url)
    if type(url) ~= "string" then return false end
    return url:match("^https://[%w%.]*discord%.com/api/webhooks/") ~= nil
        or url:match("^https://[%w%.]*discordapp%.com/api/webhooks/") ~= nil
end

local function postWebhook(url, payload)
    if not validWebhook(url) then return false, "URL webhook tidak valid" end
    if not httpRequest then return false, "executor tidak punya fungsi request" end
    local ok, res = pcall(httpRequest, {
        Url = url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(payload),
    })
    if not ok then return false, tostring(res) end
    local code = res and (res.StatusCode or res.status_code)
    if code and code >= 200 and code < 300 then return true end
    return false, "HTTP " .. tostring(code)
end

local webhookQueue = {}
local webhookWorker = false
local function queueWebhook(url, payload)
    table.insert(webhookQueue, { url = url, payload = payload })
    if webhookWorker then return end
    webhookWorker = true
    task.spawn(function()
        while #webhookQueue > 0 and uiAlive do
            local item = table.remove(webhookQueue, 1)
            local ok, err = postWebhook(item.url, item.payload)
            if not ok then log("Webhook gagal: " .. tostring(err)) end
            task.wait(1.3)
        end
        webhookWorker = false
    end)
end

local function cut(s, n)
    s = tostring(s)
    if #s > n then return s:sub(1, n - 3) .. "..." end
    return s
end

local function embedPayload(title, color, fields)
    return {
        username = "EX Steal an Egg",
        embeds = { {
            title = title,
            color = color,
            fields = fields,
            footer = { text = "EX COMMUNITY • " .. VERSION },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        } },
    }
end

local function describeEgg(root)
    if not root then return { name = "Telur", detail = "" } end
    local parts = {}
    for k, v in pairs(root:GetAttributes()) do
        table.insert(parts, tostring(k) .. ": " .. tostring(v))
    end
    table.sort(parts)
    while #parts > 8 do table.remove(parts) end
    return { name = root.Name, detail = table.concat(parts, "\n") }
end

local function sendEggWebhook(info)
    if not config.eggWebhookOn then return end
    queueWebhook(config.eggWebhookUrl, embedPayload("🥚 Telur didapat", 0x8B5CF6, {
        { name = "Telur", value = cut(info.name, 200), inline = true },
        { name = "Area", value = info.area or "-", inline = true },
        { name = "Pemain", value = player.DisplayName, inline = true },
        { name = "Detail", value = info.detail ~= "" and cut(info.detail, 900) or "-", inline = false },
        { name = "Total sesi", value = ("%d berhasil / %d gagal"):format(stats.stolen, stats.failed), inline = true },
    }))
end

-- membaca Speed & Uang (deteksi: leaderstats, atribut pemain, label HUD)
local function findStatValue(names, textMustHave)
    local ls = player:FindFirstChild("leaderstats")
    if ls then
        for _, v in ipairs(ls:GetChildren()) do
            local n = v.Name:lower()
            for _, nm in ipairs(names) do
                if n:find(nm, 1, true) and v:IsA("ValueBase") then return v.Value, "leaderstats." .. v.Name end
            end
        end
    end
    for k, v in pairs(player:GetAttributes()) do
        local n = tostring(k):lower()
        for _, nm in ipairs(names) do
            if n:find(nm, 1, true) then return v, "attribute " .. tostring(k) end
        end
    end
    for _, d in ipairs(playerGui:GetDescendants()) do
        if d:IsA("TextLabel") and not (sg and d:IsDescendantOf(sg)) and d.Text ~= "" then
            local n = d.Name:lower()
            for _, nm in ipairs(names) do
                if n:find(nm, 1, true) and (not textMustHave or d.Text:find(textMustHave, 1, true)) then
                    return d.Text, "HUD " .. d.Name
                end
            end
        end
    end
    return nil, nil
end

local function readStats()
    local speed, speedSrc = findStatValue({ "speed" }, nil)
    if speed == nil then
        local _, hum = getChar()
        if hum then speed, speedSrc = hum.WalkSpeed, "WalkSpeed" end
    end
    local money, moneySrc = findStatValue({ "cash", "money", "coin" }, "$")
    if money == nil then money, moneySrc = findStatValue({ "cash", "money", "coin" }, nil) end
    local function fmt(v)
        if v == nil then return "tidak terbaca" end
        if type(v) == "number" then return abbr(v) end
        return tostring(v)
    end
    return { speed = fmt(speed), speedSrc = speedSrc or "-", money = fmt(money), moneySrc = moneySrc or "-" }
end

local function currentPing()
    local ping = 0
    pcall(function() ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
    return ping
end

local function sendStatsWebhook(force)
    if not force and not config.statsWebhookOn then return end
    local s = readStats()
    local up = math.floor((os.clock() - sessionStart) / 60)
    queueWebhook(config.statsWebhookUrl, embedPayload("📊 Laporan AFK", 0x4ADE80, {
        { name = "Speed", value = s.speed, inline = true },
        { name = "Uang", value = s.money, inline = true },
        { name = "Ping", value = currentPing() .. " ms", inline = true },
        { name = "Telur", value = ("%d berhasil / %d gagal"):format(stats.stolen, stats.failed), inline = true },
        { name = "Durasi sesi", value = up .. " menit", inline = true },
        { name = "Pemain", value = player.DisplayName, inline = true },
    }))
end

local statsToken = 0
local function startStatsLoop()
    statsToken += 1
    local my = statsToken
    task.spawn(function()
        local last = os.clock()
        while uiAlive and config.statsWebhookOn and statsToken == my do
            task.wait(1)
            if os.clock() - last >= config.statsIntervalMin * 60 then
                last = os.clock()
                sendStatsWebhook(false)
            end
        end
    end)
end

-- ==========================================
-- TREADMILL & PEMBERSIH POPUP "+SPEED"
-- ==========================================
local brainWanted  -- didefinisikan di bawah

local Treadmill = { inst = nil, notified = false }

local function treadmillSpot(inst)
    if inst:IsA("BasePart") then
        return inst.Position + Vector3.new(0, inst.Size.Y / 2 + 3, 0)
    end
    local ok, cf, size = pcall(function() return inst:GetBoundingBox() end)
    if ok then return cf.Position + Vector3.new(0, size.Y / 2 + 3, 0) end
    local p = getInstPosition(inst)
    return p and (p + Vector3.new(0, 4, 0)) or nil
end

local function findTreadmill()
    if Treadmill.inst and Treadmill.inst.Parent then return Treadmill.inst end
    local hrp = getHRP()
    local ref = (baseCFrame and baseCFrame.Position) or (hrp and hrp.Position)
    local best, bestScore = nil, math.huge
    for _, d in ipairs(Snapshot.get()) do
        if (d:IsA("Model") or d:IsA("BasePart")) and d.Parent and nameHasAny(d.Name, HINTS.treadmill) then
            local parentMatches = d.Parent:IsA("Model") and nameHasAny(d.Parent.Name, HINTS.treadmill)
            if not parentMatches then
                local pos = getInstPosition(d)
                if pos then
                    local score = ref and (pos - ref).Magnitude or 0
                    if ownedByMe(d) then score -= 100000 end
                    if score < bestScore then
                        best, bestScore = d, score
                    end
                end
            end
        end
    end
    Treadmill.inst = best
    return best
end

function Treadmill.run(duration)
    local hrp, hum = getChar()
    if not hrp or not hum then
        task.wait(1)
        return
    end
    local inst = findTreadmill()
    if not inst then
        if not Treadmill.notified then
            Treadmill.notified = true
            log("Treadmill tidak ditemukan (nama harus mengandung 'treadmill'). Cek tab Debug.")
        end
        setStatus("Idle (treadmill tidak ditemukan)", THEME.warn)
        task.wait(duration)
        return
    end
    local spot = treadmillSpot(inst)
    if not spot then
        task.wait(duration)
        return
    end
    setStatus("Treadmill (idle)", THEME.good)
    Protect.treadmillActive = true
    if (hrp.Position - spot).Magnitude > 8 then
        hrp.CFrame = CFrame.new(spot)
        hrp.AssemblyLinearVelocity = Vector3.zero
        task.wait(0.3)
        firePromptsNear(spot, 15, { "treadmill", "run", "start" })
    end
    local t0 = os.clock()
    while os.clock() - t0 < duration and brainWanted() do
        local h, hm = getChar()
        if not h or not hm then break end
        local lv = h.CFrame.LookVector
        local dir = Vector3.new(lv.X, 0, lv.Z)
        if dir.Magnitude < 0.1 then dir = Vector3.new(0, 0, -1) end
        hm:Move(dir.Unit, false)
        if (h.Position - spot).Magnitude > 12 then
            h.CFrame = CFrame.new(spot)
            h.AssemblyLinearVelocity = Vector3.zero
        end
        task.wait(0.1)
    end
    Protect.treadmillActive = false
    local _, hm2 = getChar()
    if hm2 then hm2:Move(Vector3.zero, false) end
end

-- hapus popup "+123 Speed" (BillboardGui / label baru) supaya tidak lag saat treadmill
local popupConns = {}
local function textLooksLikeGain(t)
    t = t:gsub("<[^>]+>", "")
    if t:match("^%s*%+%s*[%d%.,]+%s*%a*") then return true end
    return t:find("+", 1, true) ~= nil and t:lower():find("speed", 1, true) ~= nil
end

local function checkPopup(inst)
    if not inst.Parent or (sg and inst:IsDescendantOf(sg)) then return end
    local target
    if inst:IsA("TextLabel") then
        if textLooksLikeGain(inst.Text) then target = inst end
    elseif inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
        for _, d in ipairs(inst:GetDescendants()) do
            if d:IsA("TextLabel") and textLooksLikeGain(d.Text) then
                target = inst
                break
            end
        end
    end
    if target then pcall(function() target:Destroy() end) end
end

local function onPopupAdded(inst)
    if inst:IsA("TextLabel") or inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
        task.delay(0.08, function() checkPopup(inst) end)
    end
end

local function setPopupCleaner(state)
    config.removePopups = state
    for _, c in ipairs(popupConns) do c:Disconnect() end
    table.clear(popupConns)
    if not state then return end
    table.insert(popupConns, Workspace.DescendantAdded:Connect(onPopupAdded))
    table.insert(popupConns, playerGui.DescendantAdded:Connect(onPopupAdded))
    task.spawn(function()
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BillboardGui") or d:IsA("SurfaceGui") then checkPopup(d) end
        end
    end)
end

-- ==========================================
-- AMBIL TELUR
-- ==========================================
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

    -- kunjungi titik area agar map ter-stream, lalu cari lagi
    local visit = {}
    for name, pos in pairs(areaCenters) do
        if next(config.areas) == nil or config.areas[name] then
            table.insert(visit, { name = name, pos = pos })
        end
    end
    for _, v in ipairs(visit) do
        if not alive() then return nil end
        setStatus("Memuat area " .. v.name .. "...", THEME.warn)
        hrp.CFrame = CFrame.new(v.pos)
        hrp.AssemblyLinearVelocity = Vector3.zero
        pcall(function() player:RequestStreamAroundAsync(v.pos, 3) end)
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
    local hrp, hum = getChar()
    if not hrp or not hum or hum.Health <= 0 then
        task.wait(1)
        return "none"
    end
    ensureBase()

    setStatus("Mencari telur...", THEME.accent2)
    local target = waitForTarget(hrp, alive)
    if not alive() then return "none" end
    if not target then
        setStatus("Tidak ada telur ditemukan", THEME.warn)
        return "none"
    end

    local prompt = target.prompt
    log(("Target: %s (%d stud%s)"):format(prompt:GetFullName(), math.floor(target.dist), target.enabled and "" or ", prompt nonaktif"))

    setStatus(config.method == "Fly" and "Terbang ke telur..." or "Teleport ke telur...", THEME.accent2)
    goTo(hrp, target.pos + Vector3.new(0, 3, 0), alive)
    if not alive() then return "none" end
    task.wait(0.3)

    -- prompt bisa nonaktif sampai kita dekat: tunggu sebentar lalu paksa aktif
    if prompt.Parent and not prompt.Enabled then
        local t0 = os.clock()
        while alive() and prompt.Parent and not prompt.Enabled and os.clock() - t0 < 2 do
            task.wait(0.1)
        end
        if prompt.Parent and not prompt.Enabled then
            pcall(function() prompt.Enabled = true end)
        end
    end

    setStatus("Mengambil telur...", THEME.accent)
    local success = false
    for _ = 1, 3 do
        if not alive() then return "none" end
        if not prompt.Parent then
            success = true
            break
        end
        triggerPrompt(prompt)
        task.wait(0.4)
        if isCarrying() or not prompt.Parent or not prompt.Enabled then
            success = true
            break
        end
    end

    local result
    if success then
        stats.stolen += 1
        result = "stolen"
        log("Telur berhasil diambil")
        local info = describeEgg(target.root)
        info.area = target.area
        sendEggWebhook(info)
    else
        stats.failed += 1
        result = "failed"
        banned[prompt] = os.clock() + 20
        log("Gagal mengambil telur (prompt tidak merespon), dilewati 20 detik")
    end
    refreshStats()

    if baseCFrame and alive() then
        setStatus("Pulang ke base...", THEME.good)
        goTo(hrp, baseCFrame.Position, alive)
        task.wait(0.5)
    end
    return result
end

-- ==========================================
-- EVENT
-- ==========================================
local EventBan = {}
local EventAttempts = {}

local function anyEventEnabled()
    for _, on in pairs(config.events) do
        if on then return true end
    end
    return false
end

local function findEventTarget(def, hrp)
    local best, bestD = nil, math.huge
    local matched = {}
    local eggFolder = Workspace:FindFirstChild("AreaEggSlotsClient")
    for _, d in ipairs(Snapshot.get()) do
        if d.Parent and not (eggFolder and d:IsDescendantOf(eggFolder)) and not (EventBan[d] and EventBan[d] > os.clock()) then
            local cand
            if d:IsA("ProximityPrompt") then
                local pname = d.Parent and d.Parent.Name or ""
                local text = (d.ActionText or "") .. " " .. (d.ObjectText or "") .. " " .. d.Name
                if nameHasAny(pname, def.keywords) or nameHasAny(text, def.keywords) then
                    local pos = getPromptPosition(d)
                    if pos then cand = { inst = d, prompt = d, pos = pos } end
                end
            elseif d:IsA("Model") or d:IsA("BasePart") then
                if nameHasAny(d.Name, def.keywords) and not Players:GetPlayerFromCharacter(d) then
                    local inside = false
                    local anc = d.Parent
                    while anc and anc ~= Workspace do
                        if matched[anc] then
                            inside = true
                            break
                        end
                        anc = anc.Parent
                    end
                    if not inside then
                        matched[d] = true
                        local hum = d:IsA("Model") and d:FindFirstChildOfClass("Humanoid")
                        if not (hum and hum.Health <= 0) then
                            local pos = getInstPosition(d)
                            if pos then cand = { inst = d, pos = pos } end
                        end
                    end
                end
            end
            if cand then
                local dist = (cand.pos - hrp.Position).Magnitude
                if dist < bestD then
                    best, bestD = cand, dist
                end
            end
        end
    end
    return best
end

local function runEvent(def, t, alive)
    local hrp = getHRP()
    if not hrp then return end
    local inst = t.inst
    setStatus("Event: " .. def.name, THEME.accent)
    log("Event " .. def.name .. " -> " .. inst:GetFullName())
    goTo(hrp, t.pos + Vector3.new(0, 3, 4), alive)

    if def.mode == "attack" then
        local tool = equipTool(def.tool)
        local t0 = os.clock()
        while alive() and inst.Parent and os.clock() - t0 < 40 do
            local p = getInstPosition(inst)
            local h = getHRP()
            if not p or not h then break end
            if (h.Position - p).Magnitude > 10 then
                h.CFrame = CFrame.new(p + Vector3.new(0, 3, 4))
                h.AssemblyLinearVelocity = Vector3.zero
            end
            if t.prompt and t.prompt.Parent then triggerPrompt(t.prompt) end
            if tool then
                if tool.Parent ~= player.Character then tool = equipTool(def.tool) end
                if tool then pcall(function() tool:Activate() end) end
            end
            task.wait(0.15)
        end
    elseif def.mode == "collect" then
        local tool = def.tool and equipTool(def.tool) or nil
        for _ = 1, 4 do
            if not alive() or not inst.Parent then break end
            local fired = false
            if t.prompt and t.prompt.Parent then
                fired = triggerPrompt(t.prompt)
            else
                fired = firePromptsNear(t.pos, 14, nil) > 0
            end
            local h = getHRP()
            if not fired and h and typeof(firetouchinterest) == "function" and inst:IsA("BasePart") then
                pcall(firetouchinterest, h, inst, 0)
                pcall(firetouchinterest, h, inst, 1)
            end
            if tool and tool.Parent == player.Character then pcall(function() tool:Activate() end) end
            task.wait(0.35)
        end
    else -- touch
        local h = getHRP()
        if h then
            h.CFrame = CFrame.new(t.pos + Vector3.new(0, 1.5, 0))
            h.AssemblyLinearVelocity = Vector3.zero
            if typeof(firetouchinterest) == "function" and inst:IsA("BasePart") then
                pcall(firetouchinterest, h, inst, 0)
                pcall(firetouchinterest, h, inst, 1)
            end
            task.wait(0.4)
        end
    end

    if inst.Parent then
        EventAttempts[inst] = (EventAttempts[inst] or 0) + 1
        if EventAttempts[inst] >= 4 then
            EventBan[inst] = os.clock() + 30
            EventAttempts[inst] = nil
        end
    else
        EventAttempts[inst] = nil
    end
end

local function eventStep(alive)
    local hrp = getHRP()
    if not hrp then return false end
    for _, def in ipairs(EVENT_DEFS) do
        if config.events[def.id] and alive() then
            local t = findEventTarget(def, hrp)
            if t then
                runEvent(def, t, alive)
                return true
            end
        end
    end
    return false
end

-- ==========================================
-- AUTOMATION (hatch, place, fuse, claim index)
-- ==========================================
local function nearBase(pos, radius)
    return baseCFrame ~= nil and (pos - baseCFrame.Position).Magnitude <= radius
end

local function actOnPrompts(kws)
    local hrp = getHRP()
    if not hrp then return 0 end
    local count = 0
    local always = function() return uiAlive end
    for _, p in ipairs(Snapshot.get()) do
        if p:IsA("ProximityPrompt") and p.Parent and p.Enabled and promptMatches(p, kws) then
            local pos = getPromptPosition(p)
            if pos and (ownedByMe(p) or nearBase(pos, BASE_RADIUS)) then
                goTo(hrp, pos + Vector3.new(0, 3, 0), always)
                task.wait(0.2)
                triggerPrompt(p)
                count += 1
                task.wait(0.4)
                if count >= 10 then break end
            end
        end
    end
    return count
end

local function autoHatchOnce()
    ensureBase()
    local btns = findButtons(HINTS.hatch, false)
    if #btns > 0 then
        clickButton(btns[1])
        task.wait(0.3)
    end
    local n = actOnPrompts(HINTS.hatch)
    if n > 0 then log("Auto Hatch: " .. n .. " telur") end
end

local function eggToolMatches(tool)
    local text = tool.Name:lower()
    for k, v in pairs(tool:GetAttributes()) do
        text = text .. " " .. tostring(k):lower() .. ":" .. tostring(v):lower()
    end
    return passesFilters(tool, text, config.placeFilters)
end

local function autoPlaceOnce()
    ensureBase()
    local hrp, hum = getChar()
    if not hrp or not hum then return end
    if not isCarrying() then
        for _, t in ipairs(player.Backpack:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("egg", 1, true) and eggToolMatches(t) then
                pcall(function() hum:EquipTool(t) end)
                task.wait(0.3)
                break
            end
        end
    end
    local n = actOnPrompts(HINTS.place)
    if n > 0 then log("Auto Place: " .. n .. " telur") end
end

local function autoFuseOnce()
    ensureBase()
    local n = actOnPrompts(HINTS.fuse)
    if n > 0 then
        task.wait(0.8)
        for _ = 1, 3 do
            clickFirstMatching({ "auto select", "select all", "fuse" })
            task.wait(0.5)
        end
        log("Auto Fuse dijalankan")
    end
end

local function autoIndexOnce()
    local claimed = 0
    local function claimAll()
        for _, b in ipairs(findButtons(HINTS.index, false)) do
            if clickButton(b) then
                claimed += 1
                task.wait(0.15)
            end
        end
    end
    claimAll()
    if claimed == 0 then
        local open = findButtons({ "index" }, true)
        if #open > 0 then
            clickButton(open[1])
            task.wait(0.6)
            claimAll()
            clickButton(open[1])
        end
    end
    if claimed > 0 then log("Auto Claim Index: " .. claimed .. " klaim") end
end

local autoTokens = {}
local function runAutoLoop(key, fn)
    autoTokens[key] = (autoTokens[key] or 0) + 1
    local my = autoTokens[key]
    task.spawn(function()
        while uiAlive and config.auto[key] and autoTokens[key] == my do
            local ok, err = Lock.run(fn)
            if not ok then log("Auto " .. key .. " error: " .. tostring(err)) end
            local iv = key == "index" and 60 or config.autoInterval
            local waited = 0
            while waited < iv and uiAlive and config.auto[key] and autoTokens[key] == my do
                task.wait(0.25)
                waited += 0.25
            end
        end
    end)
end

local function setAuto(key, on, fn)
    config.auto[key] = on
    if on then runAutoLoop(key, fn) end
end

-- ==========================================
-- SHOP
-- ==========================================
local function openShop(def)
    task.spawn(function()
        Lock.run(function()
            local btns = findButtons(def.gui, true)
            if #btns == 0 then btns = findButtons(def.gui, false) end
            for _, b in ipairs(btns) do
                if clickButton(b) then
                    log("Membuka " .. def.name .. " (tombol HUD: " .. b.Name .. ")")
                    return
                end
            end

            local hrp = getHRP()
            if not hrp then return end
            local best, bestD = nil, math.huge
            for _, d in ipairs(Snapshot.get()) do
                if d.Parent then
                    local cand
                    if d:IsA("ProximityPrompt") then
                        local pname = d.Parent and d.Parent.Name or ""
                        if nameHasAny(pname, def.world) or promptMatches(d, def.world) then
                            local pos = getPromptPosition(d)
                            if pos then cand = { prompt = d, pos = pos } end
                        end
                    elseif d:IsA("Model") and nameHasAny(d.Name, def.world) then
                        local pos = getInstPosition(d)
                        if pos then cand = { pos = pos } end
                    end
                    if cand then
                        local dist = (cand.pos - hrp.Position).Magnitude
                        if dist < bestD then
                            best, bestD = cand, dist
                        end
                    end
                end
            end
            if best then
                goTo(hrp, best.pos + Vector3.new(0, 3, 3), function() return uiAlive end)
                task.wait(0.3)
                if best.prompt then triggerPrompt(best.prompt) end
                log("Menuju " .. def.name .. (best.prompt and " (prompt dipicu)" or " (teleport saja)"))
            else
                log(def.name .. " tidak ditemukan. Cek tab Debug > Scan UI / Scan Prompt.")
            end
        end)
    end)
end

-- ==========================================
-- AFK MANAGER (satu loop untuk event > steal > treadmill)
-- ==========================================
brainWanted = function()
    return uiAlive and (config.running or anyEventEnabled() or config.treadmillIdle)
end

local brainRunning = false
local function ensureBrain()
    if brainRunning or not brainWanted() then return end
    brainRunning = true
    task.spawn(function()
        log("AFK manager berjalan")
        local aliveSteal = function() return config.running and uiAlive end
        local aliveEvents = function() return anyEventEnabled() and uiAlive end
        while brainWanted() do
            local did = false
            local ok, err = Lock.run(function()
                local hrp = getHRP()
                if not hrp then
                    task.wait(1)
                    return
                end
                if anyEventEnabled() and eventStep(aliveEvents) then
                    did = true
                    return
                end
                if config.running then
                    local res = stealCycle(aliveSteal)
                    if res ~= "none" then
                        did = true
                        return
                    end
                end
                if config.treadmillIdle then
                    Treadmill.run(4)
                else
                    task.wait(1.2)
                end
            end)
            if not ok then
                log("Error: " .. tostring(err))
                task.wait(1)
            end
            task.wait(did and 0.2 or 0.4)
        end
        brainRunning = false
        setStatus("Idle", THEME.sub)
        log("AFK manager berhenti")
    end)
end

-- ==========================================
-- PERFORMA: PLOT, PET, DEKOR
-- ==========================================
local function containsPoint(inst, pos)
    if inst:IsA("BasePart") then
        local rel = inst.CFrame:PointToObjectSpace(pos)
        return math.abs(rel.X) <= inst.Size.X / 2 + 25 and math.abs(rel.Z) <= inst.Size.Z / 2 + 25 and math.abs(rel.Y) <= inst.Size.Y / 2 + 80
    end
    if inst:IsA("Model") then
        local ok, cf, size = pcall(function() return inst:GetBoundingBox() end)
        if ok then
            local rel = cf:PointToObjectSpace(pos)
            return math.abs(rel.X) <= size.X / 2 + 25 and math.abs(rel.Z) <= size.Z / 2 + 25 and math.abs(rel.Y) <= size.Y / 2 + 80
        end
    end
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("BasePart") and (d.Position - pos).Magnitude < 60 then return true end
    end
    return false
end

local function hasEggPrompt(inst)
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("ProximityPrompt") and isEggPrompt(d) then return true end
    end
    return false
end

local function isEggRelated(inst)
    local cur = inst
    while cur and cur ~= Workspace do
        if cur.Name:lower():find("egg", 1, true) then return true end
        cur = cur.Parent
    end
    return false
end

local plotKeepMine = true
local plotWatcher

local function plotRemovable(d)
    if not d:IsDescendantOf(Workspace) then return false end
    if not (d:IsA("Model") or d:IsA("Folder") or d:IsA("BasePart")) then return false end
    if not nameHas(d.Name, "plot") then return false end
    local char = player.Character
    if char and (char == d or char:IsDescendantOf(d)) then return false end
    if plotKeepMine then
        if ownedByMe(d) then return false end
        if baseCFrame and containsPoint(d, baseCFrame.Position) then return false end
    end
    if hasEggPrompt(d) then return false end
    return true
end

local function removePlots()
    local removed, skipped = 0, 0
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsDescendantOf(Workspace) and nameHas(d.Name, "plot") then
            if plotRemovable(d) then
                pcall(function() d:Destroy() end)
                removed += 1
            else
                skipped += 1
            end
        end
    end
    log(("Plot dihapus: %d (dilewati: %d, termasuk plot milik sendiri / berisi telur)"):format(removed, skipped))
end

local function setPlotWatcher(state)
    if plotWatcher then plotWatcher:Disconnect() plotWatcher = nil end
    if not state then return end
    plotWatcher = Workspace.DescendantAdded:Connect(function(d)
        task.delay(0.1, function()
            if d.Parent and nameHas(d.Name, "plot") and plotRemovable(d) then
                pcall(function() d:Destroy() end)
            end
        end)
    end)
    track(plotWatcher)
end

local function removeByNames(modelWords, partWords)
    local count = 0
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsDescendantOf(Workspace) and not isEggRelated(d) then
            local char = player.Character
            if not (char and (char == d or char:IsDescendantOf(d))) then
                if d:IsA("Model") and modelWords and nameHasAny(d.Name, modelWords) and not Players:GetPlayerFromCharacter(d) then
                    pcall(function() d:Destroy() end)
                    count += 1
                elseif d:IsA("BasePart") and partWords and nameHasAny(d.Name, partWords) then
                    pcall(function() d:Destroy() end)
                    count += 1
                end
            end
        end
    end
    return count
end

local antiLagConn
local function setAntiLag(state)
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

local function superFpsBoost()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            end
        end
    end)
    plotKeepMine = true
    removePlots()
    setPlotWatcher(true)
    setAntiLag(true)
    log("Super FPS Boost aktif (plot orang lain dihapus, plot milikmu tetap)")
end
