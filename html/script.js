console.log('[Killfeed] Interface JavaScript chargée');

// Configuration
const KILLFEED_DURATION = 3000; // 3 secondes
const MAX_KILLS_DISPLAYED = 5; // Nombre maximum de kills affichés
let killCount = 0; // Pour donner un ID unique à chaque kill

// Initialisation de l'interface HTML
document.addEventListener('DOMContentLoaded', function() {
    console.log('[Killfeed] DOM chargé, interface prête');
    
    // Signaler à FiveM que l'interface est prête
    const resourceName = 'killfeed';
    if (resourceName) {
        fetch(`https://${resourceName}/killfeedReady`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
});

// Écouter les messages de FiveM
window.addEventListener('message', function(event) {
    const { data = {} } = event;
    
    switch(data.type) {
        case 'showKill':
            showKill(data.data);
            break;
        case 'hideKill':
            hideOldestKill();
            break;
        default:
            console.log('[Killfeed] Message non reconnu:', data.type);
    }
});

// Fonction principale pour afficher un kill
function showKill(killData) {
    console.log('[Killfeed] Affichage du kill:', killData);
    
    // Créer un nouvel élément de kill
    const killElement = createKillElement(killData);
    
    // Ajouter au container
    const container = document.getElementById('killfeed-container');
    container.appendChild(killElement);
    
    // Programmer la suppression automatique
    const killElementParent = killElement.parentNode;
    setTimeout(() => {
        if (killElementParent) {
            killElement.remove();
        }
    }, KILLFEED_DURATION);
    
    // Limiter le nombre de kills affichés (max 5)
    limitKillFeedEntries();
}

// Créer un élément HTML pour un kill
function createKillElement(killData) {
    // Incrémenter le compteur pour un ID unique
    killCount++;
    
    // Récupérer le template
    const template = document.getElementById('kill-template');

    // Cloner le template en un élément Node
    const killElement = template.cloneNode(true);
    
    // Donner un ID unique et rendre visible
    killElement.id = `kill-${killCount}`;
    killElement.style.display = 'block';
    killElement.classList.add('active');
    
    // Remplir les données
    fillKillData(killElement, killData);
    
    return killElement;
}

// Remplir les données dans l'élément HTML
function fillKillData(element, killData) {
    // Nom de la victime
    const victimName = element.querySelector('.victim-name');
    victimName.textContent = `${killData.killer} a tué ➔ ${killData.victim}`;
    
    // Points de base
    const basePoints = element.querySelector('.base-points');
    basePoints.textContent = `Kill ${killData.points} pts`;
    
    // Bonus
    const bonusesContainer = element.querySelector('.bonuses');
    const bonusPointsContainer = element.querySelector('.bonus-points');
    
    bonusesContainer.innerHTML = '';
    bonusPointsContainer.innerHTML = '';
    
    if (killData.bonuses && killData.bonuses.length > 0) {
        killData.bonuses.forEach(bonus => {
            // Texte du bonus
            const bonusText = formatBonusText(bonus);
            const bonusDiv = document.createElement('div');
            bonusDiv.className = 'bonus-item';
            bonusDiv.textContent = bonusText;
            bonusesContainer.appendChild(bonusDiv);
            
            // Points du bonus
            const bonusPointsDiv = document.createElement('div');
            bonusPointsDiv.className = 'bonus-points-item';
            bonusPointsDiv.textContent = `+${bonus.points} pts`;
            bonusPointsContainer.appendChild(bonusPointsDiv);
        });
    }
    
    // Total des points
    const totalPoints = element.querySelector('.total-points');
    totalPoints.textContent = `${killData.totalPoints} pts`;
}

// Formater le texte des bonus
function formatBonusText(bonus) {
    const bonusTexts = {
        headshot: 'Tir dans la tête',
        longdistance: 'Tir longue distance',
        killstreak: `Série de kills x${bonus.count}`
    };
    return bonusTexts[bonus.type] || 'Bonus';
}

// Supprimer le kill le plus ancien
function hideOldestKill() {
    const container = document.getElementById('killfeed-container');
    const kills = container.querySelectorAll('.kill-entry.active');
    
    if (kills.length > 0) {
        const oldestKill = kills[0];
        oldestKill.classList.add('fade-out');
        
        setTimeout(() => {
            if (oldestKill.parentNode) {
                oldestKill.remove();
            }
        }, 300); // Animation de fadeout
    }
}

// Limiter le nombre d'entrées affichées
function limitKillFeedEntries() {
    const container = document.getElementById('killfeed-container');
    const kills = container.querySelectorAll('.kill-entry.active');
    
    // Garder maximum 5 kills
    if (kills.length > MAX_KILLS_DISPLAYED) {
        // excessKills stock les kills en trop
        const excessKills = Array.from(kills).slice(0, kills.length - MAX_KILLS_DISPLAYED);

        // Supprimer les kills en trop
        excessKills.forEach(kill => {
            kill.remove();
        });
    }
}
