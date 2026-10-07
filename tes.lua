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

local function interesting(s)
    s = string.lower(tostring(s))

    return
        s:find("egg") or
        s:find("rarity") or
        s:find("variant") or
        s:find("size") or
        s:find("scale") or
        s:find("weight") or
        s:find("type") or
        s:find("mutation") or
        s:find("gold") or
        s:find("rainbow") or
        s:find("giant") or
        s:find("large") or
        s:find("medium") or
        s:find("small")
end

add("===== EGG DATA CHECK =====")
add("")

local total = 0

for _, model in ipairs(folder:GetChildren()) do
    if model:IsA("Model") then

        local found = {}

        -- Attribute model + semua descendant
        for _, obj in ipairs(model:GetDescendants()) do

            for key, value in pairs(obj:GetAttributes()) do
                local line = obj:GetFullName()
                    .. " | ATTR "
                    .. key
                    .. "="
                    .. tostring(value)

                if interesting(key) or interesting(value) then
                    table.insert(found, line)
                end
            end

            -- ValueBase
            if obj:IsA("ValueBase") then
                local line = obj:GetFullName()
                    .. " | VALUE "
                    .. obj.Name
                    .. "="
                    .. tostring(obj.Value)

                if interesting(obj.Name) or interesting(obj.Value) then
                    table.insert(found, line)
                end
            end

            -- Object/part/model name
            if interesting(obj.Name) then
                table.insert(
                    found,
                    obj:GetFullName() .. " | NAME"
                )
            end
        end

        -- Attribute model itu sendiri
        for key, value in pairs(model:GetAttributes()) do
            if interesting(key) or interesting(value) then
                table.insert(
                    found,
                    model:GetFullName()
                    .. " | MODEL_ATTR "
                    .. key
                    .. "="
                    .. tostring(value)
                )
            end
        end

        if #found > 0 then
            total += 1

            add("===== EGG #" .. total .. " =====")
            add("MODEL: " .. model:GetFullName())

            local ok, _, size = pcall(function()
                return model:GetBoundingBox()
            end)

            if ok then
                add(string.format(
                    "BOUNDING: %.2f x %.2f x %.2f",
                    size.X,
                    size.Y,
                    size.Z
                ))
            end

            for _, line in ipairs(found) do
                add(line)
            end

            add("")
        end
    end
end

add("===== TOTAL MATCH: " .. total .. " =====")

local result = table.concat(out, "\n")

pcall(function()
    if setclipboard then
        setclipboard(result)
    end
end)

print(result)

local old = player.PlayerGui:FindFirstChild("EggDataCheck")
if old then
    old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "EggDataCheck"
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

local frame = Instance.new("ScrollingFrame")
frame.Parent = gui
frame.Size = UDim2.new(0.94, 0, 
