local RS = game:GetService("ReplicatedStorage")

local paths = {
    "Shared.Util.EggRecords",
    "Shared.Util.EggScaling",
    "Shared.Util.AreaEggSlotIdentity",
    "Data.Rarity",
    "Shared.Types.Eggs",
    "Shared.Types.AreaEggs",
}

print("===== EGG DATA MODULE CHECK =====")

for _, path in ipairs(paths) do
    local obj = RS
    for part in string.gmatch(path, "[^%.]+") do
        obj = obj and obj:FindFirstChild(part)
    end

    print("\n[" .. path .. "]")

    if not obj then
        print("NOT FOUND")
        continue
    end

    print("Class:", obj.ClassName)

    local ok, result = pcall(require, obj)

    if not ok then
        print("REQUIRE ERROR:", result)
    elseif type(result) == "table" then
        local count = 0

        for k, v in pairs(result) do
            count += 1
            print("  ", tostring(k), "=", tostring(v))

            if count >= 40 then
                print("  ... truncated")
                break
            end
        end

        print("KEY COUNT:", count)
    else
        print("RETURN:", tostring(result))
    end
end
