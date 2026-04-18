include "wram.inc"
include "utils.inc"

def FADE_ANIMATION_FRAMES   equ(4)

def PALETTE_0  equ(%11100100)
def PALETTE_1  equ(%11111001)
def PALETTE_2  equ(%11111110)
def PALETTE_3  equ(%11111111)

section "fadescreen", rom0

    InitScreenFade:
        xor a
        ld [WRAM_PALETTE_NUM], a
        copy [WRAM_CURRENT_PALETTE], PALETTE_0
        copy [WRAM_FADE_FRAME_COUNTDOWN], 8
        copy [WRAM_FADE_IS_ACTIVE], 1
        ret

    UpdateScreenFade:
        ld a, [WRAM_FADE_FRAME_COUNTDOWN]
        cp 0
        jr z, .countdownContinues
            dec a
            ld [WRAM_FADE_FRAME_COUNTDOWN], a
            ret
        .countdownContinues

        ;countdown is over

        ld a, [WRAM_PALETTE_NUM]
        inc a
        ld [WRAM_PALETTE_NUM], a
        cp 4
        jr nc, .paletteShiftStillHappening
            ld hl, Palettes
            ld e, a
            xor a
            ld d, a
            add hl, de
            ld a, [hl]
            ld [WRAM_CURRENT_PALETTE], a
            copy [WRAM_FADE_FRAME_COUNTDOWN], FADE_ANIMATION_FRAMES
            ret
        .paletteShiftStillHappening

        xor a
        ld [WRAM_FADE_IS_ACTIVE], a

        ret 

    Palettes:
        db PALETTE_0
        db PALETTE_1
        db PALETTE_2
        db PALETTE_3

export InitScreenFade, UpdateScreenFade