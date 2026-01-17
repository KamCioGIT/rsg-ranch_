#  Ranch - Advanced Animal Husbandry for RedM

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
*   **Feeding Requirements**:
    *   Each `animal_feed` restores hunger to 100%.
    *   Hunger decays by 2% every minute. Growth stops below 30% hunger.
    *   An animal needs **~3-4 feeds** to grow from baby to fully grown (over 2 hours).
    *   Feed roughly every **30-35 minutes** to maintain continuous growth.
*   **Product Rewards**:
    *   Selling **fully grown animals** rewards you with products (Milk, Wool, Eggs, Meat, Leather, etc.).
    *   Manure is collected from ground piles around the ranch using a `shovel`.
*   **Ranch Management**:
    *   Job-locked ranches (MacFarlane, Emerald, Pronghorn, etc.).
    *   "My Herd" menu to manage and spawn your owned animals.
    *   **Rename your animals** by clicking on their name in the My Herd menu.
    *   Animals persist in the database and save their growth/stats.
*   **Crafting System**:
    *   Process raw products into valuable goods (Cheese, Butter, Cloth, etc.).
    *   Configurable recipes in `config.lua`.
*   **Economy System**:
    *   **Buying**: Purchase animals from the Livestock Dealer for a base price.
    *   **Selling**: Sell animals back to the dealer. Price scales with growth:
        *   Baby animals sell for 60% of buy price (to discourage instant resale).
        *   **Fully grown animals sell for 2x the buy price!**
    *   **Ranch Revenue**: 20% of your **profit** (sell price - buy price) goes to the ranch funds.
    *   **Example**: Buy a cow for $50 → Grow it fully → Sell for $100. Profit is $50, ranch gets $10 (20%), you get $90.
*   **Interactive UI**:
    *   Beautiful, vintage-style status menu for animals.
    *   Live countdown timers for growth.

## 📦 Installation

### Step 1: Dependencies
Ensure you have the following resources installed:
- `rsg-core`
- `oxmysql`
- `ox_lib` (or supported menu/target)
- `rsg-inventory`

### Step 2: Database Setup
Import the `rsg-ranch.sql` file into your database.

*Important*: Ensure your `scale` column is `DECIMAL(6,5)` to support smooth growth updates:
```sql
ALTER TABLE rsg_ranch_animals MODIFY COLUMN scale DECIMAL(6,5) DEFAULT 0.50000;
```

### Step 3: Add Ranch Jobs to RSG-Core
Open your `rsg-core/shared/jobs.lua` file and add the ranch jobs.

**Option A: Copy the entire file**
Copy the contents from `rsg-ranch/installation/shared_jobs.lua` and paste them inside your `RSGCore.Shared.Jobs` table.

**Option B: Add individual ranches**
Add this structure for each ranch you want to enable:
```lua
['macfarranch'] = {
    label = 'Macfarlane Rancher',
    type = 'rancher',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'Trainee Rancher', payment = 3 },
        ['1'] = { name = 'Ranch Hand', payment = 5 },
        ['2'] = { name = 'Senior Rancher', payment = 7 },
        ['3'] = { name = 'Ranch Manager', isboss = true, payment = 10 },
        ['4'] = { name = 'Ranch Boss', isboss = true, payment = 15 },
    },
},
```

**Available Ranch Job Names:**
| Job Name | Ranch Location |
|---|---|
| `macfarranch` | MacFarlane Ranch |
| `emeraldranch` | Emerald Ranch |
| `pronghornranch` | Pronghorn Ranch |
| `downesranch` | Downes Ranch |
| `hillhavenranch` | Hill Haven Ranch |
| `hangingdogranch` | Hanging Dog Ranch |
| `bayounwaranch` | Bayou Nwa Ranch |
| `gaptoothranch` | Gaptooth Ranch |
| `adlerranch` | Adler Ranch |

### Step 4: Set Player Jobs (Admin Only)
Use the RSG-Core admin command to assign players to ranch jobs:
```
/setjob [playerid] [jobname] [grade]
```

**Examples:**
```
/setjob 1 macfarranch 4    -- Makes player 1 the Boss of MacFarlane Ranch
/setjob 2 emeraldranch 0   -- Makes player 2 a Trainee at Emerald Ranch
```

**Grade Levels:**
| Grade | Role | Permissions |
|---|---|---|
| 0 | Trainee Rancher | Basic access |
| 1 | Ranch Hand | Basic access |
| 2 | Senior Rancher | Basic access |
| 3 | Ranch Manager | Can hire/fire, access storage |
| 4 | Ranch Boss | Full access |

**Employee Limits:**
- Each ranch can have a maximum of **10 employees**.
- Only **Manager (grade 3)** and **Boss (grade 4)** can hire new employees.

> **Note:** The `/setjob` command is built into RSG-Core and is **admin-only** by default. Only players with admin permissions can use it.

### Step 5: Copy Item Images
Copy the asset images from `rsg-ranch/html/assets` to your inventory resource:
- **Source:** `rsg-ranch/html/assets/*.png`
- **Destination:** `rsg-inventory/html/images/`

### Step 6: Review Config
Open `config.lua` to adjust settings to your server's economy (prices, growth rates, etc.).

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

1.  **Get a Ranch Job**: Get hired by a ranch or have an admin assign you a job (e.g., `macfarranch`).
2.  **Buy Animals**: Visit the **Livestock Dealer** (marked on map) to purchase animals.
3.  **Manage Your Herd**: Go to your ranch and open the **Boss Menu** → **Manage Herd** to see your animals.
4.  **Rename Animals**: Click on an animal's name in the My Herd menu to give it a custom name.
5.  **Spawn Animals**: Click "Spawn" on any animal in your herd to bring it into the world.
6.  **Feed Regularly**: Target the animal and select "Feed Animal" (requires `animal_feed` item). **Animals won't grow if hungry (below 30%)!**
7.  **Check Status**: Target the animal and select "Check Status" to see health, hunger, and growth progress.
8.  **Collect Manure**: Use a `shovel` at manure piles around the ranch to collect manure.
9.  **Sell Animals**: Visit the Livestock Dealer to sell your animals.
    *   **Price scales with growth**: Baby animals sell for 60% of buy price, fully grown sell for 2x buy price.
    *   **Fully Grown Bonus**: Selling fully grown animals rewards you with **Cash** + **Bonus Resources** (Milk, Wool, Eggs, Meat, Leather, etc.)!
    *   **Sell All**: Use the "Sell All" button to sell your entire herd at once.
    *   **Ranch Revenue**: 20% of your profit goes to ranch funds.

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
