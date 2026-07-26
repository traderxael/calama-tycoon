-- TycoonManager.server.luau
-- Server-authoritative single Heartbeat loop

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local TycoonConfig = require(script.Parent.Parent.Shared.TycoonConfig)
local Remotes = require(script.Parent.Parent.Shared.Remotes)
local DataStoreUtils = require(script.Parent.Parent.Shared.DataStoreUtils)

local ECON = TycoonConfig.ECONOMY
local playerDS = DataStoreService:GetDataStore("PlayerData_V2")
local lmePrice = ECON.BASE_LME_PRICE

type PlayerState = {
    money: number,
    stock: number,
    stages: number,
    levels: { [number]: number },
    accumulators: { [number]: number },
    rebirths: number,
    lastDispatch: number,
    lastSave: number,
}

local states: { [Player]: PlayerState } = {}

-- LME random walk
task.spawn(function()
    while true do
        task.wait(ECON.PRICE_UPDATE_INTERVAL)
        local delta = (math.random() - 0.5) * 0.3
        lmePrice = math.clamp(lmePrice + delta, ECON.MIN_PRICE, ECON.MAX_PRICE)
        for _, player in Players:GetPlayers() do
            if states[player] then
                Remotes.GetRemoteEvent("NotifyLME"):FireClient(player, lmePrice)
            end
        end
    end
end)

function rebirthMultiplier(s: PlayerState): number
    return 1.0 + s.rebirths * ECON.REBIRTH_BONUS_PER_LEVEL
end

function coopMultiplier(player: Player): number
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return 1.0 end
    local bonus = 0.0
    local count = 0
    for _, other in Players:GetPlayers() do
        if other ~= player then
            local otherRoot = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
            if otherRoot then
                local dist = (root.Position - otherRoot.Position).Magnitude
                if dist <= ECON.COOP_RADIUS then
                    bonus += ECON.COOP_BONUS
                    count += 1
                end
            end
        end
    end
    if count > 0 then
        return math.min(1.0 + bonus, 1.0 + ECON.COOP_MAX_BONUS)
    end
    return 1.0
end

function setMoney(player: Player, s: PlayerState, delta: number)
    s.money = math.max(0, s.money + delta)
    Remotes.GetRemoteEvent("NotifyMoney"):FireClient(player, s.money)
end

function setStock(player: Player, s: PlayerState, delta: number)
    s.stock = math.max(0, s.stock + delta)
    Remotes.GetRemoteEvent("NotifyStock"):FireClient(player, s.stock)
end

function savePlayer(player: Player)
    local s = states[player]
    if not s then return end
    DataStoreUtils.Save(playerDS, tostring(player.UserId), {
        money = s.money,
        stock = s.stock,
        stages = s.stages,
        levels = s.levels,
        rebirths = s.rebirths,
    })
end

function loadPlayer(player: Player): PlayerState
    local data = DataStoreUtils.Load(playerDS, tostring(player.UserId), nil)
    local s: PlayerState = {
        money = ECON.STARTING_MONEY,
        stock = 0,
        stages = 1,
        levels = {},
        accumulators = {},
        rebirths = 0,
        lastDispatch = 0,
        lastSave = 0,
    }
    if data then
        s.money = data.money or ECON.STARTING_MONEY
        s.stock = data.stock or 0
        s.stages = data.stages or 1
        s.levels = data.levels or {}
        s.rebirths = data.rebirths or 0
    end
    for i = 1, s.stages do
        s.levels[i] = s.levels[i] or 1
        s.accumulators[i] = 0
    end
    states[player] = s
    return s
end

-- Heartbeat: single loop
RunService.Heartbeat:Connect(function(dt)
    for _, player in Players:GetPlayers() do
        local s = states[player]
        if s then
            for i = 1, s.stages do
                local stage = TycoonConfig.GetStage(i)
                if stage then
                    s.accumulators[i] += dt
                    if s.accumulators[i] >= stage.ProcessingTime then
                        s.accumulators[i] -= stage.ProcessingTime
                        if stage.IsExport then
                            setStock(player, s, 1)
                        else
                            local mult = (lmePrice / ECON.BASE_LME_PRICE)
                                       * rebirthMultiplier(s)
                                       * coopMultiplier(player)
                            setMoney(player, s, math.floor(stage.BaseIncome * (s.levels[i] or 1) * mult))
                        end
                    end
                end
            end
        end
    end
end)

-- Remote handlers
Remotes.GetRemoteEvent("UpgradeStage").OnServerEvent:Connect(function(player, stageIndex)
    local s = states[player]
    if not s or type(stageIndex) ~= "number" then return end
    if stageIndex < 1 or stageIndex > s.stages then return end
    local stage = TycoonConfig.GetStage(stageIndex)
    if not stage then return end
    local cost = TycoonConfig.GetUpgradeCost(stage, s.levels[stageIndex] or 1)
    if s.money < cost then return end
    setMoney(player, s, -cost)
    s.levels[stageIndex] = (s.levels[stageIndex] or 1) + 1
end)

Remotes.GetRemoteEvent("PurchaseStage").OnServerEvent:Connect(function(player)
    local s = states[player]
    if not s then return end
    local nextStage = TycoonConfig.GetStage(s.stages + 1)
    if not nextStage then return end
    if s.money < nextStage.Cost then return end
    -- Validate proximity
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then
        local pad = workspace:FindFirstChild("PurchasePad")
        if pad and pad:IsA("BasePart") then
            if (root.Position - pad.Position).Magnitude > ECON.MAX_PURCHASE_DISTANCE then
                return
            end
        end
    end
    setMoney(player, s, -nextStage.Cost)
    s.stages += 1
    s.levels[s.stages] = 1
    s.accumulators[s.stages] = 0
    Remotes.GetRemoteEvent("NotifyStageUnlock"):FireClient(player, s.stages)
end)

Remotes.GetRemoteEvent("DispatchExport").OnServerEvent:Connect(function(player)
    local s = states[player]
    if not s or s.stock <= 0 then return end
    if os.clock() - s.lastDispatch < ECON.DISPATCH_COOLDOWN then return end
    s.lastDispatch = os.clock()
    local total = math.floor(s.stock * ECON.EXPORT_UNIT_VALUE * (lmePrice / ECON.BASE_LME_PRICE) * rebirthMultiplier(s))
    setMoney(player, s, total)
    setStock(player, s, -s.stock)
end)

Remotes.GetRemoteEvent("BuyRebirth").OnServerEvent:Connect(function(player)
    local s = states[player]
    if not s then return end
    if s.stages < ECON.REBIRTH_MIN_STAGES then return end
    if s.money < ECON.REBIRTH_MIN_MONEY then return end
    s.rebirths += 1
    s.stages = 1
    s.money = ECON.STARTING_MONEY
    s.stock = 0
    s.levels = { [1] = 1 }
    s.accumulators = {}
    s.lastDispatch = 0
    Remotes.GetRemoteEvent("NotifyRebirth"):FireClient(player, s.rebirths)
end)

-- Player lifecycle
Players.PlayerAdded:Connect(function(player)
    local s = loadPlayer(player)
    task.wait(2)
    Remotes.GetRemoteEvent("SyncState"):FireClient(player, {
        money = s.money,
        stock = s.stock,
        stages = s.stages,
        levels = s.levels,
        rebirths = s.rebirths,
        lmePrice = lmePrice,
    })
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
