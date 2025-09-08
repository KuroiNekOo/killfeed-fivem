-- Exemple de configuration - Copier vers config.lua et remplir vos valeurs
Config = {}

-- Points attribués
Config.Points = {
    Kill = 100,              -- Kill basique
    Headshot = 50,           -- Tir dans la tête
    LongDistance = 25,       -- Tir longue distance
    KillStreak = 25          -- Bonus par kill dans une série
}

-- Paramètres
Config.LongDistanceThreshold = 200.0    -- Distance en mètres
Config.KillStreakTimeout = 30000        -- 30 secondes entre kills pour série
Config.KillfeedDuration = 3000          -- 3 secondes d'affichage

-- Fonctionnalités de détection
Config.EnablePvP = true                 -- Activer la détection PvP (joueur vs joueur)
Config.EnablePvE = true                 -- Activer la détection PvE (joueur vs PNJ) - utile pour les tests

-- Configuration du système de monitoring
Config.MonitoringInterval = 1000        -- Intervalle de surveillance (ms)
Config.CleanupInterval = 30000          -- Intervalle de nettoyage (ms)  
Config.DeathStabilizationDelay = 300    -- Délai de stabilisation après mort (ms)
Config.MaxKillDistance = 1000           -- Distance max pour un kill valide (mètres)

-- Discord API - REMPLACEZ PAR VOS VRAIES VALEURS
Config.Discord = {
    BaseURL = "https://discord.com/api/v10",
    GuildID = "1234567890123456789",               -- ID de votre serveur Discord
    BotToken = GetConvar("DISCORD_BOT_TOKEN", ""),     -- Token récupéré depuis les variables serveur
    CacheTTL = 300000,                        -- 5 minutes en millisecondes
    Headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "" -- Sera construit dynamiquement
    }
}