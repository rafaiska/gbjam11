INCLUDE "hardware.inc"
INCLUDE "constants.inc"

SECTION "Graphics", ROM0

UpdateGraphics:
    ld hl, GameObjectData + 1
    call AnimateSprite
    ret

; Animate sprite
; @param hl: game object address
AnimateSprite:
    ; First check object flags to see if it moved
    bit GAME_OBJECT_FLAGS_MOVED, [hl]
    jp z, .endAnimateSprite
    res GAME_OBJECT_FLAGS_MOVED, [hl]

    ; Save game object address
    ld d, h
    ld e, l ; de <- Game Object Address

    ; Save OAM address
    ld a, GAME_OBJECT_OAM
    adc a, l
    jr nc, .saveOAMWOCarry
    inc h
.saveOAMWOCarry:
    ld l, a
    ld a, [hl+]
    ld b, a
    ld a, [hl]
    ld c, a ; bc <- OAM address

.checkChangedDirection:
    ; If changed direction, change animation
    ld h, d
    ld l, e
    ld a, GAME_OBJECT_FLAGS
    adc a, l
    jr nc, .noNeedToIncrementH
    inc h
.noNeedToIncrementH:
    ld l, a

    bit GAME_OBJECT_FLAGS_DIRECTION_CHANGED, [hl]
    jr z, .directionDidntChange
    res  GAME_OBJECT_FLAGS_DIRECTION_CHANGED, [hl]
    ld a, [hl]
    and a, GAME_OBJECT_FLAGS_CURR_DIRECTION_MASK

.setSouthSprite:
    cp a, DIRECTION_SOUTH
    jr nz, .setNorthSprite
    ld a, 0
    jr .saveOAMSprite

.setNorthSprite:
    cp a, DIRECTION_NORTH
    jr nz, .setEastWestSprite
    ld a, 1
    jr .saveOAMSprite

.setEastWestSprite:
    ld h, b
    ld l, c ; hl <- OAM address (y coord)
    inc hl ; x coord
    inc hl ; sprite
    inc hl ; flags
    bit 0, a
    jr nz, .doNotFlip
    set 5, [hl] ; sprite flip flag
    jr AnimateSprite.endSetEastWestSprite

.doNotFlip:
    res 5, [hl] ; sprite flip flag

.endSetEastWestSprite:
    ld a, 2

.saveOAMSprite:
    ld h, b
    ld l, c ; hl <- OAM address (y coord)
    inc hl ; x coord
    inc hl ; sprite
    ld [hl], a

.directionDidntChange:
    ld h, d
    ld l, e ; hl <- Game Object Address

    ; Check if sprite collided
    bit GAME_OBJECT_FLAGS_COLLISION, [hl]
    jr z, AnimateSprite.moveSprite
    res GAME_OBJECT_FLAGS_COLLISION, [hl]
    jr AnimateSprite.endAnimateSprite

.moveSprite:
    ld a, [hl]
    and a, GAME_OBJECT_FLAGS_CURR_DIRECTION_MASK ; a <- current direction
    ld h, b
    ld l, c ; hl <- OAM address
    cp a, DIRECTION_NORTH
    jr nz, .checkMoveSouth
    ld a, [hl]
    dec a
    ld [hl], a
    jr .endAnimateSprite

.checkMoveSouth:
    cp a, DIRECTION_SOUTH
    jr nz, .checkMoveEast
    ld a, [hl]
    inc a
    ld [hl], a
    jr .endAnimateSprite

.checkMoveEast:
    inc hl ; OAM x address
    cp a, DIRECTION_EAST
    jr nz, .checkMoveWest
    ld a, [hl]
    inc a
    ld [hl], a
    jr .endAnimateSprite

.checkMoveWest:
    cp a, DIRECTION_WEST
    jr nz, .endAnimateSprite
    ld a, [hl]
    dec a
    ld [hl], a
    jr .endAnimateSprite

.animateSprite:
    ; Check if counter allows animation
    ld b, 0
    ld c, GAME_OBJECT_ANIMATION_COUNTER
    add hl, bc
    ld a, [hl]
    cp a, 0
    jr z, .counterAllowsAnimation
    dec a
    ld [hl], a
    jr .endAnimateSprite

.counterAllowsAnimation:
    dec hl
    ld a, [hl+]
    ld [hl], a ; AnimationCounter <- AnimationDelay

    ; Load OAM object address
    ld h, d
    ld l, e
    ld b, 0
    ld c, GAME_OBJECT_OAM
    add hl, bc
    ld a, [hl+]
    ld b, a
    ld a, [hl]
    ld c, a ; bc <- OAM Address

    ld a, [GameObjectData + 1 + GAME_OBJECT_ANIMATION_COUNTER]
    cp a, 0
    jr nz, .endAnimateSprite

    ld a, [GameObjectData + 1 + GAME_OBJECT_FLAGS]
    and a, GAME_OBJECT_FLAGS_CURR_DIRECTION_MASK
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
    jr .saveOAMSprite2

.setSprite3:
    ld a, 3

.saveOAMSprite2:
    ld [_OAMRAM + 2], a

.endAnimateSprite:
    ret

export UpdateGraphics