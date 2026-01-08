# RSG Ranch - Advanced Animal Husbandry for RedM

A comprehensive ranching system for RedM using the RSG Core framework. This resource allows players to own ranches, buy and raise animals, collect products, craft items, and sell livestock for profit.

## 🌟 Features

*   **Animal Buying**: Purchase various animals (Cows, Bulls, Pigs, Sheep, Goats, Chickens, Roosters) from the Livestock Dealer.
*   **Realistic Growth System**:
    *   Animals start as babies (small scale).
    *   They grow over time (Default: 2 hours IRL = Full Growth).
    *   **Requires Feeding**: Animals will NOT grow if they are hungry (< 30%).
    *   **Visual Growth**: Animals physically get larger as they age.
*   **Needs System**:
    *   **Hunger**: Decays over time. Feed animals with `animal_feed`. **Critical for growth.**
    *   **Thirst**: Decays over time (Cosmetic / Placeholder).
    *   **Health**: Can be affected by starvation.
*   **Product Collection**:
    *   Collect Milk, Wool, Eggs, and Manure from animals when they are ready.
    *   Requires a bucket or interaction.
*   **Ranch Management**:
    *   Job-locked ranches (MacFarlane, Emerald, Pronghorn, etc.).
    *   "My Herd" menu to manage and spawn your owned animals.
    *   Animals persist in the database and save their growth/stats.
*   **Crafting System**:
    *   Process raw products into valuable goods (Cheese, Butter, Cloth, etc.).
    *   Configurable recipes in `config.lua`.
*   **Selling System**:
    *   Sell animals back to the dealer.
    *   Price depends on **Age** and **Growth**. Fully grown animals sell for the most!
*   **Interactive UI**:
    *   Beautiful, vintage-style status menu for animals.
    *   Live countdown timers for growth.

## 📦 Installation

1.  **Dependencies**: Ensure you have `rsg-core`, `oxmysql`, `ox_lib` (or supported menu/target), and `rsg-inventory` installed.
2.  **Database**: Import the `rsg-ranch.sql` file into your database.
    *   *Important*: Ensure your `scale` column is `DECIMAL(6,5)` to support smooth growth updates.
    ```sql
    ALTER TABLE rsg_ranch_animals MODIFY COLUMN scale DECIMAL(6,5) DEFAULT 0.50000;
    ```
3.  **Config**: Review `config.lua` to adjust settings to your server's economy.
4.  **Images**: Copy the provided asset images to your inventory resource (`rsg-inventory/html/images`) and the ranch resource (`rsg-ranch/html/assets`).

## ⚙️ Configuration Guide

### Adding a New Ranch
Open `config.lua` and locate `Config.RanchLocations`. Add a new entry:

```lua
{ 
    name = 'My New Ranch',
    ranchid = 'mynewranch',          -- Unique ID (matches job name)
    coords = vector3(x, y, z),       -- Blip/Interaction location
    npcmodel = `u_m_m_valtownfolk_01`, 
    npccoords = vector4(x, y, z, h), -- NPC location
    jobaccess = 'mynewranch',        -- Job required to use this ranch
    blipname = 'My Ranch',
    blipsprite = 'blip_ambient_herd',
    blipscale = 0.2,
    showblip = true,
    spawnpoint = vector4(x, y, z, h) -- Where animals spawn
}
```

### Adding a New Animal
1.  **Define Price**: Add to `Config.AnimalsToBuy`.
2.  **Define Base Value**: Add to `Config.BaseSellPrices`.
3.  **Define Products**: Add to `Config.AnimalProducts` (optional).
4.  **Define Rewards**: Add to `Config.SellRewards` (optional, for butchering/selling).

### Adjusting Growth Speed
Modify `Config.Growth` in `config.lua`:

```lua
Config.Growth = {
    TickRate = 60 * 1000,          -- frequency of updates (default 1 min)
    ScaleIncrease = 0.00417,       -- Amount to grow per tick. Calculation: (MaxScale - StartScale) / TotalTicks
    -- Example for 2 hours (120 mins): (1.0 - 0.5) / 120 = 0.00417
    DefaultStartScale = 0.5,
    DefaultMaxScale = 1.0,
    HungerDecayPerTick = 2,
    MinHungerToGrow = 30
}
```

### Adding Crafting Recipes
Add to `Config.CraftingRecipes`:

```lua
{ 
    item = 'my_new_item', 
    label = 'My New Item', 
    ingredients = { 
        { item = 'ingredient1', amount = 1, label = 'Ingredient Name' } 
    },
    time = 5000, -- Time in ms
    animDict = 'mech_inventory@crafting@fallbacks',
    animName = 'full_craft_and_stow'
}
```

## 🎮 How to Use (Players)

1.  **Get a Ranch Job**: You need the specific job for your ranch (e.g., `macfarranch`).
2.  **Buy Animals**: Visit the **Livestock Dealer** (marked on map) to buy animals.
3.  **Spawn Animals**: Go to your ranch's main management point and open the menu to spawn your herd.
4.  **Feed Them**: Use `animal_feed` on your animals. **They won't grow if they are hungry!**
5.  **Check Status**: Alt-eye (target) the animal to check their growth progress, health, and hunger.
6.  **Harvest**: When products are ready (milk/wool/eggs), interact with the animal.
7.  **Sell**: Visit the Livestock Dealer to sell your animals.
    *   **Fully Grown Bonus**: Selling a fully grown (100%) animal rewards you with **Cash** AND **Resources** (Meat, Leather, etc.) automatically!
    *   **Young Animals**: Selling young animals yields less cash and no bonus resources.

## �‍🌾 Ranch Management (Job System)

Ranches are tied to specific jobs (e.g., `macfarranch`). Employees with higher grades have more permissions:
*   **Boss (Grade 4)**: Can Hire/Fire/Promote, Withdraw Funds, Manage Everything.
*   **Manager (Grade 3)**: Can Hire/Fire, Withdraw Funds, Place/Remove Tables.
*   **Employee**: Can ranch animals, collect manure, craft items.

### Manure Collection
*   **Where**: Look for manure piles around the ranch (defined in config).
*   **How**: Use `Left-Alt` (Target) on the pile -> "Collect Manure".
*   **Requirement**: You need a `shovel` in your inventory.
*   **Reward**: 1x `manure` (Useful for crafting Fertilizer).

## �🛠️ Support
For support, please refer to the RSG framework documentation or the developer of this resource.
