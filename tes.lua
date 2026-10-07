local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local folder = Workspace:FindFirstChild("AreaEggSlotsClient")

if not folder then
    warn("AreaEggSlotsClient tidak ditemukan")
    return
end

local out = {}

local function add(s)
    table.insert(out, s)
end

local function attrs(inst)
    local t = {}

    for k, v in pairs(inst:GetAttributes()) do
        table.insert(t, k .. "=" .. tostring(v))
    end

    return #t > 0 and table.concat(t, ", ") or "-"
end

add("===== EGG DATA CHECK =====")
add("")

for _, model in ipairs(folder:GetChildren()) do
    if model:IsA("Model") then

        local prepared = model:GetAttribute("PreparedSourceName")

        if prepared then
            add("================================")
            add("MODEL: " .. model.Name)
            add("SOURCE: " .. tostring(prepared))
            add("ATTR: " .. attrs(model))

            local ok, cf, size = pcall(function()
                return model:GetBoundingBox()
            end)

            if ok then
                add(string.format(
                    "BOUNDING SIZE: %.3f, %.3f, %.3f",
                    size.X,
                    size.Y,
                    size.Z
                ))
            end

            local hitbox = model:FindFirstChild("Hitbox", true)

            if hitbox and hitbox:IsA("BasePart") then
                add(string.format(
                    "HITBOX SIZE: %.3f, %.3f, %.3f",
                    hitbox.Size.X,
                    hitbox.Size.Y,
                    hitbox.Size.Z
                ))
            end

            for _, d in ipairs(model:GetDescendants()) do

                if d:IsA("MeshPart") then
                    add(
                        "MESH: " .. d.Name ..
                        " | MeshId=" .. tostring(d.MeshId) ..
                        " | TextureID=" .. tostring(d.TextureID) ..
                        " | Size=" .. tostring(d.Size)
                    )

                elseif d:IsA("BasePart") then
                    add(
                        "PART: " .. d.Name ..
                        " | Material=" .. tostring(d.Material) ..
                        " | Size=" .. tostring(d.Size)
                    )

                elseif d:IsA("ValueBase") then
                    add(
                        "VALUE: " .. d.Name ..
                        "=" .. tostring(d.Value)
                    )
                end

            end

            add("")
        end
    end
end

local text = table.concat(out, "\n")

pcall(function()
    if setclipboard then
        setclipboard(text)
    end
end)

local old = player.PlayerGui:FindFirstChild("EggDataCheck")
if old then
    old:Destroy()
end

local sg = Instance.new("ScreenGui")
sg.Name = "EggDataCheck"
sg.ResetOnSpawn = false
sg.Parent = player.PlayerGui

local sf = Instance.new("ScrollingFrame")
sf.Parent = sg
sf.Size = UDim2.new(0.94, 0, 0.78, 0)
sf.Position = UDim2.new(0.03, 0, 0.1, 0)
sf.BackgroundColor3 = Color3.new(0, 0, 0)
sf.BackgroundTransparency = 0.1
sf.ScrollBarThickness = 8
sf.AutomaticCanvasSize = Enum.AutomaticSize.Y

local lbl = Instance.new("TextLabel")
lbl.Parent = sf
lbl.Size = UDim2.new(1, -12, 0, 0)
lbl.AutomaticSize = Enum.AutomaticSize.Y
lbl.BackgroundTransparency = 1
lbl.TextColor3 = Color3.new(1, 1, 1)
lbl.Font = Enum.Font.Code
lbl.TextSize = 11
lbl.TextWrapped = false
lbl.TextXAlignment = Enum.TextXAlignment.Left
lbl.TextYAlignment = Enum.TextYAlignment.Top
lbl.Text = text

local close = Instance.new("TextButton")
close.Parent = sg
close.Size = UDim2.new(0, 50, 0, 32)
close.Position = UDim2.new(0.94, -50, 0.1, -38)
close.Text = "X"

close.MouseButton1Click:Connect(function()
    sg:Destroy()
end)
