#!/usr/bin/env bash
partition_path() {
  if [[ $1 =~ [0-9]$ ]]; then printf '%sp%s\n' "$1" "$2"; else printf '%s%s\n' "$1" "$2"; fi
}
disk_in_use() {
  local disk=$1 node
  while read -r node; do
    [[ -n $node ]] || continue
    if findmnt -rn -S "$node" >/dev/null; then return 0; fi
    if swapon --noheadings --raw --show=NAME | grep -Fx -- "$node" >/dev/null; then return 0; fi
    if [[ -n $(ls /sys/class/block/"${node##*/}"/holders 2>/dev/null) ]]; then return 0; fi
  done < <(lsblk -nrpo NAME "$disk")
  return 1
}
available_disks() {
  local disk type ro
  while read -r disk type ro; do
    [[ $type == disk && $ro == 0 ]] || continue
    disk_in_use "$disk" && continue
    if lsblk -nr -o FSTYPE "$disk" | grep -Fx iso9660 >/dev/null; then continue; fi
    (( $(lsblk -bdn -o SIZE "$disk") >= 34359738368 )) || continue
    printf '%s %s\n' "$disk" "$(lsblk -dn -o SIZE,MODEL,SERIAL,TRAN "$disk" | xargs)"
  done < <(lsblk -dnpr -o NAME,TYPE,RO)
}
validate_disk() {
  [[ -b $DISK && $(lsblk -dn -o TYPE "$DISK") == disk ]] || die 'Disque cible invalide.'
  [[ $(lsblk -dn -o RO "$DISK") == 0 ]] || die 'Disque en lecture seule.'
  disk_in_use "$DISK" && die 'Disque utilisé (montage, swap ou volume actif). Démonte-le manuellement.'
  (( $(lsblk -bdn -o SIZE "$DISK") >= 34359738368 )) || die 'Disque de moins de 32 Gio.'
  [[ -z $(findmnt -rn -o TARGET | awk '$0 == "/mnt" || index($0, "/mnt/") == 1') ]] || die '/mnt est déjà utilisé.'
  [[ ! -d $TARGET || -z $(ls -A "$TARGET") ]] || die '/mnt doit être vide.'
}
partition_and_mount() {
  local name path
  EFI_PART=$(partition_path "$DISK" 1); ROOT_PART=$(partition_path "$DISK" 2)
  run sgdisk --zap-all "$DISK"
  run wipefs --all "$DISK"
  run sgdisk --new=1:0:+2G --typecode=1:ef00 --change-name=1:EFI --new=2:0:0 --typecode=2:8300 --change-name=2:Arch "$DISK"
  run partprobe "$DISK"
  run udevadm settle
  run mkfs.fat -F 32 -n EFI "$EFI_PART"
  run mkfs.btrfs -f -L Arch "$ROOT_PART"
  run mkdir -p "$TARGET"
  run mount "$ROOT_PART" "$TARGET"
  for name in @ @home @log @pkg; do run btrfs subvolume create "$TARGET/$name"; done
  run umount "$TARGET"
  run mount -o compress=zstd:3,subvol=@ "$ROOT_PART" "$TARGET"
  for name in '@home:home' '@log:var/log' '@pkg:var/cache/pacman/pkg'; do
    path=${name#*:}; run mkdir -p "$TARGET/$path"
    run mount -o "compress=zstd:3,subvol=${name%%:*}" "$ROOT_PART" "$TARGET/$path"
  done
  run mkdir -p "$TARGET/boot"
  run mount -o fmask=0077,dmask=0077 "$EFI_PART" "$TARGET/boot"
}
