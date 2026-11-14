#!/usr/bin/env bash
collect_packages() {
  local extra
  mapfile -t PACKAGES < <({
    list_packages "$PROJECT"/packages/{base,desktop,neovim}.list
    printf '%s\n' "$KERNEL" "${HW_PACKAGES[@]}"
    if ((EXTRA_KERNEL)); then
      if [[ $KERNEL == linux ]]; then echo linux-lts; else echo linux; fi
    fi
    if [[ $SESSION == sddm ]]; then echo sddm; fi
  } | sed '/^$/d' | sort -u)
  for extra in "${PACKAGES[@]}"; do
    [[ $extra =~ ^[a-zA-Z0-9@+_.-]+$ ]] || die "Nom de paquet invalide : $extra"
    case "$extra" in snapd|snapper|timeshift) die "Paquet exclu : $extra";; esac
  done
}
preflight_packages() {
  local package failed=0
  info 'Vérification de la disponibilité des paquets avant formatage…'
  for package in "${PACKAGES[@]}"; do
    pacman -Si -- "$package" >/dev/null 2>&1 || { printf 'Indisponible : %s\n' "$package" >&2; failed=1; }
  done
  ((failed == 0)) || die 'Corrige les paquets indisponibles avant de continuer.'
}
