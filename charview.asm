// charview.asm - Charset viewer screen
// Displays all 13 game background tiles (0-12) in multicolor mode.
// Shown between the title screen and game. Press SPACE to continue.

* = $5000

// --- Tile reference table (labelled for later use) ---
cv_tiles:
cv_tile_sky:         .byte 0   // sky / empty
cv_tile_far_hill:    .byte 1   // distant hill bump
cv_tile_hill_left:   .byte 2   // near hill left slope
cv_tile_hill_peak:   .byte 3   // near hill peak
cv_tile_hill_right:  .byte 4   // near hill right slope
cv_tile_hill_fill:   .byte 5   // near hill fill
cv_tile_field:       .byte 6   // field / ground
cv_tile_road:        .byte 7   // road solid
cv_tile_grass_a:     .byte 8   // grass top variant A
cv_tile_grass_b:     .byte 9   // grass top variant B
cv_tile_grass_fill:  .byte 10  // grass fill
cv_tile_roof_left:   .byte 11  // temple roof edge left
cv_tile_roof_right:  .byte 12  // temple roof edge right
cv_tile_tree_top_l:  .byte 13  // tree top left
cv_tile_tree_top_r:  .byte 14  // tree top right
cv_tile_road2:       .byte 15  // road variant B

.const CV_TILE_COUNT = 16

// 2x2 display blocks, 3 columns apart (2 wide + 1 gap)
// Row 1: tiles 0-6  -> 7 blocks -> 7*3-1 = 20 cols -> starts at col 10
// Row 2: tiles 7-12 -> 6 blocks -> 6*3-1 = 17 cols -> starts at col 11
.const CV_ROW1_SCR = $0400 + 10*40 + 10
.const CV_ROW1_COL = $d800 + 10*40 + 10
.const CV_ROW2_SCR = $0400 + 14*40 + 11
.const CV_ROW2_COL = $d800 + 14*40 + 11

.const CV_TILE_COLOR = $0f       // multicolor enabled (bit3=1), %11=yellow

.const cv_scr = $fb              // ZP pointer: screen write position
.const cv_col = $fd              // ZP pointer: color RAM write position

charview_start:
    lda #$00
    sta $d020              // black border
    sta $d021              // black background

    // Enable multicolor character mode
    lda $d016
    ora #%00010000
    sta $d016

    lda #$08
    sta $d022              // %01 = orange (road spots)
    lda #$0d
    sta $d023              // %10 = light green (tree highlights)

    lda #$00
    sta $d015              // disable sprites

    // Screen $0400, charset $2800
    lda #$1a
    sta $d018

    lda #$01
    sta $0286              // default color white
    jsr $e544              // clear screen

    // --- Row 1: tiles 0-6 ---
    lda #<CV_ROW1_SCR
    sta cv_scr
    lda #>CV_ROW1_SCR
    sta cv_scr+1
    lda #<CV_ROW1_COL
    sta cv_col
    lda #>CV_ROW1_COL
    sta cv_col+1

    lda #$00
    sta cv_tile_idx

cv_r1_loop:
    jsr cv_draw_block
    inc cv_tile_idx
    lda cv_tile_idx
    cmp #$07
    bne cv_r1_loop

    // --- Row 2: tiles 7-12 ---
    lda #<CV_ROW2_SCR
    sta cv_scr
    lda #>CV_ROW2_SCR
    sta cv_scr+1
    lda #<CV_ROW2_COL
    sta cv_col
    lda #>CV_ROW2_COL
    sta cv_col+1

cv_r2_loop:
    jsr cv_draw_block
    inc cv_tile_idx
    lda cv_tile_idx
    cmp #CV_TILE_COUNT
    bne cv_r2_loop

    // --- Wait for SPACE ---
cv_wait_space:
    jsr $ff9f              // SCNKEY
    jsr $ffe4              // GETIN
    cmp #$20
    bne cv_wait_space

    jmp game_start


// Subroutine: draw a 2x2 block of the current tile and advance pointers
cv_draw_block:
    lda cv_tile_idx
    ldy #$00
    sta (cv_scr),y         // top-left
    iny
    sta (cv_scr),y         // top-right
    ldy #40
    sta (cv_scr),y         // bottom-left
    iny
    sta (cv_scr),y         // bottom-right

    lda #CV_TILE_COLOR
    ldy #$00
    sta (cv_col),y
    iny
    sta (cv_col),y
    ldy #40
    sta (cv_col),y
    iny
    sta (cv_col),y

    // Advance pointers by 3 (block width 2 + gap 1)
    clc
    lda cv_scr
    adc #$03
    sta cv_scr
    bcc cv_scr_no_carry
    inc cv_scr+1
cv_scr_no_carry:
    clc
    lda cv_col
    adc #$03
    sta cv_col
    bcc cv_col_no_carry
    inc cv_col+1
cv_col_no_carry:
    rts


cv_tile_idx:
    .byte 0
