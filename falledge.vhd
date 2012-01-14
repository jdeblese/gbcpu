library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity falledge is
    Port (  ABUS : out STD_LOGIC_VECTOR(15 downto 0);
            RAM : in STD_LOGIC_VECTOR(7 downto 0);
            RAM_OE : out STD_LOGIC;
            WR_D : out STD_LOGIC_VECTOR(7 downto 0);
            WR_EN : out STD_LOGIC;
            CLK : IN STD_LOGIC;
            RST : IN STD_LOGIC );
end falledge;

architecture FSM of falledge is

    type STATE_TYPE is (RESET, FETCH, ERR, INCPC, WAI,
                        READ, JR, JMP_HI, JMP_LO,
                        LD16_A, LD16_1ST, LD16_B, LD16_2ND, LD16_C,
                        CALL1, CALL2, CALL3, CALL4, CALL5, CALL6, RET1, RET2, RET3, RET4,
                        OP16, LD8, ST8,
                        LDSADDR0, LDSADDR1, LSADDR2,
                        ALU8, LOADACC, INCDEC8, LOADRF,
                        BITFETCH, BITMANIP, BITSAVE);
    type DBUS_SRC is (RAMDATA, RFDATA, ACCDATA, ALUDATA, TMPDATA, UNQDATA, ZERODATA);
    type ABUS_SRC is (RFADDR, RF8ADDR, TMP8ADDR, TMP16ADDR);

    signal CS, NS: STATE_TYPE;

    -- For wait cycles
    signal waits : STD_LOGIC_VECTOR(4 downto 0);
    signal tics  : STD_LOGIC_VECTOR(4 downto 0);

    signal DMUX : DBUS_SRC;
    signal DBUS : STD_LOGIC_VECTOR(7 downto 0);

    signal AMUX : ABUS_SRC;

    signal CMD    : STD_LOGIC_VECTOR(7 downto 0);
    signal CMD_CE : STD_LOGIC;

    signal tmp : std_logic_vector(7 downto 0);
    signal tmp_ce : std_logic;
    signal unq : std_logic_vector(7 downto 0);
    signal unq_ce : std_logic;

    signal acc : STD_LOGIC_VECTOR(7 downto 0);
    signal acc_ce : std_logic;

    signal cflag, zflag, hflag, nflag : std_logic;
    signal cf_ce, zf_ce, hf_ce, nf_ce : std_logic;

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

    signal rf_idata : std_logic_vector(7 downto 0);
    signal rf_odata : std_logic_vector(7 downto 0);
    signal rf_addr : std_logic_vector(15 downto 0);
    signal rf_imux : std_logic_vector(2 downto 0);
    signal rf_omux : std_logic_vector(2 downto 0);
    signal rf_dmux : std_logic_vector(3 downto 0);
    signal rf_amux : std_logic_vector(1 downto 0);
    signal rf_ce : std_logic_vector(1 downto 0);

    component alu
        Port (  IDATA   : in std_logic_vector(7 downto 0);
                ACC     : in std_logic_vector(7 downto 0);
                ODATA   : out std_logic_vector(7 downto 0);
                CE      : in std_logic;
                CMD     : in std_logic_vector(8 downto 0);
                ZIN     : in std_logic;
                CIN     : in std_logic;
                HIN     : in std_logic;
                NIN     : in std_logic;
                ZOUT    : out std_logic;
                COUT    : out std_logic;
                HOUT    : out std_logic;
                NOUT    : out std_logic;
                CLK : IN STD_LOGIC;
                RST : IN STD_LOGIC );
    end component;

    signal ALU_ODATA   : std_logic_vector(7 downto 0);
    signal ALU_CE      : std_logic;
    signal ALU_CMD     : std_logic_vector(8 downto 0);
    signal ALU_ZIN     : std_logic;
    signal ALU_CIN     : std_logic;
    signal ALU_HIN     : std_logic;
    signal ALU_NIN     : std_logic;
    signal ALU_ZOUT    : std_logic;
    signal ALU_COUT    : std_logic;
    signal ALU_HOUT    : std_logic;
    signal ALU_NOUT    : std_logic;

begin

    urf : regfile16bit
        port map (rf_idata, rf_odata, rf_addr, rf_imux, rf_omux, rf_dmux, rf_amux, rf_ce, CLK, RST);

    ualu : alu
        port map (DBUS, acc, ALU_ODATA, ALU_CE, ALU_CMD, zflag, cflag, hflag, nflag, ALU_ZOUT, ALU_COUT, ALU_HOUT, ALU_NOUT, CLK, RST);

    ABUS <= rf_addr when AMUX = RFADDR else
            X"FF" & tmp when AMUX = TMP8ADDR else
            tmp & unq when AMUX = TMP16ADDR else
            X"0000";

    DBUS <= rf_odata    when DMUX = RFDATA else
            acc         when DMUX = ACCDATA else
            tmp         when DMUX = TMPDATA else
            unq         when DMUX = UNQDATA else
            RAM         when DMUX = RAMDATA else
            ALU_ODATA   when DMUX = ALUDATA else
            X"00";

    rf_idata <= DBUS;
    WR_D <= DBUS;

    acc_proc : process(CLK, RST)
    begin
        if RST = '1' then
            acc <= X"EE";
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

    unq_proc : process(CLK, RST)
    begin
        if (RST = '1') then
            unq <= "00000000";
        elsif (falling_edge(CLK)) then
            if (unq_ce = '1') then
                unq <= DBUS;
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

    wait_proc : process(CLK, RST)
    begin
        if rst = '1' then
            waits <= "00000";
        elsif falling_edge(clk) then
            if CS = FETCH then
                waits <= tics;
            else
                waits <= waits - "00001";
            end if;
        end if;
    end process;

    SYNC_PROC: process (clk, rst)
    begin
        if (rst = '1') then
            CS <= RESET;
        elsif (falling_edge(clk)) then
            CS <= NS;
        end if;
    end process; --End SYNC_PROC

    COMB_PROC: process (RST, CS, DBUS, CMD, waits)
    begin

        AMUX <= RFADDR;     -- Address from rf
        DMUX <= RAMDATA;    -- RAM on DBUS
        RAM_OE <= '1';      -- RAM on DBUS

        rf_imux <= "100";   -- rf input to PC
        rf_omux <= "100";   -- rf output from PC
        rf_dmux <= "0000";  -- rf 8-bit output from H
        rf_amux <= "11";    -- rf operand '+1'
        rf_ce <= "00";      -- No change to register file

        tics <= "00000";

        CMD_CE <= '0';  -- Preserve CMD
        tmp_ce <= '0';  -- Preserve tmp
        unq_ce <= '0';  -- Preserve unq
        acc_ce <= '0';  -- Preserve acc

        ALU_CMD <= "000000000";
        ALU_CE <= '0';

        WR_EN <= '0';   -- Don't edit RAM

        NS <= ERR;

        case CS is
            when RESET =>
                if RST = '0' then
                    NS <= FETCH;
                    DMUX <= ZERODATA;
                    rf_omux <= "111";   -- X"0000"
                    rf_amux <= "00";    -- + dbus
                    rf_ce   <= "11";    -- 16-bit update

                else
                    NS <= RESET;
                end if;

            when FETCH =>
                rf_ce <= "11";  -- Save incremented PC
                CMD_CE <= '1';  -- Save the command at the end of the state

                if ( DBUS = "00000000" ) then                                           -- 00h NOP
                    NS <= WAI;
                    tics <= "00010";                                                    -- 4 tics
                elsif DBUS = X"18"                                                      -- JR
                    or ( DBUS(7 downto 5) = "001" and DBUS(2 downto 0) = "000" ) then   -- Conditional JR
                    NS <= JR;
                    tics <= "00110";    -- 8 tics
                elsif DBUS = X"C3" then                                                 -- C3h JMP nn
                    NS <= READ;
                    tics <= "01010";    -- 12 tics
                elsif DBUS = X"76" then                                                 -- 76h HALT
                    NS <= ERR;
                elsif DBUS = X"CB" then                                                 -- Bit Manipulations
                    NS <= BITFETCH;
                    if DBUS(2 downto 0) = "110" then    -- src/target is (HL)
                        tics <= "01110";    -- 16 tics
                    else
                        tics <= "00110";    -- 8 tics
                    end if;
                elsif DBUS(7 downto 5) = "000" and DBUS(2 downto 0) = "111" then        -- RLCA, RLA, RRCA, RRA
                    NS <= BITMANIP;
                    tics <= "00010";    -- 4 tics
                elsif DBUS(7 downto 6) = "01" then                                      -- 8-bit loads 40h-7Fh
                    NS <= LD8;
                    if DBUS(2 downto 0) = "110" then    -- source is (HL)
                        tics <= "00110";    -- 8 tics
                    elsif DBUS(5 downto 3) = "110" then  -- target is (HL)
                        tics <= "00110";    -- 8 tics
                    else
                        tics <= "00010";    -- 4 tics
                    end if;
                elsif DBUS(7 downto 6) = "00" and DBUS(2 downto 0) = "110" then         -- 8-bit immediate loads
                    NS <= LD8;
                    if DBUS(5 downto 3) = "110" then    -- target is (HL)
                        tics <= "01010";    -- 12 tics
                    else
                        tics <= "00110";    -- 8 tics
                    end if;
                elsif DBUS(7 downto 6) = "00" and DBUS(2 downto 0) = "010" then         -- 8-bit memory loads
                    NS <= LD8;
                    tics <= "00110";    -- 8 tics
                elsif DBUS(7 downto 5) = "111" and DBUS(3 downto 2) = "00" and DBUS(0) = '0' then   -- 8-bit loads from 8-bit addresses
                    NS <= LDSADDR1;
                    if DBUS(1) = '0' then   -- immediate address
                        tics <= "01010";    -- 12 tics
                    else                    -- register address
                        tics <= "00110";    -- 8 tics
                    end if;
                elsif DBUS(7 downto 5) = "111" and DBUS(3 downto 0) = "1010" then       -- 8-bit loads from 16-bit addresses
                    NS <= LDSADDR0;
                    tics <= "01110";    -- 16 tics
                elsif DBUS(7 downto 6) = "10"                                           -- 8-bit alu ops 80h-BFh
                    or ( DBUS(7 downto 6) = "11" and DBUS(2 downto 0) = "110" ) then    -- 8-bit alu ops with immediate
                    NS <= ALU8;
                    if DBUS(2 downto 0) = "110" then    -- source is (HL) or (PC)
                        tics <= "00110";    -- 8 tics
                    else
                        tics <= "00010";    -- 4 tics
                    end if;
                elsif DBUS = X"CD" then                     -- CALL
                    NS <= CALL1;
                    tics <= "01010";    -- 12 tics
                elsif DBUS = X"C9" then                     -- RET
                    NS <= RET1;
                    tics <= "00110";    -- 8 tics
                elsif DBUS(7 downto 6) = "00" and DBUS(2 downto 1) = "10" then  -- Inc & Dec
                    NS <= INCDEC8;
                    if DBUS(5 downto 3) = "110" then    -- target is (HL)
                        tics <= "01010";    -- 12 tics
                    else
                        tics <= "00010";    -- 4 tics
                    end if;
                elsif DBUS(7 downto 6) = "00"
                    and ( DBUS(3 downto 0) = "1001" or DBUS(2 downto 0) = "011" ) then  -- 16-bit alu ops (ADD, INC, DEC)
                    NS <= OP16;
                    tics <= "00110";    -- 8 tics
                elsif DBUS(3 downto 0) = "0001" then        -- 16-bit lodds and pops
                    NS <= LD16_A;
                    tics <= "01010";    -- 12 tics
                elsif DBUS(3 downto 0) = "0101" and DBUS(7 downto 6) = "11" then     -- 16-bit pushes
                    NS <= LD16_A;
                    tics <= "01110";    -- 16 tics
--              elsif (DBUS(1 downto 0) = "10" ) then       -- 8-bit ops
--                  NS <= LD8;
                else
                    ns <= ERR;
                end if;

            when BITFETCH =>
                NS <= BITMANIP;
                rf_ce <= "11";  -- Save incremented PC
                CMD_CE <= '1';  -- Save the command at the end of the state, overwriting CBh

            when BITMANIP =>
                NS <= BITSAVE;

                -- Register
                rf_dmux <= '0' & CMD(2 downto 0);
                case CMD(2 downto 0) is
                    when "110" =>   -- Source is (HL)
                        DMUX <= RAMDATA;
                        RAM_OE <= '1';
                        rf_omux <= "010";   -- HL
                    when "111" =>   -- Source is accumulator
                        DMUX <= ACCDATA;
                    when others =>  -- Source is rf
                        DMUX <= RFDATA;
                end case;

                ALU_CE <= '1';
                ALU_CMD <= '1' & CMD;

            when BITSAVE =>
                NS <= WAI;

                DMUX <= ALUDATA;

                -- Register
                rf_imux <= '0' & CMD(2 downto 1);
                case CMD(2 downto 0) is
                    when "000" => rf_ce <= "10";
                    when "001" => rf_ce <= "01";
                    when "010" => rf_ce <= "10";
                    when "011" => rf_ce <= "01";
                    when "100" => rf_ce <= "10";
                    when "101" => rf_ce <= "01";
                    when "110" =>   -- Dest. is (HL)
                        rf_omux <= "010";   -- HL
                        WR_EN <= '1';
                    when "111" => acc_ce <= '1';
                    when others =>
                        null;
                end case;

                zflag <= ALU_ZOUT;
                hflag <= ALU_HOUT;
                nflag <= ALU_NOUT;
                cflag <= ALU_COUT;

            when OP16 =>
                NS <= WAI;

                if CMD(1) = '1' then    -- INC or DEC
                    rf_amux <= '1' & not CMD(3);
                    rf_imux <= '0' & CMD(5 downto 4);
                    rf_omux <= '0' & CMD(5 downto 4);
                    rf_ce <= "11";
                else    -- ADD
                    rf_amux <= "01";    -- Second source is HL
                    rf_imux <= "010";   -- Target is HL
                    rf_omux <= '0' & CMD(5 downto 4);
                    rf_ce <= "11";
                end if;

            when LD16_A =>
                NS <= LD16_1ST;
                if CMD(7 downto 6) = "11" and CMD(3 downto 2) = "01" then    -- PUSH
                    rf_ce   <= "11";    -- 16-bit update
                    rf_omux <= "011";   -- SP
                    rf_imux <= "011";
                    rf_amux <= "10";    -- rf operand '-1'
                end if;

            when LD16_1ST =>
                NS <= LD16_B;

                -- msB pushed first, so lsB popped first

                -- Target is lsB of 16-bit register or (SP) (set later)
                -- Source is (PC), (SP) or the msB of a 16-bit register
                if CMD(7 downto 6) = "11" and CMD(3 downto 2) = "00" then    -- POP
                    -- src
                    rf_omux <= "011";   -- SP
                    -- dst
                    if CMD(5 downto 4) = "11" then  -- POP AF
                        NS <= ERR;  -- Not yet implemented
                    else
                        rf_imux <= '0' & CMD(5 downto 4);
                        rf_ce <= "01";  -- lsB
                    end if;
                elsif CMD(7 downto 6) = "11" and CMD(3 downto 2) = "01" then -- PUSH
                    -- src
                    if CMD(5 downto 4) = "11" then  -- PUSH AF
                        DMUX <= ACCDATA;
                    else
                        DMUX <= RFDATA;
                        rf_dmux(0) <= '0'; -- msB
                        rf_dmux(2 downto 1) <= CMD(5 downto 4);
                    end if;
                    -- dst
                    rf_omux <= "011";   -- SP
                    WR_EN <= '1';       -- Enable RAM write
                else    -- LD
                    -- src is (PC)
                    -- dst
                    rf_imux <= '0' & CMD(5 downto 4);
                    rf_ce <= "01";  -- lsB
                end if;

            when LD16_B =>
                NS <= LD16_2ND;
                rf_ce   <= "11";    -- 16-bit update
                if CMD(7 downto 6) = "11" and CMD(3) = '0' then  -- PUSH/POP
                    rf_omux <= "011";   -- SP
                    rf_imux <= "011";
                    if CMD(2) = '1' then    -- PUSH
                        rf_amux <= "10";    -- rf operand '-1'
                    end if;
                end if; -- Otherwise, PC must be incremented

            when LD16_2ND =>
                NS <= LD16_C;

                -- Target is msB of 16-bit register or (SP) (set later)
                -- Source is (PC), (SP) or the lsB of a 16-bit register
                if CMD(7 downto 6) = "11" and CMD(3 downto 2) = "00" then    -- POP
                    -- src
                    rf_omux <= "011";   -- SP
                    -- dst
                    if CMD(5 downto 4) = "11" then  -- POP AF
                        acc_ce <= '1';
                    else
                        rf_imux <= '0' & CMD(5 downto 4);
                        rf_ce <= "10";  -- msB
                    end if;
                elsif CMD(7 downto 6) = "11" and CMD(3 downto 2) = "01" then -- PUSH
                    -- src
                    if CMD(5 downto 4) = "11" then  -- PUSH AF
                        DMUX <= ACCDATA;
                    else
                        DMUX <= RFDATA;
                        rf_dmux(0) <= '1'; -- lsB
                        rf_dmux(2 downto 1) <= CMD(5 downto 4);
                    end if;
                    -- dst
                    rf_omux <= "011";   -- Target is (SP)
                    WR_EN <= '1';       -- Enable RAM write
                else
                    -- src is (PC)
                    -- dst
                    rf_imux <= '0' & CMD(5 downto 4);
                    rf_ce <= "10";  -- msB
                end if;

            when LD16_C =>
                NS <= WAI;

                rf_ce   <= "11";    -- 16-bit update
                if CMD(7 downto 6) = "11" and CMD(3 downto 2) = "00" then    -- POP
                    rf_omux <= "011";   -- SP
                    rf_imux <= "011";
                elsif CMD(7 downto 6) = "11" and CMD(3 downto 2) = "01" then -- PUSH
                    rf_ce   <= "00";    -- No update needed
                end if; -- Otherwise, PC must be incremented

            when LD8 =>
                NS <= ST8;

                -- Destination register
                tmp_ce <= '1';

                -- Source register
                rf_dmux <= '0' & CMD(2 downto 0);
                case CMD(2 downto 0) is
                    when "010" =>   -- Source is RAM or ACC if left column op, otherwise rf
                        case CMD(7 downto 6) is
                            when "00" =>
                                case CMD(3) is
                                    when '1' => DMUX <= RAMDATA;
                                    when others => DMUX <= ACCDATA;
                                end case;
                            when others =>
                                DMUX <= RFDATA;
                        end case;
                    when "110" =>   -- Source is RAM
                        DMUX <= RAMDATA;
                        RAM_OE <= '1';
                        if ( (CMD(7) xor CMD(6)) = '1' ) then
                            rf_omux <= "010";   -- HL as rf_addr
                        else
                            rf_ce   <= "11";    -- 16-bit update
                        end if;
                    when "111" =>   -- Source is accumulator
                        DMUX <= ACCDATA;
                    when others =>  -- Source is rf
                        DMUX <= RFDATA;
                end case;

            when ST8 =>
                NS <= WAI;

                -- Source register
                DMUX <= TMPDATA;

                -- Destination register
                rf_imux <= '0' & CMD(5 downto 4);
                if CMD(2 downto 0) = "010" then -- LD A,(..) or LD (..),A
                    -- Set the address
                    if CMD(5) = '0' then
                        rf_omux <= "00" & CMD(4);
                    elsif CMD(5) = '1' then    -- Set up incrementing or decrementing HL
                        rf_omux <= "010";   -- HL
                        rf_imux <= "010";
                        rf_amux <= '1' & not CMD(4);    -- INC or DEC HL
                        rf_ce <= "11";
                    end if;
                    -- Set the target
                    if CMD(3) = '1' then
                        acc_ce <= '1';
                    elsif CMD(3) = '0' then
                        WR_EN <= '1';
                    end if;
                elsif CMD(5 downto 4) = "11" then   -- LD (HL),r or LD A,r
                    if CMD(3) = '1' then
                        acc_ce <= '1';
                    else
                        rf_omux <= "010";   -- HL
                        WR_EN <= '1';
                    end if;
                else    -- target is in rf
                    rf_ce(1) <= not CMD(3);
                    rf_ce(0) <= CMD(3);
                end if;

            when ALU8 =>
                NS <= LOADACC;

                -- Destination register
                ALU_CE <= '1';
                ALU_CMD <= '0' & CMD;

                -- Source register
                rf_dmux <= '0' & CMD(2 downto 0);
                case CMD(2 downto 0) is
                    when "110" =>   -- Source is RAM
                        DMUX <= RAMDATA;
                        RAM_OE <= '1';
                        if CMD(7 downto 6) = "10" then
                            rf_omux <= "010";   -- HL as rf_addr
                        else
                            rf_omux <= "100";   -- PC as rf_addr
                            rf_ce <= "11";      -- 16-bit update
                        end if;
                    when "111" =>   -- Source is accumulator
                        DMUX <= ACCDATA;
                    when others =>  -- Source is rf
                        DMUX <= RFDATA;
                end case;

            when LOADACC =>
                DMUX <= ALUDATA;
                acc_ce   <= '1';
                NS <= WAI;

                zflag <= ALU_ZOUT;
                hflag <= ALU_HOUT;
                nflag <= ALU_NOUT;
                cflag <= ALU_COUT;

            when LDSADDR0 =>
                NS <= LDSADDR1;

                -- Store address lsB in unq
                unq_ce <= '1';

                rf_ce <= "11";  -- Increment PC

            when LDSADDR1 =>
                NS <= LSADDR2;

                -- Store address byte in tmp (lsB for 8-bit addr, msB for 16-bit)
                tmp_ce <= '1';
                if CMD(3) = '0' and CMD(1) = '1' then   -- Address is FFh + C
                    DMUX <= RFDATA;
                    rf_dmux <= "0001";  -- C
                else
                    rf_ce <= "11";  -- Increment PC
                end if;

            when LSADDR2 =>
                NS <= WAI;

                if CMD(3) = '0' then
                    AMUX <= TMP8ADDR;
                else
                    AMUX <= TMP16ADDR;
                end if;

                -- Destination register
                -- Source register
                if CMD(4) = '1' then
                    ACC_CE <= '1';
                else
                    WR_EN <= '1';
                    DMUX <= ACCDATA;
                end if;

            when INCDEC8 =>
                NS <= LOADRF;

                -- Destination register
                ALU_CE <= '1';
                ALU_CMD <= '0' & CMD;

                -- Source register
                case CMD(5 downto 3) is
                    when "110" =>   -- (HL)
                        rf_omux <= "010";   -- HL
                    when "111" =>   -- ACC
                        DMUX <= ACCDATA;
                    when others =>  -- rf
                        DMUX <= RFDATA;
                        rf_dmux <= '0' & CMD(5 downto 3);
                end case;

            when LOADRF =>
                NS <= WAI;

                -- Destination register
                case CMD(5 downto 3) is
                    when "110" =>   -- (HL)
                        rf_omux <= "010";   -- HL
                        WR_EN <= '1';
                    when "111" =>   -- ACC
                        acc_ce <= '1';
                    when others =>  -- rf
                        case CMD(3) is
                            when '0' => rf_ce <= "10";
                            when '1' => rf_ce <= "01";
                            when others => rf_ce <= "ZZ";
                        end case;
                        rf_imux <= '0' & CMD(5 downto 4);
                end case;

                -- Source register
                DMUX <= ALUDATA;

                zflag <= ALU_ZOUT;
                hflag <= ALU_HOUT;
                nflag <= ALU_NOUT;

            when INCPC =>
                rf_ce   <= "11";    -- 16-bit update
                if waits /= "00000" then
                    NS <= WAI;
                else
                    NS <= FETCH;
                end if;

            when JR =>

                -- PC currently points to the second byte of the operand. If
                --  relative jumps are from the first byte of the following
                --  operand, we also need to increment PC once.
                NS <= INCPC;

                rf_amux <= "00";    -- PC + n

                -- Update is conditional
                if CMD = X"18"                                      -- JR
                    or ( CMD(4) = '0' and zflag = CMD(3) )          -- JRNZ, JRZ
                    or ( CMD(4) = '1' and cflag = CMD(3) ) then     -- JRNC, JRC
                    rf_ce   <= "11";    -- 16-bit update
                end if;

            when RET1 =>
                NS <= RET2;

                -- msB pushed first, so lsB popped first
                rf_omux <= "011";   -- SP
                rf_imux <= "100";   -- PC
                rf_ce <= "01";      -- lsB

            when RET2 =>
                NS <= RET3;
                rf_ce   <= "11";    -- 16-bit update
                rf_omux <= "011";   -- SP
                rf_imux <= "011";

            when RET3 =>
                NS <= RET4;

                rf_omux <= "011";   -- SP
                rf_imux <= "100";   -- PC
                rf_ce <= "10";      -- msB

            when RET4 =>
                NS <= WAI;

                rf_ce   <= "11";    -- 16-bit update
                rf_omux <= "011";   -- SP
                rf_imux <= "011";

            when CALL1 =>   -- tmp <= (PC++)
                NS <= CALL2;

                tmp_ce <= '1';  -- Store lsB in tmp
                rf_ce <= "11";  -- 16-bit update

            when CALL2 =>   -- unq <= (PC++)
                NS <= CALL3;

                unq_ce <= '1';  -- Store msB in unq
                rf_ce <= "11";  -- Update msB from DBUS (linked to RAM)

            when CALL3 =>   -- SP--
                NS <= CALL4;
                rf_ce   <= "11";    -- 16-bit update
                rf_omux <= "011";   -- SP
                rf_imux <= "011";
                rf_amux <= "10";    -- rf operand '-1'

            when CALL4 =>   -- (SP--) <= [PC]msB
                NS <= CALL5;
                -- src
                DMUX <= RFDATA;
                rf_dmux <= "1000";  -- msB of PC
                -- dst
                rf_omux <= "011";   -- SP
                WR_EN <= '1';       -- Enable RAM write
                -- decrement
                rf_ce   <= "11";    -- 16-bit update
                rf_imux <= "011";
                rf_amux <= "10";    -- rf operand '-1'

            when CALL5 =>   -- (SP) <= [PC]lsB
                NS <= CALL6;
                -- src
                DMUX <= RFDATA;
                rf_dmux <= "1001";  -- lsB of PC
                -- dst
                rf_omux <= "011";   -- SP
                WR_EN <= '1';       -- Enable RAM write

            when CALL6 =>   -- [PC]msB <= unq
                NS <= JMP_LO;
                DMUX <= UNQDATA;
                rf_ce <= "10";  -- Update lsB from DBUS (linked to unq)

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

                DMUX <= TMPDATA;
                rf_ce <= "01";  -- Update lsB from DBUS (linked to tmp)

            when WAI =>
                NS <= WAI;

                if waits = "00000" then
                    NS <= FETCH;
                end if;

            when ERR =>
                NS <= ERR;

        end case;
    end process; -- End COMB_PROC

end FSM;

