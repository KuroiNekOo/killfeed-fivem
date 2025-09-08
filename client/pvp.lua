print("^2[Killfeed] ^7Module PvP chargé")

-- Variables spécifiques au PvP
local pvpThread = nil
local isPvPActive = false

-- Fonction pour mettre à jour les données d'un joueur (PvP)
function UpdatePlayerData(playerId, serverId, ped)
    if not DoesEntityExist(ped) then
        return
    end
    
    local currentHealth = GetEntityHealth(ped)
    local currentPos = GetEntityCoords(ped)
    
    if not _G.playerData[serverId] then
        _G.playerData[serverId] = {}
    end
    
    local lastHealth = _G.playerData[serverId].health or GetEntityMaxHealth(ped)
    
    -- Détecter mort
    if currentHealth <= 0 and lastHealth > 0 then
        print(string.format("^3[Killfeed] ^7Mort PvP détectée: joueur %d", serverId))
        
        -- Délai pour stabilisation des données de mort
        Citizen.SetTimeout(Config.DeathStabilizationDelay, function()
            ProcessPlayerDeath(playerId, nil, "pvp")
        end)
    end
    
    -- Mettre à jour les données
    _G.playerData[serverId].health = currentHealth
    _G.playerData[serverId].position = currentPos
    _G.playerData[serverId].lastUpdate = GetGameTimer()
end

-- Thread de monitoring PvP
function StartPvPMonitoring()
    if isPvPActive then
        print("^3[Killfeed] ^7Monitoring PvP déjà actif")
        return
    end
    
    isPvPActive = true
    print("^2[Killfeed] ^7Monitoring PvP activé")
    
    pvpThread = Citizen.CreateThread(function()
        while isPvPActive and Config.EnablePvP do
            local playerCount = 0
            
            -- Scanner tous les joueurs connectés
            for i = 0, 255 do
                if NetworkIsPlayerConnected(i) then
                    local playerPed = GetPlayerPed(i)
                    local serverId = GetPlayerServerId(i)
                    
                    if playerPed and DoesEntityExist(playerPed) then
                        UpdatePlayerData(i, serverId, playerPed)
                        playerCount = playerCount + 1
                    end
                end
            end
            
            Citizen.Wait(Config.MonitoringInterval)
        end
        
        print("^3[Killfeed] ^7Thread PvP terminé")
        isPvPActive = false
    end)
end

-- Fonction pour arrêter le monitoring PvP
function StopPvPMonitoring()
    if not isPvPActive then
        return
    end
    
    isPvPActive = false
    print("^3[Killfeed] ^7Arrêt du monitoring PvP...")
    
    -- Attendre que le thread se termine
    Citizen.Wait(1500)
    pvpThread = nil
    print("^3[Killfeed] ^7Monitoring PvP arrêté")
end

RegisterCommand('killfeed_restart_pvp', function()
    print("^2[Killfeed] ^7Redémarrage PvP...")
    StopPvPMonitoring()
    if Config.EnablePvP then
        StartPvPMonitoring()
    end
end, false)

-- Initialisation automatique du PvP si activé dans la config
Citizen.CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Citizen.Wait(100)
    end
    
    Citizen.Wait(2000) -- Attendre la stabilité
    
    if Config.EnablePvP then
        StartPvPMonitoring()
    end
end)