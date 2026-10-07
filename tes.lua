local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local function dump(inst, depth, out, maxDepth)
    if depth > maxDepth then return end

    local indent = string.rep("  ", depth)

    local attrList = {}
    for k, v in pairs(inst:GetAttributes()) do
        table.insert(attrList, k .. "=" .. tostring(v))
    end

    local extra = (#attrList > 0) and (" | ATTR: " .. table.concat(attrList, ", ")) or ""

    table.insert(
        out,
        indent .. "• " .. inst.Name .. " [" .. inst.ClassName .. "]" .. extra
    )

    if inst:IsA("ValueBase") then
        table.insert(out, indent .. "  VALUE = " .. tostring(inst.Value))
    end

    if inst:IsA("ProximityPrompt") then
        table.insert(out, indent .. "  PROMPT ActionText=" .. tostring(inst.ActionText))
        table.insert(out, indent .. "  PROMPT ObjectText=" .. tostring(inst.ObjectText))
    end

    if inst:IsA("TextLabel") or inst:IsA("TextButton") then
        if inst.Text ~= "" then
            table.insert(out, indent .. "  TEXT = " .. inst.Text)
        end
    end

    for _, child in ipairs(inst:GetChildren()) do
        dump(child, depth + 1, out, maxDepth)
    end
end

local out = {}

table.insert(out, "===== EGG STRUCTURE INSPECTOR =====")
table.insert(out, "")

local folder = Workspace:FindFirstChild("AreaEggSlotsClient")

if not folder then
    table.insert(out, "AreaEggSlotsClient TIDAK DITEMUKAN.")
else
    table.insert(out, "FOUND: " .. folder:GetFullName())
    table.insert(out, "")

    for _, child in ipairs(folder:GetChildren()) do
        dump(child, 0, out, 8)
        table.insert(out, "")
    end
end

local text = table.concat(out, "\n")

pcall(function()
    if setclipboard then
        setclipboard(text)
    end
end)

local old = player.PlayerGui:FindFirstChild("EggInspect3")
if old then
    old:Destroy()
end

local sg = Instance.new("ScreenGui")
sg.Name = "EggInspect3"
sg.ResetOnSpawn = false
sg.Parent = player.PlayerGui

local sf = Instance.new("ScrollingFrame")
sf.Parent = sg
sf.Size = UDim2.new(0.92, 0, 0.75, 0)
sf.Position = UDim2.new(0.04, 0, 0.12, 0)
sf.BackgroundColor3 = Color3.new(0, 0, 0)
sf.BackgroundTransparency = 0.1
sf.ScrollBarThickness = 8
sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
sf.CanvasSize = UDim2.new(0, 0, 0, 0)

local lbl = Instance.new("TextLabel")
lbl.Parent = sf
lbl.Size = UDim2.new(1, -12, 0, 0)
lbl.AutomaticSize = Enum.AutomaticSize.Y
lbl.BackgroundTransparency = 1
lbl.TextColor3 = Color3.new(1, 1, 1)
lbl.TextWrapped = false
lbl.TextSize = 12
lbl.Font = Enum.Font.Code
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.TextYAlignment = Enum.TextYAlignment.Top
lbl.Text = text

local close = Instance.new("TextButton")
close.Parent = sg
close.Size = UDim2.new(0, 50, 0, 32)
close.Position = UDim2.new(0.94, -50, 0.12, -38)
close.Text = "X"
close.MouseButton1Click:Connect(function()
    sg:Destroy()
end)
