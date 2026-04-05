// ------------------------------------------------------------
// Sound effects for Artificial Fist
// Hand-tuned SID SFX for walking, kicking, jumping, ducking.
// Uses SID voice 2 ($d407-$d40d) to avoid clobbering voice 1.
// Call the routine for the action you want to trigger.
// ------------------------------------------------------------

.const SID_BASE   = $d400
.const V2_FREQ_LO = SID_BASE + $07
.const V2_FREQ_HI = SID_BASE + $08
.const V2_PW_LO   = SID_BASE + $09
.const V2_PW_HI   = SID_BASE + $0a
.const V2_CTRL    = SID_BASE + $0b
.const V2_AD      = SID_BASE + $0c
.const V2_SR      = SID_BASE + $0d

// Clears gate so a new effect re-triggers cleanly.
.macro sfx_gate_off() {
    lda #$00
    sta V2_CTRL
}

// Triggers voice 2 with specified params.
.macro sfx_trigger(freqLo, freqHi, pwLo, pwHi, waveGate, ad, sr) {
    lda #freqLo
    sta V2_FREQ_LO
    lda #freqHi
    sta V2_FREQ_HI
    lda #pwLo
    sta V2_PW_LO
    lda #pwHi
    sta V2_PW_HI
    lda #ad
    sta V2_AD
    lda #sr
    sta V2_SR
    lda #waveGate
    sta V2_CTRL
}

// Soft footstep: sustained noise while moving.
sfx_walk:
    lda sfx_walk_on
    bne sfx_walk_done
    sfx_gate_off()
    // low noise burst, fast attack, high sustain for continuous step hiss
    sfx_trigger($18, $02, $00, $08, $81, $02, $f8)
    lda #$01
    sta sfx_walk_on
sfx_walk_done:
    rts

// Stop the walking loop.
sfx_walk_stop:
    lda sfx_walk_on
    beq sfx_walk_stop_done
    sfx_gate_off()
    lda #$00
    sta sfx_walk_on
sfx_walk_stop_done:
    rts

// Kick: punchy saw with quick decay.
sfx_kick:
    sfx_gate_off()
    // strong transient, short decay, medium release
    sfx_trigger($90, $06, $00, $08, $21, $03, $68)
    lda #$20
    sta V2_CTRL
    rts

// Jump: triangle with longer release.
sfx_jump:
    sfx_gate_off()
    // brighter tone, smoother tail
    sfx_trigger($40, $09, $00, $08, $11, $14, $a6)
    lda #$10
    sta V2_CTRL
    rts

// Duck: low muffled pulse.
sfx_duck:
    sfx_gate_off()
    // low pulse, short decay, short release
    sfx_trigger($28, $01, $00, $10, $41, $02, $46)
    lda #$40
    sta V2_CTRL
    rts

// Hit: harsh noise burst for damage impact.
sfx_hit:
    sfx_gate_off()
    // loud sharp noise, fast attack/decay
    sfx_trigger($ff, $0f, $00, $00, $81, $00, $20)
    lda #$80
    sta V2_CTRL
    rts

// Boulder break: deep crunching noise when boulder is shattered by a kick.
sfx_boulder_break:
    sfx_gate_off()
    // low-mid noise, medium decay, short release — heavy crumbling impact
    sfx_trigger($80, $04, $00, $00, $81, $06, $28)
    lda #$80
    sta V2_CTRL
    rts

// --- Runtime state -----------------------------------------------------------
sfx_walk_on:
    .byte $00
