; Defaults:

; DMUX ram
; AMUX rf16

; RF_IMUXSEL imux
; RF_IMUX bc
; RF_OMUX bc
; RF_AMUX idata
; RF_DMUX b

; ALUFLAGS

; ***************************************************************************
; *     First block instructions (with opcode [0-3]*)                       *
; ***************************************************************************

; NOP           4 cycles
000 JMP 3fd, RF_OMUX pc, RF_DMUX x

; TODO: STOP

; JRNZ/Z helper
200 JMP 210, RF_OMUX pc
210 JMP 300, RF_OMUX pc, STORE_TMP
;   jump depending on zero flag
300 JMP 200, JCMD, JZERO, RF_OMUX pc, RF_IMUX pc, RF_AMUX inc, RF_CE

; JRNZ n        12/8 cycles
;   read n
020 JMP 200, RF_OMUX pc
;   flag is not set, so put n on the databus and update PC (8 cycles left)
220 JMP 3f9, DMUX tmp, RF_OMUX pc, RF_AMUX idata, RF_IMUX pc, RF_CE
;   flag is set, so move on to fetch (4 cycles left)
320 JMP 3fd, RF_OMUX pc

; JRZ n         12/8 cycles
;   read n
028 JMP 200, RF_OMUX pc
;   flag is not set, so move on to fetch (4 cycles left)
228 JMP 3fd, RF_OMUX pc
;   flag is set, so put n on the databus and update PC (8 cycles left)
328 JMP 3f9, DMUX tmp, RF_OMUX pc, RF_AMUX idata, RF_IMUX pc, RF_CE

; JR n          12/8 cycles
;   read n
018 JMP 200, RF_OMUX pc
;   flag doesn't matter - put n on the databus and update PC (8 cycles left)
218 JMP 3f9, DMUX tmp, RF_OMUX pc, RF_AMUX idata, RF_IMUX pc, RF_CE
318 JMP 3f9, DMUX tmp, RF_OMUX pc, RF_AMUX idata, RF_IMUX pc, RF_CE


; JRNC/C helper
254 JMP 255, RF_OMUX pc
255 JMP 31c, RF_OMUX pc, STORE_TMP
;   jump depending on carry flag
31c JMP 200, JCMD, JCARRY, RF_OMUX pc, RF_IMUX pc, RF_AMUX inc, RF_CE

; JRNC n        12/8 cycles
;   read n
030 JMP 254, RF_OMUX pc
;   flag is not set, so put n on the databus and update PC (8 cycles left)
230 JMP 3f9, DMUX tmp, RF_OMUX pc, RF_AMUX idata, RF_IMUX pc, RF_CE
;   flag is set, so move on to fetch (4 cycles left)
330 JMP 3fd, RF_OMUX pc

; JRC n         12/8 cycles
;   read n
038 JMP 254, RF_OMUX pc
;   flag is not set, so move on to fetch (4 cycles left)
238 JMP 3fd, RF_OMUX pc
;   flag is set, so put n on the databus and update PC (8 cycles left)
338 JMP 3f9, DMUX tmp, RF_OMUX pc, RF_AMUX idata, RF_IMUX pc, RF_CE


; LD16 helpers
;   Load (PC) into unq, PC++. Address should already be on bus for 1 cycle
258 JMP 259, RF_OMUX pc
259 JMP 25a, RF_OMUX pc, STORE_UNQ
25a JMP 25b, RF_OMUX pc, RF_IMUX pc, RF_AMUX inc, RF_CE
;   (PC) into tmp, PC++, and jump to 200 + CMD
25b JMP 25c, RF_OMUX pc
25c JMP 25d, RF_OMUX pc
25d JMP 24d, RF_OMUX pc, STORE_TMP
24d JMP 200, JCMD, RF_OMUX pc, RF_IMUX pc, RF_AMUX inc, RF_CE

; LD {BC,DE,HL,SP}, nn      12 cycles
; first byte in unq into lsB, second in tmp into msB, keeping PC on address bus
;   BC,nn
001 JMP 258, RF_OMUX pc
201 JMP 311, DMUX tmp, RF_IMUXSEL cmd[5:4], RF_CE hi, RF_OMUX pc
;   DE,nn
011 JMP 258, RF_OMUX pc
211 JMP 311, DMUX tmp, RF_IMUXSEL cmd[5:4], RF_CE hi, RF_OMUX pc
;   HL,nn
021 JMP 258, RF_OMUX pc
221 JMP 311, DMUX tmp, RF_IMUXSEL cmd[5:4], RF_CE hi, RF_OMUX pc
;   SP,nn
031 JMP 258, RF_OMUX pc
231 JMP 311, DMUX tmp, RF_IMUXSEL cmd[5:4], RF_CE hi, RF_OMUX pc
;   Add unq into lsB for all
311 JMP 3fe, DMUX unq, RF_IMUXSEL cmd[5:4], RF_CE lo, RF_OMUX pc


; LD ({BC,DE,HL+,HL-}),A    8 cycles
; address and acc on bus for 4 cycles, wr_en, inc/decrement HL at the end of the 4th as with PC
;   (BC),A
002 JMP 203, RF_OMUX bc, DMUX acc
203 JMP 202, RF_OMUX bc, DMUX acc
202 JMP 302, RF_OMUX bc, DMUX acc, WR
302 JMP 3fc, RF_OMUX bc, DMUX acc, WR
;   (DE),A
012 JMP 213, RF_OMUX de, DMUX acc
213 JMP 212, RF_OMUX de, DMUX acc
212 JMP 312, RF_OMUX de, DMUX acc, WR
312 JMP 3fc, RF_OMUX de, DMUX acc, WR
;   (HL+),A
022 JMP 223, RF_OMUX hl, DMUX acc
223 JMP 222, RF_OMUX hl, DMUX acc
222 JMP 322, RF_OMUX hl, DMUX acc, WR
322 JMP 3fc, RF_OMUX hl, DMUX acc, WR, RF_AMUX inc, RF_IMUX hl, RF_CE
;   (HL-),A
032 JMP 233, RF_OMUX hl, DMUX acc
233 JMP 232, RF_OMUX hl, DMUX acc
232 JMP 332, RF_OMUX hl, DMUX acc, WR
332 JMP 3fc, RF_OMUX hl, DMUX acc, WR, RF_AMUX dec, RF_IMUX hl, RF_CE

; LD A,({BC,DE})    8 cycles
; address on bus for 4 cycles, loading into A, then jump to delay 4 cycles
;   A,(BC)
00a JMP 208, RF_OMUX bc
208 JMP 20a, RF_OMUX bc
20a JMP 30a, RF_OMUX bc, STORE_ACC
30a JMP 3fc, RF_OMUX bc
;   A,(DE)
01a JMP 235, RF_OMUX de
235 JMP 21a, RF_OMUX de
21a JMP 31a, RF_OMUX de, STORE_ACC
31a JMP 3fc, RF_OMUX de

; LD A,({HL+,HL-})    8 cycles
; address on bus for 4 cycles, loading into acc, then jump to delay 4 cycles
;   set the address
02a JMP 22a, RF_OMUX hl
03a JMP 22a, RF_OMUX hl
;   read into ACC, jumping depending on cmd
22a JMP 23a, RF_OMUX hl
23a JMP 300, JCMD, RF_OMUX hl, STORE_ACC
;   increment/decrement HL
32a JMP 3fc, RF_OMUX hl, RF_AMUX inc, RF_IMUX hl, RF_CE
33a JMP 3fc, RF_OMUX hl, RF_AMUX dec, RF_IMUX hl, RF_CE


; INC/DEC {BC,DE,HL,SP}     8 cycles
;   Use the register file's internal 16-bit adder
003 JMP 3f9, RF_OMUX bc, RF_AMUX inc, RF_IMUXSEL cmd[5:4], RF_CE
013 JMP 3f9, RF_OMUX de, RF_AMUX inc, RF_IMUXSEL cmd[5:4], RF_CE
023 JMP 3f9, RF_OMUX hl, RF_AMUX inc, RF_IMUXSEL cmd[5:4], RF_CE
033 JMP 3f9, RF_OMUX sp, RF_AMUX inc, RF_IMUXSEL cmd[5:4], RF_CE
00b JMP 3f9, RF_OMUX bc, RF_AMUX dec, RF_IMUXSEL cmd[5:4], RF_CE
01b JMP 3f9, RF_OMUX de, RF_AMUX dec, RF_IMUXSEL cmd[5:4], RF_CE
02b JMP 3f9, RF_OMUX hl, RF_AMUX dec, RF_IMUXSEL cmd[5:4], RF_CE
03b JMP 3f9, RF_OMUX sp, RF_AMUX dec, RF_IMUXSEL cmd[5:4], RF_CE


; INC {B,D,H}           4 cycles    ZNH-
004 JMP 304, DMUX rf, RF_DMUX b, alu_cmd <= "001000", STORE_ALU, RF_OMUX pc
014 JMP 304, DMUX rf, RF_DMUX d, alu_cmd <= "001000", STORE_ALU, RF_OMUX pc
024 JMP 304, DMUX rf, RF_DMUX h, alu_cmd <= "001000", STORE_ALU, RF_OMUX pc
304 JMP 3fe, DMUX alu, RF_IMUXSEL cmd[5:4], RF_CE hi, ALUFLAGS, FLAGS znh, RF_OMUX pc
; INC {C,E,L}           4 cycles    ZNH-
00c JMP 314, DMUX rf, RF_DMUX c, alu_cmd <= "001000", STORE_ALU, RF_OMUX pc
01c JMP 314, DMUX rf, RF_DMUX e, alu_cmd <= "001000", STORE_ALU, RF_OMUX pc
02c JMP 314, DMUX rf, RF_DMUX l, alu_cmd <= "001000", STORE_ALU, RF_OMUX pc
314 JMP 3fe, DMUX alu, RF_IMUXSEL cmd[5:4], RF_CE lo, ALUFLAGS, FLAGS znh, RF_OMUX pc
; INC A                 4 cycles    ZNH-
03c JMP 324, DMUX acc, alu_cmd <= "001000", STORE_ALU, RF_OMUX pc
324 JMP 3fe, DMUX alu, STORE_ACC, ALUFLAGS, FLAGS znh, RF_OMUX pc

; DEC {B,D,H}                   4 cycles
005 JMP 305, DMUX rf, RF_DMUX b, alu_cmd <= "001100", STORE_ALU, RF_OMUX pc
015 JMP 305, DMUX rf, RF_DMUX d, alu_cmd <= "001100", STORE_ALU, RF_OMUX pc
025 JMP 305, DMUX rf, RF_DMUX h, alu_cmd <= "001100", STORE_ALU, RF_OMUX pc
305 JMP 3fe, DMUX alu, RF_IMUXSEL cmd[5:4], RF_CE hi, ALUFLAGS, FLAGS znh, RF_OMUX pc
; DEC {C,E,L}                   4 cycles
00d JMP 315, DMUX rf, RF_DMUX c, alu_cmd <= "001100", STORE_ALU, RF_OMUX pc
01d JMP 315, DMUX rf, RF_DMUX e, alu_cmd <= "001100", STORE_ALU, RF_OMUX pc
02d JMP 315, DMUX rf, RF_DMUX l, alu_cmd <= "001100", STORE_ALU, RF_OMUX pc
315 JMP 3fe, DMUX alu, RF_IMUXSEL cmd[5:4], RF_CE lo, ALUFLAGS, FLAGS znh, RF_OMUX pc
; DEC A                         4 cycles
03d JMP 325, DMUX acc, alu_cmd <= "001100", STORE_ALU, RF_OMUX pc
325 JMP 3fe, DMUX alu, STORE_ACC, ALUFLAGS, FLAGS znh, RF_OMUX pc

; INC/DEC (HL)      12 cycles, ZNH-
; recycle unused micro-op memory from INC r8
;   load (HL) into alu, +1
034 JMP 204, RF_OMUX hl, DMUX ram
204 JMP 214, RF_OMUX hl, DMUX ram
214 JMP 224, RF_OMUX hl, DMUX ram, alu_cmd <= "001000", STORE_ALU
224 JMP 234, RF_OMUX hl, ALUFLAGS, FLAGS znh
; recycle unused micro-op memory from DEC r8
;   load (HL) into alu, -1
035 JMP 205, RF_OMUX hl, DMUX ram
205 JMP 215, RF_OMUX hl, DMUX ram
215 JMP 225, RF_OMUX hl, DMUX ram, alu_cmd <= "001100", STORE_ALU
225 JMP 234, RF_OMUX hl, ALUFLAGS, FLAGS znh
;   store alu into (HL), then jump to fetch
234 JMP 20c, RF_OMUX hl, DMUX alu
20c JMP 21c, RF_OMUX hl, DMUX alu
21c JMP 22c, RF_OMUX hl, DMUX alu, WR
22c JMP 3fc, RF_OMUX hl, DMUX alu, WR


; LD {B,D,H},n                  8 cycles
006 JMP 306, RF_OMUX pc, DMUX ram
016 JMP 306, RF_OMUX pc, DMUX ram
026 JMP 306, RF_OMUX pc, DMUX ram
;   read the byte at PC into the register file
306 JMP 316, RF_OMUX pc, DMUX ram
316 JMP 326, RF_OMUX pc, DMUX ram, RF_IMUXSEL cmd[5:4], RF_CE hi
326 JMP 3fc, RF_OMUX pc, RF_IMUX pc, RF_AMUX inc, RF_CE
; LD {C,E,L},n                  8 cycles
00e JMP 30e, RF_OMUX pc, DMUX ram
01e JMP 30e, RF_OMUX pc, DMUX ram
02e JMP 30e, RF_OMUX pc, DMUX ram
;   read the byte at PC into the register file
30e JMP 31e, RF_OMUX pc, DMUX ram
31e JMP 32e, RF_OMUX pc, DMUX ram, RF_IMUXSEL cmd[5:4], RF_CE lo
32e JMP 3fc, RF_OMUX pc, RF_IMUX pc, RF_AMUX inc, RF_CE
; LD A,n                        8 cycles
03e JMP 31d, RF_OMUX pc, DMUX ram
31d JMP 32d, RF_OMUX pc, DMUX ram
32d JMP 33d, RF_OMUX pc, DMUX ram, STORE_ACC
33d JMP 3fc, RF_OMUX pc, RF_IMUX pc, RF_AMUX inc, RF_CE
; LD (HL),n                     12 cycles
036 JMP 363, RF_OMUX pc, DMUX ram
363 JMP 364, RF_OMUX pc, DMUX ram
364 JMP 365, RF_OMUX pc, DMUX ram, STORE_TMP
365 JMP 366, RF_OMUX pc, RF_IMUX pc, RF_AMUX inc, RF_CE
366 JMP 367, RF_OMUX hl, DMUX tmp
367 JMP 368, RF_OMUX hl, DMUX tmp
368 JMP 369, RF_OMUX hl, DMUX tmp, WR
369 JMP 3fc, RF_OMUX hl, DMUX tmp, WR

; RLCA, RLA     4 cycles    ZNHC
007 JMP 307, DMUX acc, alu_cmd <= "100000", STORE_ALU, RF_OMUX pc
017 JMP 307, DMUX acc, alu_cmd <= "100001", STORE_ALU, RF_OMUX pc
307 JMP 3fe, DMUX alu, STORE_ACC, RF_OMUX pc, FLAGS znhc

; RRCA, RRA     4 cycles    ZNHC
00f JMP 307, DMUX acc, alu_cmd <= "100010", STORE_ALU, RF_OMUX pc
01f JMP 307, DMUX acc, alu_cmd <= "100011", STORE_ALU, RF_OMUX pc

; DAA     4 cycles    Z-HC
027 JMP 327, DMUX acc, alu_cmd <= "011000", STORE_ALU, RF_OMUX pc
327 JMP 3fe, DMUX alu, STORE_ACC, RF_OMUX pc, FLAGS zhc

; CPL A         4 cycles    -NH-
02f JMP 317, DMUX acc, alu_cmd <= "010011", STORE_ALU, RF_OMUX pc
317 JMP 3fe, DMUX alu, STORE_ACC, RF_OMUX pc, FLAGS nh

; SCF, CCF     4 cycles    -NHC
037 JMP 337, DMUX acc, alu_cmd <= "011010", STORE_ALU, RF_OMUX pc
03f JMP 337, DMUX acc, alu_cmd <= "011011", STORE_ALU, RF_OMUX pc
337 JMP 3fe, DMUX alu, RF_OMUX pc, FLAGS nhc

; LD (nn),SP            20 cycles
; Load S and P into tmp and unq while loading nn into SP. Write tmp and unq to (SP), then
; load the next command while restoring tmp and unq to S and P
;   tmp <= S
;   S <= (PC++)
008 JMP 370, RF_OMUX pc, RF_DMUX sp_hi, DMUX rf, STORE_TMP
370 JMP 371, RF_OMUX pc
371 JMP 372, RF_OMUX pc, DMUX ram, RF_AMUX idata, RF_IMUX sp, RF_CE hi
372 JMP 373, RF_OMUX pc, RF_AMUX inc, RF_IMUX pc, RF_CE
;   unq <= P
;   P <= (PC++)
373 JMP 374, RF_OMUX pc, DMUX rf, RF_DMUX sp_lo, STORE_UNQ
374 JMP 375, RF_OMUX pc
375 JMP 376, RF_OMUX pc, DMUX ram, RF_AMUX idata, RF_IMUX sp, RF_CE lo
376 JMP 377, JCMD, RF_OMUX pc, RF_AMUX inc, RF_IMUX pc, RF_CE
;   (SP++) <= tmp
377 JMP 378, RF_OMUX sp, DMUX tmp
378 JMP 379, RF_OMUX sp, DMUX tmp
379 JMP 37a, RF_OMUX sp, DMUX tmp, WR
37a JMP 37b, RF_OMUX sp, DMUX tmp, WR, RF_AMUX inc, RF_IMUX sp, RF_CE
;   (SP) <= unq
;   P <= unq
37b JMP 37c, RF_OMUX sp, DMUX unq
37c JMP 37d, RF_OMUX sp, DMUX unq
37d JMP 37e, RF_OMUX sp, DMUX unq, WR
37e JMP 37f, RF_OMUX sp, DMUX unq, WR, RF_AMUX idata, RF_IMUX sp, RF_CE lo
;   S <= tmp
;   FETCH
37f JMP 3fd, DMUX tmp, RF_AMUX idata, RF_IMUX sp, RF_CE hi, RF_OMUX pc

; ADD HL,r16     8 cycles    -NHC
009 JMP 309, RF_OMUX bc, RF_AMUX hl, RF_IMUX hl, RF_CE
019 JMP 309, RF_OMUX de, RF_AMUX hl, RF_IMUX hl, RF_CE
029 JMP 309, RF_OMUX hl, RF_AMUX hl, RF_IMUX hl, RF_CE
039 JMP 309, RF_OMUX sp, RF_AMUX hl, RF_IMUX hl, RF_CE
309 JMP 3fa, RFFLAGS, FLAGS nhc

; ***************************************************************************
; *     Second block instructions: 8-bit loads                              *
; ***************************************************************************

; LD B,{B,C,D,E,H,L,A}          4 cycles
040 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX b, RF_IMUX bc, RF_CE hi
041 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX c, RF_IMUX bc, RF_CE hi
042 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX d, RF_IMUX bc, RF_CE hi
043 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX e, RF_IMUX bc, RF_CE hi
044 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX h, RF_IMUX bc, RF_CE hi
045 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX l, RF_IMUX bc, RF_CE hi
047 JMP 3fd, RF_OMUX pc, DMUX acc,           RF_IMUX bc, RF_CE hi
; LD B,(HL)                     8 cycles
046 JMP 340, RF_OMUX hl
340 JMP 341, RF_OMUX hl
341 JMP 342, RF_OMUX hl, RF_IMUXSEL cmd[5:4], RF_CE hi
342 JMP 3fc, RF_OMUX hl

; LD C,{B,C,D,E,H,L,A}          4 cycles
048 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX b, RF_IMUX bc, RF_CE lo
049 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX c, RF_IMUX bc, RF_CE lo
04a JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX d, RF_IMUX bc, RF_CE lo
04b JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX e, RF_IMUX bc, RF_CE lo
04c JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX h, RF_IMUX bc, RF_CE lo
04d JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX l, RF_IMUX bc, RF_CE lo
04f JMP 3fd, RF_OMUX pc, DMUX acc,           RF_IMUX bc, RF_CE lo
; LD C,(HL)                     8 cycles
04e JMP 343, RF_OMUX hl
343 JMP 344, RF_OMUX hl
344 JMP 342, RF_OMUX hl, RF_IMUXSEL cmd[5:4], RF_CE lo

; LD D,{B,C,D,E,H,L,A}          4 cycles
050 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX b, RF_IMUX de, RF_CE hi
051 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX c, RF_IMUX de, RF_CE hi
052 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX d, RF_IMUX de, RF_CE hi
053 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX e, RF_IMUX de, RF_CE hi
054 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX h, RF_IMUX de, RF_CE hi
055 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX l, RF_IMUX de, RF_CE hi
057 JMP 3fd, RF_OMUX pc, DMUX acc,           RF_IMUX de, RF_CE hi
; LD D,(HL)                     8 cycles
056 JMP 340, RF_OMUX hl

; LD E,{B,C,D,E,H,L,A}          4 cycles
058 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX b, RF_IMUX de, RF_CE lo
059 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX c, RF_IMUX de, RF_CE lo
05a JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX d, RF_IMUX de, RF_CE lo
05b JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX e, RF_IMUX de, RF_CE lo
05c JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX h, RF_IMUX de, RF_CE lo
05d JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX l, RF_IMUX de, RF_CE lo
05f JMP 3fd, RF_OMUX pc, DMUX acc,           RF_IMUX de, RF_CE lo
; LD E,(HL)                     8 cycles
05e JMP 343, RF_OMUX hl

; LD H,{B,C,D,E,H,L,A}          4 cycles
060 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX b, RF_IMUX hl, RF_CE hi
061 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX c, RF_IMUX hl, RF_CE hi
062 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX d, RF_IMUX hl, RF_CE hi
063 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX e, RF_IMUX hl, RF_CE hi
064 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX h, RF_IMUX hl, RF_CE hi
065 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX l, RF_IMUX hl, RF_CE hi
067 JMP 3fd, RF_OMUX pc, DMUX acc,           RF_IMUX hl, RF_CE hi
; LD H,(HL)                     8 cycles
066 JMP 340, RF_OMUX hl

; LD L,{B,C,D,E,H,L,A}          4 cycles
068 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX b, RF_IMUX hl, RF_CE lo
069 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX c, RF_IMUX hl, RF_CE lo
06a JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX d, RF_IMUX hl, RF_CE lo
06b JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX e, RF_IMUX hl, RF_CE lo
06c JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX h, RF_IMUX hl, RF_CE lo
06d JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX l, RF_IMUX hl, RF_CE lo
06f JMP 3fd, RF_OMUX pc, DMUX acc,           RF_IMUX hl, RF_CE lo
; LD L,(HL)                     8 cycles
06e JMP 343, RF_OMUX hl

; LD (HL),B                     8 cycles
070 JMP 348, RF_OMUX hl, DMUX rf, RF_DMUX b
348 JMP 349, RF_OMUX hl, DMUX rf, RF_DMUX b
349 JMP 34a, RF_OMUX hl, DMUX rf, RF_DMUX b, WR
34a JMP 3fc, RF_OMUX hl, DMUX rf, RF_DMUX b, WR
; LD (HL),C                     8 cycles
071 JMP 34c, RF_OMUX hl, DMUX rf, RF_DMUX c
34c JMP 34d, RF_OMUX hl, DMUX rf, RF_DMUX c
34d JMP 34e, RF_OMUX hl, DMUX rf, RF_DMUX c, WR
34e JMP 3fc, RF_OMUX hl, DMUX rf, RF_DMUX c, WR
; LD (HL),D                     8 cycles
072 JMP 350, RF_OMUX hl, DMUX rf, RF_DMUX d
350 JMP 351, RF_OMUX hl, DMUX rf, RF_DMUX d
351 JMP 352, RF_OMUX hl, DMUX rf, RF_DMUX d, WR
352 JMP 3fc, RF_OMUX hl, DMUX rf, RF_DMUX d, WR
; LD (HL),E                     8 cycles
073 JMP 354, RF_OMUX hl, DMUX rf, RF_DMUX e
354 JMP 355, RF_OMUX hl, DMUX rf, RF_DMUX e
355 JMP 356, RF_OMUX hl, DMUX rf, RF_DMUX e, WR
356 JMP 3fc, RF_OMUX hl, DMUX rf, RF_DMUX e, WR
; LD (HL),H                     8 cycles
074 JMP 358, RF_OMUX hl, DMUX rf, RF_DMUX h
358 JMP 359, RF_OMUX hl, DMUX rf, RF_DMUX h
359 JMP 35a, RF_OMUX hl, DMUX rf, RF_DMUX h, WR
35a JMP 3fc, RF_OMUX hl, DMUX rf, RF_DMUX h, WR
; LD (HL),L                     8 cycles
075 JMP 35c, RF_OMUX hl, DMUX rf, RF_DMUX l
35c JMP 35d, RF_OMUX hl, DMUX rf, RF_DMUX l
35d JMP 35e, RF_OMUX hl, DMUX rf, RF_DMUX l, WR
35e JMP 3fc, RF_OMUX hl, DMUX rf, RF_DMUX l, WR
; LD (HL),A                     8 cycles
077 JMP 360, RF_OMUX hl, DMUX acc
360 JMP 361, RF_OMUX hl, DMUX acc
361 JMP 362, RF_OMUX hl, DMUX acc, WR
362 JMP 3fc, RF_OMUX hl, DMUX acc, WR

; LD A,{B,C,D,E,H,L,A}          4 cycles
078 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX b, STORE_ACC
079 JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX c, STORE_ACC
07a JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX d, STORE_ACC
07b JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX e, STORE_ACC
07c JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX h, STORE_ACC
07d JMP 3fd, RF_OMUX pc, DMUX rf, RF_DMUX l, STORE_ACC
07f JMP 3fd, RF_OMUX pc, DMUX acc,           STORE_ACC
; LD A,(HL)                     8 cycles
07e JMP 345, RF_OMUX hl
345 JMP 346, RF_OMUX hl
346 JMP 342, RF_OMUX hl, DMUX ram, STORE_ACC

; TODO: HALT

; ***************************************************************************
; *     Third block instructions: 8-bit alu ops                             *
; ***************************************************************************

380 JMP 3fe, DMUX alu, STORE_ACC, FLAGS znhc, RF_OMUX pc
383 JMP 3fc, RF_OMUX hl, STORE_ACC, FLAGS znhc

; ADD A,{B,C,D,E,H,L,A}             4 cycles    ZNHC
080 JMP 380, DMUX rf, RF_DMUX b, alu_cmd <= "000000", STORE_ALU, RF_OMUX pc
081 JMP 380, DMUX rf, RF_DMUX c, alu_cmd <= "000000", STORE_ALU, RF_OMUX pc
082 JMP 380, DMUX rf, RF_DMUX d, alu_cmd <= "000000", STORE_ALU, RF_OMUX pc
083 JMP 380, DMUX rf, RF_DMUX e, alu_cmd <= "000000", STORE_ALU, RF_OMUX pc
084 JMP 380, DMUX rf, RF_DMUX h, alu_cmd <= "000000", STORE_ALU, RF_OMUX pc
085 JMP 380, DMUX rf, RF_DMUX l, alu_cmd <= "000000", STORE_ALU, RF_OMUX pc
087 JMP 380, DMUX acc, alu_cmd <= "000000", STORE_ALU, RF_OMUX pc
; ADD A,(HL)                        8 cycles    ZNHC
086 JMP 381, RF_OMUX hl
381 JMP 382, RF_OMUX hl
382 JMP 383, RF_OMUX hl, alu_cmd <= "000000", STORE_ALU

; ADC A,{B,C,D,E,H,L,A}             4 cycles    ZNHC
088 JMP 380, DMUX rf, RF_DMUX b, alu_cmd <= "000001", STORE_ALU, RF_OMUX pc
089 JMP 380, DMUX rf, RF_DMUX c, alu_cmd <= "000001", STORE_ALU, RF_OMUX pc
08a JMP 380, DMUX rf, RF_DMUX d, alu_cmd <= "000001", STORE_ALU, RF_OMUX pc
08b JMP 380, DMUX rf, RF_DMUX e, alu_cmd <= "000001", STORE_ALU, RF_OMUX pc
08c JMP 380, DMUX rf, RF_DMUX h, alu_cmd <= "000001", STORE_ALU, RF_OMUX pc
08d JMP 380, DMUX rf, RF_DMUX l, alu_cmd <= "000001", STORE_ALU, RF_OMUX pc
08f JMP 380, DMUX acc, alu_cmd <= "000001", STORE_ALU, RF_OMUX pc
; ADC A,(HL)                        8 cycles    ZNHC
08e JMP 384, RF_OMUX hl
384 JMP 385, RF_OMUX hl
385 JMP 383, RF_OMUX hl, alu_cmd <= "000001", STORE_ALU

; SUB A,{B,C,D,E,H,L,A}             4 cycles    ZNHC
090 JMP 380, DMUX rf, RF_DMUX b, alu_cmd <= "000010", STORE_ALU, RF_OMUX pc
091 JMP 380, DMUX rf, RF_DMUX c, alu_cmd <= "000010", STORE_ALU, RF_OMUX pc
092 JMP 380, DMUX rf, RF_DMUX d, alu_cmd <= "000010", STORE_ALU, RF_OMUX pc
093 JMP 380, DMUX rf, RF_DMUX e, alu_cmd <= "000010", STORE_ALU, RF_OMUX pc
094 JMP 380, DMUX rf, RF_DMUX h, alu_cmd <= "000010", STORE_ALU, RF_OMUX pc
095 JMP 380, DMUX rf, RF_DMUX l, alu_cmd <= "000010", STORE_ALU, RF_OMUX pc
097 JMP 380, DMUX acc, alu_cmd <= "000010", STORE_ALU, RF_OMUX pc
; SUB A,(HL)                        8 cycles    ZNHC
096 JMP 386, RF_OMUX hl
386 JMP 387, RF_OMUX hl
387 JMP 383, RF_OMUX hl, alu_cmd <= "000010", STORE_ALU

; SBC A,{B,C,D,E,H,L,A}             4 cycles    ZNHC
098 JMP 380, DMUX rf, RF_DMUX b, alu_cmd <= "000011", STORE_ALU, RF_OMUX pc
099 JMP 380, DMUX rf, RF_DMUX c, alu_cmd <= "000011", STORE_ALU, RF_OMUX pc
09a JMP 380, DMUX rf, RF_DMUX d, alu_cmd <= "000011", STORE_ALU, RF_OMUX pc
09b JMP 380, DMUX rf, RF_DMUX e, alu_cmd <= "000011", STORE_ALU, RF_OMUX pc
09c JMP 380, DMUX rf, RF_DMUX h, alu_cmd <= "000011", STORE_ALU, RF_OMUX pc
09d JMP 380, DMUX rf, RF_DMUX l, alu_cmd <= "000011", STORE_ALU, RF_OMUX pc
09f JMP 380, DMUX acc, alu_cmd <= "000011", STORE_ALU, RF_OMUX pc
; SBC A,(HL)                        8 cycles    ZNHC
09e JMP 388, RF_OMUX hl
388 JMP 389, RF_OMUX hl
389 JMP 383, RF_OMUX hl, alu_cmd <= "000011", STORE_ALU

; AND A,{B,C,D,E,H,L,A}             4 cycles    ZNHC
0a0 JMP 380, DMUX rf, RF_DMUX b, alu_cmd <= "010000", STORE_ALU, RF_OMUX pc
0a1 JMP 380, DMUX rf, RF_DMUX c, alu_cmd <= "010000", STORE_ALU, RF_OMUX pc
0a2 JMP 380, DMUX rf, RF_DMUX d, alu_cmd <= "010000", STORE_ALU, RF_OMUX pc
0a3 JMP 380, DMUX rf, RF_DMUX e, alu_cmd <= "010000", STORE_ALU, RF_OMUX pc
0a4 JMP 380, DMUX rf, RF_DMUX h, alu_cmd <= "010000", STORE_ALU, RF_OMUX pc
0a5 JMP 380, DMUX rf, RF_DMUX l, alu_cmd <= "010000", STORE_ALU, RF_OMUX pc
0a7 JMP 380, DMUX acc, alu_cmd <= "010000", STORE_ALU, RF_OMUX pc
; AND A,(HL)                        8 cycles    ZNHC
0a6 JMP 38a, RF_OMUX hl
38a JMP 38b, RF_OMUX hl
38b JMP 383, RF_OMUX hl, alu_cmd <= "010000", STORE_ALU

; XOR A,{B,C,D,E,H,L,A}             4 cycles    ZNHC
0a8 JMP 380, DMUX rf, RF_DMUX b, alu_cmd <= "010010", STORE_ALU, RF_OMUX pc
0a9 JMP 380, DMUX rf, RF_DMUX c, alu_cmd <= "010010", STORE_ALU, RF_OMUX pc
0aa JMP 380, DMUX rf, RF_DMUX d, alu_cmd <= "010010", STORE_ALU, RF_OMUX pc
0ab JMP 380, DMUX rf, RF_DMUX e, alu_cmd <= "010010", STORE_ALU, RF_OMUX pc
0ac JMP 380, DMUX rf, RF_DMUX h, alu_cmd <= "010010", STORE_ALU, RF_OMUX pc
0ad JMP 380, DMUX rf, RF_DMUX l, alu_cmd <= "010010", STORE_ALU, RF_OMUX pc
0af JMP 380, DMUX acc, alu_cmd <= "010010", STORE_ALU, RF_OMUX pc
; XOR A,(HL)                        8 cycles    ZNHC
0ae JMP 38c, RF_OMUX hl
38c JMP 38d, RF_OMUX hl
38d JMP 383, RF_OMUX hl, alu_cmd <= "010010", STORE_ALU

; OR A,{B,C,D,E,H,L,A}              4 cycles    ZNHC
0b0 JMP 380, DMUX rf, RF_DMUX b, alu_cmd <= "010001", STORE_ALU, RF_OMUX pc
0b1 JMP 380, DMUX rf, RF_DMUX c, alu_cmd <= "010001", STORE_ALU, RF_OMUX pc
0b2 JMP 380, DMUX rf, RF_DMUX d, alu_cmd <= "010001", STORE_ALU, RF_OMUX pc
0b3 JMP 380, DMUX rf, RF_DMUX e, alu_cmd <= "010001", STORE_ALU, RF_OMUX pc
0b4 JMP 380, DMUX rf, RF_DMUX h, alu_cmd <= "010001", STORE_ALU, RF_OMUX pc
0b5 JMP 380, DMUX rf, RF_DMUX l, alu_cmd <= "010001", STORE_ALU, RF_OMUX pc
0b7 JMP 380, DMUX acc, alu_cmd <= "010001", STORE_ALU, RF_OMUX pc
; OR A,(HL)                         8 cycles    ZNHC
0b6 JMP 38e, RF_OMUX hl
38e JMP 38f, RF_OMUX hl
38f JMP 383, RF_OMUX hl, alu_cmd <= "010001", STORE_ALU

; CP A,{B,C,D,E,H,L,A}              4 cycles    ZNHC
;   Only set flags, not ACC
0b8 JMP 390, DMUX rf, RF_DMUX b, alu_cmd <= "000110", STORE_ALU, RF_OMUX pc
0b9 JMP 390, DMUX rf, RF_DMUX c, alu_cmd <= "000110", STORE_ALU, RF_OMUX pc
0ba JMP 390, DMUX rf, RF_DMUX d, alu_cmd <= "000110", STORE_ALU, RF_OMUX pc
0bb JMP 390, DMUX rf, RF_DMUX e, alu_cmd <= "000110", STORE_ALU, RF_OMUX pc
0bc JMP 390, DMUX rf, RF_DMUX h, alu_cmd <= "000110", STORE_ALU, RF_OMUX pc
0bd JMP 390, DMUX rf, RF_DMUX l, alu_cmd <= "000110", STORE_ALU, RF_OMUX pc
0bf JMP 390, DMUX acc, alu_cmd <= "000110", STORE_ALU, RF_OMUX pc
390 JMP 3fe, DMUX alu, FLAGS znhc, RF_OMUX pc
; CP A,(HL)                         8 cycles    ZNHC
0be JMP 391, RF_OMUX hl
391 JMP 392, RF_OMUX hl
392 JMP 393, RF_OMUX hl, alu_cmd <= "000110", STORE_ALU
393 JMP 3fc, RF_OMUX hl, FLAGS znhc

; ***************************************************************************
; *     Fourth block instructions (with opcode [c-f]*)                      *
; ***************************************************************************

; Fast Loads
; LD (FF & n), A            12 cycles
0e0 JMP 25c, RF_OMUX pc
2e0 JMP 290, AMUX FF_tmp, DMUX acc
290 JMP 291, AMUX FF_tmp, DMUX acc
291 JMP 292, AMUX FF_tmp, DMUX acc, WR
292 JMP 3fc, AMUX FF_tmp, DMUX acc, WR
; LD (FF & C), A            8 cycles
0e2 JMP 293, RF_DMUX c, AMUX FF_rf8, DMUX acc
293 JMP 294, RF_DMUX c, AMUX FF_rf8, DMUX acc
294 JMP 295, RF_DMUX c, AMUX FF_rf8, DMUX acc, WR
295 JMP 3fc, RF_DMUX c, AMUX FF_rf8, DMUX acc, WR

; LD A, (FF & n)            12 cycles
0f0 JMP 25c, RF_OMUX pc
2f0 JMP 357, AMUX FF_tmp
357 JMP 297, AMUX FF_tmp
297 JMP 298, AMUX FF_tmp, STORE_ACC
298 JMP 3fc, AMUX FF_tmp
; LD A, (FF & C)            8 cycles
0f2 JMP 299, RF_DMUX c, AMUX FF_rf8
299 JMP 29a, RF_DMUX c, AMUX FF_rf8
29a JMP 29b, RF_DMUX c, AMUX FF_rf8, STORE_ACC
29b JMP 3fc, RF_DMUX c, AMUX FF_rf8

; LD (nn), A                16 cycles
0ea JMP 258, RF_OMUX pc
2ea JMP 29c, AMUX tmp_unq, DMUX acc
29c JMP 29d, AMUX tmp_unq, DMUX acc
29d JMP 20d, AMUX tmp_unq, DMUX acc, WR
20d JMP 3fc, AMUX tmp_unq, DMUX acc, WR
; LD A, (nn)                16 cycles
0fa JMP 258, RF_OMUX pc
2fa JMP 257, AMUX tmp_unq
257 JMP 267, AMUX tmp_unq
267 JMP 277, AMUX tmp_unq, STORE_ACC
277 JMP 3fc, AMUX tmp_unq

; PUSH helper
;   (SP) <= tmp
250 JMP 251, DMUX tmp, RF_OMUX sp
251 JMP 252, DMUX tmp, RF_OMUX sp
252 JMP 253, DMUX tmp, RF_OMUX sp, WR
253 JMP 3f9, DMUX tmp, RF_OMUX sp, WR

; PUSH BC                           16 cycles
;   SP--
;   tmp <= lsB(BC)
0c5 JMP 240, RF_DMUX c, DMUX rf, STORE_TMP, RF_OMUX sp, RF_AMUX dec, RF_IMUX sp, RF_CE
;   (SP--) <= msB(BC)
240 JMP 241, RF_DMUX b, DMUX rf, RF_OMUX sp
241 JMP 242, RF_DMUX b, DMUX rf, RF_OMUX sp
242 JMP 243, RF_DMUX b, DMUX rf, RF_OMUX sp, WR
243 JMP 250, RF_DMUX b, DMUX rf, RF_OMUX sp, WR, RF_AMUX dec, RF_IMUX sp, RF_CE

; PUSH DE                           16 cycles
;   SP--
;   tmp <= E
0d5 JMP 244, RF_DMUX e, DMUX rf, STORE_TMP, RF_OMUX sp, RF_AMUX dec, RF_IMUX sp, RF_CE
;   (SP--) <= D
244 JMP 245, RF_DMUX d, DMUX rf, RF_OMUX sp
245 JMP 30c, RF_DMUX d, DMUX rf, RF_OMUX sp
30c JMP 247, RF_DMUX d, DMUX rf, RF_OMUX sp, WR
247 JMP 240, RF_DMUX d, DMUX rf, RF_OMUX sp, WR, RF_AMUX dec, RF_IMUX sp, RF_CE

; PUSH HL                           16 cycles
;   SP--
;   tmp <= L
0e5 JMP 248, RF_DMUX l, DMUX rf, STORE_TMP, RF_OMUX sp, RF_AMUX dec, RF_IMUX sp, RF_CE
;   (SP--) <= H
248 JMP 249, RF_DMUX h, DMUX rf, RF_OMUX sp
249 JMP 24a, RF_DMUX h, DMUX rf, RF_OMUX sp
24a JMP 24b, RF_DMUX h, DMUX rf, RF_OMUX sp, WR
24b JMP 240, RF_DMUX h, DMUX rf, RF_OMUX sp, WR, RF_AMUX dec, RF_IMUX sp, RF_CE

; PUSH AF                           16 cycles
;   SP--
;   tmp <= znhc0000
0f5 JMP 3b8, DMUX znhc, STORE_TMP, RF_OMUX sp, RF_AMUX dec, RF_IMUX sp, RF_CE
;   (SP--) <= A
3b8 JMP 3b9, DMUX acc, RF_OMUX sp
3b9 JMP 3ba, DMUX acc, RF_OMUX sp
3ba JMP 3bb, DMUX acc, RF_OMUX sp, WR
3bb JMP 240, DMUX acc, RF_OMUX sp, WR, RF_AMUX dec, RF_IMUX sp, RF_CE


; POP BC                            12 cycles
;   C <= (SP++)
0c1 JMP 260, RF_OMUX sp
260 JMP 261, RF_OMUX sp
261 JMP 262, RF_OMUX sp, RF_IMUX bc, RF_CE lo
262 JMP 263, RF_OMUX sp, RF_AMUX inc, RF_IMUX sp, RF_CE
;   B <= (SP++)
263 JMP 264, RF_OMUX sp
264 JMP 265, RF_OMUX sp
265 JMP 32c, RF_OMUX sp, RF_IMUX bc, RF_CE hi
32c JMP 3fc, RF_OMUX sp, RF_AMUX inc, RF_IMUX sp, RF_CE

; POP DE                            12 cycles
;   E <= (SP++)
0d1 JMP 268, RF_OMUX sp
268 JMP 269, RF_OMUX sp
269 JMP 26a, RF_OMUX sp, RF_IMUX de, RF_CE lo
26a JMP 26b, RF_OMUX sp, RF_AMUX inc, RF_IMUX sp, RF_CE
;   D <= (SP++)
26b JMP 26c, RF_OMUX sp
26c JMP 26d, RF_OMUX sp
26d JMP 23d, RF_OMUX sp, RF_IMUX de, RF_CE hi
23d JMP 3fc, RF_OMUX sp, RF_AMUX inc, RF_IMUX sp, RF_CE

; POP HL                            12 cycles
;   L <= (SP++)
0e1 JMP 270, RF_OMUX sp
270 JMP 271, RF_OMUX sp
271 JMP 272, RF_OMUX sp, RF_IMUX hl, RF_CE lo
272 JMP 273, RF_OMUX sp, RF_AMUX inc, RF_IMUX sp, RF_CE
;   H <= (SP++)
273 JMP 274, RF_OMUX sp
274 JMP 275, RF_OMUX sp
275 JMP 33c, RF_OMUX sp, RF_IMUX hl, RF_CE hi
33c JMP 3fc, RF_OMUX sp, RF_AMUX inc, RF_IMUX sp, RF_CE

; POP AF                            12 cycles
;   TODO: flags <= (SP++)
0f1 JMP 278, RF_OMUX sp
278 JMP 279, RF_OMUX sp
279 JMP 27a, RF_OMUX sp
27a JMP 27b, RF_OMUX sp, RF_AMUX inc, RF_IMUX sp, RF_CE
;   A <= (SP++)
27b JMP 27c, RF_OMUX sp
27c JMP 27d, RF_OMUX sp
27d JMP 22d, RF_OMUX sp, STORE_ACC
22d JMP 3fc, RF_OMUX sp, RF_AMUX inc, RF_IMUX sp, RF_CE


280 JMP 3fc, RF_OMUX pc, RF_AMUX inc, RF_IMUX pc, RF_CE, DMUX alu, STORE_ACC, FLAGS znhc
28f JMP 3fc, RF_OMUX pc, RF_AMUX inc, RF_IMUX pc, RF_CE, FLAGS znhc
; ADD A,n                           8 cycles
0c6 JMP 281, RF_OMUX pc
281 JMP 282, RF_OMUX pc
282 JMP 280, RF_OMUX pc, alu_cmd <= "000000", STORE_ALU
; ADC A,n                           8 cycles
0ce JMP 283, RF_OMUX pc
283 JMP 284, RF_OMUX pc
284 JMP 280, RF_OMUX pc, alu_cmd <= "000001", STORE_ALU
; SUB A,n                           8 cycles
0d6 JMP 285, RF_OMUX pc
285 JMP 347, RF_OMUX pc
347 JMP 280, RF_OMUX pc, alu_cmd <= "000010", STORE_ALU
; SBC A,n                           8 cycles
0de JMP 287, RF_OMUX pc
287 JMP 288, RF_OMUX pc
288 JMP 280, RF_OMUX pc, alu_cmd <= "000011", STORE_ALU
; AND A,n                           8 cycles
0e6 JMP 289, RF_OMUX pc
289 JMP 28a, RF_OMUX pc
28a JMP 280, RF_OMUX pc, alu_cmd <= "010000", STORE_ALU
; XOR A,n                           8 cycles
0ee JMP 28b, RF_OMUX pc
28b JMP 28c, RF_OMUX pc
28c JMP 280, RF_OMUX pc, alu_cmd <= "010010", STORE_ALU
; OR A,n                            8 cycles
0f6 JMP 28d, RF_OMUX pc
28d JMP 21d, RF_OMUX pc
21d JMP 280, RF_OMUX pc, alu_cmd <= "010001", STORE_ALU
; CP A,n                            8 cycles
0fe JMP 308, RF_OMUX pc
308 JMP 30d, RF_OMUX pc
30d JMP 28f, RF_OMUX pc, alu_cmd <= "000110", STORE_ALU


; JNZ nn        16/12 cycles



; JNZ/Z helper
;   Load (PC) into unq, PC++. Address should already be on bus for 1 cycle
3a0 JMP 3a1, RF_OMUX pc
3a1 JMP 3a2, RF_OMUX pc, STORE_UNQ
3a2 JMP 3a3, RF_OMUX pc, RF_AMUX inc, RF_IMUX pc, RF_CE
;   (PC) into tmp, PC++, and jump to "10" & CMD
3a3 JMP 3a4, RF_OMUX pc
3a4 JMP 3a5, RF_OMUX pc
3a5 JMP 3a6, RF_OMUX pc, STORE_TMP
;   jump depending on zero flag
3a6 JMP 200, JCMD, JZERO, RF_OMUX pc, RF_IMUX pc, RF_AMUX inc, RF_CE

; JNZ/Z final set
3a7 JMP 3fa, DMUX unq, RF_IMUX pc, RF_CE lo



; JNZ nn
;   read nn
0c2 JMP 3a0, RF_OMUX pc
;   flag is not set, so put n on the databus and update PC (6 cycles left)
2c2 JMP 3a7, DMUX tmp, RF_IMUX pc, RF_CE hi
;   flag is set, so move on to fetch (3 cycles left)
3c2 JMP 3fd, RF_OMUX pc

; JZ nn
;   read nn
0ca JMP 3a0, RF_OMUX pc
;   flag is not set, so move on to fetch (3 cycles left)
2ca JMP 3fd, RF_OMUX pc
;   flag is set, so put n on the databus and update PC (6 cycles left)
3ca JMP 3a7, DMUX tmp, RF_IMUX pc, RF_CE hi

; JP nn
;   read nn
0c3 JMP 3a0, RF_OMUX pc
;   used a flag-based jump but flag doesn't matter - put n on the databus and update PC (6 cycles left)
2c3 JMP 3a7, DMUX tmp, RF_IMUX pc, RF_CE hi
3c3 JMP 3a7, DMUX tmp, RF_IMUX pc, RF_CE hi


; JNC nn        16/12 cycles



; JNC/C helper
;   Load (PC) into unq, PC++. Address should already be on bus for 1 cycle
3b0 JMP 3b1, RF_OMUX pc
3b1 JMP 3b2, RF_OMUX pc, STORE_UNQ
3b2 JMP 3b3, RF_OMUX pc, RF_IMUX pc, RF_AMUX inc, RF_CE
;   (PC) into tmp, PC++, and jump to "10" & CMD
3b3 JMP 3b4, RF_OMUX pc
3b4 JMP 3b5, RF_OMUX pc
3b5 JMP 3b6, RF_OMUX pc, STORE_TMP
;   jump depending on carry flag
3b6 JMP 200, RF_OMUX pc, JCMD, JCARRY, RF_IMUX pc, RF_AMUX inc, RF_CE

; JC/NC final set (TODO identical to 3a7, neccessary?)
3b7 JMP 3fa, DMUX unq, RF_IMUX pc, RF_CE lo




; JNC nn
;   read nn
0d2 JMP 3b0, RF_OMUX pc
;   flag is not set, so put n on the databus and update PC (6 cycles left)
2d2 JMP 3b7, DMUX tmp, RF_IMUX pc, RF_CE hi
;   flag is set, so move on to fetch (3 cycles left)
3d2 JMP 3fd, RF_OMUX pc

; JC nn
;   read nn
0da JMP 3b0, RF_OMUX pc
;   flag is not set, so move on to fetch (3 cycles left)
2da JMP 3fd, RF_OMUX pc
;   flag is set, so put n on the databus and update PC (6 cycles left)
3da JMP 3b7, DMUX tmp, RF_IMUX pc, RF_CE hi


; CALL helper
;   Note that SP is only decremented once here. First decrement should happen in calling routine.
;   (SP--) <= msB(PC)       (15 cycles left)
207 JMP 217, RF_DMUX pc_hi, DMUX rf, RF_OMUX sp
217 JMP 227, RF_DMUX pc_hi, DMUX rf, RF_OMUX sp
227 JMP 237, RF_DMUX pc_hi, DMUX rf, RF_OMUX sp, WR
237 JMP 209, RF_DMUX pc_hi, DMUX rf, RF_OMUX sp, WR, RF_AMUX dec, RF_IMUX sp, RF_CE
;   (SP) <= lsB(PC)
209 JMP 219, RF_DMUX pc_lo, DMUX rf, RF_OMUX sp
219 JMP 229, RF_DMUX pc_lo, DMUX rf, RF_OMUX sp
229 JMP 239, RF_DMUX pc_lo, DMUX rf, RF_OMUX sp, WR
239 JMP 321, RF_DMUX pc_lo, DMUX rf, RF_OMUX sp, WR
;   Now set PC <= nn (in tmp and unq)       (7 cycles left)
321 JMP 331, DMUX tmp, RF_IMUX pc, RF_CE hi
331 JMP 3fb, DMUX unq, RF_IMUX pc, RF_CE lo


; CALL nn                   24 cycles
;   read nn, returning on zero flag
0cd JMP 3a0, RF_OMUX pc
;   flag doesn't matter     (16 cycles left)
;   SP--
2cd JMP 207, RF_OMUX sp, RF_AMUX dec, RF_IMUX sp, RF_CE
3cd JMP 207, RF_OMUX sp, RF_AMUX dec, RF_IMUX sp, RF_CE

; CALLNZ nn                 24/12 cycles
;   read nn, returning on zero flag
0c4 JMP 3a0, RF_OMUX pc
;   flag is not set, so SP-- and push PC (16 cycles left)
2c4 JMP 207, RF_OMUX sp, RF_AMUX dec, RF_IMUX sp, RF_CE
;   flag is set, so move on to fetch (4 cycles left)
3c4 JMP 3fd, RF_OMUX pc

; CALLZ nn                  24 cycles
;   read nn, returning on zero flag
0cc JMP 3a0, RF_OMUX pc
;   flag is not set, so move on to fetch (4 cycles left)
2cc JMP 3fd, RF_OMUX pc
;   flag is set, so SP-- and push PC (16 cycles left)
3cc JMP 207, RF_OMUX sp, RF_AMUX dec, RF_IMUX sp, RF_CE

; CALLNC nn                 24/12 cycles
;   read nn, returning on carry flag
0d4 JMP 3b0, RF_OMUX pc
;   flag is not set, so SP-- and push PC (16 cycles left)
2d4 JMP 207, RF_OMUX sp, RF_AMUX dec, RF_IMUX sp, RF_CE
;   flag is set, so move on to fetch (4 cycles left)
3d4 JMP 3fd, RF_OMUX pc

; CALLC nn                  24 cycles
;   read nn, returning on carry flag
0dc JMP 3b0, RF_OMUX pc
;   flag is not set, so move on to fetch (4 cycles left)
2dc JMP 3fd, RF_OMUX pc
;   flag is set, so SP-- and push PC (16 cycles left)
3dc JMP 207, RF_OMUX sp, RF_AMUX dec, RF_IMUX sp, RF_CE


; RST                   16 cycles
;   TODO 16 or 32 cycles?

; helper
;   (SP--) <= msB(PC)       (14 cycles left)
3a8 JMP 3a9, RF_DMUX pc_hi, DMUX rf, RF_OMUX sp
3a9 JMP 3aa, RF_DMUX pc_hi, DMUX rf, RF_OMUX sp
3aa JMP 3ab, RF_DMUX pc_hi, DMUX rf, RF_OMUX sp, WR
3ab JMP 3ac, RF_DMUX pc_hi, DMUX rf, RF_OMUX sp, WR, RF_AMUX dec, RF_IMUX sp, RF_CE
;   (SP) <= lsB(PC)
3ac JMP 3ad, RF_DMUX pc_lo, DMUX rf, RF_OMUX sp
3ad JMP 3ae, RF_DMUX pc_lo, DMUX rf, RF_OMUX sp
3ae JMP 3af, RF_DMUX pc_lo, DMUX rf, RF_OMUX sp, WR
3af JMP 39e, RF_DMUX pc_lo, DMUX rf, RF_OMUX sp, WR
;   Now set PC <= nn (in tmp and unq)       (6 cycles left)
39e JMP 39f, DMUX tmp, RF_IMUX pc, RF_CE hi
39f JMP 3fc, DMUX unq, RF_IMUX pc, RF_CE lo

; RST 00
; 00h in tmp and 00h in unq
0c7 JMP 2c7, DMUX alucmd, alu_cmd <= "000000", STORE_TMP
2c7 JMP 3a8, DMUX alucmd, alu_cmd <= "000000", STORE_UNQ

; RST 08
; 00h in tmp and 08h in unq
0cf JMP 2cf, DMUX alucmd, alu_cmd <= "000000", STORE_TMP
2cf JMP 3a8, DMUX alucmd, alu_cmd <= "001000", STORE_UNQ

; RST 10
; 00h in tmp and 10h in unq
0d7 JMP 2d7, DMUX alucmd, alu_cmd <= "000000", STORE_TMP
2d7 JMP 3a8, DMUX alucmd, alu_cmd <= "010000", STORE_UNQ

; RST 18
; 00h in tmp and 18h in unq
0df JMP 2df, DMUX alucmd, alu_cmd <= "000000", STORE_TMP
2df JMP 3a8, DMUX alucmd, alu_cmd <= "011000", STORE_UNQ

; RST 20
; 00h in tmp and 20h in unq
0e7 JMP 2e7, DMUX alucmd, alu_cmd <= "000000", STORE_TMP
2e7 JMP 3a8, DMUX alucmd, alu_cmd <= "100000", STORE_UNQ

; RST 28
; 00h in tmp and 28h in unq
0ef JMP 2ef, DMUX alucmd, alu_cmd <= "000000", STORE_TMP
2ef JMP 3a8, DMUX alucmd, alu_cmd <= "101000", STORE_UNQ

; RST 30
; 00h in tmp and 30h in unq
0f7 JMP 2f7, DMUX alucmd, alu_cmd <= "000000", STORE_TMP
2f7 JMP 3a8, DMUX alucmd, alu_cmd <= "110000", STORE_UNQ

; RST 38
; 00h in tmp and 38h in unq
0ff JMP 2ff, DMUX alucmd, alu_cmd <= "000000", STORE_TMP
2ff JMP 3a8, DMUX alucmd, alu_cmd <= "111000", STORE_UNQ


; RET helper
;   delay line
39b JMP 39c
39c JMP 39d
39d JMP 394, RF_OMUX sp
;   C <= (SP++)
394 JMP 395, RF_OMUX sp
395 JMP 396, RF_OMUX sp, RF_IMUX pc, RF_CE lo
396 JMP 397, RF_OMUX sp, RF_AMUX inc, RF_IMUX sp, RF_CE
;   P <= (SP++)
397 JMP 398, RF_OMUX sp
398 JMP 399, RF_OMUX sp
399 JMP 39a, RF_OMUX sp, RF_IMUX pc, RF_CE hi
39a JMP 3f8, RF_OMUX sp, RF_AMUX inc, RF_IMUX sp, RF_CE

; RET           16 cycles
0c9 JMP 394, RF_OMUX sp

; RETNZ         20/8 cycles
0c8 JMP 200, JCMD, JZERO
;   flag is not set, so pop into PC (19 cycles left)
2c8 JMP 39b
;   flag is set, so move on to fetch (7 cycles left)
3c8 JMP 3fa

; RETZ          20/8 cycles
0c0 JMP 200, JCMD, JZERO
;   flag is not set, so move on to fetch (7 cycles left)
2c0 JMP 3fa
;   flag is set, so pop into PC (19 cycles left)
3c0 JMP 39b

; RETNC         20/8 cycles
0d8 JMP 200, JCMD, JCARRY
;   flag is not set, so pop into PC (19 cycles left)
2d8 JMP 39b
;   flag is set, so move on to fetch (7 cycles left)
3d8 JMP 3fa

; RETC          20/8 cycles
0d0 JMP 200, JCMD, JCARRY
;   flag is not set, so move on to fetch (7 cycles left)
2d0 JMP 3fa
;   flag is set, so pop into PC (19 cycles left)
3d0 JMP 39b


; JP HL         4 cycles
;   HL on address bus, H into P
0e9 JMP 2e9, RF_OMUX hl, DMUX rf, RF_DMUX h, RF_IMUX pc, RF_CE hi
;   HL on address bus, L into C
2e9 JMP 3fe, RF_OMUX hl, DMUX rf, RF_DMUX l, RF_IMUX pc, RF_CE lo
;   FIXME Why HL on address bus? Not needed


; ADD SP,n      16 cycles
;   read n into tmp, inc PC, jmp to 2e8
0e8 JMP 25c, RF_OMUX pc
;   Use internal 16-bit data path, taking flags from RF
2e8 JMP 3f5, RF_OMUX sp, RF_AMUX idata, RF_IMUX sp, RF_CE, RFFLAGS, FLAGS znhc
;   FIXME shouldn't DMUX be tmp here?

; LD HL,SP+n    12 cycles
;   read n into tmp, inc PC
0f8 JMP 25c, RF_OMUX pc
;   Use internal 16-bit data path, taking flags from RF
2f8 JMP 3f9, RF_OMUX sp, RF_AMUX idata, RF_IMUX hl, RF_CE, RFFLAGS, FLAGS znhc
;   FIXME shouldn't DMUX be tmp here?

; LD SP, HL     8 cycles
;   Use internal 16-bit data path
0f9 JMP 3f9, RF_OMUX hl, RF_IMUX sp, RF_CE


; ***************************************************************************
; *     CB Prefix Routines (Bit Manipulations)                              *
; ***************************************************************************

; CB prefix
;   load the second instruction byte into CMD, then jump to "01" & CMD
0cb JMP 2cb, RF_OMUX pc
2cb JMP 2db, RF_OMUX pc
2db JMP 2eb, RF_OMUX pc, STORE_CMD
2eb JMP 100, JCMD, RF_OMUX pc, RF_AMUX inc, RF_IMUX pc, RF_CE

; CB helper
;   Return values to register, including flags
319 JMP 3fe, RF_OMUX pc, DMUX alu, RF_IMUXSEL cmd[2:1], RF_CE hi, FLAGS znhc
329 JMP 3fe, RF_OMUX pc, DMUX alu, RF_IMUXSEL cmd[2:1], RF_CE lo, FLAGS znhc
339 JMP 3fe, RF_OMUX pc, DMUX alu, STORE_ACC, FLAGS znhc

; CB (HL) helper: tmp <= (HL), return to 200 + CMD
30f JMP 31f, RF_OMUX hl
31f JMP 200, JCMD, RF_OMUX hl, STORE_TMP

; CB (HL) helper: (HL) <= tmp   (7 cycles remaining)
32f JMP 33f, RF_OMUX hl, DMUX tmp
33f JMP 34f, RF_OMUX hl, DMUX tmp, WR
34f JMP 3fc, RF_OMUX hl, DMUX tmp, WR

; RLC (B,C,D,E,H,L}     8 cycles    ZNHC
100 JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "100000", STORE_ALU
101 JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "100000", STORE_ALU
102 JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "100000", STORE_ALU
103 JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "100000", STORE_ALU
104 JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "100000", STORE_ALU
105 JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "100000", STORE_ALU
; RLC A                 8 cycles    ZNHC
107 JMP 339, RF_OMUX pc, DMUX acc, alu_cmd <= "100000", STORE_ALU
; RLC (HL)              16 cycles    ZNHC
;   tmp <= HL           (12 cycles left)
106 JMP 30f, RF_OMUX hl
;   tmp <= RLC(tmp)     (9 cycles left)
206 JMP 2a0, RF_OMUX hl, DMUX tmp, alu_cmd <= "100000", STORE_ALU
2a0 JMP 32f, RF_OMUX hl, DMUX alu, STORE_TMP, FLAGS znhc

; RRC (B,C,D,E,H,L}     8 cycles    ZNHC
108 JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "100010", STORE_ALU
109 JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "100010", STORE_ALU
10a JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "100010", STORE_ALU
10b JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "100010", STORE_ALU
10c JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "100010", STORE_ALU
10d JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "100010", STORE_ALU
; RRC A                 8 cycles    ZNHC
10f JMP 339, RF_OMUX pc, DMUX acc, alu_cmd <= "100010", STORE_ALU
; RRC (HL)              16 cycles    ZNHC
;   tmp <= HL           (12 cycles left)
10e JMP 30f, RF_OMUX hl
;   tmp <= RRC(tmp)     (9 cycles left)
20e JMP 2a0, RF_OMUX hl, DMUX tmp, alu_cmd <= "100010", STORE_ALU

; RL (B,C,D,E,H,L}     8 cycles    ZNHC
110 JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "100001", STORE_ALU
111 JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "100001", STORE_ALU
112 JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "100001", STORE_ALU
113 JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "100001", STORE_ALU
114 JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "100001", STORE_ALU
115 JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "100001", STORE_ALU
; RL A                 8 cycles    ZNHC
117 JMP 339, RF_OMUX pc, DMUX acc, alu_cmd <= "100001", STORE_ALU
; RL (HL)               16 cycles    ZNHC
;   tmp <= HL           (12 cycles left)
116 JMP 30f, RF_OMUX hl
;   tmp <= RL(tmp)      (9 cycles left)
216 JMP 2a0, RF_OMUX hl, DMUX tmp, alu_cmd <= "100001", STORE_ALU

; RR (B,C,D,E,H,L}     8 cycles    ZNHC
118 JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "100011", STORE_ALU
119 JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "100011", STORE_ALU
11a JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "100011", STORE_ALU
11b JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "100011", STORE_ALU
11c JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "100011", STORE_ALU
11d JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "100011", STORE_ALU
; RR A                 8 cycles    ZNHC
11f JMP 339, RF_OMUX pc, DMUX acc, alu_cmd <= "100011", STORE_ALU
; RR (HL)               16 cycles    ZNHC
;   tmp <= HL           (12 cycles left)
11e JMP 30f, RF_OMUX hl
;   tmp <= RR(tmp)      (9 cycles left)
21e JMP 2a0, RF_OMUX hl, DMUX tmp, alu_cmd <= "100011", STORE_ALU

; SLA (B,C,D,E,H,L}     8 cycles    ZNHC
120 JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "100100", STORE_ALU
121 JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "100100", STORE_ALU
122 JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "100100", STORE_ALU
123 JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "100100", STORE_ALU
124 JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "100100", STORE_ALU
125 JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "100100", STORE_ALU
; SLA A                 8 cycles    ZNHC
127 JMP 339, RF_OMUX pc, DMUX acc, alu_cmd <= "100100", STORE_ALU
; SLA (HL)              16 cycles    ZNHC
;   tmp <= HL           (12 cycles left)
126 JMP 30f, RF_OMUX hl
;   tmp <= SLA(tmp)     (9 cycles left)
226 JMP 2a0, RF_OMUX hl, DMUX tmp, alu_cmd <= "100100", STORE_ALU

; SRA (B,C,D,E,H,L}     8 cycles    ZNHC
128 JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "100101", STORE_ALU
129 JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "100101", STORE_ALU
12a JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "100101", STORE_ALU
12b JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "100101", STORE_ALU
12c JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "100101", STORE_ALU
12d JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "100101", STORE_ALU
; SRA A                 8 cycles    ZNHC
12f JMP 339, RF_OMUX pc, DMUX acc, alu_cmd <= "100101", STORE_ALU
; SRA (HL)              16 cycles    ZNHC
;   tmp <= HL           (12 cycles left)
12e JMP 30f, RF_OMUX hl
;   tmp <= SRA(tmp)     (9 cycles left)
22e JMP 2a0, RF_OMUX hl, DMUX tmp, alu_cmd <= "100101", STORE_ALU

; SWP (B,C,D,E,H,L}     8 cycles    ZNHC
130 JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "100111", STORE_ALU
131 JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "100111", STORE_ALU
132 JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "100111", STORE_ALU
133 JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "100111", STORE_ALU
134 JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "100111", STORE_ALU
135 JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "100111", STORE_ALU
; SWP A                 8 cycles    ZNHC
137 JMP 339, RF_OMUX pc, DMUX acc, alu_cmd <= "100111", STORE_ALU
; SWP (HL)              16 cycles    ZNHC
;   tmp <= HL           (12 cycles left)
136 JMP 30f, RF_OMUX hl
;   tmp <= SWP(tmp)     (9 cycles left)
236 JMP 2a0, RF_OMUX hl, DMUX tmp, alu_cmd <= "100111", STORE_ALU

; SRL (B,C,D,E,H,L}     8 cycles    ZNHC
138 JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "100110", STORE_ALU
139 JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "100110", STORE_ALU
13a JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "100110", STORE_ALU
13b JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "100110", STORE_ALU
13c JMP 319, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "100110", STORE_ALU
13d JMP 329, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "100110", STORE_ALU
; SRL A                 8 cycles    ZNHC
13f JMP 339, RF_OMUX pc, DMUX acc, alu_cmd <= "100110", STORE_ALU
; SRL (HL)              16 cycles    ZNHC
;   tmp <= HL           (12 cycles left)
13e JMP 30f, RF_OMUX hl
;   tmp <= SRL(tmp)     (9 cycles left)
23e JMP 2a0, RF_OMUX hl, DMUX tmp, alu_cmd <= "100110", STORE_ALU

; BIT           8 cycles    ZNH-
310 JMP 3fe, RF_OMUX pc, FLAGS znh
; BIT b,B
140 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "101000", STORE_ALU
150 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "101010", STORE_ALU
160 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "101100", STORE_ALU
170 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "101110", STORE_ALU
148 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "101001", STORE_ALU
158 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "101011", STORE_ALU
168 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "101101", STORE_ALU
178 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "101111", STORE_ALU
; BIT b,C
141 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "101000", STORE_ALU
151 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "101010", STORE_ALU
161 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "101100", STORE_ALU
171 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "101110", STORE_ALU
149 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "101001", STORE_ALU
159 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "101011", STORE_ALU
169 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "101101", STORE_ALU
179 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "101111", STORE_ALU
; BIT b,D
142 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "101000", STORE_ALU
152 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "101010", STORE_ALU
162 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "101100", STORE_ALU
172 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "101110", STORE_ALU
14a JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "101001", STORE_ALU
15a JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "101011", STORE_ALU
16a JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "101101", STORE_ALU
17a JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "101111", STORE_ALU
; BIT b,E
143 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "101000", STORE_ALU
153 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "101010", STORE_ALU
163 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "101100", STORE_ALU
173 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "101110", STORE_ALU
14b JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "101001", STORE_ALU
15b JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "101011", STORE_ALU
16b JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "101101", STORE_ALU
17b JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "101111", STORE_ALU
; BIT b,H
144 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "101000", STORE_ALU
154 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "101010", STORE_ALU
164 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "101100", STORE_ALU
174 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "101110", STORE_ALU
14c JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "101001", STORE_ALU
15c JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "101011", STORE_ALU
16c JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "101101", STORE_ALU
17c JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "101111", STORE_ALU
; BIT b,L
145 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "101000", STORE_ALU
155 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "101010", STORE_ALU
165 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "101100", STORE_ALU
175 JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "101110", STORE_ALU
14d JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "101001", STORE_ALU
15d JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "101011", STORE_ALU
16d JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "101101", STORE_ALU
17d JMP 310, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "101111", STORE_ALU
; BIT b,A
147 JMP 310, RF_OMUX pc, DMUX acc, alu_cmd <= "101000", STORE_ALU
157 JMP 310, RF_OMUX pc, DMUX acc, alu_cmd <= "101010", STORE_ALU
167 JMP 310, RF_OMUX pc, DMUX acc, alu_cmd <= "101100", STORE_ALU
177 JMP 310, RF_OMUX pc, DMUX acc, alu_cmd <= "101110", STORE_ALU
14f JMP 310, RF_OMUX pc, DMUX acc, alu_cmd <= "101001", STORE_ALU
15f JMP 310, RF_OMUX pc, DMUX acc, alu_cmd <= "101011", STORE_ALU
16f JMP 310, RF_OMUX pc, DMUX acc, alu_cmd <= "101101", STORE_ALU
17f JMP 310, RF_OMUX pc, DMUX acc, alu_cmd <= "101111", STORE_ALU
; BIT (HL)              16 cycles    ZNH-
;   tmp <= HL           (12 cycles left)
146 JMP 30f, RF_OMUX hl
156 JMP 30f, RF_OMUX hl
166 JMP 30f, RF_OMUX hl
176 JMP 30f, RF_OMUX hl
14e JMP 30f, RF_OMUX hl
15e JMP 30f, RF_OMUX hl
16e JMP 30f, RF_OMUX hl
17e JMP 30f, RF_OMUX hl
;   flags <= BIT(tmp)       (9 cycles left)
246 JMP 2a1, RF_OMUX hl, DMUX tmp, alu_cmd <= "101000", STORE_ALU
256 JMP 2a1, RF_OMUX hl, DMUX tmp, alu_cmd <= "101010", STORE_ALU
266 JMP 2a1, RF_OMUX hl, DMUX tmp, alu_cmd <= "101100", STORE_ALU
276 JMP 2a1, RF_OMUX hl, DMUX tmp, alu_cmd <= "101110", STORE_ALU
24e JMP 2a1, RF_OMUX hl, DMUX tmp, alu_cmd <= "101001", STORE_ALU
25e JMP 2a1, RF_OMUX hl, DMUX tmp, alu_cmd <= "101011", STORE_ALU
26e JMP 2a1, RF_OMUX hl, DMUX tmp, alu_cmd <= "101101", STORE_ALU
27e JMP 2a1, RF_OMUX hl, DMUX tmp, alu_cmd <= "101111", STORE_ALU
2a1 JMP 3f9, FLAGS znh

; SET/RESET     8 cycles
25f JMP 3fe, RF_OMUX pc, DMUX alu, RF_IMUXSEL cmd[2:1], RF_CE hi
26f JMP 3fe, RF_OMUX pc, DMUX alu, RF_IMUXSEL cmd[2:1], RF_CE lo
27f JMP 3fe, RF_OMUX pc, DMUX alu, STORE_ACC
; SET b,B
180 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "111000", STORE_ALU
190 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "111010", STORE_ALU
1a0 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "111100", STORE_ALU
1b0 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "111110", STORE_ALU
188 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "111001", STORE_ALU
198 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "111011", STORE_ALU
1a8 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "111101", STORE_ALU
1b8 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "111111", STORE_ALU
; SET b,C
181 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "111000", STORE_ALU
191 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "111010", STORE_ALU
1a1 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "111100", STORE_ALU
1b1 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "111110", STORE_ALU
189 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "111001", STORE_ALU
199 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "111011", STORE_ALU
1a9 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "111101", STORE_ALU
1b9 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "111111", STORE_ALU
; SET b,D
182 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "111000", STORE_ALU
192 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "111010", STORE_ALU
1a2 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "111100", STORE_ALU
1b2 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "111110", STORE_ALU
18a JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "111001", STORE_ALU
19a JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "111011", STORE_ALU
1aa JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "111101", STORE_ALU
1ba JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "111111", STORE_ALU
; SET b,E
183 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "111000", STORE_ALU
193 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "111010", STORE_ALU
1a3 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "111100", STORE_ALU
1b3 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "111110", STORE_ALU
18b JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "111001", STORE_ALU
19b JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "111011", STORE_ALU
1ab JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "111101", STORE_ALU
1bb JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "111111", STORE_ALU
; SET b,H
184 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "111000", STORE_ALU
194 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "111010", STORE_ALU
1a4 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "111100", STORE_ALU
1b4 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "111110", STORE_ALU
18c JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "111001", STORE_ALU
19c JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "111011", STORE_ALU
1ac JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "111101", STORE_ALU
1bc JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "111111", STORE_ALU
; SET b,L
185 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "111000", STORE_ALU
195 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "111010", STORE_ALU
1a5 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "111100", STORE_ALU
1b5 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "111110", STORE_ALU
18d JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "111001", STORE_ALU
19d JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "111011", STORE_ALU
1ad JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "111101", STORE_ALU
1bd JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "111111", STORE_ALU
; SET b,A
187 JMP 27f, RF_OMUX pc, DMUX acc, alu_cmd <= "111000", STORE_ALU
197 JMP 27f, RF_OMUX pc, DMUX acc, alu_cmd <= "111010", STORE_ALU
1a7 JMP 27f, RF_OMUX pc, DMUX acc, alu_cmd <= "111100", STORE_ALU
1b7 JMP 27f, RF_OMUX pc, DMUX acc, alu_cmd <= "111110", STORE_ALU
18f JMP 27f, RF_OMUX pc, DMUX acc, alu_cmd <= "111001", STORE_ALU
19f JMP 27f, RF_OMUX pc, DMUX acc, alu_cmd <= "111011", STORE_ALU
1af JMP 27f, RF_OMUX pc, DMUX acc, alu_cmd <= "111101", STORE_ALU
1bf JMP 27f, RF_OMUX pc, DMUX acc, alu_cmd <= "111111", STORE_ALU
; SET (HL)              16 cycles
;   tmp <= HL           (12 cycles left)
186 JMP 30f, RF_OMUX hl
196 JMP 30f, RF_OMUX hl
1a6 JMP 30f, RF_OMUX hl
1b6 JMP 30f, RF_OMUX hl
18e JMP 30f, RF_OMUX hl
19e JMP 30f, RF_OMUX hl
1ae JMP 30f, RF_OMUX hl
1be JMP 30f, RF_OMUX hl
;   (HL) <= SET(tmp)    (9 cycles left)
286 JMP 2a2, RF_OMUX hl, DMUX tmp, alu_cmd <= "111000", STORE_ALU
296 JMP 2a2, RF_OMUX hl, DMUX tmp, alu_cmd <= "111010", STORE_ALU
2a6 JMP 2a2, RF_OMUX hl, DMUX tmp, alu_cmd <= "111100", STORE_ALU
2b6 JMP 2a2, RF_OMUX hl, DMUX tmp, alu_cmd <= "111110", STORE_ALU
28e JMP 2a2, RF_OMUX hl, DMUX tmp, alu_cmd <= "111001", STORE_ALU
29e JMP 2a2, RF_OMUX hl, DMUX tmp, alu_cmd <= "111011", STORE_ALU
2ae JMP 2a2, RF_OMUX hl, DMUX tmp, alu_cmd <= "111101", STORE_ALU
2be JMP 2a2, RF_OMUX hl, DMUX tmp, alu_cmd <= "111111", STORE_ALU
2a2 JMP 32f, RF_OMUX hl, DMUX alu, STORE_TMP
; RESET b,B
1c0 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "110000", STORE_ALU
1d0 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "110010", STORE_ALU
1e0 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "110100", STORE_ALU
1f0 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "110110", STORE_ALU
1c8 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "110001", STORE_ALU
1d8 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "110011", STORE_ALU
1e8 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "110101", STORE_ALU
1f8 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX b, alu_cmd <= "110111", STORE_ALU
; RESET b,C
1c1 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "110000", STORE_ALU
1d1 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "110010", STORE_ALU
1e1 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "110100", STORE_ALU
1f1 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "110110", STORE_ALU
1c9 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "110001", STORE_ALU
1d9 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "110011", STORE_ALU
1e9 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "110101", STORE_ALU
1f9 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX c, alu_cmd <= "110111", STORE_ALU
; RESET b,D
1c2 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "110000", STORE_ALU
1d2 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "110010", STORE_ALU
1e2 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "110100", STORE_ALU
1f2 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "110110", STORE_ALU
1ca JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "110001", STORE_ALU
1da JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "110011", STORE_ALU
1ea JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "110101", STORE_ALU
1fa JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX d, alu_cmd <= "110111", STORE_ALU
; RESET b,E
1c3 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "110000", STORE_ALU
1d3 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "110010", STORE_ALU
1e3 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "110100", STORE_ALU
1f3 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "110110", STORE_ALU
1cb JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "110001", STORE_ALU
1db JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "110011", STORE_ALU
1eb JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "110101", STORE_ALU
1fb JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX e, alu_cmd <= "110111", STORE_ALU
; RESET b,H
1c4 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "110000", STORE_ALU
1d4 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "110010", STORE_ALU
1e4 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "110100", STORE_ALU
1f4 JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "110110", STORE_ALU
1cc JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "110001", STORE_ALU
1dc JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "110011", STORE_ALU
1ec JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "110101", STORE_ALU
1fc JMP 25f, RF_OMUX pc, DMUX rf, RF_DMUX h, alu_cmd <= "110111", STORE_ALU
; RESET b,L
1c5 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "110000", STORE_ALU
1d5 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "110010", STORE_ALU
1e5 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "110100", STORE_ALU
1f5 JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "110110", STORE_ALU
1cd JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "110001", STORE_ALU
1dd JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "110011", STORE_ALU
1ed JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "110101", STORE_ALU
1fd JMP 26f, RF_OMUX pc, DMUX rf, RF_DMUX l, alu_cmd <= "110111", STORE_ALU
; RESET b,A
1c7 JMP 27f, RF_OMUX pc, DMUX acc, alu_cmd <= "110000", STORE_ALU
1d7 JMP 27f, RF_OMUX pc, DMUX acc, alu_cmd <= "110010", STORE_ALU
1e7 JMP 27f, RF_OMUX pc, DMUX acc, alu_cmd <= "110100", STORE_ALU
1f7 JMP 27f, RF_OMUX pc, DMUX acc, alu_cmd <= "110110", STORE_ALU
1cf JMP 27f, RF_OMUX pc, DMUX acc, alu_cmd <= "110001", STORE_ALU
1df JMP 27f, RF_OMUX pc, DMUX acc, alu_cmd <= "110011", STORE_ALU
1ef JMP 27f, RF_OMUX pc, DMUX acc, alu_cmd <= "110101", STORE_ALU
1ff JMP 27f, RF_OMUX pc, DMUX acc, alu_cmd <= "110111", STORE_ALU
; RESET (HL)            16 cycles
;   tmp <= HL           (12 cycles left)
1c6 JMP 30f, RF_OMUX hl
1d6 JMP 30f, RF_OMUX hl
1e6 JMP 30f, RF_OMUX hl
1f6 JMP 30f, RF_OMUX hl
1ce JMP 30f, RF_OMUX hl
1de JMP 30f, RF_OMUX hl
1ee JMP 30f, RF_OMUX hl
1fe JMP 30f, RF_OMUX hl
;   (HL) <= RESET(tmp)  (9 cycles left)
2c6 JMP 2a2, RF_OMUX hl, DMUX tmp, alu_cmd <= "111000", STORE_ALU
2d6 JMP 2a2, RF_OMUX hl, DMUX tmp, alu_cmd <= "111010", STORE_ALU
2e6 JMP 2a2, RF_OMUX hl, DMUX tmp, alu_cmd <= "111100", STORE_ALU
2f6 JMP 2a2, RF_OMUX hl, DMUX tmp, alu_cmd <= "111110", STORE_ALU
2ce JMP 2a2, RF_OMUX hl, DMUX tmp, alu_cmd <= "111001", STORE_ALU
2de JMP 2a2, RF_OMUX hl, DMUX tmp, alu_cmd <= "111011", STORE_ALU
2ee JMP 2a2, RF_OMUX hl, DMUX tmp, alu_cmd <= "111101", STORE_ALU
2fe JMP 2a2, RF_OMUX hl, DMUX tmp, alu_cmd <= "111111", STORE_ALU

; ***************************************************************************
; *     Subroutines                                                         *
; ***************************************************************************

3f0 JMP 3f1
3f1 JMP 3f2
3f2 JMP 3f3
3f3 JMP 3f4

3f4 JMP 3f5
3f5 JMP 3f6
3f6 JMP 3f7
3f7 JMP 3f8

3f8 JMP 3f9
3f9 JMP 3fa
3fa JMP 3fb
3fb JMP 3fc

; 4 cycles to fetch instruction
3fc JMP 3fd, RF_OMUX pc
3fd JMP 3fe, RF_OMUX pc
3fe JMP 3ff, RF_OMUX pc, STORE_CMD
3ff JCMD,    RF_OMUX pc, RF_IMUX pc, RF_AMUX inc, RF_CE
