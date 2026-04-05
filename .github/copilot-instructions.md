# Copilot Instructions — c64stuff

KickAssembler-based Commodore 64 demo/game playground. All code is 6502 assembly targeting PAL hardware. Written almost entirely by AI (GPT-5.1-Codex); assume silicon-authored conventions throughout.

---

## Build

**Primary build (from repo root):**
```
java -jar kickassembler/KickAss.jar -odir ./bin -log buildlog.txt -showmem -debugdump -vicesymbols main.asm
```
Output: `bin/main.prg`, `bin/main.vs` (VICE symbol file), `buildlog.txt`.

**VS Code task:** `Build kickass main.asm` (wraps the command above).  
**Debug:** F5 in VS Code launches VICE with the KickAssembler extension (`launch.json`).

There are no unit tests. Validation means loading `bin/main.prg` (or `d64/c64stuff.d64`) into VICE and running it.

---

## Architecture

The entire project assembles as a **single KickAssembler pass** rooted at `main.asm`. Source modules are pulled in with `.import source`:

```
main.asm
  └─ .import source "gfx.asm"       // must come first – defines label addresses used everywhere
  └─ .import source "game.asm"
       └─ .import source "sid/soundfx.asm"
```

### Memory map

| Address | Contents |
|---------|----------|
| `$2000` | `LogoChars` – custom charset for intro logo (imported binary `png/Logo - Chars.bin`) |
| `$2800` | `game_bg_charset` – 11-tile background tileset (inline bytes in `gfx.asm`) |
| `$3000`+ | Sprite bitmaps: `right0/1/2`, `left0/1/2`, `rightk`, `leftk`, `rightkn`, `leftkn`, `rightd`, `leftd`, `rightj`, `leftj` (64 bytes each, multicolor) |
| `$4000` | `start` – intro entry point (`BasicUpstart2` targets here) |
| `$6000` | `game_start` – game entry point (jumped to from intro on SPACE) |
| `music.location` | SID file loaded at its native address via `LoadSid()` |

Screen RAM is always `$0400`. Color RAM is always `$d800`.  
Sprite 0 pointer lives at `$07f8` (single sprite used throughout).

### Module roles

- **`main.asm`** — intro screen: black background, custom charset logo at top (15×6 chars), horizontal text scroller at row `$05e0`, static info rows, SID music playback. Dual-charset raster IRQ (custom at `$2000` for logo rows, ROM at `$1000` for text rows, split at raster `$78`).
- **`game.asm`** — side-scrolling gameplay: cyan background, 25-row tile background (64-column wide ring buffer), sprite walk/kick/kneel/jump animation, CIA keyboard scanning, temple overlay scripted at scroll count 120.
- **`gfx.asm`** — all shared binary data: logo charset, background tileset bytes, all sprite bitmaps, logo map data. Must be imported before `game.asm` because sprite label addresses (`right0`, `left0`, etc.) are referenced in both.
- **`sid/soundfx.asm`** — SFX routines using **SID voice 2 only** (`$d407–$d40d`). Exposes: `sfx_walk`, `sfx_walk_stop`, `sfx_kick`, `sfx_jump`, `sfx_duck`. Uses `.macro sfx_trigger(...)` and `.macro sfx_gate_off()`.

---

## Key Conventions

### KickAssembler specifics
- Constants use `.const NAME = value`; zero-page pointers use `.const ZP_LABEL = $xx` then referenced as `sta ZP_LABEL`.
- Sprite pointer value = sprite base address `/ 64` (e.g., `right0 / 64`).
- `BasicUpstart2(start)` generates the BASIC `SYS` stub; always the first line of `main.asm`.
- `.fill N, value` pads data blocks; `.import binary "path"` pulls raw asset bytes.

### Keyboard input
Direct CIA matrix scanning via `$dc00`/`$dc01` — **not** KERNAL `GETIN`. Pattern:
```
sei
lda $dc00 / tax                // save original column state
lda #COL_MASK / sta $dc00      // pull target column low
lda $dc01 / tay                // read rows
txa / sta $dc00                // restore column
cli
tya / and #ROW_BIT             // test specific key; beq = key is down
```
SPACE in the intro uses KERNAL (`$ff9f` + `$ffe4`) as an exception.

### Frame timing
Movement and animation throttle using jiffy clock at `$a2` (incremented by KERNAL IRQ ~50× per second). Compare `lda $a2 / cmp last_jiffy` to gate per-frame actions.

### Background scrolling
The 64-column tile map wraps with `AND #BG_MASK` (`BG_MASK = BG_WIDTH - 1 = $3f`). Each row has its own tile pointer table (`bg_row_tile_ptr_lo/hi`). The scroll engine redraws all 25 rows every scroll tick — no hardware scroll register is used.

### Raster IRQ / charset switching
Two IRQs per frame: top fires at raster `$00` → set `$d018=$18` (custom charset); bottom fires at `RASTER_SPLIT=$78` → play SID music + set `$d018=$14` (ROM charset). IRQ chains to `$ea31`.

### SID usage
- Voice 1/3: SID tune (`MacGyver_Title.sid`) driven by `jsr MUSIC_PLAY` once per frame in the raster IRQ.
- Voice 2: SFX only (`sid/soundfx.asm`). Never clobber voice 2 from other code.
- On game start, silence all SID registers then restore volume: `lda #$0f / sta $d418`.

### Zero-page allocation
| ZP range | Owner |
|----------|-------|
| `$f0–$fe` | game.asm background renderer (`BG_SCREEN_PTR`, `BG_COLOR_PTR`, etc.) |
| `$fb–$fe` | main.asm logo draw (`map_ptr=$fb`, `scr_ptr=$fd`) — overlaps by convention; safe because game replaces intro |

### Authoritative references
`docs/KickAssembler.pdf` and `docs/Commodore 64 Programmer's Reference Guide.pdf` are the ground truth. Assume full knowledge of VIC-II, SID, CIA registers, Kernal entry points, and C64 banking rules.
