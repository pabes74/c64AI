// KARATEGAI — player sprite (multicolor, 24x21)
// 0=transparent, 01=$D025 (black), 10=$D026 (lt red / skin), 11=sprite color (white)
sprite_player:
    .byte $00,$54,$00
    .byte $01,$55,$00
    .byte $01,$A9,$00
    .byte $00,$A8,$00
    .byte $00,$F0,$00
    .byte $0F,$FF,$00
    .byte $3F,$FF,$C0
    .byte $2F,$FF,$80
    .byte $2F,$5F,$80
    .byte $0D,$57,$00
    .byte $0F,$FF,$00
    .byte $0F,$0F,$00
    .byte $0F,$0F,$00
    .byte $0F,$0F,$00
    .byte $0F,$0F,$00
    .byte $0F,$0F,$00
    .byte $0F,$0F,$00
    .byte $0A,$0A,$00
    .byte $0A,$0A,$00
    .byte $2A,$0A,$80
    .byte $00,$00,$00
    .byte $00 // pad to 64
