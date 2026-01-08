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
    TriggerServerEvent('rsg-ranch:server:spawnRanchAnimals')
    cb('ok')
end)

RegisterNUICallback('craftItem', function(data, cb)
    local item = data.item
    local amount = data.amount
    
    RSGCore.Functions.TriggerCallback('rsg-ranch:server:canCraft', function(canCraft)
        if canCraft then
            -- Find recipe for details
            local recipe = nil
            for _, r in ipairs(Config.CraftingRecipes) do
                if r.item == item then
                    recipe = r
                    break
                end
            end
            
            if recipe then
                local label = recipe.label or item
                local time = recipe.time or 5000
                local animDict = recipe.animDict or 'mech_inventory@crafting@fallbacks'
                local animName = recipe.animName or 'full_craft_and_stow'
                
                -- Adjust time for amount (optional, but realistic)
                local totalTime = time * amount
                
                RSGCore.Functions.Progressbar("crafting_ranch", "Crafting " .. label, totalTime, false, true, {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                }, {
                    animDict = animDict,
                    anim = animName,
                    flags = 1,
                }, {}, {}, function() -- Done
                    TriggerServerEvent('rsg-ranch:server:craftItem', item, amount)
                end, function() -- Cancel
                    lib.notify({title = 'Canceled', description = 'Crafting canceled.', type = 'error'})
                end)
            else
                TriggerServerEvent('rsg-ranch:server:craftItem', item, amount) -- Fallback
            end
        else
             lib.notify({title = 'Missing Ingredients', description = 'You do not have the required items.', type = 'error'})
        end
    end, item, amount)
    
    cb('ok')
end)

RegisterNUICallback('withdrawPrompt', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    local input = lib.inputDialog('Withdraw Funds', {'Amount'})
    if input and input[1] then
        TriggerServerEvent('rsg-ranch:server:withdrawFunds', tonumber(input[1]))
    end
    cb('ok')
end)

RegisterNUICallback('depositPrompt', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    local input = lib.inputDialog('Deposit Funds', {'Amount'})
    if input and input[1] then
        TriggerServerEvent('rsg-ranch:server:depositFunds', tonumber(input[1]))
    end
    cb('ok')
end)

RegisterNUICallback('manageStaff', function(data, cb)
    RSGCore.Functions.TriggerCallback('rsg-ranch:server:getNearbyPlayers', function(players)
        SetNuiFocus(true, true) -- Ensure cursor stays
        SendNUIMessage({
            action = "openHireMenu",
            players = players
        })
    end)
    cb('ok')
end)

RegisterNUICallback('confirmHire', function(data, cb)
    TriggerServerEvent('rsg-ranch:server:hireEmployee', data.id)
    cb('ok')
end)

RegisterNUICallback('confirmPromote', function(data, cb)
    TriggerServerEvent('rsg-ranch:server:promoteEmployee', data.id, data.grade)
    SetTimeout(500, function()
        RSGCore.Functions.TriggerCallback('rsg-ranch:server:getEmployees', function(employees)
            SendNUIMessage({
                action = "openEmployeeList",
                employees = employees
            })
        end)
    end)
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


-- RANCH TABLE LOGIC
local placedObjects = {}

RegisterNetEvent('rsg-ranch:client:syncObjects', function(objects)
    -- Cleanup old
    for _, obj in pairs(placedObjects) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    placedObjects = {}

    for _, data in ipairs(objects) do
        local coords = json.decode(data.coords)
        local model = GetHashKey(data.model)
        
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(10) end
        
        local obj = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
        SetEntityHeading(obj, coords.w) -- or heading if w stored
        FreezeEntityPosition(obj, true)
        PlaceObjectOnGroundProperly(obj)
        
        table.insert(placedObjects, obj)
        
        -- Add Target
        exports.ox_target:addLocalEntity(obj, {
            {
                name = 'ranch_crafting',
                icon = 'fa-solid fa-hammer',
                label = 'Open Crafting',
                onSelect = function()
                     if not HasAnyRanchJob() then
                         lib.notify({type='error', description='Only ranchers can use this.'})
                         return
                     end
                     -- Retrieve recipes and open UI
                     SetNuiFocus(true, true)
                     SendNUIMessage({
                         action = "openCrafting",
                         recipes = Config.CraftingRecipes
                     })
                end
            },
            {
                name = 'remove_ranch_table',
                icon = 'fa-solid fa-trash',
                label = 'Remove Table',
                onSelect = function()
                    local input = lib.inputDialog('Remove Table?', {
                        {type = 'checkbox', label = 'Confirm Removal', checked = false}
                    })
                    if input and input[1] then
                        TriggerServerEvent('rsg-ranch:server:removeRanchTable')
                    end
                end,
                canInteract = function()
                    local PlayerData = RSGCore.Functions.GetPlayerData()
                    return PlayerData.job.grade.level >= 3 -- Manager/Boss
                end
            }
        })
    end
end)

RegisterNUICallback('placeTable', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    
    RSGCore.Functions.TriggerCallback('rsg-ranch:server:hasTable', function(hasTable)
        if hasTable then
            lib.notify({type='error', description='Your ranch already has a table.'})
            return
        end
        
        -- Start Placement Mode
        local modelHash = GetHashKey('p_table04x')
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do Wait(10) end
        
        local vehicle = CreateObject(modelHash, 0, 0, 0, false, false, false)
        SetEntityAlpha(vehicle, 150, false)
        SetEntityCollision(vehicle, false, false)
        
        local placing = true
        local currentHeading = GetEntityHeading(PlayerPedId())
        
        CreateThread(function()
            while placing do
                Wait(0)
                local hit, coords = RayCastGamePlayCamera(20.0)
                
                -- Rotation Logic
                if IsControlPressed(0, 0xDEB34313) then -- Arrow Left (?) or use 0xA65EB6BA
                     currentHeading = currentHeading + 1.0
                end
                if IsControlPressed(0, 0x9D2AEA88) then -- Arrow Right
                     currentHeading = currentHeading - 1.0
                end
                -- Scroll Wheel Support (Optional, but good)
                
                SetEntityCoords(vehicle, coords.x, coords.y, coords.z)
                SetEntityHeading(vehicle, currentHeading)
                PlaceObjectOnGroundProperly(vehicle)
                
                lib.showTextUI('[E] Place  [Arrows] Rotate  [Backspace] Cancel')
                
                if IsControlJustPressed(0, 0xCEFD9220) then -- 'E'
                    placing = false
                    local finalCoords = GetEntityCoords(vehicle)
                    local finalHeading = GetEntityHeading(vehicle)
                    DeleteEntity(vehicle)
                    lib.hideTextUI()
                    
                    TriggerServerEvent('rsg-ranch:server:placeRanchTable', {
                        model = 'p_table04x',
                        coords = {x=finalCoords.x, y=finalCoords.y, z=finalCoords.z, w=finalHeading}
                    })
                end
                
                if IsControlJustPressed(0, 0x156F7119) then -- Backspace / Cancel
                    placing = false
                    DeleteEntity(vehicle)
                    lib.hideTextUI()
                end 
            end
        end)
    end)
    cb('ok')
end)

function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return b, c, e
end

function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    for _, obj in pairs(placedObjects) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
end)

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('rsg-ranch:server:loadRanchObjects')
end)



RegisterNUICallback('manageEmployees', function(data, cb)
    print('[Ranch System] manageEmployees NUI triggered, requesting server data...')
    RSGCore.Functions.TriggerCallback('rsg-ranch:server:getEmployees', function(employees)
        print('[Ranch System] Received employee list: ' .. (employees and #employees or 'nil'))
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "openEmployeeList",
            employees = employees
        })
    end)
    cb('ok')
end)

RegisterNUICallback('confirmFire', function(data, cb)
    TriggerServerEvent('rsg-ranch:server:fireEmployee', data)
    -- Refresh list after short delay
    SetTimeout(500, function()
        RSGCore.Functions.TriggerCallback('rsg-ranch:server:getEmployees', function(employees)
            SendNUIMessage({
                action = "openEmployeeList",
                employees = employees
            })
        end)
    end)
    cb('ok')
end)



RegisterNUICallback('openStorage', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    Wait(100)
    TriggerServerEvent('rsg-ranch:server:openStorage')
    cb('ok')
end)

RegisterNUICallback('renameAnimal', function(data, cb)
    TriggerServerEvent('rsg-ranch:server:renameAnimal', data)
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

-- Manure Collection Logic
CreateThread(function()
    for i, coords in ipairs(Config.ManureLocations) do
        exports.ox_target:addSphereZone({
            coords = coords,
            radius = 2.0,
            debug = false,
            options = {
                {
                    name = 'collect_manure_' .. i,
                    icon = 'fa-solid fa-poop',
                    label = 'Collect Manure',
                    onSelect = function()
                        local hasShovel = RSGCore.Functions.HasItem('shovel')
                        if not hasShovel then
                            lib.notify({title = 'Missing Item', description = 'You need a shovel to dig manure!', type = 'error'})
                            return
                        end

                        if lib.progressBar({
                            duration = 5000,
                            label = 'Collecting Manure...',
                            useWhileDead = false,
                            canCancel = true,
                            disable = {
                                car = true,
                                move = true,
                                combat = true,
                            },
                            anim = {
                                dict = 'amb_work@world_human_gravedig@working@male_b@base',
                                clip = 'base',
                                flag = 1,
                            },
                        }) then
                            TriggerServerEvent('rsg-ranch:server:collectManure')
                        else
                            lib.notify({title = 'Canceled', description = 'Collection canceled.', type = 'error'})
                        end
                    end
                }
            }
        })
    end
end)

