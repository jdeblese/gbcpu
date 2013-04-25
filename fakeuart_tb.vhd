LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

use work.uart_comp.all;
use work.clockgen_comp.all;

ENTITY fakeuart_tb IS
END fakeuart_tb;

ARCHITECTURE behavior OF fakeuart_tb IS 

	--Inputs
	signal WR_D : std_logic_vector(7 downto 0) := (others => '0');
	signal ABUS : std_logic_vector(15 downto 0) := (others => '0');
	signal WR_EN : std_logic := '0';
	signal CPUCLK : std_logic := '0';
	signal RX : std_logic := '1';
	signal RST : std_logic := '1';
	signal lockrst : std_logic;

	--Outputs
	signal RD_D : std_logic_vector(7 downto 0);
	signal INT, TX : std_logic;

	-- Clock period definitions
	signal CLK : std_logic := '0';
	constant CLK_period : time := 10 ns;
    signal clkstatus : clockgen_status;

	constant CPUCLK_period : time := 240 ns;

BEGIN
 
    uclk : clockgen port map ( CLK, open, open, CPUCLK, open, clkstatus, RST );
    lockrst <= RST or not(clkstatus.locked);

	-- Instantiate the Unit Under Test (UUT)
	uut: uart PORT MAP ( WR_D, RD_D, ABUS, WR_EN, INT, TX, RX, CPUCLK, RST );

	-- Clock process definitions
	CLK_process :process
	begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
	end process;
 

	-- Stimulus process
	stim_proc: process
	begin		
		wait for CLK_period*10;
		rst <= '0';
		wait for 705 ns;

		ABUS <= X"FF01";
		WR_D <= X"6d";
		wait for CPUCLK_period * 2;
		WR_EN <= '1';
		wait for CPUCLK_period * 2;
		WR_EN <= '0';

		ABUS <= X"FF02";
		WR_D <= X"FF";
		wait for CPUCLK_period * 2;
		WR_EN <= '1';
		wait for CPUCLK_period * 2;
		WR_EN <= '0';

		wait;
	end process;

END;
