#!/bin/bash
# Build the LinuxSpherso live/installer ISO.
# Needs: a Debian 13 (trixie) or Ubuntu 24.04+ host, root, ~25 GB free disk, internet.
#   sudo ./build.sh            # full build (includes GE-Proton)
#   sudo WITH_GE_PROTON=0 ./build.sh
set -euo pipefail
cd "$(dirname "$0")"
[ "$(id -u)" = 0 ] || { echo "Run as root: sudo ./build.sh"; exit 1; }

if ! command -v lb >/dev/null; then
  apt-get update
  apt-get install -y live-build debootstrap dctrl-tools xorriso squashfs-tools mtools dosfstools \
    grub-pc-bin grub-efi-amd64-bin grub-efi-ia32-bin librsvg2-bin isolinux syslinux-common syslinux-utils grub-common debian-archive-keyring python3-pil
fi
# Ubuntu hosts: make sure debootstrap knows trixie
[ -e /usr/share/debootstrap/scripts/trixie ] || ln -s sid /usr/share/debootstrap/scripts/trixie

# --- Live ISO GRUB menu, themed with the Linux Sphere wallpaper ---
if [ ! -d config/bootloaders/grub-pc ]; then
  mkdir -p config/bootloaders
  cp -r /usr/share/live/build/bootloaders/grub-pc config/bootloaders/
fi
python3 - <<'P'
from PIL import Image, ImageEnhance
im = Image.open("artwork/linuxsphere-1920x1080.png").convert("RGB").resize((1920,1080))
ImageEnhance.Brightness(im).enhance(0.6).save("config/bootloaders/grub-pc/splash.png")
P
# rename live menu entries
grep -rl "Live system" config/bootloaders/grub-pc 2>/dev/null | xargs -r sed -i 's/Live system/LinuxSpherso Live/g' || true

export WITH_GE_PROTON="${WITH_GE_PROTON:-1}"
lb clean --purge || true
lb config
lb build
ls -lh ./*.iso
echo "ISO ready. Test with: qemu-system-x86_64 -enable-kvm -m 8G -smp 4 -cdrom LinuxSpherso-amd64.hybrid.iso"
