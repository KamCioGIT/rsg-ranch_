local RSGCore = exports['rsg-core']:GetCoreObject()
local oxmysql = exports.oxmysql

-- Growth Tick Loop (Optimized for 100+ players)
local NextGrowthTime = 0

CreateThread(function()
    while true do
        -- Sync Timer
        NextGrowthTime = os.time() + math.floor(Config.Growth.TickRate / 1000)
        
        Wait(Config.Growth.TickRate)
        
        -- Only process if animals are spawned
        if SpawnedAnimals and next(SpawnedAnimals) then
            local ids = {}
            local ranchAnimals = {} -- Track which animals belong to which ranch
            
            for id, data in pairs(SpawnedAnimals) do
                -- data is { ranchId = "...", citizenid = "...", netId = ... }
                local rId = data.ranchId
                
                table.insert(ids, id)
                if not ranchAnimals[rId] then
                    ranchAnimals[rId] = {}
                end
                table.insert(ranchAnimals[rId], id)
            end
            
            if #ids > 0 then
                local decayAmount = Config.Growth.HungerDecayPerTick or 2
                local minHunger = Config.Growth.MinHungerToGrow or 30
                
                -- BULK UPDATE: Single query for all hunger decay (async)
                oxmysql:execute([[
                    UPDATE rsg_ranch_animals 
                    SET hunger = GREATEST(0, CAST(hunger AS SIGNED) - ?) 
                    WHERE animalid IN (?)
                ]], {decayAmount, ids})
                
                -- BULK UPDATE: Single query for all growth (async)
                oxmysql:execute([[
                    UPDATE rsg_ranch_animals 
                    SET age = age + 1, scale = LEAST(?, scale + ?) 
                    WHERE scale < ? AND hunger >= ? AND animalid IN (?)
                ]], {
                    Config.Growth.DefaultMaxScale, 
                    Config.Growth.ScaleIncrease, 
                    Config.Growth.DefaultMaxScale, 
                    minHunger, 
                    ids
                })
                
                -- TARGETED EVENTS: Only send to players at each ranch
                -- Fetch updated animals and distribute to correct players
                Wait(100) -- Small delay to let writes complete
                
                for ranchId, animalIds in pairs(ranchAnimals) do
                    oxmysql:query('SELECT * FROM rsg_ranch_animals WHERE animalid IN (?)', {animalIds}, function(result)
                        if result and #result > 0 then
                            -- Get players at this ranch
                            local ranchPlayers = GetRanchPlayers(ranchId)
                            for _, src in ipairs(ranchPlayers) do
                                TriggerClientEvent('rsg-ranch:client:spawnAnimals', src, result)
                            end
                        end
                    end)
                end
                
                -- Sync growth timer to all players (lightweight event)
                TriggerClientEvent('rsg-ranch:client:syncGrowthTime', -1, NextGrowthTime)
            end
        end
    end
end)

-- Helper: Get all online players at a specific ranch
function GetRanchPlayers(ranchId)
    local players = {}
    local allPlayers = RSGCore.Functions.GetPlayers()
    
    for _, playerId in ipairs(allPlayers) do
        local Player = RSGCore.Functions.GetPlayer(playerId)
        if Player and Player.PlayerData.job.name == ranchId then
            table.insert(players, playerId)
        end
    end
    
    return players
end

RSGCore.Functions.CreateCallback('rsg-ranch:server:getNextGrowth', function(source, cb)
    cb(NextGrowthTime)
end)
