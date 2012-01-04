library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity falledge is
	Port (	ABUS : out STD_LOGIC_VECTOR(15 downto 0);
			DBUS : inout STD_LOGIC_VECTOR(7 downto 0);
			RAM_OE : out STD_LOGIC;
			CLK : IN STD_LOGIC;
			RST : IN STD_LOGIC );
end falledge;

architecture FSM of falledge is

type STATE_TYPE is (RESET, FETCH, ERR, READ, JMP, WAI, PARAM, LD);
type PC_TYPE is (PCINC, PCJMP, PCJR);
type ABUS_SRC is (APC, ASP, AHL, APTR);

signal CS, NS: STATE_TYPE;
signal w_en  : STD_LOGIC;
signal waits : STD_LOGIC_VECTOR(4 downto 0);
signal tics  : STD_LOGIC_VECTOR(4 downto 0);

signal PCBUF    : STD_LOGIC_VECTOR(7 downto 0);
signal PCBUF_CE : STD_LOGIC;

signal CMD    : STD_LOGIC_VECTOR(7 downto 0);
signal CMD_CE : STD_LOGIC;

signal AMUX : ABUS_SRC;

signal A : STD_LOGIC_VECTOR(7 downto 0);
signal RF_IMUX : STD_LOGIC_VECTOR(2 downto 0);
signal RF_OMUX : STD_LOGIC_VECTOR(2 downto 0);
signal RF_CE : STD_LOGIC;

signal PC, SP : STD_LOGIC_VECTOR( 15 downto 0);
signal PC_CE  : STD_LOGIC;
signal PC_MUX : PC_TYPE;

    component regfile
        port( DBUS : inout std_logic_vector(7 downto 0);
              DOMUX : in std_logic_vector(2 downto 0);
              DIMUX : in std_logic_vector(2 downto 0);
              CE : in std_logic;
              CLK : in std_logic;
              RST : in std_logic );
    end component;

begin

    urf : regfile port map(
        DBUS => DBUS,
        DOMUX => RF_OMUX,
        DIMUX => RF_IMUX,
        CE => RF_CE,
        CLK => CLK, RST => RST );

    ABUS <= PC    when AMUX = APC else
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
                    when PCINC =>
					    PC <= PC + "0000000000000001";
                    when PCJMP =>
					    PC <= DBUS & PCBUF;
                    when PCJR =>
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
        RF_OMUX <= "110";  -- Register file in high impedance
        RF_IMUX <= "110";  -- Doesn't matter
        RF_CE <= '0';

        w_en <= '0';
        tics <= "00000";

        CMD_CE <= '0';	-- Preserve CMD
        PC_CE <= '0';	-- Preserve PC
        AMUX <= APC;
        PC_MUX <= PCINC;	-- Doesn't matter, won't change
        RAM_OE <= '0';	-- Don't need data from RAM
        PCBUF_CE <= '0';	-- Doesn't matter, not relevant

        NS <= ERR;

		case CS is
			when RESET =>
				NS <= FETCH;

				w_en <= '0';	-- Continue waiting
				
				CMD_CE <= '0';	-- Preserve CMD
				PC_CE <= '0';	-- Preserve PC
				AMUX <= APC;
				PC_MUX <= PCINC;  -- Doesn't matter, won't change
				RAM_OE <= '0';	-- Don't need data from RAM
				PCBUF_CE <= '0';	-- Doesn't matter, not relevant

			when FETCH =>
				PCBUF_CE <= '0';	-- Don't care

				AMUX <= APC;
				PC_CE <= '1';	-- After fetch, increment PC
				PC_MUX <= PCINC;  -- Increment

				RAM_OE <= '1';	-- Put command on data bus
                CMD_CE <= '1';	-- Save the command at the end of the state

				w_en <= '0';

                if ( DBUS = "00000000" ) then     -- 00 NOP
                    NS <= WAI;
                    tics <= "00010";	-- 3 tics
                    w_en <= '1';
                elsif ( DBUS = "00011000" ) then  -- 18 JR n
                    NS <= READ;
                elsif ( DBUS = "11000011" ) then  -- C3 JMP nn
                    NS <= READ;
                elsif ( DBUS = "01110110" ) then -- 76 HALT
                    NS <= ERR;
                elsif ( (DBUS(7) xor DBUS(6)) = '1' ) then  -- 8-bit ops
                    NS <= PARAM;
                elsif (DBUS(2 downto 0) = "110" ) then  -- 8-bit ops
                    NS <= PARAM;
                else
                    ns <= ERR;
                end if;

           when PARAM =>  -- Gives RAM output a chance to go HiZ if needed
                NS <= LD;
                if ( CMD(2 downto 0) = "110" ) then  -- reading from (HL) or (PC)
                    RAM_OE <= '1';
                end if;

            when LD =>
                NS <= WAI;

                RF_IMUX <= CMD(5 downto 3);  -- Destination register

                RF_OMUX <= CMD(2 downto 0);  -- Source register
                case CMD(2 downto 0) is
                    when "110" =>  -- Source is RAM
                        RAM_OE <= '1';
                        if ( (CMD(7) xor CMD(6)) = '1' ) then  -- (HL)
                            AMUX <= AHL;
                        else  -- (PC)
                            AMUX <= APC;
	    			        PC_CE <= '1';	-- Update PC
		    		        PC_MUX <= PCINC;	-- ... increment update
                        end if;
                        tics <= "00100";  -- 5 tics
                        w_en <= '1';
                    when "111" =>  -- Source is accumulator
                        null;
                    when others =>
                        null;
                end case;

                RF_CE <= '1';

			when READ =>
				NS <= JMP;

				w_en <= '0';	-- Not waiting
				
				CMD_CE <= '0';	-- Preserve CMD

                AMUX <= APC;
				PC_CE <= '1';	-- Update PC
				PC_MUX <= PCINC;	-- ... increment update

				RAM_OE <= '1';	-- Allow n_lo on data bus

                PCBUF_CE <= '1';	-- latch n_lo in pcbuf at end of state
			
			when JMP =>
				-- Jump complete, wait
				NS <= WAI;
				w_en <= '1';

				CMD_CE <= '0';	-- Preserve CMD

                AMUX <= APC;
				PC_CE <= '1';	-- Update PC
				PC_MUX <= PCJMP;	-- ... jump update

				RAM_OE <= '1';	-- Allow n_hi on data bus

				PCBUF_CE <= '0';	-- Doesn't matter, contents will be latched in PC at next tic

                case CMD is
                    when "11000011" =>  -- JMP nn
				        tics <= "01000";	-- 9 tics
                        PC_MUX <= PCJMP;
                    when "00011000" =>  -- JR n
				        tics <= "00100";	-- 5 tics
                        PC_MUX <= PCJR;
                    when others =>
                        PC_MUX <= PCINC;
                        NS <= ERR;
                end case;

			when WAI =>
				NS <= WAI;

				w_en <= '1';	-- Continue waiting
				
				CMD_CE <= '0';	-- Preserve CMD
				PC_CE <= '0';	-- Preserve PC
				AMUX <= APC;
				PC_MUX <= PCINC;	-- Doesn't matter, won't change
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
				AMUX <= APC;
				PC_MUX <= PCINC;	-- Doesn't matter, won't change
				RAM_OE <= '0';	-- Don't need data from RAM
				PCBUF_CE <= '0';	-- Doesn't matter, not relevant

		end case;
	end process; -- End COMB_PROC
	
end FSM;

