if !def(PAD_INC)
def PAD_INC equ 1


include "hardware.inc"


rsreset
def PAD_INPUT_CURRENT   rb 1
def PAD_INPUT_PREVIOUS  rb 1
def PAD_INPUT_PRESSED   rb 1
def PAD_INPUT_RELEASED  rb 1
def sizeof_PAD_INPUT    rb 0

; \1 = PADSTATE_ADDRESS
macro InitPadInput
    ld a, $FF
    ld [\1 + PAD_INPUT_CURRENT], a
    ld [\1 + PAD_INPUT_PREVIOUS], a
    ld [\1 + PAD_INPUT_PRESSED], a
    ld [\1 + PAD_INPUT_RELEASED], a
endm

; ex UpdatePadInput PADSTATE_ADDRESS
macro UpdatePadInput

    ; move old status to prev and c
    ld a, [\1 + PAD_INPUT_CURRENT]
    ld [\1 + PAD_INPUT_PREVIOUS], a
    ld c, a

    ; read d-pad
    ld a, P1F_GET_DPAD
    ldh [rP1], a
    ; repeat twice to wait for result to stabilize
    ldh a, [rP1]
    ldh a, [rP1]

    ; put dpad input (low 4 bits of result) into b's high nibble
    swap a
    and a, $F0
    ld b, a

    ; read buttons

    ld a, P1F_GET_BTN
    ldh [rP1], a
    ; repeat 6 times to wait for result to stabilize
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]

    ; merge into b's low nibble
    and a, $0F
    or a, b
    ld b, a

    ; store input
    ld [\1 + PAD_INPUT_CURRENT], a

    ;disable input polling
    ld a, P1F_GET_NONE
    ldh [rP1], a

    ;compute pressed buttons
    ld a, c ; c = previous
    cpl 
    or a, b
    ld [\1 + PAD_INPUT_PRESSED], a

    ; compute released buttons
    ld b, a ;b = current
    cpl 
    or a, c
    ld [\1 + PAD_INPUT_RELEASED], a

endm

macro TestPadInput_Pressed
    ld a, [\1 + PAD_INPUT_PRESSED]
    and a, \2
endm

macro TestPadInput_Released
    ld a, [\1 + PAD_INPUT_RELEASED]
    and a, \2
endm


macro TestPadInput_HeldAll
    ld a, [\1 + PAD_INPUT_CURRENT]
    and a, \2
endm

macro TestPadInput_AnyButtonsPressed ;nz if true
    ld a, \2
    cpl a
    ld b, a
    ld a, [\1 + PAD_INPUT_PRESSED]
    or a, b
    cp a, $ff
endm


endc ;PAD_INC

