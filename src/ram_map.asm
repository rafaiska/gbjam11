SECTION "GameObjectData", WRAM0

GameObjectData:
.loadedObjects: db
MainCharData:
.mainCharAnimationFlags: db
.mainCharOAMAddress: dw
.mainCharAnimationDelay: db
.mainCharAnimationCounter: db
.mainCharMoveDelay: db
.mainCharMoveCounter: db
Obj1Data:
    db
    dw
    db
    db
    db
    db
Obj2Data:
    db
    dw
    db
    db
    db
    db
Obj3Data:
    db
    dw
    db
    db
    db
    db
Obj4Data:
    db
    dw
    db
    db
    db
    db
Obj5Data:
    db
    dw
    db
    db
    db
    db
Obj6Data:
    db
    dw
    db
    db
    db
    db
Obj7Data:
    db
    dw
    db
    db
    db
    db

SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db

export GameObjectData, wCurKeys, wNewKeys