# Artificial Fist

A Commodore 64 side-scrolling karate game written in 6502 assembly using KickAssembler, built as an AI-assisted development experiment. The game is a two-level brawler inspired by 1980s C64 classics like FIST II and Usagi Yojimbo. Read the full development story in [BLOGPART1.md](BLOGPART1.md), [BLOGPART2.md](BLOGPART2.md), and [BLOGPART3.md](BLOGPART3.md).

---

## Building

From the repo root:

```
java -jar /path/to/KickAss.jar -odir ./bin -log buildlog.txt -showmem -debugdump -vicesymbols main.asm
```

Output: `bin/main.prg`, `bin/main.vs` (VICE symbol file), `buildlog.txt`.

The VS Code task `Build kickass main.asm` (Ctrl+Shift+B) wraps this command. F5 launches VICE with the symbol file loaded via the KickAssembler Studio extension.

Check `buildlog.txt` for `Error` lines after every build. There are no automated tests; validation is always manual in VICE (`x64sc`).

---

## Running

Load `bin/main.prg` into VICE via File > Autostart or drag-and-drop. The game starts automatically via the `BasicUpstart2` SYS stub. No manual RUN needed.

---

## Game Structure

The game runs in three sequential screens.

### 1. Title Screen (`main.asm`, entry at `$4000`)

A black-screen intro with a custom multi-colored logo, a scrolling PETSCII text marquee, and the original SID composition playing. Press Space to continue.

Technically: dual raster IRQs per frame split the screen between a custom charset (logo) at the top and the ROM charset (scroller) at the bottom. The SID driver runs from the lower IRQ.

### 2. Charset Viewer (`charview.asm`, `$5000`)

A brief interstitial screen that displays all 16 background tiles in their multicolor palette before the game begins. Press Space to continue.

### 3. Level 1: Scrolling Brawler (`game.asm`, `$6000`)

The main gameplay loop. The player walks left or right through a 64-column ring-buffer scrolling background (sky, distant hills, trees, field, road, grass). Projectiles spawn from off-screen and must be avoided or destroyed. At the end of the level a temple appears and scrolling stops. The boss Kuro, a samurai, walks out to fight.

**Controls:**

| Key | Action |
|-----|--------|
| D | Walk right / scroll right |
| A | Walk left / scroll left |
| W | Jump |
| S | Kneel / duck |
| Space | Kick |

**Projectiles:**

| Type | Behaviour | Counter |
|------|-----------|---------|
| Knife | Flies at standing height | Duck (S) or jump (W) |
| Boulder | Rolls along the ground | Kick (Space) to shatter |

**Boss: Kuro** (sprite slot 5)

Kuro walks toward the player and strikes with his sword when in range. He takes five hits to defeat. When defeated a door appears in the temple; entering it starts Level 2.

**HUD (row 24):**

```
KARATEGAI  ♥♥♥♥♥           <BOSSNAME>  ♥♥♥♥♥
```

Five hearts each for the player and the active boss. Boss name changes per level.

### 4. Level 2: Temple Interior (`temple_interior.asm`)

A locked-camera platform room inside the temple. No scrolling. The player must dodge 10 flying knives (5 travelling right-to-left, 5 left-to-right) across multiple platform heights over a 30-second window. After the window closes a door appears on the right side. Entering it leads to the level 2 boss.

**Boss: Lung** (sprite slot 5)

A multicolor dragon. Lung walks toward the player and periodically enters a fire-breath pose, launching directional fireballs (sprite slots 6 and 7). Fireballs travel in the direction Lung is facing. He takes five hits to defeat.

---

## Module Layout

| File | Entry / Address | Role |
|------|----------------|------|
| `main.asm` | `start` at `$4000` | Title screen, dual-raster IRQ, SID driver, logo draw |
| `charview.asm` | `$5000` | Charset viewer interstitial |
| `game.asm` | `game_start` at `$6000` | Level 1 gameplay, Kuro boss, projectiles, HUD, scrolling background |
| `temple_interior.asm` | called from `game.asm` | Level 2 interior, platform layout, flying knives, Lung boss |
| `gfx.asm` | `$2000` / `$2800` / `$3000`+ | All binary graphics: logo charset, background charset, all sprite bitmaps |
| `music.asm` | `$8000` | Original 3-voice SID composition "Artificial Fist" |
| `sid/soundfx.asm` | included by `game.asm` | SFX routines using SID voice 2 only |

Import order in `main.asm` is load-address significant. `gfx.asm` must be first because sprite label addresses defined there are referenced throughout.

---

## Memory Map

| Address | Contents |
|---------|----------|
| `$2000` | `LogoChars` — custom charset for intro logo |
| `$2800` | `game_bg_charset` — 16-tile background tileset |
| `$3000`+ | Player sprite bitmaps (walk, kick, kneel, jump, hit frames) |
| `$3500`+ | Kuro boss sprites, projectile sprites (knife, boulder) |
| `$3700`+ | Lung dragon sprites (walk left/right, fire poses, death) |
| `$3940`+ | Lung fireball sprites (left and right variants, 2 frames each) |
| `$4000` | `start` — title screen entry point |
| `$5000` | `charview` — charset viewer |
| `$6000` | `game_start` — game entry point |
| `$8000` | `music_init` / `music_play` — SID driver |

Screen RAM: `$0400`. Color RAM: `$d800`. Sprite 0 pointer: `$07f8`.

### Zero-Page Allocation

| Range | Owner |
|-------|-------|
| `$f0–$fe` | `game.asm` background renderer |
| `$fb–$fe` | `main.asm` logo draw (safe overlap: intro is gone before game starts) |
| `$f0–$f4` | `temple_interior.asm` init (reused from background renderer range, safe) |

---

## Sprite Slots

| Slot | Level 1 | Level 2 |
|------|---------|---------|
| 0 | Player | Player |
| 1–4 | Projectiles (knife / boulder pool) | Flying knife pool (shared with 5–7) |
| 5 | Kuro boss | Lung boss |
| 6–7 | unused | Lung fireballs |

---

## Graphics

Background tiles use **multicolor character mode** (`$d016` bit 4 set). Each 8×8 cell gets four colors: global background (`$d021`), two shared colors (`$d022`/`$d023`), and one per-cell color from color RAM.

All sprites are **multicolor** (`$d01c`). The player sprite (slot 0) uses `$d025=$0a` (light red) and `$d026=$00` (black). The Lung boss and its fireballs use `$d025=$07` (yellow) and `$d026=$00` (black), sprite individual color `$02` (red).

Sprite bitmaps were designed in [PixelLab](https://www.pixellab.ai) and converted to C64 format with [Spritemate](https://www.spritemate.com).

---

## SID Music

`music.asm` contains an original three-voice composition in a Last Ninja-inspired style, arranged in three sections:

- **Intro** (24 steps): sparse build-up, arpeggio only, then bass, then melody
- **Main** (32 steps, loops 6×): full three-voice arrangement
- **Var** (32 steps): chromatic variation with Phrygian tension, then loops back to Main

Voice 1: pulse lead with vibrato LFO and PWM. Voice 2: syncopated bass groove (handed to the SFX engine during gameplay). Voice 3: fast pulse arpeggio.

Call `music_init` once before installing the IRQ, then `music_play` once per frame from the raster IRQ.

---

## Tools Used

| Tool | Purpose |
|------|---------|
| [KickAssembler](https://theweb.dk/KickAssembler/) | 6502 assembler |
| [VICE](https://vice-emu.sourceforge.io/) | C64 emulator for testing |
| [KickAssembler Studio](https://marketplace.visualstudio.com/items?itemName=sanmont.kickass-studio) | VS Code extension (build + launch) |
| [PixelLab](https://www.pixellab.ai) | Pixel art tool for sprite design |
| [Spritemate](https://www.spritemate.com) | Multicolor sprite editor / C64 export |
| [OpenCode](https://opencode.ai) | AI CLI agent used for development |

---

## References

- `docs/KickAssembler.pdf` — canonical KickAssembler language reference
- `docs/Commodore 64 Programmer's Reference Guide.pdf` — VIC-II, SID, CIA registers, full memory map
