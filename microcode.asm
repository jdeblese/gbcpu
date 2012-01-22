; DMUX: RAM  RF ACC ALU TMP UNQ FIXED 0
;       000 001 010 011 100 101 110

; NOP           4 cycles
000 next <= X"3fd", rf_omux <= "100", rf_dmux <= X"f";

; TODO: STOP

; checking of flags is missing from microcpu
; TODO: JRNZ n
; TODO: JRNC n

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

; INC {BC,DE,HL,SP}     8 cycles
003 next <= X"3f9", rf_omux <= "000", rf_amux <= "11", rf_imuxsel <= '1', rf_ce <= "11";
013 next <= X"3f9", rf_omux <= "001", rf_amux <= "11", rf_imuxsel <= '1', rf_ce <= "11";
023 next <= X"3f9", rf_omux <= "010", rf_amux <= "11", rf_imuxsel <= '1', rf_ce <= "11";
033 next <= X"3f9", rf_omux <= "011", rf_amux <= "11", rf_imuxsel <= '1', rf_ce <= "11";

; INC {B,D,H}           4 cycles
004 cmdjmp <= '1', next <= X"100", dmux <= "001", rf_dmux <= X"0", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
104                next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "10",                    rf_omux <= "100";
014 cmdjmp <= '1', next <= X"100", dmux <= "001", rf_dmux <= X"2", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
114                next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "10",                    rf_omux <= "100";
024 cmdjmp <= '1', next <= X"100", dmux <= "001", rf_dmux <= X"4", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
124                next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "10",                    rf_omux <= "100";

; INC L         4 cycles    ZNH-
02c cmdjmp <= '1', next <= X"100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
12c next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "01", rf_omux <= "100";

; ADD HL,n      8 cycles    -NHC
009 next <= X"3f9", rf_omux <= "000", rf_amux <= "01", rf_imux <= "010", rf_ce <= "11";
019 next <= X"3f9", rf_omux <= "001", rf_amux <= "01", rf_imux <= "010", rf_ce <= "11";
029 next <= X"3f9", rf_omux <= "010", rf_amux <= "01", rf_imux <= "010", rf_ce <= "11";
039 next <= X"3f9", rf_omux <= "011", rf_amux <= "01", rf_imux <= "010", rf_ce <= "11";

3e0 next <= X"3e1", rf_omux <= "100";
3e1 next <= X"3e2", rf_omux <= "100", unq_ce <= '1';
3e2 next <= X"3e3", rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";
3e3 next <= X"3e4", rf_omux <= "100";
3e4 next <= X"3e5", rf_omux <= "100";
3e5 next <= X"3e6", rf_omux <= "100", tmp_ce <= '1';
3e6 cmdjmp <= '1', next <= X"100", rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";

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
3ff cmdjmp <= '1', rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";
