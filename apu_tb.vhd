LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
library UNISIM;
use UNISIM.VComponents.all;

ENTITY apu_tb IS
END apu_tb;

ARCHITECTURE behavior OF apu_tb IS

--	constant clk_period : time := 10 ns;
	constant clk_period : time := 9.9341074625 ns;
--	constant sysclk_period : time := 238.4185791015 ns;  -- 4,194,304 MHz
	constant sysclk_period : time := 240 ns;  -- 4,194,304 MHz

	component apu
		port (
			abus : in std_logic_vector(15 downto 0);
			dbus : in std_logic_vector(7 downto 0);
			wr_en : in std_logic;
			pcm : out std_logic_vector(3 downto 0);
			sysclk : in std_logic; -- 4194304 Hz
			clk : in std_logic;
			rst : in std_logic );
	end component;

	signal dbus : std_logic_vector(7 downto 0) := X"00";
	signal abus : std_logic_vector(15 downto 0) := X"0000";
	signal wr_en : std_logic := '0';
	signal pcm : std_logic_vector(3 downto 0);
	signal sysclk : std_logic := '0';
	signal clk : STD_LOGIC := '0';
	signal rst : STD_LOGIC := '1';

	signal clkdiv : unsigned(4 downto 0) := "00000";

begin

	uut : apu port map (abus, dbus, wr_en, pcm, sysclk, clk, rst);

	clk_process : process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
		if clkdiv = "10111" then
			clkdiv <= (others => '0');
			sysclk <= '0';
		else
			if clkdiv = "01011" then
				sysclk <= '1';
			end if;
			clkdiv <= clkdiv + "1";
		end if;
	end process;

	tb : PROCESS
	BEGIN
		wait for clk_period*10; -- wait until global set/reset completes
		rst <= '0';
		wait for 1 ns; -- Sync to just after the falling edge

		wait for sysclk_period;
		abus <= X"FF12";
		dbus <= "00100010";
		wr_en <= '1';

		wait for sysclk_period;
		wr_en <= '0';

		wait for sysclk_period;
		abus <= X"FF26";
		dbus <= "10000000";
		wr_en <= '1';

		wait for sysclk_period;
		wr_en <= '0';

		wait for sysclk_period;
		abus <= X"FF14";
		dbus <= "00000111";
		wr_en <= '1';

		wait for sysclk_period;
		wr_en <= '0';

		wait for sysclk_period;
		abus <= X"FF13";
		dbus <= "10000011";  -- First sound, 1048 Hz
--		dbus <= "11000001";  -- Second sound, 2080 Hz
		wr_en <= '1';

		wait for sysclk_period;
		wr_en <= '0';

		wait for sysclk_period;
		abus <= X"FF11";
		dbus <= "11000000";
		wr_en <= '1';

		wait for sysclk_period;
		wr_en <= '0';

		wait; -- will wait forever
	 END PROCESS tb;

end;
