library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL ;
--use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity simple is
	Port (	ABUS : out STD_LOGIC_VECTOR(15 downto 0);
			DBUS : in STD_LOGIC_VECTOR(7 downto 0);
			RAM_OE : out STD_LOGIC;
			CLK : IN STD_LOGIC;
			RST : IN STD_LOGIC );
end simple;

architecture FSM of simple is


type STATE_TYPE is (FETCH, DECODE, ERR, READ, JMP, WAI);

signal CS, NS: STATE_TYPE; 
signal w_en		: STD_LOGIC ;
signal waits	: STD_LOGIC_VECTOR(4 downto 0);
signal tics	: STD_LOGIC_VECTOR(4 downto 0);

signal PCBUF	: STD_LOGIC_VECTOR(7 downto 0);
signal PCBUF_CE	: STD_LOGIC ;

signal PC		: STD_LOGIC_VECTOR(15 downto 0);
signal PC_OE	: STD_LOGIC ;
signal PC_CE	: STD_LOGIC ;
signal PC_MUX	: STD_LOGIC ;

signal CMD_CE	: STD_LOGIC ;

begin

	ABUS <= PC WHEN PC_OE = '1' ELSE
			"ZZZZZZZZZZZZZZZZ" ;

	PCBUF_PROC : process(CLK, RST, DBUS)
	begin
		if (RST = '1') then
			PCBUF <= "00000000" ;
		elsif (rising_edge(CLK)) then
			if (PCBUF_CE = '1') then
				PCBUF <= DBUS;
			end if;
		end if;
	end process;

	PC_PROC : process(CLK, RST, DBUS)
	begin
		if (RST = '1') then
			PC <= "0000000000000000" ;
		elsif (rising_edge(CLK)) then
			if (PC_CE = '1') then
				if (PC_MUX = '0') then
					PC <= PC + "0000000000000001" ;
				elsif (PC_MUX = '1') then
					PC(7 downto 0) <= PCBUF ;
					PC(15 downto 8) <= DBUS ;
				end if;
			end if;
		end if;
	end process;

	SYNC_PROC: process (clk, rst) 
		variable old : std_logic;
	begin 
		if (rst = '1') then 
			CS <= FETCH; 
			waits <= "00000";
			old := '0';
		elsif (rising_edge(clk)) then 
			CS <= NS; 
			if w_en = '0' then
				waits <= "00000";
			elsif w_en = '1' then
				if old = '0' then
					waits <= tics;
				else
					waits <= waits - "00001";
				end if;
			end if;
			old := w_en;
		end if; 
	end process; --End SYNC_PROC 

	COMB_PROC: process (CS, DBUS, waits)
	begin 
		case CS is 
			when FETCH => 
				NS <= DECODE ;

				PCBUF_CE <= '0' ;	-- Don't care

				PC_OE <= '1' ;	-- Let RAM latch address
				PC_CE <= '1' ;	-- After fetch, increment PC
				PC_MUX <= '0' ;	-- Increment

				RAM_OE <= '1' ;	-- Put command on data bus
				CMD_CE <= '0' ;	-- Don't overwrite old command yet

				w_en <= '0' ;

			when DECODE => 
				NS <= ERR ;

				CMD_CE <= '1' ;	-- Save current command

				w_en <= '0' ;	-- Assume there's work to do

				-- Assume 1-byte instruction
				PC_OE <= '0' ;	-- Don't need PC on the bus anymore
				PC_CE <= '0' ;	-- PC shouldn't change
				PC_MUX <= '0' ;	-- Doesn't matter, won't change
				RAM_OE <= '1' ;	-- Leave command on bus
				PCBUF_CE <= '0' ;	-- Doesn't matter, not relevant

				if DBUS = "11000011" then -- C3 : JMP nn
					NS <= READ ;

					PC_OE <= '1' ;	-- Let RAM latch the PC
					PC_CE <= '1' ;	-- Update PC
					PC_MUX <= '0' ;	-- ... increment update

					RAM_OE <= '1' ;	-- Put n_lo on data bus at next tic
				elsif DBUS = "00000000" then	-- 00 : NOP
					-- Nothing more to do, so enter wait state
					NS <= WAI ;
					tics <= "00001" ;	-- 2 tics
					w_en <= '1' ;
				end if ;

			when READ =>
				NS <= JMP ;

				w_en <= '0' ;	-- Not waiting
				
				CMD_CE <= '0' ;	-- Preserve CMD

				PC_OE <= '1' ;	-- Let RAM latch the PC
				PC_CE <= '1' ;	-- Update PC
				PC_MUX <= '0' ;	-- ... increment update

				RAM_OE <= '1' ;	-- Put n_hi on data bus at next tic

				PCBUF_CE <= '1' ;	-- n_lo is on the bus, so latch
			
			when JMP =>
				-- Jump complete, wait
				NS <= WAI ;
				tics <= "00111" ;	-- 8 tics
				w_en <= '1';

				CMD_CE <= '0' ;	-- Preserve CMD

				PC_OE <= '0' ;	-- No more data
				PC_CE <= '1' ;	-- Update PC
				PC_MUX <= '1' ;	-- ... jump update

				RAM_OE <= '1' ;	-- keep n_hi on the bus

				PCBUF_CE <= '0' ;	-- Doesn't matter, contents will be latched in PC at next tic

			when WAI => 
				NS <= WAI ;

				w_en <= '1' ;	-- Continue waiting
				
				CMD_CE <= '0' ;	-- Preserve CMD
				PC_CE <= '0' ;	-- Preserve PC
				PC_OE <= '0' ;	-- Don't need PC on the bus
				PC_MUX <= '0' ;	-- Doesn't matter, won't change
				RAM_OE <= '0' ;	-- Don't need data from RAM
				PCBUF_CE <= '0' ;	-- Doesn't matter, not relevant

				if waits = "00000" then
					NS <= FETCH ;
					w_en <= '0' ;
				end if ;
				
			when ERR => 
				NS <= ERR ;

				w_en <= '0' ;	-- Continue waiting
				
				CMD_CE <= '0' ;	-- Preserve CMD
				PC_CE <= '0' ;	-- Preserve PC
				PC_OE <= '0' ;	-- Don't need PC on the bus
				PC_MUX <= '0' ;	-- Doesn't matter, won't change
				RAM_OE <= '0' ;	-- Don't need data from RAM
				PCBUF_CE <= '0' ;	-- Doesn't matter, not relevant

		end case;
	end process; -- End COMB_PROC 
	
end FSM;

