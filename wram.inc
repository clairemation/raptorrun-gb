if !def(WRAM_INC)
def WRAM_INC equ 1

include "player-consts.inc"
include "pad.inc"

rsset _RAM

def WRAM_GAME_STATE rb 1
def WRAM_PAD_INPUT rb sizeof_PAD_INPUT
def WRAM_RANDOM   rb 1
def WRAM_IS_VBLANK  rb 1
def MODE_RAM    rb 1

rsset MODE_RAM
;titlescreen mode
def WRAM_TITLESCREEN_STATE  rb 1
def WRAM_PALETTE_NUM    rb 1
def WRAM_CURRENT_PALETTE    rb 1
def WRAM_FADE_FRAME_COUNTDOWN   rb 1

rsset MODE_RAM
; level mode
def WRAM_PLAYER_STRUCT rb sizeof_PLAYER_STRUCT
def WRAM_SCROLL_X rb 1
def WRAM_BOUNCER_SPOTS   rb 16


endc ;WRAM_INC

