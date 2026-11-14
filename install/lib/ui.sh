#!/usr/bin/env bash
ask() {
  local label=$1 value=$2
  gum input --header "$label" --value "$value"
}
choose() { local label=$1; shift; gum choose --header "$label" "$@"; }
confirm() { gum confirm --default=false --affirmative Oui --negative Non "$1"; }
questionnaire() {
  local rows=() row
  while IFS= read -r row; do rows+=("$row"); done < <(available_disks)
  ((${#rows[@]})) || die 'Aucun disque libre éligible.'
  row=$(choose 'Disque entier à effacer (installation dédiée)' "${rows[@]}")
  DISK=${row%% *}
  HOSTNAME=$(ask 'Nom de la machine' archlinux)
  USERNAME=$(ask 'Utilisateur' utilisateur)
  TIMEZONE=$(ask 'Fuseau horaire (ex. Africa/Algiers)' Africa/Algiers)
  LOCALE=$(choose 'Langue système UTF-8' fr_FR.UTF-8 en_US.UTF-8)
  KEYMAP=$(ask 'Clavier console (ex. fr, us)' fr)
  XKB_LAYOUT=$(ask 'Clavier graphique (ex. fr, us)' fr)
  KERNEL=$(choose 'Noyau' linux linux-lts)
  if confirm 'Ajouter le second noyau comme solution de secours ?'; then EXTRA_KERNEL=1; fi
  SESSION=$(choose 'Connexion' console sddm)
  if [[ $HW_NVIDIA == unknown ]]; then
    NVIDIA_MODE=$(choose 'GPU NVIDIA inconnu : choix explicite du pilote' nouveau open)
    confirm 'As-tu vérifié la compatibilité du pilote choisi avec ce GPU ?' || die 'Choix du pilote annulé.'
  elif [[ $HW_NVIDIA == legacy ]]; then
    info 'NVIDIA ancien : nouveau proposé. Le pilote propriétaire historique AUR reste hors du profil minimal.'
    confirm 'Continuer avec nouveau (performances et compatibilité variables) ?' || die 'Installation annulée.'
  fi
  validate_answers
}
validate_answers() {
  [[ $HOSTNAME =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]] || die 'Nom de machine invalide.'
  [[ $USERNAME =~ ^[a-z_][a-z0-9_-]{0,30}$ && $USERNAME != root ]] || die 'Nom utilisateur invalide.'
  [[ $TIMEZONE != /* && $TIMEZONE != *..* && -f /usr/share/zoneinfo/$TIMEZONE ]] || die 'Fuseau horaire invalide.'
  [[ $LOCALE == fr_FR.UTF-8 || $LOCALE == en_US.UTF-8 ]] || die 'Langue invalide.'
  [[ $KEYMAP =~ ^[a-zA-Z0-9_-]+$ && $XKB_LAYOUT =~ ^[a-z]{2,3}$ ]] || die 'Clavier invalide.'
  [[ $KERNEL == linux || $KERNEL == linux-lts ]] || die 'Noyau invalide.'
  [[ $SESSION == console || $SESSION == sddm ]] || die 'Session invalide.'
  if ((!DRY_RUN)); then
    localectl list-keymaps | grep -Fx -- "$KEYMAP" >/dev/null || die 'Clavier console introuvable.'
    localectl list-x11-keymap-layouts | grep -Fx -- "$XKB_LAYOUT" >/dev/null || die 'Clavier XKB introuvable.'
  fi
}
