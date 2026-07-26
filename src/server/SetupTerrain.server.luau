-- SetupTerrain.server.luau
-- Run ONCE in Studio command bar para generar desierto de Atacama
-- Pegar en la barra de comandos y presionar Enter

local T = workspace.Terrain
T:Clear()

-- Desierto plano de arena
local region = Region3.new(
    Vector3.new(-1024, -10, -1024),
    Vector3.new(1024, 40, 1024)
)
T:FillRegion(region, 4, Enum.Material.Sand)

-- Capa base de roca debajo
local rockRegion = Region3.new(
    Vector3.new(-1024, -50, -1024),
    Vector3.new(1024, -10, 1024)
)
T:FillRegion(rockRegion, 4, Enum.Material.Slate)

-- Dunas suaves (ondulaciones)
for i = 1, 20 do
    local cx = math.random(-800, 800)
    local cz = math.random(-800, 800)
    local r = math.random(30, 120)
    local h = math.random(3, 12)
    local duneRegion = Region3.new(
        Vector3.new(cx - r, 0, cz - r),
        Vector3.new(cx + r, h, cz + r)
    )
    T:FillRegion(duneRegion, 4, Enum.Material.Sand)
end

-- Zona de arena mas oscura (grava) cerca del centro (futura mina)
local minaRegion = Region3.new(
    Vector3.new(-100, -5, -100),
    Vector3.new(100, 5, 100)
)
T:FillRegion(minaRegion, 4, Enum.Material.Gravel)

print("Desierto de Atacama generado!")
print("Terreno listo para construir la mina.")
