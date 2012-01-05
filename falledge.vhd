library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity falledge is
	Port (	ABUS : out STD_LOGIC_VECTOR(15 downto 0);
			RAM : in STD_LOGIC_VECTOR(7 downto 0);
			RAM_OE : out STD_LOGIC;
            WR_D : out STD_LOGIC_VECTOR(7 downto 0);
            WR_EN : out STD_LOGIC;
			CLK : IN STD_LOGIC;
			RST : IN STD_LOGIC );
end falledge;

architecture FSM of falledge is

    type STATE_TYPE is (RESET, FETCH, ERR, READ, JR, JMP_HI, JMP_LO, WAI, PARAM, LD8, INCPC);
    type DBUS_SRC is (RAMDATA, RFDATA, ACCDATA, TMPDATA);

    signal CS, NS: STATE_TYPE;

    -- For wait cycles
    signal w_en  : STD_LOGIC;
    signal waits : STD_LOGIC_VECTOR(4 downto 0);
    signal tics  : STD_LOGIC_VECTOR(4 downto 0);

    signal DMUX : DBUS_SRC;
    signal DBUS : STD_LOGIC_VECTOR(7 downto 0);

    signal CMD    : STD_LOGIC_VECTOR(7 downto 0);
    signal CMD_CE : STD_LOGIC;

    -- Either this or an independent 8-bit output from the register file
    signal tmp : std_logic_vector(7 downto 0);
    signal tmp_ce : std_logic;

    signal acc : STD_LOGIC_VECTOR(7 downto 0);
    signal acc_ce : std_logic;

    component regfile16bit
	    Port (  idata : in std_logic_vector(7 downto 0);
	            odata : out std_logic_vector(7 downto 0);
                addr : out std_logic_vector(15 downto 0);
                imux : in std_logic_vector(2 downto 0);
                omux : in std_logic_vector(2 downto 0);
                dmux : in std_logic_vector(2 downto 0);
                amux : in std_logic_vector(1 downto 0);
                ce : in std_logic_vector(1 downto 0);
                CLK : IN STD_LOGIC;
                RST : IN STD_LOGIC );
    end component;

	signal rf_idata : std_logic_vector(7 downto 0);
	signal rf_odata : std_logic_vector(7 downto 0);
    signal rf_addr : std_logic_vector(15 downto 0);
    signal rf_imux : std_logic_vector(2 downto 0);
    signal rf_omux : std_logic_vector(2 downto 0);
    signal rf_dmux : std_logic_vector(2 downto 0);
    signal rf_amux : std_logic_vector(1 downto 0);
    signal rf_ce : std_logic_vector(1 downto 0);

begin

    urf : regfile16bit
        port map (rf_idata, rf_odata, rf_addr, rf_imux, rf_omux, rf_dmux, rf_amux, rf_ce, CLK, RST);

    ABUS <= rf_addr;

    DBUS <= rf_odata    when DMUX = RFDATA else
            acc         when DMUX = ACCDATA else
            tmp         when DMUX = TMPDATA else
            RAM;

    rf_idata <= DBUS;
    WR_D <= DBUS;

    acc_proc : process(CLK, RST)
	begin
		if RST = '1' then
			acc <= "00000000";
		elsif falling_edge(CLK) then
			if acc_ce = '1' then
				acc <= DBUS;
			end if;
		end if;
	end process;

    tmp_proc : process(CLK, RST)
	begin
		if (RST = '1') then
			tmp <= "00000000";
		elsif (falling_edge(CLK)) then
			if (tmp_ce = '1') then
				tmp <= DBUS;
			end if;
		end if;
	end process;

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

	SYNC_PROC: process (clk, rst)
	begin
		if (rst = '1') then
			CS <= RESET;
			waits <= "00000";
		elsif (falling_edge(clk)) then
			CS <= NS;
			if w_en = '0' then
				waits <= "00000";
			elsif w_en = '1' then
                if CS = wai then -- waiting
					waits <= waits - "00001";
                elsif NS = WAI then    -- preparing to wait
					waits <= tics;
				end if;
			end if;
		end if;
	end process; --End SYNC_PROC

	COMB_PROC: process (CS, DBUS, waits)
	begin

        DMUX <= RAMDATA;    -- RAM on DBUS
        RAM_OE <= '1';	    -- RAM on DBUS

        rf_imux <= "100";   -- rf input to PC
        rf_omux <= "100";   -- rf output from PC
        rf_dmux <= "000";   -- rf 8-bit output from H
        rf_amux <= "11";    -- rf operand '+1'
        rf_ce <= "00";      -- No change to register file

        w_en <= '0';
        tics <= "00000";

        CMD_CE <= '0';	-- Preserve CMD
        tmp_ce <= '0';  -- Preserve tmp
        acc_ce <= '0';  -- Preserve acc

        WR_EN <= '0';   -- Don't edit RAM

        NS <= ERR;

		case CS is
			when RESET =>
				NS <= FETCH;

				w_en <= '0';	-- Continue waiting
				
			when FETCH =>
                rf_ce <= "11";  -- Save incremented PC
                CMD_CE <= '1';	-- Save the command at the end of the state

                if ( DBUS = "00000000" ) then     -- 00 NOP
                    NS <= WAI;
                    tics <= "00010";	-- 3 tics
                    w_en <= '1';
                elsif ( DBUS = "00011000" ) then  -- 18 JR n
                    NS <= JR;
                elsif ( DBUS = "11000011" ) then  -- C3 JMP nn
                    NS <= READ;
                elsif ( DBUS = "01110110" ) then -- 76 HALT
                    NS <= ERR;
                elsif ( (DBUS(7) xor DBUS(6)) = '1' ) then  -- 8-bit ops
                    NS <= LD8;
                elsif (DBUS(2 downto 0) = "110" ) then  -- 8-bit ops
                    NS <= LD8;
                else
                    ns <= ERR;
                end if;

           when PARAM =>  -- Gives RAM output a chance to go HiZ if needed
                NS <= LD8;
                if ( CMD(2 downto 0) /= "110" ) then  -- not reading from (HL) or (PC), so A or rf
                    RAM_OE <= '0';
                end if;

            when LD8 =>
                NS <= WAI;
                tics <= "00001";    -- 2 tics
                w_en <= '1';

                -- Destination register
                rf_imux <= '0' & CMD(5 downto 4);
                if ( CMD(5 downto 4) /= "11" ) then -- Target is rf
                    rf_ce(1) <= not CMD(3);
                    rf_ce(0) <= CMD(3);
                elsif ( CMD(3) /= '1' ) then -- Target is RAM
                    rf_omux <= "010";   -- (HL)
                    WR_EN <= '1';       -- Enable RAM write
                    tics <= "00101";    -- 6 tics
                    w_en <= '1';
                else    -- Target is accumulator
                    acc_ce <= '1';
                end if;

                -- Source register
                rf_dmux <= CMD(2 downto 0);
                case CMD(2 downto 0) is
                    when "110" =>   -- Source is RAM
                        DMUX <= RAMDATA;
                        RAM_OE <= '1';
                        if ( (CMD(7) xor CMD(6)) = '1' ) then
                            rf_omux <= "010";   -- HL as rf_addr
                            tics <= "00101";    -- 6 tics
                        else
                            rf_omux <= "100";   -- PC as rf_addr
                            NS <= INCPC;
                            tics <= "00100";    -- 5 tics
                        end if;
                        w_en <= '1';
                    when "111" =>   -- Source is accumulator
                        DMUX <= ACCDATA;
                    when others =>  -- Source is rf
                        DMUX <= RFDATA;
                end case;

            when INCPC =>
                rf_ce   <= "11";    -- 16-bit update
                if ( w_en = '1' ) then
                    NS <= WAI;
                    w_en <= '1';
                    tics <= tics;
                else
                    NS <= FETCH;
                end if;

            when JR =>

                -- PC currently points to the second byte of the operand. If
                --  relative jumps are from the first byte of the following
                --  operand, we also need to increment PC once.
                NS <= INCPC;

                rf_amux <= "00";    -- PC + n
                rf_ce   <= "11";    -- 16-bit update

                tics <= "00100";    -- 5 tics
                w_en <= '1';

			when READ =>
				NS <= JMP_HI;

                tmp_ce <= '1';  -- Store byte in tmp
                rf_ce <= "11";  -- 16-bit update

			when JMP_HI =>
				-- Jump target read, now store as two 8-bit loads
				NS <= JMP_LO;

                rf_ce <= "10";  -- Update msB from DBUS (linked to RAM)

            when JMP_LO =>
				NS <= WAI;
                tics <= "00111";    -- 8 tics
                w_en <= '1';

                DMUX <= TMPDATA;
                rf_ce <= "01";  -- Update lsB from DBUS (linked to tmp)

			when WAI =>
				NS <= WAI;

				w_en <= '1';	-- Continue waiting
				
				if waits = "00000" then
					NS <= FETCH;
					w_en <= '0';
				end if;
				
			when ERR =>
				NS <= ERR;

		end case;
	end process; -- End COMB_PROC
	
end FSM;

