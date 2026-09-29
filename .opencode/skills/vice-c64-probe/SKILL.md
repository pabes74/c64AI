---
name: vice-c64-probe
description: Launch the VICE C64 emulator (x64sc / x64sc.exe), connect to its Binary Monitor Protocol over TCP, run assembled .prg files, inspect memory/registers/VIC-II state, and feed structured results back to the agent for iterative C64 assembler development. Use this skill whenever the user wants to test, debug, or validate Commodore 64 assembly code behaviour at runtime — including memory layout verification, zero-page usage, sprite registers, IRQ handlers, raster effects, or any runtime state that cannot be inferred from a static build.
---

This skill enables an AI coding agent to close the **build → run → observe → fix** loop for C64 assembler projects. After KickAss.jar produces a `.prg`, the agent can launch VICE, query live emulator state over its Binary Monitor Protocol, and receive structured JSON it can reason about — without any human in the loop.

---

## Project-specific paths (verified working)

### Linux (this machine — Ubuntu/Debian, VICE 3.7.1)

| Resource | Path |
|---|---|
| KickAss.jar | `/home/pabes/Projects/kickassembler/KickAss.jar` |
| x64sc | `/usr/bin/x64sc` |
| probe script | `tools/vice_probe.py` (repo root) |
| built .prg | `bin/main.prg` |

**Standard invocation (Linux):**
```bash
python3 tools/vice_probe.py \
  --vice /usr/bin/x64sc \
  --prg  /home/pabes/Projects/c64stuff/bin/main.prg \
  --wait 25 --run 3 \
  --dump "0x0000-0x00FF,0x07F8-0x07FF,0xD000-0xD02E,0xD400-0xD41C"
```

**Build command (Linux):**
```bash
java -jar /home/pabes/Projects/kickassembler/KickAss.jar \
  -odir ./bin -log buildlog.txt -showmem -debugdump -vicesymbols main.asm
```

### Windows (original machine)

| Resource | Path |
|---|---|
| KickAss.jar | `C:\Users\PatrickBes\Projects\c64\kickassembler\KickAss.jar` |
| x64sc.exe (GTK3) | `C:\Users\PatrickBes\Projects\c64\GTK3VICE-3.9-win64\bin\x64sc.exe` |
| x64sc.exe (SDL2) | `C:\Users\PatrickBes\Projects\c64\SDL2VICE-3.10-win64\x64sc.exe` |
| probe script | `tools/vice_probe.py` (repo root) |
| built .prg | `bin/main.prg` |

**Standard invocation (Windows):**
```
python tools/vice_probe.py \
  --vice "C:\Users\PatrickBes\Projects\c64\GTK3VICE-3.9-win64\bin\x64sc.exe" \
  --prg  "C:\Users\PatrickBes\Projects\c64\c64stuff\bin\main.prg" \
  --wait 25 --run 3 \
  --dump "0x0000-0x00FF,0x07F8-0x07FF,0xD000-0xD02E,0xD400-0xD41C"
```

Use **absolute paths** for both `--vice` and `--prg` — relative paths can fail depending on the working directory.

---

## Prerequisites

1. **VICE installed** — Linux: `/usr/bin/x64sc` (VICE 3.7.1). Windows: GTK3VICE 3.9 at path above.
2. **Python 3** available — Linux: `python3`. Windows: `python`.
3. **A built `.prg`** — run KickAss.jar first (see AGENTS.md).
4. **Port 6502 free** — binary monitor binds here. `BinaryMonitorServer=1` is already saved in `vice.ini`, so the flag is redundant but harmless to pass.
5. **Linux only — display environment**: `x64sc` requires a running display server. The `DISPLAY` or `WAYLAND_DISPLAY` environment variable must be set. When the agent runs inside a desktop session (e.g., GNOME/KDE), this is inherited automatically. If the agent runs headlessly (e.g., SSH without X forwarding), launch VICE with a virtual framebuffer: `Xvfb :99 -screen 0 1024x768x24 &` and set `DISPLAY=:99` before invoking the probe script.

---

## VICE launch gotchas (learned the hard way)

### Linux-specific

- **Display must be available** — VICE GTK3 will exit immediately if `DISPLAY`/`WAYLAND_DISPLAY` is not set. Always verify with `echo $DISPLAY` before probing. If missing, start `Xvfb` as described above.
- **Sound will fail silently in headless setups** — this is harmless; VICE continues to run without audio. Do not pass `-sounddev dummy` (not a valid flag). Omit all sound flags.
- **Do NOT pass `-sound off`** — VICE interprets `off` as a filename to autostart and crashes. Same bug as Windows.
- **`python3` not `python`** — on this machine Python 3 is invoked as `python3`.
- **Use absolute paths** for `--vice` and `--autostart` — relative paths can fail.
- **Poll for the port** — GTK3 VICE on Linux takes 3–15 s to fully initialise. The probe script polls `127.0.0.1:6502` every 400 ms up to `--wait` seconds; 25 s is a safe default.
- **VICE 3.7.1 vs 3.9** — the binary monitor wire protocol is identical between 3.7 and 3.9; the probe script works unchanged.

### Windows-specific

- **Do NOT use `CREATE_NO_WINDOW`** when spawning on Windows. GTK3 VICE requires a visible window/session context to initialise its render thread. With `CREATE_NO_WINDOW` it exits immediately.
- **Do NOT pass `-sound off`** — same crash as Linux (see above).
- **Do NOT pass `-SoundDeviceName dummy`** — not a valid flag in VICE 3.9.
- **Use `+confirmonexit` cautiously** — may not be valid in all builds; safest to omit.
- **Use absolute paths** for `--autostart` — relative paths sometimes fail.

---

## VICE Binary Monitor Protocol — exact wire format (VICE 3.9)

This was reverse-engineered by packet capture. The VICE documentation and online guides contain errors.

### Request frame
```
STX(1=0x02)  API(1=0x02)  body_len(4LE)  req_id(4LE)  cmd_type(1)  body(body_len bytes)
```
`body_len` = exact number of bytes in `body` (does NOT include `cmd_type`).

### Response frame
```
STX(1=0x02)  API(1=0x02)  body_len(4LE)  resp_type(1)  err_code(1)  req_id(4LE)  body(body_len bytes)
```
`body_len` = exact number of bytes in `body` (does NOT include `resp_type`, `err_code`, or `req_id`).
**Important:** subtract nothing from `body_len` — just read exactly that many bytes after the 12-byte header.

### Unsolicited responses
VICE pushes spontaneous register-info (`0x31`) and stopped (`0x62`) packets at any time, using `req_id=0xFFFFFFFF`. Always match responses by `req_id`, not by position. Use a loop that reads and discards non-matching packets.

### Register entry format (RESP_REGISTER_INFO = 0x31)
Response body: `count(2B LE)` then per-register:
```
item_size(1B=3)  reg_id(1B)  reg_val(2B LE)
```
Advance by `1 + item_size` = 4 bytes per entry.
**reg_id is 1 byte** (not 2 as some docs claim).

Register IDs: `0=PC  1=A  2=X  3=Y  4=SP  5=flags`

### Memory get body (CMD_MEMORY_GET = 0x01)
Request body: `side_effects(1B=0)  start(2B LE)  end(2B LE)  memspace(1B=0)  bank_id(2B LE=0)`
Response body: `count(2B LE)  bytes[count]`

**memspace=0** (CPU view) is correct for reading hardware registers at `$D000–$DFFF` on the C64 in default memory layout. memspace=1 reads ROM/character data in that range — do not use it for hardware registers.

---

## The probe script (`tools/vice_probe.py`)

The working script is already in the repo at `tools/vice_probe.py`. Do **not** rewrite it from scratch — just invoke it. The version in the repo is the verified-correct implementation.

If it is missing or corrupted, the canonical implementation is reproduced below.

```python
#!/usr/bin/env python3
"""
vice_probe.py  —  C64 VICE Binary Monitor probe for AI coding agents

VICE binary monitor protocol v2 wire format (confirmed by packet capture against VICE 3.9):
  Request:   STX(1) API(1) body_len(4LE) req_id(4LE) cmd_type(1) body(body_len bytes)
  Response:  STX(1) API(1) body_len(4LE) resp_type(1) err_code(1) req_id(4LE) body(body_len bytes)

Notes:
- body_len in response = exact payload bytes after the 12-byte header (no subtraction)
- Unsolicited responses use req_id=0xffffffff; match by req_id, not by position
- Register entries: item_size(1B=3) reg_id(1B) reg_val(2B LE) — reg_id is 1 byte
- memspace=0 is correct for hardware registers ($D000-$DFFF) in default C64 layout

Usage:
    python tools/vice_probe.py --vice path/to/x64sc.exe --prg bin/main.prg \
        [--break 0x4000] [--wait 25] [--run 3] \
        [--dump 0x0000-0x00FF,0xD000-0xD02E] [--port 6502]
"""

import argparse
import json
import os
import socket
import struct
import subprocess
import time

STX         = 0x02
API_VERSION = 0x02

CMD_MEMORY_GET     = 0x01
CMD_CHECKPOINT_SET = 0x12
CMD_REGISTERS_GET  = 0x31
CMD_QUIT           = 0xBB

RESP_MEMORY_GET      = 0x01
RESP_CHECKPOINT_INFO = 0x11
RESP_REGISTER_INFO   = 0x31
RESP_STOPPED         = 0x62
RESP_RESUMED         = 0x63

REG_PC    = 0
REG_A     = 1
REG_X     = 2
REG_Y     = 3
REG_SP    = 4
REG_FLAGS = 5

_req_id = 0

def next_rid():
    global _req_id
    _req_id += 1
    return _req_id

def build_command(cmd_type, body):
    rid = next_rid()
    frame  = struct.pack('<BB', STX, API_VERSION)
    frame += struct.pack('<I', len(body))
    frame += struct.pack('<I', rid)
    frame += bytes([cmd_type])
    frame += body
    return frame, rid

def recv_all(sock, n, timeout=5.0):
    sock.settimeout(timeout)
    buf = b''
    while len(buf) < n:
        chunk = sock.recv(n - len(buf))
        if not chunk:
            raise ConnectionError('Socket closed unexpectedly')
        buf += chunk
    return buf

def recv_response(sock, timeout=5.0):
    """
    Wire: STX(1) API(1) body_len(4LE) resp_type(1) err_code(1) req_id(4LE) body(body_len bytes)
    body_len = exact payload bytes after 12-byte header.
    """
    try:
        hdr = recv_all(sock, 12, timeout)
        body_len  = struct.unpack_from('<I', hdr, 2)[0]
        resp_type = hdr[6]
        err_code  = hdr[7]
        req_id    = struct.unpack_from('<I', hdr, 8)[0]
        body = recv_all(sock, body_len, timeout) if body_len > 0 else b''
        return {'type': resp_type, 'error': err_code, 'req_id': req_id, 'body': body}
    except socket.timeout:
        return None

def recv_by_rid(sock, rid, timeout=8.0, max_msgs=100):
    """Read messages, discarding non-matching req_ids, until match or timeout."""
    deadline = time.time() + timeout
    for _ in range(max_msgs):
        remaining_t = max(0.1, deadline - time.time())
        r = recv_response(sock, timeout=remaining_t)
        if r is None:
            break
        if r['req_id'] == rid:
            return r
    return None

def flush_pending(sock, count=500, timeout=0.4):
    """Drain buffered spontaneous responses."""
    for _ in range(count):
        if recv_response(sock, timeout=timeout) is None:
            break

def cmd_memory_get(sock, start, end, memspace=0):
    body = struct.pack('<BHHBH', 0, start, end, memspace, 0)
    frame, rid = build_command(CMD_MEMORY_GET, body)
    sock.sendall(frame)
    resp = recv_by_rid(sock, rid, timeout=8.0)
    if resp is None or resp['type'] != RESP_MEMORY_GET or resp['error'] != 0:
        return []
    if len(resp['body']) < 2:
        return []
    count = struct.unpack_from('<H', resp['body'], 0)[0]
    return list(resp['body'][2:2 + count])

def cmd_registers_get(sock, memspace=0):
    """
    Register entry format: item_size(1B=3) reg_id(1B) reg_val(2B LE)
    reg_id is 1 byte (NOT 2). Advance by 1+item_size per entry.
    """
    body = struct.pack('<B', memspace)
    frame, rid = build_command(CMD_REGISTERS_GET, body)
    sock.sendall(frame)
    resp = recv_by_rid(sock, rid, timeout=8.0)
    regs = {}
    if resp is None or resp['error'] != 0 or len(resp['body']) < 2:
        return regs
    count = struct.unpack_from('<H', resp['body'], 0)[0]
    offset = 2
    names = {REG_PC: 'pc', REG_A: 'a', REG_X: 'x',
             REG_Y: 'y', REG_SP: 'sp', REG_FLAGS: 'flags'}
    for _ in range(count):
        if offset + 4 > len(resp['body']):
            break
        item_size = resp['body'][offset]
        reg_id    = resp['body'][offset + 1]
        reg_val   = struct.unpack_from('<H', resp['body'], offset + 2)[0]
        if reg_id in names:
            name = names[reg_id]
            regs[name] = f'{reg_val:04X}' if reg_id == REG_PC else f'{reg_val:02X}'
        offset += 1 + item_size
    return regs

def cmd_set_checkpoint(sock, addr):
    body = struct.pack('<HHBBBB', addr, addr, 1, 1, 4, 0)
    frame, rid = build_command(CMD_CHECKPOINT_SET, body)
    sock.sendall(frame)
    resp = recv_by_rid(sock, rid, timeout=3.0)
    if resp and resp['error'] == 0 and len(resp['body']) >= 4:
        return struct.unpack_from('<I', resp['body'], 0)[0]
    return -1

def parse_ranges(spec):
    ranges = []
    for part in spec.split(','):
        part = part.strip()
        if not part:
            continue
        if '-' in part:
            lo_s, hi_s = part.split('-', 1)
            ranges.append((int(lo_s, 0), int(hi_s, 0)))
        else:
            addr = int(part, 0)
            ranges.append((addr, addr))
    return ranges

def wait_for_port(host, port, deadline, proc):
    while time.time() < deadline:
        if proc.poll() is not None:
            return False
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(0.5)
            s.connect((host, port))
            s.close()
            return True
        except (ConnectionRefusedError, OSError):
            pass
        finally:
            try:
                s.close()
            except Exception:
                pass
        time.sleep(0.4)
    return False

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--vice',  required=True)
    ap.add_argument('--prg',   required=True)
    ap.add_argument('--port',  type=int, default=6502)
    ap.add_argument('--break', dest='bp', default=None)
    ap.add_argument('--wait',  type=float, default=25.0)
    ap.add_argument('--run',   type=float, default=2.0)
    ap.add_argument('--dump',  default='0x0000-0x00FF')
    args = ap.parse_args()

    result = {'ok': False, 'pc': None, 'a': None, 'x': None, 'y': None,
              'sp': None, 'flags': None, 'breakpoint_hit': None,
              'memory': {}, 'error': None}

    vice_args = [
        args.vice,
        '-binarymonitor',
        '-binarymonitoraddress', f'127.0.0.1:{args.port}',
        '-autostartprgmode', '1',
        '-autostart', args.prg,
        # NOTE: no -sound off, no CREATE_NO_WINDOW — GTK3 VICE needs visible window
    ]

    proc = None
    sock = None
    try:
        proc = subprocess.Popen(
            vice_args,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

        if not wait_for_port('127.0.0.1', args.port, time.time() + args.wait, proc):
            rc = proc.poll()
            raise RuntimeError(f'VICE monitor port {args.port} not open within {args.wait}s (exit={rc})')

        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect(('127.0.0.1', args.port))

        if args.bp:
            bp_addr = int(args.bp, 0)
            flush_pending(sock)
            cmd_set_checkpoint(sock, bp_addr)
            deadline = time.time() + 15.0
            while time.time() < deadline:
                resp = recv_response(sock, timeout=1.0)
                if resp and resp['type'] == RESP_STOPPED:
                    result['breakpoint_hit'] = f'{bp_addr:04X}'
                    break
        else:
            time.sleep(args.run)
            flush_pending(sock)

        regs = cmd_registers_get(sock)
        result.update(regs)

        for lo, hi in parse_ranges(args.dump):
            data = cmd_memory_get(sock, lo, hi)
            result['memory'][f'{lo:04X}'] = [f'{b:02X}' for b in data]

        result['ok'] = True

    except Exception as exc:
        result['error'] = str(exc)
    finally:
        if sock:
            try:
                frame, _ = build_command(CMD_QUIT, b'')
                sock.sendall(frame)
            except Exception:
                pass
            try:
                sock.close()
            except Exception:
                pass
        if proc and proc.poll() is None:
            try:
                proc.terminate()
                proc.wait(timeout=4)
            except Exception:
                proc.kill()

    print(json.dumps(result, indent=2))

if __name__ == '__main__':
    main()
```

---

## Invocation examples

### Free-running sample (no breakpoint) — Linux
```bash
python3 tools/vice_probe.py \
  --vice /usr/bin/x64sc \
  --prg  /home/pabes/Projects/c64stuff/bin/main.prg \
  --wait 25 --run 3 \
  --dump "0x0000-0x00FF,0x07F8-0x07FF,0xD000-0xD02E,0xD400-0xD41C"
```

### Break at game entry point — Linux
```bash
python3 tools/vice_probe.py \
  --vice /usr/bin/x64sc \
  --prg  /home/pabes/Projects/c64stuff/bin/main.prg \
  --break 0x6000 \
  --wait 25 \
  --dump "0x0000-0x00FF,0xD000-0xD02E,0xD400-0xD41C"
```

### Headless Linux (no display session)
```bash
Xvfb :99 -screen 0 1024x768x24 &
DISPLAY=:99 python3 tools/vice_probe.py \
  --vice /usr/bin/x64sc \
  --prg  /home/pabes/Projects/c64stuff/bin/main.prg \
  --wait 30 --run 3 \
  --dump "0x0000-0x00FF,0xD000-0xD02E"
```

### Free-running sample (no breakpoint) — Windows
```bash
python tools/vice_probe.py \
  --vice "C:\Users\PatrickBes\Projects\c64\GTK3VICE-3.9-win64\bin\x64sc.exe" \
  --prg  "C:\Users\PatrickBes\Projects\c64\c64stuff\bin\main.prg" \
  --wait 25 --run 3 \
  --dump "0x0000-0x00FF,0x07F8-0x07FF,0xD000-0xD02E,0xD400-0xD41C"
```

### Break at game entry point — Windows
```bash
python tools/vice_probe.py \
  --vice "C:\Users\PatrickBes\Projects\c64\GTK3VICE-3.9-win64\bin\x64sc.exe" \
  --prg  "C:\Users\PatrickBes\Projects\c64\c64stuff\bin\main.prg" \
  --break 0x6000 \
  --wait 25 \
  --dump "0x0000-0x00FF,0xD000-0xD02E,0xD400-0xD41C"
```

### Break at intro entry point
```bash
python3 tools/vice_probe.py ... --break 0x4000 ...
```

---

## Typical memory regions

| Range | What it covers |
|---|---|
| `0x0000-0x00FF` | Zero page — your variables |
| `0x0100-0x01FF` | Stack |
| `0x0400-0x07FF` | Screen RAM |
| `0x07F8-0x07FF` | Sprite pointers (value × 64 = sprite data address) |
| `0xD000-0xD02E` | VIC-II registers |
| `0xD400-0xD41C` | SID registers |
| `0xDC00-0xDC0F` | CIA 1 |
| `0xDD00-0xDD0F` | CIA 2 |

---

## Interpreting the JSON output

```json
{
  "ok": true,
  "pc": "6000",
  "a": "00", "x": "00", "y": "00", "sp": "F4",
  "flags": "21",
  "breakpoint_hit": "6000",
  "memory": {
    "0000": ["2F","37","00",...],
    "D000": ["A0","96","00",...]
  },
  "error": null
}
```

**Diagnostics:**

| Symptom | Meaning |
|---|---|
| `"ok": false` + error message | VICE failed to launch or connect |
| `"breakpoint_hit": null` with `--break` set | Code never reached that address — likely crash or wrong entry point |
| `pc` far from expected | Bad reset vector or BASIC stub issue |
| `D015` = `00` | Sprites not enabled |
| `D020`/`D021` = `0E`/`06` | Still at BASIC default colours — init not reached |
| `sp` = `FF` | Stack empty (normal post-reset) |
| `sp` = `00` | Stack overflow |
| Zero page all `00` | Init routine didn't run |

**This project's VIC-II state at runtime (verified):**
- `D000`=`$A0` (sprite 0 X=160), `D001`=`$96` (sprite 0 Y=150)
- `D011`=`$9B` — screen on, raster IRQ active
- `D015`=`$01` — sprite 0 enabled
- `D018`=`$37` — charset pointer (changes mid-frame via raster IRQ)
- `D020`=`$00`, `D021`=`$00` — black border/background (intro)
- Sprite pointer at `$07F8`=`$C0` → sprite data at `$C0×64=$3000` ✓

---

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `"Connection refused"` | VICE not ready | Increase `--wait` (use 25+) |
| VICE exits immediately (Linux) | `DISPLAY` / `WAYLAND_DISPLAY` not set | Set `DISPLAY=:0` or start `Xvfb :99` and use `DISPLAY=:99` |
| VICE exits immediately (Windows) | Invalid flag (`-sound off`, `-SoundDeviceName`, `CREATE_NO_WINDOW`) | Use the probe script as-is |
| Memory reads all empty | Wrong `body_len` parsing | Script in repo is correct — do not modify recv_response |
| Registers all null | `reg_id` parsed as 2 bytes instead of 1 | Script in repo is correct |
| Port check shows nothing | VICE crashed during init | Check stderr; common cause is bad `-autostart` path or missing display |
