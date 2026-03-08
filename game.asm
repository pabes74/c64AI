// Game module (called from main.asm)

// Reuse graphics assets defined in gfx.asm
.import source "sid/soundfx.asm"

.const GAME_RIGHT0_PTR = right0 / 64
.const GAME_SPRITE0_X   = 160
.const GAME_SPRITE0_Y   = 150

.const GAME_RIGHT1_PTR = right1 / 64
.const GAME_RIGHT2_PTR = right2 / 64
.const GAME_LEFT0_PTR  = left0 / 64
.const GAME_LEFT1_PTR  = left1 / 64
.const GAME_LEFT2_PTR  = left2 / 64
.const GAME_RIGHTK_PTR = rightk / 64
.const GAME_LEFTK_PTR  = leftk / 64
.const GAME_RIGHTKNEEL_PTR = rightkn / 64
.const GAME_LEFTKNEEL_PTR  = leftkn / 64
.const GAME_RIGHTJUMP_PTR = rightj / 64
.const GAME_LEFTJUMP_PTR  = leftj / 64
.const GAME_RIGHTD_PTR = rightd / 64
.const GAME_LEFTD_PTR  = leftd / 64
.const KNIFE_PTR = knife1 / 64
.const BOULDER_PTR = boulder1 / 64

// Kuro boss sprite pointers
.const KURO_R0_PTR = kuro_r0 / 64
.const KURO_R1_PTR = kuro_r1 / 64
.const KURO_R2_PTR = kuro_r2 / 64
.const KURO_RS_PTR = kuro_rs / 64
.const KURO_RD_PTR = kuro_rd / 64
.const KURO_L0_PTR = kuro_l0 / 64
.const KURO_L1_PTR = kuro_l1 / 64
.const KURO_L2_PTR = kuro_l2 / 64
.const KURO_LS_PTR = kuro_ls / 64
.const KURO_LD_PTR = kuro_ld / 64

// Kuro boss constants
.const KURO_SPRITE_NUM = 5                 // sprite 5 for Kuro (0=player, 1-4=projectiles)
.const KURO_SPRITE_COLOR = $06             // dark blue armor
.const KURO_START_X = 80                   // spawn X (past right edge, MSB set)
.const KURO_START_X_MSB = 1                // X > 255
.const KURO_WALK_SPEED = 1                 // pixels per movement tick
.const KURO_STRIKE_RANGE = 20              // X distance to trigger sword strike
.const KURO_HIT_RANGE = 24                 // X distance for hit detection (>= STRIKE_RANGE)

// Kuro state machine
.const KURO_STATE_WALK = 0
.const KURO_STATE_STRIKE = 1
.const KURO_STATE_RECOIL = 2               // after being hit by player kick
.const KURO_STATE_DEAD = 3
.const KURO_STRIKE_TICKS = 15              // duration of sword strike pose
.const KURO_RECOIL_TICKS = 20              // stagger after being kicked
.const KURO_RECOIL_SPEED = 2               // pushed back pixels per tick

.const GAME_TOP_COLOR     = $03

.const ANIM_FRAME_COUNT = 3
.const ANIM_FRAME_TICKS = 6             // ~0.12s per frame @ 50Hz

.const KICK_DURATION_TICKS = 50         // 1s kick pose at 50Hz
.const KNEEL_DURATION_TICKS = 50        // 1s kneel pose at 50Hz
.const JUMP_DURATION_TICKS = 32

.const POSE_MODE_NONE = 0
.const POSE_MODE_KICK = 1
.const POSE_MODE_KNEEL = 2
.const POSE_MODE_JUMP = 3
.const POSE_MODE_HIT = 4

.const POSE_TICK_DIVIDER = 4
.const HIT_DURATION_TICKS = 8

.const ANIM_DIR_RIGHT = 0
.const ANIM_DIR_LEFT  = 1

.const KEY_D_COL_MASK = %11111011     // pull column 2 low to read D
.const KEY_D_ROW_BIT  = %00000100     // bit 2 corresponds to D's row
.const KEY_A_COL_MASK = %11111101     // pull column 1 low to read A
.const KEY_A_ROW_BIT  = %00000100     // bit 2 corresponds to A's row
.const KEY_S_COL_MASK = %11111101     // pull column 1 low to read S
.const KEY_S_ROW_BIT  = %00100000     // bit 5 corresponds to S's row
.const KEY_W_COL_MASK = %11111101     // pull column 1 low to read W
.const KEY_W_ROW_BIT  = %00000010     // bit 1 corresponds to W's row
.const KEY_SPACE_COL_MASK = %01111111 // pull column 7 low to read Space
.const KEY_SPACE_ROW_BIT  = %00010000 // bit 4 corresponds to Space's row

.const BG_SCREEN_BASE    = $0400
.const BG_COLOR_BASE     = $d800
.const BG_VISIBLE_COLS   = 40
.const BG_ROWS           = 24
.const BG_WIDTH          = 64
.const BG_MASK           = BG_WIDTH - 1

.const TILE_SKY              = $00
.const TILE_FAR_HILL         = $01
.const TILE_NEAR_HILL_LEFT   = $02
.const TILE_NEAR_HILL_PEAK   = $03
.const TILE_NEAR_HILL_RIGHT  = $04
.const TILE_NEAR_HILL_FILL   = $05
.const TILE_FIELD            = $06
.const TILE_ROAD             = $07
.const TILE_GRASS_TOP_A      = $08
.const TILE_GRASS_TOP_B      = $09
.const TILE_GRASS_FILL       = $0a
.const TILE_ROOF_EDGE_L      = $0b
.const TILE_ROOF_EDGE_R      = $0c
.const TILE_TREE_TOP_L       = $0d
.const TILE_TREE_TOP_R       = $0e
.const TILE_TREE_FILL        = $1d
.const TILE_ROAD2            = $0f
.const TILE_PILLAR           = $19
.const TILE_TREE_STUMP       = $1a

.const GAME_CHARSET_VALUE = $1a// screen=$0400, chars=$2800 (see game_bg_charset in gfx.asm)

.const BG_SCREEN_PTR   = $f0
.const BG_COLOR_PTR    = $f2
.const BG_PATTERN_PTR  = $f4
.const BG_ROW_COLOR_ZP = $f6
.const BG_ROW_INDEX_ZP     = $f7
.const BG_ROW_BASE_PTR     = $f8
.const BG_SRC_COL_ZP       = $fa
.const BG_COL_COUNT_ZP     = $fb
.const BG_COLOR_PATTERN_PTR = $fc
.const BG_SCREEN_COL_ZP     = $fe  // screen column counter (0..39)

// HUD
.const HUD_SCREEN_ADDR  = $0400 + 24*40   // $07c0 — row 24
.const HUD_COLOR_ADDR   = $d800 + 24*40   // $dbc0
.const HUD_TEXT_LEN     = 10
.const HUD_LIFE_COL     = 10
.const HUD_LIFE_MAX     = 5
.const LIFE_CHAR_FULL   = $17              // filled heart
.const LIFE_CHAR_EMPTY  = $18              // outlined heart

// Boss HUD (right side of row 24)
.const BOSS_HUD_TEXT_COL = 30              // "KURO" starts at column 30
.const BOSS_HUD_LIFE_COL = 35             // 5 hearts start at column 35
.const BOSS_HUD_TEXT_LEN = 4
.const BOSS_LIFE_MAX = 5

// Projectiles (using sprites 1-4)
.const PROJ_COUNT = 4
.const PROJ_INACTIVE = $00
.const PROJ_ACTIVE = $01
.const PROJ_STATE_RUBBLE = $02           // shattered boulder, visible briefly
.const PROJ_TYPE_KNIFE = $00
.const PROJ_TYPE_BOULDER = $01
.const PROJ_SPEED = 2                      // pixels per jiffy tick
.const PROJ_RUBBLE_TICKS = 25             // ~0.5s rubble visible at 50Hz
.const BOULDER_RUBBLE_PTR = boulder_rubble / 64
.const PROJ_START_X = 255                  // spawn off right edge
.const TRIGGER_SCROLL_1 = 20               // first knife
.const TRIGGER_SCROLL_2 = 40               // first boulder
.const TRIGGER_SCROLL_3 = 60               // second knife
.const TRIGGER_SCROLL_4 = 80               // second boulder

.const TEMPLE_TRIGGER_SCROLLS = 120
.const TEMPLE_WIDTH = 20
.const TEMPLE_HEIGHT = 6
.const TEMPLE_VISIBLE_SCROLLS = BG_VISIBLE_COLS + TEMPLE_WIDTH
.const TEMPLE_CENTER_SCROLLS = TEMPLE_TRIGGER_SCROLLS + 30  // temple centered on screen

// Entry point for game
* = $6000
game_start:
    // Make screen cyan and text white
    lda #GAME_TOP_COLOR
    sta $d020
    sta $d021

    // Enable multicolor character mode
    lda $d016
    ora #%00010000
    sta $d016
    lda #$08          // orange for %01 bit pairs (road spots)
    sta $d022
    lda #$0d          // light green for %10 bit pairs
    sta $d023

    lda #$01
    sta $0286

    // Configure multicolor palette for sprite 0 (match main.asm)
    lda #$0a
    sta $d025
    lda #$00
    sta $d026

    // Clear the screen
    jsr $e544

    // build initial character background
    jsr init_background

    // init sprite 0 in middle of screen
    lda #GAME_SPRITE0_X
    sta $d000          // sprite 0 X
    lda #GAME_SPRITE0_Y
    sta $d001          // sprite 0 Y

    lda $d010          // clear MSB of sprite 0 X
    and #%11111110
    sta $d010

    lda #$01           // white
    sta $d027          // sprite 0 color

    lda $d015          // enable sprite 0
    ora #%00000001
    sta $d015

    lda $d01c          // enable multicolor for sprite 0
    ora #%00000001
    sta $d01c

    // initialize runtime sprite state
    lda #ANIM_DIR_RIGHT
    sta anim_dir
    jsr reset_anim_state
    lda $a2
    sta movement_last_jiffy
    jsr init_hud
    jsr init_projectiles

game_main_loop:
    jsr update_projectiles
    jsr check_collisions
    jsr update_pose_state
    bne game_main_loop
    jsr update_kuro

    lda scroll_locked
    bne arena_input

    // --- Normal scrolling mode ---
    jsr key_d_pressed
    beq check_a_input

    // block scrolling right if temple is centered
    lda right_scroll_count
    cmp #TEMPLE_CENTER_SCROLLS
    bcs lock_scroll_now

    jsr movement_tick_ready
    beq game_main_loop
    jsr scroll_background_left

    // check if temple just became centered
    lda right_scroll_count
    cmp #TEMPLE_CENTER_SCROLLS
    bne scroll_right_continue
    jsr show_boss_hud
    jmp lock_scroll_now
scroll_right_continue:

    jsr set_anim_right
    jsr sfx_walk
    jsr run_anim
    jmp game_main_loop

lock_scroll_now:
    lda #$01
    sta scroll_locked
    jmp game_main_loop

check_a_input:
    jsr key_a_pressed
    bne check_a_do
    jmp no_input
check_a_do:
    jsr movement_tick_ready
    bne check_a_move
    jmp game_main_loop
check_a_move:
    jsr scroll_background_right
    jsr set_anim_left
    jsr sfx_walk
    jsr run_anim
    jmp game_main_loop

    // --- Arena mode: move sprite horizontally ---
arena_input:
    jsr key_d_pressed
    beq arena_to_check_a

    jsr movement_tick_ready
    beq arena_to_main2

    // move sprite right (check screen boundary, right limit = position 344 = X$58 MSB=1)
    lda $d010
    and #%00000001
    bne arena_d_msb_path       // MSB already set, handle extended range
    // MSB=0: adding 2 to X=254 overflows byte; intercept at >=254
    lda $d000
    cmp #(256-2)               // 254
    bcs arena_d_set_msb        // X >= 254, transition into MSB territory
    clc
    adc #$02
    sta $d000
    jmp arena_d_anim
arena_d_set_msb:
    // advance 2 into MSB range: new X = (X+2) - 256 = X - 254
    sec
    sbc #(256-2)               // result: 0 (X=254) or 1 (X=255)
    sta $d000
    lda $d010
    ora #%00000001
    sta $d010
    jmp arena_d_anim
arena_d_msb_path:
    // MSB=1: hard limit at X=88 (position 256+88=344, right screen edge)
    lda $d000
    cmp #88
    bcs arena_d_done           // already at right edge, stop
    clc
    adc #$02
    cmp #89                    // clamp if step crossed 88
    bcc arena_d_msb_store
    lda #88
arena_d_msb_store:
    sta $d000
arena_d_anim:
    jsr set_anim_right
    jsr sfx_walk
    jsr run_anim
arena_d_done:
    jmp game_main_loop

arena_to_check_a:
    jmp arena_check_a
arena_to_main2:
    jmp game_main_loop
arena_to_main:
    jmp game_main_loop

arena_check_a:
    jsr key_a_pressed
    beq no_input

    jsr movement_tick_ready
    beq arena_to_main

    // move sprite left (check screen boundary, left limit = position 24)
    lda $d010
    and #%00000001
    bne arena_a_clear_msb
    lda $d000
    cmp #26
    bcc arena_to_main          // X < 26: subtracting 2 would go below 24, stop
    sec
    sbc #$02
    sta $d000
    jmp arena_a_anim
arena_a_clear_msb:
    // MSB=1: subtract 2; if underflow cross back into MSB=0 territory
    lda $d000
    sec
    sbc #$02
    bcc arena_a_msb_cross      // underflow: X was 0 or 1
    sta $d000
    jmp arena_a_anim
arena_a_msb_cross:
    // position crossed below 256; A already holds correct low-byte (254 or 255)
    sta $d000
    lda $d010
    and #%11111110
    sta $d010
arena_a_anim:
    jsr set_anim_left
    jsr sfx_walk
    jsr run_anim
    jmp game_main_loop

no_input:
    jsr sfx_walk_stop
    jsr set_idle_frame
    jmp game_main_loop


// --- Input & movement helpers ------------------------------------------------

key_d_pressed:
    sei
    lda $dc00
    tax
    lda #KEY_D_COL_MASK
    sta $dc00
    lda $dc01
    tay
    txa
    sta $dc00
    cli

    tya
    and #KEY_D_ROW_BIT
    beq d_is_down

    lda #$00
    rts

d_is_down:
    lda #$01
    rts


key_a_pressed:
    sei
    lda $dc00
    tax
    lda #KEY_A_COL_MASK
    sta $dc00
    lda $dc01
    tay
    txa
    sta $dc00
    cli

    tya
    and #KEY_A_ROW_BIT
    beq a_is_down

    lda #$00
    rts

a_is_down:
    lda #$01
    rts


key_space_pressed:
    sei
    lda $dc00
    tax
    lda #KEY_SPACE_COL_MASK
    sta $dc00
    lda $dc01
    tay
    txa
    sta $dc00
    cli

    tya
    and #KEY_SPACE_ROW_BIT
    beq space_is_down

    lda #$00
    rts

space_is_down:
    lda #$01
    rts


key_s_pressed:
    sei
    lda $dc00
    tax
    lda #KEY_S_COL_MASK
    sta $dc00
    lda $dc01
    tay
    txa
    sta $dc00
    cli

    tya
    and #KEY_S_ROW_BIT
    beq s_is_down

    lda #$00
    rts

s_is_down:
    lda #$01
    rts


key_w_pressed:
    sei
    lda $dc00
    tax
    lda #KEY_W_COL_MASK
    sta $dc00
    lda $dc01
    tay
    txa
    sta $dc00
    cli

    tya
    and #KEY_W_ROW_BIT
    beq w_is_down

    lda #$00
    rts

w_is_down:
    lda #$01
    rts


movement_tick_ready:
    lda $a2
    cmp movement_last_jiffy
    bne movement_tick_new
    lda #$00
    rts

movement_tick_new:
    sta movement_last_jiffy
    lda #$01
    rts


// --- Background rendering --------------------------------------------------

init_background:
    sei
    jsr wait_frame_safe_window
    lda #GAME_CHARSET_VALUE
    sta $d018
    lda #$00
    sta bg_scroll_offset
    sta right_scroll_count
    jsr update_temple_window
    jsr draw_background_window
    cli
    rts


scroll_background_left:
    sei
    jsr wait_frame_safe_window
    lda bg_scroll_offset
    clc
    adc #$01
    and #BG_MASK
    sta bg_scroll_offset
    jsr update_temple_progress_right
    jsr draw_background_window
    cli
    rts


scroll_background_right:
    sei
    jsr wait_frame_safe_window
    lda bg_scroll_offset
    clc
    adc #BG_MASK      // adding mask is equivalent to subtracting 1 mod width
    and #BG_MASK
    sta bg_scroll_offset
    jsr update_temple_progress_left
    jsr draw_background_window
    cli
    rts


draw_background_window:
    lda #<BG_SCREEN_BASE
    sta BG_SCREEN_PTR
    lda #>BG_SCREEN_BASE
    sta BG_SCREEN_PTR+1

    lda #<BG_COLOR_BASE
    sta BG_COLOR_PTR
    lda #>BG_COLOR_BASE
    sta BG_COLOR_PTR+1

    lda #$00
    sta BG_ROW_INDEX_ZP

bg_row_loop:
    ldx BG_ROW_INDEX_ZP
    lda bg_row_color,x
    sta BG_ROW_COLOR_ZP

    lda bg_row_tile_ptr_lo,x
    sta BG_PATTERN_PTR
    sta BG_ROW_BASE_PTR
    lda bg_row_tile_ptr_hi,x
    sta BG_PATTERN_PTR+1
    sta BG_ROW_BASE_PTR+1

    lda bg_scroll_offset
    sta BG_SRC_COL_ZP
    beq bg_row_src_ready

    tax
bg_row_src_seek:
    inc BG_PATTERN_PTR
    bne bg_row_src_seek_next
    inc BG_PATTERN_PTR+1
bg_row_src_seek_next:
    dex
    bne bg_row_src_seek

bg_row_src_ready:
    lda #BG_VISIBLE_COLS
    sta BG_COL_COUNT_ZP
    lda #$00
    sta BG_SCREEN_COL_ZP

bg_draw_cols:
    ldy #$00
    lda (BG_PATTERN_PTR),y
    // Skip write if this cell is covered by the temple overlay
    ldx temple_state
    beq bg_write_now
    ldx BG_ROW_INDEX_ZP
    cpx #7
    bcc bg_write_now
    cpx #(7+TEMPLE_HEIGHT)
    bcs bg_write_now
    ldx BG_SCREEN_COL_ZP
    cpx temple_screen_x
    bcc bg_write_now
    txa
    sec
    sbc temple_screen_x
    cmp temple_draw_cols
    bcs bg_write_now
    jmp bg_skip_write

bg_write_now:
    sta (BG_SCREEN_PTR),y
    lda BG_ROW_COLOR_ZP
    sta (BG_COLOR_PTR),y

bg_skip_write:
    inc BG_SCREEN_COL_ZP

    inc BG_PATTERN_PTR
    bne bg_pattern_advanced
    inc BG_PATTERN_PTR+1
bg_pattern_advanced:

    inc BG_SRC_COL_ZP
    lda BG_SRC_COL_ZP
    cmp #BG_WIDTH
    bne bg_src_no_wrap
    lda #$00
    sta BG_SRC_COL_ZP
    lda BG_ROW_BASE_PTR
    sta BG_PATTERN_PTR
    lda BG_ROW_BASE_PTR+1
    sta BG_PATTERN_PTR+1
bg_src_no_wrap:

    inc BG_SCREEN_PTR
    bne bg_screen_advanced
    inc BG_SCREEN_PTR+1
bg_screen_advanced:

    inc BG_COLOR_PTR
    bne bg_color_advanced
    inc BG_COLOR_PTR+1
bg_color_advanced:

    dec BG_COL_COUNT_ZP
    bne bg_draw_cols

    inc BG_ROW_INDEX_ZP
    lda BG_ROW_INDEX_ZP
    cmp #BG_ROWS
    beq bg_rows_done
    jmp bg_row_loop
bg_rows_done:
    jsr draw_temple_overlay
    rts


update_temple_progress_right:
    lda right_scroll_count
    cmp #$ff
    beq temple_progress_done
    inc right_scroll_count
temple_progress_done:
    jsr update_temple_window
    rts


update_temple_progress_left:
    lda right_scroll_count
    beq temple_progress_left_done
    dec right_scroll_count
temple_progress_left_done:
    jsr update_temple_window
    rts


update_temple_window:
    lda #$00
    sta temple_state
    sta temple_src_col
    sta temple_draw_cols
    lda #BG_VISIBLE_COLS
    sta temple_screen_x

    lda right_scroll_count
    cmp #TEMPLE_TRIGGER_SCROLLS
    bcc temple_window_done

    sec
    sbc #TEMPLE_TRIGGER_SCROLLS
    sta BG_SRC_COL_ZP                  // delta scrolls after temple trigger
    beq temple_window_done             // still fully off-screen at X=40

    lda BG_SRC_COL_ZP
    cmp #TEMPLE_VISIBLE_SCROLLS
    bcs temple_window_done             // fully past left edge

    lda #$01
    sta temple_state

    lda BG_SRC_COL_ZP
    cmp #BG_VISIBLE_COLS
    bcc temple_entering_from_right

    sec
    sbc #BG_VISIBLE_COLS
    sta temple_src_col
    lda #$00
    sta temple_screen_x
    jmp temple_compute_width

temple_entering_from_right:
    lda #BG_VISIBLE_COLS
    sec
    sbc BG_SRC_COL_ZP
    sta temple_screen_x
    lda #$00
    sta temple_src_col

temple_compute_width:
    lda #TEMPLE_WIDTH
    sec
    sbc temple_src_col
    sta temple_draw_cols

    lda #BG_VISIBLE_COLS
    sec
    sbc temple_screen_x
    cmp temple_draw_cols
    bcs temple_window_done
    sta temple_draw_cols

temple_window_done:
    rts


draw_temple_overlay:
    lda temple_state
    cmp #$01
    beq temple_draw_start
    rts

temple_draw_start:
    lda #$00
    sta BG_ROW_INDEX_ZP

temple_row_loop:
    ldx BG_ROW_INDEX_ZP
    lda temple_screen_row_lo,x
    sta BG_SCREEN_PTR
    lda temple_screen_row_hi,x
    sta BG_SCREEN_PTR+1

    lda temple_color_row_lo,x
    sta BG_COLOR_PTR
    lda temple_color_row_hi,x
    sta BG_COLOR_PTR+1

    lda temple_screen_x
    sta BG_COL_COUNT_ZP
    beq temple_col_offset_done

temple_col_offset_loop:
    inc BG_SCREEN_PTR
    bne temple_screen_seek_ok
    inc BG_SCREEN_PTR+1
temple_screen_seek_ok:
    inc BG_COLOR_PTR
    bne temple_color_seek_ok
    inc BG_COLOR_PTR+1
temple_color_seek_ok:
    dec BG_COL_COUNT_ZP
    bne temple_col_offset_loop

temple_col_offset_done:
    lda temple_tile_ptr_lo,x
    sta BG_PATTERN_PTR
    lda temple_tile_ptr_hi,x
    sta BG_PATTERN_PTR+1

    lda temple_tile_color_ptr_lo,x
    sta BG_COLOR_PATTERN_PTR
    lda temple_tile_color_ptr_hi,x
    sta BG_COLOR_PATTERN_PTR+1

    lda temple_src_col
    sta BG_COL_COUNT_ZP
    beq temple_src_offset_done

temple_src_offset_loop:
    inc BG_PATTERN_PTR
    bne temple_tile_seek_ok
    inc BG_PATTERN_PTR+1
temple_tile_seek_ok:
    inc BG_COLOR_PATTERN_PTR
    bne temple_color_tile_seek_ok
    inc BG_COLOR_PATTERN_PTR+1
temple_color_tile_seek_ok:
    dec BG_COL_COUNT_ZP
    bne temple_src_offset_loop

temple_src_offset_done:
    lda temple_draw_cols
    beq temple_draw_done

    ldy #$00
temple_draw_col_loop:
    lda (BG_PATTERN_PTR),y
    sta (BG_SCREEN_PTR),y
    lda (BG_COLOR_PATTERN_PTR),y
    sta (BG_COLOR_PTR),y
    iny
    cpy temple_draw_cols
    bne temple_draw_col_loop

    inc BG_ROW_INDEX_ZP
    lda BG_ROW_INDEX_ZP
    cmp #TEMPLE_HEIGHT
    bne temple_row_loop
temple_draw_done:
    rts


wait_frame_safe_window:
wait_bottom_border:
    lda $d011
    bmi wait_top_window
    lda $d012
    cmp #$f8
    bcc wait_bottom_border

wait_top_window:
    lda $d011
    bmi wait_top_window
    lda $d012
    cmp #$20
    bcs wait_top_window
    rts


set_anim_right:
    lda anim_dir
    beq anim_right_done

    lda #ANIM_DIR_RIGHT
    sta anim_dir
    jsr reset_anim_state

anim_right_done:
    rts


set_anim_left:
    lda anim_dir
    cmp #ANIM_DIR_LEFT
    beq anim_left_done

    lda #ANIM_DIR_LEFT
    sta anim_dir
    jsr reset_anim_state

anim_left_done:
    rts


reset_anim_state:
    lda #$00
    sta anim_frame
    ldy #0
    jsr set_sprite_frame_from_table
    lda #ANIM_FRAME_TICKS
    sta anim_timer
    lda #$00
    sta anim_elapsed_jiffies
    lda $a2
    sta anim_last_jiffy
    rts


run_anim:
    lda $a2
    sec
    sbc anim_last_jiffy
    beq anim_wait_next_tick
    sta anim_elapsed_jiffies

    lda $a2
    sta anim_last_jiffy

anim_jiffy_step:
    lda anim_elapsed_jiffies
    beq anim_wait_next_tick

    dec anim_elapsed_jiffies

    lda anim_timer
    beq anim_tick
    dec anim_timer
    jmp anim_jiffy_step

anim_tick:
    lda #ANIM_FRAME_TICKS
    sta anim_timer
    jsr advance_anim
    jmp anim_jiffy_step

anim_wait_next_tick:
    rts


advance_anim:
    lda anim_frame
    clc
    adc #$01
    cmp #ANIM_FRAME_COUNT
    bcc anim_store
    lda #$00

anim_store:
    sta anim_frame
    ldy anim_frame
    jsr set_sprite_frame_from_table
    rts


set_idle_frame:
    lda anim_frame
    beq idle_reset_timer

    lda #$00
    sta anim_frame
    ldy #0
    jsr set_sprite_frame_from_table

idle_reset_timer:
    lda #ANIM_FRAME_TICKS
    sta anim_timer
    rts


set_sprite_frame_from_table:
    lda anim_dir
    beq load_right_frame

    lda anim_ptrs_left,y
    sta $07f8
    rts

load_right_frame:
    lda anim_ptrs_right,y
    sta $07f8
    rts


update_pose_state:
    lda pose_timer
    beq pose_check_input

    lda pose_tick_counter
    beq pose_advance_step
    dec pose_tick_counter
    lda #$01
    rts

pose_advance_step:
    lda #POSE_TICK_DIVIDER-1
    sta pose_tick_counter
    dec pose_timer

    lda pose_mode
    cmp #POSE_MODE_JUMP
    bne pose_check_finish
    jsr update_jump_motion

pose_check_finish:
    lda pose_timer
    beq pose_finish

    lda #$01
    rts

pose_finish:
    lda #POSE_MODE_NONE
    sta pose_mode
    lda #$00
    sta jump_step
    lda #GAME_SPRITE0_Y
    sta $d001
    ldy anim_frame
    jsr set_sprite_frame_from_table
    lda #$00
    sta pose_timer
    sta pose_tick_counter

    // safety: ensure sprite 0 stays visible
    lda $d015
    ora #%00000001
    sta $d015

    lda #$00
    rts

pose_check_input:
    jsr key_space_pressed
    beq pose_check_kneel

    jsr start_kick
    lda #$01
    rts

pose_check_kneel:
    jsr key_w_pressed
    beq pose_check_jump

    jsr start_jump
    lda #$01
    rts

pose_check_jump:
    jsr key_s_pressed
    beq pose_idle

    jsr start_kneel
    lda #$01
    rts

pose_idle:
    lda #$00
    rts


start_kick:
    jsr sfx_walk_stop
    jsr sfx_kick
    lda #KICK_DURATION_TICKS
    sta pose_timer
    lda #POSE_MODE_KICK
    sta pose_mode
    lda #$00
    sta pose_tick_counter
    sta kick_hit_done          // reset so this kick can land once on Kuro
    jsr set_kick_frame
    rts


start_kneel:
    jsr sfx_walk_stop
    jsr sfx_duck
    lda #KNEEL_DURATION_TICKS
    sta pose_timer
    lda #POSE_MODE_KNEEL
    sta pose_mode
    lda #$00
    sta pose_tick_counter
    jsr set_kneel_frame
    rts


start_jump:
    jsr sfx_walk_stop
    jsr sfx_jump
    lda #JUMP_DURATION_TICKS
    sta pose_timer
    lda #POSE_MODE_JUMP
    sta pose_mode
    lda #$00
    sta pose_tick_counter
    lda #$00
    sta jump_step
    jsr set_jump_frame
    jsr update_jump_motion
    rts


set_kick_frame:
    lda anim_dir
    beq kick_face_right

    lda #GAME_LEFTK_PTR
    sta $07f8
    rts

kick_face_right:
    lda #GAME_RIGHTK_PTR
    sta $07f8
    rts


set_kneel_frame:
    lda anim_dir
    beq kneel_face_right

    lda #GAME_LEFTKNEEL_PTR
    sta $07f8
    rts

kneel_face_right:
    lda #GAME_RIGHTKNEEL_PTR
    sta $07f8
    rts


set_jump_frame:
    lda anim_dir
    beq jump_face_right

    lda #GAME_LEFTJUMP_PTR
    sta $07f8
    rts

jump_face_right:
    lda #GAME_RIGHTJUMP_PTR
    sta $07f8
    rts


update_jump_motion:
    ldx jump_step
    cpx #JUMP_DURATION_TICKS
    bcc jump_step_ok
    ldx #JUMP_DURATION_TICKS-1

jump_step_ok:
    lda #GAME_SPRITE0_Y
    clc
    adc jump_y_offsets,x
    sta $d001
    inc jump_step
    rts


start_hit:
    jsr sfx_walk_stop
    jsr sfx_hit
    lda #HIT_DURATION_TICKS
    sta pose_timer
    lda #POSE_MODE_HIT
    sta pose_mode
    lda #$00
    sta pose_tick_counter
    jsr set_hit_frame
    dec player_hp
    jsr draw_hud_life
    rts


set_hit_frame:
    lda anim_dir
    beq hit_face_right

    lda #GAME_LEFTD_PTR
    sta $07f8
    rts

hit_face_right:
    lda #GAME_RIGHTD_PTR
    sta $07f8
    rts


// --- Projectiles ----------------------------------------------------------
// Sprites 1-4 are used for projectiles (VIC-II regs: sprite N at $d000+N*2)

init_projectiles:
    ldx #$00
init_proj_loop:
    lda #PROJ_INACTIVE
    sta proj_state,x
    lda #$00
    sta proj_spawn_flags,x
    sta proj_x_lo,x
    sta proj_x_hi,x
    inx
    cpx #PROJ_COUNT
    bne init_proj_loop
    rts


update_projectiles:
    jsr check_spawn_triggers

    // only move projectiles once per jiffy tick (~50Hz), same as player movement
    lda $a2
    cmp proj_last_jiffy
    beq update_proj_done_early
    sta proj_last_jiffy

    ldx #$00
update_proj_loop:
    lda proj_state,x
    cmp #PROJ_ACTIVE
    beq update_proj_do_move
    cmp #PROJ_STATE_RUBBLE
    bne update_proj_next           // INACTIVE: skip

    // RUBBLE state: count down timer, then remove
    dec proj_rubble_timer,x
    bne update_proj_next           // still visible

update_proj_deactivate:
    lda #PROJ_INACTIVE
    sta proj_state,x
    jsr disable_proj_sprite
    jmp update_proj_next

update_proj_do_move:
    // subtract PROJ_SPEED from 16-bit X
    lda proj_x_lo,x
    sec
    sbc #PROJ_SPEED
    sta proj_x_lo,x
    lda proj_x_hi,x
    sbc #$00
    sta proj_x_hi,x

    // if high byte went negative (>127), projectile is off-screen left
    bmi update_proj_deactivate

    // update VIC-II sprite position
    jsr update_proj_sprite

update_proj_next:
    inx
    cpx #PROJ_COUNT
    bne update_proj_loop
update_proj_done_early:
    rts


// Update VIC-II registers for projectile X (sprite index = X+1)
// X = projectile index (0-3), uses proj_x_lo/hi
update_proj_sprite:
    stx proj_temp

    // compute VIC register offset: sprite (X+1) -> reg offset = (X+1)*2
    txa
    clc
    adc #$01
    asl
    tay                         // Y = VIC register offset

    lda proj_x_lo,x
    sta $d000,y                 // sprite X low
    lda proj_y,x
    sta $d001,y                 // sprite Y

    // update X MSB in $d010
    lda proj_x_hi,x
    beq update_proj_msb_clear

    // set MSB bit for this sprite
    ldx proj_temp
    lda $d010
    ora sprite_enable_masks,x
    sta $d010
    rts

update_proj_msb_clear:
    ldx proj_temp
    lda $d010
    and sprite_disable_masks,x
    sta $d010
    rts


// Disable VIC sprite for projectile X
disable_proj_sprite:
    stx proj_temp
    txa
    clc
    adc #$01
    tay                         // sprite number = X+1

    // clear enable bit
    lda $d015
    and sprite_disable_masks,x
    sta $d015

    ldx proj_temp
    rts


check_spawn_triggers:
    lda right_scroll_count

    cmp #TRIGGER_SCROLL_1
    bne check_trigger_2
    lda proj_spawn_flags
    bne check_trigger_2
    lda #$01
    sta proj_spawn_flags
    ldx #$00
    lda #PROJ_TYPE_KNIFE
    jsr spawn_projectile

check_trigger_2:
    lda right_scroll_count
    cmp #TRIGGER_SCROLL_2
    bne check_trigger_3
    lda proj_spawn_flags+1
    bne check_trigger_3
    lda #$01
    sta proj_spawn_flags+1
    ldx #$01
    lda #PROJ_TYPE_BOULDER
    jsr spawn_projectile

check_trigger_3:
    lda right_scroll_count
    cmp #TRIGGER_SCROLL_3
    bne check_trigger_4
    lda proj_spawn_flags+2
    bne check_trigger_4
    lda #$01
    sta proj_spawn_flags+2
    ldx #$02
    lda #PROJ_TYPE_KNIFE
    jsr spawn_projectile

check_trigger_4:
    lda right_scroll_count
    cmp #TRIGGER_SCROLL_4
    beq do_trigger_4
    rts
do_trigger_4:
    lda proj_spawn_flags+3
    bne check_spawn_done
    lda #$01
    sta proj_spawn_flags+3
    ldx #$03
    lda #PROJ_TYPE_BOULDER
    jsr spawn_projectile

check_spawn_done:
    rts


// Spawn projectile: X = slot (0-3), A = type
spawn_projectile:
    sta proj_type,x
    lda #PROJ_ACTIVE
    sta proj_state,x

    // start at X = 344 (right edge of screen, MSB=1, low=88)
    lda #88
    sta proj_x_lo,x
    lda #$01
    sta proj_x_hi,x

    // Y = same height as player sprite
    lda #GAME_SPRITE0_Y
    sta proj_y,x

    // set sprite pointer
    stx proj_temp
    txa
    clc
    adc #$01
    tay                         // sprite number = X+1

    lda proj_type,x
    cmp #PROJ_TYPE_KNIFE
    bne spawn_is_boulder
    lda #KNIFE_PTR
    sta $07f8,y
    jmp spawn_setup_vic

spawn_is_boulder:
    lda #BOULDER_PTR
    sta $07f8,y

spawn_setup_vic:
    // set VIC registers
    tya
    asl
    tay                         // Y = VIC register offset

    lda proj_x_lo,x
    sta $d000,y
    lda #GAME_SPRITE0_Y
    sta $d001,y

    // set MSB (X > 255)
    lda $d010
    ora sprite_enable_masks,x
    sta $d010

    // enable sprite
    lda $d015
    ora sprite_enable_masks,x
    sta $d015

    // enable multicolor
    lda $d01c
    ora sprite_enable_masks,x
    sta $d01c

    // set sprite color to white
    ldx proj_temp
    txa
    clc
    adc #$01
    tay
    lda #$01
    sta $d027,y
    rts


check_collisions:
    lda pose_mode
    cmp #POSE_MODE_HIT
    beq collision_done

    ldx #$00
collision_loop:
    lda proj_state,x
    cmp #PROJ_ACTIVE
    bne collision_next

    // check if projectile X is near player X (160)
    // only collide when MSB=0 (X < 256)
    lda proj_x_hi,x
    bne collision_next

    lda proj_x_lo,x
    // is it within range [GAME_SPRITE0_X - 12, GAME_SPRITE0_X + 12]?
    cmp #(GAME_SPRITE0_X - 12)
    bcc collision_next
    cmp #(GAME_SPRITE0_X + 12)
    bcs collision_next

    // we have a hit — check type
    lda proj_type,x
    cmp #PROJ_TYPE_BOULDER
    bne collision_knife

    // boulder: check if kicking
    lda pose_mode
    cmp #POSE_MODE_KICK
    bne collision_boulder_hit
    // kick shatters boulder: switch to rubble sprite, stay visible briefly
    jsr sfx_boulder_break
    stx proj_temp
    txa
    clc
    adc #$01
    tay                            // sprite index = projectile + 1
    lda #BOULDER_RUBBLE_PTR
    sta $07f8,y                    // swap sprite pointer to rubble frame
    ldx proj_temp
    lda #PROJ_STATE_RUBBLE
    sta proj_state,x
    lda #PROJ_RUBBLE_TICKS
    sta proj_rubble_timer,x
    jmp collision_next

collision_boulder_hit:
    jsr start_hit
    lda #PROJ_INACTIVE
    sta proj_state,x
    jsr disable_proj_sprite
    jmp collision_done

collision_knife:
    // knife: check if kneeling
    lda pose_mode
    cmp #POSE_MODE_KNEEL
    beq collision_next          // knife flies past

    jsr start_hit
    lda #PROJ_INACTIVE
    sta proj_state,x
    jsr disable_proj_sprite
    jmp collision_done

collision_next:
    inx
    cpx #PROJ_COUNT
    bne collision_loop

collision_done:
    jsr check_kuro_kick_hit    // check player kick vs Kuro on every loop tick
    rts


// Check each loop tick whether the player's current kick lands on Kuro.
// One hit per kick animation (guarded by kick_hit_done).
check_kuro_kick_hit:
    lda kuro_active
    beq ckk_exit
    lda kuro_state
    cmp #KURO_STATE_DEAD
    beq ckk_exit               // don't hit dead Kuro
    lda pose_mode
    cmp #POSE_MODE_KICK
    bne ckk_exit               // player not kicking
    lda kick_hit_done
    bne ckk_exit               // this kick already landed once

    // compute absolute distance between player and Kuro
    jsr kuro_calc_distance
    cmp #24                    // sprites overlap at < 24 px
    bcs ckk_exit               // too far

    // kick lands
    lda #1
    sta kick_hit_done
    jsr sfx_hit
    dec boss_hp
    jsr draw_boss_life
    // trigger recoil
    lda #KURO_STATE_RECOIL
    sta kuro_state
    lda #KURO_RECOIL_TICKS
    sta kuro_state_timer
    lda kuro_dir
    bne ckk_recoil_left
    lda #KURO_R0_PTR
    jmp ckk_recoil_set
ckk_recoil_left:
    lda #KURO_L0_PTR
ckk_recoil_set:
    sta $07fd
    // check death
    lda boss_hp
    bne ckk_exit
    lda #KURO_STATE_DEAD
    sta kuro_state
    lda #KURO_LD_PTR
    sta $07fd
ckk_exit:
    rts


sprite_enable_masks:
    .byte %00000010, %00000100, %00001000, %00010000

sprite_disable_masks:
    .byte %11111101, %11111011, %11110111, %11101111

proj_temp:
    .byte $00


// --- HUD ------------------------------------------------------------------

init_hud:
    ldx #$00
init_hud_text_loop:
    lda hud_text,x
    sta HUD_SCREEN_ADDR,x
    lda #$07                               // yellow text
    sta HUD_COLOR_ADDR,x
    inx
    cpx #HUD_TEXT_LEN
    bne init_hud_text_loop
    jsr draw_hud_life
    rts


draw_hud_life:
    ldx #$00
draw_hud_life_loop:
    txa
    cmp player_hp
    bcc draw_hud_life_full
    lda #LIFE_CHAR_EMPTY
    sta HUD_SCREEN_ADDR + HUD_LIFE_COL,x
    lda #$01                               // white for empty heart
    sta HUD_COLOR_ADDR + HUD_LIFE_COL,x
    jmp draw_hud_life_next
draw_hud_life_full:
    lda #LIFE_CHAR_FULL
    sta HUD_SCREEN_ADDR + HUD_LIFE_COL,x
    lda #$02                               // red for full heart
    sta HUD_COLOR_ADDR + HUD_LIFE_COL,x
draw_hud_life_next:
    inx
    cpx #HUD_LIFE_MAX
    bne draw_hud_life_loop
    rts


show_boss_hud:
    ldx #$00
boss_hud_text_loop:
    lda boss_hud_text,x
    sta HUD_SCREEN_ADDR + BOSS_HUD_TEXT_COL,x
    lda #$02                               // red text
    sta HUD_COLOR_ADDR + BOSS_HUD_TEXT_COL,x
    inx
    cpx #BOSS_HUD_TEXT_LEN
    bne boss_hud_text_loop
    // add space between text and hearts
    lda #$20
    sta HUD_SCREEN_ADDR + BOSS_HUD_TEXT_COL + BOSS_HUD_TEXT_LEN
    jsr draw_boss_life
    jsr spawn_kuro
    rts


draw_boss_life:
    ldx #$00
draw_boss_life_loop:
    txa
    cmp boss_hp
    bcc draw_boss_life_full
    lda #LIFE_CHAR_EMPTY
    sta HUD_SCREEN_ADDR + BOSS_HUD_LIFE_COL,x
    lda #$01                               // white for empty heart
    sta HUD_COLOR_ADDR + BOSS_HUD_LIFE_COL,x
    jmp draw_boss_life_next
draw_boss_life_full:
    lda #LIFE_CHAR_FULL
    sta HUD_SCREEN_ADDR + BOSS_HUD_LIFE_COL,x
    lda #$02                               // red for full heart
    sta HUD_COLOR_ADDR + BOSS_HUD_LIFE_COL,x
draw_boss_life_next:
    inx
    cpx #BOSS_LIFE_MAX
    bne draw_boss_life_loop
    rts


// --- Kuro boss routines ------------------------------------------------------

spawn_kuro:
    lda kuro_active
    bne spawn_kuro_done            // already active

    lda #$01
    sta kuro_active

    // set initial position (right side of screen, X=336 -> lo=$50, hi=$01)
    lda #KURO_START_X
    sta kuro_x_lo
    lda #KURO_START_X_MSB
    sta kuro_x_hi

    // set sprite 5 Y: align bottom rows (Y-expanded = 42px tall, player = 21px)
    lda $d001
    sec
    sbc #21
    sta $d00b

    lda kuro_x_lo
    sta $d00a                      // Kuro X lo

    // set X MSB for sprite 5
    lda kuro_x_hi
    beq spawn_kuro_msb_clear
    lda $d010
    ora #%00100000
    sta $d010
    jmp spawn_kuro_setup
spawn_kuro_msb_clear:
    lda $d010
    and #%11011111
    sta $d010

spawn_kuro_setup:
    // set sprite color
    lda #KURO_SPRITE_COLOR
    sta $d02c                      // sprite 5 color register ($d027+5)

    // enable sprite 5
    lda $d015
    ora #%00100000
    sta $d015

    // enable multicolor for sprite 5
    lda $d01c
    ora #%00100000
    sta $d01c

    // expand sprite 5 vertically (taller than player)
    lda $d017
    ora #%00100000
    sta $d017

    // set initial sprite frame
    lda #KURO_L0_PTR
    sta $07fd                      // sprite 5 pointer ($07f8 + 5)

    // init animation
    lda #$00
    sta kuro_anim_frame
    sta kuro_anim_timer
    sta kuro_walk_timer
    lda #$01                       // initially facing left (spawns on right side)
    sta kuro_dir

spawn_kuro_done:
    rts


update_kuro:
    lda kuro_active
    bne kuro_is_active
    rts
kuro_is_active:

    // keep Kuro Y synced with player (bottom-aligned, Y-expand offset)
    lda $d001
    sec
    sbc #21
    sta $d00b

    // cooldown timer for hit detection
    lda kuro_hit_cooldown
    beq kuro_no_cooldown
    dec kuro_hit_cooldown
kuro_no_cooldown:

    // walk timer (use jiffy clock)
    lda $a2
    cmp kuro_walk_timer
    bne kuro_tick_ok
    rts
kuro_tick_ok:
    sta kuro_walk_timer

    // dispatch on state
    lda kuro_state
    cmp #KURO_STATE_STRIKE
    bne kuro_not_strike
    jmp kuro_do_strike
kuro_not_strike:
    cmp #KURO_STATE_RECOIL
    bne kuro_not_recoil
    jmp kuro_do_recoil
kuro_not_recoil:
    cmp #KURO_STATE_DEAD
    bne kuro_not_dead
    rts
kuro_not_dead:

    // --- KURO_STATE_WALK ---
    // compute distance to player: get player X (16-bit) and Kuro X (16-bit)
    // player X lo = $d000, MSB bit 0 of $d010
    // kuro X lo = kuro_x_lo, hi = kuro_x_hi
    // distance = kuro_16bit - player_16bit

    // check if close enough to strike
    jsr kuro_calc_distance
    cmp #KURO_STRIKE_RANGE
    bcc kuro_begin_strike

    // determine walk direction: compare kuro_x (16-bit) to player_x (in kuro_temp)
    lda kuro_x_hi
    cmp kuro_temp_hi
    bcc kuro_walk_right        // kuro hi < player hi: kuro is LEFT of player
    bne kuro_walk_left         // kuro hi > player hi: kuro is RIGHT of player
    lda kuro_x_lo              // hi bytes equal, compare lo
    cmp $d000                  // compare kuro lo with player X lo directly
    bcc kuro_walk_right        // kuro lo < player lo: kuro is LEFT of player
    // kuro >= player: walk left

kuro_walk_left:
    lda #1
    sta kuro_dir               // 1 = facing left
    lda kuro_x_lo
    sec
    sbc #KURO_WALK_SPEED
    sta kuro_x_lo
    bcs kuro_walk_left_clamp
    dec kuro_x_hi
kuro_walk_left_clamp:
    // clamp at left boundary (X=24, MSB=0)
    lda kuro_x_hi
    bne kuro_walk_left_ok      // MSB=1: position > 255, still on screen
    lda kuro_x_lo
    cmp #24
    bcs kuro_walk_left_ok
    lda #24
    sta kuro_x_lo
kuro_walk_left_ok:
    jsr kuro_update_sprite_x
    jmp kuro_animate

kuro_walk_right:
    lda #0
    sta kuro_dir               // 0 = facing right
    lda kuro_x_lo
    clc
    adc #KURO_WALK_SPEED
    sta kuro_x_lo
    bcc kuro_walk_right_clamp
    inc kuro_x_hi
kuro_walk_right_clamp:
    // clamp at right boundary (X=88, MSB=1 = position 344)
    lda kuro_x_hi
    beq kuro_walk_right_ok     // MSB=0: position < 256, well within screen
    lda kuro_x_lo
    cmp #88
    bcc kuro_walk_right_ok
    lda #88
    sta kuro_x_lo
    lda #1
    sta kuro_x_hi
kuro_walk_right_ok:
    jsr kuro_update_sprite_x
    jmp kuro_animate

kuro_begin_strike:
    lda #KURO_STATE_STRIKE
    sta kuro_state
    lda #KURO_STRIKE_TICKS
    sta kuro_state_timer
    // strike sprite matches current facing direction
    lda kuro_dir
    bne kuro_strike_sprite_left
    lda #KURO_RS_PTR               // facing right: right strike
    jmp kuro_strike_sprite_set
kuro_strike_sprite_left:
    lda #KURO_LS_PTR               // facing left: left strike
kuro_strike_sprite_set:
    sta $07fd
    jmp update_kuro_done

    // --- KURO_STATE_STRIKE ---
kuro_do_strike:
    dec kuro_state_timer
    bne kuro_strike_check_hit
    // strike finished, check result and return to walk
    lda #KURO_STATE_WALK
    sta kuro_state
    lda kuro_dir
    bne kuro_strike_end_left
    lda #KURO_R0_PTR
    jmp kuro_strike_end_set
kuro_strike_end_left:
    lda #KURO_L0_PTR
kuro_strike_end_set:
    sta $07fd
    jmp update_kuro_done

kuro_strike_check_hit:
    // only check hit at mid-point of strike
    lda kuro_state_timer
    cmp #(KURO_STRIKE_TICKS / 2)
    beq kuro_strike_hit_check2
    jmp update_kuro_done
kuro_strike_hit_check2:

    // check if player is in range
    lda kuro_hit_cooldown
    beq kuro_strike_hit_check3
    jmp update_kuro_done
kuro_strike_hit_check3:

    jsr kuro_calc_distance
    cmp #KURO_HIT_RANGE
    bcc kuro_strike_in_range
    jmp update_kuro_done
kuro_strike_in_range:

    // player is in range - check if player is kicking (blocks Kuro's strike)
    lda pose_mode
    cmp #POSE_MODE_KICK
    beq kuro_strike_blocked    // kick handles damage via check_kuro_kick_hit

    // player is NOT kicking -> player takes damage
    jsr sfx_hit
    lda #POSE_MODE_HIT
    sta pose_mode
    lda #HIT_DURATION_TICKS
    sta pose_timer
    lda #$00
    sta pose_tick_counter
    // show hit sprite
    lda anim_dir
    cmp #ANIM_DIR_RIGHT
    bne kuro_hit_player_left
    lda #GAME_RIGHTD_PTR
    jmp kuro_hit_player_set
kuro_hit_player_left:
    lda #GAME_LEFTD_PTR
kuro_hit_player_set:
    sta $07f8
    dec player_hp
    jsr draw_hud_life
    lda #30
    sta kuro_hit_cooldown
    // check game over
    lda player_hp
    beq kuro_trigger_game_over
    jmp update_kuro_done

kuro_strike_blocked:
    jmp update_kuro_done

kuro_trigger_game_over:
    jmp game_over

kuro_player_kicks_boss:
    // player kick hits Kuro -> Kuro takes damage
    jsr sfx_hit
    dec boss_hp
    jsr draw_boss_life
    lda #30
    sta kuro_hit_cooldown
    // Kuro recoils
    lda #KURO_STATE_RECOIL
    sta kuro_state
    lda #KURO_RECOIL_TICKS
    sta kuro_state_timer
    lda kuro_dir
    bne kuro_recoil_init_left
    lda #KURO_R0_PTR
    jmp kuro_recoil_init_set
kuro_recoil_init_left:
    lda #KURO_L0_PTR
kuro_recoil_init_set:
    sta $07fd
    // check if Kuro is dead
    lda boss_hp
    beq kuro_die
    jmp update_kuro_done

kuro_die:
    lda #KURO_STATE_DEAD
    sta kuro_state
    lda #KURO_LD_PTR
    sta $07fd
    jmp update_kuro_done

    // --- KURO_STATE_RECOIL ---
kuro_do_recoil:
    dec kuro_state_timer
    bne kuro_recoil_move
    // recoil finished, back to walking
    lda #KURO_STATE_WALK
    sta kuro_state
    jmp update_kuro_done

kuro_recoil_move:
    // push Kuro away from player (opposite of facing direction)
    lda kuro_dir
    bne kuro_recoil_push_right     // facing left: push right
    // facing right: push left
    lda kuro_x_lo
    sec
    sbc #KURO_RECOIL_SPEED
    sta kuro_x_lo
    bcs kuro_recoil_left_clamp
    dec kuro_x_hi
kuro_recoil_left_clamp:
    lda kuro_x_hi
    bne kuro_recoil_done           // MSB=1: still on screen
    lda kuro_x_lo
    cmp #24
    bcs kuro_recoil_done
    lda #24
    sta kuro_x_lo
    jmp kuro_recoil_done

kuro_recoil_push_right:
    lda kuro_x_lo
    clc
    adc #KURO_RECOIL_SPEED
    sta kuro_x_lo
    bcc kuro_recoil_right_clamp
    inc kuro_x_hi
kuro_recoil_right_clamp:
    lda kuro_x_hi
    beq kuro_recoil_done           // MSB=0: well within screen
    lda kuro_x_lo
    cmp #88
    bcc kuro_recoil_done
    lda #88
    sta kuro_x_lo
    lda #1
    sta kuro_x_hi
kuro_recoil_done:
    jsr kuro_update_sprite_x
    jmp update_kuro_done

kuro_animate:
    // advance walk animation
    inc kuro_anim_timer
    lda kuro_anim_timer
    cmp #ANIM_FRAME_TICKS
    bcc update_kuro_done

    lda #$00
    sta kuro_anim_timer

    ldx kuro_anim_frame
    lda kuro_dir
    bne kuro_anim_use_left
    lda kuro_anim_ptrs_right,x
    jmp kuro_anim_set
kuro_anim_use_left:
    lda kuro_anim_ptrs_left,x
kuro_anim_set:
    sta $07fd

    inx
    cpx #ANIM_FRAME_COUNT
    bne kuro_anim_store
    ldx #$00
kuro_anim_store:
    stx kuro_anim_frame

update_kuro_done:
    rts


// Calculate absolute X distance between Kuro and player, result in A
// Also leaves player X in kuro_temp_lo/hi for direction comparison after call
// Only meaningful when both are on screen (kuro_x_hi == 0 or 1)
kuro_calc_distance:
    // get player X hi (bit 0 of $d010 = MSB of sprite 0)
    lda $d010
    and #%00000001
    sta kuro_temp_hi
    lda $d000
    sta kuro_temp_lo

    // 16-bit compare: is kuro_x >= player_x?
    lda kuro_x_hi
    cmp kuro_temp_hi
    bcc kuro_dist_sub_kuro      // kuro hi < player hi: player is greater
    bne kuro_dist_sub_player    // kuro hi > player hi: kuro is greater
    lda kuro_x_lo
    cmp kuro_temp_lo
    bcc kuro_dist_sub_kuro      // kuro lo < player lo: player is greater

    // kuro >= player: distance = kuro_x - player_x
kuro_dist_sub_player:
    lda kuro_x_lo
    sec
    sbc kuro_temp_lo
    sta kuro_temp_lo
    lda kuro_x_hi
    sbc kuro_temp_hi
    bne kuro_dist_far
    lda kuro_temp_lo
    rts

kuro_dist_sub_kuro:
    // distance = player_x - kuro_x
    lda kuro_temp_lo
    sec
    sbc kuro_x_lo
    sta kuro_temp_lo
    lda kuro_temp_hi
    sbc kuro_x_hi
    bne kuro_dist_far
    lda kuro_temp_lo
    rts

kuro_dist_far:
    lda #$ff
    rts

kuro_temp_lo:
    .byte 0
kuro_temp_hi:
    .byte 0


// Update Kuro sprite 5 X position from kuro_x_lo/hi
kuro_update_sprite_x:
    lda kuro_x_lo
    sta $d00a
    lda kuro_x_hi
    beq kuro_upd_clear_msb
    lda $d010
    ora #%00100000
    sta $d010
    rts
kuro_upd_clear_msb:
    lda $d010
    and #%11011111
    sta $d010
    rts


// --- Game Over screen --------------------------------------------------------
game_over:
    // disable all sprites
    lda #$00
    sta $d015

    // silence SID
    ldx #$00
    lda #$00
game_over_sid:
    sta $d400,x
    inx
    cpx #$19
    bne game_over_sid
    lda #$0f
    sta $d418

    // black screen
    lda #$00
    sta $d020
    sta $d021

    // switch back to ROM charset and single-color mode
    lda #$14                       // default $d018 (screen $0400, charset $1000)
    sta $d018
    lda $d016
    and #%11101111                 // disable multicolor
    sta $d016

    // clear screen
    jsr $e544

    // display "GAME OVER" centered on row 12 (screen addr $0400 + 12*40 + 15 = $05e7)
    ldx #$00
game_over_text_loop:
    lda game_over_text,x
    sta $05e7,x
    lda #$01                       // white text
    sta $d9e7,x
    inx
    cpx #game_over_text_end - game_over_text
    bne game_over_text_loop

    // wait ~3 seconds (150 jiffies)
    lda $a2
    clc
    adc #150
    sta kuro_temp_lo
game_over_wait:
    lda $a2
    cmp kuro_temp_lo
    bne game_over_wait

    // return to title screen
    jmp start

// "GAME OVER" in PETSCII screen codes
game_over_text:
    .byte $07,$01,$0d,$05,$20,$0f,$16,$05,$12  // G A M E   O V E R
game_over_text_end:

bg_scroll_offset:
    .byte 0

movement_last_jiffy:
    .byte 0

proj_last_jiffy:
    .byte 0

right_scroll_count:
    .byte 0

scroll_locked:
    .byte 0

temple_state:
    .byte 0

temple_screen_x:
    .byte BG_VISIBLE_COLS

temple_src_col:
    .byte 0

temple_draw_cols:
    .byte 0

anim_dir:
    .byte ANIM_DIR_RIGHT

anim_frame:
    .byte 0

anim_timer:
    .byte ANIM_FRAME_TICKS

anim_last_jiffy:
    .byte 0

anim_elapsed_jiffies:
    .byte 0

pose_timer:
    .byte 0

pose_mode:
    .byte POSE_MODE_NONE

pose_tick_counter:
    .byte 0

jump_step:
    .byte 0

player_hp:
    .byte HUD_LIFE_MAX

boss_hp:
    .byte BOSS_LIFE_MAX

kick_hit_done:
    .byte 0

proj_state:
    .fill PROJ_COUNT, PROJ_INACTIVE
    
proj_type:
    .fill PROJ_COUNT, $00
    
proj_x_lo:
    .fill PROJ_COUNT, $00

proj_x_hi:
    .fill PROJ_COUNT, $00
    
proj_y:
    .fill PROJ_COUNT, $00
    
proj_spawn_flags:
    .fill PROJ_COUNT, $00

proj_rubble_timer:
    .fill PROJ_COUNT, $00

// Kuro boss state
kuro_active:
    .byte 0
kuro_x_lo:
    .byte 0
kuro_x_hi:
    .byte 0
kuro_anim_frame:
    .byte 0
kuro_anim_timer:
    .byte 0
kuro_walk_timer:
    .byte 0
kuro_state:
    .byte KURO_STATE_WALK
kuro_state_timer:
    .byte 0
kuro_hit_cooldown:
    .byte 0

kuro_dir:
    .byte 1                        // 0=facing right, 1=facing left

kuro_anim_ptrs_left:
    .byte KURO_L0_PTR, KURO_L1_PTR, KURO_L2_PTR

kuro_anim_ptrs_right:
    .byte KURO_R0_PTR, KURO_R1_PTR, KURO_R2_PTR

jump_y_offsets:
    .byte $00,$fe,$fc,$fa,$f8,$f6,$f4,$f2
    .byte $f0,$ee,$ec,$ea,$e8,$e8,$ea,$ec
    .byte $ee,$f0,$f2,$f4,$f6,$f8,$fa,$fc
    .byte $fe,$00,$00,$00,$00,$00,$00,$00

anim_ptrs_right:
    .byte GAME_RIGHT0_PTR, GAME_RIGHT1_PTR, GAME_RIGHT2_PTR

anim_ptrs_left:
    .byte GAME_LEFT0_PTR, GAME_LEFT1_PTR, GAME_LEFT2_PTR

hud_text:  // "KARATEGAI " in game charset screen codes ($10-$16 = K,A,R,T,E,G,I)
    .byte $10,$11,$12,$11,$13,$14,$15,$11,$16,$20

boss_hud_text:  // "KURO" in game charset screen codes ($10=K, $1b=U, $12=R, $1c=O)
    .byte $10,$1b,$12,$1c


// --- Background data -------------------------------------------------------

bg_row_color:
    .byte $0b, $0b, $0b, $0b, $0b
    .byte $0b, $0d, $0d, $08, $08
    .byte $0f, $0f, $0f, $0f, $0f
    .byte $0f, $0d, $0d, $0d, $0d
    .byte $0d, $0d, $0d, $0d, $0d

bg_row_tile_ptr_lo:
    .byte <bg_row00_tiles, <bg_row01_tiles, <bg_row02_tiles, <bg_row03_tiles, <bg_row04_tiles
    .byte <bg_row05_tiles, <bg_row06_tiles, <bg_row07_tiles, <bg_row08_tiles, <bg_row09_tiles
    .byte <bg_row10_tiles, <bg_row11_tiles, <bg_row12_tiles, <bg_row13_tiles, <bg_row14_tiles
    .byte <bg_row15_tiles, <bg_row16_tiles, <bg_row17_tiles, <bg_row18_tiles, <bg_row19_tiles
    .byte <bg_row20_tiles, <bg_row21_tiles, <bg_row22_tiles, <bg_row23_tiles, <bg_row24_tiles

bg_row_tile_ptr_hi:
    .byte >bg_row00_tiles, >bg_row01_tiles, >bg_row02_tiles, >bg_row03_tiles, >bg_row04_tiles
    .byte >bg_row05_tiles, >bg_row06_tiles, >bg_row07_tiles, >bg_row08_tiles, >bg_row09_tiles
    .byte >bg_row10_tiles, >bg_row11_tiles, >bg_row12_tiles, >bg_row13_tiles, >bg_row14_tiles
    .byte >bg_row15_tiles, >bg_row16_tiles, >bg_row17_tiles, >bg_row18_tiles, >bg_row19_tiles
    .byte >bg_row20_tiles, >bg_row21_tiles, >bg_row22_tiles, >bg_row23_tiles, >bg_row24_tiles

temple_screen_row_lo:
    .byte <(BG_SCREEN_BASE + (7*40)), <(BG_SCREEN_BASE + (8*40)), <(BG_SCREEN_BASE + (9*40))
    .byte <(BG_SCREEN_BASE + (10*40)), <(BG_SCREEN_BASE + (11*40)), <(BG_SCREEN_BASE + (12*40))

temple_screen_row_hi:
    .byte >(BG_SCREEN_BASE + (7*40)), >(BG_SCREEN_BASE + (8*40)), >(BG_SCREEN_BASE + (9*40))
    .byte >(BG_SCREEN_BASE + (10*40)), >(BG_SCREEN_BASE + (11*40)), >(BG_SCREEN_BASE + (12*40))

temple_color_row_lo:
    .byte <(BG_COLOR_BASE + (7*40)), <(BG_COLOR_BASE + (8*40)), <(BG_COLOR_BASE + (9*40))
    .byte <(BG_COLOR_BASE + (10*40)), <(BG_COLOR_BASE + (11*40)), <(BG_COLOR_BASE + (12*40))

temple_color_row_hi:
    .byte >(BG_COLOR_BASE + (7*40)), >(BG_COLOR_BASE + (8*40)), >(BG_COLOR_BASE + (9*40))
    .byte >(BG_COLOR_BASE + (10*40)), >(BG_COLOR_BASE + (11*40)), >(BG_COLOR_BASE + (12*40))

temple_tile_ptr_lo:
    .byte <temple_row0_tiles, <temple_row1_tiles, <temple_row2_tiles
    .byte <temple_row3_tiles, <temple_row4_tiles, <temple_row5_tiles

temple_tile_ptr_hi:
    .byte >temple_row0_tiles, >temple_row1_tiles, >temple_row2_tiles
    .byte >temple_row3_tiles, >temple_row4_tiles, >temple_row5_tiles

temple_tile_color_ptr_lo:
    .byte <temple_row0_colors, <temple_row1_colors, <temple_row2_colors
    .byte <temple_row3_colors, <temple_row4_colors, <temple_row5_colors

temple_tile_color_ptr_hi:
    .byte >temple_row0_colors, >temple_row1_colors, >temple_row2_colors
    .byte >temple_row3_colors, >temple_row4_colors, >temple_row5_colors

temple_row0_tiles:
    .byte TILE_SKY,TILE_SKY,TILE_ROOF_EDGE_L,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROOF_EDGE_R,TILE_SKY,TILE_SKY
temple_row1_tiles:
    .byte TILE_SKY,TILE_SKY,TILE_SKY,TILE_ROOF_EDGE_L,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROOF_EDGE_R,TILE_SKY,TILE_SKY,TILE_SKY
temple_row2_tiles:
    .byte TILE_SKY,TILE_SKY,TILE_SKY,TILE_SKY,TILE_PILLAR,TILE_SKY,TILE_SKY,TILE_PILLAR,TILE_PILLAR,TILE_PILLAR
    .byte TILE_PILLAR,TILE_PILLAR,TILE_PILLAR,TILE_SKY,TILE_SKY,TILE_PILLAR,TILE_SKY,TILE_SKY,TILE_SKY,TILE_SKY
temple_row3_tiles:
    .byte TILE_SKY,TILE_SKY,TILE_SKY,TILE_SKY,TILE_PILLAR,TILE_SKY,TILE_SKY,TILE_PILLAR,TILE_SKY,TILE_SKY
    .byte TILE_SKY,TILE_SKY,TILE_PILLAR,TILE_SKY,TILE_SKY,TILE_PILLAR,TILE_SKY,TILE_SKY,TILE_SKY,TILE_SKY
temple_row4_tiles:
    .byte TILE_SKY,TILE_SKY,TILE_SKY,TILE_SKY,TILE_PILLAR,TILE_SKY,TILE_SKY,TILE_PILLAR,TILE_SKY,TILE_SKY
    .byte TILE_SKY,TILE_SKY,TILE_PILLAR,TILE_SKY,TILE_SKY,TILE_PILLAR,TILE_SKY,TILE_SKY,TILE_SKY,TILE_SKY
temple_row5_tiles:
    .byte TILE_SKY,TILE_SKY,TILE_SKY,TILE_SKY,TILE_PILLAR,TILE_SKY,TILE_SKY,TILE_PILLAR,TILE_SKY,TILE_SKY
    .byte TILE_SKY,TILE_SKY,TILE_PILLAR,TILE_SKY,TILE_SKY,TILE_PILLAR,TILE_SKY,TILE_SKY,TILE_SKY,TILE_SKY

temple_row0_colors:
    .byte $0b,$0b,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0a,$0b,$0b
temple_row1_colors:
    .byte $0b,$0b,$0b,$0a,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$09,$0a,$0b,$0b,$0b
temple_row2_colors:
    .byte $0b,$0b,$0b,$0b,$09,$0b,$0b,$09,$0f,$0f,$0e,$0e,$0f,$0b,$0b,$09,$0b,$0b,$0b,$0b
temple_row3_colors:
    .byte $0b,$0b,$0b,$0b,$09,$0b,$0b,$09,$0b,$0b,$0b,$0b,$09,$0b,$0b,$09,$0b,$0b,$0b,$0b
temple_row4_colors:
    .byte $0b,$0b,$0b,$0b,$09,$0b,$0b,$09,$0b,$0b,$0b,$0b,$09,$0b,$0b,$09,$0b,$0b,$0b,$0b
temple_row5_colors:
    .byte $0b,$0b,$0b,$0b,$08,$0b,$0b,$08,$0b,$0b,$0b,$0b,$08,$0b,$0b,$08,$0b,$0b,$0b,$0b


bg_tile_map:
bg_row00_tiles:
    .fill BG_WIDTH, TILE_SKY
bg_row01_tiles:
    .fill BG_WIDTH, TILE_SKY
bg_row02_tiles:
    .fill BG_WIDTH, TILE_SKY
bg_row03_tiles:
    .fill BG_WIDTH, TILE_SKY
bg_row04_tiles:
    .fill BG_WIDTH, TILE_SKY
bg_row05_tiles:
    .fill BG_WIDTH, TILE_SKY
bg_row06_tiles:
    .byte TILE_SKY, TILE_SKY, TILE_TREE_TOP_L, TILE_TREE_FILL, TILE_TREE_TOP_R, TILE_SKY, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_SKY, TILE_TREE_TOP_L, TILE_TREE_FILL, TILE_TREE_TOP_R, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_TREE_TOP_L, TILE_TREE_FILL, TILE_TREE_TOP_R, TILE_SKY, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_SKY, TILE_TREE_TOP_L, TILE_TREE_FILL, TILE_TREE_TOP_R, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_TREE_TOP_L, TILE_TREE_FILL, TILE_TREE_TOP_R, TILE_SKY, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_SKY, TILE_TREE_TOP_L, TILE_TREE_FILL, TILE_TREE_TOP_R, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_TREE_TOP_L, TILE_TREE_FILL, TILE_TREE_TOP_R, TILE_SKY, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_SKY, TILE_TREE_TOP_L, TILE_TREE_FILL, TILE_TREE_TOP_R, TILE_SKY, TILE_SKY
bg_row07_tiles:
    .byte TILE_SKY, TILE_SKY, TILE_TREE_TOP_L, TILE_TREE_FILL, TILE_TREE_TOP_R, TILE_SKY, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_SKY, TILE_TREE_TOP_L, TILE_TREE_FILL, TILE_TREE_TOP_R, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_TREE_TOP_L, TILE_TREE_FILL, TILE_TREE_TOP_R, TILE_SKY, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_SKY, TILE_TREE_TOP_L, TILE_TREE_FILL, TILE_TREE_TOP_R, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_TREE_TOP_L, TILE_TREE_FILL, TILE_TREE_TOP_R, TILE_SKY, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_SKY, TILE_TREE_TOP_L, TILE_TREE_FILL, TILE_TREE_TOP_R, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_TREE_TOP_L, TILE_TREE_FILL, TILE_TREE_TOP_R, TILE_SKY, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_SKY, TILE_TREE_TOP_L, TILE_TREE_FILL, TILE_TREE_TOP_R, TILE_SKY, TILE_SKY
bg_row08_tiles:
    .byte TILE_SKY, TILE_NEAR_HILL_LEFT, TILE_NEAR_HILL_FILL, TILE_TREE_STUMP, TILE_NEAR_HILL_FILL, TILE_NEAR_HILL_RIGHT, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_NEAR_HILL_LEFT, TILE_NEAR_HILL_FILL, TILE_NEAR_HILL_RIGHT, TILE_SKY, TILE_TREE_STUMP, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_NEAR_HILL_LEFT, TILE_NEAR_HILL_FILL, TILE_TREE_STUMP, TILE_NEAR_HILL_FILL, TILE_NEAR_HILL_RIGHT, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_NEAR_HILL_LEFT, TILE_NEAR_HILL_FILL, TILE_NEAR_HILL_RIGHT, TILE_SKY, TILE_TREE_STUMP, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_NEAR_HILL_LEFT, TILE_NEAR_HILL_FILL, TILE_TREE_STUMP, TILE_NEAR_HILL_FILL, TILE_NEAR_HILL_RIGHT, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_NEAR_HILL_LEFT, TILE_NEAR_HILL_FILL, TILE_NEAR_HILL_RIGHT, TILE_SKY, TILE_TREE_STUMP, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_NEAR_HILL_LEFT, TILE_NEAR_HILL_FILL, TILE_TREE_STUMP, TILE_NEAR_HILL_FILL, TILE_NEAR_HILL_RIGHT, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_NEAR_HILL_LEFT, TILE_NEAR_HILL_FILL, TILE_NEAR_HILL_RIGHT, TILE_SKY, TILE_TREE_STUMP, TILE_SKY, TILE_SKY
bg_row09_tiles:
    .byte TILE_SKY, TILE_SKY, TILE_NEAR_HILL_LEFT, TILE_TREE_STUMP, TILE_NEAR_HILL_PEAK, TILE_NEAR_HILL_FILL, TILE_NEAR_HILL_RIGHT, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_NEAR_HILL_LEFT, TILE_NEAR_HILL_FILL, TILE_NEAR_HILL_RIGHT, TILE_TREE_STUMP, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_NEAR_HILL_LEFT, TILE_TREE_STUMP, TILE_NEAR_HILL_PEAK, TILE_NEAR_HILL_FILL, TILE_NEAR_HILL_RIGHT, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_NEAR_HILL_LEFT, TILE_NEAR_HILL_FILL, TILE_NEAR_HILL_RIGHT, TILE_TREE_STUMP, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_NEAR_HILL_LEFT, TILE_TREE_STUMP, TILE_NEAR_HILL_PEAK, TILE_NEAR_HILL_FILL, TILE_NEAR_HILL_RIGHT, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_NEAR_HILL_LEFT, TILE_NEAR_HILL_FILL, TILE_NEAR_HILL_RIGHT, TILE_TREE_STUMP, TILE_SKY, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_NEAR_HILL_LEFT, TILE_TREE_STUMP, TILE_NEAR_HILL_PEAK, TILE_NEAR_HILL_FILL, TILE_NEAR_HILL_RIGHT, TILE_SKY
    .byte TILE_SKY, TILE_SKY, TILE_NEAR_HILL_LEFT, TILE_NEAR_HILL_FILL, TILE_NEAR_HILL_RIGHT, TILE_TREE_STUMP, TILE_SKY, TILE_SKY
bg_row10_tiles:
    .fill BG_WIDTH, TILE_FIELD
bg_row11_tiles:
    .fill BG_WIDTH, TILE_FIELD
bg_row12_tiles:
    .fill BG_WIDTH, TILE_FIELD
bg_row13_tiles:
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
bg_row14_tiles:
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
bg_row15_tiles:
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
    .byte TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2,TILE_ROAD,TILE_ROAD,TILE_ROAD,TILE_ROAD2
bg_row16_tiles:
    .byte TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B
    .byte TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B
    .byte TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B
    .byte TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B
    .byte TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B
    .byte TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B
    .byte TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B
    .byte TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B, TILE_GRASS_TOP_A, TILE_GRASS_TOP_B
bg_row17_tiles:
    .fill BG_WIDTH, TILE_GRASS_FILL
bg_row18_tiles:
    .fill BG_WIDTH, TILE_GRASS_FILL
bg_row19_tiles:
    .fill BG_WIDTH, TILE_GRASS_FILL
bg_row20_tiles:
    .fill BG_WIDTH, TILE_GRASS_FILL
bg_row21_tiles:
    .fill BG_WIDTH, TILE_GRASS_FILL
bg_row22_tiles:
    .fill BG_WIDTH, TILE_GRASS_FILL
bg_row23_tiles:
    .fill BG_WIDTH, TILE_GRASS_FILL
bg_row24_tiles:
    .fill BG_WIDTH, TILE_GRASS_FILL
