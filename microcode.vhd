library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity microcode is
    Port (  ABUS : buffer STD_LOGIC_VECTOR(15 downto 0);
            RAM : in STD_LOGIC_VECTOR(7 downto 0);
            RAM_OE : out STD_LOGIC;
            WR_D : out STD_LOGIC_VECTOR(7 downto 0);
            RAM_WR : out STD_LOGIC;
            CLK : IN STD_LOGIC;
            RST : IN STD_LOGIC );
end microcode;

architecture FSM of microcode is

    type STATE_TYPE is (RESET, RUN, ERR, INCPC, WAI,
                        READ, JR, JMP_HI, JMP_LO,
                        LD16_A, LD16_1ST, LD16_B, LD16_2ND, LD16_C,
                        CALL1, CALL2, CALL3, CALL4, CALL5, CALL6, RET1, RET2, RET3, RET4,
                        OP16, LD8, ST8,
                        LDSADDR0, LDSADDR1, LSADDR2,
                        ALU8, LOADACC, INCDEC8, LOADRF, CARRY,
                        BITRUN, BITMANIP, BITSAVE);
    type DBUS_SRC is (RAMDATA, RFDATA, ACCDATA, ALUDATA, TMPDATA, UNQDATA, FSMDATA);
    type ABUS_SRC is (RFADDR, RF8ADDR, TMP8ADDR, TMP16ADDR);

    signal CS, NS: STATE_TYPE;

    -- For wait cycles
    signal waits : STD_LOGIC_VECTOR(4 downto 0);
    signal tics  : STD_LOGIC_VECTOR(4 downto 0);

    signal DMUX : DBUS_SRC;
    signal DBUS : STD_LOGIC_VECTOR(7 downto 0);
    signal FIXED : STD_LOGIC_VECTOR(7 downto 0);

    signal AMUX : ABUS_SRC;

    signal WR_EN : STD_LOGIC;

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

    signal mcmd : std_logic_vector(51 downto 0);

    signal mc_addr : std_logic_vector(8 downto 0);
    signal mc_data : std_logic_vector(31 downto 0);
    signal mc_par : std_logic_vector(3 downto 0);

    signal rf_idata : std_logic_vector(7 downto 0);
    signal rf_odata : std_logic_vector(7 downto 0);
    signal rf_addr : std_logic_vector(15 downto 0);
    signal rf_imux : std_logic_vector(2 downto 0);
    signal rf_omux : std_logic_vector(2 downto 0);
    signal rf_dmux : std_logic_vector(3 downto 0);
    signal rf_amux : std_logic_vector(1 downto 0);
    signal rf_ce : std_logic_vector(1 downto 0);

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

    signal timer_int : std_logic;

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

    component timer
        Port (  DBUS    : inout std_logic_vector(7 downto 0);
                ABUS    : in std_logic_vector(15 downto 0);
                WR_EN   : in std_logic;
                INT     : out std_logic;
                CLK     : in std_logic;
                RST     : in std_logic );
    end component;

begin

    -- Internal Blocks --

    urf : regfile16bit
        port map (rf_idata, rf_odata, rf_addr, rf_imux, rf_omux, rf_dmux, rf_amux, rf_ce, CLK, RST);

    ualu : alu
        port map (DBUS, acc, ALU_ODATA, ALU_CE, ALU_CMD, zflag, cflag, hflag, nflag, ALU_ZOUT, ALU_COUT, ALU_HOUT, ALU_NOUT, CLK, RST);

--  utimer : timer
--      port map (DBUS, ABUS, WR_EN, timer_int, CLK, RST);

    -- Internal Registers --

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

    mcmd_proc : process(CLK, RST)
    begin
        if RST = '1' then
            mcmd <= "0000000000000000000000000000000000000000000111111111"; -- JMP FF micro-op
        elsif falling_edge(CLK) then
            mcmd <= "0000000000000000" & mc_par & mc_data; -- mbus
        end if;
    end process;

    -- Signal Routing --

    rf_idata <= DBUS;
    WR_D <= DBUS;
    RAM_WR <= WR_EN;

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
            FIXED       when DMUX = FSMDATA else
            X"00";

    mc_addr <= mcmd(8 downto 0) when mcmd(9) = '0' else
               "000000000";

    rf_omux <= mcmd(13 downto 11) when mcmd(10) = '0' else
               "000";

    rf_imux <= mcmd(17 downto 15) when mcmd(14) = '0' else
               "000";

    rf_amux <= mcmd(19 downto 18);

    rf_ce <= mcmd(21 downto 20);

    cmd_ce <= mcmd(22);

    -- Delay Timing --

    wait_proc : process(CLK, RST)
    begin
        if rst = '1' then
            waits <= "00000";
        elsif falling_edge(clk) then
            if CS = RUN then
                waits <= tics;
            else
                waits <= waits - "00001";
            end if;
        end if;
    end process;

    -- Defaults --

    AMUX <= RFADDR;     -- Address from rf
    DMUX <= RAMDATA;    -- RAM on DBUS
    RAM_OE <= '1';      -- RAM on DBUS

    rf_dmux <= "0000";  -- rf 8-bit output from H

    tics <= "00000";

    tmp_ce <= '0';  -- Preserve tmp
    unq_ce <= '0';  -- Preserve unq
    acc_ce <= '0';  -- Preserve acc

    ALU_CMD <= "000000000";
    ALU_CE <= '0';

    WR_EN <= '0';   -- Don't edit RAM

    FIXED <= X"00";

    -- Microcode Memory --
    umicro : RAMB16BWER
    generic map (
        DATA_WIDTH_A => 36,
        DATA_WIDTH_B => 36,
        DOA_REG => 0,
        DOB_REG => 0,
        EN_RSTRAM_A => TRUE,
        EN_RSTRAM_B => TRUE,
        INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_00 => X"0000000000000000000000000000000000000000000000000000000000000001",
        INIT_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_10 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_11 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_12 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_13 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
        INIT_3F => X"007e21fe000001fd000001fc000001ff00000000000000000000000000000000",
        INIT_FILE => "NONE",
        RSTTYPE => "SYNC",
        RST_PRIORITY_A => "CE",
        RST_PRIORITY_B => "CE",
        SIM_COLLISION_CHECK => "ALL",
        SIM_DEVICE => "SPARTAN6"
    )
    port map (
        -- Port A
        DOA => mc_data,  -- 32-bit output: A port data output
        DOPA => mc_par,  -- 4-bit output: A port parity output
        ADDRA => mc_addr & "00000",   -- 14-bit input: A port address input: 32-bit mode -> 9-bit address
        CLKA => CLK,      -- 1-bit input: A port clock input
        ENA => '1',       -- 1-bit input: A port enable input
        REGCEA => '0',    -- 1-bit input: A port register clock enable input
        RSTA => '0',      -- 1-bit input: A port register set/reset input
        WEA => "0000",    -- 4-bit input: Port A byte-wide write enable input
        DIA => X"00000000", -- 32-bit input: A port data input
        DIPA => "0000",   -- 4-bit input: A port parity input
        -- Port B
        ADDRB => "00000000000000",   -- 14-bit input: B port address input
        CLKB => '0',      -- 1-bit input: B port clock input
        ENB => '0',       -- 1-bit input: B port enable input
        REGCEB => '0',    -- 1-bit input: B port register clock enable input
        RSTB => '0',      -- 1-bit input: B port register set/reset input
        WEB => "0000",    -- 4-bit input: Port B byte-wide write enable input
        DIB => X"00000000", -- 32-bit input: B port data input
        DIPB => "0000"    -- 4-bit input: B port parity input
    );



end FSM;

