#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

PREF_LANG="fr_FR.UTF-8"

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

header "Vérifications préliminaires"

# Vérifier qu'on n'est pas root
if [ "$EUID" -eq 0 ]; then
    error_exit "Ne pas exécuter ce script en tant que root. Utilisez un utilisateur normal avec sudo."
fi

# Vérifier que sudo est disponible
if ! command -v sudo &> /dev/null; then
    error_exit "sudo n'est pas installé. Installez-le d'abord : apt install sudo"
fi

header "Mise à jour de la liste des paquets..."
sudo apt update || error_exit "La mise à jour des paquets a échoué"

# Vérifier et générer les locales si nécessaire
header "Vérification des locales..."
if ! locale -a | grep -q "${PREF_LANG}"; then
    warn "La locale ${PREF_LANG} n'est pas générée"
    info "Génération de la locale ${PREF_LANG}..."
    if ! which locale-gen > /dev/null 2>&1; then
        sudo apt update && sudo apt install -y locales
    fi
    sudo sed -i "s/^# *\(${PREF_LANG} UTF-8\)/\1/" /etc/locale.gen
    sudo locale-gen 2>/dev/null || warn "Impossible de générer la locale ${PREF_LANG}"
    sudo update-locale LANG=${PREF_LANG} 2>/dev/null || warn "Impossible de mettre à jour LANG vers ${PREF_LANG}"
    success "Locale ${PREF_LANG} générée"
else
    success "Locale ${PREF_LANG} déjà présente"
fi