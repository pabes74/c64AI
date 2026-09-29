# CLAUDE.md — c64stuff

KickAssembler-based Commodore 64 game "Artificial Fist". All source is **6502 assembly** in the KickAssembler dialect. See AGENTS.md for the full reference — this file summarises what Claude Code needs to operate effectively.

---

## Build

```bash
java -jar /home/pabes/Projects/kickassembler/KickAss.jar \
  -odir ./bin -log buildlog.txt -showmem -debugdump -vicesymbols main.asm
```

Always check `buildlog.txt` for `Error` lines after building.

**Loader build (separate binary):**
```bash
java -jar /home/pabes/Projects/kickassembler/KickAss.jar \
  -odir ./bin -log buildlog.txt -showmem -debugdump -vicesymbols loader.asm
```

---

## Testing

No automated tests. Validate by loading `bin/main.prg` into VICE (`x64sc`). The game auto-starts via `BasicUpstart2`.

**Runtime probe (inspect live emulator state):**
```bash
python3 tools/vice_probe.py \
  --vice /usr/bin/x64sc \
  --prg  /home/pabes/Projects/c64stuff/bin/main.prg \
  --wait 25 --run 3 \
  --dump "0x0000-0x00FF,0x07F8-0x07FF,0xD000-0xD02E,0xD400-0xD41C"
```

---

## Module import order (load-address significant)

```
main.asm
  └─ .import source "gfx.asm"              // MUST be first
  └─ .import source "charview.asm"
  └─ .import source "game.asm"
       └─ .import source "sid/soundfx.asm"
  └─ .import source "temple_interior.asm"
  └─ .import source "music.asm"
```

---

## Critical hardware rules

- **SID voice 2 is SFX only** (`sid/soundfx.asm`). Never write voice 2 from any other code.
- **IRQ handlers:** `pha/txa/pha/tya/pha` on entry; chain to `$ea31` on exit.
- **Screen writes:** wrap in `sei/cli` with `wait_frame_safe_window`.
- **Hardware registers:** read-modify-write only (`lda → and/ora → sta`).

---

## Naming conventions

| Kind | Style |
|------|-------|
| Constants | `SCREAMING_SNAKE_CASE` |
| Labels / subroutines | `snake_case` with module prefix (`bg_`, `ti_`, `cv_`, `sfx_`, `kuro_`) |
| Local branches | `_done`, `_loop`, `_ok`, `_skip`, `_set` suffixes |
| Music state | `m_` prefix |

---

## Authoritative references

- `AGENTS.md` — full conventions, memory map, ZP allocation, code style
- `docs/KickAssembler.pdf` — assembler language reference
- `docs/Commodore 64 Programmer's Reference Guide.pdf` — hardware registers
- `.opencode/skills/c64-assembler/SKILL.md` — complete 6502/KickAssembler skill
- `.opencode/skills/vice-c64-probe/SKILL.md` — VICE BMP probe skill
- `.opencode/skills/c64-sidmusic/SKILL.md` — SID music composition skill
