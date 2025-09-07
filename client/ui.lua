print("^2[Killfeed] ^7Module UI chargé")

-- Variables locales pour l'interface
local isKillfeedVisible = false

-- Initialisation de l'interface HTML
Citizen.CreateThread(function()
    -- Attendre que le jeu soit complètement chargé
    -- HasStreamedTextureDictLoaded : Vérifie si une texture est chargée
    -- "mpleaderboard" : Texture qui indique que le jeu est prêt
    while not HasStreamedTextureDictLoaded("mpleaderboard") do
        Citizen.Wait(100)
    end
    
    -- Activer l'interface HTML avec NUI
    -- "false", "false" : Curseur, Clavier (pas de focus)
    SetNuiFocus(false, false)
    print("^2[Killfeed] ^7Interface initialisée")
end)

-- Fonction pour afficher un kill dans l'interface
function ShowKillInUI(killData)
    -- Envoyer les données à l'interface HTML
    SendNUIMessage({
        type = "showKill",
        data = killData
    })
    
    isKillfeedVisible = true
    
    print(string.format("^2[Killfeed] ^7Affichage du kill: %s -> %s", 
        killData.killer, killData.victim))
end

-- Fonction pour masquer le killfeed
function HideKillInUI()
    SendNUIMessage({
        type = "hideKill"
    })
    isKillfeedVisible = false
end

-- Fonction pour vérifier si le killfeed est visible
function IsKillfeedVisible()
    return isKillfeedVisible
end

-- Event pour gérer les messages de l'interface
RegisterNUICallback('killfeedReady', function(data, cb)
    print("^2[Killfeed] ^7Interface HTML prête")
    cb('ok')
end)