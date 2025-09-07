print("^2[Killfeed] ^7Module Discord chargé")

-- Cache pour éviter les appels API répétés avec TTL
local discordNameCache = {}
local cacheTimestamps = {}

-- Créer des setters et getters pour le cache
function ResetCacheTimestamps()
    discordNameCache = {}
    cacheTimestamps = {}
end

-- Fonction pour récupérer l'ID Discord d'un joueur FiveM
function GetPlayerDiscordId(source)
    -- Méthode 1: Via les identifiers FiveM
    -- Parcourir tous les identifiers du joueur (source)
    -- Commence à 0 et fini au max (length - 1)
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        -- Chercher l'identifier Discord
        local identifier = GetPlayerIdentifier(source, i)
        -- Vérifier si c'est un identifiant Discord, qui commence par "discord:"
        if string.match(identifier, "discord:") then
            -- Retourner l'ID Discord (sans le préfixe "discord:")
            -- Remplace toutes les occurrences de "discord:" par "" (rien)
            return string.gsub(identifier, "discord:", "")
        end
    end
    
    -- Si pas trouvé, retourner nil
    -- nil = "Pas de valeur" donc "rien" (comme null en JavaScript)
    return nil
end

-- Fonction pour récupérer le nom Discord via l'API
function GetDiscordName(source, callback)
    -- Récupérer l'ID Discord du joueur
    local discordId = GetPlayerDiscordId(source)
    
    if not discordId then
        print("^1[Killfeed] ^7Pas d'ID Discord trouvé pour le joueur: " .. tostring(source))
        callback("Joueur#" .. source)
        return
    end
    
    -- Vérifier le cache avec TTL
    if discordNameCache[discordId] then
        local currentTime = os.time() * 1000
        local cacheAge = currentTime - (cacheTimestamps[discordId] or 0)
        
        if cacheAge <= Config.Discord.CacheTTL then
            print("^2[Killfeed] ^7Nom Discord récupéré du cache: " .. discordNameCache[discordId])
            callback(discordNameCache[discordId])
            return
        else
            -- Cache expiré, le nettoyer
            print("^3[Killfeed] ^7Cache expiré pour Discord ID: " .. discordId)
            discordNameCache[discordId] = nil
            cacheTimestamps[discordId] = nil
        end
    end
    
    -- Vérifier que le token est configuré
    if not Config.Discord.BotToken or Config.Discord.BotToken == "" then
        print("^1[Killfeed] ^7Token Discord non configuré")
        callback("Joueur#" .. source)
        return
    end
    
    -- Construire l'URL de l'API Discord
    local apiUrl = Config.Discord.BaseURL .. "/guilds/" .. Config.Discord.GuildID .. "/members/" .. discordId
    
    -- Construire les headers avec le token
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = Config.Discord.BotToken
    }
    
    print("^2[Killfeed] ^7Appel API Discord pour: " .. discordId)
    
    -- Appel à l'API Discord
    PerformHttpRequest(apiUrl, function(statusCode, body, headers, errorData)
        print("^2[Killfeed] ^7Réponse API Discord - Status: " .. tostring(statusCode))
        
        -- Vérifier les erreurs de base
        if not statusCode then
            print("^1[Killfeed] ^7Erreur HTTP inconnue lors de l'appel API Discord")
            callback("Joueur#" .. source)
            return
        end

        -- Vérifier le body
        if not body or body == "" then
            print("^1[Killfeed] ^7Réponse vide de l'API Discord")
            callback("Joueur#" .. source)
            return
        end

        if statusCode == 200 then
            -- Succès - Parser la réponse
            local success, profile = pcall(json.decode, body)

            -- Vérifier les erreurs de parsing
            if not success then
                print("^1[Killfeed] ^7Erreur parsing JSON: " .. tostring(profile))
                callback("Joueur#" .. source)
                return
            end
            
            -- Vérifier les données du profil
            if not profile or type(profile) ~= "table" then
                print("^1[Killfeed] ^7Données de profil invalides reçues de l'API Discord")
                callback("Joueur#" .. source)
                return
            end

            -- Priorité: global_name > nickname > username
            local discordName = profile.nick or 
                              (profile.user and profile.user.global_name) or 
                              (profile.user and profile.user.username) or 
                              ("Joueur#" .. source)

            -- Vérifier si le nom est vide
            if not discordName or discordName == "" then
                print("^1[Killfeed] ^7Nom Discord introuvable dans les données du profil")
                discordName = "Joueur#" .. source
            end

            -- Tronquer si trop long
            if discordName:len() > 32 then
                discordName = discordName:sub(1, 32) -- Tronquer à 32 caractères max
            end

            -- Mettre en cache avec timestamp
            discordNameCache[discordId] = discordName
            cacheTimestamps[discordId] = os.time() * 1000
            
            print("^2[Killfeed] ^7Nom Discord récupéré: " .. discordName)
            callback(discordName)


        elseif statusCode == 404 then
            print("^3[Killfeed] ^7Joueur pas trouvé sur le serveur Discord: " .. discordId)
            callback("Joueur#" .. source)
        elseif statusCode == 401 then
            print("^1[Killfeed] ^7Erreur 401: Token Discord invalide ou expiré")
            callback("Joueur#" .. source)
        elseif statusCode == 403 then
            print("^1[Killfeed] ^7Erreur 403: Permissions insuffisantes (bot pas dans le serveur?)")
            callback("Joueur#" .. source)
        elseif statusCode == 429 then
            print("^3[Killfeed] ^7Rate limit Discord atteint, réessayer plus tard")
            callback("Joueur#" .. source)
        elseif statusCode >= 500 then
            print("^1[Killfeed] ^7Erreur serveur Discord (" .. statusCode .. "): Service indisponible")
            callback("Joueur#" .. source)
        else
            print("^1[Killfeed] ^7Erreur API Discord inconnue: " .. tostring(statusCode))
            if body and type(body) == "string" and body:len() < 200 then
                print("^1[Killfeed] ^7Détails: " .. body)
            end
            callback("Joueur#" .. source)
        end
        
        -- Log des erreurs HTTP supplémentaires
        if errorData and errorData ~= "" then
            print("^3[Killfeed] ^7Données d'erreur HTTP: " .. tostring(errorData))
        end
    end, "GET", "", headers)
end

-- Fonction pour nettoyer le cache expiré
function CleanExpiredCache()
    local currentTime = os.time() * 1000
    local cleanedCount = 0
    
    for discordId, timestamp in pairs(cacheTimestamps) do
        local cacheAge = currentTime - timestamp
        if cacheAge > Config.Discord.CacheTTL then
            discordNameCache[discordId] = nil
            cacheTimestamps[discordId] = nil
            cleanedCount = cleanedCount + 1
        end
    end
    
    if cleanedCount > 0 then
        print(string.format("^2[Killfeed] ^7Cache nettoyé: %d entrées expirées supprimées", cleanedCount))
    end
end

-- Nettoyer le cache toutes les 10 minutes
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(600000) -- 10 minutes
        CleanExpiredCache()
    end
end)

-- Fonction pour obtenir les statistiques du cache (pour debug)
function GetCacheStats()
    local cacheCount = 0
    local expiredCount = 0
    local currentTime = os.time() * 1000
    
    for discordId, _ in pairs(discordNameCache or {}) do
        cacheCount = cacheCount + 1
        local timestamp = cacheTimestamps[discordId] or 0
        local cacheAge = currentTime - timestamp
        if cacheAge > Config.Discord.CacheTTL then
            expiredCount = expiredCount + 1
        end
    end
    
    return cacheCount, expiredCount
end