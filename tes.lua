local Workspace = game:GetService("Workspace")
local out = {}

local function add(s)
    table.insert(out, tostring(s))
end

add("===== SEARCH EGG LOGIC =====")
add("")

local targets = {
    "PreparedSourceName",
    "AreaEggSlotsClient",
    "CarryAreaEgg",
    "Rarity",
    "Variant",
    "Size",
    "Egg"
}

for _, obj in ipairs(game:GetDescendants()) do
    if obj:IsA("ModuleScript") or obj:IsA("LocalScript") or obj:IsA("Script") then
        local n = string.lower(obj.Name)

        for _, target in ipairs(targets) do
            if n:find(string.lower(target), 1, true) then
                add(obj:GetFullName() .. " [" .. obj.ClassName .. "]")
                break
            end
        end
    end
end

add("")
add("===== MODULE/SCRIPT NAMES NEAR EGG =====")

for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("ModuleScript") or obj:IsA("LocalScript") or obj:IsA("Script") then
        local n = string.lower(obj.Name)
        if n:find("egg") or n:find("animal") or n:find("pet") 
        or n:find("steal") or n:find("slot") then
            add(obj:GetFullName() .. " [" .. obj.ClassName .. "]")
        end
    end
end

local result = table.concat(out, "\n")
pcall(function()
    if setclipboard then setclipboard(result) end
end)

print(result)
