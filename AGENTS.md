# AGENTS.md — c64stuff

KickAssembler-based Commodore 64 demo/game playground. All source code is **6502 assembly** in the KickAssembler dialect, targeting PAL hardware. This file documents build commands, architecture, and coding conventions for agentic coding agents working in this repo.

---

## Build

**Primary build (run from repo root):**
```
java -jar kickassembler/KickAss.jar -odir ./bin -log buildlog.txt -showmem -debugdump -vicesymbols main.asm
```
- Output: `bin/main.prg`, `bin/main.vs` (VICE symbol file), `buildlog.txt`
- VS Code task: `Build kickass main.asm` (`Ctrl+Shift+B`) wraps the command above
- F5 in VS Code launches VICE with symbols via the KickAssembler extension (`launch.json`)

**Legacy scripts (not normally needed):**
- `make_prg.ps1` — compile each `.asm` individually with `cl65.exe` → `prg/`
- `make_d64.ps1` — pack `prg/*.prg` into a D64 disk image with VICE's `c1541.exe`

**Check for build errors:** inspect `buildlog.txt` after assembly. A successful build ends with no `Error` lines.

---

## Testing

**There are no unit tests or CI pipelines.** This is bare-metal 6502; validation is always manual.

To validate a change:
1. Build as above.
2. Load `bin/main.prg` into VICE (`x64sc`): File → Autostart, or drag-and-drop.
3. The game starts automatically via the `BasicUpstart2` SYS stub.
4. Step through logic with VICE's built-in Monitor/debugger using `bin/main.vs` for symbols.

There is no concept of "running a single test" — the unit of validation is always the full emulated program.

---

## Architecture

The project assembles in a **single KickAssembler pass** rooted at `main.asm`. There is no linker; all modules share one symbol namespace. Import order is load-address significant.

```
main.asm
  └─ .import source "gfx.asm"              // MUST be first — defines sprite label addresses
  └─ .import source "charview.asm"
  └─ .import source "game.asm"
       └─ .import source "sid/soundfx.asm"
  └─ .import source "temple_interior.asm"
  └─ .import source "music.asm"
```

### Module roles

| File | Role |
|------|------|
| `main.asm` | Intro screen, dual-charset raster IRQ, SID music driver |
| `game.asm` | Scrolling gameplay, sprite animation, CIA keyboard, Kuro boss |
| `gfx.asm` | All binary graphics data (charset, sprite bitmaps, logo map) |
| `charview.asm` | Charset viewer screen shown between title and game |
| `temple_interior.asm` | Level 2 interior room |
| `music.asm` | Original SID composition (3-voice) |
| `sid/soundfx.asm` | SFX routines using SID voice 2 only |

### Memory map

| Address | Contents |
|---------|----------|
| `$2000` | `LogoChars` — custom charset for intro logo |
| `$2800` | `game_bg_charset` — 11-tile background tileset |
| `$3000`+ | Sprite bitmaps |
| `$4000` | `start` — intro entry point |
| `$6000` | `game_start` — game entry point |
| `music.location` | SID file |

Screen RAM: `$0400`. Color RAM: `$d800`. Sprite 0 pointer: `$07f8`.

### Zero-page allocation

| ZP range | Owner |
|----------|-------|
| `$f0–$fe` | `game.asm` background renderer |
| `$fb–$fe` | `main.asm` logo draw (safe overlap — intro is replaced by game at runtime) |

---

## Naming Conventions

### Constants (`.const`)
- `SCREAMING_SNAKE_CASE` — e.g., `GAME_SPRITE0_X`, `BG_VISIBLE_COLS`, `ANIM_FRAME_TICKS`
- Prefix by category: `TILE_*`, `KEY_*`, `KURO_STATE_*`, `POSE_MODE_*`
- Pointer values end in `_PTR`: `GAME_RIGHT0_PTR`, `BOULDER_RUBBLE_PTR`
- ZP pointer constants end in `_ZP`: `BG_SCREEN_PTR`, `BG_SRC_COL_ZP`

### Labels (subroutines, entry points, data)
- `snake_case` — e.g., `game_start`, `draw_background_window`, `check_kuro_kick_hit`
- Local branch targets within a routine use descriptive suffixes: `_done`, `_loop`, `_ok`, `_skip`, `_set`
  - e.g., `bg_row_loop`, `bg_src_no_wrap`, `anim_wait_next_tick`
- Module-prefix on exported labels: `bg_`, `ti_` (temple interior), `cv_` (charview), `sfx_`, `kuro_`
- Music state variables use `m_` prefix: `m_tick`, `m_v1pos`, `m_arp_phase`

### Data variables
- `snake_case` — e.g., `scroll_pos`, `anim_frame`, `player_hp`, `boss_hp`
- 16-bit pointer pairs: `_lo` / `_hi` suffix — e.g., `kuro_x_lo` / `kuro_x_hi`
- Lookup tables: descriptive suffix — `anim_ptrs_right`, `bg_row_color`, `jump_y_offsets`, `freq_lo`

### Sprite / charset labels (gfx.asm)
- Named by direction and frame: `right0`, `right1`, `left0`, `rightk`, `leftkn`, `rightj`
- Boss: `kuro_r0`, `kuro_r1`, `kuro_rs`, `kuro_ld`
- The only PascalCase label: `LogoChars` (historical; do not add more)

---

## Code Style

### Comments
- Every hardware register access gets a trailing `//` comment naming the register and its purpose:
  ```asm
  lda #%00000001     // enable raster IRQ
  sta $d01a
  lda $d019          // clear pending IRQ flags
  ```
- Section dividers within long files:
  ```asm
  // --- Background rendering ---
  ```
  or for major sections in `music.asm`:
  ```asm
  // ============================================================
  // MUSIC_PLAY — advance pattern, write SID regs. Call once/frame.
  // ============================================================
  ```
- Data tables in `gfx.asm` carry a `// tile N: description` comment per entry.
- Complex routines get a full doc-block above them describing calling convention, algorithm, and tricky interactions.

### Formatting
- Tabs for indentation.
- Blank lines separate logical phases within a routine.
- Align operand comments horizontally where practical.

### Constants vs. literals
- All magic numbers declared as `.const` at the top of the file that uses them.
- Raw hex literals (`$xx`) are acceptable only for hardware registers and bit patterns.
- Bit masks written in binary (`%00000001`) to make intent visually obvious.

---

## Hardware Rules

### SID
- Voice 1 and 3: SID tune, driven by `jsr MUSIC_PLAY` once per frame.
- **Voice 2: SFX only** (`sid/soundfx.asm`). Never write SID voice 2 registers from any other code.
- On game start: silence all SID registers, then restore volume: `lda #$0f / sta $d418`.

### IRQ handlers
- Always save/restore all registers: `pha / txa / pha / tya / pha` at entry; `pla / tay / pla / tax / pla` at exit.
- Chain to `$ea31` (KERNAL IRQ continuation) at exit.
- Dual raster IRQs per frame: top at `$00` (switch to custom charset); bottom at `$78` (play SID, switch to ROM charset).

### Screen writes
- Wrap all background draw calls in `sei` / `cli` with `wait_frame_safe_window` to avoid tearing.
- Read-modify-write pattern for hardware registers: always `lda → and/ora → sta`; never two independent `sta` writes.

### Coordinate safety
- Clamp hardware sprite coordinates at screen boundaries explicitly; never rely on wrapping.

### State guards
- Check boolean flags at subroutine entry before mutating state (e.g., `kuro_active`, `door_open`).
- Use cooldown timers (e.g., `kuro_hit_cooldown`) on hit detection to prevent repeated rapid damage.

---

## KickAssembler Specifics

- Define constants with `.const NAME = value` (not `=` alone or EQU).
- Sprite pointer value = sprite address `/ 64`.
- Pad with `.fill N, value`; import raw binary with `.import binary "path"` (paths relative to repo root).
- `BasicUpstart2(start)` generates the BASIC SYS stub at the start of the PRG.
- All source modules included with `.import source "filename.asm"`.

### Keyboard input
Direct CIA matrix scanning via `$dc00` / `$dc01`. SPACE on the intro screen uses KERNAL as an exception.

### Frame timing
Jiffy clock at `$a2` (~50× per second on PAL). Pattern: `lda $a2 / cmp last_jiffy`.

### Background scrolling
64-column ring buffer; wraps with `AND #BG_MASK` (`BG_MASK = $3f`). No hardware scroll register used.

---

## Authoritative References

- `docs/KickAssembler.pdf` — canonical KickAssembler language reference
- `docs/Commodore 64 Programmer's Reference Guide.pdf` — hardware registers, memory map, SID, VIC-II
