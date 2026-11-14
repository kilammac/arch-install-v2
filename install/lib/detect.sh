#!/usr/bin/env bash
# Les paramètres permettent les essais sur données simulées, sans modifier /sys.
nvidia_generation() {
  case "$1" in
    *' TU'[0-9]*|*' GA'[0-9]*|*' AD'[0-9]*|*' GB'[0-9]*|*' GH'[0-9]*) echo open ;;
    *' GM'[0-9]*|*' GP'[0-9]*|*' GV'[0-9]*|*' GK'[0-9]*|*' GF'[0-9]*|*' GT'[0-9]*) echo legacy ;;
    *) echo unknown ;;
  esac
}
detect_hardware() {
  local pci=${1-} usb=${2-} cpu=${3-} virt=${4-} power=${5-/sys/class/power_supply} entry generation
  HW_PACKAGES=(); HW_MODULES=(); HW_NOTES=()
  HW_NVIDIA=none; HW_BLUETOOTH=0; HW_WIFI=0; HW_LAPTOP=0; HW_VIRT=$virt
  HW_GPU_COUNT=0; HW_HYBRID=0; HW_CPU=unknown
  case "$cpu" in
    *GenuineIntel*) HW_CPU=intel; HW_PACKAGES+=(intel-ucode) ;;
    *AuthenticAMD*) HW_CPU=amd; HW_PACKAGES+=(amd-ucode) ;;
  esac
  while IFS= read -r entry; do
    [[ $entry =~ \[(0300|0302|0380)\] ]] || continue
    HW_GPU_COUNT=$((HW_GPU_COUNT + 1))
    case "$entry" in
      *'[8086:'*)
        HW_PACKAGES+=(mesa vulkan-intel)
        if [[ $entry =~ (Sandy|Ivy|Haswell|Ironlake|HD\ Graphics\ [234][0-9]{3}) ]]; then
          HW_PACKAGES+=(libva-intel-driver)
        else HW_PACKAGES+=(intel-media-driver); fi ;;
      # mesa fournit aussi libva-mesa-driver (nom virtuel, pas un paquet séparé).
      *'[1002:'*) HW_PACKAGES+=(mesa vulkan-radeon) ;;
      *'[10de:'*)
        generation=$(nvidia_generation "$entry")
        # Ne jamais masquer un GPU non reconnu ou ancien dans une machine multi-GPU.
        if [[ $HW_NVIDIA == none || $generation == unknown || $generation == legacy && $HW_NVIDIA == open ]]; then
          HW_NVIDIA=$generation
        fi ;;
      *'[1af4:'*|*'[15ad:'*|*'[1234:'*) HW_PACKAGES+=(mesa); HW_NOTES+=('GPU virtuel : accélération Wayland à vérifier dans la VM.') ;;
      *) HW_NOTES+=("GPU inconnu : $entry (pilote noyau à vérifier)") ;;
    esac
  done <<< "$pci"
  if ((HW_GPU_COUNT > 1)); then HW_HYBRID=1; fi
  if grep -qiE 'Bluetooth|\[0d11\]' <<< "$pci $usb" || compgen -G '/sys/class/bluetooth/hci*' >/dev/null; then
    HW_BLUETOOTH=1; HW_PACKAGES+=(bluez bluez-utils)
  fi
  if grep -qE '\[0280\]' <<< "$pci"; then HW_WIFI=1; HW_PACKAGES+=(iw wireless-regdb); fi
  if compgen -G "$power/BAT*" >/dev/null; then HW_LAPTOP=1; fi
  case "$virt" in
    kvm|qemu) HW_PACKAGES+=(qemu-guest-agent);;
    vmware) HW_PACKAGES+=(open-vm-tools);;
    oracle) HW_PACKAGES+=(virtualbox-guest-utils);;
  esac
  # Les autres pilotes réseau, stockage et audio restent ceux du noyau.
  HW_NOTES+=('linux-firmware et sof-firmware conservés pour les périphériques présents ou branchés ultérieurement.')
}
probe_hardware() {
  detect_hardware "$(lspci -nn)" "$(lsusb)" "$(cat /proc/cpuinfo)" "$(systemd-detect-virt || true)"
}
select_drivers() {
  local mode=${NVIDIA_MODE:-$HW_NVIDIA}
  case "$mode" in
    open)
      HW_PACKAGES+=(nvidia-open-dkms nvidia-utils egl-wayland "${KERNEL}-headers")
      if ((EXTRA_KERNEL)); then
        if [[ $KERNEL == linux ]]; then HW_PACKAGES+=(linux-lts-headers); else HW_PACKAGES+=(linux-headers); fi
      fi
      HW_MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm) ;;
    legacy|nouveau) HW_PACKAGES+=(mesa vulkan-nouveau) ;;
    unknown) HW_NOTES+=('NVIDIA non identifié : aucun pilote propriétaire choisi automatiquement.');;
  esac
}
