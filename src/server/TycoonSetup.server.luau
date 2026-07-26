-- TycoonSetup.server.luau
-- Genera los pads de compra en el mundo
-- Busca modelos del usuario en Workspace, o crea pads genericos
-- Corre UNA VEZ al inicio, luego se autodestruye

local TycoonConfig = require(script.Parent.Parent.Shared.TycoonConfig)

local padsFolder = Instance.new("Folder")
padsFolder.Name = "TycoonPads"
padsFolder.Parent = workspace

local modelsFolder = workspace:FindFirstChild("Models")

local function createPad(item)
    -- Try to find a user model first
    local model
    if modelsFolder then
        model = modelsFolder:FindFirstChild(item.Id) or modelsFolder:FindFirstChild(item.Name)
    end

    local pad = Instance.new("Part")
    pad.Name = item.Id
    pad.Anchored = true
    pad.CanCollide = true
    pad.Size = Vector3.new(6, 1, 6)
    pad.Position = Vector3.new(0, 0.5, 0) + Vector3.new(
        (math.random() - 0.5) * 60,
        0,
        (math.random() - 0.5) * 40
    )

    -- If user has a matching model, parent it to the pad
    if model then
        local clone = model:Clone()
        clone.Parent = pad
        clone:PivotTo(pad.CFrame + Vector3.new(0, 1.5, 0))
    end

    -- ClickDetector for interaction
    local cd = Instance.new("ClickDetector")
    cd.Parent = pad

    -- Billboard GUI label
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = pad

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, 0, 0, 20)
    nameLbl.Text = item.Name
    nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 14
    nameLbl.Parent = billboard

    local costLbl = Instance.new("TextLabel")
    costLbl.Size = UDim2.new(1, 0, 0, 16)
    costLbl.Position = UDim2.new(0, 0, 0, 20)
    costLbl.TextColor3 = Color3.fromRGB(255, 200, 50)
    costLbl.BackgroundTransparency = 1
    costLbl.Font = Enum.Font.Gotham
    costLbl.TextSize = 12
    local costStr = ""
    if item.CostPesos > 0 then costStr ..= "$" .. tostring(item.CostPesos) end
    if item.CostLey > 0 then
        if costStr ~= "" then costStr ..= " + " end
        costStr ..= tostring(item.CostLey) .. " CLH"
    end
    if costStr == "" then costStr = "GRATIS" end
    costLbl.Text = costStr
    costLbl.Parent = billboard

    pad.Parent = padsFolder
    print("Pad creado: " .. item.Name .. " en " .. tostring(pad.Position))
end

-- Create pads for Phase 1 items
for _, item in TycoonConfig.GetItemsByPhase(1) do
    createPad(item)
end

print("=== TycoonPads generados ===")
script:Destroy()
