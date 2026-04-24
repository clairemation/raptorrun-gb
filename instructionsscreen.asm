include "hardware.inc"
include "utils.inc"
include "wram.inc"
include "game.inc"
include "graphics-size.inc"

def TITLE_TILEMAP_SIZE    equ (1024)
def TITLE_TILESET_SIZE    equ (3152)

rsreset
def STATE_OPENING rb 1
def STATE_WAITING   rb 1
def STATE_RETURNING_TO_TITLESCREEN  rb 1


macro CheckForStartPress
    UpdatePadInput WRAM_PAD_INPUT
    TestPadInput_AnyButtonsPressed WRAM_PAD_INPUT, PADF_START | PADF_A | PADF_B
    jr z, .startIsPressed\@
        copy [WRAM_DESTINATION_FADE], 0
        copy [WRAM_INSTRUCTIONS_SCREEN_STATE], STATE_RETURNING_TO_TITLESCREEN
    .startIsPressed\@
endm

section "instructions-screen", rom0
InitInstructionsScreen:
    copy [WRAM_GAME_STATE], STATE_INSTRUCTIONSSCREEN
    copy [WRAM_INSTRUCTIONS_SCREEN_STATE], STATE_OPENING

    DisableLCD

    copy [WRAM_DESTINATION_FADE], 3


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
    
    ld a, [WRAM_INSTRUCTIONS_SCREEN_STATE]

    cp a, STATE_OPENING
    jr nz, .opening
        ld a, [WRAM_CURRENT_PALETTE]
        ld [rBGP], a
        ld [rOBP0], a

        call UpdateScreenFade
        cp 1
        ret z
        copy [WRAM_INSTRUCTIONS_SCREEN_STATE], STATE_WAITING
        ret
    .opening
    cp a, STATE_WAITING
    jr nz, .waiting
        CheckForStartPress
        ret
    .waiting
    ;exiting
    ld a, [WRAM_CURRENT_PALETTE]
    ld [rBGP], a
    ld [rOBP0], a

    call UpdateScreenFade
    cp 1
    ret z
    call InitTitleScreen
    ret
    
    ret


section "instructions-text-data", romx, bank[2]
    InstructionsText:
        db "/INSTRUCTIONS//YOU ARE A RAPTOR AND/YOUR PREY IS ACROSS/A HUGE TAR PIT.//BOUNCE ON OBJECTS/TO AVOID FALLING/INTO THE TAR.//PRESS A TO FLAP YOUR/WINGS TO SLOW YOUR/DESCENT AND TIME/YOUR LANDINGS.;"

export InitInstructionsScreen, UpdateInstructionsScreen