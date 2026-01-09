-----------------------------------------------
-- YOUR CUSTOM ITEMS
-----------------------------------------------
animal_feed  = { name = 'animal_feed',  label = 'Animal Feed',  weight = 1000, type = 'item', image = 'animal_feed.png',  unique = false, useable = true, shouldClose = true, description = 'feed for your animals' },
water_bucket = { name = 'water_bucket', label = 'Water Bucket', weight = 1000, type = 'item', image = 'water_bucket.png', unique = true,  useable = true, shouldClose = true, description = 'water for your animals' },
shovel       = { name = 'shovel',       label = 'Shovel',       weight = 1500, type = 'item', image = 'shovel.png',       unique = true,  useable = true, shouldClose = true, description = 'used for digging and collecting manure' },
-----------------------------------------------
-- ANIMAL PRODUCTS
-----------------------------------------------
milk       = { name = 'milk',       label = 'Fresh Milk', weight = 500,  type = 'item', image = 'milk.png',      unique = false, useable = false, shouldClose = true, description = 'fresh milk from cows' },
fertilizer = { name = 'fertilizer', label = 'Fertilizer', weight = 500, type = 'item', image = 'fertilizer.png', unique = false, useable = false, shouldClose = true, description = 'good for your garden' },
wool       = { name = 'wool',       label = 'Wool',       weight = 500, type = 'item', image = 'wool.png',       unique = false, useable = false, shouldClose = true, description = 'wool from sheep' },
egg        = { name = 'egg',        label = 'Egg',        weight = 100,  type = 'item', image = 'egg.png',        unique = false, useable = false, shouldClose = true, description = 'fresh farm eggs' },
-----------------------------------------------
-- PROCESSED GOODS
-----------------------------------------------
cloth      = { name = 'cloth',      label = 'Cloth',      weight = 200,  type = 'item', image = 'cloth.png',      unique = false, useable = false, shouldClose = true, description = 'woven fabric' },
boiled_egg = { name = 'boiled_egg', label = 'Boiled Egg', weight = 100,  type = 'item', image = 'boiled_egg.png', unique = false, useable = true,  shouldClose = true, description = 'a simple meal', hunger = 15 },
flour      = { name = 'flour',      label = 'Flour',      weight = 500,  type = 'item', image = 'flour.png',      unique = false, useable = false, shouldClose = true, description = 'ground wheat' },
bread      = { name = 'bread',      label = 'Bread',      weight = 300,  type = 'item', image = 'bread.png',      unique = false, useable = true,  shouldClose = true, description = 'fresh baked bread', hunger = 30 },
sausage    = { name = 'sausage',    label = 'Sausage',    weight = 300,  type = 'item', image = 'sausage.png',    unique = false, useable = true,  shouldClose = true, description = 'cooked sausage', hunger = 25 },
jerky      = { name = 'jerky',      label = 'Jerky',      weight = 100,  type = 'item', image = 'jerky.png',      unique = false, useable = true,  shouldClose = true, description = 'dried meat', hunger = 20 },
leather    = { name = 'leather',    label = 'Leather',    weight = 500,  type = 'item', image = 'leather.png',    unique = false, useable = false, shouldClose = true, description = 'tanned hide' },
sugar      = { name = 'sugar',      label = 'Sugar',      weight = 100,  type = 'item', image = 'sugar.png',      unique = false, useable = false, shouldClose = true, description = 'sweet sugar' },
jam_raspberry    = { name = 'jam_raspberry',    label = 'Raspberry Jam',    weight = 200,  type = 'item', image = 'jam_raspberry.png',    unique = false, useable = true,  shouldClose = true, description = 'sweet raspberry preserve', hunger = 15 },
jam_blackcurrant = { name = 'jam_blackcurrant', label = 'Blackcurrant Jam', weight = 200,  type = 'item', image = 'jam_blackcurrant.png', unique = false, useable = true,  shouldClose = true, description = 'tart blackcurrant preserve', hunger = 15 },
jam_peach        = { name = 'jam_peach',        label = 'Peach Jam',        weight = 200,  type = 'item', image = 'jam_peach.png',        unique = false, useable = true,  shouldClose = true, description = 'sweet peach preserve', hunger = 15 },
cheese           = { name = 'cheese',           label = 'Cheese',           weight = 200,  type = 'item', image = 'cheese.png',           unique = false, useable = true,  shouldClose = true, description = 'fresh cheese', hunger = 10 },
butter           = { name = 'butter',           label = 'Butter',           weight = 100,  type = 'item', image = 'butter.png',           unique = false, useable = true,  shouldClose = true, description = 'fresh butter', hunger = 5 },

-----------------------------------------------
-- FARMING & INGREDIENTS
-----------------------------------------------
wheat            = { name = 'wheat',            label = 'Wheat',            weight = 100,  type = 'item', image = 'wheat.png',            unique = false, useable = false, shouldClose = true, description = 'harvested wheat' },
corn             = { name = 'corn',             label = 'Corn',             weight = 100,  type = 'item', image = 'corn.png',             unique = false, useable = false, shouldClose = true, description = 'harvested corn' },
cana             = { name = 'cana',             label = 'Sugarcane',        weight = 100,  type = 'item', image = 'cana.png',             unique = false, useable = false, shouldClose = true, description = 'sugar cane stalk' },
red_raspberry    = { name = 'red_raspberry',    label = 'Raspberry',        weight = 50,   type = 'item', image = 'red_raspberry.png',    unique = false, useable = true,  shouldClose = true, description = 'fresh raspberry', hunger = 5 },
black_currant    = { name = 'black_currant',    label = 'Blackcurrant',     weight = 50,   type = 'item', image = 'black_currant.png',    unique = false, useable = true,  shouldClose = true, description = 'fresh blackcurrant', hunger = 5 },
consumable_peach = { name = 'consumable_peach', label = 'Peach',            weight = 100,  type = 'item', image = 'consumable_peach.png', unique = false, useable = true,  shouldClose = true, description = 'fresh peach', hunger = 10 },

-----------------------------------------------
-- EXTRA ANIMAL PRODUCTS
-----------------------------------------------
feather          = { name = 'feather',          label = 'Feather',          weight = 10,   type = 'item', image = 'feather.png',          unique = false, useable = false, shouldClose = true, description = 'bird feather' },
manure           = { name = 'manure',           label = 'Manure',           weight = 200,  type = 'item', image = 'manure.png',           unique = false, useable = false, shouldClose = true, description = 'animal waste' },
raw_meat         = { name = 'raw_meat',         label = 'Raw Meat',         weight = 500,  type = 'item', image = 'meat.png',             unique = false, useable = false, shouldClose = true, description = 'raw animal meat' },
