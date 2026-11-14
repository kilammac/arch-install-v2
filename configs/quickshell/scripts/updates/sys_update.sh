#!/usr/bin/env bash
# Mise à jour simple, sans Python, snapshot ni dépôt tiers ajouté.
set -euo pipefail
printf 'Mise à jour complète des paquets officiels.\n'
sudo pacman -Syu
if command -v yay >/dev/null 2>&1; then
  printf 'Mettre aussi à jour les paquets AUR avec yay ? [o/N] '
  read -r answer
  if [[ $answer == o || $answer == O ]]; then yay -Sua; fi
fi
if [[ ${SYS_UPDATE_PAUSE:-0} == 1 ]]; then read -r -p 'Entrée pour fermer… ' _; fi
