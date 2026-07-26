-- init.client.luau
-- Calama Tycoon - Client con feedback visual de ingresos

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TycoonConfig = require(ReplicatedStorage.Shared.TycoonConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local player = Players.LocalPlayer
local state = { pesos = 0, ley = 0, owned = {}, phase = 1, income = 0 }

-- GUI
local playerGui = player:WaitForChild("PlayerGui")

local function makeLabel(yOff: number, text: string, color: Color3, size: number): TextLabel
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, size)
    lbl.Position = UDim2.new(0, 5, 0, yOff)
    lbl.Text = text
    lbl.TextColor3 = color
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = size - 2
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return lbl
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CalamaHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(0, 260, 0, 220)
bg.Position = UDim2.new(0, 10, 0, 10)
bg.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
bg.BackgroundTransparency = 0.25
bg.BorderSizePixel = 0
bg.Parent = screenGui

local title = makeLabel(4, "CALAMA TYCOON", Color3.fromRGB(255, 200, 50), 20)
title.Font = Enum.Font.GothamBold
title.Parent = bg

local pesosLbl = makeLabel(26, "$0", Color3.fromRGB(80, 255, 80), 22)
pesosLbl.Font = Enum.Font.GothamBold
pesosLbl.Parent = bg

local incomeLbl = makeLabel(46, "+$0/s", Color3.fromRGB(100, 200, 100), 14)
incomeLbl.Parent = bg

local leyLbl = makeLabel(62, "Cu: 0 CLH", Color3.fromRGB(255, 180, 50), 14)
leyLbl.Parent = bg

local phaseLbl = makeLabel(78, "Fase 1 - Faena Artesanal", Color3.fromRGB(180, 180, 255), 14)
phaseLbl.Parent = bg

-- Floating income text
local floatGui = Instance.new("ScreenGui")
floatGui.Name = "FloatingIncome"
floatGui.ResetOnSpawn = false
floatGui.Parent = playerGui

local function spawnFloatingText(amount: number)
    local f = Instance.new("TextLabel")
    f.Size = UDim2.new(0, 100, 0, 24)
    f.Position = UDim2.new(0, 30, 0, 60)
    f.Text = "+$" .. tostring(amount)
    f.TextColor3 = Color3.fromRGB(80, 255, 80)
    f.BackgroundTransparency = 1
    f.Font = Enum.Font.GothamBold
    f.TextSize = 20
    f.TextXAlignment = Enum.TextXAlignment.Left
    f.Parent = floatGui

    local t = 0
    local con
    con = RunService.Heartbeat:Connect(function(dt)
        t += dt
        f.Position += UDim2.new(0, 0, 0, -60 * dt)
        f.TextTransparency = t / 1.5
        if t >= 1.5 then
            con:Disconnect()
            f:Destroy()
        end
    end)
end

-- Build buttons dynamically
local btnRefs = {}
local yPos = 94

local function getPhaseName(phase: number): string
    if phase <= #TycoonConfig.PHASES then
        return "Fase " .. tostring(phase) .. " - " .. TycoonConfig.PHASES[phase].Name
    end
    return "Fase " .. tostring(phase)
end

local function rebuildButtons()
    for _, btn in btnRefs do
        btn:Destroy()
    end
    btnRefs = {}
    yPos = 94

    local available = TycoonConfig.GetNextPhaseItems(state.phase, state.owned)
    for _, item in available do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.9, 0, 0, 22)
        btn.Position = UDim2.new(0.05, 0, 0, yPos)
        local costStr = ""
        if item.CostPesos > 0 then costStr ..= " $" .. tostring(item.CostPesos) end
        if item.CostLey > 0 then costStr ..= " Cu" .. tostring(item.CostLey) end
        btn.Text = item.Name .. costStr
        if item.CostPesos == 0 and item.CostLey == 0 then
            btn.TextColor3 = Color3.fromRGB(80, 255, 80)
        else
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        btn.BackgroundColor3 = Color3.fromRGB(35, 40, 60)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 11
        btn.BorderSizePixel = 0
        btn.Parent = bg

        local itemId = item.Id
        btn.MouseButton1Click:Connect(function()
            Remotes.GetRemoteEvent("PurchaseItem"):FireServer(itemId)
        end)

        table.insert(btnRefs, btn)
        yPos += 24
    end
    bg.Size = UDim2.new(0, 260, 0, yPos + 6)
end

-- State sync
Remotes.GetRemoteEvent("SyncState").OnClientEvent:Connect(function(data)
    state.pesos = data.pesos
    state.ley = data.ley
    state.owned = data.owned
    state.phase = data.phase

    pesosLbl.Text = "$" .. tostring(math.floor(data.pesos))
    incomeLbl.Text = "+$" .. tostring(state.income) .. "/s"
    leyLbl.Text = "Cu: " .. tostring(math.floor(data.ley)) .. " CLH"
    phaseLbl.Text = getPhaseName(data.phase)

    rebuildButtons()
end)

-- Income notification (floating text)
Remotes.GetRemoteEvent("IncomeNotify").OnClientEvent:Connect(function(amount)
    state.income += 0 -- updated via sync; just show float
    spawnFloatingText(amount)
end)

-- Update income rate from owned items on sync
local origSync = Remotes.GetRemoteEvent("SyncState").OnClientEvent
-- (income is recalculated when buttons rebuild, but we show it from state)
