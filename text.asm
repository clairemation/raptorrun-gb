include "wram.inc"
include "utils.inc"

section "text", rom0

    ;use when scx and scy are 0, when text may flow to successive lines
    WriteStringAtBCToTileIndexHLWithCharsetOffsetA:
        ldh [HRAM_SCRATCH_BYTES], a ;save charsetOffset

        .loop
            ;load next character
            ld a, [bc]

            cp $3b ;semicolon - eos
            ret z
            
            cp $2f ;forward slash - line break
            jr nz, .linebreak
                ld de, 32
                add hl, de
                ld a, l
                and a, %11100000 ;round down to nearest 32, i.e. left side of screen
                ld l, a
                inc bc
                jr .loop
            .linebreak

            cp a, $20 ;space
            jr nz, .space
                xor a ;space character gets tile #0
                jr .specialCharacterCheckDone
            .space
            cp a, $2e ;period
            jr nz, .period
                ld a, $e9
                jr .specialCharacterCheckDone
            .period

            ;apply charset offset
            ld d, a
            ldh a, [HRAM_SCRATCH_BYTES]
            add a, d
            .specialCharacterCheckDone 
            
            push hl; save hl

            ld de, _SCRN0
            add hl, de
            ld [hl], a

            pop hl

            inc bc
            inc hl

            jr .loop


        ret

    ; use when screen scroll may be wrapping around
    WriteMessageAtDEToColumnBAndVerticalOffsetC:

    .loop
        ld a, [de]
        cp $3B ; semicolon - sentinal character
        ret z ; exit if end of string

        cp a, $20 ;space
        jr nz, .space
            xor a ;space character gets tile #0
            jr .specialCharacterCheckDone
        .space
        add a, $3f ;offset from ascii value to tile index
        .specialCharacterCheckDone

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

    WriteNumberAtAToXPositionB:
        add a, $80 + 26 ;offset to tile index
        ld c, a ;tile index

        ; add tile base to x position for tile address
        ld hl, _SCRN0
        ld e, b
        xor a
        ld d, a
        add hl, de
        
        ld a, c
        ld [hl], a

        ret

export WriteMessageAtDEToColumnBAndVerticalOffsetC, WriteNumberAtAToXPositionB, WriteStringAtBCToTileIndexHLWithCharsetOffsetA