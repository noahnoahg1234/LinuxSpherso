#!/bin/bash
# Runs inside WSL2 (as root), called by build.bat.
# Copies the project to the Linux filesystem, builds the ISO, copies it back.
set -euo pipefail
SRC="$(pwd)"                       # the Windows folder, e.g. /mnt/c/Users/you/LinuxSpherso
# Build in the normal WSL user's home (passed in by build.bat) so Windows
# Explorer can open it; Explorer can't read /root.
U="${WSL_USER:-root}"
if [ "$U" != root ] && id "$U" >/dev/null 2>&1; then
  WORK="/home/$U/LinuxSpherso-build"
else
  WORK=/root/LinuxSpherso-build
fi

echo "[wsl] Project folder: $SRC"
command -v rsync >/dev/null || { apt-get update -qq; DEBIAN_FRONTEND=noninteractive apt-get install -y -qq rsync; }

# Building on /mnt/c is very slow and loses Linux permissions, so work in ext4.
mkdir -p "$WORK"
[ "$U" != root ] && chown "$U": "$WORK" 2>/dev/null || true
rsync -a --delete --exclude '/.git/' --exclude '/*.iso' \
  --exclude '/chroot/' --exclude '/binary/' --exclude '/cache/' --exclude '/.build/' \
  --exclude '/build.log' "$SRC/" "$WORK/"
cd "$WORK"

# Undo Windows line endings (text files only) and restore executable bits.
grep -rlI $'\r' --exclude-dir=chroot --exclude-dir=cache . 2>/dev/null | xargs -r sed -i 's/\r$//'
chmod +x build.sh auto/* config/hooks/live/* config/includes.chroot/usr/local/bin/* 2>/dev/null || true

[ "${DRY_RUN:-0}" = 1 ] && { echo "[wsl] DRY_RUN: prepared $WORK, not building"; exit 0; }

touch build.log; [ "$U" != root ] && chown "$U": build.log 2>/dev/null || true
./build.sh 2>&1 | tee build.log
ISO=$(ls -t "$WORK"/*.iso 2>/dev/null | head -n1)
[ -n "$ISO" ] || { echo "[wsl] No ISO produced"; exit 1; }
echo "[wsl] Copying $(basename "$ISO") back to Windows..."
cp "$ISO" "$SRC/"

# Free the ~20 GB of build files in WSL; keep only build.log.
echo "[wsl] Cleaning up build files in $WORK (keeping build.log)..."
lb clean --purge >/dev/null 2>&1 || true
find "$WORK" -mindepth 1 -maxdepth 1 ! -name build.log -exec rm -rf {} +
echo "[wsl] Done. Log: $WORK/build.log"
