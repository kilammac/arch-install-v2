#!/usr/bin/env bash
# À exécuter EXCLUSIVEMENT dans une VM QEMU jetable depuis l'ISO Arch.
set -Eeuo pipefail
[[ ${1:-} == --erase-disposable-vda ]] || { echo 'Option requise : --erase-disposable-vda' >&2; exit 2; }
[[ -d /run/archiso && -d /sys/firmware/efi && -b /dev/vda ]] || exit 2
[[ $(systemd-detect-virt) == kvm || $(systemd-detect-virt) == qemu ]] || exit 2
[[ $(lsblk -bdn -o SIZE /dev/vda) == 42949672960 ]] || { echo 'Disque virtuel attendu : 40 Gio.' >&2; exit 2; }
PROJECT=$(cd "$(dirname "$0")/.." && pwd)
DRY_RUN=0; TARGET=/mnt; DISK=/dev/vda
HOSTNAME=arch-vm; USERNAME=testeur; TIMEZONE=Africa/Algiers
LOCALE=fr_FR.UTF-8; KEYMAP=fr; XKB_LAYOUT=fr; KERNEL=linux; EXTRA_KERNEL=1; SESSION=console; NVIDIA_MODE=
for module in common ui detect disk packages system configs permissions; do
  # shellcheck source=/dev/null
  source "$PROJECT/install/lib/$module.sh"
done
pacman -Sy --needed --noconfirm gum gptfdisk btrfs-progs dosfstools pciutils usbutils parted xkeyboard-config
probe_hardware
select_drivers
collect_packages
validate_answers
validate_disk
preflight_packages
partition_and_mount
install_system
install_configs
verify_permissions
# Saisie des mots de passe à vérifier séparément sur terminal interactif.
printf 'VM-INSTALL-OK\n'
