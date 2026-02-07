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

header "Vérifications préliminaires"

# Vérifier qu'on n'est pas root
if [ "$EUID" -ne 0 ]; then
    error_exit "Exécuter ce script en tant que root ou sudo."
fi

header "Mise à jour de la liste des paquets..."
apt update || error_exit "La mise à jour des paquets a échoué"

TMP_DIR=$(mktemp -d)
DEBIAN_VERSION=13
DEBIAN_NAME="trixie"
DEBIAN_FILE="debian-${DEBIAN_VERSION}-generic-amd64.raw"
SHA512SUMS_URL="https://cloud.debian.org/images/cloud/${DEBIAN_NAME}/latest/SHA512SUMS"
DOWNLOAD_URL="https://cloud.debian.org/images/cloud/${DEBIAN_NAME}/latest/${DEBIAN_FILE}"
IMAGE_PATH="${TMP_DIR}/${DEBIAN_FILE}"

VM_ID=900
STORAGE="local-lvm"
VM_NAME="debian-${DEBIAN_VERSION}-cloud-template"
CPU=2
RAM=4096
BRIDGE="vmbr0"
DISK_SIZE=5 # En Go


if qm list | grep -q " $VM_ID "; then
    error_exit "La VM $VM_ID existe déjà"
fi

wget "$DOWNLOAD_URL" --inet4-only -P "$TMP_DIR" || { error_exit "Impossible de télécharger l'image ${DEBIAN_FILE}"; }

virt-customize \
    -a "$IMAGE_PATH" \
    --update \
    --install qemu-guest-agent \
    --run-command 'apt-get clean && apt-get autoremove -y' \
    --run-command 'cloud-init clean --logs --seed' \
    --run-command 'rm -f /etc/ssh/ssh_host_*' \
    --run-command 'truncate -s 0 /etc/machine-id && rm -f /var/lib/dbus/machine-id && ln -s /etc/machine-id /var/lib/dbus/machine-id' \
    --run-command 'rm -f /root/.bash_history'

qm create "$VM_ID" --name "$VM_NAME" --memory "$RAM" --cores "$CPU" --net0 virtio,bridge=${BRIDGE} --cpu "x86-64-v2-AES" --scsihw virtio-scsi-pci --boot c --bootdisk scsi0

qm importdisk "$VM_ID" "$IMAGE_PATH" "$STORAGE"

qm set "$VM_ID" --scsi0 "${STORAGE}:vm-${VM_ID}-disk-0" --ide2 local-lvm:cloudinit --agent enabled=1 --ipconfig0 ip=dhcp

qm disk resize "$VM_ID" scsi0 "${DISK_SIZE}G"

qm template "$VM_ID"
