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
  info 'Vérification de la disponibilité des paquets avant formatage…'
  # -Sp résout la transaction, y compris les noms virtuels et leurs fournisseurs,
  # sans télécharger, installer ni rafraîchir les bases. Conserver les erreurs
  # de Pacman pour identifier aussi une dépendance manquante ou un conflit.
  pacman -Sp --noconfirm --print-format '%n' -- "${PACKAGES[@]}" >/dev/null ||
    die 'Impossible de résoudre les paquets. Corrige les erreurs Pacman avant de continuer.'
}
