ESX = exports['es_extended']:getSharedObject()

RegisterServerEvent("adminmenu:checkPermission")
AddEventHandler("adminmenu:checkPermission", function()
    local src = source
    local ids = GetPlayerIdentifiers(src)
    local isAdmin = false

    for _, id in pairs(ids) do
        for _, adminID in pairs(Config.AdminList) do
            if id == adminID then
                isAdmin = true
                break
            end
        end
    end

    if isAdmin then
        TriggerClientEvent("adminmenu:open", src)
    else
        TriggerClientEvent("esx:showNotification", src, "No tienes permisos.")
    end
end)

RegisterServerEvent("adminmenu:getPlayers")
AddEventHandler("adminmenu:getPlayers", function(action)
    local src = source
    local players = {}

    for _, playerId in ipairs(GetPlayers()) do
        local name = GetPlayerName(playerId)
        players[playerId] = { name = name }
    end

    TriggerClientEvent("adminmenu:selectPlayer", src, players, action)
end)

RegisterServerEvent("adminmenu:actionOnPlayer")
AddEventHandler("adminmenu:actionOnPlayer", function(targetId, action)
    local src = source
    if action == "kill" then
        TriggerClientEvent("adminmenu:killPlayer", targetId)
        TriggerClientEvent("esx:showNotification", src, "Has matado a " .. GetPlayerName(targetId))
    elseif action == "spectate" then
        TriggerClientEvent("adminmenu:spectatePlayer", src, targetId)
    elseif action == "heal" then
        TriggerClientEvent("esx_ambulancejob:revive", targetId)
        TriggerClientEvent("esx:showNotification", src, "Has curado a " .. GetPlayerName(targetId))
    elseif action == "warn" then
        TriggerClientEvent("esx:showNotification", targetId, "¡Has sido advertido por un administrador!")
        TriggerClientEvent("esx:showNotification", src, "Has advertido a " .. GetPlayerName(targetId))
    elseif action == "setPermissions" then
        TriggerClientEvent("esx:showNotification", src, "Permisos asignados a " .. GetPlayerName(targetId))
    end
end)


RegisterServerEvent("adminmenu:kickPlayer")
AddEventHandler("adminmenu:kickPlayer", function(targetId, reason)
    local src = source
    DropPlayer(targetId, "Has sido kickeado por un administrador.\nMotivo: " .. reason)
end)

RegisterNetEvent("adminmenu:broadcast")
AddEventHandler("adminmenu:broadcast", function(message)
    local src = source
    TriggerClientEvent("adminmenu:showBroadcast", -1, message)
end)
