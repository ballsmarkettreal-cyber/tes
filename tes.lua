local player = game:GetService("Players").LocalPlayer
local pg = player:WaitForChild("PlayerGui")

for _, v in ipairs(pg:GetChildren()) do
    if v.Name:match("EX_Tes") then v:Destroy() end
end

local sg = Instance.new("ScreenGui")
sg.Name = "EX_Tes_B"
sg.ResetOnSpawn = false
sg.Parent = pg

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 100, 0, 50)
frame.Position = UDim2.new(0.5, -50, 0.5, -25)
frame.BackgroundColor3 = Color3.fromRGB(50, 20, 80)
frame.Parent = sg
print("Frame dibuat, tunggu 10 detik...")
task.wait(10)
print("SELESAI - ScreenGui + 1 Frame aman")
