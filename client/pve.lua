print("^2[Killfeed] ^7Module PvE chargé")

-- Variables spécifiques au PvE
local pveThread = nil
local isPvEActive = false

-- Fonction pour monitorer les PNJ à proximité (PvE)
function MonitorNearbyNPCs()
    if not Config.EnablePvE then
        return
    end
    
    -- Récupération de la position du joueur
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    
    -- Scanner les PNJ dans un rayon de 100m
    local nearbyPeds = GetGamePool('CPed')
    
    for _, npcPed in ipairs(nearbyPeds) do
        if DoesEntityExist(npcPed) and npcPed ~= playerPed and not IsPedAPlayer(npcPed) then
            local npcPos = GetEntityCoords(npcPed)
            local distance = CalculateDistance(playerPos, npcPos)
            
            -- Seulement monitorer les PNJ proches pour éviter la surcharge
            if distance <= 100 then
                local npcId = tostring(npcPed) -- Utiliser l'entity ID comme clé
                local currentHealth = GetEntityHealth(npcPed)
                
                if not _G.npcData[npcId] then
                    _G.npcData[npcId] = {
                        ped = npcPed,
                        health = currentHealth,
                        lastUpdate = GetGameTimer()
                    }
                else
                    local lastHealth = _G.npcData[npcId].health
                    
                    -- Détecter mort du PNJ
                    if currentHealth <= 0 and lastHealth > 0 then
                        print(string.format("^3[Killfeed] ^7Mort PvE détectée: PNJ %s", npcId))
                        
                        -- Délai pour stabilisation
                        Citizen.SetTimeout(KILLFEED_SHARED.DEATH_STABILIZATION_DELAY, function()
                            -- Créer un faux playerId pour ProcessPlayerDeath
                            local fakePlayerId = -1 -- ID spécial pour PNJ
                            print(string.format("^1[DEBUG] ^7Appel ProcessPlayerDeath pour PNJ: playerId=%d, npcPed=%s", 
                                fakePlayerId, tostring(npcPed)))
                            ProcessPlayerDeath(fakePlayerId, npcPed, "pve")
                        end)
                    end
                    
                    -- Mettre à jour les données
                    _G.npcData[npcId].health = currentHealth
                    _G.npcData[npcId].lastUpdate = GetGameTimer()
                end
            end
        end
    end
    
    -- Nettoyer les PNJ morts ou datés
    local currentTime = GetGameTimer()
    for npcId, data in pairs(_G.npcData) do
        if not DoesEntityExist(data.ped) or (currentTime - data.lastUpdate) > 10000 then
            _G.npcData[npcId] = nil
        end
    end
end

-- Thread de monitoring PvE
function StartPvEMonitoring()
    if isPvEActive then
        print("^3[Killfeed] ^7Monitoring PvE déjà actif")
        return
    end
    
    isPvEActive = true
    print("^2[Killfeed] ^7Monitoring PvE activé")
    
    pveThread = Citizen.CreateThread(function()
        while isPvEActive and Config.EnablePvE do
            -- Monitorer les PNJ pour les tests PvE
            MonitorNearbyNPCs()
            
            Citizen.Wait(KILLFEED_SHARED.MONITORING_INTERVAL)
        end
        
        print("^3[Killfeed] ^7Thread PvE terminé")
        isPvEActive = false
    end)
end

-- Fonction pour arrêter le monitoring PvE
function StopPvEMonitoring()
    if not isPvEActive then
        return
    end
    
    isPvEActive = false
    print("^3[Killfeed] ^7Arrêt du monitoring PvE...")
    
    -- Attendre que le thread se termine
    Citizen.Wait(1500)
    pveThread = nil
    print("^3[Killfeed] ^7Monitoring PvE arrêté")
end

RegisterCommand('killfeed_restart_pve', function()
    print("^2[Killfeed] ^7Redémarrage PvE...")
    StopPvEMonitoring()
    if Config.EnablePvE then
        StartPvEMonitoring()
    end
end, false)

-- Initialisation automatique du PvE si activé dans la config
Citizen.CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Citizen.Wait(100)
    end
    
    Citizen.Wait(2500) -- Attendre un peu plus longtemps que le PvP pour éviter la surcharge
    
    if Config.EnablePvE then
        StartPvEMonitoring()
    end
end)