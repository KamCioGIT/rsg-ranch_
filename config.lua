Config = {}

-- Animal Settings
Config.ANIMAL_ID_MIN = 100000
Config.ANIMAL_ID_MAX = 999999

Config.FeedItem = 'animal_feed'


-- Growth Settings
Config.Growth = {
    TickRate = 60 * 1000, -- Check every 1 minute (TESTING)
    ScaleIncrease = 0.05,      -- How much scale increases per tick
    DefaultStartScale = 0.5,   -- Start small
    DefaultMaxScale = 1.0      -- Adult size
}

Config.AnimalProducts = {
    ['a_c_bull_01'] = { product = 'fertilizer', productionTime = 3600, amount = 1, requiresHealth = 60, requiresHunger = 40, requiresThirst = 40 },
    ['a_c_cow'] = { product = 'ranch_milk', productionTime = 3600, amount = 1, requiresHealth = 60, requiresHunger = 40, requiresThirst = 40 },
    ['a_c_pig_01'] = { product = 'fertilizer', productionTime = 3600, amount = 1, requiresHealth = 60, requiresHunger = 40, requiresThirst = 40 },
    ['a_c_sheep_01'] = { product = 'ranch_wool', productionTime = 7200, amount = 1, requiresHealth = 60, requiresHunger = 40, requiresThirst = 40 },
    ['a_c_goat_01'] = { product = 'ranch_milk', productionTime = 3600, amount = 1, requiresHealth = 60, requiresHunger = 40, requiresThirst = 40 },
    ['a_c_chicken_01'] = { product = 'ranch_egg', productionTime = 1800, amount = 1, requiresHealth = 60, requiresHunger = 40, requiresThirst = 40 },
    ['a_c_rooster_01'] = { product = 'fertilizer', productionTime = 3600, amount = 1, requiresHealth = 60, requiresHunger = 40, requiresThirst = 40 }
}

Config.AnimalsToBuy = {
    { label = 'Bull', model = 'a_c_bull_01', price = 100 },
    { label = 'Cow', model = 'a_c_cow', price = 50 },
    { label = 'Pig', model = 'a_c_pig_01', price = 30 },
    { label = 'Sheep', model = 'a_c_sheep_01', price = 40 },
    { label = 'Goat', model = 'a_c_goat_01', price = 35 },
    { label = 'Chicken', model = 'a_c_chicken_01', price = 10 },
    { label = 'Rooster', model = 'a_c_rooster_01', price = 15 }
}

Config.AgePricing = {
    young = 0.5,
    prime = 1.5,
    adult = 1.0,
    old   = 0.7
}

Config.BaseSellPrices = {
    ['a_c_bull_01'] = 400,
    ['a_c_cow'] = 150,
    ['a_c_pig_01'] = 80,
    ['a_c_sheep_01'] = 90,
    ['a_c_goat_01'] = 85,
    ['a_c_chicken_01'] = 20,
    ['a_c_rooster_01'] = 25,
    ['a_c_dog_husky_01'] = 50
}

-- Ranch Locations
Config.RanchLocations = {
    { 
        name = 'Macfarlane Ranch',
        ranchid = 'macfarranch',
        coords = vector3(-2405.00, -2381.53, 61.18),
        npcmodel = `u_m_m_valtownfolk_01`,
        npccoords = vector4(-2405.00, -2381.53, 61.18, 71.45),
        jobaccess = 'macfarranch',
        blipname = 'Macfarlane Ranch',
        blipsprite = 'blip_ambient_herd',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(-2425.51, -2367.51, 61.18, 82.40)
    },
    { 
        name = 'Emerald Ranch',
        ranchid = 'emeraldranch',
        coords = vector3(1403.50, 280.42, 89.25),
        npcmodel = `u_m_m_valtownfolk_01`,
        npccoords = vector4(1403.50, 280.42, 89.25, 19.85),
        jobaccess = 'emeraldranch',
        blipname = 'Emerald Ranch',
        blipsprite = 'blip_ambient_herd',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(1400.58, 290.48, 88.57, 19.79)
    },
    { 
        name = 'Pronghorn Ranch',
        ranchid = 'pronghornranch',
        coords = vector3(-2561.00, 403.92, 148.23),
        npcmodel = `u_m_m_valtownfolk_01`,
        npccoords = vector4(-2561.00, 403.92, 148.23, 97.99),
        jobaccess = 'pronghornranch',
        blipname = 'Pronghorn Ranch',
        blipsprite = 'blip_ambient_herd',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(-2567.10, 404.34, 148.61, 83.07)
    },
    { 
        name = 'Downes Ranch',
        ranchid = 'downesranch',
        coords = vector3(-853.86, 339.76, 96.39),
        npcmodel = `u_m_m_valtownfolk_01`,
        npccoords = vector4(-853.86, 339.76, 96.39, 262.57),
        jobaccess = 'downesranch',
        blipname = 'Downes Ranch',
        blipsprite = 'blip_ambient_herd',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(-850.30, 334.23, 95.77, 189.21)
    },
    { 
        name = 'Hill Haven Ranch',
        ranchid = 'hillhavenranch',
        coords = vector3(1367.14, -848.88, 70.85),
        npcmodel = `u_m_m_valtownfolk_01`,
        npccoords = vector4(1367.14, -848.88, 70.85, 297.43),
        jobaccess = 'hillhavenranch',
        blipname = 'Hill Haven Ranch',
        blipsprite = 'blip_ambient_herd',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(1373.20, -845.12, 70.56, 301.98)
    },
    { 
        name = 'Hanging Dog Ranch',
        ranchid = 'hangingdogranch',
        coords = vector3(-2207.69, 726.97, 122.82),
        npcmodel = `u_m_m_valtownfolk_01`,
        npccoords = vector4(-2207.69, 726.97, 122.82, 213.49),
        jobaccess = 'hangingdogranch',
        blipname = 'Hanging Dog Ranch',
        blipsprite = 'blip_ambient_herd',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(-2208.03, 719.73, 122.54, 185.14)
    }
}

-- Buy Point Locations
Config.BuyPointLocations = {
    {
        name = 'Livestock Dealer (Buy/Sell)', -- valentine
        coords = vector3(-218.78, 652.80, 113.27),
        npcmodel = `s_m_m_unibutchers_01`,
        npccoords = vector4(-218.78, 652.80, 113.27, 241.67),
        blipname = 'Livestock Dealer',
        blipsprite = 'blip_shop_horse',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(-217.61, 649.48, 113.10, 195.09)
    },
    {
        name = 'Livestock Dealer (Buy/Sell)', -- near strawberry
        coords = vector3(-1834.75, -578.28, 155.97),
        npcmodel = `s_m_m_unibutchers_01`,
        npccoords = vector4(-1834.75, -578.28, 155.97, 304.67),
        blipname = 'Livestock Dealer',
        blipsprite = 'blip_shop_horse',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(-1830.77, -576.25, 155.97, 291.70)
    },
    {
        name = 'Livestock Dealer (Buy/Sell)', -- wallace station
        coords = vector3(-1309.82, 387.21, 95.35),
        npcmodel = `s_m_m_unibutchers_01`,
        npccoords = vector4(-1309.82, 387.21, 95.35, 167.82),
        blipname = 'Livestock Dealer',
        blipsprite = 'blip_shop_horse',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(-1311.06, 385.14, 95.51, 95.24)
    },
}

-- Sale Point Locations (Removed - Merged into Buy Points)
Config.SalePointLocations = {}
