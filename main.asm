include "hardware.inc"
include "graphics-size.inc"

def ROM_HEADER_ADDRESS  equ $0100
def ROM_MAIN_ADDRESS    equ $0150


section "header", rom0[ROM_HEADER_ADDRESS]
    di
    jp main
    ds (ROM_MAIN_ADDRESS - @), 0


section "main", rom0[ROM_MAIN_ADDRESS]
    main:
        ld sp, $cfff ;put sp in top of wram bank 0
        call Init
        .loop
            call Update
            jr .loop