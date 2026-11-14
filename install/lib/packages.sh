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
preflight_packages() (
  # Le sous-shell garde son nettoyage indépendant des traps de l'installateur.
  local config=${1:-/etc/pacman.conf} source_db probe database
  info 'Vérification de la disponibilité des paquets avant formatage…'
  source_db=$(pacman-conf --config "$config" DBPath) || die 'Impossible de trouver les bases Pacman.'
  [[ -d $source_db/sync ]] || die 'Bases des dépôts absentes ; synchronise les dépôts depuis l’ISO.'
  probe=$(mktemp -d /tmp/arch-insall-preflight.XXXXXXXX) || exit 1
  trap 'rm -rf -- "$probe"' EXIT
  mkdir -p "$probe/root" "$probe/db/local" "$probe/db/sync"
  # Copier seulement les bases de dépôts. Ne jamais utiliser les paquets
  # installés sur l'ISO : leurs dépendances peuvent être plus anciennes.
  for database in "$source_db"/sync/*.db "$source_db"/sync/*.db.sig; do
    [[ -f $database ]] || continue
    cp -L -- "$database" "$probe/db/sync/" || exit 1
  done
  # -Sp ne télécharge ni n'installe rien. Les diagnostics détaillés de Pacman
  # peuvent être écrits sur stdout : conserver les deux flux en cas d'échec.
  if ! pacman --config "$config" --root "$probe/root" --dbpath "$probe/db" \
    --logfile "$probe/pacman.log" -Sp --noconfirm --print-format '%n' \
    -- "${PACKAGES[@]}" >"$probe/resolution.log" 2>&1; then
    cat "$probe/resolution.log" >&2
    die 'Impossible de résoudre les paquets pour le nouveau système. Aucun disque formaté.'
  fi
)
