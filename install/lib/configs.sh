#!/usr/bin/env bash
backup_path() {
  local path=$1
  if [[ -e $path || -L $path ]]; then run mv -- "$path" "$path.backup-$(date +%Y%m%d-%H%M%S)-$$"; fi
}
install_configs() {
  local user_home="$TARGET/home/$USERNAME" name
  run mkdir -p "$user_home/.config" "$TARGET/opt/arch-insall"
  for name in hypr quickshell nvim kitty xdg-desktop-portal; do
    backup_path "$user_home/.config/$name"
    run cp -a "$PROJECT/configs/$name" "$user_home/.config/$name"
  done
  run mkdir -p "$user_home/.config/systemd/user"
  backup_path "$user_home/.config/systemd/user/quickshell.service"
  run cp "$PROJECT/configs/systemd/user/quickshell.service" "$user_home/.config/systemd/user/"
  write_file "$user_home/.config/hypr/config/installer.lua" <<LUA
-- Généré pour cette installation. Modifiable après redémarrage.
hl.config({ input = { kb_layout = "$XKB_LAYOUT" } })
LUA
  run install -d -m755 "$user_home/Pictures" "$user_home/Pictures/wallpaper"
  backup_path "$user_home/Pictures/wallpaper/default.png"
  run install -m644 "$PROJECT/configs/quickshell/media/wallpaper/default.png" "$user_home/Pictures/wallpaper/default.png"
  chroot_run chown "$USERNAME:$USERNAME" "/home/$USERNAME/Pictures"
  chroot_run chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/Pictures/wallpaper"
  run install -Dm644 "$PROJECT/configs/pam-quickshell" "$TARGET/etc/pam.d/quickshell"
  # Copie limitée aux ressources de l'installateur, sans Git ni fichiers personnels.
  for name in install packages configs docs; do run cp -a "$PROJECT/$name" "$TARGET/opt/arch-insall/"; done
  run cp "$PROJECT/post-install.sh" "$PROJECT/README.md" "$TARGET/opt/arch-insall/"
  run chmod -R a+rX "$TARGET/opt/arch-insall"
  run install -Dm755 "$PROJECT/configs/start-hyprland" "$TARGET/usr/local/bin/start-hyprland"
  chroot_run chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.config"
  info 'Neovim téléchargera ses extensions au premier lancement (connexion Internet requise).'
}
