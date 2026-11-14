# Arch minimal : Hyprland, Quickshell et Neovim

Installateur Bash inspiré de l’organisation de [bboysidou/dotfile_hyperland](https://github.com/bboysidou/dotfile_hyperland), avec les configurations personnelles adaptées de kilammac. Voir [ATTRIBUTIONS.md](ATTRIBUTIONS.md).

**Installation dédiée : le disque choisi est entièrement effacé après confirmation.** Le dual boot et la conservation des partitions existantes ne sont pas pris en charge. Aucun formatage n’est autorisé hors de l’ISO Arch x86_64 en mode UEFI.

## Depuis l’ISO Arch Linux

Démarre l’ISO officielle en UEFI, désactive Secure Boot et connecte-toi à Internet. Pour le Wi-Fi, utilise `iwctl`. Dans le terminal root de l’ISO, depuis le dossier de ton choix :

```bash
curl -fsSL https://raw.githubusercontent.com/kilammac/arch-insall/main/install/install.sh -o install.sh
bash install.sh
```

Le premier script télécharge le projet dans un répertoire temporaire dédié, puis ouvre les menus : disque, langue, clavier console et graphique, fuseau horaire, nom de machine, utilisateur, noyau et mode de connexion. Les mots de passe root et utilisateur sont demandés par `passwd` après installation. Ils ne sont pas placés dans des arguments, fichiers de réponses ou journaux.

Le script vérifie les paquets avant formatage. Le récapitulatif indique les pilotes et les services conditionnés par le matériel. Les disques montés, utilisés en swap, liés à un volume actif ou contenant l’ISO ne sont pas proposés.

Simulation sans partitionnement, montage ni installation de paquets (réponses d’exemple, aucune saisie de mot de passe) :

```bash
bash install.sh --dry-run
bash install.sh --dry-run --disk /dev/nvme0n1
```

Si le script est téléchargé seul, la simulation télécharge aussi les sources dans `/tmp`, puis les supprime. Dans un clone complet, elle ne crée aucun fichier système. La détection réelle nécessite `pciutils` et `usbutils`.

Pour une branche, un tag ou un commit précis, récupère **aussi le point d’entrée depuis cette référence** :

```bash
ref=main  # remplacer par le tag ou le SHA souhaité
curl -fsSL "https://raw.githubusercontent.com/kilammac/arch-insall/$ref/install/install.sh" -o install.sh
bash install.sh --ref "$ref"
```

`--branch` est un synonyme de `--ref`. `--repo propriétaire/dépôt` permet de réutiliser l’amorçage pour une autre copie du projet. `--bootstrap-only` vérifie le téléchargement et la structure sans installer. Une branche reste mobile : utilise un SHA pour fixer les sources. Les paquets proviennent des dépôts Arch actuels, même avec un SHA fixé.

## Système installé

- GPT, partition EFI FAT32 de 2 Gio montée sur `/boot`, reste en Btrfs.
- Sous-volumes `@` (`/`), `@home` (`/home`), `@log` (`/var/log`), `@pkg` (`/var/cache/pacman/pkg`), compression `zstd:3`.
- `systemd-boot`, `mkinitcpio`, noyau `linux` ou `linux-lts`, second noyau facultatif.
- Zram : taille maximale de la moitié de la RAM, plafonnée à 8 Gio. Pas d’hibernation.
- Vérification Btrfs mensuelle avec `btrfs-scrub@-.timer`. Sur un disque unique, la détection d’erreurs ne garantit pas leur réparation.
- NetworkManager et synchronisation de l’heure. Bluetooth, gestion énergétique et agents de VM selon détection.
- Hyprland en Lua, Quickshell, Neovim et leurs dépendances de fonctionnement.
- Aucun chiffrement, Snap, Snapper, snapshot automatique ou dépôt de paquets tiers ajouté.

Les pilotes Intel/AMD/NVIDIA sont sélectionnés selon le matériel. NVIDIA Turing et générations reconnues plus récentes : modules ouverts DKMS avec les en-têtes des noyaux choisis. Les anciens modèles reconnus proposent `nouveau`, avec confirmation ; leur compatibilité Hyprland n’est pas garantie. Un NVIDIA inconnu impose un choix explicite. Les pilotes propriétaires historiques AUR ne sont pas installés automatiquement. Les firmwares communs restent présents pour éviter une installation trop restrictive.

## Premier démarrage

À la fin, depuis l’ISO :

```bash
umount -R /mnt
reboot
```

Retire le support d’installation. Connecte-toi avec ton utilisateur, puis :

```bash
start-hyprland
```

SDDM est proposé si tu préfères une connexion graphique. Il n’y a pas de connexion automatique.

Raccourcis principaux : `Super+Entrée` pour Kitty, `Super+R` pour le lanceur Quickshell, `Super+F` pour Thunar, `Super+Q` pour fermer une fenêtre, `Super+Maj+E` pour quitter Hyprland. `Super+B` utilise le navigateur par défaut une fois celui-ci installé. Les écrans sont détectés automatiquement ; ajuste ensuite leur disposition dans Quickshell.

Les configurations sont copiées dans `~/.config/`. Un chemin déjà présent est renommé avec un suffixe `.backup-date-pid` avant remplacement. Les fichiers sources du projet sont conservés dans `/opt/arch-insall` pour le post-install.

Neovim télécharge ses extensions au premier lancement : Internet est nécessaire. Les serveurs de langage absents ne sont pas activés. Les outils de développement et les parseurs Treesitter restent à installer selon tes besoins ; voir `configs/nvim/README.md`.

## Paquets facultatifs

Depuis n’importe quel dossier, avec ton utilisateur **sans sudo devant Bash** :

```bash
bash /opt/arch-insall/post-install.sh
```

Espace sélectionne un groupe, Entrée valide. Rien n’est présélectionné. Les paquets sont affichés avant confirmation : navigateurs, bureautique, multimédia, développement, conteneurs, jeux, outils, empreinte et AUR. Les groupes contiennent des sélections fixes, modifiables dans `packages/optional/*.list`.

```bash
bash /opt/arch-insall/post-install.sh --dry-run --groups multimedia,outils
```

Les paquets officiels passent par une mise à jour complète `pacman -Syu`. Pour l’AUR, le script affiche le dossier de construction et ouvre le `PKGBUILD` ; inspecte aussi les fichiers associés avant de confirmer. La compilation se fait hors root avec `makepkg -si`. Aucun assistant AUR n’est imposé.

Le lecteur Quickshell utilise `mpv` (audio local) et `yt-dlp` (YouTube) du groupe multimédia. `yt-dlp` et certains autres paquets tiers dépendent de Python ; l’installateur et les scripts adaptés du projet sont en Bash. Les effets audio ne démarrent que si EasyEffects est installé. Le groupe empreinte n’active aucune authentification PAM automatiquement.

Steam/multilib restent hors de cette première sélection : aucun dépôt multilib n’est activé implicitement.

## Vérifications et dépannage

Consulte [docs/VALIDATION.md](docs/VALIDATION.md) pour les résultats réellement obtenus et [docs/RECUPERATION.md](docs/RECUPERATION.md) en cas d’interruption.

```bash
# Depuis la racine du clone
bash tests/run.sh
bash tests/preflight-pacman.sh
shellcheck -x install/install.sh install/lib/*.sh post-install.sh tests/run.sh tools/*.sh
```

Les journaux d’installation se trouvent dans `/tmp/arch-insall-log.*/install.log` sur l’ISO et, après succès, dans `/var/log/arch-insall.log` sur le système installé. Aucun redémarrage n’est déclenché automatiquement. Une installation interrompue ne se reprend pas automatiquement : n’exécute pas à nouveau le formatage pour réparer un système existant.
