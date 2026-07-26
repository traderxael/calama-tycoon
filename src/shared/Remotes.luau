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
    "UpgradeStage",
    "PurchaseStage",
    "DispatchExport",
    "BuyRebirth",
    "SyncState",
    "NotifyMoney",
    "NotifyStock",
    "NotifyStageUnlock",
    "NotifyRebirth",
    "NotifyLME",
    "CoopBonusUpdate",
}

local Remotes = {}

for _, name in REMOTE_NAMES do
    local remoteName = name :: string
    Remotes[remoteName] = nil
end

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
