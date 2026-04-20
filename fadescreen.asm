include "wram.inc"
include "utils.inc"

def FADE_ANIMATION_FRAMES   equ(4)

def PALETTE_LIGHTEST    equ(%00000000)
def PALETTE_LIGHTER  equ(%01000000)
def PALETTE_LIGHT  equ(%10010000)
def PALETTE_NORMAL  equ(%11100100)
def PALETTE_DARK  equ(%11111001)
def PALETTE_DARKER  equ(%11111110)
def PALETTE_DARKEST  equ(%11111111)

section "fadescreen", rom0

    InitScreenFade:
        copy [WRAM_CURRENT_PALETTE_INDEX], 3 ;normal
        copy [WRAM_CURRENT_PALETTE], PALETTE_NORMAL
        copy [WRAM_FADE_FRAME_COUNTDOWN], 8
        ret

    UpdateScreenFade:
        ld a, [WRAM_FADE_FRAME_COUNTDOWN]
        cp 0
        jr z, .countdownContinues
            dec a
            ld [WRAM_FADE_FRAME_COUNTDOWN], a
            ld a, 1 ;return 1 for active fade
            ret
        .countdownContinues

        ;countdown is over

        ld a, [WRAM_CURRENT_PALETTE_INDEX]
        ld b, a
        ld a, [WRAM_DESTINATION_FADE]
        cp a, b
        jr c, .destinationIsLower
        jr z, .destinationIsSame
        ; jr .destinationIsHigher
        .destinationIsHigher
            ld a, [WRAM_CURRENT_PALETTE_INDEX]
            inc a
            ld [WRAM_CURRENT_PALETTE_INDEX], a
            jr .destinationCheckOver
        .destinationIsLower
            ld a, [WRAM_CURRENT_PALETTE_INDEX]
            dec a
            ld [WRAM_CURRENT_PALETTE_INDEX], a
            jr .destinationCheckOver
        .destinationIsSame
            ;shift is over
            xor a ;return 0 if shift is over
            ret
        .destinationCheckOver

        ld hl, Palettes
        ld e, a
        xor a
        ld d, a
        add hl, de
        ld a, [hl]
        ld [WRAM_CURRENT_PALETTE], a
        copy [WRAM_FADE_FRAME_COUNTDOWN], FADE_ANIMATION_FRAMES
        
        ld a, 1 ;return 1 if shift is still active

        ret 

    Palettes:
        db PALETTE_LIGHTEST
        db PALETTE_LIGHTER
        db PALETTE_LIGHT
        db PALETTE_NORMAL
        db PALETTE_DARK
        db PALETTE_DARKER
        db PALETTE_DARKEST

export InitScreenFade, UpdateScreenFade