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

## Correction du contrôle des paquets Mesa

Le signalement `Indisponible : libva-mesa-driver` venait de l’utilisation de `pacman -Si` sur un nom virtuel fourni par `mesa`. Les branches AMD et nouveau demandent désormais directement `mesa`. Le contrôle avant formatage utilise `pacman -Sp` pour résoudre la transaction et les fournisseurs, sans installation ni téléchargement.

Vérifications exécutées après correction : suite Bash, ShellCheck, contrôle des différences et résolutions Pacman réelles pour les profils AMD et NVIDIA nouveau. Une transaction demandant explicitement `mesa` et son nom virtuel `libva-mesa-driver` a également été résolue avec succès. Les tests vérifient qu’un échec de résolution bloque la suite. Aucune réinstallation complète en VM n’a été nécessaire pour ce changement de sélection et de vérification des paquets.

## Isolation du contrôle avant formatage

Un second blocage a été reproduit avec les enregistrements de paquets extraits de l’ISO Arch du 1er novembre 2026 et les bases de dépôts officielles actuelles : la résolution sur l’ISO tentait de mettre à jour OpenSSL et cassait les dépendances d’outils du système live. Les détails étaient masqués parce que Pacman les écrivait sur stdout.

Le contrôle utilise désormais une racine et une base locale vides dans un répertoire temporaire, avec une copie des seules bases des dépôts. Il vérifie ainsi un nouveau système, indépendamment des logiciels installés sur l’ISO. Le sous-shell nettoie ses fichiers temporaires à la sortie. En cas d’échec, stdout et stderr de Pacman sont affichés avant l’arrêt, toujours avant formatage.

Vérifications exécutées :

- `bash tests/run.sh` et ShellCheck sur les points d’entrée, modules, tests et outils.
- `bash tests/preflight-pacman.sh` : dépôt synthétique local, sans téléchargement ni installation ; conflit avec un outil de l’ISO reproduit, résolution isolée réussie, base source inchangée et vraie dépendance absente toujours bloquante avec diagnostic visible.
- Résolution complète des profils Intel, AMD, NVIDIA ouvert et nouveau, avec deux noyaux, contre les bases officielles core/extra et une base locale extraite de l’ISO. Les quatre profils passent avec l’isolation ; le profil AMD reproduit le conflit OpenSSL avec l’ancienne méthode.
- Audit des fichiers et contrôle des différences.

Aucune nouvelle installation ni aucun formatage n’ont été exécutés pour cette correction.

## Permissions lors du premier login

Le problème `/etc/profile: Permission denied` et l’absence de résolution du nom utilisateur ont été reproduits dans une VM QEMU jetable, avec un vrai `pacstrap` exécuté sous `umask 077`. Le dossier `/etc` résultant avait le mode `700`, même si `/etc/profile` avait correctement le mode `644`. Le shell de login ordinaire ne pouvait donc lire ni son profil ni les informations d’identité dans `/etc`.

La réparation ciblée des dossiers `/etc`, `/var`, `/var/cache` et `/var/lib` a rétabli, dans ce système de test, la lecture du profil et la résolution de l’utilisateur. Le mode de `/etc/shadow` est resté inchangé.

Corrections : masque `022` au point d’entrée et autour de `pacstrap`/des commandes chroot, modes explicites dans `write_file`, fichier sudo en `440`, fstab en `644`, journal créé en `600` sans modifier le masque global. Un contrôle des répertoires publics, fichiers d’identité/profil et fichiers privés bloque désormais la fin de l’installation en cas de droits incorrects.

Vérifications exécutées :

- `bash tests/permissions.sh` : reproduction de la création de parents en `700`, écritures publiques et privées sous masque hérité `077`, masque transmis à pacstrap/chroot, refus de permissions publiques ou privées incorrectes.
- Nouveau système de base réellement créé par la commande pacstrap appelée depuis `install_system`, avec masque appelant `077`, dans la VM. L’essai s’arrête volontairement après pacstrap : il ne reconfigure pas le démarrage. Création du compte par le helper chroot corrigé, puis shell Bash de login sous ce compte : lecture de `/etc/profile`, `id -un` et `getent passwd` réussis.
- Suite des tests de détection/simulation et de résolution Pacman, ShellCheck et contrôle des différences.

Ce nouvel essai porte sur le système de base et les permissions du login ; ce n’est pas une nouvelle installation complète du bureau depuis les menus. Les essais initiaux du bureau avaient été exécutés sans reproduire le masque global de l’amorçage, ce qui avait laissé passer ce défaut.
