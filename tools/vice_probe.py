#!/usr/bin/env python3
"""
vice_probe.py  —  C64 VICE Binary Monitor probe for AI coding agents

VICE binary monitor protocol v2 wire format (confirmed by packet capture against VICE 3.9):
  Request:   STX(1) API(1) body_len(4LE) req_id(4LE) cmd_type(1) body(body_len bytes)
  Response:  STX(1) API(1) body_len(4LE) resp_type(1) err_code(1) req_id(4LE) body(body_len-6 bytes)

Notes:
- body_len in the response counts: resp_type(1) + err_code(1) + req_id(4) + actual_body
- Unsolicited/spontaneous responses (e.g. STOPPED, register updates) use req_id=0xffffffff

Usage:
    python tools/vice_probe.py --vice path/to/x64sc.exe --prg bin/main.prg \
        [--break 0x4000] [--wait 25] [--run 2] \
        [--dump 0x0000-0x00FF,0xD000-0xD02E] [--port 6502]

Outputs JSON to stdout.
"""

import argparse
import json
import os
import socket
import struct
import subprocess
import time

# ── Constants ────────────────────────────────────────────────────────────────
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

def next_rid() -> int:
    global _req_id
    _req_id += 1
    return _req_id

def build_command(cmd_type: int, body: bytes):
    """Build a VICE binary monitor request frame. Returns (frame_bytes, request_id)."""
    rid = next_rid()
    frame  = struct.pack('<BB', STX, API_VERSION)
    frame += struct.pack('<I', len(body))
    frame += struct.pack('<I', rid)
    frame += bytes([cmd_type])
    frame += body
    return frame, rid

def recv_all(sock: socket.socket, n: int, timeout: float = 5.0) -> bytes:
    sock.settimeout(timeout)
    buf = b''
    while len(buf) < n:
        chunk = sock.recv(n - len(buf))
        if not chunk:
            raise ConnectionError('Socket closed unexpectedly')
        buf += chunk
    return buf

def recv_response(sock: socket.socket, timeout: float = 5.0):
    """
    Read one response packet.

    Wire layout (verified by packet capture against VICE 3.9):
      STX(1) API(1) body_len(4LE) resp_type(1) err_code(1) req_id(4LE) body(body_len bytes)

    body_len = exact number of payload bytes AFTER the fixed 12-byte header.
    """
    try:
        hdr = recv_all(sock, 12, timeout)
        body_len  = struct.unpack_from('<I', hdr, 2)[0]
        resp_type = hdr[6]
        err_code  = hdr[7]
        req_id    = struct.unpack_from('<I', hdr, 8)[0]
        # body_len = bytes after the 12-byte header — no subtraction needed
        body = recv_all(sock, body_len, timeout) if body_len > 0 else b''
        return {'type': resp_type, 'error': err_code, 'req_id': req_id, 'body': body}
    except socket.timeout:
        return None

def recv_by_type(sock: socket.socket, want_type: int,
                 timeout: float = 5.0, max_msgs: int = 100):
    """Read messages until one with the desired response type arrives."""
    deadline = time.time() + timeout
    for _ in range(max_msgs):
        remaining_t = max(0.1, deadline - time.time())
        r = recv_response(sock, timeout=remaining_t)
        if r is None:
            break
        if r['type'] == want_type:
            return r
    return None

def recv_by_rid(sock: socket.socket, rid: int,
                timeout: float = 5.0, max_msgs: int = 100):
    """Read messages until one with the matching request_id arrives."""
    deadline = time.time() + timeout
    for _ in range(max_msgs):
        remaining_t = max(0.1, deadline - time.time())
        r = recv_response(sock, timeout=remaining_t)
        if r is None:
            break
        if r['req_id'] == rid:
            return r
    return None

def flush_pending(sock: socket.socket, count: int = 500, timeout: float = 0.4):
    """Drain buffered responses. Uses a high count to clear a full TCP buffer."""
    for _ in range(count):
        if recv_response(sock, timeout=timeout) is None:
            break

def cmd_memory_get(sock, start: int, end: int, memspace: int = 0) -> list:
    """
    CMD_MEMORY_GET request body: side_effects(1B) start(2B LE) end(2B LE) memspace(1B) bank(2B LE)
    Response body: count(2B LE) + bytes
    VICE responds with a matching req_id.

    Use memspace=0 (CPU view) for all regions — this is correct for reading hardware
    registers at $D000-$DFFF on the C64 (I/O mapped in the default memory layout).
    """
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

def cmd_registers_get(sock, memspace: int = 0) -> dict:
    """
    CMD_REGISTERS_GET request body: memspace(1B)
    Response body: count(2B LE) + per-reg entries:
      item_size(1B) reg_id(1B) reg_val(2B LE)
      item_size = 3 (bytes after item_size field: reg_id + reg_val)
      advance by 1 + item_size bytes per entry
    VICE responds with the matching req_id.
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

def cmd_set_checkpoint(sock, addr: int) -> int:
    """
    CMD_CHECKPOINT_SET body: start(2LE) end(2LE) stop_when_hit(1) enabled(1) cpu_op(1) temporary(1)
    cpu_op 4 = exec/fetch
    """
    body = struct.pack('<HHBBBB', addr, addr, 1, 1, 4, 0)
    frame, rid = build_command(CMD_CHECKPOINT_SET, body)
    sock.sendall(frame)
    resp = recv_by_rid(sock, rid, timeout=3.0)
    if resp and resp['error'] == 0 and len(resp['body']) >= 4:
        return struct.unpack_from('<I', resp['body'], 0)[0]
    return -1

def parse_ranges(spec: str) -> list:
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

def wait_for_port(host: str, port: int, deadline: float, proc) -> bool:
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
    ap = argparse.ArgumentParser(description='VICE Binary Monitor probe for AI agents')
    ap.add_argument('--vice',  required=True,  help='Path to x64sc.exe')
    ap.add_argument('--prg',   required=True,  help='Path to .prg file to autostart')
    ap.add_argument('--port',  type=int, default=6502)
    ap.add_argument('--break', dest='bp', default=None,
                    help='Hex address to break at (e.g. 0x4000)')
    ap.add_argument('--wait',  type=float, default=25.0,
                    help='Max seconds to wait for VICE binary monitor port to open')
    ap.add_argument('--run',   type=float, default=2.0,
                    help='Extra seconds to let the program run after connect (no-breakpoint mode)')
    ap.add_argument('--dump',  default='0x0000-0x00FF',
                    help='Memory ranges to dump (comma-separated)')
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
    ]

    proc = None
    sock = None
    try:
        proc = subprocess.Popen(
            vice_args,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            # NOTE: no CREATE_NO_WINDOW — GTK3 VICE needs a visible window
        )

        if not wait_for_port('127.0.0.1', args.port, time.time() + args.wait, proc):
            rc = proc.poll()
            raise RuntimeError(
                f'VICE binary monitor port {args.port} did not open within {args.wait}s '
                f'(exit code: {rc})'
            )

        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect(('127.0.0.1', args.port))

        if args.bp:
            bp_addr = int(args.bp, 0)
            flush_pending(sock)
            cmd_set_checkpoint(sock, bp_addr)
            # Wait for STOPPED notification
            deadline = time.time() + 15.0
            while time.time() < deadline:
                resp = recv_response(sock, timeout=1.0)
                if resp and resp['type'] == RESP_STOPPED:
                    result['breakpoint_hit'] = f'{bp_addr:04X}'
                    break
        else:
            # Let the program run, then sample
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
