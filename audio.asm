include "utils.inc"
include "hardware.inc"
include "wram.inc"

section "audio", rom0

    PlaySoundAtHL:
        ld a, [hli] ;first byte = channel
        dec a ;to zero-based
        ld b, a
        WriteHLToRamAddress WRAM_NEXT_SOUND_ADDRESS
        ld a, b
        CallJumpTableFunction a, PlaySoundFuncTable
        ret

    PlaySoundFuncTable:
        dw PlayCh1SoundAtHL
        dw PlayCh2SoundAtHL
        dw PlayCh3SoundAtHL
        dw PlayCh4SoundAtHL
        

    PlayCh1SoundAtHL:
        ReadHLFromRamAddress WRAM_NEXT_SOUND_ADDRESS

        copyHighToMemory [rNR10], [hli]
        copyHighToMemory [rNR11], [hli]
        copyHighToMemory [rNR12], [hli]
        copyHighToMemory [rNR13], [hli]
        copyHighToMemory [rNR14], [hl]
        ret

    PlayCh2SoundAtHL:
        ret 

    PlayCh3SoundAtHL:
        ret

    PlayCh4SoundAtHL:
        ReadHLFromRamAddress WRAM_NEXT_SOUND_ADDRESS

        copyHighToMemory [rNR41], [hli]
        copyHighToMemory [rNR42], [hli]
        copyHighToMemory [rNR43], [hli]
        copyHighToMemory [rNR44], [hl]
        ret

; data - first byte is audio channel #

section "audio-data", rom0
    StartSound: db $01, $15, $80, $f8, $0b, $c5
    BounceSound: db $01, $14, $4c, $f1, $9d, $c0
    LoseSound:   db $01, $1c, $c0, $f7, $3c, $c5
    FlapSound:   db $04, $33, $f0, $80, $c0
    SkeletonCrunchSound: db $04, $14, $f1, $52, $c0
    FernCrunchSound: db $04, $00, $f1, $40, $c0
    PopSound:    db $04, $0c, $f1, $32, $c0
    SpeedupSound1:  db $01, $15, $0d, $f1, $ce, $c5
    SpeedupSound2:  db $01, $15, $0d, $f1, $0b, $c6
    SpeedupSound3:  db $01, $26, $00, $f0, $21, $c7

export PlaySoundAtHL, StartSound, BounceSound, LoseSound, FlapSound, SkeletonCrunchSound, FernCrunchSound, PopSound, SpeedupSound1, SpeedupSound2, SpeedupSound3