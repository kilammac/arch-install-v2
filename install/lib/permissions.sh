#!/usr/bin/env bash
verify_permissions() {
  local relative mode failed=0
  if ((DRY_RUN)); then info '[simulation] Contrôle des droits système et des fichiers publics avant le redémarrage.'; return; fi
  info 'Vérification des permissions nécessaires à une session utilisateur…'
  for relative in / /etc /etc/profile.d /usr /usr/bin /usr/lib /var /var/lib /var/cache /var/log /home /opt /opt/arch-insall; do
    mode=$(stat -Lc '%a' "$TARGET$relative") || return 1
    if (( (8#$mode & 0005) != 0005 )); then
      printf 'Dossier inaccessible aux utilisateurs : %s (mode %s)\n' "$relative" "$mode" >&2
      failed=1
    fi
  done
  for relative in /etc/profile /etc/passwd /etc/group /etc/nsswitch.conf /etc/shells /etc/hosts /etc/hostname /etc/locale.conf /etc/vconsole.conf /etc/fstab /usr/local/bin/start-hyprland; do
    mode=$(stat -Lc '%a' "$TARGET$relative") || return 1
    if (( (8#$mode & 0004) != 0004 )); then
      printf 'Fichier public illisible : %s (mode %s)\n' "$relative" "$mode" >&2
      failed=1
    fi
  done
  for relative in /etc/shadow /etc/gshadow; do
    mode=$(stat -Lc '%a' "$TARGET$relative") || return 1
    if (( (8#$mode & 0007) != 0 )); then
      printf 'Fichier de mots de passe accessible aux autres utilisateurs : %s\n' "$relative" >&2
      failed=1
    fi
  done
  if [[ -n ${LOG_FILE:-} ]]; then
    mode=$(stat -Lc '%a' "$LOG_FILE") || return 1
    if (( (8#$mode & 0077) != 0 )); then
      printf 'Le journal doit rester privé (mode actuel %s).\n' "$mode" >&2
      failed=1
    fi
  fi
  ((failed == 0)) || die 'Permissions incorrectes : ne redémarre pas avant correction.'
}
