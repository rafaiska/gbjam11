INCLUDE "hardware.inc"

SECTION "Test Console", ROM0

; Print result for test 
; No parameters needed, read from TestResults (WRAM)
PrintTestResults:
    call WaitVBlank
    ; Turn the LCD off
    ld a, LCDCF_OFF
    ld [rLCDC], a

    call InitTestConsole
    ld a, 0
    ld b, a
.mainLoop:
    push bc
    call PrintTestResultsB
    pop bc
    inc b
    ld a, b
    cp a, 8
    jr nz, .mainLoop

    ; Turn the LCD on
    ld a, LCDCF_ON | LCDCF_BGON
    ld [rLCDC], a

    ret

; Print result for specific test 
; @param b: test index
PrintTestResultsB:
    ; Copy the tilemap
    ld hl, $9800
    ld a, b

.calculateTilemapAddr:
    cp a, 0
    jr z, .copyString
    ld c, a

    ld a, $20
    add a, l
    ld l, a
    adc a, h
    sub l
    ld h, a

    ld a, c
    dec a
    jr .calculateTilemapAddr

.copyString:
    push hl
    push bc
    ld de, TestString
    ld bc, TestStringEnd - TestString
    call Memcopy
    pop bc
    pop hl

    ; Calculate index address in string, store in hl
    ld a, $04
    add a, l
    ld l, a
    adc a, h
    sub l
    ld h, a

    ; Write test index (b) in string
    ld a, $10
    add a, b
    ld [hl], a

    ; Check if test is OK or NOK
    ld a, [TestResults]
    ld c, a
.shiftResultsByte:
    ld a, b
    cp a, 0
    jr z, .testBitZero
    dec a
    ld b, a

    ld a, c
    sra a
    ld c, a
    jr .shiftResultsByte

.testBitZero:
    ld a, c
    bit 0, a
    jr z, .endPrintTestResultsB

    ; Print N(OK)
    ld a, $03
    add a, l
    ld l, a
    adc a, h
    sub l
    ld h, a

    ld a, $2E
    add a, b
    ld [hl], a

.endPrintTestResultsB:
    ret

InitTestConsole:
    ; Copy background tile data
    ld de, FontTiles
    ld hl, $9000
    ld bc, FontTilesEnd - FontTiles
    call Memcopy

    ret

FontTiles:
    incbin "assets/font.2bpp"
FontTilesEnd:

TestString:
    db $34 ; T
    db $25 ; E
    db $33 ; S
    db $34 ; T
    db $10 ; 0
    db $1A ; :
    db $00 ;  
    db $00 ;  
    db $2F ; O
    db $2B ; K
TestStringEnd:

export PrintTestResults