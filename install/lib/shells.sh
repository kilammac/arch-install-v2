#!/usr/bin/env bash

BASE_SHELL="bash"
BASE_TERMINAL="kitty"
EXTRA_SHELLS=(bash zsh fish)
EXTRA_TERMINALS=(alacritty ghostty foot)
DEFAULT_SHELLS="bash"
DEFAULT_LOGIN_SHELL="bash"
SHELL_BIN_DIR="/usr/bin"
HYPR_TERMINAL_LUA="hypr/config/terminal.lua"

shellDefaults() {
  A_SHELLS="${A_SHELLS-$DEFAULT_SHELLS}"
  A_TERMINALS="${A_TERMINALS-}"
  A_LOGIN_SHELL="${A_LOGIN_SHELL:-$DEFAULT_LOGIN_SHELL}"
  A_DEFAULT_TERMINAL="${A_DEFAULT_TERMINAL:-$BASE_TERMINAL}"
  A_OH_MY_BASH="${A_OH_MY_BASH:-yes}"
}

terminalSelected() {
  [[ "$1" == "$BASE_TERMINAL" || " ${A_TERMINALS} " == *" $1 "* ]]
}

shellConfigureUser() {
  local repo="$1"
  writeFile "${repo}/${HYPR_TERMINAL_LUA}" <<<"return \"${A_DEFAULT_TERMINAL}\""
}

shellSelected() {
  [[ "$1" == "$BASE_SHELL" || " ${A_SHELLS} " == *" $1 "* ]]
}

shellLoginPath() {
  echo "${SHELL_BIN_DIR}/${A_LOGIN_SHELL}"
}

shellPackages() {
  local packages=()
  read -ra packages <<<"${A_SHELLS} ${A_TERMINALS}"
  if ((${#packages[@]})); then printf '%s\n' "${packages[@]}"; fi
  return 0
}

shellUserStepCount() {
  local count=0
  if shellSelected fish; then count=$((count + 1)); fi
  if [[ "${A_OH_MY_BASH:-yes}" == yes ]]; then count=$((count + 1)); fi
  echo "$count"
}
