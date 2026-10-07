local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local folder = Workspace:FindFirstChild("AreaEggSlotsClient")

if not folder then
    warn("AreaEggSlotsClient tidak ditemukan")
    return
end

local out = {}

local function add(s)
    table.insert(out, s)
end

local function hasInterestingText(s)
    s = string.lower(tostring(s))

    return
        s:find("egg") or
        s:find("rarity") or
        s:find("variant") or
        s:find("size") or
        s:find("gold") or
        s:find("rainbow") or
        s:find("giant") or
        s:find("large") or
        s:find("medium") or
        s:find("small") or
        s:find("divine") or
        s:find("mythic") or
        s:find("legend")
end

local function interestingAttributes(inst)
    local result = {}

    for key, value in pairs(inst:GetAttributes()) do
        local str = key .. "=" .. tostring(value)

        -- Abaikan metadata Blender/import yang tidak berguna
        local low = string.lower(str)

        if not (
            low:find("oldid") or
            low:find("dontmodify") or
            low:find("reimport")
        ) then
            table.insert(result, str)
        end
    end

    return result
end

add("===== EGG QUICK SCAN =====")
add("")

local count = 0

for _, model in ipairs(folder:GetChildren()) do
    if model:IsA("Model") then

        local attrs = interestingAttributes(model)
        local source = model:GetAttribute("PreparedSourceName")

        local clues = {}

        -- Attribute model
        for _, a in ipairs(attrs) do
            table.insert(clues, a)
        end

        -- Cari attribute penting di descendant
        for _, d in ipairs(model:GetDescendants()) do
            for key, value in pairs(d:GetAttributes()) do
                local str = key .. "=" .. tostring(value)
                local low = string.lower(str)

                if not (
                    low:find("oldid") or
                    low:find("dontmodify") or
                    low:find("reimport")
                ) then
                    table.insert(clues, d.Name .. "." .. str)
                end
            end
        end

        -- Cari nama object yang berpotensi menjadi petunjuk
        local names = {}

        for _, d in ipairs(model:GetDescendants()) do
            local n = string.lower(d.Name)

            if hasInterestingText(n) then
                table.insert(names, d.Name)
            end

            if d:IsA("ParticleEmitter") then
                table.insert(names, d.Name .. "[Particle]")
            end
        end

        -- Bounding box
        local sizeText = "-"

        local ok, cf, size = pcall(function()
            return model:GetBoundingBox()
        end)

        if ok then
            sizeText = string.format(
                "%.2f x %.2f x %.2f",
                size.X,
                size.Y,
                size.Z
            )
        end

        -- Hanya tampilkan model yang punya petunjuk
        if source or #clues > 0 or #names > 0 then

            count += 1

            add("EGG #" .. count)
            add("Source: " .. tostring(source or "-"))
            add("Model: " .. model.Name)
            add("Bounding: " .. sizeText)

            if #clues > 0 then
                add("Attrs: " .. table.concat(clues, " | "))
            end

            if #names > 0 then
                add("Clues: " .. table.concat(names, ", "))
            end

            add("")
        end
    end
end

add("===== TOTAL: " .. count .. " =====")

local text = table.concat(out, "\n")

pcall(function()
    if setclipboard then
        setclipboard(text)
    end
end)

local old = player.PlayerGui:FindFirstChild("EggQuickScan")
if old then
    old:Destroy()
end

local sg = Instance.new("ScreenGui")
sg.Name = "EggQuickScan"
sg.ResetOnSpawn = false
sg.Parent = player.PlayerGui

local sf = Instance.new("ScrollingFrame")
sf.Parent = sg
sf.Size = UDim2.new(0.92, 0, 0.72, 0)
sf.Position = UDim2.new(0.04, 0, 0.14, 0)
sf.BackgroundColor3 = Color3.new(0, 0, 0)
sf.BackgroundTransparency = 0.1
sf.ScrollBarThickness = 7
sf.AutomaticCanvasSize = Enum.AutomaticSize.Y

local lbl = Instance.new("TextLabel")
lbl.Parent = sf
lbl.Size = UDim2.new(1, -10, 0, 0)
lbl.AutomaticSize = Enum.AutomaticSize.Y
lbl.BackgroundTransparency = 1
lbl.TextColor3 = Color3.new(1, 1, 1)
lbl.Font = Enum.Font.Code
lbl.TextSize = 12
lbl.TextWrapped = true
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.TextYAlignment = Enum.TextYAlignment.Top
lbl.Text = text

local close = Instance.new("TextButton")
close.Parent = sg
close.Size = UDim2.new(0, 45, 0, 30)
close.Position = UDim2.new(0.95, -45, 0.14, -35)
close.Text = "X"

close.MouseButton1Click:Connect(function()
    sg:Destroy()
end)
