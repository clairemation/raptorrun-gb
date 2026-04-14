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

            ; load bouncer tile
            ld a, [hl]

            ld c, a ; bouncer tile

            ld a, b

            ld hl, TILEMAP_BASE_ADDRESS

            sla a ; x2 to get 8x8 tile index
            ld e, a
            xor a
            ld d, a
            add hl, de

            ld de, $01c0 ; vertical tiles
            add hl, de

            ld a, c ; bouncer tile
            call Draw4TileChunkToBackgroundStartingAtTileAToMapPositionHL

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

                ld b, a ; x tile


                ; roll random number
                GetNextRandomValue WRAM_RANDOM
                cp 75
                jr nc, .bouncer

                    ld hl, WRAM_BOUNCER_SPOTS
                    
                    ; add spot index to hl
                    ld a, b ; 8x8 x tile
                    srl a ; /2 to get 16x16 spot index
                    ld e, a
                    xor a
                    ld d, a
                    add hl, de

                    copy [hli], $0C

                    jr .isMultiple

                .bouncer

                    ld hl, WRAM_BOUNCER_SPOTS
                    ld a, b

                    srl a
                    ld e, a
                    xor a
                    ld d, a
                    add hl, de
                    copy [hli], $00

            .isMultiple
            ret

        
        Draw4TileChunkToBackgroundStartingAtTileAToMapPositionHL:
            push bc

            ; 1 3
            ; 2 4
            ld b, a

            ; tile 1
            copy [hli], a

            ; tile 3
            ld a, b
            add a, 2
            copy [hl], a
            
            ; one row down - 1 column = +31 tiles
            ld a, 31
            ld e, a
            xor a
            ld d, a
            add hl, de

            ld a, b
            inc a
            copy [hli], a

            add a, 2
            copy [hl], a
        
            pop bc
            
            ret


export UpdateBouncerGraphics, UpdateBouncers