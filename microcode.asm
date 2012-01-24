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

; TODO: Implement LD (nn),SP        20 cycles
; (nn) can be stored and used in tmp,unc, but not easily incremented
; (nn) could be put in one of the register file registers and incremented there, but that would block access to SP
; an addition 16-bit incrementer may be necessary

; ADD HL,r16     8 cycles    -NHC
009 next <= X"109", rf_omux <= "000", rf_amux <= "01", rf_imux <= "010", rf_ce <= "11";
019 next <= X"109", rf_omux <= "001", rf_amux <= "01", rf_imux <= "010", rf_ce <= "11";
029 next <= X"109", rf_omux <= "010", rf_amux <= "01", rf_imux <= "010", rf_ce <= "11";
039 next <= X"109", rf_omux <= "011", rf_amux <= "01", rf_imux <= "010", rf_ce <= "11";
109 next <= X"3fa", znhc <= "0111", flagsrc <= '1';

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
