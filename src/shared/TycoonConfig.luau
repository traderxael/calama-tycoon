-- TycoonConfig.luau
-- Calama Mining Tycoon - Configuracion central

export type ShopItem = {
    Id: string,
    Name: string,
    Description: string,
    Phase: number,
    CostPesos: number,
    CostLey: number,
    Income: number,
    IncomeInterval: number,
    Effect: string,
    PrereqId: string?,
}

local TycoonConfig = {}

TycoonConfig.PHASES = {
    { Id = "artesanal", Name = "Faena Artesanal", UnlockCost = 0 },
    { Id = "rajo", Name = "Rajo Abierto", UnlockCost = 5000 },
    { Id = "industrial", Name = "Industrializacion", UnlockCost = 500000 },
    { Id = "endgame", Name = "Mina Subterranea", UnlockCost = 15000000 },
}

TycoonConfig.SHOP = {
    -- Fase 1: Faena Artesanal
    {
        Id = "terreno",
        Name = "Reclamar Terreno",
        Description = "Activa el terreno en medio del desierto",
        Phase = 1,
        CostPesos = 0,
        CostLey = 0,
        Income = 0,
        IncomeInterval = 0,
        Effect = "unlock_phase",
    },
    {
        Id = "chancador",
        Name = "Chancador Manual",
        Description = "Mineral de baja ley, $5/seg",
        Phase = 1,
        CostPesos = 0,
        CostLey = 0,
        Income = 5,
        IncomeInterval = 1,
        Effect = "income",
        PrereqId = "terreno",
    },
    {
        Id = "cinta",
        Name = "Cinta Transportadora",
        Description = "Lleva la piedra al colector",
        Phase = 1,
        CostPesos = 50,
        CostLey = 0,
        Income = 0,
        IncomeInterval = 0,
        Effect = "upgrade",
        PrereqId = "chancador",
    },
    {
        Id = "colector",
        Name = "Colector de Cobre",
        Description = "Al pisarlo, cobras el dinero acumulado",
        Phase = 1,
        CostPesos = 150,
        CostLey = 0,
        Income = 0,
        IncomeInterval = 0,
        Effect = "collector",
        PrereqId = "cinta",
    },
    {
        Id = "minero",
        Name = "Contratar Minero",
        Description = "Acelera el Chancador 2x",
        Phase = 1,
        CostPesos = 300,
        CostLey = 0,
        Income = 5,
        IncomeInterval = 1,
        Effect = "income_mult",
        PrereqId = "colector",
    },
    {
        Id = "camioneta",
        Name = "Camioneta 4x4 Minera",
        Description = "Aumenta capacidad del colector",
        Phase = 1,
        CostPesos = 1000,
        CostLey = 0,
        Income = 10,
        IncomeInterval = 1,
        Effect = "income",
        PrereqId = "minero",
    },
    -- Fase 2: Rajo Abierto
    {
        Id = "rajo_unlock",
        Name = "Desbloquear Rajo Abierto",
        Description = "Se expande el terreno revelando el crater",
        Phase = 2,
        CostPesos = 5000,
        CostLey = 0,
        Income = 0,
        IncomeInterval = 0,
        Effect = "unlock_phase",
        PrereqId = "camioneta",
    },
    {
        Id = "pala",
        Name = "Pala Electrica P&H",
        Description = "Genera mineral de ley media, $50/seg",
        Phase = 2,
        CostPesos = 15000,
        CostLey = 0,
        Income = 50,
        IncomeInterval = 1,
        Effect = "income",
        PrereqId = "rajo_unlock",
    },
    {
        Id = "caex",
        Name = "Camion CAEX",
        Description = "Transporta a la chancadora principal",
        Phase = 2,
        CostPesos = 40000,
        CostLey = 5,
        Income = 100,
        IncomeInterval = 2,
        Effect = "income",
        PrereqId = "pala",
    },
    {
        Id = "lixiviacion",
        Name = "Planta de Lixiviacion",
        Description = "Transforma mineral en Catodos, $200/unidad",
        Phase = 2,
        CostPesos = 100000,
        CostLey = 0,
        Income = 200,
        IncomeInterval = 3,
        Effect = "refine",
        PrereqId = "caex",
    },
    {
        Id = "campamento",
        Name = "Campamento Minero",
        Description = "Eficiencia + ingresos pasivos",
        Phase = 2,
        CostPesos = 250000,
        CostLey = 10,
        Income = 50,
        IncomeInterval = 5,
        Effect = "income_passive",
        PrereqId = "lixiviacion",
    },
    -- Fase 3: Industrializacion
    {
        Id = "concentradora",
        Name = "Planta Concentradora",
        Description = "Molino SAG, genera Concentrado, $1000/unidad",
        Phase = 3,
        CostPesos = 500000,
        CostLey = 0,
        Income = 1000,
        IncomeInterval = 4,
        Effect = "refine",
        PrereqId = "campamento",
    },
    {
        Id = "tuberia",
        Name = "Tuberia Desaladora",
        Description = "Agua de mar. Multiplica 2x toda la produccion",
        Phase = 3,
        CostPesos = 1500000,
        CostLey = 25,
        Income = 0,
        IncomeInterval = 0,
        Effect = "mult_2x",
        PrereqId = "concentradora",
    },
    {
        Id = "fundicion",
        Name = "Fundicion de Cobre",
        Description = "Anodos de maxima pureza, $5000/unidad",
        Phase = 3,
        CostPesos = 5000000,
        CostLey = 0,
        Income = 5000,
        IncomeInterval = 5,
        Effect = "refine",
        PrereqId = "tuberia",
    },
    -- Fase 4: Endgame
    {
        Id = "tunel",
        Name = "Tunel Block Caving",
        Description = "Mineral ultra alta ley, $20000/seg",
        Phase = 4,
        CostPesos = 15000000,
        CostLey = 50,
        Income = 20000,
        IncomeInterval = 1,
        Effect = "income",
        PrereqId = "fundicion",
    },
    {
        Id = "tren",
        Name = "Estacion de Tren",
        Description = "Exportacion masiva a Puerto Antofagasta",
        Phase = 4,
        CostPesos = 50000000,
        CostLey = 100,
        Income = 0,
        IncomeInterval = 0,
        Effect = "export_bonus",
        PrereqId = "tunel",
    },
    {
        Id = "solar",
        Name = "Parque Fotovoltaico",
        Description = "100% sustentable, elimina costos electricos",
        Phase = 4,
        CostPesos = 100000000,
        CostLey = 200,
        Income = 0,
        IncomeInterval = 0,
        Effect = "solar",
        PrereqId = "tren",
    },
}

TycoonConfig.ECONOMY = {
    STARTING_PESOS = 0,
    STARTING_LEY = 0,
    COLECTOR_INTERVAL = 2,
    DISPATCH_COOLDOWN = 2,
    MAX_PURCHASE_DISTANCE = 18,
}

function TycoonConfig.GetShopItem(id: string): ShopItem?
    for _, item in TycoonConfig.SHOP do
        if item.Id == id then return item end
    end
    return nil
end

function TycoonConfig.GetItemsByPhase(phase: number): { ShopItem }
    local items = {}
    for _, item in TycoonConfig.SHOP do
        if item.Phase == phase then
            table.insert(items, item)
        end
    end
    return items
end

function TycoonConfig.GetNextPhaseItems(currentPhase: number, owned: { [string]: boolean }): { ShopItem }
    local available = {}
    for _, item in TycoonConfig.SHOP do
        if item.Phase <= currentPhase and not owned[item.Id] then
            local prereq = item.PrereqId
            if not prereq or owned[prereq] then
                table.insert(available, item)
            end
        end
    end
    return available
end

return TycoonConfig
