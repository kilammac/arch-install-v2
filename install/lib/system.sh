#!/usr/bin/env bash
install_system() {
  local uuid kernel modules
  (umask 022; run pacstrap -K "$TARGET" "${PACKAGES[@]}")
  if ((DRY_RUN)); then
    info '[simulation] genfstab -U /mnt vers /mnt/etc/fstab'
    uuid=UUID-SIMULE
  else
    genfstab -U "$TARGET" > "$TARGET/etc/fstab"
    chmod 644 "$TARGET/etc/fstab"
    uuid=$(blkid -s UUID -o value "$ROOT_PART")
    [[ -n $uuid ]] || die 'UUID Btrfs introuvable.'
  fi
  chroot_run ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
  chroot_run hwclock --systohc
  write_file "$TARGET/etc/locale.gen" <<LOCALEFILE
$LOCALE UTF-8
en_US.UTF-8 UTF-8
LOCALEFILE
  chroot_run locale-gen
  write_file "$TARGET/etc/locale.conf" <<< "LANG=$LOCALE"
  write_file "$TARGET/etc/vconsole.conf" <<< "KEYMAP=$KEYMAP"
  write_file "$TARGET/etc/hostname" <<< "$HOSTNAME"
  write_file "$TARGET/etc/hosts" <<HOSTS
127.0.0.1 localhost
::1 localhost
127.0.1.1 $HOSTNAME.localdomain $HOSTNAME
HOSTS
  chroot_run useradd -m -G wheel -s /bin/bash "$USERNAME"
  write_file "$TARGET/etc/sudoers.d/10-wheel" 440 <<< '%wheel ALL=(ALL:ALL) ALL'
  chroot_run visudo -cf /etc/sudoers
  write_file "$TARGET/etc/systemd/zram-generator.conf" <<'ZRAM'
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
ZRAM
  modules="${HW_MODULES[*]}"
  write_file "$TARGET/etc/mkinitcpio.conf.d/10-arch-insall.conf" <<INIT
MODULES=($modules)
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block filesystems fsck)
INIT
  if [[ ${NVIDIA_MODE:-$HW_NVIDIA} == open ]]; then
    write_file "$TARGET/etc/modprobe.d/nvidia.conf" <<< 'options nvidia_drm modeset=1 fbdev=1'
  fi
  chroot_run mkinitcpio -P
  chroot_run bootctl --esp-path=/boot install
  write_file "$TARGET/boot/loader/loader.conf" <<'LOADER'
default arch.conf
timeout 3
console-mode keep
editor no
LOADER
  for kernel in linux linux-lts; do
    [[ $kernel == "$KERNEL" || $EXTRA_KERNEL == 1 ]] || continue
    local entry=arch
    [[ $kernel == "$KERNEL" ]] || entry=arch-secours
    write_file "$TARGET/boot/loader/entries/$entry.conf" <<ENTRY
title Arch Linux ($kernel)
linux /vmlinuz-$kernel
initrd /initramfs-$kernel.img
options root=UUID=$uuid rootflags=subvol=@ rw
ENTRY
  done
  chroot_run systemctl enable NetworkManager.service systemd-timesyncd.service btrfs-scrub@-.timer
  if ((HW_BLUETOOTH)); then chroot_run systemctl enable bluetooth.service; fi
  if ((HW_LAPTOP)); then chroot_run systemctl enable power-profiles-daemon.service; fi
  case "$HW_VIRT" in
    kvm|qemu) chroot_run systemctl enable qemu-guest-agent.service;;
    vmware) chroot_run systemctl enable vmtoolsd.service;;
    oracle) chroot_run systemctl enable vboxservice.service;;
  esac
  if [[ $SESSION == sddm ]]; then chroot_run systemctl enable sddm.service; fi
}
set_passwords() {
  if ((DRY_RUN)); then info '[simulation] Saisie interactive des mots de passe root et utilisateur ignorée.'; return; fi
  # passwd lit directement le terminal et désactive son écho. Aucun secret dans les arguments.
  info 'Définis le mot de passe root.'
  until arch-chroot "$TARGET" passwd root; do info 'Réessaie le mot de passe root.'; done
  info "Définis le mot de passe de $USERNAME."
  until arch-chroot "$TARGET" passwd "$USERNAME"; do info 'Réessaie le mot de passe utilisateur.'; done
}
