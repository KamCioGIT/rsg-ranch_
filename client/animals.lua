local RSGCore = exports['rsg-core']:GetCoreObject()
local SpawnManager = {}
local animalDataCache = {}
local spawnedMap = {}

function SpawnManager:Initialize()
    -- Port full spawn manager logic here
end

function SpawnManager:SpawnAnimal(animalId, animalData)
    Citizen.CreateThread(function()
        -- Prevent duplicates: Check if already spawned
        if spawnedMap[animalId] and DoesEntityExist(spawnedMap[animalId]) then
            DeletePed(spawnedMap[animalId])
        end

        local modelName = animalData.model
        local model = GetHashKey(modelName)
        
        if not IsModelInCdimage(model) then
            print("[Ranch System] Error: Invalid model " .. tostring(modelName))
            return
        end

        RequestModel(model)
        local timeout = 0
        while not HasModelLoaded(model) do 
            Wait(10) 
            timeout = timeout + 1
            if timeout > 500 then -- 5 second timeout
                print("[Ranch System] Error: Timeout loading model " .. tostring(modelName))
                return
            end
        end
        
        -- Use x, y, z from data
        local ped = CreatePed(model, animalData.pos_x, animalData.pos_y, animalData.pos_z, animalData.pos_w or 0.0, true, true, 0, 0)
        
        if not DoesEntityExist(ped) then
            print("[Ranch System] Error: Failed to create ped for animal " .. animalId)
            return
        end

        spawnedMap[animalId] = ped -- Track entity
        SetEntityAsMissionEntity(ped, true, true)
        SetEntityInvincible(ped, false)
        SetEntityCanBeDamaged(ped, true)
        
        -- Force visibility loop
        for i=1, 5 do
            SetEntityVisible(ped, true)
            SetEntityAlpha(ped, 255, false)
            Citizen.InvokeNative(0x283978A15512B2FE, ped, true) -- SetRandomOutfitVariation
            Wait(50)
        end
        PlaceObjectOnGroundProperly(ped)
        
        -- Prevent fleeing (Stronger overrides)
        SetPedFleeAttributes(ped, 0, 0)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedRelationshipGroupHash(ped, GetHashKey("REL_CIVAMIMAL"))
        SetPedConfigFlag(ped, 294, false) -- Disable shocking events
        SetPedConfigFlag(ped, 301, false) -- Disable seeing shocked events
        
        -- Apply Scale (Growth)
        local scale = tonumber(animalData.scale) or 1.0
        SetPedScale(ped, scale)
        
        -- Wandering
        if Config.AnimalWanderingEnabled then
            TaskWanderStandard(ped, 10.0, 10)
        end

        -- Re-add target (moved to separate function or here)
        SetupAnimalTarget(ped, animalId, animalData)
        
        print("[Ranch System] Spawned animal " .. animalId .. " (" .. modelName .. ")")
    end)
end

function SetupAnimalTarget(ped, animalId, animalData)
    -- Add ox_target interactions (Refactored for clarity)
    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'feed_animal',
            icon = 'fa-solid fa-wheat',
            label = 'Feed Animal',
            onSelect = function()
                RSGCore.Functions.TriggerCallback('rsg-ranch:server:hasFeed', function(hasItem)
                    if not hasItem then
                        lib.notify({title = 'Feeding Failed', description = 'You need Animal Feed to do this.', type = 'error'})
                        return
                    end

                    Citizen.CreateThread(function()
                        local playerPed = PlayerPedId()
                        
                        -- Force clear any previous tasks
                        ClearPedTasksImmediately(playerPed)
                        SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true)
                        Wait(200)

                        -- Use Native Scenario
                        TaskStartScenarioInPlace(playerPed, GetHashKey('WORLD_HUMAN_BUCKET_POUR_LOW'), -1, true, false, false, false)
                        
                        -- Custom UI
                        SendNUIMessage({
                            action = "openProgressBar",
                            duration = 5000,
                            label = "Feeding Animal..."
                        })
                        
                        -- Wait and Disable Controls
                        local endTime = GetGameTimer() + 5000
                        while GetGameTimer() < endTime do
                            DisableAllControlActions(0)
                            EnableControlAction(0, 1, true) -- Look LR
                            EnableControlAction(0, 2, true) -- Look UD
                            Wait(0)
                        end

                        -- Properly Clear Task
                        ClearPedTasks(playerPed) 
                        Wait(100) -- Small buffer
                        ClearPedTasks(playerPed) -- Double tap to ensure prop drop

                        TriggerServerEvent('rsg-ranch:server:feedAnimal', animalId)
                    end)
                end)
            end
        },
        {
            name = 'animal_stay',
            icon = 'fa-solid fa-hand',
            label = 'Stay / Freeze',
            onSelect = function()
                ClearPedTasks(ped)
                FreezeEntityPosition(ped, true)
                lib.notify({title = 'Animal Status', description = 'Animal is staying put.', type = 'inform'})
            end
        },
        {
             name = 'animal_calm',
             icon = 'fa-solid fa-face-smile',
             label = 'Calm Down',
             onSelect = function()
                 ClearPedTasks(ped)
                 TaskStandStill(ped, -1)
                 lib.notify({title = 'Animal Status', description = 'You calmed the animal.', type = 'success'})
             end
        },
        {
            name = 'animal_follow',
            icon = 'fa-solid fa-walking',
            label = 'Follow Me',
            onSelect = function()
                local playerPed = PlayerPedId()
                FreezeEntityPosition(ped, false)
                ClearPedTasks(ped)
                -- Follow approx 2m behind
                TaskFollowToOffsetOfEntity(ped, playerPed, 0.0, -2.0, 0.0, 1.5, -1, 2.0, 1)
                lib.notify({title = 'Animal Status', description = 'Animal is following you.', type = 'success'})
            end
        },
        {
             name = 'animal_wander',
             icon = 'fa-solid fa-shuffle',
             label = 'Wander',
             onSelect = function()
                 FreezeEntityPosition(ped, false)
                 TaskWanderStandard(ped, 10.0, 10)
                 lib.notify({title = 'Animal Status', description = 'Animal is roaming free.', type = 'inform'})
             end
        },
        {
            name = 'animal_despawn',
            icon = 'fa-solid fa-house-chimney',
            label = 'Send to Barn',
            onSelect = function()
                DeleteEntity(ped)
                spawnedMap[animalId] = nil
                TriggerServerEvent('rsg-ranch:server:despawnAnimal', animalId)
                lib.notify({title = 'Ranch', description = 'Animal returned to barn.', type = 'inform'})
            end
        },
        {
            name = 'check_animal',
            icon = 'fa-solid fa-info-circle',
            label = 'Check Status',
            onSelect = function()
                RSGCore.Functions.TriggerCallback('rsg-ranch:server:getNextGrowth', function(nextTime)
                    -- Use fresh data from cache
                    local freshData = animalData
                    for _, a in ipairs(animalDataCache) do
                        if a.animalid == animalId then
                            freshData = a
                            break
                        end
                    end

                    SetNuiFocus(true, true)
                    SendNUIMessage({
                        action = "openAnimalStatus",
                        status = {
                            health = freshData.health or 100,
                            hunger = freshData.hunger or 100,
                            age = freshData.age or 0,
                            gender = freshData.gender or 'female',
                            nextGrowth = ((tonumber(freshData.scale) or 1.0) >= (Config.Growth.DefaultMaxScale or 1.0)) and "Fully Grown" or nextTime
                        }
                    })
                end)
            end
        }
    })
end

-- Death Check Loop
CreateThread(function()
    while true do
        Wait(2000)
        for id, ped in pairs(spawnedMap) do
            if DoesEntityExist(ped) and IsEntityDead(ped) then
                TriggerServerEvent('rsg-ranch:server:animalDied', id)
                DeleteEntity(ped) -- Despawn immediately
                spawnedMap[id] = nil 
            end
        end
    end
end)

RegisterNetEvent('rsg-ranch:client:spawnAnimals', function(animals)
    animalDataCache = animals
    for _, animal in ipairs(animals) do
        if spawnedMap[animal.animalid] and DoesEntityExist(spawnedMap[animal.animalid]) then
             -- Update existing scale dynamically
             local ped = spawnedMap[animal.animalid]
             local scale = tonumber(animal.scale) or 1.0
             SetPedScale(ped, scale)
             
             -- Also update hunger/etc in local data if needed (handled by cache update above)
        else
             SpawnManager:SpawnAnimal(animal.animalid, animal)
        end
    end
end)

-- Signal to refresh data
RegisterNetEvent('rsg-ranch:client:refreshAnimals', function()
    TriggerServerEvent('rsg-ranch:server:refreshAnimals')
end)

-- On player load, request animals
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('rsg-ranch:server:refreshAnimals')
end)

-- Helper for commands
local function GetClosestRanchAnimal()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local closestDist = 50.0 
    local closestAnimal = nil
    
    local handle, animal = FindFirstPed()
    local success = false
    repeat
        local pos = GetEntityCoords(animal)
        local dist = #(coords - pos)
        if dist < closestDist and animal ~= ped and not IsPedAPlayer(animal) and not IsPedHuman(animal) then
            closestDist = dist
            closestAnimal = animal
        end
        success, animal = FindNextPed(handle)
    until not success
    EndFindPed(handle)
    
    return closestAnimal
end

RegisterCommand('rfollow', function()
    local animal = GetClosestRanchAnimal()
    if animal then
         local playerPed = PlayerPedId()
         FreezeEntityPosition(animal, false)
         ClearPedTasks(animal)
         TaskFollowToOffsetOfEntity(animal, playerPed, 0.0, -2.0, 0.0, 1.5, -1, 2.0, 1)
         lib.notify({description = 'Animal following.', type = 'success'})
    else
         lib.notify({description = 'No animal nearby.', type = 'error'})
    end
end)

RegisterCommand('rstay', function()
    local animal = GetClosestRanchAnimal()
    if animal then
         ClearPedTasks(animal)
         FreezeEntityPosition(animal, true)
         lib.notify({description = 'Animal staying.', type = 'inform'})
    else
         lib.notify({description = 'No animal nearby.', type = 'error'})
    end
end)

RegisterCommand('rwander', function()
    local animal = GetClosestRanchAnimal()
    if animal then
         FreezeEntityPosition(animal, false)
         TaskWanderStandard(animal, 10.0, 10)
         lib.notify({description = 'Animal wandering.', type = 'inform'})
    else
         lib.notify({description = 'No animal nearby.', type = 'error'})
    end
end)

-- Cleanup on stop (added)
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    for _, ped in pairs(spawnedMap) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
end)

-- Debug Command to check Animation Dictionaries
RegisterCommand('checkanim', function()
    local animDicts = {
        -- Confirmed Baseline
        "amb_work@world_human_farmer_weeding@male_a@idle_a",
        
        -- New Candidates to Test
        "amb_work@world_human_farmer_rake@male_a@idle_a",
        "amb_work@world_human_grain_sack@male_a@idle_a", 
        "amb_work@world_human_hay_bale@male_a@idle_a",
        "mech_pickup@plant@farming",
        "amb_work@prop_human_lay_feed@male_a@idle_a",  
        "amb_camp@world_camp_jack_es_feeding_horse@idle_a",
        
        -- Bucket / Water Related
        "amb_work@world_human_bucket_pour@male_a@idle_a",
        "amb_rest@world_human_wash_face_bucket@male_a@idle_a",
        
        -- Interaction / Pickup
        "mech_pickup@p_bale_hay_01x",
        "mech_inventory@item@fall",
        
        -- General Work
        "amb_work@world_human_broom@male_a@idle_a",
        "amb_work@world_human_shovel_coal@male_a@idle_a",
        
        -- Script specific (might be invalid but worth a shot if updated)
        "script_re@fertilizer@pour", 
        "script_common@bucket@pour",
        "script_common@bucket_pour"
    }

    print("---[ Checking Animation Dictionaries ]---")
    
    Citizen.CreateThread(function()
        for _, dict in ipairs(animDicts) do
            if not HasAnimDictLoaded(dict) then
                RequestAnimDict(dict)
                local timeout = 0
                while not HasAnimDictLoaded(dict) and timeout < 50 do -- 0.5s timeout per anim to check existence
                    Wait(10)
                    timeout = timeout + 1
                end
            end
            
            if HasAnimDictLoaded(dict) then
                print("[VALID]   " .. dict)
            else
                print("[INVALID] " .. dict)
            end
        end
        print("---[ Done ]---")
    end)
end)
