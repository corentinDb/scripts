#!/bin/bash

# =============================================================================
# Script d'installation et configuration automatique de Zsh + Oh-My-Zsh
# Pour Debian et dérivés (Ubuntu, Mint, etc.)
# =============================================================================

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

PREF_LANG=fr_FR.UTF-8

# Set locale to avoid encoding issues
export LANG=$PREF_LANG
export LANGUAGE=$PREF_LANG
export LC_ALL=$PREF_LANG

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
    sudo                         # Appuyer 2x ESC pour ajouter sudo
    command-not-found            # Suggère le paquet à installer
    colored-man-pages            # Pages man colorées
    history-substring-search     # Recherche dans l'historique
    extract                      # Extraction facile d'archives (commande: extract <file>)
    docker                       # Aliases et complétion Docker
    docker-compose               # Aliases et complétion docker-compose
    ssh                          # Gestion SSH (host completion, ssh-add helpers)
    fzf
    nvm
)

# Variables d'environnement à exporter avant oh-my-zsh
declare -A ENV_VARS=(
    [EDITOR]="vim"               # Éditeur par défaut
    [VISUAL]="vim"               # Éditeur visuel
    [PAGER]="less"               # Pager par défaut
    [HISTSIZE]="10000"           # Taille de l'historique
    [SAVEHIST]="10000"           # Nombre d'entrées sauvegardées
    [ZSH_COMPDUMP]="\$ZSH/cache/.zcompdump-\$HOST" # Fichier zcompdump
    [LESS]="-R -M -i"            # Configuration de less: -R : Affiche les couleurs ANSI (pour man coloré, git diff, etc.) | -M : Prompt détaillé (ligne X de Y, pourcentage) | -i : Recherche insensible à la casse (sauf si maj présente)
    [HIST_STAMPS]="yyyy-mm-dd"   # Format des timestamps de l'historique
    [LANG]="$PREF_LANG"         # Locale par défaut
    [LANGUAGE]="$PREF_LANG"     # Langue préférée
    [LC_ALL]="$PREF_LANG"       # Locale pour toutes les catégories (écrase les LC_*)
    # Preview file content using bat (https://github.com/sharkdp/bat)
    [FZF_CTRL_T_OPTS]="--preview 'batcat -n --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
    # CTRL-Y to copy the command into clipboard using pbcopy
    [FZF_CTRL_R_OPTS]="--bind 'ctrl-y:execute-silent(echo -n {2..} | xsel --clipboard)+abort' --color header:italic --header 'Press CTRL-Y to copy command into clipboard'"
    # Print tree structure in the preview window
    [FZF_ALT_C_OPTS]="--preview 'tree -C {}'"
    # FZF default options: walker-skip common directories (inherited by other FZF options)
    [FZF_DEFAULT_OPTS]="--walker-skip .git,node_modules,target,.idea,.claude"
)

# Paquets obligatoires
REQUIRED_PACKAGES=(
    zsh                          # Shell interactif
    curl                         # Outil de transfert de données
    git                          # Système de gestion de versions
)

# Paquets Homebrew à installer
BREW_PACKAGES=(
    fzf                        # Chercheur flou interactif
)

# Paquets optionnels
OPTIONAL_PACKAGES=(
    btop
    tree
    vim
    jq
    bat
    xsel
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

info "Mise à jour de la liste des paquets..."
sudo apt update || error_exit "La mise à jour des paquets a échoué"

# Vérifier et générer les locales si nécessaire
info "Vérification des locales..."
if ! locale -a | grep -q "${ENV_VARS["LANG"]}"; then
    warn "La locale ${ENV_VARS["LANG"]} n'est pas générée"
    info "Génération de la locale ${ENV_VARS["LANG"]}..."
    if ! which locale-gen > /dev/null 2>&1; then
        sudo apt update && sudo apt install -y locales
    fi
    sudo sed -i "s/^# *\(${ENV_VARS["LANG"]} UTF-8\)/\1/" /etc/locale.gen
    sudo locale-gen 2>/dev/null || warn "Impossible de générer la locale ${ENV_VARS["LANG"]}"
    sudo update-locale LANG=${ENV_VARS["LANG"]} 2>/dev/null || warn "Impossible de mettre à jour LANG vers ${ENV_VARS["LANG"]}"
    success "Locale ${ENV_VARS["LANG"]} déjà générée"
else
    success "Locale ${ENV_VARS["LANG"]} déjà présente générée"
fi

info "Utilisateur: $USER"
info "Système: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
success "Vérifications OK"

# =============================================================================
# INSTALLATION DES PAQUETS
# =============================================================================

header "Installation des paquets système"

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
OPTIONAL_STRING=$(printf "%s " "${OPTIONAL_PACKAGES[@]}")
if sudo apt install -y $OPTIONAL_STRING 2>&1; then
    success "Paquets optionnels installés avec succès"
else
    warn "Certains paquets optionnels n'ont pas pu être installés"
fi

# =============================================================================
# INSTALLATION DE HOMEBREW
# =============================================================================

header "Installation de Homebrew"

# Vérifier si l'utilisateur linuxbrew existe, sinon le créer
info "Vérification de l'utilisateur linuxbrew..."
if ! id linuxbrew &>/dev/null; then
    info "Création de l'utilisateur linuxbrew..."
    if sudo useradd --create-home linuxbrew; then
        success "Utilisateur linuxbrew créé"
    else
        warn "Impossible de créer l'utilisateur linuxbrew"
    fi
else
    success "L'utilisateur linuxbrew existe déjà"
fi

# Vérifier si brew est déjà installé
if sudo -H -i -u linuxbrew command -v brew &> /dev/null; then
    BREW_VERSION=$(sudo -H -i -u linuxbrew brew --version | head -1)
    success "Homebrew est déjà installé: $BREW_VERSION"
else
    info "Homebrew n'est pas installé, installation en cours..."
    if curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | sudo -H -u linuxbrew NONINTERACTIVE=1 bash; then
        success "Homebrew installé avec succès"

        # Rendre le répertoire linuxbrew exécutable pour tout le monde
        info "Configuration des permissions..."
        sudo chmod -R a+x /home/linuxbrew || warn "Impossible de configurer les permissions"

        # Configuration de brew shellenv pour linuxbrew
        info "Configuration de Homebrew pour l'utilisateur linuxbrew..."
        sudo bash -c "echo >> /home/linuxbrew/.profile"
        sudo bash -c "echo 'eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\"' >> /home/linuxbrew/.profile"

    else
        warn "Impossible d'installer Homebrew"
    fi
fi

# =============================================================================
# INSTALLATION DES PACKAGES HOMEBREW
# =============================================================================

header "Installation des packages Homebrew"

info "Installation des packages Homebrew: ${BREW_PACKAGES[*]}"
if sudo -H -i -u linuxbrew command -v brew &> /dev/null; then
    for package in "${BREW_PACKAGES[@]}"; do
        info "Installation de $package..."
        if sudo -H -i -u linuxbrew brew install "$package" 2>&1 | grep -q "already installed"; then
            success "$package est déjà installé"
        elif sudo -H -i -u linuxbrew brew install "$package"; then
            success "$package installé avec succès"
        else
            warn "Impossible d'installer $package"
        fi
    done
else
    warn "Homebrew n'est pas disponible, installation des packages Homebrew ignorée"
fi

# =============================================================================
# INSTALLATION DE OH-MY-ZSH
# =============================================================================

header "Installation de Oh-My-Zsh"

# Vérifier si oh-my-zsh est déjà installé
if [ -d "$HOME/.oh-my-zsh" ]; then
    warn "Oh-My-Zsh est déjà installé dans $HOME/.oh-my-zsh"
    # Prompt for user confirmation, works both with direct execution and piped execution (curl | bash)
    if [ -t 0 ] || [ -c /dev/tty ]; then
        # Interactive mode: read from terminal
        read -p "Voulez-vous réinstaller ? [y/N]: " -r response < /dev/tty || response=""
    else
        # Non-interactive mode: default to skipping
        response=""
    fi
    # Normalize response to lowercase for comparison
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
    if [[ "$response" =~ ^(y|yes|o|oui)$ ]]; then
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

# Configuration de Homebrew dans .zshrc pour tous les cas (déjà installé ou nouvellement installé)
if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    info "Configuration de Homebrew dans .zshrc..."
    # Créer le bloc Homebrew avec headers
    {
        echo "# BEGIN INSTALL_ZSH_SCRIPT_HOMEBREW"
        echo ""
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
        echo ""
        echo "# END INSTALL_ZSH_SCRIPT_HOMEBREW"
    } > /tmp/homebrew_config.txt

    # Supprimer l'ancien bloc s'il existe (éviter les doublons)
    sed -i '/# BEGIN INSTALL_ZSH_SCRIPT_HOMEBREW/,/# END INSTALL_ZSH_SCRIPT_HOMEBREW/d' "$HOME/.zshrc" 2>/dev/null || true

    # Insérer le bloc avant la ligne source $ZSH/oh-my-zsh.sh
    awk '/source \$ZSH\/oh-my-zsh.sh/ {system("cat /tmp/homebrew_config.txt"); print; next} {print}' "$HOME/.zshrc" > /tmp/.zshrc.tmp && mv /tmp/.zshrc.tmp "$HOME/.zshrc" && rm /tmp/homebrew_config.txt || error_exit "Échec de l'ajout de la configuration Homebrew"

    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    success "Configuration Homebrew ajoutée à .zshrc"
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

# Configuration des variables d'environnement avant oh-my-zsh
info "Ajout des variables d'environnement..."
{
    echo "# BEGIN INSTALL_ZSH_SCRIPT_ENV_VARS"
    echo "# ============================================================================="
    echo "# VARIABLES D'ENVIRONNEMENT (à exporter avant oh-my-zsh)"
    echo "# ============================================================================="
    echo ""

    # Exporter chaque variable d'environnement
    for key in "${!ENV_VARS[@]}"; do
        echo "export $key=\"${ENV_VARS[$key]}\""
    done
    echo ""
    echo "# END INSTALL_ZSH_SCRIPT_ENV_VARS"
} > /tmp/env_vars.txt

# Supprimer le bloc ancien s'il existe (éviter les doublons)
sed -i '/# BEGIN INSTALL_ZSH_SCRIPT_ENV_VARS/,/# END INSTALL_ZSH_SCRIPT_ENV_VARS/d' "$HOME/.zshrc" 2>/dev/null || true

# Insérer le bloc avant la ligne source $ZSH/oh-my-zsh.sh
awk '/source \$ZSH\/oh-my-zsh.sh/ {system("cat /tmp/env_vars.txt"); print; next} {print}' "$HOME/.zshrc" > /tmp/.zshrc.tmp && mv /tmp/.zshrc.tmp "$HOME/.zshrc" && rm /tmp/env_vars.txt || error_exit "Échec de l'ajout des variables d'environnement"

success "Configuration de base appliquée"

# =============================================================================
# AJOUT DES PERSONNALISATIONS
# =============================================================================

header "Ajout des personnalisations"

info "Ajout des options setopt, aliases et configurations personnalisées..."

# Créer un backup avant modification
cp "$HOME/.zshrc" "$HOME/.zshrc.pre-custom.$(date +%Y%m%d-%H%M%S)"

# Supprimer l'ancien bloc s'il existe (éviter les doublons)
sed -i '/# BEGIN INSTALL_ZSH_SCRIPT_CUSTOM_CONFIG/,/# END INSTALL_ZSH_SCRIPT_CUSTOM_CONFIG/d' "$HOME/.zshrc" 2>/dev/null || true

# Ajouter les personnalisations à la fin du fichier
cat >> "$HOME/.zshrc" << 'EOF'
# BEGIN INSTALL_ZSH_SCRIPT_CUSTOM_CONFIG
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
alias l='ls -lhF'
alias lt='l -tr'
alias ld='l -d .*'
alias ll='l -a'
alias llt='ll -tr'

# ===== Aliases recherche =====
alias grep='grep --color'
alias sgrep='grep -R -n -H -C 5 --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv} '
(( $+commands[fd] )) || alias fd='find . -type d -name'
alias ff='find . -type f -name'

# ===== Aliases adminsys =====
alias dud='du -d 1 -h'
(( $+commands[duf] )) || alias duf='du -sh *'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# ===== Aliases utiles =====
alias df='df -h'                                 # Espace disque lisible
alias free='free -h'                             # Mémoire lisible
alias mkdir='mkdir -pv'                          # Créer dossiers parents
alias wget='wget -c'                             # Continuer téléchargements
alias h='history'                                # Raccourcis
alias hgrep="fc -El 0 | grep"                    # Recherche dans historique
alias sudo='sudo '                               # Permet d'utiliser les aliases avec sudo https://askubuntu.com/a/22043

# ===== Aliases bat =====
alias bat="batcat"
alias bcat='bat --paging=never'
alias bathelp='bat --plain --language=help'
bhelp() {
    "$@" --help 2>&1 | bathelp
}
batdiff() {
    git diff --name-only --relative --diff-filter=d -z | xargs -0 batcat --diff
}

# ===== Aliases fzf =====
alias fz='fzf --style full \
    --border --padding 1,2 \
    --border-label " Demo " --input-label " Input " --header-label " File Type " \
    --preview "fzf-preview.sh {}" \
    --bind "result:transform-list-label:
        if [[ -z \$FZF_QUERY ]]; then
          echo \" \$FZF_MATCH_COUNT items \"
        else
          echo \" \$FZF_MATCH_COUNT matches for [\$FZF_QUERY] \"
        fi
        " \
    --bind "focus:transform-preview-label:[[ -n {} ]] && printf \" Previewing [%s] \" {}" \
    --bind "focus:+transform-header:file --brief {} || echo \"No file selected\"" \
    --bind "ctrl-r:change-list-label( Reloading the list )+reload(sleep 2; git ls-files)" \
    --color "border:#aaaaaa,label:#cccccc" \
    --color "preview-border:#9999cc,preview-label:#ccccff" \
    --color "list-border:#669966,list-label:#99cc99" \
    --color "input-border:#996666,input-label:#ffcccc" \
    --color "header-border:#6699cc,header-label:#99ccff"'

# ===== Aliases brew =====
alias brew='sudo -H -i -u linuxbrew brew '

# ===== Fonctions utiles =====
# Backup rapide d'un fichier
backup() {
    cp "$1"{,.backup-$(date +%Y%m%d-%H%M%S)}
}

# END INSTALL_ZSH_SCRIPT_CUSTOM_CONFIG
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