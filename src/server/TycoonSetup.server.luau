-- TycoonSetup.server.luau
-- Genera zona de spawn + pads de compra ordenados
-- Corre UNA VEZ, se autodestruye

-- Guard: evitar doble-ejecucion
if _G.__TYCOON_SETUP_RAN then return end
_G.__TYCOON_SETUP_RAN = true

local TycoonConfig = require(game:GetService("ReplicatedStorage").Shared.TycoonConfig)

-- ── PLATAFORMA SOLIDA (evita caerse del mundo) ──
local platform = Instance.new("Part")
platform.Name = "SpawnPlatform"
platform.Anchored = true
platform.CanCollide = true
platform.Size = Vector3.new(60, 3, 50)
platform.Position = Vector3.new(0, 0.5, 12)
platform.BrickColor = BrickColor.new("Dark stone grey")
platform.Material = Enum.Material.Slate
platform.TopSurface = Enum.SurfaceType.Smooth
platform.BottomSurface = Enum.SurfaceType.Smooth
platform.Parent = workspace

-- Terreno compacto bajo la plataforma y pads
local T = workspace.Terrain
local function fillFlat(cx, cz, w, h)
    T:FillRegion(
        Region3.new(Vector3.new(cx-w, -4, cz-w), Vector3.new(cx+w, 0.5, cz+w)),
        4, Enum.Material.Sand
    )
end
fillFlat(0, 12, 40, 40)

-- ── SPAWN ──
local spawnLoc = workspace:FindFirstChild("SpawnLocation")
if not spawnLoc then
    spawnLoc = Instance.new("SpawnLocation")
    spawnLoc.Name = "SpawnLocation"
end
spawnLoc.Position = Vector3.new(0, 3.5, 2)
spawnLoc.Parent = workspace

-- ── PADS FOLDER ──
local padsFolder = Instance.new("Folder")
padsFolder.Name = "TycoonPads"
padsFolder.Parent = workspace

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

    -- Construir modelo visual sobre el pad
    local function buildPadModel(padPos: Vector3, itemId: string): Model?
        local m = Instance.new("Model")
        m.Name = itemId .. "_Model"
        local p = function(off, sz, col: BrickColor, mat: Enum.Material?)
            local part = Instance.new("Part")
            part.Anchored = true
            part.CanCollide = false
            part.Size = sz or Vector3.new(1,1,1)
            part.Position = padPos + off
            part.BrickColor = col or BrickColor.new("Medium stone grey")
            if mat then part.Material = mat end
            part.TopSurface = Enum.SurfaceType.Smooth
            part.BottomSurface = Enum.SurfaceType.Smooth
            part.Parent = m
            return part
        end
        local function w(off: Vector3, sz: Vector3, col: BrickColor): Part
            return p(off, sz, col, Enum.Material.Wood)
        end
        local function s(off: Vector3, sz: Vector3, col: BrickColor): Part
            return p(off, sz, col, Enum.Material.Slate)
        end
        if itemId == "terreno" then
            -- Bandera de reclamo: poste + banderin
            p(Vector3.new(0,1.5,0), Vector3.new(0.3,3,0.3), BrickColor.new("Bright yellow"))
            p(Vector3.new(1.5,2.5,0), Vector3.new(2,1.2,0.05), BrickColor.new("Bright green"), Enum.Material.Fabric)
            p(Vector3.new(0,4,0), Vector3.new(0.5,0.5,0.5), BrickColor.new("Bright yellow"))
        elseif itemId == "chancador" then
            -- Chancador: base de piedra + tolva + embudo
            s(Vector3.new(0,0.5,0), Vector3.new(5,1,5), BrickColor.new("Dark stone grey"))
            s(Vector3.new(0,1.5,0), Vector3.new(3,1,3), BrickColor.new("Medium stone grey"))
            p(Vector3.new(0,2.5,0), Vector3.new(2.5,0.5,2.5), BrickColor.new("Black"), Enum.Material.Metal)
            p(Vector3.new(0,1.5,0), Vector3.new(0.8,2,0.8), BrickColor.new("Really black"), Enum.Material.Metal)
            p(Vector3.new(0.8,1.2,0.8), Vector3.new(0.3,0.3,0.3), BrickColor.new("Bright orange"))
            p(Vector3.new(-0.8,1.2,-0.8), Vector3.new(0.3,0.3,0.3), BrickColor.new("Bright orange"))
            p(Vector3.new(0.8,1.2,-0.8), Vector3.new(0.3,0.3,0.3), BrickColor.new("Bright orange"))
            p(Vector3.new(-0.8,1.2,0.8), Vector3.new(0.3,0.3,0.3), BrickColor.new("Bright orange"))
        elseif itemId == "cinta" then
            -- Cinta transportadora: banda + rodillos
            s(Vector3.new(0,0.3,0), Vector3.new(2,0.2,2), BrickColor.new("Dark stone grey"))
            w(Vector3.new(0,0.8,0), Vector3.new(6,0.2,1.5), BrickColor.new("Brown"))
            for r = -2.5, 2.5, 1.2 do
                s(Vector3.new(r,0.8,0), Vector3.new(0.2,0.6,1.8), BrickColor.new("Dark stone grey"))
                p(Vector3.new(r,0.3,1.1), Vector3.new(0.3,0.2,0.3), BrickColor.new("Black"))
                p(Vector3.new(r,0.3,-1.1), Vector3.new(0.3,0.2,0.3), BrickColor.new("Black"))
            end
            -- Mineral sobre la cinta
            for r = -1.5, 1.5, 0.9 do
                p(Vector3.new(r,1.1,0), Vector3.new(0.5,0.3,0.5), BrickColor.new("Bright orange"))
            end
        elseif itemId == "colector" then
            -- Colector: contenedor grande + mineral dentro
            s(Vector3.new(0,0.5,0), Vector3.new(5,1,5), BrickColor.new("Dark stone grey"))
            s(Vector3.new(0,1.8,0), Vector3.new(4,1.5,4), BrickColor.new("Bright yellow"), Enum.Material.Metal)
            p(Vector3.new(0,2.8,0), Vector3.new(4.2,0.3,4.2), BrickColor.new("Bright yellow"), Enum.Material.Metal)
            -- Cobre dentro
            for _ = 1, 5 do
                local lx = (math.random() - 0.5) * 2.5
                local lz = (math.random() - 0.5) * 2.5
                p(Vector3.new(lx, 1.3, lz), Vector3.new(0.4,0.2,0.4), BrickColor.new("Bright orange"))
            end
        elseif itemId == "minero" then
            -- Minero: figura simple + casco
            local body = s(Vector3.new(0,0.5,0), Vector3.new(3,1,3), BrickColor.new("Dark stone grey"))
            -- Cuerpo
            p(Vector3.new(0.6,1.8,-0.3), Vector3.new(0.8,1.2,0.6), BrickColor.new("Bright yellow"), Enum.Material.Fabric)
            -- Piernas
            p(Vector3.new(0.4,0.8,-0.3), Vector3.new(0.4,0.8,0.4), BrickColor.new("Dark stone grey"), Enum.Material.Fabric)
            p(Vector3.new(0.8,0.8,-0.3), Vector3.new(0.4,0.8,0.4), BrickColor.new("Dark stone grey"), Enum.Material.Fabric)
            -- Cabeza
            p(Vector3.new(0.6,2.8,-0.3), Vector3.new(0.6,0.6,0.6), BrickColor.new("Bright yellow"))
            -- Casco
            p(Vector3.new(0.6,3.2,-0.3), Vector3.new(0.7,0.2,0.7), BrickColor.new("Bright orange"))
            -- Brazos
            p(Vector3.new(1.2,1.8,-0.3), Vector3.new(0.2,0.8,0.2), BrickColor.new("Bright yellow"), Enum.Material.Fabric)
            -- Pico
            p(Vector3.new(2,1.2,-0.3), Vector3.new(1.5,0.2,0.1), BrickColor.new("Dark stone grey"), Enum.Material.Metal)
        elseif itemId == "camioneta" then
            -- Camioneta 4x4: cabina + caja + ruedas
            local body = s(Vector3.new(0,0.3,0), Vector3.new(2.5,0.2,2), BrickColor.new("Dark stone grey"))
            -- Cabina
            p(Vector3.new(-1,0.9,0), Vector3.new(1.5,1,1.5), BrickColor.new("Bright red"), Enum.Material.Metal)
            -- Techo
            p(Vector3.new(-0.8,1.5,0), Vector3.new(0.8,0.1,1), BrickColor.new("Bright red"), Enum.Material.Metal)
            -- Caja de carga
            p(Vector3.new(1.2,0.8,0), Vector3.new(1.8,0.8,1.6), BrickColor.new("Bright red"), Enum.Material.Metal)
            -- Ruedas
            p(Vector3.new(-1.2,0.2,1.3), Vector3.new(0.3,0.4,0.3), BrickColor.new("Black"))
            p(Vector3.new(-1.2,0.2,-1.3), Vector3.new(0.3,0.4,0.3), BrickColor.new("Black"))
            p(Vector3.new(1.2,0.2,1.3), Vector3.new(0.3,0.4,0.3), BrickColor.new("Black"))
            p(Vector3.new(1.2,0.2,-1.3), Vector3.new(0.3,0.4,0.3), BrickColor.new("Black"))
            -- Mineral en la caja
            for _ = 1, 3 do
                local lx = 1.2 + (math.random() - 0.5) * 1
                local lz = (math.random() - 0.5) * 1
                p(Vector3.new(lx, 1.3, lz), Vector3.new(0.3,0.2,0.3), BrickColor.new("Bright orange"))
            end
        end
        m.Parent = padsFolder
        return m
    end
    buildPadModel(pos, item.Id)

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
workspace.Terrain:FillRegion(
    Region3.new(Vector3.new(-30, -4, -10), Vector3.new(30, 0, 35)),
    4, Enum.Material.Gravel
)

print("=== TycoonPads generados ===")
script:Destroy()
