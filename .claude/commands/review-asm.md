Review the recently modified or specified assembly file(s) for correctness against C64 hardware constraints and project conventions.

Check for:

1. **KickAssembler syntax** — `.const NAME = value`, sprite pointers as `address / 64`, `.import source/binary`
2. **Naming conventions** — SCREAMING_SNAKE_CASE constants, snake_case labels, correct module prefixes (`bg_`, `ti_`, `cv_`, `sfx_`, `kuro_`)
3. **SID voice ownership** — voice 2 written only in `sid/soundfx.asm`; voices 1 & 3 only from `music_play`
4. **IRQ handlers** — proper register save/restore (`pha/txa/pha/tya/pha`), chain to `$ea31`
5. **Screen writes** — wrapped in `sei/cli` with `wait_frame_safe_window`
6. **Hardware registers** — read-modify-write only (`lda → and/ora → sta`)
7. **Sprite coordinates** — clamped at boundaries, no reliance on wrapping
8. **State guards** — boolean flags checked before state mutation, cooldown timers on hit detection
9. **Zero-page conflicts** — `$f0–$fe` owned by game.asm background, `$fb–$fe` shared with main.asm intro (safe overlap)
10. **Comments** — hardware register accesses have trailing `// register: purpose` comments

If $args is specified, review that file. Otherwise review the most recently edited .asm file.
