#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

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


TEMPLATE_VMID=900
NEW_VMID=201
VM_NAME="vm-services"
CORES=8
MEMORY_MB=32768 # 32GB
TAGS="virtual-machine"

qm clone "$TEMPLATE_VMID" "$NEW_VMID" --name "$VM_NAME" --full
qm set "$NEW_VMID" --cores "$CORES" --memory "$MEMORY_MB"
qm set "$NEW_VMID" --tags "$TAGS"
qm set "$NEW_VMID" --boot order=scsi0