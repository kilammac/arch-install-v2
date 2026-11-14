#!/usr/bin/env bash
set -Eeuo pipefail
# Le masque privé des téléchargements/journaux ne doit pas être hérité par
# pacstrap : ses répertoires intermédiaires doivent rester traversables.
umask 022
# Ne pas activer xtrace : les mots de passe passent uniquement par passwd.
DRY_RUN=0; BOOTSTRAP_ONLY=0
REPO=kilammac/arch-insall; REF=main
DISK=/dev/vda; HOSTNAME=archlinux; USERNAME=utilisateur
TIMEZONE=Africa/Algiers; LOCALE=fr_FR.UTF-8; KEYMAP=fr; XKB_LAYOUT=fr
KERNEL=linux; EXTRA_KERNEL=0; SESSION=console; NVIDIA_MODE=
TARGET=/mnt
usage() {
  cat <<'HELP'
Usage : bash install.sh [--dry-run] [--repo propriétaire/dépôt] [--ref branche|tag|commit]
  --branch REF        synonyme de --ref
  --disk /dev/...     disque illustré dans la simulation uniquement
  --bootstrap-only   télécharger et vérifier la structure, puis quitter
  --help             afficher cette aide
L'installation réelle demande les choix dans des menus puis une confirmation.
La simulation utilise des réponses d'exemple et ne demande aucun mot de passe.
HELP
}
ARGS=("$@")
while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1;;
    --bootstrap-only) BOOTSTRAP_ONLY=1;;
    --repo|--ref|--branch|--disk)
      (($# >= 2)) || { echo "Argument manquant : $1" >&2; exit 2; }
      case "$1" in --repo) REPO=$2;; --ref|--branch) REF=$2;; --disk) DISK=$2;; esac
      shift;;
    --help|-h) usage; exit 0;;
    *) usage >&2; exit 2;;
  esac
  shift
done
[[ $REPO =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { echo 'Dépôt invalide' >&2; exit 2; }
[[ $REF =~ ^[A-Za-z0-9][A-Za-z0-9._/-]*$ && $REF != *..* ]] || { echo 'Référence invalide' >&2; exit 2; }
SELF_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ ! -f $SELF_DIR/lib/common.sh ]]; then
  # Ce téléchargement et son extraction dans /tmp sont les seules écritures de l'amorçage.
  umask 077
  BOOTSTRAP_DIR=$(mktemp -d /tmp/arch-insall.XXXXXXXX)
  trap 'rm -rf -- "$BOOTSTRAP_DIR"' EXIT
  curl --fail --show-error --silent --location --retry 3 --connect-timeout 15 --max-time 180 \
    "https://codeload.github.com/$REPO/tar.gz/$REF" -o "$BOOTSTRAP_DIR/source.tar.gz"
  mkdir "$BOOTSTRAP_DIR/source"
  tar -xzf "$BOOTSTRAP_DIR/source.tar.gz" --strip-components=1 --no-same-owner -C "$BOOTSTRAP_DIR/source"
  [[ -f $BOOTSTRAP_DIR/source/install/lib/common.sh && -f $BOOTSTRAP_DIR/source/post-install.sh && -d $BOOTSTRAP_DIR/source/configs ]] || { echo 'Archive incomplète' >&2; exit 1; }
  bash "$BOOTSTRAP_DIR/source/install/install.sh" "${ARGS[@]}"
  exit $?
fi
PROJECT=$(cd "$SELF_DIR/.." && pwd)
for module in common ui detect disk packages system configs permissions; do
  # shellcheck source=/dev/null
  source "$SELF_DIR/lib/$module.sh"
done
if ((BOOTSTRAP_ONLY)); then info "Amorçage vérifié : $REPO, référence $REF"; exit 0; fi
trap 'printf "Échec à la ligne %s. Consulte le journal ; aucun redémarrage automatique.\n" "$LINENO" >&2' ERR
if ((!DRY_RUN)); then
  ((EUID == 0)) || die 'Lance ce script comme root depuis l’ISO Arch Linux.'
  [[ -d /run/archiso && $(uname -m) == x86_64 ]] || die 'Installation autorisée seulement depuis l’ISO Arch x86_64.'
  [[ -d /sys/firmware/efi/efivars ]] || die 'Redémarre l’ISO en mode UEFI.'
  secure_boot=/sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c
  if [[ -r $secure_boot && $(od -An -tu1 -j4 -N1 "$secure_boot" | tr -d ' ') == 1 ]]; then die 'Désactive Secure Boot avant cette installation.'; fi
  curl -fsSL --connect-timeout 10 --max-time 20 https://archlinux.org/ -o /dev/null || die 'Connecte l’ISO à Internet (iwctl pour le Wi-Fi).'
  timedatectl set-ntp true
  pacman -Sy --needed --noconfirm gum gptfdisk btrfs-progs dosfstools pciutils usbutils parted xkeyboard-config
fi
if ! command -v lspci >/dev/null || ! command -v lsusb >/dev/null; then die "Détection : pciutils et usbutils requis."; fi
probe_hardware
if ((!DRY_RUN)); then questionnaire; validate_disk; else validate_answers; fi
select_drivers
collect_packages
info 'Plan : disque entier, EFI 2 Gio + Btrfs, sans chiffrement ni snapshots.'
if [[ -b $DISK ]]; then lsblk -d -o NAME,SIZE,MODEL,SERIAL,TRAN "$DISK"; else printf 'Disque illustratif : %s\n' "$DISK"; fi
printf 'Machine : %s ; utilisateur : %s ; langue : %s ; clavier : %s/%s ; fuseau : %s\n' "$HOSTNAME" "$USERNAME" "$LOCALE" "$KEYMAP" "$XKB_LAYOUT" "$TIMEZONE"
printf 'CPU : %s ; GPU : %s ; multi-GPU : %s ; NVIDIA : %s ; Wi-Fi : %s ; Bluetooth : %s ; portable : %s ; VM : %s\n' "$HW_CPU" "$HW_GPU_COUNT" "$HW_HYBRID" "${NVIDIA_MODE:-$HW_NVIDIA}" "$HW_WIFI" "$HW_BLUETOOTH" "$HW_LAPTOP" "$HW_VIRT"
printf 'Paquets : %s\n' "${PACKAGES[*]}"
printf 'Note : %s\n' "${HW_NOTES[@]}"
if ((!DRY_RUN)); then
  preflight_packages
  confirm "Effacer entièrement $DISK et installer Arch Linux ?" || die 'Annulé.'
  validate_disk
  LOG_DIR=$(mktemp -d /tmp/arch-insall-log.XXXXXXXX)
  LOG_FILE="$LOG_DIR/install.log"
  install -m600 /dev/null "$LOG_FILE"
  exec > >(tee -a "$LOG_FILE") 2>&1
  printf 'Journal : %s\n' "$LOG_FILE"
fi
partition_and_mount
install_system
install_configs
verify_permissions
set_passwords
if ((!DRY_RUN)); then
  install -Dm600 "$LOG_FILE" "$TARGET/var/log/arch-insall.log"
  sync
fi
info 'Terminé. Aucun redémarrage automatique.'
info 'Depuis l’ISO : umount -R /mnt puis reboot. Après connexion : start-hyprland'
info 'Post-install : bash /opt/arch-insall/post-install.sh'
