Launch VICE and break at the Level 1 game entry point ($6000) to inspect state after game init.

```bash
python3 tools/vice_probe.py \
  --vice /usr/bin/x64sc \
  --prg  /home/pabes/Projects/c64stuff/bin/main.prg \
  --break 0x6000 \
  --wait 25 \
  --dump "0x0000-0x00FF,0x07F8-0x07FF,0xD000-0xD02E,0xD400-0xD41C"
```

Interpret the JSON:
- `breakpoint_hit: null` means code never reached $6000 — crash or wrong flow
- Check ZP variables ($F0–$FE) used by the background renderer
- Check sprite pointers ($07F8–$07FF)
- Check VIC-II sprite registers ($D000–$D017)
- Report any anomalies in VIC-II or SID state
