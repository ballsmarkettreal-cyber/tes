local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local hrp = player.Character:WaitForChild("HumanoidRootPart")

local lines = {}
for _, v in ipairs(Workspace:GetDescendants()) do
    if v:IsA("ProximityPrompt") then
        local p = v.Parent
        local part = p:IsA("BasePart") and p or p:FindFirstChildWhichIsA("BasePart", true)
        if part and (part.Position - hrp.Position).Magnitude < 25 then
            table.insert(lines, v:GetFullName() .. " | " .. v.ActionText)
        end
    end
end

local text = #lines > 0 and table.concat(lines, "\n") or "Tidak ada ProximityPrompt dalam radius 25 stud"

pcall(function() if setclipboard then setclipboard(text) end end)

local old = player.PlayerGui:FindFirstChild("PathCheck")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "PathCheck"
sg.ResetOnSpawn = false
sg.Parent = player.PlayerGui

local box = Instance.new("TextLabel", sg)
box.Size = UDim2.new(0.9, 0, 0.5, 0)
box.Position = UDim2.new(0.05, 0, 0.25, 0)
box.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
box.BackgroundTransparency = 0.2
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.TextWrapped = true
box.TextSize = 14
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.Text = text

local close = Instance.new("TextButton", box)
close.Size = UDim2.new(0, 40, 0, 30)
close.Position = UDim2.new(1, -44, 0, 4)
close.Text = "X"
close.MouseButton1Click:Connect(function() sg:Destroy() end)
