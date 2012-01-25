; DMUX: RAM  RF ACC ALU TMP UNQ FIXED 0
;       000 001 010 011 100 101 110

; ***************************************************************************
; *     First block instructions (with opcode [0-3]*)                       *
; ***************************************************************************

; NOP           4 cycles
000 next <= X"3fd", rf_omux <= "100", rf_dmux <= X"f";

; TODO: STOP

; JRNZ n        12/8 cycles
;   read n
020 next <= X"3e4", rf_omux <= "100";
;   jump depending on zero flag
120 cmdjmp <= '1', fljmp <= '1', flsel <= '1', next <= X"200", rf_omux <= "100";
;   flag is not set, so put n on the databus and update PC (6 cycles left)
220 next <= X"3fa", dmux <= "100", rf_omux <= "100", rf_amux <= "00", rf_imux <= "100", rf_ce <= "11";
;   flag is set, so move on to fetch (2 cycles left)
320 next <= X"3fe", rf_omux <= "100";

; JRNC n        12/8 cycles
;   read n
030 next <= X"3e4", rf_omux <= "100";
;   jump depending on carry flag
130 cmdjmp <= '1', fljmp <= '1', flsel <= '0', next <= X"200", rf_omux <= "100";
;   flag is not set, so put n on the databus and update PC (6 cycles left)
230 next <= X"3fa", dmux <= "100", rf_omux <= "100", rf_amux <= "00", rf_imux <= "100", rf_ce <= "11";
;   flag is set, so move on to fetch (2 cycles left)
330 next <= X"3fe", rf_omux <= "100";

; JR n          12 cycles
;   read n
018 next <= X"3e4", rf_omux <= "100";
;   put n on the databus and update PC (7 cycles left)
118 next <= X"3f9", dmux <= "100", rf_omux <= "100", rf_amux <= "00", rf_imux <= "100", rf_ce <= "11";

; JRZ n         12/8 cycles
;   read n
028 next <= X"3e4", rf_omux <= "100";
;   jump depending on zero flag
128 cmdjmp <= '1', fljmp <= '1', flsel <= '1', next <= X"200", rf_omux <= "100";
;   flag is not set, so move on to fetch (2 cycles left)
228 next <= X"3fe", rf_omux <= "100";
;   flag is set, so put n on the databus and update PC (6 cycles left)
328 next <= X"3fa", dmux <= "100", rf_omux <= "100", rf_amux <= "00", rf_imux <= "100", rf_ce <= "11";

; JRC n         12/8 cycles
;   read n
038 next <= X"3e4", rf_omux <= "100";
;   jump depending on carry flag
138 cmdjmp <= '1', fljmp <= '1', flsel <= '0', next <= X"200", rf_omux <= "100";
;   flag is not set, so move on to fetch (2 cycles left)
238 next <= X"3fe", rf_omux <= "100";
;   flag is set, so put n on the databus and update PC (6 cycles left)
338 next <= X"3fa", dmux <= "100", rf_omux <= "100", rf_amux <= "00", rf_imux <= "100", rf_ce <= "11";


; LD {BC,DE,HL,SP}, nn      12 cycles
; first byte in unq into lsB, second in tmp into msB, keeping PC on address bus
;   BC,nn
001 next <= X"3e0", rf_omux <= "100";
101 next <= X"311", dmux <= "100", rf_imuxsel <= '1', rf_ce <= "10", rf_omux <= "100";
;   DE,nn
011 next <= X"3e0", rf_omux <= "100";
111 next <= X"311", dmux <= "100", rf_imuxsel <= '1', rf_ce <= "10", rf_omux <= "100";
;   HL,nn
021 next <= X"3e0", rf_omux <= "100";
121 next <= X"311", dmux <= "100", rf_imuxsel <= '1', rf_ce <= "10", rf_omux <= "100";
;   SP,nn
031 next <= X"3e0", rf_omux <= "100";
131 next <= X"311", dmux <= "100", rf_imuxsel <= '1', rf_ce <= "10", rf_omux <= "100";
;   Add unq into lsB for all
311 next <= X"3fe", dmux <= "101", rf_imuxsel <= '1', rf_ce <= "01", rf_omux <= "100";

; LD ({BC,DE,HL+,HL-}),A    8 cycles
; address and acc on bus for 4 cycles, wr_en, inc/decrement HL at the end of the 4th as with PC
;   (BC),A
002 cmdjmp <= '1', next <= X"100", rf_omux <= "000", dmux <= "010";
102 cmdjmp <= '1', next <= X"200", rf_omux <= "000", dmux <= "010";
202 cmdjmp <= '1', next <= X"300", rf_omux <= "000", dmux <= "010", wr_en <= '1';
302 cmdjmp <= '0', next <= X"3fc", rf_omux <= "000", dmux <= "010", wr_en <= '1';
;   (DE),A
012 cmdjmp <= '1', next <= X"100", rf_omux <= "001", dmux <= "010";
112 cmdjmp <= '1', next <= X"200", rf_omux <= "001", dmux <= "010";
212 cmdjmp <= '1', next <= X"300", rf_omux <= "001", dmux <= "010", wr_en <= '1';
312 cmdjmp <= '0', next <= X"3fc", rf_omux <= "001", dmux <= "010", wr_en <= '1';
;   (HL+),A
022 cmdjmp <= '1', next <= X"100", rf_omux <= "010", dmux <= "010";
122 cmdjmp <= '1', next <= X"200", rf_omux <= "010", dmux <= "010";
222 cmdjmp <= '1', next <= X"300", rf_omux <= "010", dmux <= "010", wr_en <= '1';
322 cmdjmp <= '0', next <= X"3fc", rf_omux <= "010", dmux <= "010", wr_en <= '1', rf_amux <= "11", rf_imux <= "010", rf_ce <= "11";
;   (HL-),A
032 cmdjmp <= '1', next <= X"100", rf_omux <= "010", dmux <= "010";
132 cmdjmp <= '1', next <= X"200", rf_omux <= "010", dmux <= "010";
232 cmdjmp <= '1', next <= X"300", rf_omux <= "010", dmux <= "010", wr_en <= '1';
332 cmdjmp <= '0', next <= X"3fc", rf_omux <= "010", dmux <= "010", wr_en <= '1', rf_amux <= "10", rf_imux <= "010", rf_ce <= "11";

; LD A,({BC,DE})    8 cycles
; address on bus for 4 cycles, loading into A, then jump to delay 4 cycles
;   A,(BC)
00a cmdjmp <= '1', next <= X"100", rf_omux <= "000";
10a cmdjmp <= '1', next <= X"200", rf_omux <= "000";
20a cmdjmp <= '1', next <= X"300", rf_omux <= "000", acc_ce <= '1';
30a                next <= X"3fc", rf_omux <= "000";
;   A,(DE)
01a cmdjmp <= '1', next <= X"100", rf_omux <= "001";
11a cmdjmp <= '1', next <= X"200", rf_omux <= "001";
21a cmdjmp <= '1', next <= X"300", rf_omux <= "001", acc_ce <= '1';
31a                next <= X"3fc", rf_omux <= "001";

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
003 next <= X"3f9", rf_omux <= "000", rf_amux <= "11", rf_imuxsel <= '1', rf_ce <= "11";
013 next <= X"3f9", rf_omux <= "001", rf_amux <= "11", rf_imuxsel <= '1', rf_ce <= "11";
023 next <= X"3f9", rf_omux <= "010", rf_amux <= "11", rf_imuxsel <= '1', rf_ce <= "11";
033 next <= X"3f9", rf_omux <= "011", rf_amux <= "11", rf_imuxsel <= '1', rf_ce <= "11";
00b next <= X"3f9", rf_omux <= "000", rf_amux <= "10", rf_imuxsel <= '1', rf_ce <= "11";
01b next <= X"3f9", rf_omux <= "001", rf_amux <= "10", rf_imuxsel <= '1', rf_ce <= "11";
02b next <= X"3f9", rf_omux <= "010", rf_amux <= "10", rf_imuxsel <= '1', rf_ce <= "11";
03b next <= X"3f9", rf_omux <= "011", rf_amux <= "10", rf_imuxsel <= '1', rf_ce <= "11";


; INC {B,D,H}           4 cycles    ZNH-
004 next <= X"304", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
014 next <= X"304", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
024 next <= X"304", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
304 next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "10",                    rf_omux <= "100", znhc <= "1110";
; INC {C,E,L}           4 cycles    ZNH-
00c next <= X"314", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
01c next <= X"314", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
02c next <= X"314", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
314 next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "01",                    rf_omux <= "100", znhc <= "1110";
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
305 next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "10",                    rf_omux <= "100", znhc <= "1110";
; DEC {C,E,L}                   4 cycles
00d next <= X"315", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "001100", alu_ce <= '1', rf_omux <= "100";
01d next <= X"315", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "001100", alu_ce <= '1', rf_omux <= "100";
02d next <= X"315", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "001100", alu_ce <= '1', rf_omux <= "100";
315 next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "01",                    rf_omux <= "100", znhc <= "1110";
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
316 next <= X"326", rf_omux <= "100", rf_imuxsel <= '1', rf_ce <= "10";
326 next <= X"3fc", rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";
; LD {C,E,L},n                  8 cycles
00e next <= X"30e", rf_omux <= "100";
01e next <= X"30e", rf_omux <= "100";
02e next <= X"30e", rf_omux <= "100";
30e next <= X"31e", rf_omux <= "100";
31e next <= X"32e", rf_omux <= "100", rf_imuxsel <= '1', rf_ce <= "01";
32e next <= X"3fc", rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";
; LD A,n                        8 cycles
03e next <= X"206", rf_omux <= "100";
206 next <= X"216", rf_omux <= "100";
216 next <= X"226", rf_omux <= "100", acc_ce <= '1';
226 next <= X"3fc", rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";
; LD (HL),n                     12 cycles
036 next <= X"20e", rf_omux <= "100";
20e next <= X"21e", rf_omux <= "100";
21e next <= X"22e", rf_omux <= "100", tmp_ce <= '1';
22e next <= X"236", rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";
236 next <= X"336", rf_omux <= "010", dmux <= "100";
336 next <= X"23e", rf_omux <= "010", dmux <= "100";
23e next <= X"33e", rf_omux <= "010", dmux <= "100", wr_en <= '1';
33e next <= X"3fc", rf_omux <= "010", dmux <= "100", wr_en <= '1';

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
341 next <= X"342", rf_omux <= "010", rf_imuxsel <= '1', rf_ce <= "10";
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
344 next <= X"342", rf_omux <= "010", rf_imuxsel <= '1', rf_ce <= "01";

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
382 next <= X"383", rf_omux <= "010", alu_cmd <= "000000", alu_ce <= '1', rf_omux <= "100";
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
385 next <= X"383", rf_omux <= "010", alu_cmd <= "000001", alu_ce <= '1', rf_omux <= "100";

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
387 next <= X"383", rf_omux <= "010", alu_cmd <= "000010", alu_ce <= '1', rf_omux <= "100";

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
389 next <= X"383", rf_omux <= "010", alu_cmd <= "000011", alu_ce <= '1', rf_omux <= "100";

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
38b next <= X"383", rf_omux <= "010", alu_cmd <= "010000", alu_ce <= '1', rf_omux <= "100";

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
38d next <= X"383", rf_omux <= "010", alu_cmd <= "010010", alu_ce <= '1', rf_omux <= "100";

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
38f next <= X"383", rf_omux <= "010", alu_cmd <= "010001", alu_ce <= '1', rf_omux <= "100";

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
392 next <= X"393", rf_omux <= "010", alu_cmd <= "000110", alu_ce <= '1', rf_omux <= "100";
393 next <= X"3fc", rf_omux <= "010", znhc <= "1111";

; ***************************************************************************
; *     Fourth block instructions (with opcode [c-f]*)                      *
; ***************************************************************************

; ***************************************************************************
; *     Subroutines                                                         *
; ***************************************************************************

; Load (PC) into unq, PC++. Address should already be on bus for 1 cycle
3e0 next <= X"3e1", rf_omux <= "100";
3e1 next <= X"3e2", rf_omux <= "100", unq_ce <= '1';
3e2 next <= X"3e3", rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";
; (PC) into tmp, PC++, and jump to "01" & CMD
3e3 next <= X"3e4", rf_omux <= "100";
3e4 next <= X"3e5", rf_omux <= "100";
3e5 next <= X"3e6", rf_omux <= "100", tmp_ce <= '1';
3e6 next <= X"100", rf_omux <= "100", cmdjmp <= '1', rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";

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
