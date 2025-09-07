print("^2[Killfeed] ^7Module Discord chargé")

-- Cache pour éviter les appels API répétés
local discordNameCache = {}

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
    
    -- Vérifier le cache
    if discordNameCache[discordId] then
        print("^2[Killfeed] ^7Nom Discord récupéré du cache: " .. discordNameCache[discordId])
        callback(discordNameCache[discordId])
        return
    end
    
    -- Construire l'URL de l'API Discord
    local apiUrl = Config.Discord.BaseURL .. "/guilds/" .. Config.Discord.GuildID .. "/members/" .. discordId
    
    print("^2[Killfeed] ^7Appel API Discord pour: " .. discordId)
    
    -- Appel à l'API Discord
    PerformHttpRequest(apiUrl, function(statusCode, body, headers, errorData)
        print("^2[Killfeed] ^7Réponse API Discord - Status: " .. tostring(statusCode))
        
        if statusCode == 200 then
            -- Succès - Parser la réponse
            local success, profile = pcall(json.decode, body)
            
            if success and profile then
                -- Priorité: global_name > nickname > username
                local discordName = profile.nick or 
                                  (profile.user and profile.user.global_name) or 
                                  (profile.user and profile.user.username) or 
                                  ("Joueur#" .. source)
                
                -- Mettre en cache
                discordNameCache[discordId] = discordName
                
                print("^2[Killfeed] ^7Nom Discord récupéré: " .. discordName)
                callback(discordName)
            else
                print("^1[Killfeed] ^7Erreur parsing JSON: " .. tostring(body))
                callback("Joueur#" .. source)
            end
        elseif statusCode == 404 then
            print("^3[Killfeed] ^7Joueur pas trouvé sur le serveur Discord: " .. discordId)
            callback("Joueur#" .. source)
        elseif statusCode == 403 then
            print("^1[Killfeed] ^7Erreur permissions Discord (vérifiez le token)")
            callback("Joueur#" .. source)
        else
            print("^1[Killfeed] ^7Erreur API Discord: " .. tostring(statusCode) .. " - " .. tostring(body))
            callback("Joueur#" .. source)
        end
    end, "GET", "", Config.Discord.Headers)
end