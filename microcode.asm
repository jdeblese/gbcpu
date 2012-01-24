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
218 next <= X"3f9", dmux <= "100", rf_omux <= "100", rf_amux <= "00", rf_imux <= "100", rf_ce <= "11";

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
101 cmdjmp <= '1', next <= X"200", dmux <= "100", rf_imuxsel <= '1', rf_ce <= "10", rf_omux <= "100";
201                next <= X"3fe", dmux <= "101", rf_imuxsel <= '1', rf_ce <= "01", rf_omux <= "100";
;   DE,nn
011 next <= X"3e0", rf_omux <= "100";
111 cmdjmp <= '1', next <= X"200", dmux <= "100", rf_imuxsel <= '1', rf_ce <= "10", rf_omux <= "100";
211                next <= X"3fe", dmux <= "101", rf_imuxsel <= '1', rf_ce <= "01", rf_omux <= "100";
;   HL,nn
021 next <= X"3e0", rf_omux <= "100";
121 cmdjmp <= '1', next <= X"200", dmux <= "100", rf_imuxsel <= '1', rf_ce <= "10", rf_omux <= "100";
221                next <= X"3fe", dmux <= "101", rf_imuxsel <= '1', rf_ce <= "01", rf_omux <= "100";
;   SP,nn
031 next <= X"3e0", rf_omux <= "100";
131 cmdjmp <= '1', next <= X"200", dmux <= "100", rf_imuxsel <= '1', rf_ce <= "10", rf_omux <= "100";
231                next <= X"3fe", dmux <= "101", rf_imuxsel <= '1', rf_ce <= "01", rf_omux <= "100";

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
;   A,(HL+)
02a next <= X"12a", rf_omux <= "010";
12a next <= X"22a", rf_omux <= "010";
22a next <= X"32a", rf_omux <= "010", acc_ce <= '1';
32a next <= X"3fc", rf_omux <= "010", rf_amux <= "11", rf_imux <= "010", rf_ce <= "11";
;   A,(HL-)
03a next <= X"13a", rf_omux <= "010";
13a next <= X"23a", rf_omux <= "010";
23a next <= X"33a", rf_omux <= "010", acc_ce <= '1';
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

; INC {B,C,D,E,H,L,A}           4 cycles    ZNH-
004 cmdjmp <= '1', next <= X"100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
104                next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "10",                    rf_omux <= "100", znhc <= "1110";
014 cmdjmp <= '1', next <= X"100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
114                next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "10",                    rf_omux <= "100", znhc <= "1110";
024 cmdjmp <= '1', next <= X"100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
124                next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "10",                    rf_omux <= "100", znhc <= "1110";
00c cmdjmp <= '1', next <= X"100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
10c                next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "01",                    rf_omux <= "100", znhc <= "1110";
01c cmdjmp <= '1', next <= X"100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
11c                next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "01",                    rf_omux <= "100", znhc <= "1110";
02c cmdjmp <= '1', next <= X"100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
12c                next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "01",                    rf_omux <= "100", znhc <= "1110";
03c cmdjmp <= '1', next <= X"100", dmux <= "010", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
13c                next <= X"3fe", dmux <= "011", acc_ce <= '1',                      rf_omux <= "100", znhc <= "1110";

; INC (HL)          12 cycles, ZNH-
; recycle unused micro-op memory from INC r8
;   load (HL) into alu, +1
034 next <= X"134", rf_omux <= "010";
134 next <= X"234", rf_omux <= "010";
234 next <= X"334", rf_omux <= "010", alu_cmd <= "001000", alu_ce <= '1';
334 next <= X"204", rf_omux <= "010", znhc <= "1110";
;   store alu into (HL), then jump to fetch
204 next <= X"304", rf_omux <= "010", dmux <= "011";
304 next <= X"214", rf_omux <= "010", dmux <= "011";
214 next <= X"314", rf_omux <= "010", dmux <= "011", wr_en <= '1';
314 next <= X"3fc", rf_omux <= "010", dmux <= "011", wr_en <= '1';

; DEC {B,C,D,E,H,L,A}           4 cycles
005 cmdjmp <= '1', next <= X"100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "001100", alu_ce <= '1', rf_omux <= "100";
105                next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "10",                    rf_omux <= "100", znhc <= "1110";
015 cmdjmp <= '1', next <= X"100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "001100", alu_ce <= '1', rf_omux <= "100";
115                next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "10",                    rf_omux <= "100", znhc <= "1110";
025 cmdjmp <= '1', next <= X"100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "001100", alu_ce <= '1', rf_omux <= "100";
125                next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "10",                    rf_omux <= "100", znhc <= "1110";
00d cmdjmp <= '1', next <= X"100", dmux <= "001", rf_dmux <= X"1", alu_cmd <= "001100", alu_ce <= '1', rf_omux <= "100";
10d                next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "01",                    rf_omux <= "100", znhc <= "1110";
01d cmdjmp <= '1', next <= X"100", dmux <= "001", rf_dmux <= X"3", alu_cmd <= "001100", alu_ce <= '1', rf_omux <= "100";
11d                next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "01",                    rf_omux <= "100", znhc <= "1110";
02d cmdjmp <= '1', next <= X"100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "001100", alu_ce <= '1', rf_omux <= "100";
12d                next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "01",                    rf_omux <= "100", znhc <= "1110";
03d cmdjmp <= '1', next <= X"100", dmux <= "010", alu_cmd <= "001100", alu_ce <= '1', rf_omux <= "100";
13d                next <= X"3fe", dmux <= "011", acc_ce <= '1',                      rf_omux <= "100", znhc <= "1110";

; DEC (HL)          12 cycles, ZNH-
; recycle unused micro-op memory from DEC r8
;   load (HL) into alu, -1
035 next <= X"135", rf_omux <= "010";
135 next <= X"235", rf_omux <= "010";
235 next <= X"335", rf_omux <= "010", alu_cmd <= "001100", alu_ce <= '1';
335 next <= X"205", rf_omux <= "010", znhc <= "1110";
;   store alu into (HL), then jump to fetch
205 next <= X"305", rf_omux <= "010", dmux <= "011";
305 next <= X"215", rf_omux <= "010", dmux <= "011";
215 next <= X"315", rf_omux <= "010", dmux <= "011", wr_en <= '1';
315 next <= X"3fc", rf_omux <= "010", dmux <= "011", wr_en <= '1';

; LD {B,C,D,E,H,L,A},n          8 cycles
;   load n into register tmp via subroutine, then copy from tmp into the target
006 next <= X"3e4", rf_omux <= "100";
106 next <= X"3fd", rf_omux <= "100", dmux <= "100", rf_imuxsel <= '1', rf_ce <= "10";
016 next <= X"3e4", rf_omux <= "100";
116 next <= X"3fd", rf_omux <= "100", dmux <= "100", rf_imuxsel <= '1', rf_ce <= "10";
026 next <= X"3e4", rf_omux <= "100";
126 next <= X"3fd", rf_omux <= "100", dmux <= "100", rf_imuxsel <= '1', rf_ce <= "10";
00e next <= X"3e4", rf_omux <= "100";
10e next <= X"3fd", rf_omux <= "100", dmux <= "100", rf_imuxsel <= '1', rf_ce <= "01";
01e next <= X"3e4", rf_omux <= "100";
11e next <= X"3fd", rf_omux <= "100", dmux <= "100", rf_imuxsel <= '1', rf_ce <= "01";
02e next <= X"3e4", rf_omux <= "100";
12e next <= X"3fd", rf_omux <= "100", dmux <= "100", rf_imuxsel <= '1', rf_ce <= "01";
03e next <= X"3e4", rf_omux <= "100";
13e next <= X"3fd", rf_omux <= "100", dmux <= "100", acc_ce <= '1';

; LD (HL),n          12 cycles
;   load n into register tmp via subroutine, then write tmp to memory
;   recycle unused micro-op memory from LD A,n
036 next <= X"3e4", rf_omux <= "100";
136 next <= X"236", rf_omux <= "010", dmux <= "100";
236 next <= X"336", rf_omux <= "010", dmux <= "100";
336 next <= X"23e", rf_omux <= "010", dmux <= "100", wr_en <= '1';
23e next <= X"3fc", rf_omux <= "010", dmux <= "100", wr_en <= '1';

; RLCA, RLA     4 cycles    ZNHC
007 cmdjmp <= '1', next <= X"100", dmux <= "010", alu_cmd <= "100000", alu_ce <= '1', rf_omux <= "100";
107                next <= X"3fe", dmux <= "011", acc_ce <= '1',                      rf_omux <= "100", znhc <= "1111";
017 cmdjmp <= '1', next <= X"100", dmux <= "010", alu_cmd <= "100001", alu_ce <= '1', rf_omux <= "100";
117                next <= X"3fe", dmux <= "011", acc_ce <= '1',                      rf_omux <= "100", znhc <= "1111";

; RRCA, RRA     4 cycles    ZNHC
00f cmdjmp <= '1', next <= X"100", dmux <= "010", alu_cmd <= "100010", alu_ce <= '1', rf_omux <= "100";
10f                next <= X"3fe", dmux <= "011", acc_ce <= '1',                      rf_omux <= "100", znhc <= "1111";
01f cmdjmp <= '1', next <= X"100", dmux <= "010", alu_cmd <= "100011", alu_ce <= '1', rf_omux <= "100";
11f                next <= X"3fe", dmux <= "011", acc_ce <= '1',                      rf_omux <= "100", znhc <= "1111";

; DAA     4 cycles    Z-HC
027 cmdjmp <= '1', next <= X"100", dmux <= "010", alu_cmd <= "011000", alu_ce <= '1', rf_omux <= "100";
127                next <= X"3fe", dmux <= "011", acc_ce <= '1',                      rf_omux <= "100", znhc <= "1011";

; CPL A         4 cycles    -NH-
02f cmdjmp <= '1', next <= X"100", dmux <= "010", alu_cmd <= "010011", alu_ce <= '1', rf_omux <= "100";
12f                next <= X"3fe", dmux <= "011", acc_ce <= '1',                      rf_omux <= "100", znhc <= "0110";

; SCF, CCF     4 cycles    -NHC
037 cmdjmp <= '1', next <= X"100", dmux <= "010", alu_cmd <= "011010", alu_ce <= '1', rf_omux <= "100";
137                next <= X"3fe", dmux <= "011",                                     rf_omux <= "100", znhc <= "0111";
03f cmdjmp <= '1', next <= X"100", dmux <= "010", alu_cmd <= "011011", alu_ce <= '1', rf_omux <= "100";
13f                next <= X"3fe", dmux <= "011",                                     rf_omux <= "100", znhc <= "0111";

; LD (nn),SP            20 cycles
; Load S and P into tmp and unq while loading nn into SP. Write tmp and unq to (SP), then
; load the next command while restoring tmp and unq to S and P
;   tmp <= S
;   S <= (PC++)
008 next <= X"108", rf_omux <= "100", dmux <= "001", rf_dmux <= X"6", tmp_ce <= '1';
108 next <= X"208", rf_omux <= "100";
208 next <= X"308", rf_omux <= "100", rf_imux <= "011", rf_ce <= "10";
308 next <= X"209", rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";
;   unq <= P
;   P <= (PC++)
209 next <= X"219", rf_omux <= "100", dmux <= "001", rf_dmux <= X"7", unq_ce <= '1';
219 next <= X"229", rf_omux <= "100";
229 next <= X"239", rf_omux <= "100", rf_imux <= "011", rf_ce <= "01";
239 next <= X"309", rf_omux <= "100", cmdjmp <= '1', rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";
;   (SP++) <= tmp
309 next <= X"319", rf_omux <= "011", dmux <= "100";
319 next <= X"329", rf_omux <= "011", dmux <= "100";
329 next <= X"339", rf_omux <= "011", dmux <= "100", wr_en <= '1';
339 next <= X"10b", rf_omux <= "011", dmux <= "100", wr_en <= '1', rf_imux <= "011", rf_amux <= "11", rf_ce <= "11";
;   (SP++) <= unq
;   P <= unq
10b next <= X"319", rf_omux <= "011", dmux <= "101";
11b next <= X"329", rf_omux <= "011", dmux <= "101";
12b next <= X"339", rf_omux <= "011", dmux <= "101", wr_en <= '1';
13b next <= X"119", rf_omux <= "011", dmux <= "101", wr_en <= '1', rf_imux <= "011", rf_ce <= "01";
;   S <= tmp
;   FETCH
119 next <= X"3fd", rf_omux <= "100", dmux <= "100", rf_imux <= "011", rf_ce <= "10";

; ADD HL,r16     8 cycles    -NHC
009 next <= X"109", rf_omux <= "000", rf_amux <= "01", rf_imux <= "010", rf_ce <= "11";
019 next <= X"109", rf_omux <= "001", rf_amux <= "01", rf_imux <= "010", rf_ce <= "11";
029 next <= X"109", rf_omux <= "010", rf_amux <= "01", rf_imux <= "010", rf_ce <= "11";
039 next <= X"109", rf_omux <= "011", rf_amux <= "01", rf_imux <= "010", rf_ce <= "11";
109 next <= X"3fa", znhc <= "0111", flagsrc <= '1';

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
046 next <= X"146", rf_omux <= "010";
146 next <= X"246", rf_omux <= "010";
246 next <= X"346", rf_omux <= "010", rf_imux <= "000", rf_ce <= "10";
346 next <= X"3fc", rf_omux <= "010";

; LD C,{B,C,D,E,H,L,A}          4 cycles
048 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", rf_imux <= "000", rf_ce <= "01";
049 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", rf_imux <= "000", rf_ce <= "01";
04a next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", rf_imux <= "000", rf_ce <= "01";
04b next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", rf_imux <= "000", rf_ce <= "01";
04c next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", rf_imux <= "000", rf_ce <= "01";
04d next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", rf_imux <= "000", rf_ce <= "01";
04f next <= X"3fd", rf_omux <= "100", dmux <= "010",                  rf_imux <= "000", rf_ce <= "01";
; LD C,(HL)                     8 cycles
04e next <= X"14e", rf_omux <= "010";
14e next <= X"24e", rf_omux <= "010";
24e next <= X"34e", rf_omux <= "010", rf_imux <= "000", rf_ce <= "01";
34e next <= X"3fc", rf_omux <= "010";

; LD D,{B,C,D,E,H,L,A}          4 cycles
050 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", rf_imux <= "001", rf_ce <= "10";
051 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", rf_imux <= "001", rf_ce <= "10";
052 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", rf_imux <= "001", rf_ce <= "10";
053 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", rf_imux <= "001", rf_ce <= "10";
054 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", rf_imux <= "001", rf_ce <= "10";
055 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", rf_imux <= "001", rf_ce <= "10";
057 next <= X"3fd", rf_omux <= "100", dmux <= "010",                  rf_imux <= "001", rf_ce <= "10";
; LD D,(HL)                     8 cycles
056 next <= X"156", rf_omux <= "010";
156 next <= X"256", rf_omux <= "010";
256 next <= X"356", rf_omux <= "010", rf_imux <= "001", rf_ce <= "10";
356 next <= X"3fc", rf_omux <= "010";

; LD E,{B,C,D,E,H,L,A}          4 cycles
058 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", rf_imux <= "001", rf_ce <= "01";
059 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", rf_imux <= "001", rf_ce <= "01";
05a next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", rf_imux <= "001", rf_ce <= "01";
05b next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", rf_imux <= "001", rf_ce <= "01";
05c next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", rf_imux <= "001", rf_ce <= "01";
05d next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", rf_imux <= "001", rf_ce <= "01";
05f next <= X"3fd", rf_omux <= "100", dmux <= "010",                  rf_imux <= "001", rf_ce <= "01";
; LD E,(HL)                     8 cycles
05e next <= X"15e", rf_omux <= "010";
15e next <= X"25e", rf_omux <= "010";
25e next <= X"35e", rf_omux <= "010", rf_imux <= "001", rf_ce <= "01";
35e next <= X"3fc", rf_omux <= "010";

; LD H,{B,C,D,E,H,L,A}          4 cycles
060 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", rf_imux <= "010", rf_ce <= "10";
061 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", rf_imux <= "010", rf_ce <= "10";
062 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", rf_imux <= "010", rf_ce <= "10";
063 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", rf_imux <= "010", rf_ce <= "10";
064 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", rf_imux <= "010", rf_ce <= "10";
065 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", rf_imux <= "010", rf_ce <= "10";
067 next <= X"3fd", rf_omux <= "100", dmux <= "010",                  rf_imux <= "010", rf_ce <= "10";
; LD H,(HL)                     8 cycles
066 next <= X"166", rf_omux <= "010";
166 next <= X"266", rf_omux <= "010";
266 next <= X"366", rf_omux <= "010", rf_imux <= "010", rf_ce <= "10";
366 next <= X"3fc", rf_omux <= "010";

; LD L,{B,C,D,E,H,L,A}          4 cycles
068 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", rf_imux <= "010", rf_ce <= "01";
069 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", rf_imux <= "010", rf_ce <= "01";
06a next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", rf_imux <= "010", rf_ce <= "01";
06b next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", rf_imux <= "010", rf_ce <= "01";
06c next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", rf_imux <= "010", rf_ce <= "01";
06d next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", rf_imux <= "010", rf_ce <= "01";
06f next <= X"3fd", rf_omux <= "100", dmux <= "010",                  rf_imux <= "010", rf_ce <= "01";
; LD L,(HL)                     8 cycles
06e next <= X"16e", rf_omux <= "010";
16e next <= X"26e", rf_omux <= "010";
26e next <= X"36e", rf_omux <= "010", rf_imux <= "010", rf_ce <= "01";
36e next <= X"3fc", rf_omux <= "010";

; LD (HL),B                     8 cycles
070 next <= X"170", rf_omux <= "010", dmux <= "001", rf_dmux <= X"0";
170 next <= X"270", rf_omux <= "010", dmux <= "001", rf_dmux <= X"0";
270 next <= X"370", rf_omux <= "010", dmux <= "001", rf_dmux <= X"0", wr_en <= '1';
370 next <= X"3fc", rf_omux <= "010", dmux <= "001", rf_dmux <= X"0", wr_en <= '1';
; LD (HL),C                     8 cycles
071 next <= X"171", rf_omux <= "010", dmux <= "001", rf_dmux <= X"1";
171 next <= X"271", rf_omux <= "010", dmux <= "001", rf_dmux <= X"1";
271 next <= X"371", rf_omux <= "010", dmux <= "001", rf_dmux <= X"1", wr_en <= '1';
371 next <= X"3fc", rf_omux <= "010", dmux <= "001", rf_dmux <= X"1", wr_en <= '1';
; LD (HL),D                     8 cycles
072 next <= X"172", rf_omux <= "010", dmux <= "001", rf_dmux <= X"2";
172 next <= X"272", rf_omux <= "010", dmux <= "001", rf_dmux <= X"2";
272 next <= X"372", rf_omux <= "010", dmux <= "001", rf_dmux <= X"2", wr_en <= '1';
372 next <= X"3fc", rf_omux <= "010", dmux <= "001", rf_dmux <= X"2", wr_en <= '1';
; LD (HL),E                     8 cycles
073 next <= X"173", rf_omux <= "010", dmux <= "001", rf_dmux <= X"3";
173 next <= X"273", rf_omux <= "010", dmux <= "001", rf_dmux <= X"3";
273 next <= X"373", rf_omux <= "010", dmux <= "001", rf_dmux <= X"3", wr_en <= '1';
373 next <= X"3fc", rf_omux <= "010", dmux <= "001", rf_dmux <= X"3", wr_en <= '1';
; LD (HL),H                     8 cycles
074 next <= X"174", rf_omux <= "010", dmux <= "001", rf_dmux <= X"4";
174 next <= X"274", rf_omux <= "010", dmux <= "001", rf_dmux <= X"4";
274 next <= X"374", rf_omux <= "010", dmux <= "001", rf_dmux <= X"4", wr_en <= '1';
374 next <= X"3fc", rf_omux <= "010", dmux <= "001", rf_dmux <= X"4", wr_en <= '1';
; LD (HL),L                     8 cycles
075 next <= X"175", rf_omux <= "010", dmux <= "001", rf_dmux <= X"5";
175 next <= X"275", rf_omux <= "010", dmux <= "001", rf_dmux <= X"5";
275 next <= X"375", rf_omux <= "010", dmux <= "001", rf_dmux <= X"5", wr_en <= '1';
375 next <= X"3fc", rf_omux <= "010", dmux <= "001", rf_dmux <= X"5", wr_en <= '1';
; LD (HL),A                     8 cycles
077 next <= X"177", rf_omux <= "010", dmux <= "010";
177 next <= X"277", rf_omux <= "010", dmux <= "010";
277 next <= X"377", rf_omux <= "010", dmux <= "010", wr_en <= '1';
377 next <= X"3fc", rf_omux <= "010", dmux <= "010", wr_en <= '1';

; LD A,{B,C,D,E,H,L,A}          4 cycles
078 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"0", acc_ce <= '1';
079 next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"1", acc_ce <= '1';
07a next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"2", acc_ce <= '1';
07b next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"3", acc_ce <= '1';
07c next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"4", acc_ce <= '1';
07d next <= X"3fd", rf_omux <= "100", dmux <= "001", rf_dmux <= X"5", acc_ce <= '1';
07f next <= X"3fd", rf_omux <= "100", dmux <= "010",                  acc_ce <= '1';
; LD A,(HL)                     8 cycles
07e next <= X"17e", rf_omux <= "010";
17e next <= X"27e", rf_omux <= "010";
27e next <= X"37e", rf_omux <= "010", acc_ce <= '1';
37e next <= X"3fc", rf_omux <= "010";

; TODO: HALT

; ***************************************************************************
; *     Third block instructions: 8-bit alu ops                             *
; ***************************************************************************

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
