# 🎯 Killfeed NovaCity

Un système de killfeed moderne et modulaire pour FiveM avec intégration Discord, détection de kills en temps réel et interface utilisateur optimisée.

## ✨ Fonctionnalités

### 🔫 Détection de Kills
- **PvP (Joueur vs Joueur)** : Surveillance en temps réel de tous les joueurs connectés
- **PvE (Joueur vs PNJ)** : Détection des kills contre les PNJ dans un rayon de 100m (utile pour les tests)
- **Armes à feu uniquement** : Filtre automatique pour ne compter que les kills par armes à feu
- **Détection headshot** : Analyse des dégâts sur les os de la tête (crâne et cou)
- **Calcul de distance** : Distance 3D précise entre tueur et victime

### 💯 Système de Points
- **Kill de base** : 100 points
- **Bonus headshot** : +50 points
- **Bonus longue distance** : +25 points (>200m)
- **Kill streaks** : +25 points par kill consécutif (dans les 30 secondes)

### 🎮 Interface Utilisateur
- **Design moderne** : Interface sombre avec transparence et animations fluides
- **Affichage en temps réel** : Killfeed positionné en bas à droite
- **Optimisations JavaScript** : Pool d'éléments DOM et limitation à 5 entrées max
- **Animations CSS** : Transitions slide-in/fade-out pour une expérience fluide

### 🔗 Intégration Discord
- **Noms réels** : Affiche les pseudos Discord au lieu des noms FiveM
- **Cache intelligent** : Système TTL de 5 minutes pour éviter les limites de taux
- **Gestion d'erreurs robuste** : Traitement des codes d'erreur HTTP (401, 403, 429, 500+)
- **Sécurité** : Token Discord externalisé (non hardcodé)

### 🛡️ Sécurité et Validation
- **Validation des commandes** : Vérification des sources, paramètres et existence des joueurs
- **Anti-cheat** : Validation des distances maximales (1000m)
- **Sanitisation** : Clamping des distances, validation des booléens
- **Token sécurisé** : Stockage du token Discord via variables serveur

## 🏗️ Architecture Modulaire

### Structure des Fichiers

```
killfeed/
├── server/                    # Scripts serveur
│   ├── server.lua            # Logique principale et gestion d'événements
│   ├── points.lua            # Calcul des points et kill streaks
│   ├── discord.lua           # API Discord avec cache TTL
│   └── commands.lua          # Commandes serveur avec validation
├── client/                    # Scripts client (architecture modulaire)
│   ├── shared_death.lua      # Fonctions partagées pour détection
│   ├── pvp.lua              # Module surveillance PvP
│   ├── pve.lua              # Module surveillance PvE
│   ├── ui.lua               # Gestion interface NUI
│   ├── events.lua           # Gestion événements réseau
│   ├── commands.lua         # Commandes client
│   └── client.lua           # Point d'entrée client
├── html/                     # Interface NUI
│   ├── index.html           # Structure HTML avec template
│   ├── style.css            # Styles modernes avec animations
│   └── script.js            # JavaScript optimisé
├── config.lua               # Configuration principale
├── config.example.lua       # Template de configuration
└── fxmanifest.lua          # Manifeste de ressource FiveM
```

### Modules Spécialisés

#### 📋 `shared_death.lua` - Fonctions Communes
- **Configuration centralisée** : Utilise les constantes de `Config` pour une gestion unifiée
- **Cache d'armes** : Optimisation des vérifications d'armes (`weaponHashCache`)
- **Détection headshot** : Analyse des os de tête (bones 31086, 39317, 57597)
- **Calcul de distance** : Formule euclidienne 3D optimisée
- **Validation des kills** : Anti-suicide, anti-cheat distance
- **Traitement central** : Fonction `ProcessPlayerDeath()` commune

#### ⚔️ `pvp.lua` - Surveillance PvP
- **Monitoring joueurs** : Scan de tous les slots connectés (0-255)
- **Tracking santé** : Surveillance en temps réel des changements de HP
- **Thread dédié** : Boucle de monitoring indépendante (1000ms)
- **Contrôle modulaire** : Activation/désactivation via `Config.EnablePvP`

#### 🤖 `pve.lua` - Surveillance PvE
- **Monitoring PNJ** : Scan des entités dans un rayon de 100m
- **Pool des Peds** : Utilisation de `GetGamePool('CPed')` pour l'efficacité
- **Nettoyage automatique** : Suppression des données de PNJ obsolètes
- **Tests facilitées** : Permet de tester sans second joueur

## 🚀 Installation

### Prérequis
1. **Serveur FiveM** avec framework CitizenFX
2. **Bot Discord** avec permissions appropriées
3. **ID du serveur Discord** (Guild ID)

### Étapes d'Installation

1. **Placer la ressource**
   ```bash
   resources/[local]/killfeed/
   ```

2. **Configurer le token Discord** dans `server.cfg`
   ```cfg
   set DISCORD_BOT_TOKEN "Bot VOTRE_TOKEN_ICI"
   ```

3. **Mettre à jour la configuration**
   - Copier `config.example.lua` vers `config.lua`
   - Modifier `Config.Discord.GuildID` avec votre ID de serveur Discord

4. **Activer la ressource** dans `server.cfg`
   ```cfg
   ensure killfeed
   ```

5. **Redémarrer le serveur**

## ⚙️ Configuration

### Système de Points
```lua
Config.Points = {
    Kill = 100,              -- Points de base pour un kill
    Headshot = 50,           -- Bonus headshot
    LongDistance = 25,       -- Bonus longue distance
    KillStreak = 25          -- Bonus par kill en série
}
```

### Paramètres de Gameplay
```lua
Config.LongDistanceThreshold = 200.0    -- Distance min pour bonus (mètres)
Config.KillStreakTimeout = 30000        -- Timeout kill streak (ms)
Config.KillfeedDuration = 3000          -- Durée d'affichage (ms)
```

### Fonctionnalités Modulaires
```lua
Config.EnablePvP = true                 -- Activer détection PvP
Config.EnablePvE = true                 -- Activer détection PvE (tests)
```

### Configuration du Monitoring
```lua
Config.MonitoringInterval = 1000        -- Intervalle de surveillance (ms)
Config.CleanupInterval = 30000          -- Intervalle de nettoyage (ms)
Config.DeathStabilizationDelay = 300    -- Délai de stabilisation après mort (ms)
Config.MaxKillDistance = 1000           -- Distance max pour un kill valide (mètres)
```

### Configuration Discord
```lua
Config.Discord = {
    BaseURL = "https://discord.com/api/v10",
    GuildID = "VOTRE_GUILD_ID",
    BotToken = GetConvar("DISCORD_BOT_TOKEN", ""),
    CacheTTL = 300000,                  -- Cache TTL (5 minutes)
}
```

## 🎮 Commandes

### Commandes Serveur

| Commande | Description | Usage |
|----------|-------------|-------|
| `/testkill` | Simule un kill avec paramètres aléatoires | Joueurs uniquement |
| `/checkdiscord [id]` | Vérifie l'intégration Discord d'un joueur | `/checkdiscord 1` |
| `/killstreak [id]` | Affiche le kill streak d'un joueur | `/killstreak 1` |
| `/resetstreak [id]` | Remet à zéro le kill streak | Admin/Console |
| `/cacheinfo` | Statistiques du cache Discord | Tous |
| `/clearcache` | Nettoie le cache expiré | Tous |
| `/flushcache` | Vide complètement le cache | Tous |

### Commandes Client

| Commande | Description |
|----------|-------------|
| `/killfeed_status` | État du monitoring et statistiques |
| `/killfeed_testweapon` | Test de détection d'arme actuelle |
| `/killfeed_stop` | Arrête le monitoring |
| `/killfeed_restart_pvp` | Redémarre uniquement le module PvP |
| `/killfeed_restart_pve` | Redémarre uniquement le module PvE |
| `/uicheck` | Vérifie l'état de l'interface utilisateur |

## 🔧 Développement et Debug

### Logs de Debug
Le système fournit des logs détaillés avec codes couleur :
- **🟢 Vert** : Informations générales et succès
- **🟡 Jaune** : Avertissements et nettoyage
- **🔴 Rouge** : Erreurs et debug détaillé
- **🔵 Bleu** : Debug spécifique aux armes

### Performance
- **Monitoring interval** : 1000ms (configurable)
- **Cache cleanup** : Toutes les 10 minutes
- **Player data cleanup** : Toutes les 30 secondes
- **Max kill distance** : 1000m (validation anti-cheat)

### Optimisations
- **Cache des armes** : Évite les appels répétés à `GetWeapontypeGroup()`
- **Pool d'entités** : Réutilisation des éléments DOM
- **Nettoyage automatique** : Prévention des fuites mémoire
- **Thread séparés** : PvP et PvE indépendants pour les performances

## 🛠️ API et Événements

### Événements Serveur
```lua
-- Déclenché quand un kill est détecté
RegisterNetEvent('killfeed:playerKilled')
-- Params: killerId, victimId, isHeadshot, distance
```

### Événements Client
```lua
-- Affiche un kill dans l'interface
RegisterNetEvent('killfeed:showKill')
-- Params: killData (killer, victim, points, etc.)
```

## 🐛 Résolution de Problèmes

### Problèmes Courants

1. **Kill non détecté**
   - Vérifier que l'arme est une arme à feu : `/killfeed_testweapon`
   - Vérifier l'état du monitoring : `/killfeed_status`

2. **Nom Discord non affiché**
   - Vérifier le token Discord : `/checkdiscord`
   - Vérifier le cache : `/cacheinfo`

3. **Interface non visible**
   - Vérifier l'état UI : `/uicheck`
   - Redémarrer la ressource

### Validation de l'Installation
```lua
-- Console F8
killfeed_status           -- État général
killfeed_testweapon      -- Test arme actuelle  
checkdiscord             -- Test Discord
testkill                 -- Test kill simulé
```

## 📝 Changelog

### Version Actuelle
- ✅ **Architecture modulaire** : Séparation PvP/PvE/Shared
- ✅ **Cache Discord TTL** : Système de cache intelligent
- ✅ **Sécurité renforcée** : Token externalisé, validation complète
- ✅ **Interface optimisée** : Pool DOM, animations fluides
- ✅ **Performance** : Threads séparés, nettoyage automatique

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.

## 👥 Support

Pour des questions, bugs ou suggestions :
1. Vérifier la section résolution de problèmes ci-dessus
2. Utiliser les commandes de debug intégrées
3. Consulter les logs serveur avec codes couleur

---

**Développé avec ❤️ pour la communauté FiveM NovaCity**