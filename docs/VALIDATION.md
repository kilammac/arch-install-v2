# Vérifications réalisées

Vérifications du 14 novembre 2026. Les résultats concernent cette version ; ils ne garantissent pas le fonctionnement de tous les matériels.

## Exécuté avec succès

- Syntaxe Bash des modules, points d’entrée et scripts shell copiés.
- ShellCheck 0.11.0 sur l’installateur, le post-install, les tests et les outils. Les exclusions documentées dans `.shellcheckrc` concernent les variables partagées et les apostrophes françaises.
- Syntaxe Lua de tous les fichiers inclus (`luac -p`).
- `bash tests/run.sh` : CPU Intel/AMD, GPU Intel/AMD, NVIDIA récent, ancien et inconnu, multi-GPU, VM, noms de partitions SATA/NVMe/MMC.
- Simulation d’installation et de post-install avec remplacement des commandes mutantes par des commandes qui échouent si elles sont exécutées.
- Refus d’installation hors ISO et refus des références Git et groupes invalides.
- Disponibilité de tous les paquets officiels déclarés, interrogée sans installation sur l’hôte.
- `bash tools/audit.sh` : recherche de motifs de secrets, chemins personnels et scripts Python dans les fichiers distribués. Les valeurs éventuelles ne sont pas affichées. Cet audit ne constitue pas une preuve mathématique d’absence de secret ; les fichiers ont aussi été examinés avant publication.
- Neovim 0.12.6 lancé dans des répertoires XDG isolés : téléchargement des 19 extensions puis second lancement et disponibilité de la commande `Oil`.
- Installation sur un disque QEMU virtuel de 40 Gio, avec ISO Arch du 1er novembre 2026 et firmware UEFI OVMF : GPT, EFI, quatre sous-volumes Btrfs, compression Zstd, installation des paquets, deux noyaux, initramfs et entrées systemd-boot.
- Saisie interactive des mots de passe root et utilisateur dans la VM, sans affichage ni conservation de leurs valeurs dans le dépôt.
- Redémarrage depuis le disque installé, sans ISO ni noyau injecté par QEMU : noyau `linux` chargé, racine Btrfs montée, réseau actif, Zram actif et contrôle Btrfs mensuel activé. Aucune unité système en échec lors du contrôle.
- Post-install simulé avec le compte non privilégié de la VM ; vérification de l’unité utilisateur Quickshell.
- Hyprland lancé dans une session de la VM : aucune erreur retournée par `hyprctl configerrors`, écran virtuel 1280 × 800 reconnu, Quickshell actif et configuration QML chargée. Une capture du bureau a été inspectée. Le rendu utilise le mode logiciel de la VM, avec des avertissements liés à l’absence de GPU accéléré, de Bluetooth et de fréquence CPU exposée.

Le premier essai en VM a révélé deux problèmes corrigés : la dépendance `xkeyboard-config` sur l’ISO et l’attribution des fichiers utilisateur à effectuer dans le chroot. Les étapes concernées ont été rejouées avec succès avant le redémarrage.

## Limites

- L’installation complète a été testée par les modules de production avec un jeu de réponses de VM, via `tools/vm-integration.sh`. Le questionnaire interactif complet n’a pas été parcouru de bout en bout.
- Pas d’essai sur matériel physique Intel/AMD/NVIDIA, de Bluetooth réel ou de lecteur d’empreinte. Les choix de pilotes sont couverts par des données simulées.
- Le noyau LTS a été installé et son entrée de démarrage créée ; le redémarrage vérifié utilise le noyau principal.
- Pas de compilation réelle du paquet AUR, ni d’installation de tous les groupes facultatifs.
- Pas de mesure de performances, de test d’hibernation ou de restauration de snapshots, ces deux dernières fonctions étant hors périmètre.

La session graphique a également permis d’ajouter la copie du fond d’écran initial dans `~/Pictures/wallpaper`, utilisé par le sélecteur Quickshell. Les droits de lecture du projet installé dans `/opt/arch-insall` sont explicitement fixés pour rester corrects avec un `umask` restrictif.

## Publication GitHub

Le dépôt public `kilammac/arch-insall` a été créé. Le point d’entrée brut a été téléchargé depuis GitHub, puis exécuté avec `--bootstrap-only` et `--dry-run` : récupération de l’archive, présence des modules et simulation terminées avec succès.

Le déploiement des configurations a aussi été rejoué dans la VM avec `umask 077` : le compte non privilégié peut lire le post-install, ses listes de paquets et le fond d’écran initial. Cet essai après démarrage utilise `chroot` pour les seules opérations d’attribution des fichiers ; l’installation depuis l’ISO utilise bien `arch-chroot`.
