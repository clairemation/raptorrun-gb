include "hardware.inc"
include "utils.inc"
include "player-consts.inc"
include "wram.inc"
include "jump-table.inc"


section "player-logic", rom0

UpdatePlayerGraphics:
    ;update player sprite to match state
    ld a, [WRAM_PLAYER_STRUCT + STATE]
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

    call Fall
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
    ; check for flap button press
    UpdatePadInput WRAM_PAD_INPUT
    TestPadInput_Pressed WRAM_PAD_INPUT, PADF_A
    jr nz, .jumpIsPressed
        copy [WRAM_PLAYER_STRUCT + SPEED], 0
        copy [WRAM_PLAYER_STRUCT + FLAP_COOLDOWN], 6
        copy [WRAM_PLAYER_STRUCT + STATE], STATE_FLAPPING    
    .jumpIsPressed
    call Fall
    ret


Fall:
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
            copy [WRAM_PLAYER_STRUCT + SPEED], 40
            copy [WRAM_PLAYER_STRUCT + STATE], STATE_RISING
            call SquashBouncerAtHL
            jr .yComparisonDone
        .aIsNotZero
            ;land on ground
            copy [WRAM_PLAYER_STRUCT + STATE], STATE_ONGROUND
            jr .yComparisonDone
    .yLessThan120
        ;increment unscaled speed
        ld a, c
        inc a
        ld [WRAM_PLAYER_STRUCT + SPEED], a
    .yComparisonDone

    ret

export UpdatePlayerGraphics, UpdatePlayerLogic