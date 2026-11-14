# Base conservée et adaptations

## Source

Installateur et ressources de [bboysidou/dotfile_hyperland](https://github.com/bboysidou/dotfile_hyperland), commit `af083563fd37c32ef9fe64adffe058fe19b57f29` du 13 novembre 2026. Les fichiers ont été récupérés depuis GitHub et comparés à la copie locale du dépôt de référence.

Cette version remplace l’architecture personnalisée précédemment utilisée dans `arch-insall`. Aucun changement d’historique forcé n’a été effectué ; la version précédente reste dans l’historique Git et sur la branche locale `archive/installateur-personnalise-3b500a8`.

## Différences dans `install/`

| Fichier | Adaptation |
|---|---|
| `install.sh` | Dépôt `kilammac/arch-insall` et dossier d’amorçage `/tmp/arch-insall-src` pour éviter de confondre les sources des deux dépôts. |
| `lib/user.sh` | Adresses de récupération/envoi du dépôt personnel et fond initial `Pictures/wallpaper/prefere-arch1.jpg`. |
| `README.md` | Adresse de téléchargement de ce dépôt. |

Tous les autres fichiers de `install/` sont identiques octet par octet à la source, notamment `lib/ui.sh`, `lib/state.sh`, `lib/questions.sh`, `lib/disk.sh`, `lib/gpu.sh`, `lib/base.sh`, les listes de paquets et `link.sh`.

Le manifeste `tests/bboysidou-install.sha256` provient des fichiers originaux téléchargés. `tests/verifier-adaptation.sh` vérifie leur identité après normalisation des seules différences autorisées ci-dessus. Il vérifie aussi l’affichage de la barre de progression d’origine.

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

Ces vérifications ne constituent pas une nouvelle installation complète depuis l’ISO avec compilation de tous les paquets AUR. Le parcours d’installation est celui de la source indiquée, et n’a pas été réécrit pour cette adaptation.

## Attribution

Les scripts et ressources de bboysidou conservent leur origine et leurs mentions. Aucune licence n’a été trouvée à la racine de la source examinée ; ce dépôt ne réattribue pas de licence aux contributions et médias de tiers. Les configurations personnelles et les autres programmes restent soumis aux droits et licences de leurs auteurs respectifs.
