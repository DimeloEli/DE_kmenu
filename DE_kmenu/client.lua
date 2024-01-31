local spawnedVehicle = nil

local spawnVehicle = function(vehicleModel, coords, heading, cb, networked)
    local model = type(vehicleModel) == 'number' and vehicleModel or joaat(vehicleModel)
    local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)
    networked = networked == nil and true or networked

    local playerCoords = GetEntityCoords(PlayerPedId())
    if not vector or not playerCoords then
        return
    end
    local dist = #(playerCoords - vector)
    if dist > 424 then
        return print("Tried to spawn vehicle on the client but the position is too far away (Out of onesync range).")
    end

    CreateThread(function()
        lib.requestModel(model)

        local vehicle = CreateVehicle(model, vector.xyz, heading, networked, true)

        if networked then
            local id = NetworkGetNetworkIdFromEntity(vehicle)
            SetNetworkIdCanMigrate(id, true)
            SetEntityAsMissionEntity(vehicle, true, true)
        end
        SetVehicleHasBeenOwnedByPlayer(vehicle, true)
        SetVehicleNeedsToBeHotwired(vehicle, false)
        SetModelAsNoLongerNeeded(model)
        SetVehRadioStation(vehicle, 'OFF')
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
        lib.notify({type = 'inform', title = 'Vehicle Spawner', description = 'You have successfully spawned a vehicle'})

        RequestCollisionAtCoord(vector.xyz)
        while not HasCollisionLoadedAroundEntity(vehicle) do
            Wait(0)
        end

        if cb then
            cb(vehicle)
        end

        spawnedVehicle = vehicle
    end)
end

RegisterCommand('kmenu', function(source, args, user)
    lib.registerMenu({
        id = 'shooting_menu',
        title = 'Shooting Menu',
        position = 'top-right',
        options = {
            {label = 'Heal', description = 'Heal yourself.', close = false},
            {label = 'Spawn Weapon', values = {'Pistol', 'Combat Pistol','SNS Pistol', 'Heavy Pistol', 'Vintage Pistol'}, description = 'Spawn yourself a weapon.', close = false},
            {label = 'Spawn Vehicle', values = {'BMX', 'Sultan', 'Asea', 'Buffalo'}, description = 'Spawn yourself a vehicle.', close = false},
            {label = 'Delete Vehicle', description = 'Delete a vehicle you spawned.', close = false},
            {label = 'Teleport', values = {'Grove Street', 'Ramps', 'Airport','Madrazo House', 'Sandy Airfield'}, description = 'Teleport to a POI on the map.', close = false},
            {label = 'Lobbies', description = 'Check lobby options.', close = true},
        }
    }, function(selected, scrollIndex, args)
        local playerPed = PlayerPedId()
        if selected == 1 then
            SetEntityHealth(playerPed, 200)
        elseif selected == 2 then
            if scrollIndex == 1 then
                GiveWeaponToPed(playerPed, 'WEAPON_PISTOL', 999, false, true)
            elseif scrollIndex == 2 then
                GiveWeaponToPed(playerPed, 'WEAPON_COMBATPISTOL', 999, false, true)
            elseif scrollIndex == 3 then
                GiveWeaponToPed(playerPed, 'WEAPON_SNSPISTOL', 999, false, true)
            elseif scrollIndex == 4 then
                GiveWeaponToPed(playerPed, 'WEAPON_HEAVYPISTOL', 999, false, true)
            elseif scrollIndex == 5 then
                GiveWeaponToPed(playerPed, 'WEAPON_VINTAGEPISTOL', 999, false, true)
            end
        elseif selected == 3 then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local playerHeading = GetEntityHeading(playerPed)

            if spawnedVehicle ~= nil then
                DeleteEntity(spawnedVehicle)
            end

            if scrollIndex == 1 then
                spawnVehicle('bmx', playerCoords, playerHeading)
            elseif scrollIndex == 2 then
                spawnVehicle('sultan', playerCoords, playerHeading)
            elseif scrollIndex == 3 then
                spawnVehicle('asea', playerCoords, playerHeading)
            elseif scrollIndex == 4 then
                spawnVehicle('buffalo', playerCoords, playerHeading)
            end
        elseif selected == 4 then
            if spawnedVehicle ~= nil then
                DeleteEntity(spawnedVehicle)
                spawnedVehicle = nil
                lib.notify({type = 'inform', description = 'You have successfully deleted your vehicle.'})
            else
                lib.notify({type = 'error', description = 'You dont have a vehicle out right now.'})
            end
        elseif selected == 5 then
            if scrollIndex == 1 then
                SetEntityCoords(playerPed, -19.7454, -1824.0524, 25.7625, 0.0, 0.0, 0.0, false)
            elseif scrollIndex == 2 then
                SetEntityCoords(playerPed, -958.1173, -778.8575, 17.8361, 0.0, 0.0, 0.0, false)
            elseif scrollIndex == 3 then
                SetEntityCoords(playerPed, -1257.0726, -3359.4731, 13.9450, 0.0, 0.0, 0.0, false)
            elseif scrollIndex == 4 then
                SetEntityCoords(playerPed, 1424.6688, 1118.0277, 114.4617, 0.0, 0.0, 0.0, false)
            elseif scrollIndex == 5 then
                SetEntityCoords(playerPed, 1737.4305, 3293.5427, 41.1633, 0.0, 0.0, 0.0, false)
            end
        elseif selected == 6 then
            lib.registerMenu({
                id = 'lobby_menu',
                title = 'Lobby Menu',
                position = 'top-right',
                options = {
                    {label = 'Create Lobby', description = 'Create a lobby in the server.', close = false},
                    {label = 'Join Lobby', description = 'Join a lobby in the server.', close = false},
                    {label = 'Delete Lobby', description = 'Delete a lobby you own in the server.', close = false},
                }
            }, function(selected, scrollIndex, args)
                if selected == 1 then
                    lib.callback('DE_kmenu:hasLobby', false, function(hasLobby)
                        if not hasLobby then
                            lib.hideMenu(false)
                            local input = lib.inputDialog('Create a Lobby', {
                                {type = 'input', label = 'Lobby name', required = true, min = 4, max = 24},
                                {type = 'number', label = 'Max players', icon = 'hashtag', required = true, min = 2, max = 8},
                                {type = 'checkbox', label = 'Use Password'},
                                {type = 'input', label = 'Password', min = 3, max = 24}
                            })
        
                            TriggerServerEvent('DE_kmenu:createLobby', input[1], input[2], input[3], input[4])
                        else
                            lib.notify({type = 'error', position = 'top', description = 'You already have a lobby made'})
                        end
                    end)
                elseif selected == 2 then
                    lib.callback('DE_kmenu:getLobbies', false, function(lobbyData)
                        local Options = {}
        
                        table.insert(Options, {
                            title = 'Return to Hub',
                            onSelect = function()
                                TriggerServerEvent('DE_kmenu:hubWorld')
                            end
                        })
                        for k, v in pairs(lobbyData) do
                            table.insert(Options, {
                                title = v.lobbyName,
                                description = v.totalPlayers .. '/' .. v.maxPlayers,
                                onSelect = function()
                                    if v.usingPassword then
                                        local pwInput = lib.inputDialog('Type in password', {
                                            {type = 'input', label = 'Lobby Password', required = true, min = 3, max = 24}
                                        })
        
                                        if pwInput[1] == v.password then
                                            TriggerServerEvent('DE_kmenu:joinLobby', v.lobbyName)
                                        else
                                            lib.notify({type = 'error', description = 'Wrong password.'})
                                        end
                                    else
                                        TriggerServerEvent('DE_kmenu:joinLobby', v.lobbyName)
                                    end
                                end,
                            })
                        end
        
                        if #Options > 1 then
                            lib.hideMenu(false)

                            lib.registerContext({
                                id = 'lobby_menu',
                                title = 'Lobbies',
                                options = Options,
                            })
        
                            lib.showContext('lobby_menu')
                        else
                            lib.notify({type = 'error', position = 'top', description = 'No lobbies are made at the moment.'})
                        end
                    end)
                elseif selected == 3 then
                    lib.callback('DE_kmenu:hasLobby', false, function(hasLobby)
                        if hasLobby then
                            lib.hideMenu(false)
                            lib.callback('DE_kmenu:getOwnerLobby', false, function(lobbyName)
                                TriggerServerEvent('DE_kmenu:deleteLobby', lobbyName)
                                lib.notify({type = 'inform', description = 'You have deleted your lobby.'})
                            end)
                        else
                            lib.notify({type = 'error', position = 'top', description = 'You dont have a lobby to delete.'})
                        end
                    end)
                end
            end)

            lib.showMenu('lobby_menu')
        end
    end)

    lib.showMenu('shooting_menu')
end)

RegisterKeyMapping('kmenu', 'Open Shooting Menu', 'keyboard', Config.Keybind)