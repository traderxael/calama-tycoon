-- init.client.luau
-- Calama Tycoon - UI completa con barra superior, dock y paneles

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TycoonConfig = require(ReplicatedStorage.Shared.TycoonConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local state = { pesos = 0, ley = 0, owned = {}, phase = 1, income = 0 }
local openPanel = nil -- nil | "shop" | "machines" | "map" | "stats" | "missions"

-- ── Screen size helper ──
local isMobile = false

-- ── Utility ──
local function abbr(n: number, sym: string?): string
    sym = sym or "$"
    if n >= 1e9 then return sym .. string.format("%.1fB", n/1e9) end
    if n >= 1e6 then return sym .. string.format("%.1fM", n/1e6) end
    if n >= 1e3 then return sym .. string.format("%.1fK", n/1e3) end
    return sym .. tostring(math.floor(n))
end

-- ── Create main GUI ──
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CalamaHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.Parent = playerGui

local function makeLbl(parent, txt, color, size, bold, align)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, 0, 0, size)
    l.Text = txt
    l.TextColor3 = color or Color3.new(1,1,1)
    l.BackgroundTransparency = 1
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize = size - 2
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function makeBtn(parent, txt, color, w, h, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, h)
    b.Text = txt
    b.BackgroundColor3 = color or Color3.fromRGB(35, 40, 60)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.Gotham
    b.TextSize = 12
    b.BorderSizePixel = 0
    b.Parent = parent
    if cb then b.MouseButton1Click:Connect(cb) end
    return b
end

-- ── TOP BAR ──
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.Position = UDim2.new(0, 0, 0, 0)
topBar.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
topBar.BackgroundTransparency = 0.15
topBar.BorderSizePixel = 0
topBar.Parent = screenGui

local function makeIndicator(tb, txt, color, x)
    local l = makeLbl(tb, txt, color, 16, true, Enum.TextXAlignment.Center)
    l.Position = UDim2.new(0, x, 0, 10)
    l.Size = UDim2.new(0, 120, 0, 20)
    return l
end

local pesosInd = makeIndicator(topBar, "$0", Color3.fromRGB(80, 255, 80), 8)
local incomeInd = makeIndicator(topBar, "+$0/s", Color3.fromRGB(100, 200, 100), 130)
local leyInd = makeIndicator(topBar, "Cu 0", Color3.fromRGB(255, 180, 50), 250)
local energyInd = makeIndicator(topBar, "E 100%", Color3.fromRGB(60, 180, 255), 360)
local phaseInd = makeIndicator(topBar, "F1", Color3.fromRGB(255, 200, 50), 460)
local menuBtn = makeBtn(topBar, "=", Color3.fromRGB(40, 40, 60), 36, 30)
menuBtn.Position = UDim2.new(1, -44, 0, 5)
menuBtn.TextSize = 18
menuBtn.Visible = false -- hidden for now

-- ── Progress bar under top bar ──
local progBar = Instance.new("Frame")
progBar.Size = UDim2.new(1, 0, 0, 3)
progBar.Position = UDim2.new(0, 0, 0, 40)
progBar.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
progBar.BorderSizePixel = 0
progBar.Parent = screenGui

local progFill = Instance.new("Frame")
progFill.Size = UDim2.new(0, 0, 1, 0)
progFill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
progFill.BorderSizePixel = 0
progFill.Parent = progBar

local progLbl = makeLbl(progBar, "", Color3.fromRGB(180, 180, 200), 11, false, Enum.TextXAlignment.Center)
progLbl.Size = UDim2.new(1, 0, 1, 0)
progLbl.TextSize = 9

-- ── BOTTOM DOCK ──
local dock = Instance.new("Frame")
dock.Size = UDim2.new(1, 0, 0, 56)
dock.Position = UDim2.new(0, 0, 1, -56)
dock.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
dock.BackgroundTransparency = 0.1
dock.BorderSizePixel = 0
dock.Parent = screenGui

local dockButtons = {}
local dockDefs = {
    { id = "shop",     label = "Tienda",    icon = "B" },
    { id = "machines", label = "Maquinas",  icon = "M" },
    { id = "map",      label = "Mapa",      icon = "P" },
    { id = "stats",    label = "Stats",     icon = "S" },
    { id = "missions", label = "Misiones",  icon = "T" },
}
local btnW = 64
local totalW = #dockDefs * btnW
local startX = (1 - totalW/1000) * 0.5  -- approximate center

for i, def in dockDefs do
    local b = Instance.new("TextButton")
    local bx = 0.5 - (totalW/2000) + (i-1)*(btnW/1000) + (btnW/2000)
    b.Size = UDim2.new(0, btnW, 0, 46)
    b.Position = UDim2.new(bx, 0, 0, 5)
    b.Text = def.label
    b.BackgroundColor3 = Color3.fromRGB(30, 35, 55)
    b.TextColor3 = Color3.fromRGB(200, 200, 210)
    b.Font = Enum.Font.Gotham
    b.TextSize = 9
    b.BorderSizePixel = 0
    b.Parent = dock

    local ico = makeLbl(b, def.icon, Color3.fromRGB(200, 200, 210), 18, true, Enum.TextXAlignment.Center)
    ico.Size = UDim2.new(1, 0, 0, 22)
    ico.Position = UDim2.new(0, 0, 0, 2)
    ico.TextSize = 16

    b.MouseButton1Click:Connect(function()
        if openPanel == def.id then
            closePanel()
        else
            openPanelView(def.id)
        end
    end)
    dockButtons[def.id] = b
end

-- ── PANEL SYSTEM ──
local panelFrame = Instance.new("Frame")
panelFrame.Size = UDim2.new(0, 340, 0, 380)
panelFrame.Position = UDim2.new(0.5, -170, 0.5, -190)
panelFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
panelFrame.BorderSizePixel = 0
panelFrame.BackgroundTransparency = 1
panelFrame.Visible = false
panelFrame.Parent = screenGui

-- Dim background
local dim = Instance.new("Frame")
dim.Size = UDim2.new(1, 0, 1, 0)
dim.BackgroundColor3 = Color3.new(0,0,0)
dim.BackgroundTransparency = 1
dim.BorderSizePixel = 0
dim.Parent = panelFrame

local panelTitle = makeLbl(panelFrame, "", Color3.fromRGB(255, 200, 50), 20, true)
panelTitle.Position = UDim2.new(0, 12, 0, 8)
panelTitle.Size = UDim2.new(1, -24, 0, 24)

local function closePanel()
    openPanel = nil
    panelFrame.Visible = false
    dim.BackgroundTransparency = 1
    panelFrame.BackgroundTransparency = 1
end

local panelClose = makeBtn(panelFrame, "X", Color3.fromRGB(60, 30, 30), 24, 24)
panelClose.Position = UDim2.new(1, -32, 0, 8)
panelClose.TextColor3 = Color3.fromRGB(200, 80, 80)
panelClose.MouseButton1Click:Connect(closePanel)

-- Container for panel content
local panelContent = Instance.new("Frame")
panelContent.Size = UDim2.new(1, -20, 1, -50)
panelContent.Position = UDim2.new(0, 10, 0, 40)
panelContent.BackgroundTransparency = 1
panelContent.BorderSizePixel = 0
panelContent.Parent = panelFrame
panelContent.ClipsDescendants = true

-- UIListLayout for content
local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 4)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = panelContent

-- ── PANEL BUILDERS ──
local function clearContent()
    for _, c in panelContent:GetChildren() do
        if c:IsA("GuiObject") then c:Destroy() end
    end
end

local function buildShopPanel()
    clearContent()
    panelTitle.Text = "Tienda - Fase " .. tostring(state.phase)
    local available = TycoonConfig.GetNextPhaseItems(state.phase, state.owned)

    -- Phase unlock progress
    local nextPhase = state.phase < #TycoonConfig.PHASES and TycoonConfig.PHASES[state.phase + 1]
    if nextPhase then
        local hdr = makeLbl(panelContent, "--- " .. nextPhase.Name .. " ($" .. tostring(nextPhase.UnlockCost) .. ") ---", Color3.fromRGB(140, 140, 160), 13, false, Enum.TextXAlignment.Center)
        hdr.Size = UDim2.new(1, 0, 0, 18)
    end

    for _, item in available do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 44)
        row.BackgroundColor3 = Color3.fromRGB(25, 28, 42)
        row.BorderSizePixel = 0
        row.Parent = panelContent

        local iLbl = makeLbl(row, item.Name, Color3.new(0.9, 0.9, 0.9), 14, true)
        iLbl.Size = UDim2.new(0.65, -60, 0, 18)
        iLbl.Position = UDim2.new(0, 8, 0, 4)

        local dLbl = makeLbl(row, item.Description, Color3.fromRGB(160, 160, 180), 11)
        dLbl.Size = UDim2.new(0.65, -60, 0, 14)
        dLbl.Position = UDim2.new(0, 8, 0, 22)
        dLbl.TextSize = 10

        local canBuy = state.pesos >= item.CostPesos and state.ley >= item.CostLey
        local costTxt = ""
        if item.CostPesos > 0 then costTxt ..= "$" .. tostring(item.CostPesos) end
        if item.CostLey > 0 then
            if costTxt ~= "" then costTxt ..= " " end
            costTxt ..= tostring(item.CostLey) .. " Cu"
        end
        if costTxt == "" then costTxt = "GRATIS" end

        local buyBtn = makeBtn(row, costTxt,
            canBuy and Color3.fromRGB(40, 100, 50) or Color3.fromRGB(60, 40, 40),
            110, 28)
        buyBtn.Position = UDim2.new(1, -118, 0, 8)
        buyBtn.TextColor3 = canBuy and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(160, 100, 100)
        buyBtn.TextSize = 11
        if not canBuy and item.CostPesos > state.pesos then
            buyBtn.Text = "FALTA $" .. tostring(item.CostPesos - state.pesos)
        elseif not canBuy and item.CostLey > state.ley then
            buyBtn.Text = "FALTA Cu" .. tostring(item.CostLey - state.ley)
        end

        local itemId = item.Id
        buyBtn.MouseButton1Click:Connect(function()
            Remotes.GetRemoteEvent("PurchaseItem"):FireServer(itemId)
        end)
    end

    if #available == 0 then
        local empty = makeLbl(panelContent, "Todo comprado en esta fase!", Color3.fromRGB(100, 200, 100), 14, false, Enum.TextXAlignment.Center)
        empty.Size = UDim2.new(1, 0, 0, 40)
    end
end

local function buildMachinesPanel()
    clearContent()
    panelTitle.Text = "Maquinas"

    local count = 0
    for _, item in TycoonConfig.SHOP do
        if state.owned[item.Id] and item.Income > 0 then
            count += 1
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 34)
            row.BackgroundColor3 = Color3.fromRGB(25, 28, 42)
            row.BorderSizePixel = 0
            row.Parent = panelContent

            local dot = Color3.fromRGB(80, 255, 80)
            local dotLbl = makeLbl(row, ">", dot, 14, true)
            dotLbl.Size = UDim2.new(0, 20, 0, 20)
            dotLbl.Position = UDim2.new(0, 6, 0, 6)
            dotLbl.TextSize = 14

            local nLbl = makeLbl(row, item.Name, Color3.new(0.9, 0.9, 0.9), 14, true)
            nLbl.Size = UDim2.new(0.5, 0, 0, 20)
            nLbl.Position = UDim2.new(0, 28, 0, 6)

            local incLbl = makeLbl(row, "+$" .. tostring(item.Income) .. "/s", Color3.fromRGB(80, 200, 80), 13)
            incLbl.Size = UDim2.new(0, 80, 0, 20)
            incLbl.Position = UDim2.new(0.55, 0, 0, 6)
            incLbl.TextSize = 12
            incLbl.TextXAlignment = Enum.TextXAlignment.Right

            -- (boton de venta no disponible)
        end
    end
    if count == 0 then
        local empty = makeLbl(panelContent, "Compra maquinas en la tienda", Color3.fromRGB(140, 140, 160), 14, false, Enum.TextXAlignment.Center)
        empty.Size = UDim2.new(1, 0, 0, 40)
    end
    -- Total
    local totalLbl = makeLbl(panelContent, "Total: +$" .. tostring(state.income) .. "/s", Color3.fromRGB(255, 200, 50), 16, true)
    totalLbl.Size = UDim2.new(1, -12, 0, 20)
    totalLbl.Position = UDim2.new(0, 6, 0, count * 38 + 6)
    totalLbl.TextXAlignment = Enum.TextXAlignment.Left
end

local function buildStatsPanel()
    clearContent()
    panelTitle.Text = "Estadisticas"
    local items = {
        { "Fase actual", "Fase " .. tostring(state.phase) .. " - " .. (TycoonConfig.PHASES[state.phase] and TycoonConfig.PHASES[state.phase].Name or "?") },
        { "Ingreso / seg", "$" .. tostring(state.income) .. "/s" },
        { "Maquinas operando", tostring(countMachines()) .. " activas" },
        { "Proxima fase", (state.phase < #TycoonConfig.PHASES) and TycoonConfig.PHASES[state.phase + 1].Name or "Ultima fase" },
    }
    for _, pair in items do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundTransparency = 1
        row.Parent = panelContent
        local a = makeLbl(row, pair[1], Color3.fromRGB(160, 160, 180), 13)
        a.Size = UDim2.new(0.5, 0, 0, 20)
        a.Position = UDim2.new(0, 8, 0, 4)
        local b = makeLbl(row, pair[2], Color3.new(0.9, 0.9, 0.9), 13, true)
        b.Size = UDim2.new(0.5, 0, 0, 20)
        b.Position = UDim2.new(0.5, 0, 0, 4)
        b.TextXAlignment = Enum.TextXAlignment.Right
    end
end

local function buildMissionsPanel()
    clearContent()
    panelTitle.Text = "Misiones"
    local goals = {
        { "Reclamar Terreno",    "terreno" },
        { "Comprar Chancador",   "chancador" },
        { "Comprar Cinta",       "cinta" },
        { "Comprar Colector",    "colector" },
        { "Contratar Minero",    "minero" },
        { "Comprar Camioneta",   "camioneta" },
        { "Desbloquear Rajo",    "rajo_unlock" },
    }
    for _, g in goals do
        local done = state.owned[g[2]] == true
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 26)
        row.BackgroundColor3 = done and Color3.fromRGB(20, 40, 20) or Color3.fromRGB(25, 25, 35)
        row.BorderSizePixel = 0
        row.Parent = panelContent
        local txt = (done and "[X] " or "[ ] ") .. g[1]
        local c = done and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(180, 180, 200)
        local l = makeLbl(row, txt, c, 13)
        l.Size = UDim2.new(1, -10, 1, 0)
        l.Position = UDim2.new(0, 6, 0, 0)
        l.TextSize = 12
    end
end

local function buildMapPanel()
    clearContent()
    panelTitle.Text = "Zonas"
    for i, phase in TycoonConfig.PHASES do
        local unlocked = i <= state.phase
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 36)
        row.BackgroundColor3 = unlocked and Color3.fromRGB(20, 35, 25) or Color3.fromRGB(30, 25, 25)
        row.BorderSizePixel = 0
        row.Parent = panelContent
        local ico = unlocked and "O" or "X"
        local ic = unlocked and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(160, 80, 80)
        local il = makeLbl(row, ico, ic, 18, true, Enum.TextXAlignment.Center)
        il.Size = UDim2.new(0, 28, 1, 0)
        il.Position = UDim2.new(0, 6, 0, 0)
        local nl = makeLbl(row, phase.Name, unlocked and Color3.new(0.9,0.9,0.9) or Color3.fromRGB(120,120,130), 14)
        nl.Size = UDim2.new(1, -44, 1, 0)
        nl.Position = UDim2.new(0, 34, 0, 0)
        if not unlocked then
            local cl = makeLbl(row, "$" .. tostring(phase.UnlockCost), Color3.fromRGB(255,200,50), 12)
            cl.Size = UDim2.new(0, 80, 1, 0)
            cl.Position = UDim2.new(1, -86, 0, 0)
            cl.TextXAlignment = Enum.TextXAlignment.Right
        end
    end
end

local function countMachines()
    local c = 0
    for _, item in TycoonConfig.SHOP do
        if state.owned[item.Id] and item.Income > 0 then c += 1 end
    end
    return c
end

local panelBuilders = {
    shop = buildShopPanel,
    machines = buildMachinesPanel,
    map = buildMapPanel,
    stats = buildStatsPanel,
    missions = buildMissionsPanel,
}

function openPanelView(id)
    openPanel = id
    panelFrame.Visible = true
    dim.BackgroundTransparency = 0.4
    panelFrame.BackgroundTransparency = 0
    if panelBuilders[id] then panelBuilders[id]() end
end

-- ── Floating income text ──
local floatGui = Instance.new("ScreenGui")
floatGui.Name = "FloatingIncome"
floatGui.ResetOnSpawn = false
floatGui.Parent = playerGui

local function spawnFloatingText(amount: number)
    if typeof(amount) ~= "number" then return end
    local f = Instance.new("TextLabel")
    f.Size = UDim2.new(0, 120, 0, 24)
    f.Position = UDim2.new(0, 14, 0, 50)
    f.Text = "+$" .. tostring(amount)
    f.TextColor3 = Color3.fromRGB(80, 255, 80)
    f.BackgroundTransparency = 1
    f.Font = Enum.Font.GothamBold
    f.TextSize = 18
    f.TextXAlignment = Enum.TextXAlignment.Left
    f.Parent = floatGui
    local t = 0
    local con
    con = RunService.Heartbeat:Connect(function(dt)
        t += dt
        f.Position += UDim2.new(0, 0, 0, -50 * dt)
        f.TextTransparency = t / 1.5
        if t >= 1.5 then
            con:Disconnect()
            f:Destroy()
        end
    end)
end

-- ── Toast notification ──
local toastGui = Instance.new("ScreenGui")
toastGui.Name = "Toasts"
toastGui.ResetOnSpawn = false
toastGui.Parent = playerGui

local activeToasts = {}
function spawnToast(text, color)
    if #activeToasts >= 3 then
        local old = table.remove(activeToasts, 1)
        old:Destroy()
    end
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(0, 240, 0, 30)
    t.Position = UDim2.new(1, -260, 0, 50 + (#activeToasts * 34))
    t.Text = text
    t.TextColor3 = color or Color3.new(1,1,1)
    t.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    t.BackgroundTransparency = 0.2
    t.Font = Enum.Font.Gotham
    t.TextSize = 13
    t.BorderSizePixel = 0
    t.Parent = toastGui
    table.insert(activeToasts, t)
    task.delay(3, function()
        t:Destroy()
        for i, v in activeToasts do
            if v == t then table.remove(activeToasts, i); break end
        end
    end)
end

-- ── Sync from server ──
Remotes.GetRemoteEvent("SyncState").OnClientEvent:Connect(function(data)
    state.pesos = data.pesos
    state.ley = data.ley
    state.owned = data.owned
    state.phase = data.phase
    state.income = data.income or 0

    pesosInd.Text = "$" .. tostring(math.floor(state.pesos))
    incomeInd.Text = "+$" .. tostring(state.income) .. "/s"
    leyInd.Text = "Cu " .. tostring(math.floor(state.ley))

    -- Phase progress
    local nextPhase = state.phase < #TycoonConfig.PHASES and TycoonConfig.PHASES[state.phase + 1]
    if nextPhase then
        local pct = math.min(state.pesos / nextPhase.UnlockCost, 1)
        progFill.Size = UDim2.new(pct, 0, 1, 0)
        progLbl.Text = "F" .. tostring(state.phase) .. " -> " .. nextPhase.Name .. " ($" .. tostring(nextPhase.UnlockCost) .. ")"
    else
        progFill.Size = UDim2.new(1, 0, 1, 0)
        progLbl.Text = "F" .. tostring(state.phase) .. " - Maximo"
    end

    phaseInd.Text = "F" .. tostring(state.phase)

    -- Rebuild open panel
    if openPanel and panelBuilders[openPanel] then
        panelBuilders[openPanel]()
    end
end)

-- Income float
Remotes.GetRemoteEvent("IncomeNotify").OnClientEvent:Connect(function(amount)
    spawnFloatingText(amount)
end)

-- ── Purchase confirmation toast ──
Remotes.GetRemoteEvent("PurchaseResult").OnClientEvent:Connect(function(success, msg)
    if success then
        spawnToast(msg or "Item comprado!", Color3.fromRGB(80, 255, 80))
    else
        spawnToast(msg or "No puedes comprar esto", Color3.fromRGB(255, 100, 100))
    end
end)
