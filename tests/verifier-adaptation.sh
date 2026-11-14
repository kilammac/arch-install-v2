#!/usr/bin/env bash
# Contrat : conserver l'installateur bboysidou, y compris son interface.
set -Eeuo pipefail
cd "$(dirname "$0")/.."
expected_count=$(wc -l < tests/bboysidou-install.sha256)
actual_count=$(find install -type f | wc -l)
[[ $actual_count == "$expected_count" ]] || { echo 'Fichiers ajoutés ou retirés dans install/ : comparaison requise.' >&2; exit 1; }
while read -r expected path; do
  case "$path" in
    install/install.sh)
      actual=$(sed \
        -e 's|REPO_SLUG="kilammac/arch-install-v2"|REPO_SLUG="bboysidou/dotfile_hyperland"|' \
        -e 's|BOOTSTRAP_DIR="/tmp/arch-install-v2-src"|BOOTSTRAP_DIR="/tmp/dotfiles-src"|' "$path" | sha256sum);;
    install/lib/user.sh)
      actual=$(sed \
        -e 's|https://github.com/kilammac/arch-install-v2.git|https://github.com/bboysidou/dotfile_hyperland.git|' \
        -e 's|git@github.com:kilammac/arch-install-v2.git|git@github.com:bboysidou/dotfile_hyperland.git|' \
        -e 's|DEFAULT_WALLPAPER="Pictures/wallpaper/prefere-arch1.jpg"|DEFAULT_WALLPAPER=".config/quickshell/media/wallpaper/default.png"|' "$path" | sha256sum);;
    install/bundles/00-core.list)
      actual=$(sed '/^qt6-multimedia$/d' "$path" | sha256sum);;
    install/README.md)
      actual=$(sed 's|raw.githubusercontent.com/kilammac/arch-install-v2/main/install/install.sh|raw.githubusercontent.com/bboysidou/dotfile_hyperland/main/install/install.sh|' "$path" | sha256sum);;
    *) actual=$(sha256sum "$path");;
  esac
  [[ ${actual%% *} == "$expected" ]] || { printf 'Écart non autorisé avec bboysidou : %s\n' "$path" >&2; exit 1; }
done < tests/bboysidou-install.sha256
printf 'OK : tous les fichiers de install/ correspondent à bboysidou, sauf les adaptations documentées.\n'
# Exécuter les fonctions originales de progression, sans lancer d'installation.
progress=$(
  # shellcheck source=../install/lib/ui.sh
  source install/lib/ui.sh
  HAS_GUM=0; UI_STEP_TOTAL=2
  _uiProgress 0 '1/2 · vérification'
  uiProgressDone
)
[[ $progress == *'░'* && $progress == *'██'* && $progress == *'2/2 · complete'* ]]
printf 'OK : barre de progression originale affichée, de zéro à la fin.\n'
while IFS= read -r -d '' path; do bash -n "$path"; done < <(find install -type f -name '*.sh' -print0)
printf 'OK : syntaxe des scripts Bash.\n'
