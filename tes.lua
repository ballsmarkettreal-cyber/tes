local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local folder = Workspace:FindFirstChild("AreaEggSlotsClient")

if not folder then
    warn("AreaEggSlotsClient tidak ditemukan")
    return
end

local out = {}

local function add(x)
    table.insert(out, tostring(x))
end

local function ignore(k)
    k = string.lower(tostring(k))
    return k:find("oldid")
        or k:find("dontmodify")
        or k:find("reimport")
end

local function collect(model)
    local data = {}

    local function put(key, value)
        if not ignore(key) then
            data[key] = tostring(value)
        end
    end

    -- Attribute model + descendant
    for _, obj in ipairs(model:GetDescendants()) do
        for k, v in pairs(obj:GetAttributes()) do
            put(obj.Name .. ".ATTR." .. k, v)
        end

        if obj:IsA("ValueBase") then
            put(obj.Name .. ".VALUE", obj.Value)
        end
    end

    for k, v in pairs(model:GetAttributes()) do
        put("MODEL.ATTR." .. k, v)
    end

    -- Prompt info
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            put("PROMPT.ObjectText", obj.ObjectText)
            put("PROMPT.ActionText", obj.ActionText)
            put("PROMPT.HoldDuration", obj.HoldDuration)
        end
    end

    -- Bounding
    local ok, _, size = pcall(function()
        return model:GetBoundingBox()
    end)

    if ok then
        put("BOUNDING.X", string.format("%.3f", size.X))
        put("BOUNDING.Y", string.format("%.3f", size.Y))
        put("BOUNDING.Z", string.format("%.3f", size.Z))
    end

    return data
end

local eggs = {}

for _, model in ipairs(folder:GetChildren()) do
    if model:IsA("Model") then
        table.insert(eggs, {
            model = model,
            data = collect(model)
        })
    end
end

add("===== EGG DIFFERENCE SCAN =====")
add("TOTAL EGG: " .. #eggs)
add("")

-- Tampilkan identitas setiap egg
for i, egg in ipairs(eggs) do
    local source = egg.model:GetAttribute("PreparedSourceName")

    add(
        "#" .. i ..
        " | " ..
        egg.model.Name ..
        " | SOURCE=" ..
        tostring(source or "-")
    )
end

add("")
add("===== FIELD DIFFERENCES =====")

-- Kumpulkan semua key
local keys = {}

for _, egg in ipairs(eggs) do
    for key in pairs(egg.data) do
        keys[key] = true
    end
end

-- Hanya tampilkan field yang nilainya berbeda
for key in pairs(keys) do

    local values = {}
    local different = false
    local firstValue = nil

    for i, egg in ipairs(eggs) do
        local value = egg.data[key] or "<nil>"

        values[i] = value

        if firstValue == nil then
            firstValue = value
        elseif value ~= firstValue then
            different = true
        end
    end

    if different then
        add("")
        add("FIELD: " .. key)

        for i, value in ipairs(values) do
            add("  #" .. i .. " = " .. value)
        end
    end
end

add("")
add("===== END =====")

local result = table.concat(out, "\n")

pcall(function()
    if setclipboard then
        setclipboard(result)
    end
end)

print(result)

-- GUI
local old = player.PlayerGui:FindFirstChild("EggDifferenceScan")
if old then
    old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "EggDifferenceScan"
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

local frame = Instance.new("ScrollingFrame")
frame.Parent = gui
frame.Size = UDim2.new(0.94, 0, 0.80, 0)
frame.Position = UDim2.new(0.03, 0, 0.08, 0)
frame.BackgroundColor3 = Color3.new(0, 0, 0)
frame.BackgroundTransparency = 0.1
frame.ScrollBarThickness = 7
frame.AutomaticCanvasSize = Enum.AutomaticSize.Y

local label = Instance.new("TextLabel")
label.Parent = frame
label.Size = UDim2.new(1, -10, 0, 0)
label.AutomaticSize = Enum.AutomaticSize.Y
label.BackgroundTransparency = 1
label.TextColor3 = Color3.new(1, 1, 1)
label.Font = Enum.Font.Code
label.TextSize = 11
label.TextWrapped = true
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Text = result

local close = Instance.new("TextButton")
close.Parent = gui
close.Size = UDim2.new(0, 45, 0, 30)
close.Position = UDim2.new(0.95, -45, 0.08, -35)
close.Text = "X"

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)
