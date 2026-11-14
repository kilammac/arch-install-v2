#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=../install/lib/state.sh
source install/lib/state.sh
# shellcheck source=../install/lib/ui.sh
source install/lib/ui.sh
# shellcheck source=../install/lib/bundles.sh
source install/lib/bundles.sh
# shellcheck source=../install/lib/questions.sh
source install/lib/questions.sh
INSTALLER_DIR=$PWD; PRESEED=0; A_EXCLUDE=; A_LOGITECH=no
# Mode utilisé par le test interactif dans un pseudo-terminal.
if [[ ${1:-} == --menu ]]; then
  HAS_GUM=1
  if [[ $2 == __defaults__ ]]; then unset A_BUNDLES; else A_BUNDLES=$2; fi
  for ((round=1; round<=${3:-1}; round++)); do
    askBundles
    bundleCollect
    firefox=no
    if [[ " ${B_PKGS[*]} " == *' firefox '* ]]; then firefox=yes; fi
    printf '\nRESULT%d=[%s];FIREFOX=[%s]\n' "$round" "$A_BUNDLES" "$firefox"
  done
  exit 0
fi
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
mkdir -p "$fixture/bin"
cat > "$fixture/bin/gum" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
[[ " $* " != *' --selected '* ]]
cat > "$MOCK_CAPTURE"
printf '%s\n' "$MOCK_OUTPUT"
exit "${MOCK_STATUS:-0}"
STUB
chmod +x "$fixture/bin/gum"
export PATH="$fixture/bin:$PATH" MOCK_CAPTURE="$fixture/selected" MOCK_OUTPUT=
label='browsers: Firefox, Chromium, Brave, Zen'
HAS_GUM=1; MOCK_OUTPUT=$label; chosen=old
uiMulti chosen test "$label" "$label" 'docker: Docker'
[[ $chosen == "$label" && $(cat "$MOCK_CAPTURE") == "$label" ]]
MOCK_OUTPUT=; chosen=old
uiMulti chosen test '' "$label" 'docker: Docker'
[[ -z $chosen && -z $(cat "$MOCK_CAPTURE") ]]
export MOCK_STATUS=130
chosen=unchanged
if uiMulti chosen test "$label" "$label"; then exit 1; fi
[[ $chosen == unchanged ]]
unset MOCK_STATUS
# Mode texte : noms seuls, dédoublonnage, exclusions et désélection conservée.
HAS_GUM=0; A_BUNDLES=core
askBundles <<< $'browsers browsers docker\nn\n' >/dev/null
[[ $A_BUNDLES == 'browsers docker' ]]
bundleCollect
[[ " ${B_PKGS[*]} " == *' firefox '* ]]
A_BUNDLES=
askBundles <<< $'\nn\n' >/dev/null
[[ -z $A_BUNDLES ]]
bundleCollect
[[ " ${B_PKGS[*]} " != *' firefox '* ]]
# Un fichier --answers peut explicitement ne choisir aucun groupe facultatif.
PRESEED=1; A_BUNDLES=
askBundles </dev/null
[[ -z $A_BUNDLES ]]
# Réponses issues de Gum : libellés complets, descriptions et virgules préservés.
PRESEED=0; A_BUNDLES=core
uiMulti() { printf -v "$1" '%s' "$(_bundleLabel browsers) $(_bundleLabel docker)"; }
uiConfirm() { return 1; }
askBundles >/dev/null
[[ $A_BUNDLES == 'browsers docker' ]]
A_EXCLUDE=firefox
bundleCollect
[[ " ${B_PKGS[*]} " != *' firefox '* ]]
ANSWERS_FILE="$fixture/answers"
saveAnswers
A_BUNDLES=; A_EXCLUDE=
loadVars "$ANSWERS_FILE"
[[ $A_BUNDLES == 'browsers docker' && $A_EXCLUDE == firefox ]]
printf 'OK : présélections avec virgules, mode texte, réponses vides, annulation et collecte des paquets.\n'
