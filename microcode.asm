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
101 cmdjmp <= '1', next <= X"200", dmux <= "100", rf_imux <= "000", rf_ce <= "10", rf_omux <= "100";
201                next <= X"3fe", dmux <= "101", rf_imux <= "000", rf_ce <= "01", rf_omux <= "100";
;   DE,nn
011 next <= X"3e0", rf_omux <= "100";
111 cmdjmp <= '1', next <= X"200", dmux <= "100", rf_imux <= "001", rf_ce <= "10", rf_omux <= "100";
211                next <= X"3fe", dmux <= "101", rf_imux <= "001", rf_ce <= "01", rf_omux <= "100";
;   HL,nn
021 next <= X"3e0", rf_omux <= "100";
121 cmdjmp <= '1', next <= X"200", dmux <= "100", rf_imux <= "010", rf_ce <= "10", rf_omux <= "100";
221                next <= X"3fe", dmux <= "101", rf_imux <= "010", rf_ce <= "01", rf_omux <= "100";
;   SP,nn
031 next <= X"3e0", rf_omux <= "100";
131 cmdjmp <= '1', next <= X"200", dmux <= "100", rf_imux <= "011", rf_ce <= "10", rf_omux <= "100";
231                next <= X"3fe", dmux <= "101", rf_imux <= "011", rf_ce <= "01", rf_omux <= "100";


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
