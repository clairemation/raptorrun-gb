include "hardware.inc"
include "utils.inc"
include "player-consts.inc"
include "wram.inc"
include "jump-table.inc"


section "player-logic", rom0

UpdatePlayerGraphics:
    ld a, [WRAM_PLAYER_STRUCT + STATE]
    ld hl, StateSpriteTable

    AddAtoHL

    ld b, [hl]

    copy [_OAMRAM + OAMA_TILEID], b
    
    ; right-side sprite
    ld a, b
    add a, 2
    ld b, a
    copy [_OAMRAM + sizeof_OAM_ATTRS + OAMA_TILEID], b

    ; update sprite position
    copy [_OAMRAM + OAMA_Y], [WRAM_PLAYER_STRUCT + Y_POS]
    copy [_OAMRAM + sizeof_OAM_ATTRS + OAMA_Y], [WRAM_PLAYER_STRUCT + Y_POS]
    ret

StateSpriteTable:
    db 0 ;standing
    db 4 ;rising
    db 8 ;flapping
    db 12 ;falling

UpdatePlayerLogic:

    ;;;;;; logic ;;;;;;

    CallJumpTableFunction [WRAM_PLAYER_STRUCT + STATE], UpdateFuncTable

    ret


UpdateFuncTable:
    dw UpdateOnGround
    dw UpdateRising
    dw UpdateFlapping
    dw UpdateFalling


UpdateOnGround:
    UpdatePadInput WRAM_PAD_INPUT
    TestPadInput_Pressed WRAM_PAD_INPUT, PADF_A
    jr nz, .jumpIsPressed
        copy [WRAM_PLAYER_STRUCT + SPEED], 40
        copy [WRAM_PLAYER_STRUCT + STATE], STATE_RISING
    .jumpIsPressed
    ret


UpdateFlapping:
    ld a, [WRAM_PLAYER_STRUCT + FLAP_COOLDOWN]
    ld b, a
    and a
    jr nz, .cooldownOver
        copy [WRAM_PLAYER_STRUCT + STATE], STATE_FALLING
        call UpdateFalling
        ret
    .cooldownOver
    ld a, b
    dec a
    ld [WRAM_PLAYER_STRUCT + FLAP_COOLDOWN], a

    call UpdateFalling
    ret


UpdateRising:
    ld a, [WRAM_PLAYER_STRUCT + SPEED]
    ld c, a ;unscaled speed
    sra a
    sra a
    sra a
    ld b, a ;scaled speed

    ld a, [WRAM_PLAYER_STRUCT + Y_POS]
    sub a, b
    ld [WRAM_PLAYER_STRUCT + Y_POS], a    

    ; dec speed, if < 0, change state
    ld a, c ;unscaled speed
    dec a
    jr nc, .overflow
        copy [WRAM_PLAYER_STRUCT + SPEED], 0
        copy [WRAM_PLAYER_STRUCT + STATE], STATE_FALLING
        jr .overflowDone
    .overflow
        ld [WRAM_PLAYER_STRUCT + SPEED], a
    .overflowDone

    ret


UpdateFalling:

    ; if in falling state, check for button press
    ; (check state because flapping state uses this function too)
    ld a, [WRAM_PLAYER_STRUCT + STATE]
    cp a, STATE_FALLING
    jr nz, .jumpIsPressed
        UpdatePadInput WRAM_PAD_INPUT
        TestPadInput_Pressed WRAM_PAD_INPUT, PADF_A
        jr nz, .jumpIsPressed
            copy [WRAM_PLAYER_STRUCT + SPEED], 0
            copy [WRAM_PLAYER_STRUCT + FLAP_COOLDOWN], 6
            copy [WRAM_PLAYER_STRUCT + STATE], STATE_FLAPPING    
        .jumpIsPressed


    ld a, [WRAM_PLAYER_STRUCT + SPEED]
    ld c, a ;unscaled speed
    sra a
    sra a
    sra a
    ld b, a ;scaled speed

    ld a, [WRAM_PLAYER_STRUCT + Y_POS]
    add a, b
    ld [WRAM_PLAYER_STRUCT + Y_POS], a    

    .checkForGround
    cp 120
    jr z, .yGTOrEqualTo120
    jr nc, .yGTOrEqualTo120
    jr .yLessThan120
    .yGTOrEqualTo120
        copy [WRAM_PLAYER_STRUCT + Y_POS], 120
        copy [WRAM_PLAYER_STRUCT + STATE], STATE_ONGROUND
        jr .yComparisonDone
    .yLessThan120
        ld a, c
        inc a
        ld [WRAM_PLAYER_STRUCT + SPEED], a
    .overflow2Done
    .yComparisonDone

    ret

export UpdatePlayerGraphics, UpdatePlayerLogic