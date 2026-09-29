// highscore.asm — session highscore table (top 5) with initials entry.
//
// Lives in the free gap between the title code ($4000) and charview ($5000).
// The table is RAM-only: it survives game overs but not a machine reset.
//
// Screens are drawn below the title logo (rows 9–24), where the title raster
// IRQ switches to the ROM charset, so all text uses ROM screen codes
// (.text lowercase → $01–$1a, shown as upper-case letters).
//
// Uses the same ZP pointers as main.asm (scr_ptr $fd, map_ptr $fb) — the title
// code owns them while these screens run.

* = $4800

.const HS_ENTRIES      = 5
.const HS_SCR_PTR      = $fd                      // = main.asm scr_ptr
.const HS_COL_PTR      = $fb                      // = main.asm map_ptr
.const HS_SCREEN       = $0400
.const HS_COLOR        = $d800
.const HS_CLEAR_ROW    = 9                        // first row cleared by hs_clear_lower
.const HS_CLEAR_START  = HS_SCREEN + HS_CLEAR_ROW*40
.const HS_CLEAR_CSTART = HS_COLOR  + HS_CLEAR_ROW*40
.const HS_CLEAR_BYTES  = (25 - HS_CLEAR_ROW) * 40 // 640 = 4 × 160

.const HS_TABLE_ROW    = 12                       // first table entry row (2 rows apart)
.const HS_TABLE_COL    = 13                       // "1. AAA  000000" = 14 chars
.const HS_ENTRY_ROW    = 15                       // initials row on the entry screen
.const HS_ENTRY_COL    = 18

.const HS_CHAR_DASH    = $2d                      // '-' placeholder for an empty initial
.const HS_CHAR_DOT     = $2e
.const HS_CHAR_ZERO    = $30

.const HS_COLOR_TITLE  = $07                      // yellow — matches the title prompt
.const HS_COLOR_ENTRY  = $01                      // white
.const HS_COLOR_NEW    = $03                      // cyan — the entry just added
.const HS_COLOR_HINT   = $0f                      // light grey

.const KEY_RETURN      = $0d
.const KEY_DEL         = $14

// Copy `len` screen codes from `src` to (row, col) and colour them.
.macro HsPrint(src, len, row, col, color) {
    ldx #$00
!loop:
    lda src,x
    sta HS_SCREEN + row*40 + col,x
    lda #color
    sta HS_COLOR  + row*40 + col,x
    inx
    cpx #len
    bne !loop-
}


// ============================================================
// hs_clear_lower — blank rows 9–24 (screen = space, colour = white).
// Trashes A, X.
// ============================================================
hs_clear_lower:
    ldx #$00
hs_clear_loop:
    lda #$20
    sta HS_CLEAR_START,x
    sta HS_CLEAR_START + 160,x
    sta HS_CLEAR_START + 320,x
    sta HS_CLEAR_START + 480,x
    lda #HS_COLOR_ENTRY
    sta HS_CLEAR_CSTART,x
    sta HS_CLEAR_CSTART + 160,x
    sta HS_CLEAR_CSTART + 320,x
    sta HS_CLEAR_CSTART + 480,x
    inx
    cpx #160
    bne hs_clear_loop
    rts


// ============================================================
// hs_cmp_slot — compare score with table entry X.
// Out: C=1 if score is strictly greater than hs_scores[X]; X preserved.
// Trashes A, Y.
// ============================================================
hs_cmp_slot:
    stx hs_idx
    txa
    asl                         // C=0 (X < 128)
    adc hs_idx                  // A = X*3
    tay
    ldx #$00
hs_cmp_loop:
    lda score,x
    cmp hs_scores,y
    bne hs_cmp_done             // first differing byte decides; C=1 → greater
    iny
    inx
    cpx #3
    bne hs_cmp_loop
    clc                         // equal → not greater (ties keep the older entry)
hs_cmp_done:
    ldx hs_idx
    rts


// ============================================================
// hs_check_qualifies — C=1 if score beats the 5th entry.
// ============================================================
hs_check_qualifies:
    ldx #HS_ENTRIES - 1
    jmp hs_cmp_slot


// ============================================================
// hs_insert — insert score into the table, shifting lower entries down.
// Sets hs_new_slot (0–4) and hs_name_base (slot*3); the new name is "---".
// Call only after hs_check_qualifies returned C=1.  Trashes A, X, Y.
// ============================================================
hs_insert:
    ldx #$00
hs_find_loop:
    jsr hs_cmp_slot
    bcs hs_found
    inx
    cpx #HS_ENTRIES
    bne hs_find_loop
    lda #$ff                    // not reached if hs_check_qualifies passed
    sta hs_new_slot
    rts

hs_found:
    stx hs_new_slot
    txa
    asl
    adc hs_new_slot
    sta hs_name_base            // first byte of the new entry
    cpx #HS_ENTRIES - 1
    beq hs_shift_done           // last slot: nothing to shift

    // move bytes [base .. 11] up by one entry (3 bytes), top down
    ldy #(HS_ENTRIES - 1) * 3 - 1
hs_shift_loop:
    lda hs_scores,y
    sta hs_scores + 3,y
    lda hs_names,y
    sta hs_names + 3,y
    cpy hs_name_base
    beq hs_shift_done
    dey
    jmp hs_shift_loop

hs_shift_done:
    ldy hs_name_base
    ldx #$00
hs_write_loop:
    lda score,x
    sta hs_scores,y
    lda #HS_CHAR_DASH
    sta hs_names,y
    iny
    inx
    cpx #3
    bne hs_write_loop
    rts


// ============================================================
// hs_draw_table — draw "HALL OF FAME" and the 5 entries below the logo.
// Expects hs_clear_lower to have run.  Trashes A, X, Y, HS_SCR_PTR, HS_COL_PTR.
// ============================================================
hs_draw_table:
    HsPrint(hs_title_text, hs_title_text_end - hs_title_text, 10, 14, HS_COLOR_TITLE)
    HsPrint(text3, text3_end - text3, 23, 10, HS_COLOR_TITLE)       // "press space to play"

    ldx #$00
hs_row_loop:
    stx hs_idx
    lda hs_row_lo,x
    sta HS_SCR_PTR
    sta HS_COL_PTR
    lda hs_row_hi,x
    sta HS_SCR_PTR+1
    clc
    adc #>(HS_COLOR - HS_SCREEN)                            // same offset in colour RAM
    sta HS_COL_PTR+1

    // rank "N."
    ldy #$00
    txa
    clc
    adc #HS_CHAR_ZERO + 1
    sta (HS_SCR_PTR),y
    iny
    lda #HS_CHAR_DOT
    sta (HS_SCR_PTR),y

    // initials at offset 3–5
    txa
    asl
    adc hs_idx
    tax                                                     // X = entry*3
    ldy #3
hs_name_loop:
    lda hs_names,x
    sta (HS_SCR_PTR),y
    inx
    iny
    cpy #6
    bne hs_name_loop

    // score digits at offset 8–13
    dex
    dex
    dex
    ldy #8
hs_digit_loop:
    lda hs_scores,x
    lsr
    lsr
    lsr
    lsr
    ora #HS_CHAR_ZERO
    sta (HS_SCR_PTR),y
    iny
    lda hs_scores,x
    and #$0f
    ora #HS_CHAR_ZERO
    sta (HS_SCR_PTR),y
    iny
    inx
    cpy #14
    bne hs_digit_loop

    // colour the row: cyan for the entry just added, white otherwise
    lda #HS_COLOR_ENTRY
    ldx hs_idx
    cpx hs_new_slot
    bne hs_row_color_set
    lda #HS_COLOR_NEW
hs_row_color_set:
    ldy #13
hs_row_color_loop:
    sta (HS_COL_PTR),y
    dey
    bpl hs_row_color_loop

    inx
    cpx #HS_ENTRIES
    bne hs_row_loop
    rts


// ============================================================
// hs_enter_initials — "NEW HIGHSCORE!" screen; type 3 letters,
// DEL = back, RETURN = confirm.  Runs on the title screen (logo and
// music IRQ active).  Writes into hs_names at hs_name_base.
// Trashes A, X, Y.
// ============================================================
hs_enter_initials:
    lda $d015                   // hide the title sprite — it sits over this area
    and #%11111110
    sta $d015

    jsr hs_clear_lower
    HsPrint(hs_new_text, hs_new_text_end - hs_new_text, 10, 13, HS_COLOR_TITLE)
    HsPrint(hs_enter_text, hs_enter_text_end - hs_enter_text, 12, 10, HS_COLOR_ENTRY)
    HsPrint(hs_hint_text, hs_hint_text_end - hs_hint_text, 20, 10, HS_COLOR_HINT)

    // player's score at row 17, cols 17–22
    ldx #$00
    ldy #$00
hs_score_loop:
    lda score,x
    lsr
    lsr
    lsr
    lsr
    ora #HS_CHAR_ZERO
    sta HS_SCREEN + 17*40 + 17,y
    lda #HS_COLOR_TITLE
    sta HS_COLOR  + 17*40 + 17,y
    iny
    lda score,x
    and #$0f
    ora #HS_CHAR_ZERO
    sta HS_SCREEN + 17*40 + 17,y
    lda #HS_COLOR_TITLE
    sta HS_COLOR  + 17*40 + 17,y
    iny
    inx
    cpx #3
    bne hs_score_loop

    lda #$00
    sta hs_cursor
    sta $c6                     // flush keys typed during game over

hs_entry_loop:
    jsr hs_draw_initials
    jsr $ffe4                   // GETIN (buffer filled by the KERNAL IRQ scan)
    beq hs_entry_loop

    cmp #KEY_RETURN
    bne hs_entry_not_return
    lda hs_cursor
    cmp #3
    bne hs_entry_loop           // need all 3 letters first
    lda #$ff                    // cursor off for the final draw
    sta hs_cursor
    jsr hs_draw_initials
    rts

hs_entry_not_return:
    cmp #KEY_DEL
    bne hs_entry_not_del
    lda hs_cursor
    beq hs_entry_loop
    dec hs_cursor
    lda hs_cursor
    clc
    adc hs_name_base
    tax
    lda #HS_CHAR_DASH
    sta hs_names,x
    jmp hs_entry_loop

hs_entry_not_del:
    cmp #$c1                    // shifted letters $c1–$da → $41–$5a
    bcc hs_entry_unshifted
    cmp #$db
    bcs hs_entry_loop
    and #$7f
hs_entry_unshifted:
    cmp #$41                    // 'A'
    bcc hs_entry_loop
    cmp #$5b                    // past 'Z'
    bcs hs_entry_loop
    ldx hs_cursor
    cpx #3
    beq hs_entry_loop           // already full — RETURN or DEL
    sec
    sbc #$40                    // PETSCII → screen code $01–$1a
    pha
    txa
    clc
    adc hs_name_base
    tax
    pla
    sta hs_names,x
    inc hs_cursor
    jmp hs_entry_loop


// Draw the 3 initials; the cursor position blinks in reverse (~3 Hz).
hs_draw_initials:
    ldx hs_name_base
    ldy #$00
hs_di_loop:
    lda hs_names,x
    cpy hs_cursor
    bne hs_di_put
    pha
    lda $a2
    and #%00001000
    beq hs_di_plain
    pla
    ora #$80                    // reverse video
    jmp hs_di_put
hs_di_plain:
    pla
hs_di_put:
    sta HS_SCREEN + HS_ENTRY_ROW*40 + HS_ENTRY_COL,y
    lda #HS_COLOR_NEW
    sta HS_COLOR  + HS_ENTRY_ROW*40 + HS_ENTRY_COL,y
    inx
    iny
    cpy #3
    bne hs_di_loop
    rts


// ============================================================
// Data
// ============================================================

// Session table, best first.  Scores are packed BCD, big-endian.
hs_scores:
    .byte $00, $50, $00         // 5000
    .byte $00, $40, $00         // 4000
    .byte $00, $30, $00         // 3000
    .byte $00, $20, $00         // 2000
    .byte $00, $10, $00         // 1000
hs_names:
    .text "aif"
    .text "kur"
    .text "lun"
    .text "kar"
    .text "gai"

// screen address of each table row (col HS_TABLE_COL)
hs_row_lo:
    .fill HS_ENTRIES, <(HS_SCREEN + (HS_TABLE_ROW + i*2)*40 + HS_TABLE_COL)
hs_row_hi:
    .fill HS_ENTRIES, >(HS_SCREEN + (HS_TABLE_ROW + i*2)*40 + HS_TABLE_COL)

hs_title_text:
    .text "hall of fame"
hs_title_text_end:

hs_new_text:
    .text "new highscore!"
hs_new_text_end:

hs_enter_text:
    .text "enter your initials"
hs_enter_text_end:

hs_hint_text:
    .text "del=back  return=ok"
hs_hint_text_end:

hs_new_slot:
    .byte $ff                   // entry added by the last game ($ff = none)
hs_name_base:
    .byte $00                   // hs_new_slot * 3
hs_cursor:
    .byte $00                   // 0–3 = next initial to type, $ff = done
hs_idx:
    .byte $00
