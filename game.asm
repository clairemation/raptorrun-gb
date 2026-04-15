include "utils.inc"
include "hardware.inc"
include "pad.inc"
include "wram.inc"
include "player-consts.inc"
include "random.inc"


def TILEMAP_BASE_ADDRESS equ($9800)

section "update", rom0

    Init:
        call InitLevel
        ret

    Update:
        call UpdateLevel
        ret

    InitLevel:
        call InitGraphicsData
        ;enable lcd
        ld [rLCDC], a
        ; init player struct
        copy [WRAM_PLAYER_STRUCT + STATE], STATE_ONGROUND
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


        ; init random seed to not be 0
        ld a, [WRAM_RANDOM]
        and a
        jr nz, .isZero
            inc a
            ld [WRAM_RANDOM], a
        .isZero

        InitPadInput WRAM_PAD_INPUT

        copy [WRAM_SCROLL_X], 0

        ; enable the vblank interrupt
        ld a, IEF_VBLANK
        ld [rIE], a
        ei

        ret


    UpdateLevel:
        ;wait for vblank
        halt 

        ;;;;;; graphics ;;;;;;

        call UpdatePlayerGraphics
        
        copy [rSCX], [WRAM_SCROLL_X]

        call UpdateBouncerGraphics

        ;;;;;; logic ;;;;;;

        call UpdatePlayerLogic

        ld hl, WRAM_SCROLL_X
        inc [hl]

        call UpdateBouncers

        ret

export Init, Update