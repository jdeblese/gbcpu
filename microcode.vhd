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
            TCK : IN STD_LOGIC;
            TDL : IN STD_LOGIC;
            TDI : IN STD_LOGIC;
            TDO : OUT STD_LOGIC;
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

    signal DMUX : std_logic_vector(2 downto 0);
    signal DBUS : STD_LOGIC_VECTOR(7 downto 0);
    signal FIXED : STD_LOGIC_VECTOR(7 downto 0);

    signal AMUX : ABUS_SRC;

    signal WR_EN : STD_LOGIC;

    signal CMD    : STD_LOGIC_VECTOR(7 downto 0);
    signal CMD_CE : STD_LOGIC;
    signal LCMD   : STD_LOGIC_VECTOR(7 downto 0);

    signal tmp : std_logic_vector(7 downto 0);
    signal tmp_ce : std_logic;
    signal unq : std_logic_vector(7 downto 0);
    signal unq_ce : std_logic;

    signal acc : STD_LOGIC_VECTOR(7 downto 0);
    signal acc_ce : std_logic;
    signal lacc: std_logic_vector(7 downto 0);

    signal cflag, zflag, hflag, nflag : std_logic;
    signal cf_en, zf_en, hf_en, nf_en : std_logic;
    signal flagsrc : std_logic;

    signal caddr : std_logic_vector(7 downto 0);

    signal mc_addr : std_logic_vector(9 downto 0);
    signal mc_data0 : std_logic_vector(31 downto 0);
    signal mc_data1 : std_logic_vector(31 downto 0);
    signal mc_data2 : std_logic_vector(31 downto 0);
    signal mc_par0 : std_logic_vector(3 downto 0);
    signal mc_par1 : std_logic_vector(3 downto 0);
    signal mc_par2 : std_logic_vector(3 downto 0);

    signal rf_idata : std_logic_vector(7 downto 0);
    signal rf_odata : std_logic_vector(7 downto 0);
    signal rf_addr : std_logic_vector(15 downto 0);
    signal rf_imux : std_logic_vector(2 downto 0);
    signal rf_omux : std_logic_vector(2 downto 0);
    signal rf_dmux : std_logic_vector(3 downto 0);
    signal rf_amux : std_logic_vector(1 downto 0);
    signal rf_ce : std_logic_vector(1 downto 0);
    signal rf_zout : std_logic;
    signal rf_nout : std_logic;
    signal rf_hout : std_logic;
    signal rf_cout : std_logic;

    signal ALU_ODATA   : std_logic_vector(7 downto 0);
    signal ALU_CE      : std_logic;
    signal ALU_CMD     : std_logic_vector(5 downto 0);
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
                zout : out std_logic;
                nout : out std_logic;
                hout : out std_logic;
                cout : out std_logic;
                CLK : IN STD_LOGIC;
                RST : IN STD_LOGIC );
    end component;

    component alu
        Port (  IDATA   : in std_logic_vector(7 downto 0);
                ACC     : in std_logic_vector(7 downto 0);
                ODATA   : out std_logic_vector(7 downto 0);
                CE      : in std_logic;
                CMD     : in std_logic_vector(5 downto 0);
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

    -- Outshifter --

    process(TCK, RST)
    begin
        if RST = '1' then
            LCMD <= X"00";
            lacc <= X"00";
        elsif rising_edge(TCK) then
            if TDL = '1' then
                TDO <= CMD(7);
                LCMD <= CMD(6 downto 0) & acc(7);
                lacc <= acc(6 downto 0) & TDI;
            else
                TDO <= LCMD(7);
                LCMD <= LCMD(6 downto 0) & lacc(7);
                lacc <= lacc(6 downto 0) & TDI;
            end if;
        end if;
    end process;

    -- Internal Blocks --

    urf : regfile16bit
        port map (rf_idata, rf_odata, rf_addr, rf_imux, rf_omux, rf_dmux, rf_amux, rf_ce, rf_zout, rf_nout, rf_hout, rf_cout, CLK, RST);

    ualu : alu
        port map (DBUS, acc, ALU_ODATA, ALU_CE, ALU_CMD, zflag, cflag, hflag, nflag, ALU_ZOUT, ALU_COUT, ALU_HOUT, ALU_NOUT, CLK, RST);

--  utimer : timer
--      port map (DBUS, ABUS, WR_EN, timer_int, CLK, RST);

    -- Internal Registers --

    acc_proc : process(CLK, RST)
    begin
        if RST = '1' then
            acc <= X"AC";
        elsif rising_edge(CLK) then
            if acc_ce = '1' then
                acc <= DBUS;
            end if;
        end if;
    end process;

    tmp_proc : process(CLK, RST)
    begin
        if (RST = '1') then
            tmp <= "00000000";
        elsif (rising_edge(CLK)) then
            if (tmp_ce = '1') then
                tmp <= DBUS;
            end if;
        end if;
    end process;

    unq_proc : process(CLK, RST)
    begin
        if (RST = '1') then
            unq <= "00000000";
        elsif (rising_edge(CLK)) then
            if (unq_ce = '1') then
                unq <= DBUS;
            end if;
        end if;
    end process;

    CMD_PROC : process(CLK, RST)
    begin
        if (RST = '1') then
            CMD <= "00000000";
        elsif (rising_edge(CLK)) then
            if (CMD_CE = '1') then
                CMD <= DBUS;
            end if;
        end if;
    end process;

    process(CLK, RST)
    begin
        if (RST = '1') then
            zflag <= '0';
            nflag <= '0';
            hflag <= '0';
            cflag <= '0';
        elsif rising_edge(CLK) then
            if flagsrc = '0' then
                if zf_en = '1' then
                    zflag <= alu_zout;
                end if;
                if nf_en = '1' then
                    nflag <= alu_nout;
                end if;
                if hf_en = '1' then
                    hflag <= alu_hout;
                end if;
                if cf_en = '1' then
                    cflag <= alu_cout;
                end if;
            else
                if zf_en = '1' then
                    zflag <= rf_zout;
                end if;
                if nf_en = '1' then
                    nflag <= rf_nout;
                end if;
                if hf_en = '1' then
                    hflag <= rf_hout;
                end if;
                if cf_en = '1' then
                    cflag <= rf_cout;
                end if;
            end if;
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

    DBUS <= RAM         when DMUX = "000" else
            rf_odata    when DMUX = "001" else
            acc         when DMUX = "010" else
            ALU_ODATA   when DMUX = "011" else
            tmp         when DMUX = "100" else
            unq         when DMUX = "101" else
            FIXED       when DMUX = "110" else
            zflag & nflag & hflag & cflag & "0000" when DMUX = "111" else,
            X"00";

    caddr <= X"40" when cmd(7 downto 5) = "010" else
             X"40" when cmd(7 downto 4) = "0110" else
             X"80" when cmd(7 downto 5) = "100" else
             X"80" when cmd(7 downto 4) = "1010" else
             cmd;

    -- Bank 0
    mc_addr(9) <= mc_data0(9);
    with mc_data0(10) select    -- addr select
        mc_addr(7 downto 0) <= mc_data0(7 downto 0) when '0',
                               cmd when others;
    with mc_data0(13 downto 12) select    -- flag select
        mc_addr(8) <= cflag when "10",
                      zflag when "11",
                      mc_data0(8) when others;

    flagsrc <= mc_data0(11);
    zf_en <= mc_par0(1);
    nf_en <= mc_par0(0);
    hf_en <= mc_data0(15);
    cf_en <= mc_data0(14);

    -- Bank 1
    rf_dmux <= mc_data1(3 downto 0);
    rf_imux <= mc_data1(6 downto 4) when mc_data1(7) = '0' else
               '0' & cmd(5 downto 4);
    rf_ce   <= mc_data1(9 downto 8);
    rf_amux <= mc_data1(11 downto 10);
    rf_omux <= mc_data1(14 downto 12) when mc_data1(15) = '0' else
               cmd(2 downto 0);

    -- Bank 2
    alu_cmd <= mc_data2(5 downto 0);
    alu_ce <= mc_data2(6);
    cmd_ce <= mc_data2(8);
    acc_ce <= mc_data2(9);
    tmp_ce <= mc_data2(10);
    unq_ce <= mc_data2(11);
    wr_en  <= mc_data2(12);
    DMUX <= mc_data2(15 downto 13);
--  AMUX <= mc_par2(1 downto 0);

    -- Defaults --

    AMUX <= RFADDR;     -- Address from rf
    RAM_OE <= '1';      -- RAM on DBUS

    FIXED <= X"00";

    -- Microcode Memory --
    umicro0 : RAMB16BWER
    generic map (
        DATA_WIDTH_A => 18,
        DATA_WIDTH_B => 18,
        DOA_REG => 0,
        DOB_REG => 0,
        EN_RSTRAM_A => TRUE,
        EN_RSTRAM_B => TRUE,
        -- Initial values
        INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 00h
        INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 20h
        INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 40h
        INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 60h
        INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 80h
        INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000", -- a0h
        INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000", -- c0h
        INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000", -- e0h
        INIT_00 => X"00000000000000000000000003f90000000000000000050003f9050003e003fd", -- 000h
        INIT_01 => X"00000000000000000000000003f90000000000000000050003f9050003e00000", -- 010h
        INIT_02 => X"00000000000005000000000003f90000000000000000050003f9050003e003e4", -- 020h
        INIT_03 => X"00000000000000000000000003f90000000000000000000003f9050003e003e4", -- 030h
        INIT_04 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 040h
        INIT_05 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 050h
        INIT_06 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 060h
        INIT_07 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 070h
        INIT_08 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 080h
        INIT_09 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 090h
        INIT_0A => X"0000000000000000000000000000000000000000000000000000000000000000", -- 0a0h
        INIT_0B => X"0000000000000000000000000000000000000000000000000000000000000000", -- 0b0h
        INIT_0C => X"0000000000000000000000000000000000000000000000000000000000000000", -- 0c0h
        INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000", -- 0d0h
        INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000", -- 0e0h
        INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000", -- 0f0h
        INIT_10 => X"0000000000000000000000000000000000000000000003fe0000060006000000", -- 100h
        INIT_11 => X"0000000000000000000000000000000000000000000003fe0000060006000000", -- 110h
        INIT_12 => X"00000000000003fe000000000000000000000000000003fe0000060006003600", -- 120h
        INIT_13 => X"0000000000000000000000000000000000000000000000000000060006002600", -- 130h
        INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 140h
        INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 150h
        INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 160h
        INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 170h
        INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 180h
        INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 190h
        INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000", -- 1a0h
        INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000", -- 1b0h
        INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000", -- 1c0h
        INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000", -- 1d0h
        INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000", -- 1e0h
        INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000", -- 1f0h
        INIT_20 => X"0000000000000000000000000000000000000000000000000000070003fe0000", -- 200h
        INIT_21 => X"0000000000000000000000000000000000000000000000000000070003fe0000", -- 210h
        INIT_22 => X"0000000000000000000000000000000000000000000000000000070003fe03fa", -- 220h
        INIT_23 => X"0000000000000000000000000000000000000000000000000000070003fe03fa", -- 230h
        INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 240h
        INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 250h
        INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 260h
        INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 270h
        INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 280h
        INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 290h
        INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000", -- 2a0h
        INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000", -- 2b0h
        INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000", -- 2c0h
        INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000", -- 2d0h
        INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000", -- 2e0h
        INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000", -- 2f0h
        INIT_30 => X"000000000000000000000000000000000000000000000000000003fc00000000", -- 300h
        INIT_31 => X"000000000000000000000000000000000000000000000000000003fc00000000", -- 310h
        INIT_32 => X"000000000000000000000000000000000000000000000000000003fc000003fe", -- 320h
        INIT_33 => X"000000000000000000000000000000000000000000000000000003fc000003fe", -- 330h
        INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 340h
        INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 350h
        INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 360h
        INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 370h
        INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 380h
        INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 390h
        INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000", -- 3a0h
        INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000", -- 3b0h
        INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000", -- 3c0h
        INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000", -- 3d0h
        INIT_3E => X"000000000000000000000000000000000000050003e603e503e403e303e203e1", -- 3e0h
        INIT_3F => X"040003ff03fe03fd03fc03fb03fa03f903f803f703f603f503f403f303f203f1", -- 3f0h
        SRVAL_A => X"000000000",  -- Start with a NOP
        INIT_FILE => "NONE",
        RSTTYPE => "SYNC",
        RST_PRIORITY_A => "CE",
        RST_PRIORITY_B => "CE",
        SIM_COLLISION_CHECK => "ALL",
        SIM_DEVICE => "SPARTAN6"
    )
    port map (
        -- Port A
        DOA => mc_data0,  -- 32-bit output: A port data output
        DOPA => mc_par0,  -- 4-bit output: A port parity output
        ADDRA => mc_addr & "0000",   -- 14-bit input: A port address input: 16-bit mode -> 10-bit address
        CLKA => CLK,      -- 1-bit input: A port clock input
        ENA => '1',       -- 1-bit input: A port enable input
        REGCEA => '0',    -- 1-bit input: A port register clock enable input
        RSTA => RST,      -- 1-bit input: A port register set/reset input
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

    umicro1 : RAMB16BWER
    generic map (
        DATA_WIDTH_A => 18,
        DATA_WIDTH_B => 18,
        DOA_REG => 0,
        DOB_REG => 0,
        EN_RSTRAM_A => TRUE,
        EN_RSTRAM_B => TRUE,
        -- Initial values
        INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 00h
        INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 20h
        INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 40h
        INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 60h
        INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 80h
        INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000", -- a0h
        INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000", -- c0h
        INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000", -- e0h
        INIT_00 => X"0000000000000000000000000720000000000000000040000f8000004000400f", -- 000h
        INIT_01 => X"0000000000000000000000001720000000000000000040021f80100040000000", -- 010h
        INIT_02 => X"0000000000004005000000002720000000000000000040042f80200040004000", -- 020h
        INIT_03 => X"0000000000000000000000003720000000000000000000003f80200040004000", -- 030h
        INIT_04 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 040h
        INIT_05 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 050h
        INIT_06 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 060h
        INIT_07 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 070h
        INIT_08 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 080h
        INIT_09 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 090h
        INIT_0A => X"0000000000000000000000000000000000000000000000000000000000000000", -- 0a0h
        INIT_0B => X"0000000000000000000000000000000000000000000000000000000000000000", -- 0b0h
        INIT_0C => X"0000000000000000000000000000000000000000000000000000000000000000", -- 0c0h
        INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000", -- 0d0h
        INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000", -- 0e0h
        INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000", -- 0f0h
        INIT_10 => X"0000000000000000000000000000000000000000000042800000000042800000", -- 100h
        INIT_11 => X"0000000000000000000000000000000000000000000042800000100042800000", -- 110h
        INIT_12 => X"0000000000004180000000000000000000000000000042800000200042804000", -- 120h
        INIT_13 => X"0000000000000000000000000000000000000000000000000000200042804000", -- 130h
        INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 140h
        INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 150h
        INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 160h
        INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 170h
        INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 180h
        INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 190h
        INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000", -- 1a0h
        INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000", -- 1b0h
        INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000", -- 1c0h
        INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000", -- 1d0h
        INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000", -- 1e0h
        INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000", -- 1f0h
        INIT_20 => X"0000000000000000000000000000000000000000000000000000000041800000", -- 200h
        INIT_21 => X"0000000000000000000000000000000000000000000000000000100041800000", -- 210h
        INIT_22 => X"0000000000000000000000000000000000000000000000000000200041804340", -- 220h
        INIT_23 => X"0000000000000000000000000000000000000000000000000000200041804340", -- 230h
        INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 240h
        INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 250h
        INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 260h
        INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 270h
        INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 280h
        INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 290h
        INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000", -- 2a0h
        INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000", -- 2b0h
        INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000", -- 2c0h
        INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000", -- 2d0h
        INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000", -- 2e0h
        INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000", -- 2f0h
        INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 300h
        INIT_31 => X"0000000000000000000000000000000000000000000000000000100000000000", -- 310h
        INIT_32 => X"00000000000000000000000000000000000000000000000000002f2000004000", -- 320h
        INIT_33 => X"00000000000000000000000000000000000000000000000000002b2000004000", -- 330h
        INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 340h
        INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 350h
        INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 360h
        INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 370h
        INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 380h
        INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 390h
        INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000", -- 3a0h
        INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000", -- 3b0h
        INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000", -- 3c0h
        INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000", -- 3d0h
        INIT_3E => X"0000000000000000000000000000000000004f404000400040004f4040004000", -- 3e0h
        INIT_3F => X"4f40400040004000000000000000000000000000000000000000000000000000", -- 3f0h
        INIT_FILE => "NONE",
        RSTTYPE => "SYNC",
        RST_PRIORITY_A => "CE",
        RST_PRIORITY_B => "CE",
        SIM_COLLISION_CHECK => "ALL",
        SIM_DEVICE => "SPARTAN6"
    )
    port map (
        -- Port A
        DOA => mc_data1,  -- 32-bit output: A port data output
        DOPA => mc_par1,  -- 4-bit output: A port parity output
        ADDRA => mc_addr & "0000",   -- 14-bit input: A port address input: 16-bit mode -> 10-bit address
        CLKA => CLK,      -- 1-bit input: A port clock input
        ENA => '1',       -- 1-bit input: A port enable input
        REGCEA => '0',    -- 1-bit input: A port register clock enable input
        RSTA => RST,      -- 1-bit input: A port register set/reset input
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

    umicro2 : RAMB16BWER
    generic map (
        DATA_WIDTH_A => 18,
        DATA_WIDTH_B => 18,
        DOA_REG => 0,
        DOB_REG => 0,
        EN_RSTRAM_A => TRUE,
        EN_RSTRAM_B => TRUE,
        -- Initial values
        INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 00h
        INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 20h
        INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 40h
        INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 60h
        INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 80h
        INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000", -- a0h
        INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000", -- c0h
        INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000", -- e0h
        INIT_00 => X"0000000000000000000000000000000000000000000020480000400000000000", -- 000h
        INIT_01 => X"0000000000000000000000000000000000000000000020480000400000000000", -- 010h
        INIT_02 => X"0000000000002048000000000000000000000000000020480000400000000000", -- 020h
        INIT_03 => X"0000000000000000000000000000000000000000000000000000400000000000", -- 030h
        INIT_04 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 040h
        INIT_05 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 050h
        INIT_06 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 060h
        INIT_07 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 070h
        INIT_08 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 080h
        INIT_09 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 090h
        INIT_0A => X"0000000000000000000000000000000000000000000000000000000000000000", -- 0a0h
        INIT_0B => X"0000000000000000000000000000000000000000000000000000000000000000", -- 0b0h
        INIT_0C => X"0000000000000000000000000000000000000000000000000000000000000000", -- 0c0h
        INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000", -- 0d0h
        INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000", -- 0e0h
        INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000", -- 0f0h
        INIT_10 => X"0000000000000000000000000000000000000000000060000000400080000000", -- 100h
        INIT_11 => X"0000000000000000000000000000000000000000000060000000400080000000", -- 110h
        INIT_12 => X"0000000000006000000000000000000000000000000060000000400080000000", -- 120h
        INIT_13 => X"0000000000000000000000000000000000000000000000000000400080000000", -- 130h
        INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 140h
        INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 150h
        INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 160h
        INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 170h
        INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 180h
        INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 190h
        INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000", -- 1a0h
        INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000", -- 1b0h
        INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000", -- 1c0h
        INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000", -- 1d0h
        INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000", -- 1e0h
        INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000", -- 1f0h
        INIT_20 => X"00000000000000000000000000000000000000000000000000005000a0000000", -- 200h
        INIT_21 => X"00000000000000000000000000000000000000000000000000005000a0000000", -- 210h
        INIT_22 => X"00000000000000000000000000000000000000000000000000005000a0008000", -- 220h
        INIT_23 => X"00000000000000000000000000000000000000000000000000005000a0008000", -- 230h
        INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 240h
        INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 250h
        INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 260h
        INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 270h
        INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 280h
        INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 290h
        INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000", -- 2a0h
        INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000", -- 2b0h
        INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000", -- 2c0h
        INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000", -- 2d0h
        INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000", -- 2e0h
        INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000", -- 2f0h
        INIT_30 => X"0000000000000000000000000000000000000000000000000000500000000000", -- 300h
        INIT_31 => X"0000000000000000000000000000000000000000000000000000500000000000", -- 310h
        INIT_32 => X"0000000000000000000000000000000000000000000000000000500000000000", -- 320h
        INIT_33 => X"0000000000000000000000000000000000000000000000000000500000000000", -- 330h
        INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 340h
        INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 350h
        INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 360h
        INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 370h
        INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 380h
        INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 390h
        INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000", -- 3a0h
        INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000", -- 3b0h
        INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000", -- 3c0h
        INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000", -- 3d0h
        INIT_3E => X"0000000000000000000000000000000000000000040000000000000008000000", -- 3e0h
        INIT_3F => X"0000010000000000000000000000000000000000000000000000000000000000", -- 3f0h
        INIT_FILE => "NONE",
        RSTTYPE => "SYNC",
        RST_PRIORITY_A => "CE",
        RST_PRIORITY_B => "CE",
        SIM_COLLISION_CHECK => "ALL",
        SIM_DEVICE => "SPARTAN6"
    )
    port map (
        -- Port A
        DOA => mc_data2,  -- 32-bit output: A port data output
        DOPA => mc_par2,  -- 4-bit output: A port parity output
        ADDRA => mc_addr & "0000",   -- 14-bit input: A port address input: 16-bit mode -> 10-bit address
        CLKA => CLK,      -- 1-bit input: A port clock input
        ENA => '1',       -- 1-bit input: A port enable input
        REGCEA => '0',    -- 1-bit input: A port register clock enable input
        RSTA => RST,      -- 1-bit input: A port register set/reset input
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

