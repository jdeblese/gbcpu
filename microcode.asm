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
007 next <= X"307", dmux <= "010", alu_cmd <= "100000", alu_ce <= '1', rf_omux <= "100";
017 next <= X"307", dmux <= "010", alu_cmd <= "100001", alu_ce <= '1', rf_omux <= "100";
307 next <= X"3fe", dmux <= "011", acc_ce <= '1',                      rf_omux <= "100", znhc <= "1111";

; RRCA, RRA     4 cycles    ZNHC
00f next <= X"307", dmux <= "010", alu_cmd <= "100010", alu_ce <= '1', rf_omux <= "100";
01f next <= X"307", dmux <= "010", alu_cmd <= "100011", alu_ce <= '1', rf_omux <= "100";

; DAA     4 cycles    Z-HC
027 next <= X"327", dmux <= "010", alu_cmd <= "011000", alu_ce <= '1', rf_omux <= "100";
327 next <= X"3fe", dmux <= "011", acc_ce <= '1',                      rf_omux <= "100", znhc <= "1011";

; CPL A         4 cycles    -NH-
02f next <= X"317", dmux <= "010", alu_cmd <= "010011", alu_ce <= '1', rf_omux <= "100";
317 next <= X"3fe", dmux <= "011", acc_ce <= '1',                      rf_omux <= "100", znhc <= "0110";

; SCF, CCF     4 cycles    -NHC
037 next <= X"337", dmux <= "010", alu_cmd <= "011010", alu_ce <= '1', rf_omux <= "100";
03f next <= X"337", dmux <= "010", alu_cmd <= "011011", alu_ce <= '1', rf_omux <= "100";
337 next <= X"3fe", dmux <= "011",                                     rf_omux <= "100", znhc <= "0111";

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

; ADD A,{B,C,D,E,H,L,A}             4 cycles    ZNHC
080 next <= X"380", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "000000", alu_ce <= '1', rf_omux <= "100";
081 next <= X"380", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "000000", alu_ce <= '1', rf_omux <= "100";
082 next <= X"380", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "000000", alu_ce <= '1', rf_omux <= "100";
083 next <= X"380", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "000000", alu_ce <= '1', rf_omux <= "100";
084 next <= X"380", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "000000", alu_ce <= '1', rf_omux <= "100";
085 next <= X"380", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "000000", alu_ce <= '1', rf_omux <= "100";
087 next <= X"380", dmux <= "010",                  alu_cmd <= "000000", alu_ce <= '1', rf_omux <= "100";
380 next <= X"3fe", dmux <= "011", acc_ce <= '1', znhc <= "1111",                       rf_omux <= "100";
; ADD A,(HL)                        8 cycles    ZNHC
086 next <= X"381", rf_omux <= "010";
381 next <= X"382", rf_omux <= "010";
382 next <= X"383", rf_omux <= "010", alu_cmd <= "000000", alu_ce <= '1';
383 next <= X"3fc", rf_omux <= "010", acc_ce <= '1', znhc <= "1111";

; ADC A,{B,C,D,E,H,L,A}             4 cycles    ZNHC
088 next <= X"380", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "000001", alu_ce <= '1', rf_omux <= "100";
089 next <= X"380", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "000001", alu_ce <= '1', rf_omux <= "100";
08a next <= X"380", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "000001", alu_ce <= '1', rf_omux <= "100";
08b next <= X"380", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "000001", alu_ce <= '1', rf_omux <= "100";
08c next <= X"380", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "000001", alu_ce <= '1', rf_omux <= "100";
08d next <= X"380", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "000001", alu_ce <= '1', rf_omux <= "100";
08f next <= X"380", dmux <= "010",                  alu_cmd <= "000001", alu_ce <= '1', rf_omux <= "100";
; ADC A,(HL)                        8 cycles    ZNHC
08e next <= X"384", rf_omux <= "010";
384 next <= X"385", rf_omux <= "010";
385 next <= X"383", rf_omux <= "010", alu_cmd <= "000001", alu_ce <= '1';

; SUB A,{B,C,D,E,H,L,A}             4 cycles    ZNHC
090 next <= X"380", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "000010", alu_ce <= '1', rf_omux <= "100";
091 next <= X"380", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "000010", alu_ce <= '1', rf_omux <= "100";
092 next <= X"380", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "000010", alu_ce <= '1', rf_omux <= "100";
093 next <= X"380", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "000010", alu_ce <= '1', rf_omux <= "100";
094 next <= X"380", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "000010", alu_ce <= '1', rf_omux <= "100";
095 next <= X"380", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "000010", alu_ce <= '1', rf_omux <= "100";
097 next <= X"380", dmux <= "010",                  alu_cmd <= "000010", alu_ce <= '1', rf_omux <= "100";
; SUB A,(HL)                        8 cycles    ZNHC
096 next <= X"386", rf_omux <= "010";
386 next <= X"387", rf_omux <= "010";
387 next <= X"383", rf_omux <= "010", alu_cmd <= "000010", alu_ce <= '1';

; SBC A,{B,C,D,E,H,L,A}             4 cycles    ZNHC
098 next <= X"380", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "000011", alu_ce <= '1', rf_omux <= "100";
099 next <= X"380", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "000011", alu_ce <= '1', rf_omux <= "100";
09a next <= X"380", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "000011", alu_ce <= '1', rf_omux <= "100";
09b next <= X"380", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "000011", alu_ce <= '1', rf_omux <= "100";
09c next <= X"380", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "000011", alu_ce <= '1', rf_omux <= "100";
09d next <= X"380", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "000011", alu_ce <= '1', rf_omux <= "100";
09f next <= X"380", dmux <= "010",                  alu_cmd <= "000011", alu_ce <= '1', rf_omux <= "100";
; SBC A,(HL)                        8 cycles    ZNHC
09e next <= X"388", rf_omux <= "010";
388 next <= X"389", rf_omux <= "010";
389 next <= X"383", rf_omux <= "010", alu_cmd <= "000011", alu_ce <= '1';

; AND A,{B,C,D,E,H,L,A}             4 cycles    ZNHC
0a0 next <= X"380", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "010000", alu_ce <= '1', rf_omux <= "100";
0a1 next <= X"380", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "010000", alu_ce <= '1', rf_omux <= "100";
0a2 next <= X"380", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "010000", alu_ce <= '1', rf_omux <= "100";
0a3 next <= X"380", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "010000", alu_ce <= '1', rf_omux <= "100";
0a4 next <= X"380", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "010000", alu_ce <= '1', rf_omux <= "100";
0a5 next <= X"380", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "010000", alu_ce <= '1', rf_omux <= "100";
0a7 next <= X"380", dmux <= "010",                  alu_cmd <= "010000", alu_ce <= '1', rf_omux <= "100";
; AND A,(HL)                        8 cycles    ZNHC
0a6 next <= X"38a", rf_omux <= "010";
38a next <= X"38b", rf_omux <= "010";
38b next <= X"383", rf_omux <= "010", alu_cmd <= "010000", alu_ce <= '1';

; XOR A,{B,C,D,E,H,L,A}             4 cycles    ZNHC
0a8 next <= X"380", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "010010", alu_ce <= '1', rf_omux <= "100";
0a9 next <= X"380", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "010010", alu_ce <= '1', rf_omux <= "100";
0aa next <= X"380", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "010010", alu_ce <= '1', rf_omux <= "100";
0ab next <= X"380", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "010010", alu_ce <= '1', rf_omux <= "100";
0ac next <= X"380", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "010010", alu_ce <= '1', rf_omux <= "100";
0ad next <= X"380", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "010010", alu_ce <= '1', rf_omux <= "100";
0af next <= X"380", dmux <= "010",                  alu_cmd <= "010010", alu_ce <= '1', rf_omux <= "100";
; XOR A,(HL)                        8 cycles    ZNHC
0ae next <= X"38c", rf_omux <= "010";
38c next <= X"38d", rf_omux <= "010";
38d next <= X"383", rf_omux <= "010", alu_cmd <= "010010", alu_ce <= '1';

; OR A,{B,C,D,E,H,L,A}              4 cycles    ZNHC
0b0 next <= X"380", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "010001", alu_ce <= '1', rf_omux <= "100";
0b1 next <= X"380", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "010001", alu_ce <= '1', rf_omux <= "100";
0b2 next <= X"380", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "010001", alu_ce <= '1', rf_omux <= "100";
0b3 next <= X"380", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "010001", alu_ce <= '1', rf_omux <= "100";
0b4 next <= X"380", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "010001", alu_ce <= '1', rf_omux <= "100";
0b5 next <= X"380", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "010001", alu_ce <= '1', rf_omux <= "100";
0b7 next <= X"380", dmux <= "010",                  alu_cmd <= "010001", alu_ce <= '1', rf_omux <= "100";
; OR A,(HL)                         8 cycles    ZNHC
0b6 next <= X"38e", rf_omux <= "010";
38e next <= X"38f", rf_omux <= "010";
38f next <= X"383", rf_omux <= "010", alu_cmd <= "010001", alu_ce <= '1';

; CP A,{B,C,D,E,H,L,A}              4 cycles    ZNHC
;   Only set flags, not ACC
0b8 next <= X"390", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "000110", alu_ce <= '1', rf_omux <= "100";
0b9 next <= X"390", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "000110", alu_ce <= '1', rf_omux <= "100";
0ba next <= X"390", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "000110", alu_ce <= '1', rf_omux <= "100";
0bb next <= X"390", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "000110", alu_ce <= '1', rf_omux <= "100";
0bc next <= X"390", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "000110", alu_ce <= '1', rf_omux <= "100";
0bd next <= X"390", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "000110", alu_ce <= '1', rf_omux <= "100";
0bf next <= X"390", dmux <= "010",                  alu_cmd <= "000110", alu_ce <= '1', rf_omux <= "100";
390 next <= X"3fe", dmux <= "011",                  znhc <= "1111",                     rf_omux <= "100";
; CP A,(HL)                         8 cycles    ZNHC
0be next <= X"391", rf_omux <= "010";
391 next <= X"392", rf_omux <= "010";
392 next <= X"393", rf_omux <= "010", alu_cmd <= "000110", alu_ce <= '1';
393 next <= X"3fc", rf_omux <= "010", znhc <= "1111";

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
261 JMP 262, RF_OMUX sp,                  RF_IMUX bc, RF_CE lo
262 JMP 263, RF_OMUX sp, RF_AMUX inc, RF_IMUX sp, RF_CE
;   B <= (SP++)
263 JMP 264, RF_OMUX sp
264 JMP 265, RF_OMUX sp
265 JMP 32c, RF_OMUX sp,                  RF_IMUX bc, RF_CE hi
32c JMP 3fc, RF_OMUX sp, RF_AMUX inc, RF_IMUX sp, RF_CE

; POP DE                            12 cycles
;   E <= (SP++)
0d1 JMP 268, RF_OMUX sp
268 JMP 269, RF_OMUX sp
269 JMP 26a, RF_OMUX sp,                  RF_IMUX de, RF_CE lo
26a JMP 26b, RF_OMUX sp, RF_AMUX inc, RF_IMUX sp, RF_CE
;   D <= (SP++)
26b JMP 26c, RF_OMUX sp
26c JMP 26d, RF_OMUX sp
26d JMP 23d, RF_OMUX sp,                  RF_IMUX de, RF_CE hi
23d JMP 3fc, RF_OMUX sp, RF_AMUX inc, RF_IMUX sp, RF_CE

; POP HL                            12 cycles
;   L <= (SP++)
0e1 JMP 270, RF_OMUX sp
270 JMP 271, RF_OMUX sp
271 JMP 272, RF_OMUX sp,                  RF_IMUX hl, RF_CE lo
272 JMP 273, RF_OMUX sp, RF_AMUX inc, RF_IMUX sp, RF_CE
;   H <= (SP++)
273 JMP 274, RF_OMUX sp
274 JMP 275, RF_OMUX sp
275 JMP 33c, RF_OMUX sp,                  RF_IMUX hl, RF_CE hi
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


; ADD A,n                           8 cycles
0c6 next <= X"281", rf_omux <= "100";
281 next <= X"282", rf_omux <= "100";
282 next <= X"280", rf_omux <= "100", alu_cmd <= "000000", alu_ce <= '1';
280 next <= X"3fc", rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11", dmux <= "011", acc_ce <= '1', znhc <= "1111";
; ADC A,n                           8 cycles
0ce next <= X"283", rf_omux <= "100";
283 next <= X"284", rf_omux <= "100";
284 next <= X"280", rf_omux <= "100", alu_cmd <= "000001", alu_ce <= '1';
; SUB A,n                           8 cycles
0d6 next <= X"285", rf_omux <= "100";
285 next <= X"347", rf_omux <= "100";
347 next <= X"280", rf_omux <= "100", alu_cmd <= "000010", alu_ce <= '1';
; SBC A,n                           8 cycles
0de next <= X"287", rf_omux <= "100";
287 next <= X"288", rf_omux <= "100";
288 next <= X"280", rf_omux <= "100", alu_cmd <= "000011", alu_ce <= '1';
; AND A,n                           8 cycles
0e6 next <= X"289", rf_omux <= "100";
289 next <= X"28a", rf_omux <= "100";
28a next <= X"280", rf_omux <= "100", alu_cmd <= "010000", alu_ce <= '1';
; XOR A,n                           8 cycles
0ee next <= X"28b", rf_omux <= "100";
28b next <= X"28c", rf_omux <= "100";
28c next <= X"280", rf_omux <= "100", alu_cmd <= "010010", alu_ce <= '1';
; OR A,n                            8 cycles
0f6 next <= X"28d", rf_omux <= "100";
28d next <= X"21d", rf_omux <= "100";
21d next <= X"280", rf_omux <= "100", alu_cmd <= "010001", alu_ce <= '1';
; CP A,n                            8 cycles
0fe next <= X"308", rf_omux <= "100";
308 next <= X"30d", rf_omux <= "100";
30d next <= X"28f", rf_omux <= "100", alu_cmd <= "000110", alu_ce <= '1';
28f next <= X"3fc", rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11", znhc <= "1111";


; JNZ nn        16/12 cycles

; JNZ/Z helper
;   Load (PC) into unq, PC++. Address should already be on bus for 1 cycle
3a0 next <= X"3a1", rf_omux <= "100";
3a1 next <= X"3a2", rf_omux <= "100", unq_ce <= '1';
3a2 next <= X"3a3", rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";
;   (PC) into tmp, PC++, and jump to "10" & CMD
3a3 next <= X"3a4", rf_omux <= "100";
3a4 next <= X"3a5", rf_omux <= "100";
3a5 next <= X"3a6", rf_omux <= "100", tmp_ce <= '1';
;   jump depending on zero flag
3a6 next <= X"200", rf_omux <= "100", cmdjmp <= '1', fljmp <= '1', flsel <= '1', rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";

; JNZ/Z final set
3a7 next <= X"3fa", dmux <= "101", rf_imux <= "100", rf_ce <= "01";

; JNZ nn
;   read nn
0c2 next <= X"3a0", rf_omux <= "100";
;   flag is not set, so put n on the databus and update PC (6 cycles left)
2c2 next <= X"3a7", dmux <= "100", rf_imux <= "100", rf_ce <= "10";
;   flag is set, so move on to fetch (3 cycles left)
3c2 next <= X"3fd", rf_omux <= "100";

; JZ nn
;   read nn
0ca next <= X"3a0", rf_omux <= "100";
;   flag is not set, so move on to fetch (3 cycles left)
2ca next <= X"3fd", rf_omux <= "100";
;   flag is set, so put n on the databus and update PC (6 cycles left)
3ca next <= X"3a7", dmux <= "100", rf_imux <= "100", rf_ce <= "10";

; JP nn
;   read nn
0c3 next <= X"3a0", rf_omux <= "100";
;   flag doesn't matter - put n on the databus and update PC (6 cycles left)
2c3 next <= X"3a7", dmux <= "100", rf_imux <= "100", rf_ce <= "10";
3c3 next <= X"3a7", dmux <= "100", rf_imux <= "100", rf_ce <= "10";


; JNC nn        16/12 cycles

; JNC/C helper
;   Load (PC) into unq, PC++. Address should already be on bus for 1 cycle
3b0 next <= X"3b1", rf_omux <= "100";
3b1 next <= X"3b2", rf_omux <= "100", unq_ce <= '1';
3b2 next <= X"3b3", rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";
;   (PC) into tmp, PC++, and jump to "10" & CMD
3b3 next <= X"3b4", rf_omux <= "100";
3b4 next <= X"3b5", rf_omux <= "100";
3b5 next <= X"3b6", rf_omux <= "100", tmp_ce <= '1';
;   jump depending on carry flag
3b6 next <= X"200", rf_omux <= "100", cmdjmp <= '1', fljmp <= '1', flsel <= '0', rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";

; JC/NC final set (TODO identical to 3a7, neccessary?)
3b7 next <= X"3fa", dmux <= "101", rf_imux <= "100", rf_ce <= "01";

; JNC nn
;   read nn
0d2 next <= X"3b0", rf_omux <= "100";
;   flag is not set, so put n on the databus and update PC (6 cycles left)
2d2 next <= X"3b7", dmux <= "100", rf_imux <= "100", rf_ce <= "10";
;   flag is set, so move on to fetch (3 cycles left)
3d2 next <= X"3fd", rf_omux <= "100";

; JC nn
;   read nn
0da next <= X"3b0", rf_omux <= "100";
;   flag is not set, so move on to fetch (3 cycles left)
2da next <= X"3fd", rf_omux <= "100";
;   flag is set, so put n on the databus and update PC (6 cycles left)
3da next <= X"3b7", dmux <= "100", rf_imux <= "100", rf_ce <= "10";


; CALL helper
;   (SP--) <= msB(PC)       (15 cycles left)
207 next <= X"217", rf_dmux <= X"8", dmux <= "001", rf_omux <= "011";
217 next <= X"227", rf_dmux <= X"8", dmux <= "001", rf_omux <= "011";
227 next <= X"237", rf_dmux <= X"8", dmux <= "001", rf_omux <= "011", wr_en <= '1';
237 next <= X"209", rf_dmux <= X"8", dmux <= "001", rf_omux <= "011", wr_en <= '1', rf_amux <= "10", rf_imux <= "011", rf_ce <= "11";
;   (SP) <= lsB(PC)
209 next <= X"219", rf_dmux <= X"9", dmux <= "001", rf_omux <= "011";
219 next <= X"229", rf_dmux <= X"9", dmux <= "001", rf_omux <= "011";
229 next <= X"239", rf_dmux <= X"9", dmux <= "001", rf_omux <= "011", wr_en <= '1';
239 next <= X"321", rf_dmux <= X"9", dmux <= "001", rf_omux <= "011", wr_en <= '1';
;   Now set PC <= nn (in tmp and unq)       (7 cycles left)
321 next <= X"331", dmux <= "100", rf_imux <= "100", rf_ce <= "10";
331 next <= X"3fb", dmux <= "101", rf_imux <= "100", rf_ce <= "01";

; CALL nn                   24 cycles
;   read nn, returning on zero flag
0cd next <= X"3a0", rf_omux <= "100";
;   flag doesn't matter     (16 cycles left)
;   SP--
2cd next <= X"207", rf_omux <= "011", rf_amux <= "10", rf_imux <= "011", rf_ce <= "11";
3cd next <= X"207", rf_omux <= "011", rf_amux <= "10", rf_imux <= "011", rf_ce <= "11";

; CALLNZ nn                 24/12 cycles
;   read nn, returning on zero flag
0c4 next <= X"3a0", rf_omux <= "100";
;   flag is not set, so SP-- and push PC (16 cycles left)
2c4 next <= X"207", rf_omux <= "011", rf_amux <= "10", rf_imux <= "011", rf_ce <= "11";
;   flag is set, so move on to fetch (4 cycles left)
3c4 next <= X"3fd", rf_omux <= "100";

; CALLZ nn                  24 cycles
;   read nn, returning on zero flag
0cc next <= X"3a0", rf_omux <= "100";
;   flag is not set, so move on to fetch (4 cycles left)
2cc next <= X"3fd", rf_omux <= "100";
;   flag is set, so SP-- and push PC (16 cycles left)
3cc next <= X"207", rf_omux <= "011", rf_amux <= "10", rf_imux <= "011", rf_ce <= "11";

; CALLNC nn                 24/12 cycles
;   read nn, returning on carry flag
0d4 next <= X"3b0", rf_omux <= "100";
;   flag is not set, so SP-- and push PC (16 cycles left)
2d4 next <= X"207", rf_omux <= "011", rf_amux <= "10", rf_imux <= "011", rf_ce <= "11";
;   flag is set, so move on to fetch (4 cycles left)
3d4 next <= X"3fd", rf_omux <= "100";

; CALLC nn                  24 cycles
;   read nn, returning on carry flag
0dc next <= X"3b0", rf_omux <= "100";
;   flag is not set, so move on to fetch (4 cycles left)
2dc next <= X"3fd", rf_omux <= "100";
;   flag is set, so SP-- and push PC (16 cycles left)
3dc next <= X"207", rf_omux <= "011", rf_amux <= "10", rf_imux <= "011", rf_ce <= "11";


; RST                   16 cycles
;   TODO 16 or 32 cycles?

; helper
;   (SP--) <= msB(PC)       (14 cycles left)
3a8 next <= X"3a9", rf_dmux <= X"8", dmux <= "001", rf_omux <= "011";
3a9 next <= X"3aa", rf_dmux <= X"8", dmux <= "001", rf_omux <= "011";
3aa next <= X"3ab", rf_dmux <= X"8", dmux <= "001", rf_omux <= "011", wr_en <= '1';
3ab next <= X"3ac", rf_dmux <= X"8", dmux <= "001", rf_omux <= "011", wr_en <= '1', rf_amux <= "10", rf_imux <= "011", rf_ce <= "11";
;   (SP) <= lsB(PC)
3ac next <= X"3ad", rf_dmux <= X"9", dmux <= "001", rf_omux <= "011";
3ad next <= X"3ae", rf_dmux <= X"9", dmux <= "001", rf_omux <= "011";
3ae next <= X"3af", rf_dmux <= X"9", dmux <= "001", rf_omux <= "011", wr_en <= '1';
3af next <= X"39e", rf_dmux <= X"9", dmux <= "001", rf_omux <= "011", wr_en <= '1';
;   Now set PC <= nn (in tmp and unq)       (6 cycles left)
39e next <= X"39f", dmux <= "100", rf_imux <= "100", rf_ce <= "10";
39f next <= X"3fc", dmux <= "101", rf_imux <= "100", rf_ce <= "01";

; RST 00
; 00h in tmp and 00h in unq
0c7 next <= X"2c7", dmux <= "110", alu_cmd <= "000000", tmp_ce <= '1';
2c7 next <= X"3a8", dmux <= "110", alu_cmd <= "000000", unq_ce <= '1';

; RST 08
; 00h in tmp and 08h in unq
0cf next <= X"2cf", dmux <= "110", alu_cmd <= "000000", tmp_ce <= '1';
2cf next <= X"3a8", dmux <= "110", alu_cmd <= "001000", unq_ce <= '1';

; RST 10
; 00h in tmp and 10h in unq
0d7 next <= X"2d7", dmux <= "110", alu_cmd <= "000000", tmp_ce <= '1';
2d7 next <= X"3a8", dmux <= "110", alu_cmd <= "010000", unq_ce <= '1';

; RST 18
; 00h in tmp and 18h in unq
0df next <= X"2df", dmux <= "110", alu_cmd <= "000000", tmp_ce <= '1';
2df next <= X"3a8", dmux <= "110", alu_cmd <= "011000", unq_ce <= '1';

; RST 20
; 00h in tmp and 20h in unq
0e7 next <= X"2e7", dmux <= "110", alu_cmd <= "000000", tmp_ce <= '1';
2e7 next <= X"3a8", dmux <= "110", alu_cmd <= "100000", unq_ce <= '1';

; RST 28
; 00h in tmp and 28h in unq
0ef next <= X"2ef", dmux <= "110", alu_cmd <= "000000", tmp_ce <= '1';
2ef next <= X"3a8", dmux <= "110", alu_cmd <= "101000", unq_ce <= '1';

; RST 30
; 00h in tmp and 30h in unq
0f7 next <= X"2f7", dmux <= "110", alu_cmd <= "000000", tmp_ce <= '1';
2f7 next <= X"3a8", dmux <= "110", alu_cmd <= "110000", unq_ce <= '1';

; RST 38
; 00h in tmp and 38h in unq
0ff next <= X"2ff", dmux <= "110", alu_cmd <= "000000", tmp_ce <= '1';
2ff next <= X"3a8", dmux <= "110", alu_cmd <= "111000", unq_ce <= '1';


; RET helper
;   delay line
39b next <= X"39c";
39c next <= X"39d";
39d next <= X"394", rf_omux <= "011";
;   C <= (SP++)
394 next <= X"395", rf_omux <= "011";
395 next <= X"396", rf_omux <= "011",                  rf_imux <= "100", rf_ce <= "01";
396 next <= X"397", rf_omux <= "011", rf_amux <= "11", rf_imux <= "011", rf_ce <= "11";
;   P <= (SP++)
397 next <= X"398", rf_omux <= "011";
398 next <= X"399", rf_omux <= "011";
399 next <= X"39a", rf_omux <= "011",                  rf_imux <= "100", rf_ce <= "10";
39a next <= X"3f8", rf_omux <= "011", rf_amux <= "11", rf_imux <= "011", rf_ce <= "11";

; RET           16 cycles
0c9 next <= X"394", rf_omux <= "011";

; RETNZ         20/8 cycles
0c8 next <= X"200", cmdjmp <= '1', fljmp <= '1', flsel <= '1';
;   flag is not set, so pop into PC (19 cycles left)
2c8 next <= X"39b";
;   flag is set, so move on to fetch (7 cycles left)
3c8 next <= X"3fa";

; RETZ          20/8 cycles
0c0 next <= X"200", cmdjmp <= '1', fljmp <= '1', flsel <= '1';
;   flag is not set, so move on to fetch (7 cycles left)
2c0 next <= X"3fa";
;   flag is set, so pop into PC (19 cycles left)
3c0 next <= X"39b";

; RETNC         20/8 cycles
0d8 next <= X"200", cmdjmp <= '1', fljmp <= '1', flsel <= '0';
;   flag is not set, so pop into PC (19 cycles left)
2d8 next <= X"39b";
;   flag is set, so move on to fetch (7 cycles left)
3d8 next <= X"3fa";

; RETC          20/8 cycles
0d0 next <= X"200", cmdjmp <= '1', fljmp <= '1', flsel <= '0';
;   flag is not set, so move on to fetch (7 cycles left)
2d0 next <= X"3fa";
;   flag is set, so pop into PC (19 cycles left)
3d0 next <= X"39b";


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
0cb next <= X"2cb", rf_omux <= "100";
2cb next <= X"2db", rf_omux <= "100";
2db next <= X"2eb", rf_omux <= "100", cmd_ce <= '1';
2eb next <= X"100", rf_omux <= "100", cmdjmp <= '1', rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";

; CB helper
;   Return values to register, including flags
319 next <= X"3fe", rf_omux <= "100", dmux <= "011", rf_imuxsel <= "10", rf_ce <= "10", znhc <= "1111";
329 next <= X"3fe", rf_omux <= "100", dmux <= "011", rf_imuxsel <= "10", rf_ce <= "01", znhc <= "1111";
339 next <= X"3fe", rf_omux <= "100", dmux <= "011", acc_ce <= '1',                     znhc <= "1111";

; CB (HL) helper: tmp <= (HL), return to 200 + CMD
30f next <= X"31f", rf_omux <= "010";
31f next <= X"200", rf_omux <= "010", tmp_ce <= '1', cmdjmp <= '1';

; CB (HL) helper: (HL) <= tmp   (7 cycles remaining)
32f next <= X"33f", rf_omux <= "010", dmux <= "100";
33f next <= X"34f", rf_omux <= "010", dmux <= "100", wr_en <= '1';
34f next <= X"3fc", rf_omux <= "010", dmux <= "100", wr_en <= '1';

; RLC (B,C,D,E,H,L}     8 cycles    ZNHC
100 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "100000", alu_ce <= '1';
101 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "100000", alu_ce <= '1';
102 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "100000", alu_ce <= '1';
103 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "100000", alu_ce <= '1';
104 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "100000", alu_ce <= '1';
105 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "100000", alu_ce <= '1';
; RLC A                 8 cycles    ZNHC
107 next <= X"339", rf_omux <= "100", dmux <= "010",                  alu_cmd <= "100000", alu_ce <= '1';
; RLC (HL)              16 cycles    ZNHC
;   tmp <= HL           (12 cycles left)
106 next <= X"30f", rf_omux <= "010";
;   tmp <= RLC(tmp)     (9 cycles left)
206 next <= X"2a0", rf_omux <= "010", dmux <= "100", alu_cmd <= "100000", alu_ce <= '1';
2a0 next <= X"32f", rf_omux <= "010", dmux <= "011", tmp_ce <= '1', znhc <= "1111";

; RRC (B,C,D,E,H,L}     8 cycles    ZNHC
108 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "100010", alu_ce <= '1';
109 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "100010", alu_ce <= '1';
10a next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "100010", alu_ce <= '1';
10b next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "100010", alu_ce <= '1';
10c next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "100010", alu_ce <= '1';
10d next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "100010", alu_ce <= '1';
; RRC A                 8 cycles    ZNHC
10f next <= X"339", rf_omux <= "100", dmux <= "010",                  alu_cmd <= "100010", alu_ce <= '1';
; RRC (HL)              16 cycles    ZNHC
;   tmp <= HL           (12 cycles left)
10e next <= X"30f", rf_omux <= "010";
;   tmp <= RRC(tmp)     (9 cycles left)
20e next <= X"2a0", rf_omux <= "010", dmux <= "100", alu_cmd <= "100010", alu_ce <= '1';

; RL (B,C,D,E,H,L}     8 cycles    ZNHC
110 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "100001", alu_ce <= '1';
111 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "100001", alu_ce <= '1';
112 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "100001", alu_ce <= '1';
113 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "100001", alu_ce <= '1';
114 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "100001", alu_ce <= '1';
115 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "100001", alu_ce <= '1';
; RL A                 8 cycles    ZNHC
117 next <= X"339", rf_omux <= "100", dmux <= "010",                  alu_cmd <= "100001", alu_ce <= '1';
; RL (HL)               16 cycles    ZNHC
;   tmp <= HL           (12 cycles left)
116 next <= X"30f", rf_omux <= "010";
;   tmp <= RL(tmp)      (9 cycles left)
216 next <= X"2a0", rf_omux <= "010", dmux <= "100", alu_cmd <= "100001", alu_ce <= '1';

; RR (B,C,D,E,H,L}     8 cycles    ZNHC
118 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "100011", alu_ce <= '1';
119 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "100011", alu_ce <= '1';
11a next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "100011", alu_ce <= '1';
11b next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "100011", alu_ce <= '1';
11c next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "100011", alu_ce <= '1';
11d next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "100011", alu_ce <= '1';
; RR A                 8 cycles    ZNHC
11f next <= X"339", rf_omux <= "100", dmux <= "010",                  alu_cmd <= "100011", alu_ce <= '1';
; RR (HL)               16 cycles    ZNHC
;   tmp <= HL           (12 cycles left)
11e next <= X"30f", rf_omux <= "010";
;   tmp <= RR(tmp)      (9 cycles left)
21e next <= X"2a0", rf_omux <= "010", dmux <= "100", alu_cmd <= "100011", alu_ce <= '1';

; SLA (B,C,D,E,H,L}     8 cycles    ZNHC
120 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "100100", alu_ce <= '1';
121 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "100100", alu_ce <= '1';
122 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "100100", alu_ce <= '1';
123 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "100100", alu_ce <= '1';
124 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "100100", alu_ce <= '1';
125 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "100100", alu_ce <= '1';
; SLA A                 8 cycles    ZNHC
127 next <= X"339", rf_omux <= "100", dmux <= "010",                  alu_cmd <= "100100", alu_ce <= '1';
; SLA (HL)              16 cycles    ZNHC
;   tmp <= HL           (12 cycles left)
126 next <= X"30f", rf_omux <= "010";
;   tmp <= SLA(tmp)     (9 cycles left)
226 next <= X"2a0", rf_omux <= "010", dmux <= "100", alu_cmd <= "100100", alu_ce <= '1';

; SRA (B,C,D,E,H,L}     8 cycles    ZNHC
128 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "100101", alu_ce <= '1';
129 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "100101", alu_ce <= '1';
12a next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "100101", alu_ce <= '1';
12b next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "100101", alu_ce <= '1';
12c next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "100101", alu_ce <= '1';
12d next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "100101", alu_ce <= '1';
; SRA A                 8 cycles    ZNHC
12f next <= X"339", rf_omux <= "100", dmux <= "010",                  alu_cmd <= "100101", alu_ce <= '1';
; SRA (HL)              16 cycles    ZNHC
;   tmp <= HL           (12 cycles left)
12e next <= X"30f", rf_omux <= "010";
;   tmp <= SRA(tmp)     (9 cycles left)
22e next <= X"2a0", rf_omux <= "010", dmux <= "100", alu_cmd <= "100101", alu_ce <= '1';

; SWP (B,C,D,E,H,L}     8 cycles    ZNHC
130 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "100111", alu_ce <= '1';
131 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "100111", alu_ce <= '1';
132 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "100111", alu_ce <= '1';
133 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "100111", alu_ce <= '1';
134 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "100111", alu_ce <= '1';
135 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "100111", alu_ce <= '1';
; SWP A                 8 cycles    ZNHC
137 next <= X"339", rf_omux <= "100", dmux <= "010",                  alu_cmd <= "100111", alu_ce <= '1';
; SWP (HL)              16 cycles    ZNHC
;   tmp <= HL           (12 cycles left)
136 next <= X"30f", rf_omux <= "010";
;   tmp <= SWP(tmp)     (9 cycles left)
236 next <= X"2a0", rf_omux <= "010", dmux <= "100", alu_cmd <= "100111", alu_ce <= '1';

; SRL (B,C,D,E,H,L}     8 cycles    ZNHC
138 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "100110", alu_ce <= '1';
139 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "100110", alu_ce <= '1';
13a next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "100110", alu_ce <= '1';
13b next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "100110", alu_ce <= '1';
13c next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "100110", alu_ce <= '1';
13d next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "100110", alu_ce <= '1';
; SRL A                 8 cycles    ZNHC
13f next <= X"339", rf_omux <= "100", dmux <= "010",                  alu_cmd <= "100110", alu_ce <= '1';
; SRL (HL)              16 cycles    ZNHC
;   tmp <= HL           (12 cycles left)
13e next <= X"30f", rf_omux <= "010";
;   tmp <= SRL(tmp)     (9 cycles left)
23e next <= X"2a0", rf_omux <= "010", dmux <= "100", alu_cmd <= "100110", alu_ce <= '1';

; BIT           8 cycles    ZNH-
310 next <= X"3fe", rf_omux <= "100", znhc <= "1110";
; BIT b,B
140 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "101000", alu_ce <= '1';
150 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "101010", alu_ce <= '1';
160 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "101100", alu_ce <= '1';
170 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "101110", alu_ce <= '1';
148 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "101001", alu_ce <= '1';
158 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "101011", alu_ce <= '1';
168 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "101101", alu_ce <= '1';
178 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "101111", alu_ce <= '1';
; BIT b,C
141 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "101000", alu_ce <= '1';
151 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "101010", alu_ce <= '1';
161 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "101100", alu_ce <= '1';
171 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "101110", alu_ce <= '1';
149 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "101001", alu_ce <= '1';
159 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "101011", alu_ce <= '1';
169 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "101101", alu_ce <= '1';
179 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "101111", alu_ce <= '1';
; BIT b,D
142 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "101000", alu_ce <= '1';
152 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "101010", alu_ce <= '1';
162 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "101100", alu_ce <= '1';
172 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "101110", alu_ce <= '1';
14a next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "101001", alu_ce <= '1';
15a next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "101011", alu_ce <= '1';
16a next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "101101", alu_ce <= '1';
17a next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "101111", alu_ce <= '1';
; BIT b,E
143 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "101000", alu_ce <= '1';
153 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "101010", alu_ce <= '1';
163 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "101100", alu_ce <= '1';
173 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "101110", alu_ce <= '1';
14b next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "101001", alu_ce <= '1';
15b next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "101011", alu_ce <= '1';
16b next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "101101", alu_ce <= '1';
17b next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "101111", alu_ce <= '1';
; BIT b,H
144 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "101000", alu_ce <= '1';
154 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "101010", alu_ce <= '1';
164 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "101100", alu_ce <= '1';
174 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "101110", alu_ce <= '1';
14c next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "101001", alu_ce <= '1';
15c next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "101011", alu_ce <= '1';
16c next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "101101", alu_ce <= '1';
17c next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "101111", alu_ce <= '1';
; BIT b,L
145 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "101000", alu_ce <= '1';
155 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "101010", alu_ce <= '1';
165 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "101100", alu_ce <= '1';
175 next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "101110", alu_ce <= '1';
14d next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "101001", alu_ce <= '1';
15d next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "101011", alu_ce <= '1';
16d next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "101101", alu_ce <= '1';
17d next <= X"310", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "101111", alu_ce <= '1';
; BIT b,A
147 next <= X"310", rf_omux <= "100", dmux <= "010", alu_cmd <= "101000", alu_ce <= '1';
157 next <= X"310", rf_omux <= "100", dmux <= "010", alu_cmd <= "101010", alu_ce <= '1';
167 next <= X"310", rf_omux <= "100", dmux <= "010", alu_cmd <= "101100", alu_ce <= '1';
177 next <= X"310", rf_omux <= "100", dmux <= "010", alu_cmd <= "101110", alu_ce <= '1';
14f next <= X"310", rf_omux <= "100", dmux <= "010", alu_cmd <= "101001", alu_ce <= '1';
15f next <= X"310", rf_omux <= "100", dmux <= "010", alu_cmd <= "101011", alu_ce <= '1';
16f next <= X"310", rf_omux <= "100", dmux <= "010", alu_cmd <= "101101", alu_ce <= '1';
17f next <= X"310", rf_omux <= "100", dmux <= "010", alu_cmd <= "101111", alu_ce <= '1';
; BIT (HL)              16 cycles    ZNH-
;   tmp <= HL           (12 cycles left)
146 next <= X"30f", rf_omux <= "010";
156 next <= X"30f", rf_omux <= "010";
166 next <= X"30f", rf_omux <= "010";
176 next <= X"30f", rf_omux <= "010";
14e next <= X"30f", rf_omux <= "010";
15e next <= X"30f", rf_omux <= "010";
16e next <= X"30f", rf_omux <= "010";
17e next <= X"30f", rf_omux <= "010";
;   flags <= BIT(tmp)       (9 cycles left)
246 next <= X"2a1", rf_omux <= "010", dmux <= "100", alu_cmd <= "101000", alu_ce <= '1';
256 next <= X"2a1", rf_omux <= "010", dmux <= "100", alu_cmd <= "101010", alu_ce <= '1';
266 next <= X"2a1", rf_omux <= "010", dmux <= "100", alu_cmd <= "101100", alu_ce <= '1';
276 next <= X"2a1", rf_omux <= "010", dmux <= "100", alu_cmd <= "101110", alu_ce <= '1';
24e next <= X"2a1", rf_omux <= "010", dmux <= "100", alu_cmd <= "101001", alu_ce <= '1';
25e next <= X"2a1", rf_omux <= "010", dmux <= "100", alu_cmd <= "101011", alu_ce <= '1';
26e next <= X"2a1", rf_omux <= "010", dmux <= "100", alu_cmd <= "101101", alu_ce <= '1';
27e next <= X"2a1", rf_omux <= "010", dmux <= "100", alu_cmd <= "101111", alu_ce <= '1';
2a1 next <= X"3f9", znhc <= "1110";

; SET/RESET     8 cycles
25f next <= X"3fe", rf_omux <= "100", dmux <= "011", rf_imuxsel <= "10", rf_ce <= "10";
26f next <= X"3fe", rf_omux <= "100", dmux <= "011", rf_imuxsel <= "10", rf_ce <= "01";
27f next <= X"3fe", rf_omux <= "100", dmux <= "011", acc_ce <= '1';
; SET b,B
180 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "111000", alu_ce <= '1';
190 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "111010", alu_ce <= '1';
1a0 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "111100", alu_ce <= '1';
1b0 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "111110", alu_ce <= '1';
188 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "111001", alu_ce <= '1';
198 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "111011", alu_ce <= '1';
1a8 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "111101", alu_ce <= '1';
1b8 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "111111", alu_ce <= '1';
; SET b,C
181 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "111000", alu_ce <= '1';
191 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "111010", alu_ce <= '1';
1a1 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "111100", alu_ce <= '1';
1b1 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "111110", alu_ce <= '1';
189 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "111001", alu_ce <= '1';
199 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "111011", alu_ce <= '1';
1a9 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "111101", alu_ce <= '1';
1b9 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "111111", alu_ce <= '1';
; SET b,D
182 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "111000", alu_ce <= '1';
192 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "111010", alu_ce <= '1';
1a2 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "111100", alu_ce <= '1';
1b2 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "111110", alu_ce <= '1';
18a next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "111001", alu_ce <= '1';
19a next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "111011", alu_ce <= '1';
1aa next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "111101", alu_ce <= '1';
1ba next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "111111", alu_ce <= '1';
; SET b,E
183 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "111000", alu_ce <= '1';
193 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "111010", alu_ce <= '1';
1a3 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "111100", alu_ce <= '1';
1b3 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "111110", alu_ce <= '1';
18b next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "111001", alu_ce <= '1';
19b next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "111011", alu_ce <= '1';
1ab next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "111101", alu_ce <= '1';
1bb next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "111111", alu_ce <= '1';
; SET b,H
184 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "111000", alu_ce <= '1';
194 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "111010", alu_ce <= '1';
1a4 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "111100", alu_ce <= '1';
1b4 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "111110", alu_ce <= '1';
18c next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "111001", alu_ce <= '1';
19c next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "111011", alu_ce <= '1';
1ac next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "111101", alu_ce <= '1';
1bc next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "111111", alu_ce <= '1';
; SET b,L
185 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "111000", alu_ce <= '1';
195 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "111010", alu_ce <= '1';
1a5 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "111100", alu_ce <= '1';
1b5 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "111110", alu_ce <= '1';
18d next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "111001", alu_ce <= '1';
19d next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "111011", alu_ce <= '1';
1ad next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "111101", alu_ce <= '1';
1bd next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "111111", alu_ce <= '1';
; SET b,A
187 next <= X"27f", rf_omux <= "100", dmux <= "010", alu_cmd <= "111000", alu_ce <= '1';
197 next <= X"27f", rf_omux <= "100", dmux <= "010", alu_cmd <= "111010", alu_ce <= '1';
1a7 next <= X"27f", rf_omux <= "100", dmux <= "010", alu_cmd <= "111100", alu_ce <= '1';
1b7 next <= X"27f", rf_omux <= "100", dmux <= "010", alu_cmd <= "111110", alu_ce <= '1';
18f next <= X"27f", rf_omux <= "100", dmux <= "010", alu_cmd <= "111001", alu_ce <= '1';
19f next <= X"27f", rf_omux <= "100", dmux <= "010", alu_cmd <= "111011", alu_ce <= '1';
1af next <= X"27f", rf_omux <= "100", dmux <= "010", alu_cmd <= "111101", alu_ce <= '1';
1bf next <= X"27f", rf_omux <= "100", dmux <= "010", alu_cmd <= "111111", alu_ce <= '1';
; SET (HL)              16 cycles
;   tmp <= HL           (12 cycles left)
186 next <= X"30f", rf_omux <= "010";
196 next <= X"30f", rf_omux <= "010";
1a6 next <= X"30f", rf_omux <= "010";
1b6 next <= X"30f", rf_omux <= "010";
18e next <= X"30f", rf_omux <= "010";
19e next <= X"30f", rf_omux <= "010";
1ae next <= X"30f", rf_omux <= "010";
1be next <= X"30f", rf_omux <= "010";
;   (HL) <= SET(tmp)    (9 cycles left)
286 next <= X"2a2", rf_omux <= "010", dmux <= "100", alu_cmd <= "111000", alu_ce <= '1';
296 next <= X"2a2", rf_omux <= "010", dmux <= "100", alu_cmd <= "111010", alu_ce <= '1';
2a6 next <= X"2a2", rf_omux <= "010", dmux <= "100", alu_cmd <= "111100", alu_ce <= '1';
2b6 next <= X"2a2", rf_omux <= "010", dmux <= "100", alu_cmd <= "111110", alu_ce <= '1';
28e next <= X"2a2", rf_omux <= "010", dmux <= "100", alu_cmd <= "111001", alu_ce <= '1';
29e next <= X"2a2", rf_omux <= "010", dmux <= "100", alu_cmd <= "111011", alu_ce <= '1';
2ae next <= X"2a2", rf_omux <= "010", dmux <= "100", alu_cmd <= "111101", alu_ce <= '1';
2be next <= X"2a2", rf_omux <= "010", dmux <= "100", alu_cmd <= "111111", alu_ce <= '1';
2a2 next <= X"32f", rf_omux <= "010", dmux <= "011", tmp_ce <= '1';
; RESET b,B
1c0 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "110000", alu_ce <= '1';
1d0 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "110010", alu_ce <= '1';
1e0 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "110100", alu_ce <= '1';
1f0 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "110110", alu_ce <= '1';
1c8 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "110001", alu_ce <= '1';
1d8 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "110011", alu_ce <= '1';
1e8 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "110101", alu_ce <= '1';
1f8 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "110111", alu_ce <= '1';
; RESET b,C
1c1 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "110000", alu_ce <= '1';
1d1 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "110010", alu_ce <= '1';
1e1 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "110100", alu_ce <= '1';
1f1 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "110110", alu_ce <= '1';
1c9 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "110001", alu_ce <= '1';
1d9 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "110011", alu_ce <= '1';
1e9 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "110101", alu_ce <= '1';
1f9 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "110111", alu_ce <= '1';
; RESET b,D
1c2 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "110000", alu_ce <= '1';
1d2 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "110010", alu_ce <= '1';
1e2 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "110100", alu_ce <= '1';
1f2 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "110110", alu_ce <= '1';
1ca next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "110001", alu_ce <= '1';
1da next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "110011", alu_ce <= '1';
1ea next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "110101", alu_ce <= '1';
1fa next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "110111", alu_ce <= '1';
; RESET b,E
1c3 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "110000", alu_ce <= '1';
1d3 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "110010", alu_ce <= '1';
1e3 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "110100", alu_ce <= '1';
1f3 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "110110", alu_ce <= '1';
1cb next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "110001", alu_ce <= '1';
1db next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "110011", alu_ce <= '1';
1eb next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "110101", alu_ce <= '1';
1fb next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "110111", alu_ce <= '1';
; RESET b,H
1c4 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "110000", alu_ce <= '1';
1d4 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "110010", alu_ce <= '1';
1e4 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "110100", alu_ce <= '1';
1f4 next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "110110", alu_ce <= '1';
1cc next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "110001", alu_ce <= '1';
1dc next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "110011", alu_ce <= '1';
1ec next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "110101", alu_ce <= '1';
1fc next <= X"25f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "110111", alu_ce <= '1';
; RESET b,L
1c5 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "110000", alu_ce <= '1';
1d5 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "110010", alu_ce <= '1';
1e5 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "110100", alu_ce <= '1';
1f5 next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "110110", alu_ce <= '1';
1cd next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "110001", alu_ce <= '1';
1dd next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "110011", alu_ce <= '1';
1ed next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "110101", alu_ce <= '1';
1fd next <= X"26f", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "110111", alu_ce <= '1';
; RESET b,A
1c7 next <= X"27f", rf_omux <= "100", dmux <= "010", alu_cmd <= "110000", alu_ce <= '1';
1d7 next <= X"27f", rf_omux <= "100", dmux <= "010", alu_cmd <= "110010", alu_ce <= '1';
1e7 next <= X"27f", rf_omux <= "100", dmux <= "010", alu_cmd <= "110100", alu_ce <= '1';
1f7 next <= X"27f", rf_omux <= "100", dmux <= "010", alu_cmd <= "110110", alu_ce <= '1';
1cf next <= X"27f", rf_omux <= "100", dmux <= "010", alu_cmd <= "110001", alu_ce <= '1';
1df next <= X"27f", rf_omux <= "100", dmux <= "010", alu_cmd <= "110011", alu_ce <= '1';
1ef next <= X"27f", rf_omux <= "100", dmux <= "010", alu_cmd <= "110101", alu_ce <= '1';
1ff next <= X"27f", rf_omux <= "100", dmux <= "010", alu_cmd <= "110111", alu_ce <= '1';
; RESET (HL)            16 cycles
;   tmp <= HL           (12 cycles left)
1c6 next <= X"30f", rf_omux <= "010";
1d6 next <= X"30f", rf_omux <= "010";
1e6 next <= X"30f", rf_omux <= "010";
1f6 next <= X"30f", rf_omux <= "010";
1ce next <= X"30f", rf_omux <= "010";
1de next <= X"30f", rf_omux <= "010";
1ee next <= X"30f", rf_omux <= "010";
1fe next <= X"30f", rf_omux <= "010";
;   (HL) <= RESET(tmp)  (9 cycles left)
2c6 next <= X"2a2", rf_omux <= "010", dmux <= "100", alu_cmd <= "111000", alu_ce <= '1';
2d6 next <= X"2a2", rf_omux <= "010", dmux <= "100", alu_cmd <= "111010", alu_ce <= '1';
2e6 next <= X"2a2", rf_omux <= "010", dmux <= "100", alu_cmd <= "111100", alu_ce <= '1';
2f6 next <= X"2a2", rf_omux <= "010", dmux <= "100", alu_cmd <= "111110", alu_ce <= '1';
2ce next <= X"2a2", rf_omux <= "010", dmux <= "100", alu_cmd <= "111001", alu_ce <= '1';
2de next <= X"2a2", rf_omux <= "010", dmux <= "100", alu_cmd <= "111011", alu_ce <= '1';
2ee next <= X"2a2", rf_omux <= "010", dmux <= "100", alu_cmd <= "111101", alu_ce <= '1';
2fe next <= X"2a2", rf_omux <= "010", dmux <= "100", alu_cmd <= "111111", alu_ce <= '1';

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
