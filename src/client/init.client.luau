-- init.client.luau
-- Client handler for Calama Tycoon

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TycoonConfig = require(ReplicatedStorage.Shared.TycoonConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local player = Players.LocalPlayer
local state = {
    money = 0,
    stock = 0,
    stages = 1,
    levels = {},
    rebirths = 0,
    lmePrice = TycoonConfig.ECONOMY.BASE_LME_PRICE,
}

-- Receive initial state
Remotes.GetRemoteEvent("SyncState").OnClientEvent:Connect(function(data)
    state.money = data.money
    state.stock = data.stock
    state.stages = data.stages
    state.levels = data.levels
    state.rebirths = data.rebirths
    state.lmePrice = data.lmePrice
end)

-- UI update handlers
Remotes.GetRemoteEvent("NotifyMoney").OnClientEvent:Connect(function(amount)
    state.money = amount
end)

Remotes.GetRemoteEvent("NotifyStock").OnClientEvent:Connect(function(amount)
    state.stock = amount
end)

Remotes.GetRemoteEvent("NotifyStageUnlock").OnClientEvent:Connect(function(stageIndex)
    state.stages = stageIndex
    state.levels[stageIndex] = 1
end)

Remotes.GetRemoteEvent("NotifyRebirth").OnClientEvent:Connect(function(rebirths)
    state.rebirths = rebirths
    state.stages = 1
    state.money = TycoonConfig.ECONOMY.STARTING_MONEY
    state.stock = 0
    state.levels = { [1] = 1 }
end)

Remotes.GetRemoteEvent("NotifyLME").OnClientEvent:Connect(function(price)
    state.lmePrice = price
end)

-- Actions
function SendUpgrade(stageIndex: number)
    Remotes.GetRemoteEvent("UpgradeStage"):FireServer(stageIndex)
end

function SendPurchase()
    Remotes.GetRemoteEvent("PurchaseStage"):FireServer()
end

function SendDispatch()
    Remotes.GetRemoteEvent("DispatchExport"):FireServer()
end

function SendRebirth()
    Remotes.GetRemoteEvent("BuyRebirth"):FireServer()
end
