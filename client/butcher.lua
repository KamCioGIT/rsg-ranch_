local RSGCore = exports['rsg-core']:GetCoreObject()
local points = {}



-- Load Anim Dict
-- Load Anim Dict
local function loadAnimDict(dict)
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) do
        Wait(10)
        timeout = timeout + 1
        if timeout > 500 then
            print("[RSG-RANCH] Warning: Animation dictionary failed to load: " .. tostring(dict))
            return false 
        end
    end
    return true
end

-- Helper to check valid ranch jobs
local function isRancher(jobName)
    if not jobName then return false end
    if jobName == 'rancher' then return true end
    for _, ranch in pairs(Config.RanchLocations) do
        if jobName == ranch.jobaccess then return true end
    end
    return false
end

local butcherBlips = {}

local function updateButcherBlips()
    -- Clear existing
    for _, blip in ipairs(butcherBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    butcherBlips = {}

    local Player = RSGCore.Functions.GetPlayerData()
    if not Player or not Player.job then return end
    
    if isRancher(Player.job.name) then
        for _, tableData in ipairs(Config.ButcherTables) do
            local blip = N_0x554d9d53f696d002(1664425300, tableData.coords.x, tableData.coords.y, tableData.coords.z)
            SetBlipSprite(blip, 'blip_ambient_butcher', 1) -- Butcher sprite
            SetBlipScale(blip, 0.2)
            N_0x9cb1a1623062f402(blip, "Butcher Table")
            table.insert(butcherBlips, blip)
        end
    end
end

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    updateButcherBlips()
end)

RegisterNetEvent('RSGCore:Client:OnJobUpdate', function(JobInfo)
    Wait(1000)
    updateButcherBlips()
end)

AddEventHandler('onResourceStart', function(resource)
   if resource == GetCurrentResourceName() then
       Wait(1000)
       updateButcherBlips()
   end
end)

-- Spawn Tables (using lib.points for optimization and collision safety)
CreateThread(function()
    for i, data in ipairs(Config.ButcherTables) do
        local point = lib.points.new({
            coords = vector3(data.coords.x, data.coords.y, data.coords.z),
            distance = 50, -- Spawn distance
        })

        function point:onEnter()
            local model = Config.ButcherProp
            RequestModel(model)
            while not HasModelLoaded(model) do Wait(10) end
            
            -- Checks if the object already exists to prevent duplicates
            local existing = GetClosestObjectOfType(self.coords.x, self.coords.y, self.coords.z, 2.0, model, false, false, false)
            if existing == 0 then
                print("[RSG-RANCH] Spawning butcher table at " .. self.coords)
                local obj = CreateObject(model, self.coords.x, self.coords.y, self.coords.z, false, false, false)
                SetEntityHeading(obj, data.coords.w)
                SetEntityAlpha(obj, 255, false)
                PlaceObjectOnGroundProperly(obj)
                -- Give physics a moment to update position before freezing
                Wait(500) 
                FreezeEntityPosition(obj, true)
                self.spawnedObj = obj
                print("[RSG-RANCH] Table spawned. Entity: " .. obj)
            else
                print("[RSG-RANCH] Table already exists at " .. self.coords)
                self.spawnedObj = existing
            end
        end

        function point:onExit()
            if self.spawnedObj and DoesEntityExist(self.spawnedObj) then
                DeleteEntity(self.spawnedObj)
                self.spawnedObj = nil
            end
        end
        
        table.insert(points, point)
    end
end)

-- Command to spawn a table locally and print coords
RegisterCommand('newranchtable', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local forward = GetEntityForwardVector(ped)
    
    -- Spawn in front of player
    local spawnPos = coords + (forward * 1.5)
    
    local model = Config.ButcherProp
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    
    local obj = CreateObject(model, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false)
    SetEntityHeading(obj, heading + 180.0) -- Face player
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    
    local finalCoords = GetEntityCoords(obj)
    local finalH = GetEntityHeading(obj)
    
    local printStr = string.format("{ coords = vector4(%0.2f, %0.2f, %0.2f, %0.2f) },", finalCoords.x, finalCoords.y, finalCoords.z, finalH)
    print("--- NEW BUTCHER TABLE ---")
    print(printStr)
    print("-------------------------")
    
    lib.notify({title = 'Table Spawned', description = 'Check F8 for coordinates to save.', type = 'success'})
end)

RegisterCommand('getcord', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    -- Format: { coords = vector4(x, y, z, h) },
    local printStr = string.format("{ coords = vector4(%0.2f, %0.2f, %0.2f, %0.2f) },", coords.x, coords.y, coords.z, heading)
    
    print("--- RANCH COORDS ---")
    print(printStr)
    print("--------------------")
    
    lib.notify({title = 'Coords Copied', description = 'Check F8 Console for the code snippet.', type = 'success'})
end)

-- Target Interaction
CreateThread(function()
    local options = {}
    
    -- Generate an option for each carcass type
    -- Generate an option for each carcass type
    print(" [RSG-RANCH] Registering butcher target options for model: " .. Config.ButcherProp)
    local options = {}

    -- Debug command to check job (verify if you are rancher)
    RegisterCommand('myjob', function()
        local job = RSGCore.Functions.GetPlayerData().job
        print("Your Job: " .. (job and job.name or "nil") .. " | Grade: " .. (job and job.grade.level or "nil"))
        lib.notify({description = "Job: " .. (job and job.name or "Unknown"), type = 'inform'})
    end)
    
    -- (isRancher moved to top)

    for carcassName, rewards in pairs(Config.ButcherRewards) do
        table.insert(options, {
            name = 'butcher_' .. carcassName,
            icon = 'fa-solid fa-drumstick-bite',
            label = 'Butcher ' .. RSGCore.Shared.Items[carcassName].label,
            onSelect = function()
                TriggerEvent('rsg-ranch:client:butcherCarcass', carcassName)
            end,
            canInteract = function()
                local Player = RSGCore.Functions.GetPlayerData()
                if not Player or not Player.job then return false end
                return isRancher(Player.job.name) and RSGCore.Functions.HasItem(carcassName)
            end
        })
    end
    
    -- Crafting Option
    table.insert(options, {
        name = 'ranch_crafting',
        icon = 'fa-solid fa-screwdriver-wrench',
        label = 'Ranch Crafting',
        onSelect = function()
            TriggerEvent('rsg-ranch:client:openCraftingMenu')
        end,
        canInteract = function()
            local Player = RSGCore.Functions.GetPlayerData()
            if not Player or not Player.job then return false end
            return isRancher(Player.job.name)
        end
    })
    
    -- Register target for the butcher table model
    exports.ox_target:addModel(GetHashKey(Config.ButcherProp), options)
end)

RegisterNetEvent('rsg-ranch:client:butcherCarcass', function(carcassName)
    print(" [RSG-RANCH] Butcher event triggered for: " .. tostring(carcassName))
    local ped = PlayerPedId()
    
    -- Using Scenarios as they are the most reliable way to trigger complex actions
    -- WORLD_HUMAN_BUTCHER_WORK is the standard butcher interaction
    local scenarioName = "WORLD_HUMAN_BUTCHER_WORK" 
    
    print(" [RSG-RANCH] Starting scenario: " .. scenarioName)
    ClearPedTasks(ped) -- Clear any previous tasks first
    TaskStartScenarioInPlace(ped, scenarioName, 0, true)
    
    print(" [RSG-RANCH] Starting progress bar...")
    if lib.progressBar({
        duration = 5000,
        label = 'Butchering carcass...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            mouse = false,
            combat = true,
        },
    }) then
        ClearPedTasks(ped)
        TriggerServerEvent('rsg-ranch:server:processCarcass', carcassName)
    else
        ClearPedTasks(ped)
        lib.notify({description = 'Cancelled', type = 'error'})
    end
end)

RegisterNetEvent('rsg-ranch:client:openCraftingMenu', function()
    local recipes = {}
    
    -- Prepare recipes with resolved ingredient labels
    for _, r in ipairs(Config.CraftingRecipes) do
        local ingredients = {}
        for _, ing in ipairs(r.ingredients) do
            local itemInfo = RSGCore.Shared.Items[ing.item]
            table.insert(ingredients, {
                item = ing.item,
                amount = ing.amount,
                label = itemInfo and itemInfo.label or ing.item
            })
        end
        
        table.insert(recipes, {
            item = r.item,
            label = r.label,
            ingredients = ingredients,
            time = r.time
        })
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openCrafting",
        recipes = recipes
    })
end)

RegisterNUICallback('craftItem', function(data, cb)
    local item = data.item
    local amount = tonumber(data.amount) or 1
    print("[RSG-RANCH-DEBUG] Crafting requested for: " .. tostring(item) .. " x" .. amount)
    TriggerServerEvent('rsg-ranch:server:attemptCraft', {item = item, amount = amount})
    cb('ok')
end)

RegisterNetEvent('rsg-ranch:client:playCraftAnim', function(data)
    local item = data.item
    local amount = data.amount or 1

    -- Find recipe
    local recipe = nil
    for _, r in ipairs(Config.CraftingRecipes) do
        if r.item == item then recipe = r break end
    end

    if not recipe then return end

    local ped = PlayerPedId()
    local totalTime = recipe.time * amount -- Scale time by amount
    
    if recipe.animDict and recipe.animName then
        if loadAnimDict(recipe.animDict) then
            TaskPlayAnim(ped, recipe.animDict, recipe.animName, 8.0, -8.0, totalTime, 1, 0, false, false, false)
        else
            -- Fallback if load fails
            TaskStartScenarioInPlace(ped, "WORLD_HUMAN_HAMMER_TABLE", 0, true)
        end
    elseif recipe.scenario then
        TaskStartScenarioInPlace(ped, recipe.scenario, 0, true)
    else
        -- Fallback scenario
        TaskStartScenarioInPlace(ped, "WORLD_HUMAN_HAMMER_TABLE", 0, true)
    end
    
    -- Freeze player to ensure animation plays fully
    FreezeEntityPosition(ped, true)
    
    -- Use Custom NUI Progress Bar
    SendNUIMessage({
        action = 'openProgressBar',
        duration = totalTime,
        label = 'Crafting ' .. amount .. 'x ' .. recipe.label .. '...'
    })

    -- Wait for the duration of the craft
    Wait(totalTime)
    
    -- Cleanup
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    TriggerServerEvent('rsg-ranch:server:finishCraft', {item = item, amount = amount})
end)

-- Cleanup props
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    for _, point in ipairs(points) do
        if point.spawnedObj and DoesEntityExist(point.spawnedObj) then
            DeleteEntity(point.spawnedObj)
        end
    end
end)
