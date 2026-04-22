include "wram.inc"
include "utils.inc"

section "text", rom0

    ; use when screen scroll is wrapping around
    WriteMessageAtDEToColumnBAndVerticalOffsetC:

    .loop
        ld a, [de]
        cp $3B ; semicolon - sentinal character
        ret z ; exit if end of string
        add a, $3f ;offset from ascii value to tile index
        copyHighToMemory [HRAM_SCRATCH_BYTES], a ;tile index

        ;backup de
        push de

        ;calculate hl

        ld a, b ;x position aka column
        and a, %00011111 ;keep x position masked to wraparound values of 0-31
        ld b, a

        ; add tile base to x position
        ld hl, _SCRN0
        ld e, b
        xor a
        ld d, a
        add hl, de

        ; add y offset
        ld e, c
        xor a
        ld d, a
        add hl, de

        ; load tile
        copyHighFromMemory [hl], [HRAM_SCRATCH_BYTES]

        ;restore de
        pop de

        inc de

        inc b

        jr .loop

    ret

export WriteMessageAtDEToColumnBAndVerticalOffsetC