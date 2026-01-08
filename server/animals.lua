local RSGCore = exports['rsg-core']:GetCoreObject()
local oxmysql = exports.oxmysql

SpawnedAnimals = {} -- Global for tracking

-- Fetch animals
RegisterNetEvent('rsg-ranch:server:refreshAnimals', function()
    local src = source
    local ids = {}
    for k, v in pairs(SpawnedAnimals) do
        if v then table.insert(ids, k) end
    end
    
    if #ids > 0 then
    -- Use query for SELECT
    oxmysql:query('SELECT * FROM rsg_ranch_animals WHERE animalid IN (?)', {ids}, function(result)
        if result then
            TriggerClientEvent('rsg-ranch:client:spawnAnimals', src, result)
        end
    end)
    end
end)

-- Despawn Logic (Send to Barn)
RegisterNetEvent('rsg-ranch:server:despawnAnimal', function(animalId)
    local idNum = tonumber(animalId)
    local idStr = tostring(animalId)
    
    if SpawnedAnimals[idNum] then SpawnedAnimals[idNum] = nil end
    if SpawnedAnimals[idStr] then SpawnedAnimals[idStr] = nil end
    if SpawnedAnimals[animalId] then SpawnedAnimals[animalId] = nil end
    
    print('[Ranch System] Despawned animal: ' .. tostring(animalId))
end)

-- Feed logic
RegisterNetEvent('rsg-ranch:server:feedAnimal', function(animalId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if Player.Functions.RemoveItem(Config.FeedItem, 1) then
        oxmysql:update('UPDATE rsg_ranch_animals SET hunger = 100, health = LEAST(100, health + 10) WHERE animalid = ?', {animalId})
        TriggerClientEvent('ox_lib:notify', src, {title = 'Animal Fed', type = 'success'})
        -- No refresh needed here usually, but if stats sync needed:
        -- TriggerEvent('rsg-ranch:server:refreshAnimals') 
    else
        TriggerClientEvent('ox_lib:notify', src, {title = 'Need Food', type = 'error'})
    end
end)



-- Collect Logic
RegisterNetEvent('rsg-ranch:server:collectProduct', function(animalId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    -- In real system, check 'product_ready' column in DB
    oxmysql:query('SELECT model, product_ready FROM rsg_ranch_animals WHERE animalid = ?', {animalId}, function(result)
        if result and result[1] then
            local model = result[1].model
            local isReady = result[1].product_ready
            local productData = Config.AnimalProducts[model]
            
            if productData then
                if isReady == 1 then
                    -- Add item & Reset DB
                    if Player.Functions.AddItem(productData.product, productData.amount) then
                        oxmysql:execute('UPDATE rsg_ranch_animals SET product_ready = 0, last_production = ? WHERE animalid = ?', {os.time(), animalId})
                        TriggerClientEvent('ox_lib:notify', src, {title = 'Collected ' .. productData.product, type = 'success'})
                    else
                        TriggerClientEvent('ox_lib:notify', src, {title = 'Inventory Full', type = 'error'})
                    end
                else
                    TriggerClientEvent('ox_lib:notify', src, {title = 'Not ready yet', description = 'Come back later.', type = 'error'})
                end
            else
                TriggerClientEvent('ox_lib:notify', src, {title = 'Nothing to collect', type = 'error'})
            end
        end
    end)
end)

-- Breeding Logic
RegisterNetEvent('rsg-ranch:server:attemptBreed', function(animalId)
    local src = source
    local chance = math.random(1, 100)
    
    if chance > 50 then
        -- Success
        oxmysql:execute('UPDATE rsg_ranch_animals SET pregnant = 1 WHERE animalid = ?', {animalId})
        TriggerClientEvent('ox_lib:notify', src, {title = 'Animal Pregnant', description = 'This animal is now expecting offspring.', type = 'success'})
    else
        TriggerClientEvent('ox_lib:notify', src, {title = 'Breeding Failed', description = 'Try again later.', type = 'inform'})
    end
end)

local DeadAnimals = {}

-- Spawn Ranch Animals (Triggered by Boss Menu)
-- Spawn Ranch Animals (Triggered by Boss Menu)
RegisterNetEvent('rsg-ranch:server:animalDied', function(animalId)
    local src = source
    local id = tonumber(animalId)
    if not id then return end
    
    print("[Ranch System] Animal Died: " .. id)
    DeadAnimals[id] = os.time() + 300 -- 5 Minute Cooldown
    
    -- Clear from spawned tracking
    SpawnedAnimals[id] = nil 
    SpawnedAnimals[tostring(id)] = nil
    
    TriggerClientEvent('ox_lib:notify', src, {title = 'Animal Died', description = 'You cannot spawn this animal for 5 minutes.', type = 'error'})
end)

RegisterNetEvent('rsg-ranch:server:spawnSpecificAnimal', function(animalId)
    local src = source
    local id = tonumber(animalId)
    if not id then return end
    
    -- Check 1: Already Spawned
    if SpawnedAnimals[id] then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Already Spawned', description = 'This animal is already out.', type = 'error'})
        return
    end

    local Player = RSGCore.Functions.GetPlayer(src)
    local PlayerJob = Player.PlayerData.job
    local ranchId = PlayerJob.name
    
    -- Check 2: Max Limit (5)
    local count = 0
    for _, rId in pairs(SpawnedAnimals) do
        if rId == ranchId then count = count + 1 end
    end
    
    
    if count >= 5 then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Limit Reached', description = 'Max 5 animals allowed at once.', type = 'error'})
        return
    end
        
    if DeadAnimals[id] and os.time() < DeadAnimals[id] then
        local left = DeadAnimals[id] - os.time()
        TriggerClientEvent('ox_lib:notify', src, {title = 'Cooldown', description = 'Animal is recovering. Wait '..left..'s', type = 'error'})
        return
    end
    
    -- print('[Ranch System] DEBUG: Searching DB for animalid: ' .. id .. ' ranchid: ' .. tostring(ranchId))

    oxmysql:single('SELECT * FROM rsg_ranch_animals WHERE animalid = ? AND ranchid = ?', {animalId, ranchId}, function(animal)
        if animal then
            -- print('[Ranch System] DEBUG: Animal found. Model: ' .. tostring(animal.model))
            SpawnedAnimals[animal.animalid] = ranchId -- Store ranch ownership
            TriggerClientEvent('rsg-ranch:client:spawnAnimals', src, {animal})
            TriggerClientEvent('ox_lib:notify', src, {title = 'Animal Called', description = 'Spawning animal '..animalId, type = 'success'})
        else
            print('[Ranch System] Animal NOT found in DB.')
            TriggerClientEvent('ox_lib:notify', src, {title = 'Error', description = 'Animal not found', type = 'error'})
        end
    end)
end)

RegisterNetEvent('rsg-ranch:server:spawnRanchAnimals', function()
    local src = source
    -- print('[Ranch System] DEBUG: spawnRanchAnimals triggered by source ' .. src)
    local Player = RSGCore.Functions.GetPlayer(src)
    local PlayerJob = Player.PlayerData.job
    local ranchId = PlayerJob.name
    
    -- Count current
    local count = 0
    for _, rId in pairs(SpawnedAnimals) do
        if rId == ranchId then count = count + 1 end
    end
    
    if count >= 5 then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Limit Reached', description = 'You already have 5 animals out.', type = 'error'})
        return
    end
    
    -- Removed LIMIT 5 to allow all animals to spawn
    -- Switched to query for correct SELECT behavior
    oxmysql:query('SELECT * FROM rsg_ranch_animals WHERE ranchid = ?', {ranchId}, function(animals)
        if animals then
            -- print('[Ranch System] DEBUG: Database returned ' .. #animals .. ' animals for ranch ' .. tostring(ranchId))
            if #animals > 0 then
                local spawnedSome = false
                local spawnList = {}
                
                for _, animal in ipairs(animals) do
                    -- Stop if limit reached
                    if count >= 5 then break end
                    
                    local aid = animal.animalid
                    -- Skip if dead or already spawned
                    local isDead = (DeadAnimals[aid] and os.time() < DeadAnimals[aid])
                    local isActive = (SpawnedAnimals[aid] ~= nil)
                    
                    if not isDead and not isActive then
                        SpawnedAnimals[aid] = ranchId
                        count = count + 1
                        table.insert(spawnList, animal)
                        spawnedSome = true
                    end
                end
                
                if spawnedSome then
                    TriggerClientEvent('rsg-ranch:client:spawnAnimals', src, spawnList)
                    TriggerClientEvent('ox_lib:notify', src, {title = 'Ranch Animals Called', description = 'Spawning ' .. #spawnList .. ' animals.', type = 'success'})
                else
                    TriggerClientEvent('ox_lib:notify', src, {title = 'Validation', description = 'Active animals: '..count..'/5. Others may be dead/active.', type = 'inform'})
                end
            else
                -- print('[Ranch System] DEBUG: No animals in tables.')
                TriggerClientEvent('ox_lib:notify', src, {title = 'No animals found for this ranch', type = 'error'})
            end
        else
            print('[Ranch System] Database query returned nil.')
            TriggerClientEvent('ox_lib:notify', src, {title = 'Database Error', type = 'error'})
        end
    end)
end)
