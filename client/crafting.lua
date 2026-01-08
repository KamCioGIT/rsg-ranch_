local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterNetEvent('rsg-ranch:client:playCraftAnim', function(data)
    local item = data.item
    local amount = data.amount
    local recipe = nil
    for _, r in ipairs(Config.CraftingRecipes) do
        if r.item == item then recipe = r break end
    end
    
    if not recipe then return end
    
    local ped = PlayerPedId()
    local dict = recipe.animDict or "mech_inventory@crafting@fallbacks"
    local name = recipe.animName or "full_craft_and_stow"
    local time = recipe.time or 5000
    
    RSGCore.Functions.Progressbar("craft_ranch", "Crafting " .. recipe.label, time, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = dict,
        anim = name,
        flags = 16,
    }, {}, {}, function() -- Done
        TriggerServerEvent('rsg-ranch:server:finishCraft', {item = item, amount = amount})
    end, function() -- Cancel
        TriggerEvent('ox_lib:notify', {title = 'Canceled', type = 'error'})
    end)
end)
