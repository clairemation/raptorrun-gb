include "utils.inc"
include "wram.inc"
include "random.inc"

def TILEMAP_BASE_ADDRESS equ($9800)

section "bouncers", rom0

    UpdateBouncerGraphics:
        ; for each bouncer in list, render all 4 tiles
        xor a
        ld b, a ; bouncer list index

        .drawBouncersLoop
            ; get bouncer list item address
            ld a, b ; bouncer list index
            ld hl, WRAM_BOUNCER_SPOTS
            ld e, a
            xor a
            ld d, a
            add hl, de

            ; load bouncer item
            ld a, [hl]


            ; if !=0, draw bouncer tiles
            and a
            jr z, .isBouncer
                ld a, b

                ld hl, TILEMAP_BASE_ADDRESS

                sla a ; x2 to get 8x8 tile index
                ld e, a
                xor a
                ld d, a
                add hl, de

                ld de, $01c0 ; vertical tiles
                add hl, de

                Draw4BackgroundTileChunk $0C, $0D, $0E, $0F ;draw bouncer

                jr .doneWithBouncerCheck

            .isBouncer
                ld a, b

                ld hl, TILEMAP_BASE_ADDRESS

                sla a ; x2 to get 8x8 tile index
                ld e, a
                xor a
                ld d, a
                add hl, de

                ld de, $01c0 ; vertical tiles
                add hl, de

                Draw4BackgroundTileChunk $00, $01, $02, $03 ;draw bg tile

            .doneWithBouncerCheck
            inc b
            ld a, b
            cp a, 16
            jr nz, .drawBouncersLoop

        ret

        UpdateBouncers:
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


                ; roll random number
                GetNextRandomValue WRAM_RANDOM
                cp 75
                jr nc, .bouncer

                    ld hl, WRAM_BOUNCER_SPOTS
                    ld a, b ; bouncer spot list index
                    
                    srl a
                    ld e, a
                    xor a
                    ld d, a
                    add hl, de
                    copy [hli], 1
                    copy [hl], 1

                    jr .isMultiple

                .bouncer

                    ld hl, WRAM_BOUNCER_SPOTS
                    ld a, b

                    srl a
                    ld e, a
                    xor a
                    ld d, a
                    add hl, de
                    copy [hli], 0
                    copy [hl], 0

            .isMultiple
            ret



export UpdateBouncerGraphics, UpdateBouncers