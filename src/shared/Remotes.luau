-- Remotes.luau
-- Lazy get-or-create RemoteEvents

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

local REMOTE_NAMES = {
    "PurchaseItem",
    "CollectMoney",
    "SyncState",
    "IncomeNotify",
}

local Remotes = {}

function Remotes.GetRemoteEvent(name: string): RemoteEvent
    local remote = remotesFolder:FindFirstChild(name)
    if not remote then
        if RunService:IsServer() then
            remote = Instance.new("RemoteEvent")
            remote.Name = name
            remote.Parent = remotesFolder
        else
            remote = remotesFolder:WaitForChild(name, 5)
        end
    end
    return remote :: RemoteEvent
end

return Remotes
