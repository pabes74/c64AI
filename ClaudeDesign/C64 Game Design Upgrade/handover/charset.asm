// KARATEGAI — FIST II redesign charset
// Multicolor character mode. Bitpairs: 00=$D021, 01=$D022, 10=$D023, 11=color RAM (0-7)
// Chars marked (hires) are used with color-RAM bit3 clear (values $00-$07)
// 64 chars, 512 bytes

charset:
ch_blank: // $00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
ch_solid1: // $01
    .byte $55,$55,$55,$55,$55,$55,$55,$55
ch_solid2: // $02
    .byte $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
ch_solid3: // $03
    .byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
ch_canopy_a: // $04
    .byte $77,$DD,$7D,$D7,$75,$1D,$C7,$41
ch_canopy_b: // $05
    .byte $DD,$77,$D7,$7D,$5C,$D4,$70,$30
ch_canopy_c: // $06
    .byte $5F,$F5,$77,$DD,$37,$1D,$0D,$04
ch_vine_a: // $07
    .byte $10,$34,$1C,$04,$34,$10,$1C,$04
ch_vine_b: // $08
    .byte $04,$1C,$34,$10,$0C,$04,$34,$10
ch_vine_end: // $09
    .byte $10,$34,$1C,$14,$04,$34,$0C,$00
ch_leaf_tuft: // $0A
    .byte $00,$14,$7D,$77,$DD,$14,$04,$00
ch_bush_top_a: // $0B
    .byte $00,$14,$7D,$D7,$7D,$D7,$77,$DD
ch_bush_top_b: // $0C
    .byte $04,$1D,$77,$DD,$77,$DD,$7D,$D7
ch_bush_fill_a: // $0D
    .byte $77,$DD,$7D,$D7,$77,$DD,$7D,$D7
ch_bush_fill_b: // $0E
    .byte $DD,$77,$D7,$7D,$DD,$77,$D7,$7D
ch_bush_base: // $0F
    .byte $77,$DD,$1D,$C7,$0D,$01,$00,$00
ch_trunk: // $10
    .byte $28,$28,$28,$28,$28,$28,$28,$28
ch_trunk_shade: // $11
    .byte $2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C
ch_grass_top: // $12
    .byte $44,$1D,$77,$DD,$77,$FF,$FF,$FF
ch_dirt_a: // $13
    .byte $AA,$BA,$AB,$EA,$AE,$AA,$BA,$AB
ch_dirt_b: // $14
    .byte $AE,$AA,$EA,$AB,$AA,$BA,$AA,$AE
ch_dirt_hole: // $15
    .byte $AA,$8A,$A2,$AA,$2A,$A2,$AA,$8A
ch_dirt_dark: // $16
    .byte $88,$22,$88,$22,$88,$22,$88,$22
ch_under_a: // $17
    .byte $00,$20,$00,$02,$00,$80,$00,$08
ch_under_b: // $18
    .byte $00,$02,$00,$20,$00,$08,$00,$80
ch_cliff_r: // $19
    .byte $A8,$AA,$A8,$A0,$A8,$AA,$A0,$A8
ch_reeds: // $1A
    .byte $00,$13,$D1,$77,$DD,$77,$DD,$77
ch_water_a: // $1B
    .byte $FF,$FF,$33,$FF,$FF,$CC,$FF,$FF
ch_water_b: // $1C
    .byte $FF,$CF,$FF,$F3,$FF,$FF,$3F,$FF
ch_water_top: // $1D
    .byte $44,$FF,$FF,$CF,$FF,$F3,$FF,$FF
ch_torii_beam: // $1E
    .byte $FF,$FF,$FF,$00,$00,$00,$00,$00
ch_torii_beam2: // $1F
    .byte $00,$FF,$FF,$00,$00,$00,$00,$00
ch_torii_end_l: // $20
    .byte $0F,$3F,$FF,$00,$00,$00,$00,$00
ch_torii_end_r: // $21
    .byte $F0,$FC,$FF,$00,$00,$00,$00,$00
ch_torii_post: // $22
    .byte $3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C
ch_torii_base: // $23
    .byte $14,$14,$55,$00,$00,$00,$00,$00
ch_banner_a: // $24
    .byte $3C,$3C,$3C,$3C,$30,$0C,$00,$00
ch_beam_h: // $25
    .byte $AA,$AA,$EE,$AA,$00,$00,$00,$00
ch_beam_v: // $26
    .byte $2E,$2E,$2E,$2E,$2E,$2E,$2E,$2E
ch_plank: // $27
    .byte $FF,$AA,$AE,$AA,$BA,$AA,$00,$00
ch_plank_l: // $28
    .byte $3F,$2A,$2B,$2A,$2E,$2A,$00,$00
ch_plank_r: // $29
    .byte $FC,$A8,$B8,$A8,$AC,$A8,$00,$00
ch_floor_a: // $2A
    .byte $FF,$AA,$AE,$AB,$AA,$BA,$AA,$AB
ch_floor_b: // $2B
    .byte $AA,$AE,$AA,$AB,$AA,$AE,$AA,$BA
ch_panel: // $2C
    .byte $FF,$C3,$C3,$FF,$C3,$C3,$FF,$00
ch_lantern_top: // $2D
    .byte $04,$04,$3F,$FF,$FF,$FF,$3F,$0C
ch_stone: // $2E
    .byte $00,$28,$AA,$28,$00,$00,$00,$00
ch_rope: // $2F
    .byte $04,$04,$04,$04,$04,$04,$04,$04
ch_moon_tl: // $30
    .byte $0F,$3F,$FF,$FF,$FF,$FF,$FF,$FF
ch_moon_tr: // $31
    .byte $F0,$FC,$FF,$FF,$FF,$FF,$FF,$FF
ch_moon_bl: // $32
    .byte $FF,$FF,$FF,$FF,$FF,$FF,$3F,$0F
ch_moon_br: // $33
    .byte $FF,$FF,$FF,$FF,$FF,$FF,$FC,$F0
ch_f_K: // $34 (hires)
    .byte $00,$C6,$CC,$F8,$F8,$CC,$C6,$00
ch_f_A: // $35 (hires)
    .byte $00,$7C,$C6,$C6,$FE,$C6,$C6,$00
ch_f_R: // $36 (hires)
    .byte $00,$FC,$C6,$FC,$F0,$D8,$CC,$00
ch_f_T: // $37 (hires)
    .byte $00,$FC,$30,$30,$30,$30,$30,$00
ch_f_E: // $38 (hires)
    .byte $00,$FC,$C0,$F8,$C0,$C0,$FC,$00
ch_f_G: // $39 (hires)
    .byte $00,$7C,$C0,$C0,$CE,$C6,$7C,$00
ch_f_I: // $3A (hires)
    .byte $00,$FC,$30,$30,$30,$30,$FC,$00
ch_f_L: // $3B (hires)
    .byte $00,$C0,$C0,$C0,$C0,$C0,$FC,$00
ch_f_V: // $3C (hires)
    .byte $00,$C6,$C6,$C6,$6C,$6C,$38,$00
ch_f_colon: // $3D (hires)
    .byte $00,$00,$30,$00,$00,$30,$00,$00
ch_f_1: // $3E (hires)
    .byte $00,$30,$70,$30,$30,$30,$FC,$00
ch_heart: // $3F
    .byte $00,$CC,$FF,$FF,$3C,$0C,$00,$00
