BasicUpstart2(start)

.const SCREEN_LINE = $05e0       // screen line to use

.const MSG_LEN = msg_end - msg
.const MAXPOS  = MSG_LEN - 40    // last valid start column


// Entry point
* = $4000
start:
    // Make screen black and text white
    lda #$00
    sta $d020
    sta $d021
    lda #$01
    sta $0286

    // Clear the screen
    jsr $e544

    lda #$00
    sta scroll_pos

main_loop:
    jsr draw_text
    jsr delay

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
    .text "hello world!"
    .fill 40, $20
msg_end:

scroll_pos:
    .byte 0


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