--[[
    STEAL AN EGG PREMIUM | EX - TNJ  -  V27 (PATCHED & ANTI-KICK OPTIMIZED)

    Perbaikan (Patched by AI):
      * GUI dipindahkan aman ke CoreGui/gethui (Bypass scan PlayerGui), fallback otomatis ke PlayerGui.
      * Modifikasi brutal ProximityPrompt dinonaktifkan (Cegah Instant Kick).
      * Anti-Trap un-anchor paksa dinonaktifkan (Cegah Kick saat loading map).
      * Anti-Lag tidak lagi men-destroy map assets, hanya mendisable (Aman dari map scan).
      * Fallback aman untuk semua fungsi khusus executor agar script 100% bisa dieksekusi.

    Perubahan V27:
      * UI hanya warna ungu & hitam, garis/border lebih tebal (kesan premium), judul "STEAL AN EGG PREMIUM | EX - TNJ".
      * Tiap tab punya ikon simbol (digambar dari shape, tidak bergantung font/emoji).
      * Tombol minimize lebih kecil. Ikon minimize: gambar blackhole + tulisan "EX" + border berputar tebal.
      * Efek petir & batu jatuh di border menu (kolam objek tetap, update 30x/detik, hanya aktif saat menu terbuka).
        Bisa dimatikan di tab CONFIG ("Efek Petir & Batu").
      * Mode Terbang dipercepat: default 130, akselerasi lebih tajam, tidak berhenti di tiap titik antara.
      * Background memakai gambar blackhole terbaru.

    Perubahan V26:
      * Gerak ala humanoid: default sekarang "Jalan" (berjalan + pathfinding + lompat), tidak ada teleport kasar lagi.
        Mode "Terbang" dibuat halus (akselerasi/perlambatan, badan menghadap arah gerak, tanpa lonjakan).
      * Sapuan area (memuat map) tidak lagi teleport ke tiap area; berjalan/terbang halus dan jedanya diperpanjang.
      * Scanning diringankan: snapshot Workspace di-cache lebih lama, cache daftar telur, hanya telur terdekat yang diperiksa,
        Egg Predict lebih jarang, jeda lebih panjang saat tidak ada target.
      * Background menu memakai gambar blackhole (gambar asli tanpa dikompres ulang, disimpan sebagai file di workspace executor).

    Dasar: V25. Tambahan V25:
      * Resize menu: tarik pojok kanan-bawah (ke kiri-atas = mengecil). Ukuran ikut tersimpan.
      * MAIN: Egg Predict, Auto Sell Egg (filter rarity), Legit Steal, Auto Favorit (nama/rarity/variant).
      * PRIORITY: urutan kerja AFK manager (default OFF; #1 selalu Steal Egg; #2-#7 bisa diatur).
      * AUTOMATION: Auto Upgrade Trail / Treadmill / Base, Pet Automation (taruh & jual pet).
      * Variant diperbarui (8 Okt 2026): Silver, Golden, Rainbow, Bloom, Spirit Bloom, Parasite, Fractured, Scrambled.
      * Pembersih popup '+Speed' & partikel dibuat ringan (antrean batch) + Mode AFK Hemat (3D off, FPS cap).

    CATATAN: fitur yang bergantung pada nama objek di game (hatch, place, sell, favorit, upgrade, dll)
    memakai deteksi kata kunci. Edit tabel HINTS / UPGRADES di bawah kalau nama di game berbeda.
    Gunakan tab Debug (Scan Backpack / Scan Aksi / Scan UI) untuk melihat nama aslinya.
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

-- Bersihkan versi sebelumnya (Patch: Bersihkan juga di CoreGui)
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

local VERSION = "V27 (Patched)"
local SAVE_FILE = "EX_StealAnEgg_V26.json"
local OLD_SAVE_FILE = "EX_StealAnEgg_V25.json"
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
    sell = { "sell" },
    favorite = { "favorite", "favourite" },
    upgrade = { "upgrade" },
}

-- kata kunci konteks untuk Auto Upgrade (dicocokkan ke nama/teks di sekitar tombol Upgrade)
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
    -- daftar mutasi per 8 Okt 2026 (+ "Normal" = tanpa mutasi)
    { "Variant", { "Normal", "Silver", "Golden", "Rainbow", "Bloom", "Spirit Bloom", "Parasite", "Fractured", "Scrambled" } },
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
    -- palet: hanya ungu & hitam
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
    running = false,          -- auto steal
    treadmillIdle = false,
    method = S("method", "Walk"),         -- "Walk" (jalan ala humanoid) | "Fly" (terbang halus). "Instant" (teleport) sudah dihapus.
    targetMode = S("targetMode", "All"),  -- "All" | "Filter"
    filters = newFilterSet("filters"),
    placeFilters = newFilterSet("placeFilters"),
    areas = listToSet(S("areas", {})),
    skipOwn = S("skipOwn", true),
    legit = S("legit", false),
    eggPredict = false,
    priorityOn = false,       -- default OFF
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
    flySpeed = S("flySpeed2", 130),     -- V27: default lebih cepat (kunci simpanan baru)
    flyHeight = S("flyHeight", 12),
    fxBorder = S("fxBorder", true),     -- efek petir & batu di border menu
    antiKB = S("antiKB", false),
    antiTrap = S("antiTrap", false),
    antiAfk = S("antiAfk", true),
    pingPanel = S("pingPanel", true),
    removePopups = S("cleanFx", true),   -- default ON (hapus popup +Speed & partikel)
    antiLag = S("antiLag", false),
    autoSave = S("autoSave", true),       -- default ON
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

local V25 = {}   -- wadah fungsi tambahan V25 (menghemat jumlah local di level atas)
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
        autoInterval = config.autoInterval,
        eggWebhookUrl = config.eggWebhookUrl,
        statsWebhookUrl = config.statsWebhookUrl,
        statsIntervalMin = config.statsIntervalMin,
        areaCenters = centers,
    }
    local okEnc, json = pcall(function() return HttpService:JSONEncode(data) end)
    if not okEnc then return false end
    if not force and json == lastSavedJson then return true end -- tidak ada perubahan, tidak perlu tulis file
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

-- Snapshot descendants Workspace (V26: di-cache 5 detik supaya tidak berat)
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
    -- [PATCH] Dihapus modifikasi HoldDuration dan ActivationDistance agar tidak memicu deteksi Anti-Cheat
    -- pcall(function()
    --    prompt.HoldDuration = 0
    --    prompt.RequiresLineOfSight = false
    --    prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance, 25)
    -- end)

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
    Protect.charConn = track(char.DescendantAdded:Connect(function(d)
        if config.antiKB and not Protect.treadmillActive and BODY_MOVERS[d.ClassName] then
            -- [PATCH] Diubah agar tidak men-destroy physics object bawaan map jika salah deteksi
            task.defer(function()
                pcall(function()
                    if d:IsA("Constraint") then
                        d.Enabled = false
                    elseif d:IsA("BodyMover") then
                        d:Destroy() -- BodyMovers safe to destroy on character
                    end
                end)
            end)
        end
    end))
end
track(player.CharacterAdded:Connect(Protect.bindChar))
if player.Character then Protect.bindChar(player.Character) end

function Protect.unstick(hrp)
    -- dorongan kecil + lompat (bukan lonjakan 10 stud seperti sebelumnya)
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
        -- [PATCH] Dihapus un-anchoring paksa agar tidak memicu deteksi eksploit saat event loading map.
        -- if hrp.Anchored then hrp.Anchored = false end

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

-- V26: hasil di-cache 2 detik (dipakai findTarget, Egg Predict, dll) supaya tidak scan ulang terus-menerus
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

    -- V26: urutkan dari yang terdekat dulu (murah), lalu periksa detail hanya sampai ketemu yang cocok.
    -- Jauh lebih ringan daripada memeriksa teks/atribut semua telur tiap siklus.
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
-- Terbang halus: kecepatan naik pelan (akselerasi), melambat saat mendekati tujuan,
-- dan badan perlahan menghadap arah gerak (tidak patah-patah / tidak "loncat").
-- V27: lebih cepat. 'through' (angka jarak) = titik antara: tidak melambat & kecepatan dibawa ke ruas berikutnya.
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

        -- deteksi macet (anti trapped): tidak bergerak > 1.2 detik
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

-- Pendaratan aman (anti tenggelam): raycast ke bawah, hanya dipakai bila tanah dekat dengan titik tujuan
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
        -- mode Jalan: berjalan seperti pemain biasa (pathfinding + lompat), tanpa teleport
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
        -- jalan/terbang halus ke treadmill (tidak teleport)
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
            -- melenceng dari treadmill: berjalan kembali, bukan teleport
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

-- hapus popup "+123 Speed" dan partikel efek (hemat CPU/RAM saat AFK di treadmill)
-- Perbaikan V25: proses antrean per batch (tidak membuat task baru per objek), dan partikel
-- (ParticleEmitter/Trail/Beam/Smoke/Fire/Sparkles) langsung dimatikan lalu dihapus.
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
        -- [PATCH] Fix Anti-Lag destroying map assets
        -- task.defer(function() pcall(function() inst:Destroy() end) end)
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
        -- sapuan awal, dipecah supaya tidak membekukan game
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
-- V25: LEGIT STEAL (jalan kaki + tahan tombol seperti pemain biasa)
-- ==========================================
do
    local PathfindingService = game:GetService("PathfindingService")

    local function flatDist(a, b)
        return (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude
    end

    -- jalan ke tujuan memakai pathfinding; fallback lurus. Return true bila sampai (jarak datar < 8 stud)
    function V25.legitWalk(dest, alive)
        local hrp, hum = getChar()
        if not hrp or not hum then return false end
        if flatDist(hrp.Position, dest) <= 8 then return true end   -- sudah dekat, tidak perlu menghitung path
        local speed = math.max(hum.WalkSpeed, 8)
        local limit = math.max(12, flatDist(hrp.Position, dest) / speed * 2 + 10)
        local t0 = os.clock()
        setStatus("Berjalan...", THEME.accent2)

        -- anti macet ala pemain: bila tidak bergerak ~1 detik, melompat
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
        -- sisa jarak (atau tanpa path): jalan lurus
        while alive() and hrp.Parent and os.clock() - t0 <= limit and flatDist(hrp.Position, dest) > 8 do
            hum:MoveTo(dest)
            task.wait(0.25)
            nudgeIfStuck(stuck)
        end
        hum:Move(Vector3.zero, false)
        return hrp.Parent ~= nil and flatDist(hrp.Position, dest) <= 8
    end

    -- tahan prompt selama HoldDuration aslinya (tidak dipaksa 0)
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
    if config.legit then return nil end   -- mode legit: tidak keliling area

    -- sapuan area dibuat jarang: minimal jeda 90 detik, dan maksimal 2 area per sapuan (bergiliran)
    if os.clock() - lastSweep < 90 then return nil end
    lastSweep = os.clock()

    -- kunjungi titik area (jalan/terbang halus, bukan teleport) agar map ter-stream, lalu cari lagi
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
    -- tidak ketemu: kembali ke base supaya tidak diam di tengah area
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

    -- prompt bisa nonaktif sampai kita dekat: tunggu sebentar lalu paksa aktif
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
                -- ikuti target dengan jalan/terbang halus (tidak teleport)
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
    else -- touch
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

-- ==========================================
-- V25: ITEM, SELL, FAVORIT, UPGRADE, PET, EGG PREDICT
-- (dibungkus do-block supaya tidak menambah jumlah local di level atas)
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

    -- cocok bila NAMA cocok ATAU filter (rarity/variant) cocok. Tanpa kriteria sama sekali = tidak cocok.
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

    -- klik tombol HUD yang cocok kata kunci, kecuali yang mengandung kata terlarang
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

    -- ---------- SELL ----------
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

    -- ---------- FAVORIT ----------
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

    -- ---------- UPGRADE (Trail / Treadmill / Base) ----------
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

    -- ---------- PET AUTOMATION ----------
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

    -- ---------- DEBUG: BACKPACK & AKSI ----------
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

    -- ---------- EGG PREDICT ----------
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

local ensureBrain   -- deklarasi awal, diisi di bagian AFK manager di bawah

local function setAuto(key, on, fn)
    config.auto[key] = on
    if on then
        if config.priorityOn then ensureBrain() else runAutoLoop(key, fn) end
    end
end

-- ==========================================
-- V25: PRIORITY (urutan kerja AFK manager)
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

    -- rapikan config.priority: slot 1 selalu steal, slot 2-7 harus id yang valid
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

    -- ON: loop mandiri tiap fitur dihentikan, AFK manager yang mengatur. OFF: loop mandiri dinyalakan lagi.
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
-- AFK MANAGER (satu loop untuk event > steal > treadmill)
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
                    -- mode PRIORITY: ikuti urutan slot; #1 = steal
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
                    task.wait(2.5)   -- V26: tidak ada kerjaan = istirahat lebih lama, tidak scan terus
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

-- ==========================================
-- V25: MODE AFK HEMAT (3D render off + batas FPS + volume 0)
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
-- CLEANUP (dipanggil saat script dieksekusi ulang / tombol Unload)
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
    if config.autoSave then pcall(saveSettings) end

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
-- V26: GAMBAR BACKGROUND (blackhole, 736x414 asli, tanpa kompresi ulang)
-- Gambar disimpan sekali sebagai file di workspace executor lalu dimuat via getcustomasset.
-- Bila executor tidak mendukung, otomatis dipakai background blackhole animasi bawaan.
-- ==========================================
do
    local BG_FILE = "EX_StealAnEgg_bg_v27.jpg"
    local BG_BYTES = 38906
    local BG_B64 = [==[
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
]==]

    local function b64decode(data)
        data = (data:gsub("[^%w%+/=]", ""))
        local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local lookup = {}
        for i = 1, 64 do lookup[chars:sub(i, i)] = i - 1 end
        local out, n = {}, 0
        for i = 1, #data, 4 do
            local c3, c4 = data:sub(i + 2, i + 2), data:sub(i + 3, i + 3)
            local v = (lookup[data:sub(i, i)] or 0) * 262144
                + (lookup[data:sub(i + 1, i + 1)] or 0) * 4096
                + (lookup[c3] or 0) * 64
                + (lookup[c4] or 0)
            local b1 = math.floor(v / 65536)
            local b2 = math.floor(v / 256) % 256
            local b3 = v % 256
            n += 1
            if c3 == "=" then
                out[n] = string.char(b1)
            elseif c4 == "=" then
                out[n] = string.char(b1, b2)
            else
                out[n] = string.char(b1, b2, b3)
            end
        end
        return table.concat(out)
    end

    function V25.loadBgImage()
        local gca = getcustomasset or getsynasset
        if typeof(gca) ~= "function" or typeof(writefile) ~= "function"
            or typeof(isfile) ~= "function" or typeof(readfile) ~= "function" then
            return nil
        end
        local ok, asset = pcall(function()
            local need = true
            if isfile(BG_FILE) then
                local okR, cur = pcall(readfile, BG_FILE)
                if okR and type(cur) == "string" and #cur == BG_BYTES then need = false end
            end
            if need then
                local bytes = b64decode(BG_B64)
                if #bytes ~= BG_BYTES then error("ukuran gambar tidak cocok setelah decode") end
                writefile(BG_FILE, bytes)
            end
            return gca(BG_FILE)
        end)
        if ok and type(asset) == "string" and asset ~= "" then return asset end
        return nil
    end
end

-- ==========================================
-- UI
-- ==========================================
local function buildUI()
    local camera = Workspace.CurrentCamera
    local vp = camera and camera.ViewportSize or Vector2.new(900, 600)
    local W = math.max(340, math.min(config.winW, vp.X - 16))
    local H = math.max(280, math.min(config.winH, vp.Y - 16))
    local SIDE = 112
    local FONT_B, FONT_M, FONT_R = Enum.Font.GothamBold, Enum.Font.GothamMedium, Enum.Font.Gotham
    local WHITE = Color3.new(1, 1, 1)
    local orderCounter = 0

    -- ---------- helper pembuat objek ----------
    local function new(class, props, parent)
        local o = Instance.new(class)
        for k, v in pairs(props) do o[k] = v end
        if o:IsA("GuiObject") and props.LayoutOrder == nil then
            orderCounter += 1
            o.LayoutOrder = orderCounter
        end
        if parent then o.Parent = parent end
        return o
    end

    local function corner(o, r)
        new("UICorner", { CornerRadius = UDim.new(0, r or 6) }, o)
    end

    -- tinggi frame mengikuti isi layout
    local function fit(frame, layout)
        local function upd()
            frame.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
        end
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(upd)
        upd()
    end

    local function makeDraggable(handle, target)
        local state = { moved = false }
        local dragging, dragStart, startPos = false, nil, nil
        track(handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                state.moved = false
                dragStart = input.Position
                startPos = target.Position
                local conn
                conn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        if conn then conn:Disconnect() end
                    end
                end)
            end
        end))
        track(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                if d.Magnitude > 6 then state.moved = true end
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end))
        return state
    end

    -- ---------- jendela utama ----------
    -- [PATCH] GUI dipasang ke gethui()/CoreGui (aman dari scan PlayerGui); fallback ke PlayerGui bila gagal
    sg = new("ScreenGui", {
        Name = "EX_StealAnEgg_V27",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
    })
    do
        local guiParent
        pcall(function()
            if typeof(gethui) == "function" then guiParent = gethui() end
        end)
        if not guiParent then
            pcall(function() guiParent = game:GetService("CoreGui") end)
        end
        local placed = false
        if guiParent then
            placed = pcall(function() sg.Parent = guiParent end) and sg.Parent == guiParent
        end
        if not placed then sg.Parent = playerGui end
    end

    local win = new("Frame", {
        Name = "Window",
        Size = UDim2.fromOffset(W, H),
        Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2),
        BackgroundColor3 = Color3.fromRGB(4, 2, 10),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, sg)
    corner(win, 10)
    local winStroke = new("UIStroke", { Color = WHITE, Thickness = 4 }, win)
    local strokeGrad = new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, THEME.accent),
            ColorSequenceKeypoint.new(0.5, THEME.accent2),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 20, 130)),
        }),
    }, winStroke)


    -- ---------- background: gambar blackhole (fallback: blackhole animasi) ----------
    local bh = { rings = {}, stars = nil, disc = nil, core = nil }
    local bgAsset = V25.loadBgImage()
    if bgAsset then
        local bgFrame = new("Frame", {
            Name = "BlackholeImageBG",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(4, 2, 10),
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = -5,
        }, win)
        corner(bgFrame, 10)
        -- Crop: gambar menutupi seluruh jendela tanpa gepeng (rasio 16:9 asli dijaga)
        local img = new("ImageLabel", {
            Name = "BlackholeImage",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image = bgAsset,
            ImageTransparency = 0,
            ScaleType = Enum.ScaleType.Crop,
            ZIndex = -4,
        }, bgFrame)
        corner(img, 10)
        -- peredam tipis supaya teks menu tetap terbaca, gambar tetap jelas
        local dim = new("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(6, 3, 14),
            BackgroundTransparency = 0.66,
            BorderSizePixel = 0,
            ZIndex = -3,
        }, bgFrame)
        corner(dim, 10)
    else
        local bgRoot = new("Frame", {
            Name = "BlackholeBG",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(4, 2, 10),
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = -5,
        }, win)
        corner(bgRoot, 10)

        local D = math.max(W, H) * 1.5
        local function disc(size, color, transp, z)
            local f = new("Frame", {
                Size = UDim2.fromOffset(size, size),
                Position = UDim2.new(0.5, -size / 2, 0.5, -size / 2),
                BackgroundColor3 = color,
                BackgroundTransparency = transp,
                BorderSizePixel = 0,
                ZIndex = z,
            }, bgRoot)
            new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
            return f
        end

        -- glow ungu lembut
        disc(D * 1.15, Color3.fromRGB(60, 20, 120), 0.82, -4)
        disc(D * 0.85, Color3.fromRGB(90, 30, 170), 0.78, -4)

        -- cincin akresi berputar (gradien stroke)
        local ringDefs = {
            { D * 0.78, 10, 0.05, 38 },
            { D * 0.62, 14, 0.00, -62 },
            { D * 0.48, 9,  0.10, 95 },
        }
        for i, r in ipairs(ringDefs) do
            local ring = disc(r[1], Color3.new(0, 0, 0), 1, -3)
            local st = new("UIStroke", { Thickness = r[2], Transparency = r[3], Color = WHITE }, ring)
            local g = new("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 190, 90)),
                    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 80, 200)),
                    ColorSequenceKeypoint.new(0.55, Color3.fromRGB(110, 70, 255)),
                    ColorSequenceKeypoint.new(0.8, Color3.fromRGB(60, 200, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 190, 90)),
                }),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.5, 0.75),
                    NumberSequenceKeypoint.new(1, 0),
                }),
            }, st)
            bh.rings[i] = { grad = g, speed = r[4] }
        end

        -- bintang berputar mengitari blackhole
        local starLayer = new("Frame", {
            Size = UDim2.fromOffset(D, D),
            Position = UDim2.new(0.5, -D / 2, 0.5, -D / 2),
            BackgroundTransparency = 1,
            ZIndex = -2,
        }, bgRoot)
        local rng = Random.new(77)
        for _ = 1, 46 do
            local ang = rng:NextNumber(0, math.pi * 2)
            local rad = rng:NextNumber(0.14, 0.5) * D
            local sz = rng:NextInteger(1, 3)
            local dot = new("Frame", {
                Size = UDim2.fromOffset(sz, sz),
                Position = UDim2.new(0.5, math.cos(ang) * rad - sz / 2, 0.5, math.sin(ang) * rad - sz / 2),
                BackgroundColor3 = rng:NextNumber() > 0.5 and WHITE or Color3.fromRGB(190, 170, 255),
                BackgroundTransparency = rng:NextNumber(0.1, 0.6),
                BorderSizePixel = 0,
                ZIndex = -2,
            }, starLayer)
            new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, dot)
        end
        bh.stars = starLayer

        -- horizon peristiwa: lubang hitam pekat + tepi bercahaya
        local core = disc(D * 0.34, Color3.new(0, 0, 0), 0, -1)
        local coreStroke = new("UIStroke", { Thickness = 4, Color = Color3.fromRGB(255, 160, 80), Transparency = 0.15 }, core)
        bh.core = core
        bh.coreStroke = coreStroke

        -- peredam supaya teks menu tetap terbaca
        new("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(6, 3, 14),
            BackgroundTransparency = 0.62,
            BorderSizePixel = 0,
            ZIndex = -1,
        }, bgRoot)
    end

    local header = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1 }, win)
    local titleLbl = new("TextLabel", {
        Size = UDim2.new(1, -66, 1, -4),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = "STEAL AN EGG PREMIUM | EX - TNJ",
        TextColor3 = WHITE,
        TextScaled = true,
        Font = FONT_B,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, header)
    new("UITextSizeConstraint", { MaxTextSize = 16, MinTextSize = 8 }, titleLbl)
    new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.55, THEME.accent2),
            ColorSequenceKeypoint.new(1, THEME.accent),
        }),
    }, titleLbl)
    local divider = new("Frame", {
        Size = UDim2.new(1, -24, 0, 3),
        Position = UDim2.new(0, 12, 0, 42),
        BackgroundColor3 = WHITE,
        BorderSizePixel = 0,
    }, win)
    corner(divider, 2)
    new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 16, 120)),
            ColorSequenceKeypoint.new(0.5, THEME.accent),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 16, 120)),
        }),
    }, divider)

    local minBtn = new("TextButton", {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.new(1, -46, 0.5, -11),
        BackgroundColor3 = THEME.off,
        BackgroundTransparency = 0,
        Text = "-",
        TextColor3 = WHITE,
        TextSize = 14,
        Font = FONT_B,
    }, header)
    corner(minBtn, 5)
    new("UIStroke", { Color = THEME.accent2, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, minBtn)
    local closeBtn = new("TextButton", {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.new(1, -24, 0.5, -11),
        BackgroundColor3 = THEME.bad,
        BackgroundTransparency = 0,
        Text = "X",
        TextColor3 = WHITE,
        TextSize = 11,
        Font = FONT_B,
    }, header)
    corner(closeBtn, 5)
    new("UIStroke", { Color = THEME.accent2, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, closeBtn)

    makeDraggable(header, win)

    -- ---------- resize: tarik pojok kanan-bawah (geser ke kiri-atas = mengecil, ke kanan-bawah = membesar) ----------
    local MIN_W, MIN_H = 340, 280
    local grip = new("TextButton", {
        Name = "ResizeGrip",
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.new(1, -30, 1, -30),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 30,
    }, win)
    for _, p in ipairs({ { 21, 21 }, { 14, 21 }, { 21, 14 }, { 7, 21 }, { 14, 14 }, { 21, 7 } }) do
        local dot = new("Frame", {
            Size = UDim2.fromOffset(3, 3),
            Position = UDim2.fromOffset(p[1], p[2]),
            BackgroundColor3 = THEME.accent2,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            ZIndex = 31,
        }, grip)
        corner(dot, 2)
    end
    local resizing, rStart, rSize = false, nil, nil
    track(grip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            rStart = input.Position
            rSize = win.AbsoluteSize
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    config.winW, config.winH = math.floor(win.AbsoluteSize.X), math.floor(win.AbsoluteSize.Y)
                    if conn then conn:Disconnect() end
                end
            end)
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - rStart
            local cam = Workspace.CurrentCamera
            local v = cam and cam.ViewportSize or Vector2.new(900, 600)
            local nw = math.clamp(rSize.X + d.X, MIN_W, math.max(MIN_W, v.X - 8))
            local nh = math.clamp(rSize.Y + d.Y, MIN_H, math.max(MIN_H, v.Y - 8))
            win.Size = UDim2.fromOffset(nw, nh)
        end
    end))

    local icon, iconGrad, iconGlowStroke
    do
        local DARK = Color3.fromRGB(6, 3, 14)
        icon = new("TextButton", {
            Name = "EXIcon",
            Size = UDim2.fromOffset(60, 60),
            Position = UDim2.new(0, 24, 0, 60),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Visible = false,
        }, sg)
        local glow = new("Frame", {
            Size = UDim2.new(1, 12, 1, 12),
            Position = UDim2.new(0, -6, 0, -6),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, icon)
        new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, glow)
        iconGlowStroke = new("UIStroke", { Color = THEME.accent, Thickness = 6, Transparency = 0.7,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, glow)
        local disk = new("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = DARK,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 2,
        }, icon)
        new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, disk)
        local st = new("UIStroke", { Color = WHITE, Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, disk)
        iconGrad = new("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, THEME.accent),
                ColorSequenceKeypoint.new(0.35, Color3.fromRGB(230, 205, 255)),
                ColorSequenceKeypoint.new(0.65, Color3.fromRGB(60, 16, 120)),
                ColorSequenceKeypoint.new(1, THEME.accent),
            }),
        }, st)
        if bgAsset then
            local im = new("ImageLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Image = bgAsset,
                ScaleType = Enum.ScaleType.Crop,
                ZIndex = 3,
            }, disk)
            new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, im)
        end
        local shade = new("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = DARK,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            ZIndex = 4,
        }, disk)
        new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, shade)
        new("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "EX",
            TextColor3 = WHITE,
            TextSize = 22,
            Font = FONT_B,
            TextStrokeColor3 = THEME.accent,
            TextStrokeTransparency = 0.3,
            ZIndex = 5,
        }, disk)
    end
    local iconDrag = makeDraggable(icon, icon)

    minBtn.MouseButton1Click:Connect(function()
        win.Visible = false
        icon.Visible = true
    end)
    icon.MouseButton1Click:Connect(function()
        if iconDrag.moved then return end
        win.Visible = true
        icon.Visible = false
    end)
    closeBtn.MouseButton1Click:Connect(function() cleanup() end)

    -- ---------- EFEK BORDER: petir + batu jatuh (ringan: objek tetap/di-pool, update 30x per detik) ----------
    do
        local rnd = Random.new((os.time() % 100000) + 7)
        local fxLayer = new("Frame", {
            Name = "BorderFX",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            Active = false,
            ZIndex = 25,
            Visible = config.fxBorder ~= false,
        }, win)
        ui.fxLayer = fxLayer
        local CORE_COL = Color3.fromRGB(240, 224, 255)
        local SEGS = 5
        local EDGES = { 1, 3, 2, 4, 3, 4 }   -- 1 atas, 2 bawah, 3 kiri, 4 kanan
        local bolts = {}
        for i = 1, #EDGES do
            local b = { edge = EDGES[i], segs = {}, active = false, nextT = os.clock() + rnd:NextNumber(0.2, 1.5), endT = 0 }
            for s = 1, SEGS + 1 do
                local glow = new("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = THEME.accent,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(2, 7),
                    Visible = false,
                    ZIndex = 26,
                }, fxLayer)
                local core = new("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = CORE_COL,
                    BorderSizePixel = 0,
                    Size = UDim2.fromOffset(2, 3),
                    Visible = false,
                    ZIndex = 27,
                }, fxLayer)
                b.segs[s] = { glow = glow, core = core }
            end
            bolts[i] = b
        end

        local function setSeg(q, x1, y1, x2, y2)
            local dx, dy = x2 - x1, y2 - y1
            local len = math.sqrt(dx * dx + dy * dy) + 2
            local rot = math.deg(math.atan2(dy, dx))
            local pos = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2)
            q.glow.Position = pos
            q.glow.Rotation = rot
            q.glow.Size = UDim2.fromOffset(len, 7)
            q.core.Position = pos
            q.core.Rotation = rot
            q.core.Size = UDim2.fromOffset(len, 3)
            q.glow.Visible = true
            q.core.Visible = true
        end

        local function strike(b)
            local W, H = win.AbsoluteSize.X, win.AbsoluteSize.Y
            local e = b.edge
            local length = (e <= 2) and W or H
            local span = length * rnd:NextNumber(0.22, 0.4)
            local start = rnd:NextNumber(0, math.max(1, length - span))
            local pts = {}
            for i = 0, SEGS do
                local along = start + span * i / SEGS
                local perp = (i == 0 or i == SEGS) and 2 or rnd:NextNumber(3, 13)
                local x, y
                if e == 1 then
                    x, y = along, perp
                elseif e == 2 then
                    x, y = along, H - perp
                elseif e == 3 then
                    x, y = perp, along
                else
                    x, y = W - perp, along
                end
                pts[i] = Vector2.new(x, y)
            end
            for i = 1, SEGS do
                setSeg(b.segs[i], pts[i - 1].X, pts[i - 1].Y, pts[i].X, pts[i].Y)
            end
            -- cabang kecil ke arah dalam
            local o = pts[2]
            local inx, iny = 0, 0
            if e == 1 then iny = 1 elseif e == 2 then iny = -1 elseif e == 3 then inx = 1 else inx = -1 end
            local blen = rnd:NextNumber(10, 20)
            local lat = rnd:NextNumber(-8, 8)
            local tx = o.X + inx * blen + ((e <= 2) and lat or 0)
            local ty = o.Y + iny * blen + ((e > 2) and lat or 0)
            setSeg(b.segs[SEGS + 1], o.X, o.Y, tx, ty)
        end

        local rocks = {}
        for i = 1, 12 do
            local size = rnd:NextInteger(5, 11)
            local f = new("Frame", {
                Size = UDim2.fromOffset(size, size),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(34, 14, 62),
                BorderSizePixel = 0,
                ZIndex = 26,
            }, fxLayer)
            new("UICorner", { CornerRadius = UDim.new(0, 3) }, f)
            new("UIStroke", { Color = THEME.accent, Thickness = 1.5, Transparency = 0.15,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
            rocks[i] = {
                f = f, side = (i % 2 == 0) and 1 or 2,
                y = rnd:NextNumber(-20, 300), vy = rnd:NextNumber(70, 150),
                rot = rnd:NextNumber(0, 360), vr = rnd:NextNumber(-180, 180),
                off = rnd:NextNumber(6, 12),
            }
        end

        local acc = 0
        track(RunService.Heartbeat:Connect(function(dt)
            if not uiAlive then return end
            -- animasi border ikon minimize (ringan: 3 properti per frame)
            if icon.Visible then
                iconGrad.Rotation = (iconGrad.Rotation + dt * 150) % 360
                local t = os.clock() * 3
                iconGlowStroke.Transparency = 0.62 + 0.2 * math.sin(t)
                iconGlowStroke.Thickness = 6 + 2 * math.sin(t)
            end
            if not win.Visible or not fxLayer.Visible then return end
            acc += dt
            if acc < 0.033 then return end
            local step = math.min(acc, 0.1)
            acc = 0
            local now = os.clock()
            local W, H = win.AbsoluteSize.X, win.AbsoluteSize.Y
            for _, b in ipairs(bolts) do
                if b.active then
                    if now >= b.endT then
                        b.active = false
                        for _, q in ipairs(b.segs) do
                            q.glow.Visible = false
                            q.core.Visible = false
                        end
                        b.nextT = now + rnd:NextNumber(0.25, 1.3)
                    else
                        local tr = rnd:NextNumber(0.3, 0.7)
                        for _, q in ipairs(b.segs) do q.glow.BackgroundTransparency = tr end
                    end
                elseif now >= b.nextT then
                    b.active = true
                    b.endT = now + rnd:NextNumber(0.1, 0.24)
                    strike(b)
                end
            end
            for _, r in ipairs(rocks) do
                r.y += r.vy * step
                r.rot += r.vr * step
                if r.y > H + 12 then
                    r.y = -12 - rnd:NextNumber(0, 60)
                    r.vy = rnd:NextNumber(70, 150)
                    r.off = rnd:NextNumber(6, 12)
                end
                local x = (r.side == 1) and r.off or (W - r.off)
                r.f.Position = UDim2.fromOffset(x, r.y)
                r.f.Rotation = r.rot
            end
        end))
    end

    local side = new("ScrollingFrame", {
        Size = UDim2.new(0, SIDE, 1, -58),
        Position = UDim2.new(0, 6, 0, 52),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, win)
    new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, side)

    local content = new("Frame", {
        Size = UDim2.new(1, -(SIDE + 18), 1, -58),
        Position = UDim2.new(0, SIDE + 12, 0, 52),
        BackgroundTransparency = 1,
    }, win)

    -- ---------- tab ----------
    local tabs = {}
    local function selectTab(t)
        for _, o in ipairs(tabs) do
            local on = (o == t)
            o.page.Visible = on
            o.btn.BackgroundColor3 = on and THEME.accent or THEME.card
            o.btn.BackgroundTransparency = on and 0 or 0.05
            o.btn.TextColor3 = on and WHITE or THEME.sub
            if o.stroke then
                o.stroke.Color = on and THEME.accent2 or THEME.off
            end
            if o.paintIcon then o.paintIcon(on and WHITE or THEME.sub) end
        end
    end

    -- ikon tab digambar dari shape (kotak 20x20) supaya selalu tampil & bisa diwarnai ungu
    local function buildTabIcon(parent, kind)
        local box = new("Frame", {
            Size = UDim2.fromOffset(20, 20),
            Position = UDim2.new(0, 7, 0.5, -10),
            BackgroundTransparency = 1,
        }, parent)
        local parts = {}
        local function shape(x, y, w, h, o)
            o = o or {}
            local f = new("Frame", {
                Position = UDim2.fromOffset(x, y),
                Size = UDim2.fromOffset(w, h),
                BackgroundColor3 = THEME.sub,
                BackgroundTransparency = o.outline and 1 or 0,
                BorderSizePixel = 0,
                Rotation = o.rot or 0,
            }, box)
            if o.round == "full" then
                new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
            elseif o.round then
                new("UICorner", { CornerRadius = UDim.new(0, o.round) }, f)
            end
            if o.outline then
                local st = new("UIStroke", { Color = THEME.sub, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
                table.insert(parts, { st, "Color" })
            else
                table.insert(parts, { f, "BackgroundColor3" })
            end
        end
        if kind == "MAIN" then          -- telur
            shape(4, 2, 12, 16, { outline = true, round = "full" })
            shape(8, 9, 4, 4, { round = "full" })
        elseif kind == "PRIORITY" then  -- daftar urutan
            shape(3, 4, 14, 3, { round = 1 })
            shape(3, 9, 14, 3, { round = 1 })
            shape(3, 14, 9, 3, { round = 1 })
        elseif kind == "AREA" then      -- pin lokasi
            shape(4, 1, 12, 12, { outline = true, round = "full" })
            shape(8, 5, 4, 4, { round = "full" })
            shape(9, 13, 2, 6, { round = 1 })
        elseif kind == "AUTOMATION" then -- gir
            shape(4, 4, 12, 12, { outline = true, round = "full" })
            shape(8, 8, 4, 4, { round = "full" })
            shape(9, 0, 2, 4)
            shape(9, 16, 2, 4)
            shape(0, 9, 4, 2)
            shape(16, 9, 4, 2)
        elseif kind == "EVENT" then     -- bintang
            shape(4, 4, 12, 12, { outline = true })
            shape(4, 4, 12, 12, { outline = true, rot = 45 })
            shape(8, 8, 4, 4, { round = "full" })
        elseif kind == "SHOP" then      -- tas belanja
            shape(6, 1, 8, 9, { outline = true, round = "full" })
            shape(3, 8, 14, 11, { round = 2 })
        elseif kind == "PROTEKSI" then  -- perisai
            shape(4, 1, 12, 10, { round = 2 })
            shape(5, 6, 10, 10, { rot = 45, round = 1 })
        elseif kind == "WEBHOOK" then   -- tautan
            shape(1, 6, 11, 8, { outline = true, round = "full" })
            shape(8, 6, 11, 8, { outline = true, round = "full" })
        elseif kind == "CONFIG" then    -- slider
            shape(2, 4, 16, 2, { round = 1 })
            shape(2, 9, 16, 2, { round = 1 })
            shape(2, 14, 16, 2, { round = 1 })
            shape(4, 2, 5, 6, { round = "full" })
            shape(12, 7, 5, 6, { round = "full" })
            shape(6, 12, 5, 6, { round = "full" })
        else                            -- DEBUG: kutu
            shape(6, 5, 8, 12, { round = "full" })
            shape(7, 1, 6, 5, { round = "full" })
            shape(2, 8, 4, 2)
            shape(14, 8, 4, 2)
            shape(2, 13, 4, 2)
            shape(14, 13, 4, 2)
        end
        return function(col)
            for _, p in ipairs(parts) do p[1][p[2]] = col end
        end
    end

    local function addTab(name)
        local btn = new("TextButton", {
            Size = UDim2.new(1, -4, 0, 38),
            BackgroundColor3 = THEME.card,
            Text = name,
            TextColor3 = THEME.sub,
            TextSize = 12,
            TextScaled = true,
            Font = FONT_B,
            AutoButtonColor = false,
        }, side)
        corner(btn, 8)
        local tabStroke = new("UIStroke", { Color = THEME.off, Thickness = 2.5, Transparency = 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, btn)
        new("UITextSizeConstraint", { MaxTextSize = 12, MinTextSize = 7 }, btn)
        new("UIPadding", { PaddingLeft = UDim.new(0, 32), PaddingRight = UDim.new(0, 4) }, btn)
        local paintIcon = buildTabIcon(btn, name)
        local page = new("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
        }, content)
        new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, page)
        new("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 12) }, page)
        local t = { btn = btn, page = page, stroke = tabStroke, paintIcon = paintIcon }
        table.insert(tabs, t)
        btn.MouseButton1Click:Connect(function() selectTab(t) end)
        return page
    end

    -- ---------- widget ----------
    local function card(parent, h)
        local f = new("Frame", {
            Size = UDim2.new(1, 0, 0, h),
            BackgroundColor3 = THEME.card,
            BackgroundTransparency = 0.08,
            BorderSizePixel = 0,
        }, parent)
        corner(f, 6)
        return f
    end

    local function label(parent, text, size, color, font)
        return new("TextLabel", {
            BackgroundTransparency = 1,
            Text = text,
            TextSize = size or 12,
            TextColor3 = color or THEME.text,
            Font = font or FONT_R,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
        }, parent)
    end

    local function section(parent, text)
        local l = label(parent, text, 11, THEME.accent2, FONT_B)
        l.Size = UDim2.new(1, 0, 0, 18)
        return l
    end

    local function note(parent, text)
        local l = label(parent, text, 11, THEME.sub)
        l.Size = UDim2.new(1, 0, 0, 0)
        l.AutomaticSize = Enum.AutomaticSize.Y
        return l
    end

    local function safeCall(cb, ...)
        local ok, err = pcall(cb, ...)
        if not ok then log("Error UI: " .. tostring(err)) end
    end

    local function buttonRow(parent, text, cb, color)
        local b = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = color or THEME.accent,
            BackgroundTransparency = 0,
            Text = text,
            TextColor3 = WHITE,
            TextSize = 13,
            Font = FONT_B,
            AutoButtonColor = true,
        }, parent)
        corner(b, 6)
        b.MouseButton1Click:Connect(function() safeCall(cb, b) end)
        return b
    end

    local function toggleRow(parent, text, default, cb, subText, reserve)
        local h = subText and 52 or 42
        local row = card(parent, h)
        local lblW = 72 + (reserve or 0)
        local lbl = label(row, text, 12, THEME.text, FONT_M)
        lbl.Size = UDim2.new(1, -lblW, 0, subText and 22 or h)
        lbl.Position = UDim2.new(0, 10, 0, subText and 3 or 0)
        if subText then
            local sl = label(row, subText, 10, THEME.sub)
            sl.Size = UDim2.new(1, -lblW, 0, 16)
            sl.Position = UDim2.new(0, 10, 0, 28)
            sl.TextWrapped = false
            sl.TextTruncate = Enum.TextTruncate.AtEnd
        end
        local sw = new("TextButton", {
            Size = UDim2.fromOffset(46, 24),
            Position = UDim2.new(1, -58, 0.5, -12),
            BackgroundColor3 = THEME.off,
            Text = "",
            AutoButtonColor = false,
        }, row)
        corner(sw, 12)
        local knob = new("Frame", {
            Size = UDim2.fromOffset(18, 18),
            Position = UDim2.new(0, 3, 0.5, -9),
            BackgroundColor3 = WHITE,
            BorderSizePixel = 0,
        }, sw)
        corner(knob, 9)
        local isOn = default and true or false
        local function paint(animate)
            local kp = isOn and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            local col = isOn and THEME.accent or THEME.off
            if animate then
                TweenService:Create(knob, TweenInfo.new(0.15), { Position = kp }):Play()
                TweenService:Create(sw, TweenInfo.new(0.15), { BackgroundColor3 = col }):Play()
            else
                knob.Position = kp
                sw.BackgroundColor3 = col
            end
        end
        paint(false)
        sw.MouseButton1Click:Connect(function()
            isOn = not isOn
            paint(true)
            safeCall(cb, isOn)
        end)
        return {
            row = row,
            set = function(v)
                isOn = v and true or false
                paint(false)
            end,
            get = function() return isOn end,
        }
    end

    local function choiceRow(parent, title, options, current, cb)
        local row = card(parent, 58)
        local t = label(row, title, 11, THEME.sub, FONT_M)
        t.Size = UDim2.new(1, -20, 0, 16)
        t.Position = UDim2.new(0, 10, 0, 4)
        local btns = {}
        local n = #options
        local function paint(val)
            for v, b in pairs(btns) do
                local on = (v == val)
                b.BackgroundColor3 = on and THEME.accent or THEME.off
                b.TextColor3 = on and WHITE or THEME.sub
            end
        end
        for i, opt in ipairs(options) do
            local b = new("TextButton", {
                Size = UDim2.new(1 / n, -8, 0, 26),
                Position = UDim2.new((i - 1) / n, 6, 0, 24),
                BackgroundColor3 = THEME.off,
                Text = opt[2],
                TextColor3 = THEME.sub,
                TextSize = 11,
                Font = FONT_B,
                AutoButtonColor = false,
            }, row)
            corner(b, 5)
            btns[opt[1]] = b
            b.MouseButton1Click:Connect(function()
                paint(opt[1])
                safeCall(cb, opt[1])
            end)
        end
        paint(current)
        return { paint = paint }
    end

    local function stepperRow(parent, title, value, minV, maxV, step, cb, suffix)
        local row = card(parent, 34)
        local t = label(row, title, 12, THEME.text, FONT_M)
        t.Size = UDim2.new(1, -126, 1, 0)
        t.Position = UDim2.new(0, 10, 0, 0)
        local val = math.clamp(tonumber(value) or minV, minV, maxV)
        local vl = new("TextLabel", {
            Size = UDim2.fromOffset(46, 24),
            Position = UDim2.new(1, -86, 0.5, -12),
            BackgroundTransparency = 1,
            TextColor3 = THEME.accent2,
            TextSize = 12,
            Font = FONT_B,
            Text = "",
        }, row)
        local function show() vl.Text = tostring(val) .. (suffix or "") end
        local function mk(txt, x, delta)
            local b = new("TextButton", {
                Size = UDim2.fromOffset(26, 24),
                Position = UDim2.new(1, x, 0.5, -12),
                BackgroundColor3 = THEME.off,
                Text = txt,
                TextColor3 = THEME.text,
                TextSize = 14,
                Font = FONT_B,
            }, row)
            corner(b, 5)
            b.MouseButton1Click:Connect(function()
                val = math.clamp(val + delta, minV, maxV)
                show()
                safeCall(cb, val)
            end)
        end
        mk("-", -116, -step)
        mk("+", -36, step)
        show()
    end

    local function textboxRow(parent, title, value, placeholder, cb)
        local row = card(parent, 58)
        local t = label(row, title, 11, THEME.sub, FONT_M)
        t.Size = UDim2.new(1, -20, 0, 16)
        t.Position = UDim2.new(0, 10, 0, 4)
        local box = new("TextBox", {
            Size = UDim2.new(1, -20, 0, 26),
            Position = UDim2.new(0, 10, 0, 24),
            BackgroundColor3 = THEME.off,
            TextColor3 = THEME.text,
            PlaceholderText = placeholder,
            PlaceholderColor3 = THEME.sub,
            Text = value or "",
            TextSize = 11,
            Font = FONT_R,
            ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, row)
        corner(box, 5)
        box.FocusLost:Connect(function() safeCall(cb, box.Text) end)
        return box
    end

    local function textBox(parent, h)
        local sc = new("ScrollingFrame", {
            Size = UDim2.new(1, 0, 0, h),
            BackgroundColor3 = THEME.bg2,
            BackgroundTransparency = 0.06,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, parent)
        corner(sc, 6)
        local lbl = new("TextLabel", {
            Size = UDim2.new(1, -8, 0, 0),
            Position = UDim2.new(0, 4, 0, 2),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            TextColor3 = THEME.sub,
            TextSize = 11,
            Font = Enum.Font.Code,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Text = "",
        }, sc)
        return sc, lbl
    end

    -- filter multi-pilih. Nilai aktif disimpan sebagai true; nonaktif = nil (V23 memakai next(set) untuk cek filter aktif)
    local function multiSelect(parent, title, sets, cats)
        local wrap = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, parent)
        local wl = new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, wrap)
        fit(wrap, wl)
        local head
        local body = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, Visible = false }, wrap)
        head = buttonRow(wrap, "v  " .. title, function()
            body.Visible = not body.Visible
            head.Text = (body.Visible and "^  " or "v  ") .. title
        end, THEME.off)
        head.LayoutOrder = 1
        body.LayoutOrder = 2
        local bl = new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, body)
        fit(body, bl)

        local painters = {}
        for _, entry in ipairs(FILTERS) do
            local cat, opts = entry[1], entry[2]
            if cats and not table.find(cats, cat) then continue end
            local lb = label(body, cat, 11, THEME.accent2, FONT_B)
            lb.Size = UDim2.new(1, 0, 0, 16)
            local grid = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, body)
            local gl = new("UIGridLayout", {
                CellSize = UDim2.new(0.5, -4, 0, 26),
                CellPadding = UDim2.fromOffset(6, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, grid)
            fit(grid, gl)
            for _, opt in ipairs(opts) do
                local chip = new("TextButton", {
                    Text = opt,
                    TextSize = 11,
                    Font = FONT_M,
                    BackgroundColor3 = THEME.off,
                    TextColor3 = THEME.sub,
                    AutoButtonColor = false,
                }, grid)
                corner(chip, 5)
                local function paint()
                    local on = sets[cat][opt] == true
                    chip.BackgroundColor3 = on and THEME.accent or THEME.off
                    chip.TextColor3 = on and WHITE or THEME.sub
                    chip.Font = on and FONT_B or FONT_M
                end
                paint()
                table.insert(painters, paint)
                chip.MouseButton1Click:Connect(function()
                    if sets[cat][opt] then sets[cat][opt] = nil else sets[cat][opt] = true end
                    paint()
                end)
            end
        end
        local clr = buttonRow(body, "Reset pilihan filter ini", function()
            for _, cat in ipairs({ "Size", "Rarity", "Variant" }) do table.clear(sets[cat]) end
            for _, p in ipairs(painters) do p() end
        end, THEME.off)
        clr.TextSize = 11
        return wrap
    end

    -- dropdown: tombol yang membuka daftar pilihan di bawahnya
    local function dropdownRow(parent, title, options, current, cb)
        local wrap = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, parent)
        local wl = new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, wrap)
        fit(wrap, wl)
        local head = card(wrap, 34)
        head.LayoutOrder = 1
        local t = label(head, title, 12, THEME.text, FONT_M)
        t.Size = UDim2.new(0.22, 0, 1, 0)
        t.Position = UDim2.new(0, 10, 0, 0)
        local btn = new("TextButton", {
            Size = UDim2.new(0.78, -18, 0, 24),
            Position = UDim2.new(0.22, 4, 0.5, -12),
            BackgroundColor3 = THEME.off,
            TextColor3 = THEME.text,
            TextSize = 11,
            Font = FONT_B,
            AutoButtonColor = false,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = "",
        }, head)
        corner(btn, 5)
        local body = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, Visible = false }, wrap)
        body.LayoutOrder = 2
        local bl = new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, body)
        fit(body, bl)
        local names = {}
        for _, o in ipairs(options) do names[o.id] = o.label end
        local function show(id) btn.Text = (names[id] or "- Kosong -") .. "  v" end
        show(current)
        for _, o in ipairs(options) do
            local ob = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = THEME.off,
                Text = o.label,
                TextColor3 = THEME.sub,
                TextSize = 11,
                Font = FONT_M,
                AutoButtonColor = true,
            }, body)
            corner(ob, 5)
            ob.MouseButton1Click:Connect(function()
                body.Visible = false
                show(o.id)
                safeCall(cb, o.id)
            end)
        end
        btn.MouseButton1Click:Connect(function() body.Visible = not body.Visible end)
        return wrap
    end

    -- ==========================================
    -- TAB MAIN
    -- ==========================================
    local pageMain = addTab("MAIN")

    section(pageMain, "STATUS")
    local statusCard = card(pageMain, 62)
    ui.statusDot = new("Frame", {
        Size = UDim2.fromOffset(10, 10),
        Position = UDim2.new(0, 10, 0, 9),
        BackgroundColor3 = THEME.sub,
        BorderSizePixel = 0,
    }, statusCard)
    corner(ui.statusDot, 5)
    ui.statusText = label(statusCard, "Idle", 12, THEME.text, FONT_B)
    ui.statusText.Size = UDim2.new(1, -34, 0, 18)
    ui.statusText.Position = UDim2.new(0, 28, 0, 5)
    ui.statsText = label(statusCard, "", 11, THEME.sub)
    ui.statsText.Size = UDim2.new(1, -20, 0, 16)
    ui.statsText.Position = UDim2.new(0, 10, 0, 26)
    ui.modeText = label(statusCard, "", 11, THEME.sub)
    ui.modeText.Size = UDim2.new(1, -20, 0, 16)
    ui.modeText.Position = UDim2.new(0, 10, 0, 43)
    ui.modeText.TextTruncate = Enum.TextTruncate.AtEnd
    ui.modeText.TextWrapped = false

    section(pageMain, "KONTROL")
    toggleRow(pageMain, "Auto Steal Telur", false, function(on)
        config.running = on
        if on then
            local hrp = getHRP()
            if hrp then baseCFrame = hrp.CFrame + Vector3.new(0, 3, 0) end
            log("Auto Steal ON (base = posisimu sekarang)")
            ensureBrain()
        else
            log("Auto Steal OFF")
        end
        refreshStats()
    end)
    toggleRow(pageMain, "Treadmill saat idle", false, function(on)
        config.treadmillIdle = on
        if on then ensureBrain() end
    end, "Lari di treadmill bila tidak ada kerjaan")
    toggleRow(pageMain, "Lewati telur milik sendiri", config.skipOwn, function(on)
        config.skipOwn = on
    end)
    toggleRow(pageMain, "Legit Steal", config.legit, function(on)
        config.legit = on
        log("Legit Steal " .. (on and "ON (jalan kaki, tanpa teleport/terbang)" or "OFF"))
        refreshStats()
    end, "Jalan kaki + tahan tombol seperti pemain biasa")

    choiceRow(pageMain, "Cara bergerak", { { "Walk", "Jalan (humanoid)" }, { "Fly", "Terbang halus" } }, config.method, function(v)
        config.method = v
        refreshStats()
    end)
    choiceRow(pageMain, "Mode target", { { "All", "Semua telur" }, { "Filter", "Pakai filter" } }, config.targetMode, function(v)
        config.targetMode = v
        refreshStats()
    end)
    stepperRow(pageMain, "Kecepatan terbang", config.flySpeed, 30, 400, 10, function(v) config.flySpeed = v end)
    stepperRow(pageMain, "Tinggi terbang", config.flyHeight, 0, 60, 2, function(v) config.flyHeight = v end)

    buttonRow(pageMain, "Set Base di posisi sekarang", function()
        local hrp = getHRP()
        if hrp then
            baseCFrame = hrp.CFrame + Vector3.new(0, 3, 0)
            log("Base disimpan di posisimu sekarang")
        end
    end, THEME.off)

    section(pageMain, "FILTER TELUR (dipakai bila mode 'Pakai filter')")
    multiSelect(pageMain, "Filter Size / Rarity / Variant", config.filters)

    section(pageMain, "EGG PREDICT")
    toggleRow(pageMain, "Egg Predict", false, function(on)
        config.eggPredict = on
        if on then
            V25.startEggPredict()
        elseif ui.predictLabel then
            ui.predictLabel.Text = "Egg Predict OFF"
        end
    end, "Baca rarity / variant / size telur terdekat")
    local predictCard = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = THEME.card,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
    }, pageMain)
    corner(predictCard, 6)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
    }, predictCard)
    ui.predictLabel = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = "Egg Predict OFF",
        TextColor3 = THEME.sub,
        TextSize = 11,
        Font = Enum.Font.Code,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, predictCard)
    note(pageMain, "Membaca teks/atribut telur yang terlihat di client. Ini bukan tebakan hasil tetas (hasil tetas ditentukan server).")

    section(pageMain, "AUTO SELL EGG")
    toggleRow(pageMain, "Auto Sell Egg", false, function(on)
        setAuto("sell", on, V25.autoSellOnce)
        log("Auto Sell Egg " .. (on and "ON" or "OFF"))
    end, "Jual egg di backpack sesuai rarity (item favorit aman)")
    multiSelect(pageMain, "Filter Rarity yang dijual", config.sellFilters, { "Rarity" })

    section(pageMain, "AUTO FAVORIT")
    toggleRow(pageMain, "Auto Favorit", false, function(on)
        setAuto("favorite", on, V25.autoFavoriteOnce)
        log("Auto Favorit " .. (on and "ON" or "OFF"))
    end, "Favoritkan item sesuai nama / rarity / variant")
    textboxRow(pageMain, "Nama item (pisahkan dengan koma)", config.favNames, "contoh: dragon, phoenix", function(txt)
        config.favNames = txt
    end)
    multiSelect(pageMain, "Filter Rarity & Variant", config.favFilters, { "Rarity", "Variant" })
    note(pageMain, "Cocok bila NAMA cocok ATAU filter rarity/variant cocok. Tanpa kriteria tidak ada yang difavoritkan.")

    section(pageMain, "LOG")
    local logScroll, logLabel = textBox(pageMain, 150)
    ui.logScroll, ui.logLabel = logScroll, logLabel

    -- ==========================================
    -- TAB PRIORITY
    -- ==========================================
    local pagePrio = addTab("PRIORITY")
    note(pagePrio, "Default MATI. Saat dinyalakan, AFK manager mengerjakan tugas sesuai urutan di bawah. #1 selalu Steal Egg. Tugas di bawahnya jalan ketika tugas di atasnya tidak punya pekerjaan (misal tidak ada telur). Tiap tugas tetap harus dinyalakan di tab Main / Automation.")
    toggleRow(pagePrio, "Aktifkan Priority", false, function(on)
        V25.applyPriorityMode(on)
        log("Priority " .. (on and "ON" or "OFF"))
    end, "Mati = tiap fitur jalan sendiri-sendiri")
    section(pagePrio, "URUTAN PRIORITAS")
    local lockCard = card(pagePrio, 34)
    local lockLbl = label(lockCard, "#1   Steal Egg  (wajib, terkunci)", 12, THEME.accent2, FONT_B)
    lockLbl.Size = UDim2.new(1, -20, 1, 0)
    lockLbl.Position = UDim2.new(0, 10, 0, 0)
    for i = 2, 7 do
        dropdownRow(pagePrio, "#" .. i, V25.PRIORITY_OPTIONS, config.priority[i], function(id)
            config.priority[i] = id
        end)
    end
    note(pagePrio, "Treadmill (idle) selalu jadi pilihan terakhir bila dinyalakan di tab Main.")

    -- ==========================================
    -- TAB AREA
    -- ==========================================
    local pageArea = addTab("AREA")
    note(pageArea, "Pilih biome yang boleh dicuri. Kosong = semua area. Tombol SET menyimpan posisimu sekarang sebagai pusat area (dipakai untuk memuat map dan menentukan area telur).")
    local areaToggles = {}
    buttonRow(pageArea, "Pilih semua area", function()
        for _, nm in ipairs(AREAS) do
            config.areas[nm] = true
            areaToggles[nm].set(true)
        end
        refreshStats()
    end, THEME.off)
    buttonRow(pageArea, "Kosongkan pilihan (artinya semua area)", function()
        for _, nm in ipairs(AREAS) do
            config.areas[nm] = nil
            areaToggles[nm].set(false)
        end
        refreshStats()
    end, THEME.off)
    for _, nm in ipairs(AREAS) do
        local t = toggleRow(pageArea, nm, config.areas[nm] == true, function(on)
            config.areas[nm] = on or nil
            refreshStats()
        end, nil, 56)
        areaToggles[nm] = t
        local pin = new("TextButton", {
            Size = UDim2.fromOffset(46, 22),
            Position = UDim2.new(1, -114, 0.5, -11),
            BackgroundColor3 = THEME.off,
            Text = areaCenters[nm] and "SET*" or "SET",
            TextColor3 = areaCenters[nm] and THEME.good or THEME.sub,
            TextSize = 10,
            Font = FONT_B,
        }, t.row)
        corner(pin, 5)
        pin.MouseButton1Click:Connect(function()
            local hrp = getHRP()
            if not hrp then return end
            areaCenters[nm] = hrp.Position
            pin.Text = "SET*"
            pin.TextColor3 = THEME.good
            log("Pusat area " .. nm .. " disimpan")
        end)
    end

    -- ==========================================
    -- TAB AUTO
    -- ==========================================
    local pageAuto = addTab("AUTOMATION")
    note(pageAuto, "Automation bekerja untuk prompt/tombol di sekitar base (radius " .. BASE_RADIUS .. " stud) atau milikmu. Set base dulu di tab MAIN.")

    section(pageAuto, "TELUR & INDEX")
    local autoDefs = {
        { "hatch", "Auto Hatch", autoHatchOnce, "Menetaskan telur di base" },
        { "place", "Auto Place", autoPlaceOnce, "Menaruh telur dari backpack (pakai filter di bawah)" },
        { "fuse", "Auto Fuse", autoFuseOnce, "Menjalankan fuse otomatis" },
        { "index", "Auto Claim Index", autoIndexOnce, "Klaim hadiah Index tiap 60 detik" },
    }
    for _, def in ipairs(autoDefs) do
        toggleRow(pageAuto, def[2], false, function(on)
            setAuto(def[1], on, def[3])
            log(def[2] .. (on and " ON" or " OFF"))
        end, def[4])
    end
    stepperRow(pageAuto, "Jeda antar aksi", config.autoInterval, 2, 60, 1, function(v)
        config.autoInterval = v
    end, " dtk")
    multiSelect(pageAuto, "Filter telur untuk Place", config.placeFilters)

    section(pageAuto, "UPGRADE")
    local upgDefs = {
        { "upgTrail", "Auto Upgrade Trail", V25.autoUpgTrailOnce, "Klik tombol Upgrade milik Trail" },
        { "upgTreadmill", "Auto Upgrade Treadmill", V25.autoUpgTreadmillOnce, "Klik tombol Upgrade milik Treadmill" },
        { "upgBase", "Auto Upgrade Base", V25.autoUpgBaseOnce, "Klik tombol Upgrade milik Base" },
    }
    for _, def in ipairs(upgDefs) do
        toggleRow(pageAuto, def[2], false, function(on)
            setAuto(def[1], on, def[3])
            log(def[2] .. (on and " ON" or " OFF"))
        end, def[4])
    end
    note(pageAuto, "Tombol berharga Robux tidak pernah diklik. Jika game tidak memakai prompt, menu upgrade perlu terbuka di layar.")

    section(pageAuto, "PET AUTOMATION")
    toggleRow(pageAuto, "Auto Taruh Pet di Plot", false, function(on)
        setAuto("petPlace", on, V25.autoPetPlaceOnce)
        log("Auto Taruh Pet " .. (on and "ON" or "OFF"))
    end, "Pilih pet berdasarkan nama atau rarity")
    textboxRow(pageAuto, "Nama pet yang ditaruh (pisahkan koma)", config.petPlaceNames, "contoh: dragon, cat", function(txt)
        config.petPlaceNames = txt
    end)
    multiSelect(pageAuto, "Rarity pet yang ditaruh", config.petPlaceFilters, { "Rarity" })

    toggleRow(pageAuto, "Auto Jual Pet", false, function(on)
        setAuto("petSell", on, V25.autoPetSellOnce)
        log("Auto Jual Pet " .. (on and "ON" or "OFF"))
    end, "Pilih pet berdasarkan nama atau rarity")
    textboxRow(pageAuto, "Nama pet yang dijual (pisahkan koma)", config.petSellNames, "contoh: rat, mouse", function(txt)
        config.petSellNames = txt
    end)
    multiSelect(pageAuto, "Rarity pet yang dijual", config.petSellFilters, { "Rarity" })
    note(pageAuto, "Pet favorit tidak pernah dijual. Tanpa nama/rarity yang dipilih, tidak ada yang dijual.")

    -- ==========================================
    -- TAB EVENT
    -- ==========================================
    local pageEvent = addTab("EVENT")
    note(pageEvent, "Event aktif. Jika nama objek event di game berbeda, ubah EVENT_DEFS di bagian atas script (cek tab DEBUG).")
    for _, def in ipairs(EVENT_DEFS) do
        toggleRow(pageEvent, def.name, false, function(on)
            config.events[def.id] = on
            if on then ensureBrain() end
            log("Event " .. def.name .. (on and " ON" or " OFF"))
        end, def.desc)
    end

    -- ==========================================
    -- TAB SHOP
    -- ==========================================
    local pageShop = addTab("SHOP")
    note(pageShop, "Membuka shop lewat tombol HUD atau terbang ke objek shop. Tombol pembelian tidak pernah diklik otomatis.")
    for _, def in ipairs(SHOPS) do
        buttonRow(pageShop, def.name, function() openShop(def) end)
        note(pageShop, def.info)
    end

    -- ==========================================
    -- TAB PROTEKSI & PERFORMA
    -- ==========================================
    local pageProt = addTab("PROTEKSI")
    section(pageProt, "PROTEKSI")
    toggleRow(pageProt, "Anti Knockback", config.antiKB, function(on) config.antiKB = on end)
    toggleRow(pageProt, "Anti Trapped", config.antiTrap, function(on) config.antiTrap = on end)
    toggleRow(pageProt, "Anti AFK", config.antiAfk, function(on) config.antiAfk = on end)
    toggleRow(pageProt, "Hapus popup '+Speed' & partikel", config.removePopups, function(on)
        setPopupCleaner(on)
    end, "Hemat CPU/RAM saat AFK di treadmill")

    section(pageProt, "TAMPILAN & PERFORMA")
    local pingFrame = new("Frame", {
        Size = UDim2.fromOffset(160, 22),
        Position = UDim2.new(1, -170, 0, 6),
        BackgroundColor3 = THEME.bg2,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Visible = config.pingPanel,
    }, sg)
    corner(pingFrame, 6)
    ui.pingLabel = new("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        TextColor3 = THEME.good,
        TextSize = 11,
        Font = FONT_B,
        Text = "PING - | FPS -",
    }, pingFrame)
    toggleRow(pageProt, "Panel Ping & FPS", config.pingPanel, function(on)
        config.pingPanel = on
        pingFrame.Visible = on
    end)
    local antiLagToggle = toggleRow(pageProt, "Anti Lag (matikan partikel)", config.antiLag, function(on)
        config.antiLag = on
        setAntiLag(on)
    end)
    toggleRow(pageProt, "Mode AFK Hemat", false, function(on)
        V25.setAfkSaver(on)
        log("Mode AFK Hemat " .. (on and "ON (3D off, FPS dibatasi, suara 0)" or "OFF"))
    end, "Matikan render 3D, batasi FPS, volume 0")
    stepperRow(pageProt, "Batas FPS saat AFK hemat", config.fpsCap, 5, 60, 5, function(v)
        config.fpsCap = v
        if config.afkSaver and typeof(setfpscap) == "function" then pcall(setfpscap, v) end
    end)
    buttonRow(pageProt, "Hapus plot orang lain (plot sendiri aman)", function()
        plotKeepMine = true
        task.spawn(removePlots)
    end, THEME.off)
    buttonRow(pageProt, "Super FPS Boost", function()
        task.spawn(function()
            superFpsBoost()
            config.antiLag = true
            antiLagToggle.set(true)
        end)
    end, THEME.warn)

    -- ==========================================
    -- TAB WEBHOOK
    -- ==========================================
    local pageWh = addTab("WEBHOOK")
    section(pageWh, "NOTIFIKASI TELUR")
    toggleRow(pageWh, "Kirim webhook tiap telur didapat", false, function(on)
        config.eggWebhookOn = on
        if on and not validWebhook(config.eggWebhookUrl) then
            log("URL webhook telur belum valid (harus URL webhook Discord)")
        end
    end)
    textboxRow(pageWh, "URL Webhook Discord (telur)", config.eggWebhookUrl, "https://discord.com/api/webhooks/...", function(txt)
        config.eggWebhookUrl = (txt:gsub("%s+", ""))
    end)
    buttonRow(pageWh, "Tes webhook telur", function()
        if not validWebhook(config.eggWebhookUrl) then
            log("URL webhook telur belum valid")
            return
        end
        queueWebhook(config.eggWebhookUrl, embedPayload("Tes webhook", 0x8B5CF6, {
            { name = "Status", value = "Berhasil terhubung", inline = true },
            { name = "Pemain", value = player.DisplayName, inline = true },
        }))
        log("Tes webhook telur dikirim")
    end, THEME.off)

    section(pageWh, "LAPORAN AFK (Speed, Uang, Ping)")
    toggleRow(pageWh, "Kirim laporan berkala", false, function(on)
        config.statsWebhookOn = on
        if on then
            if not validWebhook(config.statsWebhookUrl) then
                log("URL webhook laporan belum valid (harus URL webhook Discord)")
            end
            startStatsLoop()
        end
    end)
    textboxRow(pageWh, "URL Webhook Discord (laporan)", config.statsWebhookUrl, "https://discord.com/api/webhooks/...", function(txt)
        config.statsWebhookUrl = (txt:gsub("%s+", ""))
    end)
    stepperRow(pageWh, "Interval laporan", config.statsIntervalMin, 1, 120, 1, function(v)
        config.statsIntervalMin = v
    end, " mnt")
    buttonRow(pageWh, "Kirim laporan sekarang", function()
        if not validWebhook(config.statsWebhookUrl) then
            log("URL webhook laporan belum valid")
            return
        end
        sendStatsWebhook(true)
        log("Laporan dikirim")
    end, THEME.off)

    -- ==========================================
    -- TAB CONFIG
    -- ==========================================
    local pageCfg = addTab("CONFIG")
    toggleRow(pageCfg, "Efek Petir & Batu (border)", config.fxBorder ~= false, function(on)
        config.fxBorder = on
        if ui.fxLayer then ui.fxLayer.Visible = on end
    end, "Matikan bila HP terasa berat")
    local autoSaveToggle = toggleRow(pageCfg, "Auto Save (tiap 2 detik)", config.autoSave, function(on)
        config.autoSave = on
    end, "Hanya menulis file bila ada perubahan")
    local saveBtn
    saveBtn = buttonRow(pageCfg, "SAVE CONFIG SEKARANG", function()
        local ok = saveSettings(true)
        saveBtn.Text = ok and "TERSIMPAN!" or "GAGAL (executor tidak mendukung writefile)"
        task.delay(1.5, function()
            if saveBtn.Parent then saveBtn.Text = "SAVE CONFIG SEKARANG" end
        end)
    end)
    note(pageCfg, "File config: " .. SAVE_FILE .. " (folder workspace executor). Status berjalan seperti Auto Steal/Event/Automation tidak ikut disimpan.")
    buttonRow(pageCfg, "Hapus file simpanan", function()
        if typeof(delfile) == "function" and typeof(isfile) == "function" then
            pcall(function()
                if isfile(SAVE_FILE) then delfile(SAVE_FILE) end
            end)
            lastSavedJson = nil
            config.autoSave = false
            autoSaveToggle.set(false)
            log("File simpanan dihapus. Auto Save dimatikan, nyalakan lagi bila perlu.")
        else
            log("Executor tidak mendukung delfile")
        end
    end, THEME.bad)
    buttonRow(pageCfg, "Unload script (tutup & hentikan semua)", function() cleanup() end, THEME.bad)

    -- ==========================================
    -- TAB DEBUG
    -- ==========================================
    local pageDbg = addTab("DEBUG")
    local dbgLines = {}
    local dbgLabel
    local function dbg(text)
        table.insert(dbgLines, tostring(text))
        if #dbgLines > 250 then table.remove(dbgLines, 1) end
        if dbgLabel then dbgLabel.Text = table.concat(dbgLines, "\n") end
    end

    local function scanEggs()
        local hrp = getHRP()
        local list = collectEggPrompts()
        dbg(("== SCAN TELUR: %d prompt =="):format(#list))
        for i, p in ipairs(list) do
            if i > 15 then
                dbg("... (dipotong 15 pertama)")
                break
            end
            local pos = getPromptPosition(p)
            local d = (hrp and pos) and math.floor((pos - hrp.Position).Magnitude) or -1
            dbg(("%s | aksi='%s' | aktif=%s | jarak=%s | milikku=%s"):format(
                p:GetFullName(), tostring(p.ActionText), tostring(p.Enabled), tostring(d), tostring(ownedByMe(p))))
        end
    end

    local function scanUI()
        dbg("== SCAN UI (tombol yang terlihat) ==")
        local n = 0
        for _, d in ipairs(playerGui:GetDescendants()) do
            if (d:IsA("TextButton") or d:IsA("ImageButton")) and not d:IsDescendantOf(sg) and guiVisible(d) then
                n += 1
                if n > 60 then
                    dbg("... (dipotong 60 pertama)")
                    break
                end
                dbg(("%s | teks='%s'"):format(d:GetFullName(), buttonLabel(d)))
            end
        end
    end

    local function scanPrompts()
        local hrp = getHRP()
        if not hrp then
            dbg("Karakter belum ada")
            return
        end
        dbg("== SCAN PROMPT (radius 120 stud) ==")
        local n = 0
        for _, p in ipairs(Workspace:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                local pos = getPromptPosition(p)
                if pos and (pos - hrp.Position).Magnitude <= 120 then
                    n += 1
                    if n > 40 then
                        dbg("... (dipotong 40 pertama)")
                        break
                    end
                    dbg(("%s | aksi='%s' | objek='%s' | aktif=%s"):format(
                        p:GetFullName(), tostring(p.ActionText), tostring(p.ObjectText), tostring(p.Enabled)))
                end
            end
        end
    end

    local function scanRemotes()
        dbg("== SCAN REMOTE (ReplicatedStorage) ==")
        local n = 0
        for _, d in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                n += 1
                if n > 80 then
                    dbg("... (dipotong 80 pertama)")
                    break
                end
                dbg(d.ClassName .. " | " .. d:GetFullName())
            end
        end
    end

    local function scanStats()
        local s = readStats()
        dbg("== SCAN STATS ==")
        dbg(("Speed: %s (sumber: %s)"):format(s.speed, s.speedSrc))
        dbg(("Uang: %s (sumber: %s)"):format(s.money, s.moneySrc))
        dbg(("Ping: %d ms"):format(currentPing()))
        local tm = findTreadmill()
        dbg("Treadmill: " .. (tm and tm:GetFullName() or "tidak ditemukan"))
        dbg("Base: " .. (baseCFrame and "sudah di-set" or "belum di-set"))
        dbg(("Pusat area tersimpan: %d"):format((function()
            local c = 0
            for _ in pairs(areaCenters) do c += 1 end
            return c
        end)()))
    end

    local dbgBtns = {
        { "Scan Telur", scanEggs },
        { "Scan UI (tombol)", scanUI },
        { "Scan Prompt sekitar", scanPrompts },
        { "Scan Remote", scanRemotes },
        { "Scan Stats", scanStats },
        { "Scan Backpack (item)", function() V25.scanBackpack(dbg) end },
        { "Scan Aksi (sell/upgrade/favorit)", function() V25.scanActions(dbg) end },
    }
    for _, d in ipairs(dbgBtns) do
        buttonRow(pageDbg, d[1], function() task.spawn(d[2]) end, THEME.off)
    end
    buttonRow(pageDbg, "Salin output ke clipboard", function()
        if typeof(setclipboard) == "function" then
            setclipboard(table.concat(dbgLines, "\n"))
            log("Output debug disalin")
        else
            log("Executor tidak mendukung setclipboard")
        end
    end, THEME.off)
    buttonRow(pageDbg, "Bersihkan output", function()
        table.clear(dbgLines)
        if dbgLabel then dbgLabel.Text = "" end
    end, THEME.off)
    local _, dl = textBox(pageDbg, 220)
    dbgLabel = dl

    -- ==========================================
    -- ANIMASI BORDER + PANEL PING/FPS
    -- ==========================================
    local frames, lastT = 0, os.clock()
    track(RunService.RenderStepped:Connect(function(dt)
        if not uiAlive then return end
        strokeGrad.Rotation = (strokeGrad.Rotation + dt * 50) % 360
        for _, r in ipairs(bh.rings) do
            r.grad.Rotation = (r.grad.Rotation + dt * r.speed) % 360
        end
        if bh.stars then bh.stars.Rotation = (bh.stars.Rotation + dt * 9) % 360 end
        if bh.coreStroke then
            bh.coreStroke.Transparency = 0.2 + 0.2 * math.sin(os.clock() * 1.6)
        end
        frames += 1
        local now = os.clock()
        if now - lastT >= 0.5 then
            local fps = math.floor(frames / (now - lastT) + 0.5)
            frames, lastT = 0, now
            if pingFrame.Visible then
                ui.pingLabel.Text = ("PING %d ms | FPS %d"):format(currentPing(), fps)
            end
        end
    end))

    -- garis tepi tebal untuk semua tombol & kartu (kesan premium)
    do
        local function addStroke(o, th)
            if o:FindFirstChildOfClass("UIStroke") then return end
            new("UIStroke", { Color = THEME.accent2, Thickness = th, Transparency = 0.55,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
        end
        for _, d in ipairs(content:GetDescendants()) do
            if d:IsA("TextButton") or d:IsA("TextBox") then
                if d.BackgroundTransparency < 1 and d:FindFirstChildOfClass("UICorner") then addStroke(d, 2) end
            elseif d:IsA("Frame") then
                if d.BackgroundTransparency < 0.6 and d:FindFirstChildOfClass("UICorner")
                    and (d.Size.Y.Offset >= 28 or d.AutomaticSize ~= Enum.AutomaticSize.None)
                    and d.Size.X.Scale > 0.3 then
                    addStroke(d, 2)
                end
            end
        end
    end

    selectTab(tabs[1])
    refreshStats()
    setStatus("Idle", THEME.sub)
end

-- ==========================================
-- START
-- ==========================================
if config.method ~= "Fly" and config.method ~= "Walk" then config.method = "Walk" end   -- "Instant" lama dialihkan ke Walk
if config.targetMode ~= "All" and config.targetMode ~= "Filter" then config.targetMode = "All" end

local okUI, errUI = pcall(buildUI)
if not okUI then
    warn("[EX Steal an Egg] Gagal membuat UI: " .. tostring(errUI))
    pcall(cleanup)
    return
end

if config.removePopups then setPopupCleaner(true) end
if config.antiLag then setAntiLag(true) end

-- Auto-save tiap 2 detik (hanya menulis jika isi berubah)
task.spawn(function()
    while uiAlive do
        task.wait(2)
        if uiAlive and config.autoSave then saveSettings() end
    end
end)

log("EX Steal an Egg " .. VERSION .. " (Priority + Automation) berhasil dimuat")
