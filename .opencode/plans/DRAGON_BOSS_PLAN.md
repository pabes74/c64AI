# Dragon Boss "Lung" — Level 2 Implementation Plan

## Overview

Replace Kuro as the arena boss when `current_level == 2`. The dragon **Lung** (Chinese
for dragon) uses sprite slot 5 (same as Kuro), walks across the screen with a 3-frame
walk animation, and breathes 3 fireballs at the player at irregular intervals within
each attack cycle. Fireballs use sprite slots 6 and 7 (always free in the level 1 arena).
The player can jump over fireballs and kick Lung to deplete its 5 HP. The HUD boss name
changes from "KURO" to "LUNG". Both bosses share `boss_hp` and sprite slot 5; only new
constants, sprite data, and separate FSM branches are added.

---

## Design Decisions

| Decision | Choice |
|---|---|
| Boss location | Arena (game.asm), same trigger as Kuro (`TEMPLE_CENTER_SCROLLS`) |
| Level condition | `current_level == 2` selects Lung; level 1 keeps Kuro unchanged |
| Sprite slot | 5 (same as Kuro) |
| Fireball sprites | 6 and 7 (always free in the arena) |
| 3rd fireball behaviour | Silent skip if both slots are occupied |
| Fireball Y | Tracks player Y at fire time — player must jump to dodge |
| HUD name | "LUNG" in green (`$05`), 4 chars at column 30 |
| Shared variables | `boss_hp`, `kick_hit_done`, `door_open`, `draw_boss_life` |
| Files changed | `gfx.asm`, `game.asm` only — no changes to `temple_interior.asm` etc. |

---

## Sprite Data Plan (gfx.asm)

### Lung body sprites — sprite slot 5, `$07fd`

Appended after existing `kuro_ld` at `$36C0`:

| Label | Address | Pointer val | Description |
|---|---|---|---|
| `lung_r0` | `$3700` | `$DC` | Right walk frame 0 (idle stand) |
| `lung_r1` | `$3740` | `$DD` | Right walk frame 1 (left foot forward) |
| `lung_r2` | `$3780` | `$DE` | Right walk frame 2 (right foot forward) |
| `lung_l0` | `$37C0` | `$DF` | Left walk frame 0 |
| `lung_l1` | `$3800` | `$E0` | Left walk frame 1 |
| `lung_l2` | `$3840` | `$E1` | Left walk frame 2 |
| `lung_ld` | `$3880` | `$E2` | Death frame (collapsed) |

**Visual design:**
- Red body (`$02`), yellow belly (`$07` via `$d025`), green mane/tail (`$05` via `$d026`)
- Multicolor sprite, Y-expanded (like Kuro) — 24×42 px effective
- Low-slung dragon silhouette: body near floor, raised head left or right based on direction
- Walk cycle: legs alternate, head bobs slightly

### Fireball sprites — sprite slots 6 & 7, `$07fe`/`$07ff`

| Label | Address | Pointer val | Description |
|---|---|---|---|
| `lung_fb0` | `$38C0` | `$E3` | Fireball frame A (full flame + trail) |
| `lung_fb1` | `$3900` | `$E4` | Fireball frame B (trail phase) |

**Visual design (from reference):**
- Orange teardrop shape with inner yellow glow core
- Flame trail extends right (fireballs travel left)
- Colors: sprite color = orange (`$07`), `$d025` = yellow (`$07`), `$d026` = dark red (`$02`)
- Single-height sprites (no Y-expand needed)

### N glyph in custom charset (`game_bg_charset` at `$2800`)

Character `$1e` is currently unused. The N glyph sits at byte offset `$1e * 8 = $f0`
within the charset, drawn in the same 4-pixel-wide uppercase hi-res style as K, U, R, O:

```
  %11000110  $c6   ██░░░██░
  %11000110  $c6   ██░░░██░
  %11100110  $e6   ███░░██░
  %11110110  $f6   ████░██░
  %11011110  $de   ██░████░
  %11001110  $ce   ██░░███░
  %11000110  $c6   ██░░░██░
  %00000000  $00   ░░░░░░░░
```

---

## New Constants (game.asm)

```asm
// Lung boss sprite pointers
.const LUNG_R0_PTR  = lung_r0  / 64
.const LUNG_R1_PTR  = lung_r1  / 64
.const LUNG_R2_PTR  = lung_r2  / 64
.const LUNG_L0_PTR  = lung_l0  / 64
.const LUNG_L1_PTR  = lung_l1  / 64
.const LUNG_L2_PTR  = lung_l2  / 64
.const LUNG_LD_PTR  = lung_ld  / 64
.const LUNG_FB0_PTR = lung_fb0 / 64
.const LUNG_FB1_PTR = lung_fb1 / 64

// Lung behaviour
.const LUNG_SPRITE_NUM    = 5
.const LUNG_SPRITE_COLOR  = $02        // red
.const LUNG_FB_COLOR      = $07        // orange (fireball)
.const LUNG_FB_SPRITE_A   = 6
.const LUNG_FB_SPRITE_B   = 7
.const LUNG_START_X       = 80
.const LUNG_START_X_MSB   = 1
.const LUNG_WALK_SPEED    = 1
.const LUNG_BREATH_RANGE  = 120
.const LUNG_KICK_RANGE    = 28

// Fireball
.const LUNG_FB_SPEED      = 3
.const LUNG_FB_ANIM_TICKS = 6
.const LUNG_FB_HIT_DX     = 16
.const LUNG_FB_HIT_DY     = 12
.const LUNG_FB_ENABLE_6   = %01000000
.const LUNG_FB_DISABLE_6  = %10111111
.const LUNG_FB_ENABLE_7   = %10000000
.const LUNG_FB_DISABLE_7  = %01111111

// Lung FSM
.const LUNG_STATE_WALK    = 0
.const LUNG_STATE_BREATH  = 1
.const LUNG_STATE_RECOIL  = 2
.const LUNG_STATE_DEAD    = 3
.const LUNG_BREATH_TICKS  = 80
.const LUNG_RECOIL_TICKS  = 20
.const LUNG_RECOIL_SPEED  = 2

// Fireball launch ticks (count-up from breath start)
.const LUNG_FB1_TICK      = 10
.const LUNG_FB2_TICK      = 30
.const LUNG_FB3_TICK      = 55         // may be silently skipped if both slots busy

// HUD
.const HUD_N_CHAR         = $1e
```

---

## New State Variables (game.asm data section)

Added after `kuro_dir` (line ~2721):

```asm
// Lung boss state
lung_active:        .byte 0
lung_x_lo:          .byte 0
lung_x_hi:          .byte 0
lung_anim_frame:    .byte 0
lung_anim_timer:    .byte 0
lung_walk_timer:    .byte 0
lung_state:         .byte LUNG_STATE_WALK
lung_state_timer:   .byte 0
lung_dir:           .byte 1
lung_hit_cooldown:  .byte 0
lung_breath_tick:   .byte 0            // count-up within breath cycle

// Fireball pool (slots 0 = sprite 6, slot 1 = sprite 7)
lung_fb_state:      .fill 2, 0
lung_fb_x_lo:       .fill 2, 0
lung_fb_x_hi:       .fill 2, 0
lung_fb_y:          .fill 2, 0
lung_fb_anim_timer: .fill 2, 0
lung_fb_frame:      .fill 2, 0

lung_anim_ptrs_left:
    .byte LUNG_L0_PTR, LUNG_L1_PTR, LUNG_L2_PTR
lung_anim_ptrs_right:
    .byte LUNG_R0_PTR, LUNG_R1_PTR, LUNG_R2_PTR
```

---

## Code Changes Summary (game.asm)

### `game_start` reset (~line 187)
- Zero all lung_* and lung_fb_* state variables
- Disable sprites 6 & 7 in `$d015`
- Set `lung_state = LUNG_STATE_WALK`, `lung_dir = 1`

### `game_main_loop` (~line 284)
After `jsr update_kuro` add:
```asm
jsr update_lung
jsr update_lung_fireballs
```

### `show_boss_hud` (~line 1894)
Branch on `current_level == 2`:
- Level 2: write "LUNG" from `lung_hud_text` in green, call `spawn_lung`
- Level 1: existing "KURO" path unchanged, call `spawn_kuro`

### `check_collisions` (~line 1743)
Add before final `rts`:
```asm
jsr check_lung_kick_hit
jsr check_lung_fb_hit
```

---

## New Routines

### `spawn_lung`
- Guard `lung_active != 0` → rts
- Set `lung_active = 1`
- Position sprite 5: X lo=$50 hi=$01, Y = `$d001`−21
- `$d02c = LUNG_SPRITE_COLOR`, enable multicolor+Y-expand for sprite 5
- Write `LUNG_L0_PTR` to `$07fd`
- Set fireball sprite colors `$d02d = $d02e = LUNG_FB_COLOR`, enable multicolor for sprites 6 & 7

### `update_lung`
FSM dispatch. Throttled by jiffy via `lung_walk_timer`.

**WALK:** Compute distance. If < `LUNG_BREATH_RANGE` → enter BREATH state, reset
`lung_state_timer = LUNG_BREATH_TICKS`, `lung_breath_tick = 0`. Else: move toward
player, clamp X 24–344, update sprite 5 position, run 3-frame walk anim.

**BREATH:** Each jiffy: inc `lung_breath_tick`. Check vs `LUNG_FB1_TICK`,
`LUNG_FB2_TICK`, `LUNG_FB3_TICK` — call `fire_lung_fireball` with slot 0, 1, then
whichever free. Dec `lung_state_timer`; at 0 → WALK.

**RECOIL:** Dec `lung_state_timer`; push back `LUNG_RECOIL_SPEED` px/tick; clamp;
at 0 → WALK.

**DEAD:** `rts` immediately.

### `update_lung_fireballs`
Loop slots 0 and 1:
- Skip if inactive
- 16-bit subtract `LUNG_FB_SPEED` from x_lo/x_hi
- If x_hi went negative: deactivate, clear sprite in `$d015`
- Write X lo, X hi-bit (bits 6 & 7 of `$d010`) and Y to VIC registers
- Tick anim timer; on expiry flip fb_frame 0↔1, write `LUNG_FB0_PTR`/`LUNG_FB1_PTR` to `$07fe`/`$07ff`

### `fire_lung_fireball` (slot index in X)
- If `lung_fb_state,x != 0` → rts
- Activate slot; set X = lung_x_lo/hi, Y = `$d001` (player current Y)
- Enable sprite 6 or 7 in `$d015`; write Y; write `LUNG_FB0_PTR` to pointer

### `check_lung_kick_hit`
Guards: `lung_active`, state ≠ DEAD, `pose_mode == POSE_MODE_KICK`, `kick_hit_done == 0`,
distance < `LUNG_KICK_RANGE`. Hit: `kick_hit_done=1`, `sfx_hit`, `dec boss_hp`,
`draw_boss_life`, check for death → `open_temple_door`, else RECOIL.

### `check_lung_fb_hit`
For each slot: active, player ≠ POSE_MODE_HIT, player ≠ POSE_MODE_JUMP (jump = dodge),
X delta < `LUNG_FB_HIT_DX`, Y delta < `LUNG_FB_HIT_DY`. Hit: deactivate fireball,
call `start_hit`.

---

## Fireball Timing Diagram

```
Breath cycle = 80 ticks (~1.6 s at 50 Hz)

Tick  0  BREATH state entered, dragon stops
Tick 10  fire slot 0 → sprite 6 active  (player Y snapshotted)
Tick 30  fire slot 1 → sprite 7 active  (player Y snapshotted)
Tick 55  fire slot 0 or 1 if free       (typically both still on screen → skipped)
Tick 80  return to WALK

Fireball travel: 3 px/frame × 107 frames = 321 px (full screen width)
Slot 0 at tick 55: 45 frames old = 135 px traveled (still on screen)
Slot 1 at tick 55: 25 frames old =  75 px traveled (still on screen)
→ 3rd fireball skips silently. Adds natural variation.
```

---

## Memory Map After Changes

```
$36C0  kuro_ld         (existing)
$3700  lung_r0
$3740  lung_r1
$3780  lung_r2
$37C0  lung_l0
$3800  lung_l1
$3840  lung_l2
$3880  lung_ld
$38C0  lung_fb0
$3900  lung_fb1        ← end $393F

Safe ceiling: $3FFF (intro at $4000).  ✓
```

---

## Files Changed

| File | Nature of change |
|---|---|
| `gfx.asm` | +9 sprite data blocks (576 bytes) + N charset glyph (8 bytes) |
| `game.asm` | +constants, +state vars, +6 new routines, modify 4 existing sites |
| `DRAGON_BOSS_PLAN.md` | This document |
