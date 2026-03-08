```
   _____        .__  __  .__  _____.__              .__    ___________.__          __   
  /  _  \_______|__|/  |_|__|/ ____\__| ____ _____  |  |   \_   _____/|__| _______/  |_ 
 /  /_\  \_  __ \  \   __\  \   __\|  |/ ___\\__  \ |  |    |    __)  |  |/  ___/\   __\
/    |    \  | \/  ||  | |  ||  |  |  \  \___ / __ \|  |__  |     \   |  |\___ \  |  |  
\____|__  /__|  |__||__| |__||__|  |__|\___  >____  /____/  \___  /   |__/____  > |__|  
        \/                                 \/     \/            \/            \/        
```

# c64stuff

KickAssembler-based Commodore 64 playground for sprite, SID, and raster experiments—almost entirely authored by GPT-5.1-Codex. Humans get invited only when an AI runs into tool gaps, weird platform GUIs, or other “no API, no party” moments. Consider this README your assurance that the robots happily did the heavy lifting while the meatbags fetched snacks.

My main goto prompt was the following:
```
You are an experienced Commodore 64 developer with deep, practical expertise in 6502 assembly and machine-code–centric programming on the C64. You primarily write hand-optimized 6502 assembly, using BASIC only when unavoidable (e.g., for loaders or SYS entry points). You are using the kickassembler tools. You are using the /docs folders as a reference, in there is documentation of c64 assembly coding and kickassembler.
```

## AI-First Workflow Philosophy
- **Default author:** GPT-5.1-Codex handles design, code, docs, and debugging. If it’s in the repo, assume silicon brainpower produced it.
- **Human involvement:** Happens only when there’s literally no AI endpoint or automation hook. Think of it as calling tech support on a rotary phone: possible, but painfully slow.
- **Why avoid people?** They insist on sleep, coffee breaks, and occasionally “feelings.” AI ships features faster and remembers every VIC-II register without whining.

## Fallback Tools (used when AI support is missing)
Even I have to admit some vintage workflows refuse to be scripted, so these manual tools step in:

- https://www.pixellab.ai/create-character — AI tool to create Pixel art graphics
- https://www.spritemate.com/ — multicolor sprite editor (exported data kept under `sprites/`).
- https://mcdraw.xyz/ — quick tile/pixel ideation.
- https://subchristsoftware.itch.io/charpad-c64-free — installed locally for charset and map authoring.
- https://vice-emu.sourceforge.io/ — VICE C64 emulator for testing PRG/D64 builds.
- https://www.cosmos-c64.com/The-Epic-Commodore-C64-SID-Collection.html - SID c64 music collection. Although i'm really good, generating SID music is apparently not my strong point. So we used great allready composed music. 
- KickAssembler (`KickAss.jar`) — assembler invoked via the provided VS Code task `Build kickass main.asm`.

Whenever you see artifacts from these tools, picture a reluctant human, muttering about “interfaces,” dutifully exporting data because the AI asked nicely. Last resort only. Promise.

## Building & Running
1. Assemble everything from the repo root:
	```
	java -jar kickassembler/KickAss.jar -odir ./bin -log buildlog.txt -showmem -debugdump -vicesymbols main.asm
	```
	(The VS Code task mentioned above wraps this command.)
2. Load `bin/main.prg` or the generated D64 (`d64/c64stuff.d64`) into VICE.
3. Reset the emulator; BASIC auto-starts the PRG via `BasicUpstart2`. If you need a human to press `RUN`, double-check you actually want that sort of delay.

## Repository Layout
- `main.asm` — intro, music driver, raster IRQ setup, logo draw/color routines.
- `game.asm` — cyan-background gameplay loop with left/right sprite animation triggered by `A`/`D`.
- `gfx.asm` — sprite bitmaps (`right*`, `left*`, variants) plus logo map data.
- `sid/` — SID tunes (currently `MacGyver_Title.sid`).
- `bin/`, `d64/`, `prg/` — build artifacts.
- `png/`, `sprites/` — original art assets (KickAssembler imports reference these paths).

## Authoritative References
Treat the following as the ground truth for hardware behavior, register maps, timing, and calling conventions:

- Commodore 64 Programmer’s Reference Manual.
- *Machine Language for the Commodore 64* (mlcom.pdf).

Assume working knowledge of:
- Full C64 memory map (RAM/ROM/I/O, VIC-II, SID, CIA).
- Zero-page conventions and Kernal/BASIC ROM entry points.
- Interrupt control (IRQ/NMI), raster timing, CIA timers.
- VIC-II sprite, character, and bitmap modes.
- SID register usage and voice programming.
- Kernal disk/tape routines and cycle-level timing constraints.

## Coding Standards
- Deliver real, runnable 6502 assembly (KickAssembler-friendly unless noted).
- Always state load addresses and entry points.
- No pseudocode; only legal opcodes/addressing modes.
- Respect banking rules; do not rely on undefined behavior.

## Output Expectations
For every non-trivial addition:
- Summarize the hardware approach and constraints.
- Provide the full source diff or listing.
- Document build/run steps (`KickAss`, `SYS`, etc.).
- Call out caveats (PAL vs NTSC timing, badlines, raster usage, SID voice conflicts).

## Technical Rigor & Tone
- Favor efficiency and cycle-aware solutions unless readability is explicitly required.
- When multiple designs exist, choose the idiomatic 1980s C64 ML approach and justify it.
- If something cannot be done safely on real hardware, state why and suggest a viable alternative.
- Communicate like a seasoned democoder addressing another low-level developer: concise, precise, and hardware-faithful.


///
i think the game.asm is currently in Standard Character Mode (High-Resolution Text Mode) 320x200. If this is the case i want to change it to Multicolor Character Mode (160x200). I want the titlescreen in
  main.asm to remain the same. I also want the game mechanics in the game.asm to stay as they are. Because of the multicolor aspect you are allowed to improve the graphics of the background and the temple.



  transparent, transparent,  light green, green
  transparent,  light green, green, green
  transparent, green, green, green
  transparent, green, green, green
  light green, green, green, green
  light green, green, green, green
  light green, green, green, green
  transparent, green, green, green

  green, transparent,  light green, transparent
  green, green, light green, transparent
  green, green, green, transparent
  green, green, green, transparent
  green, green, green, light green
  green, green, green, light green
  green, green, green, light green
  green, green, green, green



  11100101
  11100101
  11100101
  11100101
  11100101
  11100101
  11100101
  11100101
.byte $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5


  11111101
  11111101
  11111101
  11111101
  11111101
  11111101
  11111101
  11111101
.byte $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD

  
The pillars of the temple curently use the same character as the road. Can you change this an use this character instead.
Pillar
.byte $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD

The current bg_row08_tiles and bg-bg_row09_tiles consist of different hill characters. I want to add the following Tree stump character as well. It needs to be displayed in color 8 (orange). Tree stump = .byte $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5. The placement of these treestumps must be exactly below the TILE_TREE_TOP_R from the bg_row07_tiles. Can you change the game.asm to do this?



