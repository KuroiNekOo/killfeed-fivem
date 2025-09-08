print("^2[Killfeed] ^7Serveur démarré")

-- Event principal : Détection d'un kill (version sécurisée avec validation renforcée)
RegisterNetEvent('killfeed:playerKilled', function(killerId, victimId, isHeadshot, distance)
    -- Obtenir la source de l'événement (qui l'a envoyé)
    local source = source
    
    print(string.format("^1[DEBUG SERVER] ^7EVENT REÇU de client %s: killer=%s, victim=%s, headshot=%s, distance=%.1f",
        tostring(source), tostring(killerId), tostring(victimId), tostring(isHeadshot), tonumber(distance) or 0.0))
    
    print(string.format("^2[Killfeed] ^7Kill reçu de client %s: killer=%s, victim=%s, headshot=%s, distance=%.1f",
        tostring(source), tostring(killerId), tostring(victimId), tostring(isHeadshot), tonumber(distance) or 0.0))
    
    -- Vérifications de sécurité avancées
    if not killerId or not victimId then
        print("^1[Killfeed] ^7Erreur: IDs manquants")
        return
    end
    
    -- Vérifier que le tueur existe
    if not GetPlayerName(killerId) then
        print("^1[Killfeed] ^7Erreur: Tueur inexistant (ID: " .. tostring(killerId) .. ")")
        return
    end
    
    -- Vérifier la victime (avec exception pour les PNJ en PvE)
    local isPvEKill = victimId >= 9999 -- IDs 9999+ = PNJ fictifs
    if not isPvEKill and not GetPlayerName(victimId) then
        print("^1[Killfeed] ^7Erreur: Victime joueur inexistante (ID: " .. tostring(victimId) .. ")")
        return
    end
    
    -- Log pour identifier le type de kill
    if isPvEKill then
        print(string.format("^2[Killfeed] ^7Kill PvE détecté: joueur %d vs PNJ (ID fictif: %d)", killerId, victimId))
    else
        print(string.format("^2[Killfeed] ^7Kill PvP détecté: joueur %d vs joueur %d", killerId, victimId))
    end
    
    -- Éviter les kills invalides (suicides, etc.)
    -- if killerId == victimId then
    --     print("^3[Killfeed] ^7Suicide ignoré (ID: " .. tostring(killerId) .. ")")
    --     return
    -- end
    
    -- Valider la distance (entre 0 et 1000m max)
    distance = tonumber(distance) or 0
    if distance < 0 or distance > 1000 then
        print("^3[Killfeed] ^7Distance suspecte ajustée: " .. tostring(distance) .. "m")
        distance = math.max(0, math.min(distance, 1000))
    end
    
    -- Valider headshot (boolean)
    isHeadshot = isHeadshot == true or isHeadshot == "true"
    
    -- Calculer les données du kill
    local killData = CalculateKillData(killerId, victimId, isHeadshot, distance)
    
    print("^2[Killfeed] ^7Données calculées, récupération nom Discord...")
    
    -- Récupérer le nom Discord de la victime
    -- GetDiscordName(victimId, function(discordName)
    --     print("^2[Killfeed] ^7Nom Discord récupéré: " .. tostring(discordName))
        
    --     killData.victim = discordName
    --     killData.killer = GetPlayerName(killerId) or ("Joueur#" .. killerId)
        
    --     -- Envoyer à tous les clients pour affichage
    --     -- L'argument (-1) = Déclencher l'event pour TOUS les clients
    --     print(string.format("^1[DEBUG SERVER] ^7Envoi TriggerClientEvent killfeed:showKill à tous les clients"))
    --     print(string.format("^1[DEBUG SERVER] ^7Données: killer=%s, victim=%s, points=%d", 
    --         killData.killer, killData.victim, killData.totalPoints))
        
    --     TriggerClientEvent('killfeed:showKill', -1, killData)
        
    --     print(string.format("^3[Killfeed] ^7%s a tué %s (%d points)", 
    --         killData.killer, killData.victim, killData.totalPoints))
    -- end)

    killData.killer = GetPlayerName(killerId) or ("Joueur#" .. killerId)

    killData.victim = isPvEKill and ("PNJ#" .. victimId) or (Player(victimId).state.discordName or GetPlayerName(victimId) or ("Joueur#" .. victimId))

    TriggerClientEvent('killfeed:showKill', -1, killData)
end)

-- Event à ajouter pour pré-charger le nom Discord à la connexion
AddEventHandler('playerJoining', function()
    local source = source

    -- Récupérer le nom Discord et le stocker
    GetDiscordName(source, function(discordName)
        Player(source).state.discordName = discordName
        print("^2[Killfeed] ^7Discord statebag défini pour " .. source .. ": " .. discordName)
    end)
end)