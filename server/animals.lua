local RSGCore = exports['rsg-core']:GetCoreObject()
local oxmysql = exports.oxmysql

SpawnedAnimals = {} -- format: [animalId] = { ranchId = "job", netId = 123 }

-- Helper to safely get ranchId
local function GetRanchId(animalId)
    local data = SpawnedAnimals[tonumber(animalId)] or SpawnedAnimals[tostring(animalId)]
    return data and data.ranchId or nil
end

-- Update NetID from Client
RegisterNetEvent('rsg-ranch:server:updateNetId', function(animalId, netId)
    local id = tonumber(animalId)
    if SpawnedAnimals[id] then
        SpawnedAnimals[id].netId = netId
        -- print('[Ranch System] Registered NetID '..netId..' for Animal '..id)
    end
end)

-- Fetch animals
RegisterNetEvent('rsg-ranch:server:refreshAnimals', function()
    local src = source
    local queryIds = {}
    local activeData = {}
    
    for k, v in pairs(SpawnedAnimals) do
        if v and v.ranchId then 
            table.insert(queryIds, k)
            activeData[k] = v.netId
        end
    end
    
    if #queryIds > 0 then
        oxmysql:query('SELECT * FROM rsg_ranch_animals WHERE animalid IN (?)', {queryIds}, function(result)
            if result then
                -- Attach known NetIDs to the result before sending
                for i, animal in ipairs(result) do
                    local aid = tonumber(animal.animalid)
                    if activeData[aid] then
                        animal.netId = activeData[aid]
                    end
                end
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
    
    print('[Ranch System] Despawned animal: ' .. tostring(animalId))
end)

-- Feed logic
RegisterNetEvent('rsg-ranch:server:feedAnimal', function(animalId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if Player.Functions.RemoveItem(Config.FeedItem, 1) then
        oxmysql:update('UPDATE rsg_ranch_animals SET hunger = 100, health = LEAST(100, health + 10) WHERE animalid = ?', {animalId})
        
        -- Fetch and sync new stats
        oxmysql:single('SELECT * FROM rsg_ranch_animals WHERE animalid = ?', {animalId}, function(animal)
            if animal then
                -- Attach existing NetID so client updates properly
                local active = SpawnedAnimals[tonumber(animalId)] or SpawnedAnimals[tostring(animalId)]
                if active and active.netId then
                    animal.netId = active.netId
                end
                TriggerClientEvent('rsg-ranch:client:spawnAnimals', src, {animal})
            end
        end)

        TriggerClientEvent('ox_lib:notify', src, {title = 'Animal Fed', type = 'success'}) 
    else
        TriggerClientEvent('ox_lib:notify', src, {title = 'Need Food', type = 'error'})
    end
end)


-- Collect Logic
RegisterNetEvent('rsg-ranch:server:collectProduct', function(animalId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    oxmysql:query('SELECT model, product_ready FROM rsg_ranch_animals WHERE animalid = ?', {animalId}, function(result)
        if result and result[1] then
            local model = result[1].model
            local isReady = result[1].product_ready
            local productData = Config.AnimalProducts[model]
            
            if productData then
                if isReady == 1 then
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
        oxmysql:execute('UPDATE rsg_ranch_animals SET pregnant = 1 WHERE animalid = ?', {animalId})
        TriggerClientEvent('ox_lib:notify', src, {title = 'Animal Pregnant', description = 'This animal is now expecting offspring.', type = 'success'})
    else
        TriggerClientEvent('ox_lib:notify', src, {title = 'Breeding Failed', description = 'Try again later.', type = 'inform'})
    end
end)

local DeadAnimals = {}

-- Animal Death
RegisterNetEvent('rsg-ranch:server:animalDied', function(animalId)
    local src = source
    local id = tonumber(animalId)
    if not id then return end
    
    print("[Ranch System] Animal Died: " .. id)
    DeadAnimals[id] = os.time() + 300 
    
    SpawnedAnimals[id] = nil 
    SpawnedAnimals[tostring(id)] = nil
    
    TriggerClientEvent('ox_lib:notify', src, {title = 'Animal Died', description = 'You cannot spawn this animal for 5 minutes.', type = 'error'})
end)

RegisterNetEvent('rsg-ranch:server:spawnSpecificAnimal', function(animalId)
    local src = source
    local id = tonumber(animalId)
    if not id then return end
    
    if GetRanchId(id) then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Already Spawned', description = 'This animal is already out.', type = 'error'})
        return
    end

    local Player = RSGCore.Functions.GetPlayer(src)
    local PlayerJob = Player.PlayerData.job
    local ranchId = PlayerJob.name
    
    local citizenId = Player.PlayerData.citizenid
    
    local count = 0
    for _, v in pairs(SpawnedAnimals) do
        -- Strict Personal Limit: Only count animals spawned by THIS person
        if v.ranchId == ranchId and v.citizenid == citizenId then 
            count = count + 1 
        end
    end
    
    if count >= 5 then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Limit Reached', description = 'You can only have 5 of YOUR animals out at once.', type = 'error'})
        return
    end
        
    if DeadAnimals[id] and os.time() < DeadAnimals[id] then
        local left = DeadAnimals[id] - os.time()
        TriggerClientEvent('ox_lib:notify', src, {title = 'Cooldown', description = 'Animal is recovering. Wait '..left..'s', type = 'error'})
        return
    end
    
    -- Strict Ownership Check
    oxmysql:single('SELECT * FROM rsg_ranch_animals WHERE animalid = ? AND ranchid = ? AND citizenid = ?', {animalId, ranchId, citizenId}, function(animal)
        if animal then
            SpawnedAnimals[animal.animalid] = { ranchId = ranchId, netId = nil, citizenid = citizenId } -- Track Owner
            TriggerClientEvent('rsg-ranch:client:spawnAnimals', src, {animal})
            TriggerClientEvent('ox_lib:notify', src, {title = 'Animal Called', description = 'Spawning animal '..animalId, type = 'success'})
        else
            TriggerClientEvent('ox_lib:notify', src, {title = 'Error', description = 'Animal not found or not yours.', type = 'error'})
        end
    end)
end)

RegisterNetEvent('rsg-ranch:server:spawnRanchAnimals', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local PlayerJob = Player.PlayerData.job
    local ranchId = PlayerJob.name
    
    local citizenId = Player.PlayerData.citizenid
    
    local count = 0
    for _, v in pairs(SpawnedAnimals) do
        if v.ranchId == ranchId and v.citizenid == citizenId then count = count + 1 end
    end
    
    if count >= 5 then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Limit Reached', description = 'You already have 5 animals out.', type = 'error'})
        return
    end
    
    -- Only fetch MY animals
    oxmysql:query('SELECT * FROM rsg_ranch_animals WHERE ranchid = ? AND citizenid = ?', {ranchId, citizenId}, function(animals)
        if animals then
            if #animals > 0 then
                local spawnList = {}
                
                for _, animal in ipairs(animals) do
                    if count >= 5 then break end
                    
                    local aid = animal.animalid
                    local isDead = (DeadAnimals[aid] and os.time() < DeadAnimals[aid])
                    local isActive = GetRanchId(aid) ~= nil
                    
                    if not isDead and not isActive then
                        SpawnedAnimals[aid] = { ranchId = ranchId, netId = nil, citizenid = citizenId }
                        count = count + 1
                        table.insert(spawnList, animal)
                    end
                end
                
                if #spawnList > 0 then
                    TriggerClientEvent('rsg-ranch:client:spawnAnimals', src, spawnList)
                    TriggerClientEvent('ox_lib:notify', src, {title = 'Ranch Animals Called', description = 'Spawning ' .. #spawnList .. ' animals.', type = 'success'})
                else
                    TriggerClientEvent('ox_lib:notify', src, {title = 'Validation', description = 'Active animals: '..count..'/5. Others may be dead/active.', type = 'inform'})
                end
            else
                TriggerClientEvent('ox_lib:notify', src, {title = 'No animals found for this ranch', type = 'error'})
            end
        end
    end)
end)

