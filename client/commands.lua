print("^2[Killfeed] ^7Module Commands chargé")

-- Fonction pour simuler un kill (pour les tests)
function SimulatePlayerKill()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Simuler des données de kill
    local isHeadshot = math.random(1, 3) == 1  -- 33% de chance
    local distance = math.random(50, 400)      -- Distance aléatoire

    -- Récupérer l'ID du joueur
    local myServerId = GetPlayerServerId(PlayerId())

    -- Déclencher l'event serveur killerId, victimId, isHeadshot, distance
    TriggerServerEvent('killfeed:playerKilled', myServerId, myServerId, isHeadshot, distance)
end

-- Commande de test côté client
RegisterCommand('killtest', function()
    SimulatePlayerKill()
end, false)

-- Commande pour vérifier l'état de l'interface
RegisterCommand('uicheck', function()
    local visible = IsKillfeedVisible()
    print(string.format("^2[Killfeed] ^7Interface visible: %s", tostring(visible)))
end, false)