if !def(WRAM_INC)
def WRAM_INC equ 1

include "player-consts.inc"
include "pad.inc"

rsset _RAM

def WRAM_PLAYER_STRUCT rb sizeof_PLAYER_STRUCT
def WRAM_PAD_INPUT rb sizeof_PAD_INPUT
def WRAM_SCROLL_X rb 1
def WRAM_RANDOM   rb 1
def WRAM_BOUNCER_SPOTS   rb 16
def WRAM_END rb 0


endc ;WRAM_INC

