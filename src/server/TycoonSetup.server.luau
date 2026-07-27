-- TycoonSetup.server.luau
-- Genera zona de spawn + pads de compra ordenados
-- Usa ProximityPrompt + plataforma solida bajo los pies
-- Busca modelos del usuario en Workspace\Models
-- Corre UNA VEZ, se autodestruye

local TycoonConfig = require(script.Parent.Parent.Shared.TycoonConfig)

-- ── PLATAFORMA SOLIDA (evita caerse del mundo) ──
local platform = Instance.new("Part")
platform.Name = "SpawnPlatform"
platform.Anchored = true
platform.CanCollide = true
platform.Size = Vector3.new(60, 1, 50)
platform.Position = Vector3.new(0, -0.5, 12)
platform.BrickColor = BrickColor.new("Dark stone grey")
platform.Material = Enum.Material.Slate
platform.TopSurface = Enum.SurfaceType.Smooth
platform.BottomSurface = Enum.SurfaceType.Smooth
platform.Parent = workspace

-- ── SPAWN ──
local spawnLoc = workspace:FindFirstChild("SpawnLocation")
if not spawnLoc then
    spawnLoc = Instance.new("SpawnLocation")
    spawnLoc.Name = "SpawnLocation"
    spawnLoc.Position = Vector3.new(0, 3.5, 2)
    spawnLoc.Parent = workspace
end

-- ── PADS FOLDER ──
local padsFolder = Instance.new("Folder")
padsFolder.Name = "TycoonPads"
padsFolder.Parent = workspace

-- Buscar modelos del usuario
local modelsFolder = workspace:FindFirstChild("Models")

-- ── Terreno ──
local T = workspace.Terrain
local function fillFlat(cx, cz, w, h)
    T:FillRegion(
        Region3.new(Vector3.new(cx-w, -4, cz-w), Vector3.new(cx+w, 0, cz+w)),
        4, Enum.Material.Sand
    )
end
fillFlat(0, 12, 40, 40)

-- ── PADS en fila ordenada ──
local items = TycoonConfig.GetItemsByPhase(1)
local columns = 3
local spacing = 12
local startX = -(math.min(#items, columns) - 1) * spacing / 2
local zPos = 12

for i, item in items do
    local col = (i - 1) % columns
    local row = math.floor((i - 1) / columns)
    local pos = Vector3.new(startX + col * spacing, 0.5, zPos + row * spacing)

    -- Modelo del usuario si existe
    local model
    if modelsFolder then
        model = modelsFolder:FindFirstChild(item.Id)
            or modelsFolder:FindFirstChild(item.Name)
    end

    -- Pad base
    local pad = Instance.new("Part")
    pad.Name = item.Id
    pad.Anchored = true
    pad.CanCollide = true
    pad.Size = Vector3.new(10, 0.5, 10)
    pad.Position = pos
    pad.BrickColor = BrickColor.new("Dark stone grey")
    pad.Material = Enum.Material.Slate
    pad.TopSurface = Enum.SurfaceType.Smooth
    pad.BottomSurface = Enum.SurfaceType.Smooth
    pad.Parent = padsFolder

    -- User model
    if model then
        local clone = model:Clone()
        clone.Parent = pad
        clone:PivotTo(CFrame.new(pos.X, pos.Y + 1.2, pos.Z))
    end

    -- ProximityPrompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.MaxActivationDistance = 16
    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = false
    prompt.ClickablePrompt = true
    prompt.Parent = pad

    -- Color del glow segun tipo
    local glowColor
    if item.CostPesos == 0 and item.CostLey == 0 then
        glowColor = BrickColor.new("Bright green")
    elseif item.Effect == "collector" then
        glowColor = BrickColor.new("Bright yellow")
    else
        glowColor = BrickColor.new("Bright blue")
    end

    -- Anillo de glow
    local glow = Instance.new("Part")
    glow.Name = "Glow_" .. item.Id
    glow.Anchored = true
    glow.CanCollide = false
    glow.Size = Vector3.new(11, 0.2, 11)
    glow.Position = Vector3.new(pos.X, 0.05, pos.Z)
    glow.BrickColor = glowColor
    glow.Material = Enum.Material.Neon
    glow.Transparency = 0.5
    glow.Parent = padsFolder

    -- Billboard
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 220, 0, 70)
    bb.StudsOffset = Vector3.new(0, 5.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = pad

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, 0, 0, 24)
    nameLbl.Text = item.Name
    nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 16
    nameLbl.Parent = bb

    local costLbl = Instance.new("TextLabel")
    costLbl.Size = UDim2.new(1, 0, 0, 18)
    costLbl.Position = UDim2.new(0, 0, 0, 24)
    if item.CostPesos == 0 and item.CostLey == 0 then
        costLbl.TextColor3 = Color3.fromRGB(80, 255, 80)
    else
        costLbl.TextColor3 = Color3.fromRGB(255, 200, 50)
    end
    costLbl.BackgroundTransparency = 1
    costLbl.Font = Enum.Font.Gotham
    costLbl.TextSize = 14
    local costStr = ""
    if item.CostPesos > 0 then costStr ..= "$" .. tostring(item.CostPesos) end
    if item.CostLey > 0 then
        if costStr ~= "" then costStr ..= " + " end
        costStr ..= tostring(item.CostLey) .. " CLH"
    end
    if costStr == "" then costStr = "GRATIS" end
    costLbl.Text = costStr
    costLbl.Parent = bb

    local descLbl = Instance.new("TextLabel")
    descLbl.Size = UDim2.new(1, 0, 0, 16)
    descLbl.Position = UDim2.new(0, 0, 0, 44)
    descLbl.Text = item.Description
    descLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    descLbl.BackgroundTransparency = 1
    descLbl.Font = Enum.Font.Gotham
    descLbl.TextSize = 11
    descLbl.Parent = bb

    print("Pad " .. item.Id .. " en " .. tostring(pos))
end

-- ── Grava decorativa alrededor ──
T:FillRegion(
    Region3.new(Vector3.new(-30, -4, -10), Vector3.new(30, 0, 35)),
    4, Enum.Material.Gravel
)

print("=== TycoonPads generados ===")
script:Destroy()
