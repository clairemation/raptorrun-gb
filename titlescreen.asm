include "hardware.inc"
include "utils.inc"
include "wram.inc"
include "game.inc"
include "graphics-size.inc"

def TITLE_TILEMAP_SIZE    equ (1024)
def TITLE_TILESET_SIZE    equ (3152)

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

macro CheckForStartPress
    TestPadInput_AnyButtonsPressed WRAM_PAD_INPUT, PADF_START | PADF_A | PADF_B
    jr z, .startIsPressed\@
        PlayStartSound
        copy [WRAM_TITLESCREEN_STATE], STATE_STARTING
    .startIsPressed\@
endm

macro CheckForDPadPress
    TestPadInput_Pressed WRAM_PAD_INPUT, PADF_LEFT
    jr nz, .leftIsPressed
        copy [_OAMRAM + OAMA_X], 14 ;move cursor
        xor a
        ld [WRAM_SELECTION], a
        jr .checkOver
    .leftIsPressed
    
    TestPadInput_Pressed WRAM_PAD_INPUT, PADF_RIGHT
    jr nz, .rightIsPressed
        copy [_OAMRAM + OAMA_X], 64 ;move cursor
        copy [WRAM_SELECTION], 1
    .rightIsPressed
    .checkOver
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
    xor a
    ld [WRAM_GAME_STATE], a
    ld [WRAM_SELECTION], a
    copy [WRAM_TITLESCREEN_STATE], STATE_WAITING

    InitPallettes
    call InitScreenFade
    copy [WRAM_DESTINATION_FADE], 6

    DisableLCD

    copy [rROMB0], 2

    ;load block 0
    ld bc, UIGraphicsData
    ld de, UIGraphicsData
    ld hl, 16
    add hl, de
    ld d, h
    ld e, l
    ld hl, $8000
    call LoadBytesToHLFromBCToDE

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

    ; load bc with midpoint
    ld b, d
    ld c, e
    ; load de with tileset rom end
    ld hl, TitleTilesetStart
    ld de, TITLE_TILESET_SIZE
    add hl, de
    ld d, h
    ld e, l
    ; set destination
    ld hl, $8800
    call LoadBytesToHLFromBCToDE

    ;load the rest with font tiles
    copy [rROMB0], 3
    ld bc, FontTiles
    inc bc ;tiles come out corrupted if I don't do this?
    ld de, ROM_END
    inc hl
    call LoadBytesToHLFromBCToDE
    copy [rROMB0], 2

    ;load tilemap
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

    call InitOAM

    ld a, $84
    ld bc, TitleText
    ld hl, 32 * 16
    call WriteStringAtBCToTileIndexHLWithCharsetOffsetA

    ;init cursor
    copy [_OAMRAM + OAMA_TILEID], 0
    copy [_OAMRAM + OAMA_X], 14
    copy [_OAMRAM + OAMA_Y], 145
    copy [_OAMRAM + OAMA_FLAGS], OAMF_PAL0

    ld a, LCDCF_ON | LCDCF_WIN9C00 | LCDCF_WINOFF | LCDCF_BG8800 | LCDCF_BG9800 | LCDCF_OBJ8 | LCDCF_OBJON | LCDCF_BGON
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
    call WaitForVBlank
    
    CallJumpTableFunction [WRAM_TITLESCREEN_STATE], UpdateFunctionTable
    
    ret


UpdateFunctionTable:
    dw UpdateWaiting
    dw UpdateStarting

UpdateWaiting:
    jp nz, .stateWaiting
        UpdatePadInput WRAM_PAD_INPUT
        CheckForDPadPress
        CheckForStartPress
        ret
    .stateWaiting
    ret 

UpdateStarting:
    ; graphics
    ld a, [WRAM_CURRENT_PALETTE]
    ldh [rBGP], a
    ldh [rOBP0], a

    ;logic

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
    
section "title-text-data", romx, bank[2]
    TitleText:
        db "  PLAY  INSTRUCTIONS;"

section "ui-sprite", romx, bank[2]
    UIGraphicsData:
        DB $80,$80,$E0,$E0,$F8,$F8,$FE,$FE
        DB $F8,$F8,$E0,$E0,$80,$80,$00,$00

export InitTitleScreen, UpdateTitleScreen