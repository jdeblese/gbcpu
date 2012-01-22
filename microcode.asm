; DMUX: RAM RF ACC ALU TMP UNQ FIXED 0

; NOP           4 cycles
000 next <= X"3fd", rf_omux <= "100", rf_dmux <= X"f";

; INC L         4 cycles    ZNH-
02c cmdjmp <= '1', next <= X"100", dmux <= "001", rf_dmux <= X"5", alu_cmd <= "001000", alu_ce <= '1', rf_omux <= "100";
12c next <= X"3fe", dmux <= "011", rf_imuxsel <= '1', rf_ce <= "01", rf_omux <= "100";

; ADD HL,n      8 cycles    -NHC
009 next <= X"3f9", rf_omux <= "000", rf_amux <= "01", rf_imux <= "010", rf_ce <= "11";
019 next <= X"3f9", rf_omux <= "001", rf_amux <= "01", rf_imux <= "010", rf_ce <= "11";
029 next <= X"3f9", rf_omux <= "010", rf_amux <= "01", rf_imux <= "010", rf_ce <= "11";
039 next <= X"3f9", rf_omux <= "011", rf_amux <= "01", rf_imux <= "010", rf_ce <= "11";

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
