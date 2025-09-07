print("^2[Killfeed] ^7Module Commands chargé")

-- Commande de test (version sécurisée)
RegisterCommand('testkill', function(source, args)
    print("^2[Killfeed] ^7Commande testkill exécutée par: " .. tostring(source))
    
    local isHeadshot = math.random(1, 2) == 1  -- 50% de chance
    local distance = math.random(50, 300)      -- Distance aléatoire
    
    print(string.format("^2[Killfeed] ^7Test: headshot=%s, distance=%d", 
        tostring(isHeadshot), distance))
    
    TriggerEvent('killfeed:playerKilled', source, source, isHeadshot, distance)
end, false)

-- Commande pour tester l'ID Discord d'un joueur
RegisterCommand('checkdiscord', function(source, args)
    local targetId = tonumber(args[1]) or source
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
    local targetId = tonumber(args[1]) or source
    local streak = GetPlayerKillStreak(targetId)
    
    print(string.format("^2[Killfeed] ^7Kill streak du joueur %d: %d", targetId, streak))
end, false)

-- Commande pour réinitialiser le kill streak d'un joueur (admin)
RegisterCommand('resetstreak', function(source, args)
    local targetId = tonumber(args[1]) or source
    ResetPlayerKillStreak(targetId)
    
    print(string.format("^2[Killfeed] ^7Kill streak réinitialisé pour le joueur: %d", targetId))
end, true) -- true = commande admin uniquement