include "utils.inc"
include "hardware.inc"
include "pad.inc"
include "wram.inc"
include "player-consts.inc"
include "random.inc"
include "game.inc"


def TILEMAP_BASE_ADDRESS equ($9800)

section "game", rom0
    
    Init:
        InitPadInput WRAM_PAD_INPUT
        copy [WRAM_IS_VBLANK], 0

        call InitTitleScreen
        ret

    Update:
        ; cheaper than a jump table, for now
        ld a, [WRAM_GAME_STATE]
        cp a, STATE_LEVEL
        jr nz, .level
            call UpdateLevel
            ret
        .level
        cp a, STATE_TITLESCREEN
        jr nz, .titleScreen
            call UpdateTitleScreen
            ret
        .titleScreen
        call UpdateInstructionsScreen
        ret

export Init, Update