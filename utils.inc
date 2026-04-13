if !def(UTILS_RGBINC)
def UTILS_RGBINC equ 1


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