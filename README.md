# c64AI – Hello World Scroller

## Overview
This repository is a tiny, fully AI-generated Commodore 64 demo that renders a one-line “hello world!” text scroller. The code sits at `$4000`, clears the display, and continuously copies a padded message into a single screen row so it slides from right to left. It is intentionally minimal, making it a great starting point for experimenting with AI-authored 8-bit assembly.

## Repository Layout
- `hello.asm` – KickAssembler-style source for the scrolling text routine.
- `make_prg.ps1` – Builds every `.asm` file into `.prg` binaries with `cl65`.
- `prg/` – Output folder for PRG files (created automatically).
- `make_d64.ps1` – Packs PRG files into a `c64stuff.d64` disk image via VICE `c1541`.
- `d64/` – Output folder for D64 images.
- `docs/`, `tmp/`, `buildlog.txt` – aux files generated during experimentation.

## Requirements
1. **cc65 toolchain** – Place the current snapshot under `../cc65-snapshot-win32/` (adjust the path in `make_prg.ps1` if needed).
2. **VICE emulator tools** – Point `make_d64.ps1` at your `c1541.exe` (defaults to `../SDL2VICE-3.10-win64/c1541.exe`).
3. **PowerShell on Windows** – Scripts are tested on PowerShell 7+, but Windows PowerShell 5.1 also works.

## Build Workflow
1. **Assemble PRG files**
	```powershell
	pwsh .\make_prg.ps1
	```
	This script scans the repo for `.asm` sources, invokes `cl65` with the provided config, and drops the binaries into `prg/`.

2. **Create a D64 image**
	```powershell
	pwsh .\make_d64.ps1
	```
	Every PRG inside `prg/` is written to `d64/c64stuff.d64`, with filenames auto-sanitized for the CBM directory.

## Configure Kick Assembler Studio + VICE
1. **Install the toolchain**
	- Download the latest KickAssembler JAR and point Kick Assembler Studio to it (Settings → Toolchains → KickAssembler → `kickass.jar`).
	- Keep `Project Folder` set to this repo so relative paths like `prg/` resolve automatically.

2. **Set the build command**
	- Command: `java -jar "${KickAssembler}" "${SourceFile}" -o "${ProjectDir}/prg/${SourceName}.prg" -vicesymbols`
	- Working dir: `${ProjectDir}`
	- Output: `${ProjectDir}/prg/${SourceName}.prg`
	This mirrors what `make_prg.ps1` produces and drops binaries where the scripts expect them.

3. **Wire up VICE for quick testing**
	- In Kick Assembler Studio, add a Run Configuration that invokes `x64sc.exe` (or `x64.exe`) from your VICE install.
	- Example command: `"C:/Tools/VICE/x64sc.exe" -autostart "${ProjectDir}/prg/${SourceName}.prg" -warp`
	- Optional: add a post-build step that calls `make_d64.ps1` so the disk image stays in sync.

4. **Optional disk workflow**
	- Configure a secondary run target that executes `c1541.exe` to inject the freshly built PRG into `d64/c64stuff.d64`:
	  ```powershell
	  pwsh ${ProjectDir}/make_d64.ps1
	  ```
	- Start VICE with `-attach d64/c64stuff.d64` if you prefer loading via the virtual drive menu instead of `-autostart`.

## Customization Tips
- Edit the `.text` inside `hello.asm` to change the scrolling message; keep the padding `.fill 40, $20` so the scroll remains smooth.
- Adjust `SCREEN_LINE` if you want to display the text on a different row (`$0400` is the top-left of screen RAM).
- Swap out the delay loops or add color cycling for more interesting effects.

## Credits
Everything in this repository—from assembly to build scripts—was produced with AI assistance. Treat it as a living demo: tweak it, break it, let the AI help rebuild it, and have fun exploring what collaborative retrocoding feels like.

