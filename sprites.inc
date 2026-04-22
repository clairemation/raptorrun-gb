if !def(SPRITES_INC)
def SPRITES_INC equ 1

rsreset
PLAYER_SPRITES  rb 4
SCORE_SPRITES_LINE_0    rb 5 ;text "score"
SCORE SPRITES_LINE_1    rb 4 ;4 digits


endc ;SPRITES_INC