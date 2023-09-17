INCLUDE "hardware.inc"
INCLUDE "constants.inc"

SECTION "Header", ROM0[$100]

    jp EntryPoint

    ds $150 - @, 0 ; Make room for the header

EntryPoint:
    ; Do not turn the LCD off outside of VBlank
WaitVBlank:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank

    ; Turn the LCD off
    ld a, 0
    ld [rLCDC], a

    ; Copy the tile data
    ld de, MainCharTiles
    ld hl, $8000
    ld bc, MainCharTilesEnd - MainCharTiles
    call Memcopy

    ld a, 0
    ld b, 160
    ld hl, _OAMRAM
ClearOam:
    ld [hli], a
    dec b
    jp nz, ClearOam

	; Initialize the main char sprite in OAM
    ld hl, _OAMRAM
    ld a, 64 + 16
    ld [hli], a
    ld a, 64 + 8
    ld [hli], a
    ld a, 0
    ld [hli], a
    ld [hli], a

    ; Turn the LCD on
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
    ld [rLCDC], a

    ; During the first (blank) frame, initialize display registers
    ld a, %11100100
    ld [rBGP], a
    ld a, %11100100
    ld [rOBP0], a

ConfigureMainCharSpriteData:
    ld a, 0
    set MAIN_CHAR_FLAGS_CURR_ANM, a
    ld [mainCharAnimationFlags], a
    ld a, 5
    ld [mainCharMoveDelay], a
    ld [mainCharMoveCounter], a

    ld a, 30
    ld [mainCharAnimationCounter], a
    ld [mainCharAnimationDelay], a

Main:
    call UpdateKeys

.waitVBlank:
    ld a, [rLY]
    cp 144
    jr c, .waitVBlank

MoveMainChar:

.updateCounters:
    ld b, DIRECTION_NONE
    ld a, [mainCharMoveCounter]
    ld c, a

.checkLeft:
    ld a, [wCurKeys]
    and a, PADF_LEFT
    jr z, .checkRight
.left:
    ld b, DIRECTION_WEST

    ; Check if counter allows movement
    ld a, c
    cp a, 0
    jr nz, .animateMainCharSprite

    ; Check if sprite is hitting a border
    ld a, [_OAMRAM + 1]
    dec a
    cp a, 8
    jr z, .animateMainCharSprite

    ; Update
    ld [_OAMRAM + 1], a
    ld a, [mainCharMoveDelay]
    ld c, a
    jr .animateMainCharSprite

.checkRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jr z, .checkUp

.right:
    ld b, DIRECTION_EAST

    ; Check if counter allows movement
    ld a, c
    cp a, 0
    jr nz, .animateMainCharSprite

    ; Check if sprite is hitting a border
    ld a, [_OAMRAM + 1]
    inc a
    cp a, 160
    jr z, .animateMainCharSprite

    ; Update
    ld [_OAMRAM + 1], a
    ld a, [mainCharMoveDelay]
    ld c, a
    jr .animateMainCharSprite

.checkUp:
    ld a, [wCurKeys]
    and a, PADF_UP
    jr z, .checkDown
.up:
    ld b, DIRECTION_NORTH

    ; Check if counter allows movement
    ld a, c
    cp a, 0
    jr nz, .animateMainCharSprite

    ; Check if sprite is hitting a border
    ld a, [_OAMRAM]
    dec a
    cp a, 24
    jr z, .animateMainCharSprite

    ; Update
    ld [_OAMRAM], a
    ld a, [mainCharMoveDelay]
    ld c, a
    jr .animateMainCharSprite

.checkDown:
    ld a, [wCurKeys]
    and a, PADF_DOWN
    jr z, .endMoveMainChar
.down:
    ld b, DIRECTION_SOUTH

    ; Check if counter allows movement
    ld a, c
    cp a, 0
    jr nz, .animateMainCharSprite

    ; Check if sprite is hitting a border
    ld a, [_OAMRAM]
    inc a
    cp a, 152
    jr z, .animateMainCharSprite

    ; Update
    ld [_OAMRAM], a
    ld a, [mainCharMoveDelay]
    ld c, a

.animateMainCharSprite:
    push bc
    call AnimateMainChar
    pop bc

.updateMoveCounter:
    ld a, c
    cp a, 0
    jr z, .endMoveMainChar
    dec a
    ld [mainCharMoveCounter], a

.endMoveMainChar:
    jp Main

; Animate main character sprite
; @param b: new direction
; @param c: move counter: equals to mainCharMoveDelay if moved in this update
AnimateMainChar:
    ; First check if direction has changed
    ld a, [mainCharAnimationFlags]
    and a, MAIN_CHAR_FLAGS_CURR_DIRECTION_MASK
    cp a, b
    jr z, .animateSprite
    ld a, b

.setSouthSprite:
    cp a, DIRECTION_SOUTH
    jr nz, .setNorthSprite
    ld a, 0
    ld [_OAMRAM + 2], a
    jr .updateDirectionRam

.setNorthSprite:
    cp a, DIRECTION_NORTH
    jr nz, .setEastWestSprite
    ld a, 1
    ld [_OAMRAM + 2], a
    jr .updateDirectionRam

.setEastWestSprite:
    ld a, 2
    ld [_OAMRAM + 2], a
    ld a, b
    bit 0, a
    jr nz, .doNotFlip
    ld a, [_OAMRAM + 3]
    set 5, a
    jr .saveOAMFlags

.doNotFlip:
    ld a, [_OAMRAM + 3]
    res 5, a

.saveOAMFlags:
    ld [_OAMRAM + 3], a

.updateDirectionRam:
    ld a, [mainCharAnimationFlags]
    and a, ~MAIN_CHAR_FLAGS_CURR_DIRECTION_MASK
    add a, b
    ld [mainCharAnimationFlags], a
    
.animateSprite:
    ld a, [mainCharAnimationCounter]
    cp a, 0
    jr nz, .endAnimateMainChar

    ld a, [mainCharAnimationFlags]
    and a, MAIN_CHAR_FLAGS_CURR_DIRECTION_MASK
    bit 1, a
    jr nz, .animateEastWest

    ld a, [_OAMRAM + 3]
    bit 5, a
    jr nz, .flipSpriteAnimateNS
    set 5, a
    jr .saveOAMFlags2

.flipSpriteAnimateNS:
    res 5, a

.saveOAMFlags2:
    ld [_OAMRAM + 3], a
    jr .endAnimateSprite

.animateEastWest:
    ld a, [_OAMRAM + 2]
    cp a, 2
    jr z, .setSprite3
    ld a, 2
    jr .saveOAMSprite

.setSprite3:
    ld a, 3

.saveOAMSprite:
    ld [_OAMRAM + 2], a

.endAnimateSprite:
    ld a, [mainCharAnimationDelay]

.endAnimateMainChar:
    dec a
    ld [mainCharAnimationCounter], a
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

UpdateKeys:
  ; Poll half the controller
  ld a, P1F_GET_BTN
  call .onenibble
  ld b, a ; B7-4 = 1; B3-0 = unpressed buttons

  ; Poll the other half
  ld a, P1F_GET_DPAD
  call .onenibble
  swap a ; A3-0 = unpressed directions; A7-4 = 1
  xor a, b ; A = pressed buttons + directions
  ld b, a ; B = pressed buttons + directions

  ; And release the controller
  ld a, P1F_GET_NONE
  ldh [rP1], a

  ; Combine with previous wCurKeys to make wNewKeys
  ld a, [wCurKeys]
  xor a, b ; A = keys that changed state
  and a, b ; A = keys that changed to pressed
  ld [wNewKeys], a
  ld a, b
  ld [wCurKeys], a
  ret

.onenibble
  ldh [rP1], a ; switch the key matrix
  call .knownret ; burn 10 cycles calling a known ret
  ldh a, [rP1] ; ignore value while waiting for the key matrix to settle
  ldh a, [rP1]
  ldh a, [rP1] ; this read counts
  or a, $F0 ; A7-4 = 1; A3-0 = unpressed keys
.knownret
  ret

; Convert a pixel position to a tilemap address
; hl = $9800 + X + Y * 32
; @param b: X
; @param c: Y
; @return hl: tile address
GetTileByPixel:
    ; First, we need to divide by 8 to convert a pixel position to a tile position.
    ; After this we want to multiply the Y position by 32.
    ; These operations effectively cancel out so we only need to mask the Y value.
    ld a, c
    and a, %11111000
    ld l, a
    ld h, 0
    ; Now we have the position * 8 in hl
    add hl, hl ; position * 16
    add hl, hl ; position * 32
    ; Convert the X position to an offset.
    ld a, b
    srl a ; a / 2
    srl a ; a / 4
    srl a ; a / 8
    ; Add the two offsets together.
    add a, l
    ld l, a
    adc a, h
    sub a, l
    ld h, a
    ; Add the offset to the tilemap's base address, and we are done!
    ld bc, $9800
    add hl, bc
    ret

; @param a: tile ID
; @return z: set if a is a wall.
IsWallTile:
    cp a, $00
    ret z
    cp a, $01
    ret z
    cp a, $02
    ret z
    cp a, $04
    ret z
    cp a, $05
    ret z
    cp a, $06
    ret z
    cp a, $07
    ret

MainCharTiles:
    incbin "assets/mainchar.2bpp"
MainCharTilesEnd:


SECTION "MainCharData", WRAM0
mainCharAnimationFlags: db
mainCharAnimationDelay: db
mainCharAnimationCounter: db
mainCharMoveDelay: db
mainCharMoveCounter: db

SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db