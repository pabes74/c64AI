// Temple Interior — Level 2
// Jumped to from game.asm when player enters the open door.
// Platform-based interior layout. No scrolling. No gameplay yet — movement only.
// Reuses charset at $2800, sprite bitmaps at $3000+, key routines, and pose
// state machine from game.asm (all in scope via single-pass assembly).

.const TI_SCR   = $0400         // screen RAM base
.const TI_COL   = $d800         // color RAM base
.const TI_COLS  = 40            // screen width

// Color RAM values:
//   bit 3 = 1 → multicolor char: %11 pixel-pair = bits 2-0 of color byte
//   bit 3 = 0 → hi-res char: 0-bit=$d021, 1-bit=full nibble
.const TI_CCEIL  = $09          // MC + brown  — ceiling / walls
.const TI_CFLOOR = $0f          // MC + yellow — road-texture floor
.const TI_CGRASS = $05          // hi-res green — grass accent strip
.const TI_CBASE  = $09          // MC + brown  — floor base row
.const TI_CPLAT  = $0f          // MC + yellow — platform tiles
.const TI_CWALL  = $09          // MC + brown  — left/right wall columns
.const TI_CAIR   = $00          // black — invisible against black $d021

// Player spawn: bottom-left, Y MUST equal GAME_SPRITE0_Y so that
// update_jump_motion and pose_finish reset the sprite to the correct ground Y.
.const TI_PLAYER_X  = 48        // screen col 3 (just inside left wall at col 0)
.const TI_PLAYER_Y  = GAME_SPRITE0_Y  // = 150; sprite bottom = raster 170 = row 14/15 boundary

// Zero-page temps for the wall-draw loop (safe — no return to game.asm)
.const TI_PTR_S  = $f0          // 2-byte screen row pointer
.const TI_PTR_C  = $f2          // 2-byte color row pointer
.const TI_CTR    = $f4          // 1-byte loop counter

// ZP scratch reused after init (safe — same addresses as TI_PTR_S/C/CTR):
.const TI_XHI    = $f0          // temp: sprite X hi-bit during column calc
.const TI_PCOL   = $f1          // current sprite column (0–39)
.const TI_BESTY  = $f2          // best Y candidate in platform surface search
.const TI_TEMPY  = $f3          // sprite Y at start of jump landing check
.const TI_GRAV   = $f4          // gravity fall target Y

// Sprite Y when standing on each platform row (50 + row×8 - 20):
.const TI_P1_Y   = 86           // row  7 platform
.const TI_P2_Y   = 102          // row  9 platform
.const TI_P3_Y   = 118          // row 11 platform
.const TI_P4_Y   = 134          // row 13 platform (P4 and P5 share this row)

* = $7600

temple_interior_start:
    // --- Interior color palette (dark cave, stone walls, gold floors) ---
    lda #$00
    sta $d021               // black background (air/empty space)
    lda #$09                // %01 pixel-pairs = brown (wall accent)
    sta $d022
    lda #$07                // %10 pixel-pairs = yellow (floor sheen)
    sta $d023
    // $d018 = $1A already set by charview (screen $0400, charset $2800) — no change needed

    // --- Clear screen RAM $0400-$07e7 to TILE_SKY ($00 = transparent/black air) ---
    lda #TILE_SKY
    ldx #$00
ti_clrs_pg012:
    sta $0400,x
    sta $0500,x
    sta $0600,x
    inx
    bne ti_clrs_pg012
    ldx #$00
ti_clrs_pg3:
    sta $0700,x
    inx
    cpx #$e8                // 232 bytes covers rows 21-24 partial; ends at $07e7
    bne ti_clrs_pg3

    // --- Clear color RAM $d800-$dbe7 ---
    lda #TI_CAIR
    ldx #$00
ti_clrc_pg012:
    sta $d800,x
    sta $d900,x
    sta $da00,x
    inx
    bne ti_clrc_pg012
    ldx #$00
ti_clrc_pg3:
    sta $db00,x
    inx
    cpx #$e8
    bne ti_clrc_pg3

    // --- Ceiling: rows 0 and 1, full 40-column width ---
    lda #TILE_PILLAR
    ldx #$00
ti_ceil_tiles:
    sta TI_SCR + 0*40,x
    sta TI_SCR + 1*40,x
    inx
    cpx #TI_COLS
    bne ti_ceil_tiles
    lda #TI_CCEIL
    ldx #$00
ti_ceil_colors:
    sta TI_COL + 0*40,x
    sta TI_COL + 1*40,x
    inx
    cpx #TI_COLS
    bne ti_ceil_colors

    // --- Floor: rows 15-18 ---
    // Row 15 is the ground row: sprite at Y=150 has bottom at raster 170,
    // which is the last raster of char row 14. Row 15 tiles sit directly below.
    ldx #$00
ti_floor_tiles:
    lda #TILE_ROAD
    sta TI_SCR + 15*40,x
    sta TI_SCR + 16*40,x
    lda #TILE_GRASS_FILL
    sta TI_SCR + 17*40,x
    lda #TILE_PILLAR
    sta TI_SCR + 18*40,x
    inx
    cpx #TI_COLS
    bne ti_floor_tiles
    ldx #$00
ti_floor_colors:
    lda #TI_CFLOOR
    sta TI_COL + 15*40,x
    sta TI_COL + 16*40,x
    lda #TI_CGRASS
    sta TI_COL + 17*40,x
    lda #TI_CBASE
    sta TI_COL + 18*40,x
    inx
    cpx #TI_COLS
    bne ti_floor_colors

    // --- Left wall (col 0) and right wall (col 39): rows 2-14 (above the floor) ---
    lda #<(TI_SCR + 2*40)
    sta TI_PTR_S
    lda #>(TI_SCR + 2*40)
    sta TI_PTR_S+1
    lda #<(TI_COL + 2*40)
    sta TI_PTR_C
    lda #>(TI_COL + 2*40)
    sta TI_PTR_C+1
    lda #13                 // rows 2..14 inclusive = 13 rows
    sta TI_CTR
ti_wall_loop:
    lda #TILE_PILLAR
    ldy #0
    sta (TI_PTR_S),y        // left wall col 0
    ldy #39
    sta (TI_PTR_S),y        // right wall col 39
    lda #TI_CWALL
    ldy #0
    sta (TI_PTR_C),y
    ldy #39
    sta (TI_PTR_C),y
    clc
    lda TI_PTR_S
    adc #40
    sta TI_PTR_S
    bcc ti_wall_s_ok
    inc TI_PTR_S+1
ti_wall_s_ok:
    clc
    lda TI_PTR_C
    adc #40
    sta TI_PTR_C
    bcc ti_wall_c_ok
    inc TI_PTR_C+1
ti_wall_c_ok:
    dec TI_CTR
    bne ti_wall_loop

    // --- Platforms (five, staggered at jump-reachable heights) ---
    // Jump peak: sprite Y min = 126 → sprite bottom at raster 146 ≈ row 11.9.
    // Rows 7-13 offer interesting variation; all are reachable or near-reachable.

    // Platform 1: row 7,  cols  5-14  (10 tiles — high left)
    lda #TILE_ROAD
    ldx #5
ti_p1:
    sta TI_SCR + 7*40,x
    inx
    cpx #15
    bne ti_p1
    lda #TI_CPLAT
    ldx #5
ti_p1c:
    sta TI_COL + 7*40,x
    inx
    cpx #15
    bne ti_p1c

    // Platform 2: row 9,  cols 22-32  (11 tiles — high right)
    lda #TILE_ROAD
    ldx #22
ti_p2:
    sta TI_SCR + 9*40,x
    inx
    cpx #33
    bne ti_p2
    lda #TI_CPLAT
    ldx #22
ti_p2c:
    sta TI_COL + 9*40,x
    inx
    cpx #33
    bne ti_p2c

    // Platform 3: row 11, cols  8-18  (11 tiles — center mid)
    lda #TILE_ROAD
    ldx #8
ti_p3:
    sta TI_SCR + 11*40,x
    inx
    cpx #19
    bne ti_p3
    lda #TI_CPLAT
    ldx #8
ti_p3c:
    sta TI_COL + 11*40,x
    inx
    cpx #19
    bne ti_p3c

    // Platform 4: row 13, cols  2-10   (9 tiles — low left)
    lda #TILE_ROAD
    ldx #2
ti_p4:
    sta TI_SCR + 13*40,x
    inx
    cpx #11
    bne ti_p4
    lda #TI_CPLAT
    ldx #2
ti_p4c:
    sta TI_COL + 13*40,x
    inx
    cpx #11
    bne ti_p4c

    // Platform 5: row 13, cols 28-36   (9 tiles — low right)
    lda #TILE_ROAD
    ldx #28
ti_p5:
    sta TI_SCR + 13*40,x
    inx
    cpx #37
    bne ti_p5
    lda #TI_CPLAT
    ldx #28
ti_p5c:
    sta TI_COL + 13*40,x
    inx
    cpx #37
    bne ti_p5c

    // --- HUD: player life hearts at row 24, col 10 ---
    jsr draw_hud_life

    // --- Reset pose / animation state (clear any leftover boss-fight state) ---
    lda #$00
    sta pose_timer
    sta pose_mode
    sta pose_tick_counter
    sta jump_step
    lda #ANIM_DIR_RIGHT
    sta anim_dir
    jsr reset_anim_state    // sets sprite frame, anim_frame, anim_timer, anim_last_jiffy

    lda $a2
    sta movement_last_jiffy // prevent immediate scroll tick on entry

    // --- Place player sprite at bottom-left ---
    lda #$00
    sta $d010               // clear all sprite X MSBs
    lda #TI_PLAYER_X
    sta $d000               // sprite 0 X
    lda #TI_PLAYER_Y        // = 150 — matches pose_finish ground reset
    sta $d001               // sprite 0 Y
    lda #GAME_SPRITE0_Y
    sta player_ground_y     // always start on the floor
    // sprite frame already set by reset_anim_state above

    // Sprite 0 on, Kuro sprite 5 off
    lda $d015
    ora #%00000001
    and #%11011111
    sta $d015
    lda $d01c
    ora #%00000001
    sta $d01c

    // -------------------------------------------------------------------------
    // Main movement loop — mirrors arena_input from game.asm
    // -------------------------------------------------------------------------
ti_main_loop:
    jsr update_pose_state   // processes Space/W/S; returns A=1 while pose active
    beq ti_input_ready      // A=0: no active pose → handle walk/idle input

    // pose is active: if it's a jump, check for mid-air platform landing
    lda pose_mode
    cmp #POSE_MODE_JUMP
    bne ti_main_loop        // non-jump pose: keep spinning
    lda jump_step
    cmp #13
    bcc ti_main_loop        // ascending (steps 0–12): nothing to land on yet
    jsr ti_check_jump_landing
    jmp ti_main_loop

ti_input_ready:

    // --- D key: move right ---
    jsr key_d_pressed
    beq ti_check_a

    jsr movement_tick_ready
    beq ti_main_loop

    lda $d010
    and #%00000001
    bne ti_d_msb            // MSB already set: handle extended X range
    lda $d000
    cmp #(256-2)            // about to overflow the low byte?
    bcs ti_d_setmsb
    clc
    adc #$02
    sta $d000
    jmp ti_d_anim
ti_d_setmsb:
    sec
    sbc #(256-2)
    sta $d000
    lda $d010
    ora #%00000001
    sta $d010
    jmp ti_d_anim
ti_d_msb:
    lda $d000
    cmp #88                 // right limit: pixel 344 (X=88 with MSB=1)
    bcs ti_d_done
    clc
    adc #$02
    cmp #89
    bcc ti_d_store
    lda #88
ti_d_store:
    sta $d000
ti_d_anim:
    jsr set_anim_right
    jsr sfx_walk
    jsr run_anim
    jsr ti_check_gravity    // fall if sprite stepped off a platform edge
ti_d_done:
    jmp ti_main_loop

    // --- A key: move left ---
ti_check_a:
    jsr key_a_pressed
    beq ti_no_input

    jsr movement_tick_ready
    beq ti_main_loop

    lda $d010
    and #%00000001
    bne ti_a_msb
    lda $d000
    cmp #26                 // left limit: pixel 24
    bcc ti_main_loop
    sec
    sbc #$02
    sta $d000
    jmp ti_a_anim
ti_a_msb:
    lda $d000
    sec
    sbc #$02
    bcc ti_a_cross
    sta $d000
    jmp ti_a_anim
ti_a_cross:
    sta $d000
    lda $d010
    and #%11111110
    sta $d010
ti_a_anim:
    jsr set_anim_left
    jsr sfx_walk
    jsr run_anim
    jsr ti_check_gravity    // fall if sprite stepped off a platform edge
    jmp ti_main_loop

    // --- No input ---
ti_no_input:
    jsr sfx_walk_stop
    jsr set_idle_frame
    jmp ti_main_loop


// ============================================================
// ti_get_sprite_col — compute sprite center column → TI_PCOL_CHECK
// Input:  $d000 (sprite X lo), $d010 bit 0 (sprite X MSB)
// Output: TI_COL = column 0–39 (column under sprite center)
// Clobbers: A, TI_XHI
// ============================================================
ti_get_sprite_col:
    lda $d010
    and #%00000001
    sta TI_XHI
    lda $d000
    sec
    sbc #12             // sprite center = X+12; (center − 24) = X − 12
    bcs ti_gsc_ok
    dec TI_XHI
ti_gsc_ok:
    lsr TI_XHI          // 9-bit right-shift ×3  =  ÷8
    ror
    lsr TI_XHI
    ror
    lsr TI_XHI
    ror
    sta TI_PCOL_CHECK
    rts


// ============================================================
// ti_find_surface_y — find nearest platform/floor surface Y
// that is >= player_ground_y at the current sprite X column.
// The floor (Y=150) is always a valid surface.
// Input:  player_ground_y, sprite X ($d000/$d010)
// Output: A = surface Y  (>= player_ground_y)
// Clobbers: TI_XHI, TI_COL, TI_BESTY
// ============================================================
ti_find_surface_y:
    jsr ti_get_sprite_col
    lda #GAME_SPRITE0_Y     // floor is always the default surface
    sta TI_BESTY

    // Platform 1: row 7, Y=86, cols 5–14
    lda TI_PCOL_CHECK
    cmp #5
    bcc ti_fsy2
    cmp #15
    bcs ti_fsy2
    lda #TI_P1_Y
    cmp player_ground_y
    bcc ti_fsy2             // P1 is above player: can't fall to it
    cmp TI_BESTY
    bcs ti_fsy2             // not a better (closer) surface
    sta TI_BESTY
ti_fsy2:
    // Platform 2: row 9, Y=102, cols 22–32
    lda TI_PCOL_CHECK
    cmp #22
    bcc ti_fsy3
    cmp #33
    bcs ti_fsy3
    lda #TI_P2_Y
    cmp player_ground_y
    bcc ti_fsy3
    cmp TI_BESTY
    bcs ti_fsy3
    sta TI_BESTY
ti_fsy3:
    // Platform 3: row 11, Y=118, cols 8–18
    lda TI_PCOL_CHECK
    cmp #8
    bcc ti_fsy4
    cmp #19
    bcs ti_fsy4
    lda #TI_P3_Y
    cmp player_ground_y
    bcc ti_fsy4
    cmp TI_BESTY
    bcs ti_fsy4
    sta TI_BESTY
ti_fsy4:
    // Platform 4: row 13, Y=134, cols 2–10
    lda TI_PCOL_CHECK
    cmp #2
    bcc ti_fsy5
    cmp #11
    bcs ti_fsy5
    lda #TI_P4_Y
    cmp player_ground_y
    bcc ti_fsy5
    cmp TI_BESTY
    bcs ti_fsy5
    sta TI_BESTY
ti_fsy5:
    // Platform 5: row 13, Y=134, cols 28–36
    lda TI_PCOL_CHECK
    cmp #28
    bcc ti_fsy_done
    cmp #37
    bcs ti_fsy_done
    lda #TI_P4_Y
    cmp player_ground_y
    bcc ti_fsy_done
    cmp TI_BESTY
    bcs ti_fsy_done
    sta TI_BESTY
ti_fsy_done:
    lda TI_BESTY
    rts


// ============================================================
// ti_check_jump_landing — called each frame while POSE_MODE_JUMP
// is active and jump_step >= 13 (descending arc).  Finds the
// topmost platform the sprite has just reached and, if found,
// calls pose_finish to end the jump and land there.
// Input:  jump_step, $d001, player_ground_y, sprite X
// Clobbers: A, TI_XHI, TI_COL, TI_BESTY, TI_TEMPY
// ============================================================
ti_check_jump_landing:
    lda $d001
    sta TI_TEMPY                // current sprite Y (descending)

    jsr ti_get_sprite_col       // → TI_PCOL_CHECK

    // Search for the platform with the SMALLEST y_stand that:
    //   • is above the starting ground (y_stand < player_ground_y)
    //   • sprite has reached or passed  (TI_TEMPY >= y_stand)
    // Sentinel: TI_BESTY = player_ground_y (means "nothing found").
    lda player_ground_y
    sta TI_BESTY

    // Platform 1: Y=86, cols 5–14
    lda TI_PCOL_CHECK
    cmp #5
    bcc ti_cjl2
    cmp #15
    bcs ti_cjl2
    lda #TI_P1_Y
    cmp player_ground_y
    bcs ti_cjl2                 // P1 >= player_ground_y → not above starting ground
    lda TI_TEMPY
    cmp #TI_P1_Y
    bcc ti_cjl2                 // sprite still above P1 level
    lda #TI_P1_Y
    cmp TI_BESTY
    bcs ti_cjl2                 // not a better (higher) platform
    sta TI_BESTY
ti_cjl2:
    // Platform 2: Y=102, cols 22–32
    lda TI_PCOL_CHECK
    cmp #22
    bcc ti_cjl3
    cmp #33
    bcs ti_cjl3
    lda #TI_P2_Y
    cmp player_ground_y
    bcs ti_cjl3
    lda TI_TEMPY
    cmp #TI_P2_Y
    bcc ti_cjl3
    lda #TI_P2_Y
    cmp TI_BESTY
    bcs ti_cjl3
    sta TI_BESTY
ti_cjl3:
    // Platform 3: Y=118, cols 8–18
    lda TI_PCOL_CHECK
    cmp #8
    bcc ti_cjl4
    cmp #19
    bcs ti_cjl4
    lda #TI_P3_Y
    cmp player_ground_y
    bcs ti_cjl4
    lda TI_TEMPY
    cmp #TI_P3_Y
    bcc ti_cjl4
    lda #TI_P3_Y
    cmp TI_BESTY
    bcs ti_cjl4
    sta TI_BESTY
ti_cjl4:
    // Platform 4: Y=134, cols 2–10
    lda TI_PCOL_CHECK
    cmp #2
    bcc ti_cjl5
    cmp #11
    bcs ti_cjl5
    lda #TI_P4_Y
    cmp player_ground_y
    bcs ti_cjl5
    lda TI_TEMPY
    cmp #TI_P4_Y
    bcc ti_cjl5
    lda #TI_P4_Y
    cmp TI_BESTY
    bcs ti_cjl5
    sta TI_BESTY
ti_cjl5:
    // Platform 5: Y=134, cols 28–36
    lda TI_PCOL_CHECK
    cmp #28
    bcc ti_cjl_check
    cmp #37
    bcs ti_cjl_check
    lda #TI_P4_Y
    cmp player_ground_y
    bcs ti_cjl_check
    lda TI_TEMPY
    cmp #TI_P4_Y
    bcc ti_cjl_check
    lda #TI_P4_Y
    cmp TI_BESTY
    bcs ti_cjl_check
    sta TI_BESTY
ti_cjl_check:
    lda TI_BESTY
    cmp player_ground_y
    beq ti_cjl_done             // sentinel unchanged → no platform reached
    // Land on the platform: set player_ground_y first so pose_finish uses it
    sta player_ground_y
    jsr pose_finish             // ends jump pose, snaps $d001 to player_ground_y
ti_cjl_done:
    rts


// ============================================================
// ti_check_gravity — after a horizontal walk step, check if the
// sprite is still above a valid surface.  If it has walked off a
// platform edge, animate a fall to the nearest surface below.
// Input:  player_ground_y, sprite X ($d000/$d010)
// Clobbers: A, TI_XHI, TI_COL, TI_BESTY, TI_GRAV
// ============================================================
ti_check_gravity:
    jsr ti_find_surface_y       // A = nearest surface Y >= player_ground_y
    cmp player_ground_y
    beq ti_cg_done              // same surface → sprite is still on solid ground
    // Surface is lower: sprite walked off an edge; fall to A
    sta TI_GRAV
ti_grav_loop:
    sei
    jsr wait_frame_safe_window
    cli
    lda $d001
    clc
    adc #4                      // fall 4 px per frame
    cmp TI_GRAV
    bcc ti_grav_move            // not yet at landing surface
    lda TI_GRAV                 // snap to surface
    sta $d001
    sta player_ground_y
    rts
ti_grav_move:
    sta $d001
    jmp ti_grav_loop
ti_cg_done:
    rts
