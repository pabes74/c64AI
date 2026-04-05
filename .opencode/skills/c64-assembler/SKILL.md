---
name: c64-assembler
description: Write, edit, and debug KickAssembler 6502 assembly for Commodore 64 PAL hardware — covering build, memory layout, VIC-II, SID, CIA, IRQ handlers, and project conventions
license: MIT
compatibility: opencode
metadata:
  audience: developers
  platform: commodore-64
  assembler: kickassembler
---

## What I do

- Write and edit 6502 KickAssembler source files following project conventions
- Diagnose KickAssembler build errors from `buildlog.txt`
- Advise on VIC-II (video), SID (audio), and CIA (I/O) hardware register usage
- Help design IRQ handlers, raster splits, sprite multiplexing, and screen effects
- Guide memory layout decisions within the C64 64 KB address space
- Explain or extend the background renderer, sprite animation, and boss state machines in this project
- Write SID music routines and SFX macros following the voice-ownership rules of this codebase
- Review changes for correctness against C64 hardware constraints

## When to use me

Use this skill whenever you are:
- Adding or modifying any `.asm` source file in this project
- Debugging a KickAssembler error or unexpected emulator behavior
- Designing new game mechanics, screens, or effects for the C64
- Working with VIC-II registers, SID registers, or CIA keyboard scanning
- Unsure about memory map placement, zero-page usage, or sprite pointer math

---

## Build

```
java -jar kickassembler/KickAss.jar -odir ./bin -log buildlog.txt -showmem -debugdump -vicesymbols main.asm
```

Run from repo root. Output: `bin/main.prg`, `bin/main.vs`, `buildlog.txt`.  
VS Code shortcut: `Ctrl+Shift+B` → `Build kickass main.asm`.  
Check `buildlog.txt` for `Error` lines after every build.

**There are no unit tests.** Validate by loading `bin/main.prg` into VICE (`x64sc`) and running manually. The game auto-starts via `BasicUpstart2`.

---

## Module import order (load-address significant)

```
main.asm
  └─ .import source "gfx.asm"              // MUST be first — defines all sprite/charset addresses
  └─ .import source "charview.asm"
  └─ .import source "game.asm"
       └─ .import source "sid/soundfx.asm"
  └─ .import source "temple_interior.asm"
  └─ .import source "music.asm"
```

`gfx.asm` must precede `game.asm` — sprite labels defined there are referenced in `game.asm`.

---

## Memory map

| Address | Contents |
|---------|----------|
| `$2000` | `LogoChars` — custom charset (intro logo) |
| `$2800` | `game_bg_charset` — 11-tile background tileset |
| `$3000`+ | Sprite bitmaps |
| `$4000` | `start` — intro entry point |
| `$6000` | `game_start` — game entry point |
| `music.location` | SID music data |

Screen RAM: `$0400`. Color RAM: `$d800`. Sprite 0 pointer: `$07f8`.

### Zero-page allocation

| ZP range | Owner |
|----------|-------|
| `$f0–$fe` | `game.asm` background renderer |
| `$fb–$fe` | `main.asm` logo draw (safe overlap — intro replaced by game at runtime) |

---

## Naming conventions

| Kind | Style | Examples |
|------|-------|---------|
| Constants | `SCREAMING_SNAKE_CASE` | `GAME_SPRITE0_X`, `TILE_SKY`, `KURO_STATE_WALK` |
| Subroutine / data labels | `snake_case` | `game_start`, `draw_background_window` |
| Local branch targets | `label_done/loop/ok/skip/set` | `bg_row_loop`, `anim_wait_next_tick` |
| Module-exported labels | prefix `bg_`, `ti_`, `cv_`, `sfx_`, `kuro_` | `bg_draw_cols`, `sfx_trigger` |
| Music state vars | `m_` prefix | `m_tick`, `m_v1pos`, `m_arp_phase` |
| 16-bit pointer pairs | `_lo` / `_hi` suffix | `kuro_x_lo`, `kuro_x_hi` |
| Sprite pointer constants | `_PTR` suffix | `GAME_RIGHT0_PTR`, `BOULDER_RUBBLE_PTR` |
| ZP pointer constants | `_ZP` suffix | `BG_SCREEN_PTR`, `BG_SRC_COL_ZP` |

The only PascalCase label is `LogoChars` — a historical exception; do not add more.

---

## Code style

### Comments
- Every hardware register write gets a trailing `//` comment: register name + purpose.
- Section banners separate logical regions: `// --- Background rendering ---`
- Major routines in `music.asm` use `// ====` doc-blocks with calling convention and algorithm notes.
- Data tables in `gfx.asm` carry `// tile N: description` per entry.

### Formatting
- Tabs for indentation; blank lines between logical phases within a routine.
- Align trailing comments horizontally where practical.

### Constants vs. literals
- All magic numbers as `.const NAME = value` at the top of the file.
- Hardware register addresses (`$d018`) and bit patterns (`%00000001`) may use raw literals.
- Always use binary notation for bit masks to make intent obvious.

---

## Hardware rules

### SID voice ownership
- **Voice 1 & 3:** SID tune only — driven by `jsr MUSIC_PLAY` once per frame.
- **Voice 2:** SFX only (`sid/soundfx.asm`). Never write voice 2 registers from any other code.
- Game start sequence: zero all SID registers, then `lda #$0f / sta $d418` to restore volume.

### IRQ handlers
- Save/restore all registers: `pha / txa / pha / tya / pha` on entry; `pla / tay / pla / tax / pla` on exit.
- Chain to `$ea31` (KERNAL IRQ continuation) at exit.
- Dual raster IRQs per frame: line `$00` → switch to custom charset; line `$78` → call `MUSIC_PLAY`, switch to ROM charset.

### Screen writes
- Wrap all background draw calls in `sei` / `cli` with `wait_frame_safe_window` to avoid raster tearing.
- Hardware register access: always `lda → and/ora → sta` (read-modify-write); never two separate `sta` writes.

### Coordinate safety
- Clamp hardware sprite X/Y coordinates at screen boundaries explicitly — never rely on register wrapping.

### State guards
- Check boolean flags (`kuro_active`, `door_open`) at subroutine entry before mutating state.
- Use cooldown timers (e.g., `kuro_hit_cooldown`) on hit detection to prevent rapid repeated damage.

---

## KickAssembler specifics

- Constants: `.const NAME = value` (not bare `=` or EQU).
- Sprite pointer = sprite address `/ 64`.
- Padding: `.fill N, value`. Raw binary import: `.import binary "path"` (path relative to repo root).
- BASIC SYS stub: `BasicUpstart2(start)`.
- All source modules: `.import source "filename.asm"`.

### Frame timing
Jiffy clock at `$a2` (~50 Hz PAL). Pattern: `lda $a2 / cmp last_jiffy`.

### Background scrolling
64-column ring buffer, wrap with `AND #BG_MASK` (`BG_MASK = $3f`). No hardware scroll register used.

### CIA keyboard scanning
Direct matrix read via `$dc00` / `$dc01`. SPACE on the intro screen uses KERNAL as a deliberate exception.

---

## Authoritative references

- `docs/KickAssembler.pdf` — canonical language reference (directives, macros, expressions)
- `docs/Commodore 64 Programmer's Reference Guide.pdf` — VIC-II, SID, CIA registers, memory map
