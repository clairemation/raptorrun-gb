include "wram.inc"
include "utils.inc"

section "vblank_interrupt", rom0[$0040]
    push af
    copy [WRAM_IS_VBLANK], 1
    pop af
    reti

section "lcd_interrupt", rom0[$0048]
    push af
    call LCDInterrupt
    pop af
    reti