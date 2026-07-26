-- TerrainGen.server.luau
-- Genera el desierto de Atacama al arrancar el juego (RUN ONCE)
-- Despues de generar, borrar este script del lugar

local T = workspace.Terrain
T:Clear()

local R3 = Region3.new
local V3 = Vector3.new
local SAND = Enum.Material.Sand
local SLATE = Enum.Material.Slate
local GRAVEL = Enum.Material.Gravel

-- Base de arena (desierto plano)
T:FillRegion(R3(V3(-1024,-10,-1024), V3(1024,40,1024)), 4, SAND)

-- Capa de roca base
T:FillRegion(R3(V3(-1024,-50,-1024), V3(1024,-10,1024)), 4, SLATE)

-- Dunas suaves (ondulaciones)
for _ = 1, 25 do
    local cx = math.random(-800, 800)
    local cz = math.random(-800, 800)
    local r = math.random(40, 140)
    local h = math.random(3, 15)
    T:FillRegion(R3(V3(cx-r, -2, cz-r), V3(cx+r, h, cz+r)), 4, SAND)
end

-- Zona de la mina (grava, centro del mapa)
T:FillRegion(R3(V3(-120, -5, -120), V3(120, 8, 120)), 4, GRAVEL)

-- Cerro pequeno al fondo (referencia visual)
T:FillRegion(R3(V3(300, -5, -500), V3(500, 60, -300)), 4, SLATE)
T:FillRegion(R3(V3(310, 0, -490), V3(490, 55, -310)), 4, SAND)

print("=== Desierto de Atacama generado ===")
print("Terreno listo. Biome: arena + grava + dunas.")
script:Destroy() -- se borra solo despues de ejecutar
