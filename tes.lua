local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local hrp = player.Character:WaitForChild("HumanoidRootPart")

local out = {}
local function add(s) table.insert(out, s) end

local function attrs(inst)
    local t = {}
    for k, v in pairs(inst:GetAttributes()) do
        table.insert(t, k .. "=" .. tostring(v))
    end
    return #t > 0 and table.concat(t, ", ") or "-"
end

local seen = {}
for _, v in ipairs(Workspace:GetDescendants()) do
    if v:IsA("ProximityPrompt") and v.Name == "CarryAreaEgg" then
        local part = v.Parent
        if part and part:IsA("BasePart") and (part.Position - hrp.Position).Magnitude < 40 then
            add("== " .. v:GetFullName())
            add("part attr: " .. attrs(part))
            add("prompt attr: " .. attrs(v))

            -- naik ke atas: cari model/folder pembungkus + attributes-nya
            local p = part.Parent
            local depth = 0
            while p and p ~= Workspace and depth < 4 do
                add("parent[" .. depth .. "]: " .. p.Name .. " (" .. p.ClassName .. ") attr: " .. attrs(p))
                p = p.Parent
                depth += 1
            end

            -- anak-anak di sekitar part: Value object dan teks label
            local root = part.Parent ~= Workspace and part.Parent or part
            for _, d in ipairs(root:GetDescendants()) do
                if d:IsA("ValueBase") then
                    add("  value " .. d.Name .. " = " .. tostring(d.Value))
                elseif d:IsA("TextLabel") and d.Text ~= "" then
                    add("  text " .. d:GetFullName():sub(-40) .. " = " .. d.Text)
                end
            end
            add("")
        end
    end
end

local text = #out > 0 and table.concat(out, "\n") or "Tidak ada CarryAreaEgg dalam radius 40 stud"
pcall(function() if setclipboard then setclipboard(text) end end)

local old = player.PlayerGui:FindFirstChild("EggInspect")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "EggInspect"
sg.ResetOnSpawn = false
sg.Parent = player.PlayerGui

local sf = Instance.new("ScrollingFrame", sg)
sf.Size = UDim2.new(0.9, 0, 0.6, 0)
sf.Position = UDim2.new(0.05, 0, 0.2, 0)
sf.BackgroundColor3 = Color3.new(0, 0, 0)
sf.BackgroundTransparency = 0.15
sf.CanvasSize = UDim2.new(0, 0, 0, 0)
sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
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
