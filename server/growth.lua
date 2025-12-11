local RSGCore = exports['rsg-core']:GetCoreObject()
local oxmysql = exports.oxmysql

-- Growth Tick Loop
-- Growth Tick Loop
local NextGrowthTime = 0

CreateThread(function()
    while true do
        -- Sync Timer
        NextGrowthTime = os.time() + math.floor(Config.Growth.TickRate / 1000)
        TriggerClientEvent('rsg-ranch:client:syncGrowthTime', -1, NextGrowthTime)

        Wait(Config.Growth.TickRate)
        
        if SpawnedAnimals and next(SpawnedAnimals) then
             local ids = {}
             for id, _ in pairs(SpawnedAnimals) do
                 table.insert(ids, id)
             end
             
             -- Loop updates for specific active animals
             for _, id in ipairs(ids) do
                  -- Decay (Faster decay to require feeding)
                  oxmysql:updateSync('UPDATE rsg_ranch_animals SET hunger = GREATEST(0, hunger - 2) WHERE animalid = ?', {id})
                  -- Growth (Requires good nutrition: >= 30 hunger)
                  oxmysql:updateSync('UPDATE rsg_ranch_animals SET age = age + 1, scale = LEAST(?, scale + ?) WHERE scale < ? AND hunger >= 30 AND animalid = ?', {
                      Config.Growth.DefaultMaxScale, Config.Growth.ScaleIncrease, Config.Growth.DefaultMaxScale, id
                  })
             end
             
             -- Signal clients to refetch updated data
             TriggerClientEvent('rsg-ranch:client:refreshAnimals', -1)
        end
    end
end)

RSGCore.Functions.CreateCallback('rsg-ranch:server:getNextGrowth', function(source, cb)
    cb(NextGrowthTime)
end)
