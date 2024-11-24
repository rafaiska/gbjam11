INCLUDE "hardware.inc"
INCLUDE "constants.inc"

SECTION "Header", ROM0[$100]

    jp EntryPoint

    ds $150 - @, 0 ; Make room for the header

EntryPoint:
    ld a, $FF
    ld [TestResults], a

    call Test0
    call Test1
    call Test2
    call Test3
    call Test4
    call Test5
    call Test6
    call Test7

    call PrintTestResults

Loopa:
    jr Loopa

SECTION "TestData", WRAM0
TestResults: db

export TestResults