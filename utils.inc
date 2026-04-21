if !def(UTILS_RGBINC)
def UTILS_RGBINC equ 1

macro Breakpoint
        ld b, b
endm

macro DisableLCD
    ;wait for VBlank
    .wait_vblank\@
        ldh a, [rLY]
        cp a, SCRN_Y
        jr nz, .wait_vblank\@

    ;turn LCD off
        xor a
        ldh [rLCDC], a
endm

; copy /2 into /1 via a
macro copy
        ld a, \2
        ld \1, a
endm

macro copyHighToMemory
        ld a, \2
        ldh \1, a
endm

macro copyHighFromMemory
        ldh a, \2
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

; \1 = function index
; \2 = function table address
macro CallJumpTableFunction
    ld a, \1
    ld hl, \2
    ld d, 0
    ld e, a
    add hl, de
    add hl, de ;address is 2bytes

    ld a, [hli]
    ld h, [hl]
    ld l, a

    ld de, .callReturnAddress\@
    push de
    jp hl
    .callReturnAddress\@
endm

endc ;UTILS_RGBINC