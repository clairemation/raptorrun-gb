include "hardware.inc"
include "utils.inc"
include "player-consts.inc"
include "wram.inc"
include "random.inc"

def PLAYER equ(WRAM_PLAYER_STRUCT)

def STATE_PLAYING   equ(0)
def STATE_LOST  equ(1)

macro PlayFlap
    copyHighToMemory [rNR41], $33
    copyHighToMemory [rNR42], $f0
    copyHighToMemory [rNR43], $80
    copyHighToMemory [rNR44], $c0
endm

macro PlayBounce
    copyHighToMemory [rNR10], $14
    copyHighToMemory [rNR11], $4c
    copyHighToMemory [rNR12], $f1
    copyHighToMemory [rNR13], $9d
    copyHighToMemory [rNR14], $c0
endm

macro PlayCrunch
    copyHighToMemory [rNR41], $14
    copyHighToMemory [rNR42], $f1
    copyHighToMemory [rNR43], $52
    copyHighToMemory [rNR44], $c0
endm

macro PlayFernCrunch
    copyHighToMemory [rNR41], $00
    copyHighToMemory [rNR42], $f1
    copyHighToMemory [rNR43], $40
    copyHighToMemory [rNR44], $c0
endm

macro PlayPop
    copyHighToMemory [rNR41], $0c
    copyHighToMemory [rNR42], $f1
    copyHighToMemory [rNR43], $32
    copyHighToMemory [rNR44], $c0
endm

macro PlayLose
    copyHighToMemory [rNR10], $1c
    copyHighToMemory [rNR11], $c0
    copyHighToMemory [rNR12], $f7
    copyHighToMemory [rNR13], $3c
    copyHighToMemory [rNR14], $c5
endm


macro Die
    ;set sprite priority flags to appear behind bg
    ld hl, BOTTOM_LEFT_SPRITE_ADDRESS + OAMA_FLAGS
    set 7, [hl]
    ld hl, BOTTOM_RIGHT_SPRITE_ADDRESS + OAMA_FLAGS
    set 7, [hl]

    copy [PLAYER + STATE], STATE_DYING
endm

section "player-logic", rom0

InitPlayerGraphics:
    ; set sprite priority flags to appear in front of bg
    ld hl, BOTTOM_LEFT_SPRITE_ADDRESS + OAMA_FLAGS
    res 7, [hl]
    ld hl, BOTTOM_RIGHT_SPRITE_ADDRESS + OAMA_FLAGS
    res 7, [hl]

    ret

UpdatePlayerGraphics:

    ;update player sprite to match state
    ld a, [PLAYER + STATE]
    ld hl, StateSpriteTable
    AddAtoHL
    
    ld b, [hl]
    copy [TOP_LEFT_SPRITE_ADDRESS + OAMA_TILEID], b
    inc b
    copy [BOTTOM_LEFT_SPRITE_ADDRESS + OAMA_TILEID], b
    inc b
    copy [TOP_RIGHT_SPRITE_ADDRESS + OAMA_TILEID], b
    inc b
    copy [BOTTOM_RIGHT_SPRITE_ADDRESS + OAMA_TILEID], b

    ; update sprite position
    ld a, [PLAYER + Y_POS]
    ld [TOP_LEFT_SPRITE_ADDRESS + OAMA_Y], a
    ld [TOP_RIGHT_SPRITE_ADDRESS + OAMA_Y], a
    add a, 8
    ld [BOTTOM_LEFT_SPRITE_ADDRESS + OAMA_Y], a
    ld [BOTTOM_RIGHT_SPRITE_ADDRESS + OAMA_Y], a
    
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


UpdateFalling:
    ; check for flap button press
    UpdatePadInput WRAM_PAD_INPUT
    TestPadInput_Pressed WRAM_PAD_INPUT, PADF_A
    jr nz, .jumpIsPressed
        copy [PLAYER + SPEED], 0
        copy [PLAYER + FLAP_COOLDOWN], 6
        copy [PLAYER + STATE], STATE_FLAPPING
        PlayFlap
        GetNextRandomValue WRAM_RANDOM ;mix up random seed
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
    cp 125
    jr z, .yGTOrEqualTo125
    jr nc, .yGTOrEqualTo125
    jp .yLessThan125
    .yGTOrEqualTo125
        copy [PLAYER + Y_POS], 125
        
        ;get current tile
        ld a, [WRAM_SCROLL_X_FOREGROUND] ;left edge of screen
        add a, 40 ;player X offset
        ;divide by 16 to get slot #
        srl a
        srl a
        srl a
        srl a

        ld b, a ;slot index

        ; check bouncer slot list
        ld hl, WRAM_BOUNCER_SPOTS
        ld e, a
        xor a
        ld d, a
        add hl, de ; WRAM_BOUNCER_SPOTS + player slot X

        ld a, [hl]
        and a

        cp a, $60
        jr z, .isBubble
        cp a, $0c
        jr z, .isSkeleton
        cp a, $14
        jr z, .isFern
        cp a, $08
        jr z, .isTrike
        jp .isEmpty
        .isBubble
            PlayPop
            call SquashBouncerAtHLInIndexB
            copy [WRAM_SQUASHED_SKELETON_INDEX], b
            copy [WRAM_SQUASHED_SKELETON_COUNTDOWN], 8
            copy [PLAYER + SPEED], 30
            copy [PLAYER + STATE], STATE_RISING
            ret
        .isSkeleton
            PlayCrunch
            call SquashBouncerAtHLInIndexB
            ;set up squashed skeleton animation
            copy [WRAM_SQUASHED_SKELETON_INDEX], b
            copy [WRAM_SQUASHED_SKELETON_COUNTDOWN], 8
            copy [PLAYER + SPEED], 30
            copy [PLAYER + STATE], STATE_RISING
            ret
        .isFern
            PlayFernCrunch
            call SquashBouncerAtHLInIndexB
            copy [PLAYER + SPEED], 37
            copy [PLAYER + STATE], STATE_RISING
            ret
        .isTrike
            PlayBounce
            copy [PLAYER + SPEED], 40
            copy [PLAYER + STATE], STATE_RISING
            ret
        .isEmpty
            Die
            ret
    .yLessThan125
        ;increment unscaled speed
        ld a, c
        inc a
        ld [PLAYER + SPEED], a

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

    cp 135
    jr z, .yGTOrEqualTo130
    jr nc, .yGTOrEqualTo130
    jr .yLessThan130
    .yGTOrEqualTo130
        copy [PLAYER + Y_POS], 135
        PlayLose
        copy [PLAYER + STATE], STATE_DEAD
        call LoseLevel
        
    .yLessThan130
    ret

UpdateDead:
    ret

export InitPlayerGraphics, UpdatePlayerGraphics, UpdatePlayerLogic