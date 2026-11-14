#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=install/lib/common.sh
source install/lib/common.sh
# shellcheck source=install/lib/system.sh
source install/lib/system.sh
# shellcheck source=install/lib/permissions.sh
source install/lib/permissions.sh
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
DRY_RUN=0
TARGET=$fixture/root
# Reproduire la création des parents de pacstrap sous le masque problématique.
# shellcheck disable=SC2174
(umask 077; mkdir -m755 -p "$fixture/before/etc/pacman.d")
[[ $(stat -c %a "$fixture/before/etc") == 700 ]]
# Même sous un masque hérité restrictif, les fichiers publics ont un mode fixé.
(
  umask 077
  write_file "$TARGET/etc/nested/public.conf" <<< 'public'
  write_file "$TARGET/etc/nested/private.conf" 600 <<< 'private'
  write_file "$TARGET/etc/sudoers.d/test" 440 <<< '%wheel ALL=(ALL:ALL) ALL'
  [[ $(umask) == 0077 ]]
)
[[ $(stat -c %a "$TARGET/etc") == 755 ]]
[[ $(stat -c %a "$TARGET/etc/nested/public.conf") == 644 ]]
[[ $(stat -c %a "$TARGET/etc/nested/private.conf") == 600 ]]
[[ $(stat -c %a "$TARGET/etc/sudoers.d/test") == 440 ]]
# Vérifier le masque réel transmis à pacstrap et au chroot, sans les exécuter.
if bash -s -- "$PWD" "$fixture" <<'CHECK'
set -Eeuo pipefail
source "$1/install/lib/common.sh"
source "$1/install/lib/system.sh"
fixture=$2; TARGET=$fixture/root; DRY_RUN=0; PACKAGES=(base)
umask 077
run() {
  [[ $1 == pacstrap && $(umask) == 0022 ]] || exit 95
  printf 'pacstrap-022\n' > "$fixture/pacstrap-mask"
  # Arrêt volontaire avant toute autre opération système.
  exit 77
}
install_system
CHECK
then exit 1
else [[ $? == 77 ]]
fi
[[ $(cat "$fixture/pacstrap-mask") == pacstrap-022 ]]
(
  umask 077
  run() { [[ $1 == arch-chroot && $(umask) == 0022 ]]; }
  chroot_run true
  [[ $(umask) == 0077 ]]
)
# Le vérificateur doit accepter les fichiers publics et refuser les régressions.
for dir in etc/profile.d usr/bin usr/lib usr/local/bin var/lib var/cache var/log home opt/arch-insall; do
  mkdir -p "$TARGET/$dir"
done
for file in profile passwd group nsswitch.conf shells hosts hostname locale.conf vconsole.conf fstab; do
  write_file "$TARGET/etc/$file" <<< test
done
write_file "$TARGET/usr/local/bin/start-hyprland" 755 <<< '#!/bin/bash'
write_file "$TARGET/etc/shadow" 600 <<< test
write_file "$TARGET/etc/gshadow" 600 <<< test
LOG_FILE=$fixture/install.log
install -m600 /dev/null "$LOG_FILE"
verify_permissions
chmod 700 "$TARGET/etc"
if (verify_permissions) > "$fixture/failure.log" 2>&1; then exit 1; fi
grep -q 'Dossier inaccessible' "$fixture/failure.log"
chmod 755 "$TARGET/etc"
chmod 644 "$TARGET/etc/shadow"
if (verify_permissions) > "$fixture/failure.log" 2>&1; then exit 1; fi
grep -q 'Fichier de mots de passe accessible' "$fixture/failure.log"
printf 'OK : droits publics/privés, masque pacstrap/chroot et détection des permissions incorrectes.\n'
