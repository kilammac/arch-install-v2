# Récupération après interruption

Depuis l’ISO Arch en mode UEFI, connecte-toi à Internet et identifie les partitions avec `lsblk -f`. Les noms ci-dessous sont des exemples à remplacer par ceux de ton disque. **Ne lance pas `mkfs` ni l’installateur pour une réparation.**

```bash
mount -o compress=zstd:3,subvol=@ /dev/nvme0n1p2 /mnt
mount --mkdir -o subvol=@home /dev/nvme0n1p2 /mnt/home
mount --mkdir -o subvol=@log /dev/nvme0n1p2 /mnt/var/log
mount --mkdir -o subvol=@pkg /dev/nvme0n1p2 /mnt/var/cache/pacman/pkg
mount /dev/nvme0n1p1 /mnt/boot
arch-chroot /mnt
```

Dans le chroot, selon l’erreur identifiée :

```bash
pacman -Syu
mkinitcpio -P
bootctl --esp-path=/boot install
passwd root
passwd ton_utilisateur
```

Vérifie `/etc/fstab`, `/boot/loader/entries/*.conf` et l’UUID de la racine avec `blkid`. Les entrées doivent désigner la racine Btrfs et `rootflags=subvol=@`.

```bash
exit
umount -R /mnt
reboot
```

Après connexion, si le bureau ne démarre pas :

```bash
start-hyprland
journalctl --user -u quickshell.service -b
journalctl -b -p err
```

En cas de blocage après plusieurs échecs de Quickshell : corrige l’erreur, puis utilise `systemctl --user reset-failed quickshell.service` et `systemctl --user restart quickshell.service` depuis une session Hyprland.
