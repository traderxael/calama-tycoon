-- TycoonManager.server.luau
-- Server-authoritative single Heartbeat loop - Calama Tycoon
-- v3: Collector pad bonus, feedback completo

-- Guard: evitar doble-ejecucion si init.server hace require()
if _G.__TYCOON_MANAGER_RAN then return end
_G.__TYCOON_MANAGER_RAN = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TycoonConfig = require(ReplicatedStorage.Shared.TycoonConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataStoreUtils = require(ReplicatedStorage.Shared.DataStoreUtils)

local ECON = TycoonConfig.ECONOMY
local playerDS = DataStoreService:GetDataStore("CalamaTycoon_v1")
local COLECTOR_COOLDOWN = 15 -- segundos entre bonus

type PlayerState = {
    pesos: number,
    ley: number,
    owned: { [string]: boolean },
    currentPhase: number,
    totalIncome: number,
    incomeAccum: number,
    lastSave: number,
    lastCollect: number,
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
        lastCollect = 0,
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

local function fireSync(player, s)
    Remotes.GetRemoteEvent("SyncState"):FireClient(player, {
        pesos = s.pesos, ley = s.ley,
        owned = s.owned, phase = s.currentPhase,
        income = s.totalIncome,
    })
end

-- Heartbeat: auto-income
RunService.Heartbeat:Connect(function(dt)
    for _, player in Players:GetPlayers() do
        local s = states[player]
        if s and s.totalIncome > 0 then
            s.incomeAccum += dt * s.totalIncome
            if s.incomeAccum >= 1 then
                local earn = math.floor(s.incomeAccum)
                s.pesos += earn
                s.incomeAccum -= earn
                fireSync(player, s)
                if earn > 0 then
                    Remotes.GetRemoteEvent("IncomeNotify"):FireClient(player, earn)
                end
            end
        end
    end
end)

-- Execute purchase (shared: GUI buttons + ProximityPrompt)
local function executePurchase(player, item, pad)
    local s = states[player]
    if not s then
        Remotes.GetRemoteEvent("PurchaseResult"):FireClient(player, false, "Estado no disponible")
        return false
    end
    if s.owned[item.Id] then
        -- Already owned: check if collector -> trigger collect instead
        if item.Effect == "collector" then
            local now = os.clock()
            local remaining = COLECTOR_COOLDOWN - (now - s.lastCollect)
            if remaining > 0 then
                Remotes.GetRemoteEvent("PurchaseResult"):FireClient(player, false, "Cooldown: " .. tostring(math.ceil(remaining)) .. "s")
                return false
            end
            local bonus = math.max(s.totalIncome * 3, 10)
            s.pesos += bonus
            s.lastCollect = now
            fireSync(player, s)
            Remotes.GetRemoteEvent("IncomeNotify"):FireClient(player, bonus)
            Remotes.GetRemoteEvent("PurchaseResult"):FireClient(player, true, "+$" .. tostring(bonus) .. " BONUS COLECTOR!")
            return true
        end
        Remotes.GetRemoteEvent("PurchaseResult"):FireClient(player, false, "Ya tienes este item")
        return false
    end
    if item.Phase > s.currentPhase then
        Remotes.GetRemoteEvent("PurchaseResult"):FireClient(player, false, "Fase no disponible")
        return false
    end
    if item.PrereqId and not s.owned[item.PrereqId] then
        Remotes.GetRemoteEvent("PurchaseResult"):FireClient(player, false, "Compra el item anterior primero")
        return false
    end
    if s.pesos < item.CostPesos then
        Remotes.GetRemoteEvent("PurchaseResult"):FireClient(player, false, "Fondos insuficientes")
        return false
    end
    if s.ley < item.CostLey then
        Remotes.GetRemoteEvent("PurchaseResult"):FireClient(player, false, "No tienes suficiente Ley Alta")
        return false
    end

    -- Proximity check (if pad provided)
    if pad then
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root and (root.Position - pad.Position).Magnitude > ECON.MAX_PURCHASE_DISTANCE then
            Remotes.GetRemoteEvent("PurchaseResult"):FireClient(player, false, "Acercate al pad")
            return false
        end
    end

    -- Execute purchase
    s.pesos -= item.CostPesos
    s.ley -= item.CostLey
    s.owned[item.Id] = true
    if item.Effect == "unlock_phase" and item.Phase == s.currentPhase then
        s.currentPhase += 1
    end
    s.totalIncome = calcIncome(s)
    fireSync(player, s)
    Remotes.GetRemoteEvent("PurchaseResult"):FireClient(player, true, item.Name .. " comprado!")

    -- Update pad visual (green glow, OWNED label)
    task.spawn(function()
        local pads = workspace:FindFirstChild("TycoonPads")
        if not pads then return end
        local pad = pads:FindFirstChild(item.Id)
        if not pad then return end
        pad.BrickColor = BrickColor.new("Bright green")
        local glow = pads:FindFirstChild("Glow_" .. item.Id)
        if glow then
            glow.BrickColor = BrickColor.new("Bright green")
            glow.Transparency = 0.2
        end
        local bb = pad:FindFirstChildWhichIsA("BillboardGui")
        if bb then
            local children = bb:GetChildren()
            if #children >= 2 then
                children[2].Text = "ADQUIRIDO"
                children[2].TextColor3 = Color3.fromRGB(80, 255, 80)
            end
        end
    end)
    return true
end

-- Purchase handler (GUI buttons from Tienda panel)
Remotes.GetRemoteEvent("PurchaseItem").OnServerEvent:Connect(function(player, itemId)
    if type(itemId) ~= "string" then return end
    local item = TycoonConfig.GetShopItem(itemId)
    if not item then return end
    executePurchase(player, item, nil)
end)

-- Collector handler (legacy, desde Init.client, pero ya se maneja en executePurchase)
Remotes.GetRemoteEvent("CollectMoney").OnServerEvent:Connect(function(player)
    local s = states[player]
    if not s then return end
    fireSync(player, s)
end)

-- Player lifecycle
Players.PlayerAdded:Connect(function(player)
    local s = loadPlayer(player)
    task.wait(1)
    fireSync(player, s)
end)

-- ProximityPrompt wiring
task.spawn(function()
    task.wait(1.5)
    local pads = workspace:WaitForChild("TycoonPads", 10)
    if not pads then return end
    local function wirePad(pad)
        local prompt = pad:FindFirstChildWhichIsA("ProximityPrompt")
        if prompt then
            prompt.Triggered:Connect(function(plr)
                local item = TycoonConfig.GetShopItem(pad.Name)
                if not item then return end
                executePurchase(plr, item, pad)
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
