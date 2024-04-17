INCLUDE "hardware.inc"
INCLUDE "constants.inc"

SECTION "Physics", ROM0

; Moves the main character according to input received
; Moves alien enemies
; Handle collisions
UpdatePhysics:
    call PrepareMoveMainChar

    ; Collisions
    ld hl, GameObjectData
    inc hl
    call HandleCollision
    ret

; Checks if main char is moved by input
PrepareMoveMainChar:
.checkLeft:
    ld a, [wCurKeys]
    and a, PADF_LEFT
    jr z, .checkRight
.left:
    ld b, DIRECTION_WEST
    jr .saveDirectionAndSetFlag

.checkRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jr z, .checkUp
.right:
    ld b, DIRECTION_EAST
    jr .saveDirectionAndSetFlag

.checkUp:
    ld a, [wCurKeys]
    and a, PADF_UP
    jr z, .checkDown
.up:
    ld b, DIRECTION_NORTH
    jr .saveDirectionAndSetFlag

.checkDown:
    ld a, [wCurKeys]
    and a, PADF_DOWN
    jr z, .endPrepareMoveMainChar
.down:
    ld b, DIRECTION_SOUTH

.saveDirectionAndSetFlag:
    ld hl, GameObjectData + 1 + GAME_OBJECT_FLAGS
    ld a, [hl]
    and a, GAME_OBJECT_FLAGS_CURR_DIRECTION_MASK
    cp b
    jr z, .directionHasntChanged
    set GAME_OBJECT_FLAGS_DIRECTION_CHANGED, [hl]

 .directionHasntChanged:
    ld a, [hl]
    and a, ~GAME_OBJECT_FLAGS_CURR_DIRECTION_MASK
    add a, b
    set GAME_OBJECT_FLAGS_MOVED, a
    ld [hl], a

.endPrepareMoveMainChar:
    ret

; Handles collision of a game object
; @param hl: address of the game object
HandleCollision:
    ld d, h
    ld e, l
    ld b, 0
    ld c, GAME_OBJECT_FLAGS
    add hl, bc
    ld a, [hl] ; object flags

    bit GAME_OBJECT_FLAGS_MOVED, a
    jp z, .endHandleCollision

    ; Check if counter allows movement
    ld h, d
    ld l, e
    ld c, GAME_OBJECT_MOVE_COUNTER
    add hl, bc
    ld a, [hl]
    cp a, 0
    jr z, .counterAllowsMovement
    dec a
    ld [hl], a
    ld h, d
    ld l, e
    res GAME_OBJECT_FLAGS_MOVED, [hl]
    jr .endHandleCollision

.counterAllowsMovement:
    ld h, d
    ld l, e
    ld c, GAME_OBJECT_FLAGS
    add hl, bc
    ld a, [hl]
    and a, GAME_OBJECT_FLAGS_CURR_DIRECTION_MASK

    ; Load OAM x and y coordinates
    push af
    ld h, d
    ld l, e
    ld c, GAME_OBJECT_OAM
    add hl, bc
    ld a, [hl+]
    ld b, a
    ld a, [hl]
    ld c, a ; bc <- OAM Address
    ld h, b
    ld l, c
    ld a, [hl+] ; y coordinate
    ld b, a
    ld a, [hl] ; x coordinate
    ld c, a
    pop af

    cp a, DIRECTION_NORTH
    jr z, .up
    cp a, DIRECTION_SOUTH
    jr z, .down
    cp a, DIRECTION_EAST
    jr z, .right
    cp a, DIRECTION_WEST
    jr z, .left
    jr .endHandleCollision ;  UNEXPECTED DIRECTION

.left:
    ld a, c
    dec a

    ; Check if sprite is hitting a border
    cp a, 8
    jr z, .collisionHappened
    jr c, .collisionHappened

    jr .checkCollisionWithHatchLeft

.right:
    ld a, c
    inc a

    ; Check if sprite is hitting a border
    cp a, 160
    jr z, .collisionHappened
    jr nc, .collisionHappened

    jr .checkCollisionWithHatchRight

.up:
    ld a, b
    dec a

    ; Check if sprite is hitting a border
    cp a, 24
    jr z, .collisionHappened
    jr c, .collisionHappened

    jr .checkCollisionWithHatchUp

.down:
    ld a, b
    inc a

    ; Check if sprite is hitting a border
    cp a, 150
    jr z, .collisionHappened
    jr nc, .collisionHappened
    

    ; A --- B
    ; |     | Main char sprite 8x8
    ; |     | Vertices A,B,C,D
    ; C --- D
.checkCollisionWithHatchDown:
    ; Vertix C: H.x <= C.x <= H.x + H.w & H.y <= C.y <= H.y + H.h
    ;H.x <= C.x; C.x = o.x
    ld a, c

    cp a, HATCH_RECT_X0
    jr c, .noCollision
    ; Vertix D
.checkCollisionWithHatchLeft:
    ; Vertix A
    ; Vertix C
.checkCollisionWithHatchRight:
    ; Vertix B
    ; Vertix D
.checkCollisionWithHatchUp:
    ; Vertix A
    ; Vertix B


    ; P.x >= H.x - 8
    ld a, c
    cp a, HATCH_RECT_X0 - 9
    jr c, .noCollision

    ; P.x <= H.x + H.w
    cp a, HATCH_RECT_X1 + 1
    jr nc, .noCollision

    ; P.y >= H.y - 8
    ld a, b
    cp a, HATCH_RECT_Y0 - 9
    jr c, .noCollision

    ; P.x <= H.x + H.h
    cp a, HATCH_RECT_Y1 +1
    jr c, .collisionHappened

.noCollision:
    ld h, d
    ld l, e
    ld b, 0
    ld c, GAME_OBJECT_MOVE_DELAY
    add hl, bc
    ld a, [hl+]; Load delay
    ld [hl], a ; Move Counter = Move Delay
    jr .endHandleCollision

.collisionHappened:
    ld h, d
    ld l, e
    set GAME_OBJECT_FLAGS_COLLISION, [hl]

.endHandleCollision:
    ret

; Set c flag if there is collision between two rects
; @param SP-2: rectA origin coordinates y, x
; @param SP-4: rectA dimensions h, w
; @param SP-6: rectB origin coordinates y, x
; @param SP-8: rectB dimensions h, w
CollisionBetweenRects:
    ; r1x + r1w >= r2x
    ld hl, SP-1
    ld a, [hl] ;r1x
    ld hl, SP-3
    add a, [hl] ; r1x + r1w
    ld hl, SP-5
    cp a, [hl]
    jr nc, .collisionDetected

    ; r1x <= r2x + r2w

    ; r1y + r1h >= r2y

    ; r1y <= r2y + r2h

.collisionDetected:
    scf
.noCollisionDetected:
    ret

export UpdatePhysics