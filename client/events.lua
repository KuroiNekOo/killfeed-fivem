print("^2[Killfeed] ^7Module Events chargé")

-- Réception des données de kill depuis le serveur
RegisterNetEvent('killfeed:showKill')
AddEventHandler('killfeed:showKill', function(killData)
    -- Afficher le kill dans l'interface
    ShowKillInUI(killData)
    
    -- Programmer la disparition après le délai configuré
    SetTimeout(Config.KillfeedDuration, function()
        HideKillInUI()
    end)
end)