#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=../install/lib/state.sh
source install/lib/state.sh
# shellcheck source=../install/lib/shells.sh
source install/lib/shells.sh
# shellcheck source=../install/lib/questions.sh
source install/lib/questions.sh
# shellcheck source=../install/lib/bundles.sh
source install/lib/bundles.sh
# shellcheck source=../install/lib/user.sh
source install/lib/user.sh
shellDefaults
[[ $DEFAULT_USERNAME == kilam && $A_SHELLS == bash && $A_LOGIN_SHELL == bash && $A_OH_MY_BASH == yes ]]
[[ " ${EXTRA_SHELLS[*]} " == *' bash '* ]]
[[ $(shellLoginPath) == /usr/bin/bash && $(shellUserStepCount) == 1 ]]
A_OH_MY_BASH=no
[[ $(shellUserStepCount) == 0 ]]
A_SHELLS='bash fish'; A_OH_MY_BASH=yes
[[ $(shellUserStepCount) == 2 ]]
# Tester le choix oui/non et le défaut proposé, sans toucher aux disques.
A_MODE=wipe; A_DISK=/dev/nvme0n1
uiWarn() { :; }; uiError() { :; }; diskOsTags() { :; }
uiTypedConfirm() { echo 'La saisie du disque ne doit plus être demandée.' >&2; exit 1; }
uiConfirm() { [[ $1 == *"$A_DISK"* && $2 == no ]]; }
_confirmDestructive
uiConfirm() { return 1; }
if _confirmDestructive; then exit 1; fi
# L'option décochée et le shell choisi restent prioritaires en reprise.
PRESEED=1; A_SHELLS=bash; A_LOGIN_SHELL=bash; A_TERMINALS=; A_DEFAULT_TERMINAL=kitty; A_OH_MY_BASH=no
askShells
[[ $A_OH_MY_BASH == no ]]
[[ " ${ANSWER_VARS[*]} " == *' A_OH_MY_BASH '* ]]
INSTALLER_DIR=$PWD
bundleEntries browsers | grep -Fx firefox >/dev/null
[[ $(bundleMeta browsers default) == on ]]
# La simulation de l'assistant officiel ne lance pas le téléchargement.
DRY_RUN=1
asUser() { printf '%s\n' "$*"; }
output=$(userOhMyBash)
[[ $output == *'https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh'* && $output != *--unattended* ]]
printf 'OK : kilam, Bash, Firefox, Oh My Bash, reprise et confirmation simple.\n'
