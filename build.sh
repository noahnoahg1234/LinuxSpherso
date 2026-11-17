#!/bin/bash
# Build the LinuxSpherso live/installer ISO.
# Needs: a Debian 13 (trixie) or Ubuntu 24.04+ host, root, ~25 GB free disk, internet.
#   sudo ./build.sh            # full build (includes GE-Proton)
#   sudo WITH_GE_PROTON=0 ./build.sh
set -euo pipefail
cd "$(dirname "$0")"
[ "$(id -u)" = 0 ] || { echo "Run as root: sudo ./build.sh"; exit 1; }

# --- Host build tools (installed every run; apt skips what is already there) ---
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y live-build debootstrap dctrl-tools xorriso squashfs-tools mtools dosfstools \
  grub-pc-bin grub-efi-amd64-bin grub-efi-ia32-bin grub-common librsvg2-bin isolinux \
  syslinux-common syslinux-utils debian-archive-keyring python3-pil curl rsync cpio wget file xz-utils

# live-build/debootstrap older than Debian 13's can't build trixie images
# (e.g. Debian 12 under WSL, older Ubuntu). Fetch the Debian 13 versions.
fetch_deb() {  # $1 = package name; downloads Debian 13's version, prints its path
  local idx=/tmp/trixie-all-Packages
  [ -s "$idx" ] || curl -fsSL https://deb.debian.org/debian/dists/trixie/main/binary-all/Packages.xz | xz -d > "$idx"
  local f; f=$(awk -v p="$1" '$1=="Package:"{m=($2==p)} m&&$1=="Filename:"{print $2; exit}' "$idx")
  [ -n "$f" ] && curl -fsSL "https://deb.debian.org/debian/$f" -o "/tmp/${f##*/}" && echo "/tmp/${f##*/}"
}
LB_VER=$(lb --version 2>/dev/null | grep -o '^[0-9]\{8\}' || echo 0)
if [ "$LB_VER" -lt 20250000 ]; then
  echo "Upgrading live-build ($LB_VER) and debootstrap to Debian 13 versions..."
  DEBS="$(fetch_deb live-build) $(fetch_deb debootstrap) $(fetch_deb debian-archive-keyring)"
  apt-get install -y $DEBS
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

# Settings for the chroot hooks (live-build clears env vars inside the chroot).
# Removed from the image again by hooks/live/0900-cleanup.
mkdir -p config/includes.chroot/etc
echo "WITH_GE_PROTON=${WITH_GE_PROTON:-1}" > config/includes.chroot/etc/linuxsphere-build.conf
lb clean --purge || true
lb config
lb build
ls -lh ./*.iso
echo "ISO ready. Test with: qemu-system-x86_64 -enable-kvm -m 8G -smp 4 -cdrom LinuxSpherso-amd64.hybrid.iso"
