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

    signal AMUX : std_logic_vector(1 downto 0);

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
    signal lflags : std_logic_vector(3 downto 0);
    signal cf_en, zf_en, hf_en, nf_en : std_logic;
    signal flagsrc : std_logic;

    signal mc_addr : std_logic_vector(9 downto 0);
    signal mc_data0 : std_logic_vector(31 downto 0);
    signal mc_data1 : std_logic_vector(31 downto 0);
    signal mc_data2 : std_logic_vector(31 downto 0);
    signal mc_par0 : std_logic_vector(3 downto 0);
    signal mc_par1 : std_logic_vector(3 downto 0);
    signal mc_par2 : std_logic_vector(3 downto 0);
    signal mc_code : std_logic_vector(53 downto 0);
    signal lcode : std_logic_vector(53 downto 0);

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

    signal JTAGLINK : std_logic;

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
                TCK : IN STD_LOGIC;
                TDL : IN STD_LOGIC;
                TDI : IN STD_LOGIC;
                TDO : OUT STD_LOGIC;
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

    with TDL select
        JTAGLINK <= lcode(53) when '0',
                    mc_code(53) when others;

    process(TCK, RST)
    begin
        if RST = '1' then
--          JTAGLINK <= '0';
            LCMD <= X"00";
            lacc <= X"00";
            lflags <= X"0";
            lcode <= (others => '0');
        elsif rising_edge(TCK) then
            if TDL = '1' then
--              JTAGLINK <= mc_code(53);
                lcode <= mc_code(52 downto 0) & CMD(7);
                LCMD <= CMD(6 downto 0) & acc(7);
                lacc <= acc(6 downto 0) & zflag;
                lflags <= nflag & hflag & cflag & TDI;
            else
--              JTAGLINK <= lcode(53);
                lcode <= lcode(52 downto 0) & LCMD(7);
                LCMD <= LCMD(6 downto 0) & lacc(7);
                lacc <= lacc(6 downto 0) & lflags(3);
                lflags <= lflags(2 downto 0) & TDI;
            end if;
        end if;
    end process;

    -- Internal Blocks --

    urf : regfile16bit
        port map (rf_idata, rf_odata, rf_addr, rf_imux, rf_omux, rf_dmux, rf_amux, rf_ce, rf_zout, rf_nout, rf_hout, rf_cout, TCK, TDL, JTAGLINK, TDO, CLK, RST);

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

    ABUS <= rf_addr when AMUX = "00" else
            tmp & unq when AMUX = "01" else
            X"FF" & tmp when AMUX = "11" else
            X"FF" & rf_odata;

    DBUS <= RAM         when DMUX = "000" else
            rf_odata    when DMUX = "001" else
            acc         when DMUX = "010" else
            ALU_ODATA   when DMUX = "011" else
            tmp         when DMUX = "100" else
            unq         when DMUX = "101" else
            "00" & alu_cmd when DMUX = "110" else
            zflag & nflag & hflag & cflag & "0000" when DMUX = "111" else
            X"00";

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

    with mc_par1(1 downto 0) select
        rf_imux <= mc_data1(6 downto 4) when "00",
                   '0' & cmd(5 downto 4) when "01",
                   '0' & cmd(2 downto 1) when others;

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
    AMUX <= mc_par2(1 downto 0);

    mc_code(53 downto 52) <= mc_par1(1 downto 0);
    mc_code(51 downto 36) <= mc_data1(15 downto 0);
    mc_code(35 downto 34) <= mc_par1(1 downto 0);
    mc_code(33 downto 18) <= mc_data1(15 downto 0);
    mc_code(17 downto 16) <= mc_par0(1 downto 0);
    mc_code(15 downto 0) <= mc_data0(15 downto 0);

    -- Defaults --

    RAM_OE <= '1';      -- RAM on DBUS

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
        INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 80h
        INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 100h
        INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 180h
        INITP_04 => X"000000000000000000000000000000000000000000000f000000000000000000", -- 200h
        INITP_05 => X"00030000000300000000000000000000000000000000000f00000000c0000003", -- 280h
        INITP_06 => X"00000000000000000000000000000000000c4000000c8f00000c4f030004cf00", -- 300h
        INITP_07 => X"000000000000000000000000000000000000000000000000000000c3000000c3", -- 380h
        INIT_00 => X"0307030e0315031403f9020803090370030703060305030403f90203025803fd", -- 000h
        INIT_01 => X"0307030e0315031403f9023503090200030703060305030403f9021302580000", -- 010h
        INIT_02 => X"0317030e0315031403f9022a03090200032703060305030403f9022302580200", -- 020h
        INIT_03 => X"0337031d0325032403f9022a03090254033703630205020403f9023302580254", -- 030h
        INIT_04 => X"03fd034303fd03fd03fd03fd03fd03fd03fd034003fd03fd03fd03fd03fd03fd", -- 040h
        INIT_05 => X"03fd034303fd03fd03fd03fd03fd03fd03fd034003fd03fd03fd03fd03fd03fd", -- 050h
        INIT_06 => X"03fd034303fd03fd03fd03fd03fd03fd03fd034003fd03fd03fd03fd03fd03fd", -- 060h
        INIT_07 => X"03fd034503fd03fd03fd03fd03fd03fd03600000035c035803540350034c0348", -- 070h
        INIT_08 => X"0380038403800380038003800380038003800381038003800380038003800380", -- 080h
        INIT_09 => X"0380038803800380038003800380038003800386038003800380038003800380", -- 090h
        INIT_0A => X"0380038c0380038003800380038003800380038a038003800380038003800380", -- 0a0h
        INIT_0B => X"039003910390039003900390039003900380038e038003800380038003800380", -- 0b0h
        INIT_0C => X"02cf028303a003a002cb03a00394360002c70281024003a003a003a002603600", -- 0c0h
        INIT_0D => X"02df0287000003b0000003b00000260002d70285024403b0000003b002682600", -- 0d0h
        INIT_0E => X"02ef028b000000000000025802e9025c02e7028902480000000002930270025c", -- 0e0h
        INIT_0F => X"02ff0308000000000000025803f9025c02f7028d03b80000000002990278025c", -- 0f0h
        INIT_10 => X"0339030f0329031903290319032903190339030f032903190329031903290319", -- 100h
        INIT_11 => X"0339030f0329031903290319032903190339030f032903190329031903290319", -- 110h
        INIT_12 => X"0339030f0329031903290319032903190339030f032903190329031903290319", -- 120h
        INIT_13 => X"0339030f0329031903290319032903190339030f032903190329031903290319", -- 130h
        INIT_14 => X"0310030f0310031003100310031003100310030f031003100310031003100310", -- 140h
        INIT_15 => X"0310030f0310031003100310031003100310030f031003100310031003100310", -- 150h
        INIT_16 => X"0310030f0310031003100310031003100310030f031003100310031003100310", -- 160h
        INIT_17 => X"0310030f0310031003100310031003100310030f031003100310031003100310", -- 170h
        INIT_18 => X"027f030f026f025f026f025f026f025f027f030f026f025f026f025f026f025f", -- 180h
        INIT_19 => X"027f030f026f025f026f025f026f025f027f030f026f025f026f025f026f025f", -- 190h
        INIT_1A => X"027f030f026f025f026f025f026f025f027f030f026f025f026f025f026f025f", -- 1a0h
        INIT_1B => X"027f030f026f025f026f025f026f025f027f030f026f025f026f025f026f025f", -- 1b0h
        INIT_1C => X"027f030f026f025f026f025f026f025f027f030f026f025f026f025f026f025f", -- 1c0h
        INIT_1D => X"027f030f026f025f026f025f026f025f027f030f026f025f026f025f026f025f", -- 1d0h
        INIT_1E => X"027f030f026f025f026f025f026f025f027f030f026f025f026f025f026f025f", -- 1e0h
        INIT_1F => X"027f030f026f025f026f025f026f025f027f030f026f025f026f025f026f025f", -- 1f0h
        INIT_20 => X"000002a003fc021c0000030a0219020a021702a0021502140202030203110210", -- 200h
        INIT_21 => X"000002a00280022c0000031a022903f9022702a0022502240212031203110300", -- 210h
        INIT_22 => X"000002a003fc03fc0000023a023903fd023702a08234823402220322031103f9", -- 220h
        INIT_23 => X"000002a003fc000000000700032103fd020902a0021a020c02320332031103f9", -- 230h
        INIT_24 => X"000002a1060000000240024b024a0249024002a1030c02450250024302420241", -- 240h
        INIT_25 => X"03fe02a1024d025d025c025b025a0259026702a1031c025503f9025302520251", -- 250h
        INIT_26 => X"03fe02a1023d026d026c026b026a0269027702a1032c02650264026302620261", -- 260h
        INIT_27 => X"03fe02a1022d027d027c027b027a027903fc02a1033c02750274027302720271", -- 270h
        INIT_28 => X"c3fc02a2021d0280028c0280028a0280028802a203470280028402800282c3fc", -- 280h
        INIT_29 => X"000002a2020d029d03fc029b029a03fc029802a203fc0295029403fc02920291", -- 290h
        INIT_2A => X"000002a2000000000000000000000000000002a2000000000000032f83f9c32f", -- 2a0h
        INIT_2B => X"000002a2000000000000000000000000000002a2000000000000000000000000", -- 2b0h
        INIT_2C => X"03a802a2020703fd02db03fd0000039b03a802a20000020703a703a7000003fa", -- 2c0h
        INIT_2D => X"03a802a2000003fd02eb03fd0000039b03a802a200000207000003b7000003fa", -- 2d0h
        INIT_2E => X"03a802a2000000000500029c03fecbf503a802a2000000000000000000000290", -- 2e0h
        INIT_2F => X"03a802a200000000000002570000cbf903a802a2000000000000000000000357", -- 2f0h
        INIT_30 => X"031f031e028f0247000003fccbfa030dc3fe031683fe83fe000003fc00003600", -- 300h
        INIT_31 => X"0600032e032d2600000003fcc3fe03f983fe032683fe83fe000003fc03fe83fe", -- 310h
        INIT_32 => X"033f03fc033d03fc000003fcc3fe03f9c3fe03fc83fe83fe000003fc033103fd", -- 320h
        INIT_33 => X"034f000003fc03fc000003fcc3fe03f9c3fe000000000000000003fc03fb03fd", -- 330h
        INIT_34 => X"03fc03fc034e034d000003fc034a03490280034203460342034403fc03420341", -- 340h
        INIT_35 => X"000003fc035e035d000003fc035a0359029703fc03560355000003fc03520351", -- 350h
        INIT_36 => X"00000000000000000000000003fc03690368036703660365036403fc03620361", -- 360h
        INIT_37 => X"03fd037f037e037d037c037b037a037903780777037603750374037303720371", -- 370h
        INIT_38 => X"0383038f0383038d0383038b038303890383038703830385c3fc03830382c3fe", -- 380h
        INIT_39 => X"03fc039f0394039d039c03f8039a03990398039703960395c3fc03930392c3fe", -- 390h
        INIT_3A => X"039e03af03ae03ad03ac03ab03aa03a903fa360003a603a503a403a303a203a1", -- 3a0h
        INIT_3B => X"0000000000000000024003bb03ba03b903fa260003b603b503b403b303b203b1", -- 3b0h
        INIT_3C => X"0000000002070207000003a7000003fa00000000000003fd03a703fd0000039b", -- 3c0h
        INIT_3D => X"0000000000000207000003b7000003fa00000000000003fd000003fd0000039b", -- 3d0h
        INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000", -- 3e0h
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
        INITP_00 => X"0000000000000000000000000000000000400040004000400040004000400040", -- 00h
        INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 80h
        INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 100h
        INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 180h
        INITP_04 => X"0000000080000000800000000000000000000004000000040000000400000004", -- 200h
        INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 280h
        INITP_06 => X"0000000000000000000000000000010400000000000800001008150400000500", -- 300h
        INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 380h
        INIT_00 => X"40004000400140010b0000000720400640004000400040000f0000004000400f", -- 000h
        INIT_01 => X"40004000400340031b0010001720400040004000400240021f00100040000000", -- 010h
        INIT_02 => X"40004000400540052b0020002720400040004000400440042f00200040004000", -- 020h
        INIT_03 => X"40004000400040003b0020003720400040004000200020003f00200040004000", -- 030h
        INIT_04 => X"4100200041054104410341024101410042002000420542044203420242014200", -- 040h
        INIT_05 => X"4110200041154114411341124111411042102000421542144213421242114210", -- 050h
        INIT_06 => X"4120200041254124412341224121412042202000422542244223422242214220", -- 060h
        INIT_07 => X"4000200040054004400340024001400020000000200520042003200220012000", -- 070h
        INIT_08 => X"4000200040054004400340024001400040002000400540044003400240014000", -- 080h
        INIT_09 => X"4000200040054004400340024001400040002000400540044003400240014000", -- 090h
        INIT_0A => X"4000200040054004400340024001400040002000400540044003400240014000", -- 0a0h
        INIT_0B => X"4000200040054004400340024001400040002000400540044003400240014000", -- 0b0h
        INIT_0C => X"00004000400040004000400030000000000040003b3140004000400030000000", -- 0c0h
        INIT_0D => X"00004000000040000000400000000000000040003b3340000000400030000000", -- 0d0h
        INIT_0E => X"00004000000000000000400022444000000040003b3500000000000130004000", -- 0e0h
        INIT_0F => X"00004000000000000000400023304000000040003b3000000000000130004000", -- 0f0h
        INIT_10 => X"4000200040054004400340024001400040002000400540044003400240014000", -- 100h
        INIT_11 => X"4000200040054004400340024001400040002000400540044003400240014000", -- 110h
        INIT_12 => X"4000200040054004400340024001400040002000400540044003400240014000", -- 120h
        INIT_13 => X"4000200040054004400340024001400040002000400540044003400240014000", -- 130h
        INIT_14 => X"4000200040054004400340024001400040002000400540044003400240014000", -- 140h
        INIT_15 => X"4000200040054004400340024001400040002000400540044003400240014000", -- 150h
        INIT_16 => X"4000200040054004400340024001400040002000400540044003400240014000", -- 160h
        INIT_17 => X"4000200040054004400340024001400040002000400540044003400240014000", -- 170h
        INIT_18 => X"4000200040054004400340024001400040002000400540044003400240014000", -- 180h
        INIT_19 => X"4000200040054004400340024001400040002000400540044003400240014000", -- 190h
        INIT_1A => X"4000200040054004400340024001400040002000400540044003400240014000", -- 1a0h
        INIT_1B => X"4000200040054004400340024001400040002000400540044003400240014000", -- 1b0h
        INIT_1C => X"4000200040054004400340024001400040002000400540044003400240014000", -- 1c0h
        INIT_1D => X"4000200040054004400340024001400040002000400540044003400240014000", -- 1d0h
        INIT_1E => X"4000200040054004400340024001400040002000400540044003400240014000", -- 1e0h
        INIT_1F => X"4000200040054004400340024001400040002000400540044003400240014000", -- 1f0h
        INIT_20 => X"0000200000002000000000003009000030082000200020000000000042004000", -- 200h
        INIT_21 => X"0000200040002000000010003009434030082000200020001000100042004000", -- 210h
        INIT_22 => X"000020003f302000000020003009400030082000200020002000200042004340", -- 220h
        INIT_23 => X"000020003f30000000002000300940003b382000100020002000200042004340", -- 230h
        INIT_24 => X"000020004f4000003b343004300430043b322000300230023b30300030003000", -- 240h
        INIT_25 => X"420020004000400040004f404000400000002000400040003000300030003000", -- 250h
        INIT_26 => X"410020003210300030003f3031103000000020003200300030003f3031003000", -- 260h
        INIT_27 => X"400020003000300030003f3030003000000020003220300030003f3031203000", -- 270h
        INIT_28 => X"4f40200040004000400040004000400040002000400040004000400040004f40", -- 280h
        INIT_29 => X"0000200000000000000100010001000000002000000100010001000000000000", -- 290h
        INIT_2A => X"0000200000000000000000000000000000002000000000000000200000002000", -- 2a0h
        INIT_2B => X"0000200000000000000000000000000000002000000000000000000000000000", -- 2b0h
        INIT_2C => X"000020003b30400040004000000000000000200000003b300240024000000000", -- 2c0h
        INIT_2D => X"000020000000400040004000000000000000200000003b300000024000000000", -- 2d0h
        INIT_2E => X"00002000000000004f4000002145333000002000000000000000000000000000", -- 2e0h
        INIT_2F => X"0000200000000000000000000000332000002000000000000000000000000000", -- 2f0h
        INIT_30 => X"2000400040003002000000000000400040004000420042000000000000004f40", -- 300h
        INIT_31 => X"2000410040004f40000010004200434040004200410041000000100041004000", -- 310h
        INIT_32 => X"20004f4040003f3000002f204100434040004f404000400000002f2002404000", -- 320h
        INIT_33 => X"200000004f403f3000002b2040004340400000000000000000002b2001404000", -- 330h
        INIT_34 => X"2000200120012001000020002000200040002000200021002000200022002000", -- 340h
        INIT_35 => X"0000200520052005000020042004200400002003200320030000200220022002", -- 350h
        INIT_36 => X"00000000000000000000000020002000200020004f4040004000200020002000", -- 360h
        INIT_37 => X"423031303000300030003f303000300030004f404130400040074f4042304000", -- 370h
        INIT_38 => X"2000200020002000200020002000200020002000200020002000200020004000", -- 380h
        INIT_39 => X"014002403000000000003f303240300030003f30314030002000200020004000", -- 390h
        INIT_3A => X"30093009300930093b3830083008300801404f404000400040004f4040004000", -- 3a0h
        INIT_3B => X"00000000000000003b3030003000300001404f404000400040004f4040004000", -- 3b0h
        INIT_3C => X"000000003b303b30000002400000000000000000000040000240400000000000", -- 3c0h
        INIT_3D => X"0000000000003b30000002400000000000000000000040000000400000000000", -- 3d0h
        INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000", -- 3e0h
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
        INITP_01 => X"0000002000000020000000000000000000000000000000000000000000000000", -- 80h
        INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 100h
        INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 180h
        INITP_04 => X"0000400000004000000040000000000000000000000000000000000004000000", -- 200h
        INITP_05 => X"00100003001000030000000000000000000000000000000005abcabf00000000", -- 280h
        INITP_06 => X"00000000000000000000c0000000000000000000000000000000000000000000", -- 300h
        INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000", -- 380h
        INIT_00 => X"40620000204c2048000000000000240040600000204c20480000400000000000", -- 000h
        INIT_01 => X"40630000204c2048000000000000000040610000204c20480000400000000000", -- 010h
        INIT_02 => X"40530000204c2048000000000000000040580000204c20480000400000000000", -- 020h
        INIT_03 => X"405b0000404c40480000000000000000405a0000000000000000400000000000", -- 030h
        INIT_04 => X"4000000020002000200020002000200040000000200020002000200020002000", -- 040h
        INIT_05 => X"4000000020002000200020002000200040000000200020002000200020002000", -- 050h
        INIT_06 => X"4000000020002000200020002000200040000000200020002000200020002000", -- 060h
        INIT_07 => X"4200000022002200220022002200220040000000200020002000200020002000", -- 070h
        INIT_08 => X"4041000020412041204120412041204140400000204020402040204020402040", -- 080h
        INIT_09 => X"4043000020432043204320432043204340420000204220422042204220422042", -- 090h
        INIT_0A => X"4052000020522052205220522052205240500000205020502050205020502050", -- 0a0h
        INIT_0B => X"4046000020462046204620462046204640510000205120512051205120512051", -- 0b0h
        INIT_0C => X"c4000000000000000000000000000000c4000000240000000000000000000000", -- 0c0h
        INIT_0D => X"c4000000000000000000000000000000c4000000240000000000000000000000", -- 0d0h
        INIT_0E => X"c4000000000000000000000020000000c4000000240000000000400000000000", -- 0e0h
        INIT_0F => X"c4000000000000000000000000000000c4000000e40000000000000000000000", -- 0f0h
        INIT_10 => X"4062000020622062206220622062206240600000206020602060206020602060", -- 100h
        INIT_11 => X"4063000020632063206320632063206340610000206120612061206120612061", -- 110h
        INIT_12 => X"4065000020652065206520652065206540640000206420642064206420642064", -- 120h
        INIT_13 => X"4066000020662066206620662066206640670000206720672067206720672067", -- 130h
        INIT_14 => X"4069000020692069206920692069206940680000206820682068206820682068", -- 140h
        INIT_15 => X"406b0000206b206b206b206b206b206b406a0000206a206a206a206a206a206a", -- 150h
        INIT_16 => X"406d0000206d206d206d206d206d206d406c0000206c206c206c206c206c206c", -- 160h
        INIT_17 => X"406f0000206f206f206f206f206f206f406e0000206e206e206e206e206e206e", -- 170h
        INIT_18 => X"4079000020792079207920792079207940780000207820782078207820782078", -- 180h
        INIT_19 => X"407b0000207b207b207b207b207b207b407a0000207a207a207a207a207a207a", -- 190h
        INIT_1A => X"407d0000207d207d207d207d207d207d407c0000207c207c207c207c207c207c", -- 1a0h
        INIT_1B => X"407f0000207f207f207f207f207f207f407e0000207e207e207e207e207e207e", -- 1b0h
        INIT_1C => X"4071000020712071207120712071207140700000207020702070207020702070", -- 1c0h
        INIT_1D => X"4073000020732073207320732073207340720000207220722072207220722072", -- 1d0h
        INIT_1E => X"4075000020752075207520752075207540740000207420742074207420742074", -- 1e0h
        INIT_1F => X"4077000020772077207720772077207740760000207620762076207620762076", -- 1f0h
        INIT_20 => X"0000806250006000000002002000000020008060000000004000500080000000", -- 200h
        INIT_21 => X"0000806300517000000002002000800020008061004c00484000500080000400", -- 210h
        INIT_22 => X"0000806500007000000000003000000030008064000000004000500080008000", -- 220h
        INIT_23 => X"0000806600000000000002003000000030008067000060004000500080008000", -- 230h
        INIT_24 => X"0000806900000000300030002000200030008068200020003000300020002000", -- 240h
        INIT_25 => X"6000806b0400000000000000080000000000806a040000009000900080008000", -- 250h
        INIT_26 => X"6000806d0000000000000000000000000200806c000000000000000000000000", -- 260h
        INIT_27 => X"6200806f0200000000000000000000000000806e000000000000000000000000", -- 270h
        INIT_28 => X"0000807900000052000000500000004300008078000000410000004000006200", -- 280h
        INIT_29 => X"0000807b5000400000000200000000000200807a500050004000500050004000", -- 290h
        INIT_2A => X"0000807d0000000000000000000000000000807c000000000000640000006400", -- 2a0h
        INIT_2B => X"0000807f0000000000000000000000000000807e000000000000000000000000", -- 2b0h
        INIT_2C => X"c8088079000000000000000000000000c8008078000000008000800000000000", -- 2c0h
        INIT_2D => X"c818807b000000000100000000000000c810807a000000000000800000000000", -- 2d0h
        INIT_2E => X"c828807d000000000000400020000000c820807c000000000000000000004000", -- 2e0h
        INIT_2F => X"c838807f000000000000000000000000c830807e000000000000000000000000", -- 2f0h
        INIT_30 => X"0000000000463000000000000000000062000000600060000000500000000000", -- 300h
        INIT_31 => X"04000000000000000000000060008000620000006000600000005000a0000000", -- 310h
        INIT_32 => X"8000000002000000000000006000800062000000620062000000500080000000", -- 320h
        INIT_33 => X"90000000000000000000000062008000600000000000000000005000a0000000", -- 330h
        INIT_34 => X"9000300030002000000030003000200000420200000000000000000000000000", -- 340h
        INIT_35 => X"0000300030002000000030003000200000003000300020000000300030002000", -- 350h
        INIT_36 => X"0000000000000000000000009000900080008000000004000000500050004000", -- 360h
        INIT_37 => X"8000b000b000a000a00090009000800080000000000000002800000000000000", -- 370h
        INIT_38 => X"0051000000520000005000000043000000420000004100000200004000006200", -- 380h
        INIT_39 => X"a000800000000000000000000000000000000000000000000000004600006000", -- 390h
        INIT_3A => X"30003000200020003000300020002000a0000000040000000000000008000000", -- 3a0h
        INIT_3B => X"00000000000000005000500040004000a0000000040000000000000008000000", -- 3b0h
        INIT_3C => X"0000000000000000000080000000000000000000000000008000000000000000", -- 3c0h
        INIT_3D => X"0000000000000000000080000000000000000000000000000000000000000000", -- 3d0h
        INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000", -- 3e0h
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

