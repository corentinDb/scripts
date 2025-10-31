#!/bin/bash

# =============================================================================
# Script d'installation et configuration automatique de Zsh + Oh-My-Zsh
# Pour Debian et dérivés (Ubuntu, Mint, etc.)
# =============================================================================

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Set locale to avoid encoding issues
export LANG=fr_FR.UTF-8
export LANGUAGE=fr_FR.UTF-8

# =============================================================================
# CONFIGURATION
# =============================================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Thème oh-my-zsh
ZSH_THEME="candy"

# Plugins oh-my-zsh
ZSH_PLUGINS=(
    git                          # Aliases et complétion git
    sudo                         # Appuyer 2x ESC pour ajouter sudo
    command-not-found            # Suggère le paquet à installer
    colored-man-pages            # Pages man colorées
    history-substring-search     # Recherche dans l'historique
    extract                      # Extraction facile d'archives (commande: extract <file>)
    docker                       # Aliases et complétion Docker
    docker-compose               # Aliases et complétion docker-compose
    ssh                          # Gestion SSH (host completion, ssh-add helpers)
    common-aliases               # Aliases courants pour commandes fréquentes
)

# Paquets obligatoires
REQUIRED_PACKAGES=(
    zsh                          # Shell interactif
    curl                         # Outil de transfert de données
    git                          # Système de gestion de versions
)

# Paquets optionnels: format "paquet:description"
# Structure unique pour faciliter la maintenance
declare -a OPTIONAL_PACKAGES=(
    "btop:Moniteur de processus interactif"
    "tree:Affiche la structure des répertoires"
    "vim:Éditeur de texte avancé"
    "jq:Processeur JSON en ligne de commande"
    "bat:Cat amélioré avec coloration syntaxique"
    "fzf:Chercheur flou interactif"
)

# =============================================================================
# FONCTIONS
# =============================================================================

# Affichage des messages
error_exit() {
    echo -e "${RED}❌ Erreur: $1${NC}" >&2
    exit 1
}

info() {
    echo -e "${GREEN}➜${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

success() {
    echo -e "${CYAN}✅ $1${NC}"
}

header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""
}

# =============================================================================
# VÉRIFICATIONS PRÉLIMINAIRES
# =============================================================================

header "Vérifications préliminaires"

# Vérifier qu'on n'est pas root
if [ "$EUID" -eq 0 ]; then
    error_exit "Ne pas exécuter ce script en tant que root. Utilisez un utilisateur normal avec sudo."
fi

# Vérifier que sudo est disponible
if ! command -v sudo &> /dev/null; then
    error_exit "sudo n'est pas installé. Installez-le d'abord : apt install sudo"
fi

info "Utilisateur: $USER"
info "Système: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
success "Vérifications OK"

# =============================================================================
# INSTALLATION DES PAQUETS
# =============================================================================

header "Installation des paquets système"

info "Mise à jour de la liste des paquets..."
sudo apt update || error_exit "La mise à jour des paquets a échoué"

info "Installation des paquets obligatoires..."
REQUIRED_STRING=$(printf "%s " "${REQUIRED_PACKAGES[@]}")
sudo apt install -y $REQUIRED_STRING || error_exit "L'installation des paquets obligatoires a échoué"

# Vérification des versions installées
ZSH_VERSION=$(zsh --version | cut -d' ' -f2)
success "Zsh $ZSH_VERSION installé"

# =============================================================================
# PAQUETS OPTIONNELS
# =============================================================================

header "Paquets optionnels"

info "Installation des paquets optionnels..."
# Extraire les noms de paquets (partie avant le ':')
OPTIONAL_NAMES=()
for item in "${OPTIONAL_PACKAGES[@]}"; do
    OPTIONAL_NAMES+=("${item%%:*}")
done

OPTIONAL_STRING=$(printf "%s " "${OPTIONAL_NAMES[@]}")
if sudo apt install -y $OPTIONAL_STRING 2>&1; then
    success "Paquets optionnels installés avec succès"
else
    warn "Certains paquets optionnels n'ont pas pu être installés"
fi

# =============================================================================
# INSTALLATION DE OH-MY-ZSH
# =============================================================================

header "Installation de Oh-My-Zsh"

# Vérifier si oh-my-zsh est déjà installé
if [ -d "$HOME/.oh-my-zsh" ]; then
    warn "Oh-My-Zsh est déjà installé dans $HOME/.oh-my-zsh"
    read -p "Voulez-vous réinstaller ? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Sauvegarde de l'ancien oh-my-zsh..."
        mv "$HOME/.oh-my-zsh" "$HOME/.oh-my-zsh.backup.$(date +%Y%m%d-%H%M%S)"
        if [ -f "$HOME/.zshrc" ]; then
            mv "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d-%H%M%S)"
        fi
    else
        info "Installation de oh-my-zsh ignorée"
        skip_omz=true
    fi
fi

if [ "${skip_omz:-false}" = false ]; then
    info "Téléchargement et installation de oh-my-zsh..."
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
        success "Oh-My-Zsh installé avec succès"
    else
        error_exit "L'installation de oh-my-zsh a échoué"
    fi
fi

# =============================================================================
# CONFIGURATION DE ZSH
# =============================================================================

header "Configuration de Zsh"

# Vérifier que .zshrc existe
if [ ! -f "$HOME/.zshrc" ]; then
    error_exit "Le fichier .zshrc n'existe pas. L'installation de oh-my-zsh a peut-être échoué."
fi

# Configuration du thème
info "Configuration du thème: $ZSH_THEME"
sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$ZSH_THEME\"/" "$HOME/.zshrc" || error_exit "Échec de la configuration du thème"

# Configuration des plugins
info "Configuration des plugins: ${ZSH_PLUGINS[*]}"
PLUGINS_STRING=$(printf "%s " "${ZSH_PLUGINS[@]}")
sed -i "s/^plugins=.*/plugins=($PLUGINS_STRING)/" "$HOME/.zshrc" || error_exit "Échec de la configuration des plugins"

# Décommenter la ligne export PATH de bash
info "Configuration du PATH bash..."
sed -i '2s/^#\s*//' "$HOME/.zshrc" 2>/dev/null || true

success "Configuration de base appliquée"

# =============================================================================
# AJOUT DES PERSONNALISATIONS
# =============================================================================

header "Ajout des personnalisations"

info "Ajout des options setopt, aliases et configurations personnalisées..."

# Créer un backup avant modification
cp "$HOME/.zshrc" "$HOME/.zshrc.pre-custom.$(date +%Y%m%d-%H%M%S)"

# Ajouter les personnalisations à la fin du fichier
cat >> "$HOME/.zshrc" << 'EOF'

# =============================================================================
# PERSONNALISATIONS PERSONNELLES
# =============================================================================

# ===== Options Zsh =====

# Historique optimisé
setopt HIST_REDUCE_BLANKS        # Supprime les espaces superflus
setopt HIST_SAVE_NO_DUPS         # Pas de doublons à la sauvegarde
setopt HIST_IGNORE_ALL_DUPS      # Supprime les anciens doublons

# Navigation améliorée
setopt PUSHD_SILENT              # Pas d'affichage automatique de la pile

# Globbing avancé
setopt EXTENDED_GLOB             # Patterns avancés **, ^, ~, #

# Sécurité
setopt NO_CLOBBER                # Empêche l'écrasement avec > (utiliser >| pour forcer)

# ===== Aliases ls =====
alias ls='ls --color=tty'
alias ll='ls -alhF'
alias l='ls -lhF'
alias la='ls -aF'

# ===== Aliases utiles =====
alias df='df -h'                                 # Espace disque lisible
alias free='free -h'                             # Mémoire lisible
alias mkdir='mkdir -pv'                          # Créer dossiers parents
alias wget='wget -c'                             # Continuer téléchargements
alias histg='history | grep'                     # Recherche dans historique

# ===== Fonctions utiles =====

psgrep() {
    ps aux | grep -v grep | grep -i -e VSZ -e "$@"
}

# Backup rapide d'un fichier
backup() {
    cp "$1"{,.backup-$(date +%Y%m%d-%H%M%S)}
}

# ===== Variables d'environnement =====
export EDITOR='vim'                              # Éditeur par défaut
export VISUAL='vim'
export PAGER='less'

# Configuration de less pour une meilleure expérience
export LESS='-R -M -i'
# -R : Affiche les couleurs ANSI (pour man coloré, git diff, etc.)
# -M : Prompt détaillé (ligne X de Y, pourcentage)
# -i : Recherche insensible à la casse (sauf si maj présente)

# ===== Format de l'historique =====
export HIST_STAMPS="yyyy-mm-dd"                     # Format des timestamps (histoire)

# ===== Prompt personnalisé (optionnel) =====
# PROMPT='%F{green}%n@%m%f:%F{blue}%~%f$ '

EOF

success "Personnalisations ajoutées"

# =============================================================================
# CHANGEMENT DU SHELL PAR DÉFAUT
# =============================================================================

header "Configuration du shell par défaut"

# Obtenir le chemin de zsh
ZSH_PATH=$(which zsh)
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)

if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
    success "Zsh est déjà le shell par défaut"
else
    info "Shell actuel: $CURRENT_SHELL"
    info "Changement du shell par défaut vers: $ZSH_PATH"

    # Essayer de changer avec sudo (sans demander de mot de passe)
    if sudo chsh -s "$ZSH_PATH" "$USER" 2>/dev/null; then
        success "Shell par défaut changé avec succès"
        echo "  → Le changement sera effectif lors de votre prochaine connexion"
    else
        warn "Impossible de changer le shell automatiquement"
        echo ""
        echo "Exécutez manuellement cette commande:"
        echo "  chsh -s \$(which zsh)"
        echo ""
    fi
fi

# =============================================================================
# FINALISATION ET LANCEMENT
# =============================================================================

echo ""
success "Installation terminée ! Zsh et Oh-My-Zsh sont configurés."
echo ""

# Lancer automatiquement zsh
exec zsh -l