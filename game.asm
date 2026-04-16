include "utils.inc"
include "hardware.inc"
include "pad.inc"
include "wram.inc"
include "player-consts.inc"
include "random.inc"


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
        cp a, 0
        jr nz, .LevelState
        .TitleScreenState
            call UpdateTitleScreen
            ret
        .LevelState
            call UpdateLevel
        ret

export Init, Update