        * = $0801          ; BASIC program start

        .word next         ; link to next BASIC line
        .word 10           ; line number 10
        .byte $9e          ; SYS token
        .text "2064"       ; "SYS2064"
        .byte 0            ; end of line
next    .word 0            ; end of BASIC program

        * = $0810          ; 2064 decimal

start:
        lda #$00
        sta $d020          ; border = black
        sta $d021          ; background = black

        jsr $e544          ; clear screen

        lda #$07
        sta $0286          ; default text color = yellow
        lda #$93
        jsr $ffd2          ; apply color

        lda #<($0400 + $01EF)
        sta scrptr
        lda #>($0400 + $01EF)
        sta scrptr+1

        lda #<($d800 + $01EF)
        sta colptr
        lda #>($d800 + $01EF)
        sta colptr+1

        ldx #0
print_loop:
        lda msg,x
        beq done
        ldy #0
        sta (scrptr),y
        lda #$07
        sta (colptr),y
        inc scrptr
        bne sk1
        inc scrptr+1
sk1:    inc colptr
        bne sk2
        inc colptr+1
sk2:    inx
        bne print_loop

done:   jmp done

msg:    .text "HELLO WORLD"
        .byte 0

scrptr: .word 0
colptr: .word 0
