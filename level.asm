include "utils.inc"
include "hardware.inc"
include "pad.inc"
include "wram.inc"
include "player-consts.inc"
include "random.inc"
include "game.inc"

def STATE_PLAYING   equ(0)
def STATE_LOST  equ(1)

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

        ld a, [WRAM_LEVEL_STATE]
        cp STATE_PLAYING
        jr nz, .isPlayingState
            ld hl, WRAM_SCROLL_X
            inc [hl]
        .isPlayingState

        call UpdateBouncers

        ret

export InitLevel, ResetLevel, UpdateLevel