!to "default", $0801
.byte $0C,$08,$0A,$00,$9E,$20,$32,$30,$36,$39,$00,$00,$00
jmp start

msg:
.byte $48,$45,$4c,$4c,$4f,$20,$57,$4f
.byte $52,$4c,$44,$00

start:
lda #$93
jsr $ffd2
ldx #$00
prtloop:
lda msg,x
beq forever
sta $0400,x
inx
cpx #$0d
bne prtloop
forever:
jmp forever
