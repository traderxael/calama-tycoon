-- TycoonConfig.luau
-- Minera de Calama - Configuracion central del tycoon

export type StageConfig = {
    Id: string,
    Name: string,
    Description: string,
    Cost: number,
    UpgradeBaseCost: number,
    UpgradeCostGrowth: number,
    BaseIncome: number,
    ProcessingTime: number,
    InputItem: string?,
    OutputItem: string,
    IsExport: boolean,
    Color: Color3,
    Icon: string,
}

local TycoonConfig = {}

TycoonConfig.MACHINES = {
    {
        Id = "rajo",
        Name = "Rajo",
        Description = "Mina a cielo abierto - extraccion de mineral",
        Cost = 0,
        UpgradeBaseCost = 50,
        UpgradeCostGrowth = 1.5,
        BaseIncome = 1,
        ProcessingTime = 3,
        OutputItem = "Mineral",
        IsExport = false,
        Color = Color3.fromRGB(139, 90, 43),
        Icon = "pickaxe",
    },
    {
        Id = "chancado",
        Name = "Chancado",
        Description = "Planta de chancado primario",
        Cost = 200,
        UpgradeBaseCost = 150,
        UpgradeCostGrowth = 1.6,
        BaseIncome = 3,
        ProcessingTime = 4,
        InputItem = "Mineral",
        OutputItem = "Ripio",
        IsExport = false,
        Color = Color3.fromRGB(169, 169, 169),
        Icon = "gear",
    },
    {
        Id = "molienda",
        Name = "Molienda",
        Description = "Molinos SAG y bolas",
        Cost = 800,
        UpgradeBaseCost = 400,
        UpgradeCostGrowth = 1.65,
        BaseIncome = 8,
        ProcessingTime = 5,
        InputItem = "Ripio",
        OutputItem = "Pulpa",
        IsExport = false,
        Color = Color3.fromRGB(192, 192, 192),
        Icon = "gear",
    },
    {
        Id = "flotacion",
        Name = "Flotacion",
        Description = "Celdas de flotacion - concentrado de cobre",
        Cost = 2500,
        UpgradeBaseCost = 900,
        UpgradeCostGrowth = 1.7,
        BaseIncome = 20,
        ProcessingTime = 6,
        InputItem = "Pulpa",
        OutputItem = "Concentrado",
        IsExport = false,
        Color = Color3.fromRGB(205, 127, 50),
        Icon = "flask",
    },
    {
        Id = "fundicion",
        Name = "Fundicion",
        Description = "Horno de fundicion - cobre blister",
        Cost = 8000,
        UpgradeBaseCost = 2500,
        UpgradeCostGrowth = 1.75,
        BaseIncome = 55,
        ProcessingTime = 7,
        InputItem = "Concentrado",
        OutputItem = "Blister",
        IsExport = false,
        Color = Color3.fromRGB(255, 140, 0),
        Icon = "fire",
    },
    {
        Id = "refineria",
        Name = "refineria SX-EW",
        Description = "Extraccion por solventes y electro-obtencion",
        Cost = 25000,
        UpgradeBaseCost = 7000,
        UpgradeCostGrowth = 1.8,
        BaseIncome = 150,
        ProcessingTime = 8,
        InputItem = "Blister",
        OutputItem = "Catodos",
        IsExport = false,
        Color = Color3.fromRGB(184, 115, 51),
        Icon = "zap",
    },
    {
        Id = "fcab",
        Name = "FCAB",
        Description = "Ferrocarril de Antofagasta a Bolivia",
        Cost = 75000,
        UpgradeBaseCost = 18000,
        UpgradeCostGrowth = 1.85,
        BaseIncome = 400,
        ProcessingTime = 10,
        InputItem = "Catodos",
        OutputItem = "Carga",
        IsExport = false,
        Color = Color3.fromRGB(50, 50, 200),
        Icon = "train",
    },
    {
        Id = "puerto",
        Name = "Puerto",
        Description = "Puerto de embarque - exportacion mundial",
        Cost = 200000,
        UpgradeBaseCost = 50000,
        UpgradeCostGrowth = 1.9,
        BaseIncome = 0,
        ProcessingTime = 12,
        InputItem = "Carga",
        OutputItem = "Exportacion",
        IsExport = true,
        Color = Color3.fromRGB(0, 150, 200),
        Icon = "anchor",
    },
}

TycoonConfig.ECONOMY = {
    BASE_LME_PRICE = 4.25,
    MIN_PRICE = 3.40,
    MAX_PRICE = 5.30,
    PRICE_UPDATE_INTERVAL = 40,
    EXPORT_UNIT_VALUE = 350,
    REBIRTH_BONUS_PER_LEVEL = 0.25,
    REBIRTH_MIN_STAGES = 7,
    REBIRTH_MIN_MONEY = 50000,
    COOP_RADIUS = 45,
    COOP_BONUS = 0.20,
    COOP_MAX_BONUS = 0.60,
    MAX_PURCHASE_DISTANCE = 18,
    DISPATCH_COOLDOWN = 2,
    STARTING_MONEY = 100,
}

function TycoonConfig.GetUpgradeCost(stage: StageConfig, level: number): number
    return math.floor(stage.UpgradeBaseCost * stage.UpgradeCostGrowth ^ (level - 1))
end

function TycoonConfig.GetStage(i: number): StageConfig?
    return TycoonConfig.MACHINES[i]
end

function TycoonConfig.TotalStages(): number
    return #TycoonConfig.MACHINES
end

return TycoonConfig
