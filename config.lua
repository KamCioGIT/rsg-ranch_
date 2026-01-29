Config = {}

-- Animal Settings
Config.ANIMAL_ID_MIN = 100000
Config.ANIMAL_ID_MAX = 999999

Config.FeedItem = 'animal_feed'


-- Growth Settings (3 hours IRL = 180 minutes to fully grow)
-- Animals MUST be fed (hunger >= 30) at each tick to continue growing
-- Hunger decays each tick, so feeding is required throughout growth
Config.Growth = {
    TickRate = 60 * 1000,          -- Check every 1 minute
    ScaleIncrease = 0.00278,       -- 0.5 / 180 = grows fully in 180 ticks (3 hours)
    DefaultStartScale = 0.5,       -- Start small (baby)
    DefaultMaxScale = 1.0,         -- Adult size
    HungerDecayPerTick = 2,        -- How much hunger drops each tick
    MinHungerToGrow = 30           -- Minimum hunger required to grow
}

Config.AnimalProducts = {
    ['a_c_bull_01'] = { product = 'manure', productionTime = 3600, amount = 1, requiresHealth = 60, requiresHunger = 40, requiresThirst = 40 },
    ['a_c_cow'] = { product = 'milk', productionTime = 3600, amount = 1, requiresHealth = 60, requiresHunger = 40, requiresThirst = 40 },
    ['a_c_pig_01'] = { product = 'manure', productionTime = 3600, amount = 1, requiresHealth = 60, requiresHunger = 40, requiresThirst = 40 },
    ['a_c_sheep_01'] = { product = 'wool', productionTime = 7200, amount = 1, requiresHealth = 60, requiresHunger = 40, requiresThirst = 40 },
    ['a_c_goat_01'] = { product = 'milk', productionTime = 3600, amount = 1, requiresHealth = 60, requiresHunger = 40, requiresThirst = 40 },
    ['a_c_chicken_01'] = { product = 'egg', productionTime = 1800, amount = 1, requiresHealth = 60, requiresHunger = 40, requiresThirst = 40 },
    ['a_c_rooster_01'] = { product = 'manure', productionTime = 3600, amount = 1, requiresHealth = 60, requiresHunger = 40, requiresThirst = 40 }
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
    ['a_c_rooster_01'] = 25
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
        name = 'Bayou Nwa Ranch',
        ranchid = 'bayounwaranch',
        coords = vector3(2258.3, -137.6, 46.2),
        npcmodel = `u_m_m_valtownfolk_01`,
        npccoords = vector4(2258.3, -137.6, 46.2, 0.0),
        jobaccess = 'bayounwaranch',
        blipname = 'Bayou Nwa Ranch',
        blipsprite = 'blip_ambient_herd',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(2263.3, -137.6, 46.2, 0.0)
    },
    { 
        name = 'Gaptooth Ranch',
        ranchid = 'gaptoothranch',
        coords = vector3(-5194.6, -2130.7, 12.1),
        npcmodel = `u_m_m_valtownfolk_01`,
        npccoords = vector4(-5194.6, -2130.7, 12.1, 0.0),
        jobaccess = 'gaptoothranch',
        blipname = 'Gaptooth Ranch',
        blipsprite = 'blip_ambient_herd',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(-5189.6, -2130.7, 12.1, 0.0)
    },
    { 
        name = 'Adler Ranch',
        ranchid = 'adlerranch',
        coords = vector3(-411.3, 1746.7, 216.3),
        npcmodel = `u_m_m_valtownfolk_01`,
        npccoords = vector4(-411.3, 1746.7, 216.3, 180.0),
        jobaccess = 'adlerranch',
        blipname = 'Adler Ranch',
        blipsprite = 'blip_ambient_herd',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(-416.3, 1746.7, 216.3, 0.0)
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
        name = 'Livestock Dealer (New Austin)',
        coords = vector3(-4674.1, -3754.5, 13.9),
        npcmodel = `s_m_m_unibutchers_01`,
        npccoords = vector4(-4674.1, -3754.5, 13.9, 0.0),
        blipname = 'Livestock Dealer',
        blipsprite = 'blip_shop_horse',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(-4672.0, -3754.5, 13.9, 0.0)
    },
    {
        name = 'Livestock Dealer (Lemoyne)',
        coords = vector3(2573.9, -781.7, 42.4),
        npcmodel = `s_m_m_unibutchers_01`,
        npccoords = vector4(2573.9, -781.7, 42.4, 0.0),
        blipname = 'Livestock Dealer',
        blipsprite = 'blip_shop_horse',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(2575.9, -781.7, 42.4, 0.0)
    },
    {
        name = 'Livestock Dealer (Heartlands)',
        coords = vector3(-370.2, -349.8, 87.2),
        npcmodel = `s_m_m_unibutchers_01`,
        npccoords = vector4(-370.2, -349.8, 87.2, 0.0),
        blipname = 'Livestock Dealer',
        blipsprite = 'blip_shop_horse',
        blipscale = 0.2,
        showblip = true,
        spawnpoint = vector4(-368.2, -349.8, 87.2, 0.0)
    },
}

-- Sale Point Locations (Removed - Merged into Buy Points)
-- Carcass Map
Config.CarcassItems = {
    ['a_c_bull_01'] = 'carcass_bull',
    ['a_c_cow'] = 'carcass_cow',
    ['a_c_pig_01'] = 'carcass_pig',
    ['a_c_sheep_01'] = 'carcass_sheep',
    ['a_c_goat_01'] = 'carcass_goat',
    ['a_c_chicken_01'] = 'carcass_chicken',
    ['a_c_rooster_01'] = 'carcass_rooster'
}

-- Butchering Rewards
-- Rewards for selling FULLY GROWN animals
Config.SellRewards = {
    ['a_c_cow'] = {
        { item = 'raw_meat', amount = 10 },
        { item = 'milk', amount = 5 },
        { item = 'leather', amount = 2 }
    },
    ['a_c_bull_01'] = {
        { item = 'raw_meat', amount = 15 },
        { item = 'leather', amount = 3 }
    },
    ['a_c_pig_01'] = {
        { item = 'raw_meat', amount = 8 },
        { item = 'leather', amount = 1 }
    },
    ['a_c_sheep_01'] = {
        { item = 'raw_meat', amount = 6 },
        { item = 'wool', amount = 5 }
    },
    ['a_c_goat_01'] = {
        { item = 'raw_meat', amount = 5 },
        { item = 'milk', amount = 2 }
    },
    ['a_c_chicken_01'] = {
        { item = 'raw_meat', amount = 2 },
        { item = 'egg', amount = 4 },
        { item = 'feather', amount = 5 }
    },
    ['a_c_rooster_01'] = {
        { item = 'raw_meat', amount = 3 },
        { item = 'feather', amount = 8 }
    }
}
    
Config.CraftingRecipes = {
    { 
        item = 'cheese', 
        label = 'Cheese', 
        ingredients = { 
            { item = 'milk', amount = 1, label = 'Milk' }
        },
        time = 5000,
        animDict = 'mech_inventory@crafting@fallbacks',
        animName = 'full_craft_and_stow'
    },
    { 
        item = 'butter', 
        label = 'Butter', 
        ingredients = { 
            { item = 'milk', amount = 1, label = 'Milk' } 
        },
        time = 4000,
        animDict = 'mech_inventory@crafting@fallbacks',
        animName = 'full_craft_and_stow'
    },
    { 
        item = 'fertilizer', 
        label = 'Fertilizer', 
        ingredients = { 
            { item = 'manure', amount = 1, label = 'Manure' } 
        },
        time = 3000,
        animDict = 'mech_inventory@crafting@fallbacks',
        animName = 'full_craft_and_stow'
    },
    { 
        item = 'animal_feed', 
        label = 'Animal Feed', 
        ingredients = { 
            { item = 'wheat', amount = 1, label = 'Wheat' },
            { item = 'corn', amount = 1, label = 'Corn' } 
        },
        time = 3000,
        animDict = 'mech_inventory@crafting@fallbacks',
        animName = 'full_craft_and_stow'
    },
    { 
        item = 'cloth', 
        label = 'Cloth', 
        ingredients = { 
            { item = 'wool', amount = 2, label = 'Wool' } 
        },
        time = 4000,
        animDict = 'mech_inventory@crafting@fallbacks',
        animName = 'full_craft_and_stow'
    },
    { 
        item = 'boiled_egg', 
        label = 'Boiled Egg', 
        ingredients = { 
            { item = 'egg', amount = 1, label = 'Egg' } 
        },
        time = 2000,
        animDict = 'mech_inventory@crafting@fallbacks',
        animName = 'full_craft_and_stow'
    },
    { 
        item = 'flour', 
        label = 'Flour', 
        ingredients = { 
            { item = 'wheat', amount = 2, label = 'Wheat' } 
        },
        time = 5000,
        animDict = 'mech_inventory@crafting@fallbacks',
        animName = 'full_craft_and_stow'
    },
    { 
        item = 'bread', 
        label = 'Bread', 
        ingredients = { 
            { item = 'flour', amount = 1, label = 'Flour' },
            { item = 'milk', amount = 1, label = 'Milk' }
        },
        time = 10000,
        animDict = 'mech_inventory@crafting@fallbacks',
        animName = 'full_craft_and_stow'
    },
    { 
        item = 'sausage', 
        label = 'Sausage', 
        ingredients = { 
            { item = 'raw_meat', amount = 2, label = 'Raw Meat' }
        },
        time = 6000,
        animDict = 'mech_inventory@crafting@fallbacks',
        animName = 'full_craft_and_stow'
    },
    { 
        item = 'jerky', 
        label = 'Jerky', 
        ingredients = { 
            { item = 'raw_meat', amount = 1, label = 'Raw Meat' }
        },
        time = 5000,
        animDict = 'mech_inventory@crafting@fallbacks',
        animName = 'full_craft_and_stow'
    },
    { 
        item = 'leather', 
        label = 'Leather', 
        ingredients = { 
            { item = 'hide_cow_1star', amount = 1, label = 'Cow Hide' }
        },
        time = 8000,
        animDict = 'mech_inventory@crafting@fallbacks',
        animName = 'full_craft_and_stow'
    },
    { 
        item = 'sugar', 
        label = 'Sugar', 
        ingredients = { 
            { item = 'cana', amount = 2, label = 'Sugarcane' }
        },
        time = 4000,
        animDict = 'mech_inventory@crafting@fallbacks',
        animName = 'full_craft_and_stow'
    },
    { 
        item = 'jam_raspberry', 
        label = 'Raspberry Jam', 
        ingredients = { 
            { item = 'red_raspberry', amount = 2, label = 'Raspberry' },
            { item = 'sugar', amount = 1, label = 'Sugar' }
        },
        time = 5000,
        animDict = 'mech_inventory@crafting@fallbacks',
        animName = 'full_craft_and_stow'
    },
    { 
        item = 'jam_blackcurrant', 
        label = 'Blackcurrant Jam', 
        ingredients = { 
            { item = 'black_currant', amount = 2, label = 'Black Currant' },
            { item = 'sugar', amount = 1, label = 'Sugar' }
        },
        time = 5000,
        animDict = 'mech_inventory@crafting@fallbacks',
        animName = 'full_craft_and_stow'
    },
    { 
        item = 'jam_peach', 
        label = 'Peach Jam', 
        ingredients = { 
            { item = 'consumable_peach', amount = 2, label = 'Peach' },
            { item = 'sugar', amount = 1, label = 'Sugar' }
        },
        time = 5000,
        animDict = 'mech_inventory@crafting@fallbacks',
        animName = 'full_craft_and_stow'
    }
}

Config.ButcherProp = 'p_table04x'
Config.ButcherTables = {}

Config.ManureLocations = {
    vector3(-2396.7, -2469.1, 60.3), -- MacFarlane
    vector3(-2416.5, -2395.7, 61.4), -- MacFarlane
    vector3(-5199.8, -2161.9, 12.1), -- Gaptooth
    vector3(-2544.7, 395.2, 148.3),  -- Pronghorn
    vector3(-2544.6, 403.5, 148.6),  -- Pronghorn (New)
    vector3(-2221.5, 727.4, 123.0),  -- New Location 1
    vector3(-2223.9, 738.2, 123.5),  -- New Location 2
    vector3(-868.3, 341.1, 96.6),    -- New Location 3
    vector3(-872.0, 318.8, 96.9),    -- New Location 4
    vector3(-417.7, 1755.9, 216.3),  -- New Location 5
    vector3(-411.0, 1713.8, 216.4),  -- New Location 6
    vector3(1394.4, 302.0, 88.5),    -- New Location 7
    vector3(1393.7, 288.5, 88.7),    -- New Location 8
    vector3(2265.2, -119.7, 46.5),   -- New Location 9
    vector3(2251.6, -119.7, 46.8),   -- New Location 10
    vector3(1364.8, -841.7, 71.0),   -- New Location 11
    vector3(1406.4, -873.0, 62.7)    -- New Location 12
}


