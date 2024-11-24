INCLUDE "hardware.inc"

SECTION "Test Console", ROM0

; Print result for test 
; @param b: test index (0-7)
; @param c: OK? (0: true, 1: false)
PrintTestResults:
    call InitTestConsole
    ret

InitTestConsole:
    call WaitVBlank
    ; Turn the LCD off
    ld a, LCDCF_OFF
    ld [rLCDC], a
.copyCharacterTiles:
    ; Copy background tile data
    ld de, FontTiles
    ld hl, $9000
    ld bc, FontTilesEnd - FontTiles
    call Memcopy

    ; Turn the LCD on
    ld a, LCDCF_ON | LCDCF_BGON
    ld [rLCDC], a

    ret

FontTiles:
    incbin "assets/font.2bpp"
FontTilesEnd:

export PrintTestResults