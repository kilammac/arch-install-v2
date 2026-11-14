#!/usr/bin/env bash
# Régression réelle avec un dépôt local synthétique : aucun téléchargement,
# aucune installation et aucune modification des bases du système.
set -Eeuo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=install/lib/common.sh
source install/lib/common.sh
# shellcheck source=install/lib/packages.sh
source install/lib/packages.sh
command -v pacman >/dev/null || die 'Pacman requis pour ce test.'
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
mkdir -p "$fixture/db/local/iso-tool-1-1" "$fixture/db/local/test-lib-1-1" "$fixture/db/sync" "$fixture/repo" "$fixture/root"
cp -- "$(pacman-conf DBPath)/local/ALPM_DB_VERSION" "$fixture/db/local/ALPM_DB_VERSION"
# L'outil de l'ISO exige l'ancienne bibliothèque. Le nouveau système veut la v2.
cat > "$fixture/db/local/iso-tool-1-1/desc" <<'DESC'
%NAME%
iso-tool

%VERSION%
1-1

%DEPENDS%
test-lib=1

DESC
cat > "$fixture/db/local/test-lib-1-1/desc" <<'DESC'
%NAME%
test-lib

%VERSION%
1-1

DESC
repo_package() {
  local name=$1 version=$2 dependency=${3:-}
  mkdir -p "$fixture/repo/$name-$version"
  {
    printf '%%NAME%%\n%s\n\n%%VERSION%%\n%s\n\n%%FILENAME%%\n%s-%s-x86_64.pkg.tar.zst\n\n%%ARCH%%\nx86_64\n\n' "$name" "$version" "$name" "$version"
    if [[ -n $dependency ]]; then printf '%%DEPENDS%%\n%s\n\n' "$dependency"; fi
  } > "$fixture/repo/$name-$version/desc"
}
repo_package test-lib 2-1
repo_package desktop 1-1 'test-lib>=2'
repo_package broken-desktop 1-1 'missing-library>=1'
tar -czf "$fixture/db/sync/test.db" -C "$fixture/repo" test-lib-2-1 desktop-1-1 broken-desktop-1-1
cat > "$fixture/pacman.conf" <<CONF
[options]
Architecture = x86_64
DBPath = $fixture/db
# Dépôt synthétique local sans signature ; aucune configuration système modifiée.
SigLevel = Never
[test]
Server = file://$fixture/repo
CONF
before=$(find "$fixture/db/local" -type f -exec sha256sum {} + | sort)
if pacman --config "$fixture/pacman.conf" -Sp --noconfirm desktop > "$fixture/before.log" 2>&1; then
  die 'Le témoin doit reproduire le conflit avec les paquets de l’ISO.'
fi
grep -q 'iso-tool' "$fixture/before.log" || { cat "$fixture/before.log" >&2; die 'Conflit de référence non reproduit.'; }
PACKAGES=(desktop)
preflight_packages "$fixture/pacman.conf"
after=$(find "$fixture/db/local" -type f -exec sha256sum {} + | sort)
[[ $before == "$after" ]] || die 'La base locale source a changé.'
PACKAGES=(broken-desktop)
if (preflight_packages "$fixture/pacman.conf") > "$fixture/after.log" 2>&1; then
  die 'Une dépendance réellement absente doit bloquer.'
fi
grep -q missing-library "$fixture/after.log" || die 'Le détail de la dépendance absente doit être visible.'
printf 'OK : conflit ISO reproduit, résolution isolée réussie, base source inchangée et vraie dépendance absente signalée.\n'
