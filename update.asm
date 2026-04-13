include "utils.inc"
include "hardware.inc"
include "pad.inc"
include "wram.inc"
include "player-consts.inc"
include "random.inc"


def TILEMAP_BASE_ADDRESS equ($9800)
def NEXT_SPOT_RELATIVE_TILE_POSITION equ(32 * 14)

section "update", rom0
    Init:
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
        ld b, 32
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


    Update:
        ;wait for vblank
        halt 

        ;;;;;; graphics ;;;;;;

        call UpdatePlayerGraphics
        
        copy [rSCX], [WRAM_SCROLL_X]

        ;;;;;; logic ;;;;;;

        call UpdatePlayerLogic

        ld hl, WRAM_SCROLL_X
        inc [hl]


        ld a, [WRAM_SCROLL_X]
        ld b, a
        and a, %00001111
        jr nz, .isMultiple

            ; is a multiple of 16, i.e. on tile border

            ; find tilemap address of next spot
            
            ld a, b
            ; add width of screen
            add a, 160
            ; divide by 8 to get scroll tile
            srl a
            srl a
            srl a

            ld b, a ; index in bouncer spot list

            ld l, a
            xor a
            ld h, a
            ld de, NEXT_SPOT_RELATIVE_TILE_POSITION
            add hl, de
            ld de, TILEMAP_BASE_ADDRESS
            add hl, de

            ; roll random number
            GetNextRandomValue WRAM_RANDOM
            cp 75
            jr nc, .noBouncer
                Draw4BackgroundTileChunk $0C, $0D, $0E, $0F ;draw bouncer

                ld hl, WRAM_BOUNCER_SPOTS
                ld a, b ; bouncer spot list index
                
                ld e, a
                xor a
                ld d, a
                add hl, de
                copy [hli], 1
                copy [hl], 1

                jr .isMultiple

            .noBouncer

                Draw4BackgroundTileChunk $00, $01, $02, $03 ;draw bg tile

                    ld hl, WRAM_BOUNCER_SPOTS
                    ld a, b

                    ld e, a
                    xor a
                    ld d, a
                    add hl, de
                    copy [hli], 0
                    copy [hl], 0

        .isMultiple

        ret

export Init, Update