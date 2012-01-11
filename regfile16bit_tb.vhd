LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
library UNISIM;
use UNISIM.VComponents.all;

ENTITY regfile16bit_tb IS
END regfile16bit_tb;

ARCHITECTURE behavior OF regfile16bit_tb IS

    constant clk_period : time := 10 ns;

    component regfile16bit
	    Port (  idata : in std_logic_vector(7 downto 0);
	            odata : out std_logic_vector(7 downto 0);
                addr : out std_logic_vector(15 downto 0);
                imux : in std_logic_vector(2 downto 0);
                omux : in std_logic_vector(2 downto 0);
                dmux : in std_logic_vector(3 downto 0);
                amux : in std_logic_vector(1 downto 0);
                ce : in std_logic_vector(1 downto 0);
                CLK : IN STD_LOGIC;
                RST : IN STD_LOGIC );
    end component;

	signal idata : std_logic_vector(7 downto 0) := X"00";
	signal odata : std_logic_vector(7 downto 0) := X"00";
    signal addr : std_logic_vector(15 downto 0) := X"0000";
    signal imux : std_logic_vector(2 downto 0) := "000";
    signal omux : std_logic_vector(2 downto 0) := "000";
    signal dmux : std_logic_vector(3 downto 0) := "0000";
    signal amux : std_logic_vector(1 downto 0) := "00";
    signal ce : std_logic_vector(1 downto 0) := "00";
    signal CLK : STD_LOGIC := '0';
    signal RST : STD_LOGIC := '1';

begin

    uut : regfile16bit port map (idata, odata, addr, imux, omux, dmux, amux, ce, CLK, RST);

    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    tb : PROCESS
    BEGIN
        wait for clk_period*10; -- wait until global set/reset completes
        rst <= '0';
        wait for 1 ns; -- Sync to just after the falling edge

        -- HL <= 010Ah
        imux <= "010";
        ce <= "10";
        idata <= X"01";
        wait for clk_period;
        ce <= "01";
        idata <= X"0A";
        omux <= "010";
        wait for clk_period;

        -- BC <= F5h
        imux <= "000";
        ce <= "01";
        idata <= X"F5";
        wait for clk_period;

        -- Increment BC
        imux <= "000";
        ce <= "11";
        amux <= "11";
        omux <= "000";
        wait for clk_period;

        -- Add BC to HL
        imux <= "010";
        ce <= "11";
        amux <= "01";
        omux <= "000";
        wait for clk_period;

        -- Decrement SP
        imux <= "011";
        ce <= "11";
        amux <= "10";
        omux <= "011";
        wait for clk_period;

        -- Add 2 to PC
        imux <= "100";
        amux <= "00";
        omux <= "100";
        ce <= "11";
        idata <= X"02";
        wait for clk_period;

        -- Move HL into PC
        omux <= "111"; -- Zeros
        amux <= "01";  -- HL
        imux <= "100"; -- PC
        ce <= "11";
        wait for clk_period;

        -- Move SP into HL
        omux <= "011"; -- SP
        amux <= "00";  -- IDATA
        imux <= "010"; -- HL
        IDATA <= X"00";
        ce <= "11";
        wait for clk_period;

        -- Display HL on ADDR
        omux <= "010";
        ce <= "00";

        wait; -- will wait forever
     END PROCESS tb;

end;
