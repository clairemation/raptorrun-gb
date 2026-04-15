include "hardware.inc"
include "utils.inc"
include "wram.inc"

def TITLE_TILEMAP_SIZE    equ (1024)
def TITLE_TILESET_SIZE    equ (2688)

macro InitPallettes
    ; init the palettes
    ld a, %11100100
    ld [rBGP], a
    ld [rOBP0], a
    ld a, %00011011
    ld [rOBP1], a
endm

section "titlescreen", rom0
InitTitleScreen:
    copy [WRAM_GAME_STATE], 0

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

    ret 

UpdateTitleScreen:
    ; check for start button press
    UpdatePadInput WRAM_PAD_INPUT
    TestPadInput_Pressed WRAM_PAD_INPUT, PADF_START
    jr nz, .startIsPressed
        copy [WRAM_GAME_STATE], 1  
        call InitLevel
    .startIsPressed
    ret


section "title-tileset", romx, bank[2]
TitleTilesetStart:
    incbin "graphics/titleset.chr"

section "title-tilemap", romx, bank[2]
TitleTilemapStart:
    incbin "graphics/titlemap.tlm"
    

export InitTitleScreen, UpdateTitleScreen