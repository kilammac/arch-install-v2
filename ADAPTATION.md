# Base conservée et adaptations

## Source

Installateur et ressources de [bboysidou/dotfile_hyperland](https://github.com/bboysidou/dotfile_hyperland), commit `af083563fd37c32ef9fe64adffe058fe19b57f29` du 13 novembre 2026. Les fichiers ont été récupérés depuis GitHub et comparés à la copie locale du dépôt de référence.

Cette version remplace l’architecture personnalisée précédemment utilisée dans `arch-install-v2`. Aucun changement d’historique forcé n’a été effectué ; la version précédente reste dans l’historique Git et sur la branche locale `archive/installateur-personnalise-3b500a8`.

## Différences dans `install/`

| Fichier | Adaptation |
|---|---|
| `install.sh` | Dépôt `kilammac/arch-install-v2` et dossier d’amorçage `/tmp/arch-install-v2-src` pour éviter de confondre les sources des deux dépôts. |
| `lib/user.sh` | Adresses de récupération/envoi du dépôt personnel et fond initial `Pictures/wallpaper/prefere-arch1.jpg`. |
| `bundles/00-core.list` | Ajout de `qt6-multimedia`, requis par le lecteur cassette de la configuration Quickshell personnelle. |
| `README.md` | Adresse de téléchargement de ce dépôt. |

Les préférences complémentaires et les corrections de sélection ci-dessous modifient aussi les questions, les shells et les réponses enregistrées. Dans `lib/ui.sh`, seul le helper de sélection multiple est adapté ; la progression est conservée. Les adaptations déjà commitées dans la base et les listes core sont également conservées dans le delta explicite.

Le manifeste `tests/bboysidou-install.sha256` provient des fichiers originaux téléchargés. `tests/verifier-adaptation.sh` vérifie leur identité après normalisation des seules différences autorisées ci-dessus. Il vérifie aussi l’affichage de la barre de progression d’origine.

### Préférences complémentaires validées

- `lib/questions.sh` propose `kilam`, affiche Bash parmi les shells, propose Oh My Bash par défaut et remplace la saisie du chemin du disque par Oui/Non avec Non par défaut.
- `lib/shells.sh` choisit Bash par défaut et compte l’étape Oh My Bash dans la progression ; `lib/state.sh` mémorise `A_OH_MY_BASH` pour la reprise.
- `install.sh` ajoute cette étape ; `lib/user.sh` lance l’assistant officiel Oh My Bash avec le compte utilisateur et son terminal interactif. L’assistant garde sa création et sa sauvegarde habituelles du `.bashrc`. Aucun fichier `.bashrc` personnel n’est copié.
- Firefox était déjà inclus et sélectionné par défaut dans le groupe Navigateurs : aucune modification de cette liste.

Le delta explicite `tests/preferences-installateur.patch`, relatif à la version `5217b97`, est retiré dans une copie temporaire avant la comparaison à bboysidou. Les empreintes d’origine ne sont pas recalculées pour masquer les adaptations.

Vérifications de cette mise à jour : `tests/preferences.sh`, comparaison amont, ShellCheck et simulation complète avec progression terminée. L’assistant officiel a aussi été réellement exécuté dans un HOME temporaire via l’étape verbose d’origine ; son Bash interactif puis `exit` ont rendu la main à la progression. Ce test ciblé n’est pas une nouvelle installation complète en VM.

## Configurations personnelles

- `hypr/`, `nvim/` et `quickshell/` viennent des configurations actives du système de kilammac.
- Les fichiers de configuration inclus ont été comparés individuellement aux sources locales : aucun contenu réécrit.
- Les fichiers générés par machine (`hypr/monitors.lua`, `hypr/workspaces.lua`, `hypr/config/env-gpu.lua`, `hypr/config/terminal.lua`) restent gérés et ignorés par Git comme chez bboysidou. L’installateur génère donc les écrans, pilotes et choix de terminal pour la machine cible.
- Les copies de sauvegarde, journaux, essais QML et documents de travail locaux ne sont pas distribués.
- `Wallpaper/` contient uniquement `f31423680.jpg`, `f31718840.jpg` et `prefere-arch1.jpg`, copiés depuis la collection personnelle. Leurs sommes de contrôle ont été comparées aux fichiers sources.
- Les autres configurations, ressources et mécanismes de liaison de bboysidou sont conservés.

## Vérifications réalisées

- Comparaison intégrale de `install/` avec le manifeste source, et confirmation de l’identité de `lib/ui.sh`.
- Exécution des fonctions originales de progression et vérification de leur affichage.
- Syntaxe Bash de tous les scripts de `install/`.
- ShellCheck 0.11.0 sur les points d’entrée et le script de vérification, sans modification des scripts d’origine pour satisfaire l’outil.
- Simulation complète du point d’entrée avec les réponses d’exemple : étapes jusqu’au message final et barre terminée. Aucun partitionnement ni installation de paquets sur l’hôte.
- Exécution réelle de `install/link.sh --yes` dans un HOME temporaire, puis `--check` : tous les liens sont valides, dont les trois configurations et les wallpapers.
- Comparaison des configurations et des wallpapers avec les sources du système.
- Recherche de motifs de clés privées et de jetons dans les fichiers destinés à la publication, sans afficher de valeurs sensibles.

Les essais statiques et de simulation ci-dessus sont complétés par l’installation réelle décrite plus bas. Le parcours est celui de la source indiquée ; tous les groupes et paquets AUR n’ont pas été testés.

## Attribution

Les scripts et ressources de bboysidou conservent leur origine et leurs mentions. Aucune licence n’a été trouvée à la racine de la source examinée ; ce dépôt ne réattribue pas de licence aux contributions et médias de tiers. Les configurations personnelles et les autres programmes restent soumis aux droits et licences de leurs auteurs respectifs.

## Installation réelle de validation

Une installation complète du point d’entrée publié a été exécutée depuis l’ISO Arch du 1er novembre 2026, dans une VM QEMU/OVMF avec un disque virtuel dédié de 40 Gio. Le questionnaire d’origine a été prérempli avec `--answers`, puis les confirmations et les mots de passe ont été fournis sur l’entrée standard ; leurs valeurs ne sont pas publiées. La sortie utilisait l’interface texte originale, avec sa barre de progression.

Choix de test : Btrfs, systemd-boot, utilisateur Bash, groupe core, sans Snapper ni hibernation. Cinq paquets AUR ont été exclus via le mécanisme d’origine (`otf-apple-sf-pro`, `ttf-orbitron`, `ttf-icomoon-feather`, `nmrs`, `nmrs-tui`) ; la construction de yay-bin, le clonage des dotfiles et les autres étapes du parcours ont été exécutés. Cela ne valide pas l’installation de tous les groupes ni de tous les paquets AUR.

Résultats :

- Les étapes `questions`, `disk`, `base`, `system` et `user` sont terminées ; la progression atteint son message final.
- `/etc` est en `755`, `/etc/profile`, `/etc/passwd` et `/etc/group` en `644`, `/etc/shadow` en `600`.
- Le shell de login ordinaire lit le profil et résout son nom correctement, avant puis après redémarrage depuis le disque installé sans ISO.
- Les liens des configurations pointent vers `~/.dotfiles` et l’état du fond d’écran désigne `~/Pictures/wallpaper/prefere-arch1.jpg`.
- Hyprland charge la configuration personnelle sans erreur retournée par `hyprctl configerrors`.
- Le premier lancement de Quickshell a révélé l’absence de QtMultimedia pour le lecteur cassette. L’installation du seul paquet `qt6-multimedia` dans la VM a permis le chargement de la configuration et le démarrage du service. Ce paquet est donc ajouté au groupe core, sans réécrire les scripts ni les fichiers personnels.
- Le rendu de cette VM est logiciel ; les avertissements sur le GPU accéléré, les fréquences CPU ou l’absence de périphériques ne constituent pas des essais de matériel physique.

La comparaison complète avec la source et les essais de téléchargement doivent continuer à passer après chaque adaptation des adresses du dépôt.

## Correction de la sélection des groupes

Trois défauts ont été reproduits sans installation de système :

- Les libellés de groupes contiennent des virgules. Le paramètre `gum choose --selected` les découpait et perdait les présélections, notamment celle de Navigateurs. Les options sont maintenant passées en arguments et les libellés présélectionnés sur stdin, séparés par des retours à la ligne.
- La touche Espace ne bascule pas les cases dans Gum 2.0.2, alors que les menus l'indiquaient. Les menus indiquent désormais X ou Tab, qui fonctionnent dans cette version. Le défaut est aussi signalé dans [Gum #1143](https://github.com/charmbracelet/gum/issues/1143).
- En mode texte, les noms seuls tels que `browsers` étaient perdus par une conversion qui attendait un deux-points. La conversion accepte maintenant les noms et les libellés complets, ne conserve que les groupes disponibles et retire les doublons.

Une sélection explicitement vide reste vide quand on rouvre le menu ; un `A_BUNDLES=""` fourni dans `--answers` est également respecté. Le groupe core reste obligatoire.

Vérifications exécutées : `tests/bundles.sh`, puis six scénarios réels dans un pseudo-terminal avec le binaire officiel Arch Gum 2.0.2 et Expect (`tests/bundles-gum.exp`). Les scénarios couvrent la validation de Navigateurs sans changement, plusieurs présélections, la sélection par X, la désélection par Tab suivie d'une réouverture, les groupes `default=on` et l'exclusion effective de Firefox. Les tests de préférences, ShellCheck et la comparaison des adaptations sont aussi exécutés. Aucun paquet ni système n'est installé par ces tests.

Le patch de comparaison inclut les changements du projet déjà commités avant cette correction (listes core et réglage Zram), sans réécrire leurs fichiers pour cette tâche.
