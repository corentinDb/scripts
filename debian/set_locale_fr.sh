#!/bin/bash

# =============================================================================
# LOAD utils.sh
# =============================================================================

TEMP_DIR=$(mktemp -d)

# Charger les fonctions et configurations communes
echo "Téléchargement des utilitaires..."
curl -fsSL "https://dlbgd.fr/scripts/utils.sh" -o "$TEMP_DIR/utils.sh" || {
    echo "Erreur: Impossible de télécharger utils.sh"
    exit 1
}
source "$TEMP_DIR/utils.sh"

# =============================================================================
# CONFIGURATION
# =============================================================================

PREF_LANG="fr_FR.UTF-8"

# Set locale to avoid encoding issues
export LANG=$PREF_LANG
export LANGUAGE=$PREF_LANG
export LC_ALL=$PREF_LANG

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