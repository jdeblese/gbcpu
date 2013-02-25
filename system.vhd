library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package system_comp is
    type io_op is record
        addr : std_logic_vector(15 downto 0);
        data : std_logic_vector(7 downto 0);
    end record;
    type io_list is array (3 downto 0) of io_op;

    component system
    Port (
        RST : IN STD_LOGIC;
        CLK : in  STD_LOGIC;
        LED : OUT STD_LOGIC_VECTOR(7 downto 0);
        debugrd : out io_list;
        debugwr : out io_list;
        TDI : in STD_LOGIC;
        TDO : out STD_LOGIC;
        TDL : in STD_LOGIC;
        TCK : in STD_LOGIC;
        VSYNC : OUT STD_LOGIC;
        HSYNC : OUT STD_LOGIC;
        RED : OUT STD_LOGIC_VECTOR(2 downto 0);
        GREEN : OUT STD_LOGIC_VECTOR(2 downto 0);
        BLUE : OUT STD_LOGIC_VECTOR(1 downto 0) );
    end component;
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;

library UNISIM;
use UNISIM.VComponents.all;

use work.clockgen_comp.all;
use work.cpu_comp.all;
use work.video_comp.all;
use work.driver_comp.all;
use work.system_comp.all;

entity system is
    Port (
        RST : IN STD_LOGIC;
        CLK : in  STD_LOGIC;
        LED : OUT STD_LOGIC_VECTOR(7 downto 0);
        debugrd : out io_list;
        debugwr : out io_list;
        TDI : in STD_LOGIC;
        TDO : out STD_LOGIC;
        TDL : in STD_LOGIC;
        TCK : in STD_LOGIC;
        VSYNC : OUT STD_LOGIC;
        HSYNC : OUT STD_LOGIC;
        RED : OUT STD_LOGIC_VECTOR(2 downto 0);
        GREEN : OUT STD_LOGIC_VECTOR(2 downto 0);
        BLUE : OUT STD_LOGIC_VECTOR(1 downto 0) );
end system;

architecture Behavioral of system is

    signal RAMA : std_logic_vector(31 downto 0);
    signal RAMB : std_logic_vector(31 downto 0);

    signal DIA_TOP, DOA_TOP   : STD_LOGIC_VECTOR(31 downto 0);  -- A port data output
    signal WTOP_EN : STD_LOGIC;

    signal clkdiv : std_logic;
    signal divtimer : std_logic_vector(3 downto 0);
    signal slowtimer : std_logic_vector(31 downto 0);
    signal sclken : std_logic;

    signal spol : std_logic;

    -- GBCPU
    signal ADDRCPU : STD_LOGIC_VECTOR(13 downto 0);
    signal ABUS : STD_LOGIC_VECTOR(15 downto 0);
    signal RAM : STD_LOGIC_VECTOR(7 downto 0);
    signal DOA_BOOT, DOA_CART   : STD_LOGIC_VECTOR(31 downto 0);  -- A port data output
    signal wr_d : std_logic_vector(7 downto 0);
    signal vid_d : std_logic_vector(7 downto 0);
    signal wr_en : std_logic;
    signal pixels : pixelpipe;
    signal cpuclk, fastclk, pixclk, lockrst : std_logic;
    signal clkstatus : clockgen_status;
    signal BOOTRAM_VIS : std_logic;


    -- Debouncer
    component debouncer
        Port ( rst : in std_logic;
               btn : in  STD_LOGIC;
               clk : in  STD_LOGIC;
               filtered : out  STD_LOGIC);
    end component;

--  signal bclk : std_logic;
--  ATTRIBUTE buffer_type : string;  --" {bufgdll | ibufg | bufgp | ibuf | bufr | none}";
--  ATTRIBUTE buffer_type OF bclk : SIGNAL IS "BUFG";

--  type io_op is record
--      addr : std_logic_vector(15 downto 0);
--      data : std_logic_vector(7 downto 0);
--  end record;
--  type io_list is array (3 downto 0) of io_op;
    signal read, write : io_list;

    constant read_default : io_list := (others => (addr => (others => '0'), data => (others => '0')));
    constant write_default : io_list := (others => (addr => (others => '0'), data => (others => '0')));

begin

    -- CLOCKS

    -- 10 MHz Clock
    process(CLK,RST)
    begin
        if RST = '1' then
            divtimer <= "0000";
            clkdiv <= '1';
        elsif rising_edge(CLK) then
            if ( divtimer = "0100" ) then
                divtimer <= divtimer + "0001";
                clkdiv <= '1';
            elsif ( divtimer = "1001" ) then
                divtimer <= "0000";
                clkdiv <= '0';
            else
                divtimer <= divtimer + "0001";
            end if;
        end if;
    end process;

    -- 1/4 Hz Clock
    process(CLK,RST,divtimer)
    begin
        if RST = '1' then
            slowtimer <= X"00000000";
            spol <= '0';
        elsif rising_edge(CLK) and divtimer = "0000" then
            if slowtimer = X"0098967f" then    -- 98967f
                slowtimer <= X"00000000";
                spol <= '0';
            else
                if slowtimer = X"004c4b40" then  -- 4c4b40
                    spol <= '1';
                end if;
                slowtimer <= slowtimer + "01";
            end if;
        end if;
    end process;

    uclk : clockgen port map ( CLK, fastclk, open, cpuclk, pixclk, clkstatus, RST );
--  uclk : clockgen port map ( CLK, fastclk, open, open,   pixclk, clkstatus, RST );
--  ucpuclk : BUFG port map (I => spol, O => cpuclk);


    lockrst <= RST or not(clkstatus.locked);

    -- GBCPU

    LED(0) <= WTOP_EN;
    LED(1) <= spol;
    LED(2) <= '0';
    LED(3) <= clkstatus.clkfx_err;
    LED(4) <= lockrst;

    process(cpuclk,RST)
        variable toggle : std_logic;
    begin
        if RST = '1' then
            LED(5) <= '0';
            toggle := '0';
        elsif rising_edge(cpuclk) then
            toggle := not(toggle);
            if ABUS = X"FF40" and wr_d(7) = '1' then
                LED(5) <= '1';
            end if;
        end if;
    end process;

    ADDRCPU(13 downto 3) <= ABUS(10 downto 0);
    ADDRCPU(2 downto 0) <= "000";

    process(cpuclk, RST)
    begin
        if RST = '1' then
            BOOTRAM_VIS <= '1';  -- Set to 1 to enable booting using the boot ROM rather than cartridge memory
        elsif rising_edge(cpuclk) then
            if ABUS = X"FF50" and wr_en = '1' and wr_d = X"01" then
                BOOTRAM_VIS <= '0';
            end if;
        end if;
    end process;

    RAM <= DOA_BOOT(7 downto 0) WHEN ABUS(15 downto  8) = "00000000" and BOOTRAM_VIS = '1' else  -- 0000-00FF
           DOA_CART(7 downto 0) WHEN ABUS(15 downto 11) = "00000" else  -- 0000-07FF
           vid_d                WHEN ABUS(15 downto 13) = "100" else    -- 8000-9FFF
           vid_d                WHEN ABUS(15 downto 4) = X"FF4" else        -- FF40-FF4F
           DOA_TOP(7 downto 0)  WHEN ABUS(15 downto 11) = "11111" else    -- F800-FFFF
            "ZZZZZZZZ";

    WTOP_EN <= wr_en WHEN ABUS(15 downto 11) = "11111" else '0';

    DIA_TOP(31 downto 8) <= (others => '0');
    DIA_TOP(7 downto 0) <= wr_d;

    debugrd <= read;
    debugwr <= write;
    process(cpuclk,RST)
    begin
        if RST = '1' then
            read <= read_default;
            write <= write_default;
        elsif rising_edge(cpuclk) then
            read(2 downto 0) <= read(3 downto 1);
            read(3).addr <= ABUS;
            read(3).data <= RAM;
            if wr_en = '1' then
                write(2 downto 0) <= write(3 downto 1);
                write(3).addr <= ABUS;
                write(3).data <= wr_d;
            end if;
        end if;
    end process;

    -- Component Instantiation
    ucpu: cpu PORT MAP(
        ABUS => ABUS,
        RAM => RAM,
        RAM_OE => open,
        wr_d => wr_d,
        RAM_WR => wr_en,
        TCK => TCK,
        TDL => TDL,
        TDI => TDI,
        TDO => TDO,
        CLK => cpuclk,
        RST => lockrst
    );

    ugpu : video port map ( wr_d, vid_d, ABUS, wr_en, pixels, LED(6), cpuclk, lockrst );
    uvga : driver port map ( VSYNC, HSYNC, RED, GREEN, BLUE, pixels, fastclk, cpuclk, pixclk, lockrst, LED(7) );

    bootram : RAMB16BWER
    generic map (
        DATA_WIDTH_A => 9,
        DATA_WIDTH_B => 9,
        DOA_REG => 0,
        DOB_REG => 0,
        EN_RSTRAM_A => TRUE,
        EN_RSTRAM_B => TRUE,
        -- GB Bootstrap Rom
        INIT_00 => X"e0fc3e77773e32e2f33e0ce232803e110eff2621fb207ccb329fff21affffe31",
--      INIT_00 => X"e0fc3e77773e32e2f33e0ce232803e110eff2621fb207ccb32800421affffe31",
        INIT_01 => X"f920052322131a080600d811f32034fe7b130096cd0095cd1a80102101041147",
        INIT_02 => X"0440e0913e42e057643e67f3180f2ef9200d3208283d0c0e992f219910ea193e",
--      INIT_02 => X"c340e0913e42e057643e67f3180f2ef9200d3208283d0c0e992f219910ea193e",
        INIT_03 => X"062064fec11e062862fe831e7c24130ef2201df7200dfa2090fe44f00c0e021e",
--      INIT_03 => X"062064fec11e062862fe831e7c24130ef2201df7200dfa2090fe44f00c0e0100",
        INIT_04 => X"1711cbc11711cbc504064fcb1820164f2005d2201542e09042f0e2873e0ce27b",
        INIT_05 => X"0e0089881f1108000d000c00830073030b000dcc6666edcec923222322f52005", -- 00A0
        INIT_06 => X"3c42a5b9a5b9423c3e33b9bb9f99dcddccec0e6e6367bbbb99d9dddde66eccdc", -- 00C0
        INIT_07 => X"50e0013efe2086fb20052386781906f52034fe7d23fe20be131a00a811010421",
        INIT_FILE => "NONE",
        RSTTYPE => "SYNC",
        RST_PRIORITY_A => "CE",
        RST_PRIORITY_B => "CE",
        SIM_COLLISION_CHECK => "ALL",
        SIM_DEVICE => "SPARTAN6"
    )
    port map (
        -- Port A
        DOA => DOA_BOOT,  -- 32-bit output: A port data output
        ADDRA => ADDRCPU, -- 14-bit input: A port address input
        CLKA => cpuclk,   -- 1-bit input: A port clock input
        ENA => '1',       -- 1-bit input: A port enable input
        REGCEA => '0',    -- 1-bit input: A port register clock enable input
        RSTA => '0',      -- 1-bit input: A port register set/reset input
        WEA => "0000",    -- 4-bit input: Port A byte-wide write enable input
        DIA => X"00000000", -- 32-bit input: A port data input
        DIPA => "0000",   -- 4-bit input: A port parity input
        -- Port B
        ADDRB => (others => '0'), -- 14-bit input: B port address input
        CLKB => '0',      -- 1-bit input: B port clock input
        ENB => '0',       -- 1-bit input: B port enable input
        REGCEB => '0',    -- 1-bit input: B port register clock enable input
        RSTB => '0',      -- 1-bit input: B port register set/reset input
        WEB => "0000",    -- 4-bit input: Port B byte-wide write enable input
        DIB => X"00000000", -- 32-bit input: B port data input
        DIPB => "0000"    -- 4-bit input: B port parity input
    );

    cartram : RAMB16BWER
    generic map (
        -- DATA_WIDTH_A/DATA_WIDTH_B: 0, 1, 2, 4, 9, 18, or 36
        DATA_WIDTH_A => 9,
        DATA_WIDTH_B => 9,
        -- DOA_REG/DOB_REG: Optional output register (0 or 1)
        DOA_REG => 0,
        DOB_REG => 0,
        -- EN_RSTRAM_A/EN_RSTRAM_B: Enable/disable RST
        EN_RSTRAM_A => TRUE,
        EN_RSTRAM_B => TRUE,
        -- INITP_00 to INITP_07: Initial memory contents.
        INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
        INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
        -- INIT_00 to INIT_3F: Initial memory contents.
--      INIT_00 => X"00000000000000002f833eff0721fe36ff06210536ff0721000000cf40e0913e",
--      INIT_00 => X"0000000000000000000003202414043323130332221202fffe314264012c2c00",
        -- 0000 NOP         00
        -- 0001 LD B,ff     06 ff
        -- 0003 LD D,02     16 02
        -- 0005 LD H,04     26 04
        -- 0007 LD (HL),06  36 06
        -- 0009 LD C,01     0e 01
        -- 000b LD E,03     1e 03
        -- 000d LD L,05     2e 05
        -- 000f LD A,07     3e 07
        -- 0011 LD BC,0000  01 00 00
        -- 0014 LD A,(BC)   0a
        -- 0015 LD DE,0001  11 01 00
        -- 0018 LD A,(DE)   1a
        -- 0019 LD SP,fffe  31 fe ff
        -- 001c LD HL,0019  21 19 00
        -- 001f LD A,(HL+)  2A
        INIT_00 => X"2a001921fffe311a0001110a000001073e052e031e010e063604260216ff0600",
        -- 0020 LD A,(HL+)  2A
        -- 0021 LD A,(HL-)  3A
        -- 0022 LD A,bb     3e bb
        -- 0023 LD (BC),A   02
        -- 0024 LD (DE),A   12
        -- 0025 LD (HL+),A  22
        -- 0026 LD (HL-),A  32
        -- 0027 INC BC      03
        -- 0028 INC DE      13
        -- 0029 INC HL      23
        -- 002a INC SP      33
        -- 002b DEC BC      0b
        -- 002c DEC DE      1b
        -- 002d DEC HL      2b
        -- 002e DEC SP      3b
        -- 002f NOP
        -- 0030 LD BC,0800  01 00 08
        -- 0033 LD DE,c800  11 00 c8
        -- 0036 LD SP,c800  31 00 c8
        -- Test addition, and H and C flags, but not Z flag - do later
        -- 0039 ADD HL,BC   09
        -- 003a ADD HL,DE   19
        -- 003b ADD HL,SP   39
        -- 003c ADD HL,HL   29
        -- 003d NOP
        -- 003e NOP
        -- 003f NOP
        INIT_01 => X"00000029391909c80031c800110800013b2b1b0b3323130332221202bb3e3a2a",
        -- 0040 LD B, 0f    06 0f
        -- 0042 INC B       04
        -- 0043 LD C, ff    0e ff
        -- 0045 INC C       0c
        -- 0046 INC D       14
        -- 0047 INC E       1c
        -- 0048 INC H       24
        -- 0049 INC L       2c
        -- 004a INC (HL)    34
        -- 004b INC A       3c
        -- 004c DEC B       05
        -- 004d DEC C       0d
        -- 004e DEC D       15
        -- 004f DEC E       1d
        -- 0050 DEC H       25
        -- 0051 DEC L       2d
        -- 0052 DEC (HL)    35
        -- 0053 DEC A       3d
        INIT_02 => X"0000000000000000000000003d352d251d150d053c342c241c140cff0e040f06",
        INIT_08 => X"00000000000000000000000000000000000000000000000000000000000100c3",
        -- INIT_A/INIT_B: Initial values on output port
        INIT_A => X"000000000",
        INIT_B => X"000000000",
        -- INIT_FILE: Optional file used to specify initial RAM contents
        INIT_FILE => "NONE",
        -- RSTTYPE: "SYNC" or "ASYNC"
        RSTTYPE => "SYNC",
        -- RST_PRIORITY_A/RST_PRIORITY_B: "CE" or "SR"
        RST_PRIORITY_A => "CE",
        RST_PRIORITY_B => "CE",
        -- SIM_COLLISION_CHECK: Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE"
        SIM_COLLISION_CHECK => "ALL",
        -- SIM_DEVICE: Must be set to "SPARTAN6" for proper simulation behavior
        SIM_DEVICE => "SPARTAN6", -- was: "SPARTAN3ADSP",
        -- SRVAL_A/SRVAL_B: Set/Reset value for RAM output
        SRVAL_A => X"000000000",
        SRVAL_B => X"000000000",
        -- WRITE_MODE_A/WRITE_MODE_B: "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
        WRITE_MODE_A => "WRITE_FIRST",
        WRITE_MODE_B => "WRITE_FIRST"
    )
    port map (
        -- Port A
        DOA => DOA_CART,  -- 32-bit output: A port data output
--      DOPA => DOPA,     -- 4-bit output: A port parity output
        ADDRA => ADDRCPU,   -- 14-bit input: A port address input
        CLKA => cpuclk,   -- 1-bit input: A port clock input
        ENA => '1',       -- 1-bit input: A port enable input
        REGCEA => '0',    -- 1-bit input: A port register clock enable input
        RSTA => '0',      -- 1-bit input: A port register set/reset input
        WEA => "0000",    -- 4-bit input: Port A byte-wide write enable input
        DIA => X"00000000",       -- 32-bit input: A port data input
        DIPA => "0000",   -- 4-bit input: A port parity input
        -- Port B
--      DOB => DOB,       -- 32-bit output: B port data output
--      DOPB => DOPB,     -- 4-bit output: B port parity output
        ADDRB => "00" & X"000",   -- 14-bit input: B port address input
        CLKB => '0',      -- 1-bit input: B port clock input
        ENB => '0',       -- 1-bit input: B port enable input
        REGCEB => '0',    -- 1-bit input: B port register clock enable input
        RSTB => '0',      -- 1-bit input: B port register set/reset input
        WEB => "0000",    -- 4-bit input: Port B byte-wide write enable input
        DIB => X"00000000",       -- 32-bit input: B port data input
        DIPB => "0000"    -- 4-bit input: B port parity input
    );

    topram : RAMB16BWER
    generic map (
        DATA_WIDTH_A => 9,
        DATA_WIDTH_B => 9,
        DOA_REG => 0,
        DOB_REG => 0,
        EN_RSTRAM_A => TRUE,
        EN_RSTRAM_B => TRUE,
        INIT_A => X"000000000",
        INIT_B => X"000000000",
        INIT_FILE => "NONE",
        RSTTYPE => "SYNC",
        RST_PRIORITY_A => "CE",
        RST_PRIORITY_B => "CE",
        SIM_COLLISION_CHECK => "ALL",
        SIM_DEVICE => "SPARTAN6",
        SRVAL_A => X"000000000",
        SRVAL_B => X"000000000",
        WRITE_MODE_A => "WRITE_FIRST",
        WRITE_MODE_B => "WRITE_FIRST"
    )
    port map (
        -- Port A
        DOA => DOA_TOP,   -- 32-bit output: A port data output
--      DOPA => DOPA,     -- 4-bit output: A port parity output
        ADDRA => ADDRCPU, -- 14-bit input: A port address input
        CLKA => cpuclk,   -- 1-bit input: A port clock input
        ENA => '1',       -- 1-bit input: A port enable input
        REGCEA => '0',    -- 1-bit input: A port register clock enable input
        RSTA => RST,      -- 1-bit input: A port register set/reset input
        WEA => WTOP_EN & WTOP_EN & WTOP_EN & WTOP_EN,    -- 4-bit input: Port A byte-wide write enable input
        DIA => DIA_TOP,   -- 32-bit input: A port data input
        DIPA => "0000",   -- 4-bit input: A port parity input
        -- Port B
--      DOB => DOB,       -- 32-bit output: B port data output
--      DOPB => DOPB,     -- 4-bit output: B port parity output
        ADDRB => (others => '0'),   -- 14-bit input: B port address input
        CLKB => '0',      -- 1-bit input: B port clock input
        ENB => '0',       -- 1-bit input: B port enable input
        REGCEB => '0',    -- 1-bit input: B port register clock enable input
        RSTB => '0',      -- 1-bit input: B port register set/reset input
        WEB => "0000",    -- 4-bit input: Port B byte-wide write enable input
        DIB => (others => '0'),       -- 32-bit input: B port data input
        DIPB => "0000"    -- 4-bit input: B port parity input
    );

end Behavioral;

