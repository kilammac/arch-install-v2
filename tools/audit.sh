#!/usr/bin/env bash
# Contrôles avant publication ; ne jamais afficher la valeur d'un secret détecté.
set -Eeuo pipefail
cd "$(dirname "$0")/.."
failed=0
if rg -l --hidden --glob '!.git/**' --glob '!.cache/**' --glob '!PROMPT.md' --glob '!tools/audit.sh' \
  'BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY|github_pat_[A-Za-z0-9_]+|ghp_[A-Za-z0-9]{30,}|AKIA[0-9A-Z]{16}|/home/kilam|#!/.*python' \
  configs install packages post-install.sh README.md docs tests tools; then
  echo 'Fichiers à examiner avant publication (valeurs masquées).' >&2
  failed=1
fi
if find configs -type l -print | grep .; then
  echo 'Liens symboliques à examiner avant publication.' >&2; failed=1
fi
((failed == 0)) || exit 1
printf 'OK : aucun motif de secret, chemin personnel ni script Python détecté dans les fichiers distribués.\n'
