include "utils.inc"
include "wram.inc"
include "random.inc"

rsreset
def BUBBLE_INDEX  rb 1
def SKELETON_INDEX  rb 1
def FERN_INDEX  rb 1

def BUBBLE_ODDS equ(10)
def SKELETON_ODDS   equ(20)
def FERN_ODDS   equ (30)
def TRIKE_ODDS  equ (10)


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

    call AddIndexBToUpdateList

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
    cp BUBBLE_ODDS
        jr c, .isBubble\@
    cp BUBBLE_ODDS + SKELETON_ODDS
        jr c, .isSkeleton\@
    cp BUBBLE_ODDS + SKELETON_ODDS + FERN_ODDS
        jr c, .isFern\@
    cp BUBBLE_ODDS + SKELETON_ODDS + FERN_ODDS + TRIKE_ODDS
        jr c, .isTrike\@
    jr .isEmpty\@
    
    .isBubble\@
        ld a, $60
        jr .randomComparisonDone\@
    .isSkeleton\@
        ld a, $0C
        jr .randomComparisonDone\@
    .isFern\@
        ld a, $14
        jr .randomComparisonDone\@
    .isTrike\@
        ld a, $08
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

;TODO: replace
macro KillSquashedSkeleton
    ld a, [WRAM_SQUASHED_SKELETON_INDEX]
    ld b, a

    call AddIndexBToUpdateList

    ; add index to slot base to get slot address
    ld hl, WRAM_BOUNCER_SPOTS
    ld e, b
    xor a
    ld d, a
    add hl, de

    ; change to blank tile
    copy [hl], $00
endm

section "bouncers", rom0
    InitBouncerLogic:
        ; initialize bouncer list
        ld hl, WRAM_BOUNCER_SPOTS
        ld b, 16
        .loop
            copy [hli], 0
            dec b
            jr nz, .loop

        copy [WRAM_SQUASHED_SKELETON_COUNTDOWN], $ff
        
        ; add first 11 slots to update list to clear them
        ld hl, WRAM_BOUNCER_INDICES_TO_UPDATE
        xor a
        ld b, a
        .clearFirstTenSlotsLoop
            copy [hli], b
            inc b
            ld a, b
            cp 11
            jr nz, .clearFirstTenSlotsLoop

        copy [hl], $ff
        copy [WRAM_NUM_BOUNCERS_TO_UPDATE], 11

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
            inc hl
            jr .bouncerUpdateLoop

        .bouncerUpdateLoopFinished
        xor a
        ld [WRAM_NUM_BOUNCERS_TO_UPDATE], a
        copy [WRAM_BOUNCER_INDICES_TO_UPDATE], $ff

        ret

    UpdateBouncers:
        ; populate next bouncer slot when scroll is on slot border, e.g. scroll is a multiple of 16

        ld a, [WRAM_SCROLL_X_FOREGROUND]
        ld b, a
        and a, %00001111
        jr nz, .isOnSlotBorder
            PopulateNextBouncerSlot
        .isOnSlotBorder

        ;kill squashed skeleton if countdown is over

        ld a, [WRAM_SQUASHED_SKELETON_COUNTDOWN]
        cp a, $ff ; $ff = no countdown active
        ret z ;no countdown active
        
        dec a
        ld [WRAM_SQUASHED_SKELETON_COUNTDOWN], a
        ret nz ;countdown not finished

        ;countdown finished
        KillSquashedSkeleton

        copy [WRAM_SQUASHED_SKELETON_COUNTDOWN], $ff
        ret

    SquashBouncerAtHLInIndexB:
        ld a, [hl]
        add a, 4
        ld [hl], a

        ;add to update list
        call AddIndexBToUpdateList

        ret

    AddIndexBToUpdateList:
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