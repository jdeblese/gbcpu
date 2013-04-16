--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   07:33:41 04/16/2013
-- Design Name:   
-- Module Name:   /home/jw/projects/xilinx/GameBoy/video_tb.vhd
-- Project Name:  GameBoy
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: video
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

use work.video_comp.all;
use work.driver_comp.all;
use work.clockgen_comp.all;

ENTITY video_tb IS
END video_tb;

ARCHITECTURE behavior OF video_tb IS 

	--Inputs
	signal DIN : std_logic_vector(7 downto 0) := (others => '0');
	signal ABUS : std_logic_vector(15 downto 0) := (others => '0');
	signal WR_EN : std_logic := '0';
	signal CPUCLK : std_logic := '0';
	signal pixclk : std_logic := '0';
	signal fastclk : std_logic := '0';
	signal RST : std_logic := '1';
	signal lockrst : std_logic;

	--Outputs
	signal DOUT : std_logic_vector(7 downto 0);
	signal VID : pixelpipe;
	signal debug : std_logic;

	-- Clock period definitions
	signal CLK : std_logic := '0';
	constant CLK_period : time := 10 ns;
    signal clkstatus : clockgen_status;

	constant CPUCLK_period : time := 240 ns;

BEGIN
 
    uclk : clockgen port map ( CLK, fastclk, open, CPUCLK, pixclk, clkstatus, RST );
    lockrst <= RST or not(clkstatus.locked);

	-- Instantiate the Unit Under Test (UUT)
	uut: video PORT MAP (
	       DIN => DIN,
	       DOUT => DOUT,
	       ABUS => ABUS,
	       WR_EN => WR_EN,
	       VID => VID,
	       debug => debug,
	       CLK => CPUCLK,
	       RST => lockrst
	     );

    uvga : driver port map ( open, open, open, open, open, VID, fastclk, cpuclk, pixclk, lockrst, open );

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

		ABUS <= X"8000";
		DIN <= X"81";
		wait for CPUCLK_period * 2;
		WR_EN <= '1';
		wait for CPUCLK_period * 2;
		WR_EN <= '0';

		ABUS <= X"8010";
		DIN <= X"42";
		wait for CPUCLK_period * 2;
		WR_EN <= '1';
		wait for CPUCLK_period * 2;
		WR_EN <= '0';

		ABUS <= X"9800";
		DIN <= X"00";
		wait for CPUCLK_period * 2;
		WR_EN <= '1';
		wait for CPUCLK_period * 2;
		WR_EN <= '0';

		ABUS <= X"9C00";
		DIN <= X"01";
		wait for CPUCLK_period * 2;
		WR_EN <= '1';
		wait for CPUCLK_period * 2;
		WR_EN <= '0';

		ABUS <= X"FF42";
		DIN <= X"00";
		wait for CPUCLK_period * 2;
		WR_EN <= '1';
		wait for CPUCLK_period * 2;
		WR_EN <= '0';

		ABUS <= X"FF43";
		DIN <= X"00";
		wait for CPUCLK_period * 2;
		WR_EN <= '1';
		wait for CPUCLK_period * 2;
		WR_EN <= '0';

		ABUS <= X"FF4A";
		DIN <= X"00";
		wait for CPUCLK_period * 2;
		WR_EN <= '1';
		wait for CPUCLK_period * 2;
		WR_EN <= '0';

		ABUS <= X"FF4B";
		DIN <= X"0C";
		wait for CPUCLK_period * 2;
		WR_EN <= '1';
		wait for CPUCLK_period * 2;
		WR_EN <= '0';

		ABUS <= X"FF40";
		DIN <= X"F1";
		wait for CPUCLK_period * 2;
		WR_EN <= '1';
		wait for CPUCLK_period * 2;
		WR_EN <= '0';

		wait;
	end process;

END;
