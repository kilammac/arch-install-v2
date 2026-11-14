#!/usr/bin/env bash
# Fonctions communes, sans effet au chargement.
die() { printf 'Erreur : %s\n' "$*" >&2; exit 1; }
info() { printf '\n%s\n' "$*" >&2; }
run() {
  printf '+ ' >&2; printf '%q ' "$@" >&2; printf '\n' >&2
  if ((DRY_RUN)); then return 0; fi
  "$@"
}
write_file() (
  local path=$1 mode=${2:-644}
  if ((DRY_RUN)); then printf '[simulation : fichier %s]\n' "$path"; cat; return; fi
  umask 022
  mkdir -p "$(dirname "$path")"
  # Créer le fichier sans exposition transitoire si son mode final est privé.
  (umask 077; cat > "$path")
  chmod "$mode" "$path"
)
chroot_run() (umask 022; run arch-chroot "$TARGET" "$@")
list_packages() { sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$@"; }
validate_repo() { [[ $1 =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; }
validate_ref() { [[ $1 =~ ^[A-Za-z0-9][A-Za-z0-9._/-]*$ && $1 != *..* ]]; }
