local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local hrp = player.Character:WaitForChild("HumanoidRootPart")

local out, seen = {}, {}
local function add(s) table.insert(out, s) end

local function attrs(inst)
    local t = {}
    for k, v in pairs(inst:GetAttributes()) do
        table.insert(t, k .. "=" .. tostring(v))
    end
    return #t > 0 and table.concat(t, ", ") or "-"
end

local function topInstance(inst)
    local p = inst
    while p.Parent and p.Parent ~= Workspace do p = p.Parent end
    return p
end

local params = OverlapParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {player.Character}

for _, v in ipairs(Workspace:GetDescendants()) do
    if v:IsA("ProximityPrompt") and v.Name == "CarryAreaEgg" then
        local part = v.Parent
        if part and part:IsA("BasePart") and (part.Position - hrp.Position).Magnitude < 40 then
            add("== prompt di " .. tostring(part.Position))
            for _, hit in ipairs(Workspace:GetPartBoundsInRadius(part.Position, 12, params)) do
                if hit ~= part and hit.Name ~= "Baseplate" then
                    local top = topInstance(hit)
                    if not seen[top] and top.Name ~= "Terrain" then
                        seen[top] = true
                        add("• " .. top:GetFullName() .. " (" .. top.ClassName .. ") attr: " .. attrs(top))
                        add("    hit: " .. hit.Name .. " attr: " .. attrs(hit))
                        for _, d in ipairs(top:GetDescendants()) do
                            if d:IsA("ValueBase") then
                                add("    value " .. d.Name .. " = " .. tostring(d.Value))
                            elseif d:IsA("TextLabel") and d.Text ~= "" then
                                add("    text = " .. d.Text)
                            end
                        end
                    end
                end
            end
            add("")
        end
    end
end

local text = #out > 0 and table.concat(out, "\n") or "Tidak ada objek dekat prompt"
pcall(function() if setclipboard then setclipboard(text) end end)

local old = player.PlayerGui:FindFirstChild("EggInspect2")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "EggInspect2"
sg.ResetOnSpawn = false
sg.Parent = player.PlayerGui

local sf = Instance.new("ScrollingFrame", sg)
sf.Size = UDim2.new(0.9, 0, 0.6, 0)
sf.Position = UDim2.new(0.05, 0, 0.2, 0)
sf.BackgroundColor3 = Color3.new(0, 0, 0)
sf.BackgroundTransparency = 0.15
sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
sf.CanvasSize = UDim2.new(0, 0, 0, 0)
sf.ScrollBarThickness = 6

local lbl = Instance.new("TextLabel", sf)
lbl.Size = UDim2.new(1, -10, 0, 0)
lbl.AutomaticSize = Enum.AutomaticSize.Y
lbl.BackgroundTransparency = 1
lbl.TextColor3 = Color3.new(1, 1, 1)
lbl.TextWrapped = true
lbl.TextSize = 12
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.TextYAlignment = Enum.TextYAlignment.Top
lbl.Text = text

local close = Instance.new("TextButton", sg)
close.Size = UDim2.new(0, 44, 0, 30)
close.Position = UDim2.new(0.95, -44, 0.2, -34)
close.Text = "X"
close.MouseButton1Click:Connect(function() sg:Destroy() end)
