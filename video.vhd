library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED."+";
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

-- FIXME: How does starting, stopping and changing the video affect
--  the phase of the clock divider, if at all?

entity video is
    Port (  DIN     : in std_logic_vector(7 downto 0);
            DOUT    : out std_logic_vector(7 downto 0);
            ABUS    : in std_logic_vector(15 downto 0);
            WR_EN   : in std_logic;
            VIDROW  : out unsigned(7 downto 0);
            VIDCOL  : out unsigned(7 downto 0);
            VIDWORD : out std_logic_vector(1 downto 0);
            VIDWR   : out std_logic;
            CLK     : in std_logic;
            RST     : in std_logic );
end video;

architecture Behaviour of video is

    -- Registers
    signal lcdc, dma, bgp, obp0, obp1 : std_logic_vector(7 downto 0);
    signal scx, scy, wx, wy, ly, lyc : unsigned(7 downto 0);  -- All 8-bit values
    signal tile : unsigned(4 downto 0);  -- Horizontal tile number

    signal lcdc_tiledatsel : std_logic;

    signal mode : std_logic_vector(1 downto 0);
    signal ly_coinc : std_logic;

    signal count : std_logic_vector(8 downto 0);

    signal bgshift : std_logic_vector(7 downto 0);  -- ly - scy
    signal dataddr : std_logic_vector(9 downto 0); -- Address in tile data table (16-bit words)
    signal bitfield : std_logic;
    signal tilerow : std_logic_vector(15 downto 0); -- one row of 2-bit values, 8 lsbits then 8 msbits
    signal tileidx : std_logic_vector(7 downto 0);  -- active tile

    type STATE_TYPE is (RESET, OAMSCAN, MAPREAD, TILEREAD, WAI, HBLANK, VBLANK);
    signal CS, NS: STATE_TYPE;

    type VRAMSTATES is (VRAM_RST, VRAM_TILE, VRAM_LO, VRAM_HI, VRAM_SPRITE);
    signal VRAMCS, VRAMNS, VRAMOS: VRAMSTATES;
    signal vram_init : std_logic;
    signal vram_delay : unsigned(2 downto 0);

    signal lcd_clk : std_logic;

    signal map_doa : std_logic_vector(31 downto 0);
    signal map_dob : std_logic_vector(31 downto 0);
    signal map_en : std_logic;
    signal map_sel : std_logic;
    signal map_addr : std_logic_vector(9 downto 0);  -- Address within tile map (000h -- 3FFh)

    signal lo_addr : std_logic_vector(13 downto 0);
    signal lo_doa : std_logic_vector(31 downto 0);
    signal lo_dob : std_logic_vector(31 downto 0);
    signal lo_en : std_logic;

    signal mid_addr : std_logic_vector(13 downto 0);
    signal mid_doa : std_logic_vector(31 downto 0);
    signal mid_dob : std_logic_vector(31 downto 0);
    signal mid_en : std_logic;

    signal hi_addr : std_logic_vector(13 downto 0);
    signal hi_doa : std_logic_vector(31 downto 0);
    signal hi_dob : std_logic_vector(31 downto 0);
    signal hi_en : std_logic;

    signal internal_en : std_logic;

    signal scanline_fill : unsigned(7 downto 0);
    signal scanline_in   : std_logic_vector(1 downto 0);
    signal scanline_doa  : std_logic_vector(15 downto 0);
    signal scanline_wr   : std_logic;

    signal sladdr : std_logic_vector(12 downto 0);
    signal slsrc  : std_logic;
    signal sldma  : unsigned(7 downto 0);

    signal pixcount : unsigned(2 downto 0);
begin

    -- Names for ease of use
    lcdc_tiledatsel <= lcdc(4);

    -- *********************************************************************************************
    -- Memory mapping, 8000-9FFF and FF40-FF4B

    -- first three local RAMs are for data tables, last is for background tile maps

    lo_en  <= WR_EN when ABUS(15 downto 11) = "10000" else '0';  -- 8000h -- 87FFh
    mid_en <= WR_EN when ABUS(15 downto 11) = "10001" else '0';  -- 8800h -- 8FFFh
    hi_en  <= WR_EN when ABUS(15 downto 11) = "10010" else '0';  -- 9000h -- 97FFh
    map_en <= WR_EN when ABUS(15 downto 11) = "10011" else '0';  -- 9800h -- 9FFFh

    DOUT <= lo_doa(7 downto 0)  when ABUS(15 downto 11) = "10000" else  -- 8000h -- 87FFh
            mid_doa(7 downto 0) when ABUS(15 downto 11) = "10001" else  -- 8800h -- 8FFFh
            hi_doa(7 downto 0)  when ABUS(15 downto 11) = "10010" else  -- 9000h -- 97FFh
            map_doa(7 downto 0) when ABUS(15 downto 11) = "10011" else  -- 9800h -- 9FFFh
            lcdc                   when ABUS = "1111111101000000" else     -- FF40
            "00000" & std_logic(ly_coinc) & mode when ABUS = "1111111101000001" else     -- there's more to this register
            std_logic_vector(scy)  when ABUS = "1111111101000010" else
            std_logic_vector(scx)  when ABUS = "1111111101000011" else
            std_logic_vector(ly)   when ABUS = "1111111101000100" else
            std_logic_vector(lyc)  when ABUS = "1111111101000101" else
            dma                    when ABUS = "1111111101000110" else
            bgp                    when ABUS = "1111111101000111" else
            obp0                   when ABUS = "1111111101001000" else
            obp1                   when ABUS = "1111111101001001" else
            std_logic_vector(wy)   when ABUS = "1111111101001010" else
            std_logic_vector(wx)   when ABUS = "1111111101001011" else  -- Last defined register
            "ZZZZZZZZ";

    -- *********************************************************************************************
    -- Internal registers

    inproc : process(CLK, RST)
    begin
        if RST = '1' then
            lcdc <= X"7d";
            scy  <= X"03";
            scx  <= X"00";
            lyc  <= X"dd";
            dma  <= X"dd";
            bgp  <= X"dd";
            obp0 <= X"dd";
            obp1 <= X"dd";
            wy   <= X"dd";
            wx   <= X"dd";
        elsif rising_edge(CLK) then
            if WR_EN = '1' and ABUS(15 downto 4) = "111111110100" then
                case ABUS(3 downto 0) is
                    when "0000" => lcdc <= DIN;
                    when "0010" => scy  <= unsigned(DIN);
                    when "0011" => scx  <= unsigned(DIN);
                    when "0101" => lyc  <= unsigned(DIN);
                    when "0110" => dma  <= DIN;
                    when "0111" => bgp  <= DIN;
                    when "1000" => obp0 <= DIN;
                    when "1001" => obp1 <= DIN;
                    when "1010" => wy   <= unsigned(DIN);  -- should only change at the start of a redraw, never during
                    when "1011" => wx   <= unsigned(DIN);  -- may be changed during a scan line interrupt to distort graphics
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    -- *********************************************************************************************
    -- Timing

    countproc : process(CLK, RST)
    begin
        if RST = '1' then
            count <= "000000000";
        elsif rising_edge(CLK) then
            if CS = RESET then
                count <= "000000000";
            elsif count = "111000111" then  -- 455 (1C7h)
                count <= "000000000";
            else
                count <= count + "1";
            end if;
        end if;
    end process;

    lineproc : process(CLK, RST)
    begin
        if RST = '1' then
            ly <= X"00";
        elsif rising_edge(CLK) then
            if count = "111000111" then  -- 455 (1C7h)
                if ly = "10011001" then  -- 153 (99h)
                    ly <= "00000000";
                else
                    ly <= ly + "1";
                end if;
            end if;
        end if;
    end process;

    -- *********************************************************************************************
    -- Scanline buffer

    -- scanline_fill(7 downto 0) : number of pixels rendered in this scanline
    -- scanline_in(1 downto 0)   : pixel to write to scanline buffer
    -- scanline_doa(15 downto 0) : scanline buffer output
    -- scanline_wr               : scanline buffer write enable

    scanlineram : RAMB8BWER
    generic map (
        DATA_WIDTH_A => 2,
        DATA_WIDTH_B => 2,
        DOA_REG => 0,
        DOB_REG => 0,
        EN_RSTRAM_A => TRUE,
        EN_RSTRAM_B => TRUE,
        -- GB Bootstrap Rom
        RSTTYPE => "SYNC",
        RST_PRIORITY_A => "CE",
        RST_PRIORITY_B => "CE",
        SIM_COLLISION_CHECK => "ALL"
--      SIM_DEVICE => "SPARTAN6"       -- WRONG NAME
    )
    port map (
        -- Port A: Scanline I/O
        ADDRAWRADDR => sladdr,  -- 13-bit address
        DIADI => X"000" & "00" & scanline_in,   -- 16-bit data input
        DOADO => scanline_doa,                  -- 16-bit data output
        WEAWEL => scanline_wr & scanline_wr,    -- 2-bit write enable
        DIPADIP => "00",   -- 2-bit parity input
        CLKAWRCLK => CLK,  -- clock
        ENAWREN => '1',    -- port enable
        REGCEA => '0',     -- output register enable
        RSTA => '0',       -- reset
        -- Port B: not used
        ADDRBRDADDR => '0' & X"000",  -- 13-bit address
        CLKBRDCLK => CLK,             -- clock
        ENBRDEN => '0',               -- port enable
        REGCEBREGCE => '0',           -- output register enable
        RSTBRST => '0',               -- reset
        WEBWEU => "00",               -- write enable
        DIBDI => X"0000",             -- 16-bit data input
        DIPBDIP => "00"               -- 2-bit parity input
    );

    VIDCOL <= sldma;
    VIDROW <= ly;
    VIDWORD <= scanline_doa(1 downto 0);
    VIDWR <= slsrc;

    with slsrc select
        sladdr <= "0000" & std_logic_vector(scanline_fill) & "0" when '1',
                  "0000" & std_logic_vector(sldma) & "0" when others;

    scanlinedma : process(CLK,RST)
        variable OS : STATE_TYPE;
    begin
        if RST = '1' then
            sldma <= (others => '0');
            slsrc <= '0';
        elsif rising_edge(CLK) then
            -- DMA starts after scanline is finished, so on state change to HBLANK
            if CS = HBLANK and OS /= HBLANK then
                slsrc <= '1';
            end if;
            OS := CS;
            -- Count up to FF, then stop and turn off DMA
            if slsrc = '1' then
                if sldma = X"FF" then
                    sldma <= (others => '0');
                    slsrc <= '0';
                else
                    sldma <= sldma + 1;
                end if;
            end if;
        end if;
    end process;

    -- *********************************************************************************************
    -- VRAM FSM

    process (CLK, RST)
    begin
        if RST = '1' then
            VRAMCS <= VRAM_RST;
        elsif rising_edge(CLK) then  -- LCD clocks data in on falling edge
            VRAMCS <= VRAMNS;
            VRAMOS <= VRAMCS;
        end if;
    end process;

    process (RST, VRAMCS, VRAMOS, NS, vram_init)
    begin

        case VRAMCS is
            when VRAM_RST =>
                VRAMNS <= VRAM_RST;
                if NS = MAPREAD then
                    VRAMNS <= VRAM_TILE;
                end if;

            when VRAM_TILE =>
                VRAMNS <= VRAM_TILE;
                if NS = HBLANK then
                    VRAMNS <= VRAM_RST;
                elsif VRAMOS = VRAM_TILE then
                    VRAMNS <= VRAM_LO;
                end if;

            when VRAM_LO =>
                VRAMNS <= VRAM_LO;
                if NS = HBLANK then
                    VRAMNS <= VRAM_RST;
                elsif VRAMOS = VRAM_LO then
                    VRAMNS <= VRAM_HI;
                end if;

            when VRAM_HI =>
                VRAMNS <= VRAM_HI;
                if NS = HBLANK then
                    VRAMNS <= VRAM_RST;
                elsif VRAMOS = VRAM_HI then
                    if vram_init = '1' then
                        VRAMNS <= VRAM_TILE;
                    else
                        VRAMNS <= VRAM_SPRITE;
                    end if;
                end if;

            when VRAM_SPRITE =>
                VRAMNS <= VRAM_SPRITE;
                if NS = HBLANK then
                    VRAMNS <= VRAM_RST;
                elsif VRAMOS = VRAM_SPRITE then
                    VRAMNS <= VRAM_TILE;
                end if;

            when others =>
                VRAMNS <= VRAM_RST;
        end case;
    end process;

    process(CLK,RST)
    begin
        if RST = '1' then
            vram_init <= '0';
        elsif rising_edge(CLK) then
            if VRAMNS = VRAM_TILE and VRAMCS /= VRAM_TILE then
                if VRAMCS = VRAM_RST then
                    vram_init <= '1';
                else
                    vram_init <= '0';
                end if;
            end if;
        end if;
    end process;

    process(CLK,RST)
    begin
        if RST = '1' then
            vram_delay <= (others => '0');
        elsif rising_edge(CLK) then
            if vram_init = '1' then
                vram_delay <= unsigned(scx(2 downto 0));
            elsif vram_delay /= "0" then
                vram_delay <= vram_delay - 1;
            end if;
        end if;
    end process;

    process(CLK,RST)
    begin
        if RST = '1' then
            lcd_clk <= '0';
        elsif CLK'event then
            if CS = MAPREAD and vram_init = '0' and vram_delay = "0" then
                lcd_clk <= not(CLK);
            end if;
        end if;
    end process;

    -- *********************************************************************************************

    process(CLK,RST)
    begin
        if RST = '1' then
            tile <= (others => '0');
        elsif rising_edge(CLK) then
            if VRAMCS = VRAM_RST then
                tile <= (others => '0');
            elsif VRAMNS = VRAM_TILE and VRAMCS /= VRAM_TILE then  -- Only update 'tile' when stepping to the next one
                tile <= tile + "00001";
            end if;
        end if;
    end process;

    map_sel <= lcdc(3);
    process(CLK,RST)
        variable x : unsigned(4 downto 0);
        variable y : unsigned(7 downto 0);
    begin
        if RST = '1' then
            map_addr <= (others => '0');
            tileidx <= (others => '0');
        elsif falling_edge(CLK) then
            if VRAMCS = VRAM_TILE then
                x := tile + scx(7 downto 3);
                y := ly + scy;
                map_addr <= std_logic_vector(y(7 downto 3)) & std_logic_vector(x);
                tileidx <= map_dob(7 downto 0);
            end if;
        end if;
    end process;

    process(CLK,RST)
        variable x, y : unsigned(7 downto 0);
        variable rowdata : std_logic_vector(15 downto 0);
    begin
        if RST = '1' then
            dataddr <= (others => '0');
            bitfield <= '0';
        elsif falling_edge(CLK) then
            if VRAMCS = VRAM_LO or VRAMCS = VRAM_HI then
                y := ly + scy;
                dataddr(9 downto 3) <= tileidx(6 downto 0);  -- which tile to be read determined by tile map
                dataddr(2 downto 0) <= std_logic_vector(y(2 downto 0));  -- row of tile to be read determined by ly and scy
                if VRAMCS = VRAM_LO then
                    bitfield <= '0';
                else
                    bitfield <= '1';
                end if;
            end if;
        end if;
    end process;

    -- *********************************************************************************************
    -- FSM-dependent processes

    process(CLK,RST)
    begin
        if RST = '1' then
            pixcount <= (others => '0');
        elsif falling_edge(CLK) then
            if CS = MAPREAD then
                if tile = "00000" then
                    pixcount <= scx(2 downto 0);  -- counts up to 8 to indicate how many pixels written to scanline buffer
                end if;
            elsif CS = TILEREAD then
                pixcount <= pixcount + "001";
            end if;
        end if;
    end process;

    process(CLK,RST)
        variable x, y : unsigned(7 downto 0);
        variable rowdata : std_logic_vector(15 downto 0);
    begin
        if RST = '1' then
            scanline_fill <= (others => '0');
            scanline_in <= (others => '0');
            scanline_wr <= '0';
        elsif falling_edge(CLK) then
            if NS = MAPREAD and CS /= MAPREAD then
--              if lcdc(5) and (ly >= wy) and (scanline_fill + to_unsigned(7,8) >= wx) then  -- Window
--                  x := lx - wx - to_unsigned(7, 8);
--                  y := ly - wy;
--                  map_sel <= lcdc(6);
                x := scanline_fill + scx;
                y := ly + scy;
            elsif CS = MAPREAD then
                -- Tile index is now available at output of mapram, so read tile
                y := ly + scy;
            elsif CS = TILEREAD then
                -- Tile row is now available at output of the appropriate RAM
                -- either 0 to 255 with origin 8000 or -128 to 127 with origin 9000
                if tileidx(7) = '1' then
                    rowdata := mid_dob(15 downto 0);  -- 8800-8FFF
                elsif lcdc_tiledatsel = '1' then -- only true when drawing bg, otherwise dependent on other parameters
                    rowdata := lo_dob(15 downto 0);  -- 8000-8800
                else
                    rowdata := hi_dob(15 downto 0);  -- 9000-9800
                end if;
                -- Of 16 bits of data, low bit of pixel comes from first 8 bits and high bit from last 8 bits
                scanline_in <= rowdata(to_integer('1' & pixcount)) & rowdata(to_integer(pixcount));
                scanline_wr <= '1';
                scanline_fill <= scanline_fill + X"01";
            end if;
        end if;
    end process;


    -- *********************************************************************************************
    -- Renderer FSM

    SYNC_PROC: process (CLK, RST)
    begin
        if RST = '1' then
            CS <= RESET;
        elsif rising_edge(CLK) then
            CS <= NS;
        end if;
    end process;

    COMB_PROC: process (RST, CS, lcdc, ly, count)
    begin

        internal_en <= '0';     -- Disable internal RAM port when not in use to avoid collisions
        mode <= "00";

        case CS is
            when RESET =>
                NS <= RESET;
                if lcdc(7) = '1' then
                    NS <= OAMSCAN;
                    internal_en <= '1';
                end if;

            when OAMSCAN =>
                NS <= OAMSCAN;
                mode <= "10";
                internal_en <= '1';
                if count = "001001111" then -- 79 (4Fh)
                    NS <= MAPREAD;
                end if;

            when TILEREAD =>
                NS <= RESET;
                mode <= "11";
                internal_en <= '1';

            when WAI =>
                NS <= WAI;

            when MAPREAD =>
                NS <= MAPREAD;
                mode <= "11";
                internal_en <= '1';
                if count = "011111011" then -- 251 (FBh)  Earliest value, may be as late as 377 (179h)
                    internal_en <= '0';
                    NS <= HBLANK;
                end if;

            when HBLANK =>
                NS <= HBLANK;
                mode <= "00";
                if count = "111000111" then -- 455 (1C7h)
                    if ly = "10001111" then -- 143 (8Fh)
                        NS <= VBLANK;
                    else
                        NS <= OAMSCAN;
                    end if;
                end if;

            when VBLANK =>
                NS <= VBLANK;
                mode <= "01";
                if count = "111000111" and ly = "10011001" then -- 455, 153 (1C7h, 99h)
                    NS <= OAMSCAN;
                end if;

            when others => 
                NS <= RESET;
        end case;
    end process;

    -- *********************************************************************************************
    -- Positioning tests

    ly_coinc <= '1' when ly = lyc else '0';

    -- *********************************************************************************************
    -- Local RAM

    -- External access is through port A, according to memory map defined above
    -- Internal access is through port B, using 'dataddr' / 'map_sel & mapaddr' and '_dob' signals


    lo_addr(2 downto 0) <= "000";
    lo_addr(3) <= bitfield;
    lo_addr(13 downto 4) <= dataddr;
    loram : RAMB16BWER
    generic map (
        DATA_WIDTH_A => 9,
        DATA_WIDTH_B => 9,
        DOA_REG => 0,
        DOB_REG => 0,
        EN_RSTRAM_A => TRUE,
        EN_RSTRAM_B => TRUE,
        -- GB Bootstrap Rom
        RSTTYPE => "SYNC",
        RST_PRIORITY_A => "CE",
        RST_PRIORITY_B => "CE",
        SIM_COLLISION_CHECK => "ALL",
        SIM_DEVICE => "SPARTAN6",
        WRITE_MODE_A => "READ_FIRST"    -- Averts collisions when reading an address just written to
    )
    port map (
        -- Port A: data from CPU
        DOA => lo_doa,   -- 32-bit output: A port data output
        ADDRA => ABUS(10 downto 0) & "000", -- 14-bit input: A port address input: 8-bit output -> 11-bit address
        CLKA => CLK,      -- 1-bit input: A port clock input
        ENA => '1',       -- 1-bit input: A port enable input
        REGCEA => '0',    -- 1-bit input: A port register clock enable input
        RSTA => '0',      -- 1-bit input: A port register set/reset input
        WEA => "000" & lo_en,   -- 4-bit input: Port A byte-wide write enable input
        DIA => X"000000" & DIN, -- 32-bit input: A port data input
        DIPA => "0000",   -- 4-bit input: A port parity input
        -- Port B: data to output
        DOB => lo_dob,   -- 32-bit output: B port data output
        ADDRB => lo_addr, -- 14-bit input: B port address input: 8-bit output -> 11-bit address
        CLKB => CLK,      -- 1-bit input: B port clock input
        ENB => internal_en, -- 1-bit input: B port enable input
        REGCEB => '0',    -- 1-bit input: B port register clock enable input
        RSTB => '0',      -- 1-bit input: B port register set/reset input
        WEB => "0000",    -- 4-bit input: Port B byte-wide write enable input
        DIB => X"00000000", -- 32-bit input: B port data input
        DIPB => "0000"    -- 4-bit input: B port parity input
    );

    mid_addr(2 downto 0) <= "000";
    mid_addr(3) <= bitfield;
    mid_addr(13 downto 4) <= dataddr;
    midram : RAMB16BWER
    generic map (
        DATA_WIDTH_A => 9,
        DATA_WIDTH_B => 9,
        DOA_REG => 0,
        DOB_REG => 0,
        EN_RSTRAM_A => TRUE,
        EN_RSTRAM_B => TRUE,
        -- GB Bootstrap Rom
        RSTTYPE => "SYNC",
        RST_PRIORITY_A => "CE",
        RST_PRIORITY_B => "CE",
        SIM_COLLISION_CHECK => "ALL",
        SIM_DEVICE => "SPARTAN6",
        WRITE_MODE_A => "READ_FIRST"    -- Averts collisions when reading an address just written to
    )
    port map (
        -- Port A: data from CPU
        DOA => mid_doa,   -- 32-bit output: A port data output
        ADDRA => ABUS(10 downto 0) & "000", -- 14-bit input: A port address input: 8-bit output -> 11-bit address
        CLKA => CLK,      -- 1-bit input: A port clock input
        ENA => '1',       -- 1-bit input: A port enable input
        REGCEA => '0',    -- 1-bit input: A port register clock enable input
        RSTA => '0',      -- 1-bit input: A port register set/reset input
        WEA => "000" & mid_en,   -- 4-bit input: Port A byte-wide write enable input
        DIA => X"000000" & DIN, -- 32-bit input: A port data input
        DIPA => "0000",   -- 4-bit input: A port parity input
        -- Port B: data to output
        DOB => mid_dob,   -- 32-bit output: B port data output
        ADDRB => mid_addr, -- 14-bit input: B port address input: 8-bit output -> 11-bit address
        CLKB => CLK,      -- 1-bit input: B port clock input
        ENB => internal_en, -- 1-bit input: B port enable input
        REGCEB => '0',    -- 1-bit input: B port register clock enable input
        RSTB => '0',      -- 1-bit input: B port register set/reset input
        WEB => "0000",    -- 4-bit input: Port B byte-wide write enable input
        DIB => X"00000000", -- 32-bit input: B port data input
        DIPB => "0000"    -- 4-bit input: B port parity input
    );

    hi_addr(2 downto 0) <= "000";
    hi_addr(3) <= bitfield;
    hi_addr(13 downto 4) <= dataddr;
    hiram : RAMB16BWER
    generic map (
        DATA_WIDTH_A => 9,
        DATA_WIDTH_B => 9,
        DOA_REG => 0,
        DOB_REG => 0,
        EN_RSTRAM_A => TRUE,
        EN_RSTRAM_B => TRUE,
        -- GB Bootstrap Rom
        RSTTYPE => "SYNC",
        RST_PRIORITY_A => "CE",
        RST_PRIORITY_B => "CE",
        SIM_COLLISION_CHECK => "ALL",
        SIM_DEVICE => "SPARTAN6",
        WRITE_MODE_A => "READ_FIRST"    -- Averts collisions when reading an address just written to
    )
    port map (
        -- Port A: data from CPU
        DOA => hi_doa,   -- 32-bit output: A port data output
        ADDRA => ABUS(10 downto 0) & "000", -- 14-bit input: A port address input: 8-bit output -> 11-bit address
        CLKA => CLK,      -- 1-bit input: A port clock input
        ENA => '1',       -- 1-bit input: A port enable input
        REGCEA => '0',    -- 1-bit input: A port register clock enable input
        RSTA => '0',      -- 1-bit input: A port register set/reset input
        WEA => "000" & hi_en,   -- 4-bit input: Port A byte-wide write enable input
        DIA => X"000000" & DIN, -- 32-bit input: A port data input
        DIPA => "0000",   -- 4-bit input: A port parity input
        -- Port B: data to output
        DOB => hi_dob,   -- 32-bit output: B port data output
        ADDRB => hi_addr, -- 14-bit input: B port address input: 8-bit output -> 11-bit address
        CLKB => CLK,      -- 1-bit input: B port clock input
        ENB => internal_en, -- 1-bit input: B port enable input
        REGCEB => '0',    -- 1-bit input: B port register clock enable input
        RSTB => '0',      -- 1-bit input: B port register set/reset input
        WEB => "0000",    -- 4-bit input: Port B byte-wide write enable input
        DIB => X"00000000", -- 32-bit input: B port data input
        DIPB => "0000"    -- 4-bit input: B port parity input
    );

    mapram : RAMB16BWER
    generic map (
        DATA_WIDTH_A => 9,
        DATA_WIDTH_B => 9,
        DOA_REG => 0,
        DOB_REG => 0,
        EN_RSTRAM_A => TRUE,
        EN_RSTRAM_B => TRUE,
        -- GB Bootstrap Rom
        RSTTYPE => "SYNC",
        RST_PRIORITY_A => "CE",
        RST_PRIORITY_B => "CE",
        SIM_COLLISION_CHECK => "ALL",
        SIM_DEVICE => "SPARTAN6",
        WRITE_MODE_A => "READ_FIRST"    -- Averts collisions when reading an address just written to
    )
    port map (
        -- Port A: data from CPU
        DOA => map_doa,   -- 32-bit output: A port data output
        ADDRA => ABUS(10 downto 0) & "000", -- 14-bit input: A port address input: 8-bit output -> 11-bit address
        CLKA => CLK,      -- 1-bit input: A port clock input
        ENA => '1',       -- 1-bit input: A port enable input
        REGCEA => '0',    -- 1-bit input: A port register clock enable input
        RSTA => '0',      -- 1-bit input: A port register set/reset input
        WEA => "000" & map_en,   -- 4-bit input: Port A byte-wide write enable input
        DIA => X"000000" & DIN, -- 32-bit input: A port data input
        DIPA => "0000",   -- 4-bit input: A port parity input
        -- Port B: data to internal bus
        DOB => map_dob,   -- 32-bit output: B port data output
        ADDRB => map_sel & map_addr & "000", -- 14-bit input: B port address input: 8-bit output -> 11-bit address
        CLKB => CLK,      -- 1-bit input: B port clock input
        ENB => internal_en, -- 1-bit input: B port enable input
        REGCEB => '0',    -- 1-bit input: B port register clock enable input
        RSTB => '0',      -- 1-bit input: B port register set/reset input
        WEB => "0000",    -- 4-bit input: Port B byte-wide write enable input
        DIB => X"00000000", -- 32-bit input: B port data input
        DIPB => "0000"    -- 4-bit input: B port parity input
    );


end Behaviour;
