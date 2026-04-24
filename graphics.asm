include "hardware.inc"

section "graphics-functions", rom0

    InitOAM:
        ld c, OAM_COUNT
        ld hl, _OAMRAM
        ld de, sizeof_OAM_ATTRS
        .init_oam
            ld [hl], 0
            add hl, de
            dec c
            jr nz, .init_oam
        ret

    InitPallettes:
        ; init the palettes
        ld a, %11100100
        ldh [rBGP], a
        ldh [rOBP0], a
        ld a, %00011011
        ldh [rOBP1], a
        ret

export InitOAM, InitPallettes