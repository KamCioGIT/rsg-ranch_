local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterNetEvent('rsg-ranch:server:attemptCraft', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local item = data.item
    local amount = tonumber(data.amount) or 1

    local recipe = nil
    for _, r in ipairs(Config.CraftingRecipes) do
        if r.item == item then recipe = r break end
    end

    if not recipe then return end

    local hasIngredients = true
    local missingItems = ""

    for _, ingredient in ipairs(recipe.ingredients) do
        local requiredAmount = ingredient.amount * amount
        local pItem = Player.Functions.GetItemByName(ingredient.item)
        local count = pItem and pItem.amount or 0
        
        if count < requiredAmount then
            hasIngredients = false
            local label = RSGCore.Shared.Items[ingredient.item] and RSGCore.Shared.Items[ingredient.item].label or ingredient.item
            missingItems = missingItems .. label .. " "
        end
    end

    if hasIngredients then
        TriggerClientEvent('rsg-ranch:client:playCraftAnim', src, {item = item, amount = amount})
    else
        TriggerClientEvent('ox_lib:notify', src, {title = 'Missing Ingredients', description = 'You need: ' .. missingItems, type = 'error'})
    end
end)

RegisterNetEvent('rsg-ranch:server:finishCraft', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local item = data.item
    local amount = tonumber(data.amount) or 1

    local recipe = nil
    for _, r in ipairs(Config.CraftingRecipes) do
        if r.item == item then recipe = r break end
    end

    if not recipe then return end

    -- Re-verify ingredients before taking action
    local hasIngredients = true
    for _, ingredient in ipairs(recipe.ingredients) do
        local requiredAmount = ingredient.amount * amount
        local pItem = Player.Functions.GetItemByName(ingredient.item)
        if not pItem or pItem.amount < requiredAmount then
            hasIngredients = false
        end
    end

    if hasIngredients then
        for _, ingredient in ipairs(recipe.ingredients) do
            Player.Functions.RemoveItem(ingredient.item, ingredient.amount * amount)
        end
        Player.Functions.AddItem(recipe.item, amount)
        TriggerClientEvent('ox_lib:notify', src, {title = 'Crafting Complete', description = 'You crafted ' .. amount .. 'x ' .. recipe.label, type = 'success'})
    else
        -- Exploit attempt or drop/use during anim
        TriggerClientEvent('ox_lib:notify', src, {title = 'Error', description = 'Ingredients unavailable.', type = 'error'})
    end
end)
