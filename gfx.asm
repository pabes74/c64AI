// Shared graphics assets for main.asm and game.asm
.const GAME_BG_CHARSET_BASE = $2800

* = $2000
LogoChars:
    // Logo charset binary (png/Logo - Chars.bin) is not committed.
    // Filled with zeros so the build succeeds; regenerate from source PNG to restore logo visuals.
    .fill 2048, $00

* = GAME_BG_CHARSET_BASE
// Gameplay background tileset (256 chars @ $2800)
game_bg_charset:
// Multicolor character mode tileset (2 bits per pixel)
// %00 = $d021 (background/sky), %01 = $d022 (dark blue), %10 = $d023 (green), %11 = colour RAM

// tile 0: sky/empty (all background)
    .byte $00,$00,$00,$00,$00,$00,$00,$00

// tile 1: distant hill bump (%11 body, uses colour RAM = light blue per bg_row_color)
    .byte $00,$00,$3c,$ff,$ff,$ff,$ff,$ff

// tile 2: near hill left slope (%10 green, widening down)
    .byte $00,$80,$80,$a0,$a0,$a8,$aa,$aa

// tile 3: near hill peak (%11 highlight tip, %10 green body)
    .byte $00,$3c,$aa,$aa,$aa,$aa,$aa,$aa

// tile 4: near hill right slope (%10 green, widening down)
    .byte $00,$02,$02,$0a,$0a,$2a,$aa,$aa

// tile 5: near hill fill (%10 solid green)
    .byte $00,$aa,$aa,$aa,$aa,$aa,$aa,$aa

// tile 6: field/ground fill (%10 green with %11 flower specks)
    .byte $00,$aa,$aa,$ea,$aa,$aa,$ab,$aa

// tile 7: road (%11=yellow via colour RAM $0f, %01=brown spots via $d022)
    .byte $ff,$ff,$df,$ff,$7f,$ff,$f7,$ff

// tile 8: grass top variant A (%10 green blade)
    .byte $20,$20,$a8,$aa,$aa,$aa,$aa,$aa

// tile 9: grass top variant B (%10 green blade)
    .byte $08,$08,$2a,$aa,$aa,$aa,$aa,$aa

// tile 10: grass fill (solid %10 green)
    .byte $aa,$aa,$aa,$aa,$aa,$aa,$aa,$aa

// tile 11: temple roof edge left (%11 diagonal)
    .byte $00,$c0,$f0,$fc,$ff,$ff,$ff,$ff

// tile 12: temple roof edge right (%11 diagonal)
    .byte $00,$03,$0f,$3f,$ff,$ff,$ff,$ff

// tile 13: tree top left  (%00=transparent, %10=light green, %11=green)
    .byte $0b,$2f,$3f,$3f,$bf,$bf,$bf,$3f

// tile 14: tree top right (%00=transparent, %10=light green, %11=green)
    .byte $c8,$f8,$fc,$fc,$fe,$fe,$fe,$ff

// tile 15: road variant B (%11=yellow, %01=orange spots at rows 0/3/5, cols 3/1/0)
    .byte $fd,$ff,$ff,$df,$ff,$7f,$ff,$ff

// HUD characters (hi-res mode via color RAM bit3=0)
// K (screen code $10)
    .byte $c6,$cc,$d8,$f0,$d8,$cc,$c6,$00
// A (screen code $11)
    .byte $3c,$66,$66,$7e,$66,$66,$66,$00
// R (screen code $12)
    .byte $7c,$66,$66,$7c,$78,$6c,$66,$00
// T (screen code $13)
    .byte $7e,$5a,$18,$18,$18,$18,$3c,$00
// E (screen code $14)
    .byte $7e,$60,$60,$78,$60,$60,$7e,$00
// G (screen code $15)
    .byte $3c,$66,$60,$6e,$66,$66,$3c,$00
// I (screen code $16)
    .byte $3c,$18,$18,$18,$18,$18,$3c,$00
// full life heart (screen code $17)
    .byte $66,$ff,$ff,$7e,$3c,$18,$00,$00
// empty life heart (screen code $18)
    .byte $66,$99,$81,$42,$24,$18,$00,$00

// tile 25: pillar (%11=solid, %01=orange accent on right edge)
    .byte $fd,$fd,$fd,$fd,$fd,$fd,$fd,$fd

// tile 26: tree stump (%11=colour RAM, %10=light green, %01=%01=orange)
    .byte $e5,$e5,$e5,$e5,$e5,$e5,$e5,$e5

// U (screen code $1b)
    .byte $66,$66,$66,$66,$66,$66,$3c,$00
// O (screen code $1c)
    .byte $3c,$66,$66,$66,$66,$66,$3c,$00

// tile 29 ($1d): tree fill — solid green (%11 in every pixel)
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff

game_bg_charset_end:
    .fill 256*8 - (game_bg_charset_end - game_bg_charset), $00

* = $3000
right0:
    // Sprite imported from sprites/pixellab (1).txt (sprite 1)
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$30,$00,$00
    .byte $fc,$00,$00,$d4,$00,$03,$d8,$00
    .byte $0c,$10,$00,$00,$96,$00,$02,$aa
    .byte $90,$02,$a6,$80,$00,$b8,$00,$00
    .byte $28,$00,$00,$3f,$00,$00,$ae,$00
    .byte $00,$aa,$80,$02,$82,$80,$02,$80
    .byte $a0,$0a,$00,$a0,$07,$00,$d0,$81

// sprite 2 / multicolor / color: $01
right1:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$30,$00,$00
    .byte $fc,$00,$00,$d4,$00,$0f,$d8,$00
    .byte $00,$10,$00,$00,$94,$00,$00,$a9
    .byte $00,$00,$aa,$40,$00,$ab,$00,$00
    .byte $28,$00,$00,$3f,$00,$00,$ae,$00
    .byte $00,$aa,$00,$00,$aa,$80,$00,$2a
    .byte $00,$00,$ae,$00,$00,$71,$00,$81

// sprite 3 / multicolor / color: $01
right2:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$30,$00,$00
    .byte $fc,$00,$0c,$d4,$00,$03,$d8,$00
    .byte $00,$10,$00,$00,$94,$00,$02,$aa
    .byte $90,$02,$aa,$c0,$00,$a8,$00,$00
    .byte $28,$00,$00,$3f,$00,$00,$ae,$00
    .byte $02,$aa,$00,$02,$aa,$80,$0a,$82
    .byte $80,$0e,$02,$80,$01,$03,$40,$81

// sprite 4 / multicolor / color: $01
left0:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$0c,$00,$00
    .byte $3f,$00,$00,$17,$00,$00,$27,$c0
    .byte $00,$04,$30,$00,$96,$00,$06,$aa
    .byte $80,$02,$9a,$80,$00,$2e,$00,$00
    .byte $28,$00,$00,$fc,$00,$00,$ba,$00
    .byte $02,$aa,$00,$02,$82,$80,$0a,$02
    .byte $80,$0a,$00,$a0,$07,$00,$d0,$81

// sprite 5 / multicolor / color: $01
left1:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$0c,$00,$00
    .byte $3f,$00,$00,$17,$00,$00,$27,$f0
    .byte $00,$04,$00,$00,$16,$00,$00,$6a
    .byte $00,$01,$aa,$00,$00,$ea,$00,$00
    .byte $28,$00,$00,$fc,$00,$00,$ba,$00
    .byte $00,$aa,$00,$02,$aa,$00,$00,$a8
    .byte $00,$00,$ba,$00,$00,$4d,$00,$81

// sprite 6 / multicolor / color: $01
left2:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$0c,$00,$00
    .byte $3f,$00,$00,$17,$30,$00,$27,$c0
    .byte $00,$04,$00,$00,$16,$00,$06,$aa
    .byte $80,$03,$aa,$80,$00,$2a,$00,$00
    .byte $28,$00,$00,$fc,$00,$00,$ba,$00
    .byte $00,$aa,$80,$02,$aa,$80,$02,$82
    .byte $a0,$02,$80,$b0,$01,$c0,$40,$81    

// sprite 7 / multicolor / color: $01
rightk:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$30,$00,$00
    .byte $fc,$00,$00,$d4,$40,$00,$d8,$80
    .byte $03,$12,$83,$0c,$96,$89,$02,$aa
    .byte $09,$02,$aa,$28,$0a,$28,$28,$2c
    .byte $2e,$a0,$10,$3e,$80,$00,$ae,$80
    .byte $00,$aa,$00,$02,$80,$00,$02,$80
    .byte $00,$0a,$00,$00,$07,$00,$00,$81

// sprite 8 / multicolor / color: $01
leftk:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$0c,$00,$00
    .byte $3f,$00,$01,$17,$00,$02,$27,$00
    .byte $c2,$84,$c0,$62,$96,$30,$60,$aa
    .byte $80,$28,$aa,$80,$28,$28,$a0,$0a
    .byte $b8,$38,$02,$bc,$04,$02,$ba,$00
    .byte $00,$aa,$00,$00,$02,$80,$00,$02
    .byte $80,$00,$00,$a0,$00,$00,$d0,$81

// sprite 9 / multicolor / color: $01
rightkn:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$0f,$00
    .byte $03,$3f,$c0,$00,$f5,$c0,$00,$06
    .byte $40,$00,$95,$80,$02,$a4,$00,$0a
    .byte $a8,$24,$08,$2a,$a4,$08,$af,$80
    .byte $08,$bb,$80,$04,$2a,$a0,$02,$a8
    .byte $a8,$0a,$a8,$a0,$07,$28,$d0,$81

// sprite 10 / multicolor / color: $01
leftkn:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$f0,$00
    .byte $03,$fc,$c0,$03,$5f,$00,$01,$90
    .byte $00,$02,$56,$00,$00,$1a,$80,$18
    .byte $2a,$a0,$1a,$a8,$20,$02,$fa,$20
    .byte $02,$ee,$20,$0a,$a8,$10,$2a,$2a
    .byte $80,$0a,$2a,$a0,$07,$28,$d0,$81    

// sprite 11 / multicolor / color: $01
rightd:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$01,$00,$04,$09,$00
    .byte $48,$2b,$00,$88,$20,$30,$a0,$a1
    .byte $e1,$a0,$a9,$e1,$ab,$eb,$d5,$fb
    .byte $a8,$d7,$ab,$80,$3e,$2b,$00,$81

// sprite 12 / multicolor / color: $01
leftd:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$40,$00,$00,$60,$10,$00,$e8
    .byte $21,$00,$08,$22,$00,$4a,$0a,$0c
    .byte $6a,$0a,$4b,$eb,$ea,$4b,$2a,$ea
    .byte $57,$02,$eb,$d7,$00,$e8,$3c,$81

// sprite 13 / multicolor / color: $01
rightj:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$3c,$00,$00,$03,$30,$00,$00
    .byte $fc,$00,$0c,$d4,$60,$18,$d8,$a0
    .byte $28,$12,$80,$0a,$96,$80,$02,$aa
    .byte $00,$00,$aa,$00,$00,$28,$00,$00
    .byte $2f,$a0,$00,$3e,$a8,$02,$ae,$a8
    .byte $02,$aa,$28,$02,$80,$a0,$00,$b0
    .byte $a0,$00,$50,$d0,$00,$40,$10,$81

// sprite 14 / multicolor / color: $01
leftj:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$3c,$00,$0c,$c0,$00
    .byte $3f,$00,$09,$17,$30,$0a,$27,$24
    .byte $02,$84,$28,$02,$96,$a0,$00,$aa
    .byte $80,$00,$aa,$00,$00,$28,$00,$0a
    .byte $f8,$00,$2a,$bc,$00,$2a,$ba,$80
    .byte $28,$aa,$80,$0a,$02,$80,$0a,$0e
    .byte $00,$07,$05,$00,$04,$01,$00,$81

knife1:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$b0,$00,$00,$b0,$00,$00
    .byte $b0,$3f,$ff,$ff,$2f,$ff,$ff,$0a
    .byte $aa,$ba,$00,$00,$b0,$00,$00,$b0
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$81

boulder1:
    .byte $00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$2f,$c0,$00
    .byte $95,$70,$02,$55,$70,$02,$55,$5c
    .byte $09,$57,$5c,$09,$55,$dc,$09,$55
    .byte $dc,$09,$55,$dc,$09,$55,$dc,$09
    .byte $55,$dc,$09,$55,$dc,$09,$55,$dc
    .byte $02,$57,$5c,$02,$55,$70,$00,$95
    .byte $c0,$00,$27,$00,$00,$00,$00,$81

// Boulder rubble: three scattered rock fragments, same multicolor palette as boulder1.
// Fragment 1: rows 3-5, pairs 2-5 (upper area)
// Fragment 2: rows 8-10, pairs 6-9 (center-right)
// Fragment 3: rows 13-16, pairs 1-8 (lower, largest)
boulder_rubble:
    .byte $00,$00,$00  // row 0: empty
    .byte $00,$00,$00  // row 1: empty
    .byte $00,$00,$00  // row 2: empty
    .byte $0d,$70,$00  // row 3: frag1 top   [..BLACK,ORG,ORG,BLACK..]
    .byte $06,$90,$00  // row 4: frag1 mid   [..ORG,WHITE,WHITE,ORG..]
    .byte $0f,$f0,$00  // row 5: frag1 base  [..BLACK,BLACK,BLACK,BLACK..]
    .byte $00,$00,$00  // row 6: gap
    .byte $00,$00,$00  // row 7: gap
    .byte $00,$0d,$70  // row 8: frag2 top   [....BLACK,ORG,ORG,BLACK..]
    .byte $00,$06,$90  // row 9: frag2 mid   [....ORG,WHITE,WHITE,ORG..]
    .byte $00,$0f,$f0  // row 10: frag2 base [....BLACK,BLACK,BLACK,BLACK..]
    .byte $00,$00,$00  // row 11: gap
    .byte $00,$00,$00  // row 12: gap
    .byte $35,$55,$c0  // row 13: frag3 top  [.BLACK,ORG,ORG,ORG,ORG,ORG,ORG,BLACK.]
    .byte $19,$99,$40  // row 14: frag3 mid1 [.ORG,WHITE,ORG,WHITE,ORG,WHITE,ORG,ORG.]
    .byte $16,$69,$40  // row 15: frag3 mid2 [.ORG,ORG,WHITE,ORG,WHITE,WHITE,ORG,ORG.]
    .byte $3f,$ff,$c0  // row 16: frag3 base [.BLACK x8.]
    .byte $00,$00,$00  // row 17: empty
    .byte $00,$00,$00  // row 18: empty
    .byte $00,$00,$00  // row 19: empty
    .byte $00,$00,$00  // row 20: empty
    .byte $81

// Kuro boss sprites (multicolor, samurai with sword)
// Colors: %01=$d025 (light red/skin), %10=sprite color (dark blue armor), %11=$d026 (black outline/sword)

// --- Right-facing set ---

// Kuro walk right frame 0 (standing, feet together)
kuro_r0:
    .byte $00,$3c,$00     // row 0:  helmet top
    .byte $00,$ff,$00     // row 1:  helmet
    .byte $03,$ff,$c0     // row 2:  helmet wide
    .byte $00,$57,$00     // row 3:  face (skin %01)
    .byte $00,$ff,$00     // row 4:  chin guard
    .byte $03,$aa,$c0     // row 5:  shoulders (armor %10)
    .byte $0f,$aa,$f0     // row 6:  torso wide
    .byte $0f,$aa,$f0     // row 7:  torso
    .byte $0f,$ea,$f0     // row 8:  torso with sash
    .byte $03,$aa,$c0     // row 9:  waist
    .byte $03,$aa,$c0     // row 10: waist
    .byte $03,$ff,$c0     // row 11: belt (black)
    .byte $03,$aa,$c0     // row 12: hakama top
    .byte $03,$aa,$c0     // row 13: hakama
    .byte $0a,$00,$a0     // row 14: legs apart
    .byte $0a,$00,$a0     // row 15: legs
    .byte $0a,$00,$a0     // row 16: legs
    .byte $0a,$00,$a0     // row 17: shins
    .byte $0f,$00,$f0     // row 18: feet (black boots)
    .byte $0f,$00,$f0     // row 19: feet
    .byte $00,$00,$00     // row 20: empty
    .byte $81

// Kuro walk right frame 1 (left foot forward)
kuro_r1:
    .byte $00,$3c,$00
    .byte $00,$ff,$00
    .byte $03,$ff,$c0
    .byte $00,$57,$00
    .byte $00,$ff,$00
    .byte $03,$aa,$c0
    .byte $0f,$aa,$f0
    .byte $0f,$aa,$f0
    .byte $0f,$ea,$f0
    .byte $03,$aa,$c0
    .byte $03,$aa,$c0
    .byte $03,$ff,$c0
    .byte $03,$aa,$c0
    .byte $02,$aa,$80
    .byte $02,$80,$a0     // left leg forward
    .byte $02,$80,$a0
    .byte $0a,$02,$80
    .byte $0a,$02,$80
    .byte $0f,$00,$f0
    .byte $3c,$00,$3c
    .byte $00,$00,$00
    .byte $81

// Kuro walk right frame 2 (right foot forward)
kuro_r2:
    .byte $00,$3c,$00
    .byte $00,$ff,$00
    .byte $03,$ff,$c0
    .byte $00,$57,$00
    .byte $00,$ff,$00
    .byte $03,$aa,$c0
    .byte $0f,$aa,$f0
    .byte $0f,$aa,$f0
    .byte $0f,$ea,$f0
    .byte $03,$aa,$c0
    .byte $03,$aa,$c0
    .byte $03,$ff,$c0
    .byte $03,$aa,$c0
    .byte $02,$aa,$80
    .byte $0a,$02,$80     // right leg forward
    .byte $0a,$02,$80
    .byte $02,$80,$a0
    .byte $02,$80,$a0
    .byte $0f,$00,$f0
    .byte $3c,$00,$3c
    .byte $00,$00,$00
    .byte $81

// Kuro sword strike right
kuro_rs:
    .byte $00,$3c,$00
    .byte $00,$ff,$00
    .byte $03,$ff,$c0
    .byte $00,$57,$00
    .byte $00,$ff,$00
    .byte $03,$aa,$c0
    .byte $0f,$aa,$ff     // arm extended with sword
    .byte $0f,$aa,$ff
    .byte $0f,$ea,$ff     // sword blade
    .byte $03,$aa,$ff
    .byte $03,$aa,$fc
    .byte $03,$ff,$c0
    .byte $03,$aa,$c0
    .byte $03,$aa,$c0
    .byte $0a,$00,$a0
    .byte $0a,$00,$a0
    .byte $0a,$00,$a0
    .byte $0a,$00,$a0
    .byte $0f,$00,$f0
    .byte $0f,$00,$f0
    .byte $00,$00,$00
    .byte $81

// Kuro death right (falling backward)
kuro_rd:
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$3c,$00
    .byte $00,$ff,$00
    .byte $03,$d7,$c0
    .byte $0f,$ff,$f0
    .byte $0f,$ea,$f0
    .byte $3f,$aa,$fc
    .byte $0a,$ff,$a0
    .byte $0a,$aa,$a0
    .byte $0f,$0f,$f0
    .byte $81

// --- Left-facing set ---

// Kuro walk left frame 0
kuro_l0:
    .byte $00,$3c,$00
    .byte $00,$ff,$00
    .byte $03,$ff,$c0
    .byte $00,$d5,$00     // face mirrored
    .byte $00,$ff,$00
    .byte $03,$aa,$c0
    .byte $0f,$aa,$f0
    .byte $0f,$aa,$f0
    .byte $0f,$ab,$f0
    .byte $03,$aa,$c0
    .byte $03,$aa,$c0
    .byte $03,$ff,$c0
    .byte $03,$aa,$c0
    .byte $03,$aa,$c0
    .byte $0a,$00,$a0
    .byte $0a,$00,$a0
    .byte $0a,$00,$a0
    .byte $0a,$00,$a0
    .byte $0f,$00,$f0
    .byte $0f,$00,$f0
    .byte $00,$00,$00
    .byte $81

// Kuro walk left frame 1
kuro_l1:
    .byte $00,$3c,$00
    .byte $00,$ff,$00
    .byte $03,$ff,$c0
    .byte $00,$d5,$00
    .byte $00,$ff,$00
    .byte $03,$aa,$c0
    .byte $0f,$aa,$f0
    .byte $0f,$aa,$f0
    .byte $0f,$ab,$f0
    .byte $03,$aa,$c0
    .byte $03,$aa,$c0
    .byte $03,$ff,$c0
    .byte $03,$aa,$c0
    .byte $02,$aa,$80
    .byte $0a,$02,$80
    .byte $0a,$02,$80
    .byte $02,$80,$a0
    .byte $02,$80,$a0
    .byte $0f,$00,$f0
    .byte $3c,$00,$3c
    .byte $00,$00,$00
    .byte $81

// Kuro walk left frame 2
kuro_l2:
    .byte $00,$3c,$00
    .byte $00,$ff,$00
    .byte $03,$ff,$c0
    .byte $00,$d5,$00
    .byte $00,$ff,$00
    .byte $03,$aa,$c0
    .byte $0f,$aa,$f0
    .byte $0f,$aa,$f0
    .byte $0f,$ab,$f0
    .byte $03,$aa,$c0
    .byte $03,$aa,$c0
    .byte $03,$ff,$c0
    .byte $03,$aa,$c0
    .byte $02,$aa,$80
    .byte $02,$80,$a0
    .byte $02,$80,$a0
    .byte $0a,$02,$80
    .byte $0a,$02,$80
    .byte $0f,$00,$f0
    .byte $3c,$00,$3c
    .byte $00,$00,$00
    .byte $81

// Kuro sword strike left
kuro_ls:
    .byte $00,$3c,$00
    .byte $00,$ff,$00
    .byte $03,$ff,$c0
    .byte $00,$d5,$00
    .byte $00,$ff,$00
    .byte $03,$aa,$c0
    .byte $ff,$aa,$f0     // arm extended with sword (left)
    .byte $ff,$aa,$f0
    .byte $ff,$ab,$f0
    .byte $ff,$aa,$c0
    .byte $3f,$aa,$c0
    .byte $03,$ff,$c0
    .byte $03,$aa,$c0
    .byte $03,$aa,$c0
    .byte $0a,$00,$a0
    .byte $0a,$00,$a0
    .byte $0a,$00,$a0
    .byte $0a,$00,$a0
    .byte $0f,$00,$f0
    .byte $0f,$00,$f0
    .byte $00,$00,$00
    .byte $81

// Kuro death left
kuro_ld:
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$00,$00
    .byte $00,$3c,$00
    .byte $00,$ff,$00
    .byte $03,$d5,$c0
    .byte $0f,$ff,$f0
    .byte $0f,$ab,$f0
    .byte $3f,$aa,$fc
    .byte $0a,$ff,$a0
    .byte $0a,$aa,$a0
    .byte $0f,$f0,$f0
    .byte $81

// Logo map data: 15x6 cells, 8 bits per cell (90 bytes)
map_data:
	.byte $00,$01,$02,$03,$04,$03,$05,$03,$06,$07,$08,$09,$0a,$0b,$00
	.byte $00,$0c,$0d,$0e,$0f,$10,$11,$12,$13,$14,$15,$16,$17,$18,$00
	.byte $19,$1a,$1b,$1c,$1d,$1e,$1f,$20,$21,$22,$23,$24,$25,$26,$27
	.byte $00,$00,$28,$29,$2a,$2b,$2c,$2d,$2e,$2f,$30,$31,$32,$00,$00
	.byte $00,$00,$33,$34,$35,$36,$37,$38,$39,$3a,$3b,$3c,$00,$00,$00
	.byte $00,$3d,$3e,$3f,$00,$40,$41,$42,$43,$44,$00,$45,$46,$00,$00
