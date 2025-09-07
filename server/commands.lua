print("^2[Killfeed] ^7Module Commands chargé")

-- Commande de test (version sécurisée)
RegisterCommand('testkill', function(source, args)
    if source == 0 then
        print("^1[Killfeed] ^7Cette commande ne peut pas être exécutée depuis la console serveur")
        return
    end
    
    print("^2[Killfeed] ^7Commande testkill exécutée par: " .. tostring(source))
    
    local isHeadshot = math.random(1, 2) == 1  -- 50% de chance
    local distance = math.random(50, 300)      -- Distance aléatoire
    
    print(string.format("^2[Killfeed] ^7Test: headshot=%s, distance=%d", 
        tostring(isHeadshot), distance))
    
    TriggerEvent('killfeed:playerKilled', source, source, isHeadshot, distance)
end, false)

-- Commande pour tester l'ID Discord d'un joueur
RegisterCommand('checkdiscord', function(source, args)
    if source == 0 then
        print("^1[Killfeed] ^7Cette commande nécessite un joueur connecté")
        return
    end
    
    local targetId = tonumber(args[1]) or source
    
    -- Valider l'ID du joueur cible
    if not targetId or targetId < 1 then
        print("^1[Killfeed] ^7ID joueur invalide: " .. tostring(args[1] or "nil"))
        return
    end
    
    -- Vérifier que le joueur existe
    if not GetPlayerName(targetId) then
        print("^1[Killfeed] ^7Joueur inexistant: " .. tostring(targetId))
        return
    end
    
    local discordId = GetPlayerDiscordId(targetId)
    
    if discordId then
        print(string.format("^2[Killfeed] ^7Joueur %d = Discord ID: %s", targetId, discordId))
        
        GetDiscordName(targetId, function(discordName)
            print(string.format("^2[Killfeed] ^7Nom Discord: %s", discordName))
        end)
    else
        print(string.format("^1[Killfeed] ^7Pas d'ID Discord pour le joueur: %d", targetId))
    end
end, false)

-- Commande pour vérifier le kill streak d'un joueur
RegisterCommand('killstreak', function(source, args)
    if source == 0 then
        print("^1[Killfeed] ^7Cette commande nécessite un joueur connecté")
        return
    end
    
    local targetId = tonumber(args[1]) or source
    
    -- Valider l'ID du joueur cible
    if not targetId or targetId < 1 then
        print("^1[Killfeed] ^7ID joueur invalide: " .. tostring(args[1] or "nil"))
        return
    end
    
    -- Vérifier que le joueur existe
    if not GetPlayerName(targetId) then
        print("^1[Killfeed] ^7Joueur inexistant: " .. tostring(targetId))
        return
    end
    
    local streak = GetPlayerKillStreak(targetId)
    print(string.format("^2[Killfeed] ^7Kill streak du joueur %d: %d", targetId, streak))
end, false)

-- Commande pour réinitialiser le kill streak d'un joueur (admin)
RegisterCommand('resetstreak', function(source, args)
    -- Cette commande peut être exécutée depuis la console (admin serveur)
    local targetId = tonumber(args[1])
    
    -- Si pas d'argument et exécuté par un joueur, utiliser le joueur courant
    if not targetId and source > 0 then
        targetId = source
    end
    
    -- Valider l'ID du joueur cible
    if not targetId or targetId < 1 then
        print("^1[Killfeed] ^7Usage: resetstreak [playerid]")
        print("^1[Killfeed] ^7ID joueur requis depuis la console serveur")
        return
    end
    
    -- Vérifier que le joueur existe (si pas console)
    if source > 0 and not GetPlayerName(targetId) then
        print("^1[Killfeed] ^7Joueur inexistant: " .. tostring(targetId))
        return
    end
    
    ResetPlayerKillStreak(targetId)
    print(string.format("^2[Killfeed] ^7Kill streak réinitialisé pour le joueur: %d", targetId))
end, false)

-- Commande pour vérifier l'état du cache Discord (admin)
RegisterCommand('cacheinfo', function(source, args)
    local cacheCount, expiredCount = GetCacheStats()
    
    print(string.format("^2[Killfeed] ^7Cache Discord: %d entrées (%d expirées)", cacheCount, expiredCount))
    print(string.format("^2[Killfeed] ^7TTL configuré: %d ms (%.1f minutes)", Config.Discord.CacheTTL, Config.Discord.CacheTTL / 60000))
end, false)

-- Commande pour forcer le nettoyage du cache
RegisterCommand('clearcache', function(source, args)
    CleanExpiredCache()

    print("^2[Killfeed] ^7Nettoyage manuel du cache effectué")
end, false)

-- Commande pour vider complètement le cache
RegisterCommand('flushcache', function(source, args)
    ResetCacheTimestamps()
    
    print("^2[Killfeed] ^7Cache Discord complètement vidé")
end, false)