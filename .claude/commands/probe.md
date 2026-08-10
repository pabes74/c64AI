Launch VICE and probe the live C64 emulator state using tools/vice_probe.py.

Run the following command (requires a display session; if headless, prepend `DISPLAY=:99` and ensure Xvfb is running):

```bash
python3 tools/vice_probe.py \
  --vice /usr/bin/x64sc \
  --prg  /home/pabes/Projects/c64stuff/bin/main.prg \
  --wait 25 --run 3 \
  --dump "0x0000-0x00FF,0x07F8-0x07FF,0xD000-0xD02E,0xD400-0xD41C"
```

Then interpret the JSON output:
- `ok: false` → report the error
- Check `D015` (sprite enable), `D018` (charset pointer), `D020`/`D021` (border/bg color)
- Check `$07F8`–`$07FF` sprite pointers (value × 64 = sprite bitmap address)
- Check zero page (`0000`–`00FF`) for variable state
- Check SID registers (`D400`–`D41C`) for audio state
- Report PC and CPU registers

Key expected values at intro screen:
- `D015` = `01` (sprite 0 enabled)
- `D018` = `37` (custom charset active)
- `D020`/`D021` = `00`/`00` (black)
- `$07F8` = `C0` → sprite data at `$3000`
