// ============================================================
// music.asm — "Artificial Fist" intro theme
// Last Ninja-inspired atmospheric SID composition for C64/6581 PAL
//
// Structure:
//   INTRO  (24 steps) — sparse build-up: arp only, then bass, then melody
//   MAIN   (32 steps) — full 3-voice arrangement; loops MAIN_REPEATS times
//   VAR    (32 steps) — chromatic variation: B4 peak, Phrygian tension,
//                       stepwise descent; then loops back to MAIN
//
// Voice 1: Pulse lead melody — vibrato LFO, PWM, upward portamento
// Voice 2: Pulse bass groove — syncopated Am ostinato
// Voice 3: Pulse fast arpeggio — shimmering minor-chord harmony
//
// Called from main.asm:
//   jsr music_init   (once, before IRQ is installed)
//   jsr music_play   (every video frame, from raster IRQ)
//
// NOTE: Voice 2 is used for SFX during gameplay (sid/soundfx.asm).
// There is no conflict: main.asm clears all SID registers before
// starting the game, handing voice 2 cleanly to the SFX engine.
// ============================================================

* = $8000

.const M_TEMPO      = 6    // frames per sequencer step (~8.3 steps/sec PAL 50 Hz)
.const ARP_SPEED    = 2    // frames between arp steps (25 steps/sec)
.const VIB_SPEED    = 2    // vibrato LFO phase advance per frame
.const SLIDE_STEP   = $40  // portamento: freq units per frame (upward only)
.const MAIN_REPEATS = 6    // how many times MAIN loops before switching to VAR

// Section identifiers
.const SEC_INTRO = 0
.const SEC_MAIN  = 1
.const SEC_VAR   = 2

// Pattern lengths (steps) per section per voice
.const LEN_INTRO_V1 = 24
.const LEN_INTRO_V2 = 24
.const LEN_MAIN_V1  = 32
.const LEN_MAIN_V2  = 16
.const LEN_VAR_V1   = 32
.const LEN_VAR_V2   = 16
.const LEN_V3       = 8    // arp-root pattern; same length for all sections

// Special note values (1-based index into freq table; 0 = rest, $fe = hold)
.const _R  = 0             // rest — silence the voice (gate off)
.const _H  = $fe           // hold — sustain current pitch, no retrigger

// ============================================================
// music_init — call once; configures all three SID voices and
// resets every sequencer and modulation state variable.
// ============================================================
music_init:
    // Zero all SID registers ($d400–$d418)
    ldx #$18
    lda #0
mclr:
    sta $d400,x
    dex
    bpl mclr

    // Voice 1 — pulse melody: moderate attack, high sustain
    lda #$00
    sta $d402            // PW lo (PWM sweeps each frame)
    lda #$08
    sta $d403            // PW hi ~50% duty starting point
    lda #$26             // A=2 D=6
    sta $d405
    lda #$a6             // S=A R=6
    sta $d406

    // Voice 2 — pulse bass: punchy, medium sustain
    lda #$00
    sta $d409            // PW lo
    lda #$0c
    sta $d40a            // PW hi ~75% duty (warm bass)
    lda #$04             // A=0 D=4
    sta $d40c
    lda #$82             // S=8 R=2
    sta $d40d

    // Voice 3 — pulse arpeggio: instant attack, sustained pluck
    lda #$00
    sta $d410            // PW lo
    lda #$0a
    sta $d411            // PW hi ~62% duty
    lda #$04             // A=0 D=4
    sta $d413
    lda #$81             // S=8 R=1
    sta $d414

    // SID filter: low-pass on voices 1 and 3, resonance 9
    lda #$00
    sta $d415            // cutoff lo
    lda #$40
    sta $d416            // cutoff hi (LFO sweeps around this)
    lda #$95             // resonance=9, route V1+V3 ($01|$04=$05, res=$90)
    sta $d417
    lda #$1f             // low-pass mode, master volume 15
    sta $d418

    // Initialise section state to INTRO
    lda #SEC_INTRO
    sta m_section
    lda #0
    sta m_rep_count

    // Zero all sequencer and modulation state
    lda #0
    sta m_tick
    sta m_v1pos
    sta m_v2pos
    sta m_v3pos
    sta m_v1note
    sta m_v2note
    sta m_v3root
    sta m_arp_phase
    sta m_arp_timer
    sta m_vib_phase
    sta m_v1base_lo
    sta m_v1base_hi
    sta m_pw
    sta m_filt
    sta m_slide_lo
    sta m_slide_hi
    sta m_slide_tgt_lo
    sta m_slide_tgt_hi
    sta m_slide_active
    sta m_slide_flag
    lda #1
    sta m_fdir

    // Set pattern lengths for INTRO
    jsr set_section_lengths

    // Prime the first notes
    jsr sv1
    jsr sv2
    jsr sv3
    rts

// ============================================================
// music_play — call once per video frame from the raster IRQ.
// Runs all per-frame modulation routines, then advances the
// pattern sequencer every M_TEMPO frames.
// Voice 1 drives section changes; V2 and V3 are synchronised via
// the advance_section "wrap-prime" trick (see advance_section).
// ============================================================
music_play:
    jsr do_pw            // pulse-width modulation on voice 1
    jsr do_slide         // portamento pitch slide (if active)
    jsr do_vib           // vibrato LFO (skipped while sliding)
    jsr do_arp           // fast arpeggio on voice 3
    jsr do_filt          // filter cutoff LFO sweep

    inc m_tick
    lda m_tick
    cmp #M_TEMPO
    bcc mp_done

    lda #0
    sta m_tick

    // Voice 1 — drives section changes
    inc m_v1pos
    lda m_v1pos
    cmp m_v1len
    bcc mp_v1ok
    lda #0
    sta m_v1pos
    jsr advance_section  // may change section; primes V2/V3 wrap-to-0
mp_v1ok:
    jsr sv1

    // Voice 2 — independent loop within section
    inc m_v2pos
    lda m_v2pos
    cmp m_v2len
    bcc mp_v2ok
    lda #0
    sta m_v2pos
mp_v2ok:
    jsr sv2

    // Voice 3 — 8-step arp root loop
    inc m_v3pos
    lda m_v3pos
    cmp #LEN_V3
    bcc mp_v3ok
    lda #0
    sta m_v3pos
mp_v3ok:
    jsr sv3

mp_done:
    rts

// ============================================================
// advance_section — called when V1 pattern wraps.
// Updates m_section and m_rep_count, refreshes pattern lengths,
// and primes V2pos/V3pos to (len-1) so music_play's inc wraps
// them cleanly to 0 on the same sequencer tick.
// ============================================================
advance_section:
    lda m_section
    cmp #SEC_INTRO
    beq as_to_main       // INTRO always transitions to MAIN
    cmp #SEC_MAIN
    beq as_from_main     // MAIN repeats or advances to VAR

    // SEC_VAR → SEC_MAIN (loop indefinitely after first variation)
    lda #SEC_MAIN
    sta m_section
    lda #0
    sta m_rep_count
    jsr set_section_lengths
    jmp as_sync

as_to_main:
    lda #SEC_MAIN
    sta m_section
    lda #0
    sta m_rep_count
    jsr set_section_lengths
    jmp as_sync

as_from_main:
    inc m_rep_count
    lda m_rep_count
    cmp #MAIN_REPEATS
    bcc as_sync          // still repeating MAIN — just re-sync positions
    // Switch to variation
    lda #SEC_VAR
    sta m_section
    lda #0
    sta m_rep_count
    jsr set_section_lengths

as_sync:
    // Set V2 to (m_v2len - 1): music_play's inc will wrap it to 0.
    lda m_v2len
    sec
    sbc #1
    sta m_v2pos
    // Set V3 to (LEN_V3 - 1): same wrap trick.
    lda #(LEN_V3 - 1)
    sta m_v3pos
    rts

// ============================================================
// set_section_lengths — update m_v1len and m_v2len for m_section.
// ============================================================
set_section_lengths:
    lda m_section
    cmp #SEC_INTRO
    beq ssl_intro
    cmp #SEC_VAR
    beq ssl_var
    // SEC_MAIN
    lda #LEN_MAIN_V1
    sta m_v1len
    lda #LEN_MAIN_V2
    sta m_v2len
    rts
ssl_intro:
    lda #LEN_INTRO_V1
    sta m_v1len
    lda #LEN_INTRO_V2
    sta m_v2len
    rts
ssl_var:
    lda #LEN_VAR_V1
    sta m_v1len
    lda #LEN_VAR_V2
    sta m_v2len
    rts

// ============================================================
// sv1 — load melody note for the current section and position.
// Dispatches to the correct per-section pattern, then handles
// hold, rest, normal retrigger, or portamento slide.
// ============================================================
sv1:
    ldx m_v1pos
    lda m_section
    cmp #SEC_VAR
    beq sv1_load_var
    cmp #SEC_MAIN
    beq sv1_load_main
    // SEC_INTRO — no slides during intro
    lda intro_v1,x
    sta m_v1note
    lda #0
    sta m_slide_flag
    jmp sv1_process

sv1_load_main:
    lda main_v1,x
    sta m_v1note
    lda main_v1flags,x
    sta m_slide_flag
    jmp sv1_process

sv1_load_var:
    lda var_v1,x
    sta m_v1note
    lda var_v1flags,x
    sta m_slide_flag

sv1_process:
    lda m_v1note
    cmp #_H
    beq sv1_done         // hold: sustain, nothing to do
    cmp #_R
    beq sv1_off

    lda m_slide_flag
    bne sv1_portamento

    // Normal retrigger: write freq, reset vibrato, cycle gate
    lda m_v1note
    tax
    dex                  // 1-based → 0-based
    lda freq_lo,x
    sta m_slide_lo       // sync slide state to current pitch
    sta m_v1base_lo      // vibrato oscillates around this base
    sta $d400
    lda freq_hi,x
    sta m_slide_hi
    sta m_v1base_hi
    sta $d401
    lda #0
    sta m_slide_active
    sta m_vib_phase      // restart vibrato from zero on each new note
    lda #$40             // gate off — reset ADSR envelope
    sta $d404
    lda #$41             // pulse + gate on
    sta $d404
    rts

sv1_portamento:
    // Set slide target; do_slide interpolates toward it each frame
    lda m_v1note
    tax
    dex
    lda freq_lo,x
    sta m_slide_tgt_lo
    sta m_v1base_lo      // vibrato will centre on target when slide ends
    lda freq_hi,x
    sta m_slide_tgt_hi
    sta m_v1base_hi
    lda #1
    sta m_slide_active
    rts

sv1_off:
    lda #0
    sta m_slide_active
    lda #$40             // gate off — enter release phase
    sta $d404
sv1_done:
    rts

// ============================================================
// sv2 — load bass note for the current section and position.
// ============================================================
sv2:
    ldx m_v2pos
    lda m_section
    cmp #SEC_INTRO
    beq sv2_load_intro
    cmp #SEC_VAR
    beq sv2_load_var
    lda main_v2,x
    jmp sv2_process

sv2_load_intro:
    lda intro_v2,x
    jmp sv2_process

sv2_load_var:
    lda var_v2,x

sv2_process:
    cmp #_H
    beq sv2_done
    sta m_v2note
    cmp #_R
    beq sv2_off
    tax
    dex
    lda freq_lo,x
    sta $d407
    lda freq_hi,x
    sta $d408
    lda #$40             // gate off — reset ADSR
    sta $d40b
    lda #$41             // pulse + gate on
    sta $d40b
    rts

sv2_off:
    lda #$40             // gate off — enter release
    sta $d40b
sv2_done:
    rts

// ============================================================
// sv3 — load arp root note for the current section.
// Resets arp phase so each chord change starts from the root.
// ============================================================
sv3:
    ldx m_v3pos
    lda m_section
    cmp #SEC_INTRO
    beq sv3_load_intro
    cmp #SEC_VAR
    beq sv3_load_var
    lda main_v3,x
    jmp sv3_set

sv3_load_intro:
    lda intro_v3,x
    jmp sv3_set

sv3_load_var:
    lda var_v3,x

sv3_set:
    sta m_v3root
    lda #0
    sta m_arp_phase      // restart arp from root on each chord change
    rts

// ============================================================
// do_arp — advance Voice 3 arpeggio one step every ARP_SPEED frames.
// Cycles root → minor 3rd (+3) → perfect 5th (+7).
// Retriggers envelope on each step for a plucked-chord shimmer.
// ============================================================
do_arp:
    inc m_arp_timer
    lda m_arp_timer
    cmp #ARP_SPEED
    bcc do_arp_done

    lda #0
    sta m_arp_timer

    lda m_v3root
    beq do_arp_done      // root = 0: voice 3 silent

    ldx m_arp_phase
    clc
    adc arp_offsets,x
    cmp #50              // guard: 49-entry freq table
    bcs do_arp_done

    tax
    dex                  // 1-based → 0-based
    lda freq_lo,x
    sta $d40e
    lda freq_hi,x
    sta $d40f
    lda #$40             // gate off
    sta $d412
    lda #$41             // gate on — envelope retrigger
    sta $d412

    inc m_arp_phase
    lda m_arp_phase
    cmp #3
    bcc do_arp_done
    lda #0
    sta m_arp_phase

do_arp_done:
    rts

// ============================================================
// do_vib — apply vibrato LFO to Voice 1 each frame.
// Adds a non-negative delta from vib_table to the base frequency.
// Skipped during portamento (do_slide owns the freq writes then).
// ============================================================
do_vib:
    lda m_slide_active
    bne do_vib_done      // portamento takes priority

    lda m_v1note
    beq do_vib_done      // silence

    ldx m_vib_phase
    lda m_v1base_lo
    clc
    adc vib_table,x      // add LFO offset; carry propagates into hi
    sta $d400
    lda m_v1base_hi
    adc #0
    sta $d401

    lda m_vib_phase
    clc
    adc #VIB_SPEED
    and #$0f
    sta m_vib_phase

do_vib_done:
    rts

// ============================================================
// do_slide — portamento: advance Voice 1 frequency upward toward
// m_slide_tgt by SLIDE_STEP per frame. Snaps to exact target.
// ============================================================
do_slide:
    lda m_slide_active
    beq do_slide_done

    lda m_slide_lo
    clc
    adc #SLIDE_STEP
    sta m_slide_lo
    lda m_slide_hi
    adc #0
    sta m_slide_hi

    lda m_slide_hi
    cmp m_slide_tgt_hi
    bcc do_slide_write   // hi still below target: keep going
    bne do_slide_snap    // hi above target: overshot

    lda m_slide_lo
    cmp m_slide_tgt_lo
    bcc do_slide_write   // lo still below target: keep going

do_slide_snap:
    lda m_slide_tgt_lo
    sta m_slide_lo
    lda m_slide_tgt_hi
    sta m_slide_hi
    lda #0
    sta m_slide_active

do_slide_write:
    lda m_slide_lo
    sta $d400
    lda m_slide_hi
    sta $d401

do_slide_done:
    rts

// ============================================================
// do_pw — pulse-width modulation on Voice 1.
// PWM counter sweeps 0–255; duty cycle cycles between ~31%–75%.
// ============================================================
do_pw:
    inc m_pw
    lda m_pw
    sta $d402            // PW lo
    lsr
    lsr
    lsr
    lsr
    lsr                  // A = 0-7
    clc
    adc #$05             // PW hi: $05–$0c
    sta $d403
    rts

// ============================================================
// do_filt — triangle-LFO sweep of the SID filter cutoff.
// m_filt sweeps 0–$50; effective cutoff = $20 + m_filt ($20–$70).
// ============================================================
do_filt:
    lda m_fdir
    beq do_filt_down

    inc m_filt
    lda m_filt
    cmp #$50
    bcc do_filt_set
    lda #0
    sta m_fdir
    beq do_filt_set      // A=0, Z set, always branches

do_filt_down:
    dec m_filt
    bne do_filt_set
    lda #1
    sta m_fdir

do_filt_set:
    lda m_filt
    clc
    adc #$20
    sta $d416
    rts

// ============================================================
// Modulation tables
// ============================================================

// Minor-triad arpeggio offsets: root, minor 3rd, perfect 5th
arp_offsets:
    .byte 0, 3, 7

// Vibrato LFO (16 entries, unsigned 0–8, one-sided upward sine)
vib_table:
    .byte 0, 1, 2, 4, 6, 7, 8, 7, 6, 4, 2, 1, 0, 0, 0, 0

// ============================================================
// INTRO section patterns  (V1, V2: 24 steps each; V3: 8 steps)
//
// Three stages of build-up:
//   Steps  0- 7: V1 silent, V2 silent — arp drones alone
//   Steps  8-15: V2 bass enters gently, V1 still silent
//   Steps 16-23: V1 melody hints (A3 → C4 → E4)
//
// Note index reference (1-based):
//   E2=17  F2=18  G2=20  A2=22
//   A3=34  C4=37  E4=41
// ============================================================

intro_v1:
    // 0-7: silence — arp alone fills the space
    .byte  _R,  _R,  _R,  _R,   _R,  _R,  _R,  _R
    // 8-15: still silent — bass has entered below
    .byte  _R,  _R,  _R,  _R,   _R,  _R,  _R,  _R
    // 16-23: melody enters — A3 held, C4, E4 hint at the coming theme
    .byte  34,  _H,  _H,  _H,   37,  _H,  41,  _H

intro_v2:
    // 0-7: silence — arp alone
    .byte  _R,  _R,  _R,  _R,   _R,  _R,  _R,  _R
    // 8-15: Am bass enters, sparse
    .byte  22,  _R,  22,  _R,   20,  _R,  18,  _R
    // 16-23: bass grows, anticipating the main groove
    .byte  22,  22,  _R,  22,   20,  20,  _R,  _R

// V3 intro roots: Am drone with one Gm step — very calm
intro_v3:
    .byte  22,  22,  22,  22,   20,  20,  22,  22

// ============================================================
// MAIN section patterns  (V1: 32 steps, V2: 16 steps, V3: 8)
//
// V1 phrase A (0-15):  descend from A4 through the scale to A3
// V1 phrase B (16-31): rising Am arc with portamento slide at step 22
//
// Note index reference:
//   E2=17  F2=18  G2=20  A2=22
//   A3=34  C4=37  D4=39  E4=41  G4=44  A4=46
// ============================================================

main_v1:
    // Phrase A — descent (steps 0-15)
    .byte  46,  _H,  _H,  _H   // A4 sustained
    .byte  44,  _H,  41,  _H   // G4 → E4
    .byte  39,  _H,  _H,  _H   // D4 sustained
    .byte  _R,  _R,  34,  _H   // silence → A3
    // Phrase B — ascending return (steps 16-31)
    .byte  34,  _H,  37,  _H   // A3 → C4
    .byte  41,  _H,  44,  _H   // E4 → G4  (step 22 = portamento)
    .byte  46,  _H,  _H,  _H   // A4 peak, sustained
    .byte  41,  _H,  _R,  _R   // E4 descent, rest

// Slide flags for MAIN: 1 = portamento into that note (upward only)
main_v1flags:
    .byte  0, 0, 0, 0,  0, 0, 0, 0   // steps 0-7
    .byte  0, 0, 0, 0,  0, 0, 0, 0   // steps 8-15
    .byte  0, 0, 0, 0,  0, 0, 1, 0   // step 22 = portamento (E4→G4 glide)
    .byte  0, 0, 0, 0,  0, 0, 0, 0   // steps 24-31

// V2 main bass: syncopated Am ostinato with descending F–E figure
main_v2:
    .byte  22,  22,  _R,  22   // A2 A2 . A2 — pump
    .byte  20,  20,  _R,  _R   // G2 G2 . .
    .byte  18,  18,  17,  17   // F2 F2 E2 E2 — chromatic descent
    .byte  18,  _R,  22,  _R   // F2 . A2 . — resolve

// V3 main roots: Am→Gm→Fm→Em→Am (full minor circle, loops twice per V1 cycle)
main_v3:
    .byte  22,  22,  20,  20,   18,  18,  17,  22

// ============================================================
// VAR section patterns  (V1: 32 steps, V2: 16 steps, V3: 8)
//
// Character: wider range (B4 peak), Phrygian tension (G#4),
// Last Ninja stepwise descent (C4-B3-A3), portamento rise to A4.
//
// Note index reference (additions for VAR):
//   F4=42  G#4=45  A4=46  B4=48  (all within the 49-entry table)
//   B3=36
// ============================================================

var_v1:
    // High phrase with chromatic tension (steps 0-15)
    .byte  46,  _H,  _H,  48   // A4 sustained → leap to B4
    .byte  _H,  _H,  46,  _H   // B4 sustained → A4 settles
    .byte  45,  _H,  44,  _H   // G#4 Phrygian tension → G4 resolve
    .byte  42,  _H,  _H,  _H   // F4 sustained
    // Descending return phrase (steps 16-31)
    .byte  41,  _H,  39,  _H   // E4 → D4 stepwise
    .byte  37,  36,  34,  _H   // C4 → B3 → A3 (classic Last Ninja descent)
    .byte  37,  _H,  41,  _H   // C4 back up → E4
    .byte  46,  _H,  _R,  _R   // A4 peak (step 28 = portamento) → rest

// Slide flags for VAR: portamento at step 28 (E4 glides up to A4)
var_v1flags:
    .byte  0, 0, 0, 0,  0, 0, 0, 0   // steps 0-7
    .byte  0, 0, 0, 0,  0, 0, 0, 0   // steps 8-15
    .byte  0, 0, 0, 0,  0, 0, 0, 0   // steps 16-23
    .byte  0, 0, 0, 0,  1, 0, 0, 0   // step 28 = portamento (E4→A4 glide)

// V2 variation bass: same Am framework, reversed Em-Fm tension figure
var_v2:
    .byte  22,  22,  _R,  22   // A2 A2 . A2 — same opening
    .byte  20,  _R,  20,  _R   // G2 with breathing room
    .byte  17,  17,  18,  _R   // E2 E2 F2 rest — reversed tension
    .byte  22,  _R,  22,  _R   // Am resolution, airy

// V3 variation roots: Am→Em→Fm→Gm (tighter motion, more forward drive)
var_v3:
    .byte  22,  22,  17,  17,   18,  18,  20,  22

// ============================================================
// Sequencer and modulation state variables
// ============================================================
m_tick:         .byte 0   // frame counter for sequencer advance
m_v1pos:        .byte 0   // position in current V1 pattern
m_v2pos:        .byte 0   // position in current V2 pattern
m_v3pos:        .byte 0   // position in V3 arp-root pattern
m_v1note:       .byte 0   // most recent V1 note index (1-based)
m_v2note:       .byte 0   // most recent V2 note index
m_v3root:       .byte 0   // current arp root note (fed to do_arp)
m_arp_phase:    .byte 0   // arp step within chord (0–2)
m_arp_timer:    .byte 0   // frame countdown between arp steps
m_vib_phase:    .byte 0   // vibrato LFO table index (0–15)
m_v1base_lo:    .byte 0   // V1 base frequency lo (vibrato reference)
m_v1base_hi:    .byte 0   // V1 base frequency hi
m_pw:           .byte 0   // PWM counter (incremented each frame)
m_filt:         .byte 0   // filter LFO offset (0–$50)
m_fdir:         .byte 1   // filter LFO direction (1=up, 0=down)
m_slide_lo:     .byte 0   // current portamento frequency lo
m_slide_hi:     .byte 0   // current portamento frequency hi
m_slide_tgt_lo: .byte 0   // portamento target frequency lo
m_slide_tgt_hi: .byte 0   // portamento target frequency hi
m_slide_active: .byte 0   // 1 = portamento in progress
m_slide_flag:   .byte 0   // temp: slide flag for current sv1 step
m_v1len:        .byte 0   // current section's V1 pattern length
m_v2len:        .byte 0   // current section's V2 pattern length
m_section:      .byte 0   // current section (SEC_INTRO/SEC_MAIN/SEC_VAR)
m_rep_count:    .byte 0   // how many times MAIN has completed consecutively

// ============================================================
// Frequency table — PAL C64 (49 entries, C1 to C5, 1-based)
// Note N → freq_lo[N-1] / freq_hi[N-1]
// Fn = round(f_hz × 16777216 / 985248)
// ============================================================
freq_lo:
    //     C      C#     D      D#     E      F      F#     G      G#     A      A#     B
    .byte $2d,  $4e,  $71,  $96,  $be,  $e8,  $14,  $43,  $74,  $a9,  $e0,  $1b  // octave 1
    .byte $5a,  $9c,  $e2,  $2c,  $7c,  $d0,  $28,  $86,  $e8,  $52,  $c0,  $36  // octave 2
    .byte $b4,  $38,  $c4,  $58,  $f8,  $a0,  $50,  $0c,  $d0,  $a4,  $80,  $6c  // octave 3
    .byte $68,  $70,  $88,  $b0,  $f0,  $40,  $a0,  $18,  $a0,  $48,  $00,  $d8  // octave 4
    .byte $d0                                                                        // C5

freq_hi:
    .byte $02,  $02,  $02,  $02,  $02,  $02,  $03,  $03,  $03,  $03,  $03,  $04  // octave 1
    .byte $04,  $04,  $04,  $05,  $05,  $05,  $06,  $06,  $06,  $07,  $07,  $08  // octave 2
    .byte $08,  $09,  $09,  $0a,  $0a,  $0b,  $0c,  $0d,  $0d,  $0e,  $0f,  $10  // octave 3
    .byte $11,  $12,  $13,  $14,  $15,  $17,  $18,  $1a,  $1b,  $1d,  $1f,  $20  // octave 4
    .byte $22                                                                        // C5
