# Origine des fichiers

L’organisation de cet installateur (amorçage GitHub, modules Bash, menus gum et listes de paquets) s’inspire de [bboysidou/dotfile_hyperland](https://github.com/bboysidou/dotfile_hyperland). Les nouveaux modules de `install/`, le post-install et les tests ont été écrits pour ce projet.

Les configurations `configs/hypr`, `configs/quickshell` et `configs/nvim` proviennent de la configuration personnelle de kilammac, elle-même adaptée notamment des dotfiles de bboysidou. Les mentions et crédits présents dans ces fichiers sont conservés. Elles ont été préparées pour une nouvelle machine : écrans automatiques, chemins portables, démarrage conditionnel des applications facultatives et retrait des scripts Python de cette distribution.

Aucune licence n’a été trouvée dans la copie locale du dépôt de référence examinée. Ce projet ne réattribue pas de licence aux contributions ou médias de tiers ; leur présence ici ne constitue pas une autorisation générale de réutilisation. Consulter leurs auteurs pour les conditions applicables.

Les programmes installés et les extensions Neovim téléchargées restent soumis à leurs licences respectives. Arch Linux, Hyprland et les noms des projets cités appartiennent à leurs titulaires.

## Références techniques

- [Btrfs : administration et compression](https://btrfs.readthedocs.io/en/latest/Administration.html)
- [Btrfs : scrub](https://btrfs.readthedocs.io/en/latest/btrfs-scrub.html)
- [ArchWiki : systemd-boot](https://wiki.archlinux.org/title/Systemd-boot)
- [ArchWiki : Zram](https://wiki.archlinux.org/title/zram)
- [Hyprland : configuration Lua](https://hypr.land/news/26_lua/)
- [Hyprland : NVIDIA](https://wiki.hypr.land/nvidia/)
- [Arch : transition NVIDIA 590 et matériels anciens](https://archlinux.org/news/nvidia-590-driver-drops-pascal-support-main-packages-switch-to-open-kernel-modules/)

Copie de référence examinée : commit `af083563fd37c32ef9fe64adffe058fe19b57f29`.
