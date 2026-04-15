macro GetNextRandomValueFromLFSR8

    ld d, a
    ld e, a

    ; xor a bunch of bits (taps)

    ;bit 5
    sla e
    sla e
    xor a, e

    ; bit 4
    sla e
    xor a, e

    ; bit 3
    sla e
    xor a, e

    ; shift left while carrying new bit
    rla
    rl d

    ld a, d
endm

; \1 = LFSR8 address
macro GetNextRandomValue
    ld a, [\1]
    GetNextRandomValueFromLFSR8
    ld [\1], a
endm