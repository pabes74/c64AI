BasicUpstart2(start)

.import source "gfx.asm"
.import source "music.asm"

.const MUSIC_INIT = music_init
.const MUSIC_PLAY = music_play

.const RIGHT0_PTR = right0 / 64
.const SPRITE0_X   = 160
.const SPRITE0_Y   = 150

.const SCREEN_BASE = $0400
.const COLOR_BASE  = $d800
.const SCREEN_LINE = $05e0       // screen line to use

.const RASTER_SPLIT = $78        // raster line where we switch back to ROM charset

// static text lines (rows under scroller)
.const TEXT1_ROW = 16
.const TEXT2_ROW = 17
.const TEXT3_ROW = 18

.const TEXT1_COL = 6
.const TEXT2_COL = 7
.const TEXT3_COL = 10

.const TEXT1_ADDR = SCREEN_BASE + TEXT1_ROW*40 + TEXT1_COL
.const TEXT2_ADDR = SCREEN_BASE + TEXT2_ROW*40 + TEXT2_COL
.const TEXT3_ADDR = SCREEN_BASE + TEXT3_ROW*40 + TEXT3_COL

.const TEXT3_COLOR_ADDR = COLOR_BASE + TEXT3_ROW*40 + TEXT3_COL

.const MSG_LEN = msg_end - msg
.const MAXPOS  = MSG_LEN - 40    // last valid start column


// Entry point
* = $4000
start:
    // Make screen black and text white
    lda #$00
    sta $d020
    sta $d021

    // Ensure multicolor character mode is off for title screen
    lda $d016
    and #%11101111
    sta $d016

    lda #$01
    sta $0286

    // Configure multicolor palette for sprite 0
    lda #$0a
    sta $d025
    lda #$00
    sta $d026

    // Clear the screen
    jsr $e544

    // Use custom charset at $2000 with screen at $0400
    // $d018: bits 4-7 = screen / $0400, bits 1-3 = chars / $0800
    // screen=$0400 -> 1, chars=$2000 -> 4 -> %0001 1000 = $18
    lda #$18
    sta $d018

    jsr blank_background_chars
    jsr draw_logo
    jsr color_logo

    // draw static info text under scroller
    jsr draw_static_text

    // init SID music
    jsr MUSIC_INIT

    // setup raster IRQ to use custom charset for logo rows
    // and ROM charset for the lower part (so text is readable)
    sei
    lda #<irq_handler
    sta $0314
    lda #>irq_handler
    sta $0315

    lda #$00
    sta irq_state

    lda #$00           // first IRQ at line 0 (top)
    sta $d012
    lda $d011
    and #%01111111     // ensure raster high bit = 0
    sta $d011

    lda #%00000001     // enable raster IRQ
    sta $d01a

    lda $d019          // clear pending IRQ flags
    sta $d019
    cli

    // init sprite 0 in middle of screen
    lda #SPRITE0_X
    sta $d000          // sprite 0 X
    lda #SPRITE0_Y
    sta $d001          // sprite 0 Y

    lda $d010          // clear MSB of sprite 0 X
    and #%11111110
    sta $d010

    lda #$01           // white
    sta $d027          // sprite 0 color

    lda #RIGHT0_PTR   // sprite data pointer in $07f8
    sta $07f8

    lda $d015          // enable sprite 0
    ora #%00000001
    sta $d015

    lda $d01c          // enable multicolor for sprite 0
    ora #%00000001
    sta $d01c

    lda #$00
    sta scroll_pos

main_loop:
    jsr draw_text
    jsr delay
    jsr check_space
    bne no_space
    jmp start_game

no_space:
    inc scroll_pos
    lda scroll_pos
    cmp #MAXPOS+1
    bcc main_loop

    lda #$00
    sta scroll_pos
    jmp main_loop


// Message buffer: spaces + text + spaces
msg:
    .fill 40, $20
    .text "welcome to artificial fist!"
    .fill 40, $20
msg_end:

text1:
    .text "programmed by ai agents 2026"
text1_end:

text2:
    .text "original sid theme by ai 2026"
text2_end:

text3:
    .text "press space to play"
text3_end:

.const TEXT1_LEN = text1_end - text1
.const TEXT2_LEN = text2_end - text2
.const TEXT3_LEN = text3_end - text3

scroll_pos:
    .byte 0

irq_state:
    .byte 0

.const map_ptr = $fb
.const scr_ptr = $fd


draw_text:
    ldx #$00
    ldy scroll_pos
draw_loop:
    lda msg,y
    sta SCREEN_LINE,x
    inx
    iny
    cpx #40
    bne draw_loop
    rts


check_space:
    jsr $ff9f      // SCNKEY: scan keyboard
    jsr $ffe4      // GETIN: get key from buffer (0 if none)
    cmp #$20       // space?
    rts            // Z flag set if equal


draw_static_text:
    // line 1: "programmed by ai agents 2026"
    lda #<TEXT1_ADDR
    sta scr_ptr
    lda #>TEXT1_ADDR
    sta scr_ptr+1

    ldy #0
text1_loop:
    lda text1,y
    sta (scr_ptr),y
    iny
    cpy #TEXT1_LEN
    bne text1_loop

    // line 2: "music by jeroen soede 1988"
    lda #<TEXT2_ADDR
    sta scr_ptr
    lda #>TEXT2_ADDR
    sta scr_ptr+1

    ldy #0
text2_loop:
    lda text2,y
    sta (scr_ptr),y
    iny
    cpy #TEXT2_LEN
    bne text2_loop

    // line 3: "press space to play" (also color it)
    lda #<TEXT3_ADDR
    sta scr_ptr
    lda #>TEXT3_ADDR
    sta scr_ptr+1

    ldy #0
text3_loop:
    lda text3,y
    sta (scr_ptr),y
    iny
    cpy #TEXT3_LEN
    bne text3_loop

    // set color for line 3 to yellow
    lda #<TEXT3_COLOR_ADDR
    sta scr_ptr
    lda #>TEXT3_COLOR_ADDR
    sta scr_ptr+1

    ldy #0
text3_col_loop:
    lda #$07      // yellow
    sta (scr_ptr),y
    iny
    cpy #TEXT3_LEN
    bne text3_col_loop
    rts


start_game:
    sei

    // restore default KERNAL IRQ vector and disable raster IRQs
    lda #$31
    sta $0314
    lda #$ea
    sta $0315

    lda #$00
    sta $d01a

    // use ROM charset at $1000 with screen at $0400
    lda #$14
    sta $d018

    // silence SID: clear registers $d400-$d418 (incl. volume)
    ldx #$18
    lda #$00
sid_clear_loop:
    sta $d400,x
    dex
    bpl sid_clear_loop

    // restore reasonable master volume after silence sweep
    lda #$0f
    sta $d418

    cli

    jmp start


// Draw 15x6 logo map at top of screen (starting at $0400)
.const LOGO_WIDTH  = 15
.const LOGO_HEIGHT = 6
.const LOGO_X_OFFSET = 12
.const LOGO_SCREEN_BASE = SCREEN_BASE + LOGO_X_OFFSET
.const LOGO_COLOR_BASE  = COLOR_BASE + LOGO_X_OFFSET
.const LOGO_COLOR_TOP   = $07   // yellow
.const LOGO_COLOR_BOT   = $02   // red

blank_background_chars:
    // Clear charset char 0 (used by map for empty cells)
    ldx #7
bb0_loop:
    lda #$00
    sta LogoChars+0*8,x
    dex
    bpl bb0_loop

    // Clear charset char $20 (space, used by clear-screen routine)
    ldx #7
bb20_loop:
    lda #$00
    sta LogoChars+$20*8,x
    dex
    bpl bb20_loop
    rts

color_logo:
    lda #<LOGO_COLOR_BASE
    sta scr_ptr
    lda #>LOGO_COLOR_BASE
    sta scr_ptr+1

    ldx #LOGO_HEIGHT        // row counter (6 rows total)
row_color_loop:
    // Determine color for this row: top 3 rows yellow, bottom 3 rows red
    lda #LOGO_COLOR_TOP     // default yellow
    cpx #4                  // if X >= 4, we're in top half (rows count down 6→1)
    bcs row_color_set       // yes, use yellow
    lda #LOGO_COLOR_BOT     // X < 4, bottom half → red
row_color_set:
    sta temp_color

    ldy #0                  // column index
col_color_loop:
    lda temp_color
    sta (scr_ptr),y
    iny
    cpy #LOGO_WIDTH
    bne col_color_loop

    // advance scr_ptr by 40 (full screen row)
    clc
    lda scr_ptr
    adc #40
    sta scr_ptr
    bcc skip_inc_color_hi
    inc scr_ptr+1
skip_inc_color_hi:

    dex
    bne row_color_loop
    rts

temp_color: .byte 0         // temporary storage for current row color

draw_logo:
    lda #<map_data
    sta map_ptr
    lda #>map_data
    sta map_ptr+1

    lda #<LOGO_SCREEN_BASE
    sta scr_ptr
    lda #>LOGO_SCREEN_BASE
    sta scr_ptr+1

    ldx #LOGO_HEIGHT        // row counter
row_loop:
    ldy #0                  // column index
col_loop:
    lda (map_ptr),y
    sta (scr_ptr),y
    iny
    cpy #LOGO_WIDTH
    bne col_loop

    // advance map_ptr by LOGO_WIDTH
    clc
    lda map_ptr
    adc #LOGO_WIDTH
    sta map_ptr
    bcc skip_inc_map_hi
    inc map_ptr+1
skip_inc_map_hi:

    // advance scr_ptr by 40 (full screen row)
    clc
    lda scr_ptr
    adc #40
    sta scr_ptr
    bcc skip_inc_scr_hi
    inc scr_ptr+1
skip_inc_scr_hi:

    dex
    bne row_loop
    rts


delay:
    ldx #$ff
delay_outer:
    ldy #$ff
delay_inner:
    dey
    bne delay_inner
    dex
    bne delay_outer
    rts


irq_handler:
    pha
    txa
    pha
    tya
    pha

    lda $d019
    and #%00000001
    beq irq_not_raster
    sta $d019          // acknowledge raster IRQ

    lda irq_state
    beq irq_top

irq_bottom:
    // play SID once per frame
    jsr MUSIC_PLAY

    // bottom part: use ROM charset at $1000 (screen still at $0400)
    lda #$14
    sta $d018

    lda #$00           // next IRQ at line 0 (top)
    sta $d012

    lda #$00
    sta irq_state
    jmp irq_done

irq_top:
    // top part: use custom charset at $2000
    lda #$18
    sta $d018

    lda #RASTER_SPLIT  // next IRQ where we switch back
    sta $d012

    lda #$01
    sta irq_state

irq_done:
    pla
    tay
    pla
    tax
    pla
    jmp $ea31          // chain to KERNAL IRQ handler

irq_not_raster:
    pla
    tay
    pla
    tax
    pla
    jmp $ea31
