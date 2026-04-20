include "utils.inc"
include "hardware.inc"
include "pad.inc"
include "wram.inc"
include "player-consts.inc"
include "random.inc"
include "game.inc"

rsreset
def STATE_RESETTING_STAGE_0 rb 1
def STATE_RESETTING_STAGE_1 rb 1
def STATE_RESETTING_STAGE_2 rb 1
def STATE_RESETTING_STAGE_3 rb 1
def STATE_FADEIN    rb 1
def STATE_PLAYING   rb 1
def STATE_LOSING  rb 1
def STATE_LOST_STAGE_0  rb 1
def STATE_LOST_STAGE_1  rb 1
def STATE_WAITING   rb 1

def TEXT_LINE_0 equ (32 * 6)

macro ClearTextLines
    ; clear text lines
    ld hl, _SCRN0 + TEXT_LINE_0
    xor a
    ld b, a
    .eraseScreenLoop\@
        xor a
        ld [hli], a
        inc b
        ld a, b
        cp a, 64
        jr nz, .eraseScreenLoop\@
endm

macro CheckForOutOfVBlank
    ld a, [rLY]
    cp 144
    jr nc, .outOfVblank\@
        ld b,b
    .outOfVblank\@
    ld [HRAM_SCRATCH_BYTES], a
endm

macro EnableLineCompareInterrupt
    copy [rLYC], 32
    copy [rSTAT], STATF_LYC
endm

macro DisableLCDInterrupt
    ;turn hblank and line interrupts off
    copy [rLYC], 255
    xor a
    ld [rSTAT], a
endm

section "level", rom0

    InitLevel:
        copy [WRAM_GAME_STATE], STATE_LEVEL
        copy [rROMB0], 1
        call InitGraphicsData

        ;setup linecompare interrupts
        copy [rLYC], 255
        xor a
        ld [rSTAT], a
        ld a, IEF_VBLANK | IEF_LCDC
        ld [rIE], a

        ;enable lcd
        ld a, LCDCF_ON | LCDCF_WIN9C00 | LCDCF_WINOFF | LCDCF_BG8800 | LCDCF_BG9800 | LCDCF_OBJ16 | LCDCF_OBJON | LCDCF_BGON
        ld [rLCDC], a

        call InitPlayer

        call ResetLevel

        ei

        ret

    

    ResetLevel:
        copy [WRAM_LEVEL_STATE], STATE_RESETTING_STAGE_0

        ret

    UpdateLevel:
        ;wait for vblank
        call WaitForVBlank

        ;;;;;; graphics ;;;;;;
    
        CallJumpTableFunction [WRAM_LEVEL_STATE], UpdateGraphicsFuncTable

        ;;;;;; logic ;;;;;;

        CallJumpTableFunction [WRAM_LEVEL_STATE], UpdateLogicFuncTable

        ret

    UpdateGraphicsFuncTable:
        dw UpdateResettingStage0Graphics
        dw UpdateResettingStage1Graphics
        dw UpdateResettingStage2Graphics
        dw UpdateResettingStage3Graphics
        dw UpdateFadeInGraphics
        dw UpdatePlayingGraphics
        dw UpdateLosingGraphics
        dw UpdateLostStage0Graphics
        dw UpdateLostStage1Graphics
        dw UpdateWaitingGraphics


    UpdateResettingStage0Graphics:
        ClearTextLines
        copy [WRAM_LEVEL_STATE], STATE_RESETTING_STAGE_1
        ret

    UpdateResettingStage1Graphics:
        ret
        
    UpdateResettingStage2Graphics:
        copy [WRAM_LEVEL_STATE], STATE_RESETTING_STAGE_3
        ret
    
    UpdateResettingStage3Graphics:
        ret

    UpdateFadeInGraphics:
        call UpdatePlayerGraphics
        ld a, [WRAM_CURRENT_PALETTE]
        ld [rBGP], a
        ld [rOBP0], a
        ret

    UpdatePlayingGraphics:
        call UpdatePlayerGraphics
        call UpdateScrollGraphics
        
        ret

    ;todo: don't need this stage anymore?
    UpdateLosingGraphics:
        call UpdateScrollGraphics
        ret 

    UpdateLostStage0Graphics:
        call UpdateScrollGraphics
        call WriteLostMessageLine0
        copy [WRAM_LEVEL_STATE], STATE_LOST_STAGE_1
        ret

    UpdateLostStage1Graphics:
        call UpdateScrollGraphics
        call WriteLostMessageLine1
        copy [WRAM_LEVEL_STATE], STATE_WAITING
        ret

    UpdateWaitingGraphics:
        call UpdateScrollGraphics
        ret

    UpdateScrollGraphics:
        copy [rSCX], [WRAM_SCROLL_X_TOP]

        call UpdateBouncerGraphics

        EnableLineCompareInterrupt

        ret

    UpdateLogicFuncTable:
        dw UpdateResettingStage0Logic
        dw UpdateResettingStage1Logic
        dw UpdateResettingStage2Logic
        dw UpdateResettingStage3Logic
        dw UpdateFadeInLogic
        dw UpdatePlayingLogic
        dw UpdateLosingLogic
        dw UpdateLostStage0Logic
        dw UpdateLostStage1Logic
        dw UpdateWaitingLogic

    UpdateResettingStage0Logic:
        ret

    UpdateResettingStage1Logic:
        xor a
        ld [WRAM_SCROLL_X], a
        ld [WRAM_SCROLL_X_TOP], a

        call InitBouncerLogic

        ; init player struct
        copy [WRAM_PLAYER_STRUCT + STATE], STATE_RISING
        copy [WRAM_PLAYER_STRUCT + X_POS], 40
        copy [WRAM_PLAYER_STRUCT + Y_POS], 120
        copy [WRAM_PLAYER_STRUCT + SPEED], 40


        ;; init random seed
        copy [WRAM_RANDOM], 1

        copy [WRAM_SCROLL_X], 0
        copy [WRAM_TOP_SCROLL_COUNTER], 0

        copy [WRAM_LEVEL_STATE], STATE_RESETTING_STAGE_2
        ret

    UpdateResettingStage2Logic:
        ret

    UpdateResettingStage3Logic:
        copy [WRAM_DESTINATION_FADE], 3 ;normal
        copy [WRAM_LEVEL_STATE], STATE_FADEIN
        ret

    UpdateFadeInLogic:
        call UpdateScreenFade

        cp a, 1
        ret z ;continue if fade unfinished

        copy [WRAM_LEVEL_STATE], STATE_PLAYING

    
    UpdatePlayingLogic:
        call UpdatePlayerLogic
        call Scroll
        ret 

    ;todo: stage no longer needed
    UpdateLosingLogic:
        copy [WRAM_LEVEL_STATE], STATE_LOST_STAGE_0
        ret 

    UpdateLostStage0Logic:
        ret

    UpdateLostStage1Logic:
        ret

    UpdateWaitingLogic:
        UpdatePadInput WRAM_PAD_INPUT
        TestPadInput_Pressed WRAM_PAD_INPUT, PADF_START
        jr nz, .startIsPressed
            call ResetLevel
        .startIsPressed
        ret

    Scroll:
        ld hl, WRAM_SCROLL_X
        inc [hl]

        ld a, [WRAM_TOP_SCROLL_COUNTER]
        inc a
        ld [WRAM_TOP_SCROLL_COUNTER], a

        and a, %00000011 ;every four frames

        jr nz, .every4thFrame
            ld a, [WRAM_SCROLL_X_TOP]
            inc a
            ld [WRAM_SCROLL_X_TOP], a
        .every4thFrame

        call UpdateBouncers

        ret

    WriteLostMessageLine0:
        ; add current scroll x tile
        ld a, [WRAM_SCROLL_X]
        srl a
        srl a
        srl a

        add a, 6 ; 5 tiles from left (eyeballed)
        and a, %00011111 ; mask column to wraparound values of 0-31
        ld b, a

        ld de, GameOverText
        
        ld c, TEXT_LINE_0

        call WriteMessageAtDEToColumnBAndVerticalOffsetC

        ret 

    WriteLostMessageLine1:

        ld a, [WRAM_SCROLL_X]
        srl a
        srl a
        srl a
        
        add a, 5 ; 4 tiles from left (eyeballed)
        and a, %00011111 ; mask column to wraparound values of 0-31
        ld b, a

        ld de, PressStartText

        ld a, TEXT_LINE_0
        add a, 32
        ld c, a

        call WriteMessageAtDEToColumnBAndVerticalOffsetC

        ret 

    ; use when screen scroll is wrapping around
    WriteMessageAtDEToColumnBAndVerticalOffsetC:

        .loop
            ld a, [de]
            cp $3B ; semicolon - sentinal character
            jr z, .endloop
            add a, $3f ;offset from ascii value to tile index
            copyHighToMemory [HRAM_SCRATCH_BYTES], a

            ;backup de
            copy [HRAM_SCRATCH_BYTES + 1], d
            copy [HRAM_SCRATCH_BYTES + 2], e 

            ;calculate hl

            ; add tile base to x position
            ld hl, _SCRN0
            ld e, b
            xor a
            ld d, a
            add hl, de

            ; add y offset
            ld e, c
            xor a
            ld d, a
            add hl, de

            ; load tile
            ldh a, [HRAM_SCRATCH_BYTES]
            ld [hl], a

            ;restore de
            copyHighFromMemory d, [HRAM_SCRATCH_BYTES + 1]
            copyHighFromMemory e, [HRAM_SCRATCH_BYTES + 2]

            inc de

            ld a, b
            inc a
            and a, %00011111 ;keep column masked to wraparound values of 0-31
            ld b, a

            jr .loop
        .endloop
        ret

    LoseLevel:
        copy [WRAM_LEVEL_STATE], STATE_LOSING
        ret 

    LCDInterrupt:
        ;check if on target line
        ld a, [rSTAT]
        bit 2, a
        jr z, .return

        ld b, a

        ;enable next hblank
        copy [rSTAT], STATF_MODE00

        ;check for current hblank
        ld a, b
        and a, 3
        jr nz, .return

        ;draw normal section scroll
        copy [rSCX], [WRAM_SCROLL_X]

        DisableLCDInterrupt

        .return
        ret

export InitLevel, ResetLevel, UpdateLevel, LoseLevel, LCDInterrupt