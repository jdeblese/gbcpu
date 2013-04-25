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
        TX  : out STD_LOGIC;
        RX  : in STD_LOGIC;
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

use work.uart_comp.all;
use work.timer_comp.all;
use work.microcode_comp.all;
use work.types_comp.all;
use work.cartram_comp.all;
use work.sysram_comp.all;
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
        TX  : out STD_LOGIC;
        RX  : in STD_LOGIC;
        VSYNC : OUT STD_LOGIC;
        HSYNC : OUT STD_LOGIC;
        RED : OUT STD_LOGIC_VECTOR(2 downto 0);
        GREEN : OUT STD_LOGIC_VECTOR(2 downto 0);
        BLUE : OUT STD_LOGIC_VECTOR(1 downto 0) );
end system;

architecture Behavioral of system is

    signal RAMA : std_logic_vector(31 downto 0);
    signal RAMB : std_logic_vector(31 downto 0);

    signal topram_in : ram_in;
    signal topram_out : ram_out;

    signal clkdiv : std_logic;
    signal divtimer : std_logic_vector(3 downto 0);
    signal slowtimer : std_logic_vector(31 downto 0);
    signal sclken : std_logic;

    signal spol : std_logic;


    -- GBCPU
    signal ADDRCPU : STD_LOGIC_VECTOR(13 downto 0);
    signal ABUS : STD_LOGIC_VECTOR(15 downto 0);
    signal RAM : STD_LOGIC_VECTOR(7 downto 0);
    signal DOA_BOOT : STD_LOGIC_VECTOR(31 downto 0);  -- A port data output
    signal wr_d, cart_d, vid_d, sys_d, timer_d, uart_d : std_logic_vector(7 downto 0);
    signal wr_en : std_logic;
    signal pixels : pixelpipe;
    signal clkstatus : clockgen_status;
    signal BOOTRAM_VIS : std_logic;

    signal cpuclk, fastclk, pixclk, lockrst : std_logic;
    signal startup, slowrst : std_logic;

    signal rIF, rIE, interrupts : interrupts_group;

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
            startup <= '1';
        elsif rising_edge(CLK) and divtimer = "0000" then
            if slowtimer = X"0098967f" then    -- 98967f
                slowtimer <= X"00000000";
                spol <= '0';
                startup <= '0';
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
    slowrst <= lockrst and startup;

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
           cart_d               WHEN ABUS(15) = '0'             else    -- 0000-7FFF  Cartridge ROM
           vid_d                WHEN ABUS(15 downto 13) = "100" else    -- 8000-9FFF
           cart_d               WHEN ABUS(15 downto 13) = "101" else    -- A000-BFFF  Cartridge RAM
           sys_d                WHEN ABUS(15 downto 13) = "110" else    -- C000-DFFF
           uart_d               WHEN ABUS = X"FF01"             else
           uart_d               WHEN ABUS = X"FF02"             else
           timer_d              WHEN ABUS(15 downto 2) = X"FF0" & "01" else -- FF04-FF07  video registers
           vid_d                WHEN ABUS(15 downto 4) = X"FF4" else    -- FF40-FF4F  video registers
           "000" & rIF.ext & rIF.serial & rIF.timer & rIF.lcd & rIF.vblank WHEN ABUS = X"FF0F" else    -- FF0F Interrupt flag register
           "000" & rIE.ext & rIE.serial & rIE.timer & rIE.lcd & rIE.vblank WHEN ABUS = X"FFFF" else    -- FFFF Interrupt enable register
           topram_out.odata(7 downto 0) WHEN ABUS(15 downto 11) = "11111" else  -- F800-FFFF  fast ram
           sys_d                WHEN ABUS(15 downto 13) = "111" else    -- E000-FFFF  when not bumped by fast ram
            "ZZZZZZZZ";

    process(cpuclk,RST)
    begin
        if RST = '1' then
            rIF <= ('0', '0', '0', '0', '0');
            rIE <= ('0', '0', '0', '0', '0');
        elsif rising_edge(cpuclk) then
            -- Writes to enable register
            if ABUS = X"FFFF" and wr_en = '1' then
                rIE.vblank <= wr_d(0);
                rIE.lcd    <= wr_d(1);
                rIE.timer  <= wr_d(2);
                rIE.serial <= wr_d(3);
                rIE.ext    <= wr_d(4);
            end if;
            -- Writes to flag register
            if rIE.vblank = '1' and interrupts.vblank = '1' then
                rIF.vblank <= '1';
            elsif ABUS = X"FF0F" and wr_en = '1' then
                rIF.vblank <= wr_d(0);
            end if;
            if rIE.lcd = '1' and interrupts.lcd = '1' then
                rIF.lcd <= '1';
            elsif ABUS = X"FF0F" and wr_en = '1' then
                rIF.lcd <= wr_d(1);
            end if;
            if rIE.timer = '1' and interrupts.timer = '1' then
                rIF.timer <= '1';
            elsif ABUS = X"FF0F" and wr_en = '1' then
                rIF.timer <= wr_d(2);
            end if;
            if rIE.serial = '1' and interrupts.serial = '1' then
                rIF.serial <= '1';
            elsif ABUS = X"FF0F" and wr_en = '1' then
                rIF.serial <= wr_d(3);
            end if;
            if rIE.ext = '1' and interrupts.ext = '1' then
                rIF.ext <= '1';
            elsif ABUS = X"FF0F" and wr_en = '1' then
                rIF.ext <= wr_d(4);
            end if;
        end if;
    end process;

    topram_in.wen <= wr_en&wr_en&wr_en&wr_en WHEN ABUS(15 downto 11) = "11111" else "0000";

    topram_in.ipar <= (others => '0');
    topram_in.idata(31 downto 8) <= (others => '0');
    topram_in.idata(7 downto 0) <= wr_d;

    ucartram : cartram port map (RST, cpuclk, ABUS, cart_d, wr_d, '1', wr_en);
    usysram : sysram port map (RST, cpuclk, ABUS, sys_d, wr_d, '1', wr_en);

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
        rIF => rIF,
        rIE => rIE,
        TCK => TCK,
        TDL => TDL,
        TDI => TDI,
        TDO => TDO,
        CLK => cpuclk,
        RST => slowrst
    );

    utimer : timer port map ( wr_d, timer_d, ABUS, wr_en, interrupts.timer, cpuclk, slowrst );
    uuart : uart port map ( wr_d, uart_d, ABUS, wr_en, interrupts.serial, RX, TX, cpuclk, slowrst );

    ugpu : video port map ( wr_d, vid_d, ABUS, wr_en, pixels, LED(6), cpuclk, slowrst );
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
        DOA => topram_out.odata,
        ADDRA => ADDRCPU,
        CLKA => cpuclk,
        ENA => '1',
        REGCEA => '0',
        RSTA => RST,
        WEA => topram_in.wen,
        DIA => topram_in.idata,
        DIPA => topram_in.ipar,
        -- Port B
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

