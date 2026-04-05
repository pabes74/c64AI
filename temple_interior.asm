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

// --- Flying-knife gameplay constants ---
// 10 knives total: 5 × knife1 fly right→left, 5 × knife2 fly left→right.
// Both sets span a 30-second window (1500 jiffies PAL).
// Sprite slots used: sprites 1–7 (7 hardware sprites shared as a pool).
// At most ~2 of each type are in flight simultaneously given the spawn gaps,
// so 7 pool slots comfortably cover all overlaps.

.const TI_POOL_SIZE      = 7            // total sprite slots in shared knife pool
.const TI_KNIFE1_COUNT   = 5            // right→left knives (knife1 sprite)
.const TI_KNIFE2_COUNT   = 5            // left→right knives (knife2 sprite)
.const TI_KNIFE_SPEED    = 3            // pixels per jiffy tick (both directions)
.const TI_KNIFE_DURATION = 1500         // jiffy ticks for the full 30-second window
.const TI_KNIFE_HIT_DX   = 12          // horizontal hit radius (pixels)
.const TI_KNIFE_HIT_DY   = 10          // vertical hit radius (pixels)

// Direction flags stored per slot
.const TI_KDIR_RL = 0                  // right → left  (knife1)
.const TI_KDIR_LR = 1                  // left  → right (knife2)

// knife2 left-edge start: pixel X = 24 (just inside left wall), MSB=0
.const TI_K2_START_X_LO = 24
.const TI_K2_START_X_HI = 0
// knife2 deactivation threshold: X > 344 (MSB=1 and lo > $58)
.const TI_K2_END_X_LO   = $58          // = 88, same as right-edge limit

// Playable Y band: top of ceiling row 2 ends at raster ≈ 26+16=42; add sprite
// half-height (10px) so the knife centre never overlaps the ceiling tile.
// Floor Y = 150 (GAME_SPRITE0_Y).  The 5 platform stand-Y values cover the
// range: 86, 102, 118, 134, 150 — use these as the valid knife heights.
.const TI_KY_1 = 86             // top platform height (row 7)
.const TI_KY_2 = 102            // platform row 9
.const TI_KY_3 = 118            // platform row 11
.const TI_KY_4 = 134            // platform row 13
.const TI_KY_5 = 150            // floor height

// Knife state values
.const TI_KS_INACTIVE = 0
.const TI_KS_ACTIVE   = 1

// --- Exit door constants ---
// Door appears on the right side of the temple floor after the 30-second knife window.
// Matches the game.asm temple door profile: 4 cols × 3 rows.
// Position: cols 32–35, rows 12–14 (sits directly above the floor at row 15).
// Color: $03 = cyan (hi-res, non-multicolor).
.const TI_DOOR_COL_L  = 32              // leftmost column of door
.const TI_DOOR_COL_R  = 35              // rightmost column of door  (inclusive)
.const TI_DOOR_ROW_T  = 12             // top row of door
.const TI_DOOR_ROW_B  = 14             // bottom row of door (inclusive)
.const TI_DOOR_COLOR  = $03            // cyan (hi-res char mode)
// Player column range that overlaps the door (sprite center must be cols 30–37)
.const TI_DOOR_HIT_COL_L = 30
.const TI_DOOR_HIT_COL_R = 37

// Sprite enable/disable bit masks for sprites 1–7 (pool slots 0–6)
.const TI_SMASK_1 = %00000010   // sprite 1
.const TI_SMASK_2 = %00000100   // sprite 2
.const TI_SMASK_3 = %00001000   // sprite 3
.const TI_SMASK_4 = %00010000   // sprite 4
.const TI_SMASK_5 = %00100000   // sprite 5
.const TI_SMASK_6 = %01000000   // sprite 6
.const TI_SMASK_7 = %10000000   // sprite 7

// Sprite Y when standing on each platform row (50 + row×8 - 20):
.const TI_P1_Y   = 86           // row  7 platform
.const TI_P2_Y   = 102          // row  9 platform
.const TI_P3_Y   = 118          // row 11 platform
.const TI_P4_Y   = 134          // row 13 platform (P4 and P5 share this row)

* = $7800

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

    // --- HUD: full player HUD (name label + life hearts) at row 24 ---
    jsr init_hud

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

    // --- Initialise flying-knife subsystem ---
    jsr ti_init_knives

    // -------------------------------------------------------------------------
    // Main movement loop — mirrors arena_input from game.asm
    // -------------------------------------------------------------------------
ti_main_loop:
    jsr ti_update_knives        // advance active knives, spawn new ones on schedule
    jsr ti_check_knife_hit      // detect knife–player collision
    jsr ti_check_door_hit       // detect player touching exit door → show LEVEL 2
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
    bcs ti_a_do_move        // above left limit: proceed
    jmp ti_main_loop        // at/below limit: skip move
ti_a_do_move:
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
// ti_get_sprite_col — compute sprite center column → TI_PCOL
// Input:  $d000 (sprite X lo), $d010 bit 0 (sprite X MSB)
// Output: TI_PCOL = column 0–39 (column under sprite center)
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
    sta TI_PCOL
    rts


// ============================================================
// ti_find_surface_y — find nearest platform/floor surface Y
// that is >= player_ground_y at the current sprite X column.
// The floor (Y=150) is always a valid surface.
// Input:  player_ground_y, sprite X ($d000/$d010)
// Output: A = surface Y  (>= player_ground_y)
// Clobbers: TI_XHI, TI_PCOL, TI_BESTY
// ============================================================
ti_find_surface_y:
    jsr ti_get_sprite_col
    lda #GAME_SPRITE0_Y     // floor is always the default surface
    sta TI_BESTY

    // Platform 1: row 7, Y=86, cols 5–14
    lda TI_PCOL
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
    lda TI_PCOL
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
    lda TI_PCOL
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
    lda TI_PCOL
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
    lda TI_PCOL
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
// Clobbers: A, TI_XHI, TI_PCOL, TI_BESTY, TI_TEMPY
// ============================================================
ti_check_jump_landing:
    lda $d001
    sta TI_TEMPY                // current sprite Y (descending)

    jsr ti_get_sprite_col       // → TI_PCOL

    // Search for the platform with the SMALLEST y_stand that:
    //   • is above the starting ground (y_stand < player_ground_y)
    //   • sprite has reached or passed  (TI_TEMPY >= y_stand)
    // Sentinel: TI_BESTY = player_ground_y (means "nothing found").
    lda player_ground_y
    sta TI_BESTY

    // Platform 1: Y=86, cols 5–14
    lda TI_PCOL
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
    lda TI_PCOL
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
    lda TI_PCOL
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
    lda TI_PCOL
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
    lda TI_PCOL
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
// Clobbers: A, TI_XHI, TI_PCOL, TI_BESTY, TI_GRAV
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


// ============================================================
// ti_init_knives — reset all pool slots, disable sprites 1–7,
//                  seed the jiffy timer and both spawn pointers.
// ============================================================
ti_init_knives:
    // disable sprites 1–7 (keep sprite 0 = player)
    lda $d015
    and #%00000001              // clear bits 1–7
    sta $d015

    // clear all pool slots
    ldx #TI_POOL_SIZE - 1
ti_ik_clear:
    lda #TI_KS_INACTIVE
    sta ti_knife_state,x
    dex
    bpl ti_ik_clear

    // snapshot current jiffy counter as the window start
    lda $a2
    sta ti_knife_last_jiffy
    lda #$00
    sta ti_window_jiffy_lo
    sta ti_window_jiffy_hi
    sta ti_k1_next              // next knife1 index to spawn (0–4)
    sta ti_k2_next              // next knife2 index to spawn (0–4)
    sta ti_door_visible         // exit door not yet shown

    rts


// ============================================================
// ti_update_knives — call once per main-loop iteration.
//   • Advances 16-bit elapsed jiffy counter.
//   • Spawns next knife1 (R→L) and/or knife2 (L→R) on schedule.
//   • Moves all active pool slots in their respective directions.
//   • Deactivates slots that have left the screen.
// Uses: A, X, Y.
// ============================================================
ti_update_knives:
    // --- Advance elapsed jiffy counter once per tick ---
    lda $a2
    cmp ti_knife_last_jiffy
    bne ti_uk_tick
    jmp ti_uk_no_tick
ti_uk_tick:
    sta ti_knife_last_jiffy

    inc ti_window_jiffy_lo
    bne ti_uk_spawns
    inc ti_window_jiffy_hi

ti_uk_spawns:
    // --- Spawn next knife1 (R→L) if scheduled ---
    ldx ti_k1_next
    cpx #TI_KNIFE1_COUNT
    bcs ti_uk_chk_k2            // all 5 knife1 already spawned

    lda ti_window_jiffy_hi
    cmp ti_k1_spawn_hi,x
    bcc ti_uk_chk_k2
    bne ti_uk_do_k1
    lda ti_window_jiffy_lo
    cmp ti_k1_spawn_lo,x
    bcc ti_uk_chk_k2

ti_uk_do_k1:
    lda ti_k1_heights,x         // height for this knife1
    sta ti_temp2                // stash Y
    lda #TI_KDIR_RL
    jsr ti_spawn_knife          // A=direction, ti_temp2=Y; returns, slot stored internally
    inc ti_k1_next

    // --- Spawn next knife2 (L→R) if scheduled ---
ti_uk_chk_k2:
    ldx ti_k2_next
    cpx #TI_KNIFE2_COUNT
    bcs ti_uk_move              // all 5 knife2 already spawned

    lda ti_window_jiffy_hi
    cmp ti_k2_spawn_hi,x
    bcc ti_uk_move
    bne ti_uk_do_k2
    lda ti_window_jiffy_lo
    cmp ti_k2_spawn_lo,x
    bcc ti_uk_move

ti_uk_do_k2:
    lda ti_k2_heights,x         // height for this knife2
    sta ti_temp2
    lda #TI_KDIR_LR
    jsr ti_spawn_knife
    inc ti_k2_next

    // --- Move all active pool slots ---
ti_uk_move:
    ldx #$00
ti_uk_move_loop:
    lda ti_knife_state,x
    cmp #TI_KS_ACTIVE
    bne ti_uk_move_next

    lda ti_knife_dir,x
    cmp #TI_KDIR_LR
    beq ti_uk_move_lr

    // --- R→L: subtract speed, deactivate when X goes negative ---
    lda ti_knife_x_lo,x
    sec
    sbc #TI_KNIFE_SPEED
    sta ti_knife_x_lo,x
    lda ti_knife_x_hi,x
    sbc #$00
    sta ti_knife_x_hi,x
    bmi ti_uk_deactivate        // high byte went negative: off left edge
    jsr ti_update_knife_sprite
    jmp ti_uk_move_next

    // --- L→R: add speed, deactivate when X > 344 (hi=1, lo>$58) ---
ti_uk_move_lr:
    lda ti_knife_x_lo,x
    clc
    adc #TI_KNIFE_SPEED
    sta ti_knife_x_lo,x
    lda ti_knife_x_hi,x
    adc #$00
    sta ti_knife_x_hi,x
    // off right edge: hi=1 AND lo >= $59
    cmp #$01
    bcc ti_uk_lr_ok             // hi=0: still on screen
    bne ti_uk_deactivate        // hi>1: way off screen
    lda ti_knife_x_lo,x
    cmp #(TI_K2_END_X_LO + 1)
    bcs ti_uk_deactivate        // lo >= $59: past right edge
ti_uk_lr_ok:
    jsr ti_update_knife_sprite
    jmp ti_uk_move_next

ti_uk_deactivate:
    lda #TI_KS_INACTIVE
    sta ti_knife_state,x
    jsr ti_disable_knife_sprite

ti_uk_move_next:
    inx
    cpx #TI_POOL_SIZE
    bne ti_uk_move_loop

    // --- Reveal exit door once the 30-second knife window has elapsed ---
    lda ti_door_visible
    bne ti_uk_no_tick           // already drawn
    lda ti_window_jiffy_hi
    cmp #>TI_KNIFE_DURATION
    bcc ti_uk_no_tick           // not yet 1500 jiffies
    jsr ti_draw_exit_door

ti_uk_no_tick:
    rts


// ============================================================
// ti_spawn_knife — find a free pool slot and activate a knife.
// Input:  A = direction (TI_KDIR_RL or TI_KDIR_LR)
//         ti_temp2 = sprite Y (height)
// Clobbers: A, X, Y, ti_temp, ti_temp2.
// ============================================================
ti_spawn_knife:
    sta ti_temp                 // save direction

    // find first inactive slot
    ldx #$00
ti_sk_find:
    lda ti_knife_state,x
    cmp #TI_KS_INACTIVE
    beq ti_sk_found
    inx
    cpx #TI_POOL_SIZE
    bne ti_sk_find
    rts                         // no free slot: skip spawn (extremely rare)

ti_sk_found:
    lda #TI_KS_ACTIVE
    sta ti_knife_state,x
    lda ti_temp
    sta ti_knife_dir,x          // store direction flag

    // set Y from ti_temp2
    lda ti_temp2
    sta ti_knife_y,x

    // set starting X based on direction
    lda ti_temp
    cmp #TI_KDIR_LR
    beq ti_sk_lr_start

    // R→L: start at pixel 344 (MSB=1, lo=$58)
    lda #$58
    sta ti_knife_x_lo,x
    lda #$01
    sta ti_knife_x_hi,x
    lda #KNIFE_PTR
    jmp ti_sk_set_ptr

    // L→R: start at pixel 24 (MSB=0, lo=$18)
ti_sk_lr_start:
    lda #TI_K2_START_X_LO
    sta ti_knife_x_lo,x
    lda #TI_K2_START_X_HI
    sta ti_knife_x_hi,x
    lda #KNIFE2_PTR

ti_sk_set_ptr:
    // sprite number = slot + 1; write sprite pointer at $07f9 + slot
    stx ti_temp
    sta ti_temp2                // save sprite pointer — txa below would clobber A
    txa
    tay
    iny                         // Y = sprite number (1-based)
    lda ti_temp2                // restore sprite pointer (KNIFE_PTR or KNIFE2_PTR)
    sta $07f8,y                 // $07f9–$07ff for sprites 1–7

    // set VIC-II X/Y: sprite N at $d000 + N*2
    tya
    asl
    tay                         // Y = VIC register offset
    ldx ti_temp
    lda ti_knife_x_lo,x
    sta $d000,y
    lda ti_knife_y,x
    sta $d001,y

    // set/clear X MSB in $d010
    lda ti_knife_x_hi,x
    beq ti_sk_msb_clear
    lda $d010
    ora ti_knife_enable_masks,x
    sta $d010
    jmp ti_sk_msb_done
ti_sk_msb_clear:
    lda $d010
    and ti_knife_disable_masks,x
    sta $d010
ti_sk_msb_done:

    // enable sprite in $d015
    lda $d015
    ora ti_knife_enable_masks,x
    sta $d015

    // enable multicolor in $d01c
    lda $d01c
    ora ti_knife_enable_masks,x
    sta $d01c

    // set sprite colour: white ($01)
    ldx ti_temp
    txa
    tay
    iny                         // sprite number
    lda #$01
    sta $d027,y

    ldx ti_temp
    rts


// ============================================================
// ti_update_knife_sprite — write pool slot X's 9-bit X and Y
//   to VIC-II registers.  Sprite number = slot + 1.
// X = pool slot (0–6). Clobbers A, Y; preserves X.
// ============================================================
ti_update_knife_sprite:
    stx ti_temp

    txa
    clc
    adc #$01
    asl
    tay                         // Y = VIC register offset (sprite*2)

    lda ti_knife_x_lo,x
    sta $d000,y
    lda ti_knife_y,x
    sta $d001,y

    lda ti_knife_x_hi,x
    beq ti_uks_clear_msb

    ldx ti_temp
    lda $d010
    ora ti_knife_enable_masks,x
    sta $d010
    ldx ti_temp
    rts

ti_uks_clear_msb:
    ldx ti_temp
    lda $d010
    and ti_knife_disable_masks,x
    sta $d010
    ldx ti_temp
    rts


// ============================================================
// ti_disable_knife_sprite — turn off VIC sprite for pool slot X.
// X = pool slot (0–6). Clobbers A; preserves X.
// ============================================================
ti_disable_knife_sprite:
    lda $d015
    and ti_knife_disable_masks,x
    sta $d015
    lda $d010
    and ti_knife_disable_masks,x
    sta $d010
    rts


// ============================================================
// ti_check_knife_hit — test all active pool slots against player.
//   Collision when:
//     • knife X within TI_KNIFE_HIT_DX of player column (160)
//       for R→L knives (MSB=0 only);
//       for L→R knives the player column is also 160 so same check.
//     • |knife_y - player_y| <= TI_KNIFE_HIT_DY
//   On hit: slot deactivated, start_hit called.
// Clobbers: A, X, Y.
// ============================================================
ti_check_knife_hit:
    lda pose_mode
    cmp #POSE_MODE_HIT
    beq ti_ckh_done
    cmp #POSE_MODE_JUMP
    beq ti_ckh_done

    ldx #$00
ti_ckh_loop:
    lda ti_knife_state,x
    cmp #TI_KS_ACTIVE
    bne ti_ckh_next

    // only collide when MSB=0 (knife visible on-screen, X < 256)
    lda ti_knife_x_hi,x
    bne ti_ckh_next

    // horizontal check: knife_x in [148..172] i.e. GAME_SPRITE0_X ± HIT_DX
    lda ti_knife_x_lo,x
    sec
    sbc #(GAME_SPRITE0_X - TI_KNIFE_HIT_DX)
    bcc ti_ckh_next
    cmp #(TI_KNIFE_HIT_DX * 2 + 1)
    bcs ti_ckh_next

    // vertical check: |knife_y - player_y| <= TI_KNIFE_HIT_DY
    lda ti_knife_y,x
    sec
    sbc $d001
    bcs ti_ckh_pos_dy
    eor #$ff
    clc
    adc #$01
ti_ckh_pos_dy:
    cmp #(TI_KNIFE_HIT_DY + 1)
    bcs ti_ckh_next

    // HIT
    lda #TI_KS_INACTIVE
    sta ti_knife_state,x
    jsr ti_disable_knife_sprite
    jsr start_hit
    jmp ti_ckh_done

ti_ckh_next:
    inx
    cpx #TI_POOL_SIZE
    bne ti_ckh_loop
ti_ckh_done:
    rts


// ============================================================
// ti_draw_exit_door — paint 4×3 door tiles on the right side
//   of the temple floor once the 30-second knife window ends.
//   Tile = TILE_DOOR ($1d, solid block).  Color = TI_DOOR_COLOR
//   ($03 = cyan, hi-res mode).  Sets ti_door_visible = 1.
// Clobbers: A, X.
// ============================================================
ti_draw_exit_door:
    ldx #TI_DOOR_COL_L
ti_ded_col:
    // rows 12, 13, 14 for each column
    lda #TILE_DOOR
    sta TI_SCR + 12*40,x
    sta TI_SCR + 13*40,x
    sta TI_SCR + 14*40,x
    lda #TI_DOOR_COLOR
    sta TI_COL + 12*40,x
    sta TI_COL + 13*40,x
    sta TI_COL + 14*40,x
    inx
    cpx #(TI_DOOR_COL_R + 1)
    bne ti_ded_col

    lda #$01
    sta ti_door_visible
    rts


// ============================================================
// ti_check_door_hit — if door is visible and player column
//   overlaps it while on the floor, trigger ti_show_level2.
// Input:  ti_door_visible, player_ground_y, sprite X ($d000/$d010)
// Clobbers: A, X, Y (via ti_get_sprite_col).
// ============================================================
ti_check_door_hit:
    lda ti_door_visible
    beq ti_cdh_done             // door not visible yet

    // player must be on the floor (not on a raised platform)
    lda player_ground_y
    cmp #GAME_SPRITE0_Y
    bne ti_cdh_done

    jsr ti_get_sprite_col       // → TI_PCOL
    lda TI_PCOL
    cmp #TI_DOOR_HIT_COL_L
    bcc ti_cdh_done
    cmp #(TI_DOOR_HIT_COL_R + 1)
    bcs ti_cdh_done

    jsr ti_show_level2          // show message and wait for space

ti_cdh_done:
    rts


// ============================================================
// ti_show_level2 — full black screen with "LEVEL 2" in white,
//   identical approach to game_over in game.asm.
//   Waits for Space, then jumps to game_start.
// Clobbers: A, X, Y.
// ============================================================
ti_show_level2:
    // disable all sprites
    lda #$00
    sta $d015

    // black border + background
    lda #$00
    sta $d020
    sta $d021

    // switch to ROM uppercase charset + disable multicolor (mirrors game_over)
    lda #$14                    // screen $0400, charset $1000 (ROM upper)
    sta $d018
    lda $d016
    and #%11101111              // clear multicolor bit
    sta $d016

    // clear entire screen via KERNAL (same as game_over)
    jsr $e544

    // write "LEVEL " (6 chars) centred on row 12, cols 16–22 (7 chars total)
    // $0400 + 12*40 + 16 = $05f0   color: $d800 + 12*40 + 16 = $d9f0
    // ROM uppercase PETSCII screen codes: L=$0c E=$05 V=$16 E=$05 L=$0c sp=$20
    ldx #$00
ti_sl2_text:
    lda ti_level2_text,x
    sta $05f0,x
    lda #$01                    // white text
    sta $d9f0,x
    inx
    cpx #6                      // 6 chars: "LEVEL "
    bne ti_sl2_text

    // increment level counter and write the digit (col 22 = $05f6)
    inc ti_level_num
    lda ti_level_num
    sta $05f6                   // 7th char position
    lda #$01
    sta $d9f6

    // wait for space bar
ti_sl2_wait:
    jsr key_space_pressed
    beq ti_sl2_wait             // 0 = not pressed; loop until pressed

    // advance level counter — hero exits the temple, so the next scrolling
    // section begins at the incremented level
    inc current_level

    // jump back to game — game_start fully re-initialises VIC-II / state
    jmp game_start

ti_level2_text:
    // "LEVEL " in ROM uppercase PETSCII screen codes (digit written separately)
    .byte $0c,$05,$16,$05,$0c,$20


// ============================================================
// Knife subsystem data tables
// ============================================================

// --- knife1 (R→L) spawn schedule — 5 knives over 30 s ---
//   knife1 #0:  150 jiffies  (~3 s)
//   knife1 #1:  400 jiffies  (~8 s)
//   knife1 #2:  700 jiffies  (~14 s)
//   knife1 #3: 1000 jiffies  (~20 s)
//   knife1 #4: 1300 jiffies  (~26 s)
ti_k1_spawn_lo:
    .byte <150,  <400,  <700,  <1000, <1300
ti_k1_spawn_hi:
    .byte >150,  >400,  >700,  >1000, >1300

// Heights for each knife1 — spread across all five playable levels
ti_k1_heights:
    .byte TI_KY_3       // knife1 #0: row 11 (mid)
    .byte TI_KY_5       // knife1 #1: floor
    .byte TI_KY_1       // knife1 #2: row 7 (top)
    .byte TI_KY_4       // knife1 #3: row 13 (low)
    .byte TI_KY_2       // knife1 #4: row 9

// --- knife2 (L→R) spawn schedule — 5 knives over 30 s ---
// Offset from knife1 by ~150 jiffies so they interleave:
//   knife2 #0:  250 jiffies  (~5 s)
//   knife2 #1:  550 jiffies  (~11 s)
//   knife2 #2:  850 jiffies  (~17 s)
//   knife2 #3: 1100 jiffies  (~22 s)
//   knife2 #4: 1400 jiffies  (~28 s)
ti_k2_spawn_lo:
    .byte <250,  <550,  <850,  <1100, <1400
ti_k2_spawn_hi:
    .byte >250,  >550,  >850,  >1100, >1400

// Heights for each knife2 — different pattern to keep player moving
ti_k2_heights:
    .byte TI_KY_5       // knife2 #0: floor
    .byte TI_KY_2       // knife2 #1: row 9
    .byte TI_KY_4       // knife2 #2: row 13
    .byte TI_KY_1       // knife2 #3: row 7 (top)
    .byte TI_KY_3       // knife2 #4: row 11 (mid)

// Enable/disable masks for pool slots 0–6 (sprites 1–7)
ti_knife_enable_masks:
    .byte %00000010, %00000100, %00001000, %00010000
    .byte %00100000, %01000000, %10000000

ti_knife_disable_masks:
    .byte %11111101, %11111011, %11110111, %11101111
    .byte %11011111, %10111111, %01111111

// --- Pool state variables (7 slots) ---
ti_knife_state:
    .fill TI_POOL_SIZE, TI_KS_INACTIVE

ti_knife_dir:
    .fill TI_POOL_SIZE, TI_KDIR_RL

ti_knife_x_lo:
    .fill TI_POOL_SIZE, $00

ti_knife_x_hi:
    .fill TI_POOL_SIZE, $00

ti_knife_y:
    .fill TI_POOL_SIZE, $00

// --- Spawn progress counters ---
ti_k1_next:
    .byte $00                   // next knife1 index to spawn (0–4)

ti_k2_next:
    .byte $00                   // next knife2 index to spawn (0–4)

// --- Shared timing state ---
ti_window_jiffy_lo:
    .byte $00

ti_window_jiffy_hi:
    .byte $00

ti_knife_last_jiffy:
    .byte $00

// --- Scratch bytes ---
ti_temp:
    .byte $00

ti_temp2:
    .byte $00

// --- Exit door state ---
ti_door_visible:
    .byte $00                   // set to 1 once the exit door has been drawn

// --- Level number counter ---
// Starts at $31 ('1'); incremented before display → first completion shows '2'.
ti_level_num:
    .byte $31
