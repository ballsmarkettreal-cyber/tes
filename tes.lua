local Players = game:GetService("Players")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

for _, v in ipairs(pg:GetChildren()) do
    if v.Name:match("EX_Test") then v:Destroy() end
end

local sg = Instance.new("ScreenGui")
sg.Name = "EX_Test_UI"
sg.ResetOnSpawn = false
sg.Parent = pg

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 400, 0, 200)
frame.Position = UDim2.new(0.5, -200, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(30, 10, 50)
frame.BorderSizePixel = 0
frame.Parent = sg

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Text = "TEST AMAN ✓"
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Parent = frame
