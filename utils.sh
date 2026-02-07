#!/bin/bash

# =============================================================================
# FICHIER UTILITAIRE COMMUN - utils.sh
# Fonctions et configurations communes à tous les scripts
# =============================================================================

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# =============================================================================
# CONFIGURATION COMMUNE
# =============================================================================

# Locale par défaut
PREF_LANG="fr_FR.UTF-8"
export LANG=$PREF_LANG
export LANGUAGE=$PREF_LANG
export LC_ALL=$PREF_LANG

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =============================================================================
# FONCTIONS COMMUNES
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
# VÉRIFICATIONS PRÉLIMINAIRES COMMUNES
# =============================================================================

common_preflight_checks() {
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
}