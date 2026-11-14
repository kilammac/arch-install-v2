#!/usr/bin/env bash
set -Eeuo pipefail
DRY_RUN=0
SELF=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=install/lib/common.sh
source "$SELF/install/lib/common.sh"
# shellcheck source=install/lib/ui.sh
source "$SELF/install/lib/ui.sh"
GROUPS_SELECTED=()
while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1;;
    --groups)
      (($# >= 2)) || die 'Liste de groupes manquante.'
      IFS=, read -ra GROUPS_SELECTED <<< "$2"; shift;;
    --help|-h) echo 'Usage : bash post-install.sh [--dry-run] [--groups navigateurs,multimedia,…]'; exit 0;;
    *) die "Option inconnue : $1";;
  esac
  shift
done
if ((!DRY_RUN)); then
  ((EUID != 0)) || die 'Lance le post-install avec ton compte utilisateur, sans sudo devant bash.'
  [[ -f /etc/arch-release ]] || die 'Arch Linux requis.'
  command -v gum >/dev/null || die 'Installe gum : sudo pacman -Syu gum'
fi
mapfile -t AVAILABLE < <(find "$SELF/packages/optional" -name '*.list' -printf '%f\n' | sed s/.list$// | sort)
if ((${#GROUPS_SELECTED[@]} == 0)); then
  if ((DRY_RUN)); then printf 'Groupes disponibles : %s\n' "${AVAILABLE[*]}"; exit 0; fi
  info 'Espace : sélectionner ; Entrée : valider. Aucun groupe présélectionné.'
  selection=$(gum choose --no-limit --header 'Paquets facultatifs' "${AVAILABLE[@]}") || exit 0
  [[ -n $selection ]] || exit 0
  mapfile -t GROUPS_SELECTED <<< "$selection"
fi
OFFICIAL=(); AUR=()
for group in "${GROUPS_SELECTED[@]}"; do
  [[ $group =~ ^[a-z]+$ && -f $SELF/packages/optional/$group.list ]] || die "Groupe inconnu : $group"
  while read -r package; do
    case "$package" in aur:*) AUR+=("${package#aur:}");; *) OFFICIAL+=("$package");; esac
  done < <(list_packages "$SELF/packages/optional/$group.list")
done
printf 'Dépôts officiels : %s\nAUR : %s\n' "${OFFICIAL[*]:-aucun}" "${AUR[*]:-aucun}"
info 'Des dépendances tierces peuvent installer Python (notamment yt-dlp et lutris). Aucun installateur Python personnel.'
if ((!DRY_RUN)); then confirm 'Installer ces paquets ?' || exit 0; fi
if ((${#OFFICIAL[@]})); then run sudo pacman -Syu --needed -- "${OFFICIAL[@]}"; fi
for package in "${AUR[@]}"; do
  [[ $package =~ ^[a-zA-Z0-9@+_.-]+$ ]] || die 'Nom AUR invalide.'
  if ((DRY_RUN)); then info "[simulation] Cloner AUR/$package, consulter les sources et lancer makepkg -si hors root."; continue; fi
  sudo pacman -Syu --needed base-devel git
  build_dir=$(mktemp -d "/tmp/arch-insall-aur.XXXXXXXX")
  git clone -- "https://aur.archlinux.org/$package.git" "$build_dir/$package"
  info "Consulte tous les fichiers de construction dans $build_dir/$package avant de continuer."
  find "$build_dir/$package" -maxdepth 1 -type f -not -path '*/.git/*' -print
  less "$build_dir/$package/PKGBUILD"
  confirm "As-tu inspecté les sources de $package et acceptes-tu leur compilation ?" || continue
  (cd "$build_dir/$package" && makepkg -si)
done
info 'Post-install terminé. Aucun service facultatif ni authentification par empreinte activé automatiquement.'
