-- TycoonManager.server.luau
-- Server-authoritative single Heartbeat loop - Calama Tycoon

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local TycoonConfig = require(script.Parent.Parent.Shared.TycoonConfig)
local Remotes = require(script.Parent.Parent.Shared.Remotes)
local DataStoreUtils = require(script.Parent.Parent.Shared.DataStoreUtils)

local ECON = TycoonConfig.ECONOMY
local playerDS = DataStoreService:GetDataStore("CalamaTycoon_v1")

type PlayerState = {
    pesos: number,
    ley: number,
    owned: { [string]: boolean },
    currentPhase: number,
    totalIncome: number,
    incomeAccum: number,
    lastSave: number,
}

local states: { [Player]: PlayerState } = {}

function calcIncome(s: PlayerState): number
    local total = 0
    for _, item in TycoonConfig.SHOP do
        if s.owned[item.Id] then
            total += item.Income
        end
    end
    return total
end

function savePlayer(player: Player)
    local s = states[player]
    if not s then return end
    DataStoreUtils.Save(playerDS, tostring(player.UserId), {
        pesos = s.pesos,
        ley = s.ley,
        owned = s.owned,
        phase = s.currentPhase,
    })
end

function loadPlayer(player: Player): PlayerState
    local data = DataStoreUtils.Load(playerDS, tostring(player.UserId), nil)
    local s: PlayerState = {
        pesos = ECON.STARTING_PESOS,
        ley = ECON.STARTING_LEY,
        owned = {},
        currentPhase = 1,
        totalIncome = 0,
        incomeAccum = 0,
        lastSave = 0,
    }
    if data then
        s.pesos = data.pesos or 0
        s.ley = data.ley or 0
        s.owned = data.owned or {}
        s.currentPhase = data.phase or 1
    end
    s.totalIncome = calcIncome(s)
    states[player] = s
    return s
end

-- Heartbeat: single loop
RunService.Heartbeat:Connect(function(dt)
    for _, player in Players:GetPlayers() do
        local s = states[player]
        if s and s.totalIncome > 0 then
            s.incomeAccum += dt * s.totalIncome
            if s.incomeAccum >= 1 then
                local earn = math.floor(s.incomeAccum)
                s.pesos += earn
                s.incomeAccum -= earn
                Remotes.GetRemoteEvent("SyncState"):FireClient(player, {
                    pesos = s.pesos, ley = s.ley,
                    owned = s.owned, phase = s.currentPhase,
                    income = s.totalIncome,
                })
                if earn > 0 then
                    Remotes.GetRemoteEvent("IncomeNotify"):FireClient(player, earn)
                end
            end
        end
    end
end)

-- Purchase handler
Remotes.GetRemoteEvent("PurchaseItem").OnServerEvent:Connect(function(player, itemId)
    local s = states[player]
    if not s or type(itemId) ~= "string" then return end
    local item = TycoonConfig.GetShopItem(itemId)
    if not item then return end
    if s.owned[item.Id] then return end
    if item.Phase > s.currentPhase then return end

    -- Check prereq
    if item.PrereqId and not s.owned[item.PrereqId] then return end

    -- Check pesos
    if s.pesos < item.CostPesos then return end
    if s.ley < item.CostLey then return end

    -- Validate proximity: find nearest owned pad
    if item.CostPesos > 0 or item.CostLey > 0 then
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local pads = workspace:FindFirstChild("TycoonPads")
            if pads then
                local near = false
                for _, pad in pads:GetChildren() do
                    if pad:IsA("BasePart") and s.owned[pad.Name] then
                        if (root.Position - pad.Position).Magnitude <= ECON.MAX_PURCHASE_DISTANCE then
                            near = true
                            break
                        end
                    end
                end
                if not near then return end
            end
        end
    end

    -- Purchase
    s.pesos -= item.CostPesos
    s.ley -= item.CostLey
    s.owned[item.Id] = true

    -- Handle unlock_phase items
    if item.Effect == "unlock_phase" and item.Phase == s.currentPhase then
        s.currentPhase += 1
    end

    s.totalIncome = calcIncome(s)

    Remotes.GetRemoteEvent("SyncState"):FireClient(player, {
        pesos = s.pesos, ley = s.ley,
        owned = s.owned, phase = s.currentPhase,
        income = s.totalIncome,
    })
end)

-- Collector handler (pisar el colector cobra acumulado)
Remotes.GetRemoteEvent("CollectMoney").OnServerEvent:Connect(function(player)
    local s = states[player]
    if not s then return end
    -- Already auto-collected via heartbeat; this is a visual confirmation
    Remotes.GetRemoteEvent("SyncState"):FireClient(player, {
        pesos = s.pesos, ley = s.ley,
        owned = s.owned, phase = s.currentPhase,
        income = s.totalIncome,
    })
end)

-- Player lifecycle
Players.PlayerAdded:Connect(function(player)
    local s = loadPlayer(player)
    task.wait(1)
    Remotes.GetRemoteEvent("SyncState"):FireClient(player, {
        pesos = s.pesos, ley = s.ley,
        owned = s.owned, phase = s.currentPhase,
        income = s.totalIncome,
    })
end)

-- ClickDetector wiring for pads (after pads are created)
local function handlePadClick(plr, pad)
    local s = states[plr]
    if not s then return end
    local itemId = pad.Name
    local item = TycoonConfig.GetShopItem(itemId)
    if not item then return end
    if s.owned[item.Id] then return end
    if item.Phase > s.currentPhase then return end
    if item.PrereqId and not s.owned[item.PrereqId] then return end
    if s.pesos < item.CostPesos then return end
    if s.ley < item.CostLey then return end

    -- Proximity check
    local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if root then
        if (root.Position - pad.Position).Magnitude > ECON.MAX_PURCHASE_DISTANCE then
            return
        end
    end

    s.pesos -= item.CostPesos
    s.ley -= item.CostLey
    s.owned[item.Id] = true
    if item.Effect == "unlock_phase" and item.Phase == s.currentPhase then
        s.currentPhase += 1
    end
    s.totalIncome = calcIncome(s)

    Remotes.GetRemoteEvent("SyncState"):FireClient(plr, {
        pesos = s.pesos, ley = s.ley,
        owned = s.owned, phase = s.currentPhase,
        income = s.totalIncome,
    })
end

task.spawn(function()
    task.wait(1)
    local pads = workspace:WaitForChild("TycoonPads", 10)
    if not pads then return end
    local function wirePad(pad)
        local cd = pad:FindFirstChildWhichIsA("ClickDetector")
        if cd then
            cd.MouseClick:Connect(function(plr)
                handlePadClick(plr, pad)
            end)
        end
    end
    pads.ChildAdded:Connect(wirePad)
    for _, pad in pads:GetChildren() do
        wirePad(pad)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    savePlayer(player)
    states[player] = nil
end)

game:BindToClose(function()
    for _, player in Players:GetPlayers() do
        savePlayer(player)
    end
end)

-- Autosave
task.spawn(function()
    while true do
        task.wait(120)
        for _, player in Players:GetPlayers() do
            savePlayer(player)
        end
    end
end)
