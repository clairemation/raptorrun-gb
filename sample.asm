include "utils.inc"
include "hardware.inc"


def TILES_COUNT equ (384)
def BYTES_PER_TILE  equ (16)
def TILES_BYTE_SIZE equ (TILES_COUNT * BYTES_PER_TILE)
def TILEMAPS_COUNT  equ (2)
def BYTES_PER_TILEMAP   equ (1024)
def TILEMAPS_BYTE_SIZE  equ (TILEMAPS_COUNT * BYTES_PER_TILEMAP)
def GRAPHICS_DATA_SIZE  equ (TILES_BYTE_SIZE + TILEMAPS_BYTE_SIZE)
def GRAPHICS_DATA_ADDRESS_END   equ ($8000)
def GRAPHICS_DATA_ADDRESS_START equ (GRAPHICS_DATA_ADDRESS_END - GRAPHICS_DATA_SIZE)


rsset _RAM

def WRAM_BG_SCX rb 1
def WRAM_WIN_ENABLE_FLAG    rb 1
def WRAM_BG_SCROLL_X    rb 3
def WRAM_IS_VBLANK  rb 1
def WRAM_BG_LAYER_UPDATE_BITS   rb 1
def WRAM_END    rb 0

rsreset


macro LoadGraphicsDataIntoVRAM
    ld de, GRAPHICS_DATA_ADDRESS_START
    ld hl, _VRAM8000
    .load_tile\@
        ld a, [de]
        inc de
        ld [hli], a
        ld a, d
        cp a, high(GRAPHICS_DATA_ADDRESS_END)
        jr nz, .load_tile\@
endm

macro InitOAM
    ld c, OAM_COUNT
    ld hl, _OAMRAM + OAMA_Y
    ld de, sizeof_OAM_ATTRS
    .init_oam\@
        ld [hl], 0
        add hl, de
        dec c
        jr nz, .init_oam\@

endm

section "sample", rom0

    InitSample:
        DisableLCD

        ;init WRAM
        ; InitPadInput WRAM_PAD_INPUT
        xor a
        ld [WRAM_BG_SCX], a
        ld [WRAM_WIN_ENABLE_FLAG], a

        ;init palette
        ld a, %11100100
        ld [rBGP], a
        ld [rOBP0], a
        ld a, %00011011
        ld [rOBP1], a

        LoadGraphicsDataIntoVRAM
        InitOAM


        ; enable VBlank interrupt 
        
        copy [rLYC], 255
        xor a
        ld [rSTAT], a
        ld a, IEF_VBLANK | IEF_LCDC
        ld [rIE], a
        ei


        ; turn LCD on
        ld a, LCDCF_ON | LCDCF_WIN9C00 | LCDCF_BG8800 | LCDCF_BG9800 | LCDCF_OBJ16 | LCDCF_OBJON | LCDCF_BGON
        ld [rLCDC], a


        ret 

    UpdateSample:
        .wait_for_vblank
            halt
            ld hl, WRAM_IS_VBLANK
            xor a
            cp a, [hl]
            jr z, .wait_for_vblank

            ld [hl], a

        
        ;;;;;;; vblank ;;;;;;;

        ; turn on line comparison LCD interrupt
        copy [rLYC], 47
        copy [rSTAT], STATF_LYC


        ld a, [WRAM_BG_LAYER_UPDATE_BITS]
        inc a
        ld c, a ; incremented value

        ; scroll top section when bit 2 changes (i.e. every 4 frames)
        and a, %00001000
        ld b, a
        ld a, [WRAM_BG_LAYER_UPDATE_BITS]
        and a, %00001000
        xor a, b
        ld a, [WRAM_BG_SCROLL_X]
        jr z, .top_section
            inc a
            ld [WRAM_BG_SCROLL_X], a
        
        .top_section
        
        ld [rSCX], a ; set top section

        ld a, c

        and a, %00000010
        ld b, a
        ld a, [WRAM_BG_LAYER_UPDATE_BITS]
        and a, %00000010
        xor a, b
        jr z, .middle_section
            ld a, [WRAM_BG_SCROLL_X + 1]
            inc a
            ld [WRAM_BG_SCROLL_X + 1], a
        
        .middle_section

        
        ld a, [WRAM_BG_SCROLL_X + 2]
        inc a
        ld [WRAM_BG_SCROLL_X + 2], a
        


        ld a, c
        ld [WRAM_BG_LAYER_UPDATE_BITS], a
        
        ret 

    LCDInterrupt:
        ; return if not at target line
        ld a, [rSTAT]
        bit 2, a
        ret z

        ld b, a
        copy [rSTAT], STATF_MODE00 ; turn on hblank interrupt
        ld a, b
        
        ;return if not at hblank
        and a, %00000011
        ret nz

        ; mid section
        ld a, [rLY]
        cp a, 47
        jr nz, .mid_section
            copy [rSCX], [WRAM_BG_SCROLL_X + 1]
            ;turn on next line interrupt
            copy [rLYC], 111
            copy [rSTAT], STATF_LYC
            ret
        .mid_section

        ;bottom section
        copy [rSCX], [WRAM_BG_SCROLL_X + 2]
        ; turn off line and hblank interrupt
        copy [rLYC], 255
        copy [rSTAT], 0

        ret


section "vblank_interrupt", rom0[$0040]
    push af
    copy [WRAM_IS_VBLANK], 1
    pop af
    reti

section "lcd_interrupt", rom0[$0048]
    push af
    push bc
    call LCDInterrupt
    pop bc
    pop af
    reti

export InitSample, UpdateSample