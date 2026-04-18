include "utils.inc"
include "wram.inc"
include "random.inc"

def TILEMAP_BASE_ADDRESS equ($9800)

macro PopulateNextBouncerSlot
    ; find tilemap address of next spot
            
    ld a, b
    ; add width of screen
    add a, 160
    ; divide by 8 to get scroll tile
    srl a
    srl a
    srl a

    ld b, a ; x tile

    ;get bouncer slot address
    ld hl, WRAM_BOUNCER_SPOTS
    ; add spot index to hl
    ld a, b ; 8x8 x tile
    srl a ; /2 to get 16x16 spot index
    ld e, a
    xor a
    ld d, a
    add hl, de ; hl = spot address

    GetNextRandomValue WRAM_RANDOM
    cp 50
        jr c, .isTrike\@
    cp 100
        jr c, .isSkeleton\@
    cp 150
        jr c, .isFern\@
    jr .isEmpty\@
    
    .isTrike\@
        copy [hli], $08
        jr .randomComparisonDone\@
    .isSkeleton\@
        copy [hli], $0C
        jr .randomComparisonDone\@
    .isFern\@
        copy [hli], $14
        jr .randomComparisonDone\@
    .isEmpty\@
        copy [hli], $00
        jr .randomComparisonDone\@
    .randomComparisonDone\@
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
    ;TODO: Update only on change
    UpdateBouncerGraphics:
        ; for each slot in list, render all 4 tiles
        xor a
        ld b, a ; bouncer slot list index

        .drawSlotLoop
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
            Draw4TileChunkToBackgroundStartingAtTileAToMapPositionHL ; uses c

            inc b
            ld a, b
            cp a, 16
            jr nz, .drawSlotLoop

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

    SquashBouncerAtHL:
        ld a, [hl]
        add a, 4
        ld [hl], a
        ret


export UpdateBouncerGraphics, UpdateBouncers, SquashBouncerAtHL