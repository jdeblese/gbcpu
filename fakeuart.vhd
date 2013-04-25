library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package uart_comp is
	component uart
	Port(
		WR_D  : in std_logic_vector(7 downto 0);
		RD_D  : out std_logic_vector(7 downto 0);
		ABUS  : in std_logic_vector(15 downto 0);
		WR_EN : in std_logic;
		INT	  : out std_logic;
		TX 	  : out std_logic;
		RX 	  : in std_logic;
		CLK	  : in std_logic;
		RST	  : in std_logic );
	end component;
end package;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

-- FIXME: How does starting, stopping and changing the uart affect
--  the phase of the clock divider, if at all?

use work.uart_comp.all;

entity uart is
	Port(
		WR_D  : in std_logic_vector(7 downto 0);
		RD_D  : out std_logic_vector(7 downto 0);
		ABUS  : in std_logic_vector(15 downto 0);
		WR_EN : in std_logic;
		INT	  : out std_logic;
		TX 	  : out std_logic;
		RX 	  : in std_logic;
		CLK	  : in std_logic;
		RST	  : in std_logic );
end uart;

architecture Behaviour of uart is

	-- Registers
	signal sb, sb_new : std_logic_vector(7 downto 0);
	signal sc, sc_new : std_logic_vector(7 downto 0);
	signal shift, shift_new : std_logic_vector(7 downto 0);
	signal bitcount, bitcount_new : unsigned(3 downto 0);

	-- Baudrate divider
	-- Input clock is master CPU clock at 100 MHz / 24
	-- Dividing by 4 gives a rate of 1041666.6 Baud
	-- FT232R chip can achieve 1043478.261 Baud for a divider ratio of 2.875, an error of 0.17%
	signal div, div_new : unsigned(1 downto 0);

	-- FSM
	type STATES is (SLEEP, TXMIT);
	signal CS, NS : STATES;

	-- OUTPUT
	signal tx_int, tx_new : std_logic;

begin

	RD_D <= "ZZZZZZZZ" when WR_EN = '1' else
			sb when ABUS = X"FF01" else
			sc when ABUS = X"FF02" else
			"ZZZZZZZZ";

	TX <= tx_int;

	latchproc : process(CLK, RST)
	begin
		if RST = '1' then
			sb <= (others => '0');
			sc <= (others => '0');
			shift <= (others => '0');
			CS <= SLEEP;
			tx_int <= '1';
			div <= (others => '0');
		elsif rising_edge(CLK) then
			sb <= sb_new;
			sc <= sc_new;
			shift <= shift_new;
			CS <= NS;
			tx_int <= tx_new;
			div <= div_new;
			bitcount <= bitcount_new;
		end if;
	end process;

	combproc : process(CS, tx_int, div, sb, sc, shift, WR_EN)
		variable sb_nxt, sc_nxt, shift_nxt : std_logic_vector(7 downto 0);
		variable STEP : STATES;
		variable tx_nxt : std_logic;
		variable div_nxt : unsigned(1 downto 0);
		variable bitcount_nxt : unsigned(3 downto 0);
	begin
		sb_nxt    := sb;
		sc_nxt    := sc;
		shift_nxt := shift;
		STEP      := CS;
		tx_nxt    := tx_int;
		div_nxt   := div + "1";
		bitcount_nxt := bitcount;

		if CS = TXMIT and div = "0" then
			if bitcount_nxt = "1000" then -- Time to send the stop bit
				tx_nxt := '1';
				bitcount_nxt := "1001";
				sb_nxt := shift;
			elsif bitcount_nxt = "1001" then -- Done transmitting
				STEP := SLEEP;
			else -- Shifting out data
				shift_nxt := '0' & shift(7 downto 1);
				tx_nxt := shift(0);
				bitcount_nxt := bitcount + "1";
			end if;
		end if;

		-- FIXME is writing during a transmission allowed, and does it have an effect?
		if WR_EN = '1' then
			if ABUS = X"FF01" then
				sb_nxt := WR_D;
			elsif ABUS = X"FF02" then
				sc_nxt := WR_D;
				-- A '1' in the MSb starts transmission
				if WR_D(7) = '1' then
					STEP := TXMIT;
					-- Start bit
					tx_nxt := '0';
					div_nxt := "01";
					bitcount_nxt := (others => '0');
				else
					STEP := SLEEP;
				end if;
			end if;
		end if;

		sb_new    <= sb_nxt;
		sc_new    <= sc_nxt;
		shift_new <= shift_nxt;
		NS        <= STEP;
		tx_new    <= tx_nxt;
		div_new   <= div;
		bitcount_new <= bitcount;
	end process;

end Behaviour;
