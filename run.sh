#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Ensure prerequisites: the VICE C64 emulator (provides x64sc) ---
ensure_vice() {
  if command -v x64sc >/dev/null 2>&1; then
    return 0
  fi

  echo "x64sc not found — installing the VICE emulator (needs sudo)..." >&2
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "Error: apt-get not available; install VICE manually (package: vice)." >&2
    exit 1
  fi

  sudo apt-get update
  sudo apt-get install -y vice

  if ! command -v x64sc >/dev/null 2>&1; then
    echo "Error: installed the 'vice' package but x64sc is still not on PATH." >&2
    exit 1
  fi
}

ensure_vice
X64SC="$(command -v x64sc)"

# The Ubuntu 'vice' package ships without the C64 ROMs (DFSG repack).
# Warn early if the kernal ROM is missing so failures are self-explanatory.
if [ ! -e /usr/lib/vice/C64/kernal-901227-03.bin ] \
   && [ ! -e /usr/share/vice/C64/kernal-901227-03.bin ]; then
  echo "Warning: VICE C64 ROMs not found in /usr/lib/vice/C64 or /usr/share/vice/C64." >&2
  echo "         x64sc will fail to boot. Install the ROMs (e.g. from a VICE source build)." >&2
fi

"$X64SC" \
  -moncommands "$SCRIPT_DIR/bin/main.vs" \
  -virtualdev8 \
  +drive8truedrive \
  -autostart "$SCRIPT_DIR/bin/aifist.d64:loader"
