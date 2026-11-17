#!/bin/bash
# Runs inside WSL2 (as root), called by build.bat.
# Copies the project to the Linux filesystem, builds the ISO, copies it back.
set -euo pipefail
SRC="$(pwd)"                       # the Windows folder, e.g. /mnt/c/Users/you/LinuxSpherso
WORK=/root/LinuxSpherso-build

echo "[wsl] Project folder: $SRC"
command -v rsync >/dev/null || { apt-get update -qq; DEBIAN_FRONTEND=noninteractive apt-get install -y -qq rsync; }

# Building on /mnt/c is very slow and loses Linux permissions, so work in ext4.
mkdir -p "$WORK"
rsync -a --delete --exclude '/.git/' --exclude '/*.iso' \
  --exclude '/chroot/' --exclude '/binary/' --exclude '/cache/' --exclude '/.build/' \
  --exclude '/build.log' "$SRC/" "$WORK/"
cd "$WORK"

# Undo Windows line endings (text files only) and restore executable bits.
grep -rlI $'\r' --exclude-dir=chroot --exclude-dir=cache . 2>/dev/null | xargs -r sed -i 's/\r$//'
chmod +x build.sh auto/* config/hooks/live/* config/includes.chroot/usr/local/bin/* 2>/dev/null || true

[ "${DRY_RUN:-0}" = 1 ] && { echo "[wsl] DRY_RUN: prepared $WORK, not building"; exit 0; }

./build.sh 2>&1 | tee build.log
ISO=$(ls -t "$WORK"/*.iso 2>/dev/null | head -n1)
[ -n "$ISO" ] || { echo "[wsl] No ISO produced"; exit 1; }
echo "[wsl] Copying $(basename "$ISO") back to Windows..."
cp "$ISO" "$SRC/"
