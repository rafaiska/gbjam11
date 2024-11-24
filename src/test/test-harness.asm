INCLUDE "hardware.inc"
INCLUDE "constants.inc"

SECTION "Tests", ROM0

Test0:
    ld a, [TestResults]
    res 0, a
    ld [TestResults], a
    ret

Test1:
    ld a, [TestResults]
    res 1, a
    ld [TestResults], a
    ret

Test2:
    ld a, [TestResults]
    res 2, a
    ld [TestResults], a
    ret

Test3:
    ld a, [TestResults]
    res 3, a
    ld [TestResults], a
    ret

Test4:
    ld a, [TestResults]
    res 4, a
    ld [TestResults], a
    ret

Test5:
    ld a, [TestResults]
    res 5, a
    ld [TestResults], a
    ret

Test6:
    ld a, [TestResults]
    res 6, a
    ld [TestResults], a
    ret

Test7:
    ld a, [TestResults]
    cp a, $80
    jr z, .success
    ret
.success:
    res 7, a
    ld [TestResults], a
    ret

export Test0
export Test1
export Test2
export Test3
export Test4
export Test5
export Test6
export Test7