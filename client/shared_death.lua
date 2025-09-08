print("^2[Killfeed] ^7Module Shared chargé")

-- Configuration partagée
KILLFEED_SHARED = {
    MONITORING_INTERVAL = 1000, -- ms
    CLEANUP_INTERVAL = 30000,   -- ms
    DEATH_STABILIZATION_DELAY = 300, -- ms
    MAX_KILL_DISTANCE = 1000,   -- mètres max pour un kill valide
}

-- Variables globales partagées
_G.playerData = {} -- Données des joueurs trackés
_G.npcData = {}    -- Données des PNJ trackés
_G.isMonitoring = false
_G.monitoringThread = nil

-- Armes à feu acceptées pour le killfeed (avec les vrais hash des groupes)
local FIREARM_GROUPS = {
    -- Nouvelle méthode par hash de groupe
    [416676503] = true, -- GROUP_PISTOL
    [GetHashKey("GROUP_PISTOL")] = true,
    [GetHashKey("GROUP_SMG")] = true,
    [GetHashKey("GROUP_RIFLE")] = true,
    [GetHashKey("GROUP_SNIPER")] = true,
    [GetHashKey("GROUP_SHOTGUN")] = true,
    [GetHashKey("GROUP_LMG")] = true,
    [GetHashKey("GROUP_HEAVY")] = true,
}

-- Bones de la tête pour détection headshot (optimisé avec set pour O(1))
-- Chaque personnage a un squelette 3D avec des "os" (bones)
-- Chaque os a un ID numérique unique
-- 31086 = crâne principal, 39317/57597 = cou
-- POURQUOI en set ? HEAD_BONES[boneId] est O(1) (instantané) vs parcourir une liste qui serait O(n)
local HEAD_BONES = {
    [31086] = true, -- SKEL_HEAD
    [39317] = true, -- SKEL_NECK_1
    [57597] = true, -- SKEL_NECK_2
}

-- Cache pour éviter les calculs répétés
local weaponHashCache = {}
local UNARMED_HASH = GetHashKey("WEAPON_UNARMED")

-- Fonction optimisée pour vérifier si une arme est une arme à feu
function IsFirearm(weaponHash)
    print(string.format("^1[DEBUG WEAPON] ^7IsFirearm appelé: hash=%s", tostring(weaponHash)))
    
    if weaponHash == 0 or weaponHash == UNARMED_HASH then
        print("^1[DEBUG WEAPON] ^7UNARMED ou 0, return false")
        return false
    end
    
    -- Utiliser le cache pour éviter les appels répétés à GetWeapontypeGroup
    if weaponHashCache[weaponHash] == nil then
        local weaponGroup = GetWeapontypeGroup(weaponHash)
        print(string.format("^1[DEBUG WEAPON] ^7WeaponGroup: %s, FIREARM_GROUPS[%s]: %s", 
            tostring(weaponGroup), tostring(weaponGroup), tostring(FIREARM_GROUPS[weaponGroup])))
        weaponHashCache[weaponHash] = FIREARM_GROUPS[weaponGroup] or false
    end
    
    local result = weaponHashCache[weaponHash]
    print(string.format("^1[DEBUG WEAPON] ^7Result: %s", tostring(result)))
    
    return result
end

-- Fonction optimisée pour détecter un headshot
function IsHeadshot(victimPed)
    -- Méthode principale : vérifier le dernier bone de dégât
    local _, lastDamageBone = GetPedLastDamageBone(victimPed)
    if HEAD_BONES[lastDamageBone] then
        return true
    end
    
    -- Méthode de fallback : vérifier les dégâts sur les bones de tête
    for boneId in pairs(HEAD_BONES) do
        if HasEntityBeenDamagedByWeapon(victimPed, 0, boneId) then
            return true
        end
    end
    
    return false
end

-- Fonction optimisée pour calculer la distance
function CalculateDistance(pos1, pos2)
    if not pos1 or not pos2 then
        return 0
    end
    
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    local dz = pos1.z - pos2.z
    
    -- Calcul la racine carrée de la somme des carrés ci-dessus
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Fonction pour valider un kill
function IsValidKill(killerServerId, victimServerId, distance)
    -- Éviter les suicides
    -- if killerServerId == victimServerId then
    --     return false, "suicide"
    -- end
    
    -- Vérifier distance raisonnable
    if distance > KILLFEED_SHARED.MAX_KILL_DISTANCE then
        return false, "distance_trop_grande"
    end
    
    return true, "valide"
end

-- Fonction principale pour traiter une mort (commune PvP/PvE)
function ProcessPlayerDeath(victimId, npcPed, killType)
    print(string.format("^1[DEBUG] ^7ProcessPlayerDeath appelé: victimId=%s, npcPed=%s, type=%s", 
        tostring(victimId), tostring(npcPed), tostring(killType)))
    
    local victimPed = npcPed or GetPlayerPed(victimId) -- Utiliser le PNJ fourni ou récupérer le joueur
    local victimServerId = victimId == -1 and 9999 or GetPlayerServerId(victimId) -- ID fictif pour PNJ
    
    print(string.format("^1[DEBUG] ^7VictimPed: %s, VictimServerId: %s, DoesEntityExist: %s", 
        tostring(victimPed), tostring(victimServerId), tostring(DoesEntityExist(victimPed))))
    
    if not DoesEntityExist(victimPed) then
        print("^1[DEBUG] ^7RETURN: Entity n'existe pas")
        return
    end
    
    -- Obtenir la cause de la mort
    local deathCause = GetPedCauseOfDeath(victimPed)
    
    print(string.format("^1[DEBUG] ^7DeathCause: %s, IsFirearm: %s", 
        tostring(deathCause), tostring(IsFirearm(deathCause))))
    
    -- Vérifier que c'est une arme à feu
    if not IsFirearm(deathCause) then
        print("^1[DEBUG] ^7RETURN: Pas une arme à feu")
        return
    end
    
    -- Chercher le tueur
    local killerEntity = GetPedSourceOfDeath(victimPed)
    
    print(string.format("^1[DEBUG] ^7KillerEntity: %s, DoesEntityExist: %s", 
        tostring(killerEntity), tostring(DoesEntityExist(killerEntity))))
    
    if not DoesEntityExist(killerEntity) then
        print("^1[DEBUG] ^7RETURN: Killer entity n'existe pas")
        return
    end
    
    local killerServerId = nil
    local killerType = killType or "unknown"
    
    -- Déterminer le type de tueur
    print(string.format("^1[DEBUG] ^7IsPedAPlayer: %s, PlayerPedId: %s, killerEntity: %s", 
        tostring(IsPedAPlayer(killerEntity)), tostring(PlayerPedId()), tostring(killerEntity)))
    
    if IsPedAPlayer(killerEntity) then
        -- C'est un joueur
        local killerPlayerId = NetworkGetPlayerIndexFromPed(killerEntity)
        killerServerId = GetPlayerServerId(killerPlayerId)
        killerType = "player"
        print(string.format("^1[DEBUG] ^7Type: player, killerServerId: %s", tostring(killerServerId)))
    elseif killerEntity == PlayerPedId() then
        -- C'est le joueur local qui a tué un PNJ
        killerServerId = GetPlayerServerId(PlayerId())
        killerType = "pve"
        print(string.format("^1[DEBUG] ^7Type: pve, killerServerId: %s", tostring(killerServerId)))
    else
        -- Autre type de tueur (PNJ, véhicule, etc.) - ignorer
        print("^1[DEBUG] ^7RETURN: Autre type de tueur, ignore")
        return
    end
    
    -- Calculer la distance
    local killerPos = GetEntityCoords(killerEntity)
    local victimPos = GetEntityCoords(victimPed)
    local distance = CalculateDistance(killerPos, victimPos)
    
    -- Valider le kill
    local isValid, reason = IsValidKill(killerServerId, victimServerId, distance)
    if not isValid then
        print(string.format("^3[Killfeed] ^7Kill ignoré (%s): %d -> %d", reason, killerServerId, victimServerId))
        return
    end
    
    -- Détecter headshot
    local isHeadshot = IsHeadshot(victimPed)
    
    -- Log pour debug avec type de kill
    local killIcon = killerType == "pve" and "🤖" or "👤"
    print(string.format("^2[Killfeed] ^7Kill %s: %d -> %d | HS:%s | %.1fm | Arme:%d", 
        killIcon, killerServerId, victimServerId, isHeadshot and "✓" or "✗", distance, deathCause))
    
    -- Déclencher l'événement serveur avec une victime fictive pour PvE
    local actualVictimId = killerType == "pve" and 999 or victimServerId -- ID fictif pour PNJ
    
    print(string.format("^1[DEBUG] ^7TriggerServerEvent: killer=%d, victim=%d, headshot=%s, distance=%.1f", 
        killerServerId, actualVictimId, tostring(isHeadshot), distance))
    
    TriggerServerEvent('killfeed:playerKilled', killerServerId, actualVictimId, isHeadshot, distance)
end

-- Fonction pour arrêter le monitoring
function StopDeathMonitoring()
    if not _G.isMonitoring then
        return
    end
    
    _G.isMonitoring = false
    print("^3[Killfeed] ^7Arrêt du monitoring...")
    
    -- Attendre que le thread se termine
    Citizen.Wait(1500)
    _G.monitoringThread = nil
    print("^3[Killfeed] ^7Monitoring arrêté")
end

-- Thread de nettoyage optimisé (partagé)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(KILLFEED_SHARED.CLEANUP_INTERVAL)
        
        local currentTime = GetGameTimer()
        local cleanedCount = 0
        
        for serverId, data in pairs(_G.playerData) do
            local playerId = GetPlayerFromServerId(serverId)
            local isDisconnected = playerId == -1 or not NetworkIsPlayerConnected(playerId)
            local isStale = data.lastUpdate and (currentTime - data.lastUpdate) > 60000 -- 1 minute
            
            if isDisconnected or isStale then
                _G.playerData[serverId] = nil
                cleanedCount = cleanedCount + 1
            end
        end
        
        if cleanedCount > 0 then
            print(string.format("^3[Killfeed] ^7Nettoyage: %d entrées supprimées", cleanedCount))
        end
    end
end)

-- Commandes de debug partagées
RegisterCommand('killfeed_stop', function()
    StopDeathMonitoring()
end, false)

RegisterCommand('killfeed_status', function()
    local playerCount = 0
    for _ in pairs(_G.playerData) do
        playerCount = playerCount + 1
    end
    
    local npcCount = 0
    for _ in pairs(_G.npcData) do
        npcCount = npcCount + 1
    end
    
    print(string.format("^2[Killfeed] ^7Status: %s | Joueurs: %d | PNJ: %d | PvP: %s | PvE: %s", 
        _G.isMonitoring and "ACTIF" or "INACTIF", playerCount, npcCount, 
        Config.EnablePvP and "ON" or "OFF", Config.EnablePvE and "ON" or "OFF"))
end, false)

-- Commande pour tester la détection d'arme actuelle
RegisterCommand('killfeed_testweapon', function()
    local playerPed = PlayerPedId()
    local currentWeapon = GetSelectedPedWeapon(playerPed)
    local weaponGroup = GetWeapontypeGroup(currentWeapon)
    local isFirearm = IsFirearm(currentWeapon)
    
    print(string.format("^2[Killfeed] ^7Arme actuelle: hash=%d, group=%d, isFirearm=%s", 
        currentWeapon, weaponGroup, tostring(isFirearm)))
end, false)