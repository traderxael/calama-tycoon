-- DataStoreUtils.luau
-- Save/Load con pcall + retry

local DataStoreService = game:GetService("DataStoreService")

local DataStoreUtils = {}

function DataStoreUtils.Save(ds: DataStore, key: string, value: any): boolean
    for _ = 1, 3 do
        local ok, err = pcall(function()
            ds:SetAsync(key, value)
        end)
        if ok then
            return true
        end
        task.wait(1)
    end
    return false
end

function DataStoreUtils.Load(ds: DataStore, key: string, default: any): any
    for _ = 1, 3 do
        local ok, data = pcall(function()
            return ds:GetAsync(key)
        end)
        if ok and data ~= nil then
            return data
        end
        task.wait(1)
    end
    return default
end

return DataStoreUtils
