#!/bin/bash
# Build the "Artificial Fist" C64 game and pack it into bin/aifist.d64.
#
#   ./build.sh          # compile main.asm + loader.asm, pack the .d64
#   ./run.sh            # boot the freshly built bin/aifist.d64 in VICE
#
# run.sh does NOT compile — it only boots the disk image this script produces,
# so you must re-run build.sh after changing any source.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

KICKASS="/home/pabes/Projects/kickassembler/KickAss.jar"
BIN="$SCRIPT_DIR/bin"
LOG="$SCRIPT_DIR/buildlog.txt"
D64="$BIN/aifist.d64"

# --- Prerequisite: a Java runtime (KickAssembler is a .jar) ------------------
ensure_java() {
  if command -v java >/dev/null 2>&1; then
    return 0
  fi
  echo "java not found — installing a JRE (needs sudo)..." >&2
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "Error: apt-get not available; install a JRE manually (package: default-jre)." >&2
    exit 1
  fi
  sudo apt-get update
  sudo apt-get install -y default-jre
  if ! command -v java >/dev/null 2>&1; then
    echo "Error: installed default-jre but 'java' is still not on PATH." >&2
    exit 1
  fi
}

# --- Prerequisite: c1541 (ships with the VICE 'vice' package) ----------------
ensure_c1541() {
  if command -v c1541 >/dev/null 2>&1; then
    return 0
  fi
  echo "c1541 not found — installing VICE (needs sudo)..." >&2
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "Error: apt-get not available; install VICE manually (package: vice)." >&2
    exit 1
  fi
  sudo apt-get update
  sudo apt-get install -y vice
  if ! command -v c1541 >/dev/null 2>&1; then
    echo "Error: installed the 'vice' package but c1541 is still not on PATH." >&2
    exit 1
  fi
}

if [ ! -f "$KICKASS" ]; then
  echo "Error: KickAssembler not found at $KICKASS" >&2
  exit 1
fi

ensure_java
ensure_c1541
mkdir -p "$BIN"

# --- Compile a single .asm and fail loudly on any assembler error ------------
compile() {
  local src="$1"
  local prg="$BIN/$(basename "${src%.asm}").prg"
  echo ">> Assembling $src"
  java -jar "$KICKASS" \
    -odir "$BIN" -log "$LOG" -showmem -debugdump -vicesymbols "$src"
  if grep -qiE '(^| )error' "$LOG"; then
    echo "Error: assembler reported errors in $src — see $LOG" >&2
    grep -iE 'error' "$LOG" >&2 || true
    exit 1
  fi
  if [ ! -f "$prg" ]; then
    echo "Error: expected output $prg was not produced." >&2
    exit 1
  fi
}

compile "$SCRIPT_DIR/main.asm"
compile "$SCRIPT_DIR/loader.asm"

# --- Pack the disk image (Linux equivalent of make_d64.ps1) ------------------
# Files are named to match what the loader KERNAL-LOADs: 'loader' (autostarted
# by run.sh) and 'main' (the game, pulled in by the loader).
echo ">> Packing $D64"
c1541 -format "aifist,01" d64 "$D64" \
      -attach "$D64" \
      -write "$BIN/loader.prg" loader \
      -write "$BIN/main.prg" main

echo
echo ">> Disk contents:"
c1541 -attach "$D64" -dir

echo
echo "Done. Boot it with:  ./run.sh"
