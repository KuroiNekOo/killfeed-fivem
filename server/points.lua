print("^2[Killfeed] ^7Module Points chargé")

-- Stockage des kill streaks par joueur
local playerKillStreaks = {}
local lastKillTime = {}

-- Fonction pour calculer les points et bonus (version sécurisée)
function CalculateKillData(killerId, victimId, isHeadshot, distance)
    local killData = {
        victim = "",
        killer = "",
        points = Config.Points.Kill,
        bonuses = {},
        totalPoints = Config.Points.Kill
    }
    
    -- Bonus headshot
    if isHeadshot then
        table.insert(killData.bonuses, {type = "headshot", points = Config.Points.Headshot})
        killData.totalPoints = killData.totalPoints + Config.Points.Headshot
    end
    
    -- Bonus longue distance
    if distance >= Config.LongDistanceThreshold then
        table.insert(killData.bonuses, {type = "longdistance", points = Config.Points.LongDistance})
        killData.totalPoints = killData.totalPoints + Config.Points.LongDistance
    end
    
    -- Gestion kill streak (version sécurisée)
    -- Utiliser os.time() au lieu de GetGameTimer() côté serveur
    local currentTime = os.time() * 1000 -- Convertir en millisecondes
    
    if not playerKillStreaks[killerId] then
        playerKillStreaks[killerId] = 1
    else
        -- Vérifier si le kill précédent était récent
        if lastKillTime[killerId] and (currentTime - lastKillTime[killerId]) <= Config.KillStreakTimeout then
            playerKillStreaks[killerId] = playerKillStreaks[killerId] + 1
        else
            playerKillStreaks[killerId] = 1
        end
    end
    
    lastKillTime[killerId] = currentTime
    
    -- Bonus kill streak (à partir du 2ème kill)
    if playerKillStreaks[killerId] > 1 then
        local streakPoints = playerKillStreaks[killerId] * Config.Points.KillStreak
        table.insert(killData.bonuses, {
            type = "killstreak", 
            points = streakPoints, 
            count = playerKillStreaks[killerId]
        })
        killData.totalPoints = killData.totalPoints + streakPoints
    end
    
    return killData
end

-- Fonction pour obtenir le kill streak actuel d'un joueur
function GetPlayerKillStreak(playerId)
    return playerKillStreaks[playerId] or 0
end

-- Fonction pour réinitialiser le kill streak d'un joueur
function ResetPlayerKillStreak(playerId)
    playerKillStreaks[playerId] = nil
    lastKillTime[playerId] = nil
end