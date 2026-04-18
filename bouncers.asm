include "utils.inc"
include "wram.inc"
include "random.inc"

def TILEMAP_BASE_ADDRESS equ($9800)

macro PopulateNextBouncerSlot
    ; find tilemap address of next spot
            
    ld a, b
    ; add width of screen
    add a, 160
    ; divide by 16 to get slot index
    srl a
    srl a
    srl a
    srl a

    ;;;; add slot to update list
    ld b, a ;spot index

    ld a, [WRAM_NUM_BOUNCERS_TO_UPDATE] ;index in WRAM list
    ld c, a
    ld hl, WRAM_BOUNCER_INDICES_TO_UPDATE
    ld e, a
    xor a
    ld d, a
    add hl, de


    ld a, b ;spot index

    ld [hli], a ;add bouncer index to update list
    ld [hl], $ff ;eol sentinal value

    ;increment list count
    ld b, a ;slot index
    ld a, c ;update list count
    inc a
    ld [WRAM_NUM_BOUNCERS_TO_UPDATE], a
    ;;;;;;;;;;;

    ;;;;;;;; update slot

    ;get slot address
    ld a, b ;slot index
    
    ld hl, WRAM_BOUNCER_SPOTS
    
    ; add spot index to hl
    ld e, a
    xor a
    ld d, a
    add hl, de ; hl = spot address

    ;roll for next bouncer tile
    GetNextRandomValue WRAM_RANDOM
    cp 50
        jr c, .isTrike\@
    cp 100
        jr c, .isSkeleton\@
    cp 150
        jr c, .isFern\@
    jr .isEmpty\@
    
    .isTrike\@
        ld a, $08
        jr .randomComparisonDone\@
    .isSkeleton\@
        ld a, $0C
        jr .randomComparisonDone\@
    .isFern\@
        ld a, $14
        jr .randomComparisonDone\@
    .isEmpty\@
        ld a, $00
        jr .randomComparisonDone\@
    .randomComparisonDone\@

    ; load tile to slot address
    ld [hl], a
endm

;TODO: Fix bug where tile 1 and 3 get wrong id on last space
;uses c
macro Draw4TileChunkToBackgroundStartingAtTileAToMapPositionHL

    ; 1 3
    ; 2 4
    ld c, a

    ; tile 1
    copy [hli], a

    ; tile 3
    ld a, c
    add a, 2
    copy [hl], a
    
    ; one row down - 1 column = +31 tiles
    ld a, 31
    ld e, a
    xor a
    ld d, a
    add hl, de

    ld a, c
    inc a
    copy [hli], a

    add a, 2
    copy [hl], a
endm

macro KillSquashedSkeleton
    ;get second-leftmost bouncer slot index, e.g. scrollx / 16
    ld a, [WRAM_SCROLL_X]
    srl a
    srl a
    srl a
    srl a

    ; add index to slot base to get slot address
    ld hl, WRAM_BOUNCER_SPOTS
    ld e, a
    xor a
    ld d, a
    add hl, de
    inc hl

    ; if squashed skeleton, change to blank tile
    ld a, [hl]
    cp $10
    jr nz, .isSquashedSkeleton\@
        copy [hl], $00
        jr .doneWithComparison\@
    .isSquashedSkeleton\@
    .doneWithComparison\@
endm

section "bouncers", rom0
    InitBouncerLogic:
        copy [WRAM_BOUNCER_INDICES_TO_UPDATE], $ff
        xor a
        ld [WRAM_NUM_BOUNCERS_TO_UPDATE], a
        ret

    ;TODO: Update only on change
    UpdateBouncerGraphics:

        ld hl, WRAM_BOUNCER_INDICES_TO_UPDATE

        .bouncerUpdateLoop
            ;loop through update list
            
            ld a, [hl]

            cp $ff ;eol sentinel
            jr z, .bouncerUpdateLoopFinished
            
            push hl ;bouncer update list
            ld b, a ;bouncer slot index
            
            ;get address of new bouncer
            ld hl, WRAM_BOUNCER_SPOTS
            ld e, a
            xor a
            ld d, a
            add hl, de ;hl = slot address of new bouncer

            ld a, [hl] ;a = new bouncer tile
            ld c, a ;c = new bouncer tile

            ld hl, TILEMAP_BASE_ADDRESS

            ld a, b ;bouncer slot index
            sla a ; x2 to get 8x8 tile index
            
            ld e, a
            xor a
            ld d, a
            add hl, de ;hl = tilemap slot address x

            ld de, $01c0 ; vertical tiles
            add hl, de ;hl = final tilemap slot addy

            ld a, c ;bouncer tile

            Draw4TileChunkToBackgroundStartingAtTileAToMapPositionHL

            pop hl ;update list
            ld a, $ff
            ld [hl], a ;erase update list entry
            inc hl
            jr .bouncerUpdateLoop

        .bouncerUpdateLoopFinished
        xor a
        ld [WRAM_NUM_BOUNCERS_TO_UPDATE], a

        ret

    UpdateBouncers:
        ; when on slot border, e.g. scroll is a multiple of 16
        ld a, [WRAM_SCROLL_X]
        ld b, a
        and a, %00001111
        jr nz, .isOnSlotBorder

            PopulateNextBouncerSlot

            KillSquashedSkeleton

        .isOnSlotBorder
        ret

    SquashBouncerAtHLInIndexB:
        ld a, [hl]
        add a, 4
        ld [hl], a

        ;add to update list

        ;get list element address
        ld hl, WRAM_BOUNCER_INDICES_TO_UPDATE
        ld a, [WRAM_NUM_BOUNCERS_TO_UPDATE]
        ld e, a
        xor a
        ld d, a
        add hl, de ;address of update list element

        ;update list length
        inc a
        ld [WRAM_NUM_BOUNCERS_TO_UPDATE], a

        ld a, b ;index
        ld [hli], a
        ld [hl], $ff ;eol


        ret


export InitBouncerLogic, UpdateBouncerGraphics, UpdateBouncers, SquashBouncerAtHLInIndexB