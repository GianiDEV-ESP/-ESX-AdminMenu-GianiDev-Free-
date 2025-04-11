local isNoclip = false
local noclipSpeed = 1.5
local spectating = false
local spectateTarget = nil
local showTags = false

RegisterCommand("adminmenu", function()
    TriggerServerEvent("adminmenu:checkPermission")
end)

RegisterNetEvent("adminmenu:open", function(players)
    lib.registerContext({
        id = 'admin_menu',
        title = 'Menú de Administración',
        options = {
            {
                title = 'Ver Tags de Jugadores',
                icon = 'id-card',
                onSelect = function()
                    showTags = not showTags
                    lib.notify({
                        title = "Tags de Jugadores",
                        description = showTags and "Mostrando tags" or "Tags ocultos",
                        type = showTags and "success" or "info"
                    })
                end
            },
            {
                title = 'Activar/Desactivar NoClip',
                icon = 'plane',
                onSelect = function()
                    toggleNoclip()
                end
            },
            {
                title = 'Ver Jugadores',
                icon = 'eye',
                onSelect = function()
                    TriggerServerEvent("adminmenu:getPlayers", "ver")
                end
            },
            {
                title = 'Gestionar Jugadores',
                icon = 'user-cog',
                onSelect = function()
                    TriggerServerEvent("adminmenu:getPlayers", "acciones")
                end
            },
            {
                title = 'Enviar Anuncio General',
                icon = 'bullhorn',
                onSelect = function()
                    local input = lib.inputDialog("Anuncio General", {
                        {type = "input", label = "Mensaje para todos", placeholder = "Ejemplo: Reinicio en 5 minutos"}
                    })

                    if input and input[1] and input[1] ~= "" then
                        TriggerServerEvent("adminmenu:broadcast", input[1])
                    else
                        lib.notify({
                            title = "Anuncio cancelado",
                            description = "Debes escribir un mensaje para enviar.",
                            type = "error"
                        })
                    end
                end
            },
            {
                title = 'Sacar Vehículo',
                icon = 'car',
                onSelect = function()
                    local input = lib.inputDialog("Sacar Vehículo", {
                        {type = "input", label = "Hash del Vehículo", placeholder = "Ejemplo: adder"}
                    })

                    if input and input[1] and input[1] ~= "" then
                        spawnVehicle(input[1])
                    else
                        lib.notify({
                            title = "Error",
                            description = "Debes escribir un hash de vehículo válido.",
                            type = "error"
                        })
                    end
                end
            }
        }
    })
    lib.showContext('admin_menu')
end)

RegisterNetEvent("adminmenu:selectPlayer")
AddEventHandler("adminmenu:selectPlayer", function(players, action)
    local options = {}
    for k, v in pairs(players) do
        table.insert(options, {
            title = v.name .. " (ID: " .. k .. ")",
            icon = 'user',
            onSelect = function()
                if action == "acciones" then
                    openPlayerOptions(k, v.name)
                else
                    lib.notify({
                        title = "Jugador",
                        description = "ID: " .. k .. " | Nombre: " .. v.name,
                        type = "inform"
                    })
                end
            end
        })
    end

    lib.registerContext({
        id = 'select_player',
        title = action == "acciones" and "Selecciona un jugador" or "Jugadores Conectados",
        menu = 'admin_menu',
        options = options
    })
    lib.showContext('select_player')
end)

function openPlayerOptions(playerId, playerName)
    lib.registerContext({
        id = 'player_actions',
        title = "Acciones de " .. playerName,
        options = {
            {
                title = 'Matar',
                icon = 'times-circle',
                onSelect = function()
                    TriggerServerEvent("adminmenu:actionOnPlayer", playerId, "kill")
                end
            },
            {
                title = 'Espectear',
                icon = 'eye',
                onSelect = function()
                    TriggerServerEvent("adminmenu:actionOnPlayer", playerId, "spectate")
                end
            },
            {
                title = 'Curar',
                icon = 'heartbeat',
                onSelect = function()
                    TriggerServerEvent("adminmenu:actionOnPlayer", playerId, "heal")
                end
            },
            {
                title = 'Advertir',
                icon = 'exclamation-triangle',
                onSelect = function()
                    TriggerServerEvent("adminmenu:actionOnPlayer", playerId, "warn")
                end
            },
            {
                title = 'Poner Permisos',
                icon = 'shield-alt',
                onSelect = function()
                    TriggerServerEvent("adminmenu:actionOnPlayer", playerId, "setPermissions")
                end
            },
            {
                title = 'Kickear',
                icon = 'sign-out-alt',
                onSelect = function()
                    TriggerEvent("adminmenu:promptKick", playerId)
                end
            },
        }
    })
    lib.showContext('player_actions')
end

function toggleNoclip()
    isNoclip = not isNoclip
    local player = PlayerPedId()
    SetEntityInvincible(player, isNoclip)
    SetEntityVisible(player, not isNoclip, false)
    SetEntityCollision(player, not isNoclip, not isNoclip)

    if isNoclip then
        lib.notify({ title = "Admin", description = "NoClip activado", type = "success" })
        ShowNoclipHelp()
        CreateThread(NoclipLoop)
    else
        lib.notify({ title = "Admin", description = "NoClip desactivado", type = "info" })
    end
end

function ShowNoclipHelp()
    lib.alertDialog({
        header = "Controles NoClip",
        content = "W/A/S/D - Moverse\nQ/E - Subir/Bajar\nShift - Más rápido\nScroll - Cambiar velocidad",
        centered = true
    })
end

function NoclipLoop()
    while isNoclip do
        local player = PlayerPedId()
        local coords = GetEntityCoords(player)
        local heading = GetGameplayCamRot(2)
        local forward = GetEntityForwardVector(player)
        local right = vector3(-forward.y, forward.x, 0.0)
        local moveSpeed = noclipSpeed

        if IsControlPressed(0, 21) then moveSpeed = moveSpeed * 2.5 end
        if IsControlJustPressed(0, 15) then noclipSpeed = noclipSpeed + 0.5 end
        if IsControlJustPressed(0, 14) then noclipSpeed = math.max(0.5, noclipSpeed - 0.5) end

        local moveVec = vector3(0, 0, 0)
        if IsControlPressed(0, 32) then moveVec = moveVec + forward end
        if IsControlPressed(0, 33) then moveVec = moveVec - forward end
        if IsControlPressed(0, 34) then moveVec = moveVec - right end
        if IsControlPressed(0, 35) then moveVec = moveVec + right end
        if IsControlPressed(0, 44) then moveVec = moveVec + vector3(0, 0, 1.0) end
        if IsControlPressed(0, 38) then moveVec = moveVec - vector3(0, 0, 1.0) end

        local newCoords = coords + (moveVec * moveSpeed)
        SetEntityCoordsNoOffset(player, newCoords.x, newCoords.y, newCoords.z, true, true, true)
        SetEntityHeading(player, heading.z)
        Wait(0)
    end
end

RegisterNetEvent("adminmenu:killPlayer")
AddEventHandler("adminmenu:killPlayer", function()
    SetEntityHealth(PlayerPedId(), 0)
end)

RegisterNetEvent("adminmenu:spectatePlayer")
AddEventHandler("adminmenu:spectatePlayer", function(target)
    local playerPed = PlayerPedId()
    if not spectating then
        spectating = true
        spectateTarget = GetPlayerPed(GetPlayerFromServerId(target))
        SetEntityVisible(playerPed, false)
        SetEntityInvincible(playerPed, true)
        NetworkSetEntityInvisibleToNetwork(playerPed, true)
        NetworkSetInSpectatorMode(true, spectateTarget)
    else
        spectating = false
        spectateTarget = nil
        NetworkSetInSpectatorMode(false, playerPed)
        SetEntityVisible(playerPed, true)
        SetEntityInvincible(playerPed, false)
        NetworkSetEntityInvisibleToNetwork(playerPed, false)
    end
end)

RegisterNetEvent("adminmenu:promptKick")
AddEventHandler("adminmenu:promptKick", function(playerId)
    local input = lib.inputDialog("Kickear jugador", {
        {type = "input", label = "Motivo del Kick", placeholder = "Ejemplo: Comportamiento tóxico"}
    })

    if input and input[1] and input[1] ~= "" then
        TriggerServerEvent("adminmenu:kickPlayer", playerId, input[1])
    else
        lib.notify({
            title = "Kick cancelado",
            description = "Debes escribir un motivo para kickear.",
            type = "error"
        })
    end
end)

RegisterNetEvent("adminmenu:showBroadcast")
AddEventHandler("adminmenu:showBroadcast", function(msg)
    lib.notify({
        title = "Anuncio del Staff",
        description = msg,
        type = "inform",
        duration = 10000
    })
end)

function DrawTags()
    if showTags then
        for _, player in ipairs(GetActivePlayers()) do
            local playerPed = GetPlayerPed(player)
            if playerPed ~= PlayerPedId() then
                local playerName = GetPlayerName(player)
                local playerId = GetPlayerServerId(player)
                local coords = GetEntityCoords(playerPed)
                DrawText3D(coords.x, coords.y, coords.z + 1.0, playerName .. " (ID: " .. playerId .. ")")
            end
        end
    end
end

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(0)
        SetTextProportional(true)
        SetTextColour(255, 255, 255, 255)
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

function spawnVehicle(vehicleHash)
    local model = GetHashKey(vehicleHash)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(500)
    end

    local playerPed = PlayerPedId()
    local pos = GetEntityCoords(playerPed)
    local vehicle = CreateVehicle(model, pos.x, pos.y, pos.z, GetEntityHeading(playerPed), true, false)
    
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleNumberPlateText(vehicle, "BYADMIN") -- Asigna la matrícula
    SetModelAsNoLongerNeeded(model)
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
end

CreateThread(function()
    while true do
        Wait(0)
        DrawTags()
    end
end)
