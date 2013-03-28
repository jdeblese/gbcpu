org $100
    xor A
    ld  ($06),A     ; timer resets to zero
    ld  A,04
    ld  ($07),A     ; enable timer, 4kHz tick
    ld  ($FF),A     ; enable timer interrupt, disable others
    jr  $FE         ; wait

org $50
    ld  HL,$FF0F
    clr 2,(HL)      ; clear interrupt flag
    ld  HL,$8000    ; toggle first row of tile 0
    ld  B,(HL)
    ld  A,$FF
    xor B
    ld  (HL),A
    ld  HL,$FFFF
    set 2,(HL)      ; enable timer interrupt
    ret

;       INIT_02 => X"ffff2177a8ff3e46800021d6cbff0f2100000000000000000000000000000000",
;       INIT_03 => X"0000000000000000000000000000000000000000000000000000000000c996cb",
;       INIT_08 => X"000000000000000000000000000000000000000000fe18ffe007e0043e06e0af",

; top row will flicker at approximately 8 Hz
