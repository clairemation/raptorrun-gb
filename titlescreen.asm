include "hardware.inc"
include "utils.inc"
include "wram.inc"
include "game.inc"

def TITLE_TILEMAP_SIZE    equ (1024)
def TITLE_TILESET_SIZE    equ (2688)

def STATE_WAITING   equ(0)
def STATE_STARTING  equ(1)

def PALETTE_0  equ(%11100100)
def PALETTE_1  equ(%11111001)
def PALETTE_2  equ(%11111110)
def PALETTE_3  equ(%11111111)

def FADE_ANIMATION_FRAMES   equ(4)

macro InitPallettes
    ; init the palettes
    ld a, PALETTE_0
    ld [rBGP], a
    ld [rOBP0], a
    ld a, %00011011
    ld [rOBP1], a
endm

macro WaitForStartPress
    UpdatePadInput WRAM_PAD_INPUT
    TestPadInput_Pressed WRAM_PAD_INPUT, PADF_START
    jr nz, .startIsPressed\@
        copy [WRAM_TITLESCREEN_STATE], STATE_STARTING
    .startIsPressed\@
endm

section "titlescreen", rom0
InitTitleScreen:
    copy [WRAM_GAME_STATE], 0
    copy [WRAM_TITLESCREEN_STATE], STATE_WAITING
    copy [WRAM_PALETTE_NUM], 0
    copy [WRAM_CURRENT_PALETTE], PALETTE_0
    copy [WRAM_FADE_FRAME_COUNTDOWN], 8
    DisableLCD

    copy [rROMB0], 2

    ; load block 2
    
    ld bc, TitleTilesetStart
    ; load de with tileset rom midpoint
    ld hl, TitleTilesetStart
    ld de, $0800
    add hl, de
    ld d, h
    ld e, l
    ; set destination
    ld hl, $9000
    call LoadBytesToHLFromBCToDE

    ; load block 1

    ; load bc with midpoint + 1
    ld b, d
    ld c, e
    ; inc bc
    ; load de with tileset rom end
    ld hl, TitleTilesetStart
    ld de, TITLE_TILESET_SIZE
    add hl, de
    ld d, h
    ld e, l
    ; set destination
    ld hl, $8800
    call LoadBytesToHLFromBCToDE


    ld bc, TitleTilemapStart
    ; load de with tileset rom end
    ld hl, TitleTilemapStart
    ld de, TITLE_TILEMAP_SIZE
    add hl, de
    ld d, h
    ld e, l
    ; set destination
    ld hl, $9800
    call LoadBytesToHLFromBCToDE
    
    InitPallettes

    ld a, LCDCF_ON | LCDCF_WIN9C00 | LCDCF_WINOFF | LCDCF_BG8800 | LCDCF_BG9800 | LCDCF_OBJ16 | LCDCF_OBJOFF | LCDCF_BGON
    ld [rLCDC], a

    ; enable the vblank interrupt
    ld a, IEF_VBLANK
    ld [rIE], a

    ei

    ret 

UpdateTitleScreen:
    .vblank
        halt 
        nop
        ld a, [WRAM_IS_VBLANK]
        cp 1
        jr nz, .vblank

    copy [WRAM_IS_VBLANK], 0
    
    ; ;graphics
    ld a, [WRAM_CURRENT_PALETTE]
    ld [rBGP], a
    
    ; ;logic

    ld a, [WRAM_TITLESCREEN_STATE]
    cp STATE_WAITING ;waiting
    jr nz, .stateWaiting
        ; check for start button press
        WaitForStartPress
        ret
    .stateWaiting

    ;starting state

    ld a, [WRAM_FADE_FRAME_COUNTDOWN]
    cp 0
    jr z, .countdownContinues
        dec a
        ld [WRAM_FADE_FRAME_COUNTDOWN], a
        ret
    .countdownContinues

    ;countdown is over

    ld a, [WRAM_PALETTE_NUM]
    inc a
    ld [WRAM_PALETTE_NUM], a
    cp 3
    jr nc, .paletteShiftStillHappening
        ld hl, Palettes
        ld e, a
        xor a
        ld d, a
        add hl, de
        ld a, [hl]
        ld [WRAM_CURRENT_PALETTE], a
        copy [WRAM_FADE_FRAME_COUNTDOWN], FADE_ANIMATION_FRAMES
        ret
    .paletteShiftStillHappening
        call InitLevel
    ret

Palettes:
    db PALETTE_0
    db PALETTE_1
    db PALETTE_2
    db PALETTE_3


section "title-tileset", romx, bank[2]
TitleTilesetStart:
    incbin "graphics/titleset.chr"

section "title-tilemap", romx, bank[2]
TitleTilemapStart:
    incbin "graphics/titlemap.tlm"
    

export InitTitleScreen, UpdateTitleScreen