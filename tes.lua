local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local out = {}

local function add(x)
    table.insert(out, tostring(x))
end

local function dump(folderName)
    local folder = Workspace:FindFirstChild(folderName)

    if not folder then
        add("[" .. folderName .. "] TIDAK DITEMUKAN")
        return
    end

    add("===== " .. folderName .. " =====")
    add("Class: " .. folder.ClassName)
    add("Children: " .. #folder:GetChildren())
    add("")

    local count = 0

    for _, obj in ipairs(folder:GetChildren()) do
        count += 1

        add("#" .. count .. " " .. obj.Name .. " [" .. obj.ClassName .. "]")

        for k, v in pairs(obj:GetAttributes()) do
            add("  ATTR " .. k .. " = " .. tostring(v))
        end

        if obj:IsA("ValueBase") then
            add("  VALUE = " .. tostring(obj.Value))
        end

        -- hanya child langsung yang punya nama menarik
        for _, child in ipairs(obj:GetChildren()) do
            local n = string.lower(child.Name)

            if n:find("egg")
                or n:find("rarity")
                or n:find("variant")
                or n:find("size")
                or n:find("scale")
                or n:find("weight")
                or n:find("type")
                or n:find("mutation") then

                add("  CHILD " .. child.Name .. " [" .. child.ClassName .. "]")

                for k, v in pairs(child:GetAttributes()) do
                    add("    ATTR " .. k .. " = " .. tostring(v))
                end

                if child:IsA("ValueBase") then
                    add("    VALUE = " .. tostring(child.Value))
                end
            end
        end

        add("")
    end
end

add("===== EGG SOURCE CHECK =====")
add("")

dump("Eggs")
add("")
dump("AreaEggSlotsClient")

local result = table.concat(out, "\n")

pcall(function()
    if setclipboard then
        setclipboard(result)
    end
end)

print(result)

local old = player.PlayerGui:FindFirstChild("EggSourceCheck")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "EggSourceCheck"
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

local frame = Instance.new("ScrollingFrame")
frame.Parent = gui
frame.Size = UDim2.new(.94,0,.8,0)
frame.Position = UDim2.new(.03,0,.08,0)
frame.BackgroundColor3 = Color3.new(0,0,0)
frame.BackgroundTransparency = .1
frame.ScrollBarThickness = 7
frame.AutomaticCanvasSize = Enum.AutomaticSize.Y

local label = Instance.new("TextLabel")
label.Parent = frame
label.Size = UDim2.new(1,-10,0,0)
label.AutomaticSize = Enum.AutomaticSize.Y
label.BackgroundTransparency = 1
label.TextColor3 = Color3.new(1,1,1)
label.Font = Enum.Font.Code
label.TextSize = 11
label.TextWrapped = true
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.Text = result

local close = Instance.new("TextButton")
close.Parent = gui
close.Size = UDim2.new(0,45,0,30)
close.Position = UDim2.new(.95,-45,.08,-35)
close.Text = "X"

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)
