include "utils.inc"
include "hardware.inc"
include "pad.inc"
include "wram.inc"
include "player-consts.inc"
include "random.inc"
include "game.inc"

def STATE_PLAYING   equ(0)
def STATE_LOSING  equ(1)
def STATE_LOST  equ (2)

def TEXT_LINE_0 equ (32 * 7)

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

section "level", rom0

    InitLevel:
        copy [WRAM_GAME_STATE], STATE_LEVEL
        copy [rROMB0], 1
        call InitGraphicsData
        ;enable lcd
        ld [rLCDC], a

        call ResetLevel

        ei

        ret

    

    ResetLevel:
        halt

        ClearTextLines

        ; init player struct
        copy [WRAM_LEVEL_STATE], STATE_PLAYING
        copy [WRAM_PLAYER_STRUCT + STATE], STATE_RISING
        copy [WRAM_PLAYER_STRUCT + X_POS], 40
        copy [WRAM_PLAYER_STRUCT + Y_POS], 120
        copy [WRAM_PLAYER_STRUCT + SPEED], 40

        ; initialize bouncer list
        ld hl, WRAM_BOUNCER_SPOTS
        ld b, 16
        .loop
            copy [hli], 0
            dec b
            jr nz, .loop


        ;; init random seed
        copy [WRAM_RANDOM], 1

        copy [WRAM_SCROLL_X], 0

            ret

    UpdateLevel:
        ;wait for vblank
        halt 
        nop

        ;;;;;; graphics ;;;;;;

        call UpdatePlayerGraphics
        
        copy [rSCX], [WRAM_SCROLL_X]

        call UpdateBouncerGraphics

        ;;;;;; logic ;;;;;;

        call UpdatePlayerLogic

        CallJumpTableFunction [WRAM_LEVEL_STATE], UpdateFuncTable

        ret

    UpdateFuncTable:
        dw UpdatePlaying
        dw UpdateLosing
        dw UpdateLost

    UpdatePlaying:
        ld hl, WRAM_SCROLL_X
        inc [hl]

        call UpdateBouncers

        ret 

    UpdateLosing:
        ;keep scrolling until at tile border
        ld a, [WRAM_SCROLL_X]
        ld b, a
        and a, %00000111 ;scrollx is multiple of 8
        cp 0
        jr nz, .isAtTileBorder
            call WriteLostMessage
            copy [WRAM_LEVEL_STATE], STATE_LOST
            ret
        .isAtTileBorder
        ld a, b
        inc a
        ld [WRAM_SCROLL_X], a
        call UpdateBouncers
        ret 

    UpdateLost:
        ret

    WriteLostMessage:
        halt 

        ld hl, _SCRN0 + TEXT_LINE_0 + 6 ;center at scrnx of 0, eyeballed
        
        ; add current scroll x tile
        ld a, [rSCX]
        srl a
        srl a
        srl a
        ld b, a ; scroll x tile
        ld e, a
        xor a
        ld d, a
        add hl, de

        ld de, GameOverText
        
        call WriteMessageAtDEToTileHL

        ld hl, _SCRN0 + TEXT_LINE_0 + 32 + 5

        ld a, b ; scroll x tile
        ld e, a
        xor a
        ld d, a
        add hl, de

        ld de, PressStartText

        call WriteMessageAtDEToTileHL
        ret 

    WriteMessageAtDEToTileHL:

        .loop
            ld a, [de]
            cp $3B ; semicolon - sentinal character
            jr z, .endloop
            cp 20
            ; jr nz, .space
            ;     ld a, 0
            ;     jr .spaceCompareDone
            ; .space
            add a, $3f
            .spaceCompareDone
            copy [hli], a
            inc de
            jr .loop
        .endloop
        ret


    LoseLevel:
        copy [WRAM_LEVEL_STATE], STATE_LOSING

        ; ld de, $3000
        ; xor a
        ; .loop
        ;     ld a, [de]
        ;     cp 0
        ;     jr z, .endloop
        ;     add a, $3f
        ;     copy [_SCRN0], a
        ;     inc de

        ; .endloop

        ret 

export InitLevel, ResetLevel, UpdateLevel, LoseLevel