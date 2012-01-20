; NOP
000 next <= X"1fd", rf_omux <= "100", rf_dmux <= X"f";

; INC L
02c next <= X"040", rf_omux <= "100", alu_cmd <= X"2c", alu_ce <= '1', rf_dmux <= X"5";
040 next <= X"1fe", rf_omux <= "100", rf_imuxsel <= '1', rf_ce <= "01";

1f8 next <= X"1f9";
1f9 next <= X"1fa";
1fa next <= X"1fb";
1fb next <= X"1fc";
1fc next <= X"1fd";
1fd next <= X"1fe", rf_omux <= "100";
1fe next <= X"1ff", rf_omux <= "100";
1ff cmdjmp <= '1', rf_omux <= "100", rf_imux <= "100", rf_amux <= "11", rf_ce <= "11";
