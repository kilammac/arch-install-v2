# Arch Linux — installateur bboysidou avec les configurations de kilammac

Ce dépôt conserve l’installateur de [bboysidou/dotfile_hyperland](https://github.com/bboysidou/dotfile_hyperland), ses menus, sa barre de progression, ses étapes, sa détection matérielle, ses groupes de paquets et sa reprise après erreur.

Les configurations Hyprland, Neovim et Quickshell sont celles de kilammac. La collection `Wallpaper/` contient ses trois fonds d’écran. Le détail vérifiable des adaptations figure dans [ADAPTATION.md](ADAPTATION.md).

## Installation

Depuis le terminal root de l’ISO Arch Linux démarrée en UEFI, avec Secure Boot désactivé et Internet connecté, dans un nouveau dossier :

```bash
cd "$(mktemp -d /tmp/arch-install-v2-lancement.XXXXXXXX)"
curl -fsSL https://raw.githubusercontent.com/kilammac/arch-install-v2/main/install/install.sh -o install.sh
bash install.sh
```

Le parcours est celui de bboysidou : questions, choix du disque et du partitionnement, sélection des paquets, configuration du système, pilotes, installation des dotfiles et proposition de redémarrage. Les paquets supplémentaires se choisissent dans ses menus d’origine, avec possibilité d’affiner les paquets d’un groupe.

Préférences proposées : utilisateur `kilam`, Bash comme shell de connexion et Oh My Bash activé. Firefox reste sélectionné dans le groupe Navigateurs. L’effacement du disque demande une confirmation Oui/Non, avec Non par défaut.

Si tu conserves Oh My Bash, son assistant officiel crée son `.bashrc` et ouvre Bash. Tape `exit` pour reprendre l’installation. Aucun `.bashrc` personnel n’est copié ; tu peux le reprendre manuellement ensuite.

**Le choix d’effacement du disque détruit ses partitions après confirmation.** Ne lance pas l’installateur pour réparer une installation existante.

Les options d’origine sont conservées :

```bash
bash install.sh --dry-run
bash install.sh --branch main
```

`--dry-run` garde le questionnaire original et affiche les opérations prévues. `--answers FICHIER` permet de préremplir les réponses au format de bboysidou. N’utilise que tes propres fichiers de réponses : ils sont chargés comme du Bash.

Le menu original propose plusieurs chargeurs de démarrage et des options facultatives. Pour conserver ton choix sans snapshots, réponds non à Snapper. Aucun chiffrement ni Snap n’a été ajouté à l’installateur.

## Configurations

Le dépôt est cloné dans `~/.dotfiles`, puis `install/link.sh` crée les liens vers `~/.config/hypr`, `~/.config/nvim`, `~/.config/quickshell` et `~/Pictures/wallpaper`, ainsi que les autres liens prévus par bboysidou. Les cibles existantes sont sauvegardées par son script avant remplacement.

Les écrans, espaces de travail, choix du terminal et variables GPU générés par machine suivent le mécanisme original. Les scripts ne sont pas remplacés par une seconde architecture de post-installation.

Fond initial : `Wallpaper/prefere-arch1.jpg`.

## Vérifications

Depuis la racine du clone :

```bash
bash tests/verifier-adaptation.sh
bash tests/preferences.sh
shellcheck -x -P SCRIPTDIR install/install.sh install/link.sh tests/verifier-adaptation.sh
```

Les journaux et la reprise utilisent les emplacements d’origine : `/tmp/installer` sur l’ISO, puis `/var/log/installer.log` sur le système installé.

La seule dépendance ajoutée au groupe de base est `qt6-multimedia`, nécessaire au lecteur cassette de ta configuration Quickshell. Le parcours complet a été testé en VM, jusqu’au redémarrage et au premier login ; les choix et limites de cet essai sont détaillés dans [ADAPTATION.md](ADAPTATION.md).
