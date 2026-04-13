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