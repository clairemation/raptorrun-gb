include "wram.inc"

section "utils", rom0

LoadBytesToHLFromBCToDE:
    .load_tile
        ; load byte
        ld a, [bc]
        inc bc
        ld [hli], a
        
        ; check current source address against last
        ld a, b
        cp a, d
        jr z, .highByteMatches
            jr .load_tile
        .highByteMatches
            ld a, c
            cp a, e
            jr z, .checkOver
        jr nz, .load_tile
        .checkOver
    ret

WaitForVBlank:
.haltLoop
    halt 
    nop
    ld a, [WRAM_IS_VBLANK]
    cp 0
    jr z, .haltLoop

    xor a
    ld [WRAM_IS_VBLANK], a
    
ret

export LoadBytesToHLFromBCToDE, WaitForVBlank