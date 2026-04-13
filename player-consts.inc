if !def(PLAYER_CONSTS_INC)
def PLAYER_CONSTS_INC equ 1

rsreset
def STATE_ONGROUND  rb 1 ; 0
def STATE_RISING    rb 1 ; 1
def STATE_FLAPPING  rb 1 ; 2
def STATE_FALLING   rb 1 ; 3

;player struct
rsreset
def STATE   rb 1
def X_POS   rb 1
def Y_POS   rb 1
def SPEED   rb 1
def FLAP_COOLDOWN   rb 1
def sizeof_PLAYER_STRUCT   rb 0

endc ;PLAYER_CONSTS_INC

