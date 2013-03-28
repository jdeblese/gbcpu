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
use work.cpuregs_comp.all;
use work.microcode_comp.all;
use work.regfile16bit_comp.all;

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

    signal cflag, zflag, hflag, nflag : std_logic;
    signal flagsrc : std_logic;

    signal r_iflags : std_logic_vector(3 downto 0);

    signal rf_odata : std_logic_vector(7 downto 0);
    signal rf_addr : std_logic_vector(15 downto 0);
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

    signal specialregs : cr_regs;
    signal sreg_en : cr_enables;

    signal rf_mux : rf_muxes;

begin

    -- *****************************************************************
    -- Internal Blocks --

    ureg : cpuregs
        port map ( specialregs, sreg_en, DBUS, r_iflags,
                   TCK, TDL, TDI, R_TDO_MC_TDI,
                   CLK, RST);

    uctrl : microcode
        port map ( AMUX, DMUX,
                   flagsrc,
                   rf_mux,
                   ALU_CMD, ALU_CE,
                   sreg_en,
                   WR_EN, RAM_OE,
                   specialregs.cmd, cflag, zflag,
                   TCK, TDL, R_TDO_MC_TDI, MC_TDO_RF_TDI,
                   CLK, RST);

    urf : regfile16bit
        port map ( DBUS, rf_odata, rf_addr,
                   rf_mux,
                   rf_zout, rf_nout, rf_hout, rf_cout,
                   TCK, TDL, MC_TDO_RF_TDI, TDO,
                   CLK, RST);

    ualu : alu
        port map ( DBUS, specialregs.acc, ALU_ODATA, ALU_CE, ALU_CMD,
                   zflag, cflag, hflag, nflag,
                   ALU_ZOUT, ALU_COUT, ALU_HOUT, ALU_NOUT,
                   CLK, RST);

--  utimer : timer
--      port map (DBUS, ABUS, WR_EN, timer_int, CLK, RST);

    -- *****************************************************************
    -- Signal Routing --

    zflag <= specialregs.flags(3);
    nflag <= specialregs.flags(2);
    hflag <= specialregs.flags(1);
    cflag <= specialregs.flags(0);

    with flagsrc select
        r_iflags <= alu_zout & alu_nout & alu_hout & alu_cout when '0',
                    rf_zout & rf_nout & rf_hout & rf_cout when others;

    WR_D <= DBUS;
    RAM_WR <= WR_EN;

    ABUS <= rf_addr when AMUX = "00" else
            specialregs.tmp & specialregs.unq when AMUX = "01" else
            X"FF" & specialregs.tmp when AMUX = "11" else
            X"FF" & rf_odata;

    DBUS <= RAM         when DMUX = "000" else
            rf_odata    when DMUX = "001" else
            specialregs.acc when DMUX = "010" else
            ALU_ODATA   when DMUX = "011" else
            specialregs.tmp when DMUX = "100" else
            specialregs.unq when DMUX = "101" else
            "00" & alu_cmd when DMUX = "110" else  -- To allow microcode to specify a data value (6-bit)
            zflag & nflag & hflag & cflag & "0000" when DMUX = "111" else
            X"00";

end FSM;

