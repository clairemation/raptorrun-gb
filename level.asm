include "utils.inc"
include "hardware.inc"
include "pad.inc"
include "wram.inc"
include "player-consts.inc"
include "random.inc"
include "game.inc"

def FIRST_LINE_INTERRUPT    equ(8)
def SECOND_LINE_INTERRUPT   equ(21)
def THIRD_LINE_INTERRUPT    equ(111)

rsreset
def STATE_RESETTING_STAGE_0 rb 1
def STATE_RESETTING_STAGE_1 rb 1
def STATE_RESETTING_STAGE_2 rb 1
def STATE_FADEIN    rb 1
def STATE_PLAYING   rb 1
def STATE_LOSING  rb 1
def STATE_LOST_STAGE_0  rb 1
def STATE_LOST_STAGE_1  rb 1
def STATE_WAITING   rb 1
def STATE_FADEOUT   rb 1

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

macro ClearTextLines2
    ; clear text lines with original lines from tilemap in rom
    ld hl, _SCRN0 + TEXT_LINE_0
    ld de, BGTileMap + TEXT_LINE_0
    ld b, 64
    .eraseScreenLoop\@
        copy [hli], [de]
        inc de
        sub b
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

;\1 = line number
macro EnableLineCompareInterrupt
    copy [rLYC], \1
    copy [rSTAT], STATF_LYC
endm

macro DisableLCDInterrupt
    ;turn hblank and line interrupts off
    copy [rLYC], 255
    xor a
    ld [rSTAT], a
endm

macro UpdatePaletteGraphics
    ld a, [WRAM_CURRENT_PALETTE]
    ld [rBGP], a
    ld [rOBP0], a
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
        ld a, LCDCF_ON | LCDCF_WIN9C00 | LCDCF_WINOFF | LCDCF_BG8800 | LCDCF_BG9800 | LCDCF_OBJ8 | LCDCF_OBJON | LCDCF_BGON
        ld [rLCDC], a

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
        dw UpdateFadeInGraphics
        dw UpdatePlayingGraphics
        dw UpdateLosingGraphics
        dw UpdateLostStage0Graphics
        dw UpdateLostStage1Graphics
        dw UpdateWaitingGraphics
        dw UpdateFadeOutGraphics


    UpdateResettingStage0Graphics:
        ClearTextLines2
        call WriteWordScore
        copy [WRAM_LEVEL_STATE], STATE_RESETTING_STAGE_1
        ret

    UpdateResettingStage1Graphics:
        call UpdateScrollGraphics
        call InitPlayerGraphics
        call UpdateScoreGraphics
        copy [WRAM_LEVEL_STATE], STATE_RESETTING_STAGE_2
        ret
        
    UpdateResettingStage2Graphics:
        ; never gets called
        ret

    UpdateFadeInGraphics:
        call UpdatePlayerGraphics
        UpdatePaletteGraphics
        ret

    UpdatePlayingGraphics:
        call UpdatePlayerGraphics
        call UpdateScrollGraphics
        call UpdateScoreGraphics
        ret

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

    UpdateFadeOutGraphics:
        call UpdateScrollGraphics
        UpdatePaletteGraphics
        ret

    UpdateScrollGraphics:
        copy [rSCX], 0 ;no scroll, for text at top of screen
        EnableLineCompareInterrupt FIRST_LINE_INTERRUPT

        call UpdateBouncerGraphics

        ret

    UpdateScoreGraphics:
        ld a, 16
        ld b, a ;x pos

        ld a, [WRAM_SCORE_THOUSANDS]
        call WriteNumberAtAToXPositionB

        inc b
        ld a, [WRAM_SCORE_HUNDREDS]
        call WriteNumberAtAToXPositionB

        inc b
        ld a, [WRAM_SCORE_TENS]
        call WriteNumberAtAToXPositionB

        inc b
        ld a, [WRAM_SCORE_ONES]
        call WriteNumberAtAToXPositionB

        

        ret

    UpdateLogicFuncTable:
        dw UpdateResettingStage0Logic
        dw UpdateResettingStage1Logic
        dw UpdateResettingStage2Logic
        dw UpdateFadeInLogic
        dw UpdatePlayingLogic
        dw UpdateLosingLogic
        dw UpdateLostStage0Logic
        dw UpdateLostStage1Logic
        dw UpdateWaitingLogic
        dw UpdateFadeOutLogic

    UpdateResettingStage0Logic:
        ;never gets called
        ret

    UpdateResettingStage1Logic:
        xor a
        ld [WRAM_SCROLL_X_FOREGROUND], a
        ld [WRAM_SCROLL_X_MIDGROUND], a
        ld [WRAM_SCROLL_X_BACKGROUND], a
        ld [WRAM_TOP_SCROLL_COUNTER], a
        ld [WRAM_SCORE_ONES], a
        ld [WRAM_SCORE_TENS], a
        ld [WRAM_SCORE_HUNDREDS], a
        ld [WRAM_SCORE_THOUSANDS], a

        call InitBouncerLogic

        ; init player struct
        copy [WRAM_PLAYER_STRUCT + STATE], STATE_RISING
        copy [WRAM_PLAYER_STRUCT + X_POS], 40
        copy [WRAM_PLAYER_STRUCT + Y_POS], 120
        copy [WRAM_PLAYER_STRUCT + SPEED], 40

        ;; init random seed
        copy [WRAM_RANDOM], 1

        ret

    UpdateResettingStage2Logic:
        copy [WRAM_DESTINATION_FADE], 3 ;normal
        copy [WRAM_LEVEL_STATE], STATE_FADEIN
        ret

    UpdateFadeInLogic:
        call UpdateScreenFade

        cp a, 1
        ret z ;continue if fade unfinished

        copy [WRAM_LEVEL_STATE], STATE_PLAYING
        ret
    
    UpdatePlayingLogic:
        call UpdatePlayerLogic
        call Scroll
        call IncrementScore
        ret 

    ;todo: stage no longer needed
    UpdateLosingLogic:
        ;keep scrolling to nearest half tile (to center text)
        ld a, [WRAM_SCROLL_X_BACKGROUND]
        and a, %00000111
        cp a, 4
        jr z, .positionNotReached
            call Scroll
            ret
        .positionNotReached

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
            copy [WRAM_DESTINATION_FADE], 0
            copy [WRAM_LEVEL_STATE], STATE_FADEOUT
        .startIsPressed
        ret

    UpdateFadeOutLogic:
        call UpdateScreenFade

        cp a, 1
        ret z ;continue loop if fade is active

        call ResetLevel
        ret

    Scroll:
        ld hl, WRAM_SCROLL_X_FOREGROUND
        inc [hl]

        ld a, [WRAM_TOP_SCROLL_COUNTER]
        inc a
        ld [WRAM_TOP_SCROLL_COUNTER], a

        and a, %00000011 ;every 4 frames
        jr nz, .every4thFrame
            ld a, [WRAM_SCROLL_X_BACKGROUND]
            inc a
            ld [WRAM_SCROLL_X_BACKGROUND], a
        .every4thFrame

        ld a, [WRAM_TOP_SCROLL_COUNTER]
        and a, %00000001 ;every other frame
        jr nz, .everyOtherFrame
            ld a, [WRAM_SCROLL_X_MIDGROUND]
            inc a
            ld [WRAM_SCROLL_X_MIDGROUND], a
        .everyOtherFrame

        call UpdateBouncers

        ret

    IncrementScore:
        ld a, [WRAM_SCORE_ONES]
        inc a
        cp $0a
        jr nz, .carryOne
            copy [WRAM_SCORE_ONES], 0
            ld a, [WRAM_SCORE_TENS]
            inc a
            cp $0a
            jr nz, .carryTen
                copy [WRAM_SCORE_TENS], 0
                ld a, [WRAM_SCORE_HUNDREDS]
                inc a
                cp $0a
                jr nz, .carryHundred
                    copy [WRAM_SCORE_HUNDREDS], 0
                    ld a, [WRAM_SCORE_THOUSANDS]
                    inc a
                    cp $0a
                    jr nz, .thousandsOverflow
                        ; just max out at 9999
                        copy [WRAM_SCORE_ONES], 9
                        copy [WRAM_SCORE_TENS], 9
                        copy [WRAM_SCORE_HUNDREDS], 9
                        copy [WRAM_SCORE_THOUSANDS], 9
                        ret
                    .thousandsOverflow
                    ld [WRAM_SCORE_THOUSANDS], a
                    ret
                .carryHundred
                ld [WRAM_SCORE_HUNDREDS], a
                ret
            .carryTen
            ld [WRAM_SCORE_TENS], a
            ret
        .carryOne
        ld [WRAM_SCORE_ONES], a

        ret

    WriteLostMessageLine0:
        ; add current scroll x tile
        ld a, [WRAM_SCROLL_X_BACKGROUND]
        srl a
        srl a
        srl a

        add a, 6 ; 5 tiles from left (eyeballed)
        ld b, a

        ld de, GameOverText
        
        ld c, TEXT_LINE_0

        call WriteMessageAtDEToColumnBAndVerticalOffsetC

        ret 

    WriteLostMessageLine1:

        ld a, [WRAM_SCROLL_X_BACKGROUND]
        srl a
        srl a
        srl a
        
        add a, 5 ; 4 tiles from left (eyeballed)
        ld b, a

        ld de, PressStartText

        ld a, TEXT_LINE_0
        add a, 32
        ld c, a

        call WriteMessageAtDEToColumnBAndVerticalOffsetC

        ret 

    WriteWordScore:

        ld de, ScoreText
        ld b, 10
        xor a
        ld c, a
        call WriteMessageAtDEToColumnBAndVerticalOffsetC
        
        ret

    LoseLevel:
        copy [WRAM_LEVEL_STATE], STATE_LOSING
        ret 

    LCDInterrupt:
        ;check if on target line
        ldh a, [rSTAT]
        bit 2, a
        ret z

        ld b, a

        ;enable next hblank
        copyHighToMemory [rSTAT], STATF_MODE00

        ;check for current hblank
        ld a, b
        and a, 3
        ret nz

        ldh a, [rLY]

        cp FIRST_LINE_INTERRUPT
        jr nz, .topSection
            copyHighToMemory [rSCX], [WRAM_SCROLL_X_MIDGROUND]
            EnableLineCompareInterrupt SECOND_LINE_INTERRUPT
            ret
        .topSection

        cp SECOND_LINE_INTERRUPT
        jr nz, .middleSection
            copyHighToMemory [rSCX], [WRAM_SCROLL_X_BACKGROUND]
            EnableLineCompareInterrupt THIRD_LINE_INTERRUPT
            ret
        .middleSection
            
        ;bottom Section i.e. rest of screen
        ;draw normal section scroll
        copyHighToMemory [rSCX], [WRAM_SCROLL_X_FOREGROUND]

        DisableLCDInterrupt
        ret

export InitLevel, ResetLevel, UpdateLevel, LoseLevel, LCDInterrupt