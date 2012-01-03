library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity falledge is
	Port (	ABUS : out STD_LOGIC_VECTOR(15 downto 0);
			DBUS : in STD_LOGIC_VECTOR(7 downto 0);
			RAM_OE : out STD_LOGIC;
			CLK : IN STD_LOGIC;
			RST : IN STD_LOGIC );
end falledge;

architecture FSM of falledge is


type STATE_TYPE is (RESET, FETCH, ERR, READ, JMP, WAI);
type PC_TYPE is (INC, JMP, JR);
type ABUS_SRC is (PC, SP, HL, PTR);

signal CS, NS: STATE_TYPE; 
signal w_en  : STD_LOGIC;
signal waits : STD_LOGIC_VECTOR(4 downto 0);
signal tics  : STD_LOGIC_VECTOR(4 downto 0);

signal PCBUF    : STD_LOGIC_VECTOR(7 downto 0);
signal PCBUF_CE : STD_LOGIC;

signal PC     : STD_LOGIC_VECTOR(15 downto 0);
signal PC_OE  : STD_LOGIC;
signal PC_CE  : STD_LOGIC;
signal PC_MUX : PC_TYPE;

signal CMD    : STD_LOGIC_VECTOR(7 downto 0);
signal CMD_CE : STD_LOGIC;

begin

	ABUS <= PC WHEN PC_OE = '1' ELSE
			"ZZZZZZZZZZZZZZZZ";

	CMD_PROC : process(CLK, RST)
	begin
		if (RST = '1') then
			CMD <= "00000000";
		elsif (falling_edge(CLK)) then
			if (CMD_CE = '1') then
				CMD <= DBUS;
			end if;
		end if;
	end process;

	PCBUF_PROC : process(CLK, RST)
	begin
		if (RST = '1') then
			PCBUF <= "00000000";
		elsif (falling_edge(CLK)) then
			if (PCBUF_CE = '1') then
				PCBUF <= DBUS;
			end if;
		end if;
	end process;

	PC_PROC : process(CLK, RST, DBUS)
	begin
		if (RST = '1') then
			PC <= "0000000000000000";
		elsif (falling_edge(CLK)) then
			if (PC_CE = '1') then
                case PC_MUX is
                    when INC =>
					    PC <= PC + "0000000000000001";
                    when JMP =>
					    PC <= DBUS & PCBUF;
                    when JR =>
					    PC <= PC + (PCBUF(7) & PCBUF(7) & PCBUF(7) & PCBUF(7) & PCBUF(7) & PCBUF(7) & PCBUF(7) & PCBUF(7) & PCBUF);
                end case;
			end if;
		end if;
	end process;

	SYNC_PROC: process (clk, rst) 
		variable old : std_logic;
	begin 
		if (rst = '1') then 
			CS <= RESET;
			waits <= "00000";
			old := '0';
		elsif (falling_edge(clk)) then 
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
			when RESET => 
				NS <= FETCH;

				w_en <= '0';	-- Continue waiting
				
				CMD_CE <= '0';	-- Preserve CMD
				PC_CE <= '0';	-- Preserve PC
				PC_OE <= '0';	-- Don't need PC on the bus
				PC_MUX <= INC;  -- Doesn't matter, won't change
				RAM_OE <= '0';	-- Don't need data from RAM
				PCBUF_CE <= '0';	-- Doesn't matter, not relevant

			when FETCH => 
				PCBUF_CE <= '0';	-- Don't care

				PC_OE <= '1';	-- Let RAM latch address
				PC_CE <= '1';	-- After fetch, increment PC
				PC_MUX <= INC;  -- Increment

				RAM_OE <= '1';	-- Put command on data bus
                CMD_CE <= '1';	-- Save the command at the end of the state

				w_en <= '0';

                case DBUS is
                    when "00011000" =>  -- 18 : JR n
                        NS <= READ;
                    when "11000011" =>  -- C3 : JMP nn
					    NS <= READ;
                    when "00000000" =>  -- 00 : NOP
					    NS <= WAI;
					    tics <= "00010";	-- 3 tics
                        w_en <= '1';
                    when others =>
                        ns <= ERR;
                end case;

			when READ =>
				NS <= JMP;

				w_en <= '0';	-- Not waiting
				
				CMD_CE <= '0';	-- Preserve CMD

                PC_OE <= '1';	-- Provide address for n_lo
				PC_CE <= '1';	-- Update PC
				PC_MUX <= INC;	-- ... increment update

				RAM_OE <= '1';	-- Allow n_lo on data bus

                PCBUF_CE <= '1';	-- latch n_lo in pcbuf at end of state
			
			when JMP =>
				-- Jump complete, wait
				NS <= WAI;
				w_en <= '1';

				CMD_CE <= '0';	-- Preserve CMD

                PC_OE <= '1';	-- Provide address for n_hi
				PC_CE <= '1';	-- Update PC
				PC_MUX <= JMP;	-- ... jump update

				RAM_OE <= '1';	-- Allow n_hi on data bus

				PCBUF_CE <= '0';	-- Doesn't matter, contents will be latched in PC at next tic

                case CMD is
                    when "11000011" =>  -- JMP nn
				        tics <= "01000";	-- 9 tics
                        PC_MUX <= JMP;
                    when "00011000" =>  -- JR n
				        tics <= "00100";	-- 5 tics
                        PC_MUX <= JR;
                    when others =>
                        PC_MUX <= INC;
                        NS <= ERR;
                end case;

			when WAI => 
				NS <= WAI;

				w_en <= '1';	-- Continue waiting
				
				CMD_CE <= '0';	-- Preserve CMD
				PC_CE <= '0';	-- Preserve PC
				PC_OE <= '0';	-- Don't need PC on the bus
				PC_MUX <= INC;	-- Doesn't matter, won't change
				RAM_OE <= '0';	-- Don't need data from RAM
				PCBUF_CE <= '0';	-- Doesn't matter, not relevant

				if waits = "00000" then
					NS <= FETCH;
					w_en <= '0';
				end if;
				
			when ERR => 
				NS <= ERR;

				w_en <= '0';	-- Continue waiting
				
				CMD_CE <= '0';	-- Preserve CMD
				PC_CE <= '0';	-- Preserve PC
				PC_OE <= '0';	-- Don't need PC on the bus
				PC_MUX <= INC;	-- Doesn't matter, won't change
				RAM_OE <= '0';	-- Don't need data from RAM
				PCBUF_CE <= '0';	-- Doesn't matter, not relevant

		end case;
	end process; -- End COMB_PROC 
	
end FSM;

