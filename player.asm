include "hardware.inc"
include "utils.inc"
include "player-consts.inc"
include "wram.inc"
include "jump-table.inc"

def PLAYER equ(WRAM_PLAYER_STRUCT)

def STATE_PLAYING   equ(0)
def STATE_LOST  equ(1)

section "player-logic", rom0

UpdatePlayerGraphics:
    ; if dying state, draw bg over sprite
    ld a, [PLAYER + STATE]
    cp STATE_DYING
    jr nz, .isDying
        ld hl, _OAMRAM + OAMA_FLAGS
        set 7, [hl]
        ld hl, _OAMRAM + sizeof_OAM_ATTRS + OAMA_FLAGS
        ; inc hl ; + 2 for next sprite
        set 7, [hl]
        jr .dyingComparisonDone
    .isDying
        ld hl, _OAMRAM + OAMA_FLAGS
        res 7, [hl]
        ld hl, _OAMRAM + sizeof_OAM_ATTRS + OAMA_FLAGS
        ; inc hl ; + 2 for next sprite
        res 7, [hl]
    .dyingComparisonDone

    ;update player sprite to match state
    ld a, [PLAYER + STATE]
    ld hl, StateSpriteTable
    AddAtoHL
    ld b, [hl]
    copy [_OAMRAM + OAMA_TILEID], b
    
    ; update right-side sprite
    ; (next OAM sprite = tile + 2)
    ld a, b
    add a, 2
    ld b, a
    copy [_OAMRAM + sizeof_OAM_ATTRS + OAMA_TILEID], b

    ; update sprite position
    copy [_OAMRAM + OAMA_Y], [PLAYER + Y_POS]
    copy [_OAMRAM + sizeof_OAM_ATTRS + OAMA_Y], [PLAYER + Y_POS]
    ret

StateSpriteTable:
    db 0 ;standing
    db 4 ;rising
    db 8 ;flapping
    db 12 ;falling
    db 16 ;dying
    db 16 ;dead

UpdatePlayerLogic:
    CallJumpTableFunction [PLAYER + STATE], UpdateFuncTable
    ret


UpdateFuncTable:
    dw UpdateOnGround
    dw UpdateRising
    dw UpdateFlapping
    dw UpdateFalling
    dw UpdateDying
    dw UpdateDead


UpdateOnGround:
    UpdatePadInput WRAM_PAD_INPUT
    TestPadInput_Pressed WRAM_PAD_INPUT, PADF_A
    jr nz, .jumpIsPressed
        copy [PLAYER + SPEED], 40
        copy [PLAYER + STATE], STATE_RISING
    .jumpIsPressed
    ret


UpdateFlapping:
    ld a, [PLAYER + FLAP_COOLDOWN]
    ld b, a
    and a
    jr nz, .cooldownOver
        copy [PLAYER + STATE], STATE_FALLING
        call UpdateFalling
        ret
    .cooldownOver
    ld a, b
    dec a
    ld [PLAYER + FLAP_COOLDOWN], a

    call Fall
    ret


UpdateRising:
    ld a, [PLAYER + SPEED]
    ld c, a ;unscaled speed
    sra a
    sra a
    sra a
    ld b, a ;scaled speed

    ld a, [PLAYER + Y_POS]
    sub a, b
    ld [PLAYER + Y_POS], a    

    ; dec speed, if < 0, change state
    ld a, c ;unscaled speed
    dec a
    jr nc, .overflow
        copy [PLAYER + SPEED], 0
        copy [PLAYER + STATE], STATE_FALLING
        jr .overflowDone
    .overflow
        ld [PLAYER + SPEED], a
    .overflowDone

    ret


UpdateFalling:
    ; check for flap button press
    UpdatePadInput WRAM_PAD_INPUT
    TestPadInput_Pressed WRAM_PAD_INPUT, PADF_A
    jr nz, .jumpIsPressed
        copy [PLAYER + SPEED], 0
        copy [PLAYER + FLAP_COOLDOWN], 6
        copy [PLAYER + STATE], STATE_FLAPPING    
    .jumpIsPressed
    call Fall
    ret


Fall:
    ld a, [PLAYER + SPEED]
    ld c, a ;unscaled speed
    sra a
    sra a
    sra a
    ld b, a ;scaled speed

    ld a, [PLAYER + Y_POS]
    add a, b
    ld [PLAYER + Y_POS], a    

    .checkForGround
    cp 120
    jr z, .yGTOrEqualTo120
    jr nc, .yGTOrEqualTo120
    jr .yLessThan120
    .yGTOrEqualTo120
        copy [PLAYER + Y_POS], 120
        
        ;get current tile
        ld a, [WRAM_SCROLL_X] ;left edge of screen
        add a, 40 ;player X offset
        ;divide by 16 to get slot #
        srl a
        srl a
        srl a
        srl a

        ; check bouncer slot list
        ld hl, WRAM_BOUNCER_SPOTS
        ld e, a
        xor a
        ld d, a
        add hl, de ; WRAM_BOUNCER_SPOTS + player slot X

        ld a, [hl]
        ; if a != 0
        and a
        jr z, .aIsNotZero
            ;bounce
            copy [PLAYER + SPEED], 40
            copy [PLAYER + STATE], STATE_RISING
            call SquashBouncerAtHL
            jr .yComparisonDone
        .aIsNotZero
            ;land on ground
            copy [PLAYER + STATE], STATE_DYING
            copy [WRAM_LEVEL_STATE], STATE_LOST
            jr .yComparisonDone
    .yLessThan120
        ;increment unscaled speed
        ld a, c
        inc a
        ld [PLAYER + SPEED], a
    .yComparisonDone

    ret

UpdateDying:
    ld a, [PLAYER + SPEED]
    ld c, a ;unscaled speed
    sra a
    sra a
    sra a
    ld b, a ;scaled speed

    ld a, [PLAYER + Y_POS]
    add a, b
    ld [PLAYER + Y_POS], a    

    ; dec speed, if < 0, change state
    ld a, c ;unscaled speed
    sub a, 12
    jr nc, .overflow
        copy [PLAYER + SPEED], 0
        copy [PLAYER + STATE], STATE_DEAD
        jr .overflowDone
    .overflow
        ld [PLAYER + SPEED], a
    .overflowDone
    ret

UpdateDead:
    UpdatePadInput WRAM_PAD_INPUT
    TestPadInput_Pressed WRAM_PAD_INPUT, PADF_START
    jr nz, .startIsPressed
        call ResetLevel
    .startIsPressed
    ret

export UpdatePlayerGraphics, UpdatePlayerLogic