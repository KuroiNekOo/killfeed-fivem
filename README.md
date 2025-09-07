# Killfeed NovaCity - Documentation Développeur

## 📋 Vue d'ensemble

Killfeed avancé pour serveur FiveM avec intégration Discord, système de points et interface NUI moderne. Développé avec une architecture modulaire pour faciliter la maintenance et les extensions.

**Auteur**: Xam42  
**Version**: 1.0.0  
**Framework**: CitizenFX (FiveM)  

---

## 📁 Structure du Projet

```
killfeed/
├── server/              # Scripts côté serveur
│   ├── points.lua       # Système de points et kill streaks
│   ├── discord.lua      # Intégration Discord API
│   ├── server.lua       # Logique principale serveur
│   └── commands.lua     # Commandes administrateur/test
├── client/              # Scripts côté client
│   ├── ui.lua           # Gestion interface NUI
│   ├── events.lua       # Gestion événements réseau
│   ├── commands.lua     # Commandes client/test
│   └── client.lua       # Point d'entrée client
├── html/                # Interface utilisateur NUI
│   ├── index.html       # Structure HTML
│   ├── script.js        # Logique JavaScript
│   └── style.css        # Styles CSS
├── config.lua           # Configuration globale
├── fxmanifest.lua       # Manifest FiveM
└── README.md            # Cette documentation
```

---

## ⚙️ Configuration (`config.lua`)

### Variables Globales

```lua
Config = {}
```

### Système de Points
```lua
Config.Points = {
    Kill = 100,              -- Points pour un kill basique
    Headshot = 50,           -- Bonus tir dans la tête
    LongDistance = 25,       -- Bonus tir longue distance  
    KillStreak = 25          -- Bonus par kill en série
}
```

### Paramètres Gameplay
```lua
Config.LongDistanceThreshold = 200.0    -- Distance minimum (mètres) pour bonus
Config.KillStreakTimeout = 30000        -- Délai max entre kills (ms) pour série
Config.KillfeedDuration = 3000          -- Durée d'affichage interface (ms)
```

### Configuration Discord
```lua
Config.Discord = {
    BaseURL = "https://discord.com/api/v10",           -- URL API Discord
    GuildID = "VOTRE_GUILD_ID",                        -- ID serveur Discord
    BotToken = "Bot VOTRE_TOKEN",                      -- Token bot Discord
    Headers = {                                        -- Headers HTTP
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bot VOTRE_TOKEN"
    }
}
```

---

## 🖥️ Côté Serveur

### `server/points.lua` - Système de Points

#### Variables Locales
- `playerKillStreaks{}` : Table des kill streaks par joueur
- `lastKillTime{}` : Timestamp du dernier kill par joueur

#### Fonctions Principales

**`CalculateKillData(killerId, victimId, isHeadshot, distance)`**
- **Description** : Calcule les points et bonus pour un kill
- **Paramètres** :
  - `killerId` (number) : ID serveur du tueur
  - `victimId` (number) : ID serveur de la victime  
  - `isHeadshot` (boolean) : Tir dans la tête
  - `distance` (number) : Distance du tir
- **Retour** : Table `killData` avec points et bonus
- **Logique** : 
  - Points de base selon `Config.Points.Kill`
  - Bonus headshot si `isHeadshot = true`
  - Bonus longue distance si `distance >= Config.LongDistanceThreshold`
  - Calcul et bonus kill streak avec timeout

**`GetPlayerKillStreak(playerId)`**
- **Description** : Récupère le kill streak actuel d'un joueur
- **Paramètres** : `playerId` (number)
- **Retour** : Nombre de kills en série (number)

**`ResetPlayerKillStreak(playerId)`**
- **Description** : Remet à zéro le kill streak d'un joueur
- **Paramètres** : `playerId` (number)
- **Usage** : Mort du joueur, déconnexion, etc.

### `server/discord.lua` - Intégration Discord

#### Variables Locales
- `discordNameCache{}` : Cache des noms Discord pour éviter appels API répétés

#### Fonctions Principales

**`GetPlayerDiscordId(source)`**
- **Description** : Extrait l'ID Discord depuis les identifiers FiveM
- **Paramètres** : `source` (number) - ID serveur du joueur
- **Retour** : String ID Discord ou `nil`
- **Logique** : Parse tous les identifiers, cherche le préfixe "discord:"

**`GetDiscordName(source, callback)`**
- **Description** : Récupère le nom Discord via l'API Discord
- **Paramètres** :
  - `source` (number) : ID serveur du joueur
  - `callback` (function) : Fonction appelée avec le nom
- **Cache** : Utilise `discordNameCache` pour optimiser les performances
- **API** : Appel GET `/guilds/{GUILD_ID}/members/{USER_ID}`
- **Priorité noms** : `nickname` > `global_name` > `username`
- **Gestion erreurs** : 404 (pas sur serveur), 403 (permissions), autres

### `server/server.lua` - Logique Principale

#### Événements Réseau

**`RegisterNetEvent('killfeed:playerKilled')`**
- **Description** : Événement principal de traitement d'un kill
- **Paramètres** :
  - `killerId` (number) : ID du tueur
  - `victimId` (number) : ID de la victime
  - `isHeadshot` (boolean) : Tir dans la tête
  - `distance` (number) : Distance du tir
- **Flux** :
  1. Validation des paramètres
  2. Calcul des données via `CalculateKillData()`
  3. Récupération nom Discord de la victime
  4. Récupération nom FiveM du tueur
  5. Envoi à tous les clients via `TriggerClientEvent`

### `server/commands.lua` - Commandes

**Commandes Disponibles :**

| Commande | Description | Paramètres | Restriction |
|----------|-------------|------------|-------------|
| `/testkill` | Test kill simulé | Aucun | Public |
| `/checkdiscord [id]` | Vérifier ID Discord | ID joueur (optionnel) | Public |
| `/killstreak [id]` | Voir kill streak | ID joueur (optionnel) | Public |
| `/resetstreak [id]` | Reset kill streak | ID joueur (optionnel) | Admin uniquement |

---

## 💻 Côté Client

### `client/ui.lua` - Interface NUI

#### Variables Locales
- `isKillfeedVisible` (boolean) : État de visibilité du killfeed

#### Fonctions Principales

**`ShowKillInUI(killData)`**
- **Description** : Affiche un kill dans l'interface NUI
- **Paramètres** : `killData` (table) - Données du kill
- **Actions** :
  - Envoie message NUI type "showKill"
  - Met à jour `isKillfeedVisible`
  - Log pour debug

**`HideKillInUI()`**
- **Description** : Masque le killfeed
- **Actions** : Envoie message NUI type "hideKill"

**`IsKillfeedVisible()`**
- **Retour** : État de visibilité (boolean)

#### Thread d'Initialisation
- Attend chargement texture "mpleaderboard"
- Configure NUI focus
- Log confirmation d'initialisation

#### Callbacks NUI
- `killfeedReady` : Confirmation interface HTML prête

### `client/events.lua` - Gestion Événements

**`RegisterNetEvent('killfeed:showKill')`**
- **Description** : Reçoit les données de kill du serveur
- **Actions** :
  1. Appel `ShowKillInUI(killData)`
  2. Programme masquage avec `SetTimeout(Config.KillfeedDuration)`

### `client/commands.lua` - Commandes Client

**`SimulatePlayerKill()`**
- **Description** : Génère un kill de test
- **Logique** :
  - Headshot aléatoire (33% chance)
  - Distance aléatoire (50-400m)
  - Déclenche événement serveur

**Commandes Disponibles :**
- `/killtest` : Test kill simulé
- `/uicheck` : Vérifier état interface

### `client/client.lua` - Point d'Entrée
- Simple log de démarrage
- Point d'entrée minimal pour chargement ordonné

---

## 🌐 Interface NUI (`html/`)

### `index.html` - Structure

#### Éléments Principaux
```html
<div id="killfeed-container">           <!-- Container principal -->
    <div id="kill-template">            <!-- Template kill (masqué) -->
        <div class="kill-info">
            <div class="victim-name">    <!-- Nom tueur → victime -->
            <div class="bonuses">        <!-- Liste des bonus -->
        </div>
        <div class="points-section">
            <div class="base-points">    <!-- Points de base -->
            <div class="bonus-points">   <!-- Points bonus -->
            <div class="total-points">   <!-- Total points -->
        </div>
    </div>
</div>
```

### `script.js` - Logique JavaScript

#### Configuration
```javascript
const KILLFEED_DURATION = 3000;        // Durée affichage (ms)
const MAX_KILLS_DISPLAYED = 5;         // Limite kills affichés
let killCount = 0;                      // ID unique par kill
```

#### Fonctions Principales

**`showKill(killData)`**
- Crée nouvel élément kill via `createKillElement()`
- Ajoute au DOM
- Programme suppression automatique
- Limite nombre d'entrées

**`createKillElement(killData)`**
- Clone template HTML
- Assigne ID unique
- Appel `fillKillData()` pour remplissage
- Retourne élément configuré

**`fillKillData(element, killData)`**
- Renseigne nom victime/tueur
- Configure points de base
- Parse et affiche bonus
- Calcule total points

**`formatBonusText(bonus)`**
- Traduit types bonus en texte français
- Gère cas spéciaux (kill streak avec compteur)

#### Gestionnaire Messages
```javascript
window.addEventListener('message', function(event) {
    switch(event.data.type) {
        case 'showKill': showKill(event.data.data); break;
        case 'hideKill': hideOldestKill(); break;
    }
});
```

### `style.css` - Styles

#### Positionnement
- Container fixe en bas à droite
- Largeur : 400px
- Position : `bottom: 100px; right: 20px;`

#### Animations
- Fade in/out pour apparition/disparition
- Transitions fluides
- Effets hover

---

## 📡 Événements Réseau

### Serveur → Client
| Événement | Paramètres | Description |
|-----------|------------|-------------|
| `killfeed:showKill` | `killData` (table) | Affichage d'un nouveau kill |

### Client → Serveur  
| Événement | Paramètres | Description |
|-----------|------------|-------------|
| `killfeed:playerKilled` | `killerId, victimId, isHeadshot, distance` | Signalement d'un kill |

### Structure `killData`
```lua
killData = {
    victim = "Nom Discord",              -- Nom de la victime
    killer = "Nom FiveM",                -- Nom du tueur
    points = 100,                        -- Points de base
    bonuses = {                          -- Array des bonus
        {
            type = "headshot",           -- Type : headshot/longdistance/killstreak
            points = 50,                 -- Points du bonus
            count = 3                    -- Nombre (pour killstreak)
        }
    },
    totalPoints = 225                    -- Total calculé
}
```

---

## 🔧 Installation & Configuration

### Prérequis
1. Serveur FiveM fonctionnel
2. Bot Discord avec permissions appropriées
3. Accès Guild ID du serveur Discord

### Installation
1. Copier le dossier dans `resources/[local]/killfeed/`
2. Configurer `config.lua` avec vos paramètres Discord
3. Ajouter `ensure killfeed` dans `server.cfg`
4. Redémarrer serveur

### Configuration Discord
1. Créer application Discord Developer Portal
2. Créer bot et copier token
3. Inviter bot sur serveur avec permissions appropriées
4. Récupérer Guild ID du serveur
5. Renseigner `Config.Discord` dans `config.lua`

### Commandes de Test
```bash
# Console serveur FiveM
testkill                    # Tester kill simulé
checkdiscord [id]          # Vérifier intégration Discord

# Console client (F8)
killtest                   # Tester depuis client
uicheck                    # Vérifier état interface
```

---

## 🐛 Débogage

### Logs Importants
- `^2[Killfeed] ^7Module XXX chargé` : Confirmation chargement modules
- `^2[Killfeed] ^7Interface initialisée` : NUI prêt
- `^1[Killfeed] ^7SCRIPT ERROR` : Erreurs Lua

### Problèmes Courants

**Fonctions non trouvées**
- Vérifier ordre chargement dans `fxmanifest.lua`
- Redémarrer avec `stop killfeed; refresh; start killfeed`

**Discord ne fonctionne pas**
- Vérifier token bot et permissions
- Contrôler Guild ID
- Tester avec `/checkdiscord`

**Interface ne s'affiche pas**
- Vérifier console F12 navigateur
- Contrôler événements NUI
- Tester avec `/killtest`

### Performance
- Cache Discord actif pour éviter spam API
- Limitation à 5 kills affichés simultanément
- Nettoyage automatique éléments DOM

---

## 🔄 Ordre de Chargement

### Serveur
1. `config.lua` - Configuration globale
2. `server/points.lua` - Fonctions calcul points
3. `server/discord.lua` - Fonctions Discord
4. `server/server.lua` - Logique principale
5. `server/commands.lua` - Commandes (utilise fonctions précédentes)

### Client  
1. `config.lua` - Configuration globale
2. `client/ui.lua` - Fonctions interface
3. `client/events.lua` - Gestion événements (utilise fonctions UI)
4. `client/commands.lua` - Commandes (utilise fonctions UI/events)
5. `client/client.lua` - Point d'entrée

**⚠️ Important** : L'ordre est critique pour éviter les erreurs de dépendances entre fonctions.

---

## 📈 Extensions Possibles

### Fonctionnalités Suggérées
- Base de données persistante des statistiques
- Leaderboards en temps réel
- Webhooks Discord pour logs
- Système de rangs/niveaux
- Récompenses automatiques
- Interface admin web
- API REST pour statistiques externes

### Points d'Extension
- `server/points.lua` : Ajouter nouveaux types de bonus
- `client/ui.lua` : Personnaliser interface
- `config.lua` : Nouveaux paramètres
- `html/` : Nouvelle interface ou thèmes

---

*Documentation générée pour Killfeed NovaCity v1.0.0 - Dernière mise à jour : $(date)*