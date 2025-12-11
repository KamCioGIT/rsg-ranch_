local RSGCore = exports['rsg-core']:GetCoreObject()
local spawnedPeds = {}


local function spawnPed(model, coords, heading)
    local hash
    if type(model) == "number" then
        hash = model
    else
        hash = GetHashKey(model)
    end
    
    if not IsModelInCdimage(hash) then
        -- print("[Ranch System] Error: Model not found in CD image: " .. tostring(model))
        return nil
    end

    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) do
        Wait(10)
        timeout = timeout + 1
        if timeout > 500 then -- 5 seconds timeout
            -- print("[Ranch System] Error: Timed out loading model: " .. tostring(model))
            return nil
        end
    end

    local ped = CreatePed(hash, coords.x, coords.y, coords.z - 1.0, heading, false, false, 0, 0)
    SetEntityHeading(ped, heading)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityVisible(ped, true)
    SetEntityAlpha(ped, 255, false)
    SetRandomOutfitVariation(ped, true)
    PlaceObjectOnGroundProperly(ped) -- Helper to snap to ground if Z is slightly off
    -- print("[Ranch System] Spawned NPC at " .. coords.x .. ", " .. coords.y .. ", " .. coords.z)
    return ped
end


local function HasAnyRanchJob()
    local PlayerData = RSGCore.Functions.GetPlayerData()
    if not PlayerData or not PlayerData.job then return false end
    
    for _, ranch in ipairs(Config.RanchLocations) do
        if ranch.jobaccess == PlayerData.job.name then
            return true
        end
    end
    return false
end


local function HasSpecificRanchJob(jobName)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    if not PlayerData or not PlayerData.job then return false end
    return PlayerData.job.name == jobName
end


CreateThread(function()
    -- Buy and Sell Points (Merged)
    for _, location in ipairs(Config.BuyPointLocations) do
        local ped = spawnPed(location.npcmodel, vector3(location.npccoords.x, location.npccoords.y, location.npccoords.z), location.npccoords.w)
        if ped then
            table.insert(spawnedPeds, ped)

            -- Blip
            if location.showblip then
                local blip = N_0x554d9d53f696d002(1664425300, location.coords.x, location.coords.y, location.coords.z)
                SetBlipSprite(blip, location.blipsprite, 1)
                SetBlipScale(blip, location.blipscale)
                N_0x9cb1a1623062f402(blip, location.blipname)
            end

            -- Target
            exports.ox_target:addLocalEntity(ped, {
                {
                    name = 'open_buy_menu',
                    icon = 'fa-solid fa-cow',
                    label = 'Buy Livestock',
                    onSelect = function()
                        if not HasAnyRanchJob() then
                            lib.notify({title = 'Access Denied', description = 'Only ranchers can buy livestock.', type = 'error'})
                            return
                        end
                        SetNuiFocus(true, true)
                        SendNUIMessage({
                            action = "openBuyMenu",
                            items = Config.AnimalsToBuy
                        })
                    end,
                    canInteract = function()
                        return HasAnyRanchJob()
                    end
                },
                {
                    name = 'open_sell_menu',
                    icon = 'fa-solid fa-sack-dollar',
                    label = 'Sell Livestock',
                    onSelect = function()
                        RSGCore.Functions.TriggerCallback('rsg-ranch:server:getOwnedAnimals', function(animals)
                            if not animals then animals = {} end
                            -- Format for NUI
                            local sellItems = {}
                            for _, animal in ipairs(animals) do
                                -- Calculate Dynamic Price (Match Server Logic)
                                local model = animal.model
                                local scale = tonumber(animal.scale) or Config.Growth.DefaultStartScale
                                
                                -- Find Buy Price
                                local buyPrice = 0
                                for _, item in ipairs(Config.AnimalsToBuy) do
                                    if item.model == model then
                                        buyPrice = item.price
                                        break
                                    end
                                end
                                
                                -- Get Max Sell Price
                                local maxSellPrice = Config.BaseSellPrices and Config.BaseSellPrices[model] or (buyPrice * 2)
                                
                                -- Calculate Progress
                                local startScale = Config.Growth.DefaultStartScale
                                local maxScale = Config.Growth.DefaultMaxScale
                                local progress = (scale - startScale) / (maxScale - startScale)
                                if progress < 0 then progress = 0 end
                                if progress > 1 then progress = 1 end
                                
                                local startValue = buyPrice * 0.6
                                local currentPrice = math.floor(startValue + ((maxSellPrice - startValue) * progress))

                                table.insert(sellItems, {
                                    id = animal.animalid,
                                    label = animal.model, -- You might want a prettier label map
                                    price = currentPrice,
                                    age = animal.age or 0,
                                    model = animal.model
                                })
                            end
                            SetNuiFocus(true, true)
                            SendNUIMessage({
                                action = "openSellMenu",
                                items = sellItems
                            })
                        end)
                    end,
                    canInteract = function()
                        return HasAnyRanchJob()
                    end
                }
            })
        end
    end

    -- Ranch Locations (Boss Menu)
    for _, location in ipairs(Config.RanchLocations) do
        local ped = spawnPed(location.npcmodel, vector3(location.npccoords.x, location.npccoords.y, location.npccoords.z), location.npccoords.w)
        if ped then
            table.insert(spawnedPeds, ped)

            if location.showblip then
                local blip = N_0x554d9d53f696d002(1664425300, location.coords.x, location.coords.y, location.coords.z)
                SetBlipSprite(blip, location.blipsprite, 1)
                SetBlipScale(blip, location.blipscale)
                N_0x9cb1a1623062f402(blip, location.blipname)
            end

            exports.ox_target:addLocalEntity(ped, {
                {
                    name = 'open_ranch_menu',
                    icon = 'fa-solid fa-book',
                    label = 'Manage Ranch',
                    onSelect = function()
                        if not HasSpecificRanchJob(location.jobaccess) then
                             lib.notify({title = 'Access Denied', description = 'You do not work at this ranch.', type = 'error'})
                             return
                        end
                        RSGCore.Functions.TriggerCallback('rsg-ranch:server:getRanchData', function(result)
                            if not result then 
                                result = {
                                    name = location.name,
                                    funds = 0,
                                    employees = 0,
                                    animals = 0
                                }
                            else
                                -- Merge name from config
                                result.name = location.name
                            end
                            
                            SetNuiFocus(true, true)
                            SendNUIMessage({
                                action = "openBossMenu",
                                ranchData = result
                            })
                        end)
                    end,
                    canInteract = function()
                        return HasSpecificRanchJob(location.jobaccess)
                    end
                }
            })
        end
    end
end)


RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('buyItem', function(data, cb)
    TriggerServerEvent('rsg-ranch:server:buyItem', data)
    cb('ok')
end)

RegisterNUICallback('sellItem', function(data, cb)
    TriggerServerEvent('rsg-ranch:server:sellItem', data)
    cb('ok')
end)

RegisterNUICallback('spawnAnimals', function(data, cb)
    -- print('[Ranch System] DEBUG: NUI spawnAnimals triggered')
    TriggerServerEvent('rsg-ranch:server:spawnRanchAnimals')
    cb('ok')
end)

RegisterNUICallback('withdrawPrompt', function(data, cb)
    SetNuiFocus(false, false)
    local input = lib.inputDialog('Withdraw Funds', {'Amount'})
    if input and input[1] then
        TriggerServerEvent('rsg-ranch:server:withdrawFunds', tonumber(input[1]))
    end
    cb('ok')
end)

RegisterNUICallback('depositPrompt', function(data, cb)
    SetNuiFocus(false, false)
    local input = lib.inputDialog('Deposit Funds', {'Amount'})
    if input and input[1] then
        TriggerServerEvent('rsg-ranch:server:depositFunds', tonumber(input[1]))
    end
    cb('ok')
end)



RegisterNUICallback('getLivestock', function(data, cb)
    -- print('[Ranch System] DEBUG: NUI getLivestock triggered')
    -- Fetch owned animals reuse existing callback
    RSGCore.Functions.TriggerCallback('rsg-ranch:server:getOwnedAnimals', function(result)
        -- print('[Ranch System] DEBUG: getOwnedAnimals callback returned '..(result and #result or 0)..' animals')
        SendNUIMessage({
            action = "openLivestockMenu",
            items = result
        })
    end)
    cb('ok')
end)

RegisterNUICallback('spawnSpecific', function(data, cb)
    -- print('[Ranch System] DEBUG: NUI spawnSpecific triggered with ID: ' .. tostring(data.id))
    TriggerServerEvent('rsg-ranch:server:spawnSpecificAnimal', data.id)
    cb('ok')
end)

RegisterNUICallback('manageStaff', function(data, cb)
    SetNuiFocus(false, false)
    local input = lib.inputDialog('Hire New Staff', {'Player ID'})
    if input and input[1] then
        TriggerServerEvent('rsg-ranch:server:hireEmployee', tonumber(input[1]))
    end
    cb('ok')
end)

RegisterNUICallback('fireStaff', function(data, cb)
    SetNuiFocus(false, false)
    local input = lib.inputDialog('Fire Staff', {'Player ID'})
    if input and input[1] then
        TriggerServerEvent('rsg-ranch:server:fireEmployee', tonumber(input[1]))
    end
    cb('ok')
end)

RegisterNUICallback('promoteStaff', function(data, cb)
    SetNuiFocus(false, false)
    local input = lib.inputDialog('Promote Staff', {'Player ID', 'Grade (0-2)'})
    if input and input[1] and input[2] then
        TriggerServerEvent('rsg-ranch:server:promoteEmployee', tonumber(input[1]), tonumber(input[2]))
    end
    cb('ok')
end)

RegisterNUICallback('openStorage', function(data, cb)
    SetNuiFocus(false, false)
    Wait(100)
    TriggerServerEvent('rsg-ranch:server:openStorage')
    cb('ok')
end)


AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    -- Remove targets if needed (Ox Target usually cleans up on resource stop automatically for local entities, 
    -- but explicit removal is good practice if IDs were tracked, here we just kill the peds)
end)

