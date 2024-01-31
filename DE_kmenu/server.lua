local Lobbies = {}
local playerLobby = {}

RegisterNetEvent('DE_kmenu:createLobby')
AddEventHandler('DE_kmenu:createLobby', function(name, max, usingPW, password)
    table.insert(Lobbies, {
        lobbyName = name,
        maxPlayers = max,
        usingPassword = usingPW,
        password = password,
        totalPlayers = 0,
        owner = source,
    })
    JoinLobby(name)
end)

RegisterNetEvent('DE_kmenu:hubWorld')
AddEventHandler('DE_kmenu:hubWorld', function()
    if playerLobby[source] then
        for k, v in pairs(Lobbies) do
            if playerLobby[source] == v.lobbyName then
                v.totalPlayers -= 1
            end
        end
        playerLobby[source] = nil
        SetPlayerRoutingBucket(source, 0)
        TriggerClientEvent('ox_lib:notify', source, {type = 'inform', description = 'You have returned to the hub world.'})
    else
        TriggerClientEvent('ox_lib:notify', source, {type = 'error', description = 'You are not currently in a lobby.'})
    end
end)

RegisterNetEvent('DE_kmenu:joinLobby')
AddEventHandler('DE_kmenu:joinLobby', function(name)
    if playerLobby[source] ~= nil then
        for k, v in pairs(Lobbies) do
            if v.lobbyName == name and v.totalPlayers == v.maxPlayers then
                TriggerClientEvent('ox_lib:notify', source, {type = 'error', description = 'This lobby is already full.'})
                return
            end

            if playerLobby[source] == v.lobbyName and v.lobbyName ~= name then
                v.totalPlayers -= 1
            end
        end
    end
    
    JoinLobby(name)
end)

RegisterNetEvent('DE_kmenu:deleteLobby')
AddEventHandler('DE_kmenu:deleteLobby', function(name)
    if playerLobby[source] ~= nil then
        playerLobby[source] = nil
    end
    
    for k, v in pairs(Lobbies) do
        if v.lobbyName == name then
            table.remove(Lobbies, k)
        end
    end

    print(GetPlayerRoutingBucket(source))
    if GetPlayerRoutingBucket(source) ~= 0 then
        SetPlayerRoutingBucket(source, 0)
        TriggerClientEvent('ox_lib:notify', source, {type = 'inform', description = 'You have returned to the hub world.'})
    end
    print(GetPlayerRoutingBucket(source))
end)

lib.callback.register('DE_kmenu:getLobbies', function(source, cb)
    return Lobbies
end)

lib.callback.register('DE_kmenu:getOwnerLobby', function(source, cb)
    for k, v in pairs(Lobbies) do
        if v.owner == source then
            return v.lobbyName
        end
    end
end)

lib.callback.register('DE_kmenu:hasLobby', function(source, cb)
    for k,v in pairs(Lobbies) do
        if v.owner == source then
            return true
        end
    end

    return false
end)

JoinLobby = function(name)
    for k, v in pairs(Lobbies) do
        if v.lobbyName == name then
            if playerLobby[source] ~= v.lobbyName then
                playerLobby[source] = v.lobbyName
                v.totalPlayers += 1
                SetPlayerRoutingBucket(source, k)
                TriggerClientEvent('ox_lib:notify', source, {type = 'inform', description = 'You have successfully joined this lobby.'})
            else
                TriggerClientEvent('ox_lib:notify', source, {type = 'error', description = 'You are already in this lobby.'})
            end
            break 
        end
    end
end