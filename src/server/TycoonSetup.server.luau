-- TycoonSetup.server.luau
-- Genera zona de spawn + pads de compra ordenados
-- Busca modelos del usuario en Workspace\Models
-- Corre UNA VEZ, se autodestruye

local TycoonConfig = require(script.Parent.Parent.Shared.TycoonConfig)

-- Spawn
local spawnLoc = workspace:FindFirstChild("SpawnLocation")
if not spawnLoc then
    spawnLoc = Instance.new("SpawnLocation")
    spawnLoc.Name = "SpawnLocation"
    spawnLoc.Position = Vector3.new(0, 5, 0)
    spawnLoc.Parent = workspace
end

-- Pads folder
local padsFolder = Instance.new("Folder")
padsFolder.Name = "TycoonPads"
padsFolder.Parent = workspace

-- Buscar modelos del usuario
local modelsFolder = workspace:FindFirstChild("Models")

-- Terreno base plano cerca del spawn
local T = workspace.Terrain
local function fillFlat(cx, cz, w, h)
    T:FillRegion(
        Region3.new(Vector3.new(cx-w, -2, cz-w), Vector3.new(cx+w, 0.5, cz+w)),
        4, Enum.Material.Sand
    )
end
fillFlat(0, 0, 30, 30)

-- Pads en fila ordenada cerca del spawn
local items = TycoonConfig.GetItemsByPhase(1)
local columns = 3
local spacing = 12
local startX = -(math.min(#items, columns) - 1) * spacing / 2
local zPos = 15

for i, item in items do
    local col = (i - 1) % columns
    local row = math.floor((i - 1) / columns)
    local pos = Vector3.new(startX + col * spacing, 1, zPos + row * spacing)

    -- Try to find matching user model
    local model
    if modelsFolder then
        model = modelsFolder:FindFirstChild(item.Id)
            or modelsFolder:FindFirstChild(item.Name)
    end

    -- Pad base (plataforma de piedra)
    local pad = Instance.new("Part")
    pad.Name = item.Id
    pad.Anchored = true
    pad.CanCollide = true
    pad.Size = Vector3.new(10, 1, 10)
    pad.Position = pos
    pad.BrickColor = BrickColor.new("Dark stone grey")
    pad.Material = Enum.Material.Slate
    pad.TopSurface = Enum.SurfaceType.Smooth
    pad.BottomSurface = Enum.SurfaceType.Smooth
    pad.Parent = padsFolder

    -- User model si existe
    if model then
        local clone = model:Clone()
        clone.Parent = pad
        clone:PivotTo(CFrame.new(pos.X, pos.Y + 1.5, pos.Z))
    end

    -- ClickDetector (radio generoso)
    local cd = Instance.new("ClickDetector")
    cd.MaxActivationDistance = 24
    cd.Parent = pad

    -- Billboard
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 220, 0, 70)
    bb.StudsOffset = Vector3.new(0, 6, 0)
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
    costLbl.TextColor3 = Color3.fromRGB(255, 200, 50)
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

-- Zona de grava alrededor de los pads (marcando el area de construccion)
T:FillRegion(
    Region3.new(Vector3.new(-25, -3, 0), Vector3.new(25, 0.25, 40)),
    4, Enum.Material.Gravel
)

print("=== TycoonPads generados cerca del spawn ===")
script:Destroy()
