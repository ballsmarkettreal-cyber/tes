local player = game:GetService("Players").LocalPlayer
local pg = player:WaitForChild("PlayerGui")

for _, v in ipairs(pg:GetChildren()) do
    if v.Name:match("EX_Tes") then v:Destroy() end
end

local sg = Instance.new("ScreenGui")
sg.Name = "EX_Tes_A"
sg.ResetOnSpawn = false
sg.Parent = pg
print("ScreenGui kosong dibuat, tunggu 10 detik...")
task.wait(10)
print("SELESAI - ScreenGui kosong aman")
