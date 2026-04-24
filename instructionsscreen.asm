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
    UpdatePadInput WRAM_PAD_INPUT
    TestPadInput_AnyButtonsPressed WRAM_PAD_INPUT, PADF_START | PADF_A | PADF_B
    jr z, .startIsPressed\@
        call InitTitleScreen
    .startIsPressed\@
endm

section "instructions-screen", rom0
InitInstructionsScreen:
    copy [WRAM_GAME_STATE], STATE_INSTRUCTIONSSCREEN

    InitPallettes
    call InitScreenFade
    copy [WRAM_DESTINATION_FADE], 6

    DisableLCD

    call InitOAM

    call ClearBackground

    ld a, $84
    ld bc, InstructionsText
    ld hl, 0
    call WriteStringAtBCToTileIndexHLWithCharsetOffsetA

    ld a, LCDCF_ON | LCDCF_WIN9C00 | LCDCF_WINOFF | LCDCF_BG8800 | LCDCF_BG9800 | LCDCF_OBJ8 | LCDCF_OBJOFF | LCDCF_BGON
    ldh [rLCDC], a

    ; enable the vblank interrupt
    ld a, IEF_VBLANK
    ldh [rIE], a
    
    ei

    ret 

UpdateInstructionsScreen:
    call WaitForVBlank
    
    CheckForStartPress
    
    ret


section "instructions-text-data", romx, bank[2]
    InstructionsText:
        db "/INSTRUCTIONS//YOU ARE A RAPTOR AND/YOUR PREY IS ACROSS/A HUGE TAR PIT.//BOUNCE ON OBJECTS/TO AVOID FALLING/INTO THE TAR.//PRESS A TO FLAP YOUR/WINGS TO SLOW YOUR/DESCENT AND TIME/YOUR LANDINGS.;"

export InitInstructionsScreen, UpdateInstructionsScreen