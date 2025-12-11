local RSGCore = exports['rsg-core']:GetCoreObject()
local oxmysql = exports.oxmysql


CreateThread(function()
    if GetResourceState('ox_inventory') == 'started' then
        for _, ranch in ipairs(Config.RanchLocations) do
            local stashName = 'ranch_' .. ranch.jobaccess
            local label = ranch.name .. ' Storage'
            -- RegisterStash(id, label, slots, maxWeight, owner, groups, coords)
            exports.ox_inventory:RegisterStash(stashName, label, 50, 4000000, nil, {[ranch.jobaccess] = 0})
            -- print('[Ranch System] Registered stash: ' .. stashName)
        end
    end
end)


RegisterNetEvent('rsg-ranch:server:buyItem', function(data)
    local src = source
    -- print("[Ranch System] Processing Buy Request from Source: " .. src)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local price = tonumber(data.price)
    local model = data.model
    local amount = tonumber(data.amount) or 1
    
    if amount < 1 then amount = 1 end
    if amount > 10 then amount = 10 end -- Hard cap

    local PlayerJob = Player.PlayerData.job
    local ranchId = PlayerJob.name
    

    local count = oxmysql:scalarSync('SELECT COUNT(*) FROM rsg_ranch_animals WHERE ranchid = ?', {ranchId}) or 0
    if (count + amount) > 20 then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Limit Reached', description = 'You cannot have more than 20 animals. Current: '..count, type = 'error'})
        return
    end
    
    local totalPrice = price * amount

    if Player.Functions.RemoveMoney('cash', totalPrice) then
        local startScale = Config.Growth.DefaultStartScale
        local spawnCoords = vector4(0,0,0,0)
        for _, ranch in ipairs(Config.RanchLocations) do
            if ranch.jobaccess == ranchId then
                spawnCoords = ranch.spawnpoint
                break
            end
        end
        
        if spawnCoords.x == 0 then
             Player.Functions.AddMoney('cash', totalPrice)
             TriggerClientEvent('ox_lib:notify', src, {title = 'Purchase Failed', description = 'You do not own a ranch!', type = 'error'})
             return
        end
        
        for i=1, amount do
            local animalId = math.random(Config.ANIMAL_ID_MIN, Config.ANIMAL_ID_MAX)
            local exists = oxmysql:scalarSync('SELECT 1 FROM rsg_ranch_animals WHERE animalid = ?', {animalId})
            while exists do
                animalId = math.random(Config.ANIMAL_ID_MIN, Config.ANIMAL_ID_MAX)
                exists = oxmysql:scalarSync('SELECT 1 FROM rsg_ranch_animals WHERE animalid = ?', {animalId})
            end
            
            oxmysql:insert('INSERT INTO rsg_ranch_animals (animalid, model, pos_x, pos_y, pos_z, pos_w, scale, age, ranchid, born) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                animalId, model, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, startScale, 0, ranchId, os.time()
            })
        end

        -- print("Player " .. src .. " bought " .. amount .. " " .. model .. " for $" .. totalPrice)
        TriggerClientEvent('ox_lib:notify', src, {title = 'Purchase Successful', description = 'Bought '..amount..' animals.', type = 'success'})
    else
        TriggerClientEvent('ox_lib:notify', src, {title = 'Purchase Failed', description = 'Not enough cash! Need $'..totalPrice, type = 'error'})
    end
end)


RegisterNetEvent('rsg-ranch:server:sellItem', function(data)
    local src = source
    -- print("[Ranch System] Processing Sell Request from Source: " .. src .. " for Animal ID: " .. tostring(data.id))
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local animalId = data.id
    local PlayerJob = Player.PlayerData.job
    local ranchId = PlayerJob.name
    
    local result = oxmysql:singleSync('SELECT * FROM rsg_ranch_animals WHERE animalid = ? AND ranchid = ?', {animalId, ranchId})
    
    if result then
        local model = result.model
        local scale = tonumber(result.scale) or Config.Growth.DefaultStartScale
        

        local buyPrice = 0
        for _, item in ipairs(Config.AnimalsToBuy) do
            if item.model == model then
                buyPrice = item.price
                break
            end
        end
        

        local maxSellPrice = Config.BaseSellPrices[model] or (buyPrice * 2)
        

        local startScale = Config.Growth.DefaultStartScale
        local maxScale = Config.Growth.DefaultMaxScale
        local progress = (scale - startScale) / (maxScale - startScale)
        if progress < 0 then progress = 0 end
        if progress > 1 then progress = 1 end
        
        local startValue = buyPrice * 0.6
        local finalPrice = math.floor(startValue + ((maxSellPrice - startValue) * progress))
        

        local ranchShare = math.floor(finalPrice * 0.25) -- 25% to Ranch
        local playerShare = finalPrice - ranchShare
        
        oxmysql:execute('DELETE FROM rsg_ranch_animals WHERE animalid = ?', {animalId})
        -- Clean up from global spawn tracker if exists
        TriggerEvent('rsg-ranch:server:despawnAnimal', animalId)
        

        Player.Functions.AddMoney('cash', playerShare)
        

        oxmysql:execute('INSERT INTO rsg_ranch_funds (ranchid, funds) VALUES (?, ?) ON DUPLICATE KEY UPDATE funds = funds + ?', {ranchId, ranchShare, ranchShare})
        
        TriggerClientEvent('ox_lib:notify', src, {title = 'Sale Successful', description = 'Sold for $' .. finalPrice .. ' (Received: $' .. playerShare .. ', Ranch: $' .. ranchShare .. ')', type = 'success'})
    else
        TriggerClientEvent('ox_lib:notify', src, {title = 'Sale Failed', description = 'Animal not found or already sold.', type = 'error'})
    end
end)

RegisterNetEvent('rsg-ranch:server:withdrawFunds', function(amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local ranchId = Player.PlayerData.job.name
    local grade = Player.PlayerData.job.grade.level
    
    if grade < 2 then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Access Denied', description = 'Only Manager/Boss can withdraw funds.', type = 'error'})
        return
    end
    
    local funds = oxmysql:scalarSync('SELECT funds FROM rsg_ranch_funds WHERE ranchid = ?', {ranchId}) or 0
    if funds >= amount then
        oxmysql:update('UPDATE rsg_ranch_funds SET funds = funds - ? WHERE ranchid = ?', {amount, ranchId})
        Player.Functions.AddMoney('cash', amount)
        TriggerClientEvent('ox_lib:notify', src, {title = 'Withdrawn', description = '$'..amount, type = 'success'})
    else
        TriggerClientEvent('ox_lib:notify', src, {title = 'Insufficient Funds', type = 'error'})
    end
end)

RegisterNetEvent('rsg-ranch:server:depositFunds', function(amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local ranchId = Player.PlayerData.job.name
    
    if Player.Functions.RemoveMoney('cash', amount) then
        oxmysql:execute('INSERT INTO rsg_ranch_funds (ranchid, funds) VALUES (?, ?) ON DUPLICATE KEY UPDATE funds = funds + ?', {ranchId, amount, amount})
        TriggerClientEvent('ox_lib:notify', src, {title = 'Deposited', description = '$'..amount, type = 'success'})
    else
        TriggerClientEvent('ox_lib:notify', src, {title = 'Not enough cash', type = 'error'})
    end
end)

RegisterNetEvent('rsg-ranch:server:hireEmployee', function(targetId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Target = RSGCore.Functions.GetPlayer(targetId)
    
    if not Player or not Target then return end
    
    local grade = Player.PlayerData.job.grade.level
    -- User requested Managers (assumed Grade 1) can also hire/fire lower ranks
    if grade < 1 then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Access Denied', description = 'Only Manager/Boss can hire.', type = 'error'})
        return
    end

    local ranchId = Player.PlayerData.job.name
    
    -- When hiring, default to grade 0 (Rancher)
    Target.Functions.SetJob(ranchId, 0)
    
    TriggerClientEvent('ox_lib:notify', src, {title = 'Hired', description = 'You hired '..Target.PlayerData.charinfo.firstname, type = 'success'})
    TriggerClientEvent('ox_lib:notify', targetId, {title = 'Hired', description = 'You were hired at '..ranchId, type = 'success'})
end)

RegisterNetEvent('rsg-ranch:server:fireEmployee', function(targetId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Target = RSGCore.Functions.GetPlayer(targetId)
    
    if not Player then return end
    local myGrade = Player.PlayerData.job.grade.level

    if myGrade < 1 then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Access Denied', description = 'Only Manager/Boss can fire.', type = 'error'})
        return
    end
    
    if Target then
        local targetGrade = Target.PlayerData.job.grade.level
        
        -- Logic:
        -- Boss (2) can fire anyone.
        -- Manager (1) can fire Rancher (0).
        -- Manager (1) cannot fire Manager (1) or Boss (2).
        -- Manager (1) cannot fire self (targetId == src).
        -- User: "manager can fire his lower ranch but not him self only boss can fire manager"

        if myGrade == 1 then
            if src == targetId then
                TriggerClientEvent('ox_lib:notify', src, {title = 'Action Failed', description = 'You cannot fire yourself.', type = 'error'})
                return
            end
            if targetGrade >= 1 then
                TriggerClientEvent('ox_lib:notify', src, {title = 'Access Denied', description = 'Managers cannot fire other Managers or Bosses.', type = 'error'})
                return
            end
        end

        -- If we are here, it's either Boss (who can do anything) or Manager firing a Grade 0.
        Target.Functions.SetJob('unemployed', 0)
        TriggerClientEvent('ox_lib:notify', src, {title = 'Fired', description = 'You fired '..Target.PlayerData.charinfo.firstname, type = 'success'})
        TriggerClientEvent('ox_lib:notify', targetId, {title = 'Fired', description = 'You were fired.', type = 'error'})
    else
        TriggerClientEvent('ox_lib:notify', src, {title = 'Error', description = 'Player not found (must be online)', type = 'error'})
    end

end)

RegisterNetEvent('rsg-ranch:server:promoteEmployee', function(targetId, newGrade)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local Target = RSGCore.Functions.GetPlayer(targetId)
    
    if not Player or not Target then return end
    
    local myGrade = Player.PlayerData.job.grade.level
    local targetGrade = Target.PlayerData.job.grade.level

    -- Only Boss (2) should be promoting people to Manager (1) or higher.
    -- Manager (1) technically manages distinct lower ranks. If there's only 0, they can't promote.
    -- If there were ranks 0.5, they could. But usually it's 0, 1, 2.
    -- User: "only boss can fire manager same goes for promoting" -> Only boss can promote TO manager.
    
    if myGrade < 2 then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Access Denied', description = 'Only Boss can promote/demote.', type = 'error'})
        return
    end

    -- Boss can do whatever they want.
    local ranchId = Player.PlayerData.job.name
    Target.Functions.SetJob(ranchId, newGrade)
    
    TriggerClientEvent('ox_lib:notify', src, {title = 'Promoted/Demoted', description = 'Set grade to '..newGrade, type = 'success'})
    TriggerClientEvent('ox_lib:notify', targetId, {title = 'Job Update', description = 'Your position was updated to grade '..newGrade, type = 'success'})
end)

RegisterNetEvent('rsg-ranch:server:openStorage', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local jobName = Player.PlayerData.job.name
    local stashName = 'ranch_' .. jobName
    
    if GetResourceState('ox_inventory') == 'started' then
        exports.ox_inventory:forceOpenInventory(src, 'stash', stashName)
    else
        -- Fallback for rsg-inventory (triggered from server to ensure sync)
        TriggerClientEvent("rsg-inventory:client:SetCurrentStash", src, stashName)
        TriggerClientEvent("inventory:client:OpenInventory", src, "stash", stashName, {
            maxweight = 4000000,
            slots = 50,
        })
    end
end)

RSGCore.Functions.CreateCallback('rsg-ranch:server:getRanchData', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return cb(nil) end
    local ranchId = Player.PlayerData.job.name
    
    local funds = oxmysql:scalarSync('SELECT funds FROM rsg_ranch_funds WHERE ranchid = ?', {ranchId}) or 0
    local animalCount = oxmysql:scalarSync('SELECT COUNT(*) FROM rsg_ranch_animals WHERE ranchid = ?', {ranchId}) or 0
    local employees = 0 
    
    cb({
        funds = funds,
        animals = animalCount,
        employees = employees
    })
end)
RSGCore.Functions.CreateCallback('rsg-ranch:server:getOwnedAnimals', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return cb({}) end
    local ranchId = Player.PlayerData.job.name
    
    oxmysql:query('SELECT * FROM rsg_ranch_animals WHERE ranchid = ?', {ranchId}, function(result)
        cb(result)
    end)
end)
