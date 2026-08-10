# KARATEGAI — FIST II-style visual redesign
## Handover spec for the coding agent (KickAssembler)

Everything in this package obeys real C64 hardware limits and was generated from
the same data used to render the approved mockups. Nothing needs "adapting" —
the `.asm` files assemble as-is with KickAssembler.

---

## 1. Video mode

**Multicolor character mode** (like FIST II):
- `$D011 = $1B` (text mode, 25 rows)
- `$D016 = $D8` (multicolor on, 40 cols; use `$D0-$D7` low bits for hardware scroll)
- Custom charset, 64 chars (`charset.asm`), 512 bytes. Point `$D018` at it.
- Bitpairs: `00`=$D021, `01`=$D022, `10`=$D023, `11`=color RAM (colors 0–7 only).
- HUD font chars are **hires cells**: color RAM bit 3 clear (values $00–$07).

## 2. Color registers — two art directions

Both directions share the SAME charset and the same screen maps (except
canopy/moon decoration), so switching direction = changing 3 registers.

**Direction A — "Jungle Night" (faithful FIST II)**
```
lda #$00  sta $D020   // border black
lda #$00  sta $D021   // background black
lda #$0D  sta $D022   // lt green  (leaf highlights)
lda #$08  sta $D023   // orange    (earth / wood)
```

**Direction B — "Dusk Silhouette"**
```
lda #$00  sta $D020
lda #$06  sta $D021   // blue night sky
lda #$00  sta $D022   // black (silhouette foliage)
lda #$08  sta $D023   // orange
```

**Sprites (both directions)**
```
lda #$00  sta $D025   // sprite MC1: black (hair, belt)
lda #$0A  sta $D026   // sprite MC2: lt red (skin)
lda #$01  sta $D027   // player sprite color: white (gi)
```

**HUD raster split (required):** at raster line ~$B8 (start of char row 23) set
`$D021 = $00` so the HUD band is black in both directions; restore the
direction's background color at vblank. This is the classic FIST II-style
status-panel trick.

## 3. Color RAM values

`screens.asm` contains ready-made color RAM per screen: multicolor cells are
stored with bit 3 set (`$08 | color`), hires HUD cells as plain `$00-$07`.
Cell colors used: 1 white, 2 red, 4 purple, 5 green, 7 yellow.

## 4. Screens (level flows left → right, scrolling)

The three maps are representative 40×25 keyframes of the scrolling level;
tile the bands horizontally between them.

- **screen2 — jungle path & pond**: canopy rows 0–2 (dir A) / moon (dir B),
  bush band rows 7–11 with trunks, grass fringe row 12, dirt rows 13–17,
  pond cols 30–39 (reeds row 12, purple water rows 13–17), dark under-earth
  rows 18–22, HUD rows 23–24.
- **screen3 — village gate**: same bands; torii gate cols 13–28 (red beams
  color 2, white posts color 1, black bases), banner chars under the beam.
- **screen1 — temple interior (platform room / boss)**: ceiling beam row 0,
  pillars cols 2/19/37, shoji panels, hanging lanterns, wooden platforms
  (plank chars, yellow top edge), plank floor rows 17–18, stones below.

## 5. Sprite

`sprite.asm` = the current small player recreated 1:1 (24×21 multicolor,
white gi / black hair & belt / skin). Keep your existing animation frames;
only the colors above matter.

## 6. HUD

Row 24: `KARATEGAI` (hires font chars, color 7 yellow), 5 hearts
(multicolor `ch_heart`, color 2 red), `LVL:1`. Row 23 blank black spacer.
Font glyphs included for K A R T E G I L V : 1 only — add glyphs the same
way if you need more (hires, 2px stroke).

## 7. Files

- `charset.asm` — 64 chars, labeled `ch_<name>`, indices in `CHARSET_MAP.md`
- `screens.asm` — `screen{A|B}{1|2|3}_chars` + `_color`, 1000 bytes each
- `sprite.asm` — `sprite_player`, 64 bytes
- `png/screen{A|B}{1|2|3}-1x.png` — exact 320×200 reference (also -3x)
- `png/charset-sheet.png`, `png/sprite-player.png`

## 8. Memory budget

Charset 512 B + 6 screen/color maps 6 KB (or generate from band descriptors
for the scroller) + sprite 64 B. Everything fits alongside a standard
double-buffered scroll setup.
