INCLUDE "hardware.inc"

SECTION "Utils", ROM0

WaitVBlank:
    ld a, [rLY]
    cp 144
    jr c, WaitVBlank
    ret

Memcopy:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or a, c
    jp nz, Memcopy
    ret



export WaitVBlank
export Memcopy