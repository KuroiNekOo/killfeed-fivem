console.log('[Killfeed] Interface JavaScript chargée');

// Configuration
const KILLFEED_DURATION = 3000; // 3 secondes
const MAX_KILLS_DISPLAYED = 5; // Nombre maximum de kills affichés
let killCount = 0; // Pour donner un ID unique à chaque kill

// Pool d'éléments pour optimiser la performance
const killElementPool = []; // Stock des éléments réutilisables
const MAX_POOL_SIZE = 8; // Maximum 8 éléments dans le pool (plus que MAX_KILLS_DISPLAYED)
const activeKillElements = new Set(); // Éléments actuellement affichés

// Initialisation de l'interface HTML
document.addEventListener('DOMContentLoaded', function() {
    console.log('[Killfeed] DOM chargé, interface prête');
    
    // Pré-remplir le pool avec quelques éléments pour des performances optimales
    initializeKillElementPool();
    
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

// Fonction pour pré-remplir le pool d'éléments au démarrage
function initializeKillElementPool() {
    const initialPoolSize = 3; // Créer 3 éléments à l'avance
    
    for (let i = 0; i < initialPoolSize; i++) {
        const element = createNewKillElement();
        resetKillElement(element); // S'assurer qu'il est prêt
        killElementPool.push(element);
    }
    
    console.log(`[Killfeed] Pool initialisé avec ${initialPoolSize} éléments`);
}

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
    
    // Emprunter un élément du pool (ou en créer un nouveau)
    const killElement = borrowKillElement();
    
    // Remplir les données
    fillKillData(killElement, killData);
    
    // Ajouter au container
    const container = document.getElementById('killfeed-container');
    container.appendChild(killElement);
    
    // Programmer le retour automatique au pool
    setTimeout(() => {
        if (killElement.parentNode) {
            killElement.parentNode.removeChild(killElement);
        }
        // Rendre l'élément au pool au lieu de le supprimer
        returnKillElementToPool(killElement);
    }, KILLFEED_DURATION);
    
    // Limiter le nombre de kills affichés (max 5)
    limitKillFeedEntries();
}

// Fonction pour emprunter un élément du pool (ou en créer un nouveau)
function borrowKillElement() {
    let killElement;
    
    if (killElementPool.length > 0) {
        // Il y a un élément disponible dans le pool → le réutiliser
        killElement = killElementPool.pop();
        console.log(`[Killfeed] Élément réutilisé du pool (${killElementPool.length} restants)`);
    } else {
        // Pas d'élément disponible → en créer un nouveau
        killElement = createNewKillElement();
        console.log('[Killfeed] Nouvel élément créé');
    }
    
    // Préparer l'élément pour utilisation
    killElement.style.display = 'block';
    killElement.classList.add('active');
    killElement.classList.remove('fade-out');
    
    // L'ajouter au tracking des éléments actifs
    activeKillElements.add(killElement);
    
    return killElement;
}

// Fonction pour créer un nouvel élément HTML (utilisée quand le pool est vide)
function createNewKillElement() {
    // Incrémenter le compteur pour un ID unique
    killCount++;
    
    // Récupérer le template et le cloner
    const template = document.getElementById('kill-template');
    const killElement = template.cloneNode(true);
    
    // Donner un ID unique
    killElement.id = `kill-${killCount}`;
    
    return killElement;
}

// Fonction pour rendre un élément au pool après usage
function returnKillElementToPool(killElement) {
    // Retirer du tracking des éléments actifs
    activeKillElements.delete(killElement);
    
    // Nettoyer l'élément pour réutilisation
    resetKillElement(killElement);
    
    // Le remettre dans le pool s'il y a de la place
    if (killElementPool.length < MAX_POOL_SIZE) {
        killElementPool.push(killElement);
        console.log(`[Killfeed] Élément rendu au pool (${killElementPool.length} disponibles)`);
    } else {
        // Pool plein → supprimer définitivement l'élément
        killElement.remove();
        console.log('[Killfeed] Élément supprimé (pool plein)');
    }
}

// Fonction pour nettoyer un élément avant de le remettre dans le pool
function resetKillElement(element) {
    // Cacher l'élément et retirer les classes d'animation
    element.style.display = 'none';
    element.classList.remove('active', 'fade-out');
    
    // Vider le contenu pour éviter les fuites de données
    const victimName = element.querySelector('.victim-name');
    const bonuses = element.querySelector('.bonuses');
    const basePoints = element.querySelector('.base-points');
    const bonusPoints = element.querySelector('.bonus-points');
    const totalPoints = element.querySelector('.total-points');
    
    if (victimName) victimName.textContent = '';
    if (bonuses) bonuses.innerHTML = '';
    if (basePoints) basePoints.textContent = '';
    if (bonusPoints) bonusPoints.innerHTML = '';
    if (totalPoints) totalPoints.textContent = '';
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
                oldestKill.parentNode.removeChild(oldestKill);
            }
            // Rendre l'élément au pool au lieu de le supprimer
            returnKillElementToPool(oldestKill);
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

        // Retourner les kills en trop au pool
        excessKills.forEach(kill => {
            if (kill.parentNode) {
                kill.parentNode.removeChild(kill);
            }
            returnKillElementToPool(kill);
        });
    }
}
