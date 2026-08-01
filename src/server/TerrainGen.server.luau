-- TerrainGen.server.luau
-- Genera el desierto de Atacama al arrancar el juego (RUN ONCE)
-- Borra baseplate, fondo blanco, pone cielo y luz desertica

local T = workspace.Terrain
local R3 = Region3.new
local V3 = Vector3.new
local SAND = Enum.Material.Sand
local SLATE = Enum.Material.Slate
local GRAVEL = Enum.Material.Gravel

-- Borrar BasePlate si existe
local bp = workspace:FindFirstChild("BasePlate")
if bp then bp:Destroy() end

-- Limpiar cualquier otro fondo blanco
for _, obj in workspace:GetChildren() do
    if obj:IsA("Part") and obj.Name == "Baseplate" then
        obj:Destroy()
    end
end

-- Cielo desertico (Atacama)
local Lighting = game:GetService("Lighting")
Lighting.Ambient = Color3.fromRGB(120, 100, 80)
Lighting.Brightness = 2.5
Lighting.GlobalShadows = true
Lighting.OutdoorAmbient = Color3.fromRGB(180, 150, 120)
Lighting.ShadowSoftness = 0.3
Lighting.GeographicLatitude = -22.46
Lighting.ClockTime = 14
Lighting.TimeOfDay = "14:00:00"

-- Sky box (despejado)
local sky = Instance.new("Sky")
sky.SkyboxBk = "rbxassetid://95206878"
sky.SkyboxDn = "rbxassetid://95206878"
sky.SkyboxFt = "rbxassetid://95206878"
sky.SkyboxLf = "rbxassetid://95206878"
sky.SkyboxRt = "rbxassetid://95206878"
sky.SkyboxUp = "rbxassetid://95206878"
sky.SunAngularSize = 8
sky.SunVelocity = Vector3.new(0, 0, 0)
sky.Parent = Lighting

-- TERRAIN
T:Clear()

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
print("BasePlate borrado, cielo desertico, terreno listo.")
script:Destroy()
