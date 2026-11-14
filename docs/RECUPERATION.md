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

## `/etc/profile: Permission denied` et `I have no name!`

Les premières versions de cet installateur laissaient `umask 077` actif pendant `pacstrap`. La création des dossiers intermédiaires pouvait donner le mode `700` à `/etc` et à certains parents sous `/var`. Un utilisateur ordinaire ne pouvait alors plus lire `/etc/profile` ni résoudre son nom via `/etc/passwd`.

Pour réparer le système déjà démarré, ouvre une autre console (`Ctrl+Alt+F3`) et connecte-toi **directement avec root**. Depuis n’importe quel dossier :

```bash
stat -c '%a %n' /etc /etc/profile /etc/passwd /etc/group /etc/nsswitch.conf
chmod 755 /etc /var /var/cache /var/lib
chmod 644 /etc/profile /etc/passwd /etc/group /etc/nsswitch.conf \
  /etc/shells /etc/hosts /etc/hostname /etc/locale.conf \
  /etc/vconsole.conf /etc/fstab
```

Déconnecte la session utilisateur en erreur et reconnecte-toi. Ne lance pas de `chmod -R` sur `/etc` et ne rends jamais `/etc/shadow` ou `/etc/gshadow` lisibles par tous.

Si la connexion root est impossible, monte le système depuis l’ISO comme indiqué plus haut, entre dans `arch-chroot /mnt`, puis exécute les mêmes commandes. Ne relance pas le formatage pour cette réparation.
