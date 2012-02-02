; DMUX: RAM  RF ACC ALU TMP UNQ FIXED ZNHC
;       000 001 010 011 100 101 110   111
; AMUX: RF16 TMP16 RF8 TMP8
;       00   01    10  11

; ***************************************************************************
; *     First block instructions (with opcode [0-3]*)                       *
; ***************************************************************************

; NOP           4 cycles
000 next <= X"3fd", rf_omux <= "100", rf_dmux <= X"f";

; TODO: STOP

; JRNZ/Z helper
200 next <= X"210", rf_omux <= "100";
210 next <= X"300", rf_omux <= "100", tmp_ce <= '1';
;   jump depending on zero flag
300 next <= X"200", rf_omux <= "100", cmdjmp <= '1', fljmp <= '1', flsel <= '1', rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";

; JRNZ n        12/8 cycles
;   read n
020 next <= X"200", rf_omux <= "100";
;   flag is not set, so put n on the databus and update PC (8 cycles left)
220 next <= X"3f9", dmux <= "100", rf_omux <= "100", rf_amux <= "00", rf_imux <= "100", rf_ce <= "11";
;   flag is set, so move on to fetch (4 cycles left)
320 next <= X"3fd", rf_omux <= "100";

; JRZ n         12/8 cycles
;   read n
028 next <= X"200", rf_omux <= "100";
;   flag is not set, so move on to fetch (4 cycles left)
228 next <= X"3fd", rf_omux <= "100";
;   flag is set, so put n on the databus and update PC (8 cycles left)
328 next <= X"3f9", dmux <= "100", rf_omux <= "100", rf_amux <= "00", rf_imux <= "100", rf_ce <= "11";

; JR n          12/8 cycles
;   read n
018 next <= X"200", rf_omux <= "100";
;   flag doesn't matter - put n on the databus and update PC (8 cycles left)
218 next <= X"3f9", dmux <= "100", rf_omux <= "100", rf_amux <= "00", rf_imux <= "100", rf_ce <= "11";
318 next <= X"3f9", dmux <= "100", rf_omux <= "100", rf_amux <= "00", rf_imux <= "100", rf_ce <= "11";


; JRNC/C helper
254 next <= X"255", rf_omux <= "100";
255 next <= X"31c", rf_omux <= "100", tmp_ce <= '1';
;   jump depending on zero flag
31c next <= X"200", rf_omux <= "100", cmdjmp <= '1', fljmp <= '1', flsel <= '0', rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";

; JRNC n        12/8 cycles
;   read n
030 next <= X"254", rf_omux <= "100";
;   flag is not set, so put n on the databus and update PC (8 cycles left)
230 next <= X"3f9", dmux <= "100", rf_omux <= "100", rf_amux <= "00", rf_imux <= "100", rf_ce <= "11";
;   flag is set, so move on to fetch (4 cycles left)
330 next <= X"3fd", rf_omux <= "100";

; JRC n         12/8 cycles
;   read n
038 next <= X"254", rf_omux <= "100";
;   flag is not set, so move on to fetch (4 cycles left)
238 next <= X"3fd", rf_omux <= "100";
;   flag is set, so put n on the databus and update PC (8 cycles left)
338 next <= X"3f9", dmux <= "100", rf_omux <= "100", rf_amux <= "00", rf_imux <= "100", rf_ce <= "11";


; LD16 helpers
;   Load (PC) into unq, PC++. Address should already be on bus for 1 cycle
258 next <= X"259", rf_omux <= "100";
259 next <= X"25a", rf_omux <= "100", unq_ce <= '1';
25a next <= X"25b", rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";
;   (PC) into tmp, PC++, and jump to 200 + CMD
25b next <= X"25c", rf_omux <= "100";
25c next <= X"25d", rf_omux <= "100";
25d next <= X"24d", rf_omux <= "100", tmp_ce <= '1';
24d next <= X"200", rf_omux <= "100", cmdjmp <= '1', rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";

; LD {BC,DE,HL,SP}, nn      12 cycles
; first byte in unq into lsB, second in tmp into msB, keeping PC on address bus
;   BC,nn
001 next <= X"258", rf_omux <= "100";
201 next <= X"311", dmux <= "100", rf_imuxsel <= "01", rf_ce <= "10", rf_omux <= "100";
;   DE,nn
011 next <= X"258", rf_omux <= "100";
211 next <= X"311", dmux <= "100", rf_imuxsel <= "01", rf_ce <= "10", rf_omux <= "100";
;   HL,nn
021 next <= X"258", rf_omux <= "100";
221 next <= X"311", dmux <= "100", rf_imuxsel <= "01", rf_ce <= "10", rf_omux <= "100";
;   SP,nn
031 next <= X"258", rf_omux <= "100";
231 next <= X"311", dmux <= "100", rf_imuxsel <= "01", rf_ce <= "10", rf_omux <= "100";
;   Add unq into lsB for all
311 next <= X"3fe", dmux <= "101", rf_imuxsel <= "01", rf_ce <= "01", rf_omux <= "100";


; LD ({BC,DE,HL+,HL-}),A    8 cycles
; address and acc on bus for 4 cycles, wr_en, inc/decrement HL at the end of the 4th as with PC
;   (BC),A
002 next <= X"203", rf_omux <= "000", dmux <= "010";
203 next <= X"202", rf_omux <= "000", dmux <= "010";
202 next <= X"302", rf_omux <= "000", dmux <= "010", wr_en <= '1';
302 next <= X"3fc", rf_omux <= "000", dmux <= "010", wr_en <= '1';
;   (DE),A
012 next <= X"213", rf_omux <= "001", dmux <= "010";
213 next <= X"212", rf_omux <= "001", dmux <= "010";
212 next <= X"312", rf_omux <= "001", dmux <= "010", wr_en <= '1';
312 next <= X"3fc", rf_omux <= "001", dmux <= "010", wr_en <= '1';
;   (HL+),A
022 next <= X"223", rf_omux <= "010", dmux <= "010";
223 next <= X"222", rf_omux <= "010", dmux <= "010";
222 next <= X"322", rf_omux <= "010", dmux <= "010", wr_en <= '1';
322 next <= X"3fc", rf_omux <= "010", dmux <= "010", wr_en <= '1', rf_amux <= "11", rf_imux <= "010", rf_ce <= "11";
;   (HL-),A
032 next <= X"233", rf_omux <= "010", dmux <= "010";
233 next <= X"232", rf_omux <= "010", dmux <= "010";
232 next <= X"332", rf_omux <= "010", dmux <= "010", wr_en <= '1';
332 next <= X"3fc", rf_omux <= "010", dmux <= "010", wr_en <= '1', rf_amux <= "10", rf_imux <= "010", rf_ce <= "11";

; LD A,({BC,DE})    8 cycles
; address on bus for 4 cycles, loading into A, then jump to delay 4 cycles
;   A,(BC)
00a next <= X"208", rf_omux <= "000";
208 next <= X"20a", rf_omux <= "000";
20a next <= X"30a", rf_omux <= "000", acc_ce <= '1';
30a next <= X"3fc", rf_omux <= "000";
;   A,(DE)
01a next <= X"235", rf_omux <= "001";
235 next <= X"21a", rf_omux <= "001";
21a next <= X"31a", rf_omux <= "001", acc_ce <= '1';
31a next <= X"3fc", rf_omux <= "001";

; LD A,({HL+,HL-})    8 cycles
; address on bus for 4 cycles, loading into acc, then jump to delay 4 cycles
;   set the address
02a next <= X"22a", rf_omux <= "010";
03a next <= X"22a", rf_omux <= "010";
;   read into ACC, jumping depending on cmd
22a next <= X"23a", rf_omux <= "010";
23a cmdjmp <= '1', next <= X"300", rf_omux <= "010", acc_ce <= '1';
;   increment/decrement HL
32a next <= X"3fc", rf_omux <= "010", rf_amux <= "11", rf_imux <= "010", rf_ce <= "11";
33a next <= X"3fc", rf_omux <= "010", rf_amux <= "10", rf_imux <= "010", rf_ce <= "11";


; INC/DEC {BC,DE,HL,SP}     8 cycles
003 next <= X"3f9", rf_omux <= "000", rf_amux <= "11", rf_imuxsel <= "01", rf_ce <= "11";
013 next <= X"3f9", rf_omux <= "001", rf_amux <= "11", rf_imuxsel <= "01", rf_ce <= "11";
023 next <= X"3f9", rf_omux <= "010", rf_amux <= "11", rf_imuxsel <= "01", rf_ce <= "11";
033 next <= X"3f9", rf_omux <= "011", rf_amux <= "11", rf_imuxsel <= "01", rf_ce <= "11";
00b next <= X"3f9", rf_omux <= "000", rf_amux <= "10", rf_imuxsel <= "01", rf_ce <= "11";
01b next <= X"3f9", rf_omux <= "001", rf_amux <= "10", rf_imuxsel <= "01", rf_ce <= "11";
02b next <= X"3f9", rf_omux <= "010", rf_amux <= "10", rf_imuxsel <= "01", rf_ce <= "11";
03b next <= X"3f9", rf_omux <= "011", rf_amux <= "10", rf_imuxsel <= "01", rf_ce <= "11";


; INC {B,D,H}           4 cycles    ZNH-
004 next <= X"304", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
014 next <= X"304", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
024 next <= X"304", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
304 next <= X"3fe", dmux <= "011", rf_imuxsel <= "01", rf_ce <= "10",                    rf_omux <= "100", znhc <= "1110";
; INC {C,E,L}           4 cycles    ZNH-
00c next <= X"314", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
01c next <= X"314", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
02c next <= X"314", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
314 next <= X"3fe", dmux <= "011", rf_imuxsel <= "01", rf_ce <= "01",                    rf_omux <= "100", znhc <= "1110";
; INC A                 4 cycles    ZNH-
03c next <= X"324", dmux <= "010", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
324 next <= X"3fe", dmux <= "011", acc_ce <= '1',                      rf_omux <= "100", znhc <= "1110";

; INC (HL)          12 cycles, ZNH-
; recycle unused micro-op memory from INC r8
;   load (HL) into alu, +1
034 next <= X"204", rf_omux <= "010";
204 next <= X"214", rf_omux <= "010";
214 next <= X"224", rf_omux <= "010", alu_cmd <= "001000", alu_ce <= '1';
224 next <= X"234", rf_omux <= "010", znhc <= "1110";
;   store alu into (HL), then jump to fetch
234 next <= X"20c", rf_omux <= "010", dmux <= "011";
20c next <= X"21c", rf_omux <= "010", dmux <= "011";
21c next <= X"22c", rf_omux <= "010", dmux <= "011", wr_en <= '1';
22c next <= X"3fc", rf_omux <= "010", dmux <= "011", wr_en <= '1';


; DEC {B,D,H}                   4 cycles
005 next <= X"305", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "001100", alu_ce <= '1', rf_omux <= "100";
015 next <= X"305", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "001100", alu_ce <= '1', rf_omux <= "100";
025 next <= X"305", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "001100", alu_ce <= '1', rf_omux <= "100";
305 next <= X"3fe", dmux <= "011", rf_imuxsel <= "01", rf_ce <= "10",                    rf_omux <= "100", znhc <= "1110";
; DEC {C,E,L}                   4 cycles
00d next <= X"315", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "001100", alu_ce <= '1', rf_omux <= "100";
01d next <= X"315", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "001100", alu_ce <= '1', rf_omux <= "100";
02d next <= X"315", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "001100", alu_ce <= '1', rf_omux <= "100";
315 next <= X"3fe", dmux <= "011", rf_imuxsel <= "01", rf_ce <= "01",                    rf_omux <= "100", znhc <= "1110";
; DEC A                         4 cycles
03d next <= X"325", dmux <= "010", alu_cmd <= "001100", alu_ce <= '1', rf_omux <= "100";
325 next <= X"3fe", dmux <= "011", acc_ce <= '1',                      rf_omux <= "100", znhc <= "1110";

; DEC (HL)          12 cycles, ZNH-
; recycle unused micro-op memory from DEC r8
;   load (HL) into alu, -1
035 next <= X"205", rf_omux <= "010";
205 next <= X"215", rf_omux <= "010";
215 next <= X"225", rf_omux <= "010", alu_cmd <= "001100", alu_ce <= '1';
225 next <= X"234", rf_omux <= "010", znhc <= "1110";
;   store alu into (HL), then jump to fetch (same as with INC (HL))


; LD {B,D,H},n                  8 cycles
006 next <= X"306", rf_omux <= "100";
016 next <= X"306", rf_omux <= "100";
026 next <= X"306", rf_omux <= "100";
306 next <= X"316", rf_omux <= "100";
316 next <= X"326", rf_omux <= "100", rf_imuxsel <= "01", rf_ce <= "10";
326 next <= X"3fc", rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";
; LD {C,E,L},n                  8 cycles
00e next <= X"30e", rf_omux <= "100";
01e next <= X"30e", rf_omux <= "100";
02e next <= X"30e", rf_omux <= "100";
30e next <= X"31e", rf_omux <= "100";
31e next <= X"32e", rf_omux <= "100", rf_imuxsel <= "01", rf_ce <= "01";
32e next <= X"3fc", rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";
; LD A,n                        8 cycles
03e next <= X"31d", rf_omux <= "100";
31d next <= X"32d", rf_omux <= "100";
32d next <= X"33d", rf_omux <= "100", acc_ce <= '1';
33d next <= X"3fc", rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";
; LD (HL),n                     12 cycles
036 next <= X"363", rf_omux <= "100";
363 next <= X"364", rf_omux <= "100";
364 next <= X"365", rf_omux <= "100", tmp_ce <= '1';
365 next <= X"366", rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";
366 next <= X"367", rf_omux <= "010", dmux <= "100";
367 next <= X"368", rf_omux <= "010", dmux <= "100";
368 next <= X"369", rf_omux <= "010", dmux <= "100", wr_en <= '1';
369 next <= X"3fc", rf_omux <= "010", dmux <= "100", wr_en <= '1';

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
008 next <= X"370", rf_omux <= "100", dmux <= "001", rf_dmux <= X"6", tmp_ce <= '1';
370 next <= X"371", rf_omux <= "100";
371 next <= X"372", rf_omux <= "100", rf_imux <= "011", rf_ce <= "10";
372 next <= X"373", rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";
;   unq <= P
;   P <= (PC++)
373 next <= X"374", rf_omux <= "100", dmux <= "001", rf_dmux <= X"7", unq_ce <= '1';
374 next <= X"375", rf_omux <= "100";
375 next <= X"376", rf_omux <= "100", rf_imux <= "011", rf_ce <= "01";
376 next <= X"377", rf_omux <= "100", cmdjmp <= '1', rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";
;   (SP++) <= tmp
377 next <= X"378", rf_omux <= "011", dmux <= "100";
378 next <= X"379", rf_omux <= "011", dmux <= "100";
379 next <= X"37a", rf_omux <= "011", dmux <= "100", wr_en <= '1';
37a next <= X"37b", rf_omux <= "011", dmux <= "100", wr_en <= '1', rf_imux <= "011", rf_amux <= "11", rf_ce <= "11";
;   (SP++) <= unq
;   P <= unq
37b next <= X"37c", rf_omux <= "011", dmux <= "101";
37c next <= X"37d", rf_omux <= "011", dmux <= "101";
37d next <= X"37e", rf_omux <= "011", dmux <= "101", wr_en <= '1';
37e next <= X"37f", rf_omux <= "011", dmux <= "101", wr_en <= '1', rf_imux <= "011", rf_ce <= "01";
;   S <= tmp
;   FETCH
37f next <= X"3fd", rf_omux <= "100", dmux <= "100", rf_imux <= "011", rf_ce <= "10";

; ADD HL,r16     8 cycles    -NHC
009 next <= X"309", rf_omux <= "000", rf_amux <= "01", rf_imux <= "010", rf_ce <= "11";
019 next <= X"309", rf_omux <= "001", rf_amux <= "01", rf_imux <= "010", rf_ce <= "11";
029 next <= X"309", rf_omux <= "010", rf_amux <= "01", rf_imux <= "010", rf_ce <= "11";
039 next <= X"309", rf_omux <= "011", rf_amux <= "01", rf_imux <= "010", rf_ce <= "11";
309 next <= X"3fa", znhc <= "0111", flagsrc <= '1';

; ***************************************************************************
; *     Second block instructions: 8-bit loads                              *
; ***************************************************************************

; LD B,{B,C,D,E,H,L,A}          4 cycles
040 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", rf_imux <= "000", rf_ce <= "10";
041 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", rf_imux <= "000", rf_ce <= "10";
042 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", rf_imux <= "000", rf_ce <= "10";
043 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", rf_imux <= "000", rf_ce <= "10";
044 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", rf_imux <= "000", rf_ce <= "10";
045 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", rf_imux <= "000", rf_ce <= "10";
047 next <= X"3fd", rf_omux <= "100", dmux <= "010",                  rf_imux <= "000", rf_ce <= "10";
; LD B,(HL)                     8 cycles
046 next <= X"340", rf_omux <= "010";
340 next <= X"341", rf_omux <= "010";
341 next <= X"342", rf_omux <= "010", rf_imuxsel <= "01", rf_ce <= "10";
342 next <= X"3fc", rf_omux <= "010";

; LD C,{B,C,D,E,H,L,A}          4 cycles
048 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", rf_imux <= "000", rf_ce <= "01";
049 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", rf_imux <= "000", rf_ce <= "01";
04a next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", rf_imux <= "000", rf_ce <= "01";
04b next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", rf_imux <= "000", rf_ce <= "01";
04c next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", rf_imux <= "000", rf_ce <= "01";
04d next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", rf_imux <= "000", rf_ce <= "01";
04f next <= X"3fd", rf_omux <= "100", dmux <= "010",                  rf_imux <= "000", rf_ce <= "01";
; LD C,(HL)                     8 cycles
04e next <= X"343", rf_omux <= "010";
343 next <= X"344", rf_omux <= "010";
344 next <= X"342", rf_omux <= "010", rf_imuxsel <= "01", rf_ce <= "01";

; LD D,{B,C,D,E,H,L,A}          4 cycles
050 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", rf_imux <= "001", rf_ce <= "10";
051 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", rf_imux <= "001", rf_ce <= "10";
052 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", rf_imux <= "001", rf_ce <= "10";
053 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", rf_imux <= "001", rf_ce <= "10";
054 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", rf_imux <= "001", rf_ce <= "10";
055 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", rf_imux <= "001", rf_ce <= "10";
057 next <= X"3fd", rf_omux <= "100", dmux <= "010",                  rf_imux <= "001", rf_ce <= "10";
; LD D,(HL)                     8 cycles
056 next <= X"340", rf_omux <= "010";

; LD E,{B,C,D,E,H,L,A}          4 cycles
058 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", rf_imux <= "001", rf_ce <= "01";
059 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", rf_imux <= "001", rf_ce <= "01";
05a next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", rf_imux <= "001", rf_ce <= "01";
05b next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", rf_imux <= "001", rf_ce <= "01";
05c next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", rf_imux <= "001", rf_ce <= "01";
05d next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", rf_imux <= "001", rf_ce <= "01";
05f next <= X"3fd", rf_omux <= "100", dmux <= "010",                  rf_imux <= "001", rf_ce <= "01";
; LD E,(HL)                     8 cycles
05e next <= X"343", rf_omux <= "010";

; LD H,{B,C,D,E,H,L,A}          4 cycles
060 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", rf_imux <= "010", rf_ce <= "10";
061 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", rf_imux <= "010", rf_ce <= "10";
062 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", rf_imux <= "010", rf_ce <= "10";
063 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", rf_imux <= "010", rf_ce <= "10";
064 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", rf_imux <= "010", rf_ce <= "10";
065 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", rf_imux <= "010", rf_ce <= "10";
067 next <= X"3fd", rf_omux <= "100", dmux <= "010",                  rf_imux <= "010", rf_ce <= "10";
; LD H,(HL)                     8 cycles
066 next <= X"340", rf_omux <= "010";

; LD L,{B,C,D,E,H,L,A}          4 cycles
068 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", rf_imux <= "010", rf_ce <= "01";
069 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", rf_imux <= "010", rf_ce <= "01";
06a next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", rf_imux <= "010", rf_ce <= "01";
06b next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", rf_imux <= "010", rf_ce <= "01";
06c next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", rf_imux <= "010", rf_ce <= "01";
06d next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", rf_imux <= "010", rf_ce <= "01";
06f next <= X"3fd", rf_omux <= "100", dmux <= "010",                  rf_imux <= "010", rf_ce <= "01";
; LD L,(HL)                     8 cycles
06e next <= X"343", rf_omux <= "010";

; LD (HL),B                     8 cycles
070 next <= X"348", rf_omux <= "010", dmux <= "001", rf_dmux <= X"0";
348 next <= X"349", rf_omux <= "010", dmux <= "001", rf_dmux <= X"0";
349 next <= X"34a", rf_omux <= "010", dmux <= "001", rf_dmux <= X"0", wr_en <= '1';
34a next <= X"3fc", rf_omux <= "010", dmux <= "001", rf_dmux <= X"0", wr_en <= '1';
; LD (HL),C                     8 cycles
071 next <= X"34c", rf_omux <= "010", dmux <= "001", rf_dmux <= X"1";
34c next <= X"34d", rf_omux <= "010", dmux <= "001", rf_dmux <= X"1";
34d next <= X"34e", rf_omux <= "010", dmux <= "001", rf_dmux <= X"1", wr_en <= '1';
34e next <= X"3fc", rf_omux <= "010", dmux <= "001", rf_dmux <= X"1", wr_en <= '1';
; LD (HL),D                     8 cycles
072 next <= X"350", rf_omux <= "010", dmux <= "001", rf_dmux <= X"2";
350 next <= X"351", rf_omux <= "010", dmux <= "001", rf_dmux <= X"2";
351 next <= X"352", rf_omux <= "010", dmux <= "001", rf_dmux <= X"2", wr_en <= '1';
352 next <= X"3fc", rf_omux <= "010", dmux <= "001", rf_dmux <= X"2", wr_en <= '1';
; LD (HL),E                     8 cycles
073 next <= X"354", rf_omux <= "010", dmux <= "001", rf_dmux <= X"3";
354 next <= X"355", rf_omux <= "010", dmux <= "001", rf_dmux <= X"3";
355 next <= X"356", rf_omux <= "010", dmux <= "001", rf_dmux <= X"3", wr_en <= '1';
356 next <= X"3fc", rf_omux <= "010", dmux <= "001", rf_dmux <= X"3", wr_en <= '1';
; LD (HL),H                     8 cycles
074 next <= X"358", rf_omux <= "010", dmux <= "001", rf_dmux <= X"4";
358 next <= X"359", rf_omux <= "010", dmux <= "001", rf_dmux <= X"4";
359 next <= X"35a", rf_omux <= "010", dmux <= "001", rf_dmux <= X"4", wr_en <= '1';
35a next <= X"3fc", rf_omux <= "010", dmux <= "001", rf_dmux <= X"4", wr_en <= '1';
; LD (HL),L                     8 cycles
075 next <= X"35c", rf_omux <= "010", dmux <= "001", rf_dmux <= X"5";
35c next <= X"35d", rf_omux <= "010", dmux <= "001", rf_dmux <= X"5";
35d next <= X"35e", rf_omux <= "010", dmux <= "001", rf_dmux <= X"5", wr_en <= '1';
35e next <= X"3fc", rf_omux <= "010", dmux <= "001", rf_dmux <= X"5", wr_en <= '1';
; LD (HL),A                     8 cycles
077 next <= X"360", rf_omux <= "010", dmux <= "010";
360 next <= X"361", rf_omux <= "010", dmux <= "010";
361 next <= X"362", rf_omux <= "010", dmux <= "010", wr_en <= '1';
362 next <= X"3fc", rf_omux <= "010", dmux <= "010", wr_en <= '1';

; LD A,{B,C,D,E,H,L,A}          4 cycles
078 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", acc_ce <= '1';
079 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", acc_ce <= '1';
07a next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", acc_ce <= '1';
07b next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", acc_ce <= '1';
07c next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", acc_ce <= '1';
07d next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", acc_ce <= '1';
07f next <= X"3fd", rf_omux <= "100", dmux <= "010",                  acc_ce <= '1';
; LD A,(HL)                     8 cycles
07e next <= X"345", rf_omux <= "010";
345 next <= X"346", rf_omux <= "010";
346 next <= X"342", rf_omux <= "010", acc_ce <= '1';

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
0e0 next <= X"25c", rf_omux <= "100";
2e0 next <= X"290", amux <= "11", dmux <= "010";
290 next <= X"291", amux <= "11", dmux <= "010";
291 next <= X"292", amux <= "11", dmux <= "010", wr_en <= '1';
292 next <= X"3fc", amux <= "11", dmux <= "010", wr_en <= '1';
; LD (FF & C), A            8 cycles
0e2 next <= X"293", rf_dmux <= X"1", amux <= "10", dmux <= "010";
293 next <= X"294", rf_dmux <= X"1", amux <= "10", dmux <= "010";
294 next <= X"295", rf_dmux <= X"1", amux <= "10", dmux <= "010", wr_en <= '1';
295 next <= X"3fc", rf_dmux <= X"1", amux <= "10", dmux <= "010", wr_en <= '1';

; LD A, (FF & n)            12 cycles
0f0 next <= X"25c", rf_omux <= "100";
2f0 next <= X"357", amux <= "11";
357 next <= X"297", amux <= "11";
297 next <= X"298", amux <= "11", acc_ce <= '1';
298 next <= X"3fc", amux <= "11";
; LD A, (FF & C)            8 cycles
0f2 next <= X"299", rf_dmux <= X"1", amux <= "10";
299 next <= X"29a", rf_dmux <= X"1", amux <= "10";
29a next <= X"29b", rf_dmux <= X"1", amux <= "10", acc_ce <= '1';
29b next <= X"3fc", rf_dmux <= X"1", amux <= "10";

; LD (nn), A                16 cycles
0ea next <= X"258", rf_omux <= "100";
2ea next <= X"29c", amux <= "01", dmux <= "010";
29c next <= X"29d", amux <= "01", dmux <= "010";
29d next <= X"20d", amux <= "01", dmux <= "010", wr_en <= '1';
20d next <= X"3fc", amux <= "01", dmux <= "010", wr_en <= '1';
; LD A, (nn)                16 cycles
0fa next <= X"258", rf_omux <= "100";
2fa next <= X"257", amux <= "01";
257 next <= X"267", amux <= "01";
267 next <= X"277", amux <= "01", acc_ce <= '1';
277 next <= X"3fc", amux <= "01";

; PUSH helper
;   (SP) <= tmp
250 next <= X"251", dmux <= "100", rf_omux <= "011";
251 next <= X"252", dmux <= "100", rf_omux <= "011";
252 next <= X"253", dmux <= "100", rf_omux <= "011", wr_en <= '1';
253 next <= X"3f9", dmux <= "100", rf_omux <= "011", wr_en <= '1';

; PUSH BC                           16 cycles
;   SP--
;   tmp <= lsB(BC)
0c5 next <= X"240", rf_dmux <= X"1", dmux <= "001", tmp_ce <= '1', rf_omux <= "011", rf_amux <= "10", rf_imux <= "011", rf_ce <= "11";
;   (SP--) <= msB(BC)
240 next <= X"241", rf_dmux <= X"0", dmux <= "001", rf_omux <= "011";
241 next <= X"242", rf_dmux <= X"0", dmux <= "001", rf_omux <= "011";
242 next <= X"243", rf_dmux <= X"0", dmux <= "001", rf_omux <= "011", wr_en <= '1';
243 next <= X"250", rf_dmux <= X"0", dmux <= "001", rf_omux <= "011", wr_en <= '1', rf_amux <= "10", rf_imux <= "011", rf_ce <= "11";

; PUSH DE                           16 cycles
;   SP--
;   tmp <= E
0d5 next <= X"244", rf_dmux <= X"3", dmux <= "001", tmp_ce <= '1', rf_omux <= "011", rf_amux <= "10", rf_imux <= "011", rf_ce <= "11";
;   (SP--) <= D
244 next <= X"245", rf_dmux <= X"2", dmux <= "001", rf_omux <= "011";
245 next <= X"30c", rf_dmux <= X"2", dmux <= "001", rf_omux <= "011";
30c next <= X"247", rf_dmux <= X"2", dmux <= "001", rf_omux <= "011", wr_en <= '1';
247 next <= X"240", rf_dmux <= X"2", dmux <= "001", rf_omux <= "011", wr_en <= '1', rf_amux <= "10", rf_imux <= "011", rf_ce <= "11";

; PUSH HL                           16 cycles
;   SP--
;   tmp <= L
0e5 next <= X"248", rf_dmux <= X"5", dmux <= "001", tmp_ce <= '1', rf_omux <= "011", rf_amux <= "10", rf_imux <= "011", rf_ce <= "11";
;   (SP--) <= H
248 next <= X"249", rf_dmux <= X"4", dmux <= "001", rf_omux <= "011";
249 next <= X"24a", rf_dmux <= X"4", dmux <= "001", rf_omux <= "011";
24a next <= X"24b", rf_dmux <= X"4", dmux <= "001", rf_omux <= "011", wr_en <= '1';
24b next <= X"240", rf_dmux <= X"4", dmux <= "001", rf_omux <= "011", wr_en <= '1', rf_amux <= "10", rf_imux <= "011", rf_ce <= "11";

; PUSH AF                           16 cycles
;   SP--
;   tmp <= znhc0000
0f5 next <= X"3b8", dmux <= "111", tmp_ce <= '1', rf_omux <= "011", rf_amux <= "10", rf_imux <= "011", rf_ce <= "11";
;   (SP--) <= A
3b8 next <= X"3b9", dmux <= "010", rf_omux <= "011";
3b9 next <= X"3ba", dmux <= "010", rf_omux <= "011";
3ba next <= X"3bb", dmux <= "010", rf_omux <= "011", wr_en <= '1';
3bb next <= X"240", dmux <= "010", rf_omux <= "011", wr_en <= '1', rf_amux <= "10", rf_imux <= "011", rf_ce <= "11";


; POP BC                            12 cycles
;   C <= (SP++)
0c1 next <= X"260", rf_omux <= "011";
260 next <= X"261", rf_omux <= "011";
261 next <= X"262", rf_omux <= "011",                  rf_imux <= "000", rf_ce <= "01";
262 next <= X"263", rf_omux <= "011", rf_amux <= "11", rf_imux <= "011", rf_ce <= "11";
;   B <= (SP++)
263 next <= X"264", rf_omux <= "011";
264 next <= X"265", rf_omux <= "011";
265 next <= X"32c", rf_omux <= "011",                  rf_imux <= "000", rf_ce <= "10";
32c next <= X"3fc", rf_omux <= "011", rf_amux <= "11", rf_imux <= "011", rf_ce <= "11";

; POP DE                            12 cycles
;   E <= (SP++)
0d1 next <= X"268", rf_omux <= "011";
268 next <= X"269", rf_omux <= "011";
269 next <= X"26a", rf_omux <= "011",                  rf_imux <= "001", rf_ce <= "01";
26a next <= X"26b", rf_omux <= "011", rf_amux <= "11", rf_imux <= "011", rf_ce <= "11";
;   D <= (SP++)
26b next <= X"26c", rf_omux <= "011";
26c next <= X"26d", rf_omux <= "011";
26d next <= X"23d", rf_omux <= "011",                  rf_imux <= "001", rf_ce <= "10";
23d next <= X"3fc", rf_omux <= "011", rf_amux <= "11", rf_imux <= "011", rf_ce <= "11";

; POP HL                            12 cycles
;   L <= (SP++)
0e1 next <= X"270", rf_omux <= "011";
270 next <= X"271", rf_omux <= "011";
271 next <= X"272", rf_omux <= "011",                  rf_imux <= "010", rf_ce <= "01";
272 next <= X"273", rf_omux <= "011", rf_amux <= "11", rf_imux <= "011", rf_ce <= "11";
;   H <= (SP++)
273 next <= X"274", rf_omux <= "011";
274 next <= X"275", rf_omux <= "011";
275 next <= X"33c", rf_omux <= "011",                  rf_imux <= "010", rf_ce <= "10";
33c next <= X"3fc", rf_omux <= "011", rf_amux <= "11", rf_imux <= "011", rf_ce <= "11";

; POP AF                            12 cycles
;   TODO: flags <= (SP++)
0f1 next <= X"278", rf_omux <= "011";
278 next <= X"279", rf_omux <= "011";
279 next <= X"27a", rf_omux <= "011";
27a next <= X"27b", rf_omux <= "011", rf_amux <= "11", rf_imux <= "011", rf_ce <= "11";
;   A <= (SP++)
27b next <= X"27c", rf_omux <= "011";
27c next <= X"27d", rf_omux <= "011";
27d next <= X"22d", rf_omux <= "011", acc_ce <= '1';
22d next <= X"3fc", rf_omux <= "011", rf_amux <= "11", rf_imux <= "011", rf_ce <= "11";


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
0e9 next <= X"2e9", rf_omux <= "010", dmux <= "001", rf_dmux <= X"4", rf_imux <= "100", rf_ce <= "10";
;   HL on address bus, L into C
2e9 next <= X"3fe", rf_omux <= "010", dmux <= "001", rf_dmux <= X"5", rf_imux <= "100", rf_ce <= "01";


; ADD SP,n      16 cycles
;   read n
0e8 next <= X"25c", rf_omux <= "100";
;   Use internal 16-bit data path, taking flags from RF
2e8 next <= X"3f5", rf_omux <= "011", rf_amux <= "00", rf_imux <= "011", rf_ce <= "11", znhc <= "1111", flagsrc <= "1";

; LD HL,SP+n    12 cycles
;   read n
0f8 next <= X"25c", rf_omux <= "100";
;   Use internal 16-bit data path, taking flags from RF
2f8 next <= X"3f9", rf_omux <= "011", rf_amux <= "00", rf_imux <= "010", rf_ce <= "11", znhc <= "1111", flagsrc <= "1";

; LD SP, HL     8 cycles
;   Use internal 16-bit data path
0f9 next <= X"3f9", rf_omux <= "010", rf_imux <= "011", rf_ce <= "11";


; ***************************************************************************
; *     CB Prefix Routines (Bit Manipulations)                              *
; ***************************************************************************

; load the second instruction byte into CMD, then jump to "01" & CMD
0cb next <= X"2cb", rf_omux <= "100";
2cb next <= X"2db", rf_omux <= "100";
2db next <= X"2eb", rf_omux <= "100", cmd_ce <= '1';
2eb next <= X"100", rf_omux <= "100", cmdjmp <= '1', rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";

; Return values to register, including flags
319 next <= X"3fe", rf_omux <= "100", dmux <= "011", rf_imuxsel <= "10", rf_ce <= "10", znhc <= "1111";
329 next <= X"3fe", rf_omux <= "100", dmux <= "011", rf_imuxsel <= "10", rf_ce <= "01", znhc <= "1111";
339 next <= X"3fe", rf_omux <= "100", dmux <= "011", acc_ce <= '1',                     znhc <= "1111";

; RLC (B,C,D,E,H,L}     8 cycles    ZNHC
100 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "100000", alu_ce <= '1';
101 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "100000", alu_ce <= '1';
102 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "100000", alu_ce <= '1';
103 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "100000", alu_ce <= '1';
104 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "100000", alu_ce <= '1';
105 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "100000", alu_ce <= '1';
; RLC A                 8 cycles    ZNHC
107 next <= X"339", rf_omux <= "100", dmux <= "010",                  alu_cmd <= "100000", alu_ce <= '1';

; RRC (B,C,D,E,H,L}     8 cycles    ZNHC
108 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "100010", alu_ce <= '1';
109 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "100010", alu_ce <= '1';
10a next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "100010", alu_ce <= '1';
10b next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "100010", alu_ce <= '1';
10c next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "100010", alu_ce <= '1';
10d next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "100010", alu_ce <= '1';
; RRC A                 8 cycles    ZNHC
10f next <= X"339", rf_omux <= "100", dmux <= "010",                  alu_cmd <= "100010", alu_ce <= '1';

; RL (B,C,D,E,H,L}     8 cycles    ZNHC
110 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "100001", alu_ce <= '1';
111 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "100001", alu_ce <= '1';
112 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "100001", alu_ce <= '1';
113 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "100001", alu_ce <= '1';
114 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "100001", alu_ce <= '1';
115 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "100001", alu_ce <= '1';
; RL A                 8 cycles    ZNHC
117 next <= X"339", rf_omux <= "100", dmux <= "010",                  alu_cmd <= "100001", alu_ce <= '1';

; RR (B,C,D,E,H,L}     8 cycles    ZNHC
118 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "100011", alu_ce <= '1';
119 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "100011", alu_ce <= '1';
11a next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "100011", alu_ce <= '1';
11b next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "100011", alu_ce <= '1';
11c next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "100011", alu_ce <= '1';
11d next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "100011", alu_ce <= '1';
; RR A                 8 cycles    ZNHC
11f next <= X"339", rf_omux <= "100", dmux <= "010",                  alu_cmd <= "100011", alu_ce <= '1';

; SLA (B,C,D,E,H,L}     8 cycles    ZNHC
120 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "100100", alu_ce <= '1';
121 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "100100", alu_ce <= '1';
122 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "100100", alu_ce <= '1';
123 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "100100", alu_ce <= '1';
124 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "100100", alu_ce <= '1';
125 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "100100", alu_ce <= '1';
; SLA A                 8 cycles    ZNHC
127 next <= X"339", rf_omux <= "100", dmux <= "010",                  alu_cmd <= "100100", alu_ce <= '1';

; SRA (B,C,D,E,H,L}     8 cycles    ZNHC
128 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "100101", alu_ce <= '1';
129 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "100101", alu_ce <= '1';
12a next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "100101", alu_ce <= '1';
12b next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "100101", alu_ce <= '1';
12c next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "100101", alu_ce <= '1';
12d next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "100101", alu_ce <= '1';
; SRA A                 8 cycles    ZNHC
12f next <= X"339", rf_omux <= "100", dmux <= "010",                  alu_cmd <= "100101", alu_ce <= '1';

; SWP (B,C,D,E,H,L}     8 cycles    ZNHC
130 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "100111", alu_ce <= '1';
131 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "100111", alu_ce <= '1';
132 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "100111", alu_ce <= '1';
133 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "100111", alu_ce <= '1';
134 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "100111", alu_ce <= '1';
135 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "100111", alu_ce <= '1';
; SWP A                 8 cycles    ZNHC
137 next <= X"339", rf_omux <= "100", dmux <= "010",                  alu_cmd <= "100111", alu_ce <= '1';

; SRL (B,C,D,E,H,L}     8 cycles    ZNHC
138 next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "100110", alu_ce <= '1';
139 next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "100110", alu_ce <= '1';
13a next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "100110", alu_ce <= '1';
13b next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "100110", alu_ce <= '1';
13c next <= X"319", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "100110", alu_ce <= '1';
13d next <= X"329", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "100110", alu_ce <= '1';
; SRL A                 8 cycles    ZNHC
13f next <= X"339", rf_omux <= "100", dmux <= "010",                  alu_cmd <= "100110", alu_ce <= '1';

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

; ***************************************************************************
; *     Subroutines                                                         *
; ***************************************************************************

3f0 next <= X"3f1";
3f1 next <= X"3f2";
3f2 next <= X"3f3";
3f3 next <= X"3f4";

3f4 next <= X"3f5";
3f5 next <= X"3f6";
3f6 next <= X"3f7";
3f7 next <= X"3f8";

3f8 next <= X"3f9";
3f9 next <= X"3fa";
3fa next <= X"3fb";
3fb next <= X"3fc";

; 4 cycles to fetch instruction
3fc next <= X"3fd", rf_omux <= "100";
3fd next <= X"3fe", rf_omux <= "100";
3fe next <= X"3ff", rf_omux <= "100", cmd_ce <= '1';
3ff cmdjmp <= '1',  rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";
