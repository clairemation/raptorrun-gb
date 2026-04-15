if !def(UTILS_RGBINC)
def UTILS_RGBINC equ 1

macro DisableLCD
    ;wait for VBlank
    .wait_vblank\@
        ld a, [rLY]
        cp a, SCRN_Y
        jr nz, .wait_vblank\@

    ;turn LCD off
        xor a
        ld [rLCDC], a
endm

; copy /2 into /1 via a
macro copy
        ld a, \2
        ld \1, a
endm


macro AddAtoHL
        ld e, a
        xor a
        ld d, a
        add hl, de
endm

; \1 = source start \2 = source end \3 = dest start
macro LoadSeriesOfBytes
    ld bc, \1
    ld de, \2
    ld hl, \3
    call LoadBytesToHLFromBCToDE
endm

; draw all 4 tiles in background :
; \1 \3
; \2 \4
macro Draw4BackgroundTileChunk
        copy [hli], \1
        copy [hl], \3
        ld a, 31
        ld e, a
        xor a
        ld d, a
        add hl, de
        copy [hli], \2
        copy [hl], \4
endm

endc ;UTILS_RGBINC