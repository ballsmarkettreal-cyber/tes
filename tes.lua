local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

local out = {}

local function add(x)
    table.insert(out, tostring(x))
end

local function dumpObject(obj, indent)
    indent = indent or ""

    add(indent .. obj:GetFullName() .. " [" .. obj.ClassName .. "]")

    -- Attributes
    for k, v in pairs(obj:GetAttributes()) do
        add(indent .. "  ATTR: " .. k .. " = " .. tostring(v))
    end

    -- ValueBase
    if obj:IsA("ValueBase") then
        add(indent .. "  VALUE: " .. obj.Name .. " = " .. tostring(obj.Value))
    end

    -- Prompt
    if obj:IsA("ProximityPrompt") then
        add(indent .. "  ACTION: " .. obj.ActionText)
        add(indent .. "  OBJECT: " .. obj.ObjectText)
        add(indent .. "  HOLD: " .. tostring(obj.HoldDuration))
        add(indent .. "  DIST: " .. tostring(obj.MaxActivationDistance))
    end
end

add("===== CARRY AREA EGG INSPECTOR =====")
add("")

local found = 0

for _, prompt in ipairs(Workspace:GetDescendants()) do
    if prompt:IsA("ProximityPrompt")
        and prompt.Name == "CarryAreaEgg" then

        local part = prompt.Parent

        if part and part:IsA("BasePart") then
            local distance = (part.Position - hrp.Position).Magnitude

            if distance <= 40 then
                found += 1

                add("===== PROMPT #" .. found .. " =====")
                add("DISTANCE: " .. string.format("%.2f", distance))
                add("")

                -- Naik beberapa parent dari prompt
                local current = prompt

                for level = 0, 6 do
                    if not current then break end

                    add("----- LEVEL " .. level .. " -----")
                    dumpObject(current, "")

                    current = current.Parent
                end

                add("")
                add("----- CHILDREN OF PROMPT PARENT -----")

                for _, child in ipairs(part.Parent:GetChildren()) do
                    dumpObject(child, "  ")
                end

                add("")
            end
        end
    end
end

add("===== TOTAL PROMPT: " .. found .. " =====")

local result = table.concat(out, "\n")

pcall(function()
    if setclipboard then
        setclipboard(result)
    end
end)

print(result)

local old = player.PlayerGui:FindFirstChild("CarryEggInspector")
if old then
    old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "CarryEggInspector"
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
