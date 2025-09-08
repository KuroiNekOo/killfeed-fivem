print("^2[Killfeed] ^7Module Events chargé")

-- Réception des données de kill depuis le serveur
RegisterNetEvent('killfeed:showKill', function(killData)
    print(string.format("^1[DEBUG CLIENT] ^7EVENT killfeed:showKill reçu: killer=%s, victim=%s, points=%d", 
        killData.killer or "nil", killData.victim or "nil", killData.totalPoints or 0))

    -- Afficher le kill dans l'interface
    ShowKillInUI(killData)
    
    -- Programmer la disparition après le délai configuré
    -- SetTimeout(Config.KillfeedDuration, function()
    --     HideKillInUI()
    -- end)
end)