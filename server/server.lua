print("^2[Killfeed] ^7Serveur démarré")


-- Event principal : Détection d'un kill (version sécurisée)
RegisterNetEvent('killfeed:playerKilled')
AddEventHandler('killfeed:playerKilled', function(killerId, victimId, isHeadshot, distance)
    -- Vérifier si l'ID du tueur et de la victime sont valides
    print(string.format("^2[Killfeed] ^7Début traitement kill: killer=%s, victim=%s",
        tostring(killerId), tostring(victimId)))
    
    -- Vérifications de sécurité
    if not killerId or not victimId then
        print("^1[Killfeed] ^7Erreur: IDs manquants")
        return
    end
    
    -- Calculer les données du kill
    local killData = CalculateKillData(killerId, victimId, isHeadshot, distance)
    
    print("^2[Killfeed] ^7Données calculées, récupération nom Discord...")
    
    -- Récupérer le nom Discord de la victime
    GetDiscordName(victimId, function(discordName)
        print("^2[Killfeed] ^7Nom Discord récupéré: " .. tostring(discordName))
        
        killData.victim = discordName
        killData.killer = GetPlayerName(killerId) or ("Joueur#" .. killerId)
        
        -- Envoyer à tous les clients pour affichage
        -- L'argument (-1) = Déclencher l'event pour TOUS les clients
        TriggerClientEvent('killfeed:showKill', -1, killData)
        
        print(string.format("^3[Killfeed] ^7%s a tué %s (%d points)", 
            killData.killer, killData.victim, killData.totalPoints))
    end)
end)

