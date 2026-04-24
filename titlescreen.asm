include "hardware.inc"
include "utils.inc"
include "wram.inc"
include "game.inc"

def TITLE_TILEMAP_SIZE    equ (1024)
def TITLE_TILESET_SIZE    equ (3712)

def STATE_WAITING   equ(0)
def STATE_STARTING  equ(1)

def PALETTE_NORMAL  equ(%11100100)

macro InitPallettes
    ; init the palettes
    ld a, PALETTE_NORMAL
    ldh [rBGP], a
    ldh [rOBP0], a
    ld a, %00011011
    ldh [rOBP1], a
endm

macro WaitForStartPress
    UpdatePadInput WRAM_PAD_INPUT
    TestPadInput_AnyButtonsPressed WRAM_PAD_INPUT, PADF_START | PADF_A | PADF_B
    jr z, .startIsPressed\@
        PlayStartSound
        copy [WRAM_TITLESCREEN_STATE], STATE_STARTING
    .startIsPressed\@
endm

macro PlayStartSound
    copyHighToMemory [rNR10], $15
    copyHighToMemory [rNR11], $80
    copyHighToMemory [rNR12], $f8
    copyHighToMemory [rNR13], $0b
    copyHighToMemory [rNR14], $c5
endm

section "titlescreen", rom0
InitTitleScreen:
    copy [WRAM_GAME_STATE], 0
    copy [WRAM_TITLESCREEN_STATE], STATE_WAITING

    InitPallettes
    call InitScreenFade
    copy [WRAM_DESTINATION_FADE], 6

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

    ld a, LCDCF_ON | LCDCF_WIN9C00 | LCDCF_WINOFF | LCDCF_BG8800 | LCDCF_BG9800 | LCDCF_OBJ16 | LCDCF_OBJOFF | LCDCF_BGON
    ldh [rLCDC], a

    ; enable the vblank interrupt
    ld a, IEF_VBLANK
    ldh [rIE], a

    copy [rNR52], AUDENA_ON
    copy [rNR50], $77
    copy [rNR51], $ff
    
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
    ldh [rBGP], a
    
    ; ;logic

    ld a, [WRAM_TITLESCREEN_STATE]
    cp STATE_WAITING ;waiting
    jr nz, .stateWaiting
        WaitForStartPress
        ret
    .stateWaiting

    ;starting state - fade out

    call UpdateScreenFade ;sets a to 1 or 0 if fade is active or finished, respectively
    ; continue loop if fade is active
    cp a, 1
    ret z
        
    ;else call init level (ending the loop)
    call InitLevel
    ret


section "title-tileset", romx, bank[2]
TitleTilesetStart:
    incbin "graphics/titleset.chr"

section "title-tilemap", romx, bank[2]
TitleTilemapStart:
    incbin "graphics/titlemap.tlm"
    

export InitTitleScreen, UpdateTitleScreen