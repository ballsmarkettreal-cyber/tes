--[[
    STEAL AN EGG PREMIUM | EX - TNJ  -  V28 (SAFE)

    Perubahan V28 (SAFE):
      * GUI kembali ke PlayerGui (bukan CoreGui/gethui). Banyak anti-cheat
        memindai ScreenGui asing di CoreGui dan langsung kick.
      * Background gambar (getcustomasset + writefile) jadi OPT-IN.
        Default: pakai blackhole animasi bawaan (tanpa I/O).
      * Auto-save default OFF (hindari spam writefile tiap 2 detik).
      * Efek petir & batu default OFF (hindari Heartbeat 30x/detik).
      * Pembersih popup default OFF.
      * Anti-Knockback & Anti-Trapped dipaksa OFF saat pertama load config.
      * File simpanan baru: EX_StealAnEgg_V28.json (config V26 lama tetap dibaca
        hanya untuk filter / nama / area supaya setting tidak hilang).
      * Semua fitur lama tetap ADA. Fitur berisiko tinggal dinyalakan lagi di
        tab CONFIG / PROTEKSI bila user memang mau.

    Perubahan V27:
      * UI hanya warna ungu & hitam, garis/border lebih tebal (kesan premium),
        judul "STEAL AN EGG PREMIUM | EX - TNJ".
      * Tiap tab punya ikon simbol (digambar dari shape).
      * Tombol minimize lebih kecil. Ikon minimize: blackhole + "EX" + border berputar.
      * Efek petir & batu jatuh di border menu (bisa dimatikan di tab CONFIG).
      * Mode Terbang dipercepat: default 130.

    Perubahan V26:
      * Gerak ala humanoid: default "Jalan". "Terbang" halus.
      * Scanning diringankan, snapshot di-cache lebih lama.

    Dasar: V25. Tambahan V25:
      * Resize menu, Egg Predict, Auto Sell, Legit Steal, Auto Favorit.
      * PRIORITY, AUTOMATION (Upgrade, Pet).
      * Variant: Silver, Golden, Rainbow, Bloom, Spirit Bloom, Parasite,
        Fractured, Scrambled.
      * Mode AFK Hemat (3D off, FPS cap).

    CATATAN: fitur yang bergantung pada nama objek di game memakai deteksi kata
    kunci. Edit tabel HINTS / UPGRADES kalau nama di game berbeda. Gunakan tab
    Debug untuk melihat nama aslinya.
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
local function cleanOldGui()
    local function cleanIn(parent)
        pcall(function()
            for _, v in ipairs(parent:GetChildren()) do
                if v.Name:match("EX_StealAnEgg") then v:Destroy() end
            end
        end)
    end
    cleanIn(playerGui)
    pcall(function() cleanIn(game:GetService("CoreGui")) end)
    pcall(function() if typeof(gethui) == "function" then cleanIn(gethui()) end end)
end

if _G.EX_STEAL_EGG_CLEANUP then pcall(_G.EX_STEAL_EGG_CLEANUP) end
cleanOldGui()

local VERSION = "V28 (SAFE)"
local SAVE_FILE = "EX_StealAnEgg_V28.json"
local OLD_SAVE_FILE = "EX_StealAnEgg_V26.json"   -- hanya untuk migrasi filter/nama
local BASE_RADIUS = 140

-- ==========================================
-- HINTS
-- ==========================================
local HINTS = {
    hatch = { "hatch" },
    place = { "place" },
    fuse = { "fuse" },
    index = { "claim" },
    treadmill = { "treadmill", "tredmill" },
    trap = { "trap", "snare", "cage", "stun", "freeze", "glue" },
    sell = { "sell" },
    favorite = { "favorite", "favourite" },
    upgrade = { "upgrade" },
}

local UPGRADES = {
    upgTrail = { name = "Trail", words = { "trail" } },
    upgTreadmill = { name = "Treadmill", words = { "treadmill", "tredmill" } },
    upgBase = { name = "Base", words = { "base", "plot" } },
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
    { "Variant", { "Normal", "Silver", "Golden", "Rainbow", "Bloom", "Spirit Bloom", "Parasite", "Fractured", "Scrambled" } },
}

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
    bg1 = Color3.fromRGB(20, 8, 36),
    bg2 = Color3.fromRGB(5, 2, 10),
    card = Color3.fromRGB(20, 9, 36),
    off = Color3.fromRGB(40, 20, 72),
    accent = Color3.fromRGB(142, 62, 255),
    accent2 = Color3.fromRGB(206, 160, 255),
    text = Color3.fromRGB(246, 240, 255),
    sub = Color3.fromRGB(172, 142, 222),
    good = Color3.fromRGB(196, 140, 255),
    warn = Color3.fromRGB(168, 108, 255),
    bad = Color3.fromRGB(104, 34, 184),
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
        for _, fileName in ipairs({ SAVE_FILE, OLD_SAVE_FILE }) do
            local ok, data = pcall(function()
                if isfile(fileName) then return HttpService:JSONDecode(readfile(fileName)) end
                return nil
            end)
            if ok and type(data) == "table" then
                saved = data
                break
            end
        end
    end
end

-- [V28 SAFE] Fitur berisiko dipaksa OFF saat pertama kali load.
-- User bisa mengaktifkannya lagi lewat UI; preferensi akan tersimpan di file V28.
saved.fxBorder = nil
saved.cleanFx = nil
saved.autoSave = nil
saved.useBgImage = nil
saved.antiKB = nil
saved.antiTrap = nil

local function S(key, default)
    local v = saved[key]
    if v == nil then return default end
    return v
end

local function newFilterSet(key)
    local raw = S(key, {})
    if type(raw) ~= "table" then raw = {} end
    local out = {
        Size = listToSet(raw.Size),
        Rarity = listToSet(raw.Rarity),
        Variant = listToSet(raw.Variant),
    }
    for _, entry in ipairs(FILTERS) do
        local valid = listToSet(entry[2])
        for k in pairs(out[entry[1]]) do
            if not valid[k] then out[entry[1]][k] = nil end
        end
    end
    return out
end

local areaCenters = { Forest = Vector3.new(597, 10, -324) }
for name, arr in pairs(S("areaCenters", {})) do
    if type(arr) == "table" and #arr == 3 then
        areaCenters[name] = Vector3.new(arr[1], arr[2], arr[3])
    end
end

local config = {
    running = false,
    treadmillIdle = false,
    method = S("method", "Walk"),
    targetMode = S("targetMode", "All"),
    filters = newFilterSet("filters"),
    placeFilters = newFilterSet("placeFilters"),
    areas = listToSet(S("areas", {})),
    skipOwn = S("skipOwn", true),
    legit = S("legit", false),
    eggPredict = false,
    priorityOn = false,
    priority = S("priority", { "steal", "event", "hatch", "place", "fuse", "sell", "favorite" }),
    sellFilters = newFilterSet("sellFilters"),
    favFilters = newFilterSet("favFilters"),
    favNames = S("favNames", ""),
    petPlaceFilters = newFilterSet("petPlaceFilters"),
    petPlaceNames = S("petPlaceNames", ""),
    petSellFilters = newFilterSet("petSellFilters"),
    petSellNames = S("petSellNames", ""),
    afkSaver = false,
    fpsCap = S("fpsCap", 15),
    winW = S("winW", 580),
    winH = S("winH", 420),
    flySpeed = S("flySpeed2", 130),
    flyHeight = S("flyHeight", 12),
    fxBorder = S("fxBorder", false),     -- V28: default OFF
    antiKB = S("antiKB", false),
    antiTrap = S("antiTrap", false),
    antiAfk = S("antiAfk", true),
    pingPanel = S("pingPanel", true),
    removePopups = S("cleanFx", false),  -- V28: default OFF
    antiLag = S("antiLag", false),
    autoSave = S("autoSave", false),     -- V28: default OFF
    useBgImage = S("useBgImage", false), -- V28: default OFF
    events = {},
    auto = {
        hatch = false, place = false, fuse = false, index = false,
        sell = false, favorite = false,
        upgTrail = false, upgTreadmill = false, upgBase = false,
        petPlace = false, petSell = false,
    },
    autoInterval = S("autoInterval", 6),
    eggWebhookOn = false,
    eggWebhookUrl = S("eggWebhookUrl", ""),
    statsWebhookOn = false,
    statsWebhookUrl = S("statsWebhookUrl", ""),
    statsIntervalMin = S("statsIntervalMin", 5),
}

local V25 = {}
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

local lastSavedJson = nil
local function saveSettings(force)
    if typeof(writefile) ~= "function" then return false end
    local function f(sets)
        return { Size = setToList(sets.Size), Rarity = setToList(sets.Rarity), Variant = setToList(sets.Variant) }
    end
    local centers = {}
    for name, v in pairs(areaCenters) do centers[name] = { v.X, v.Y, v.Z } end
    local data = {
        areas = setToList(config.areas),
        filters = f(config.filters),
        placeFilters = f(config.placeFilters),
        sellFilters = f(config.sellFilters),
        favFilters = f(config.favFilters),
        favNames = config.favNames,
        petPlaceFilters = f(config.petPlaceFilters),
        petPlaceNames = config.petPlaceNames,
        petSellFilters = f(config.petSellFilters),
        petSellNames = config.petSellNames,
        legit = config.legit,
        priority = config.priority,
        fpsCap = config.fpsCap,
        winW = config.winW,
        winH = config.winH,
        method = config.method,
        targetMode = config.targetMode,
        skipOwn = config.skipOwn,
        flySpeed2 = config.flySpeed,
        flyHeight = config.flyHeight,
        fxBorder = config.fxBorder,
        antiKB = config.antiKB,
        antiTrap = config.antiTrap,
        antiAfk = config.antiAfk,
        pingPanel = config.pingPanel,
        cleanFx = config.removePopups,
        antiLag = config.antiLag,
        autoSave = config.autoSave,
        useBgImage = config.useBgImage,
        autoInterval = config.autoInterval,
        eggWebhookUrl = config.eggWebhookUrl,
        statsWebhookUrl = config.statsWebhookUrl,
        statsIntervalMin = config.statsIntervalMin,
        areaCenters = centers,
    }
    local okEnc, json = pcall(function() return HttpService:JSONEncode(data) end)
    if not okEnc then return false end
    if not force and json == lastSavedJson then return true end
    local okWrite = pcall(writefile, SAVE_FILE, json)
    if okWrite then lastSavedJson = json end
    return okWrite
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
        local move = config.method == "Fly" and "Terbang" or "Jalan"
        local target = config.targetMode == "All" and "Semua" or "Filter"
        local areaCount = 0
        for _ in pairs(config.areas) do areaCount += 1 end
        ui.modeText.Text = ("Gerak: %s   Target: %s   Area: %s"):format(move, target, areaCount > 0 and (areaCount .. " dipilih") or "semua")
    end
end

-- ==========================================
-- HELPER KARAKTER
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

local Snapshot = { t = 0, list = {} }
function Snapshot.get()
    if os.clock() - Snapshot.t > 5 then
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
-- HELPER GUI GAME
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
-- LOCK GERAK
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
-- PROTEKSI
-- ==========================================
local Protect = { lastWalk = 16, flying = false, treadmillActive = false }
local BODY_MOVERS = {
    BodyVelocity = true, BodyPosition = true, BodyForce = true, BodyThrust = true,
    BodyAngularVelocity = true, LinearVelocity = true, VectorForce = true, LineForce = true,
}

function Protect.bindChar(char)
    if Protect.charConn then Protect.charConn:Disconnect() end
    Protect.charConn = track(char.DescendantAdded:Connect(function(d)
        if config.antiKB and not Protect.treadmillActive and BODY_MOVERS[d.ClassName] then
            task.defer(function()
                pcall(function()
                    if d:IsA("Constraint") then
                        d.Enabled = false
                    elseif d:IsA("BodyMover") then
                        d:Destroy()
                    end
                end)
            end)
        end
    end))
end
track(player.CharacterAdded:Connect(Protect.bindChar))
if player.Character then Protect.bindChar(player.Character) end

function Protect.unstick(hrp)
    hrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
    hrp.AssemblyLinearVelocity = Vector3.zero
    local _, hum = getChar()
    if hum then
        hum.PlatformStand = false
        hum.Sit = false
        hum.Jump = true
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
    if protectAccum < 0.5 then return end
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

local eggPromptCache = { t = -10, list = {} }
local function collectEggPrompts()
    if os.clock() - eggPromptCache.t < 2 then
        local alive = {}
        for _, p in ipairs(eggPromptCache.list) do
            if p.Parent then table.insert(alive, p) end
        end
        return alive
    end
    local result = {}
    local function scan(list)
        for _, d in ipairs(list) do
            if d:IsA("ProximityPrompt") and isEggPrompt(d) then
                table.insert(result, d)
            end
        end
    end
    local folder = Workspace:FindFirstChild("AreaEggSlotsClient")
    if folder then scan(folder:GetDescendants()) end
    if #result == 0 then scan(Snapshot.get()) end
    eggPromptCache.t = os.clock()
    eggPromptCache.list = result
    return result
end

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

local VARIANT_KEYS = { "silver", "golden", "rainbow", "bloom", "parasite", "monstrous", "fractured", "scrambled" }
local VARIANT_ALIASES = {
    ["parasite"] = { "parasite", "monstrous" },
    ["spirit bloom"] = { "spirit bloom", "spiritbloom", "spirit_bloom" },
}

local function matchesValue(root, text, key)
    key = key:lower()
    if key == "normal" then
        for _, k in ipairs(VARIANT_KEYS) do
            if text:find(k, 1, true) then return false end
        end
        return true
    end
    if key == "common" then
        text = (text:gsub("uncommon", ""))
    end
    if key == "bloom" then
        text = (text:gsub("spirit[%s_]*bloom", ""))
    end
    local aliases = VARIANT_ALIASES[key]
    if aliases then
        for _, a in ipairs(aliases) do
            if text:find(a, 1, true) then return true end
        end
        return false
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

    local cands = {}
    for _, prompt in ipairs(collectEggPrompts()) do
        c.total += 1
        local pos = getPromptPosition(prompt)
        if not pos then
            c.nopos += 1
        elseif banned[prompt] and banned[prompt] > os.clock() then
            c.banned += 1
        else
            table.insert(cands, { prompt = prompt, pos = pos, d = (pos - hrp.Position).Magnitude })
        end
    end
    table.sort(cands, function(a, b) return a.d < b.d end)

    local examined = 0
    for _, cand in ipairs(cands) do
        if best and best.enabled then break end
        if examined >= 40 then break end
        local prompt, pos = cand.prompt, cand.pos
        if config.skipOwn and ownedByMe(prompt) then
            c.mine += 1
        else
            examined += 1
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
local function flyToInner(hrp, targetPos, speed, alive, through)
    local lastPos, lastT, stalls = hrp.Position, os.clock(), 0
    local accel = math.max(speed * 4, 80)
    local cur = V25.flyCarry or 0
    local stopDist = through or 1.5
    while alive() do
        if not hrp.Parent then
            V25.flyCarry = 0
            return false
        end
        local delta = targetPos - hrp.Position
        local dist = delta.Magnitude
        if dist < stopDist then break end
        local dt = math.min(RunService.Heartbeat:Wait(), 0.1)
        local want = through and speed or math.min(speed, math.sqrt(2 * accel * dist) + 2)
        if cur < want then
            cur = math.min(want, cur + accel * dt)
        else
            cur = math.max(want, cur - accel * 2 * dt)
        end
        cur = math.max(cur, 12)
        local dir = delta.Unit
        local step = math.min(dist, cur * dt)
        local newPos = hrp.Position + dir * step
        local cf = hrp.CFrame
        local rot = cf - cf.Position
        local flat = Vector3.new(dir.X, 0, dir.Z)
        if flat.Magnitude > 0.05 then
            local face = CFrame.lookAt(Vector3.zero, flat)
            rot = rot:Lerp(face, math.min(1, dt * 10))
        end
        hrp.CFrame = CFrame.new(newPos) * rot
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero

        if os.clock() - lastT > 1.2 then
            if (hrp.Position - lastPos).Magnitude < 1 then
                stalls += 1
                Protect.unstick(hrp)
                if stalls >= 3 then
                    V25.flyCarry = 0
                    return false
                end
            else
                stalls = 0
            end
            lastPos, lastT = hrp.Position, os.clock()
        end
    end
    V25.flyCarry = through and cur or 0
    return true
end

local function flyTo(hrp, targetPos, speed, alive, through)
    Protect.flying = true
    local ok = flyToInner(hrp, targetPos, speed, alive, through)
    Protect.flying = false
    return ok
end

local function groundSnap(pos)
    local ignore = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then table.insert(ignore, plr.Character) end
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignore
    local res = Workspace:Raycast(pos + Vector3.new(0, 6, 0), Vector3.new(0, -40, 0), params)
    if res and math.abs((res.Position.Y + 3) - pos.Y) <= 10 then
        return Vector3.new(pos.X, math.max(pos.Y, res.Position.Y + 3.2), pos.Z)
    end
    return pos
end

local function goTo(hrp, targetPos, alive)
    if config.method ~= "Fly" then
        return V25.legitWalk(targetPos, alive)
    end
    local speed = config.flySpeed
    V25.flyCarry = 0
    if (hrp.Position - targetPos).Magnitude < 15 then
        return flyTo(hrp, targetPos, speed, alive)
    end
    local cruiseY = math.max(hrp.Position.Y, targetPos.Y) + config.flyHeight
    if not flyTo(hrp, Vector3.new(hrp.Position.X, cruiseY, hrp.Position.Z), speed, alive, 2.5) then return false end
    if not flyTo(hrp, Vector3.new(targetPos.X, cruiseY, targetPos.Z), speed, alive, 12) then return false end
    return flyTo(hrp, targetPos, speed, alive)
end

-- ==========================================
-- WEBHOOK
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
-- TREADMILL & PEMBERSIH POPUP
-- ==========================================
local brainWanted

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
        Protect.treadmillActive = false
        goTo(hrp, spot, brainWanted)
        Protect.treadmillActive = true
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
            hm:Move(Vector3.zero, false)
            Protect.treadmillActive = false
            goTo(h, spot, brainWanted)
            Protect.treadmillActive = true
        end
        task.wait(0.1)
    end
    Protect.treadmillActive = false
    local _, hm2 = getChar()
    if hm2 then hm2:Move(Vector3.zero, false) end
end

local popupConns = {}
local setPopupCleaner
do
    local FX_CLASSES = { ParticleEmitter = true, Trail = true, Beam = true, Smoke = true, Fire = true, Sparkles = true }
    local queue, head = {}, 1
    local loopOn = false

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

    local function killFx(inst)
        pcall(function() inst.Enabled = false end)
    end

    local function onAdded(inst)
        if FX_CLASSES[inst.ClassName] then
            killFx(inst)
        elseif inst:IsA("TextLabel") or inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
            if #queue - head < 2000 then
                queue[#queue + 1] = { inst, os.clock() + 0.08 }
            end
        end
    end

    local function startLoop()
        if loopOn then return end
        loopOn = true
        task.spawn(function()
            while loopOn and uiAlive do
                task.wait(0.15)
                local now, processed = os.clock(), 0
                while head <= #queue and processed < 80 do
                    local e = queue[head]
                    if e[2] > now then break end
                    queue[head] = false
                    head += 1
                    processed += 1
                    if e[1].Parent then checkPopup(e[1]) end
                end
                if head > #queue then
                    table.clear(queue)
                    head = 1
                end
            end
            loopOn = false
        end)
    end

    setPopupCleaner = function(state)
        config.removePopups = state
        for _, c in ipairs(popupConns) do c:Disconnect() end
        table.clear(popupConns)
        if not state then
            loopOn = false
            table.clear(queue)
            head = 1
            return
        end
        table.insert(popupConns, Workspace.DescendantAdded:Connect(onAdded))
        table.insert(popupConns, playerGui.DescendantAdded:Connect(onAdded))
        startLoop()
        task.spawn(function()
            local n = 0
            for _, d in ipairs(Workspace:GetDescendants()) do
                if not (state and config.removePopups) then break end
                if FX_CLASSES[d.ClassName] then
                    killFx(d)
                elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
                    checkPopup(d)
                end
                n += 1
                if n % 250 == 0 then task.wait(0.03) end
            end
        end)
    end
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

-- ==========================================
-- V25: LEGIT STEAL
-- ==========================================
do
    local PathfindingService = game:GetService("PathfindingService")

    local function flatDist(a, b)
        return (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude
    end

    function V25.legitWalk(dest, alive)
        local hrp, hum = getChar()
        if not hrp or not hum then return false end
        if flatDist(hrp.Position, dest) <= 8 then return true end
        local speed = math.max(hum.WalkSpeed, 8)
        local limit = math.max(12, flatDist(hrp.Position, dest) / speed * 2 + 10)
        local t0 = os.clock()
        setStatus("Berjalan...", THEME.accent2)

        local function nudgeIfStuck(state)
            local now = os.clock()
            if now - state.t >= 1 then
                if (hrp.Position - state.p).Magnitude < 0.6 then hum.Jump = true end
                state.t, state.p = now, hrp.Position
            end
        end
        local stuck = { t = os.clock(), p = hrp.Position }

        local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
        local okPath = pcall(function() path:ComputeAsync(hrp.Position, dest) end)
        if okPath and path.Status == Enum.PathStatus.Success then
            for _, wp in ipairs(path:GetWaypoints()) do
                if not alive() or os.clock() - t0 > limit or not hrp.Parent then break end
                if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
                hum:MoveTo(wp.Position)
                local reached = false
                local conn = hum.MoveToFinished:Connect(function() reached = true end)
                local w0 = os.clock()
                while not reached and alive() and os.clock() - w0 < 3 and os.clock() - t0 <= limit do
                    task.wait(0.1)
                    nudgeIfStuck(stuck)
                end
                conn:Disconnect()
            end
        end
        while alive() and hrp.Parent and os.clock() - t0 <= limit and flatDist(hrp.Position, dest) > 8 do
            hum:MoveTo(dest)
            task.wait(0.25)
            nudgeIfStuck(stuck)
        end
        hum:Move(Vector3.zero, false)
        return hrp.Parent ~= nil and flatDist(hrp.Position, dest) <= 8
    end

    function V25.legitTrigger(prompt)
        return pcall(function()
            prompt:InputHoldBegin()
            task.wait(math.max(prompt.HoldDuration, 0) + 0.15)
            prompt:InputHoldEnd()
        end)
    end
end

local lastSweep = 0
local sweepIdx = 0
local function waitForTarget(hrp, alive)
    local target = findTarget(hrp, false)
    if target then return target end
    if config.legit then return nil end

    if os.clock() - lastSweep < 90 then return nil end
    lastSweep = os.clock()

    local visit = {}
    for name, pos in pairs(areaCenters) do
        if next(config.areas) == nil or config.areas[name] then
            table.insert(visit, { name = name, pos = pos })
        end
    end
    table.sort(visit, function(a, b) return a.name < b.name end)
    local picked = {}
    for i = 1, math.min(2, #visit) do
        sweepIdx = sweepIdx % #visit + 1
        table.insert(picked, visit[sweepIdx])
    end
    for _, v in ipairs(picked) do
        if not alive() then return nil end
        setStatus("Menuju area " .. v.name .. "...", THEME.warn)
        pcall(function() player:RequestStreamAroundAsync(v.pos, 3) end)
        goTo(hrp, v.pos, alive)
        local t0 = os.clock()
        repeat
            task.wait(0.5)
            target = findTarget(hrp, true)
        until target or not alive() or os.clock() - t0 > 3
        if target then return target end
    end
    if baseCFrame and alive() then goTo(hrp, baseCFrame.Position, alive) end
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

    setStatus(config.method == "Fly" and not config.legit and "Terbang ke telur..." or "Berjalan ke telur...", THEME.accent2)
    local reached
    if config.legit then
        reached = V25.legitWalk(target.pos, alive)
    else
        reached = goTo(hrp, target.pos + Vector3.new(0, 3, 0), alive)
    end
    if not alive() then return "none" end
    if not reached and hrp.Parent and (hrp.Position - target.pos).Magnitude > 25 then
        stats.failed += 1
        banned[prompt] = os.clock() + 15
        log("Gagal mencapai telur (karakter tersangkut), dilewati 15 detik")
        refreshStats()
        return "failed"
    end
    task.wait(0.3)

    if prompt.Parent and not prompt.Enabled then
        local t0 = os.clock()
        while alive() and prompt.Parent and not prompt.Enabled and os.clock() - t0 < 2 do
            task.wait(0.1)
        end
        if prompt.Parent and not prompt.Enabled and not config.legit then
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
        if config.legit then V25.legitTrigger(prompt) else triggerPrompt(prompt) end
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
        if config.legit then
            V25.legitWalk(baseCFrame.Position, alive)
        else
            goTo(hrp, baseCFrame.Position, alive)
        end
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
            if (h.Position - p).Magnitude > 12 then
                goTo(h, p + Vector3.new(0, 3, 4), function() return alive() and inst.Parent ~= nil end)
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
    else
        local h = getHRP()
        if h then
            if (h.Position - t.pos).Magnitude > 4 then
                goTo(h, t.pos + Vector3.new(0, 1.5, 0), alive)
            end
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
-- AUTOMATION
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

-- ==========================================
-- V25: ITEM, SELL, FAVORIT, UPGRADE, PET, EGG PREDICT
-- ==========================================
do
    local warned = {}
    local function warnOnce(key, msg)
        if not warned[key] then
            warned[key] = true
            log(msg)
        end
    end

    local GEAR_WORDS = { "bat", "net", "racket", "racquet", "scrambler", "consumable", "booster", "potion" }
    local MAX_ITEMS_PER_RUN = 12
    local alive = function() return uiAlive end

    local function allTools()
        local list = {}
        local _, _, char = getChar()
        if char then
            for _, t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") then table.insert(list, t) end
            end
        end
        for _, t in ipairs(player.Backpack:GetChildren()) do
            if t:IsA("Tool") then table.insert(list, t) end
        end
        return list
    end

    local function toolAlive(t)
        return t.Parent == player.Backpack or (player.Character ~= nil and t.Parent == player.Character)
    end

    local function itemText(tool)
        local parts = { tool.Name:lower() }
        for k, v in pairs(tool:GetAttributes()) do
            table.insert(parts, tostring(k):lower() .. ":" .. tostring(v):lower())
        end
        local count = 0
        for _, d in ipairs(tool:GetDescendants()) do
            count += 1
            if count > 40 then break end
            table.insert(parts, d.Name:lower())
            if d:IsA("TextLabel") then table.insert(parts, d.Text:lower()) end
            if d:IsA("StringValue") then table.insert(parts, d.Value:lower()) end
        end
        return table.concat(parts, " ")
    end

    local function isFavorited(tool, text)
        for k, v in pairs(tool:GetAttributes()) do
            local kl = tostring(k):lower()
            local favKey = kl:find("favorite", 1, true) or kl:find("favourite", 1, true)
                or kl == "fav" or kl == "isfav" or kl == "locked" or kl == "islocked" or kl == "lock"
            if favKey and v and v ~= 0 and v ~= "" then
                return true
            end
        end
        return text:find("favorited", 1, true) ~= nil
    end

    local function isEggTool(tool) return tool.Name:lower():find("egg", 1, true) ~= nil end
    local function isGearTool(tool) return nameHasAny(tool.Name, GEAR_WORDS) end
    local function isPetTool(tool) return not isEggTool(tool) and not isGearTool(tool) end

    local function parseNames(s)
        local list = {}
        for w in tostring(s or ""):gmatch("[^,;\n]+") do
            w = w:lower():gsub("^%s+", ""):gsub("%s+$", "")
            if w ~= "" then table.insert(list, w) end
        end
        return list
    end

    local function matchesSpec(tool, text, names, filters)
        for _, w in ipairs(names) do
            if text:find(w, 1, true) then return true end
        end
        if hasAnyFilter(filters) and passesFilters(tool, text, filters) then return true end
        return false
    end

    local function equipHeld(tool)
        local _, hum = getChar()
        if not hum then return false end
        if tool.Parent ~= player.Character then
            pcall(function() hum:EquipTool(tool) end)
            task.wait(0.3)
        end
        return tool.Parent == player.Character
    end

    local function backToBase()
        local hrp = getHRP()
        if hrp and baseCFrame then goTo(hrp, baseCFrame.Position, alive) end
    end

    local function clickLabeled(keys, bannedWords)
        for _, b in ipairs(findButtons(keys, false)) do
            local lab = (buttonLabel(b) .. " " .. b.Name):lower()
            local skip = false
            for _, w in ipairs(bannedWords) do
                if lab:find(w, 1, true) then
                    skip = true
                    break
                end
            end
            if not skip and clickButton(b) then return true end
        end
        return false
    end

    local function sellTools(tools, label)
        local hrp = getHRP()
        if not hrp then return 0 end
        local sold, fails = 0, 0
        for i, tool in ipairs(tools) do
            if i > MAX_ITEMS_PER_RUN or not uiAlive then break end
            if toolAlive(tool) and equipHeld(tool) then
                local done = clickLabeled(HINTS.sell, { "all" })
                if not done then
                    for _, p in ipairs(Snapshot.get()) do
                        if p:IsA("ProximityPrompt") and p.Parent and p.Enabled and promptMatches(p, HINTS.sell) then
                            local pos = getPromptPosition(p)
                            if pos and (ownedByMe(p) or nearBase(pos, BASE_RADIUS)) then
                                goTo(hrp, pos + Vector3.new(0, 3, 0), alive)
                                task.wait(0.2)
                                triggerPrompt(p)
                                done = true
                                break
                            end
                        end
                    end
                end
                if not done then
                    warnOnce("sell_none_" .. label, "Auto Sell " .. label .. ": tombol/prompt 'Sell' tidak ditemukan. Buka menu jual dulu, atau cek Debug > Scan Aksi.")
                    break
                end
                task.wait(0.35)
                clickLabeled({ "confirm" }, {})
                task.wait(0.4)
                if toolAlive(tool) then
                    fails += 1
                    if fails >= 2 then
                        warnOnce("sell_fail_" .. label, "Auto Sell " .. label .. ": item tidak terjual setelah klik Sell (mungkin butuh langkah lain). Dihentikan, cek Debug.")
                        break
                    end
                else
                    sold += 1
                    fails = 0
                end
            end
        end
        backToBase()
        return sold
    end

    function V25.autoSellOnce()
        ensureBase()
        if not hasAnyFilter(config.sellFilters) then
            warnOnce("sell_nofilter", "Auto Sell Egg: pilih minimal satu rarity dulu (tanpa filter tidak menjual apa pun).")
            return
        end
        if config.sellFilters.Rarity["Cosmic"] then
            warnOnce("sell_cosmic", "Peringatan Auto Sell: 'Cosmic' juga nama biome, jadi egg biome Cosmic bisa ikut terjual. Cek Debug > Scan Backpack dulu.")
        end
        local list = {}
        for _, t in ipairs(allTools()) do
            if isEggTool(t) then
                local text = itemText(t)
                if not isFavorited(t, text) and passesFilters(t, text, config.sellFilters) then
                    table.insert(list, t)
                end
            end
        end
        if #list == 0 then return end
        local n = sellTools(list, "egg")
        if n > 0 then log("Auto Sell: " .. n .. " egg terjual") end
    end

    local favTried = {}
    function V25.autoFavoriteOnce()
        local names = parseNames(config.favNames)
        if #names == 0 and not hasAnyFilter(config.favFilters) then
            warnOnce("fav_nocrit", "Auto Favorit: isi nama atau pilih rarity/variant dulu.")
            return
        end
        local done, fails = 0, 0
        for _, t in ipairs(allTools()) do
            if done >= 8 or not uiAlive then break end
            if not isGearTool(t) and (favTried[t] == nil or favTried[t] < os.clock()) then
                local text = itemText(t)
                if not isFavorited(t, text) and matchesSpec(t, text, names, config.favFilters) then
                    favTried[t] = os.clock() + 300
                    if equipHeld(t) then
                        local clicked = clickLabeled(HINTS.favorite, { "unfav", "unlock" })
                        if not clicked then
                            warnOnce("fav_btn", "Auto Favorit: tombol 'Favorite' tidak ditemukan di layar. Buka inventory/menu item dulu, atau cek Debug > Scan Aksi.")
                            break
                        end
                        task.wait(0.4)
                        if isFavorited(t, itemText(t)) then
                            done += 1
                            fails = 0
                        else
                            fails += 1
                            if fails >= 2 then
                                warnOnce("fav_fail", "Auto Favorit: klik tombol tidak mengubah status item (butuh langkah lain). Dihentikan.")
                                break
                            end
                        end
                    end
                end
            end
        end
        if done > 0 then log("Auto Favorit: " .. done .. " item") end
    end

    local function contextText(btn)
        local parts = {}
        local cur = btn
        for _ = 1, 5 do
            if not cur or cur == playerGui then break end
            table.insert(parts, cur.Name:lower())
            local parent = cur.Parent
            if parent then
                for _, sib in ipairs(parent:GetChildren()) do
                    if sib:IsA("TextLabel") and sib.Text ~= "" then table.insert(parts, sib.Text:lower()) end
                end
            end
            cur = parent
        end
        return table.concat(parts, " ")
    end

    local function hasWord(text, words)
        for _, w in ipairs(words) do
            if text:find(w, 1, true) then return true end
        end
        return false
    end

    local function upgradeOnce(key)
        local def = UPGRADES[key]
        ensureBase()
        local clicked = 0
        for _, b in ipairs(findButtons(HINTS.upgrade, false)) do
            local ctx = contextText(b)
            if hasWord(ctx, def.words) and not ctx:find("robux", 1, true) and not ctx:find("r$", 1, true) then
                if clickButton(b) then
                    clicked += 1
                    task.wait(0.3)
                end
                if clicked >= 5 then break end
            end
        end
        if clicked == 0 then
            local hrp = getHRP()
            local n = 0
            for _, p in ipairs(Snapshot.get()) do
                if n >= 3 or not hrp then break end
                if p:IsA("ProximityPrompt") and p.Parent and p.Enabled and promptMatches(p, HINTS.upgrade) then
                    local pos = getPromptPosition(p)
                    local full = p:GetFullName():lower()
                    if pos and hasWord(full, def.words) and (ownedByMe(p) or nearBase(pos, BASE_RADIUS)) then
                        goTo(hrp, pos + Vector3.new(0, 3, 0), alive)
                        task.wait(0.2)
                        triggerPrompt(p)
                        clicked += 1
                        n += 1
                        task.wait(0.4)
                    end
                end
            end
            if clicked > 0 then backToBase() end
        end
        if clicked > 0 then
            log("Auto Upgrade " .. def.name .. ": " .. clicked .. "x")
        else
            warnOnce("upg_" .. key, "Auto Upgrade " .. def.name .. ": tombol/prompt Upgrade tidak ditemukan. Buka menu upgrade-nya dan biarkan terbuka, atau cek Debug > Scan Aksi.")
        end
    end

    function V25.autoUpgTrailOnce() upgradeOnce("upgTrail") end
    function V25.autoUpgTreadmillOnce() upgradeOnce("upgTreadmill") end
    function V25.autoUpgBaseOnce() upgradeOnce("upgBase") end

    function V25.autoPetPlaceOnce()
        ensureBase()
        local names = parseNames(config.petPlaceNames)
        if #names == 0 and not hasAnyFilter(config.petPlaceFilters) then
            warnOnce("petplace_nocrit", "Pet Place: isi nama atau pilih rarity dulu.")
            return
        end
        local chosen
        for _, t in ipairs(allTools()) do
            if isPetTool(t) then
                local text = itemText(t)
                if matchesSpec(t, text, names, config.petPlaceFilters) then
                    chosen = t
                    break
                end
            end
        end
        if not chosen then
            warnOnce("petplace_none", "Pet Place: tidak ada pet di backpack yang cocok (pet mungkin bukan Tool, cek Debug > Scan Backpack).")
            return
        end
        if not equipHeld(chosen) then return end
        local n = actOnPrompts(HINTS.place)
        if n > 0 then log("Pet Place: " .. n .. " prompt dipicu (" .. chosen.Name .. ")") end
    end

    function V25.autoPetSellOnce()
        ensureBase()
        local names = parseNames(config.petSellNames)
        if #names == 0 and not hasAnyFilter(config.petSellFilters) then
            warnOnce("petsell_nocrit", "Pet Sell: isi nama atau pilih rarity dulu (tanpa kriteria tidak menjual apa pun).")
            return
        end
        local list = {}
        for _, t in ipairs(allTools()) do
            if isPetTool(t) then
                local text = itemText(t)
                if not isFavorited(t, text) and matchesSpec(t, text, names, config.petSellFilters) then
                    table.insert(list, t)
                end
            end
        end
        if #list == 0 then return end
        local n = sellTools(list, "pet")
        if n > 0 then log("Pet Sell: " .. n .. " pet terjual") end
    end

    function V25.scanBackpack(dbg)
        dbg("== SCAN BACKPACK ==")
        for i, t in ipairs(allTools()) do
            if i > 40 then
                dbg("... (dipotong 40 pertama)")
                break
            end
            local text = itemText(t)
            local kind = isEggTool(t) and "EGG" or (isGearTool(t) and "GEAR" or "PET/ITEM")
            local attrs = {}
            for k, v in pairs(t:GetAttributes()) do table.insert(attrs, tostring(k) .. "=" .. tostring(v)) end
            dbg(("%s | %s | fav=%s | attr: %s"):format(t.Name, kind, tostring(isFavorited(t, text)), #attrs > 0 and table.concat(attrs, ", ") or "-"))
        end
    end

    function V25.scanActions(dbg)
        dbg("== SCAN AKSI (tombol sell / upgrade / favorite yang terlihat) ==")
        local n = 0
        for _, group in ipairs({ HINTS.sell, HINTS.upgrade, HINTS.favorite }) do
            for _, b in ipairs(findButtons(group, false)) do
                n += 1
                if n > 40 then
                    dbg("... (dipotong 40 pertama)")
                    return
                end
                dbg(("%s | teks='%s' | konteks: %s"):format(b:GetFullName(), buttonLabel(b), contextText(b):sub(1, 90)))
            end
        end
        if n == 0 then dbg("Tidak ada tombol terlihat. Buka menu jual/upgrade/inventory dulu lalu scan lagi.") end
    end

    local function optsOf(cat)
        for _, entry in ipairs(FILTERS) do
            if entry[1] == cat then return entry[2] end
        end
        return {}
    end

    local function hitsOf(root, text, cat)
        local hits = {}
        for _, o in ipairs(optsOf(cat)) do
            if matchesValue(root, text, o) then table.insert(hits, o) end
        end
        return hits
    end

    local function eggPredictText()
        local hrp = getHRP()
        if not hrp then return "Karakter belum ada" end
        local list = {}
        for _, p in ipairs(collectEggPrompts()) do
            local pos = getPromptPosition(p)
            if pos and not (config.skipOwn and ownedByMe(p)) then
                table.insert(list, { p = p, pos = pos, d = (pos - hrp.Position).Magnitude })
            end
        end
        if #list == 0 then return "Tidak ada telur terdeteksi (dekati area telur agar map ter-load)" end
        table.sort(list, function(a, b) return a.d < b.d end)
        local filterOn = config.targetMode == "Filter" and hasAnyFilter(config.filters)
        local lines = {}
        for i = 1, math.min(4, #list) do
            local e = list[i]
            local root = getEggRoot(e.p)
            local text = collectEggText(root)
            local rar = hitsOf(root, text, "Rarity")
            local var = hitsOf(root, text, "Variant")
            local siz = hitsOf(root, text, "Size")
            local area = detectAreaFromText(norm(collectAncestorText(e.p) .. " " .. text)) or nearestAreaByCenter(e.pos) or "?"
            local verdict = filterOn and (passesFilters(root, text, config.filters) and "LOLOS" or "TIDAK") or "-"
            table.insert(lines, ("#%d %s | %s | %s | %s | %d stud | filter: %s"):format(
                i,
                #rar > 0 and table.concat(rar, "/") or "rarity ?",
                #var > 0 and table.concat(var, "/") or "Normal",
                #siz > 0 and siz[1] or "size ?",
                area, math.floor(e.d), verdict))
        end
        return table.concat(lines, "\n")
    end

    local predictToken = 0
    function V25.startEggPredict()
        predictToken += 1
        local my = predictToken
        task.spawn(function()
            while uiAlive and config.eggPredict and predictToken == my do
                local ok, txt = pcall(eggPredictText)
                if ui.predictLabel then
                    ui.predictLabel.Text = ok and txt or ("Error: " .. tostring(txt))
                end
                task.wait(2.5)
            end
        end)
    end
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

local ensureBrain

local function setAuto(key, on, fn)
    config.auto[key] = on
    if on then
        if config.priorityOn then ensureBrain() else runAutoLoop(key, fn) end
    end
end

-- ==========================================
-- V25: PRIORITY
-- ==========================================
do
    V25.AUTO_META = {
        hatch = { "Auto Hatch", autoHatchOnce },
        place = { "Auto Place", autoPlaceOnce },
        fuse = { "Auto Fuse", autoFuseOnce },
        index = { "Auto Claim Index", autoIndexOnce },
        sell = { "Auto Sell Egg", V25.autoSellOnce },
        favorite = { "Auto Favorit", V25.autoFavoriteOnce },
        upgTrail = { "Upgrade Trail", V25.autoUpgTrailOnce },
        upgTreadmill = { "Upgrade Treadmill", V25.autoUpgTreadmillOnce },
        upgBase = { "Upgrade Base", V25.autoUpgBaseOnce },
        petPlace = { "Pet: Taruh di Plot", V25.autoPetPlaceOnce },
        petSell = { "Pet: Jual", V25.autoPetSellOnce },
    }
    V25.AUTO_ORDER = { "hatch", "place", "fuse", "index", "sell", "favorite", "upgTrail", "upgTreadmill", "upgBase", "petPlace", "petSell" }

    V25.PRIORITY_OPTIONS = {
        { id = "none", label = "- Kosong -" },
        { id = "event", label = "Event (yang aktif)" },
    }
    for _, key in ipairs(V25.AUTO_ORDER) do
        table.insert(V25.PRIORITY_OPTIONS, { id = key, label = V25.AUTO_META[key][1] })
    end

    local valid = { none = true, event = true }
    for k in pairs(V25.AUTO_META) do valid[k] = true end
    local fixed = { "steal" }
    local src = type(config.priority) == "table" and config.priority or {}
    for i = 2, 7 do
        local id = src[i]
        fixed[i] = (type(id) == "string" and valid[id]) and id or "none"
    end
    config.priority = fixed

    V25.lastAutoRun = {}
    function V25.autoDue(key)
        local iv = key == "index" and 60 or config.autoInterval
        return os.clock() - (V25.lastAutoRun[key] or 0) >= iv
    end

    function V25.applyPriorityMode(on)
        config.priorityOn = on and true or false
        if on then
            for key in pairs(autoTokens) do autoTokens[key] = autoTokens[key] + 1 end
            ensureBrain()
        else
            for key, meta in pairs(V25.AUTO_META) do
                if config.auto[key] then runAutoLoop(key, meta[2]) end
            end
        end
    end
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
-- AFK MANAGER
-- ==========================================
local function anyPriorityAutoEnabled()
    if not config.priorityOn then return false end
    for key in pairs(V25.AUTO_META) do
        if config.auto[key] then return true end
    end
    return false
end

brainWanted = function()
    return uiAlive and (config.running or anyEventEnabled() or config.treadmillIdle or anyPriorityAutoEnabled())
end

local brainRunning = false
function ensureBrain()
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
                if config.priorityOn then
                    for _, id in ipairs(config.priority) do
                        if not brainWanted() then break end
                        if id == "steal" then
                            if config.running and stealCycle(aliveSteal) ~= "none" then
                                did = true
                                return
                            end
                        elseif id == "event" then
                            if anyEventEnabled() and eventStep(aliveEvents) then
                                did = true
                                return
                            end
                        else
                            local meta = V25.AUTO_META[id]
                            if meta and config.auto[id] and V25.autoDue(id) then
                                V25.lastAutoRun[id] = os.clock()
                                local okA, errA = pcall(meta[2])
                                if not okA then log("Priority " .. meta[1] .. " error: " .. tostring(errA)) end
                                did = true
                                return
                            end
                        end
                    end
                else
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
                end
                if config.treadmillIdle then
                    Treadmill.run(4)
                else
                    task.wait(2.5)
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
-- PERFORMA
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

-- ==========================================
-- V25: MODE AFK HEMAT
-- ==========================================
do
    local savedVolume
    function V25.setAfkSaver(state)
        config.afkSaver = state and true or false
        pcall(function() RunService:Set3dRenderingEnabled(not state) end)
        if typeof(setfpscap) == "function" then
            pcall(setfpscap, state and math.clamp(config.fpsCap, 5, 60) or 60)
        end
        pcall(function()
            local gs = UserSettings():GetService("UserGameSettings")
            if state then
                savedVolume = savedVolume or gs.MasterVolume
                gs.MasterVolume = 0
            elseif savedVolume then
                gs.MasterVolume = savedVolume
                savedVolume = nil
            end
        end)
        if state then
            task.spawn(function()
                while config.afkSaver and uiAlive do
                    task.wait(45)
                    pcall(function() collectgarbage("collect") end)
                end
            end)
        end
    end
end

-- ==========================================
-- CLEANUP
-- ==========================================
local function cleanup()
    uiAlive = false
    config.running = false
    config.treadmillIdle = false
    config.statsWebhookOn = false
    config.eggWebhookOn = false
    config.priorityOn = false
    config.eggPredict = false
    if config.afkSaver then pcall(V25.setAfkSaver, false) end
    for k in pairs(config.events) do config.events[k] = false end
    for k in pairs(config.auto) do config.auto[k] = false end
    Protect.flying = false
    Protect.treadmillActive = false
    -- [V28 SAFE] Selalu simpan sekali di akhir supaya preferensi user tidak hilang.
    pcall(saveSettings)

    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    table.clear(connections)
    for _, c in ipairs(popupConns) do pcall(function() c:Disconnect() end) end
    table.clear(popupConns)
    if antiLagConn then pcall(function() antiLagConn:Disconnect() end) end
    if plotWatcher then pcall(function() plotWatcher:Disconnect() end) end

    local _, hum = getChar()
    if hum then
        pcall(function()
            hum:Move(Vector3.zero, false)
            hum.PlatformStand = false
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        end)
    end
    if sg then pcall(function() sg:Destroy() end) end
    if _G.EX_STEAL_EGG_CLEANUP == cleanup then _G.EX_STEAL_EGG_CLEANUP = nil end
end
_G.EX_STEAL_EGG_CLEANUP = cleanup

-- ==========================================
-- BACKGROUND IMAGE (opt-in)
-- ==========================================
do
    local BG_FILE = "EX_StealAnEgg_bg_v27.jpg"
    local BG_BYTES = 38906
    local BG_B64 = [==[
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