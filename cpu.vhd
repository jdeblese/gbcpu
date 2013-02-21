library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package cpu_comp is
    component cpu
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
    end component;
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

use work.cpu_comp.all;

entity cpu is
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
end cpu;

architecture FSM of cpu is

    signal DMUX : std_logic_vector(2 downto 0);
    signal DBUS : STD_LOGIC_VECTOR(7 downto 0);

    signal AMUX : std_logic_vector(1 downto 0);

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
    signal cf_en, zf_en, hf_en, nf_en : std_logic;
    signal flagsrc : std_logic;

    signal r_oflags, r_iflags, r_flagsce : std_logic_vector(3 downto 0);

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

    signal R_TDO_MC_TDI, MC_TDO_RF_TDI : std_logic;  -- JTAG: MSB Out

    component microcode
        Port (  ABUSMUX : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
                DBUSMUX : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
                flagsrc : OUT STD_LOGIC;
                zf_en : OUT STD_LOGIC;
                nf_en : OUT STD_LOGIC;
                hf_en : OUT STD_LOGIC;
                cf_en : OUT STD_LOGIC;
                RF_DMUX : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
                RF_IMUX : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
                RF_AMUX : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
                RF_OMUX : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
                RF_CE   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
                ALU_CMD : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
                ALU_CE  : OUT STD_LOGIC;
                R_CMDCE : OUT STD_LOGIC;
                R_ACCCE : OUT STD_LOGIC;
                R_TMPCE : OUT STD_LOGIC;
                R_UNQCE : OUT STD_LOGIC;
                RAM_WREN : OUT STD_LOGIC;
                RAM_OE   : OUT STD_LOGIC;
                CMD   : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
                CFLAG : IN STD_LOGIC;
                ZFLAG : IN STD_LOGIC;
                TCK : IN STD_LOGIC;
                TDL : IN STD_LOGIC;
                TDI : IN STD_LOGIC;
                TDO : OUT STD_LOGIC;
                CLK : IN STD_LOGIC;
                RST : IN STD_LOGIC );
    end component;

    component cpuregs
        Port (  CMD_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
                TMP_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
                UNQ_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
                ACC_OUT : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
                DATA : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
                CMD_CE : IN STD_LOGIC;
                TMP_CE : IN STD_LOGIC;
                UNQ_CE : IN STD_LOGIC;
                ACC_CE : IN STD_LOGIC;
                FLAGS_OUT : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
                FLAGS_IN  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
                FLAGS_CE  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
                TCK : IN STD_LOGIC;
                TDL : IN STD_LOGIC;
                TDI : IN STD_LOGIC;
                TDO : OUT STD_LOGIC;
                CLK : IN STD_LOGIC;
                RST : IN STD_LOGIC );
    end component;

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

    -- *****************************************************************
    -- Internal Blocks --

    ureg : cpuregs
        port map ( CMD, tmp, unq, acc, DBUS, CMD_CE, tmp_ce, unq_ce, acc_ce,
                   r_oflags, r_iflags, r_flagsce,
                   TCK, TDL, TDI, R_TDO_MC_TDI,
                   CLK, RST);

    uctrl : microcode
        port map ( AMUX, DMUX,
                   flagsrc, zf_en, nf_en, hf_en, cf_en,
                   rf_dmux, rf_imux, rf_amux, rf_omux, rf_ce,
                   ALU_CMD, ALU_CE,
                   CMD_CE, acc_ce, tmp_ce, unq_ce,
                   WR_EN, RAM_OE,
                   CMD, cflag, zflag,
                   TCK, TDL, R_TDO_MC_TDI, MC_TDO_RF_TDI,
                   CLK, RST);

    urf : regfile16bit
        port map ( DBUS, rf_odata, rf_addr,
                   rf_imux, rf_omux, rf_dmux, rf_amux, rf_ce,
                   rf_zout, rf_nout, rf_hout, rf_cout,
                   TCK, TDL, MC_TDO_RF_TDI, TDO,
                   CLK, RST);

    ualu : alu
        port map ( DBUS, acc, ALU_ODATA, ALU_CE, ALU_CMD,
                   zflag, cflag, hflag, nflag,
                   ALU_ZOUT, ALU_COUT, ALU_HOUT, ALU_NOUT,
                   CLK, RST);

--  utimer : timer
--      port map (DBUS, ABUS, WR_EN, timer_int, CLK, RST);

    -- *****************************************************************
    -- Signal Routing --

    zflag <= r_oflags(3);
    nflag <= r_oflags(2);
    hflag <= r_oflags(1);
    cflag <= r_oflags(0);

    with flagsrc select
        r_iflags <= alu_zout & alu_nout & alu_hout & alu_cout when '0',
                    rf_zout & rf_nout & rf_hout & rf_cout when others;

    r_flagsce <= zf_en & nf_en & hf_en & cf_en;

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

    -- *****************************************************************
    -- Defaults --

    RAM_OE <= '1';      -- RAM on DBUS


end FSM;

