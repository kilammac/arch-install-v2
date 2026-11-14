#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
PROJECT=$PWD
DRY_RUN=1; KERNEL=linux; EXTRA_KERNEL=0; NVIDIA_MODE=; SESSION=console
# shellcheck source=install/lib/common.sh
source install/lib/common.sh
# shellcheck source=install/lib/detect.sh
source install/lib/detect.sh
# shellcheck source=install/lib/disk.sh
source install/lib/disk.sh
# shellcheck source=install/lib/packages.sh
source install/lib/packages.sh
fail() { echo "ÉCHEC : $*" >&2; exit 1; }
contains() { [[ " ${HW_PACKAGES[*]} " == *" $1 "* ]]; }
check() { "$@" || fail "$*"; }
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
intel='0000:00:02.0 VGA compatible controller [0300]: Intel Corporation Alder Lake-P Integrated Graphics Controller [8086:46a6]'
amd='0000:05:00.0 Display controller [0380]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 31 [1002:744c]'
nvidia='0000:01:00.0 3D controller [0302]: NVIDIA Corporation GA107M [GeForce RTX 3050 Mobile] [10de:25a2]'
legacy='0000:01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GP107 [GeForce GTX 1050] [10de:1c81]'
unknown='0000:01:00.0 VGA compatible controller [0300]: NVIDIA Corporation Device [10de:ffff]'
detect_hardware "$intel" '' GenuineIntel none "$fixture"
select_drivers
check contains intel-ucode
check contains vulkan-intel
contains nvidia-utils && fail 'Pilote NVIDIA sur Intel seul'
check test "$HW_GPU_COUNT" = 1
detect_hardware "$amd" '' AuthenticAMD none "$fixture"
select_drivers
check contains amd-ucode
check contains vulkan-radeon
check contains mesa
contains libva-mesa-driver && fail 'Nom virtuel libva-mesa-driver demandé séparément sur AMD'
contains vulkan-intel && fail 'Pilote Intel sur AMD seul'
detect_hardware "$intel
$nvidia" 'Bluetooth radio' GenuineIntel none "$fixture"
EXTRA_KERNEL=1; select_drivers
check test "$HW_HYBRID" = 1
check test "$HW_NVIDIA" = open
check contains nvidia-open-dkms
check contains linux-headers
check contains linux-lts-headers
check contains bluez
EXTRA_KERNEL=0
detect_hardware "$legacy" '' GenuineIntel none "$fixture"
select_drivers
check test "$HW_NVIDIA" = legacy
check contains vulkan-nouveau
check contains mesa
contains libva-mesa-driver && fail 'Nom virtuel libva-mesa-driver demandé séparément sur nouveau'
contains nvidia-open-dkms && fail 'Pilote récent sur Pascal'
detect_hardware "$unknown" '' GenuineIntel none "$fixture"
select_drivers
check test "$HW_NVIDIA" = unknown
contains nvidia-open-dkms && fail 'Pilote NVIDIA deviné'
detect_hardware "$nvidia
$legacy" '' GenuineIntel none "$fixture"
check test "$HW_NVIDIA" = legacy
detect_hardware "$unknown
$nvidia" '' GenuineIntel none "$fixture"
check test "$HW_NVIDIA" = unknown
detect_hardware '0000:00:01.0 VGA compatible controller [0300]: Red Hat Virtio GPU [1af4:1050]' '' GenuineIntel kvm "$fixture"
select_drivers
check contains qemu-guest-agent
collect_packages
for package in "${PACKAGES[@]}"; do
  [[ $package =~ ^[a-zA-Z0-9@+_.-]+$ ]] || fail "Paquet invalide $package"
done
check test "$(partition_path /dev/sda 1)" = /dev/sda1
check test "$(partition_path /dev/nvme0n1 2)" = /dev/nvme0n1p2
check test "$(partition_path /dev/mmcblk0 1)" = /dev/mmcblk0p1
# Vérifier le contrat du contrôle avant formatage et son arrêt sur échec.
mkdir -p "$fixture/live-db/sync" "$fixture/live-db/local"
touch "$fixture/live-db/sync/repo.db" "$fixture/live-db/local/outil-iso"
(
  pacman-conf() { printf '%s\n' "$fixture/live-db"; }
  pacman() {
    local dbpath='' args=" $* "
    while (($#)); do
      if [[ $1 == --dbpath ]]; then dbpath=$2; break; fi
      shift
    done
    [[ $args == *' -Sp --noconfirm --print-format %n -- mesa libva-mesa-driver '* ]] || return 1
    [[ $dbpath != "$fixture/live-db" && -d $dbpath/local && -f $dbpath/sync/repo.db ]] || return 1
    [[ -z $(ls -A "$dbpath/local") ]] || return 1
    printf '%s\n' "${dbpath%/db}" > "$fixture/last-probe"
  }
  PACKAGES=(mesa libva-mesa-driver)
  preflight_packages
) || fail 'La vérification doit résoudre les fournisseurs sans installation'
check test ! -d "$(cat "$fixture/last-probe")"
check test -f "$fixture/live-db/local/outil-iso"
if (
  pacman-conf() { printf '%s\n' "$fixture/live-db"; }
  pacman() { printf 'DEPENDANCE-MANQUANTE-DETAILLEE\n'; return 1; }
  preflight_packages
) > "$fixture/resolution-failure.log" 2>&1; then
  fail 'Une résolution impossible doit bloquer avant formatage'
fi
grep -q DEPENDANCE-MANQUANTE-DETAILLEE "$fixture/resolution-failure.log" || fail 'Diagnostic stdout de Pacman perdu'
# Les commandes mutantes seraient fatales si le mode simulation les exécutait.
mkdir "$fixture/bin"
for command in sgdisk wipefs partprobe udevadm mkfs.fat mkfs.btrfs mkdir mount umount btrfs pacstrap arch-chroot cp chmod chown install sync sudo pacman; do
  # shellcheck disable=SC2016
  printf '#!/usr/bin/env bash\necho "INTERDIT : %%s" "$0" >&2\nexit 97\n' > "$fixture/bin/$command"
  chmod +x "$fixture/bin/$command"
done
PATH="$fixture/bin:$PATH" bash install/install.sh --dry-run --disk /dev/nvme0n1 > "$fixture/dry.log" 2>&1 || fail 'Simulation ayant tenté une mutation'
grep -q 'INTERDIT' "$fixture/dry.log" && fail 'Commande mutante exécutée'
grep -q 'subvol=@home' "$fixture/dry.log" || fail 'Montage home manquant'
PATH="$fixture/bin:$PATH" bash post-install.sh --dry-run --groups multimedia,aur > "$fixture/post.log" 2>&1 || fail 'Simulation post-install mutante'
if bash install/install.sh --ref ../main --dry-run > /dev/null 2>&1; then fail 'Référence dangereuse acceptée'; fi
if bash post-install.sh --dry-run --groups ../../invalid > /dev/null 2>&1; then fail 'Groupe invalide accepté'; fi
if [[ ! -d /run/archiso ]]; then
  if bash install/install.sh > "$fixture/refusal.log" 2>&1; then fail 'Installation acceptée hors ISO'; fi
fi
# Analyse de syntaxe des scripts propres au projet.
while IFS= read -r file; do bash -n "$file"; done < <(find install tests tools -name '*.sh')
bash -n post-install.sh
printf 'OK : détection Intel/AMD/NVIDIA/hybride/VM, partitions, simulations sans mutation et refus des entrées invalides.\n'
