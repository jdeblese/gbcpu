LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
library UNISIM;
use UNISIM.VComponents.all;

use work.system_comp.all;
use work.clockgen_comp.all;
use work.cpu_comp.all;
use work.video_comp.all;
use work.driver_comp.all;

ENTITY cpu_tb IS
END cpu_tb;

ARCHITECTURE behavior OF cpu_tb IS

    constant clk_period : time := 10 ns;

    signal CLK : STD_LOGIC;
    signal RST : STD_LOGIC;

    signal VSYNC, HSYNC : std_logic;
    signal RED, GREEN : std_logic_vector(2 downto 0);
    signal BLUE : std_logic_vector(1 downto 0);

    signal read, write : io_list;
    signal TDO : std_logic;
    signal LED : std_logic_vector(7 downto 0);
BEGIN

    usys : system port map( RST, CLK, LED, read, write, '0', TDO, '0', '0', VSYNC, HSYNC, RED, GREEN, BLUE );


    -- Clock process definitions
    clk_process : process
    begin
        CLK <= '0';
        wait for clk_period/2;
        CLK <= '1';
        wait for clk_period/2;
    end process;

    --  Test Bench Statements
    tb : PROCESS
    BEGIN

        rst <= '1';

        wait for clk_period * 9; -- wait until global set/reset completes
        wait for clk_period * 0.9;

        rst <= '0';

        wait for 15 us;
        rst <= '1';
        wait for clk_period * 10;
        rst <= '0';

        wait; -- will wait forever
     END PROCESS tb;
     --  End Test Bench

END;
