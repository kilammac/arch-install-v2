#!/usr/bin/env bash
# Test déclenché manuellement dans le panneau ; résultat en Mbit/s.
set -euo pipefail
phase=${1:-down}
seconds=${2:-5}
[[ $seconds =~ ^[0-9]+$ ]] || exit 2
((seconds > 0 && seconds <= 60)) || exit 2
if [[ $phase == down ]]; then
  rate=$(curl -fsSL --connect-timeout 5 --max-time "$seconds" -o /dev/null -w '%{speed_download}' 'https://speed.cloudflare.com/__down?bytes=100000000' || [[ $? == 28 ]])
elif [[ $phase == up ]]; then
  rate=$(head -c 10000000 /dev/zero | curl -fsS --connect-timeout 5 --max-time "$seconds" -X POST --data-binary @- -o /dev/null -w '%{speed_upload}' https://speed.cloudflare.com/__up || [[ $? == 28 ]])
else exit 2; fi
awk -v rate="$rate" 'BEGIN {printf "%.2f\n", rate * 8 / 1000000}'
