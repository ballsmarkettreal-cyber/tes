--[[ STEAL AN EGG PREMIUM | EX - TNJ - V29 CLEAN
     - GUI hanya di PlayerGui (bukan CoreGui/gethui)
     - Tidak panggil VirtualInputManager / getcustomasset saat load
     - Auto-save, FX border, popup cleaner: default OFF
     - Background: blackhole ANIMASI (bukan gambar)
     - Semua fitur tetap ada ]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local StatsService = game:GetService("Stats")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

pcall(function()
    for _, v in ipairs(playerGui:GetChildren()) do
        if v.Name:match("EX_StealAnEgg") then v:Destroy() end
    end
end)

local VERSION = "V29 (Clean)"
local SAVE_FILE = "EX_StealAnEgg_V29.json"
local OLD_SAVE_FILE = "EX_StealAnEgg_V28.json"
local BASE_RADIUS = 140

local HINTS = {
    hatch = { "hatch" }, place = { "place" }, fuse = { "fuse" },
    index = { "claim" }, treadmill = { "treadmill", "tredmill" },
    trap = { "trap", "snare", "cage", "stun", "freeze", "glue" },
    sell = { "sell" }, favorite = { "favorite", "favourite" }, upgrade = { "upgrade" },
}
local UPGRADES = {
    upgTrail = { name = "Trail", words = { "trail" } },
    upgTreadmill = { name = "Treadmill", words = { "treadmill", "tredmill" } },
    upgBase = { name = "Base", words = { "base", "plot" } },
}
local AREAS = { "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic", "Cherry Blossom", "Titan Temple", "Angels & Demons", "Enchanted Forest" }
local AREA_DETECT = {
    { "Enchanted Forest", { "enchanted" } }, { "Angels & Demons", { "angel", "demon" } },
    { "Cherry Blossom", { "cherry", "blossom" } }, { "Titan Temple", { "titan" } },
    { "Abyss Ocean", { "abyss" } }, { "Prehistoric", { "prehistoric" } },
    { "Cosmic", { "cosmic" } }, { "Volcano", { "volcano" } }, { "Snow", { "snow" } },
    { "Jungle", { "jungle" } }, { "Desert", { "desert" } }, { "Lake", { "lake" } }, { "Forest", { "forest" } },
}
local FILTERS = {
    { "Size", { "Small", "Medium", "Large", "Giant" } },
    { "Rarity", { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Cosmic", "Eternal", "Divine" } },
    { "Variant", { "Normal", "Silver", "Golden", "Rainbow", "Bloom", "Spirit Bloom", "Parasite", "Fractured", "Scrambled" } },
}
local EVENT_DEFS = {
    { id = "scramble", name = "Dr. Scramble Mecha & Drone", desc = "Boss tiap 30 mnt, drop Samples", keywords = { "scramble", "mecha", "drone" }, mode = "attack", tool = "bat" },
    { id = "rift", name = "Rift & Overlord", desc = "Tiap 30 mnt, drop Boss Tokens", keywords = { "overlord", "rift" }, mode = "attack", tool = "bat" },
    { id = "greatbloom", name = "Great Bloom", desc = "Tiap 30 mnt", keywords = { "greatbloom", "great bloom" }, mode = "collect" },
    { id = "butterfly", name = "Butterfly Bloom", desc = "Tangkap kupu-kupu", keywords = { "butterfly" }, mode = "collect", tool = "net" },
    { id = "frog", name = "Hungry Frog (parasit)", desc = "5 parasit = Monster Chest", keywords = { "parasite", "hungryfrog", "frog" }, mode = "collect" },
    { id = "angdem", name = "Angels vs Demons (ring)", desc = "Kumpulkan ring tim", keywords = { "ring" }, mode = "touch" },
    { id = "admin", name = "Admin Abuse (Sammy)", desc = "Event admin mingguan", keywords = { "sammy" }, mode = "attack", tool = "bat" },
}
local SHOPS = {
    { name = "Shop Utama", info = "Featured: Extinction Egg (Robux)", gui = { "shop" }, world = { "shop" } },
    { name = "Experiment Shop", info = "Booster, mutasi Scrambled, Experiment Egg", gui = { "experiment" }, world = { "experiment" } },
    { name = "Dr. Scramble's Lab", info = "Tukar 3 egg jadi pet eksperimen", gui = { "laboratory", "lab" }, world = { "laboratory", "lab" } },
    { name = "Boss Shop", info = "Hadiah dari Rift / Overlord", gui = { "boss shop", "bossshop" }, world = { "bossshop", "boss shop" } },
}
local THEME = {
    bg1 = Color3.fromRGB(20, 8, 36), bg2 = Color3.fromRGB(5, 2, 10),
    card = Color3.fromRGB(20, 9, 36), off = Color3.fromRGB(40, 20, 72),
    accent = Color3.fromRGB(142, 62, 255), accent2 = Color3.fromRGB(206, 160, 255),
    text = Color3.fromRGB(246, 240, 255), sub = Color3.fromRGB(172, 142, 222),
    good = Color3.fromRGB(196, 140, 255), warn = Color3.fromRGB(168, 108, 255),
    bad = Color3.fromRGB(104, 34, 184),
}

local function listToSet(list) local s = {}; for _, v in ipairs(list or {}) do s[v] = true end; return s end
local function setToList(set) local l = {}; for k, on in pairs(set) do if on then table.insert(l, k) end end; table.sort(l); return l end
local function norm(s) return (tostring(s):lower():gsub("[^%w]", "")) end
local function abbr(n)
    n = tonumber(n); if not n then return "?" end
    local units = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }; local i = 1
    while math.abs(n) >= 1000 and i < #units do n = n / 1000; i += 1 end
    if i == 1 then return ("%.0f"):format(n) end; return ("%.2f%s"):format(n, units[i])
end
local function nameHas(name, kw)
    local lname = name:lower(); kw = kw:lower(); local init = 1
    while true do
        local s = lname:find(kw, init, true); if not s then return false end
        local prev = name:sub(s - 1, s - 1); local cur = name:sub(s, s)
        if s == 1 or not prev:match("%a") or (prev:match("%l") and cur:match("%u")) then return true end
        init = s + 1
    end
end
local function nameHasAny(name, list) for _, k in ipairs(list) do if nameHas(name, k) then return true end end; return false end

local saved = {}
do
    if typeof(readfile) == "function" and typeof(isfile) == "function" then
        for _, fileName in ipairs({ SAVE_FILE, OLD_SAVE_FILE }) do
            local ok, data = pcall(function() if isfile(fileName) then return HttpService:JSONDecode(readfile(fileName)) end; return nil end)
            if ok and type(data) == "table" then saved = data; break end
        end
    end
end
saved.fxBorder = nil; saved.cleanFx = nil; saved.autoSave = nil; saved.antiKB = nil; saved.antiTrap = nil

local function S(key, default) local v = saved[key]; if v == nil then return default end; return v end
local function newFilterSet(key)
    local raw = S(key, {}); if type(raw) ~= "table" then raw = {} end
    local out = { Size = listToSet(raw.Size), Rarity = listToSet(raw.Rarity), Variant = listToSet(raw.Variant) }
    for _, entry in ipairs(FILTERS) do
        local valid = listToSet(entry[2])
        for k in pairs(out[entry[1]]) do if not valid[k] then out[entry[1]][k] = nil end end
    end
    return out
end

local areaCenters = { Forest = Vector3.new(597, 10, -324) }
for name, arr in pairs(S("areaCenters", {})) do
    if type(arr) == "table" and #arr == 3 then areaCenters[name] = Vector3.new(arr[1], arr[2], arr[3]) end
end

local config = {
    running = false, treadmillIdle = false,
    method = S("method", "Walk"), targetMode = S("targetMode", "All"),
    filters = newFilterSet("filters"), placeFilters = newFilterSet("placeFilters"),
    areas = listToSet(S("areas", {})), skipOwn = S("skipOwn", true), legit = S("legit", false),
    eggPredict = false, priorityOn = false,
    priority = S("priority", { "steal", "event", "hatch", "place", "fuse", "sell", "favorite" }),
    sellFilters = newFilterSet("sellFilters"), favFilters = newFilterSet("favFilters"), favNames = S("favNames", ""),
    petPlaceFilters = newFilterSet("petPlaceFilters"), petPlaceNames = S("petPlaceNames", ""),
    petSellFilters = newFilterSet("petSellFilters"), petSellNames = S("petSellNames", ""),
    afkSaver = false, fpsCap = S("fpsCap", 15), winW = S("winW", 580), winH = S("winH", 420),
    flySpeed = S("flySpeed2", 130), flyHeight = S("flyHeight", 12),
    fxBorder = S("fxBorder", false), antiKB = S("antiKB", false), antiTrap = S("antiTrap", false),
    antiAfk = S("antiAfk", true), pingPanel = S("pingPanel", true),
    removePopups = S("cleanFx", false), antiLag = S("antiLag", false), autoSave = S("autoSave", false),
    events = {}, auto = {
        hatch = false, place = false, fuse = false, index = false, sell = false, favorite = false,
        upgTrail = false, upgTreadmill = false, upgBase = false, petPlace = false, petSell = false,
    },
    autoInterval = S("autoInterval", 6),
    eggWebhookOn = false, eggWebhookUrl = S("eggWebhookUrl", ""),
    statsWebhookOn = false, statsWebhookUrl = S("statsWebhookUrl", ""),
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

local function track(conn) table.insert(connections, conn); return conn end

local lastSavedJson = nil
local function saveSettings(force)
    if typeof(writefile) ~= "function" then return false end
    local function f(sets) return { Size = setToList(sets.Size), Rarity = setToList(sets.Rarity), Variant = setToList(sets.Variant) } end
    local centers = {}
    for name, v in pairs(areaCenters) do centers[name] = { v.X, v.Y, v.Z } end
    local data = {
        areas = setToList(config.areas), filters = f(config.filters), placeFilters = f(config.placeFilters),
        sellFilters = f(config.sellFilters), favFilters = f(config.favFilters), favNames = config.favNames,
        petPlaceFilters = f(config.petPlaceFilters), petPlaceNames = config.petPlaceNames,
        petSellFilters = f(config.petSellFilters), petSellNames = config.petSellNames,
        legit = config.legit, priority = config.priority, fpsCap = config.fpsCap,
        winW = config.winW, winH = config.winH, method = config.method, targetMode = config.targetMode,
        skipOwn = config.skipOwn, flySpeed2 = config.flySpeed, flyHeight = config.flyHeight,
        fxBorder = config.fxBorder, antiKB = config.antiKB, antiTrap = config.antiTrap,
        antiAfk = config.antiAfk, pingPanel = config.pingPanel, cleanFx = config.removePopups,
        antiLag = config.antiLag, autoSave = config.autoSave, autoInterval = config.autoInterval,
        eggWebhookUrl = config.eggWebhookUrl, statsWebhookUrl = config.statsWebhookUrl,
        statsIntervalMin = config.statsIntervalMin, areaCenters = centers,
    }
    local okEnc, json = pcall(function() return HttpService:JSONEncode(data) end)
    if not okEnc then return false end
    if not force and json == lastSavedJson then return true end
    local okWrite = pcall(writefile, SAVE_FILE, json)
    if okWrite then lastSavedJson = json end
    return okWrite
end

local logLines = {}
local function log(msg)
    msg = os.date("%H:%M:%S") .. "  " .. tostring(msg)
    table.insert(logLines, msg)
    if #logLines > 80 then table.remove(logLines, 1) end
    if ui.logLabel then
        ui.logLabel.Text = table.concat(logLines, "\n")
        task.defer(function() if ui.logScroll then ui.logScroll.CanvasPosition = Vector2.new(0, 1e6) end end)
    end
end
local function setStatus(text, color)
    if ui.statusText then ui.statusText.Text = text end
    if ui.statusDot then ui.statusDot.BackgroundColor3 = color or THEME.sub end
end
local function refreshStats()
    if ui.statsText then ui.statsText.Text = ("Berhasil: %d    Gagal: %d"):format(stats.stolen, stats.failed) end
    if ui.modeText then
        local move = config.method == "Fly" and "Terbang" or "Jalan"
        local target = config.targetMode == "All" and "Semua" or "Filter"
        local areaCount = 0; for _ in pairs(config.areas) do areaCount += 1 end
        ui.modeText.Text = ("Gerak: %s   Target: %s   Area: %s"):format(move, target, areaCount > 0 and (areaCount .. " dipilih") or "semua")
    end
end

local function getChar()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hrp, hum, char
end
local function getHRP() local hrp = getChar(); return hrp end
local function ensureBase()
    if not baseCFrame then local hrp = getHRP(); if hrp then baseCFrame = hrp.CFrame + Vector3.new(0, 3, 0) end end
end
local function getInstPosition(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst.Position end
    if inst:IsA("Attachment") then return inst.WorldPosition end
    if inst:IsA("Model") then local ok, cf = pcall(function() return inst:GetPivot() end); if ok then return cf.Position end end
    return nil
end
local function getPromptPosition(prompt)
    local pos = getInstPosition(prompt.Parent); if pos then return pos end
    local model = prompt:FindFirstAncestorOfClass("Model")
    if model then pos = getInstPosition(model); if pos then return pos end end
    local part = prompt.Parent and prompt.Parent:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

local Snapshot = { t = 0, list = {} }
function Snapshot.get()
    if os.clock() - Snapshot.t > 5 then Snapshot.list = Workspace:GetDescendants(); Snapshot.t = os.clock() end
    return Snapshot.list
end

local function promptText(p) return (p.Name .. " " .. (p.ActionText or "") .. " " .. (p.ObjectText or "")):lower() end
local function promptMatches(p, kws)
    local t = promptText(p)
    for _, k in ipairs(kws) do if t:find(k, 1, true) then return true end end
    return false
end
local function triggerPrompt(prompt)
    if typeof(fireproximityprompt) == "function" then
        local ok = pcall(fireproximityprompt, prompt); if ok then return true end
    end
    return pcall(function() prompt:InputHoldBegin(); task.wait(0.05); prompt:InputHoldEnd() end)
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
    local t = ""; if btn:IsA("TextButton") then t = btn.Text end
    if t == "" then
        for _, d in ipairs(btn:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text ~= "" then t = d.Text; break end
        end
    end
    return t
end
local function findButtons(keywords, exact)
    local found = {}
    for _, d in ipairs(playerGui:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("ImageButton")) and not (sg and d:IsDescendantOf(sg)) and guiVisible(d) then
            local lab = buttonLabel(d):lower(); local nm = d.Name:lower()
            for _, k in ipairs(keywords) do
                if exact then
                    if lab == k or nm == k then table.insert(found, d); break end
                elseif lab:find(k, 1, true) or nm:find(k, 1, true) then
                    table.insert(found, d); break
                end
            end
        end
    end
    return found
end
local function clickButton(btn)
    local label = (buttonLabel(btn) .. " " .. btn.Name):lower()
    if label:find("buy", 1, true) or label:find("purchase", 1, true) or label:find("robux", 1, true) or label:find("r$", 1, true) then return false end
    if typeof(firesignal) == "function" then
        pcall(firesignal, btn.MouseButton1Click); pcall(firesignal, btn.Activated); return true
    elseif typeof(getconnections) == "function" then
        pcall(function() for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end end); return true
    end
    return false
end
local function clickFirstMatching(keys)
    for _, k in ipairs(keys) do
        local btns = findButtons({ k }, false)
        for _, b in ipairs(btns) do if clickButton(b) then return true end end
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
    for _, t in ipairs(char:GetChildren()) do if match(t) then return t end end
    for _, t in ipairs(player.Backpack:GetChildren()) do
        if match(t) then pcall(function() hum:EquipTool(t) end); task.wait(0.15); return t end
    end
    return nil
end

local Lock = { queue = {}, held = false }
function Lock.acquire()
    local ticket = {}; table.insert(Lock.queue, ticket)
    while uiAlive and (Lock.held or Lock.queue[1] ~= ticket) do task.wait(0.1) end
    local idx = table.find(Lock.queue, ticket); if idx then table.remove(Lock.queue, idx) end
    Lock.held = true
end
function Lock.release() Lock.held = false end
function Lock.run(fn) Lock.acquire(); local ok, err = pcall(fn); Lock.release(); return ok, err end

local Protect = { lastWalk = 16, flying = false, treadmillActive = false }
local BODY_MOVERS = { BodyVelocity = true, BodyPosition = true, BodyForce = true, BodyThrust = true, BodyAngularVelocity = true, LinearVelocity = true, VectorForce = true, LineForce = true }

function Protect.bindChar(char)
    if Protect.charConn then Protect.charConn:Disconnect() end
    Protect.charConn = track(char.DescendantAdded:Connect(function(d)
        if config.antiKB and not Protect.treadmillActive and BODY_MOVERS[d.ClassName] then
            task.defer(function()
                pcall(function()
                    if d:IsA("Constraint") then d.Enabled = false
                    elseif d:IsA("BodyMover") then d:Destroy() end
                end)
            end)
        end
    end))
end
track(player.CharacterAdded:Connect(Protect.bindChar))
if player.Character then Protect.bindChar(player.Character) end
function Protect.unstick(hrp)
    hrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0); hrp.AssemblyLinearVelocity = Vector3.zero
    local _, hum = getChar()
    if hum then hum.PlatformStand = false; hum.Sit = false; hum.Jump = true end
end

local protectAccum = 0
track(RunService.Heartbeat:Connect(function(dt)
    if not (config.antiKB or config.antiTrap) then return end
    local hrp, hum, char = getChar(); if not hrp or not hum then return end
    if config.antiKB and not Protect.flying and not Protect.treadmillActive then
        local v = hrp.AssemblyLinearVelocity
        local horiz = Vector3.new(v.X, 0, v.Z)
        local allowed = math.max(hum.WalkSpeed, 16) * 1.6 + 10
        if horiz.Magnitude > allowed then
            local lim = horiz.Unit * allowed
            hrp.AssemblyLinearVelocity = Vector3.new(lim.X, math.min(v.Y, 80), lim.Z)
        elseif v.Y > 90 then hrp.AssemblyLinearVelocity = Vector3.new(v.X, 90, v.Z) end
    end
    protectAccum += dt; if protectAccum < 0.5 then return end; protectAccum = 0
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
        if hum.WalkSpeed > 1 then Protect.lastWalk = hum.WalkSpeed else hum.WalkSpeed = Protect.lastWalk end
        for _, d in ipairs(char:GetDescendants()) do
            if not d:IsA("Tool") and not d:IsA("Accessory") and nameHasAny(d.Name, HINTS.trap) then
                pcall(function() d:Destroy() end)
            elseif d:IsA("JointInstance") or d:IsA("WeldConstraint") then
                local other
                if d.Part0 and not d.Part0:IsDescendantOf(char) then other = d.Part0
                elseif d.Part1 and not d.Part1:IsDescendantOf(char) then other = d.Part1 end
                if other and nameHasAny(other:GetFullName(), HINTS.trap) then pcall(function() d:Destroy() end) end
            end
        end
    end
end))

track(player.Idled:Connect(function()
    if config.antiAfk then
        pcall(function()
            local VU = game:GetService("VirtualUser")
            VU:CaptureController(); VU:ClickButton2(Vector2.new())
        end)
    end
end))

local function isEggPrompt(p)
    if not p:IsA("ProximityPrompt") then return false end
    local name = p.Name:lower(); local action = (p.ActionText or ""):lower()
    if name:find("carryareaegg", 1, true) then return true end
    if action:find("carry", 1, true) or action:find("steal", 1, true) then return true end
    if name:find("egg", 1, true) and (action:find("grab", 1, true) or action:find("take", 1, true) or action:find("pick", 1, true)) then return true end
    return false
end
local eggPromptCache = { t = -10, list = {} }
local function collectEggPrompts()
    if os.clock() - eggPromptCache.t < 2 then
        local alive = {}
        for _, p in ipairs(eggPromptCache.list) do if p.Parent then table.insert(alive, p) end end
        return alive
    end
    local result = {}
    local function scan(list)
        for _, d in ipairs(list) do if d:IsA("ProximityPrompt") and isEggPrompt(d) then table.insert(result, d) end end
    end
    local folder = Workspace:FindFirstChild("AreaEggSlotsClient")
    if folder then scan(folder:GetDescendants()) end
    if #result == 0 then scan(Snapshot.get()) end
    eggPromptCache.t = os.clock(); eggPromptCache.list = result
    return result
end

local OWNER_ATTRS = { "Owner", "OwnerId", "OwnerUserId", "OwnerName", "UserId", "PlayerName", "Player" }
local function ownedByMe(inst)
    local myName = player.Name:lower(); local myDisplay = player.DisplayName:lower(); local myId = tostring(player.UserId)
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
    local function addAttrs(inst) for k, v in pairs(inst:GetAttributes()) do table.insert(parts, tostring(k):lower() .. ":" .. tostring(v):lower()) end end
    addAttrs(root)
    local count = 0
    for _, d in ipairs(root:GetDescendants()) do
        count += 1; if count > 80 then break end
        table.insert(parts, d.Name:lower()); addAttrs(d)
        if d:IsA("TextLabel") then table.insert(parts, d.Text:lower()) end
    end
    return table.concat(parts, " ")
end
local function collectAncestorText(inst)
    local parts = {}; local cur = inst
    while cur and cur ~= Workspace do
        table.insert(parts, cur.Name:lower())
        for k, v in pairs(cur:GetAttributes()) do
            if type(v) == "string" then table.insert(parts, tostring(k):lower() .. ":" .. v:lower()) end
        end
        cur = cur.Parent
    end
    return table.concat(parts, " ")
end
local function detectAreaFromText(normText)
    for _, entry in ipairs(AREA_DETECT) do for _, key in ipairs(entry[2]) do
        if normText:find(key, 1, true) then return entry[1] end
    end end
    return nil
end
local function nearestAreaByCenter(pos)
    local count, best, bestD = 0, nil, math.huge
    for name, c in pairs(areaCenters) do
        count += 1; local d = (c - pos).Magnitude
        if d < bestD then best, bestD = name, d end
    end
    if count >= 2 then return best end
    return nil
end

local VARIANT_KEYS = { "silver", "golden", "rainbow", "bloom", "parasite", "monstrous", "fractured", "scrambled" }
local VARIANT_ALIASES = { ["parasite"] = { "parasite", "monstrous" }, ["spirit bloom"] = { "spirit bloom", "spiritbloom", "spirit_bloom" } }
local function matchesValue(root, text, key)
    key = key:lower()
    if key == "normal" then
        for _, k in ipairs(VARIANT_KEYS) do if text:find(k, 1, true) then return false end end
        return true
    end
    if key == "common" then text = (text:gsub("uncommon", "")) end
    if key == "bloom" then text = (text:gsub("spirit[%s_]*bloom", "")) end
    local aliases = VARIANT_ALIASES[key]
    if aliases then
        for _, a in ipairs(aliases) do if text:find(a, 1, true) then return true end end
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
    for _, cat in ipairs({ "Size", "Rarity", "Variant" }) do if next(filters[cat]) ~= nil then return true end end
    return false
end
local function passesFilters(root, text, filters)
    for _, cat in ipairs({ "Size", "Rarity", "Variant" }) do
        local set = filters[cat]
        if next(set) ~= nil then
            local ok = false
            for key, on in pairs(set) do
                if on and matchesValue(root, text, key) then ok = true; break end
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
        if not pos then c.nopos += 1
        elseif banned[prompt] and banned[prompt] > os.clock() then c.banned += 1
        else table.insert(cands, { prompt = prompt, pos = pos, d = (pos - hrp.Position).Magnitude }) end
    end
    table.sort(cands, function(a, b) return a.d < b.d end)
    local examined = 0
    for _, cand in ipairs(cands) do
        if best and best.enabled then break end
        if examined >= 40 then break end
        local prompt, pos = cand.prompt, cand.pos
        if config.skipOwn and ownedByMe(prompt) then c.mine += 1
        else
            examined += 1
            local root = getEggRoot(prompt)
            local text = (filterOn or areaOn) and collectEggText(root) or nil
            local area = nil; local pass = true
            if areaOn then
                area = detectAreaFromText(norm(collectAncestorText(prompt) .. " " .. text)) or nearestAreaByCenter(pos)
                if not area or not config.areas[area] then c.area += 1; pass = false end
            end
            if pass and filterOn and not passesFilters(root, text, config.filters) then c.filtered += 1; pass = false end
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

local function flyToInner(hrp, targetPos, speed, alive, through)
    local lastPos, lastT, stalls = hrp.Position, os.clock(), 0
    local accel = math.max(speed * 4, 80)
    local cur = V25.flyCarry or 0
    local stopDist = through or 1.5
    while alive() do
        if not hrp.Parent then V25.flyCarry = 0; return false end
        local delta = targetPos - hrp.Position
        local dist = delta.Magnitude
        if dist < stopDist then break end
        local dt = math.min(RunService.Heartbeat:Wait(), 0.1)
        local want = through and speed or math.min(speed, math.sqrt(2 * accel * dist) + 2)
        if cur < want then cur = math.min(want, cur + accel * dt)
        else cur = math.max(want, cur - accel * 2 * dt) end
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
                stalls += 1; Protect.unstick(hrp)
                if stalls >= 3 then V25.flyCarry = 0; return false end
            else stalls = 0 end
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
local function goTo(hrp, targetPos, alive)
    if config.method ~= "Fly" then return V25.legitWalk(targetPos, alive) end
    local speed = config.flySpeed
    V25.flyCarry = 0
    if (hrp.Position - targetPos).Magnitude < 15 then return flyTo(hrp, targetPos, speed, alive) end
    local cruiseY = math.max(hrp.Position.Y, targetPos.Y) + config.flyHeight
    if not flyTo(hrp, Vector3.new(hrp.Position.X, cruiseY, hrp.Position.Z), speed, alive, 2.5) then return false end
    if not flyTo(hrp, Vector3.new(targetPos.X, cruiseY, targetPos.Z), speed, alive, 12) then return false end
    return flyTo(hrp, targetPos, speed, alive)
end

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request
local function validWebhook(url)
    if type(url) ~= "string" then return false end
    return url:match("^https://[%w%.]*discord%.com/api/webhooks/") ~= nil
        or url:match("^https://[%w%.]*discordapp%.com/api/webhooks/") ~= nil
end
local function postWebhook(url, payload)
    if not validWebhook(url) then return false, "URL webhook tidak valid" end
    if not httpRequest then return false, "executor tidak punya request" end
    local ok, res = pcall(httpRequest, { Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(payload) })
    if not ok then return false, tostring(res) end
    local code = res and (res.StatusCode or res.status_code)
    if code and code >= 200 and code < 300 then return true end
    return false, "HTTP " .. tostring(code)
end
local webhookQueue = {}; local webhookWorker = false
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
local function cut(s, n) s = tostring(s); if #s > n then return s:sub(1, n - 3) .. "..." end; return s end
local function embedPayload(title, color, fields)
    return { username = "EX Steal an Egg", embeds = { { title = title, color = color, fields = fields, footer = { text = "EX COMMUNITY • " .. VERSION }, timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ") } } }
end
local function describeEgg(root)
    if not root then return { name = "Telur", detail = "" } end
    local parts = {}
    for k, v in pairs(root:GetAttributes()) do table.insert(parts, tostring(k) .. ": " .. tostring(v)) end
    table.sort(parts); while #parts > 8 do table.remove(parts) end
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
        for _, nm in ipairs(names) do if n:find(nm, 1, true) then return v, "attribute " .. tostring(k) end end
    end
    for _, d in ipairs(playerGui:GetDescendants()) do
        if d:IsA("TextLabel") and not (sg and d:IsDescendantOf(sg)) and d.Text ~= "" then
            local n = d.Name:lower()
            for _, nm in ipairs(names) do
                if n:find(nm, 1, true) and (not textMustHave or d.Text:find(textMustHave, 1, true)) then return d.Text, "HUD " .. d.Name end
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
            if os.clock() - last >= config.statsIntervalMin * 60 then last = os.clock(); sendStatsWebhook(false) end
        end
    end)
end

local brainWanted
local Treadmill = { inst = nil, notified = false }
local function treadmillSpot(inst)
    if inst:IsA("BasePart") then return inst.Position + Vector3.new(0, inst.Size.Y / 2 + 3, 0) end
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
                    if score < bestScore then best, bestScore = d, score end
                end
            end
        end
    end
    Treadmill.inst = best
    return best
end
function Treadmill.run(duration)
    local hrp, hum = getChar()
    if not hrp or not hum then task.wait(1); return end
    local inst = findTreadmill()
    if not inst then
        if not Treadmill.notified then Treadmill.notified = true; log("Treadmill tidak ditemukan. Cek tab Debug.") end
        setStatus("Idle (treadmill tidak ada)", THEME.warn)
        task.wait(duration); return
    end
    local spot = treadmillSpot(inst)
    if not spot then task.wait(duration); return end
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
        if inst:IsA("TextLabel") then if textLooksLikeGain(inst.Text) then target = inst end
        elseif inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
            for _, d in ipairs(inst:GetDescendants()) do
                if d:IsA("TextLabel") and textLooksLikeGain(d.Text) then target = inst; break end
            end
        end
        if target then pcall(function() target:Destroy() end) end
    end
    local function killFx(inst) pcall(function() inst.Enabled = false end) end
    local function onAdded(inst)
        if FX_CLASSES[inst.ClassName] then killFx(inst)
        elseif inst:IsA("TextLabel") or inst:IsA("BillboardGui") or inst:IsA("SurfaceGui") then
            if #queue - head < 2000 then queue[#queue + 1] = { inst, os.clock() + 0.08 } end
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
                    queue[head] = false; head += 1; processed += 1
                    if e[1].Parent then checkPopup(e[1]) end
                end
                if head > #queue then table.clear(queue); head = 1 end
            end
            loopOn = false
        end)
    end
    setPopupCleaner = function(state)
        config.removePopups = state
        for _, c in ipairs(popupConns) do c:Disconnect() end
        table.clear(popupConns)
        if not state then loopOn = false; table.clear(queue); head = 1; return end
        table.insert(popupConns, Workspace.DescendantAdded:Connect(onAdded))
        table.insert(popupConns, playerGui.DescendantAdded:Connect(onAdded))
        startLoop()
    end
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

do
    local PathfindingService = game:GetService("PathfindingService")
    local function flatDist(a, b) return (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude end
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
                    task.wait(0.1); nudgeIfStuck(stuck)
                end
                conn:Disconnect()
            end
        end
        while alive() and hrp.Parent and os.clock() - t0 <= limit and flatDist(hrp.Position, dest) > 8 do
            hum:MoveTo(dest); task.wait(0.25); nudgeIfStuck(stuck)
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

local lastSweep = 0; local sweepIdx = 0
local function waitForTarget(hrp, alive)
    local target = findTarget(hrp, false)
    if target then return target end
    if config.legit then return nil end
    if os.clock() - lastSweep < 90 then return nil end
    lastSweep = os.clock()
    local visit = {}
    for name, pos in pairs(areaCenters) do
        if next(config.areas) == nil or config.areas[name] then table.insert(visit, { name = name, pos = pos }) end
    end
    table.sort(visit, function(a, b) return a.name < b.name end)
    local picked = {}
    for i = 1, math.min(2, #visit) do sweepIdx = sweepIdx % #visit + 1; table.insert(picked, visit[sweepIdx]) end
    for _, v in ipairs(picked) do
        if not alive() then return nil end
        setStatus("Menuju area " .. v.name .. "...", THEME.warn)
        pcall(function() player:RequestStreamAroundAsync(v.pos, 3) end)
        goTo(hrp, v.pos, alive)
        local t0 = os.clock()
        repeat task.wait(0.5); target = findTarget(hrp, true)
        until target or not alive() or os.clock() - t0 > 3
        if target then return target end
    end
    if baseCFrame and alive() then goTo(hrp, baseCFrame.Position, alive) end
    return nil
end

local function stealCycle(alive)
    local hrp, hum = getChar()
    if not hrp or not hum or hum.Health <= 0 then task.wait(1); return "none" end
    ensureBase()
    setStatus("Mencari telur...", THEME.accent2)
    local target = waitForTarget(hrp, alive)
    if not alive() then return "none" end
    if not target then setStatus("Tidak ada telur", THEME.warn); return "none" end
    local prompt = target.prompt
    log(("Target: %s (%d stud%s)"):format(prompt:GetFullName(), math.floor(target.dist), target.enabled and "" or ", prompt nonaktif"))
    setStatus(config.method == "Fly" and not config.legit and "Terbang..." or "Berjalan...", THEME.accent2)
    local reached
    if config.legit then reached = V25.legitWalk(target.pos, alive)
    else reached = goTo(hrp, target.pos + Vector3.new(0, 3, 0), alive) end
    if not alive() then return "none" end
    if not reached and hrp.Parent and (hrp.Position - target.pos).Magnitude > 25 then
        stats.failed += 1; banned[prompt] = os.clock() + 15
        log("Gagal mencapai telur, dilewati 15 detik"); refreshStats(); return "failed"
    end
    task.wait(0.3)
    if prompt.Parent and not prompt.Enabled then
        local t0 = os.clock()
        while alive() and prompt.Parent and not prompt.Enabled and os.clock() - t0 < 2 do task.wait(0.1) end
        if prompt.Parent and not prompt.Enabled and not config.legit then pcall(function() prompt.Enabled = true end) end
    end
    setStatus("Mengambil telur...", THEME.accent)
    local success = false
    for _ = 1, 3 do
        if not alive() then return "none" end
        if not prompt.Parent then success = true; break end
        if config.legit then V25.legitTrigger(prompt) else triggerPrompt(prompt) end
        task.wait(0.4)
        if isCarrying() or not prompt.Parent or not prompt.Enabled then success = true; break end
    end
    local result
    if success then
        stats.stolen += 1; result = "stolen"; log("Telur berhasil diambil")
        local info = describeEgg(target.root); info.area = target.area; sendEggWebhook(info)
    else
        stats.failed += 1; result = "failed"; banned[prompt] = os.clock() + 20
        log("Gagal mengambil telur, dilewati 20 detik")
    end
    refreshStats()
    if baseCFrame and alive() then
        setStatus("Pulang ke base...", THEME.good)
        if config.legit then V25.legitWalk(baseCFrame.Position, alive)
        else goTo(hrp, baseCFrame.Position, alive) end
        task.wait(0.5)
    end
    return result
end

local EventBan = {}; local EventAttempts = {}
local function anyEventEnabled()
    for _, on in pairs(config.events) do if on then return true end end
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
                    local inside = false; local anc = d.Parent
                    while anc and anc ~= Workspace do
                        if matched[anc] then inside = true; break end
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
                if dist < bestD then best, bestD = cand, dist end
            end
        end
    end
    return best
end
local function runEvent(def, t, alive)
    local hrp = getHRP(); if not hrp then return end
    local inst = t.inst
    setStatus("Event: " .. def.name, THEME.accent)
    log("Event " .. def.name .. " -> " .. inst:GetFullName())
    goTo(hrp, t.pos + Vector3.new(0, 3, 4), alive)
    if def.mode == "attack" then
        local tool = equipTool(def.tool)
        local t0 = os.clock()
        while alive() and inst.Parent and os.clock() - t0 < 40 do
            local p = getInstPosition(inst); local h = getHRP()
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
            if t.prompt and t.prompt.Parent then fired = triggerPrompt(t.prompt)
            else fired = firePromptsNear(t.pos, 14, nil) > 0 end
            local h = getHRP()
            if not fired and h and typeof(firetouchinterest) == "function" and inst:IsA("BasePart") then
                pcall(firetouchinterest, h, inst, 0); pcall(firetouchinterest, h, inst, 1)
            end
            if tool and tool.Parent == player.Character then pcall(function() tool:Activate() end) end
            task.wait(0.35)
        end
    else
        local h = getHRP()
        if h then
            if (h.Position - t.pos).Magnitude > 4 then goTo(h, t.pos + Vector3.new(0, 1.5, 0), alive) end
            if typeof(firetouchinterest) == "function" and inst:IsA("BasePart") then
                pcall(firetouchinterest, h, inst, 0); pcall(firetouchinterest, h, inst, 1)
            end
            task.wait(0.4)
        end
    end
    if inst.Parent then
        EventAttempts[inst] = (EventAttempts[inst] or 0) + 1
        if EventAttempts[inst] >= 4 then EventBan[inst] = os.clock() + 30; EventAttempts[inst] = nil end
    else EventAttempts[inst] = nil end
end
local function eventStep(alive)
    local hrp = getHRP(); if not hrp then return false end
    for _, def in ipairs(EVENT_DEFS) do
        if config.events[def.id] and alive() then
            local t = findEventTarget(def, hrp)
            if t then runEvent(def, t, alive); return true end
        end
    end
    return false
end

local function nearBase(pos, radius) return baseCFrame ~= nil and (pos - baseCFrame.Position).Magnitude <= radius end
local function actOnPrompts(kws)
    local hrp = getHRP(); if not hrp then return 0 end
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
    if #btns > 0 then clickButton(btns[1]); task.wait(0.3) end
    local n = actOnPrompts(HINTS.hatch)
    if n > 0 then log("Auto Hatch: " .. n) end
end
local function eggToolMatches(tool)
    local text = tool.Name:lower()
    for k, v in pairs(tool:GetAttributes()) do text = text .. " " .. tostring(k):lower() .. ":" .. tostring(v):lower() end
    return passesFilters(tool, text, config.placeFilters)
end
local function autoPlaceOnce()
    ensureBase()
    local hrp, hum = getChar(); if not hrp or not hum then return end
    if not isCarrying() then
        for _, t in ipairs(player.Backpack:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("egg", 1, true) and eggToolMatches(t) then
                pcall(function() hum:EquipTool(t) end); task.wait(0.3); break
            end
        end
    end
    local n = actOnPrompts(HINTS.place)
    if n > 0 then log("Auto Place: " .. n) end
end
local function autoFuseOnce()
    ensureBase()
    local n = actOnPrompts(HINTS.fuse)
    if n > 0 then
        task.wait(0.8)
        for _ = 1, 3 do clickFirstMatching({ "auto select", "select all", "fuse" }); task.wait(0.5) end
        log("Auto Fuse dijalankan")
    end
end
local function autoIndexOnce()
    local claimed = 0
    local function claimAll()
        for _, b in ipairs(findButtons(HINTS.index, false)) do
            if clickButton(b) then claimed += 1; task.wait(0.15) end
        end
    end
    claimAll()
    if claimed == 0 then
        local open = findButtons({ "index" }, true)
        if #open > 0 then clickButton(open[1]); task.wait(0.6); claimAll(); clickButton(open[1]) end
    end
    if claimed > 0 then log("Auto Claim Index: " .. claimed) end
end

do
    local warned = {}
    local function warnOnce(key, msg) if not warned[key] then warned[key] = true; log(msg) end end
    local GEAR_WORDS = { "bat", "net", "racket", "racquet", "scrambler", "consumable", "booster", "potion" }
    local MAX_ITEMS_PER_RUN = 12
    local alive = function() return uiAlive end
    local function allTools()
        local list = {}
        local _, _, char = getChar()
        if char then for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") then table.insert(list, t) end end end
        for _, t in ipairs(player.Backpack:GetChildren()) do if t:IsA("Tool") then table.insert(list, t) end end
        return list
    end
    local function toolAlive(t) return t.Parent == player.Backpack or (player.Character ~= nil and t.Parent == player.Character) end
    local function itemText(tool)
        local parts = { tool.Name:lower() }
        for k, v in pairs(tool:GetAttributes()) do table.insert(parts, tostring(k):lower() .. ":" .. tostring(v):lower()) end
        local count = 0
        for _, d in ipairs(tool:GetDescendants()) do
            count += 1; if count > 40 then break end
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
            if favKey and v and v ~= 0 and v ~= "" then return true end
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
        for _, w in ipairs(names) do if text:find(w, 1, true) then return true end end
        if hasAnyFilter(filters) and passesFilters(tool, text, filters) then return true end
        return false
    end
    local function equipHeld(tool)
        local _, hum = getChar(); if not hum then return false end
        if tool.Parent ~= player.Character then pcall(function() hum:EquipTool(tool) end); task.wait(0.3) end
        return tool.Parent == player.Character
    end
    local function backToBase()
        local hrp = getHRP(); if hrp and baseCFrame then goTo(hrp, baseCFrame.Position, alive) end
    end
    local function clickLabeled(keys, bannedWords)
        for _, b in ipairs(findButtons(keys, false)) do
            local lab = (buttonLabel(b) .. " " .. b.Name):lower()
            local skip = false
            for _, w in ipairs(bannedWords) do if lab:find(w, 1, true) then skip = true; break end end
            if not skip and clickButton(b) then return true end
        end
        return false
    end
    local function sellTools(tools, label)
        local hrp = getHRP(); if not hrp then return 0 end
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
                                goTo(hrp, pos + Vector3.new(0, 3, 0), alive); task.wait(0.2); triggerPrompt(p)
                                done = true; break
                            end
                        end
                    end
                end
                if not done then warnOnce("sell_none_" .. label, "Auto Sell: tombol tidak ditemukan. Cek Debug."); break end
                task.wait(0.35); clickLabeled({ "confirm" }, {}); task.wait(0.4)
                if toolAlive(tool) then
                    fails += 1
                    if fails >= 2 then warnOnce("sell_fail_" .. label, "Auto Sell: item tidak terjual. Dihentikan."); break end
                else sold += 1; fails = 0 end
            end
        end
        backToBase(); return sold
    end
    function V25.autoSellOnce()
        ensureBase()
        if not hasAnyFilter(config.sellFilters) then warnOnce("sell_nofilter", "Auto Sell Egg: pilih rarity dulu."); return end
        local list = {}
        for _, t in ipairs(allTools()) do
            if isEggTool(t) then
                local text = itemText(t)
                if not isFavorited(t, text) and passesFilters(t, text, config.sellFilters) then table.insert(list, t) end
            end
        end
        if #list == 0 then return end
        local n = sellTools(list, "egg"); if n > 0 then log("Auto Sell: " .. n) end
    end
    local favTried = {}
    function V25.autoFavoriteOnce()
        local names = parseNames(config.favNames)
        if #names == 0 and not hasAnyFilter(config.favFilters) then warnOnce("fav_nocrit", "Auto Favorit: isi kriteria dulu."); return end
        local done, fails = 0, 0
        for _, t in ipairs(allTools()) do
            if done >= 8 or not uiAlive then break end
            if not isGearTool(t) and (favTried[t] == nil or favTried[t] < os.clock()) then
                local text = itemText(t)
                if not isFavorited(t, text) and matchesSpec(t, text, names, config.favFilters) then
                    favTried[t] = os.clock() + 300
                    if equipHeld(t) then
                        local clicked = clickLabeled(HINTS.favorite, { "unfav", "unlock" })
                        if not clicked then warnOnce("fav_btn", "Auto Favorit: tombol tidak ditemukan."); break end
                        task.wait(0.4)
                        if isFavorited(t, itemText(t)) then done += 1; fails = 0
                        else
                            fails += 1
                            if fails >= 2 then warnOnce("fav_fail", "Auto Favorit: klik tidak efek. Dihentikan."); break end
                        end
                    end
                end
            end
        end
        if done > 0 then log("Auto Favorit: " .. done) end
    end
    local function contextText(btn)
        local parts = {}; local cur = btn
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
    local function hasWord(text, words) for _, w in ipairs(words) do if text:find(w, 1, true) then return true end end; return false end
    local function upgradeOnce(key)
        local def = UPGRADES[key]
        ensureBase()
        local clicked = 0
        for _, b in ipairs(findButtons(HINTS.upgrade, false)) do
            local ctx = contextText(b)
            if hasWord(ctx, def.words) and not ctx:find("robux", 1, true) and not ctx:find("r$", 1, true) then
                if clickButton(b) then clicked += 1; task.wait(0.3) end
                if clicked >= 5 then break end
            end
        end
        if clicked == 0 then
            local hrp = getHRP(); local n = 0
            for _, p in ipairs(Snapshot.get()) do
                if n >= 3 or not hrp then break end
                if p:IsA("ProximityPrompt") and p.Parent and p.Enabled and promptMatches(p, HINTS.upgrade) then
                    local pos = getPromptPosition(p)
                    local full = p:GetFullName():lower()
                    if pos and hasWord(full, def.words) and (ownedByMe(p) or nearBase(pos, BASE_RADIUS)) then
                        goTo(hrp, pos + Vector3.new(0, 3, 0), alive); task.wait(0.2); triggerPrompt(p)
                        clicked += 1; n += 1; task.wait(0.4)
                    end
                end
            end
            if clicked > 0 then backToBase() end
        end
        if clicked > 0 then log("Auto Upgrade " .. def.name .. ": " .. clicked .. "x")
        else warnOnce("upg_" .. key, "Auto Upgrade " .. def.name .. ": tombol tidak ditemukan.") end
    end
    function V25.autoUpgTrailOnce() upgradeOnce("upgTrail") end
    function V25.autoUpgTreadmillOnce() upgradeOnce("upgTreadmill") end
    function V25.autoUpgBaseOnce() upgradeOnce("upgBase") end
    function V25.autoPetPlaceOnce()
        ensureBase()
        local names = parseNames(config.petPlaceNames)
        if #names == 0 and not hasAnyFilter(config.petPlaceFilters) then warnOnce("petplace_nocrit", "Pet Place: isi kriteria dulu."); return end
        local chosen
        for _, t in ipairs(allTools()) do
            if isPetTool(t) then
                local text = itemText(t)
                if matchesSpec(t, text, names, config.petPlaceFilters) then chosen = t; break end
            end
        end
        if not chosen then warnOnce("petplace_none", "Pet Place: tidak ada pet cocok."); return end
        if not equipHeld(chosen) then return end
        local n = actOnPrompts(HINTS.place)
        if n > 0 then log("Pet Place: " .. n .. " prompt dipicu") end
    end
    function V25.autoPetSellOnce()
        ensureBase()
        local names = parseNames(config.petSellNames)
        if #names == 0 and not hasAnyFilter(config.petSellFilters) then warnOnce("petsell_nocrit", "Pet Sell: isi kriteria dulu."); return end
        local list = {}
        for _, t in ipairs(allTools()) do
            if isPetTool(t) then
                local text = itemText(t)
                if not isFavorited(t, text) and matchesSpec(t, text, names, config.petSellFilters) then table.insert(list, t) end
            end
        end
        if #list == 0 then return end
        local n = sellTools(list, "pet"); if n > 0 then log("Pet Sell: " .. n) end
    end
    function V25.scanBackpack(dbg)
        dbg("== SCAN BACKPACK ==")
        for i, t in ipairs(allTools()) do
            if i > 40 then dbg("... dipotong"); break end
            local text = itemText(t)
            local kind = isEggTool(t) and "EGG" or (isGearTool(t) and "GEAR" or "PET/ITEM")
            local attrs = {}
            for k, v in pairs(t:GetAttributes()) do table.insert(attrs, tostring(k) .. "=" .. tostring(v)) end
            dbg(("%s | %s | fav=%s | attr: %s"):format(t.Name, kind, tostring(isFavorited(t, text)), #attrs > 0 and table.concat(attrs, ", ") or "-"))
        end
    end
    function V25.scanActions(dbg)
        dbg("== SCAN AKSI ==")
        local n = 0
        for _, group in ipairs({ HINTS.sell, HINTS.upgrade, HINTS.favorite }) do
            for _, b in ipairs(findButtons(group, false)) do
                n += 1; if n > 40 then dbg("... dipotong"); return end
                dbg(("%s | teks='%s' | konteks: %s"):format(b:GetFullName(), buttonLabel(b), contextText(b):sub(1, 90)))
            end
        end
        if n == 0 then dbg("Tidak ada tombol terlihat. Buka menu dulu lalu scan lagi.") end
    end
    local function optsOf(cat) for _, entry in ipairs(FILTERS) do if entry[1] == cat then return entry[2] end end; return {} end
    local function hitsOf(root, text, cat)
        local hits = {}
        for _, o in ipairs(optsOf(cat)) do if matchesValue(root, text, o) then table.insert(hits, o) end end
        return hits
    end
    local function eggPredictText()
        local hrp = getHRP(); if not hrp then return "Karakter belum ada" end
        local list = {}
        for _, p in ipairs(collectEggPrompts()) do
            local pos = getPromptPosition(p)
            if pos and not (config.skipOwn and ownedByMe(p)) then table.insert(list, { p = p, pos = pos, d = (pos - hrp.Position).Magnitude }) end
        end
        if #list == 0 then return "Tidak ada telur terdeteksi" end
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
            table.insert(lines, ("#%d %s | %s | %s | %s | %d stud | %s"):format(
                i, #rar > 0 and table.concat(rar, "/") or "rarity ?",
                #var > 0 and table.concat(var, "/") or "Normal",
                #siz > 0 and siz[1] or "size ?",
                area, math.floor(e.d), verdict))
        end
        return table.concat(lines, "\n")
    end
    local predictToken = 0
    function V25.startEggPredict()
        predictToken += 1; local my = predictToken
        task.spawn(function()
            while uiAlive and config.eggPredict and predictToken == my do
                local ok, txt = pcall(eggPredictText)
                if ui.predictLabel then ui.predictLabel.Text = ok and txt or ("Error: " .. tostring(txt)) end
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
            while waited < iv and uiAlive and config.auto[key] and autoTokens[key] == my do task.wait(0.25); waited += 0.25 end
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

do
    V25.AUTO_META = {
        hatch = { "Auto Hatch", autoHatchOnce }, place = { "Auto Place", autoPlaceOnce },
        fuse = { "Auto Fuse", autoFuseOnce }, index = { "Auto Claim Index", autoIndexOnce },
        sell = { "Auto Sell Egg", V25.autoSellOnce }, favorite = { "Auto Favorit", V25.autoFavoriteOnce },
        upgTrail = { "Upgrade Trail", V25.autoUpgTrailOnce }, upgTreadmill = { "Upgrade Treadmill", V25.autoUpgTreadmillOnce },
        upgBase = { "Upgrade Base", V25.autoUpgBaseOnce }, petPlace = { "Pet: Taruh", V25.autoPetPlaceOnce },
        petSell = { "Pet: Jual", V25.autoPetSellOnce },
    }
    V25.AUTO_ORDER = { "hatch", "place", "fuse", "index", "sell", "favorite", "upgTrail", "upgTreadmill", "upgBase", "petPlace", "petSell" }
    V25.PRIORITY_OPTIONS = { { id = "none", label = "- Kosong -" }, { id = "event", label = "Event (yang aktif)" } }
    for _, key in ipairs(V25.AUTO_ORDER) do table.insert(V25.PRIORITY_OPTIONS, { id = key, label = V25.AUTO_META[key][1] }) end
    local valid = { none = true, event = true }; for k in pairs(V25.AUTO_META) do valid[k] = true end
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
            for key, meta in pairs(V25.AUTO_META) do if config.auto[key] then runAutoLoop(key, meta[2]) end end
        end
    end
end

local function openShop(def)
    task.spawn(function()
        Lock.run(function()
            local btns = findButtons(def.gui, true)
            if #btns == 0 then btns = findButtons(def.gui, false) end
            for _, b in ipairs(btns) do
                if clickButton(b) then log("Membuka " .. def.name); return end
            end
            local hrp = getHRP(); if not hrp then return end
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
                        if dist < bestD then best, bestD = cand, dist end
                    end
                end
            end
            if best then
                goTo(hrp, best.pos + Vector3.new(0, 3, 3), function() return uiAlive end)
                task.wait(0.3)
                if best.prompt then triggerPrompt(best.prompt) end
                log("Menuju " .. def.name)
            else log(def.name .. " tidak ditemukan.") end
        end)
    end)
end

local function anyPriorityAutoEnabled()
    if not config.priorityOn then return false end
    for key in pairs(V25.AUTO_META) do if config.auto[key] then return true end end
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
                if not hrp then task.wait(1); return end
                if config.priorityOn then
                    for _, id in ipairs(config.priority) do
                        if not brainWanted() then break end
                        if id == "steal" then
                            if config.running and stealCycle(aliveSteal) ~= "none" then did = true; return end
                        elseif id == "event" then
                            if anyEventEnabled() and eventStep(aliveEvents) then did = true; return end
                        else
                            local meta = V25.AUTO_META[id]
                            if meta and config.auto[id] and V25.autoDue(id) then
                                V25.lastAutoRun[id] = os.clock()
                                local okA, errA = pcall(meta[2])
                                if not okA then log("Priority " .. meta[1] .. " error: " .. tostring(errA)) end
                                did = true; return
                            end
                        end
                    end
                else
                    if anyEventEnabled() and eventStep(aliveEvents) then did = true; return end
                    if config.running then
                        local res = stealCycle(aliveSteal)
                        if res ~= "none" then did = true; return end
                    end
                end
                if config.treadmillIdle then Treadmill.run(4)
                else task.wait(2.5) end
            end)
            if not ok then log("Error: " .. tostring(err)); task.wait(1) end
            task.wait(did and 0.2 or 0.4)
        end
        brainRunning = false
        setStatus("Idle", THEME.sub)
        log("AFK manager berhenti")
    end)
end

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
            if plotRemovable(d) then pcall(function() d:Destroy() end); removed += 1
            else skipped += 1 end
        end
    end
    log(("Plot dihapus: %d (dilewati: %d)"):format(removed, skipped))
end
local function setPlotWatcher(state)
    if plotWatcher then plotWatcher:Disconnect(); plotWatcher = nil end
    if not state then return end
    plotWatcher = Workspace.DescendantAdded:Connect(function(d)
        task.delay(0.1, function()
            if d.Parent and nameHas(d.Name, "plot") and plotRemovable(d) then pcall(function() d:Destroy() end) end
        end)
    end)
    track(plotWatcher)
end
local antiLagConn
local function setAntiLag(state)
    if antiLagConn then antiLagConn:Disconnect(); antiLagConn = nil end
    if not state then return end
    local function clean(v)
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then pcall(function() v.Enabled = false end) end
    end
    task.spawn(function() for _, v in ipairs(Workspace:GetDescendants()) do clean(v) end end)
    antiLagConn = Workspace.DescendantAdded:Connect(clean)
    track(antiLagConn)
end
local function superFpsBoost()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic; v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1 end
        end
    end)
    plotKeepMine = true
    removePlots(); setPlotWatcher(true); setAntiLag(true)
    log("Super FPS Boost aktif")
end

do
    local savedVolume
    function V25.setAfkSaver(state)
        config.afkSaver = state and true or false
        pcall(function() RunService:Set3dRenderingEnabled(not state) end)
        if typeof(setfpscap) == "function" then pcall(setfpscap, state and math.clamp(config.fpsCap, 5, 60) or 60) end
        pcall(function()
            local gs = UserSettings():GetService("UserGameSettings")
            if state then savedVolume = savedVolume or gs.MasterVolume; gs.MasterVolume = 0
            elseif savedVolume then gs.MasterVolume = savedVolume; savedVolume = nil end
        end)
    end
end

local function cleanup()
    uiAlive = false
    config.running = false; config.treadmillIdle = false
    config.statsWebhookOn = false; config.eggWebhookOn = false
    config.priorityOn = false; config.eggPredict = false
    if config.afkSaver then pcall(V25.setAfkSaver, false) end
    for k in pairs(config.events) do config.events[k] = false end
    for k in pairs(config.auto) do config.auto[k] = false end
    Protect.flying = false; Protect.treadmillActive = false
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
            hum:Move(Vector3.zero, false); hum.PlatformStand = false
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        end)
    end
    if sg then pcall(function() sg:Destroy() end) end
    if _G.EX_STEAL_EGG_CLEANUP == cleanup then _G.EX_STEAL_EGG_CLEANUP = nil end
end
_G.EX_STEAL_EGG_CLEANUP = cleanup

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

    local function new(class, props, parent)
        local o = Instance.new(class)
        for k, v in pairs(props) do o[k] = v end
        if o:IsA("GuiObject") and props.LayoutOrder == nil then
            orderCounter += 1; o.LayoutOrder = orderCounter
        end
        if parent then o.Parent = parent end
        return o
    end
    local function corner(o, r) new("UICorner", { CornerRadius = UDim.new(0, r or 6) }, o) end
    local function fit(frame, layout)
        local function upd() frame.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y) end
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(upd); upd()
    end
    local function makeDraggable(handle, target)
        local state = { moved = false }
        local dragging, dragStart, startPos = false, nil, nil
        track(handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; state.moved = false; dragStart = input.Position; startPos = target.Position
                local conn
                conn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false; if conn then conn:Disconnect() end end
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

    sg = new("ScreenGui", {
        Name = "EX_StealAnEgg_V29", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
    })
    sg.Parent = playerGui

    local win = new("Frame", {
        Name = "Window", Size = UDim2.fromOffset(W, H),
        Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2),
        BackgroundColor3 = Color3.fromRGB(4, 2, 10), BorderSizePixel = 0, ClipsDescendants = true,
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

    -- Background: blackhole animasi (tanpa gambar)
    local bh = { rings = {}, stars = nil, core = nil }
    local bgRoot = new("Frame", {
        Name = "BlackholeBG", Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(4, 2, 10), BorderSizePixel = 0,
        ClipsDescendants = true, ZIndex = -5,
    }, win)
    corner(bgRoot, 10)
    local D = math.max(W, H) * 1.5
    local function disc(size, color, transp, z)
        local f = new("Frame", {
            Size = UDim2.fromOffset(size, size),
            Position = UDim2.new(0.5, -size / 2, 0.5, -size / 2),
            BackgroundColor3 = color, BackgroundTransparency = transp,
            BorderSizePixel = 0, ZIndex = z,
        }, bgRoot)
        new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
        return f
    end
    disc(D * 1.15, Color3.fromRGB(60, 20, 120), 0.82, -4)
    disc(D * 0.85, Color3.fromRGB(90, 30, 170), 0.78, -4)
    local ringDefs = {
        { D * 0.78, 10, 0.05, 38 },
        { D * 0.62, 14, 0.00, -62 },
        { D * 0.48, 9, 0.10, 95 },
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
    local starLayer = new("Frame", {
        Size = UDim2.fromOffset(D, D),
        Position = UDim2.new(0.5, -D / 2, 0.5, -D / 2),
        BackgroundTransparency = 1, ZIndex = -2,
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
            BorderSizePixel = 0, ZIndex = -2,
        }, starLayer)
        new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, dot)
    end
    bh.stars = starLayer
    local core = disc(D * 0.34, Color3.new(0, 0, 0), 0, -1)
    local coreStroke = new("UIStroke", { Thickness = 4, Color = Color3.fromRGB(255, 160, 80), Transparency = 0.15 }, core)
    bh.core = core; bh.coreStroke = coreStroke
    new("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(6, 3, 14),
        BackgroundTransparency = 0.62, BorderSizePixel = 0, ZIndex = -1,
    }, bgRoot)

    local header = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1 }, win)
    local titleLbl = new("TextLabel", {
        Size = UDim2.new(1, -66, 1, -4), Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1, Text = "STEAL AN EGG PREMIUM | EX - TNJ",
        TextColor3 = WHITE, TextScaled = true, Font = FONT_B,
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
        Size = UDim2.new(1, -24, 0, 3), Position = UDim2.new(0, 12, 0, 42),
        BackgroundColor3 = WHITE, BorderSizePixel = 0,
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
        Size = UDim2.fromOffset(18, 18), Position = UDim2.new(1, -46, 0.5, -11),
        BackgroundColor3 = THEME.off, BackgroundTransparency = 0, Text = "-",
        TextColor3 = WHITE, TextSize = 14, Font = FONT_B,
    }, header)
    corner(minBtn, 5)
    new("UIStroke", { Color = THEME.accent2, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, minBtn)
    local closeBtn = new("TextButton", {
        Size = UDim2.fromOffset(18, 18), Position = UDim2.new(1, -24, 0.5, -11),
        BackgroundColor3 = THEME.bad, BackgroundTransparency = 0, Text = "X",
        TextColor3 = WHITE, TextSize = 11, Font = FONT_B,
    }, header)
    corner(closeBtn, 5)
    new("UIStroke", { Color = THEME.accent2, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, closeBtn)
    makeDraggable(header, win)

    local MIN_W, MIN_H = 340, 280
    local grip = new("TextButton", {
        Name = "ResizeGrip", Size = UDim2.fromOffset(30, 30),
        Position = UDim2.new(1, -30, 1, -30), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, ZIndex = 30,
    }, win)
    for _, p in ipairs({ { 21, 21 }, { 14, 21 }, { 21, 14 }, { 7, 21 }, { 14, 14 }, { 21, 7 } }) do
        local dot = new("Frame", {
            Size = UDim2.fromOffset(3, 3), Position = UDim2.fromOffset(p[1], p[2]),
            BackgroundColor3 = THEME.accent2, BackgroundTransparency = 0.2,
            BorderSizePixel = 0, ZIndex = 31,
        }, grip)
        corner(dot, 2)
    end
    local resizing, rStart, rSize = false, nil, nil
    track(grip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true; rStart = input.Position; rSize = win.AbsoluteSize
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
            Name = "EXIcon", Size = UDim2.fromOffset(60, 60),
            Position = UDim2.new(0, 24, 0, 60), BackgroundTransparency = 1,
            Text = "", AutoButtonColor = false, Visible = false,
        }, sg)
        local glow = new("Frame", {
            Size = UDim2.new(1, 12, 1, 12), Position = UDim2.new(0, -6, 0, -6),
            BackgroundTransparency = 1, BorderSizePixel = 0,
        }, icon)
        new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, glow)
        iconGlowStroke = new("UIStroke", { Color = THEME.accent, Thickness = 6, Transparency = 0.7,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, glow)
        local disk = new("Frame", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = DARK,
            BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 2,
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
        local shade = new("Frame", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = DARK,
            BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 4,
        }, disk)
        new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, shade)
        new("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "EX",
            TextColor3 = WHITE, TextSize = 22, Font = FONT_B,
            TextStrokeColor3 = THEME.accent, TextStrokeTransparency = 0.3, ZIndex = 5,
        }, disk)
    end
    local iconDrag = makeDraggable(icon, icon)
    minBtn.MouseButton1Click:Connect(function() win.Visible = false; icon.Visible = true end)
    icon.MouseButton1Click:Connect(function()
        if iconDrag.moved then return end
        win.Visible = true; icon.Visible = false
    end)
    closeBtn.MouseButton1Click:Connect(function() cleanup() end)

    -- Border FX: petir + batu jatuh (default OFF, toggle di CONFIG)
    do
        local rnd = Random.new((os.time() % 100000) + 7)
        local fxLayer = new("Frame", {
            Name = "BorderFX", Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ClipsDescendants = true, Active = false, ZIndex = 25,
            Visible = config.fxBorder ~= false,
        }, win)
        ui.fxLayer = fxLayer
        local CORE_COL = Color3.fromRGB(240, 224, 255)
        local SEGS = 5
        local EDGES = { 1, 3, 2, 4, 3, 4 }
        local bolts = {}
        for i = 1, #EDGES do
            local b = { edge = EDGES[i], segs = {}, active = false, nextT = os.clock() + rnd:NextNumber(0.2, 1.5), endT = 0 }
            for s = 1, SEGS + 1 do
                local glow = new("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = THEME.accent,
                    BackgroundTransparency = 0.5, BorderSizePixel = 0,
                    Size = UDim2.fromOffset(2, 7), Visible = false, ZIndex = 26,
                }, fxLayer)
                local core2 = new("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = CORE_COL,
                    BorderSizePixel = 0, Size = UDim2.fromOffset(2, 3), Visible = false, ZIndex = 27,
                }, fxLayer)
                b.segs[s] = { glow = glow, core = core2 }
            end
            bolts[i] = b
        end
        local function setSeg(q, x1, y1, x2, y2)
            local dx, dy = x2 - x1, y2 - y1
            local len = math.sqrt(dx * dx + dy * dy) + 2
            local rot = math.deg(math.atan2(dy, dx))
            local pos = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2)
            q.glow.Position = pos; q.glow.Rotation = rot; q.glow.Size = UDim2.fromOffset(len, 7)
            q.core.Position = pos; q.core.Rotation = rot; q.core.Size = UDim2.fromOffset(len, 3)
            q.glow.Visible = true; q.core.Visible = true
        end
        local function strike(b)
            local W_, H_ = win.AbsoluteSize.X, win.AbsoluteSize.Y
            local e = b.edge
            local length = (e <= 2) and W_ or H_
            local span = length * rnd:NextNumber(0.22, 0.4)
            local start = rnd:NextNumber(0, math.max(1, length - span))
            local pts = {}
            for i = 0, SEGS do
                local along = start + span * i / SEGS
                local perp = (i == 0 or i == SEGS) and 2 or rnd:NextNumber(3, 13)
                local x, y
                if e == 1 then x, y = along, perp
                elseif e == 2 then x, y = along, H_ - perp
                elseif e == 3 then x, y = perp, along
                else x, y = W_ - perp, along end
                pts[i] = Vector2.new(x, y)
            end
            for i = 1, SEGS do setSeg(b.segs[i], pts[i - 1].X, pts[i - 1].Y, pts[i].X, pts[i].Y) end
            local o = pts[2]
            local inx, iny = 0, 0
            if e == 1 then iny = 1 elseif e == 2 then iny = -1 elseif e == 3 then inx = 1 else inx = -1 end
            local blen = rnd:NextNumber(10, 20); local lat = rnd:NextNumber(-8, 8)
            local tx = o.X + inx * blen + ((e <= 2) and lat or 0)
            local ty = o.Y + iny * blen + ((e > 2) and lat or 0)
            setSeg(b.segs[SEGS + 1], o.X, o.Y, tx, ty)
        end
        local rocks = {}
        for i = 1, 12 do
            local size = rnd:NextInteger(5, 11)
            local f = new("Frame", {
                Size = UDim2.fromOffset(size, size), AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(34, 14, 62), BorderSizePixel = 0, ZIndex = 26,
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
            if icon.Visible then
                iconGrad.Rotation = (iconGrad.Rotation + dt * 150) % 360
                local t = os.clock() * 3
                iconGlowStroke.Transparency = 0.62 + 0.2 * math.sin(t)
                iconGlowStroke.Thickness = 6 + 2 * math.sin(t)
            end
            if not win.Visible or not fxLayer.Visible then return end
            acc += dt
            if acc < 0.033 then return end
            local step = math.min(acc, 0.1); acc = 0
            local now = os.clock()
            local W_, H_ = win.AbsoluteSize.X, win.AbsoluteSize.Y
            for _, b in ipairs(bolts) do
                if b.active then
                    if now >= b.endT then
                        b.active = false
                        for _, q in ipairs(b.segs) do q.glow.Visible = false; q.core.Visible = false end
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
                r.y += r.vy * step; r.rot += r.vr * step
                if r.y > H_ + 12 then
                    r.y = -12 - rnd:NextNumber(0, 60)
                    r.vy = rnd:NextNumber(70, 150); r.off = rnd:NextNumber(6, 12)
                end
                local x = (r.side == 1) and r.off or (W_ - r.off)
                r.f.Position = UDim2.fromOffset(x, r.y)
                r.f.Rotation = r.rot
            end
        end))
    end

    local side = new("ScrollingFrame", {
        Size = UDim2.new(0, SIDE, 1, -58), Position = UDim2.new(0, 6, 0, 52),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, win)
    new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, side)
    local content = new("Frame", {
        Size = UDim2.new(1, -(SIDE + 18), 1, -58), Position = UDim2.new(0, SIDE + 12, 0, 52),
        BackgroundTransparency = 1,
    }, win)

    local tabs = {}
    local function selectTab(t)
        for _, o in ipairs(tabs) do
            local on = (o == t)
            o.page.Visible = on
            o.btn.BackgroundColor3 = on and THEME.accent or THEME.card
            o.btn.BackgroundTransparency = on and 0 or 0.05
            o.btn.TextColor3 = on and WHITE or THEME.sub
            if o.stroke then o.stroke.Color = on and THEME.accent2 or THEME.off end
            if o.paintIcon then o.paintIcon(on and WHITE or THEME.sub) end
        end
    end
    local function buildTabIcon(parent, kind)
        local box = new("Frame", {
            Size = UDim2.fromOffset(20, 20), Position = UDim2.new(0, 7, 0.5, -10),
            BackgroundTransparency = 1,
        }, parent)
        local parts = {}
        local function shape(x, y, w, h, o)
            o = o or {}
            local f = new("Frame", {
                Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
                BackgroundColor3 = THEME.sub, BackgroundTransparency = o.outline and 1 or 0,
                BorderSizePixel = 0, Rotation = o.rot or 0,
            }, box)
            if o.round == "full" then new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
            elseif o.round then new("UICorner", { CornerRadius = UDim.new(0, o.round) }, f) end
            if o.outline then
                local st = new("UIStroke", { Color = THEME.sub, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
                table.insert(parts, { st, "Color" })
            else table.insert(parts, { f, "BackgroundColor3" }) end
        end
        if kind == "MAIN" then
            shape(4, 2, 12, 16, { outline = true, round = "full" }); shape(8, 9, 4, 4, { round = "full" })
        elseif kind == "PRIORITY" then
            shape(3, 4, 14, 3, { round = 1 }); shape(3, 9, 14, 3, { round = 1 }); shape(3, 14, 9, 3, { round = 1 })
        elseif kind == "AREA" then
            shape(4, 1, 12, 12, { outline = true, round = "full" }); shape(8, 5, 4, 4, { round = "full" }); shape(9, 13, 2, 6, { round = 1 })
        elseif kind == "AUTOMATION" then
            shape(4, 4, 12, 12, { outline = true, round = "full" }); shape(8, 8, 4, 4, { round = "full" })
            shape(9, 0, 2, 4); shape(9, 16, 2, 4); shape(0, 9, 4, 2); shape(16, 9, 4, 2)
        elseif kind == "EVENT" then
            shape(4, 4, 12, 12, { outline = true }); shape(4, 4, 12, 12, { outline = true, rot = 45 }); shape(8, 8, 4, 4, { round = "full" })
        elseif kind == "SHOP" then
            shape(6, 1, 8, 9, { outline = true, round = "full" }); shape(3, 8, 14, 11, { round = 2 })
        elseif kind == "PROTEKSI" then
            shape(4, 1, 12, 10, { round = 2 }); shape(5, 6, 10, 10, { rot = 45, round = 1 })
        elseif kind == "WEBHOOK" then
            shape(1, 6, 11, 8, { outline = true, round = "full" }); shape(8, 6, 11, 8, { outline = true, round = "full" })
        elseif kind == "CONFIG" then
            shape(2, 4, 16, 2, { round = 1 }); shape(2, 9, 16, 2, { round = 1 }); shape(2, 14, 16, 2, { round = 1 })
            shape(4, 2, 5, 6, { round = "full" }); shape(12, 7, 5, 6, { round = "full" }); shape(6, 12, 5, 6, { round = "full" })
        else
            shape(6, 5, 8, 12, { round = "full" }); shape(7, 1, 6, 5, { round = "full" })
            shape(2, 8, 4, 2); shape(14, 8, 4, 2); shape(2, 13, 4, 2); shape(14, 13, 4, 2)
        end
        return function(col) for _, p in ipairs(parts) do p[1][p[2]] = col end end
    end
    local function addTab(name)
        local btn = new("TextButton", {
            Size = UDim2.new(1, -4, 0, 38), BackgroundColor3 = THEME.card, Text = name,
            TextColor3 = THEME.sub, TextSize = 12, TextScaled = true, Font = FONT_B, AutoButtonColor = false,
        }, side)
        corner(btn, 8)
        local tabStroke = new("UIStroke", { Color = THEME.off, Thickness = 2.5, Transparency = 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, btn)
        new("UITextSizeConstraint", { MaxTextSize = 12, MinTextSize = 7 }, btn)
        new("UIPadding", { PaddingLeft = UDim.new(0, 32), PaddingRight = UDim.new(0, 4) }, btn)
        local paintIcon = buildTabIcon(btn, name)
        local page = new("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 4, CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
        }, content)
        new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, page)
        new("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 12) }, page)
        local t = { btn = btn, page = page, stroke = tabStroke, paintIcon = paintIcon }
        table.insert(tabs, t)
        btn.MouseButton1Click:Connect(function() selectTab(t) end)
        return page
    end

    local function card(parent, h)
        local f = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = THEME.card,
            BackgroundTransparency = 0.08, BorderSizePixel = 0 }, parent)
        corner(f, 6)
        return f
    end
    local function label(parent, text, size, color, font)
        return new("TextLabel", {
            BackgroundTransparency = 1, Text = text, TextSize = size or 12,
            TextColor3 = color or THEME.text, Font = font or FONT_R,
            TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
        }, parent)
    end
    local function section(parent, text)
        local l = label(parent, text, 11, THEME.accent2, FONT_B)
        l.Size = UDim2.new(1, 0, 0, 18); return l
    end
    local function note(parent, text)
        local l = label(parent, text, 11, THEME.sub)
        l.Size = UDim2.new(1, 0, 0, 0); l.AutomaticSize = Enum.AutomaticSize.Y; return l
    end
    local function safeCall(cb, ...)
        local ok, err = pcall(cb, ...)
        if not ok then log("Error UI: " .. tostring(err)) end
    end
    local function buttonRow(parent, text, cb, color)
        local b = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = color or THEME.accent,
            BackgroundTransparency = 0, Text = text, TextColor3 = WHITE,
            TextSize = 13, Font = FONT_B, AutoButtonColor = true,
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
            sl.Size = UDim2.new(1, -lblW, 0, 16); sl.Position = UDim2.new(0, 10, 0, 28)
            sl.TextWrapped = false; sl.TextTruncate = Enum.TextTruncate.AtEnd
        end
        local sw = new("TextButton", {
            Size = UDim2.fromOffset(46, 24), Position = UDim2.new(1, -58, 0.5, -12),
            BackgroundColor3 = THEME.off, Text = "", AutoButtonColor = false,
        }, row)
        corner(sw, 12)
        local knob = new("Frame", {
            Size = UDim2.fromOffset(18, 18), Position = UDim2.new(0, 3, 0.5, -9),
            BackgroundColor3 = WHITE, BorderSizePixel = 0,
        }, sw)
        corner(knob, 9)
        local isOn = default and true or false
        local function paint(animate)
            local kp = isOn and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            local col = isOn and THEME.accent or THEME.off
            if animate then
                TweenService:Create(knob, TweenInfo.new(0.15), { Position = kp }):Play()
                TweenService:Create(sw, TweenInfo.new(0.15), { BackgroundColor3 = col }):Play()
            else knob.Position = kp; sw.BackgroundColor3 = col end
        end
        paint(false)
        sw.MouseButton1Click:Connect(function()
            isOn = not isOn; paint(true); safeCall(cb, isOn)
        end)
        return { row = row, set = function(v) isOn = v and true or false; paint(false) end, get = function() return isOn end }
    end
    local function choiceRow(parent, title, options, current, cb)
        local row = card(parent, 58)
        local t = label(row, title, 11, THEME.sub, FONT_M)
        t.Size = UDim2.new(1, -20, 0, 16); t.Position = UDim2.new(0, 10, 0, 4)
        local btns = {}; local n = #options
        local function paint(val)
            for v, b in pairs(btns) do
                local on = (v == val)
                b.BackgroundColor3 = on and THEME.accent or THEME.off
                b.TextColor3 = on and WHITE or THEME.sub
            end
        end
        for i, opt in ipairs(options) do
            local b = new("TextButton", {
                Size = UDim2.new(1 / n, -8, 0, 26), Position = UDim2.new((i - 1) / n, 6, 0, 24),
                BackgroundColor3 = THEME.off, Text = opt[2], TextColor3 = THEME.sub,
                TextSize = 11, Font = FONT_B, AutoButtonColor = false,
            }, row)
            corner(b, 5); btns[opt[1]] = b
            b.MouseButton1Click:Connect(function() paint(opt[1]); safeCall(cb, opt[1]) end)
        end
        paint(current)
        return { paint = paint }
    end
    local function stepperRow(parent, title, value, minV, maxV, step, cb, suffix)
        local row = card(parent, 34)
        local t = label(row, title, 12, THEME.text, FONT_M)
        t.Size = UDim2.new(1, -126, 1, 0); t.Position = UDim2.new(0, 10, 0, 0)
        local val = math.clamp(tonumber(value) or minV, minV, maxV)
        local vl = new("TextLabel", {
            Size = UDim2.fromOffset(46, 24), Position = UDim2.new(1, -86, 0.5, -12),
            BackgroundTransparency = 1, TextColor3 = THEME.accent2, TextSize = 12, Font = FONT_B, Text = "",
        }, row)
        local function show() vl.Text = tostring(val) .. (suffix or "") end
        local function mk(txt, x, delta)
            local b = new("TextButton", {
                Size = UDim2.fromOffset(26, 24), Position = UDim2.new(1, x, 0.5, -12),
                BackgroundColor3 = THEME.off, Text = txt, TextColor3 = THEME.text,
                TextSize = 14, Font = FONT_B,
            }, row)
            corner(b, 5)
            b.MouseButton1Click:Connect(function() val = math.clamp(val + delta, minV, maxV); show(); safeCall(cb, val) end)
        end
        mk("-", -116, -step); mk("+", -36, step)
        show()
    end
    local function textboxRow(parent, title, value, placeholder, cb)
        local row = card(parent, 58)
        local t = label(row, title, 11, THEME.sub, FONT_M)
        t.Size = UDim2.new(1, -20, 0, 16); t.Position = UDim2.new(0, 10, 0, 4)
        local box = new("TextBox", {
            Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 24),
            BackgroundColor3 = THEME.off, TextColor3 = THEME.text,
            PlaceholderText = placeholder, PlaceholderColor3 = THEME.sub,
            Text = value or "", TextSize = 11, Font = FONT_R, ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        }, row)
        corner(box, 5)
        box.FocusLost:Connect(function() safeCall(cb, box.Text) end)
        return box
    end
    local function textBox(parent, h)
        local sc = new("ScrollingFrame", {
            Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = THEME.bg2,
            BackgroundTransparency = 0.06, BorderSizePixel = 0, ScrollBarThickness = 3,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, parent)
        corner(sc, 6)
        local lbl = new("TextLabel", {
            Size = UDim2.new(1, -8, 0, 0), Position = UDim2.new(0, 4, 0, 2),
            AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
            TextColor3 = THEME.sub, TextSize = 11, Font = Enum.Font.Code,
            TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top, Text = "",
        }, sc)
        return sc, lbl
    end
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
            if not cats or table.find(cats, cat) then
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
                        Text = opt, TextSize = 11, Font = FONT_M,
                        BackgroundColor3 = THEME.off, TextColor3 = THEME.sub, AutoButtonColor = false,
                    }, grid)
                    corner(chip, 5)
                    local function paint()
                        local on = sets[cat][opt] == true
                        chip.BackgroundColor3 = on and THEME.accent or THEME.off
                        chip.TextColor3 = on and WHITE or THEME.sub
                        chip.Font = on and FONT_B or FONT_M
                    end
                    paint(); table.insert(painters, paint)
                    chip.MouseButton1Click:Connect(function()
                        if sets[cat][opt] then sets[cat][opt] = nil else sets[cat][opt] = true end
                        paint()
                    end)
                end
            end
        end
        local clr = buttonRow(body, "Reset pilihan filter ini", function()
            for _, cat in ipairs({ "Size", "Rarity", "Variant" }) do table.clear(sets[cat]) end
            for _, p in ipairs(painters) do p() end
        end, THEME.off)
        clr.TextSize = 11
        return wrap
    end
    local function dropdownRow(parent, title, options, current, cb)
        local wrap = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, parent)
        local wl = new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, wrap)
        fit(wrap, wl)
        local head = card(wrap, 34)
        head.LayoutOrder = 1
        local t = label(head, title, 12, THEME.text, FONT_M)
        t.Size = UDim2.new(0.22, 0, 1, 0); t.Position = UDim2.new(0, 10, 0, 0)
        local btn = new("TextButton", {
            Size = UDim2.new(0.78, -18, 0, 24), Position = UDim2.new(0.22, 4, 0.5, -12),
            BackgroundColor3 = THEME.off, TextColor3 = THEME.text, TextSize = 11,
            Font = FONT_B, AutoButtonColor = false, TextTruncate = Enum.TextTruncate.AtEnd, Text = "",
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
                Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = THEME.off,
                Text = o.label, TextColor3 = THEME.sub, TextSize = 11,
                Font = FONT_M, AutoButtonColor = true,
            }, body)
            corner(ob, 5)
            ob.MouseButton1Click:Connect(function()
                body.Visible = false; show(o.id); safeCall(cb, o.id)
            end)
        end
        btn.MouseButton1Click:Connect(function() body.Visible = not body.Visible end)
        return wrap
    end

    -- ===== TAB MAIN =====
    local pageMain = addTab("MAIN")
    section(pageMain, "STATUS")
    local statusCard = card(pageMain, 62)
    ui.statusDot = new("Frame", {
        Size = UDim2.fromOffset(10, 10), Position = UDim2.new(0, 10, 0, 9),
        BackgroundColor3 = THEME.sub, BorderSizePixel = 0,
    }, statusCard)
    corner(ui.statusDot, 5)
    ui.statusText = label(statusCard, "Idle", 12, THEME.text, FONT_B)
    ui.statusText.Size = UDim2.new(1, -34, 0, 18); ui.statusText.Position = UDim2.new(0, 28, 0, 5)
    ui.statsText = label(statusCard, "", 11, THEME.sub)
    ui.statsText.Size = UDim2.new(1, -20, 0, 16); ui.statsText.Position = UDim2.new(0, 10, 0, 26)
    ui.modeText = label(statusCard, "", 11, THEME.sub)
    ui.modeText.Size = UDim2.new(1, -20, 0, 16); ui.modeText.Position = UDim2.new(0, 10, 0, 43)
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
        else log("Auto Steal OFF") end
        refreshStats()
    end)
    toggleRow(pageMain, "Treadmill saat idle", false, function(on)
        config.treadmillIdle = on
        if on then ensureBrain() end
    end, "Lari di treadmill bila tidak ada kerjaan")
    toggleRow(pageMain, "Lewati telur milik sendiri", config.skipOwn, function(on) config.skipOwn = on end)
    toggleRow(pageMain, "Legit Steal", config.legit, function(on)
        config.legit = on
        log("Legit Steal " .. (on and "ON" or "OFF"))
        refreshStats()
    end, "Jalan kaki + tahan tombol seperti pemain biasa")
    choiceRow(pageMain, "Cara bergerak", { { "Walk", "Jalan (humanoid)" }, { "Fly", "Terbang halus" } }, config.method, function(v)
        config.method = v; refreshStats()
    end)
    choiceRow(pageMain, "Mode target", { { "All", "Semua telur" }, { "Filter", "Pakai filter" } }, config.targetMode, function(v)
        config.targetMode = v; refreshStats()
    end)
    stepperRow(pageMain, "Kecepatan terbang", config.flySpeed, 30, 400, 10, function(v) config.flySpeed = v end)
    stepperRow(pageMain, "Tinggi terbang", config.flyHeight, 0, 60, 2, function(v) config.flyHeight = v end)
    buttonRow(pageMain, "Set Base di posisi sekarang", function()
        local hrp = getHRP()
        if hrp then baseCFrame = hrp.CFrame + Vector3.new(0, 3, 0); log("Base disimpan") end
    end, THEME.off)
    section(pageMain, "FILTER TELUR")
    multiSelect(pageMain, "Filter Size / Rarity / Variant", config.filters)
    section(pageMain, "EGG PREDICT")
    toggleRow(pageMain, "Egg Predict", false, function(on)
        config.eggPredict = on
        if on then V25.startEggPredict()
        elseif ui.predictLabel then ui.predictLabel.Text = "Egg Predict OFF" end
    end, "Baca rarity / variant / size telur terdekat")
    local predictCard = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = THEME.card, BackgroundTransparency = 0.08, BorderSizePixel = 0,
    }, pageMain)
    corner(predictCard, 6)
    new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, predictCard)
    ui.predictLabel = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Text = "Egg Predict OFF", TextColor3 = THEME.sub,
        TextSize = 11, Font = Enum.Font.Code, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    }, predictCard)
    note(pageMain, "Membaca teks/atribut telur yang terlihat di client.")
    section(pageMain, "AUTO SELL EGG")
    toggleRow(pageMain, "Auto Sell Egg", false, function(on)
        setAuto("sell", on, V25.autoSellOnce); log("Auto Sell Egg " .. (on and "ON" or "OFF"))
    end, "Jual egg di backpack sesuai rarity")
    multiSelect(pageMain, "Filter Rarity yang dijual", config.sellFilters, { "Rarity" })
    section(pageMain, "AUTO FAVORIT")
    toggleRow(pageMain, "Auto Favorit", false, function(on)
        setAuto("favorite", on, V25.autoFavoriteOnce); log("Auto Favorit " .. (on and "ON" or "OFF"))
    end, "Favoritkan item sesuai nama / rarity")
    textboxRow(pageMain, "Nama item (pisahkan dengan koma)", config.favNames, "contoh: dragon, phoenix", function(txt)
        config.favNames = txt
    end)
    multiSelect(pageMain, "Filter Rarity & Variant", config.favFilters, { "Rarity", "Variant" })
    section(pageMain, "LOG")
    local logScroll, logLabel = textBox(pageMain, 150)
    ui.logScroll, ui.logLabel = logScroll, logLabel

    -- ===== TAB PRIORITY =====
    local pagePrio = addTab("PRIORITY")
    note(pagePrio, "Default MATI. Saat dinyalakan, AFK manager mengerjakan sesuai urutan. #1 selalu Steal Egg.")
    toggleRow(pagePrio, "Aktifkan Priority", false, function(on)
        V25.applyPriorityMode(on); log("Priority " .. (on and "ON" or "OFF"))
    end, "Mati = tiap fitur jalan sendiri")
    section(pagePrio, "URUTAN PRIORITAS")
    local lockCard = card(pagePrio, 34)
    local lockLbl = label(lockCard, "#1   Steal Egg  (wajib, terkunci)", 12, THEME.accent2, FONT_B)
    lockLbl.Size = UDim2.new(1, -20, 1, 0); lockLbl.Position = UDim2.new(0, 10, 0, 0)
    for i = 2, 7 do
        dropdownRow(pagePrio, "#" .. i, V25.PRIORITY_OPTIONS, config.priority[i], function(id) config.priority[i] = id end)
    end

    -- ===== TAB AREA =====
    local pageArea = addTab("AREA")
    note(pageArea, "Pilih biome yang boleh dicuri. Kosong = semua area.")
    local areaToggles = {}
    buttonRow(pageArea, "Pilih semua area", function()
        for _, nm in ipairs(AREAS) do config.areas[nm] = true; areaToggles[nm].set(true) end
        refreshStats()
    end, THEME.off)
    buttonRow(pageArea, "Kosongkan pilihan", function()
        for _, nm in ipairs(AREAS) do config.areas[nm] = nil; areaToggles[nm].set(false) end
        refreshStats()
    end, THEME.off)
    for _, nm in ipairs(AREAS) do
        local t = toggleRow(pageArea, nm, config.areas[nm] == true, function(on)
            config.areas[nm] = on or nil; refreshStats()
        end, nil, 56)
        areaToggles[nm] = t
        local pin = new("TextButton", {
            Size = UDim2.fromOffset(46, 22), Position = UDim2.new(1, -114, 0.5, -11),
            BackgroundColor3 = THEME.off, Text = areaCenters[nm] and "SET*" or "SET",
            TextColor3 = areaCenters[nm] and THEME.good or THEME.sub, TextSize = 10, Font = FONT_B,
        }, t.row)
        corner(pin, 5)
        pin.MouseButton1Click:Connect(function()
            local hrp = getHRP(); if not hrp then return end
            areaCenters[nm] = hrp.Position; pin.Text = "SET*"; pin.TextColor3 = THEME.good
            log("Pusat area " .. nm .. " disimpan")
        end)
    end

    -- ===== TAB AUTOMATION =====
    local pageAuto = addTab("AUTOMATION")
    note(pageAuto, "Automation bekerja untuk prompt/tombol di sekitar base (radius " .. BASE_RADIUS .. ").")
    section(pageAuto, "TELUR & INDEX")
    local autoDefs = {
        { "hatch", "Auto Hatch", autoHatchOnce, "Menetaskan telur di base" },
        { "place", "Auto Place", autoPlaceOnce, "Menaruh telur dari backpack" },
        { "fuse", "Auto Fuse", autoFuseOnce, "Menjalankan fuse otomatis" },
        { "index", "Auto Claim Index", autoIndexOnce, "Klaim hadiah Index tiap 60 detik" },
    }
    for _, def in ipairs(autoDefs) do
        toggleRow(pageAuto, def[2], false, function(on)
            setAuto(def[1], on, def[3]); log(def[2] .. (on and " ON" or " OFF"))
        end, def[4])
    end
    stepperRow(pageAuto, "Jeda antar aksi", config.autoInterval, 2, 60, 1, function(v) config.autoInterval = v end, " dtk")
    multiSelect(pageAuto, "Filter telur untuk Place", config.placeFilters)
    section(pageAuto, "UPGRADE")
    local upgDefs = {
        { "upgTrail", "Auto Upgrade Trail", V25.autoUpgTrailOnce, "Klik tombol Upgrade milik Trail" },
        { "upgTreadmill", "Auto Upgrade Treadmill", V25.autoUpgTreadmillOnce, "Klik tombol Upgrade milik Treadmill" },
        { "upgBase", "Auto Upgrade Base", V25.autoUpgBaseOnce, "Klik tombol Upgrade milik Base" },
    }
    for _, def in ipairs(upgDefs) do
        toggleRow(pageAuto, def[2], false, function(on)
            setAuto(def[1], on, def[3]); log(def[2] .. (on and " ON" or " OFF"))
        end, def[4])
    end
    section(pageAuto, "PET AUTOMATION")
    toggleRow(pageAuto, "Auto Taruh Pet di Plot", false, function(on)
        setAuto("petPlace", on, V25.autoPetPlaceOnce); log("Auto Taruh Pet " .. (on and "ON" or "OFF"))
    end, "Pilih pet berdasarkan nama atau rarity")
    textboxRow(pageAuto, "Nama pet yang ditaruh (pisahkan koma)", config.petPlaceNames, "contoh: dragon, cat", function(txt) config.petPlaceNames = txt end)
    multiSelect(pageAuto, "Rarity pet yang ditaruh", config.petPlaceFilters, { "Rarity" })
    toggleRow(pageAuto, "Auto Jual Pet", false, function(on)
        setAuto("petSell", on, V25.autoPetSellOnce); log("Auto Jual Pet " .. (on and "ON" or "OFF"))
    end, "Pilih pet berdasarkan nama atau rarity")
    textboxRow(pageAuto, "Nama pet yang dijual (pisahkan koma)", config.petSellNames, "contoh: rat, mouse", function(txt) config.petSellNames = txt end)
    multiSelect(pageAuto, "Rarity pet yang dijual", config.petSellFilters, { "Rarity" })

    -- ===== TAB EVENT =====
    local pageEvent = addTab("EVENT")
    note(pageEvent, "Event aktif. Nama objek event di game harus sesuai dengan EVENT_DEFS di script.")
    for _, def in ipairs(EVENT_DEFS) do
        toggleRow(pageEvent, def.name, false, function(on)
            config.events[def.id] = on
            if on then ensureBrain() end
            log("Event " .. def.name .. (on and " ON" or " OFF"))
        end, def.desc)
    end

    -- ===== TAB SHOP =====
    local pageShop = addTab("SHOP")
    note(pageShop, "Membuka shop lewat tombol HUD atau terbang ke objek shop. Tombol pembelian tidak pernah diklik otomatis.")
    for _, def in ipairs(SHOPS) do
        buttonRow(pageShop, def.name, function() openShop(def) end)
        note(pageShop, def.info)
    end

    -- ===== TAB PROTEKSI =====
    local pageProt = addTab("PROTEKSI")
    section(pageProt, "PROTEKSI")
    toggleRow(pageProt, "Anti Knockback", config.antiKB, function(on) config.antiKB = on end)
    toggleRow(pageProt, "Anti Trapped", config.antiTrap, function(on) config.antiTrap = on end)
    toggleRow(pageProt, "Anti AFK", config.antiAfk, function(on) config.antiAfk = on end)
    toggleRow(pageProt, "Hapus popup '+Speed' & partikel", config.removePopups, function(on) setPopupCleaner(on) end, "Hemat CPU/RAM")
    section(pageProt, "TAMPILAN & PERFORMA")
    local pingFrame = new("Frame", {
        Size = UDim2.fromOffset(160, 22), Position = UDim2.new(1, -170, 0, 6),
        BackgroundColor3 = THEME.bg2, BackgroundTransparency = 0.08,
        BorderSizePixel = 0, Visible = config.pingPanel,
    }, sg)
    corner(pingFrame, 6)
    ui.pingLabel = new("TextLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        TextColor3 = THEME.good, TextSize = 11, Font = FONT_B, Text = "PING - | FPS -",
    }, pingFrame)
    toggleRow(pageProt, "Panel Ping & FPS", config.pingPanel, function(on)
        config.pingPanel = on; pingFrame.Visible = on
    end)
    local antiLagToggle = toggleRow(pageProt, "Anti Lag (matikan partikel)", config.antiLag, function(on)
        config.antiLag = on; setAntiLag(on)
    end)
    toggleRow(pageProt, "Mode AFK Hemat", false, function(on)
        V25.setAfkSaver(on); log("Mode AFK Hemat " .. (on and "ON" or "OFF"))
    end, "Matikan render 3D, batasi FPS, volume 0")
    stepperRow(pageProt, "Batas FPS saat AFK hemat", config.fpsCap, 5, 60, 5, function(v)
        config.fpsCap = v
        if config.afkSaver and typeof(setfpscap) == "function" then pcall(setfpscap, v) end
    end)
    buttonRow(pageProt, "Hapus plot orang lain (plot sendiri aman)", function()
        plotKeepMine = true; task.spawn(removePlots)
    end, THEME.off)
    buttonRow(pageProt, "Super FPS Boost", function()
        task.spawn(function() superFpsBoost(); config.antiLag = true; antiLagToggle.set(true) end)
    end, THEME.warn)

    -- ===== TAB WEBHOOK =====
    local pageWh = addTab("WEBHOOK")
    section(pageWh, "NOTIFIKASI TELUR")
    toggleRow(pageWh, "Kirim webhook tiap telur didapat", false, function(on)
        config.eggWebhookOn = on
        if on and not validWebhook(config.eggWebhookUrl) then log("URL webhook telur belum valid") end
    end)
    textboxRow(pageWh, "URL Webhook Discord (telur)", config.eggWebhookUrl, "https://discord.com/api/webhooks/...", function(txt)
        config.eggWebhookUrl = (txt:gsub("%s+", ""))
    end)
    buttonRow(pageWh, "Tes webhook telur", function()
        if not validWebhook(config.eggWebhookUrl) then log("URL webhook telur belum valid"); return end
        queueWebhook(config.eggWebhookUrl, embedPayload("Tes webhook", 0x8B5CF6, {
            { name = "Status", value = "Berhasil terhubung", inline = true },
            { name = "Pemain", value = player.DisplayName, inline = true },
        }))
        log("Tes webhook telur dikirim")
    end, THEME.off)
    section(pageWh, "LAPORAN AFK")
    toggleRow(pageWh, "Kirim laporan berkala", false, function(on)
        config.statsWebhookOn = on
        if on then
            if not validWebhook(config.statsWebhookUrl) then log("URL webhook laporan belum valid") end
            startStatsLoop()
        end
    end)
    textboxRow(pageWh, "URL Webhook Discord (laporan)", config.statsWebhookUrl, "https://discord.com/api/webhooks/...", function(txt)
        config.statsWebhookUrl = (txt:gsub("%s+", ""))
    end)
    stepperRow(pageWh, "Interval laporan", config.statsIntervalMin, 1, 120, 1, function(v) config.statsIntervalMin = v end, " mnt")
    buttonRow(pageWh, "Kirim laporan sekarang", function()
        if not validWebhook(config.statsWebhookUrl) then log("URL webhook laporan belum valid"); return end
        sendStatsWebhook(true); log("Laporan dikirim")
    end, THEME.off)

    -- ===== TAB CONFIG =====
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
        saveBtn.Text = ok and "TERSIMPAN!" or "GAGAL (executor tidak support writefile)"
        task.delay(1.5, function() if saveBtn.Parent then saveBtn.Text = "SAVE CONFIG SEKARANG" end end)
    end)
    note(pageCfg, "File config: " .. SAVE_FILE)
    buttonRow(pageCfg, "Hapus file simpanan", function()
        if typeof(delfile) == "function" and typeof(isfile) == "function" then
            pcall(function() if isfile(SAVE_FILE) then delfile(SAVE_FILE) end end)
            lastSavedJson = nil
            config.autoSave = false; autoSaveToggle.set(false)
            log("File simpanan dihapus.")
        else log("Executor tidak mendukung delfile") end
    end, THEME.bad)
    buttonRow(pageCfg, "Unload script", function() cleanup() end, THEME.bad)

    -- ===== TAB DEBUG =====
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
            if i > 15 then dbg("... dipotong"); break end
            local pos = getPromptPosition(p)
            local d = (hrp and pos) and math.floor((pos - hrp.Position).Magnitude) or -1
            dbg(("%s | aksi='%s' | aktif=%s | jarak=%s | milikku=%s"):format(
                p:GetFullName(), tostring(p.ActionText), tostring(p.Enabled), tostring(d), tostring(ownedByMe(p))))
        end
    end
    local function scanUI()
        dbg("== SCAN UI ==")
        local n = 0
        for _, d in ipairs(playerGui:GetDescendants()) do
            if (d:IsA("TextButton") or d:IsA("ImageButton")) and not d:IsDescendantOf(sg) and guiVisible(d) then
                n += 1; if n > 60 then dbg("... dipotong"); break end
                dbg(("%s | teks='%s'"):format(d:GetFullName(), buttonLabel(d)))
            end
        end
    end
    local function scanPrompts()
        local hrp = getHRP()
        if not hrp then dbg("Karakter belum ada"); return end
        dbg("== SCAN PROMPT (radius 120) ==")
        local n = 0
        for _, p in ipairs(Workspace:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                local pos = getPromptPosition(p)
                if pos and (pos - hrp.Position).Magnitude <= 120 then
                    n += 1; if n > 40 then dbg("... dipotong"); break end
                    dbg(("%s | aksi='%s' | objek='%s' | aktif=%s"):format(
                        p:GetFullName(), tostring(p.ActionText), tostring(p.ObjectText), tostring(p.Enabled)))
                end
            end
        end
    end
    local function scanRemotes()
        dbg("== SCAN REMOTE ==")
        local n = 0
        for _, d in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
                n += 1; if n > 80 then dbg("... dipotong"); break end
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
        if typeof(setclipboard) == "function" then setclipboard(table.concat(dbgLines, "\n")); log("Output debug disalin")
        else log("Executor tidak mendukung setclipboard") end
    end, THEME.off)
    buttonRow(pageDbg, "Bersihkan output", function() table.clear(dbgLines); if dbgLabel then dbgLabel.Text = "" end end, THEME.off)
    local _, dl = textBox(pageDbg, 220)
    dbgLabel = dl

    -- Animasi border + panel ping
    local frames, lastT = 0, os.clock()
    track(RunService.RenderStepped:Connect(function(dt)
        if not uiAlive then return end
        strokeGrad.Rotation = (strokeGrad.Rotation + dt * 50) % 360
        for _, r in ipairs(bh.rings) do r.grad.Rotation = (r.grad.Rotation + dt * r.speed) % 360 end
        if bh.stars then bh.stars.Rotation = (bh.stars.Rotation + dt * 9) % 360 end
        if bh.coreStroke then bh.coreStroke.Transparency = 0.2 + 0.2 * math.sin(os.clock() * 1.6) end
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
                    and d.Size.X.Scale > 0.3 then addStroke(d, 2) end
            end
        end
    end
    selectTab(tabs[1])
    refreshStats()
    setStatus("Idle", THEME.sub)
end

-- START
if config.method ~= "Fly" and config.method ~= "Walk" then config.method = "Walk" end
if config.targetMode ~= "All" and config.targetMode ~= "Filter" then config.targetMode = "All" end

local okUI, errUI = pcall(buildUI)
if not okUI then
    warn("[EX Steal an Egg] Gagal membuat UI: " .. tostring(errUI))
    pcall(cleanup)
    return
end
if config.removePopups then setPopupCleaner(true) end
if config.antiLag then setAntiLag(true) end
task.spawn(function()
    while uiAlive do
        task.wait(2)
        if uiAlive and config.autoSave then saveSettings() end
    end
end)
log("EX Steal an Egg " .. VERSION .. " berhasil dimuat")