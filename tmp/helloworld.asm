; Simple C64 "HELLO WORLD" in center-ish of screen

; Load address for BASIC autostart
        * = $0801

        ; Minimal BASIC stub: 10 SYS2064
        .word next       ; BASIC link pointer (filled by assembler)
        .word 10         ; line number
        .byte $9e        ; BASIC token for SYS
        .text "2064"     ; SYS 2064
        .byte 0          ; end of line
next    .word 0          ; end of BASIC program

; Machine code at $0810 (2064)
        * = $0810

start:
        ; Set background (black) and border (black)
        lda #$00
        sta $d020        ; border color
        sta $d021        ; background color

        ; Clear screen using KERNAL routine at $e544
        jsr $e544

        ; Set text color to yellow (color code 7)
        lda #$07
        sta $0286        ; default text color
        lda #$93
        jsr $ffd2        ; CHROUT: print control code to apply color

        ; Print "HELLO WORLD" centered (row 12, column 15)
        ; Screen address = $0400 + $01EF = $05EF
        ; Color address  = $d800 + $01EF = $d9EF
        ldy #0
print_loop:
        lda msg,y
        beq done
        sta $05ef,y
        lda #$07
        sta $d9ef,y
        iny
        bne print_loop

done:
        jmp done         ; loop forever

msg:
        .text "HELLO WORLD"
        .byte 0
