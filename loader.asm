// ============================================================
// loader.asm — Loading screen launcher
//
// Imports the pre-built loadscreen.prg binary at $0801.
// The binary has its own BASIC SYS stub and displays a bitmap
// loading screen.
//
// The infinite halt loop at $084A is patched with a JMP to a
// stub placed at $084D — in the zero-filled gap that exists in
// the original loadscreen binary between the code ($084C) and
// the screen RAM ($0C00).  This keeps the PRG load address at
// $0801 so BASIC can find and execute the SYS stub correctly.
//
// The stub must call KERNAL LOAD and then jump to $4000.
// Problem: KERNAL LOAD overwrites $0801-$87FF (main.prg),
// which includes the stub itself.  After LOAD's internal RTS,
// execution would land on overwritten bytes.
//
// Solution — ZP trampoline:
//   1. Write "JMP $4000" (3 bytes) to ZP $FB-$FD BEFORE loading.
//      ($FB-$FD are safe: main.asm only uses them inside the
//       logo draw routine, long after $4000 has been entered.)
//   2. Push a fake return address ($00/$FA) onto the stack so
//      KERNAL LOAD's final RTS lands at ZP $FB.
//   3. JMP (not JSR) into KERNAL LOAD — it does its work, then
//      its RTS pops our fake address → CPU executes $FB which
//      is our pre-written "JMP $4000".
//
// Binary imports:
//   Part 1  $0801–$0849  73 bytes  — BASIC stub + display code
//   [patch  $084A–$084C  3 bytes   — JMP $084D]
//   [stub   $084D–$086C  ~32 bytes — ZP trampoline + KERNAL calls]
//   Part 2  $0C00–$3F41  13122 B   — screen RAM + color + bitmap
//   (gaps between segments are zero-filled by KickAssembler,
//    matching the zeros in the original binary.)
// ============================================================

// KERNAL routines
.const KERNAL_SETNAM = $FFBD
.const KERNAL_SETLFS = $FFBA
.const KERNAL_LOAD   = $FFD5

// ZP trampoline target (in main.asm, logo draw uses $FB-$FD
// only after start: is entered — safe to use as a temp vector)
.const ZP_TRAMPOLINE = $FB

// main.asm entry point
.const MAIN_ENTRY = $4000

// Loading-screen hold: outer count for the busy-wait in loader_stub.
// ~0.33 s per outer iteration at PAL ~1 MHz → 15 ≈ 5 s.
.const HOLD_OUTER = 15

// loadscreen.prg binary offsets (2-byte PRG header already skipped):
//   Part 1 : file offset 2,    73 bytes  → $0801-$0849
//   Part 2 : file offset 1025, 13122 bytes → $0C00-$3F41
//     offset 1025 = ($0C00 - $0801) + 2 header bytes
//     size 13122  = $3F41 - $0C00 + 1

// --- Part 1: BASIC stub + display code (up to but NOT including halt) ---
* = $0801
.import binary "prg/loadscreen.prg", 2, 73

// --- Patch: replace halt loop at $084A with JMP to stub ---
* = $084A
    jmp $084D

// --- Loader stub at $084D (zero-filled gap in original binary) ---
* = $084D

loader_stub:
    // --- Hold the loading graphic (~5 s) before KERNAL LOAD overwrites the
    //     bitmap RAM at $0C00-$3F41. Busy loop: no IRQ/jiffy dependency. ---
    lda #HOLD_OUTER
    sta hold_ctr
hold_loop_o:
    ldx #$00
hold_loop_x:
    ldy #$00
hold_loop_y:
    dey
    bne hold_loop_y             // 256 * 5 cyc  ≈ 1280 cyc
    dex
    bne hold_loop_x             // 256 iters     ≈ 0.33 s
    dec hold_ctr
    bne hold_loop_o             // HOLD_OUTER iters ≈ 5 s

    // -- Set up ZP trampoline: write JMP $4000 to $FB-$FD --
    lda #$4C                    // JMP opcode
    sta ZP_TRAMPOLINE + 0
    lda #<MAIN_ENTRY            // lo byte of $4000
    sta ZP_TRAMPOLINE + 1
    lda #>MAIN_ENTRY            // hi byte of $4000
    sta ZP_TRAMPOLINE + 2

    // -- SETNAM: filename "MAIN" --
    lda #[loader_name_end - loader_name]
    ldx #<loader_name
    ldy #>loader_name
    jsr KERNAL_SETNAM

    // -- SETLFS: logical 1, device 8, secondary 0 --
    //    secondary 1 = load to address from PRG header ($0801)
    lda #1
    ldx #8
    ldy #1
    jsr KERNAL_SETLFS

    // -- Push fake return address so KERNAL LOAD's RTS → $FB --
    //    RTS pops lo then hi and adds 1.
    //    To land at $FB: push hi=$00 first, then lo=$FA.
    lda #>( ZP_TRAMPOLINE - 1 ) // $00  (hi byte of $00FA)
    pha
    lda #<( ZP_TRAMPOLINE - 1 ) // $FA  (lo byte of $00FA)
    pha

    // -- A=0 (load mode), then JMP — KERNAL LOAD will RTS → $FB → JMP $4000 --
    lda #0
    jmp KERNAL_LOAD

loader_name:
    .text "MAIN"
loader_name_end:

// Counter for the loading-graphic hold busy-loop (in the zero-filled gap).
hold_ctr:
    .byte $00

// --- Part 2: screen RAM + color data + bitmap ---
//     (zero gap from $086C to $0BFF matches original binary zeros)
* = $0C00
.import binary "prg/loadscreen.prg", 1025, 13122
