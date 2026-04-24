if !def(GAME_INC)
def GAME_INC equ 1

rsreset
def STATE_TITLESCREEN   rb 1
def STATE_INSTRUCTIONSSCREEN    rb 1
def STATE_LEVEL rb 1

endc ; GAME_INC